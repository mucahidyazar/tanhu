#!/usr/bin/env python3
"""
İki görseli aynı yükseklikte yan yana koyar (docs/media/review/hud_envanter.jpg, hud_harita.jpg).

  python3 assets/ui/hud/_src/compare_pair.py <sol> <sağ> <çıktı.jpg> [--left-crop=x,y,w,h] [--right-crop=x,y,w,h] [--height=H]

Kırpımlar kaynak pikselidir; ikisi de H yüksekliğine (varsayılan sağın kırpım yüksekliği) ölçeklenir: aynı ölçek.
Bağımlılık: numpy ve ffmpeg.
"""
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from cut_kit import read_png, resize  # noqa: E402
from compare import side_by_side, write_jpg  # noqa: E402


def _box(arg: str):
    return tuple(int(v) for v in arg.split("=", 1)[1].split(","))


def _crop(img, box):
    if box is None:
        return img
    x, y, w, h = box
    return img[y:y + h, x:x + w]


def _opaque(img):
    out = img.copy()
    out[..., 3] = 1.0
    return out


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = [a for a in sys.argv[1:] if a.startswith("--")]
    if len(args) < 3:
        print(__doc__)
        return 2
    left_box = right_box = None
    height = 0
    for o in opts:
        if o.startswith("--left-crop="):
            left_box = _box(o)
        elif o.startswith("--right-crop="):
            right_box = _box(o)
        elif o.startswith("--height="):
            height = int(o.split("=", 1)[1])
    left = _opaque(_crop(read_png(Path(args[0])), left_box))
    right = _opaque(_crop(read_png(Path(args[1])), right_box))
    h = height or right.shape[0]
    left = resize(left, max(int(round(left.shape[1] * h / left.shape[0])), 1), h)
    right = resize(right, max(int(round(right.shape[1] * h / right.shape[0])), 1), h)
    write_jpg(Path(args[2]), side_by_side(left, right))
    print(args[2])
    return 0


if __name__ == "__main__":
    sys.exit(main())
