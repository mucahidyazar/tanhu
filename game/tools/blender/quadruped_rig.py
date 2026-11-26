#!/usr/bin/env python3
"""
Dört ayaklı varlık hattı (fauna.md §10, godot.md §6.7): Meshy'nin iskeletsiz ağından iskeletli oyun GLB'si, uzak sürü ağı ve binek ölçüleri.
Kredi harcamaz, Meshy çağırmaz. Türe özgü sayılar JSON tarifindedir (ör. tools/blender/quadruped_sheep.json); at ve öteki dört ayaklılar kendi
tarifiyle aynı betiği kullanır.

Kullanım (game/ klasöründe):
  /opt/homebrew/bin/blender -b --python tools/blender/quadruped_rig.py -- tools/blender/quadruped_sheep.json
  source tools/_godot_lock.sh; godot_import_locked                 # ilk koşuda .import dosyaları böyle doğar
  ... -- <tarif.json> --only=import; godot_import_locked           # klip döngüsü, doku sınıfı (ilk koşudan sonra bir kez)
  ... -- <tarif.json> --only=rig        # yalnız oyun GLB'si (Blender'sız da koşar: python3 tools/blender/quadruped_rig.py <tarif> --only=rig)
  ... -- <tarif.json> --only=far,meta   # uzak ağ (Blender ister) ve <id>.json
  ... -- <tarif.json> --debug-normal=<ara.glb>   # yalnız normalize edilmiş ağ (yeni türde burgu ve iskelet noktalarını kareye bakarak ayarlamak için)
  ... -- <tarif.json> --model=<id> --out=<klasör> # çok modelli tarifte (models: at) yalnız bir model; çıktı denemede başka klasöre ({id} modelin adı)
Metal kum havuzunda açılmadığından Blender komutları kum havuzu dışında koşar.

Hat:
  1. Normalize: gövde hattı +z'ye, taban y = 0'a, başın yana dönükse boyun burgusu ile öne (dilim dilim döndürme, ağırlıksız, hacim korur), boy uydurma.
  2. İskelet: gövde, karın, boyun, baş, kulak, kuyruk, dört bacak (üç bölüm + toynak). Görünen eklemler bacak kesitlerinden, yün içindekiler tariften.
  3. Ağırlık: Automatic Weights yerine bölge maskesi (renk + geometri) ve ağ üzerinde yumuşatma. UV dikişinde bölünmüş köşeler konuma göre kaynaştırılır:
     aynı konumdaki kopyalar aynı ağırlığı alır, dikiş açılmaz. Yün bacağa yalnız kısmen uyar; bacağın koyu derisi yünden bağımsızdır.
  4. Klipler: bacaklar analitik IK ile çözülür (basan toynak modele göre sabit hızla geri kayar: oyunda hayvan aynı hızla ilerleyince yerde durur).
     Yürüme fazları fauna.md §10: sol arka 0, sol ön 0,25, sağ arka 0,5, sağ ön 0,75; tırıs çapraz çift. Tarifte jump varsa (at) bir kez oynayan sıçrama
     klibi de basılır (pose_jump: toplanma, itiş, havada toplanmış bacaklar, ön sonra arka iniş; havadaki yay oyunun kodudur), evreleri <id>.json'a yazılır.
  5. Çıktı: GLB doğrudan yazılır (Blender dışa aktarıcısı kopyaları birleştirip köşe sırasını değiştirir), doku tools/glb_prepare.py ile sınıfın boyuna iner.
  6. Uzak ağ: Blender Decimate; Meshy atlası binlerce küçük adadır, indirgenen üçgen adalar arasında geçemez: her üçgen atlasta kendi bölgesinin
     ortalama rengini taşıyan küçük bir yamaya bakar. Aynı doku dosyasını kullanır (GLB görseli dış URI, Godot aynı Texture2D'yi yükler).

Bu betiğin ürettiği klipler ve ağ tools/blender/quadruped_measure.gd ile Godot'da ölçülür; kareler tools/blender/quadruped_preview.py ile çizilir.
"""
import json
import math
import os
import subprocess
import sys
import tempfile

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)
GAME = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import glb_prepare  # noqa: E402

try:
    import bpy  # Blender içinde koşarken
except ImportError:
    bpy = None


# --- Genel yardımcılar ------------------------------------------------------------------------------------------

def sstep(a, b, x):
    """Yumuşak basamak; a > b olursa ters yönde (a'da 0, b'de 1)."""
    t = np.clip((np.asarray(x, dtype=np.float64) - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def unit(v):
    v = np.asarray(v, dtype=np.float64)
    return v / max(np.linalg.norm(v), 1e-12)


def rot_x(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]], dtype=np.float64)


def rot_y(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]], dtype=np.float64)


def rot_z(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]], dtype=np.float64)


def euler_xyz(pitch=0.0, yaw=0.0, roll=0.0):
    """Derece; dünya eksenlerinde: +pitch burun aşağı (+x), +yaw sola (+y), +roll sol yan yukarı (+z)."""
    return rot_y(math.radians(yaw)) @ rot_x(math.radians(pitch)) @ rot_z(math.radians(roll))


def rot_between(a, b):
    """a birim vektörünü b birim vektörüne çeviren en küçük dönüş."""
    a, b = unit(a), unit(b)
    v = np.cross(a, b)
    c = float(np.dot(a, b))
    if c < -0.999999:
        axis = unit(np.cross(a, [1.0, 0.0, 0.0]) if abs(a[0]) < 0.9 else np.cross(a, [0.0, 1.0, 0.0]))
        return 2.0 * np.outer(axis, axis) - np.eye(3)
    k = np.array([[0, -v[2], v[1]], [v[2], 0, -v[0]], [-v[1], v[0], 0]], dtype=np.float64)
    return np.eye(3) + k + k @ k / (1.0 + c)


def mat_to_quat(m):
    """3×3 dönüş → (x, y, z, w)."""
    t = m[0, 0] + m[1, 1] + m[2, 2]
    if t > 0.0:
        s = math.sqrt(t + 1.0) * 2.0
        q = [(m[2, 1] - m[1, 2]) / s, (m[0, 2] - m[2, 0]) / s, (m[1, 0] - m[0, 1]) / s, 0.25 * s]
    elif m[0, 0] > m[1, 1] and m[0, 0] > m[2, 2]:
        s = math.sqrt(1.0 + m[0, 0] - m[1, 1] - m[2, 2]) * 2.0
        q = [0.25 * s, (m[0, 1] + m[1, 0]) / s, (m[0, 2] + m[2, 0]) / s, (m[2, 1] - m[1, 2]) / s]
    elif m[1, 1] > m[2, 2]:
        s = math.sqrt(1.0 + m[1, 1] - m[0, 0] - m[2, 2]) * 2.0
        q = [(m[0, 1] + m[1, 0]) / s, 0.25 * s, (m[1, 2] + m[2, 1]) / s, (m[0, 2] - m[2, 0]) / s]
    else:
        s = math.sqrt(1.0 + m[2, 2] - m[0, 0] - m[1, 1]) * 2.0
        q = [(m[0, 2] + m[2, 0]) / s, (m[1, 2] + m[2, 1]) / s, 0.25 * s, (m[1, 0] - m[0, 1]) / s]
    q = np.array(q, dtype=np.float64)
    return q / np.linalg.norm(q)


def frame_from_y(y_dir, x_ref=(1.0, 0.0, 0.0)):
    """Yerel +y kemik yönü, yerel +x x_ref'e en yakın olan dik çerçeve (sütunlar x, y, z)."""
    y = unit(y_dir)
    x_ref = np.asarray(x_ref, dtype=np.float64)
    if abs(np.dot(unit(x_ref), y)) > 0.95:
        x_ref = np.array([0.0, 0.0, 1.0]) if abs(y[2]) < 0.9 else np.array([1.0, 0.0, 0.0])
    z = unit(np.cross(x_ref, y))
    x = np.cross(y, z)
    return np.column_stack((x, y, z))


# --- Kaynak ve kaynaştırma ---------------------------------------------------------------------------------------

class Source:
    """Ham GLB: köşeler (float64), üçgenler, doku baytları."""

    def __init__(self, path):
        doc, binary = glb_prepare.read_glb(path)
        self.path = path
        prim = doc["meshes"][0]["primitives"][0]
        attrs = prim["attributes"]
        self.positions = self._accessor(doc, binary, attrs["POSITION"]).astype(np.float64)
        self.normals = self._accessor(doc, binary, attrs["NORMAL"]).astype(np.float64)
        self.uvs = self._accessor(doc, binary, attrs["TEXCOORD_0"]).astype(np.float32)
        self.tris = self._accessor(doc, binary, prim["indices"]).astype(np.uint32).reshape(-1, 3)
        image = doc["images"][0]
        view = doc["bufferViews"][image["bufferView"]]
        start = view.get("byteOffset", 0)
        self.image = binary[start:start + view["byteLength"]]
        self.mime = image.get("mimeType", "image/jpeg")
        self.material = doc["materials"][0]
        self.sampler = doc["samplers"][0] if doc.get("samplers") else {"magFilter": 9729, "minFilter": 9987}

    @staticmethod
    def _accessor(doc, binary, index):
        acc = doc["accessors"][index]
        view = doc["bufferViews"][acc["bufferView"]]
        num = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[acc["type"]]
        dtype = {5126: np.float32, 5125: np.uint32, 5123: np.uint16}[acc["componentType"]]
        offset = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
        return np.frombuffer(binary, dtype, acc["count"] * num, offset).reshape(acc["count"], num).copy()

    def thumbnail(self, size=1024):
        """Doku numpy dizisi (satır, sütun, RGB; 0..1), renk maskesi ve uzak ağ için küçültülmüş."""
        ext = ".jpg" if "jpeg" in self.mime else ".png"
        with tempfile.TemporaryDirectory() as tmp:
            src = os.path.join(tmp, "t" + ext)
            with open(src, "wb") as fh:
                fh.write(self.image)
            raw = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", src, "-vf", "scale=%d:%d:flags=area" % (size, size),
                                  "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], check=True, capture_output=True).stdout
        return np.frombuffer(raw, np.uint8).reshape(size, size, 3).astype(np.float32) / 255.0


class Welded:
    """Konuma göre kaynaştırılmış ağ: köşe → kaynak köşe eşlemesi, kenarlar, üçgenler. Ağırlık bu ağda hesaplanır."""

    def __init__(self, positions, tris, cell=1e-5):
        key = np.round(positions / cell).astype(np.int64)
        _, self.index = np.unique(key, axis=0, return_inverse=True)
        self.index = self.index.ravel()
        self.count = int(self.index.max()) + 1
        self.positions = np.zeros((self.count, 3))
        self.positions[self.index] = positions
        self.tris = self.index[tris]
        e = np.vstack((self.tris[:, [0, 1]], self.tris[:, [1, 2]], self.tris[:, [2, 0]]))
        e.sort(axis=1)
        self.edges = np.unique(e, axis=0)
        self.degree = np.zeros(self.count)
        np.add.at(self.degree, self.edges[:, 0], 1.0)
        np.add.at(self.degree, self.edges[:, 1], 1.0)

    def smooth(self, field, iterations, strength=0.5, pinned=None):
        """Ağ üzerinde Laplace yumuşatması; pinned (bool dizi) köşeler ilk değerinde kalır. field (n,) ya da (n, k)."""
        f = np.array(field, dtype=np.float64)
        base = f.copy()
        degree = np.maximum(self.degree, 1.0)
        if f.ndim == 2:
            degree = degree[:, None]
        a, b = self.edges[:, 0], self.edges[:, 1]
        for _ in range(iterations):
            acc = np.zeros_like(f)
            np.add.at(acc, a, f[b])
            np.add.at(acc, b, f[a])
            f = (1.0 - strength) * f + strength * acc / degree
            if pinned is not None:
                f[pinned] = base[pinned]
        return f

    def spread(self, values):
        """Kaynaşmış köşe değerini kaynak köşelere dağıtır."""
        return values[self.index]


# --- 1. Normalize ------------------------------------------------------------------------------------------------

def normalize(source, recipe):
    """Ham ağı oyun uzayına getirir. Döner: (konumlar, normaller, bilgi). Ham birimli sayılar tarifin normalize bölümündedir."""
    rc = recipe["normalize"]
    P = source.positions.copy()
    N = source.normals.copy()
    info = {}
    # Gövde hattı: gövde dilimlerinin orta çizgisi +z olur, x = 0'a oturur.
    ground = P[:, 1].min()
    zs = np.arange(rc["torso_z"][0], rc["torso_z"][1], 0.1)
    mids = []
    for z in zs:
        picked = (P[:, 2] >= z) & (P[:, 2] < z + 0.1) & (P[:, 1] > ground + rc["torso_min_height"])
        mids.append((P[picked, 0].min() + P[picked, 0].max()) * 0.5)
    slope, center_x = np.polyfit(zs + 0.05, mids, 1)
    yaw = math.atan(slope)
    c, s = math.cos(-yaw), math.sin(-yaw)
    x = P[:, 0] - center_x
    P[:, 0], P[:, 2] = c * x - s * P[:, 2], s * x + c * P[:, 2]
    N[:, 0], N[:, 2] = c * N[:, 0] - s * N[:, 2], s * N[:, 0] + c * N[:, 2]
    info["yaw_fix_deg"] = math.degrees(yaw)
    P[:, 1] -= ground
    # Boyun burgusu: her yatay dilim kendi merkezinde döner; dönüş yukarı doğru artar, baş bütün döner. Arkada gövdeye bağlı kısım z maskesiyle durur.
    # Ek burgular (isteğe bağlı, sırayla; kurt: arka gövde yana kıvrık): aynı yöntem, z_zero > z_full ise rampa geriye doğrudur.
    for tw in [rc.get("neck_twist")] + list(rc.get("extra_twists", [])):
        if not tw:
            continue
        t = sstep(tw["y0"], tw["y1"], P[:, 1])
        # Baş ve çevresi bütün döner (kulak ucu ve çene alt dilimlere insin diye yükseklikten bağımsız).
        rigid = sstep(tw["head_radius_zero"], tw["head_radius_full"], np.linalg.norm(P - np.array(tw["head_center"]), axis=1))
        t = t + (1.0 - t) * rigid
        cx = tw["center_low"][0] + (tw["center_high"][0] - tw["center_low"][0]) * t
        cz = tw["center_low"][1] + (tw["center_high"][1] - tw["center_low"][1]) * t
        dx, dz = P[:, 0] - cx, P[:, 2] - cz
        ramp = np.clip((P[:, 2] - tw["z_zero"]) / (tw["z_full"] - tw["z_zero"]), 0.0, 1.0)
        mask = ramp if tw.get("z_linear") else sstep(tw["z_zero"], tw["z_full"], P[:, 2])
        free = sstep(tw["y_free0"], tw["y_free1"], P[:, 1])
        mask = np.maximum(np.maximum(mask, free), rigid)
        angle = math.radians(tw["angle_deg"]) * t * mask
        ca, sa = np.cos(angle), np.sin(angle)
        P[:, 0], P[:, 2] = cx + ca * dx - sa * dz, cz + sa * dx + ca * dz
        N[:, 0], N[:, 2] = ca * N[:, 0] - sa * N[:, 2], sa * N[:, 0] + ca * N[:, 2]
    # Boy: omuz yüksekliği y ve x ölçeğini, burundan kuyruğa boy z ölçeğini verir (fark tarifin sınırını aşamaz).
    probe = rc["shoulder_probe"]
    picked = (np.abs(P[:, 2] - rc["shoulder_z"]) < probe) & (np.abs(P[:, 0]) < 0.15)
    shoulder_raw = float(np.percentile(P[picked, 1], 98.0))
    shoulder_mask = picked
    length_raw = float(P[:, 2].max() - P[:, 2].min())
    if "uniform_length_m" in rc:
        # Eşit ölçek: burundan kuyruk ucuna boy verilir, oran bozulmaz (kampın atı Horse.MODEL_LENGTH'e göre ölçülüdür).
        scale_y = scale_z = rc["uniform_length_m"] / length_raw
    else:
        scale_y = rc["shoulder_m"] / shoulder_raw
        scale_z = rc["length_m"] / length_raw
        scale_z = max(scale_z, scale_y * rc["z_squash_limit"])
    scales = np.array([scale_y, scale_y, scale_z])
    P = P * scales
    N = N / scales
    N /= np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-9)
    info["scale_y"] = scale_y
    info["scale_z"] = scale_z
    # Başlangıç: dört ayağın ortası (dönüş ekseni hayvanın altında kalsın).
    low = P[:, 1] < 0.03
    mids_z = []
    for sign_z in (1.0, -1.0):
        for sign_x in (1.0, -1.0):
            q = P[low & (np.sign(P[:, 0]) == sign_x) & (np.sign(P[:, 2]) == sign_z)]
            mids_z.append((q[:, 2].min() + q[:, 2].max()) * 0.5)
    P[:, 2] -= (mids_z[0] + mids_z[1] + mids_z[2] + mids_z[3]) * 0.25
    info["shoulder_m"] = float(np.percentile(P[shoulder_mask, 1], 98.0))
    return P, N, info


def write_debug_mesh(path, P, N, source, image=None):
    """Ara ağı iskeletsiz yazar (yalnız önizleme için)."""
    w = GlbWriter()
    pos = w.accessor(P.astype(np.float32), 5126, "VEC3", 34962, minmax=True)
    nor = w.accessor(N.astype(np.float32), 5126, "VEC3", 34962)
    uv = w.accessor(source.uvs, 5126, "VEC2", 34962)
    idx = w.accessor(source.tris.ravel(), 5125, "SCALAR", 34963)
    img = w.blob_view(image if image is not None else source.image)
    doc = {"asset": {"version": "2.0"}, "scene": 0, "scenes": [{"nodes": [0]}], "nodes": [{"mesh": 0, "name": "debug"}],
           "meshes": [{"primitives": [{"attributes": {"POSITION": pos, "NORMAL": nor, "TEXCOORD_0": uv}, "indices": idx, "material": 0}]}],
           "materials": [source.material], "textures": [{"source": 0, "sampler": 0}], "samplers": [source.sampler],
           "images": [{"bufferView": img, "mimeType": source.mime}]}
    w.finish(path, doc)


class GlbWriter:
    """Küçük GLB yazıcısı: erişiciler ve görünümler tek BIN bölümünde."""

    def __init__(self):
        self.parts = []
        self.size = 0
        self.views = []
        self.accessors = []

    def _append(self, data):
        pad = (4 - self.size % 4) % 4
        if pad:
            self.parts.append(b"\0" * pad)
            self.size += pad
        offset = self.size
        self.parts.append(data)
        self.size += len(data)
        return offset

    def blob_view(self, data):
        self.views.append({"buffer": 0, "byteOffset": self._append(data), "byteLength": len(data)})
        return len(self.views) - 1

    def accessor(self, array, component, kind, target=None, minmax=False, normalized=False):
        data = array.tobytes()
        view = {"buffer": 0, "byteOffset": self._append(data), "byteLength": len(data)}
        if target:
            view["target"] = target
        self.views.append(view)
        count = array.size if kind == "SCALAR" else array.shape[0]
        acc = {"bufferView": len(self.views) - 1, "componentType": component, "count": int(count), "type": kind}
        if normalized:
            acc["normalized"] = True
        if minmax:
            flat = array.reshape(count, -1)
            acc["min"] = [float(v) for v in flat.min(0)]
            acc["max"] = [float(v) for v in flat.max(0)]
        self.accessors.append(acc)
        return len(self.accessors) - 1

    def finish(self, path, doc):
        doc["accessors"] = self.accessors
        doc["bufferViews"] = self.views
        doc["buffers"] = [{"byteLength": self.size}]
        glb_prepare.write_glb(path, doc, b"".join(self.parts))


# --- 2. İskelet --------------------------------------------------------------------------------------------------

LEG_IDS = ("FrontL", "FrontR", "HindL", "HindR")
LEG_PARTS = ("Upper", "Lower", "Cannon", "Hoof")


def leg_bone(leg, part):
    """FrontL, Upper → FrontUpperL."""
    return leg[:-1] + part + leg[-1]


class Leg:
    """Bir bacağın dinlenme ölçüleri: eklemler (üst, orta, alt, bilek), toynak ucu, taban."""

    def __init__(self, leg_id):
        self.id = leg_id
        self.kind = "front" if leg_id.startswith("Front") else "hind"
        self.joints = None
        self.toe = None
        self.axis_y = None
        self.axis_xz = None


class Rig:
    """Kemikler: adlar, ebeveynler, dinlenme başı ve dönüşü (dünya uzayı = model uzayı)."""

    def __init__(self):
        self.names = []
        self.parents = []
        self.heads = []
        self.rotations = []
        self.index = {}
        self.legs = {}

    def add(self, name, parent, head, tail, x_ref=(1.0, 0.0, 0.0)):
        self.index[name] = len(self.names)
        self.names.append(name)
        self.parents.append(self.index[parent] if parent else -1)
        self.heads.append(np.asarray(head, dtype=np.float64))
        self.rotations.append(frame_from_y(np.asarray(tail, dtype=np.float64) - np.asarray(head, dtype=np.float64), x_ref))

    def finish(self):
        self.heads = np.array(self.heads)
        self.rotations = np.array(self.rotations)

    def __len__(self):
        return len(self.names)


def measure_feet(welded, seeds=None):
    """Dört toynak: taban altındaki köşelerden merkez ve uç. Toynak dörtte birlik bölgesinde değilse (maral: uzak ön ayak gövdenin
    ortasına basar) tarif tohum verir (skeleton.feet: {bacak: [x, z]}): taban köşesi en yakın tohumun toynağıdır."""
    p = welded.positions
    feet = {}
    low = p[:, 1] < 0.03
    nearest = None
    if seeds:
        ids = list(seeds)
        centers = np.array([seeds[i] for i in ids], dtype=np.float64)
        d = np.hypot(p[:, 0][:, None] - centers[:, 0][None, :], p[:, 2][:, None] - centers[:, 1][None, :])
        nearest = np.array(ids)[np.argmin(d, axis=1)]
    for leg_id, sign_x, sign_z in (("FrontL", 1.0, 1.0), ("FrontR", -1.0, 1.0), ("HindL", 1.0, -1.0), ("HindR", -1.0, -1.0)):
        if nearest is not None:
            q = p[low & (nearest == leg_id)]
        else:
            q = p[low & (np.sign(p[:, 0]) == sign_x) & (np.sign(p[:, 2]) == sign_z)]
        feet[leg_id] = {"x": float((q[:, 0].min() + q[:, 0].max()) * 0.5), "z": float((q[:, 2].min() + q[:, 2].max()) * 0.5),
                        "toe": float(q[:, 2].max()), "sole": float(q[:, 1].min())}
    return feet


def track_leg_axis(welded, foot, top_y, step=0.01, radius=0.075, band=0.02):
    """Bacağın orta hattı: tabandan yukarı dilim dilim yürür (kesit ortası). Döner: yükseklikler, (x, z) merkezleri."""
    p = welded.positions
    ys = np.arange(0.02, top_y, step)
    center = np.array([foot["x"], foot["z"]])
    out = []
    for y in ys:
        picked = np.abs(p[:, 1] - y) < band
        d = np.hypot(p[:, 0] - center[0], p[:, 2] - center[1])
        q = p[picked & (d < radius)]
        if len(q) >= 3:
            here = np.array([(q[:, 0].min() + q[:, 0].max()) * 0.5, (q[:, 2].min() + q[:, 2].max()) * 0.5])
            center = center * 0.5 + here * 0.5
        out.append(center.copy())
    return ys, np.array(out)


def build_rig(recipe, welded):
    """Kemikleri kurar. Görünen bacak eklemleri ağdan ölçülür, yün içindekiler tariften."""
    sk = recipe["skeleton"]
    rig = Rig()
    rig.add("Root", None, (0, 0, 0), (0, 0.2, 0))
    rig.add("Hips", "Root", sk["hips"], sk["spine"])
    rig.add("Spine", "Hips", sk["spine"], sk["chest"])
    rig.add("Chest", "Spine", sk["chest"], sk["neck"][0])
    bh = np.array(sk["belly"])
    rig.add("Belly", "Spine", bh, bh + (0, -0.1, 0))
    neck = [np.array(n) for n in sk["neck"]] + [np.array(sk["head"])]
    rig.add("Neck1", "Chest", neck[0], neck[1])
    rig.add("Neck2", "Neck1", neck[1], neck[2])
    rig.add("Neck3", "Neck2", neck[2], neck[3])
    rig.add("Head", "Neck3", neck[3], sk["nose"])
    for side in ("L", "R"):
        rig.add("Ear" + side, "Head", sk["ears"][side]["base"], sk["ears"][side]["tip"], x_ref=(0.0, 0.0, 1.0))
    tail = [np.array(t) for t in sk["tail"]]
    for k in range(len(tail) - 1):
        rig.add("Tail%d" % (k + 1), "Hips" if k == 0 else "Tail%d" % k, tail[k], tail[k + 1])
    # Yele (isteğe bağlı): boyun sırtı boyunca kemikler, her biri kendi boyun kemiğine bağlı; dalgası kliptedir.
    mane = sk.get("mane")
    if mane:
        points = [np.array(m) for m in mane["points"]]
        for k in range(len(points) - 1):
            rig.add("Mane%d" % (k + 1), mane["parents"][k], points[k], points[k + 1], x_ref=(1.0, 0.0, 0.0))
    feet = measure_feet(welded, sk.get("feet"))
    for leg_id in LEG_IDS:
        leg = Leg(leg_id)
        spec = sk["legs"][leg.kind]
        foot = feet[leg_id]
        ys, axis = track_leg_axis(welded, foot, spec.get("track_top_y", spec["low_y"] + 0.05), radius=spec.get("track_radius", 0.075))
        at = lambda y: np.array([np.interp(y, ys, axis[:, 0]), np.interp(y, ys, axis[:, 1])])  # noqa: E731
        fx, fz = at(spec["fetlock_y"])
        lx, lz = at(spec["low_y"])
        j3 = np.array([fx, spec["fetlock_y"], fz])
        j2 = np.array([lx, spec["low_y"], lz])
        j1 = np.array([lx, spec["mid"]["y"], lz + spec["mid"]["dz"]])
        # Üst eklem: alt eklemin z'sine göre (dz) ya da tarifte z varsa iki yanda aynı yerde (deve: ayaklar adımlı durur, omuz ve kalça eklemi
        # gövdede simetriktir; bacak eklemden eğik iner).
        top_z = spec["top"]["z"] if "z" in spec["top"] else lz + spec["top"]["dz"]
        # Yanda da isteğe bağlı mutlak yer (maral: uzak ön toynak gövdenin ortasına basar, omuz eklemi yine kendi yanındadır).
        top_x = (spec["top"]["x"] if leg_id.endswith("L") else -spec["top"]["x"]) if "x" in spec["top"] else lx * spec["top"]["x_factor"]
        j0 = np.array([top_x, spec["top"]["y"], top_z])
        leg.toe = np.array([foot["x"], foot["sole"], foot["toe"]])
        leg.joints = np.array([j0, j1, j2, j3])
        leg.axis_y = ys
        leg.axis_xz = axis
        rig.legs[leg_id] = leg
        parent = spec["parent"]
        for k, part in enumerate(LEG_PARTS):
            name = leg_bone(leg_id, part)
            tail_pos = leg.joints[k + 1] if k < 3 else leg.toe
            rig.add(name, parent if k == 0 else leg_bone(leg_id, LEG_PARTS[k - 1]), leg.joints[k], tail_pos)
    rig.finish()
    return rig


# --- 3. Ağırlık ---------------------------------------------------------------------------------------------------

def segment_distance(p, a, b):
    """Noktaların [a, b] doğru parçasına uzaklığı ve parçadaki yeri (0..1)."""
    ab = b - a
    t = np.clip(((p - a) @ ab) / max(ab @ ab, 1e-12), 0.0, 1.0)
    return np.linalg.norm(p - (a + np.outer(t, ab)), axis=1), t


def vertex_colors(source, welded, thumbnail):
    """Kaynaşmış köşe başına doku rengi (kopyaların ortalaması); doku glTF düzeninde: v = 0 üst satır."""
    h, w = thumbnail.shape[:2]
    px = np.clip((source.uvs[:, 0] * w).astype(int), 0, w - 1)
    py = np.clip((source.uvs[:, 1] * h).astype(int), 0, h - 1)
    colors = np.zeros((welded.count, 3))
    counts = np.zeros(welded.count)
    np.add.at(colors, welded.index, thumbnail[py, px])
    np.add.at(counts, welded.index, 1.0)
    return colors / counts[:, None]


def chain_weights(y, ladder):
    """Yüksekliğe göre zincir payı: ladder [(eklem yüksekliği, yarı bant)] aşağıdan yukarı; n eklem n+1 kemik verir (ilk sütun en alt kemik)."""
    out = np.zeros((len(y), len(ladder) + 1))
    below = np.ones(len(y))
    for k, (joint_y, band) in enumerate(ladder):
        up = sstep(joint_y - band, joint_y + band, y)
        out[:, k] = below * (1.0 - up)
        below = below * up
    out[:, len(ladder)] = below
    return out


def compute_weights(recipe, rig, welded, lum):
    """Bölge maskeleri: gövde tabanı, kuyruk, boyun, baş, kulak, bacak. Her bölge payı ağ üzerinde yumuşar; sıra bölge önceliğidir."""
    wc = recipe["weights"]
    p = welded.positions
    n = welded.count
    W = np.zeros((n, len(rig)))
    idx = rig.index
    y, z = p[:, 1], p[:, 2]
    dark = sstep(wc["dark_lum"][1], wc["dark_lum"][0], lum)

    # Gövde tabanı: z boyunca üç kemik, karın yaprağı altta.
    a = wc["body_blend"]["hips_spine"]
    b = wc["body_blend"]["spine_chest"]
    w_spine_up = sstep(a[0], a[1], z)
    w_chest_up = sstep(b[0], b[1], z)
    W[:, idx["Hips"]] = 1.0 - w_spine_up
    W[:, idx["Spine"]] = w_spine_up * (1.0 - w_chest_up)
    W[:, idx["Chest"]] = w_spine_up * w_chest_up
    bl = wc["belly"]
    belly = sstep(bl["y"][0], bl["y"][1], y) * sstep(bl["z"][0], bl["z"][1], z) * sstep(bl["z"][3], bl["z"][2], z) * bl["share"]
    belly = welded.smooth(belly, 4)
    W *= (1.0 - belly)[:, None]
    W[:, idx["Belly"]] += belly

    def blend(share, targets):
        """targets: (n, kemik) satır toplamı 1; share kadar bu kemiklere geçer."""
        nonlocal W
        W = W * (1.0 - share)[:, None] + targets * share[:, None]

    # Kuyruk: boğumun gerisi. Boğum düzlemi tarifte.
    tc = wc["tail"]
    behind = (p - np.array(tc["point"])) @ unit(tc["normal"])
    tail_share = welded.smooth(sstep(tc["blend"][0], tc["blend"][1], behind), tc["smooth"])
    if "chain" in tc:
        # Uzun kuyruk (at): kemik zinciri kılın boyunca iner; köşenin payı en yakın kemik parçasındaki yerinden, eklemlerde yumuşak geçişle.
        tail_points = [np.array(t, dtype=np.float64) for t in recipe["skeleton"]["tail"]]
        count = len(tail_points) - 1
        best = np.full(n, 1e9)
        param = np.zeros(n)
        for k in range(count):
            d, t = segment_distance(p, tail_points[k], tail_points[k + 1])
            picked = d < best
            best[picked] = d[picked]
            param[picked] = (k + t[picked]) / count
        col = chain_weights(param, [((k + 1) / count, tc["chain"] / count) for k in range(count - 1)])
        targets = np.zeros_like(W)
        for k in range(count):
            targets[:, idx["Tail%d" % (k + 1)]] = col[:, k]
    else:
        tail_heads = [rig.heads[idx["Tail1"]], rig.heads[idx["Tail2"]], rig.heads[idx["Tail3"]], np.array(recipe["skeleton"]["tail"][3])]
        tail_axis = unit(tail_heads[3] - tail_heads[0])
        along = (p - tail_heads[0]) @ tail_axis
        length = np.linalg.norm(tail_heads[3] - tail_heads[0])
        u = along / length
        targets = np.zeros_like(W)
        targets[:, idx["Tail1"]] = 1.0 - sstep(0.22, 0.48, u)
        targets[:, idx["Tail3"]] = sstep(0.6, 0.86, u)
        targets[:, idx["Tail2"]] = 1.0 - targets[:, idx["Tail1"]] - targets[:, idx["Tail3"]]
    blend(tail_share, targets)
    tail_body = tail_share.copy()

    # Boyun: gövdeden tarifin düzlemiyle ayrılır; zincir payı boyun hattına uzaklıktan.
    nc = wc["neck"]
    front = (p - np.array(nc["point"])) @ unit(nc["normal"])
    neck_share = welded.smooth(sstep(nc["blend"][0], nc["blend"][1], front), nc["smooth"])
    if "exclude_box" in nc:
        # Sırttaki eşya (eyer) boyna bağlanmaz: kutunun içi gövdede kalır, kenarı yumuşak.
        lo, hi = np.array(nc["exclude_box"][0]), np.array(nc["exclude_box"][1])
        margin = nc.get("exclude_margin", 0.03)
        inside = np.ones(n)
        for axis in range(3):
            inside *= sstep(lo[axis] - margin, lo[axis] + margin, p[:, axis]) * sstep(hi[axis] + margin, hi[axis] - margin, p[:, axis])
        neck_share *= 1.0 - inside
    joints = [rig.heads[idx["Neck1"]], rig.heads[idx["Neck2"]], rig.heads[idx["Neck3"]], rig.heads[idx["Head"]]]
    best = np.full(n, 1e9)
    param = np.zeros(n)
    for k in range(3):
        d, t = segment_distance(p, joints[k], joints[k + 1])
        picked = d < best
        best[picked] = d[picked]
        param[picked] = (k + t[picked]) / 3.0
    targets = np.zeros_like(W)
    targets[:, idx["Neck1"]] = 1.0 - sstep(0.2, 0.5, param)
    targets[:, idx["Neck3"]] = sstep(0.55, 0.85, param)
    targets[:, idx["Neck2"]] = 1.0 - targets[:, idx["Neck1"]] - targets[:, idx["Neck3"]]
    blend(neck_share, targets)

    # Yele (isteğe bağlı): boyun bölgesinde sırt çizgisine yakın köşeler (koyu yelede renk de) kısmen yele kemiklerine geçer; kemik boyun ekseni
    # çevresinde dönünce yele dalgalanır, boynun derisi az kıpırdar.
    mc = wc.get("mane")
    if mc and "Mane1" in idx:
        crest = [np.array(m, dtype=np.float64) for m in recipe["skeleton"]["mane"]["points"]]
        count = len(crest) - 1
        best = np.full(n, 1e9)
        param = np.zeros(n)
        for k in range(count):
            d, t = segment_distance(p, crest[k], crest[k + 1])
            picked = d < best
            best[picked] = d[picked]
            param[picked] = (k + t[picked]) / count
        seed = sstep(mc["reach"][1], mc["reach"][0], best)
        if "dark_lum" in mc:
            seed = np.maximum(seed, sstep(mc["dark_lum"][1], mc["dark_lum"][0], lum) * (best < mc["dark_reach"]))
        mane_share = welded.smooth(seed * neck_share, mc["smooth"]) * mc["share"]
        col = chain_weights(param, [((k + 1) / count, mc["chain"] / count) for k in range(count - 1)])
        targets = np.zeros_like(W)
        for k in range(count):
            targets[:, idx["Mane%d" % (k + 1)]] = col[:, k]
        blend(mane_share, targets)

    # Baş: yüz, boynuz, kulak koyu; tepe yünü elipsoidle. Yaka yumuşar. Kafa çevresindeki koyu köşeler (boynuz ucu) bütün kafaya bağlı.
    hc = wc["head"]
    center = np.array(hc["center"])
    rel = p - center
    if "pitch_deg" in hc:
        # Elipsoid başın eksenine yatar (at: başı burnu aşağı uzun).
        rel = rel @ rot_x(math.radians(hc["pitch_deg"]))
    q = rel / np.array(hc["radii"])
    ellipse = np.linalg.norm(q, axis=1)
    near = np.linalg.norm(p - center, axis=1) < hc["reach"]
    head_seed = np.maximum(sstep(hc["collar"][1], hc["collar"][0], ellipse), dark * near * (y > 0.6))
    # Başa bağlı ek elipsoitler (isteğe bağlı; maralın açık renkli geniş boynuzu): içleri bütün kafaya bağlıdır, erişim sınırı yoktur.
    for extra in hc.get("extra", []):
        q2 = (p - np.array(extra["center"])) / np.array(extra["radii"])
        head_seed = np.maximum(head_seed, sstep(hc["collar"][1], hc["collar"][0], np.linalg.norm(q2, axis=1)))
    pinned = (head_seed > 0.95) | (ellipse > 2.2)
    head_share = welded.smooth(head_seed, hc["smooth"], pinned=pinned)
    targets = np.zeros_like(W)
    targets[:, idx["Head"]] = 1.0
    # Kulaklar: taban-uç ekseni çevresindeki koyu köşeler.
    ec = wc["ear"]
    for side in ("L", "R"):
        base = rig.heads[idx["Ear" + side]]
        tip = np.array(recipe["skeleton"]["ears"][side]["tip"])
        axis = unit(tip - base)
        along = (p - base) @ axis
        d, _ = segment_distance(p, base, tip + axis * 0.02)
        ear = sstep(ec["start"], ec["full"], along) * (d < ec["radius"]) * near
        ear = welded.smooth(ear, 2)
        targets[:, idx["Head"]] -= ear
        targets[:, idx["Ear" + side]] = ear
    targets[:, idx["Head"]] = np.maximum(targets[:, idx["Head"]], 0.0)
    targets /= targets.sum(1, keepdims=True)
    blend(head_share, targets)

    # Bacaklar: önce yün (yalnız üst kemiğe, kısmen), sonra koyu deri (zincire, tam). Yün alt bacağın kaldıracına binmez: yırtılmaz, kol gibi sürüklenmez.
    lc = wc["leg"]
    for leg_id in LEG_IDS:
        leg = rig.legs[leg_id]
        j = leg.joints
        ys, axis = leg.axis_y, leg.axis_xz
        hem = lc["hem_y"][leg.kind]
        cx = np.interp(y, ys, axis[:, 0])
        cz = np.interp(y, ys, axis[:, 1])
        d_axis = np.hypot(p[:, 0] - cx, p[:, 2] - cz)
        d_lower, _ = segment_distance(p, j[1], j[2])
        d_upper, _ = segment_distance(p, j[0], j[1])
        d_bone = np.minimum(d_lower, d_upper)
        side_ok = (np.sign(p[:, 0]) == np.sign(leg.toe[0])) | (np.abs(p[:, 0]) < 0.02)
        # Bacağı saran yün: kemiğe yakınlık × yükseklik × yün payı → üst kemik.
        wool = sstep(lc["wool_far"], lc["wool_near"], d_bone) * sstep(lc["wool_top"][leg.kind], hem, y) * lc["wool_share"][leg.kind] * side_ok * (1.0 - tail_body)
        pinned = d_bone > lc["wool_far"] + 0.08
        wool = welded.smooth(wool, lc["wool_smooth"], pinned=pinned)
        targets = np.zeros_like(W)
        targets[:, idx[leg_bone(leg_id, "Upper")]] = 1.0
        blend(wool, targets)
        # Koyu deri: boru içinde, etek çizgisinin altında. Etek üstüne çıkan koyu şerit (bacak arkası) yüne bırakılır.
        if lc.get("tube") == "chain":
            # Uzun bacak (at): boru kemik zincirine uzaklıktır; yarıçap bilekten eteğe büyür (önkol, incik kalınlaşır).
            d_chain = np.minimum(d_bone, np.minimum(segment_distance(p, j[2], j[3])[0], segment_distance(p, j[3], leg.toe)[0]))
            grow = np.clip((y - j[3][1]) / max(hem - j[3][1], 1e-6), 0.0, 1.0)
            tube = d_chain < lc["tube_radius"] + (lc.get("tube_radius_top", lc["tube_radius"]) - lc["tube_radius"]) * grow
        else:
            tube = d_axis < lc["tube_radius"]
        below = sstep(hem + lc["hem_fade"], hem - lc["hem_fade"], y)
        leg_seed = tube * below * np.maximum(dark, sstep(hem - 0.01, hem - 0.05, y))
        pinned = (leg_seed > 0.9) & (y < hem - lc["hem_fade"])
        pinned |= ~tube & (y < hem - 0.05)
        pinned |= y > hem + 0.10
        skin = welded.smooth(leg_seed, lc["skin_smooth"], pinned=pinned)
        # Zincir: bant yükseklikleri (toynak, alt, orta). Toynak köşeleri rijit.
        bands = lc["blend"]
        ladder = [(j[3][1], bands["hoof"]), (j[2][1], bands["low"]), (j[1][1], bands["mid"])]
        col = chain_weights(y, ladder)  # sütunlar: Hoof, Cannon, Lower, Upper
        targets = np.zeros_like(W)
        targets[:, idx[leg_bone(leg_id, "Hoof")]] = col[:, 0]
        targets[:, idx[leg_bone(leg_id, "Cannon")]] = col[:, 1]
        targets[:, idx[leg_bone(leg_id, "Lower")]] = col[:, 2]
        targets[:, idx[leg_bone(leg_id, "Upper")]] = col[:, 3]
        blend(skin, targets)

    W[:, idx["Root"]] = 0.0
    return W


def limit_influences(W, keep=4, floor=0.01):
    """Her köşede en büyük dört ağırlık, toplam 1. Döner: (eklem sırası, ağırlık)."""
    order = np.argsort(-W, axis=1)[:, :keep]
    values = np.take_along_axis(W, order, axis=1)
    values[values < floor] = 0.0
    values /= np.maximum(values.sum(1, keepdims=True), 1e-9)
    return order, values


# --- 4. Klipler ---------------------------------------------------------------------------------------------------

class Pose:
    """Bir karenin gövde sürücüsü: kemik başına dünya eksenlerinde göreli dönüş, kayma ve (yaprak kemikte) ölçek; ayak durumları."""

    def __init__(self):
        self.delta = {}
        self.offset = {}
        self.scale = {}
        self.feet = {}

    def rotate(self, bone, pitch=0.0, yaw=0.0, roll=0.0):
        m = euler_xyz(pitch, yaw, roll)
        self.delta[bone] = self.delta[bone] @ m if bone in self.delta else m

    def move(self, bone, x=0.0, y=0.0, z=0.0):
        current = self.offset.get(bone, np.zeros(3))
        self.offset[bone] = current + np.array([x, y, z])


class Foot:
    """Toynağın durumu: uç noktası (toe), yatış (pitch, derece; + uç aşağı), alt eklem bükümü (flex, derece; + diz ya da içdirsek kapanır)."""

    def __init__(self, toe, pitch=0.0, flex=0.0):
        self.toe = np.asarray(toe, dtype=np.float64)
        self.pitch = pitch
        self.flex = flex


class Solver:
    """Gövde FK + bacak IK: Pose → her kemiğin dünya dönüşü ve konumu."""

    def __init__(self, rig):
        self.rig = rig
        self.clamped = 0
        self.reach = {}
        self.order = list(range(len(rig)))
        self.leg_bones = {}
        self.leg_data = {}
        for leg_id, leg in rig.legs.items():
            ids = [rig.index[leg_bone(leg_id, part)] for part in LEG_PARTS]
            self.leg_bones.update({i: leg_id for i in ids})
            j = leg.joints
            a = np.linalg.norm(j[1] - j[0])
            b = np.linalg.norm(j[2] - j[1])
            c = np.linalg.norm(j[3] - j[2])
            # Alt eklem açısı (orta-alt-bilek) ve iki üçgenin dinlenme düzlemleri.
            cos_beta = np.clip((j[1] - j[2]) @ (j[3] - j[2]) / (b * c), -1.0, 1.0)
            u = unit(j[3] - j[0])
            v = j[1] - j[0]
            v = unit(v - u * (v @ u))
            w = unit(j[3] - j[1])
            s_ = j[2] - j[1]
            s_ = unit(s_ - w * (s_ @ w))
            self.leg_data[leg_id] = {"ids": ids, "a": a, "b": b, "c": c, "beta": math.acos(cos_beta), "n_top": np.cross(u, v), "n_low": np.cross(w, s_)}

    def evaluate(self, pose):
        rig = self.rig
        count = len(rig)
        pos = np.zeros((count, 3))
        rot = np.zeros((count, 3, 3))
        carried = np.zeros((count, 3, 3))  # dinlenmeye göre dünya eksenlerinde birikmiş dönüş
        pending = {}
        for i in self.order:
            name = rig.names[i]
            par = rig.parents[i]
            if i in self.leg_bones:
                leg_id = self.leg_bones[i]
                if self.leg_data[leg_id]["ids"][0] == i:
                    pending[leg_id] = par
                continue
            d = pose.delta.get(name, np.eye(3))
            if par < 0:
                carried[i] = d
                pos[i] = rig.heads[i] + pose.offset.get(name, 0.0)
            else:
                carried[i] = carried[par] @ d
                pos[i] = pos[par] + carried[par] @ (rig.heads[i] - rig.heads[par]) + pose.offset.get(name, 0.0)
            rot[i] = carried[i] @ rig.rotations[i]
        for leg_id, par in pending.items():
            self._solve_leg(leg_id, par, pose.feet.get(leg_id), pos, rot, carried)
        return pos, rot

    def _solve_leg(self, leg_id, par, foot, pos, rot, carried):
        rig = self.rig
        leg = rig.legs[leg_id]
        data = self.leg_data[leg_id]
        ids = data["ids"]
        j = leg.joints
        if foot is None:
            foot = Foot(leg.toe)
        j0 = pos[par] + carried[par] @ (j[0] - rig.heads[par])
        hoof_rot = rot_x(math.radians(foot.pitch))
        j3 = foot.toe + hoof_rot @ (j[3] - leg.toe)
        a, b, c = data["a"], data["b"], data["c"]
        # Ağda bacak düz bir borudur: duruşta alt kemik ve bilek rijit kalır (alt eklem açısı sabit), bütün boy değişimi üst eklemdedir; salınımda alt eklem kapanır.
        beta = max(data["beta"] - math.radians(foot.flex), math.radians(35.0))
        d = math.sqrt(b * b + c * c - 2.0 * b * c * math.cos(beta))
        u = j3 - j0
        dist = np.linalg.norm(u)
        limit = (a + d) * 0.9995
        self.reach[leg_id] = max(self.reach.get(leg_id, 0.0), dist / (a + d))
        if dist > limit:
            self.clamped += 1
            u = u / dist * limit
            dist = limit
        u = u / dist
        cos_a = np.clip((a * a + dist * dist - d * d) / (2.0 * a * dist), -1.0, 1.0)
        j1 = j0 + a * (cos_a * u + math.sqrt(max(0.0, 1.0 - cos_a * cos_a)) * unit(np.cross(carried[par] @ data["n_top"], u)))
        w = unit(j3 - j1)
        cos_b = np.clip((b * b + d * d - c * c) / (2.0 * b * d), -1.0, 1.0)
        j2 = j1 + b * (cos_b * w + math.sqrt(max(0.0, 1.0 - cos_b * cos_b)) * unit(np.cross(carried[par] @ data["n_low"], w)))
        # Dönüşler: ebeveynin çerçevesi taşınır, kemik yönü yeni yöne en küçük dönüşle çevrilir (burulma birikmez).
        points = [j0, j1, j2]
        tips = [j1, j2, j3]
        frame_parent = carried[par]
        for k in range(3):
            i = ids[k]
            base = frame_parent @ rig.rotations[i]
            rest_dir = base @ np.array([0.0, 1.0, 0.0])
            turn = rot_between(rest_dir, tips[k] - points[k])
            rot[i] = turn @ base
            pos[i] = points[k]
            frame_parent = rot[i] @ rig.rotations[i].T
        i = ids[3]
        rot[i] = hoof_rot @ rig.rotations[i]
        pos[i] = j3

    def locals(self, pos, rot):
        """Dünya pozundan glTF düğüm yerelleri: dönüş dörtlüsü ve öteleme."""
        rig = self.rig
        count = len(rig)
        q = np.zeros((count, 4))
        t = np.zeros((count, 3))
        for i in range(count):
            par = rig.parents[i]
            if par < 0:
                q[i] = mat_to_quat(rot[i])
                t[i] = pos[i]
            else:
                q[i] = mat_to_quat(rot[par].T @ rot[i])
                t[i] = rot[par].T @ (pos[i] - pos[par])
        return q, t


def smooth_keys(t, keys):
    """Parça parça yumuşak eğri: keys [(zaman, değer)], artan zamanda."""
    if t <= keys[0][0]:
        return keys[0][1]
    for (t0, v0), (t1, v1) in zip(keys, keys[1:]):
        if t <= t1:
            return v0 + (v1 - v0) * float(sstep(t0, t1, t))
    return keys[-1][1]


def spline_keys(t, keys):
    """Akıcı eğri: keys [(zaman, değer)], artan zamanda; iç anahtarda eğim komşuların farkıdır (Catmull-Rom), uçlarda düz. smooth_keys gibi her anahtarda durmaz."""
    if t <= keys[0][0]:
        return float(keys[0][1])
    if t >= keys[-1][0]:
        return float(keys[-1][1])
    n = len(keys)

    def slope(k):
        if k == 0 or k == n - 1:
            return 0.0
        return (keys[k + 1][1] - keys[k - 1][1]) / (keys[k + 1][0] - keys[k - 1][0])

    for k in range(n - 1):
        t0, v0 = keys[k]
        t1, v1 = keys[k + 1]
        if t <= t1:
            h = t1 - t0
            u = (t - t0) / h
            return float((2 * u ** 3 - 3 * u ** 2 + 1) * v0 + (u ** 3 - 2 * u ** 2 + u) * h * slope(k) + (-2 * u ** 3 + 3 * u ** 2) * v1
                         + (u ** 3 - u ** 2) * h * slope(k + 1))
    return float(keys[-1][1])


def pulse(t, center, width):
    """Kısa çan: center çevresinde, width yarı genişlik."""
    x = (t - center) / width
    return math.exp(-x * x * 4.0)


def wave(ph, cycles, phase=0.0):
    return math.cos(2.0 * math.pi * (cycles * ph - phase))


def stand_feet(rig):
    """Dinlenme yerinde dört ayak."""
    return {leg_id: Foot(leg.toe.copy()) for leg_id, leg in rig.legs.items()}


def chain_names(rig, prefix):
    """Zincirin kemikleri sırayla (Tail1, Tail2, ... ya da Mane1, ...)."""
    out = []
    while "%s%d" % (prefix, len(out) + 1) in rig.index:
        out.append("%s%d" % (prefix, len(out) + 1))
    return out


def per_bone(values, k):
    """Kemik başına değer listesinden k'ıncısı (liste kısaysa sonuncusu)."""
    return values[min(k, len(values) - 1)]


def pose_idle(rig, spec, t):
    T = spec["length_s"]
    ph = t / T
    pose = Pose()
    pose.feet = stand_feet(rig)
    # Nefes: karın genişler, gövde çok az yükselir (6 sn'de iki nefes).
    breath = 0.5 - 0.5 * wave(ph, 2)
    pose.scale["Belly"] = (1.0 + 0.05 * breath, 1.0 + 0.06 * breath, 1.0 + 0.008 * breath)
    pose.rotate("Spine", pitch=-0.35 * breath)
    pose.rotate("Chest", pitch=0.35 * breath)
    pose.move("Hips", y=0.0015 * breath)
    # Ağırlık yana geçer, gelir.
    pose.move("Hips", x=0.004 * wave(ph, 1, 0.1))
    pose.rotate("Hips", roll=0.3 * wave(ph, 1, 0.1))
    # Baş yavaşça çevreyi süzer.
    yaw = 7.0 * math.sin(2.0 * math.pi * ph) * (0.7 + 0.3 * wave(ph, 2, 0.3))
    pitch = 1.8 * math.sin(2.0 * math.pi * (2.0 * ph + 0.1))
    pose.rotate("Neck1", yaw=yaw * 0.2, pitch=pitch * 0.2)
    pose.rotate("Neck2", yaw=yaw * 0.25, pitch=pitch * 0.2)
    pose.rotate("Neck3", yaw=yaw * 0.25, pitch=pitch * 0.2)
    pose.rotate("Head", yaw=yaw * 0.3, pitch=pitch * 0.4)
    # Kulak silkmesi: kısa, yan yan.
    flick_l = pulse(t, 1.4, 0.16) + 0.7 * pulse(t, 1.75, 0.13)
    flick_r = pulse(t, 4.2, 0.16) + 0.6 * pulse(t, 4.55, 0.12)
    pose.rotate("EarL", pitch=-16.0 * flick_l, roll=9.0 * flick_l)
    pose.rotate("EarR", pitch=-16.0 * flick_r, roll=-9.0 * flick_r)
    # Kuyruk: ağır, çok az.
    sway = 2.2 * wave(ph, 1, 0.35) + spec.get("swish_deg", 3.0) * pulse(t, 3.0, 0.3) * math.sin(2.0 * math.pi * (t - 3.0) * 2.2)
    share = spec.get("tail_share", [0.5, 0.5, 0.4])
    for k, name in enumerate(chain_names(rig, "Tail")):
        # Uzun kuyrukta salınım uca doğru gecikir (kıl dalgası).
        lag = spec.get("tail_lag_s", 0.0) * k
        swing = sway if lag == 0.0 else 2.2 * wave((t - lag) / T, 1, 0.35) + spec.get("swish_deg", 3.0) * pulse(t - lag, 3.0, 0.3) * math.sin(2.0 * math.pi * (t - lag - 3.0) * 2.2)
        pose.rotate(name, yaw=swing * per_bone(share, k), pitch=0.4 * breath if k == 0 else 0.0)
    # Yele: esintide ağır ağır kıpırdar.
    for k, name in enumerate(chain_names(rig, "Mane")):
        pose.rotate(name, roll=spec.get("mane_breeze_deg", 0.0) * wave(ph, 2, 0.15 * k))
    return pose


def pose_graze(rig, spec, t, alpha):
    """alpha: baş yerdeyken boynun toplam dönüşü (derece; tarifin mouth_y'sine çözülür)."""
    T = spec["length_s"]
    ph = t / T
    pose = Pose()
    pose.feet = stand_feet(rig)
    g = smooth_keys(t, [(0.0, 0.0), (0.25, 0.0), (1.45, 1.0), (6.0, 1.0), (7.3, 0.0), (T, 0.0)])
    # Gövde: göğüs biraz iner, kalça biraz kalkar.
    pose.rotate("Hips", pitch=0.6 * g)
    pose.rotate("Spine", pitch=spec["spine_pitch"] * g)
    pose.rotate("Chest", pitch=spec["chest_pitch"] * g)
    breath = 0.5 - 0.5 * wave(ph, 3)
    pose.scale["Belly"] = (1.0 + 0.035 * breath, 1.0 + 0.045 * breath, 1.0 + 0.006 * breath)
    split = spec["neck_split"]
    bite = 0.0
    side = 0.0
    if 1.3 < t < 6.2:
        # Otlama: baş ağır ağır yana gezer, arada ot koparır.
        side = 5.5 * math.sin(2.0 * math.pi * (t - 1.45) / 1.6) * float(sstep(1.3, 2.0, t)) * float(sstep(6.2, 5.5, t))
        for center in (2.15, 2.85, 3.75, 4.5, 5.25):
            bite += pulse(t, center, 0.17)
    neck_pitch = alpha * g
    neck_lift = -2.2 * bite
    pose.rotate("Neck1", pitch=neck_pitch * split[0] + neck_lift * 0.3, yaw=side * 0.2)
    pose.rotate("Neck2", pitch=neck_pitch * split[1] + neck_lift * 0.3, yaw=side * 0.25)
    pose.rotate("Neck3", pitch=neck_pitch * split[2] + neck_lift * 0.4, yaw=side * 0.25)
    head_back = _graze_head_back(spec, alpha) * g
    chew = 0.0
    if t > 6.0:
        chew = 1.3 * math.sin(2.0 * math.pi * 3.0 * (t - 6.0)) * float(sstep(6.0, 6.8, t)) * float(sstep(T, T - 0.5, t))
    pose.rotate("Head", pitch=head_back + 5.0 * bite + chew, yaw=side * 0.3)
    droop = 7.0 * g
    flick = pulse(t, 3.2, 0.14) + pulse(t, 5.9, 0.14)
    pose.rotate("EarL", pitch=droop - 14.0 * flick)
    pose.rotate("EarR", pitch=droop - 14.0 * pulse(t, 3.3, 0.14))
    sway = 2.0 * wave(ph, 2, 0.2) + spec.get("swish_deg", 3.0) * pulse(t, 4.4, 0.3) * math.sin(2.0 * math.pi * (t - 4.4) * 2.2)
    share = spec.get("tail_share", [0.5, 0.5, 0.4])
    for k, name in enumerate(chain_names(rig, "Tail")):
        pose.rotate(name, yaw=sway * per_bone(share, k), pitch=-2.0 * g if k == 0 else 0.0)
    for k, name in enumerate(chain_names(rig, "Mane")):
        pose.rotate(name, roll=spec.get("mane_breeze_deg", 0.0) * wave(ph, 3, 0.15 * k))
    return pose


def _graze_head_back(spec, alpha):
    """Boyun alpha kadar eğilince başın dünya yatışı head_pitch kalsın diye geri dönüşü (göğüs eğimi dahil)."""
    return spec["head_pitch"] - alpha - spec["chest_pitch"] - spec["spine_pitch"] - 0.6


def solve_graze_alpha(rig, solver, spec, nose):
    """Burun tarifin mouth_y yüksekliğine insin: ikiye bölme."""
    head_i = rig.index["Head"]
    def mouth(alpha):
        pose = pose_graze(rig, spec, 3.0, alpha)
        pos, rot = solver.evaluate(pose)
        local = rig.rotations[head_i].T @ (nose - rig.heads[head_i])
        return (pos[head_i] + rot[head_i] @ local)[1]
    lo, hi = 40.0, 150.0
    for _ in range(40):
        mid = (lo + hi) * 0.5
        if mouth(mid) > spec["mouth_y"]:
            lo = mid
        else:
            hi = mid
    return (lo + hi) * 0.5


def gait_foot_state(ph, duty, travel, stride, lift, roll_off, peak):
    """Toynak evresi (0 = basış): uç için göreli z, yükseklik, yatış; ve salınım evresi (duruşta -1)."""
    if ph < duty:
        s = ph / duty
        dz = travel * 0.5 - travel * s
        return dz, 0.0, roll_off * float(sstep(0.68, 1.0, s)), -1.0
    u = (ph - duty) / (1.0 - duty)
    h00 = 2 * u ** 3 - 3 * u ** 2 + 1
    h10 = u ** 3 - 2 * u ** 2 + u
    h01 = -2 * u ** 3 + 3 * u ** 2
    h11 = u ** 3 - u ** 2
    # Basış ve kalkışta hız kuşak hızına yaklaşır; tam eşitlemek fazla taşma yapar (bacak boyu), yerdeyken zaten kuşak hızıdır.
    tangent = -stride * (1.0 - duty) * 0.55
    dz = h00 * (-travel * 0.5) + h10 * tangent + h01 * (travel * 0.5) + h11 * tangent
    y = lift * math.sin(math.pi * u) ** 2
    pitch = smooth_keys(u, [(0.0, roll_off), (0.28, peak), (0.78, peak * 0.12), (1.0, 0.0)])
    return dz, y, pitch, u


def pose_gait(rig, spec, ph, neutrals):
    pose = Pose()
    body = spec["body"]
    duty = spec["duty"]
    stride = spec["stride_m"]
    travel = stride * duty
    for leg_id, leg in rig.legs.items():
        kind = leg.kind
        foot_ph = (ph - spec["phases"][leg_id]) % 1.0
        dz, y, pitch, u = gait_foot_state(foot_ph, duty, travel, stride, spec["lift_m"], spec["roll_off"][kind], spec["swing_peak"][kind])
        toe = neutrals[leg_id] + np.array([0.0, y, dz + spec["stance_shift"][kind]])
        flex = spec["flex"][kind] * math.sin(math.pi * u) ** 1.3 if u >= 0.0 else spec["stance_give"][kind] * math.sin(math.pi * foot_ph / duty)
        pose.feet[leg_id] = Foot(toe, pitch=pitch, flex=flex)
    p0 = duty * 0.5  # sol arka toynağın duruş ortası
    # Gövde: iki vuruşta bir iner kalkar; kalça ve göğüs ters salınır.
    pose.move("Hips", y=-body["crouch_m"] + (-body["bob_m"] * wave(ph, 2, 2 * p0) if spec["duty"] < 0.5 else body["bob_m"] * wave(ph, 2, 2 * p0)))
    if "rock_deg" in body:
        # Dörtnal: gövde adımda bir kez öne arkaya yatar (arka bacaklar iterken ön kalkar, ön bacaklar basarken sağrı kalkar) ve bir kez iner kalkar.
        pose.rotate("Hips", pitch=body["rock_deg"] * wave(ph, 1, body["rock_phase"]))
        pose.move("Hips", y=body["bob1_m"] * wave(ph, 1, body["bob1_phase"]))
        pose.rotate("Chest", pitch=body.get("spine_flex_deg", 0.0) * wave(ph, 1, body["rock_phase"] + 0.25))
    pose.move("Hips", x=body["sway_m"] * wave(ph, 1, p0))
    hip_yaw = -body["hip_yaw"] * wave(ph, 1, 0.0)
    chest_yaw_total = -body["chest_yaw"] * wave(ph, 1, spec["phases"]["FrontL"])
    hip_roll = body["hip_roll"] * wave(ph, 1, p0)
    chest_roll_total = body["chest_roll"] * wave(ph, 1, p0 + spec["phases"]["FrontL"])
    pose.rotate("Hips", yaw=hip_yaw, roll=hip_roll)
    pose.rotate("Spine", yaw=(chest_yaw_total - hip_yaw) * 0.5, roll=(chest_roll_total - hip_roll) * 0.5)
    pose.rotate("Chest", yaw=(chest_yaw_total - hip_yaw) * 0.5, roll=(chest_roll_total - hip_roll) * 0.5, pitch=0.5 * wave(ph, 2, 2 * p0 + 0.12))
    # Boyun ve baş: yürürken biraz öne, adımla başını sallar; gövdenin yaw'ını siler.
    nod = body["nod"] * wave(ph, body.get("nod_cycles", 2), body.get("nod_cycles", 2) * (p0 + spec["phases"]["FrontL"]) + 0.1)
    pump = body.get("neck_pump_deg", 0.0) * wave(ph, 1, body.get("rock_phase", 0.0) + body.get("pump_lag", 0.0)) if "rock_deg" in body else 0.0
    pose.rotate("Neck1", pitch=body["neck_pitch"] * 0.5 + nod * 0.5 + pump * 0.6, yaw=-chest_yaw_total * 0.5)
    pose.rotate("Neck2", pitch=body["neck_pitch"] * 0.5 + pump * 0.4, yaw=-chest_yaw_total * 0.3)
    pose.rotate("Head", pitch=body["head_pitch"] - nod * 0.6 - pump * 0.5, yaw=-chest_yaw_total * 0.2)
    # Karın ve kuyruk: ağır kütle, gecikmeli.
    pose.move("Belly", y=-body["belly_m"] * wave(ph, 2, 2 * p0 + 0.2), x=body["belly_m"] * 0.8 * wave(ph, 1, p0 + 0.12))
    tail_yaw = body["tail_yaw"]
    tail_pitch = body["tail_pitch"]
    share = body.get("tail_share", [0.6, 0.5, 0.4])
    yaw_lag = body.get("tail_yaw_lag", [0.18, 0.28, 0.38])
    pitch_lag = body.get("tail_pitch_lag", [0.28, 0.42, 0.56])
    lift = body.get("tail_lift", [0.0])
    cycles = body.get("tail_pitch_cycles", 2)
    for k, name in enumerate(chain_names(rig, "Tail")):
        # Dörtnalda kuyruk kalkar, kıl arkaya akar (tail_lift; eksi yukarı ve geri), dalga uca doğru gecikir.
        pose.rotate(name, yaw=tail_yaw * per_bone(share, k) * wave(ph, 1, p0 + per_bone(yaw_lag, k)),
                    pitch=per_bone(lift, k) + tail_pitch * per_bone(share, k) * wave(ph, cycles, cycles * p0 + per_bone(pitch_lag, k)))
    # Yele: boyun boyunca ilerleyen dalga (sırttan başa doğru gecikir).
    mane_amp = body.get("mane_wave_deg", 0.0)
    for k, name in enumerate(chain_names(rig, "Mane")):
        pose.rotate(name, roll=mane_amp * wave(ph, body.get("mane_cycles", 1), body.get("mane_phase", 0.0) + body.get("mane_lag", 0.12) * k),
                    pitch=body.get("mane_lift_deg", 0.0))
    # Kulaklar: adımla oynar.
    ear = body["ear"] * wave(ph, 2, 2 * p0 + 0.3)
    pose.rotate("EarL", pitch=ear)
    pose.rotate("EarR", pitch=ear)
    return pose


def jump_leg_times(spec):
    """Sıçramada bacak başına anlar (saniye): ön bacak kalkış ve iniş, arka bacak kalkış ve iniş. Öncü sağ ön önce iner (sol ön önce kalkar), arka çift az aralıklı."""
    times = spec["times"]
    lead = spec.get("lead_s", 0.0)
    return {
        "FrontL": (times["lift"] - lead, times["touchdown"] + lead),
        "FrontR": (times["lift"], times["touchdown"]),
        "HindL": (times["takeoff"], times["hind_down"] - lead * 0.5),
        "HindR": (times["takeoff"] + lead * 0.3, times["hind_down"] + lead * 0.5),
    }


def pose_jump(rig, spec, t):
    """Sıçrama (tarifin jump'ı; t saniye). Klip yerindedir ve gövdenin havadaki yayını taşımaz: oyunda kod kaldırır (RideableHorse.leap; yükseklik ve süre hıza göre).
    Evreler: toplanma (kalça çöker, ağırlık arkaya), ön bacakların kalkışı (lift), arka bacakların itişi ve kalkışı (takeoff), havada toplanmış bacaklar (ön ayaklar
    dirseğin altına katlanır, arka ayaklar karnın altına), ön inişi (touchdown; öncü sağ ön), arka inişi (hind_down), toparlanma. Basan toynak itişte (arka) ve ön inişte
    ground_mps hızıyla geri kayar (oyun bu evreleri o hıza göre oynatır, ayak yerde kaymaz); toplanmada ve toparlanmada yerindedir. Gövdenin yatışı kalçanın ve
    omzun yükseklik eğrisinden çıkar (omuz: ön bacak kökü)."""
    times = spec["times"]
    lift, touch, hind = times["lift"], times["touchdown"], times["hind_down"]
    ground = spec["ground_mps"]
    body = spec["body"]
    front = spec["front"]
    back = spec["hind"]
    pose = Pose()
    hips_head = rig.heads[rig.index["Hips"]]
    span = float(np.mean([rig.legs[leg].joints[0][2] for leg in ("FrontL", "FrontR")])) - hips_head[2]
    hy = spline_keys(t, body["hips_y"])
    sy = spline_keys(t, body["shoulder_y"])
    hz = spline_keys(t, body.get("hips_z", [[0.0, 0.0]]))
    pitch = -math.degrees(math.asin(float(np.clip((sy - hy) / span, -0.9, 0.9))))
    roll = body.get("roll_deg", 0.0) * math.sin(2.0 * math.pi * t / spec["length_s"])
    pose.move("Hips", y=hy, z=hz)
    pose.rotate("Hips", pitch=pitch, roll=roll)
    # Havada sırt kamburlaşır (bascule), inişte düzelir.
    arch = spline_keys(t, body.get("arch_deg", [[0.0, 0.0]]))
    pose.rotate("Spine", pitch=arch * 0.5)
    pose.rotate("Chest", pitch=arch * 0.5)
    turn = euler_xyz(pitch, 0.0, roll)
    offset = np.array([0.0, hy, hz])

    def anchor(point):
        """Gövdeyle giden noktanın (dinlenmede point) bu karedeki yeri (omurganın kamburu sayılmaz: küçüktür)."""
        return hips_head + offset + turn @ (np.asarray(point) - hips_head)

    for leg_id, (up_at, down_at) in jump_leg_times(spec).items():
        leg = rig.legs[leg_id]
        rest = leg.toe.copy()
        root = anchor(leg.joints[0])
        if leg.kind == "front":
            tuck = root + turn @ np.array([0.0, -front["tuck_drop"], -front["tuck_back"]])
            tuck[0] = rest[0] * front.get("tuck_x", 1.0)
            # İnişte ayak önde basar, inişin sonuna (hind_down) dek gövdenin altına geri kayar.
            land = np.array([rest[0], rest[1], rest[2] + ground * max(hind - down_at, 0.0)])
            rise = float(sstep(up_at, up_at + front["rise_s"], t))
            reach = float(sstep(down_at - front["reach_s"], down_at, t))
            if t < down_at - front["reach_s"]:
                toe = rest + (tuck - rest) * rise
                toe[1] += front.get("clear_m", 0.0) * math.sin(math.pi * rise) ** 2
                foot_pitch = front["roll_off"] * float(sstep(up_at - 0.08, up_at, t)) * (1.0 - rise) + front["tuck_pitch"] * rise
                flex = front["tuck_flex"] * rise
            elif t < down_at:
                # Açılış: ayak öne ve aşağı uzanır (yay: önce öne, sonra aşağı).
                toe = tuck + (land - tuck) * reach
                toe[2] += front.get("reach_over_m", 0.0) * math.sin(math.pi * reach) * (1.0 - reach)
                foot_pitch = front["tuck_pitch"] * (1.0 - reach) + front.get("land_pitch", 0.0) * reach
                flex = front["tuck_flex"] * (1.0 - reach) ** 1.5
            else:
                slide = min(t, hind) - down_at
                toe = land - np.array([0.0, 0.0, ground * max(slide, 0.0)])
                give = math.sin(math.pi * float(np.clip((t - down_at) / max(hind - down_at + 0.12, 1e-3), 0.0, 1.0)))
                foot_pitch = front.get("land_pitch", 0.0) * float(sstep(down_at + 0.06, down_at, t))
                flex = front.get("land_give", 0.0) * give
        else:
            tuck = root + turn @ np.array([0.0, -back["tuck_drop"], back["tuck_fwd"]])
            tuck[0] = rest[0] * back.get("tuck_x", 1.0)
            push = rest - np.array([0.0, 0.0, ground * max(min(t, up_at) - lift, 0.0)])
            off = rest - np.array([0.0, 0.0, ground * max(up_at - lift, 0.0)])
            rise = float(sstep(up_at, up_at + back["rise_s"], t))
            reach = float(sstep(down_at - back["reach_s"], down_at, t))
            crouch = float(sstep(0.0, lift, t)) * float(sstep(up_at, up_at - 0.12, t))
            if t < up_at:
                toe = push
                foot_pitch = back["push_roll"] * float(sstep(up_at - back.get("roll_s", 0.12), up_at, t))
                flex = back["crouch_flex"] * crouch
            elif t < down_at - back["reach_s"]:
                toe = off + (tuck - off) * rise
                foot_pitch = back["push_roll"] + (back["tuck_pitch"] - back["push_roll"]) * rise
                flex = back["tuck_flex"] * rise
            elif t < down_at:
                toe = tuck + (rest - tuck) * reach
                foot_pitch = back["tuck_pitch"] * (1.0 - reach)
                flex = back["tuck_flex"] * (1.0 - reach) ** 1.5
            else:
                give = math.sin(math.pi * float(np.clip((t - down_at) / back.get("give_s", 0.3), 0.0, 1.0)))
                toe = rest.copy()
                foot_pitch = 0.0
                flex = back.get("land_give", 0.0) * give
        pose.feet[leg_id] = Foot(toe, pitch=foot_pitch, flex=flex)
    # Boyun ve baş: toplanmada iner, kalkışta kalkar, havada öne ve aşağı uzanır (bascule), inişte kalkar (denge).
    neck = spline_keys(t, spec["neck"])
    split = spec.get("neck_split", [0.5, 0.3, 0.2])
    for k, name in enumerate(("Neck1", "Neck2", "Neck3")):
        pose.rotate(name, pitch=neck * split[k])
    pose.rotate("Head", pitch=spline_keys(t, spec["head"]))
    ears = spline_keys(t, spec.get("ears", [[0.0, 0.0]]))
    pose.rotate("EarL", pitch=ears)
    pose.rotate("EarR", pitch=ears)
    # Karın: kalkışta gerilir, inişte sarsılır.
    pose.move("Belly", y=-0.012 * pulse(t, touch + 0.06, 0.1) - 0.008 * pulse(t, hind + 0.05, 0.1))
    # Kuyruk havada kalkar ve arkaya akar, dalga uca doğru gecikir; yele kalkar, dalgalanır.
    tail = spline_keys(t, spec["tail_lift"])
    share = spec.get("tail_share", [1.0, 0.45, 0.35, 0.3, 0.25])
    for k, name in enumerate(chain_names(rig, "Tail")):
        lag = 0.05 * k
        swing = spec.get("tail_wave_deg", 0.0) * math.sin(2.0 * math.pi * (t - lag) * 1.6) * float(sstep(0.0, 0.3, t)) * float(sstep(spec["length_s"], spec["length_s"] - 0.3, t))
        pose.rotate(name, pitch=spline_keys(t - lag, spec["tail_lift"]) * per_bone(share, k) if k > 0 else tail, yaw=swing * per_bone(share, k))
    mane = spline_keys(t, spec.get("mane_lift", [[0.0, 0.0]]))
    for k, name in enumerate(chain_names(rig, "Mane")):
        pose.rotate(name, pitch=mane, roll=spec.get("mane_wave_deg", 0.0) * math.sin(2.0 * math.pi * (1.5 * t - 0.12 * k)) * abs(mane) / max(abs(mane) + 1.0, 1.0))
    return pose


def gait_neutrals(rig, recipe):
    """Yürüyüşte toynak uçlarının merkez yeri: dinlenme yeri, çift ortasına çekilmiş (sol-sağ basış farkı azalır)."""
    sym = recipe["gait"]["symmetry"]
    out = {}
    for kind, pair in (("front", ("FrontL", "FrontR")), ("hind", ("HindL", "HindR"))):
        a, b = rig.legs[pair[0]].toe, rig.legs[pair[1]].toe
        mid_z = (a[2] + b[2]) * 0.5
        half_x = (abs(a[0]) + abs(b[0])) * 0.5
        for leg_id, toe in ((pair[0], a), (pair[1], b)):
            # Yan bacağın adından (L sol, +x): toynağı ortaya basan bacak (maral) öteki yana geçmesin.
            target = np.array([half_x if leg_id.endswith("L") else -half_x, toe[1], mid_z])
            out[leg_id] = toe + (target - toe) * sym
    return out


def build_clips(recipe, rig, solver):
    """Kliplerin dünya pozları. Döner: {ad: {"times", "rot": (kare, kemik, 4), "pos": (kare, kemik, 3), "scale": {kemik: (kare, 3)}, "length"}}."""
    clips = {}
    spec_all = recipe["clips"]
    neutrals = gait_neutrals(rig, recipe)

    def bake(name, length, samples, make_pose, loop=True):
        times = np.linspace(0.0, length, samples + 1)
        rots = np.zeros((samples + 1, len(rig), 4))
        poss = np.zeros((samples + 1, len(rig), 3))
        scale = {}
        solver.clamped = 0
        solver.reach = {}
        for f, t in enumerate(times):
            # Döngü: son kare ilk kareyle aynı evreden çizilir (bir kez oynayan klipte son kare kendi anıdır).
            pose = make_pose(0.0 if loop and f == samples else float(t))
            pos, rot = solver.evaluate(pose)
            q, tr = solver.locals(pos, rot)
            if f > 0:
                flip = np.sum(q * rots[f - 1], axis=1) < 0.0
                q[flip] *= -1.0
            rots[f] = q
            poss[f] = tr
            for bone, value in pose.scale.items():
                scale.setdefault(bone, np.ones((samples + 1, 3)))[f] = value
        print("  %s: en çok erişim %s" % (name, {k: round(v, 3) for k, v in solver.reach.items()}))
        if solver.clamped:
            print("  UYARI: %s: %d karede bacak boyu yetmedi" % (name, solver.clamped))
        clips[name] = {"times": times, "rot": rots, "pos": poss, "scale": scale, "length": length}

    spec = spec_all["idle"]
    bake("idle", spec["length_s"], int(round(spec["length_s"] * spec["rate"])), lambda t: pose_idle(rig, spec, t))

    for name, spec in spec_all.items():
        if "stride_m" not in spec:
            continue
        length = spec["stride_m"] / spec["speed_mps"]
        spec["length_s"] = length
        bake(name, length, spec["samples"], lambda t, s=spec, L=length: pose_gait(rig, s, (t / L) % 1.0, neutrals))

    spec = spec_all.get("graze")
    if spec:
        alpha = solve_graze_alpha(rig, solver, spec, np.array(recipe["skeleton"]["nose"], dtype=np.float64))
        print("  graze: boyun toplam dönüşü %.1f°, baş geri dönüşü %.1f°" % (alpha, _graze_head_back(spec, alpha)))
        bake("graze", spec["length_s"], int(round(spec["length_s"] * spec["rate"])), lambda t: pose_graze(rig, spec, t, alpha))

    # Sıçrama (isteğe bağlı; at): bir kez oynar.
    spec = spec_all.get("jump")
    if spec:
        bake("jump", spec["length_s"], int(round(spec["length_s"] * spec["rate"])), lambda t: pose_jump(rig, spec, t), loop=spec.get("loop", False))
    return clips


# --- 5. Oyun GLB'si -----------------------------------------------------------------------------------------------

def rest_locals(rig):
    """Dinlenme düğümleri: yerel öteleme ve dönüş."""
    trans = np.zeros((len(rig), 3))
    quats = np.zeros((len(rig), 4))
    for i in range(len(rig)):
        par = rig.parents[i]
        if par < 0:
            trans[i] = rig.heads[i]
            quats[i] = mat_to_quat(rig.rotations[i])
        else:
            trans[i] = rig.rotations[par].T @ (rig.heads[i] - rig.heads[par])
            quats[i] = mat_to_quat(rig.rotations[par].T @ rig.rotations[i])
    return trans, quats


def write_rigged_glb(path, recipe, source, P, N, joints, weights, rig, clips):
    """İskeletli GLB: köşe sırası ham dosyanınkidir; doku ham 8K (glb_prepare sınıfın boyuna indirir)."""
    w = GlbWriter()
    pos = w.accessor(P.astype(np.float32), 5126, "VEC3", 34962, minmax=True)
    nor = w.accessor(N.astype(np.float32), 5126, "VEC3", 34962)
    uv = w.accessor(source.uvs, 5126, "VEC2", 34962)
    jnt = w.accessor(joints.astype(np.uint8), 5121, "VEC4", 34962)
    wgt = w.accessor(weights.astype(np.float32), 5126, "VEC4", 34962)
    idx = w.accessor(source.tris.ravel(), 5125, "SCALAR", 34963)
    img = w.blob_view(source.image)
    # Bağ matrisleri: dinlenme dünyasının tersi, sütun düzeni.
    inverse = np.zeros((len(rig), 16), dtype=np.float32)
    for i in range(len(rig)):
        m = np.eye(4)
        m[:3, :3] = rig.rotations[i].T
        m[:3, 3] = -(rig.rotations[i].T @ rig.heads[i])
        inverse[i] = m.T.ravel()
    ibm = w.accessor(inverse, 5126, "MAT4")
    # Düğümler: 0 Armature, 1 ağ, 2.. kemikler.
    trans, quats = rest_locals(rig)
    base = 2
    nodes = [{"name": "Armature", "children": [1, base]}, {"name": recipe["id"], "mesh": 0, "skin": 0}]
    for i, name in enumerate(rig.names):
        children = [base + k for k, par in enumerate(rig.parents) if par == i]
        node = {"name": name, "translation": [float(v) for v in trans[i]], "rotation": [float(v) for v in quats[i]]}
        if children:
            node["children"] = children
        nodes.append(node)
    animations = []
    for name, clip in clips.items():
        times = w.accessor(clip["times"].astype(np.float32), 5126, "SCALAR", minmax=True)
        samplers = []
        channels = []

        def track(bone_index, path_name, values, kind):
            acc = w.accessor(values.astype(np.float32), 5126, kind)
            samplers.append({"input": times, "output": acc, "interpolation": "LINEAR"})
            channels.append({"sampler": len(samplers) - 1, "target": {"node": base + bone_index, "path": path_name}})

        for i, bone in enumerate(rig.names):
            if bone == "Root":
                continue
            track(i, "rotation", clip["rot"][:, i], "VEC4")
            # Yalnız gövde kökü ve karın yaprağı öteleme taşır; bacak zinciri FK ile aynı noktaya varır.
            if bone in ("Hips", "Belly"):
                track(i, "translation", clip["pos"][:, i], "VEC3")
            if bone == "Belly":
                scale = clip["scale"].get(bone)
                if scale is None:
                    scale = np.ones((len(clip["times"]), 3))
                track(i, "scale", scale, "VEC3")
        animations.append({"name": name, "samplers": samplers, "channels": channels})
    material = dict(source.material)
    material["name"] = recipe["id"]
    doc = {"asset": {"version": "2.0", "generator": "tools/blender/quadruped_rig.py"}, "scene": 0, "scenes": [{"nodes": [0]}], "nodes": nodes,
           "meshes": [{"name": recipe["id"], "primitives": [{"attributes": {"POSITION": pos, "NORMAL": nor, "TEXCOORD_0": uv, "JOINTS_0": jnt, "WEIGHTS_0": wgt},
                                                              "indices": idx, "material": 0}]}],
           "skins": [{"name": recipe["id"] + "_skin", "joints": [base + i for i in range(len(rig))], "inverseBindMatrices": ibm, "skeleton": base}],
           "materials": [material], "textures": [{"source": 0, "sampler": 0}], "samplers": [source.sampler],
           "images": [{"bufferView": img, "mimeType": source.mime}], "animations": animations}
    w.finish(path, doc)


def report_weights(rig, joints, weights, welded):
    """Dikiş denetimi: aynı konumdaki kopyaların ağırlığı aynı mı; kemik başına etkili köşe."""
    sets = {}
    bad = 0
    for k, w_id in enumerate(welded.index):
        key = tuple(sorted(zip(joints[k].tolist(), np.round(weights[k], 4).tolist())))
        if sets.setdefault(int(w_id), key) != key:
            bad += 1
    used = np.zeros(len(rig))
    for c in range(4):
        np.add.at(used, joints[:, c], (weights[:, c] > 0.05).astype(float))
    print("  ağırlık: dikişte ayrışan kopya %d; bağsız kemik: %s" % (bad, [rig.names[i] for i in range(len(rig)) if used[i] == 0]))
    return bad


# --- 6. Uzak ağ --------------------------------------------------------------------------------------------------

def decimate(positions, tris, importance, target, factor):
    """Blender Decimate (collapse): (köşeler, üçgenler). importance yüksek köşe geç gider."""
    mesh = bpy.data.meshes.new("far_src")
    mesh.from_pydata(positions.tolist(), [], tris.tolist())
    mesh.update()
    obj = bpy.data.objects.new("far_src", mesh)
    bpy.context.scene.collection.objects.link(obj)
    # Decimate'te düşük ağırlık geç gider (0 kilitler): önemli köşe küçük ağırlık alır.
    group = obj.vertex_groups.new(name="keep")
    for i, value in enumerate(importance.tolist()):
        group.add([i], 1.0 - 0.9 * float(value), "REPLACE")
    mod = obj.modifiers.new("dec", "DECIMATE")
    mod.decimate_type = "COLLAPSE"
    mod.use_collapse_triangulate = True
    mod.vertex_group = "keep"
    mod.vertex_group_factor = factor
    best = None
    ratio = target / float(len(tris))
    for _ in range(8):
        mod.ratio = ratio
        obj.update_tag()
        bpy.context.view_layer.update()
        depsgraph = bpy.context.evaluated_depsgraph_get()
        result = obj.evaluated_get(depsgraph).to_mesh()
        count = sum(1 for _p in result.polygons)
        verts = np.array([v.co[:] for v in result.vertices], dtype=np.float64)
        faces = np.array([p.vertices[:] for p in result.polygons if len(p.vertices) == 3], dtype=np.int64)
        obj.evaluated_get(depsgraph).to_mesh_clear()
        best = (verts, faces)
        if abs(count - target) <= target * 0.03:
            break
        ratio *= target / float(count)
    bpy.data.objects.remove(obj)
    bpy.data.meshes.remove(mesh)
    return best


def corner_normals(verts, faces):
    """Köşe normalleri (üçgen, 3, 3): alan ağırlıklı yumuşak normal; indirgemede katlanan üçgende (yumuşak normal yüze ters) yüz normali, yoksa kara leke çıkar."""
    a, b, c = verts[faces[:, 0]], verts[faces[:, 1]], verts[faces[:, 2]]
    fn = np.cross(b - a, c - a)
    smooth = np.zeros_like(verts)
    for k in range(3):
        np.add.at(smooth, faces[:, k], fn)
    smooth /= np.maximum(np.linalg.norm(smooth, axis=1, keepdims=True), 1e-12)
    unit_fn = fn / np.maximum(np.linalg.norm(fn, axis=1, keepdims=True), 1e-12)
    out = smooth[faces]
    bad = (out * unit_fn[:, None, :]).sum(2) < 0.25
    out[bad] = np.repeat(unit_fn[:, None, :], 3, axis=1)[bad]
    print("  uzak ağ normalleri: %d köşe yüz normali aldı" % int(bad.sum()))
    return out


class AtlasPalette:
    """Atlasın tekdüze renkli küçük yamaları: renge en yakın yamanın UV'si. Meshy atlası binlerce küçük adadır; indirgenen üçgen ya da örtülen ada, atlasta bu yamalardan
    birine bakar (yama birkaç texeldir, ada kenarını aşmaz)."""

    def __init__(self, thumb, patch_texels):
        self.h, self.w = thumb.shape[:2]
        self.patch = patch_texels
        pad = np.pad(thumb.astype(np.float64), ((1, 0), (1, 0), (0, 0)))
        self.sat = pad.cumsum(0).cumsum(1)
        table2 = (pad * pad).cumsum(0).cumsum(1)
        radius = int(math.ceil(patch_texels)) + 1
        gx, gy = np.meshgrid(np.arange(radius, self.w - radius, 2), np.arange(radius, self.h - radius, 2))
        gx, gy = gx.ravel(), gy.ravel()
        mean = self.box(self.sat, gx, gy, radius)
        spread = (self.box(table2, gx, gy, radius) - mean * mean).sum(1)
        good = (spread < 0.002) & (mean.mean(1) > 0.06)
        self.xy = np.column_stack((gx[good], gy[good]))
        self.colors = mean[good]

    def box(self, table, px, py, r):
        x0, x1 = np.clip(px - r, 0, self.w), np.clip(px + r + 1, 0, self.w)
        y0, y1 = np.clip(py - r, 0, self.h), np.clip(py + r + 1, 0, self.h)
        area = np.maximum((x1 - x0) * (y1 - y0), 1)[:, None]
        return (table[y1, x1] - table[y0, x1] - table[y1, x0] + table[y0, x0]) / area

    def sample(self, uv, r=1):
        """UV noktalarının kutu süzgeçli rengi."""
        px = np.clip((uv[:, 0] * self.w).astype(int), 0, self.w - 1)
        py = np.clip((uv[:, 1] * self.h).astype(int), 0, self.h - 1)
        return self.box(self.sat, px, py, r)

    def nearest(self, color):
        """(yama merkezi UV, renk hatası)."""
        score = np.abs(self.colors - color).sum(1)
        k = int(np.argmin(score))
        return (self.xy[k] + 0.5) / np.array([self.w, self.h]), float(score[k])

    def triangle(self, center):
        """Yamanın küçük UV üçgeni."""
        r = self.patch / float(self.w)
        return center + np.array([[-r, -r * 0.6], [r, -r * 0.6], [0.0, r]])


def far_uvs(verts, faces, source, P, palette, samples):
    """Her uzak üçgene atlasta bölgesinin ortalama rengini taşıyan küçük bir yama. Döner: (üçgen, 3, 2) UV."""
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    tree = BVHTree.FromPolygons([tuple(v) for v in P.tolist()], source.tris.tolist(), all_triangles=True)
    rng = np.random.default_rng(7)
    uvs = np.zeros((len(faces), 3, 2), dtype=np.float32)
    errors = []
    for fi, face in enumerate(faces):
        a, b, c = verts[face[0]], verts[face[1]], verts[face[2]]
        bary = rng.dirichlet((1.0, 1.0, 1.0), samples)
        points = bary[:, 0:1] * a + bary[:, 1:2] * b + bary[:, 2:3] * c
        cand = []
        for point in points:
            hit = tree.find_nearest(Vector(point.tolist()))
            if hit[2] is not None:
                cand.append(source.uvs[source.tris[hit[2]]].mean(axis=0))
        colors = palette.sample(np.array(cand))
        lit = colors.mean(1) > 0.06
        target = (colors[lit] if lit.any() else colors).mean(axis=0)
        center, error = palette.nearest(target)
        errors.append(error)
        uvs[fi] = palette.triangle(center)
    print("  uzak ağ UV: palet %d yama, renk hatası ort. %.3f, en çok %.3f" % (len(palette.colors), float(np.mean(errors)), float(np.max(errors))))
    return uvs


def write_far_glb(path, recipe, source, verts, faces, normals, uvs, image_uri):
    """Uzak ağ: iskeletsiz, köşeler üçgen başına; görsel aynı klasördeki doku dosyasına bakar (Godot aynı Texture2D'yi yükler)."""
    w = GlbWriter()
    corners = faces.ravel()
    pos = w.accessor(verts[corners].astype(np.float32), 5126, "VEC3", 34962, minmax=True)
    nor = w.accessor(normals.reshape(-1, 3).astype(np.float32), 5126, "VEC3", 34962)
    uv = w.accessor(uvs.reshape(-1, 2).astype(np.float32), 5126, "VEC2", 34962)
    idx = w.accessor(np.arange(len(corners), dtype=np.uint32), 5125, "SCALAR", 34963)
    material = dict(source.material)
    material["name"] = recipe["id"] + "_far"
    doc = {"asset": {"version": "2.0", "generator": "tools/blender/quadruped_rig.py"}, "scene": 0, "scenes": [{"nodes": [0]}],
           "nodes": [{"name": recipe["id"] + "_far", "mesh": 0}],
           "meshes": [{"name": recipe["id"] + "_far", "primitives": [{"attributes": {"POSITION": pos, "NORMAL": nor, "TEXCOORD_0": uv}, "indices": idx, "material": 0}]}],
           "materials": [material], "textures": [{"source": 0, "sampler": 0}], "samplers": [source.sampler], "images": [{"uri": image_uri}]}
    w.finish(path, doc)


def build_far(recipe, source, P, welded, lum, thumb, out_dir):
    if bpy is None:
        sys.exit("Uzak ağ Blender ister: blender -b --python tools/blender/quadruped_rig.py -- <tarif> --only=far")
    fc = recipe["far"]
    rid = recipe["id"]
    dark = sstep(recipe["weights"]["dark_lum"][1], recipe["weights"]["dark_lum"][0], lum)
    y = welded.positions[:, 1]
    keep = np.maximum(dark, sstep(fc["keep_below"] + 0.03, fc["keep_below"] - 0.01, y))
    keep = welded.smooth(keep, 2)
    # İndirgeme kaynağı: yünün derin kıvrımları yumuşar (bütçe bacak ve başa kalsın), koyu köşeler yerinde.
    surface = welded.smooth(welded.positions, fc["wool_smooth"], pinned=keep > 0.6)
    verts, faces = decimate(surface, welded.tris, keep, fc["triangles"], fc["keep_factor"])
    # Kaynak ağın boyuna otur (yumuşatma ve indirgeme az da olsa küçültür); taban y = 0.
    low, high = welded.positions.min(0), welded.positions.max(0)
    vlow, vhigh = verts.min(0), verts.max(0)
    verts = low + (verts - vlow) * (high - low) / np.maximum(vhigh - vlow, 1e-9)
    normals = corner_normals(verts, faces)
    uvs = far_uvs(verts, faces, source, P, AtlasPalette(thumb, fc["patch_texels"]), fc["samples"])
    image_uri = rid + "_0.jpg"
    path = os.path.join(out_dir, rid + "_far.glb")
    write_far_glb(path, recipe, source, verts, faces, normals, uvs, image_uri)
    print("  uzak ağ: %d üçgen, kutu %s - %s, %.2f MB" % (len(faces), np.round(verts.min(0), 3).tolist(), np.round(verts.max(0), 3).tolist(), os.path.getsize(path) / 1e6))
    return len(faces)


# --- 7. Ölçüler ve içe aktarma ayarları ----------------------------------------------------------------------------

def write_meta(recipe, rig, welded, info, out_dir, far_triangles):
    """<id>.json: binek noktası, boy, baş yönü, klipler. Yürüyen klipte speed_mps ve stride_m oyunun oynatma hızını (f = v / L) verir."""
    p = welded.positions
    sc = recipe["saddle"]
    picked = (np.abs(p[:, 0]) < sc["probe"][0]) & (np.abs(p[:, 2] - sc["z"]) < sc["probe"][1])
    saddle_y = float(np.percentile(p[picked, 1], 90.0)) - sc["sink"]
    shoulder = info["shoulder_m"]
    head = rig.heads[rig.index["Head"]]
    nose = np.array(recipe["skeleton"]["nose"])
    clips = {}
    for name, spec in recipe["clips"].items():
        row = {"length_s": round(float(spec.get("length_s", spec.get("stride_m", 0.0) / spec.get("speed_mps", 1.0))), 4), "loop": bool(spec.get("loop", True))}
        if "stride_m" in spec:
            row.update({"speed_mps": spec["speed_mps"], "stride_m": spec["stride_m"], "duty": spec["duty"], "phases": spec["phases"]})
        if "times" in spec:
            # Bir kez oynayan klibin evreleri (saniye) ve basan toynağın geri kayma hızı: oyun evreleri bunlarla eşler (RideableHorse.leap).
            row.update({"times": spec["times"], "ground_mps": spec["ground_mps"],
                        "legs": {leg: [round(a, 4), round(b, 4)] for leg, (a, b) in jump_leg_times(spec).items()}})
        clips[name] = row
    meta = {
        "id": recipe["id"],
        "generated_by": "tools/blender/quadruped_rig.py",
        "forward": [0.0, 0.0, 1.0],
        "up": [0.0, 1.0, 0.0],
        "length_m": round(float(p[:, 2].max() - p[:, 2].min()), 4),
        "shoulder_m": round(shoulder, 4),
        "height_m": round(float(p[:, 1].max()), 4),
        "width_m": round(float(p[:, 0].max() - p[:, 0].min()), 4),
        "saddle_y": round(saddle_y, 4),
        "saddle_z": sc["z"],
        "saddle_bone": sc["bone"],
        "head_dir": [round(float(v), 4) for v in unit(nose - head)],
        "nose": [round(float(v), 4) for v in nose],
        "deform_bones": len(rig) - 1,
        "bones": list(rig.names),
        "clips": clips,
    }
    if "far" in recipe:
        meta["far"] = {"path": recipe["id"] + "_far.glb", "triangles": far_triangles}
    if "Mane1" in rig.index:
        meta["mane_bones"] = chain_names(rig, "Mane")
    meta["tail_bones"] = chain_names(rig, "Tail")
    with open(os.path.join(out_dir, recipe["id"] + ".json"), "w", encoding="utf-8") as fh:
        json.dump(meta, fh, indent=1, ensure_ascii=False)
        fh.write("\n")
    print("  %s.json: boy %.3f, omuz %.3f, sırt y %.3f z %.3f" % (recipe["id"], meta["length_m"], meta["shoulder_m"], meta["saddle_y"], meta["saddle_z"]))
    return meta


def configure_import(recipe, out_dir):
    """İçe aktarma ayarları: klipler döngülü (tarifte loop false olan bir kez oynar: sıçrama; _subresources merge_subresources ile), anahtar azaltma kapalı (azaltma basan toynağı 1 cm'ye dek oynatır), sabit iz
    silinmez (kliplerin izi aynı kalsın: geçişte kemik takılmaz). Uzak ağda LOD ve gölge ağı üretilmez (MultiMesh tek LOD alır). İlk içe aktarmadan sonra çalışır;
    .import yoksa bildirir."""
    rid = recipe["id"]
    sub = {"animations": {name: {"settings/loop_mode": 1 if recipe["clips"][name].get("loop", True) else 0} for name in sorted(recipe["clips"])},
           "nodes": {"PATH:AnimationPlayer": {"optimizer/enabled": False}}}
    entries = {
        rid + ".glb.import": [("animation/remove_immutable_tracks", "false"), ("animation/fps", str(recipe.get("import_fps", 30)))],
    }
    if "far" in recipe:
        entries[rid + "_far.glb.import"] = [("meshes/generate_lods", "false"), ("meshes/create_shadow_meshes", "false"), ("meshes/ensure_tangents", "false")]
    pending = False
    for name, params in entries.items():
        path = os.path.join(out_dir, name)
        if not os.path.exists(path):
            print("  %s yok: önce içe aktarın (source tools/_godot_lock.sh; godot_import_locked), sonra --only=import" % name)
            pending = True
            continue
        changed = glb_prepare.patch_import(path, params)
        if name == rid + ".glb.import" and merge_subresources(path, sub):
            changed.append("_subresources")
        print("  %s: %s" % (name, ", ".join(changed) if changed else "ayarlı"))
    plan = glb_prepare.load_plan()
    glb_prepare.write_textures(plan, rid, 2)
    return pending


def merge_subresources(import_path, wanted):
    """[params]'ın _subresources sözlüğüne istenen ayarları katar (öteki anahtarlar kalır). Godot içe aktarınca değeri çok satıra açar (JSON biçiminde); satır satır
    çalışan glb_prepare.patch_import onu bozardı, burada sözlük bütün okunur. Değişirse değer tek satır yazılır (Godot içe aktarırken yine açar). Değiştiyse True."""
    with open(import_path, encoding="utf-8") as fh:
        lines = fh.read().split("\n")
    prefix = "_subresources="
    start = next((i for i, line in enumerate(lines) if line.startswith(prefix)), None)
    current = {}
    end = start
    if start is not None:
        depth = 0
        for end in range(start, len(lines)):
            depth += lines[end].count("{") - lines[end].count("}")
            if depth == 0:
                break
        current = json.loads("\n".join(lines[start:end + 1])[len(prefix):])
    merged = json.loads(json.dumps(current))
    for group, items in wanted.items():
        target = merged.setdefault(group, {})
        for item, settings in items.items():
            target.setdefault(item, {}).update(settings)
    if merged == current:
        return False
    # Açılmış değer aynı biçimde (satır başına bir anahtar, girintisiz) yazılır.
    text = prefix + (json.dumps(merged, indent=0) if start is not None and end > start else json.dumps(merged))
    if start is None:
        # Bölümün sonuna (glb_prepare.patch_import gibi): [params]'ın son dolu satırından sonra.
        at = next((i for i, line in enumerate(lines) if line.strip() == "[params]"), len(lines) - 1) + 1
        while at < len(lines) and not lines[at].startswith("["):
            at += 1
        while at > 0 and lines[at - 1] == "":
            at -= 1
        lines.insert(at, text)
    else:
        lines[start:end + 1] = [text]
    with open(import_path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))
    return True


# --- Giriş -------------------------------------------------------------------------------------------------------

def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    options = {}
    positional = []
    for a in argv:
        if a.startswith("--"):
            key, _, value = a[2:].partition("=")
            options[key] = value or "1"
        else:
            positional.append(a)
    if not positional:
        sys.exit(__doc__)
    return positional[0], options


def merged(base, over):
    """Tarifin kopyası: over'ın sözlükleri iç içe birleşir, öteki değerleri yerine geçer."""
    out = dict(base)
    for key, value in over.items():
        out[key] = merged(out[key], value) if isinstance(value, dict) and isinstance(out.get(key), dict) else value
    return out


def recipe_models(recipe, only=None):
    """Tarifin modelleri: models bölümü varsa her model (ortak sayılar + modelin üstüne yazdıkları; id modelin adı), yoksa tarifin kendisi.
    Aynı türün iki Meshy ağı (doru ve kır at) tek tarifle kurulur: iskelet ve klipler ortaktır, ağdan ölçülen eklemler ve ağa göre noktalar modelindir."""
    models = recipe.get("models")
    if not models:
        return [recipe]
    base = {k: v for k, v in recipe.items() if k != "models"}
    out = []
    for model_id, over in models.items():
        if only and model_id != only:
            continue
        model = merged(base, over)
        model["id"] = model_id
        out.append(model)
    if not out:
        sys.exit("tarifte %s modeli yok (var: %s)" % (only, ", ".join(models)))
    return out


def main():
    recipe_path, options = parse_args()
    with open(recipe_path if os.path.isabs(recipe_path) else os.path.join(GAME, recipe_path), encoding="utf-8") as fh:
        recipe = json.load(fh)
    for model in recipe_models(recipe, options.get("model")):
        run(model, options)


def run(recipe, options):
    print("== %s" % recipe["id"])
    stages = set(options.get("only", "rig,far,meta,import").split(","))
    if "far" not in recipe:
        stages.discard("far")
    # --out=<klasör> (deneme): çıktı oyun klasörü yerine oraya ({id} modelin adı).
    out_dir = options["out"].replace("{id}", recipe["id"]) if options.get("out") else os.path.join(GAME, recipe["output_dir"])
    os.makedirs(out_dir, exist_ok=True)
    source = Source(os.path.join(GAME, recipe["source"]))
    P, N, info = normalize(source, recipe)
    print("normalize", {k: round(v, 4) for k, v in info.items()}, "kutu", np.round(P.min(0), 3).tolist(), np.round(P.max(0), 3).tolist())
    if "debug-normal" in options:
        image = None
        if options.get("debug-image"):
            with open(options["debug-image"], "rb") as fh:
                image = fh.read()
        path = options["debug-normal"].replace("{id}", recipe["id"])
        write_debug_mesh(path, P, N, source, image)
        return
    welded = Welded(P, source.tris)
    thumb = source.thumbnail(1024)
    lum = vertex_colors(source, welded, thumb).mean(axis=1)
    rig = build_rig(recipe, welded)
    print("iskelet: %d kemik" % len(rig))
    solver = Solver(rig)
    if "rig" in stages:
        W = compute_weights(recipe, rig, welded, lum)
        order, values = limit_influences(W)
        joints = welded.spread(order)
        weights = welded.spread(values)
        report_weights(rig, joints, weights, welded)
        clips = build_clips(recipe, rig, solver)
        tmp_dir = options.get("tmp") or os.environ.get("TMPDIR") or tempfile.gettempdir()
        tmp_glb = os.path.join(tmp_dir, recipe["id"] + "_8k.glb")
        write_rigged_glb(tmp_glb, recipe, source, P, N, joints, weights, rig, clips)
        cls = glb_prepare.texture_class(glb_prepare.load_plan(), recipe["texture_class"])
        final_glb = os.path.join(out_dir, recipe["id"] + ".glb")
        glb_prepare.prepare(tmp_glb, final_glb, cls[1], 2, cls)
        os.remove(tmp_glb)
        # Uzak ağ bu dosyaya bakar: Godot'nun çıkarmasını beklemeden yazılır (dokular sahneden önce içe aktarılır, aynı baytlar yeniden yazılmaz).
        texture_path = dict(glb_prepare.extracted_textures(final_glb))[0]
        if not os.path.exists(texture_path):
            with open(texture_path, "wb") as fh:
                fh.write(glb_prepare.glb_images(final_glb)[0][2])
    far_triangles = None
    if "far" in stages:
        far_triangles = build_far(recipe, source, P, welded, lum, thumb, out_dir)
    if "meta" in stages:
        if far_triangles is None:
            old = os.path.join(out_dir, recipe["id"] + ".json")
            if os.path.exists(old):
                with open(old, encoding="utf-8") as fh:
                    far_triangles = json.load(fh).get("far", {}).get("triangles")
        for spec in recipe["clips"].values():
            if "stride_m" in spec:
                spec["length_s"] = spec["stride_m"] / spec["speed_mps"]
        write_meta(recipe, rig, welded, info, out_dir, far_triangles)
    if "import" in stages:
        configure_import(recipe, out_dir)


if __name__ == "__main__":
    main()
