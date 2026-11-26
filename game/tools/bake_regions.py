#!/usr/bin/env python3
"""
Meshy karakter modelleri için "bölge maskesi" pişirir (karakter oluşturucudaki renk değişimi için).

Çıktılar (modelin klasörüne):
  <id>_regions.png   R = saç, G = ten, B = göz bebeği (UV uzayında; chibi 1024x1024, gerçekçi 2048x2048)
  <id>_regions2.png  R = göz akı (stilde göz akı yoktur; ten rengine boyanır)
  <id>_regions.json  her bölgenin dokudaki ortalama rengi (shader bu renge göre yeniden boyar)

Nasıl çalışır?
  1. GLB içinden köşe konumları, normaller, UV'ler, iskelet ağırlıkları ve renk dokusu okunur.
  2. Üçgenler UV uzayında taranır; her doku pikselinin 3B konumu, yüzey yönü ve bağlı olduğu
     kemik bulunur.
  3. Kafa kemiğine bağlı pikseller saç / yüz / göz olarak, eller ve boyun ten olarak sınıflanır.
     Ten rengi yanaklardan, saç rengi kafanın tepesinden örneklenir.

İki oran ayrı ele alınır (kafanın boya oranına göre kendiliğinden seçilir):
  - chibi (kafa boyun ~%30'undan büyük): kafadaki ten/göz/ağız dışında kalan her şey saçtır; gözler
    kafanın belli bir bandındadır; dokuda boyalı göz akı tene boyanır.
  - gerçekçi (Mete, kadın kahraman): saç RENGİYLE bulunur (kafa tepesindeki saçın renk dağılımına
    benzeyen pikseller); böylece alın bandı, makyaj ve kaş altı gölgesi saç sayılmaz. Omuza ve göğse
    sarkan örgüler boyun/omurga kemiklerine bağlıdır; kafadaki saçtan başlayıp 3B uzayda bitişik, gövde
    yüzeyinden çıkıntılı saç renkli noktalara yayılarak (taşma dolgusu) bulunur ve kafanın altında dikey
    şerit olarak izlenir (aynı renkteki deri zırh bağları gövde yüzeyindedir, karışmaz). Kafadaki ten renkli
    ama yüz olmayan yüzeyler (saçtaki açık tutamlar, topuz bağı, alın bandının desenleri, örgü boncukları) yüz
    teninden ayıklanır: çevresinde ten payı düşük olanlar ve yüzün ortasına bağlı olmayanlar elenir. Gözler çeneden
    kafa boyunun yarısı yukarıdaki bantta aranır; gerçek göz akı korunur (tene boyanmaz). Yakadan görünen
    boyun teni yüzün teninden kesintisiz devam eden ten renkli yüzeydir; kafa-boyun geçiş üçgenleri de sayılır
    (sayılmasa çenenin altında boyanmamış şeritler kalır) ve boyun simetrik olduğu için aynası tende olmayan
    ten renkli yüzey (bronz toka, göğüs süsü) dışarıda bırakılır. Atlas çok parçalı olduğu için
    maske 2048 piksel ve az genişletmeyle yazılır (komşu adalara renk sızmaz).

Kullanım:
  python3 tools/bake_regions.py assets/characters/mete/mete.glb [--size 2048]
Gerekenler: python3 + numpy, ffmpeg (JPEG/PNG okuma-yazma için).
"""
import argparse
import json
import os
import struct
import subprocess
import sys
from collections import Counter

import numpy as np

COMPONENT = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
WIDTH = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}
HEAD_JOINTS = {"head", "head_end", "headfront"}
SKIN_JOINTS = {"lefthand", "righthand", "neck"}
# Gerçekçi modellerde örgülerin bağlı olabileceği kemikler (kafadan sarkan saç).
BRAID_JOINTS = {"neck", "spine", "spine01", "spine02", "leftshoulder", "rightshoulder", "leftarm", "rightarm"}
# Gerçekçi modellerde yakadan görünen boyun ve göğüs teninin bağlı olabileceği kemikler.
NECK_JOINTS = {"neck", "spine", "spine01", "spine02", "leftshoulder", "rightshoulder"}
NECK_DEPTH = 0.12
NECK_HALF_WIDTH = 0.09
# Gerçekçi yüzlerde göz bandının yarı yüksekliği (metre).
EYE_HALF_BAND = 0.022
# Maske çözünürlüğü ve adaların dışına genişletme (piksel): gerçekçi modellerin atlası çok parçalıdır.
SIZE_CHIBI = 1024
SIZE_REALISTIC = 2048
DILATE_CHIBI = 4
DILATE_REALISTIC = 2
# Kafa yüksekliği / boy oranı bundan küçükse model gerçekçi oranlı sayılır.
REALISTIC_HEAD_RATIO = 0.28
# Örgü taşma dolgusunun hücre boyu (metre; modelin bind pozu metre cinsindendir).
BRAID_VOXEL = 0.012
# Örgüler gövdenin (zırh, kaftan) önünde ya da arkasında sarkar: gövde yüzeyinden en az bu kadar
# (metre) çıkıntılı olmalılar. Gövde yüzeyi GRID_CELL boyunda (x, y) hücrelerinde tahmin edilir.
BRAID_PROTRUSION = 0.01
GRID_CELL = 0.025
# Örgünün çıkıntılı çekirdeğine bu kadar yakın (metre) saç renkli pikseller de örgüdür (yanları, alt yüzü).
BRAID_HALO = 0.015
# Kafanın altında örgüler dikey şeritler olarak izlenir: her yatay dilimde (metre) yalnızca bir üst dilimdeki
# şerit merkezine en fazla STRAND_HALF_WIDTH (metre) uzaklıktaki pikseller kalır (yandaki zırh bağları elenir).
STRAND_SLICE = 0.015
STRAND_HALF_WIDTH = 0.035
STRAND_GAP = 0.03
# Boyun ve göğüs teni simetriktir: aynasının (−x) bu kadar (metre) yakınında ten olmayan ten renkli yüzey bir süstür
# (ör. Mete'nin pelerin tokası, kadın kahramanın göğüs süsü; bronz, ten rengine çok yakındır).
MIRROR_TOLERANCE = 0.012
# Yüz teni ayıklama (gerçekçi modeller): FACE_DENSITY_VOXEL boyunda hücrelerin 27 komşuluğunda kafa piksellerinin en az
# FACE_MIN_SKIN_SHARE kadarı ten olmalı; kalan ten, yüzün ortasından FACE_VOXEL boyunda hücrelerle taşma dolgusuyla seçilir.
FACE_DENSITY_VOXEL = 0.008
FACE_MIN_SKIN_SHARE = 0.35
FACE_VOXEL = 0.006
LUMA = np.array([0.299, 0.587, 0.114])


# --- GLB okuma ------------------------------------------------------------------

def read_glb(path):
    data = open(path, "rb").read()
    magic, _version, _length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF":
        raise ValueError("GLB değil: " + path)
    offset = 12
    gltf, binary = None, None
    while offset < len(data):
        chunk_len, chunk_type = struct.unpack_from("<II", data, offset)
        chunk = data[offset + 8: offset + 8 + chunk_len]
        if chunk_type == 0x4E4F534A:
            gltf = json.loads(chunk)
        elif chunk_type == 0x004E4942:
            binary = chunk
        offset += 8 + chunk_len
    return gltf, binary


def accessor(gltf, binary, index):
    acc = gltf["accessors"][index]
    view = gltf["bufferViews"][acc["bufferView"]]
    dtype = COMPONENT[acc["componentType"]]
    width = WIDTH[acc["type"]]
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    item = np.dtype(dtype).itemsize * width
    stride = view.get("byteStride", item)
    count = acc["count"]
    raw = np.frombuffer(binary, dtype=np.uint8, count=stride * (count - 1) + item, offset=start)
    rows = np.lib.stride_tricks.as_strided(raw, shape=(count, item), strides=(stride, 1))
    out = np.frombuffer(rows.copy().tobytes(), dtype=dtype).reshape(count, width)
    if acc.get("normalized"):
        out = out.astype(np.float32) / np.iinfo(dtype).max
    return out


def decode_image(gltf, binary, image_index):
    img = gltf["images"][image_index]
    view = gltf["bufferViews"][img["bufferView"]]
    blob = binary[view.get("byteOffset", 0): view.get("byteOffset", 0) + view["byteLength"]]
    probe = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "stream=width,height", "-of", "csv=p=0", "-i", "pipe:0"],
                           input=blob, capture_output=True, check=True)
    w, h = [int(v) for v in probe.stdout.decode().strip().split(",")[:2]]
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", "pipe:0", "-f", "rawvideo", "-pix_fmt", "rgb24", "pipe:1"],
                         input=blob, capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.uint8).reshape(h, w, 3).astype(np.float32) / 255.0


def write_png(path, img):
    h, w, c = img.shape
    data = np.clip(img * 255.0 + 0.5, 0, 255).astype(np.uint8).tobytes()
    fmt = "rgba" if c == 4 else "rgb24"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", fmt, "-s", f"{w}x{h}", "-i", "pipe:0", path],
                   input=data, check=True)


# --- Tarama (rasterization) -------------------------------------------------------

def rasterize(uv, tris, size):
    """Her üçgeni UV uzayında tarar. Dönen: (piksel_y, piksel_x, üçgen_no, ağırlıklar[3])."""
    ys, xs, ids, weights = [], [], [], []
    px = uv * size
    for t, (a, b, c) in enumerate(tris):
        p0, p1, p2 = px[a], px[b], px[c]
        x0 = int(np.floor(min(p0[0], p1[0], p2[0]))); x1 = int(np.ceil(max(p0[0], p1[0], p2[0])))
        y0 = int(np.floor(min(p0[1], p1[1], p2[1]))); y1 = int(np.ceil(max(p0[1], p1[1], p2[1])))
        if x1 < 0 or y1 < 0 or x0 >= size or y0 >= size:
            continue
        x0, y0 = max(x0, 0), max(y0, 0)
        x1, y1 = min(x1, size - 1), min(y1, size - 1)
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        gx, gy = gx.ravel(), gy.ravel()
        d = (p1[1] - p2[1]) * (p0[0] - p2[0]) + (p2[0] - p1[0]) * (p0[1] - p2[1])
        if abs(d) < 1e-12:
            continue
        w0 = ((p1[1] - p2[1]) * (gx - p2[0]) + (p2[0] - p1[0]) * (gy - p2[1])) / d
        w1 = ((p2[1] - p0[1]) * (gx - p2[0]) + (p0[0] - p2[0]) * (gy - p2[1])) / d
        w2 = 1.0 - w0 - w1
        inside = (w0 >= -0.02) & (w1 >= -0.02) & (w2 >= -0.02)
        if not inside.any():
            # Çok küçük üçgen: en azından merkez pikselini işaretle.
            cx, cy = (p0 + p1 + p2) / 3.0
            gx, gy = np.array([cx]), np.array([cy])
            w0, w1, w2 = np.array([1 / 3]), np.array([1 / 3]), np.array([1 / 3])
            inside = np.array([True])
        xs.append(np.clip(gx[inside].astype(int), 0, size - 1))
        ys.append(np.clip(gy[inside].astype(int), 0, size - 1))
        ids.append(np.full(inside.sum(), t))
        weights.append(np.stack([w0[inside], w1[inside], w2[inside]], axis=1))
    return np.concatenate(ys), np.concatenate(xs), np.concatenate(ids), np.concatenate(weights)


def dilate(mask, steps, free=None):
    """Maskeyi UV ada sınırlarının dışına doğru genişletir (dikiş izlerini önler).
    free verilirse yalnızca hiçbir üçgenin kapsamadığı boş piksellere taşar; komşu adalara sızmaz."""
    out = mask.copy()
    for _ in range(steps):
        grown = out.copy()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            grown = np.maximum(grown, np.roll(np.roll(out, dy, axis=0), dx, axis=1))
        out = grown if free is None else np.where(free, grown, out)
    return out


def blur(mask):
    k = np.array([1.0, 2.0, 1.0]) / 4.0
    out = mask.copy()
    for axis in (0, 1):
        out = sum(np.roll(out, s, axis=axis) * w for s, w in zip((-1, 0, 1), k))
    return out


# --- Sınıflandırma ---------------------------------------------------------------

def to_hex(c):
    c = np.clip(np.asarray(c), 0, 1)
    return "#%02x%02x%02x" % tuple(int(v * 255 + 0.5) for v in c)


def hsv(colors):
    """RGB (0..1) → (ton 0..1, doygunluk, parlaklık)."""
    mx = colors.max(axis=-1)
    mn = colors.min(axis=-1)
    delta = mx - mn + 1e-6
    r, g, b = colors[..., 0], colors[..., 1], colors[..., 2]
    hue = np.where(mx == r, ((g - b) / delta) % 6.0, np.where(mx == g, (b - r) / delta + 2.0, (r - g) / delta + 4.0)) / 6.0
    sat = np.where(mx > 1e-4, (mx - mn) / (mx + 1e-6), 0.0)
    return hue, sat, mx


def skin_like(colors, ref, hue_tol=0.035, sat_lo=0.45, sat_hi=1.9):
    """Ten rengine benzerlik: aynı ton ailesi, benzer doygunluk; gölgeli ten de kabul edilir.
    Beyaz kumaş/saç (doygunluk ~0) ve kırmızı pelerin (çok doygun) dışarıda kalır."""
    hue, sat, val = hsv(colors)
    rh, rs, _rv = hsv(np.asarray(ref, dtype=np.float32)[None, :])
    dh = np.abs(hue - rh[0])
    dh = np.minimum(dh, 1.0 - dh)
    return (dh < hue_tol) & (sat > rs[0] * sat_lo) & (sat < rs[0] * sat_hi + 0.05) & (val > 0.3)


def bake(path, size=None):
    """Maskeleri pişirir. size verilmezse chibi modellerde 1024, gerçekçi modellerde 2048 kullanılır:
    Meshy'nin gerçekçi modellerinin doku atlası binlerce küçük adaya bölünmüştür; düşük çözünürlükte
    komşu adaların kenarları (çift doğrusal süzgeç yüzünden) birbirinin rengini alır."""
    px, realistic = sample_pixels(path, size)
    size = px["size"]
    ys, xs = px["ys"], px["xs"]
    grow = DILATE_REALISTIC if realistic else DILATE_CHIBI
    regions = classify_realistic(px) if realistic else classify_chibi(px)
    hair, skin, eye, sclera = regions["hair"], regions["skin"], regions["eye"], regions["sclera"]

    covered = np.zeros((size, size), dtype=bool)
    covered[ys, xs] = True
    mask = np.zeros((size, size, 3), dtype=np.float32)
    extra = np.zeros((size, size, 3), dtype=np.float32)
    for channel, sel in enumerate((hair, skin, eye, sclera)):
        layer = np.zeros((size, size), dtype=np.float32)
        layer[ys[sel], xs[sel]] = 1.0
        # Kenarları hafifçe yumuşat ama yumuşatmayı yalnızca bölgenin kendi adası ve boşluklarla sınırla.
        soft = blur(layer)
        layer = np.where(covered, np.maximum(layer * 0.0 + np.where(layer > 0, 1.0, 0.0), soft * (layer > 0)), soft)
        layer = dilate(layer, grow, free=~covered)
        if channel < 3:
            mask[:, :, channel] = np.clip(layer, 0, 1)
        else:
            extra[:, :, 0] = np.clip(layer, 0, 1)

    base, _ = os.path.splitext(path)
    out_png = base + "_regions.png"
    write_png(out_png, mask)
    # Ek maske (alfa kanalı kullanılmaz: Godot içe aktarırken saydam piksellerin rengini değiştirir).
    write_png(base + "_regions2.png", extra)
    info = {
        "hair_base": to_hex(regions["hair_ref"]), "skin_base": to_hex(regions["skin_ref"]), "eye_base": to_hex(regions["eye_ref"]),
        "mode": "gerçekçi" if realistic else "chibi",
        "pixels": {"hair": int(hair.sum()), "skin": int(skin.sum()), "eye": int(eye.sum()), "sclera": int(sclera.sum())},
        "note": "tools/bake_regions.py ile üretildi; _regions.png R=saç G=ten B=göz; _regions2.png R=göz akı (tene boyanır)",
    }
    with open(base + "_regions.json", "w", encoding="utf-8") as f:
        json.dump(info, f, ensure_ascii=False, indent=2)
    return out_png, info


def sample_pixels(path, size=None):
    """GLB'yi okur ve UV uzayında taranan her doku pikselinin 3B bilgisini döndürür: (px sözlüğü, gerçekçi mi).
    size verilmezse modelin oranına göre seçilir (SIZE_CHIBI / SIZE_REALISTIC)."""
    gltf, binary = read_glb(path)
    prim = gltf["meshes"][0]["primitives"][0]
    attrs = prim["attributes"]
    pos = accessor(gltf, binary, attrs["POSITION"]).astype(np.float32)
    nrm = accessor(gltf, binary, attrs["NORMAL"]).astype(np.float32)
    uv = accessor(gltf, binary, attrs["TEXCOORD_0"]).astype(np.float32)
    tris = accessor(gltf, binary, prim["indices"]).reshape(-1, 3).astype(np.int64)
    joints = accessor(gltf, binary, attrs["JOINTS_0"]).astype(np.int64)
    weights = accessor(gltf, binary, attrs["WEIGHTS_0"]).astype(np.float32)
    joint_names = [gltf["nodes"][j].get("name", "").lower() for j in gltf["skins"][0]["joints"]]
    material = gltf["materials"][prim.get("material", 0)]
    tex_index = material["pbrMetallicRoughness"]["baseColorTexture"]["index"]
    texture = decode_image(gltf, binary, gltf["textures"][tex_index]["source"])

    # Köşe başına baskın kemik → kafa / ten bölgesi.
    dominant = joints[np.arange(len(joints)), np.argmax(weights, axis=1)]
    names = np.array(joint_names)[dominant]
    vert_head = np.isin(names, list(HEAD_JOINTS))
    # Kafanın sınırları (saç dahil) ve boya oranı → chibi mi, gerçekçi mi?
    hp = pos[vert_head]
    y_lo, y_hi = hp[:, 1].min(), hp[:, 1].max()
    height = max(pos[:, 1].max() - pos[:, 1].min(), 1e-3)
    realistic = (y_hi - y_lo) / height < REALISTIC_HEAD_RATIO
    if size is None:
        size = SIZE_REALISTIC if realistic else SIZE_CHIBI

    ys, xs, tri_ids, bary = rasterize(uv, tris, size)
    corner = tris[tri_ids]
    th, tw, _ = texture.shape
    color = texture[np.clip((ys + 0.5) / size * th, 0, th - 1).astype(int), np.clip((xs + 0.5) / size * tw, 0, tw - 1).astype(int)]
    px = {
        "p": np.einsum("nk,nkd->nd", bary, pos[corner]),
        "n": np.einsum("nk,nkd->nd", bary, nrm[corner]),
        "color": color,
        "lum": color @ LUMA,
        "sat": color.max(axis=1) - color.min(axis=1),
        "head": vert_head[corner].sum(axis=1) >= 2,
        "skin_joint": np.isin(names, list(SKIN_JOINTS))[corner].sum(axis=1) >= 2,
        # Pikselin en çok bağlı olduğu köşenin baskın kemiği.
        "joint": names[corner[np.arange(len(corner)), np.argmax(bary, axis=1)]],
        "ys": ys, "xs": xs, "size": size,
    }
    px["n"] /= np.linalg.norm(px["n"], axis=1, keepdims=True) + 1e-6

    # Kafaya göre göreli konum.
    half_w = max(abs(hp[:, 0]).max(), 1e-3)
    px["rel_y"] = (px["p"][:, 1] - y_lo) / max(y_hi - y_lo, 1e-3)
    px["rel_x"] = np.abs(px["p"][:, 0]) / half_w
    hips = pos[np.isin(names, ["hips"])]
    px["waist_y"] = hips[:, 1].mean() if len(hips) else pos[:, 1].min() + height * 0.5
    px["joints"] = joint_positions(gltf, binary)
    return px, realistic


def joint_positions(gltf, binary):
    """Eklemlerin bind pozundaki konumları (ters bind matrislerinden; ad küçük harfle → konum)."""
    skin = gltf["skins"][0]
    if "inverseBindMatrices" not in skin:
        return {}
    ibm = accessor(gltf, binary, skin["inverseBindMatrices"]).reshape(-1, 4, 4).transpose(0, 2, 1)
    out = {}
    for k, j in enumerate(skin["joints"]):
        out[gltf["nodes"][j].get("name", "").lower()] = np.linalg.inv(ibm[k].astype(np.float64))[:3, 3]
    return out


def reference_colors(px):
    """Ten rengi yanakların doygun ve aydınlık piksellerinden (yandan düşen saç tutamları beyaz/koyu
    olduğu için elenir), saç rengi kafanın tepesinden örneklenir."""
    head, rel_y, rel_x = px["head"], px["rel_y"], px["rel_x"]
    front = px["n"][:, 2] > 0.45
    face_zone = head & front & (rel_y > 0.12) & (rel_y < 0.5) & (rel_x < 0.55)
    cheeks = face_zone & (px["sat"] > 0.1) & (px["lum"] > 0.45)
    skin_ref = np.median(px["color"][cheeks], axis=0) if cheeks.sum() > 20 else np.array([0.95, 0.78, 0.65])
    crown = head & (rel_y > 0.86)
    hair_ref = np.median(px["color"][crown], axis=0) if crown.sum() > 20 else np.array([0.3, 0.2, 0.15])
    return skin_ref, hair_ref, crown


def classify_chibi(px):
    """Chibi modeller (eski yol, değişmedi): kafada ten/göz/ağız dışındaki her şey saçtır."""
    head, rel_y, rel_x, n, p = px["head"], px["rel_y"], px["rel_x"], px["n"], px["p"]
    color, lum, sat = px["color"], px["lum"], px["sat"]
    ys, xs, size = px["ys"], px["xs"], px["size"]
    front = n[:, 2] > 0.45
    skin_ref, hair_ref, _crown = reference_colors(px)
    is_skin = skin_like(color, skin_ref)
    # Gözler: yüzün tam önünde, burun hizasının üstünde, ortanın iki yanında (kâkül ve kaşlar dışarıda kalsın).
    eye_band = head & (n[:, 2] > 0.7) & (rel_y > 0.24) & (rel_y < 0.45) & (rel_x > 0.06) & (rel_x < 0.58)
    eye = eye_band & (lum < 0.33) & ~is_skin
    mouth = head & front & (rel_y < 0.3) & (rel_x < 0.35) & ~is_skin
    skin = (head | px["skin_joint"]) & is_skin
    hair = head & ~skin & ~eye & ~mouth & ~(eye_band & (lum > 0.85))
    eye_ref = np.median(color[eye], axis=0) if eye.sum() > 10 else np.array([0.2, 0.15, 0.12])
    # Göz akı: göz bebeğinin UV'de hemen çevresindeki çok açık, doygunluğu düşük pikseller.
    # (Stilde göz akı yok; tene boyanır. Yalnızca göz bebeği komşuluğuna bakıldığı için beyaz saç tutamları karışmaz.)
    iris_layer = np.zeros((size, size), dtype=np.float32)
    iris_layer[ys[eye], xs[eye]] = 1.0
    near_iris = dilate(iris_layer, 7)[ys, xs] > 0.5
    # Ayrıca göz yüksekliğinde, yüzün önünde ve gözlerin iki yanında kalan açık şeritler (dokudaki göz akı
    # boyaması ya da yüzü kesen açık tutamlar). Referans stilde bu bölgede beyaz yoktur.
    eye_front = eye & (n[:, 2] > 0.6)
    if eye_front.sum() > 10:
        ey0, ey1 = np.percentile(p[eye_front, 1], 5), np.percentile(p[eye_front, 1], 95)
        side_band = head & (n[:, 2] > 0.55) & (p[:, 1] > ey0 - 0.004) & (p[:, 1] < ey1 + 0.008) & (rel_x > 0.15) & (rel_x < 0.7)
    else:
        side_band = np.zeros_like(head)
    sclera = head & front & (near_iris | side_band) & (lum > 0.7) & (sat < 0.16) & ~eye
    hair = hair & ~sclera
    return {"hair": hair, "skin": skin, "eye": eye, "sclera": sclera,
            "hair_ref": hair_ref, "skin_ref": skin_ref, "eye_ref": eye_ref}


def hair_like(px, sample):
    """Örnek saç piksellerinin (kafa tepesi) renk dağılımına benzeyen pikseller: parlaklık örneğin
    %5-%95 aralığında (biraz pay ile), renk tonu (parlaklıktan arındırılmış renk) örneğin medyanına yakın."""
    color, lum = px["color"], px["lum"]
    if sample.sum() < 20:
        return np.zeros(len(lum), dtype=bool)
    s_lum = lum[sample]
    lo, hi = np.percentile(s_lum, 5), np.percentile(s_lum, 95)
    chroma = color - lum[:, None]
    ref = np.median(chroma[sample], axis=0)
    spread = np.percentile(np.linalg.norm(chroma[sample] - ref, axis=1), 90)
    tol = max(0.045, spread * 1.3)
    return (lum > lo - 0.04) & (lum < hi + 0.06) & (np.linalg.norm(chroma - ref, axis=1) < tol)


def near_cells(px, core, others, radius):
    """others içindeki, core noktalarına radius kadar yakın pikseller (radius boyunda hücrelerle, 27 komşu)."""
    keys = np.floor(px["p"] / radius).astype(np.int64)
    core_cells = set(map(tuple, keys[core]))
    near = set()
    for x, y, z in core_cells:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for dz in (-1, 0, 1):
                    near.add((x + dx, y + dy, z + dz))
    idx = np.nonzero(others)[0]
    hit = np.array([tuple(k) in near for k in keys[idx]], dtype=bool)
    out = np.zeros(len(others), dtype=bool)
    out[idx[hit]] = True
    return out


def flood_braids(px, seeds, candidates):
    """Kafadaki saçtan (seeds) başlayıp 3B uzayda bitişik aday piksellere (örgüler) yayılır.
    Noktalar BRAID_VOXEL boyunda hücrelere bölünür; 26 komşulukla genişlik öncelikli arama yapılır."""
    return flood(px, seeds, candidates, BRAID_VOXEL)


def dense_among(px, sel, among, voxel, min_share):
    """sel içindeki piksellerden, çevresindeki (voxel boyunda 27 hücre) among piksellerinin en az min_share kadarı
    sel olanlar. Seyrek seçimler elenir: ör. koyu saçın içindeki ten renkli parlak tutamlar."""
    keys = np.floor(px["p"] / voxel).astype(np.int64)
    sel_count = Counter(map(tuple, keys[sel]))
    all_count = Counter(map(tuple, keys[among]))
    idx = np.nonzero(sel)[0]
    offsets = [(dx, dy, dz) for dx in (-1, 0, 1) for dy in (-1, 0, 1) for dz in (-1, 0, 1)]
    keep = np.zeros(len(idx), dtype=bool)
    for j, (x, y, z) in enumerate(keys[idx]):
        s = sum(sel_count.get((x + dx, y + dy, z + dz), 0) for dx, dy, dz in offsets)
        a = sum(all_count.get((x + dx, y + dy, z + dz), 0) for dx, dy, dz in offsets)
        keep[j] = s >= min_share * max(a, 1)
    out = np.zeros(len(sel), dtype=bool)
    out[idx[keep]] = True
    return out


def flood(px, seeds, candidates, voxel):
    """seeds piksellerinin hücrelerinden başlayıp 3B uzayda bitişik candidates piksellerine yayılır (voxel boyunda
    hücreler, 26 komşuluk, genişlik öncelikli arama). Döner: ulaşılan candidates pikselleri."""
    keys = np.floor(px["p"] / voxel).astype(np.int64)
    cand_cells = set(map(tuple, keys[candidates]))
    frontier = list(set(map(tuple, keys[seeds])))
    reached = set(frontier)
    offsets = [(dx, dy, dz) for dx in (-1, 0, 1) for dy in (-1, 0, 1) for dz in (-1, 0, 1) if dx or dy or dz]
    while frontier:
        nxt = []
        for x, y, z in frontier:
            for dx, dy, dz in offsets:
                c = (x + dx, y + dy, z + dz)
                if c in cand_cells and c not in reached:
                    reached.add(c)
                    nxt.append(c)
        frontier = nxt
    hit = np.array([tuple(k) in reached for k in keys[candidates]], dtype=bool)
    out = np.zeros(len(candidates), dtype=bool)
    out[np.nonzero(candidates)[0][hit]] = True
    return out


def protrusion(px, body):
    """Her pikselin gövde yüzeyinden ne kadar dışarıda olduğu (metre; önde +z, arkada -z yönünde).
    Gövde yüzeyi, o (x, y) hücresindeki öne (arkaya) bakan piksellerin z değerlerinin %25'lik
    (%75'lik) dilimidir: ince örgü yüzeyi hücrenin az bir kısmını kaplar, geniş zırh ise çoğunu."""
    p, nz = px["p"], px["n"][:, 2]
    center_z = np.median(p[body, 2]) if body.any() else 0.0
    cells = np.floor(p[:, :2] / GRID_CELL).astype(np.int64)
    key = cells[:, 0] * 100003 + cells[:, 1]
    out = np.full(len(p), -1.0)
    for side, sign in ((p[:, 2] >= center_z, 1.0), (p[:, 2] < center_z, -1.0)):
        facing = body & side & (nz * sign > 0.2)
        if not facing.any():
            continue
        order = np.argsort(key[facing])
        k_sorted = key[facing][order]
        z_sorted = (p[facing, 2] * sign)[order]
        uniq, start = np.unique(k_sorted, return_index=True)
        surface = {}
        for i, k in enumerate(uniq):
            end = start[i + 1] if i + 1 < len(start) else len(k_sorted)
            surface[k] = np.percentile(z_sorted[start[i]:end], 25)
        idx = np.nonzero(side)[0]
        base = np.array([surface.get(k, np.inf) for k in key[idx]])
        out[idx] = p[idx, 2] * sign - base
    return out


def mirror_supported(px, sel, support, tol=MIRROR_TOLERANCE):
    """sel içindeki piksellerden, x'e göre aynasının (−x, y, z) tol kadar yakınında support pikseli olanlar.
    Vücut (yüz, boyun) bind pozunda simetriktir; tek yanda kalan yüzey (toka, broş, boncuk) elenir."""
    keys = set(map(tuple, np.floor(px["p"][support] / tol).astype(np.int64)))
    idx = np.nonzero(sel)[0]
    mirrored = np.floor(px["p"][idx] * np.array([-1.0, 1.0, 1.0]) / tol).astype(np.int64)
    offsets = [(dx, dy, dz) for dx in (-1, 0, 1) for dy in (-1, 0, 1) for dz in (-1, 0, 1)]
    hit = np.array([any((x + dx, y + dy, z + dz) in keys for dx, dy, dz in offsets) for x, y, z in mirrored], dtype=bool)
    out = np.zeros(len(sel), dtype=bool)
    out[idx[hit]] = True
    return out


def strand_clusters(xs, gap):
    """x değerlerini aralarında gap'ten büyük boşluk olan kümelere ayırır; küme merkezlerini (medyan) döndürür."""
    order = np.sort(xs)
    centers, start = [], 0
    for i in range(1, len(order) + 1):
        if i == len(order) or order[i] - order[i - 1] > gap:
            centers.append(float(np.median(order[start:i])))
            start = i
    return centers


def trim_strands(px, braids, head_bottom):
    """Kafanın altındaki örgü piksellerini dikey şerit izleyerek kırpar: her dilimde yalnızca üstteki dilimin
    şerit merkezlerine yakın pikseller kalır. Örgüye bitişik aynı renkli zırh bağları böylece elenir."""
    p = px["p"]
    idx = np.nonzero(braids)[0]
    keep = braids & (p[:, 1] >= head_bottom)
    below = idx[p[idx, 1] < head_bottom]
    if len(below) == 0:
        return keep
    slice_of = np.floor(p[below, 1] / STRAND_SLICE).astype(np.int64)
    centers = []
    for k in range(slice_of.max(), slice_of.min() - 1, -1):
        sel = below[slice_of == k]
        if len(sel) == 0:
            continue
        xs = p[sel, 0]
        if not centers:
            centers = strand_clusters(xs, STRAND_GAP)
        moved = []
        for cx in centers:
            near = np.abs(xs - cx) < STRAND_HALF_WIDTH
            if near.any():
                keep[sel[near]] = True
                moved.append(0.5 * cx + 0.5 * float(np.median(xs[near])))
            else:
                moved.append(cx)
        centers = moved
    return keep


def classify_realistic(px):
    """Gerçekçi oranlı modeller (Mete, kadın kahraman): saç rengiyle bulunur, örgüler taşma dolgusuyla
    eklenir, gözler yüzün ten bölgesine göre konumlanır; göz akı korunur."""
    head, n, p = px["head"], px["n"], px["p"]
    color, lum, sat = px["color"], px["lum"], px["sat"]
    skin_ref, hair_ref, crown = reference_colors(px)
    is_skin = skin_like(color, skin_ref)
    like_hair = hair_like(px, crown & ~is_skin)

    # Yüz: kafanın önündeki ten pikselleri. Göz hizası çeneden (yüz teninin alt ucu) kafa boyunun yarısı kadar
    # yukarıdadır (kafa boyu: "Head" ekleminden kafa tepesi "head_end" eklemine). Alnı açık, saçı tepede toplanmış
    # karakterlerde yüz teni çok yukarı uzandığı için yüz teninin oranı kullanılamaz (kâkül göz sanılır).
    face = head & (n[:, 2] > 0.35) & is_skin
    eye = np.zeros(len(lum), dtype=bool)
    if face.sum() > 50:
        fy0, fy1 = np.percentile(p[face, 1], 2), np.percentile(p[face, 1], 98)
        fx = max(np.percentile(np.abs(p[face, 0]), 95), 1e-3)
        joints = px.get("joints", {})
        if "head" in joints and "head_end" in joints:
            eye_y = fy0 + 0.5 * (joints["head_end"][1] - joints["head"][1])
        else:
            eye_y = fy0 + 0.45 * (fy1 - fy0)
        band = head & (n[:, 2] > 0.55) & (np.abs(p[:, 1] - eye_y) < EYE_HALF_BAND)
        band &= (np.abs(p[:, 0]) > 0.08 * fx) & (np.abs(p[:, 0]) < 0.75 * fx)
        # Göz bebeği: ten ve göz akı olmayan koyu ya da renkli pikseller. Kirpikler de sayılabilir; boyama
        # parlaklığı koruduğu için koyu kirpik koyu kalır.
        eye = band & ~is_skin & (lum < 0.55) & ~((sat < 0.12) & (lum > 0.7))
    eye_ref = np.median(color[eye], axis=0) if eye.sum() > 10 else np.array([0.2, 0.15, 0.12])

    head_hair = head & like_hair & ~is_skin & ~eye
    # Örgüler: kafadan sarkan, boyun/omurga/omuz kemiklerine bağlı, bel üstündeki saç renkli ve gövdeden
    # çıkıntılı pikseller (aynı renkteki deri zırh bağları gövde yüzeyindedir, çıkıntılı değildir).
    upper = ~head & (p[:, 1] > px["waist_y"])
    hairy = upper & like_hair & np.isin(px["joint"], list(BRAID_JOINTS))
    # Çekirdek: öne ya da arkaya bakan, gövdeden çıkıntılı saç renkli pikseller (yana bakan zırh kenarları
    # çıkıntılı görünebildiği için sayılmaz); sonra çekirdeğe yakın saç renkli pikseller eklenir.
    core = hairy & (np.abs(n[:, 2]) > 0.35) & (protrusion(px, upper) > BRAID_PROTRUSION)
    braids = np.zeros_like(head)
    head_bottom = p[head, 1].min() if head.any() else 0.0
    if core.any() and head_hair.any():
        braids = flood_braids(px, head_hair, core)
        braids |= near_cells(px, braids, hairy & ~braids, BRAID_HALO)
        braids = trim_strands(px, braids, head_bottom)
    hair = head_hair | braids
    # Ten: yüz, kulaklar ve eller; ayrıca yakadan görünen boyun (omuz/omurga kemiklerine bağlı; kafanın en fazla
    # NECK_DEPTH altında ve boyun genişliğinde). Yalnızca yüzün teninden kesintisiz devam eden ten renkli yüzey
    # alınır; böylece göğüsteki bronz toka, kürk yaka ya da bej kumaş tene karışmaz. Ten benzerliği de daha sıkıdır.
    face_skin = head & is_skin & ~hair
    # Kafaya bağlı ama yüz olmayan ten renkli yüzeyler (saçtaki parlak tutamlar, topuz bağı, alın bandının açık
    # desenleri, örgü başındaki bronz boncuklar) ayıklanır: önce çevresinde ten payı düşük olanlar, sonra yüzün
    # ortasına ince hücrelerle bağlı olmayanlar elenir. Yüz, kulaklar ve çene korunur.
    dense = dense_among(px, face_skin, head, FACE_DENSITY_VOXEL, FACE_MIN_SKIN_SHARE)
    face_core = dense & (n[:, 2] > 0.6) & (px["rel_x"] < 0.3) & (px["rel_y"] > 0.15) & (px["rel_y"] < 0.5)
    if face_core.any():
        face_skin = flood(px, face_core, dense, FACE_VOXEL)
    # Boynun arkası saçla örtülüdür; arkadaki kürk yaka ten sanılmasın diye yalnızca öne bakan yüzey. Kafa ile boyun
    # arasındaki geçiş üçgenleri (köşelerinden yalnızca biri kafaya bağlı) da boyundur: sayılmasalar çenenin altında
    # boyanmamış ten şeritleri kalır.
    neck_joints = list(NECK_JOINTS | HEAD_JOINTS)
    neckline = ~head & np.isin(px["joint"], neck_joints) & (p[:, 1] > head_bottom - NECK_DEPTH) & (n[:, 2] > 0.0)
    neckline &= (np.abs(p[:, 0]) < NECK_HALF_WIDTH) & skin_like(color, skin_ref, hue_tol=0.02, sat_lo=0.7, sat_hi=1.35)
    neck_skin = flood_braids(px, face_skin, neckline) if neckline.any() and face_skin.any() else np.zeros_like(head)
    if neck_skin.any():
        # Boyun teni simetriktir: aynası tende olmayan ten renkli yüzey (bronz toka, göğüs süsü) çıkarılır; kalan tenden
        # yüze bağlı olanlar yeniden seçilir (süsün kenarından kopan küçük adacıklar kalmasın).
        kept = neck_skin & mirror_supported(px, neck_skin, neck_skin | face_skin)
        neck_skin = flood_braids(px, face_skin, kept)
    skin = (face_skin | (px["skin_joint"] & is_skin) | neck_skin) & ~hair
    sclera = np.zeros(len(lum), dtype=bool)
    return {"hair": hair, "skin": skin, "eye": eye, "sclera": sclera,
            "hair_ref": hair_ref, "skin_ref": skin_ref, "eye_ref": eye_ref}


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("glb", nargs="+")
    parser.add_argument("--size", type=int, default=None, help="maske boyutu (varsayılan: chibi 1024, gerçekçi 2048)")
    args = parser.parse_args()
    for path in args.glb:
        out, info = bake(path, args.size)
        print(out, json.dumps(info, ensure_ascii=False))


if __name__ == "__main__":
    sys.exit(main())
