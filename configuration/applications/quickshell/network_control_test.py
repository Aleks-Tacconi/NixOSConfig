"""Test the Quickshell NetworkManager helper's pure parsing behavior."""

import unittest
from argparse import Namespace
from unittest.mock import patch

from network_control import connect_network, device_status, security_details, split_terse


class NetworkControlTest(unittest.TestCase):
    """Cover values that are easy to corrupt in nmcli terse output."""

    def test_split_terse_unescapes_colons_and_backslashes(self) -> None:
        """Preserve escaped SSIDs and BSSIDs while splitting fields."""
        self.assertEqual(
            split_terse(r"*:Office\: 5G:AA\:BB\:CC\:DD\:EE\:FF:82:WPA2"),
            ["*", "Office: 5G", "AA:BB:CC:DD:EE:FF", "82", "WPA2"],
        )
        self.assertEqual(split_terse(r":Path\\Name"), ["", r"Path\Name"])

    def test_security_classification(self) -> None:
        """Separate password, open, and unsupported enterprise flows."""
        self.assertEqual(security_details("--"), ("Open", False, True))
        self.assertEqual(security_details("OWE"), ("OWE", False, True))
        self.assertEqual(security_details("WPA2 WPA3"), ("WPA2 WPA3", True, True))
        self.assertEqual(security_details("WPA2 802.1X"), ("WPA2 802.1X", False, False))
        self.assertEqual(security_details("WEP"), ("WEP", False, False))

    @patch("network_control.run_nmcli")
    def test_status_uses_the_connected_wifi_interface(self, run_nmcli) -> None:
        """Prefer the connected adapter when several Wi-Fi devices exist."""
        run_nmcli.side_effect = [
            "wlan0:wifi:disconnected:\n"
            "wlan1:wifi:connected:Office\n"
            "enp1s0:ethernet:connected:Wired\n",
            "enabled\n",
        ]
        status = device_status()
        self.assertEqual(status["interfaceName"], "wlan1")
        self.assertEqual(status["wifiInterface"], "wlan1")

    @patch("network_control.run_nmcli")
    def test_saved_connection_lets_nmcli_choose_compatible_profile(self, run_nmcli) -> None:
        """Select by BSSID instead of forcing a potentially stale saved UUID."""
        connect_network(
            Namespace(
                interface="wlan0",
                bssid="AA:BB:CC:DD:EE:FF",
                uuid="saved-uuid",
                password_stdin=False,
            )
        )
        run_nmcli.assert_called_once_with(
            [
                "--wait",
                "30",
                "device",
                "wifi",
                "connect",
                "AA:BB:CC:DD:EE:FF",
                "ifname",
                "wlan0",
            ],
            input_text=None,
        )


if __name__ == "__main__":
    unittest.main()
