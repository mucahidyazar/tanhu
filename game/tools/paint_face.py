#!/usr/bin/env python3
"""
Meshy kişisinin yüzünü kredisiz boyar: kaynak görselin yüzü, ağın ön yüzeyine dik izdüşümle dokuya işlenir. Ağ, UV, iskelet ve
klipler değişmez; yalnız renk dokusu değişir. Ham dosyalara dokunmaz: assets/_meshy_raw/<id>/ içindeki hiçbir dosya yazılmaz, yalnız
altındaki face_paint/ klasörü bu aracındır.

GERİ ALMA (game/ klasöründe):
  python3 tools/paint_face.py <id> --undo
  source tools/_godot_lock.sh; godot_import_locked
  Godot --headless --path . -s res://tools/clip_library_export.gd -- <id>
Bu, boyalı dokuyu (face_paint/<id>_painted.jpg) siler, oyun GLB'sini ve <id>_Image_0.jpg'yi ham 8K'dan yeniden yazar. Ayar ve kaynak
(face_paint/paint.json) durur, araç yeniden koşulunca aynı boya gelir. Boya varken tools/glb_prepare.py ham 8K yerine boyalı dokuyu
okur: tools/prepare_character.py yeniden koşsa da yüz kaybolmaz.

Yöntem:
  1. Yüz bölgesindeki üçgenler seçilir (paint.json window). Ten yüzeyinden yükselen koyu üçgenler saç tutamıdır, ham kalır.
  2. Her üçgen 8K doku uzayında taranır; her dokunun 3B konumu üçgen içi hesaplanır, (x, y) ile kaynak görsele bakılır. Eşleme benzerlik
     dönüşümüdür: anchor_mesh ↔ anchor_source, scale_px_per_m. Hizayı göz çizgisi, burun, ağız ve çene belirler.
  3. polygon (kaynak pikseli) yumuşatılıp maske olur: kenarda ham tene karışır, saç çizgisine taşmaz. hair_guard çokgenlerinde ham dokunun
     koyu pikseli (alında ve şakakta yalnız saçtır) boyanmaz. Ağın alt yüzü konseptten kısaysa warp_y düşey eşlemeyi parça parça kurar.
  4. Kaynağın teni, maskenin kenar bandında ham tene eşitlenir (doğrusal ışıkta kanal kazancı). Beyaz, gri, kızıl ve koyuya kazanç
     uygulanmaz: dişler, göz akı, ağız içi ve iris rengini korur. Kaynak önce oyun dokusunun boyuna göre rötuşlanır (paint.json).
  5. Üçgen kenarından dışarı doğru, atlasın boş dokularına da izdüşümle boyanır (gutter): doku küçültülürken adanın kenarı kendi
     rengini görür. Başka parçanın dokusuna yazılmaz.
Sonuç face_paint/<id>_painted.jpg (8K). Oyun kopyasını tools/glb_prepare.py yazar: --embed sınıfın boyunda küçültür ve GLB'ye gömer.
Kaynak "self" ise (2026-11-08, Gutu ve Huyan Hatun) kaynak görsel ağın kendi ham 8K yüzüdür: source_box aynı benzerlik eşlemesiyle önden dik
izdüşümle çizilir (üçgen başına z-tampon, UV'den ham dokuya çift doğrusal bakış). Yüz değişmez; source_cleanup'ın sildiği leke (burun
altındaki koyu iz, çeneye inen açık şerit) çevresindeki tenle dolar, polygon yalnız lekenin çevresini boyar. Ten eşitlemesi yapılmaz (kazanç 1).

Kullanım (game/ klasöründe; Pillow ve numpy sistemi kirletmeden):
  uv run --no-project --with pillow --with numpy python tools/paint_face.py <id> [--dry-run=<klasör>]
  --dry-run: boyalı dokuyu verilen klasöre yazar, projeye dokunmaz. Sonra: source tools/_godot_lock.sh; godot_import_locked
"""
import io
import json
import os
import sys

try:
    import numpy as np
    from PIL import Image, ImageDraw, ImageFilter
except ImportError:
    np = None  # --undo bunlarsız çalışır.

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import glb_prepare  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "assets", "_meshy_raw")
COMP = {5126: "<f4", 5123: "<u2", 5125: "<u4", 5121: "u1"}
NUM = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}
LUMA = (0.299, 0.587, 0.114)
# Boyalı 8K'nın JPEG kalitesi: ham dosyayla aynı sınıfta, kroma küçültmesiz.
PAINT_JPEG_QUALITY = 95
# Kaynak görselin arama öncesi büyütme oranı: 8K dokuda çift doğrusal bakışta basamak görünmesin.
SOURCE_UPSCALE = 4
# Önden derinlik ızgarası (m) ve yerel ten yüzeyinin penceresi (seyrek hücre): yükselen saç tutamı bu ölçekte azınlıktadır.
SURFACE_CELL = 0.0005
SURFACE_STRIDE = 4
SURFACE_RADIUS = 7


def paint_dir(cid):
    return os.path.join(RAW, cid, "face_paint")


def painted_path(cid):
    return os.path.join(paint_dir(cid), "%s_painted.jpg" % cid)


def load_settings(cid):
    path = os.path.join(paint_dir(cid), "paint.json")
    if not os.path.exists(path):
        sys.exit("Ayar yok: %s" % os.path.relpath(path, ROOT))
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def accessor(doc, binary, index):
    acc = doc["accessors"][index]
    view = doc["bufferViews"][acc["bufferView"]]
    dtype = np.dtype(COMP[acc["componentType"]])
    num = NUM[acc["type"]]
    offset = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = view.get("byteStride", 0) or dtype.itemsize * num
    if stride == dtype.itemsize * num:
        return np.frombuffer(binary, dtype, acc["count"] * num, offset).reshape(acc["count"], num).astype(np.float64)
    raw = np.frombuffer(binary, np.uint8, acc["count"] * stride, offset).reshape(acc["count"], stride)
    return np.frombuffer(raw[:, :dtype.itemsize * num].tobytes(), dtype).reshape(acc["count"], num).astype(np.float64)


def load_mesh(path):
    """Bağlama pozundaki ağ (metre, +Y yukarı, +Z ön) ve 8K temel renk görseli."""
    doc, binary = glb_prepare.read_glb(path)
    prim = doc["meshes"][0]["primitives"][0]
    attrs = prim["attributes"]
    mesh = {
        "pos": accessor(doc, binary, attrs["POSITION"]),
        "uv": accessor(doc, binary, attrs["TEXCOORD_0"]),
        "idx": accessor(doc, binary, prim["indices"]).reshape(-1, 3).astype(np.int64),
    }
    image = doc["images"][0]
    view = doc["bufferViews"][image["bufferView"]]
    start = view.get("byteOffset", 0)
    mesh["texture"] = np.asarray(Image.open(io.BytesIO(binary[start: start + view["byteLength"]])).convert("RGB"))
    return mesh


def bilinear(image, x, y):
    """(x, y) piksel merkezi kuralıyla çift doğrusal örnekleme; sınır dışı kenardan okunur."""
    h, w = image.shape[:2]
    fx, fy = x - 0.5, y - 0.5
    x0, y0 = np.floor(fx).astype(np.int64), np.floor(fy).astype(np.int64)
    ax, ay = fx - x0, fy - y0
    if image.ndim == 3:
        ax, ay = ax[..., None], ay[..., None]
    x1, y1 = np.clip(x0 + 1, 0, w - 1), np.clip(y0 + 1, 0, h - 1)
    x0, y0 = np.clip(x0, 0, w - 1), np.clip(y0, 0, h - 1)
    return (image[y0, x0] * (1 - ax) * (1 - ay) + image[y0, x1] * ax * (1 - ay) + image[y1, x0] * (1 - ax) * ay + image[y1, x1] * ax * ay)


def to_linear(c):
    c = np.clip(c / 255.0, 0.0, 1.0)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def to_srgb(c):
    c = np.clip(c, 0.0, 1.0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055) * 255.0


def front_buffer(mesh, tris, x_range, y_range):
    """Üçgenlerin önden görünümü (SURFACE_CELL ızgarası): (z, üçgen). Boş hücrede z nan, üçgen -1; satır 0 en üst."""
    columns = int((x_range[1] - x_range[0]) / SURFACE_CELL) + 1
    rows = int((y_range[1] - y_range[0]) / SURFACE_CELL) + 1
    depth = np.full((rows, columns), -np.inf)
    owner = np.full((rows, columns), -1, dtype=np.int64)
    for t in tris:
        tri = mesh["pos"][mesh["idx"][t]]
        px = (tri[:, 0] - x_range[0]) / SURFACE_CELL
        py = (y_range[1] - tri[:, 1]) / SURFACE_CELL
        xa, xb = max(int(np.floor(px.min())), 0), min(int(np.ceil(px.max())), columns - 1)
        ya, yb = max(int(np.floor(py.min())), 0), min(int(np.ceil(py.max())), rows - 1)
        if xa > xb or ya > yb:
            continue
        denom = (py[1] - py[2]) * (px[0] - px[2]) + (px[2] - px[1]) * (py[0] - py[2])
        if abs(denom) < 1e-9:
            continue
        gx, gy = np.meshgrid(np.arange(xa, xb + 1) + 0.5, np.arange(ya, yb + 1) + 0.5)
        l0 = ((py[1] - py[2]) * (gx - px[2]) + (px[2] - px[1]) * (gy - py[2])) / denom
        l1 = ((py[2] - py[0]) * (gx - px[2]) + (px[0] - px[2]) * (gy - py[2])) / denom
        l2 = 1 - l0 - l1
        z = l0 * tri[0, 2] + l1 * tri[1, 2] + l2 * tri[2, 2]
        sub = depth[ya:yb + 1, xa:xb + 1]
        win = (l0 >= 0) & (l1 >= 0) & (l2 >= 0) & (z > sub)
        sub[win] = z[win]
        owner[ya:yb + 1, xa:xb + 1][win] = t
    depth[owner < 0] = np.nan
    return depth, owner


def local_surface(depth):
    """Seyrek hücrelerde çevrenin alt yüzdeliği (yükselen tutamlar ölçüyü etkilemez). Dönen ızgaranın hücresi SURFACE_CELL × SURFACE_STRIDE."""
    coarse = depth[::SURFACE_STRIDE, ::SURFACE_STRIDE]
    rows, columns = coarse.shape
    out = np.full(coarse.shape, np.nan)
    radius = SURFACE_RADIUS
    for r in range(rows):
        for c in range(columns):
            cell = coarse[max(r - radius, 0): r + radius + 1, max(c - radius, 0): c + radius + 1]
            values = cell[~np.isnan(cell)]
            if values.size:
                out[r, c] = np.percentile(values, 40)
    return out


def sample_surface(surface, x, y, x_range, y_range, fallback):
    cell = SURFACE_CELL * SURFACE_STRIDE
    c = np.clip(((x - x_range[0]) / cell).astype(np.int64), 0, surface.shape[1] - 1)
    r = np.clip(((y_range[1] - y) / cell).astype(np.int64), 0, surface.shape[0] - 1)
    out = surface[r, c]
    return np.where(np.isnan(out), fallback, out)


def warp_source_y(y, table, scale):
    """warp_y: [[ağ y (m), kaynak y (piksel)], ...] parçalı doğrusal düşey eşleme; tablonun dışında benzerlik ölçeği sürer. Ağın alt yüzü konseptten
    kısaysa (çene kapalı üretilmiş) ağız ve çene yukarı toplanır, göz ve burun çizgisi yerinde kalır."""
    table = sorted(table)
    mesh_y = np.array([row[0] for row in table], dtype=np.float64)
    source_y = np.array([row[1] for row in table], dtype=np.float64)
    return np.interp(y, mesh_y, source_y) - np.minimum(y - mesh_y[0], 0.0) * scale - np.maximum(y - mesh_y[-1], 0.0) * scale


def clean_source(image, polygons, sx0, sy0, min_luma=105):
    """Kaynaktan yüze ait olmayan izleri (alına düşen tutam, parlama çizgisi) siler: çokgenin içi çevredeki tenden yayılan renkle dolar.
    Yayılan renk yalnız tenden gelir: saç ve kaş dolguya sızmaz. min_luma (cleanup_min_luma) saçın alna düşürdüğü kahve gölgeyi de dışarıda bırakır."""
    holes = Image.new("L", (image.shape[1], image.shape[0]), 0)
    draw = ImageDraw.Draw(holes)
    for polygon in polygons:
        draw.polygon([(x - sx0, y - sy0) for x, y in polygon], fill=255)
    hole = np.asarray(holes) > 0
    luma = (image * LUMA).sum(-1)
    unknown = hole | ~((luma > min_luma) & (luma < 225) & (image[..., 0] > image[..., 2] + 18))
    fill = image.copy()
    fill[unknown] = image[~unknown].mean(0)
    for _ in range(1500):
        blurred = (np.roll(fill, 1, 0) + np.roll(fill, -1, 0) + np.roll(fill, 1, 1) + np.roll(fill, -1, 1)) / 4.0
        fill[unknown] = blurred[unknown]
    out = image.copy()
    out[hole] = fill[hole]
    return out


def retouch_source(image, settings, sx0, sy0):
    """Oyun dokusunun boyu için rötuş: tints (çokgen içi renk çarpanı) ve strokes (çizgi). Parlak ince şeritler adanın kenarına kadar
    dağılıp yüzde lekeye döner, ince koyu çizgi ise kaybolur (bir doku pikseli ≈3 mm)."""
    scale = 4
    size = (image.shape[1] * scale, image.shape[0] * scale)
    for tint in settings.get("tints", []):
        layer = Image.new("L", size, 0)
        ImageDraw.Draw(layer).polygon([((x - sx0) * scale, (y - sy0) * scale) for x, y in tint["polygon"]], fill=255)
        layer = layer.filter(ImageFilter.GaussianBlur(tint.get("soft_px", 0.7) * scale)).resize((image.shape[1], image.shape[0]), Image.BOX)
        weight = np.asarray(layer).astype(np.float64)[..., None] / 255.0
        image = image * (1.0 - weight * (1.0 - np.array(tint["multiply"], dtype=np.float64)))
    for stroke in settings.get("strokes", []):
        layer = Image.new("L", size, 0)
        ImageDraw.Draw(layer).line([((x - sx0) * scale, (y - sy0) * scale) for x, y in stroke["line"]], fill=255, width=int(round(stroke["width_px"] * scale)), joint="curve")
        layer = layer.filter(ImageFilter.GaussianBlur(0.4 * scale)).resize((image.shape[1], image.shape[0]), Image.BOX)
        weight = np.asarray(layer).astype(np.float64)[..., None] / 255.0 * stroke.get("alpha", 1.0)
        image = image * (1.0 - weight) + np.array(stroke["color"], dtype=np.float64) * weight
    return image


def front_render(mesh, settings):
    """Kaynak "self": ağın ham 8K yüzü, source_box'ın piksellerinde önden dik izdüşümle (eşleme paint'in lookup'ıyla aynı: anchor_mesh ↔
    anchor_source, scale_px_per_m; warp_y yok sayılır). Pencerenin (window) önden görünen üçgenleri z-tamponla taranır, her piksel UV'den
    ham dokuya çift doğrusal bakar. Üçgen düşmeyen piksel çevrenin ortalamasıyla dolar."""
    pos, uv, idx = mesh["pos"], mesh["uv"], mesh["idx"]
    raw = mesh["texture"].astype(np.float64)
    size = raw.shape[0]
    sx0, sy0, sx1, sy1 = settings["source_box"]
    scale = float(settings["scale_px_per_m"])
    ax_src, ay_src = settings["anchor_source"]
    ax_mesh, ay_mesh = settings["anchor_mesh"]
    window = settings["window"]
    corners = pos[idx]
    centers = corners.mean(1)
    tris = np.where((np.abs(centers[:, 0]) < window["x"]) & (centers[:, 1] > window["y"][0]) & (centers[:, 1] < window["y"][1])
                    & (centers[:, 2] > window["z_min"]))[0]
    width, height = sx1 - sx0, sy1 - sy0
    depth = np.full((height, width), -np.inf)
    out = np.zeros((height, width, 3))
    for t in tris:
        tri = corners[t]
        if np.cross(tri[1] - tri[0], tri[2] - tri[0])[2] <= 0:
            continue
        px = ax_src + (tri[:, 0] - ax_mesh) * scale - sx0
        py = ay_src - (tri[:, 1] - ay_mesh) * scale - sy0
        xa, xb = max(int(np.floor(px.min())), 0), min(int(np.ceil(px.max())), width - 1)
        ya, yb = max(int(np.floor(py.min())), 0), min(int(np.ceil(py.max())), height - 1)
        if xa > xb or ya > yb:
            continue
        denom = (py[1] - py[2]) * (px[0] - px[2]) + (px[2] - px[1]) * (py[0] - py[2])
        if abs(denom) < 1e-9:
            continue
        gx, gy = np.meshgrid(np.arange(xa, xb + 1) + 0.5, np.arange(ya, yb + 1) + 0.5)
        l0 = ((py[1] - py[2]) * (gx - px[2]) + (px[2] - px[1]) * (gy - py[2])) / denom
        l1 = ((py[2] - py[0]) * (gx - px[2]) + (px[0] - px[2]) * (gy - py[2])) / denom
        l2 = 1 - l0 - l1
        z = l0 * tri[0, 2] + l1 * tri[1, 2] + l2 * tri[2, 2]
        sub = depth[ya:yb + 1, xa:xb + 1]
        win = (l0 >= -1e-6) & (l1 >= -1e-6) & (l2 >= -1e-6) & (z > sub)
        if not win.any():
            continue
        sub[win] = z[win]
        tuv = uv[idx[t]]
        u = l0 * tuv[0, 0] + l1 * tuv[1, 0] + l2 * tuv[2, 0]
        v = l0 * tuv[0, 1] + l1 * tuv[1, 1] + l2 * tuv[2, 1]
        out[ya:yb + 1, xa:xb + 1][win] = bilinear(raw, u[win] * size, v[win] * size)
    empty = np.isinf(depth)
    if empty.all():
        sys.exit("self kaynak: source_box'a üçgen düşmedi (anchor ve window'u denetleyin)")
    out[empty] = out[~empty].mean(0)
    return out


def paint(settings, log=print):
    """Boyalı 8K dokuyu ve boyanan doku sayısını döndürür."""
    mesh = load_mesh(os.path.join(ROOT, settings["mesh"]))
    pos, uv, idx = mesh["pos"], mesh["uv"], mesh["idx"]
    raw = mesh["texture"]
    size = raw.shape[0]
    # Kaynak: gerekli bölge temizlenir ve büyütülür, maske aynı ızgaradadır. "self": ağın kendi ham yüzü (front_render).
    sx0, sy0, sx1, sy1 = settings["source_box"]
    if settings["source"] == "self":
        crop = Image.fromarray(np.clip(front_render(mesh, settings) + 0.5, 0, 255).astype(np.uint8))
    else:
        crop = Image.open(os.path.join(ROOT, settings["source"])).convert("RGB").crop((sx0, sy0, sx1, sy1))
    prepared = np.asarray(crop).astype(np.float64)
    if settings.get("source_cleanup"):
        prepared = clean_source(prepared, settings["source_cleanup"], sx0, sy0, settings.get("cleanup_min_luma", 105))
    prepared = retouch_source(prepared, settings, sx0, sy0)
    for iris in settings.get("iris", []):
        # Oyun dokusunda iris 3-4 dokuya iner: açık halkası griye döner, bakış kaybolur. Koyultulur.
        gx, gy = np.meshgrid(np.arange(prepared.shape[1]) + 0.5 + sx0, np.arange(prepared.shape[0]) + 0.5 + sy0)
        edge = np.clip((iris["radius"] - np.hypot(gx - iris["center"][0], gy - iris["center"][1])) / 1.5, 0.0, 1.0)
        prepared = prepared * (1.0 - edge[..., None] * (1.0 - iris["factor"]))
    if settings.get("sharpen"):
        # Küçültmede ince koyu çizgi solar (kaynak pikselinden oyun dokusuna ≈2,7 kat): yalnız koyu taraf önceden koyultulur, tende hale çıkmaz.
        soft = np.asarray(Image.fromarray(np.clip(prepared + 0.5, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(settings["sharpen"]["radius_px"]))).astype(np.float64)
        prepared = prepared + np.minimum(prepared - soft, 0.0) * settings["sharpen"]["amount"]
    crop = Image.fromarray(np.clip(prepared + 0.5, 0, 255).astype(np.uint8))
    up = SOURCE_UPSCALE
    source = np.asarray(crop.resize((crop.width * up, crop.height * up), Image.LANCZOS)).astype(np.float64)
    mask_img = Image.new("L", (crop.width * up, crop.height * up), 0)
    ImageDraw.Draw(mask_img).polygon([((x - sx0) * up, (y - sy0) * up) for x, y in settings["polygon"]], fill=255)
    mask_img = mask_img.filter(ImageFilter.GaussianBlur(settings["feather_px"] * up))
    mask = np.asarray(mask_img).astype(np.float64) / 255.0
    scale = float(settings["scale_px_per_m"])
    ax_src, ay_src = settings["anchor_source"]
    ax_mesh, ay_mesh = settings["anchor_mesh"]

    # Saç koruması: bu çokgenlerin içinde (alın, şakak: ham dokuda koyu olan yalnız saçtır) ham dokunun koyu pikseli boyanmaz. Kökte yükselmeyen
    # tutam üçgenine de sürülmez, saç çizgisi hamdaki kadar keskin kalır.
    guard = None
    if settings.get("hair_guard"):
        guard_img = Image.new("L", mask_img.size, 0)
        for polygon in settings["hair_guard"]:
            ImageDraw.Draw(guard_img).polygon([((x - sx0) * up, (y - sy0) * up) for x, y in polygon], fill=255)
        guard = np.asarray(guard_img.filter(ImageFilter.GaussianBlur(up))).astype(np.float64) / 255.0
    warp = settings.get("warp_y")

    def lookup(points):
        """3B noktaların büyütülmüş kaynaktaki (x, y) konumu."""
        source_y = warp_source_y(points[..., 1], warp, scale) if warp else ay_src - (points[..., 1] - ay_mesh) * scale
        return ((ax_src + (points[..., 0] - ax_mesh) * scale - sx0) * up, (source_y - sy0) * up)

    # 1. Aday üçgenler ve saç tutamları.
    window = settings["window"]
    corners = pos[idx]
    centers = corners.mean(1)
    candidates = np.where((np.abs(centers[:, 0]) < window["x"]) & (centers[:, 1] > window["y"][0]) & (centers[:, 1] < window["y"][1])
                          & (centers[:, 2] > window["z_min"]))[0]
    bary = np.array([(i / 7.0, j / 7.0, 1.0 - (i + j) / 7.0) for i in range(8) for j in range(8 - i)])
    tri_uv = uv[idx[candidates]]
    points = (bary[None, :, :, None] * tri_uv[:, None, :, :]).sum(2)
    colors = raw[np.clip((points[..., 1] * size).astype(np.int64), 0, size - 1), np.clip((points[..., 0] * size).astype(np.int64), 0, size - 1)]
    dark = ((colors.astype(np.float64) * LUMA).sum(-1) < settings["hair"]["dark_luma"]).mean(1)
    a, b, c = corners[candidates, 0], corners[candidates, 1], corners[candidates, 2]
    faces_front = np.cross(b - a, c - a)[:, 2] > 0
    x_range = (-window["x"] - 0.01, window["x"] + 0.01)
    y_range = (window["y"][0] - 0.01, window["y"][1] + 0.01)
    depth, owner = front_buffer(mesh, candidates[faces_front], x_range, y_range)
    surface = local_surface(depth)
    center_z = centers[candidates, 2]
    near = sample_surface(surface, centers[candidates, 0], centers[candidates, 1], x_range, y_range, center_z)
    rise = center_z - near
    hair = (dark > settings["hair"]["dark_share"]) & (rise > settings["hair"]["rise_m"])
    # Önden görünen üçgen boyanır; görünmeyenden yalnız yüzeye yakın olan (katlanma, burun kanadı). Kafa arkası ve çene altı ham kalır.
    seen = np.isin(candidates, np.unique(owner[owner >= 0]))
    close = rise > -float(settings["visibility_m"])
    keep = candidates[~hair & (seen | close)]
    log("[aday] %d üçgen; %d saç tutamı ve %d görünmeyen ham kalır, %d boyanır" % (len(candidates), int(hair.sum()), int((~hair & ~(seen | close)).sum()), len(keep)))

    # 2. Atlasın başka parçalara ait dokuları: üstlerine yazılmaz.
    occupied_img = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(occupied_img)
    uv_px = uv[idx] * size
    keep_set = np.zeros(len(idx), bool)
    keep_set[keep] = True
    for t in np.where(~keep_set)[0]:
        draw.polygon([tuple(uv_px[t, 0]), tuple(uv_px[t, 1]), tuple(uv_px[t, 2])], fill=255)
    occupied = np.asarray(occupied_img) > 0

    # 3. Üçgenler: doku başına en yakın üçgen kazanır; önce renk eşitlemesi için örnek toplanır.
    gutter = int(settings["gutter_px"])
    best = np.full((size, size), np.inf, dtype=np.float32)
    jobs = []
    band_raw, band_src = [], []
    for t in keep:
        (x0, y0), (x1, y1), (x2, y2) = uv_px[t]
        denom = (y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2)
        if abs(denom) < 0.5:
            continue
        xa, xb = int(max(np.floor(min(x0, x1, x2)) - gutter, 0)), int(min(np.ceil(max(x0, x1, x2)) + gutter, size - 1))
        ya, yb = int(max(np.floor(min(y0, y1, y2)) - gutter, 0)), int(min(np.ceil(max(y0, y1, y2)) + gutter, size - 1))
        gx, gy = np.meshgrid(np.arange(xa, xb + 1) + 0.5, np.arange(ya, yb + 1) + 0.5)
        l0 = ((y1 - y2) * (gx - x2) + (x2 - x1) * (gy - y2)) / denom
        l1 = ((y2 - y0) * (gx - x2) + (x0 - x2) * (gy - y2)) / denom
        l2 = 1 - l0 - l1
        # Kenar uzaklığı: barisentrik × yükseklik (içeride artı). Dışarıda en kısa kenara göre, dokuda.
        h0 = abs(denom) / max(np.hypot(x2 - x1, y2 - y1), 1e-9)
        h1 = abs(denom) / max(np.hypot(x0 - x2, y0 - y2), 1e-9)
        h2 = abs(denom) / max(np.hypot(x1 - x0, y1 - y0), 1e-9)
        distance = -np.minimum(np.minimum(l0 * h0, l1 * h1), l2 * h2).astype(np.float32)
        sub_occupied = occupied[ya:yb + 1, xa:xb + 1]
        allowed = (distance <= gutter) & ((~sub_occupied) | (distance <= 0))
        sub_best = best[ya:yb + 1, xa:xb + 1]
        winner = allowed & (distance < sub_best)
        if not winner.any():
            continue
        sub_best[winner] = distance[winner]
        rows, cols = np.where(winner)
        # İnce üçgende kenar dışı izdüşüm uzağa kaçmasın.
        w0, w1, w2 = np.clip(l0[winner], -0.6, 1.6), np.clip(l1[winner], -0.6, 1.6), np.clip(l2[winner], -0.6, 1.6)
        total = w0 + w1 + w2
        jobs.append((int(t), rows + ya, cols + xa, w0 / total, w1 / total, w2 / total, distance[winner]))
    # Yalnız son kazanan doku kullanılır: her iş kendi doku listesini kazanana göre süzer.
    filtered = []
    for t, rows, cols, w0, w1, w2, distance in jobs:
        still = best[rows, cols] == distance
        if not still.any():
            continue
        point = w0[still, None] * pos[idx[t, 0]] + w1[still, None] * pos[idx[t, 1]] + w2[still, None] * pos[idx[t, 2]]
        filtered.append((rows[still], cols[still], point, distance[still]))
    log("[tarama] %d üçgen, %d doku" % (len(filtered), sum(len(f[0]) for f in filtered)))

    # 4. Renk eşitleme: maskenin dolu kısmının kenar bandında ham ten ↔ kaynak ten.
    def skin_like(c):
        luma = (c * LUMA).sum(-1)
        return (luma > 105) & (luma < 225) & (c[..., 0] > c[..., 2] + 18)

    for rows, cols, point, distance in filtered:
        inside = distance <= 0
        if not inside.any():
            continue
        sx, sy = lookup(point[inside])
        alpha = bilinear(mask, sx, sy)
        band = (alpha > settings["match_band"][0]) & (alpha < settings["match_band"][1])
        if band.any():
            band_raw.append(raw[rows[inside][band], cols[inside][band]].astype(np.float64))
            band_src.append(bilinear(source, sx[band], sy[band]))
    band_raw = np.concatenate(band_raw)
    band_src = np.concatenate(band_src)
    raw_skin = np.median(band_raw[skin_like(band_raw)], 0)
    src_skin = np.median(band_src[skin_like(band_src)], 0)
    gain = to_linear(raw_skin) / to_linear(src_skin)
    if settings["source"] == "self":
        # Kaynak ağın kendi dokusudur: eşitlenecek ten farkı yoktur. Kıvrık yüzeyde (çene altı) önden izdüşüm başka yerin rengini okur,
        # bant ölçüsü kayar; kazanç 1'de tutulur.
        gain = np.ones(3)
    src_saturation = (src_skin.max() - src_skin.min()) / src_skin.max()
    src_tone = (src_skin[1] - src_skin[2]) / (src_skin[0] - src_skin[2])
    log("[ten] ham %s, kaynak %s, kazanç %s" % (raw_skin.round(1).tolist(), src_skin.round(1).tolist(), gain.round(3).tolist()))

    def adjust(c):
        # Tam kazanç yalnız tenle aynı tondaki aydınlık renge: beyaz, gri, kızıl ve koyu (göz akı, diş, ağız içi, iris, kaş) kendi rengini korur.
        high, low = c.max(-1), c.min(-1)
        saturation = (high - low) / np.maximum(high, 1.0)
        tone = (c[..., 1] - c[..., 2]) / np.maximum(c[..., 0] - c[..., 2], 1.0)
        luma = (c * LUMA).sum(-1)
        weight = (np.clip(saturation / (src_saturation * 0.75), 0.0, 1.0) * np.clip(1.0 - np.abs(tone - src_tone) / 0.3, 0.0, 1.0)
                  * np.clip((luma - 70.0) / 40.0, 0.0, 1.0))
        adjusted = to_srgb(to_linear(c) * (1.0 + (gain - 1.0) * weight[..., None]))
        # Çok koyu çizgi öteki kişilerin yumuşak boyasına göre mürekkep gibi durur: tene doğru biraz açılır.
        lift = float(settings.get("dark_lift", 0.0)) * np.clip((90.0 - luma) / 40.0, 0.0, 1.0)
        return adjusted + (raw_skin - adjusted) * lift[..., None]

    # 5. Dokuya yaz.
    out = raw.copy()
    written = 0
    for rows, cols, point, distance in filtered:
        sx, sy = lookup(point)
        alpha = bilinear(mask, sx, sy)
        use = alpha > 0.002
        if not use.any():
            continue
        color = adjust(bilinear(source, sx[use], sy[use]))
        blend = alpha[use, None]
        if guard is not None:
            limit = settings["hair"]["guard_luma"]
            keep = bilinear(guard, sx[use], sy[use]) * np.clip((limit[1] - (raw[rows[use], cols[use]].astype(np.float64) * LUMA).sum(-1)) / (limit[1] - limit[0]), 0.0, 1.0)
            blend = blend * (1.0 - keep[:, None])
        out[rows[use], cols[use]] = np.clip(raw[rows[use], cols[use]] * (1.0 - blend) + color * blend + 0.5, 0, 255).astype(np.uint8)
        written += int(use.sum())
    return out, written


def main():
    argv = sys.argv[1:]
    args = [a for a in argv if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in argv if a.startswith("--"))
    if len(args) != 1:
        sys.exit(__doc__)
    cid = args[0]
    plan = glb_prepare.load_plan()
    if "undo" in opts:
        path = glb_prepare.painted_source(cid)
        if path:
            os.remove(path)
            print("[geri alma] %s silindi" % os.path.relpath(path, ROOT))
        glb_prepare.embed_texture(plan, cid, 2)
        print("Sıradaki adım: source tools/_godot_lock.sh; godot_import_locked")
        return
    if np is None:
        sys.exit("Pillow ve numpy gerekli: uv run --no-project --with pillow --with numpy python tools/paint_face.py %s" % cid)
    painted, texels = paint(load_settings(cid))
    target = os.path.join(opts["dry-run"], "%s_painted.jpg" % cid) if "dry-run" in opts else painted_path(cid)
    Image.fromarray(painted).save(target, quality=PAINT_JPEG_QUALITY, subsampling=0, optimize=True)
    print("[boya] %d doku → %s (%.1f MB)" % (texels, target, os.path.getsize(target) / 1e6))
    if "dry-run" in opts:
        return
    glb_prepare.embed_texture(plan, cid, 2)
    print("Sıradaki adım: source tools/_godot_lock.sh; godot_import_locked")


if __name__ == "__main__":
    main()
