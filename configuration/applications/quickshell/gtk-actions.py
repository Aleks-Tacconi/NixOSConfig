"""Discover and activate parameterless GTK actions over D-Bus."""

from __future__ import annotations

import argparse
import asyncio
import json
import re
import sys
import xml.etree.ElementTree as ET
from collections.abc import Sequence
from typing import Any

from dbus_next import BusType, Message, MessageType
from dbus_next.aio import MessageBus

DBUS_SERVICE = "org.freedesktop.DBus"
DBUS_PATH = "/org/freedesktop/DBus"
DBUS_INTERFACE = "org.freedesktop.DBus"
INTROSPECT_INTERFACE = "org.freedesktop.DBus.Introspectable"
GTK_ACTIONS_INTERFACE = "org.gtk.Actions"

CALL_TIMEOUT = 0.75
MAX_CONCURRENT_CALLS = 32
MAX_CONNECTIONS = 8
MAX_DEPTH = 8
MAX_NODES = 96
MAX_ACTIONS_PER_OBJECT = 128
MAX_XML_BYTES = 256 * 1024
OBJECT_PATH_RE = re.compile(r"/(?:[A-Za-z0-9_]+(?:/[A-Za-z0-9_]+)*)?")
CALL_SEMAPHORE = asyncio.Semaphore(MAX_CONCURRENT_CALLS)


class BridgeError(RuntimeError):
    """Represent a D-Bus bridge operation failure."""


async def call(bus: MessageBus, message: Message) -> list[Any]:
    """Call a D-Bus method with a short timeout."""
    async with CALL_SEMAPHORE:
        reply = await asyncio.wait_for(bus.call(message), timeout=CALL_TIMEOUT)
    if reply.message_type == MessageType.ERROR:
        detail = str(reply.body[0]) if reply.body else "D-Bus method failed"
        raise BridgeError(f"{reply.error_name or 'D-Bus error'}: {detail}")
    if reply.message_type != MessageType.METHOD_RETURN:
        raise BridgeError("Unexpected D-Bus reply")
    return reply.body


async def daemon_call(bus: MessageBus, member: str, signature: str = "", body: list[Any] | None = None) -> list[Any]:
    """Call a method on the session bus daemon."""
    return await call(
        bus,
        Message(
            destination=DBUS_SERVICE,
            path=DBUS_PATH,
            interface=DBUS_INTERFACE,
            member=member,
            signature=signature,
            body=body or [],
        ),
    )


async def connection_pid(bus: MessageBus, name: str) -> int | None:
    """Return the Unix PID for a bus name when accessible."""
    try:
        body = await daemon_call(bus, "GetConnectionUnixProcessID", "s", [name])
        return int(body[0])
    except (BridgeError, asyncio.TimeoutError, IndexError, TypeError, ValueError):
        return None


async def connection_owner(bus: MessageBus, name: str) -> str | None:
    """Resolve a well-known name to its unique connection name."""
    if name.startswith(":"):
        return name
    try:
        body = await daemon_call(bus, "GetNameOwner", "s", [name])
        return str(body[0])
    except (BridgeError, asyncio.TimeoutError, IndexError):
        return None


async def services_for_pid(bus: MessageBus, pid: int) -> list[tuple[str, str]]:
    """Find one preferred service name for each connection owned by a PID."""
    body = await daemon_call(bus, "ListNames")
    names = [str(name) for name in body[0]]
    pids = await asyncio.gather(*(connection_pid(bus, name) for name in names))
    owned_names = [name for name, owner_pid in zip(names, pids, strict=True) if owner_pid == pid]
    owners = await asyncio.gather(*(connection_owner(bus, name) for name in owned_names))

    aliases: dict[str, list[str]] = {}
    for name, owner in zip(owned_names, owners, strict=True):
        if owner is not None:
            aliases.setdefault(owner, []).append(name)

    services: list[tuple[str, str]] = []
    for owner, connection_names in aliases.items():
        well_known = sorted(name for name in connection_names if not name.startswith(":"))
        services.append((well_known[0] if well_known else owner, owner))

    services.sort(key=lambda item: (item[0].startswith(":"), item[0]))
    return services[:MAX_CONNECTIONS]


def child_path(parent: str, child: str) -> str | None:
    """Resolve and validate an introspection child object path."""
    path = child if child.startswith("/") else f"{parent.rstrip('/')}/{child}"
    return path if OBJECT_PATH_RE.fullmatch(path) else None


async def introspect(bus: MessageBus, service: str, path: str) -> ET.Element | None:
    """Return parsed introspection XML for an accessible object."""
    try:
        body = await call(
            bus,
            Message(
                destination=service,
                path=path,
                interface=INTROSPECT_INTERFACE,
                member="Introspect",
            ),
        )
        xml = str(body[0])
        if len(xml.encode()) > MAX_XML_BYTES:
            return None
        return ET.fromstring(xml)
    except (BridgeError, asyncio.TimeoutError, IndexError, ET.ParseError):
        return None


def friendly_title(action_id: str) -> str:
    """Convert a GTK action identifier into a concise display title."""
    name = re.sub(r"^(?:app|win|window)\.", "", action_id, flags=re.IGNORECASE)
    name = re.sub(r"([a-z0-9])([A-Z])", r"\1 \2", name)
    words = re.sub(r"[._-]+", " ", name).strip()
    return words.title() if words else action_id


async def describe_actions(bus: MessageBus, service: str, path: str) -> list[dict[str, str]]:
    """List enabled parameterless GTK actions on one object."""
    try:
        body = await call(
            bus,
            Message(
                destination=service,
                path=path,
                interface=GTK_ACTIONS_INTERFACE,
                member="List",
            ),
        )
        action_ids = [str(action) for action in body[0]][:MAX_ACTIONS_PER_OBJECT]
    except (BridgeError, asyncio.TimeoutError, IndexError, TypeError):
        return []

    async def describe(action_id: str) -> dict[str, str] | None:
        """Describe one action and reject disabled or parameterized actions."""
        try:
            body = await call(
                bus,
                Message(
                    destination=service,
                    path=path,
                    interface=GTK_ACTIONS_INTERFACE,
                    member="Describe",
                    signature="s",
                    body=[action_id],
                ),
            )
            description = body[0]
            if not bool(description[0]) or str(description[1]):
                return None
            return {
                "service": service,
                "path": path,
                "action": action_id,
                "title": friendly_title(action_id),
            }
        except (BridgeError, asyncio.TimeoutError, IndexError, TypeError):
            return None

    descriptions = await asyncio.gather(*(describe(action_id) for action_id in dict.fromkeys(action_ids)))
    return [description for description in descriptions if description is not None]


async def inspect_connection(bus: MessageBus, service: str) -> list[dict[str, str]]:
    """Inspect one bounded object tree for GTK action groups."""
    paths = ["/"]
    visited: set[str] = set()
    action_objects: list[str] = []

    for _depth in range(MAX_DEPTH + 1):
        batch = [path for path in paths if path not in visited][: MAX_NODES - len(visited)]
        if not batch:
            break
        visited.update(batch)
        nodes = await asyncio.gather(*(introspect(bus, service, path) for path in batch))
        paths = []
        for path, node in zip(batch, nodes, strict=True):
            if node is None:
                continue
            if any(interface.get("name") == GTK_ACTIONS_INTERFACE for interface in node.findall("interface")):
                action_objects.append(path)
            for child in node.findall("node"):
                resolved = child_path(path, child.get("name", ""))
                if resolved is not None and resolved not in visited:
                    paths.append(resolved)

    groups = await asyncio.gather(*(describe_actions(bus, service, path) for path in action_objects))
    return [action for group in groups for action in group]


async def list_actions(bus: MessageBus, pid: int) -> list[dict[str, str]]:
    """Discover GTK actions exported by all bounded connections for a PID."""
    services = await services_for_pid(bus, pid)
    groups = await asyncio.gather(*(inspect_connection(bus, service) for service, _owner in services))

    actions: list[dict[str, str]] = []
    seen: set[tuple[str, str, str]] = set()
    for (service, owner), group in zip(services, groups, strict=True):
        for action in group:
            key = (owner, action["path"], action["action"])
            if key not in seen:
                seen.add(key)
                action["service"] = service
                actions.append(action)
    return sorted(actions, key=lambda action: (action["title"].casefold(), action["action"], action["path"]))


async def activate_action(bus: MessageBus, service: str, path: str, action: str) -> None:
    """Activate a parameterless GTK action."""
    await call(
        bus,
        Message(
            destination=service,
            path=path,
            interface=GTK_ACTIONS_INTERFACE,
            member="Activate",
            signature="sava{sv}",
            body=[action, [], {}],
        ),
    )


def positive_pid(value: str) -> int:
    """Parse a positive process identifier for argparse."""
    pid = int(value)
    if pid <= 0:
        raise argparse.ArgumentTypeError("PID must be positive")
    return pid


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    """Parse bridge command-line arguments."""
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    list_parser = subparsers.add_parser("list", help="list parameterless actions for PID")
    list_parser.add_argument("pid", type=positive_pid)
    activate_parser = subparsers.add_parser("activate", help="activate a parameterless action")
    activate_parser.add_argument("service")
    activate_parser.add_argument("path")
    activate_parser.add_argument("action")
    return parser.parse_args(argv)


async def run(args: argparse.Namespace) -> None:
    """Run the selected bridge command on the session bus."""
    bus = await MessageBus(bus_type=BusType.SESSION).connect()
    try:
        if args.command == "list":
            print(json.dumps(await list_actions(bus, args.pid), separators=(",", ":")))
        else:
            await activate_action(bus, args.service, args.path, args.action)
    finally:
        bus.disconnect()


def main() -> int:
    """Run the CLI and convert D-Bus failures to a nonzero exit code."""
    try:
        asyncio.run(run(parse_args()))
    except (BridgeError, asyncio.TimeoutError, OSError) as error:
        print(f"quickshell-gtk-actions: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
