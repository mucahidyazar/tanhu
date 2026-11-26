#!/usr/bin/env python3
"""
Uzun giysinin ağırlığı: oturuşta eteğin davul gibi açılmasını azaltır. Kredi harcamaz; ağın konumu, dokusu, kemikler ve klipler değişmez, yalnız JOINTS_0 ve
WEIGHTS_0 yazılır (yazma tools/rig_fix.py --apply'ın sırasındadır: eklem düzeltmesi, omuz geçişi, etek, parmak). Hep ham ağırlıktan hesaplanır: aynı girdi aynı dosyayı verir.

Kusur (K92): Meshy kumaşı bacak kemiklerine katı bağlar. Sol ve sağ uyluk arasındaki sınır keskindir, etek ucu baldıra bağlıdır (Ana'da diz altı %89 baldır). Bağdaşta
baldır yatınca bacak eksenine uzak kumaş kemikle dönüp yukarı kalkar, iki bacak arasındaki yüzey gerilir: davul.

Yöntem: etek bölgesinde (kalçanın altı, bacak ekseninden uzak, etek ucunun üstü; çizme, baldır ve pantolon dışarıda) ağırlık, ham değer yerine kalça ve uyluk arasında yumuşak bir alandır:
  - kalça payı yüksekliğe göre artar: kalça ekleminde 0, diz hizasında knee_share, etek ucunda hem_share; kumaş dizi örter, dizden aşağı sarkar;
  - baldır payı eksene yakın kumaşta kalır, uzaklaştıkça söner: etek ucu kemikle birlikte kalkmaz;
  - sol-sağ geçişi orta çizgide side_blend genişliğinde yumuşar: iki uyluk ayrılınca yüzey yırtılmaz, gerilme geniş banda yayılır;
  - alan kalçada ve bacak yarıçapında ham ağırlığa yumuşak geçer. Saç ve kuşak ucu gibi bacağa bağlı olmayan köşe değişmez;
  - kumaşta uyluk baskın kalır (PoseFit baskın kemiği okur), alan kaynaşık ağda yumuşatılır: gerilmeyi asıl azaltan budur.
Alan yalnız dinlenme konumuna bağlıdır: aynı yerdeki iki kumaş katı aynı ağırlığı alır, katlar ayrışmaz. Sol-sağ simetriktir (orta düzlem x = 0).

Kişi başına değerler data/garment_weights.json'dadır. Listede olmayan kişi değişmez (kısa giysi). Yeni kişide --suggest bir başlangıç önerir.

Kullanım (game/ klasöründe):
  python3 tools/garment_weights.py --report [id ...] [--dir=<klasör>]   # listedeki kişilerin değerleri ve alanın kapladığı köşe; hiçbir şeyi değiştirmez
  python3 tools/garment_weights.py --suggest [id ...]                   # ağdan etek ucu ve bacak yarıçapı önerisi
"""
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skin_data import smooth_step  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_PATH = os.path.join(ROOT, "data", "garment_weights.json")
# Alanın kalçadaki ham ağırlığa geçişi (diz hizası = 1 ölçeğinde, kalça eklemi 0).
TOP_FADE = (-0.05, 0.35)
# Bacak yarıçapından kumaşa geçiş bandı (metre).
RADIUS_BAND = 0.04
# Baldır payının sönme bandı (metre; eksen uzaklığı).
CALF_BAND = 0.1
# Kalça payı, uyluğun baskınlığını bozmayacak sınırın bu oranına kadar çıkar.
DOMINANCE_MARGIN = 0.88
# Köşe bacağa bu kadar bağlıysa alana girer (saç, kuşak ucu ve kol girmesin).
LEG_BOUND = (0.2, 0.6)
# Bacak eksenine yakın kumaşın kalça payı çarpanı: yakın (near), uzak 1 (dizi örten yüzey bacakla gitsin).
NEAR_SHARE = 0.8
NEAR_BAND = (0.09, 0.18)
# Alanın yumuşatma turu (kaynaşık ağda komşu ortalaması; tur başına ≈1 cm): keskin geçiş gerilmenin asıl kaynağıdır. 2 turda Ana'da 2 kattan çok gerilen yüzey %8,9, 60 turda %4,8 (ham %8,5).
SMOOTH_PASSES = 60
FOOT_BONES = ("LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase")
LEG_BONES = ("LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg")


def load_table(path=DATA_PATH):
    if not os.path.exists(path):
        return {}
    with open(path, encoding="utf-8") as fh:
        return json.load(fh).get("people", {})


def segment_distance(points, a, b):
    ab = b - a
    t = np.clip(((points - a) @ ab) / (ab @ ab), 0.0, 1.0)
    return np.linalg.norm(points - (a + t[:, None] * ab), axis=1)


def leg_distance(pos, joint_pos):
    """Köşenin en yakın bacak eksenine uzaklığı (uyluk ve baldır parçaları, metre)."""
    out = None
    for side in ("Left", "Right"):
        up, leg, foot = joint_pos[side + "UpLeg"], joint_pos[side + "Leg"], joint_pos[side + "Foot"]
        d = np.minimum(segment_distance(pos, up, leg), segment_distance(pos, leg, foot))
        out = d if out is None else np.minimum(out, d)
    return out


def body_levels(joint_pos):
    """Kalça eklemi, diz ve bilek yüksekliği (metre; dinlenme)."""
    hip = (joint_pos["LeftUpLeg"][1] + joint_pos["RightUpLeg"][1]) * 0.5
    knee = (joint_pos["LeftLeg"][1] + joint_pos["RightLeg"][1]) * 0.5
    ankle = (joint_pos["LeftFoot"][1] + joint_pos["RightFoot"][1]) * 0.5
    return hip, knee, ankle


def suggest(pos, names, dense, joint_pos):
    """Ağdan başlangıç: çizme yarıçapı bilek bandının %97'si; etek ucu bilekten yukarı, eksenden çizmenin 1,6 katından uzak köşenin ilk göründüğü yükseklik."""
    index = {name: i for i, name in enumerate(names)}
    leg = sum(dense[:, index[n]] for n in LEG_BONES)
    foot = sum(dense[:, index[n]] for n in FOOT_BONES)
    hip, knee, ankle = body_levels(joint_pos)
    r = leg_distance(pos, joint_pos)
    near_ankle = (pos[:, 1] >= ankle) & (pos[:, 1] < ankle + 0.1) & (foot < 0.5) & (leg > 0.3)
    boot = float(np.percentile(r[near_ankle], 97)) if near_ankle.any() else 0.1
    hem = None
    y = ankle + 0.05
    while y < hip:
        hit = (pos[:, 1] >= y) & (pos[:, 1] < y + 0.02) & (leg > 0.3) & (r > boot * 1.6)
        if hit.sum() >= 8:
            hem = y
            break
        y += 0.01
    return {"hem_y": round(float(hem) if hem is not None else float(knee), 2), "boot_radius": round(boot + 0.02, 2), "leg_radius": round(boot, 2)}


def field(pos, names, dense, joint_pos, spec):
    """Yeni yoğun ağırlık ve alanın kapladığı pay (0..1, köşe başına). dense değişmez."""
    index = {name: i for i, name in enumerate(names)}
    hip, knee, _ = body_levels(joint_pos)
    y = pos[:, 1]
    x = pos[:, 0]
    r = leg_distance(pos, joint_pos)
    level = (hip - y) / (hip - knee)
    leg = sum(dense[:, index[n]] for n in LEG_BONES)
    foot = sum(dense[:, index[n]] for n in FOOT_BONES)
    rl = float(spec["leg_radius"])
    hem = float(spec["hem_y"])
    # Etek ucunun altında yalnız eksenden uzak köşe kumaştır (kürk ve saçak uçları): çizme ve baldır bacakta kalır.
    below = 1.0 - smooth_step(hem - 0.03, hem, y)
    inner = rl + (float(spec.get("boot_radius", rl + 0.03)) - rl) * below
    cover = smooth_step(TOP_FADE[0], TOP_FADE[1], level) * smooth_step(inner, inner + RADIUS_BAND, r)
    cover = cover * smooth_step(LEG_BOUND[0], LEG_BOUND[1], leg) * (1.0 - foot)
    side = smooth_step(-float(spec["side_blend"]), float(spec["side_blend"]), x)
    hem_level = max((hip - hem) / (hip - knee), 1.05)
    hips = np.interp(level, [0.0, 1.0, hem_level], [0.0, float(spec["knee_share"]), float(spec["hem_share"])])
    hips = hips * (NEAR_SHARE + (1.0 - NEAR_SHARE) * smooth_step(NEAR_BAND[0], NEAR_BAND[1], r))
    # Baldır payı eksene yakın kumaşta ham değerinden gelir, uzaklaştıkça söner: pantolon ve açık giysinin ön kenarı bacakla gider, etek kemikle kalkmaz.
    keep = (1.0 - smooth_step(inner, inner + float(spec.get("calf_band", CALF_BAND)), r))[:, None]
    calf_left = dense[:, index["LeftLeg"]] * keep[:, 0]
    calf_right = dense[:, index["RightLeg"]] * keep[:, 0]
    calf = calf_left + calf_right
    # Kumaş köşesinde uyluk baskın kalır: PoseFit zemin payını ve kalça boşluğunu baskın kemikten okur, kalçaya baskın etek ucu zemine değen beden sayılırdı (Ana bağdaşta 24 cm
    # havada kalıyordu). Orta çizgide iki uyluk paylaştığı için sınır orada daha düşüktür.
    major = np.maximum(side, 1.0 - side)
    hips = np.minimum(hips, DOMINANCE_MARGIN * (1.0 - calf) * major / (1.0 + major))
    thigh = np.clip(1.0 - hips - calf, 0.0, 1.0)
    target = np.zeros_like(dense)
    target[:, index["Hips"]] = hips
    target[:, index["LeftUpLeg"]] = side * thigh
    target[:, index["RightUpLeg"]] = (1.0 - side) * thigh
    target[:, index["LeftLeg"]] = calf_left
    target[:, index["RightLeg"]] = calf_right
    out = dense * (1.0 - cover[:, None]) + target * cover[:, None]
    return out, cover


def _keep_thigh_dominant(out, index, changed):
    """Yumuşatma orta çizgide kalça payını uyluğun üstüne çıkarabilir: fazlası iki uyluğa geri döner (PoseFit baskın kemiği okur)."""
    hips, left, right = index["Hips"], index["LeftUpLeg"], index["RightUpLeg"]
    thigh = out[:, left] + out[:, right]
    # Yalnız bacağa bağlı kumaş: kalçanın üstündeki köşe zaten kalçaya baskındır, uyluğu yoktur.
    over = changed & (thigh > out[:, hips] * 0.5) & (out[:, hips] > np.maximum(out[:, left], out[:, right]) * DOMINANCE_MARGIN)
    if not over.any():
        return
    ratio = out[over, left] / np.maximum(thigh[over], 1e-9)
    # Toplam korunur: kalça h, uyluk t, büyük pay m (m = max(oran, 1 - oran)); hedef h = marj × m × t.
    major = np.maximum(ratio, 1.0 - ratio)
    total = out[over, hips] + thigh[over]
    target = total * DOMINANCE_MARGIN * major / (1.0 + DOMINANCE_MARGIN * major)
    out[over, hips] = target
    out[over, left] = (total - target) * ratio
    out[over, right] = (total - target) * (1.0 - ratio)


def apply(rig_id, skin, dense, joint_pos, welded=None, table=None):
    """Kişi listedeyse alanı uygular; (yeni yoğun ağırlık, değişen köşe maskesi, not). Listede değilse dense aynen döner."""
    spec = (load_table() if table is None else table).get(rig_id)
    if not spec:
        return dense, np.zeros(len(dense), bool), ""
    out, cover = field(skin.pos, skin.names, dense, joint_pos, spec)
    if welded is not None and SMOOTH_PASSES:
        out = welded.smooth(out, np.clip(cover * 3.0, 0.0, 1.0), SMOOTH_PASSES)
    changed = cover > 1e-6
    _keep_thigh_dominant(out, skin.index, changed)
    return out, changed, "etek alanı: %d köşe (diz payı %.2f, uç payı %.2f)" % (changed.sum(), spec["knee_share"], spec["hem_share"])


def main():
    import rig_fix
    from glb_prepare import read_glb
    from skin_data import Skin, raw_weights
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    ids = [a for a in sys.argv[1:] if not a.startswith("--")]
    rig_fix.use_paths(flags)
    table = load_table()
    if "--suggest" in flags or "--report" in flags:
        for rig_id in ids or (rig_fix.all_ids() if "--suggest" in flags else sorted(table)):
            doc, binary = read_glb(rig_fix.model_path(rig_id))
            skin = Skin(doc, binary)
            ibm = rig_fix.read_accessor(doc, binary, doc["skins"][0]["inverseBindMatrices"])
            joint_pos = {name: np.linalg.inv(np.array(ibm[i], float).reshape(4, 4).T)[:3, 3] for i, name in enumerate(skin.names)}
            dense = raw_weights(rig_id, read_glb, skin.names)[0]
            if "--suggest" in flags:
                print("%-16s %s" % (rig_id, suggest(skin.pos, skin.names, dense, joint_pos)))
            else:
                spec = table.get(rig_id)
                if not spec:
                    print("%-16s listede yok, değişmez" % rig_id)
                    continue
                _, cover = field(skin.pos, skin.names, dense, joint_pos, spec)
                print("%-16s %s, alan %d köşe" % (rig_id, spec, (cover > 1e-6).sum()))
        return
    sys.exit(__doc__)


if __name__ == "__main__":
    main()
