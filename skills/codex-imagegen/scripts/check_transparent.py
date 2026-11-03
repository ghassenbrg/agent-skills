#!/usr/bin/env python3
"""Check transparent images against harsh backgrounds, where leftovers can't hide.

check_transparent.py IMAGE... --sheet out.png     report, and a sheet to look at
check_transparent.py IMAGE --clean out.png        also clear stray specks, and trim to the subject

Exits 1 if an image has no alpha channel or an opaque corner. A clean report doesn't prove a clean image:
a white patch under a character's feet touches the character and has transparent corners, so always look at the sheet.
"""
import argparse
import sys

from PIL import Image, ImageChops, ImageFilter

SOLID = 16  # alpha above this counts as part of the picture; below it is faint dust
BACKGROUNDS = [(255, 0, 200), (30, 26, 18), (255, 255, 255)]  # each one hides what another shows


def groups(mask):
    """Connected groups of a 0/255 mask, biggest first, each a list of pixel indexes."""
    w, h = mask.size
    px = bytearray(mask.tobytes())
    found = []
    for start in range(w * h):
        if not px[start]:
            continue
        px[start] = 0
        stack, members = [start], []
        while stack:
            p = stack.pop()
            members.append(p)
            x, y = p % w, p // w
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < w and 0 <= ny < h and px[ny * w + nx]:
                    px[ny * w + nx] = 0
                    stack.append(ny * w + nx)
        found.append(members)
    return sorted(found, key=len, reverse=True)


def solid_mask(alpha):
    return alpha.point(lambda v: 255 if v > SOLID else 0)


def report(path):
    source = Image.open(path)
    if "A" not in source.getbands():
        print(f"{path}: FAIL no alpha channel ({source.mode}). Generate it again; don't remove a background.")
        return False
    alpha = source.convert("RGBA").getchannel("A")
    w, h = alpha.size
    corners = [alpha.getpixel(p) for p in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1))]
    found = groups(solid_mask(alpha))
    strays = sum(len(g) for g in found[1:])
    ok = not any(corners)
    print(f"{path}: {'ok' if ok else 'FAIL opaque corner'} {w}x{h} corners {corners} "
          f"subject bbox {solid_mask(alpha).getbbox()} parts {len(found)} stray pixels {strays}")
    return ok


def sheet(paths, out, size=420):
    grid = Image.new("RGB", (size * len(paths), size * (len(BACKGROUNDS) + 1)))
    for col, path in enumerate(paths):
        image = Image.open(path).convert("RGBA")
        box = solid_mask(image.getchannel("A")).getbbox() or (0, 0, *image.size)
        subject = image.crop(box)
        fitted = subject.copy()
        fitted.thumbnail((size - 16, size - 16), Image.LANCZOS)
        for row, colour in enumerate(BACKGROUNDS):
            cell = Image.new("RGB", (size, size), colour)
            cell.paste(fitted, ((size - fitted.width) // 2, (size - fitted.height) // 2), fitted)
            grid.paste(cell, (col * size, row * size))
        # The bottom edge, enlarged: it's where background and floor leftovers collect.
        band = subject.crop((0, max(subject.height - subject.width // 2, 0), subject.width, subject.height))
        scale = size / band.width
        band = band.resize((size, max(int(band.height * scale), 1)), Image.LANCZOS)
        cell = Image.new("RGB", (size, size), BACKGROUNDS[0])
        cell.paste(band, (0, 0), band)
        grid.paste(cell, (col * size, len(BACKGROUNDS) * size))
    grid.save(out)
    print(f"sheet: {out} (look at it: magenta, dark, white, then the bottom edge enlarged)")


def clean(path, out):
    """Clears specks well away from the subject and trims to it. The subject's own soft edge isn't touched."""
    image = Image.open(path).convert("RGBA")
    alpha = image.getchannel("A")
    solid = solid_mask(alpha)
    found = groups(solid)
    kept = [g for g in found if len(g) >= len(found[0]) * 0.005]  # small separate parts, like a music note, stay
    mask = bytearray(image.width * image.height)
    for group in kept:
        for p in group:
            mask[p] = 255
    subject = Image.frombytes("L", image.size, bytes(mask))
    near = subject.filter(ImageFilter.MaxFilter(9))
    image.putalpha(ImageChops.multiply(alpha, near))
    x0, y0, x1, y1 = subject.getbbox()
    pad = 10
    image.crop((max(x0 - pad, 0), max(y0 - pad, 0), min(x1 + pad, image.width), min(y1 + pad, image.height))).save(out)
    print(f"cleaned: {out} kept {len(kept)} part(s), cleared {sum(len(g) for g in found) - sum(len(g) for g in kept)} stray pixels")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("images", nargs="+")
    parser.add_argument("--sheet", help="write a sheet of the images on harsh backgrounds")
    parser.add_argument("--clean", help="write a copy of the one image without stray specks, trimmed to the subject")
    args = parser.parse_args()
    if args.clean and len(args.images) != 1:
        parser.error("--clean takes one image")
    ok = all([report(path) for path in args.images])
    if args.sheet:
        sheet(args.images, args.sheet)
    if args.clean and ok:
        clean(args.images[0], args.clean)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
