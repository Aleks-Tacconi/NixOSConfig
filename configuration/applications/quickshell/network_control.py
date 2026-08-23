"""Provide structured and password-safe NetworkManager operations for Quickshell."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from collections.abc import Sequence
from typing import Any

SECRET_REQUIRED_EXIT = 20
NMCLI_TIMEOUT = 35


class NetworkError(RuntimeError):
    """Represent a failed NetworkManager operation."""

    def __init__(self, message: str, *, secret_required: bool = False) -> None:
        super().__init__(message)
        self.secret_required = secret_required


def split_terse(line: str) -> list[str]:
    """Split one escaped nmcli terse-output row."""
    fields: list[str] = []
    field: list[str] = []
    escaped = False
    for character in line:
        if escaped:
            field.append(character)
            escaped = False
        elif character == "\\":
            escaped = True
        elif character == ":":
            fields.append("".join(field))
            field = []
        else:
            field.append(character)
    if escaped:
        field.append("\\")
    fields.append("".join(field))
    return fields


def run_nmcli(
    arguments: Sequence[str], *, input_text: str | None = None
) -> str:
    """Run nmcli with stable output and return stdout."""
    environment = os.environ.copy()
    environment["LC_ALL"] = "C"
    try:
        result = subprocess.run(
            ["nmcli", *arguments],
            input=input_text,
            capture_output=True,
            text=True,
            timeout=NMCLI_TIMEOUT,
            env=environment,
            check=False,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired) as error:
        raise NetworkError("NetworkManager did not respond") from error
    if result.returncode == 0:
        return result.stdout

    message = result.stderr.strip() or result.stdout.strip() or "Network operation failed"
    lowered = message.lower()
    secret_required = "secret" in lowered or "password" in lowered
    raise NetworkError(message, secret_required=secret_required)


def device_status() -> dict[str, Any]:
    """Return the preferred network device and Wi-Fi radio state."""
    output = run_nmcli(
        ["-t", "-e", "yes", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]
    )
    devices = []
    for line in output.splitlines():
        parts = split_terse(line)
        if len(parts) < 4 or parts[0] == "lo":
            continue
        devices.append(
            {
                "interfaceName": parts[0],
                "type": parts[1],
                "state": parts[2],
                "label": ":".join(parts[3:]) or parts[0],
            }
        )

    connected = [device for device in devices if device["state"] == "connected"]
    preferred = next((device for device in connected if device["type"] == "wifi"), None)
    preferred = preferred or next(
        (device for device in connected if device["type"] == "ethernet"), None
    )
    preferred = preferred or next(
        (device for device in devices if device["type"] in {"wifi", "ethernet"}), None
    )
    wifi = next((device for device in connected if device["type"] == "wifi"), None)
    wifi = wifi or next((device for device in devices if device["type"] == "wifi"), None)
    radio = run_nmcli(["-t", "-f", "WIFI", "radio"]).strip()
    return {
        **(preferred or {}),
        "interfaceName": (preferred or {}).get("interfaceName", ""),
        "type": (preferred or {}).get("type", "none"),
        "state": (preferred or {}).get("state", "unavailable"),
        "label": (preferred or {}).get("label", "No network"),
        "wifiInterface": (wifi or {}).get("interfaceName", ""),
        "wifiEnabled": radio == "enabled",
    }


def security_details(security: str) -> tuple[str, bool, bool]:
    """Classify nmcli security text for the popup connection flow."""
    normalized = security.strip()
    if normalized in {"", "--"}:
        return ("Open", False, True)
    if "OWE" in normalized:
        return (normalized, False, True)
    if "802.1X" in normalized or "EAP" in normalized or "WEP" in normalized:
        return (normalized, False, False)
    return (normalized, True, True)


def saved_wifi_profiles() -> dict[str, str]:
    """Map saved Wi-Fi SSIDs to their NetworkManager profile UUIDs."""
    output = run_nmcli(["-t", "-e", "yes", "-f", "UUID,TYPE", "connection", "show"])
    profiles: dict[str, str] = {}
    for line in output.splitlines():
        parts = split_terse(line)
        if len(parts) != 2 or parts[1] not in {"wifi", "802-11-wireless"}:
            continue
        ssid_output = run_nmcli(
            ["-t", "-e", "yes", "-g", "802-11-wireless.ssid", "connection", "show", "uuid", parts[0]]
        )
        ssid = split_terse(ssid_output.strip())[0] if ssid_output.strip() else ""
        if ssid and ssid not in profiles:
            profiles[ssid] = parts[0]
    return profiles


def wifi_networks(interface_name: str, rescan: bool) -> list[dict[str, Any]]:
    """Return visible Wi-Fi networks, deduplicated by SSID and security type."""
    output = run_nmcli(
        [
            "-t", "-e", "yes", "-f", "IN-USE,SSID,BSSID,SIGNAL,SECURITY",
            "device", "wifi", "list", "ifname", interface_name,
            "--rescan", "yes" if rescan else "no",
        ]
    )
    saved = saved_wifi_profiles()
    networks: dict[tuple[str, str], dict[str, Any]] = {}
    for line in output.splitlines():
        parts = split_terse(line)
        if len(parts) < 5 or not parts[1]:
            continue
        security_label, requires_password, supported = security_details(parts[4])
        network = {
            "active": parts[0] == "*",
            "ssid": parts[1],
            "bssid": parts[2],
            "signal": int(parts[3]) if parts[3].isdigit() else 0,
            "security": security_label,
            "requiresPassword": requires_password,
            "supported": supported,
            "savedUuid": saved.get(parts[1], ""),
        }
        key = (network["ssid"], security_label)
        current = networks.get(key)
        if current is None or network["active"] or network["signal"] > current["signal"]:
            networks[key] = network
    return sorted(networks.values(), key=lambda item: (not item["active"], -item["signal"], item["ssid"].lower()))


def connect_network(arguments: argparse.Namespace) -> None:
    """Activate a visible Wi-Fi network, optionally reading its password from stdin."""
    command = ["--wait", "30"]
    password = None
    if arguments.password_stdin:
        command.insert(0, "--ask")
        password = sys.stdin.readline().rstrip("\n") + "\n"
    run_nmcli([*command, "device", "wifi", "connect", arguments.bssid, "ifname", arguments.interface], input_text=password)


def connect_hidden(arguments: argparse.Namespace) -> None:
    """Activate an open or WPA Personal hidden Wi-Fi network."""
    command = ["--wait", "30"]
    password = None
    if arguments.password_stdin:
        command.insert(0, "--ask")
        password = sys.stdin.readline().rstrip("\n") + "\n"
    run_nmcli([*command, "device", "wifi", "connect", arguments.ssid, "ifname", arguments.interface, "hidden", "yes"], input_text=password)


def build_parser() -> argparse.ArgumentParser:
    """Build the command-line parser."""
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("status")
    scan = commands.add_parser("scan")
    scan.add_argument("--interface", required=True)
    scan.add_argument("--rescan", action="store_true")
    connect = commands.add_parser("connect")
    connect.add_argument("--interface", required=True)
    connect.add_argument("--bssid", required=True)
    connect.add_argument("--uuid", default="")
    connect.add_argument("--password-stdin", action="store_true")
    hidden = commands.add_parser("connect-hidden")
    hidden.add_argument("--interface", required=True)
    hidden.add_argument("--ssid", required=True)
    hidden.add_argument("--password-stdin", action="store_true")
    disconnect = commands.add_parser("disconnect")
    disconnect.add_argument("--interface", required=True)
    radio = commands.add_parser("radio")
    radio.add_argument("state", choices=["on", "off"])
    return parser


def main(arguments: Sequence[str] | None = None) -> int:
    """Run the requested NetworkManager operation."""
    options = build_parser().parse_args(arguments)
    try:
        if options.command == "status":
            print(json.dumps(device_status(), ensure_ascii=False))
        elif options.command == "scan":
            print(json.dumps(wifi_networks(options.interface, options.rescan), ensure_ascii=False))
        elif options.command == "connect":
            connect_network(options)
        elif options.command == "connect-hidden":
            connect_hidden(options)
        elif options.command == "disconnect":
            run_nmcli(["--wait", "15", "device", "disconnect", options.interface])
        elif options.command == "radio":
            run_nmcli(["radio", "wifi", options.state])
    except NetworkError as error:
        print(str(error), file=sys.stderr)
        return SECRET_REQUIRED_EXIT if error.secret_required else 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
