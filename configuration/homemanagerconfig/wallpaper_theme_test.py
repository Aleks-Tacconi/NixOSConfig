"""Check wallpaper color extraction and theme generation without changing live settings."""

import tempfile
import json
import unittest
from pathlib import Path
from unittest.mock import patch

from PIL import Image

from wallpaper_theme import gnome_accent, notify_apps, qt_palette, recolor_kde, recolor_kvantum, wallpaper_accent, write_theme


class WallpaperThemeTest(unittest.TestCase):
    """Cover neutral images, semantic colors, palette roles, and failed selections."""

    def test_native_accent_follows_hue_and_handles_neutrals(self):
        """Native GTK accents track wallpaper hue without treating gray as red."""
        for color, expected in (((220, 80, 90), "red"), ((80, 120, 220), "blue"),
                                ((80, 220, 100), "green"), ((176, 176, 176), "slate")):
            with self.subTest(color=color):
                self.assertEqual(gnome_accent(color), expected)

    @patch("wallpaper_theme.subprocess.run")
    def test_notify_updates_gsettings_and_wakes_qt_directory_watchers(self, run):
        """Publish native preferences and replace markers without touching managed files."""
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory)
            (config / "qt6ct").mkdir()
            managed = config / "qt6ct/qt6ct.conf"
            managed.write_text("managed settings")
            notify_apps((80, 120, 220), config)
            self.assertEqual(run.call_args_list[0].args[0][-1], "blue")
            self.assertEqual(run.call_args_list[1].args[0][0], "dbus-send")
            self.assertEqual((config / "qt6ct/.wallpaper-palette").read_text(), "80,120,220")
            self.assertEqual(managed.read_text(), "managed settings")

    def test_accent_ignores_dark_background(self):
        """A small colored subject should supply the accent instead of black."""
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "wallpaper.png"
            image = Image.new("RGB", (100, 100), "black")
            image.paste((180, 30, 40), (40, 40, 60, 60))
            image.save(path)
            red, green, blue = wallpaper_accent(path)
            self.assertGreater(red, green * 2)
            self.assertGreater(red, blue * 2)
            self.assertGreaterEqual(min(red, green, blue), 70)

    def test_grayscale_gets_neutral_accent(self):
        """Monochrome wallpapers should not invent a hue."""
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "gray.png"
            Image.new("RGB", (10, 10), (100, 100, 100)).save(path)
            self.assertEqual(wallpaper_accent(path), (176, 176, 176))

    def test_kde_retains_semantic_colors(self):
        """Changing the accent must leave error colors and ordinary surfaces alone."""
        template = "DecorationFocus=243,139,168\nForegroundNegative=243, 139, 168\nBackgroundNormal=20,20,20\n"
        result = recolor_kde(template, (80, 120, 220))
        self.assertIn("DecorationFocus=80,120,220", result)
        self.assertIn("ForegroundNegative=243, 139, 168", result)
        self.assertIn("BackgroundNormal=20,20,20", result)

    def test_kvantum_preserves_alpha(self):
        """Kvantum's translucent highlights should retain their opacity."""
        result = recolor_kvantum("highlight.color=#F38BA84D\nshadow=#DD809C", (80, 120, 220))
        self.assertIn("#5078dc4D", result)
        self.assertNotIn("#DD809C", result)

    def test_qt_has_all_color_roles(self):
        """Each group includes the Qt 6 Accent role and a dark selection foreground."""
        for line in qt_palette((80, 120, 220)).splitlines()[1:]:
            colors = line.split("=", 1)[1].split(", ")
            self.assertEqual(len(colors), 22)
            self.assertEqual(colors[12], "#ff5078dc")
            self.assertEqual(colors[21], colors[12])

    def test_bad_image_leaves_existing_theme_untouched(self):
        """A failed image decode must not overwrite the active palette."""
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            palette = output / "qt.conf"
            palette.write_text("previous palette")
            with self.assertRaises(OSError):
                write_theme(output / "missing.png", output, output / "kde", output / "kvantum")
            self.assertEqual(palette.read_text(), "previous palette")

    def test_generated_shell_palette_matches_application_accent(self):
        """Publish the same extracted accent for the shell and application palettes."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            image = root / "wallpaper.png"
            Image.new("RGB", (10, 10), (180, 30, 60)).save(image)
            kde = root / "base.colors"
            kde.write_text("DecorationFocus=243,139,168\n")
            for suffix in ("svg", "kvconfig"):
                (root / f"catppuccin-mocha-red-charcoal.{suffix}").write_text("#F38BA8")
            output = root / "generated"
            accent = write_theme(image, output, kde, root)
            color = "#" + "".join(f"{channel:02x}" for channel in accent)
            self.assertEqual(json.loads((output / "shell-palette.json").read_text()), {"accent": color})
            self.assertIn(color, (output / "Kvantum/wallpaper/wallpaper.svg").read_text())


if __name__ == "__main__":
    unittest.main()
