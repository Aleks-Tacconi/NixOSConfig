"""Derive wallpaper accents and publish them to dark Qt, KDE, and native GTK apps."""

import argparse
import colorsys
import json
import re
import subprocess
from pathlib import Path

from PIL import Image, ImageOps


def gnome_accent(accent: tuple[int, int, int]) -> str:
    """Map the wallpaper hue to a native libadwaita accent that updates live."""
    hue, saturation, _ = colorsys.rgb_to_hsv(*(channel / 255 for channel in accent))
    if saturation < 0.15:
        return "slate"
    hues = {"blue": 213, "teal": 189, "green": 131, "yellow": 40,
            "orange": 23, "red": 352, "pink": 331, "purple": 287}
    return min(hues, key=lambda name: min(abs(hue * 360 - hues[name]), 360 - abs(hue * 360 - hues[name])))


def notify_apps(accent: tuple[int, int, int], config: Path) -> None:
    """Publish the GNOME accent and notify running Qt/KDE apps of new colors."""
    subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "accent-color", gnome_accent(accent)], check=True)
    subprocess.run([
        "dbus-send", "--session", "--type=signal", "/KGlobalSettings",
        "org.kde.KGlobalSettings.notifyChange", "int32:0", "int32:0",
    ], check=True)
    for name in ("qt5ct", "qt6ct"):
        marker = config / name / ".wallpaper-palette"
        if marker.parent.is_dir():
            temporary = marker.with_suffix(".tmp")
            temporary.write_text(",".join(map(str, accent)))
            temporary.replace(marker)


def wallpaper_accent(path: Path) -> tuple[int, int, int]:
    """Choose a prominent chromatic color, avoiding shadows and washed-out pixels."""
    with Image.open(path) as original:
        image = ImageOps.exif_transpose(original).convert("RGB")
        image.thumbnail((128, 128))
        colors = image.quantize(colors=12).convert("RGB").getcolors(128 * 128)
    chromatic = []
    for count, rgb in colors:
        hue, saturation, value = colorsys.rgb_to_hsv(*(channel / 255 for channel in rgb))
        if saturation >= 0.15 and value >= 0.15:
            chromatic.append((count * saturation * value, hue, saturation))
    if not chromatic:
        return (176, 176, 176)
    _, hue, saturation = max(chromatic)
    rgb = colorsys.hsv_to_rgb(hue, min(0.65, max(0.3, saturation)), 0.88)
    return tuple(round(channel * 255) for channel in rgb)


def recolor_kde(template: str, accent: tuple[int, int, int]) -> str:
    """Replace accent roles while retaining semantic error and success colors."""
    rgb = ",".join(map(str, accent))
    roles = r"BackgroundAlternate|BackgroundNormal|DecorationFocus|ForegroundLink"
    return re.sub(
        rf"^({roles})=243,\s*139,\s*168$",
        lambda match: f"{match[1]}={rgb}",
        template,
        flags=re.MULTILINE,
    )


def recolor_kvantum(template: str, accent: tuple[int, int, int]) -> str:
    """Tint the Kvantum SVG and settings, including their translucent accents."""
    color = "#" + "".join(f"{channel:02x}" for channel in accent)
    shadow = "#" + "".join(f"{round(channel * 0.91):02x}" for channel in accent)
    template = re.sub("#f38ba8", color, template, flags=re.IGNORECASE)
    template = re.sub("#dd809c", shadow, template, flags=re.IGNORECASE)
    return re.sub("#eb9ab7", color, template, flags=re.IGNORECASE)


def qt_palette(accent: tuple[int, int, int]) -> str:
    """Emit Qt color-role lists for both Qt 5 and Qt 6, including Accent."""
    color = "#ff" + "".join(f"{channel:02x}" for channel in accent)
    roles = [
        "#ffcdd6f4", "#ff202020", "#ff3c3c3c", "#ff2c2c2c", "#ff101010",
        "#ff141414", "#ffcdd6f4", "#ffffffff", "#ffcdd6f4", "#ff101010",
        "#ff141414", "#ff000000", color, "#ff101010", color, color,
        "#ff202020", "#ff000000", "#ff101010", "#ffcdd6f4", "#80cdd6f4", color,
    ]
    disabled = roles.copy()
    for role in (0, 6, 8, 13):
        disabled[role] = "#ff777777"
    return "[ColorScheme]\n" + "\n".join(
        f"{group}_colors={', '.join(palette)}"
        for group, palette in (("active", roles), ("inactive", roles), ("disabled", disabled))
    ) + "\n"


def write_theme(image: Path, output: Path, kde: Path, kvantum: Path) -> tuple[int, int, int]:
    """Generate all files before replacing the active palette files atomically."""
    accent = wallpaper_accent(image)
    name = "wallpaper"
    files = {
        output / "shell-palette.json": json.dumps({"accent": "#" + "".join(f"{channel:02x}" for channel in accent)}),
        output / "kdeglobals": recolor_kde(kde.read_text(), accent),
        output / "qt.conf": qt_palette(accent),
    }
    for suffix in ("svg", "kvconfig"):
        source = kvantum / f"catppuccin-mocha-red-charcoal.{suffix}"
        files[output / "Kvantum" / name / f"{name}.{suffix}"] = recolor_kvantum(
            source.read_text(), accent
        )
    for path, text in files.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary = path.with_suffix(path.suffix + ".tmp")
        temporary.write_text(text)
        temporary.replace(path)
    return accent


def main() -> None:
    """Read explicit paths supplied by the Nix wrapper."""
    parser = argparse.ArgumentParser(description=__doc__)
    for argument in ("image", "output", "kde", "kvantum"):
        parser.add_argument(f"--{argument}", type=Path, required=True)
    parser.add_argument("--notify", action="store_true")
    parser.add_argument("--config", type=Path, default=Path.home() / ".config")
    args = parser.parse_args()
    try:
        accent = write_theme(args.image, args.output, args.kde, args.kvantum)
        if args.notify:
            notify_apps(accent, args.config)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Could not generate wallpaper colors: {error}\n")


if __name__ == "__main__":
    main()
