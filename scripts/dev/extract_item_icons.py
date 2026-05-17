from __future__ import annotations

import sys
from pathlib import Path
from collections import deque

from PIL import Image, ImageFilter


ITEMS = ("coin", "heal", "fever_orb")
TARGET_SIZE = 512
PADDING = 34


def is_key_green(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    if a == 0:
        return True
    return g > 150 and r < 70 and b < 80 and (g - max(r, b)) > 95


def chroma_key_connected_background(image: Image.Image, remove_internal_key: bool, internal_min_area: int = 0) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    visited = bytearray(width * height)
    alpha = Image.new("L", rgba.size, 255)
    alpha_pixels = alpha.load()
    queue: deque[tuple[int, int]] = deque()

    def add_if_key(x: int, y: int) -> None:
        if x < 0 or y < 0 or x >= width or y >= height:
            return
        index = y * width + x
        if visited[index]:
            return
        if is_key_green(pixels[x, y]):
            visited[index] = 1
            queue.append((x, y))

    for x in range(width):
        add_if_key(x, 0)
        add_if_key(x, height - 1)
    for y in range(height):
        add_if_key(0, y)
        add_if_key(width - 1, y)

    while queue:
        x, y = queue.popleft()
        alpha_pixels[x, y] = 0
        add_if_key(x + 1, y)
        add_if_key(x - 1, y)
        add_if_key(x, y + 1)
        add_if_key(x, y - 1)

    if remove_internal_key:
        for y in range(height):
            for x in range(width):
                if is_key_green(pixels[x, y]):
                    alpha_pixels[x, y] = 0
    elif internal_min_area > 0:
        for y in range(height):
            for x in range(width):
                start_index = y * width + x
                if visited[start_index] or not is_key_green(pixels[x, y]):
                    continue
                component = []
                queue.append((x, y))
                visited[start_index] = 1
                while queue:
                    cx, cy = queue.popleft()
                    component.append((cx, cy))
                    for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                        if nx < 0 or ny < 0 or nx >= width or ny >= height:
                            continue
                        index = ny * width + nx
                        if visited[index] or not is_key_green(pixels[nx, ny]):
                            continue
                        visited[index] = 1
                        queue.append((nx, ny))
                if len(component) >= internal_min_area:
                    for cx, cy in component:
                        alpha_pixels[cx, cy] = 0

    rgba.putalpha(alpha)
    return rgba


def clean_edge(image: Image.Image, despill_green: bool) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    # Contract the matte slightly to remove chroma-key antialias pixels.
    alpha = alpha.filter(ImageFilter.MinFilter(3))
    pixels = rgba.load()
    alpha_pixels = alpha.load()
    width, height = rgba.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            new_alpha = alpha_pixels[x, y]
            if new_alpha == 0:
                pixels[x, y] = (r, g, b, 0)
                continue
            if despill_green and g > r and g > b:
                green_bias = g - max(r, b)
                if green_bias > 35 and r < 95 and b < 95:
                    new_alpha = int(new_alpha * 0.45)
                    g = max(r, b, int(g * 0.55))
                elif green_bias > 22:
                    g = int(g - green_bias * 0.45)
            pixels[x, y] = (r, g, b, new_alpha)

    return rgba


def trim_and_square(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if not bbox:
        return Image.new("RGBA", (TARGET_SIZE, TARGET_SIZE), (0, 0, 0, 0))

    cropped = image.crop(bbox)
    max_side = max(cropped.width, cropped.height)
    canvas_size = max_side + PADDING * 2
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    canvas.alpha_composite(cropped, ((canvas_size - cropped.width) // 2, (canvas_size - cropped.height) // 2))
    return canvas.resize((TARGET_SIZE, TARGET_SIZE), Image.Resampling.LANCZOS)


def extract(source: Path, output_dir: Path) -> None:
    source_image = Image.open(source).convert("RGBA")
    width, height = source_image.size
    output_dir.mkdir(parents=True, exist_ok=True)

    for index, item_name in enumerate(ITEMS):
        left = round(width * index / 3)
        right = round(width * (index + 1) / 3)
        region = source_image.crop((left, 0, right, height))
        keyed = clean_edge(
            chroma_key_connected_background(region, item_name != "heal", 600 if item_name == "heal" else 0),
            item_name != "heal",
        )
        final = trim_and_square(keyed)
        final.save(output_dir / f"{item_name}.png")


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: extract_item_icons.py <source.png> <output_dir>", file=sys.stderr)
        return 2
    extract(Path(sys.argv[1]), Path(sys.argv[2]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
