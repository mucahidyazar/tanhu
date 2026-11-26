#!/usr/bin/env python3
"""
Stil karşılaştırma aracı: referans görüntü ile bizim render'ımızı renk ölçümleriyle karşılaştırır.

Her iki görüntüde aynı anlamlı bölgeler (saç, ten, pelerin...) için örnek noktalar verilir;
araç her noktanın çevresindeki medyan rengi alır, CIE Lab uzayında farkı (ΔE) hesaplar,
noktaları görüntüye çizer ve iki görüntüyü yan yana birleştirir.

Kullanım:
  python3 tools/style_compare.py ref.png ref_points.json ours.png our_points.json out_dir
Nokta dosyası: {"hair_lit": [x, y], ...}  (piksel koordinatı, görüntünün kendi boyutunda)
"""
import json
import os
import subprocess
import sys

import numpy as np


def load(path):
    probe = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "stream=width,height", "-of", "csv=p=0", path],
                           capture_output=True, check=True).stdout.decode().strip().split(",")
    w, h = int(probe[0]), int(probe[1])
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "rawvideo", "-pix_fmt", "rgb24", "pipe:1"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.uint8).reshape(h, w, 3).astype(np.float32) / 255.0


def save(path, img):
    h, w, _ = img.shape
    data = np.clip(img * 255.0 + 0.5, 0, 255).astype(np.uint8).tobytes()
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{w}x{h}", "-i", "pipe:0", path],
                   input=data, check=True)


def srgb_to_lab(c):
    c = np.asarray(c, dtype=np.float64)
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = lin @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16.0 / 116.0)
    return np.stack([116.0 * f[..., 1] - 16.0, 500.0 * (f[..., 0] - f[..., 1]), 200.0 * (f[..., 1] - f[..., 2])], axis=-1)


def sample(img, x, y, r=4):
    h, w, _ = img.shape
    patch = img[max(y - r, 0): min(y + r + 1, h), max(x - r, 0): min(x + r + 1, w)].reshape(-1, 3)
    return np.median(patch, axis=0)


def mark(img, points, color=(1.0, 0.0, 1.0)):
    out = img.copy()
    for x, y in points:
        out[max(y - 6, 0): y + 7, max(x - 6, 0): x - 4] = color
        out[max(y - 6, 0): y + 7, x + 5: x + 7] = color
        out[max(y - 6, 0): y - 4, max(x - 6, 0): x + 7] = color
        out[y + 5: y + 7, max(x - 6, 0): x + 7] = color
    return out


def hexc(c):
    return "#%02x%02x%02x" % tuple(int(v * 255 + 0.5) for v in np.clip(c, 0, 1))


def main():
    ref_path, ref_pts_path, our_path, our_pts_path, out_dir = sys.argv[1:6]
    ref, ours = load(ref_path), load(our_path)
    ref_pts, our_pts = json.load(open(ref_pts_path)), json.load(open(our_pts_path))
    os.makedirs(out_dir, exist_ok=True)
    rows, total = [], []
    for name in ref_pts:
        if name not in our_pts:
            continue
        a = sample(ref, *ref_pts[name])
        b = sample(ours, *our_pts[name])
        de = float(np.linalg.norm(srgb_to_lab(a) - srgb_to_lab(b)))
        la, lb = srgb_to_lab(a), srgb_to_lab(b)
        total.append(de)
        rows.append(f"{name:14s} ref {hexc(a)}  biz {hexc(b)}  ΔE {de:5.1f}   ΔL {lb[0]-la[0]:+5.1f}  Δa {lb[1]-la[1]:+5.1f}  Δb {lb[2]-la[2]:+5.1f}")
    print("\n".join(rows))
    print(f"ORTALAMA ΔE: {np.mean(total):.1f}  (≈2 fark edilmez, <6 çok yakın, >12 belirgin fark)")
    # Yan yana görüntü (aynı yüksekliğe ölçeklenmiş, noktalar işaretli).
    h = 900
    def fit(img):
        scale = h / img.shape[0]
        idx_y = (np.arange(h) / scale).astype(int).clip(0, img.shape[0] - 1)
        w = int(img.shape[1] * scale)
        idx_x = (np.arange(w) / scale).astype(int).clip(0, img.shape[1] - 1)
        return img[idx_y][:, idx_x]
    left = fit(mark(ref, list(ref_pts.values())))
    right = fit(mark(ours, list(our_pts.values())))
    save(os.path.join(out_dir, "side_by_side.png"), np.concatenate([left, right], axis=1))


if __name__ == "__main__":
    main()
