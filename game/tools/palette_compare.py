#!/usr/bin/env python3
"""
Palet karşılaştırma aracı: iki görüntüdeki malzeme sınıflarının (çimen, toprak, kaya, yosun...)
ton dağılımlarını karşılaştırır. Nokta seçmeye gerek yoktur; pikseller renklerine göre sınıflanır.

Her sınıf için %10 / %50 / %90 aydınlık yüzdeliklerindeki ortalama renk bulunur ve CIE Lab uzayında
fark (ΔE) yazdırılır. Böylece "koyu tonlar, orta tonlar, açık tonlar" ayrı ayrı ayarlanabilir.

Kullanım:
  python3 tools/palette_compare.py ref.png ours.png [--ref-crop=x0,y0,x1,y1] [--our-crop=x0,y0,x1,y1] [--out=karşılaştırma.png]
Kırpma, yazı ve arayüz gibi alanları dışarıda bırakmak içindir.

Pelerinin okunurluğu (K58; sanat-animasyon.md öneri 4; fark OKLab'dadır, 0,02 görünür bir farktır):
  python3 tools/palette_compare.py --cape [--dye=lake_blue|all] [--json=sonuç.json] [--stops=durak_dosyası.json]
      P1: altı ışık durağında (data/character/cape_light_stops.json v3: oyunun ışık durakları, data/time/light_stops.json'dan
      kampın ölçüm dakikalarında çözülmüş değerler; scenes/dev/cape_lineup.tscn --export-stops yazar) boyanın (data/character/capes.json) kalabalık
      paletinden en küçük farkı. Palet var olan kalabalık modellerinin (crowd_hun_*) dokusundan ölçülür: modelin
      kullandığı doku pikselleri OKLab'da öbeklenir, %1'den büyük öbekler kalır. Işık: albedo × (güneş ya da ay
      × enerji + ortam × enerji) × pozlama, doğrusal renkte (düz albedo hesabı; boyalı süzgeç ve ton eşleme P4'tedir).
      Ölçüt: en kötü durak ≥0,05, öğle ≥0,08. Ek bilgi: P2 renk körlüğü (Machado 2009, deutan ve protan) ≥0,05;
      P3 zemin (karda WCAG ≥3:1, ot ve toprakta ≥0,10); kalabalık paletinin soğuk bantta kalan payı (yasak, 0 olmalı).
  python3 tools/palette_compare.py --blob kare.png anahtar.png [--scale=8] [--ring=3] [--out=görsel.png]
      P4: iki kare aynı pozdadır; anahtar karesinde pelerin başka bir renge boyanmıştır, iki karenin farkı pelerinin
      lekesidir (scenes/dev/cape_lineup.tscn --key). Kare 1/scale'e iner (kutu süzgeci); lekenin hücreleri ile çevresindeki
      halkanın (ring hücre) ortalama rengi arasındaki fark ölçülür. Ölçüt ≥0,06.
"""
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from style_compare import load, save, srgb_to_lab, hexc  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAPES_JSON = os.path.join(ROOT, "data", "character", "capes.json")
STOPS_JSON = os.path.join(ROOT, "data", "character", "cape_light_stops.json")
CROWD_MODELS = ("crowd_hun_man", "crowd_hun_rider", "crowd_hun_woman")
# Eski varsayılan (K58: en kötü ışıkta ΔE 0,034): karşılaştırma için yazdırılır.
OLD_DEFAULT = "#3e5f6b"
# Zemin renkleri (sanat-animasyon.md §10, yaklaşık): kar, ot, toprak.
GROUND = {"kar": "#e2ddd6", "ot": "#8fa058", "toprak": "#7a6248"}
# Machado 2009, şiddet 1,0 (doğrusal RGB).
CVD = {
    "deutan": np.array([[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]]),
    "protan": np.array([[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]]),
}
P1_WORST, P1_NOON, P2_MIN, P3_SNOW, P3_GROUND, P4_MIN = 0.05, 0.08, 0.05, 3.0, 0.10, 0.06

# Sınıflar: HSV aralıkları (ton derece, doygunluk 0..1, parlaklık 0..1).
CLASSES = {
    "çimen": dict(h=(68, 150), s=(0.3, 1.0), v=(0.18, 0.95)),
    "toprak": dict(h=(18, 40), s=(0.28, 0.7), v=(0.35, 0.97)),
    "kaya": dict(h=(40, 62), s=(0.05, 0.5), v=(0.72, 1.0)),
    "yosun": dict(h=(46, 68), s=(0.5, 1.0), v=(0.45, 0.95)),
}
PERCENTILES = (10, 50, 90)


def to_hsv(img):
    r, g, b = img[..., 0], img[..., 1], img[..., 2]
    mx, mn = img.max(-1), img.min(-1)
    d = mx - mn + 1e-9
    h = np.where(mx == r, (g - b) / d % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60.0
    s = np.where(mx > 0, d / (mx + 1e-9), 0)
    return h, s, mx


def class_masks(img):
    h, s, v = to_hsv(img)
    out = {}
    for name, c in CLASSES.items():
        out[name] = (h >= c["h"][0]) & (h < c["h"][1]) & (s >= c["s"][0]) & (s <= c["s"][1]) & (v >= c["v"][0]) & (v <= c["v"][1])
    return out


def stats(img, mask):
    px = img[mask]
    if len(px) < 50:
        return None
    lab = srgb_to_lab(px)
    order = np.argsort(lab[:, 0])
    res = []
    for p in PERCENTILES:
        i = int(len(order) * p / 100)
        lo, hi = max(i - len(order) // 40, 0), min(i + len(order) // 40 + 1, len(order))
        res.append(px[order[lo:hi]].mean(0))
    return res, len(px)


def crop(img, arg):
    if not arg:
        return img
    x0, y0, x1, y1 = map(int, arg.split(","))
    return img[y0:y1, x0:x1]


# --- OKLab ve pelerin ölçütü (K58) ---------------------------------------------------------

def hex_rgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


def to_linear(c):
    c = np.asarray(c, dtype=np.float64)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def to_srgb(c):
    c = np.clip(np.asarray(c, dtype=np.float64), 0.0, 1.0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1.0 / 2.4) - 0.055)


def oklab_linear(lin):
    """Doğrusal RGB (…, 3) → OKLab (…, 3) (Björn Ottosson; scripts/character/ok_color.gd ile aynı katsayılar)."""
    m1 = np.array([[0.4122214708, 0.5363325363, 0.0514459929], [0.2119034982, 0.6806995451, 0.1073969566],
                   [0.0883024619, 0.2817188376, 0.6299787005]])
    m2 = np.array([[0.2104542553, 0.7936177850, -0.0040720468], [1.9779984951, -2.4285922050, 0.4505937099],
                   [0.0259040371, 0.7827717662, -0.8086757660]])
    lms = np.cbrt(np.asarray(lin, dtype=np.float64) @ m1.T)
    return lms @ m2.T


def oklch(lab):
    lab = np.asarray(lab)
    return np.stack([lab[..., 0], np.hypot(lab[..., 1], lab[..., 2]), np.degrees(np.arctan2(lab[..., 2], lab[..., 1])) % 360.0], -1)


def rel_luminance(lin):
    return float(np.asarray(lin) @ np.array([0.2126, 0.7152, 0.0722]))


def read_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def res_path(path):
    return os.path.join(ROOT, path[len("res://"):]) if path.startswith("res://") else path


def light_stops(path=None):
    """Durakların aydınlatması: [(id, ad, ışık_doğrusal (3), ortam_doğrusal (3), pozlama, k20)]. v3'te değerler oyunun ışık
    duraklarından çözülmüştür (ışığın gücü × k; minute, light_stop alanları bilgi içindir)."""
    out = []
    for stop in read_json(path or STOPS_JSON)["stops"]:
        sample = stop["sample"]
        if isinstance(sample, str):
            sample = read_json(res_path(stop["file"]))["samples"][sample]
        light = to_linear(np.array(sample["light_color"][:3])) * float(sample.get("light_energy", 1.0))
        amb_color = to_linear(np.array(sample.get("ambient_color", [0, 0, 0])[:3]))
        sky = sample.get("sky", {}).get("mid")
        mix = float(sample.get("ambient_sky", 0.0)) if sky else 0.0
        if sky:
            amb_color = amb_color * (1.0 - mix) + to_linear(np.array(sky[:3])) * mix
        ambient = amb_color * float(sample.get("ambient_energy", 0.0))
        fire = stop.get("fire")
        if fire:
            # Godot'nun nokta ışığı sönümü (omni_attenuation 1): (1 − (d/r)^4)^2 / d.
            d, r = float(fire["distance"]), float(fire["range"])
            att = max(1.0 - (d / r) ** 4, 0.0) ** 2 / max(d, 1e-4)
            light = light + to_linear(np.array(fire["color"][:3])) * float(fire["energy"]) * att
        out.append((stop["id"], stop["name"], light, ambient, float(sample.get("exposure", 1.0)), stop.get("k20", "")))
    return out


def lit(lin_albedo, stop):
    _, _, light, ambient, exposure, _ = stop
    return np.clip(np.asarray(lin_albedo) * (light + ambient) * exposure, 0.0, 1.0)


def crowd_palette(models=CROWD_MODELS, k=12, size=512, min_share=0.01):
    """Kalabalık modellerinin dokusunda modelin kullandığı piksellerin OKLab öbekleri:
    [(model, doğrusal renk, pay)] ve modelin soğuk bantta kalan piksel payı {model: pay}."""
    from bake_regions import accessor, rasterize, read_glb
    band = read_json(CAPES_JSON)["cold_band"]
    palette, cold = [], {}
    for model in models:
        folder = os.path.join(ROOT, "assets", "characters", model)
        gltf, binary = read_glb(os.path.join(folder, model + ".glb"))
        prim = gltf["meshes"][0]["primitives"][0]
        uv = accessor(gltf, binary, prim["attributes"]["TEXCOORD_0"]).astype(np.float64)
        idx = accessor(gltf, binary, prim["indices"]).reshape(-1, 3).astype(np.int64)
        tex = load(os.path.join(folder, model + "_Image_0.jpg"))
        ys, xs, _, _ = rasterize(uv, idx, size)
        used = np.zeros((size, size), dtype=bool)
        used[ys, xs] = True
        n = tex.shape[0]
        py, px = np.nonzero(used)
        col = tex[((py + 0.5) / size * n).astype(int), ((px + 0.5) / size * n).astype(int)].astype(np.float64)
        lin = to_linear(col)
        lab = oklab_linear(lin)
        lch = oklch(lab)
        cold[model] = float(np.mean((lch[:, 1] >= band["chroma_min"]) & (lch[:, 2] >= band["hue_min"]) & (lch[:, 2] <= band["hue_max"])))
        rng = np.random.default_rng(7)
        cent = lab[rng.choice(len(lab), k, replace=False)]
        for _ in range(40):
            assign = ((lab[:, None, :] - cent[None]) ** 2).sum(-1).argmin(1)
            for j in range(k):
                if (assign == j).any():
                    cent[j] = lab[assign == j].mean(0)
        for j in range(k):
            share = float(np.mean(assign == j))
            if share >= min_share:
                palette.append((model, lin[assign == j].mean(0), share))
    return palette, cold


def cape_report(dye_ids=None, stops_path=None):
    capes = read_json(CAPES_JSON)
    dyes = [(d["id"], d["name"], d["color"]) for d in capes["dyes"]]
    if dye_ids:
        dyes = [d for d in dyes if d[0] in dye_ids]
    dyes.append(("old_default", "Eski varsayılan", OLD_DEFAULT))
    stops_file = read_json(stops_path or STOPS_JSON)
    if stops_file.get("version", 1) >= 3:
        print("Durak dosyası v%d: %s; ölçüm dakikaları %s" % (stops_file["version"], stops_file.get("light_stops", ""),
              ", ".join("%s %s" % (s["id"], s.get("minute", "")) for s in stops_file["stops"])))
    stops = light_stops(stops_path)
    palette, cold = crowd_palette()
    result = {"stops": [s[0] for s in stops], "crowd_colors": len(palette), "crowd_cold_share": cold, "dyes": {}}
    print("Kalabalık paleti: %d renk (%s); soğuk bantta kalan piksel payı: %s" % (
        len(palette), ", ".join(CROWD_MODELS), ", ".join("%s %%%.2f" % (m, v * 100) for m, v in cold.items())))
    print("Işık durakları: " + ", ".join("%s (%s)" % (s[0], s[5]) for s in stops))
    header = "%-16s %-8s " % ("Boya", "Renk") + " ".join("%13s" % s[0][:13] for s in stops) + "  en kötü  P1   P2(d/p)      P3 kar/ot/toprak"
    print(header)
    for dye_id, name, hexs in dyes:
        lin = to_linear(hex_rgb(hexs))
        per_stop = []
        nearest = []
        for stop in stops:
            a = oklab_linear(lit(lin, stop))
            best, who = 9.0, None
            for model, c_lin, share in palette:
                de = float(np.linalg.norm(a - oklab_linear(lit(c_lin, stop))))
                if de < best:
                    best, who = de, "%s %s" % (model.replace("crowd_hun_", ""), hexc(to_srgb(c_lin)))
            per_stop.append(best)
            nearest.append(who)
        noon = per_stop[[s[5] for s in stops].index("noon")] if "noon" in [s[5] for s in stops] else per_stop[-1]
        worst = min(per_stop)
        worst_stop = stops[int(np.argmin(per_stop))][0]
        cvd = {}
        for kind, m in CVD.items():
            a = oklab_linear(np.clip(lin @ m.T, 0, 1))
            cvd[kind] = min(float(np.linalg.norm(a - oklab_linear(np.clip(c @ m.T, 0, 1)))) for _, c, _ in palette)
        snow = to_linear(hex_rgb(GROUND["kar"]))
        contrast = (rel_luminance(snow) + 0.05) / (rel_luminance(lin) + 0.05)
        grass = float(np.linalg.norm(oklab_linear(lin) - oklab_linear(to_linear(hex_rgb(GROUND["ot"])))))
        soil = float(np.linalg.norm(oklab_linear(lin) - oklab_linear(to_linear(hex_rgb(GROUND["toprak"])))))
        p1 = worst >= P1_WORST and noon >= P1_NOON
        p2 = min(cvd.values()) >= P2_MIN
        p3 = contrast >= P3_SNOW and grass >= P3_GROUND and soil >= P3_GROUND
        print("%-16s %-8s " % (name[:16], hexs) + " ".join("%13.3f" % v for v in per_stop)
              + "  %.3f %s  %.3f/%.3f %s  %.2f/%.3f/%.3f %s" % (worst, "geçer" if p1 else "GEÇMEZ", cvd["deutan"], cvd["protan"],
                                                                "geçer" if p2 else "geçmez", contrast, grass, soil, "geçer" if p3 else "geçmez"))
        result["dyes"][dye_id] = {"name": name, "color": hexs, "per_stop": dict(zip([s[0] for s in stops], per_stop)),
                                  "nearest": dict(zip([s[0] for s in stops], nearest)), "worst": worst, "worst_stop": worst_stop,
                                  "noon": noon, "p1": p1, "cvd": cvd, "p2": p2, "snow_contrast": contrast, "grass": grass,
                                  "soil": soil, "p3": p3}
    return result


def blob_report(frame_path, key_path, scale=8, ring=3, threshold=0.08, out=None):
    """P4: kare 1/scale'e iner; anahtar karesiyle farkı pelerinin lekesidir. Döner: sözlük."""
    a = load(frame_path).astype(np.float64)
    b = load(key_path).astype(np.float64)
    if a.shape != b.shape:
        raise SystemExit("Karelerin boyu farklı: %s %s" % (a.shape, b.shape))
    mask = (np.abs(a - b).max(-1) > threshold).astype(np.float64)
    h, w = (a.shape[0] // scale) * scale, (a.shape[1] // scale) * scale
    lin = to_linear(a[:h, :w]).reshape(h // scale, scale, w // scale, scale, 3).mean((1, 3))
    frac = mask[:h, :w].reshape(h // scale, scale, w // scale, scale).mean((1, 3))
    blob = frac >= 0.5
    if not blob.any():
        return {"frame": frame_path, "blob_cells": 0, "pixels": int(mask.sum()), "delta_e": None, "pass": False}
    near = np.zeros_like(blob)
    for dy in range(-ring, ring + 1):
        for dx in range(-ring, ring + 1):
            near |= np.roll(np.roll(blob, dy, 0), dx, 1)
    halo = near & ~blob & (frac < 0.1)
    cape = oklab_linear(lin[blob].mean(0))
    around = oklab_linear(lin[halo].mean(0))
    de = float(np.linalg.norm(cape - around))
    ys, xs = np.nonzero(mask)
    result = {"frame": os.path.basename(frame_path), "pixels": int(mask.sum()),
              "bbox_px": [int(xs.max() - xs.min() + 1), int(ys.max() - ys.min() + 1)], "blob_cells": int(blob.sum()),
              "ring_cells": int(halo.sum()), "cape": hexc(to_srgb(lin[blob].mean(0))), "around": hexc(to_srgb(lin[halo].mean(0))),
              "delta_e": de, "pass": de >= P4_MIN}
    if out:
        small = to_srgb(lin)
        vis = small.copy()
        vis[halo] = vis[halo] * 0.5 + np.array([1.0, 0.8, 0.0]) * 0.5
        vis[blob] = vis[blob] * 0.5 + np.array([1.0, 0.0, 1.0]) * 0.5
        big = np.repeat(np.repeat(np.concatenate([small, vis], 1), 4, 0), 4, 1)
        save(out, big)
    return result


def main():
    if "--cape" in sys.argv[1:]:
        opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
        dye = opts.get("dye", "all")
        result = cape_report(None if dye == "all" else dye.split(","), opts.get("stops"))
        if "json" in opts:
            with open(opts["json"], "w", encoding="utf-8") as f:
                json.dump(result, f, ensure_ascii=False, indent=1)
        return
    if "--blob" in sys.argv[1:]:
        args = [a for a in sys.argv[1:] if not a.startswith("--")]
        opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
        r = blob_report(args[0], args[1], int(opts.get("scale", 8)), int(opts.get("ring", 3)), out=opts.get("out"))
        print(json.dumps(r, ensure_ascii=False))
        return
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    ref, ours = crop(load(args[0]), opts.get("ref-crop")), crop(load(args[1]), opts.get("our-crop"))
    mr, mo = class_masks(ref), class_masks(ours)
    total = []
    for name in CLASSES:
        a, b = stats(ref, mr[name]), stats(ours, mo[name])
        if a is None or b is None:
            print(f"{name:7s}: {'referansta' if a is None else 'bizde'} yok")
            continue
        fa, fb = a[1] / mr[name].size * 100, b[1] / mo[name].size * 100
        line = [f"{name:7s} alan ref %{fa:4.1f} biz %{fb:4.1f} |"]
        for p, ca, cb in zip(PERCENTILES, a[0], b[0]):
            la, lb = srgb_to_lab(ca), srgb_to_lab(cb)
            de = float(np.linalg.norm(la - lb))
            total.append(de)
            line.append(f" p{p}: {hexc(ca)}→{hexc(cb)} ΔE{de:4.1f} (ΔL{lb[0]-la[0]:+4.0f} Δa{lb[1]-la[1]:+4.0f} Δb{lb[2]-la[2]:+4.0f})")
        print("".join(line))
    if total:
        print(f"ORTALAMA ΔE: {np.mean(total):.1f}")
    if "out" in opts:
        # Sınıf maskelerini renkli göster (hangi piksellerin sayıldığını kontrol etmek için).
        colors = {"çimen": (0.2, 0.8, 0.2), "toprak": (0.8, 0.5, 0.2), "kaya": (1.0, 1.0, 0.8), "yosun": (0.8, 0.8, 0.0)}
        def overlay(img, masks):
            o = img * 0.25
            for k, m in masks.items():
                o[m] = colors[k]
            return o
        h = 600
        def fit(img):
            sc = h / img.shape[0]
            iy = (np.arange(h) / sc).astype(int).clip(0, img.shape[0] - 1)
            ix = (np.arange(int(img.shape[1] * sc)) / sc).astype(int).clip(0, img.shape[1] - 1)
            return img[iy][:, ix]
        save(opts["out"], np.concatenate([fit(overlay(ref, mr)), fit(overlay(ours, mo))], axis=1))


if __name__ == "__main__":
    main()
