#!/usr/bin/env python3
"""
HUD'un referansla yan yana karşılaştırması (docs/media/review/hud_karsilastirma*.jpg).

  python3 assets/ui/hud/_src/compare.py <referans.webp|png> <oyun_karesi.png> <çıktı_klasörü> [ad]

Referans 1080 satıra ölçeklenir (oyunun arayüzü 1080 satıra çizilir): iki kare aynı ölçektedir.
  <ad>.jpg           solda referans, sağda oyunun karesi (ikisi de 1080 satır)
  <ad>_parcalar.jpg  parça parça (sol üst, sağ üst, alt orta, sağ alt), her satırda solda referans sağda oyun, 2 kat büyük
Bağımlılık: numpy ve ffmpeg.
"""
import subprocess
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from cut_kit import read_png, resize  # noqa: E402

ROWS = 1080
GAP = 16
BG = np.array([0.07, 0.065, 0.06], dtype=np.float32)


def to_rows(img: np.ndarray, rows: int) -> np.ndarray:
    h, w = img.shape[:2]
    if h == rows:
        return img
    return resize(img, int(round(w * rows / h)), rows)


def write_jpg(path: Path, img: np.ndarray) -> None:
    h, w = img.shape[:2]
    data = (np.clip(img[..., :3], 0, 1) * 255 + 0.5).astype(np.uint8).tobytes()
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{w}x{h}", "-i", "-",
                    "-frames:v", "1", "-q:v", "2", str(path)], input=data, check=True)


def side_by_side(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    h = max(a.shape[0], b.shape[0])
    out = np.zeros((h, a.shape[1] + GAP + b.shape[1], 3), np.float32)
    out[:] = BG
    out[:a.shape[0], :a.shape[1]] = a[..., :3]
    out[:b.shape[0], a.shape[1] + GAP:] = b[..., :3]
    return out


def crop(img: np.ndarray, box: tuple) -> np.ndarray:
    x0, y0, x1, y1 = (int(round(v)) for v in box)
    h, w = img.shape[:2]
    return img[max(y0, 0):min(y1, h), max(x0, 0):min(x1, w)]


def regions(w: float, h: float) -> list:
    """Parçaların kutuları (1080 satırlık karede): köşelere ve alt ortaya göre."""
    return [
        ("sol üst", (0, 0, 460, 222)),
        ("sağ üst", (w - 362, 0, w, 402)),
        ("alt orta", (w / 2 - 386, h - 166, w / 2 + 394, h - 36)),
        ("sağ alt", (w - 300, h - 146, w, h - 36)),
    ]


def main() -> int:
    if len(sys.argv) < 4:
        print(__doc__)
        return 2
    ref = to_rows(read_png(Path(sys.argv[1])), ROWS)
    game = to_rows(read_png(Path(sys.argv[2])), ROWS)
    out_dir = Path(sys.argv[3])
    name = sys.argv[4] if len(sys.argv) > 4 else "hud_karsilastirma"
    out_dir.mkdir(parents=True, exist_ok=True)
    write_jpg(out_dir / f"{name}.jpg", side_by_side(ref, game))
    rows = []
    for _, (rbox), (_, gbox) in zip([r[0] for r in regions(ref.shape[1], ref.shape[0])],
                                     [r[1] for r in regions(ref.shape[1], ref.shape[0])],
                                     regions(game.shape[1], game.shape[0])):
        a = crop(ref, rbox)
        b = crop(game, gbox)
        a = resize(np.concatenate([a[..., :3], np.ones(a.shape[:2] + (1,), np.float32)], -1), a.shape[1] * 2, a.shape[0] * 2)
        b = resize(np.concatenate([b[..., :3], np.ones(b.shape[:2] + (1,), np.float32)], -1), b.shape[1] * 2, b.shape[0] * 2)
        rows.append(side_by_side(a, b))
    width = max(r.shape[1] for r in rows)
    total = sum(r.shape[0] for r in rows) + GAP * (len(rows) - 1)
    sheet = np.zeros((total, width, 3), np.float32)
    sheet[:] = BG
    y = 0
    for r in rows:
        sheet[y:y + r.shape[0], :r.shape[1]] = r
        y += r.shape[0] + GAP
    write_jpg(out_dir / f"{name}_parcalar.jpg", sheet)
    print(out_dir / f"{name}.jpg")
    print(out_dir / f"{name}_parcalar.jpg")
    return 0


if __name__ == "__main__":
    sys.exit(main())
