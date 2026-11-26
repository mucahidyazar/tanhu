#!/usr/bin/env python3
"""
Kılık maskesi (K58): Mete'nin Meshy modelinde pelerinin, zırh levhalarının, gömleğin ve kırmızı kuşağın
doku bölgelerini pişirir. Pelerin rengi tek yerden gelir (CharacterOptions.cape_tint); Kışlak Kaftanı da
aynı maskeyle giydirilir (shaders/character_toon.gdshader, dye_mask). Ağ, iskelet ve doku değişmez.

Çıktılar (modelin klasörüne):
  <id>_dye.png    R = pelerin kumaşı (kürk yakası ve saçak dışarıda), G = zırh levhaları, B = gömlek
  <id>_dye2.png   R = kuşak, önlük ve gömleğin kırmızı şeritleri (kırmızıdır ama pelerin değildir)
  <id>_dye.json   bölgelerin dokudaki ortalama rengi ve doğrusal parlaklığı (gölgelendiricinin oranı buna
                  göre kurulur: bölgenin ortalama pikseli seçilen rengin kendisi olur, kıvrımın gölgesi kalır)

Nasıl çalışır?
  1. GLB'den köşe konumu ve UV okunur; üçgenler UV uzayında taranır, her doku pikselinin bağlama pozundaki
     3B yeri bulunur (bake_regions.py ile aynı tarama). Saç, ten ve göz (<id>_regions.png) dışarıda kalır.
  2. Renk ailesi: kırmızı kumaş r / max(g, b) ile (dokuda 1,9–2,1 arası boştur), zırh levhası gri ve soğukça
     (doygunluk düşük, b/r yüksek), gömlek bej.
  3. Kırmızının hangi giysiye ait olduğunu 3B yer söyler: bel çevresindeki halka kuşaktır, karnın önünden
     sarkan şerit önlüktür, gömleğin etek ve kolunun önündeki kırmızı yalnız gömleğin yüzeyindedir (kolun
     arkası ve üstü pelerinin omuzdan sarkan kanadıdır); kalan kırmızı pelerinindir (sırtta ve yanlarda gövdeden
     uzak sarkan katman, omuz örtüsü). Bölgeler modele özgüdür (ZONES); yeni model gelince ölçülüp yazılır.
  4. Kumaştaki kir lekeleri ve kürke karışan kenar pikselleri (kırmızımsı) pelerine katılır (GROW). Maske
     kenarları yumuşatılır ve UV adalarının dışındaki boş piksellere taşırılır (dikiş izi kalmasın); komşu adaya
     ve saçın, tenin, gözün boşluk payına girmez.

Kullanım:
  python3 tools/bake_dye_mask.py assets/characters/mete/mete.glb [--size 2048] [--out-dir klasör]
Gerekenler: python3 + numpy, ffmpeg.
"""
import argparse
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bake_regions import accessor, blur, dilate, rasterize, read_glb, write_png  # noqa: E402
from style_compare import load  # noqa: E402

SIZE = 2048
DILATE = 3
# Kırmızı bölgenin kırmızımsı komşulara büyüme adımı (piksel).
GROW = 3
# Gölgelendiricinin parlaklık ağırlıkları (character_toon.gdshader lum()): doğrusal renkte.
LUMA = np.array([0.299, 0.587, 0.114])
# Kırmızı kumaş: r / max(g, b). Dokuda 1,9–2,1 arası neredeyse boştur (deri 1,4–1,7, kumaş 2,4–3,0).
RED_LO, RED_HI = 1.85, 2.2

# Modele özgü bölgeler (bağlama pozu, metre; +z ön, y yukarı). Mete'nin gövdesi z ≈ +0,085 çevresindedir;
# pelerin sırtta z < −0,1'de, yanlarda |x| > 0,25'te sarkar.
ZONES = {
    "mete": {
        # Bel kuşağı: y aralığı ve gövdenin elipsi (x yarı eksen, z merkezi, z yarı eksen).
        "sash": {"y": (0.975, 1.205), "ellipse": (0.215, 0.095, 0.16)},
        # Önlük: kuşaktan sarkan şerit.
        "apron": {"y": (0.40, 1.0), "z_min": 0.08, "x_max": 0.2},
        # Gömleğin eteği ve şeridi: bacakların çevresi.
        "skirt": {"y": (0.48, 1.0), "ellipse": (0.275, 0.08, 0.2)},
        # Gömleğin kolları (pelerinin altında, üst kolda): |x| aralığı, y aralığı, kol ekseninden uzaklık.
        "sleeve": {"x": (0.24, 0.5), "y": (1.22, 1.52), "axis_y": 1.385, "axis_z": 0.045, "radius": 0.095, "front": -0.01, "top": 0.06},
        # Zırh: gövde ve etek panelleri (pelerin ve kollar dışarıda).
        "armor": {"y": (0.68, 1.43), "ellipse": (0.25, 0.08, 0.215)},
        # Başın ve boynun kırmızıları pelerin değildir (pelerinin yakası omuzlara bağlıdır): kafa ve boyun kemiğine bu paydan
        # çok bağlı kırmızı, y_min'in altında kaftanın yakasıdır (kuşakla aynı yün kahvesine döner), üstünde saçın topuz bağı
        # ve kurdelesidir (kendi kızılında kalır).
        "head": {"weight": 0.4, "y_min": 1.66},
    },
}


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def to_linear(c):
    c = np.asarray(c, dtype=np.float64)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def to_hex(c):
    c = np.clip(np.asarray(c, dtype=np.float64), 0.0, 1.0)
    return "#%02x%02x%02x" % tuple(int(round(v * 255)) for v in c)


def in_ellipse(x, z, spec):
    ax, cz, az = spec
    return (x / ax) ** 2 + ((z - cz) / az) ** 2 <= 1.0


def in_range(v, r):
    return (v >= r[0]) & (v <= r[1])


def hsv(c):
    mx = c.max(1)
    mn = c.min(1)
    d = mx - mn + 1e-9
    r, g, b = c[:, 0], c[:, 1], c[:, 2]
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60.0
    s = np.where(mx > 1e-3, (mx - mn) / np.maximum(mx, 1e-3), 0.0)
    return h, s, mx


def classify(col, p3, zones, head_weight=None):
    """Her doku pikselinin bölge ağırlıkları: cape, plate, tunic, trim (0..1). head_weight: pikselin kafa ve boyun
    kemiklerine bağlılık payı (0..1; yoksa yalnız yükseklik)."""
    x, y, z = p3[:, 0], p3[:, 1], p3[:, 2]
    redness = col[:, 0] / np.maximum(np.maximum(col[:, 1], col[:, 2]), 0.002)
    red_w = smoothstep(RED_LO, RED_HI, redness)
    h, s, v = hsv(col)
    br = col[:, 2] / np.maximum(col[:, 0], 0.002)

    sash = in_range(y, zones["sash"]["y"]) & in_ellipse(x, z, zones["sash"]["ellipse"])
    ap = zones["apron"]
    apron = in_range(y, ap["y"]) & (z > ap["z_min"]) & (np.abs(x) < ap["x_max"])
    skirt = in_range(y, zones["skirt"]["y"]) & in_ellipse(x, z, zones["skirt"]["ellipse"])
    sl = zones["sleeve"]
    # Kolun önü ve altı gömlektir; arkası ve üstü pelerinin omuzdan sarkan kanadıdır (aynı kırmızı).
    sleeve = in_range(np.abs(x), sl["x"]) & in_range(y, sl["y"]) & (np.hypot(y - sl["axis_y"], z - sl["axis_z"]) < sl["radius"]) \
        & (y - sl["axis_y"] < sl["top"])
    sleeve_front = sleeve & (z - sl["axis_z"] > sl["front"])
    armor = in_range(y, zones["armor"]["y"]) & in_ellipse(x, z, zones["armor"]["ellipse"])

    body_red = sash | apron | skirt | sleeve_front
    hd = zones["head"]
    hair = y > hd["y_min"]
    collar = (head_weight > hd["weight"]) & ~hair if head_weight is not None else np.zeros_like(hair)
    cape = red_w * (~body_red) * (~hair) * (~collar)
    trim = red_w * (body_red | collar) * (~hair)
    # Zırh levhası: gri, soğukça, koyu (deri bağlar ve kahve kenarlar dışarıda).
    gray = smoothstep(0.3, 0.17, s) * smoothstep(0.72, 0.84, br) * smoothstep(0.17, 0.23, v) * smoothstep(0.6, 0.48, v)
    plate = gray * armor * (1.0 - red_w)
    # Gömlek: açık bej (kürk yakası aynı renktedir, ama gövdenin üstünde değil pelerinin kenarındadır).
    beige = smoothstep(14.0, 20.0, h) * smoothstep(44.0, 38.0, h) * smoothstep(0.18, 0.26, s) * smoothstep(0.62, 0.55, s) \
        * smoothstep(0.45, 0.55, v) * smoothstep(1.75, 1.6, redness)
    tunic = beige * (skirt | sleeve) * (~sash)
    return {"cape": cape, "plate": plate, "tunic": tunic, "trim": trim}


def grow_into(layer, candidate, steps):
    """Bölgeyi komşu adaylara adım adım büyütür (UV uzayında 1 piksel): kırmızı kumaştaki kir lekeleri ve
    kumaşın kürke ya da deriye karıştığı kenar pikselleri (rengi kırmızıyla bej arasında) bölgeye katılır."""
    out = layer.copy()
    for _ in range(steps):
        grown = out.copy()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            grown = np.maximum(grown, np.roll(np.roll(out, dy, axis=0), dx, axis=1))
        out = np.where(candidate, grown, out)
    return out


# Kafa ve boyun kemikleri (Meshy iskeleti): başın kırmızıları (topuz bağı, kurdele) bunlara bağlıdır.
HEAD_JOINTS = {"head", "head_end", "headfront", "neck"}


def texel_head_weight(gltf, binary, prim, tri, w):
    """Her doku pikselinin kafa ve boyun kemiklerine bağlılık payı (0..1): köşe ağırlıklarının taramadaki karışımı."""
    joints = accessor(gltf, binary, prim["attributes"]["JOINTS_0"]).astype(np.int64)
    weights = accessor(gltf, binary, prim["attributes"]["WEIGHTS_0"]).astype(np.float64)
    names = [gltf["nodes"][j].get("name", "").lower() for j in gltf["skins"][0]["joints"]]
    is_head = np.array([n in HEAD_JOINTS for n in names])
    vertex_head = (weights * is_head[joints]).sum(1)
    return (vertex_head[tri] * w).sum(1)


def layer_image(values, ys, xs, size, covered, candidate=None, forbid=None):
    layer = np.zeros((size, size), dtype=np.float32)
    np.maximum.at(layer, (ys, xs), values.astype(np.float32))
    if candidate is not None:
        layer = grow_into(layer, candidate, GROW)
    # Kenarı yumuşat (yalnız bölgenin kendi pikselleri ve boşluklar), sonra adaların dışına taşır. Saç, ten ve gözün
    # boşluğa taşan payına (forbid; bake_regions.py'nin maskesi) girilmez: iki ada yan yanaysa boşluk onundur.
    soft = blur(layer)
    layer = np.where(covered, np.maximum(layer, soft * (layer > 0)), soft)
    free = ~covered if forbid is None else (~covered & ~forbid)
    if forbid is not None:
        layer = np.where(forbid & ~covered, 0.0, layer)
    return np.clip(dilate(layer, DILATE, free=free), 0.0, 1.0)


def region_base(col, weight):
    """Bölgenin ağırlıklı ortalama rengi (sRGB) ve doğrusal parlaklığının ortalaması."""
    w = weight[:, None]
    total = float(weight.sum())
    if total < 1.0:
        return None
    mean = (col * w).sum(0) / total
    lum = float(((to_linear(col) @ LUMA) * weight).sum() / total)
    return mean, lum


def bake(path, size=SIZE, out_dir=None):
    model_id = os.path.splitext(os.path.basename(path))[0]
    if model_id not in ZONES:
        raise SystemExit("Bu model için bölge tanımı yok: %s (ZONES)" % model_id)
    gltf, binary = read_glb(path)
    prim = gltf["meshes"][0]["primitives"][0]
    pos = accessor(gltf, binary, prim["attributes"]["POSITION"]).astype(np.float64)
    uv = accessor(gltf, binary, prim["attributes"]["TEXCOORD_0"]).astype(np.float64)
    idx = accessor(gltf, binary, prim["indices"]).reshape(-1, 3).astype(np.int64)
    folder = os.path.dirname(path)
    tex = load(os.path.join(folder, model_id + "_Image_0.jpg"))
    regions = load(os.path.join(folder, model_id + "_regions.png"))
    ys, xs, ids, w = rasterize(uv, idx, size)
    p3 = (pos[idx[ids]] * w[..., None]).sum(1)
    head_weight = texel_head_weight(gltf, binary, prim, idx[ids], w)

    def sample(img):
        n = img.shape[0]
        return img[((ys + 0.5) / size * n).astype(int).clip(0, n - 1), ((xs + 0.5) / size * n).astype(int).clip(0, n - 1)]

    col = sample(tex).astype(np.float64)
    body = sample(regions).max(1) > 0.5
    parts = classify(col, p3, ZONES[model_id], head_weight)
    for key in parts:
        parts[key] = parts[key] * (~body)

    covered = np.zeros((size, size), dtype=bool)
    covered[ys, xs] = True
    # Kırmızımsı ama eşiğin altındaki pikseller (kir, gölge, kürkle karışan kenar): ton kırmızıda, deri ve kürk değil.
    h, s, v = hsv(col)
    redness = col[:, 0] / np.maximum(np.maximum(col[:, 1], col[:, 2]), 0.002)
    hd = ZONES[model_id]["head"]
    on_head = (p3[:, 1] > hd["y_min"]) | (head_weight > hd["weight"])
    reddish = ((h < 18.0) | (h > 335.0)) & (redness > 1.3) & (s > 0.25) & (v < 0.65) & (~body) & (~on_head)
    candidate = np.zeros((size, size), dtype=bool)
    candidate[ys[reddish], xs[reddish]] = True
    n = regions.shape[0]
    grid = ((np.arange(size) + 0.5) / size * n).astype(int).clip(0, n - 1)
    forbid = regions[grid][:, grid].max(-1) > 0.5
    mask = np.zeros((size, size, 3), dtype=np.float32)
    mask2 = np.zeros((size, size, 3), dtype=np.float32)
    for channel, key in enumerate(("cape", "plate", "tunic")):
        mask[:, :, channel] = layer_image(parts[key], ys, xs, size, covered, candidate if key == "cape" else None, forbid)
    mask2[:, :, 0] = layer_image(parts["trim"], ys, xs, size, covered, candidate, forbid)
    # Pelerin ve kuşak aynı adaylara büyür: çakıştıkları yerde pelerin kalır (kuşak bölgesi zaten ayrıdır).
    mask2[:, :, 0] = np.minimum(mask2[:, :, 0], 1.0 - mask[:, :, 0])
    base = os.path.join(out_dir or folder, model_id)
    write_png(base + "_dye.png", mask)
    write_png(base + "_dye2.png", mask2)

    info = {"note": "tools/bake_dye_mask.py ile üretildi (K58); _dye.png R=pelerin G=zırh levhası B=gömlek; _dye2.png R=kuşak, önlük ve şeritler",
            "size": size}
    for key in ("cape", "plate", "tunic", "trim"):
        # Taban rengi yalnız bölgenin kesin piksellerinden (yumuşak kenarlar ortalamayı kaydırmasın).
        strong = parts[key] > 0.9
        found = region_base(col[strong], np.ones(int(strong.sum())))
        if found is None:
            continue
        mean, lum = found
        info[key] = {"base": to_hex(mean), "lum": round(lum, 5), "pixels": int(strong.sum())}
    with open(base + "_dye.json", "w", encoding="utf-8") as f:
        json.dump(info, f, ensure_ascii=False, indent=2)
        f.write("\n")
    return info


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("glb")
    ap.add_argument("--size", type=int, default=SIZE)
    ap.add_argument("--out-dir", default=None, help="çıktı klasörü (varsayılan: modelin klasörü)")
    args = ap.parse_args()
    info = bake(args.glb, args.size, args.out_dir)
    print(json.dumps(info, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
