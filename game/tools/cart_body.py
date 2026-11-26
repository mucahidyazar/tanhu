#!/usr/bin/env python3
"""
Araba gövdesi hattı: Meshy'nin tekerleksiz araba gövdesini (assets/_meshy_raw/<id>/<id>.glb) oyun uzayına getirir ve kodla çizilen
tekerleğin oturacağı ölçüleri yazar. Kredi harcamaz, Meshy'yi çağırmaz. Tekerlek ve dingil ucu kodun işidir (dönerler; DepartCart'ın
tekerleği: scripts/maps/depart_cart.gd WHEEL_RADIUS, WHEEL_TRACK); gövde tek ağdır ve dönmez.

Hat:
  1. Dönüş: okların ucu +z'ye (oyun uzayı: y yukarı, +z ön, +x arabanın solu).
  2. Ölçek: dingil uçları (gövdenin altında yana en çok çıkan köşeler) tekerleğin dış yüzüne gelir: tekerlek merkezi iki yanda
     wheel_track'te, dingil ucu ondan stub_out kadar dışarıda (göbek onu örter).
  3. Yer: başlangıç dingil ortasının altındaki zemindir; dingil wheel_radius yüksekliğindedir (tekerlek zemine değer).
  4. Doku tools/glb_prepare.py ile satırın doku sınıfına iner (8K ham kopya _meshy_raw'da kalır).
  5. <id>.json: tekerlek yarıçapı ve izi, dingil yüksekliği, kasa kutusu ve üstü, örtünün tepesi, okların uçları ve çeken atın yeri,
     gövdenin en alçak noktası. Godot sınaması: tests/unit/test_cart_felt_asset.gd.

Kullanım (game/ klasöründe): python3 tools/cart_body.py cart_felt
"""
import json
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import glb_prepare  # noqa: E402

# Tarif: ham Meshy biriminde ölçü bantları, oyun metresinde hedefler. Tekerlek DepartCart'ınkidir (yarıçap 0,72, iz 0,92).
RECIPES = {
    "cart_felt": {
        "doc": "Keçe araba gövdesi (E19 yol denemesi): ham ağda okların ucu +x'tedir. Dingilin iki ucu ham ağda 9 cm ileri geri kaymıştır "
               "(Meshy); tekerlek iki uçta aynı z'de, ortalamada durur, göbek ucu örter.",
        "yaw_deg": -90.0,
        "wheel_radius": 0.72,
        "wheel_track": 0.92,
        "stub_out": 0.054,
        "axle_band_y": [-0.40, -0.29],
        "bed_band_y": [-0.12, -0.02],
        "deskew": {"y": [-0.17, 0.2], "reach": [0.14, 0.22]},
        "shaft_min_z": 1.7,
        "hitch_gap": 0.3,
    },
}


def read_mesh(doc, binary):
    prim = doc["meshes"][0]["primitives"][0]
    attrs = prim["attributes"]

    def acc(index):
        a = doc["accessors"][index]
        view = doc["bufferViews"][a["bufferView"]]
        num = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
        dtype = {5126: np.float32, 5125: np.uint32, 5123: np.uint16}[a["componentType"]]
        offset = view.get("byteOffset", 0) + a.get("byteOffset", 0)
        return np.frombuffer(binary, dtype, a["count"] * num, offset).reshape(a["count"], num).copy(), a, view
    return acc(attrs["POSITION"]), acc(attrs["NORMAL"]), acc(prim["indices"])


def write_vec3(binary, accessor, view, values):
    """VEC3 float erişicisini yerinde yazar, min/max günceller (aralıklı görünüm desteklenmez)."""
    if view.get("byteStride", 12) != 12:
        sys.exit("aralıklı (byteStride) köşe görünümü desteklenmiyor")
    offset = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    data = values.astype(np.float32).tobytes()
    binary[offset: offset + len(data)] = data
    if "min" in accessor:
        accessor["min"] = [float(v) for v in values.min(0)]
        accessor["max"] = [float(v) for v in values.max(0)]


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in RECIPES:
        sys.exit(__doc__)
    rid = sys.argv[1]
    rc = RECIPES[rid]
    plan = glb_prepare.load_plan()
    row = glb_prepare.asset_by_id(plan, rid)
    raw_path = os.path.join(GAME, "assets", "_meshy_raw", rid, rid + ".glb")
    out_dir = os.path.join(GAME, row["dir"])
    doc, binary = glb_prepare.read_glb(raw_path)
    binary = bytearray(binary)
    (P, pos_acc, pos_view), (N, nor_acc, nor_view), (T, _, _) = read_mesh(doc, binary)
    P = P.astype(np.float64)
    N = N.astype(np.float64)
    # 1. Dönüş (y çevresinde).
    a = math.radians(rc["yaw_deg"])
    c, s = math.cos(a), math.sin(a)
    R = np.array([[c, 0.0, s], [0.0, 1.0, 0.0], [-s, 0.0, c]])
    P = P @ R.T
    N = N @ R.T
    # 2. Ölçek: dingil uçları (alt bantta yana en çok çıkan köşeler).
    axle = P[(P[:, 1] > rc["axle_band_y"][0]) & (P[:, 1] < rc["axle_band_y"][1])]
    ends = {}
    for side, sign in (("L", 1.0), ("R", -1.0)):
        q = axle[np.sign(axle[:, 0]) == sign]
        far = q[np.argsort(-np.abs(q[:, 0]))[:40]]
        ends[side] = {"x": float(np.abs(far[:, 0]).max()), "y": float((far[:, 1].min() + far[:, 1].max()) * 0.5), "z": float(far[:, 2].mean())}
    stub_raw = (ends["L"]["x"] + ends["R"]["x"]) * 0.5
    scale = (rc["wheel_track"] + rc["stub_out"]) / stub_raw
    P *= scale
    axle_y = (ends["L"]["y"] + ends["R"]["y"]) * 0.5 * scale
    axle_z = (ends["L"]["z"] + ends["R"]["z"]) * 0.5 * scale
    # 3. Yer: dingil ortası (0, wheel_radius, 0).
    P -= np.array([0.0, axle_y - rc["wheel_radius"], axle_z])
    # Dingil eğikse (iki ucu ileri geri kaymış) dingil ve uçlarındaki yataklar düşey eksen çevresinde dik konuma döner: tekerleğin
    # göbeği iki uçta da dingilin ucunu örter. Yalnız dingil hattına yakın köşeler döner, kenarı yumuşak (gövde yerinde kalır).
    skew = (ends["L"]["z"] - ends["R"]["z"]) * scale
    deskew = rc.get("deskew")
    if deskew and abs(skew) > 0.01:
        half = stub_raw * scale
        angle = math.atan2(skew, 2.0 * half)
        line = np.array([math.cos(angle), math.sin(angle)])  # x-z düzleminde dingil yönü
        d = np.abs(P[:, 0] * line[1] - P[:, 2] * line[0])
        y_ok = (P[:, 1] > rc["wheel_radius"] + deskew["y"][0]) & (P[:, 1] < rc["wheel_radius"] + deskew["y"][1])
        t = np.clip((deskew["reach"][1] - d) / (deskew["reach"][1] - deskew["reach"][0]), 0.0, 1.0)
        w = t * t * (3.0 - 2.0 * t) * y_ok
        turn = angle * w
        ct, st = np.cos(turn), np.sin(turn)
        x, z = P[:, 0].copy(), P[:, 2].copy()
        P[:, 0], P[:, 2] = ct * x + st * z, -st * x + ct * z
        nx, nz = N[:, 0].copy(), N[:, 2].copy()
        N[:, 0], N[:, 2] = ct * nx + st * nz, -st * nx + ct * nz
        print("[araba] dingil %.1f° eğikti: %d köşe döndü" % (math.degrees(angle), int((w > 0).sum())))
    # Dingil uçları son hâlinde (kaymanın kalanı ölçüye yazılır).
    band = (P[:, 1] > rc["wheel_radius"] - 0.17) & (P[:, 1] < rc["wheel_radius"] + 0.2)
    final_ends = {}
    for side, sign in (("L", 1.0), ("R", -1.0)):
        q = P[band & (np.sign(P[:, 0]) == sign)]
        far = q[np.argsort(-np.abs(q[:, 0]))[:40]]
        final_ends[side] = float(far[:, 2].mean())
    write_vec3(binary, pos_acc, pos_view, P)
    write_vec3(binary, nor_acc, nor_view, N / np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-9))
    # 4. Oyun GLB'si: doku sınıfın boyunda.
    tmp = os.path.join(out_dir, rid + "_tmp.glb")
    os.makedirs(out_dir, exist_ok=True)
    glb_prepare.write_glb(tmp, doc, bytes(binary))
    cls = glb_prepare.texture_class(plan, row["texture_class"])
    glb_prepare.prepare(tmp, os.path.join(out_dir, rid + ".glb"), cls[1], 2, cls)
    os.remove(tmp)
    # 5. Ölçüler.
    lo, hi = P.min(0), P.max(0)
    bed_band = (P[:, 1] > rc["wheel_radius"] + (rc["bed_band_y"][0] - (axle_y / scale)) * scale) & (P[:, 1] < rc["wheel_radius"] + (rc["bed_band_y"][1] - (axle_y / scale)) * scale)
    bed = P[bed_band & (P[:, 2] < rc["shaft_min_z"])]
    shafts = P[P[:, 2] > rc["shaft_min_z"]]
    tips = {}
    for side, sign in (("L", 1.0), ("R", -1.0)):
        q = shafts[np.sign(shafts[:, 0]) == sign]
        tip = q[np.argmax(q[:, 2])]
        tips[side] = [round(float(v), 4) for v in tip]
    hitch_z = max(tips["L"][2], tips["R"][2])
    meta = {
        "id": rid,
        "generated_by": "tools/cart_body.py",
        "doc": "Başlangıç dingil ortasının altındaki zemindir (y = 0); +z ön (okların ucu), +x arabanın solu. Tekerlekler kodladır: merkezleri "
               "(±wheel_track, wheel_radius, 0), dingil x ekseninde (DepartCart._build_wheel). MeshyProp ile konursa taban zemine indirilmez: "
               "gövdenin en alçak noktası clearance_m yüksekliğindedir.",
        "forward": [0.0, 0.0, 1.0],
        "up": [0.0, 1.0, 0.0],
        "scale_from_raw": round(float(scale), 5),
        "yaw_deg": rc["yaw_deg"],
        "wheel_radius": rc["wheel_radius"],
        "wheel_track": rc["wheel_track"],
        "axle": [0.0, rc["wheel_radius"], 0.0],
        "axle_stub_x": round(float(stub_raw * scale), 4),
        "axle_stub_skew_z": round(final_ends["L"] - final_ends["R"], 4),
        "axle_stub_skew_raw_z": round(float((ends["L"]["z"] - ends["R"]["z"]) * scale), 4),
        "bed": {"min": [round(float(v), 4) for v in bed.min(0)], "max": [round(float(v), 4) for v in bed.max(0)]},
        "bed_top_m": round(float(bed[:, 1].max()), 4),
        "cover_top_m": round(float(hi[1]), 4),
        "clearance_m": round(float(lo[1]), 4),
        "shaft_tips": tips,
        "hitch": [0.0, round(float((tips["L"][1] + tips["R"][1]) * 0.5), 4), round(float(hitch_z + rc["hitch_gap"]), 4)],
        "box": {"min": [round(float(v), 4) for v in lo], "max": [round(float(v), 4) for v in hi]},
        "triangles": int(len(T) // 3),
    }
    with open(os.path.join(out_dir, rid + ".json"), "w", encoding="utf-8") as fh:
        json.dump(meta, fh, indent=1, ensure_ascii=False)
        fh.write("\n")
    print("[araba] %s: ölçek %.4f, kutu %s – %s, kasa üstü %.3f, örtü tepesi %.3f, alçak nokta %.3f, dingil ucu %.3f (kayma %.3f), ok uçları %s" % (
        rid, scale, np.round(lo, 3).tolist(), np.round(hi, 3).tolist(), meta["bed_top_m"], meta["cover_top_m"], meta["clearance_m"],
        meta["axle_stub_x"], meta["axle_stub_skew_z"], tips))


if __name__ == "__main__":
    main()
