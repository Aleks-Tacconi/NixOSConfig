"""Discover a Qt global-menu endpoint by process ID."""

from __future__ import annotations

import argparse
import asyncio
import json
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
MENU_INTERFACE = "com.canonical.dbusmenu"

CALL_TIMEOUT = 0.5
MAX_CONCURRENT_CALLS = 32
MAX_MENU_ID = 64
PROBE_ATTEMPTS = 8
PROBE_DELAY = 0.15
CALL_SEMAPHORE = asyncio.Semaphore(MAX_CONCURRENT_CALLS)


async def call(bus: MessageBus, message: Message) -> list[Any]:
    """Call a D-Bus method with a bounded timeout."""
    async with CALL_SEMAPHORE:
        reply = await asyncio.wait_for(bus.call(message), timeout=CALL_TIMEOUT)
    if reply.message_type != MessageType.METHOD_RETURN:
        raise RuntimeError(reply.error_name or "D-Bus method failed")
    return reply.body


async def connection_pid(bus: MessageBus, name: str) -> int | None:
    """Return the Unix PID that owns a unique bus name."""
    try:
        body = await call(
            bus,
            Message(
                destination=DBUS_SERVICE,
                path=DBUS_PATH,
                interface=DBUS_INTERFACE,
                member="GetConnectionUnixProcessID",
                signature="s",
                body=[name],
            ),
        )
        return int(body[0])
    except (RuntimeError, asyncio.TimeoutError, IndexError, TypeError, ValueError):
        return None


async def services_for_pid(bus: MessageBus, pid: int) -> list[str]:
    """List unique D-Bus connection names owned by a process."""
    body = await call(
        bus,
        Message(
            destination=DBUS_SERVICE,
            path=DBUS_PATH,
            interface=DBUS_INTERFACE,
            member="ListNames",
        ),
    )
    names = [str(name) for name in body[0] if str(name).startswith(":")]
    pids = await asyncio.gather(*(connection_pid(bus, name) for name in names))
    return [
        name for name, owner_pid in zip(names, pids, strict=True) if owner_pid == pid
    ]


async def is_menu(bus: MessageBus, service: str, path: str) -> bool:
    """Return whether an object implements the Canonical menu interface."""
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
        node = ET.fromstring(str(body[0]))
        return any(
            interface.get("name") == MENU_INTERFACE
            for interface in node.findall("interface")
        )
    except (RuntimeError, asyncio.TimeoutError, IndexError, ET.ParseError):
        return False


async def probe(bus: MessageBus, pid: int) -> dict[str, str] | None:
    """Find the sole Qt menu endpoint exported by a process."""
    for attempt in range(PROBE_ATTEMPTS):
        services = await services_for_pid(bus, pid)
        candidates = [
            (service, f"/MenuBar/{menu_id}")
            for service in services
            for menu_id in range(1, MAX_MENU_ID + 1)
        ]
        matches = await asyncio.gather(
            *(is_menu(bus, service, path) for service, path in candidates)
        )
        endpoints = [
            {"service": service, "path": path}
            for (service, path), matches_menu in zip(candidates, matches, strict=True)
            if matches_menu
        ]
        if len(endpoints) == 1:
            return endpoints[0]
        if len(endpoints) > 1:
            return None
        if attempt + 1 < PROBE_ATTEMPTS:
            await asyncio.sleep(PROBE_DELAY)
    return None


def positive_pid(value: str) -> int:
    """Parse a positive process identifier for argparse."""
    pid = int(value)
    if pid <= 0:
        raise argparse.ArgumentTypeError("PID must be positive")
    return pid


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pid", type=positive_pid)
    return parser.parse_args(argv)


async def run(pid: int) -> None:
    """Discover and print a process's Qt menu endpoint."""
    bus = await MessageBus(bus_type=BusType.SESSION).connect()
    try:
        print(json.dumps(await probe(bus, pid), separators=(",", ":")))
    finally:
        bus.disconnect()


def main() -> int:
    """Run the endpoint probe and report transport failures."""
    try:
        asyncio.run(run(parse_args().pid))
    except (RuntimeError, asyncio.TimeoutError, OSError) as error:
        print(f"quickshell-qt-menu: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
