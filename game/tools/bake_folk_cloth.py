#!/usr/bin/env python3
"""
Folk'un giysi ölçüsü (Yol Haritası folk-generator; scripts/character/folk.gd): kalabalık modelinin dokusunda giysinin (bölge maskesinde
saç, ten ve göz olmayan piksellerin) doğrusal ortalama parlaklığını ve parlaklık dağılımını ölçer. Folk kişinin giysisini bu ölçüyle
boyar (shaders/character_toon.gdshader, cloth_color): giysinin ortalama pikseli seçilen rengin kendisi olur, kıvrımın gölgesi kalır;
boyanın parlaklık bandı (cloth_band) koyu deri, kuşak ve çizmeyi doğal renginde bırakır.

Önce bölge maskesi pişer (tools/bake_regions.py <glb> --size 1024; kalabalık modellerinin dokusu 1024 pikseldir). Sonra:
  python3 tools/bake_folk_cloth.py assets/characters/crowd_hun_man/crowd_hun_man.glb [...]
Çıktı: her model için {cloth_lum, band [alt, üst], base} satırı (data/character/folk.json «models» kaydına yazılır).
Gerekenler: python3 + numpy, ffmpeg.
"""
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from style_compare import load  # noqa: E402

# Gölgelendiricinin parlaklık ağırlıkları (character_toon.gdshader lum()): doğrusal renkte.
LUMA = np.array([0.299, 0.587, 0.114])


def to_linear(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def measure(glb):
    folder = os.path.dirname(glb)
    model = os.path.splitext(os.path.basename(glb))[0]
    tex = load(os.path.join(folder, model + "_Image_0.jpg")).astype(np.float64)
    if tex.max() > 1.5:
        tex /= 255.0
    mask = load(os.path.join(folder, model + "_regions.png")).astype(np.float64)
    if mask.max() > 1.5:
        mask /= 255.0
    if mask.shape[:2] != tex.shape[:2]:
        raise SystemExit("%s: maske (%s) ile doku (%s) aynı boyda değil" % (model, mask.shape, tex.shape))
    cloth = mask[..., :3].sum(-1) < 0.05
    lin = to_linear(tex[..., :3])
    lum = lin @ LUMA
    values = lum[cloth]
    base = lin[cloth].mean(0) ** (1 / 2.2)
    return {
        "cloth_lum": round(float(values.mean()), 5),
        # Bandın altı koyu deri ve çizmedir (en koyu %20), üstü giysinin orta tonu: arada boya yumuşakça girer.
        "band": [round(float(np.percentile(values, 20)), 5), round(float(np.percentile(values, 45)), 5)],
        "base": "#%02x%02x%02x" % tuple(np.clip(base * 255, 0, 255).astype(int)),
        "share": round(float(cloth.mean()), 4),
    }


def main():
    out = {}
    for glb in sys.argv[1:]:
        out[os.path.splitext(os.path.basename(glb))[0]] = measure(glb)
    print(json.dumps(out, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    sys.exit(main())
