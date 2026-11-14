"""Discover a Qt global-menu endpoint by process ID."""

from __future__ import annotations

import argparse
import asyncio
import json
import sys
import xml.etree.ElementTree as ET
from collections.abc import Sequence
from contextvars import ContextVar
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
CALL_SEMAPHORE: ContextVar[asyncio.Semaphore] = ContextVar("call_semaphore")


def get_semaphore() -> asyncio.Semaphore:
    """Return the call concurrency semaphore for the active context."""
    try:
        return CALL_SEMAPHORE.get()
    except LookupError:
        semaphore = asyncio.Semaphore(MAX_CONCURRENT_CALLS)
        CALL_SEMAPHORE.set(semaphore)
        return semaphore


async def call(bus: MessageBus, message: Message) -> list[Any]:
    """Call a D-Bus method with a bounded timeout."""
    async with get_semaphore():
        reply = await asyncio.wait_for(bus.call(message), timeout=CALL_TIMEOUT)
    if reply.message_type != MessageType.METHOD_RETURN:
        raise RuntimeError(reply.error_name or "D-Bus method failed")
    return list(reply.body)


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
    except (TimeoutError, RuntimeError, IndexError, TypeError, ValueError):
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


async def introspect(bus: MessageBus, service: str, path: str) -> ET.Element | None:
    """Return parsed introspection XML for a D-Bus object path."""
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
        return ET.fromstring(str(body[0]))
    except (TimeoutError, RuntimeError, IndexError, ET.ParseError):
        return None


async def is_menu(bus: MessageBus, service: str, path: str) -> bool:
    """Return whether an object implements the Canonical menu interface."""
    node = await introspect(bus, service, path)
    if node is None:
        return False
    return any(
        interface.get("name") == MENU_INTERFACE
        for interface in node.findall("interface")
    )


async def discover_menubar_children(bus: MessageBus, service: str) -> list[str]:
    """Inspect /MenuBar via Introspect to discover child node paths."""
    node = await introspect(bus, service, "/MenuBar")
    if node is None:
        return []
    paths: list[str] = []
    for child in node.findall("node"):
        name = (child.get("name") or "").strip("/")
        if name:
            paths.append(f"/MenuBar/{name.removeprefix('MenuBar/')}")
    return paths


def endpoint_sort_key(endpoint: dict[str, str]) -> tuple[int, int, str, str]:
    """Order menu endpoints by lowest numeric ID first, then path and service."""
    tail = endpoint["path"].rsplit("/", 1)[-1]
    if tail.isdigit():
        return (0, int(tail), endpoint["path"], endpoint["service"])
    return (1, 0, endpoint["path"], endpoint["service"])


async def probe_candidates(
    bus: MessageBus, candidates: Sequence[tuple[str, str]]
) -> dict[str, str] | None:
    """Check candidate (service, path) pairs and return the lowest-numbered menu."""
    if not candidates:
        return None
    matches = await asyncio.gather(
        *(is_menu(bus, service, path) for service, path in candidates)
    )
    endpoints = [
        {"service": service, "path": path}
        for (service, path), matches_menu in zip(candidates, matches, strict=True)
        if matches_menu
    ]
    return min(endpoints, key=endpoint_sort_key) if endpoints else None


async def probe(bus: MessageBus, pid: int) -> dict[str, str] | None:
    """Find the lowest-numbered Qt menu endpoint exported by a process."""
    for attempt in range(PROBE_ATTEMPTS):
        services = await services_for_pid(bus, pid)
        child_lists = await asyncio.gather(
            *(discover_menubar_children(bus, service) for service in services)
        )
        discovered = [
            (service, path)
            for service, paths in zip(services, child_lists, strict=True)
            for path in paths
        ]
        endpoint = await probe_candidates(bus, discovered)
        if endpoint is not None:
            return endpoint
        if not discovered:
            fallback = [
                (service, f"/MenuBar/{menu_id}")
                for service in services
                for menu_id in range(1, MAX_MENU_ID + 1)
            ]
            endpoint = await probe_candidates(bus, fallback)
            if endpoint is not None:
                return endpoint
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
    CALL_SEMAPHORE.set(asyncio.Semaphore(MAX_CONCURRENT_CALLS))
    bus = await MessageBus(bus_type=BusType.SESSION).connect()
    try:
        print(json.dumps(await probe(bus, pid), separators=(",", ":")))
    finally:
        bus.disconnect()


def main() -> int:
    """Run the endpoint probe and report transport failures."""
    try:
        asyncio.run(run(parse_args().pid))
    except (TimeoutError, RuntimeError, OSError) as error:
        print(f"quickshell-qt-menu: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
