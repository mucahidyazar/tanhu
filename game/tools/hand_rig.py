#!/usr/bin/env python3
"""
Meshy iskeletine parmak kemiği ekler (24 kemikte el tek parçadır, kapanmaz). Kredi harcamaz; ağın konumu, dokusu ve klip dönüşleri değişmez,
dosyada düğümler, skin eklem listesi, ters bağ matrisleri ve JOINTS_0/WEIGHTS_0 yazılır. Kemikler yalnız ana kişi dosyasına eklenir: klipler ve
taşıyıcı parmak izi taşımaz, parmağın pozu oyunda HandGrip'ten (scripts/character/hand_grip.gd), belge sitesinde clip_library_export.gd'nin yazdığı sabit izden gelir.

Kemik yerleri ağdan ölçülür (T-poz, kişi ve el başına):
  1. El çerçevesi: bilekten parmak uçlarına u, avuç yüzünün normali n (avuca doğru), avuç genişliği v (başparmak yanı).
  2. Elin n yönünden izdüşümü (2 mm ızgara). Uçtan bileğe satır satır: ayrı koşular parmak, koşuların birleştiği yer ağ (parmak arası).
  3. Başparmak: u'nun gerisinde (v + n) yönünde en uç nokta; ona bağlı köşelerin ekseni ve kesitin genişlediği yer kökü.
  4. Dört parmak: her koşu bir parmak. Avuç genişliğini doldurmayan yan ya da fazla geniş koşu kaynaşık parmak sayılır (Hereka, Teoman: ağda
     parmaklar ayrık değil): bant, tipik parmak enine bölünür. Bu kişide parmaklar birlikte bükülür, teker teker ayrılmaz.
  5. Boğumlar: ağ yerine göre kök boğumu (MCP) ağın 0,35 parmak boyu gerisinde, orta boğum (PIP) 0,30 boyu ilerisinde; ağda o noktaya yakın halka varsa
     oraya oturur. Kemik düğümünde yerel Y parmak yönü, yerel +X eksenindeki artı dönüş parmağı avuca kapatır (her iki elde aynı işaret).

Ağırlık: parmak köşesi eksene göre, boğum çevresinde yumuşak geçişle; avuçta iki komşu parmak arasında paylaşılır; bileğin gerisindeki ve ele bağlı
olmayan köşe değişmez. Elde en çok dört etkili kemik kalır.

Kullanım (game/ klasöründe):
  python3 tools/hand_rig.py --report [id ...] [--dir=<klasör>]     # ölçer, hiçbir şeyi değiştirmez
Dosyaya yazma tools/rig_fix.py --apply'ın sırasındadır: eklem düzeltmesi, omuz geçişi, etek, parmak.
"""
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rig_fix  # noqa: E402
from glb_prepare import pack_views, read_glb  # noqa: E402
from skin_data import Skin, Welded, raw_weights, smooth_step  # noqa: E402

SIDES = ("Left", "Right")
# Başparmak yanından serçeye. Adlar Meshy kemikleriyle çakışmaz ve ClipRetarget'in kol anahtarlarını (shoulder, arm, leg, foot) taşımaz.
FINGERS = ("Thumb", "Index", "Middle", "Ring", "Pinky")
JOINTS_PER_FINGER = 2
# İzdüşüm ızgarası (metre): en ince parmak 1 cm.
CELL = 0.002
# Bu kadar satırdan kısa çıkıntı parmak sayılmaz (0,6 cm: Baba'nın serçesi ağdan bir elde 1,4, ötekinde 0,6 cm çıkar).
MIN_LEAF_ROWS = 3
# Ucu el boyunun bu payından gerideki çıkıntı parmak değildir (yen ve kürk uçları).
MIN_TIP_SHARE = 0.45
# Ağ (parmak arası) yerine göre boğum payları, parmağın açık boyuna oran.
MCP_BEHIND_WEB = 0.35
PIP_AHEAD_OF_WEB = 0.30
# Orta boğum ağdaki halkaya bu kadar (parmak boyuna oran) yakınsa oraya oturur.
RING_SNAP = 0.10
# Boğum çevresindeki yumuşak geçişin yarı genişliği (bir sonraki kemiğin boyuna oran).
MCP_BLEND = 0.35
PIP_BLEND = 0.30
# Başparmağın kökü aranırken ona bağlı köşelerin uzaklığı (el boyuna oran) ve kesitin genişleme eşiği.
THUMB_REACH = 0.55
THUMB_WIDEN = 1.7
# Kaynaşık koşu: tipik parmak eninin bu katından genişse bölünür.
FUSED_RATIO = 1.6
# Parmağın açık boyu, ucunun bileğe uzaklığının en az bu payıdır (çentik gibi kısa ağda kök boğumu doğru yere insin; sağlam ellerde 0,24-0,30).
MIN_FREE_SHARE = 0.22


def finger_bone(side, finger, joint):
    return "%s%s%d" % (side, finger, joint)


FINGER_BONES = tuple(finger_bone(side, finger, joint) for side in SIDES for finger in FINGERS for joint in range(1, JOINTS_PER_FINGER + 1))


def is_finger_bone(name):
    return name in FINGER_BONES


# --- Ölçü ---------------------------------------------------------------------------------------------------

def _hand_frame(skin, dense, joint_pos, side):
    """Elin bölgesi ve çerçevesi: (bilek, u, v, n, köşe sırası)."""
    jh = skin.index[side + "Hand"]
    wrist, elbow = joint_pos[side + "Hand"], joint_pos[side + "ForeArm"]
    fore = (wrist - elbow) / np.linalg.norm(wrist - elbow)
    picked = (dense[:, jh] > 0.5) & (((skin.pos - wrist) @ fore) > -0.01)
    idx = np.nonzero(picked)[0]
    p = skin.pos[idx]
    u = fore
    for _ in range(2):
        along = (p - wrist) @ u
        far = p[along > along.max() * 0.7]
        u = far.mean(0) - wrist
        u /= np.linalg.norm(u)
    q = p - p.mean(0)
    q = q - np.outer(q @ u, u)
    # q u'ya diktir: en büyük yayılım avuç genişliği, ikincisi avuç kalınlığı (normal).
    _, _, vt = np.linalg.svd(q[::max(1, len(q) // 4000)], full_matrices=False)
    n = vt[1] - u * (vt[1] @ u)
    n /= np.linalg.norm(n)
    if n[1] > 0.0:
        n = -n  # T-pozda avuç aşağı bakar (K85).
    v = np.cross(n, u)
    if v[2] < 0.0:
        v = -v  # Başparmak öne (+Z).
    return wrist, u, v, n, idx


def _silhouette(skin, idx, wrist, u, v):
    """Elin n yönünden izdüşümü: satır u, sütun v (CELL ızgarası)."""
    chosen = np.zeros(len(skin.pos), bool)
    chosen[idx] = True
    tris = skin.tris[chosen[skin.tris].all(1)]
    rel = skin.pos - wrist
    uu, vv = rel @ u, rel @ v
    umin, vmin = uu[idx].min(), vv[idx].min()
    rows = int((uu[idx].max() - umin) / CELL) + 2
    cols = int((vv[idx].max() - vmin) / CELL) + 2
    fu, fv = (uu - umin) / CELL, (vv - vmin) / CELL
    image = np.zeros((rows, cols), bool)
    for a, b, c in tris:
        ax, ay, bx, by, cx, cy = fu[a], fv[a], fu[b], fv[b], fu[c], fv[c]
        d = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(d) < 1e-9:
            continue
        x0, x1 = int(min(ax, bx, cx)), min(int(max(ax, bx, cx)) + 1, rows - 1)
        y0, y1 = int(min(ay, by, cy)), min(int(max(ay, by, cy)) + 1, cols - 1)
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1, dtype=float), np.arange(y0, y1 + 1, dtype=float), indexing="ij")
        l0 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / d
        l1 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / d
        image[x0:x1 + 1, y0:y1 + 1] |= (l0 >= -0.02) & (l1 >= -0.02) & (1.0 - l0 - l1 >= -0.02)
    return image, umin, vmin


def _runs(row):
    """Satırdaki dolu koşular (a, b; iki hücreden kısası gürültü)."""
    out = []
    i = 0
    n = len(row)
    while i < n:
        if row[i]:
            j = i
            while j + 1 < n and row[j + 1]:
                j += 1
            if j - i >= 2:
                out.append((i, j))
            i = j + 1
        else:
            i += 1
    return out


def _bridged_runs(image):
    """Satır başına koşular; tek satırlık köprü ayrılır: üst ve alt satırda iki ayrı koşuya değen koşu (ince bir üçgen iki parmağı bir satırda birleştirebilir) o aralıktan bölünür."""
    rows = [_runs(image[r]) for r in range(image.shape[0])]
    for r in range(1, image.shape[0] - 1):
        fixed = []
        for a, b in rows[r]:
            up = [x for x in rows[r + 1] if x[0] <= b and x[1] >= a]
            down = [x for x in rows[r - 1] if x[0] <= b and x[1] >= a]
            if len(up) >= 2 and len(up) == len(down):
                start = a
                for k in range(len(up) - 1):
                    cut = (up[k][1] + up[k + 1][0] + down[k][1] + down[k + 1][0]) // 4
                    fixed.append((start, cut - 1))
                    start = cut + 1
                fixed.append((start, b))
            else:
                fixed.append((a, b))
        rows[r] = fixed
    return rows


def _leaves(image):
    """Uçtan bileğe satır satır izlenen koşulardan yapraklar (parmak uçları): her biri [(satır, a, b)]. İki iz birleşince ikisi de biter (ağ). Bir parmak izi ikiye bölünürse büyük
    örtüşen kol onundur, öteki kol yeni bir uçtur: yanındaki kısa parmak ona bitişik başlamış olabilir (Baba'nın serçesi)."""
    open_tracks = []
    leaves = []
    all_runs = _bridged_runs(image)
    for r in range(image.shape[0] - 1, -1, -1):
        current = all_runs[r]
        hits = [[] for _ in current]
        for track in open_tracks:
            _, la, lb = track["rows"][-1]
            track["next"] = [i for i, (a, b) in enumerate(current) if a <= lb and b >= la]
            for i in track["next"]:
                hits[i].append(track)
        kept = []
        started = set()
        for track in open_tracks:
            alone = [i for i in track["next"] if len(hits[i]) == 1]
            if len(alone) != len(track["next"]) or not alone:
                continue
            _, la, lb = track["rows"][-1]
            best = max(alone, key=lambda i: min(current[i][1], lb) - max(current[i][0], la))
            a, b = current[best]
            track["rows"].append((r, a, b))
            kept.append(track)
            started.add(best)
            for i in alone:
                if i != best:
                    fresh = {"rows": [(r, current[i][0], current[i][1])], "leaf": track["leaf"]}
                    if track["leaf"]:
                        leaves.append(fresh)
                    kept.append(fresh)
                    started.add(i)
        for i, (a, b) in enumerate(current):
            if i in started:
                continue
            fresh = {"rows": [(r, a, b)], "leaf": not hits[i]}
            if fresh["leaf"]:
                leaves.append(fresh)
            kept.append(fresh)
        open_tracks = kept
    return [np.array(t["rows"], float) for t in leaves if len(t["rows"]) >= MIN_LEAF_ROWS]


def _line(xs, ys):
    """En küçük kareler doğrusu y = a + b x."""
    if len(xs) < 2 or np.ptp(xs) < 1e-6:
        return float(np.mean(ys)), 0.0
    b, a = np.polyfit(xs, ys, 1)
    return float(a), float(b)


def _thumb(skin, welded, adjacency, wrist, u, v, n, idx, hand_length):
    """Başparmak: en uç nokta, ekseni, kökü. (uç, kök, açık boy, yarıçap, üye köşeler)."""
    rel = skin.pos[idx] - wrist
    uu, vv, nn = rel @ u, rel @ v, rel @ n
    centre_v, centre_n = np.median(vv), np.median(nn)
    # Parmak uçlarının gerisinde, avuç merkezinden (v + n) yönünde en uzak nokta.
    candidate = (uu > 0.3 * hand_length) & (uu < 0.85 * hand_length)
    score = (vv - centre_v) + 0.8 * (nn - centre_n)
    tip_vertex = idx[candidate][np.argmax(score[candidate])]
    tip = skin.pos[tip_vertex]
    # Uçtan kaynaşık çizgide, THUMB_REACH içindeki bağlı köşeler.
    reach = THUMB_REACH * hand_length
    wid = welded.of
    allowed = np.zeros(welded.count, bool)
    allowed[wid[idx]] = True
    welded_pos = np.zeros((welded.count, 3))
    welded_pos[wid] = skin.pos
    allowed &= np.linalg.norm(welded_pos - tip, axis=1) < reach
    start = int(wid[tip_vertex])
    seen = {start}
    stack = [start]
    while stack:
        a = stack.pop()
        for b in adjacency[a]:
            if allowed[b] and b not in seen:
                seen.add(b)
                stack.append(b)
    members = np.array(sorted(seen))
    pts = welded_pos[members]
    # Eksen: uca yakın yarının ana ekseni; sonra kesit genişliyorsa kök oradadır.
    dist = np.linalg.norm(pts - tip, axis=1)
    near = pts[dist < 0.5 * reach]
    if len(near) < 4:
        near = pts
    centre = near.mean(0)
    _, _, vt = np.linalg.svd(near - centre, full_matrices=False)
    axis = vt[0]
    if axis @ (wrist - tip) < 0.0:
        axis = -axis
    along = (pts - tip) @ axis
    radial = np.linalg.norm((pts - tip) - np.outer(along, axis), axis=1)
    bins = np.arange(0.0, along.max() + 0.003, 0.003)
    widths = []
    for b in bins:
        hit = (along >= b) & (along < b + 0.006)
        widths.append(np.percentile(radial[hit], 90) if hit.sum() >= 3 else (widths[-1] if widths else 0.0))
    widths = np.array(widths)
    sane = widths[(bins > 0.01) & (bins < 0.035)]
    base_radius = float(np.median(sane)) if len(sane) else 0.01
    wide = np.nonzero((bins > 0.02) & (widths > THUMB_WIDEN * max(base_radius, 0.004)))[0]
    free = float(bins[wide[0]]) if len(wide) else float(along.max())
    free = min(max(free, 0.015), 0.5 * hand_length)
    base = tip + axis * free
    return tip, base, free, base_radius, -axis


def _analyze_hand(skin, dense, joint_pos, welded, adjacency, side):
    """Bir elin ölçüsü: {finger: {joints: [p1, p2], tip, dir, width, ...}}, frame, notes."""
    wrist, u, v, n, idx = _hand_frame(skin, dense, joint_pos, side)
    image, umin, vmin = _silhouette(skin, idx, wrist, u, v)
    leaves = _leaves(image)
    rows = []
    for track in leaves:
        tip_u = track[0, 0] * CELL + umin
        web_u = track[-1, 0] * CELL + umin
        mid_v = (track[:, 1] + track[:, 2]) * 0.5 * CELL + vmin
        width = float(np.median(track[:, 2] - track[:, 1] + 1) * CELL)
        rows.append({"tip_u": tip_u, "web_u": web_u, "track": track, "mid_v": mid_v, "width": width, "v": float(mid_v.mean())})
    hand_length = max([r["tip_u"] for r in rows] + [(image.shape[0] * CELL + umin)])
    rows = sorted([r for r in rows if r["tip_u"] > MIN_TIP_SHARE * hand_length], key=lambda r: r["v"])
    # Ağı çok yukarıda duran koşu (kaynaşık parmağın ucundaki çentik): parmak gerçekte daha aşağıdan başlar.
    for r in rows:
        r["web_u"] = min(r["web_u"], r["tip_u"] * (1.0 - MIN_FREE_SHARE))
    notes = []
    tip, base, free, radius, axis = _thumb(skin, welded, adjacency, wrist, u, v, n, idx, hand_length)
    # Başparmak koşusunu dört parmaktan ayır: ucu başparmağın ucuna yakın koşu başparmaktır.
    tip_rel = tip - wrist
    for r in list(rows):
        if abs(r["tip_u"] - tip_rel @ u) < 0.02 and abs(r["v"] - tip_rel @ v) < 0.025:
            rows.remove(r)
    fingers = {}
    typical = float(np.median([r["width"] for r in rows])) if len(rows) >= 3 else 0.0
    # Avuç bandı: parmak ağlarının hemen gerisindeki satırın en geniş koşusu (başparmak ayrıysa içinde değildir).
    webs = [r["web_u"] for r in rows]
    level = (min(webs) if webs else umin + 0.6 * hand_length) - 0.006
    r_band = int(np.clip((level - umin) / CELL, 0, image.shape[0] - 1))
    runs = _runs(image[r_band])
    if not runs:
        runs = [(0, image.shape[1] - 1)]
    band = max(runs, key=lambda x: x[1] - x[0])
    band_lo, band_hi = band[0] * CELL + vmin, band[1] * CELL + vmin
    if typical <= 0.0:
        typical = (band_hi - band_lo) / 4.0
    # Geniş koşular kaynaşıktır: bölünür.
    strips = []
    for r in rows:
        k = max(1, int(round(r["width"] / typical))) if r["width"] > FUSED_RATIO * typical else 1
        half = r["width"] / 2.0
        for j in range(k):
            strips.append({"row": r, "offset": -half + r["width"] * (j + 0.5) / k, "real": k == 1})
    # Bandın boş kalan yanları: ağda ayrı parmak yok.
    covered_lo = min([s["row"]["v"] + s["offset"] - typical / 2.0 for s in strips], default=band_hi)
    covered_hi = max([s["row"]["v"] + s["offset"] + typical / 2.0 for s in strips], default=band_lo)
    extra = []
    if not strips:
        k = max(1, int(round((band_hi - band_lo) / typical)))
        extra = [band_lo + (band_hi - band_lo) * (j + 0.5) / k for j in range(k)]
    else:
        gap = covered_lo - band_lo
        # Bandın boş yanı tipik parmağın en az 0,7'si kadarsa orada ayrı koşusu olmayan parmak vardır (Teoman, Hereka). Daha darı avucun kenarıdır: kemik verilirse el kenarı bükülür.
        k = int(gap / typical + 0.3)
        extra += [covered_lo - typical * (j + 0.5) for j in range(k)]
        gap = band_hi - covered_hi
        k = int(gap / typical + 0.3)
        extra += [covered_hi + typical * (j + 0.5) for j in range(k)]
    free_len = float(np.median([r["tip_u"] - r["web_u"] for r in rows])) if rows else 0.3 * hand_length
    for cv in extra:
        col = int(np.clip((cv - vmin) / CELL, 0, image.shape[1] - 1))
        filled = np.nonzero(image[:, col])[0]
        top = filled.max() * CELL + umin if len(filled) else hand_length
        strips.append({"row": None, "v": cv, "tip_u": float(top), "real": False})
    # Dörtten çok şerit olursa en kısa uçlu fazlası atılır.
    def strip_v(s):
        return s["row"]["v"] + s["offset"] if s["row"] is not None else s["v"]
    strips.sort(key=strip_v, reverse=True)
    while len(strips) > 4:
        # Önce sonradan eklenen şerit (ağda koşusu yok), sonra en kısa uçlu.
        strips.pop(int(np.argmin([(s["row"]["tip_u"] if s["row"] is not None else s["tip_u"] - 1.0) for s in strips])))
    if len(strips) < 4:
        notes.append("%s elde ağda %d parmak var" % (side, len(strips)))
    fused = [FINGERS[1:][i] for i, s in enumerate(strips) if not s["real"]]
    if fused:
        notes.append("%s elde ayrı koşusu olmayan parmak: %s (bant bölündü)" % (side, ", ".join(fused)))
    rel = skin.pos[idx] - wrist
    pu, pv, pn = rel @ u, rel @ v, rel @ n
    for name, s in zip(FINGERS[1:], strips):
        if s["row"] is not None:
            r = s["row"]
            track_u = r["track"][:, 0] * CELL + umin
            a, b = _line(track_u, r["mid_v"] + s["offset"])
            tip_u, web_u = r["tip_u"], r["web_u"]
        else:
            a, b = s["v"], 0.0
            tip_u = s["tip_u"]
            web_u = tip_u - free_len
        length = max(tip_u - web_u, 0.015)
        # Derinlik: şeridin köşelerinin kalınlık ortası, u boyunca doğru.
        half = max(typical * 0.6, 0.006)
        strip = np.abs(pv - (a + b * pu)) < half
        strip &= pu > web_u - length * 0.5
        us, ns = [], []
        for bin_u in np.arange(web_u - length * 0.5, tip_u, 0.004):
            hit = strip & (pu >= bin_u) & (pu < bin_u + 0.006)
            if hit.sum() >= 2:
                us.append(bin_u + 0.003)
                ns.append((pn[hit].min() + pn[hit].max()) * 0.5)
        if len(us) >= 2:
            c, d = _line(np.array(us), np.array(ns))
        else:
            c, d = float(np.median(pn)), 0.0

        def at(t):
            return wrist + u * t + v * (a + b * t) + n * (c + d * t)
        mcp_u = web_u - MCP_BEHIND_WEB * length
        pip_u = web_u + PIP_AHEAD_OF_WEB * length
        # Orta boğum: ağda yakın bir halka varsa oraya (hiç köşe olmayan yerde büküm uzun bir yüzü gerer).
        near = pu[strip & (pu > mcp_u) & (pu < tip_u)]
        if len(near):
            ring = near[np.argmin(np.abs(near - pip_u))]
            if abs(ring - pip_u) < RING_SNAP * length:
                pip_u = float(ring)
        direction = at(tip_u) - at(mcp_u)
        direction /= np.linalg.norm(direction)
        fingers[name] = {"joints": [at(mcp_u), at(pip_u)], "tip": at(tip_u), "dir": direction, "web": at(web_u), "length": length, "real": bool(s["real"]),
                         "band_v": (a, b), "width": typical}
    # Başparmak: kök ve ortası; kapanma yönü avuç ortasına.
    longest = max([(f["tip"] - wrist) @ u for f in fingers.values()], default=hand_length)
    grip = wrist + u * (0.62 * longest) + n * (np.median(pn) + 0.015)
    fingers["Thumb"] = {"joints": [base, base + axis * (free * 0.5)], "tip": tip, "dir": axis, "web": base, "length": free, "real": True, "radius": radius, "grip": grip, "width": radius * 2.0}
    return {"side": side, "wrist": wrist, "u": u, "v": v, "n": n, "idx": idx, "fingers": fingers, "notes": notes, "hand_length": hand_length, "typical": typical}


def bind_positions(doc, binary, skin):
    """Eklemlerin bağ pozundaki yeri (ağ uzayı, metre): ters bağ matrisinin tersi."""
    ibm = rig_fix.read_accessor(doc, binary, doc["skins"][0]["inverseBindMatrices"])
    return {name: np.linalg.inv(np.array(ibm[i], float).reshape(4, 4).T)[:3, 3] for i, name in enumerate(skin.names)}


def analyze(skin, dense, joint_pos, welded):
    """Kişinin iki eli: {side: el ölçüsü}."""
    adjacency = [[] for _ in range(welded.count)]
    for a, b in welded.edges:
        adjacency[a].append(int(b))
        adjacency[b].append(int(a))
    return {side: _analyze_hand(skin, dense, joint_pos, welded, adjacency, side) for side in SIDES}


def _even_out_lengths(hands, common):
    """Sol ve sağ aynı kemik boylarını taşır: her parmağın iki eldeki orta boğum ve kök boğum uzaklığının ortalaması, uçtan geriye. Eksen ve uç her elin kendi ağından kalır (ağ iki elde birebir aynı değildir;
    başparmağın kök ölçüsü bir elde kesitin genişlemesine erken takılabilir)."""
    for name in common:
        left, right = hands["Left"]["fingers"][name], hands["Right"]["fingers"][name]
        distal = (np.linalg.norm(left["tip"] - left["joints"][1]) + np.linalg.norm(right["tip"] - right["joints"][1])) * 0.5
        proximal = (np.linalg.norm(left["joints"][1] - left["joints"][0]) + np.linalg.norm(right["joints"][1] - right["joints"][0])) * 0.5
        for f in (left, right):
            middle = f["tip"] - f["dir"] * distal
            f["joints"] = [middle - f["dir"] * proximal, middle]


def rig_hands(doc, binary, skin, dense, joint_pos, welded):
    """Parmak kemiklerini ve ağırlıklarını kurar. Dönüş: (yeni ikili bölüm, yeni yoğun ağırlık, değişen köşe maskesi, notlar). İki elde parmak sayısı farklı çıkarsa
    az olanına inilir: sol ve sağ aynı kemikleri taşır. Elde hiç kemik kurulamazsa kişi 24 kemikte kalır, not düşülür."""
    hands = analyze(skin, dense, joint_pos, welded)
    common = [name for name in FINGERS if all(name in hands[side]["fingers"] for side in SIDES)]
    notes = []
    for side in SIDES:
        notes += hands[side]["notes"]
        hands[side]["fingers"] = {name: f for name, f in hands[side]["fingers"].items() if name in common}
    if "Thumb" not in common or len(common) < 2:
        notes.append("parmak kemiği kurulamadı: %s" % common)
        return binary, dense, np.zeros(len(skin.pos), bool), notes
    _even_out_lengths(hands, common)
    binary = add_bones(doc, binary, hands)
    names = [doc["nodes"][j]["name"] for j in doc["skins"][0]["joints"]]
    column_of = {name: i for i, name in enumerate(names)}
    wide = np.zeros((len(skin.pos), len(names)))
    wide[:, :dense.shape[1]] = dense
    changed = np.zeros(len(skin.pos), bool)
    for side in SIDES:
        changed |= hand_weights(skin, wide, hands[side], column_of) > 0.0
    # Boğum geçişleri kaynaşık köşelerde ortak, komşuda yumuşak; bileğin gerisine yayılmaz.
    mask = np.clip(changed.astype(float), 0.0, 1.0)
    wide = welded.smooth(wide, mask, 1, 0.35)
    if len(common) < len(FINGERS):
        notes.append("ağda ayrı parmak yetmedi: yalnız %s" % ", ".join(common))
    return binary, wide, changed, notes


# --- Ağırlık -------------------------------------------------------------------------------------------------

def hand_weights(skin, dense, hand, column_of):
    """Elin köşelerini parmak kemiklerine paylaştırır (dense yerinde değişir; sütunlar parmak kemiklerini de içerir). Ele bağlı olmayan köşe değişmez."""
    side = hand["side"]
    jh = column_of[side + "Hand"]
    fingers = hand["fingers"]
    wrist, u, v, n = hand["wrist"], hand["u"], hand["v"], hand["n"]
    bound = np.nonzero(dense[:, jh] > 1e-4)[0]
    if len(bound) == 0:
        return np.zeros(len(skin.pos))
    p = skin.pos[bound]
    names = [f for f in FINGERS if f in fingers]
    # Her parmağa: eksen boyunca konum (t, kök boğumdan), eksene uzaklık.
    ts, ds, first, second = {}, {}, {}, {}
    for name in names:
        f = fingers[name]
        p1, p2 = f["joints"]
        axis = f["dir"]
        rel = p - p1
        t = rel @ axis
        ts[name] = t
        tip_t = (f["tip"] - p1) @ axis
        clipped = np.clip(t, -0.02, tip_t)
        ds[name] = np.linalg.norm(rel - np.outer(clipped, axis), axis=1)
        seg = np.linalg.norm(p2 - p1)
        first[name] = smooth_step(-MCP_BLEND * seg, MCP_BLEND * seg, t)
        next_len = max(tip_t - seg, 0.005)
        second[name] = smooth_step(seg - PIP_BLEND * min(seg, next_len), seg + PIP_BLEND * min(seg, next_len), t)
    # Komşu paylaşımı: yakın eksene ağırlıklı; açık parmakta en yakın eksen tek başına.
    matrix = np.stack([ds[name] for name in names], 1)
    nearest = np.argmin(matrix, axis=1)
    closeness = np.exp(-((matrix / max(hand["typical"], 0.008)) ** 2))
    share = closeness / np.maximum(closeness.sum(1, keepdims=True), 1e-9)
    hard = np.zeros_like(share)
    hard[np.arange(len(p)), nearest] = 1.0
    # Ağın ötesinde (parmak açık) sert, avuçta yumuşak. Serbest parmakta her köşe kendi parmağınındır; avuçta eksenden uzak köşenin payı düşer (başparmak kökünün altı, kol ucu).
    limit = np.array([max(fingers[name].get("width", 0.02), 0.012) * 1.6 + 0.008 for name in names])
    near_axis = 1.0 - smooth_step(limit, limit + 0.015, matrix)
    for k, name in enumerate(names):
        web_t = (fingers[name]["web"] - fingers[name]["joints"][0]) @ fingers[name]["dir"]
        free = smooth_step(web_t - 0.004, web_t + 0.004, ts[name])
        share[:, k] = (share[:, k] * near_axis[:, k]) * (1.0 - free) + hard[:, k] * free
    total_hand = dense[bound, jh].copy()
    for k, name in enumerate(names):
        a = share[:, k] * first[name]
        b = share[:, k] * second[name]
        w1 = np.maximum(a - b, 0.0)
        w2 = b
        dense[bound, column_of[finger_bone(side, name, 1)]] = total_hand * w1
        dense[bound, column_of[finger_bone(side, name, 2)]] = total_hand * w2
    used = np.zeros(len(skin.pos))
    all_columns = [column_of[finger_bone(side, name, j)] for name in names for j in (1, 2)]
    moved = dense[bound][:, all_columns].sum(1)
    moved = np.minimum(moved, total_hand)
    dense[bound, jh] = total_hand - moved
    used[bound] = (moved > 1e-5).astype(float)
    return used


# --- Düğümler ------------------------------------------------------------------------------------------------

def _rotation_from_axes(x, y):
    """Sütunları (x, y, x×y) olan dönüşün kuaterniyonu (x, y, z, w)."""
    x = np.array(x, float)
    y = np.array(y, float)
    y = y / np.linalg.norm(y)
    x = x - y * (x @ y)
    x = x / np.linalg.norm(x)
    z = np.cross(x, y)
    m = np.stack([x, y, z], 1)
    t = m[0, 0] + m[1, 1] + m[2, 2]
    if t > 0.0:
        s = math.sqrt(t + 1.0) * 2.0
        q = ((m[2, 1] - m[1, 2]) / s, (m[0, 2] - m[2, 0]) / s, (m[1, 0] - m[0, 1]) / s, 0.25 * s)
    elif m[0, 0] > m[1, 1] and m[0, 0] > m[2, 2]:
        s = math.sqrt(1.0 + m[0, 0] - m[1, 1] - m[2, 2]) * 2.0
        q = (0.25 * s, (m[0, 1] + m[1, 0]) / s, (m[0, 2] + m[2, 0]) / s, (m[2, 1] - m[1, 2]) / s)
    elif m[1, 1] > m[2, 2]:
        s = math.sqrt(1.0 + m[1, 1] - m[0, 0] - m[2, 2]) * 2.0
        q = ((m[0, 1] + m[1, 0]) / s, 0.25 * s, (m[1, 2] + m[2, 1]) / s, (m[0, 2] - m[2, 0]) / s)
    else:
        s = math.sqrt(1.0 + m[2, 2] - m[0, 0] - m[1, 1]) * 2.0
        q = ((m[0, 2] + m[2, 0]) / s, (m[1, 2] + m[2, 1]) / s, 0.25 * s, (m[1, 0] - m[0, 1]) / s)
    return tuple(float(c) for c in q)


def flex_axis(finger, name, n, grip=None):
    """Kemiğin yerel +X'i: artı dönüş parmağı avuca kapatır (dört parmakta avuç normaline, başparmakta avucun ortasına)."""
    direction = finger["dir"]
    if name == "Thumb" and grip is not None:
        target = grip - finger["joints"][0]
        target = target - direction * (target @ direction)
        axis = np.cross(direction, target)
    else:
        axis = np.cross(direction, n)
    length_ = np.linalg.norm(axis)
    return axis / length_ if length_ > 1e-6 else np.cross(direction, n)


def strip_fingers(doc, binary):
    """Dosyada parmak kemiği varsa çıkarır: düğümler (hep listenin sonundadır), el düğümlerinin çocukları, skin eklem listesi, ters bağ matrisleri; köşe
    ağırlığına dokunmaz (ağırlık hep hamdan yazılır). Yeni bytes döndürür; yoksa aynısı."""
    nodes = doc["nodes"]
    skin = doc["skins"][0]
    finger_nodes = {i for i, node in enumerate(nodes) if node.get("name") in FINGER_BONES}
    if not finger_nodes:
        return binary
    keep = len(nodes) - len(finger_nodes)
    if min(finger_nodes) != keep:
        raise SystemExit("parmak düğümleri listenin sonunda değil: bu araç yazmadı")
    for node in nodes:
        if "children" in node:
            node["children"] = [c for c in node["children"] if c not in finger_nodes]
            if not node["children"]:
                del node["children"]
    del nodes[keep:]
    joints = [j for j in skin["joints"] if j not in finger_nodes]
    skin["joints"] = joints
    return _rewrite_ibm_view(doc, binary, joints, None)


def _rewrite_ibm_view(doc, binary, joints, matrices):
    """Ters bağ erişicisinin görünümünü yeni boyutla yazar (BIN yeniden dizilir: glb_prepare.pack_views). matrices None ise eski ilk len(joints) matris kalır."""
    views = doc["bufferViews"]
    skin = doc["skins"][0]
    acc = doc["accessors"][skin["inverseBindMatrices"]]
    view_index = acc["bufferView"]
    view = views[view_index]
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    if matrices is None:
        blob = bytes(binary[start: start + 64 * len(joints)])
    else:
        blob = np.asarray(matrices, np.float32).tobytes()
    blobs = [bytes(binary[v.get("byteOffset", 0): v.get("byteOffset", 0) + v["byteLength"]]) for v in views]
    blobs[view_index] = blob
    acc["byteOffset"] = 0
    acc["count"] = len(joints)
    return pack_views(doc, blobs)


def add_bones(doc, binary, hands):
    """Parmak düğümlerini, skin eklemlerini ve ters bağ matrislerini yazar (dosyada parmak kemiği olmamalı). Yeni bytes döndürür."""
    nodes = doc["nodes"]
    rig = rig_fix.Rig(doc)
    scale = _armature_scale(doc, rig)
    skin = doc["skins"][0]
    joints = list(skin["joints"])
    for side in SIDES:
        hand = hands[side]
        hand_node = rig.node_of[side + "Hand"]
        for name in FINGERS:
            finger = hand["fingers"].get(name)
            if finger is None:
                continue
            x = flex_axis(finger, name, hand["n"], finger.get("grip"))
            q_world = _rotation_from_axes(x, finger["dir"])
            parent_p, parent_q = rig.P[side + "Hand"], rig.Q[side + "Hand"]
            parent_node = hand_node
            for j, point in enumerate(finger["joints"]):
                p_arm = tuple(float(c) / scale for c in point)
                t = rig_fix.qrot(rig_fix.qconj(parent_q), rig_fix.sub(p_arm, parent_p))
                r = rig_fix.qnorm(rig_fix.qmul(rig_fix.qconj(parent_q), q_world))
                index = len(nodes)
                nodes.append({"name": finger_bone(side, name, j + 1), "rotation": [float(c) for c in r], "translation": [float(c) for c in t]})
                nodes[parent_node].setdefault("children", []).append(index)
                joints.append(index)
                parent_p, parent_q, parent_node = p_arm, q_world, index
    skin["joints"] = joints
    matrices = _bind_matrices(doc)
    return _rewrite_ibm_view(doc, binary, joints, matrices)


def _armature_scale(doc, rig):
    """Eklem biriminden metreye: Armature düğümünün ölçeği (Meshy'de 0,01). Dönüşlü kök bu aracın alanı dışındadır."""
    node = rig.parent_node.get(rig.node_of[rig.order[0]])
    scale = 1.0
    while node is not None:
        n = doc["nodes"][node]
        if abs(sum(c * c for c in n.get("rotation", (0, 0, 0, 1))[:3])) > 1e-8:
            raise SystemExit("iskeletin kökü döndürülmüş: bu araç beklemiyor")
        scale *= n.get("scale", (1, 1, 1))[0]
        node = rig.parent_node.get(node)
    return scale


def _bind_matrices(doc):
    """Skin eklem sırasıyla ters bağ matrisleri (sütun sırası: glTF)."""
    nodes = doc["nodes"]
    rig = rig_fix.Rig(doc)
    armature = [[1.0 if i == j else 0.0 for j in range(4)] for i in range(4)]
    chain = []
    node = rig.parent_node.get(rig.node_of[rig.order[0]])
    while node is not None:
        chain.append(node)
        node = rig.parent_node.get(node)
    for i in reversed(chain):
        n = nodes[i]
        armature = rig_fix.mat_mul(armature, rig_fix.trs_matrix(n.get("translation", (0, 0, 0)), n.get("rotation", (0, 0, 0, 1)), n.get("scale", (1, 1, 1))))
    world = {}
    for name in rig.order:
        n = nodes[rig.node_of[name]]
        local = rig_fix.trs_matrix(n.get("translation", (0, 0, 0)), n.get("rotation", (0, 0, 0, 1)), n.get("scale", (1, 1, 1)))
        parent = rig.parent[name]
        world[name] = rig_fix.mat_mul(world[parent] if parent else armature, local)
    out = []
    for name in rig.names:
        inv = rig_fix.affine_inverse(world[name])
        out.append([inv[r][c] for c in range(4) for r in range(4)])
    return out


# --- Rapor ---------------------------------------------------------------------------------------------------

def report(ids):
    for rig_id in ids:
        doc, binary = read_glb(rig_fix.model_path(rig_id))
        binary = strip_fingers(doc, binary)
        skin = Skin(doc, binary)
        dense = raw_weights(rig_fix.raw_source_id(rig_id), read_glb, skin.names)[0]
        hands = analyze(skin, dense, bind_positions(doc, binary, skin), Welded(skin.pos, skin.tris))
        for side in SIDES:
            hand = hands[side]
            parts = []
            for name in FINGERS:
                f = hand["fingers"].get(name)
                if f is None:
                    parts.append("%s yok" % name)
                    continue
                parts.append("%s %.1f/%.1f%s" % (name, np.linalg.norm(f["joints"][1] - f["joints"][0]) * 100, np.linalg.norm(f["tip"] - f["joints"][1]) * 100, "" if f["real"] else " kaynaşık"))
            print("%-16s %-5s %s" % (rig_id, side, " | ".join(parts)))
            for note in hand["notes"]:
                print("    " + note)


def main():
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    ids = [a for a in sys.argv[1:] if not a.startswith("--")]
    rig_fix.use_paths(flags)
    if "--report" in flags:
        report(ids or rig_fix.all_ids())
        return
    sys.exit(__doc__)


if __name__ == "__main__":
    main()
