#!/usr/bin/env python3
"""
Tek ağlı bir GLB'yi model uzayındaki kutulara göre iki GLB'ye ayırır: kurala göre kutulardan birinin içindeki üçgen
«içeride», öteki «dışarıda» çıkar. Üçgenler kesilmez, kesit mevcut kenarları izler. Köşeler model uzayında kalır
(ortalanmaz): iki çıktı aynı dönüşümle üst üste konunca özgün model yeniden oluşur, parçanın gövdedeki yeri
koordinatlarının kendisidir. İki çıktı da özgün görseli ve malzemeyi taşır; kullanılmayan köşeler atılır.

Meshy görselden 3B modelleri tek ve kapalı bir ağdır: üstüne dikilen eşya (beşiğin kemerinden asılı yay ve sadak)
gövdeye iplerinden kaynamıştır. Kutu bu ipleri keser, --seed kutunun içindeki başka parçaları (kemerin kutuya giren
ucu) dışarıda bırakır: içeride yalnız tohum noktasına üçgen üçgen bağlı küme kalır.

Çıktıların dokusu özgün boydadır (8K): oyun kopyasını glb_prepare.py yazar (assets/_meshy_raw değişmez).

Kullanım:
  python3 tools/glb_split_region.py <girdi.glb> <içeride.glb> <dışarıda.glb> --box=x0,y0,z0,x1,y1,z1 [--box=...]
      [--rule=centroid|any] [--seed=x,y,z] [--report=<rapor.json>] [--silhouettes=<klasör>]

  --box          Kutu (model uzayı; alt köşe, üst köşe). Birden çok verilebilir, içeride kutuların birleşimidir.
  --rule         Üçgen ne zaman içeride sayılır: centroid (varsayılan) ağırlık merkezi kutudaysa; any bir köşesi bile
                 kutudaysa. Uzun ince üçgenli iplerde any dışarıda kalan gövdeye sivri uç bırakmaz: kesimi geçen üçgenler
                 içerideki parçaya gider (parçanın o ucu asılı yerinde gövdenin içinde kalır).
  --seed         Tohum nokta: içeride yalnız bu noktaya en yakın kutu içi üçgenle bitişik küme kalır. Bitişiklik
                 köşe konumlarıyla bakılır (UV dikişinde bölünen köşeler aynı sayılır).
  --report       Kesimin kaydı (JSON): kaynak, kutular, tohum, iki çıktının üçgen ve köşe sayısı, sınır kutusu, merkezi.
  --silhouettes  Doğrulama çizimleri: <içeride adı>_front.png, _side.png, <dışarıda adı>_front.png, _side.png ve iki
                 çıktının üst üste bindiği overlay_front.png, overlay_side.png (saf Python, PPM → PNG için ffmpeg).
                 Önden: +Z'den bakılır (X sağa). Yandan: +X'ten bakılır (Z sola). Bütün çizimler aynı çerçevededir.

Örnek (beşik; tools/asset_plan.json cradle_bow satırı):
  python3 tools/glb_split_region.py assets/_meshy_raw/cradle/cradle.glb bow.glb body.glb \\
      --box=-0.62,0.04,-0.47,0.50,0.668,0.47 --rule=any --seed=-0.12,0.37,0.0 --report=assets/props/cradle_bow/split.json
  python3 tools/glb_prepare.py body.glb assets/props/cradle/cradle.glb
  python3 tools/glb_prepare.py bow.glb assets/props/cradle_bow/cradle_bow.glb
"""
import copy
import json
import os
import struct
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from glb_prepare import read_glb, write_glb  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRIANGLES = 4
RULES = ("centroid", "any")
COMPONENT_FORMAT = {5120: "b", 5121: "B", 5122: "h", 5123: "H", 5125: "I", 5126: "f"}
TYPE_COMPONENTS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT2": 4, "MAT3": 9, "MAT4": 16}
IDENTITY_MATRIX = [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]
# Bitişiklik için köşe konumunun yuvarlanması (model birimi): UV dikişinde bölünen köşeler aynı noktadır.
WELD_DIGITS = 5
SILHOUETTE_SIZE = 800
SILHOUETTE_MARGIN = 0.02
# Çizimlerin görünümleri: yatay eksen, yatay işaret. Dikey her zaman Y.
VIEWS = {"front": (0, 1.0), "side": (2, -1.0)}
FOREGROUND = (40, 40, 40)
INSIDE_COLOR = (205, 60, 40)
OUTSIDE_COLOR = (150, 150, 150)
BOTH_COLOR = (90, 20, 110)


# --- GLB okuma ------------------------------------------------------------------------------------

def read_accessor(doc, binary, index):
    """Erişimcinin elemanları: düz liste (bileşen bileşen) ve eleman başına bileşen sayısı."""
    accessor = doc["accessors"][index]
    if "sparse" in accessor:
        sys.exit("Seyrek (sparse) erişimci desteklenmiyor")
    view = doc["bufferViews"][accessor["bufferView"]]
    fmt = COMPONENT_FORMAT[accessor["componentType"]]
    count = TYPE_COMPONENTS[accessor["type"]]
    size = struct.calcsize("<" + fmt)
    stride = view.get("byteStride") or size * count
    start = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    if stride == size * count:
        return list(struct.unpack_from("<%d%s" % (accessor["count"] * count, fmt), binary, start)), count
    out = []
    for i in range(accessor["count"]):
        out.extend(struct.unpack_from("<%d%s" % (count, fmt), binary, start + i * stride))
    return out, count


def check_supported(doc):
    """Yalnız durağan modeller ve birim dönüşümlü düğümler: köşeler doğrudan model uzayındadır."""
    if doc.get("skins") or doc.get("animations"):
        sys.exit("İskeletli ya da canlandırmalı GLB desteklenmiyor: bu araç durağan eşya içindir")
    for node in doc.get("nodes", []):
        if "mesh" not in node:
            continue
        if any(key in node for key in ("translation", "rotation", "scale")) or node.get("matrix", IDENTITY_MATRIX) != IDENTITY_MATRIX:
            sys.exit("Ağ düğümünün dönüşümü birim değil: köşeler model uzayında sayılamaz")


def load_primitives(doc, binary):
    """Ağın üçgen yüzeyleri: [{mesh, primitive, positions, triangles}]. Konumlar düz liste, üçgenler (a, b, c) listesi."""
    out = []
    for mesh_index, mesh in enumerate(doc.get("meshes", [])):
        for prim_index, prim in enumerate(mesh["primitives"]):
            if prim.get("mode", TRIANGLES) != TRIANGLES:
                sys.exit("Yalnız üçgen yüzeyler desteklenir")
            positions, _ = read_accessor(doc, binary, prim["attributes"]["POSITION"])
            if "indices" in prim:
                indices, _ = read_accessor(doc, binary, prim["indices"])
            else:
                indices = list(range(len(positions) // 3))
            triangles = [tuple(indices[i:i + 3]) for i in range(0, len(indices), 3)]
            out.append({"mesh": mesh_index, "primitive": prim_index, "positions": positions, "triangles": triangles})
    if not out:
        sys.exit("GLB'de ağ yok")
    return out


# --- Sınıflandırma ---------------------------------------------------------------------------------

def centroid(positions, triangle):
    a, b, c = triangle
    return ((positions[3 * a] + positions[3 * b] + positions[3 * c]) / 3.0,
            (positions[3 * a + 1] + positions[3 * b + 1] + positions[3 * c + 1]) / 3.0,
            (positions[3 * a + 2] + positions[3 * b + 2] + positions[3 * c + 2]) / 3.0)


def in_boxes(point, boxes):
    """Nokta kutulardan birinin içinde mi (kutu: (x0, y0, z0, x1, y1, z1))?"""
    x, y, z = point
    for box in boxes:
        if box[0] <= x <= box[3] and box[1] <= y <= box[4] and box[2] <= z <= box[5]:
            return True
    return False


def welded_ids(positions):
    """Köşe → konum kimliği: aynı noktadaki köşeler (UV dikişi) aynı kimliği alır."""
    seen = {}
    out = []
    for i in range(0, len(positions), 3):
        key = (round(positions[i], WELD_DIGITS), round(positions[i + 1], WELD_DIGITS), round(positions[i + 2], WELD_DIGITS))
        out.append(seen.setdefault(key, len(seen)))
    return out


def connected_groups(triangles, welded, members):
    """members'taki üçgenlerin bitişiklik kümeleri (ortak köşe konumu): {kök: [üçgen sırası]}."""
    parent = {}

    def find(x):
        parent.setdefault(x, x)
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for t in members:
        a, b, c = (welded[v] for v in triangles[t])
        for u, v in ((a, b), (b, c)):
            ru, rv = find(u), find(v)
            if ru != rv:
                parent[ru] = rv
    groups = {}
    for t in members:
        groups.setdefault(find(welded[triangles[t][0]]), []).append(t)
    return groups


def vertex(positions, index):
    return positions[3 * index], positions[3 * index + 1], positions[3 * index + 2]


def triangle_inside(positions, triangle, boxes, rule):
    """Üçgen kurala göre kutuların içinde mi?"""
    if rule == "any":
        return any(in_boxes(vertex(positions, v), boxes) for v in triangle)
    return in_boxes(centroid(positions, triangle), boxes)


def classify(prim, boxes, rule, seed):
    """Yüzeyin içerideki üçgenleri (küme). Tohum varsa yalnız ona en yakın kutu içi üçgenin bitişik kümesi."""
    positions = prim["positions"]
    triangles = prim["triangles"]
    centers = [centroid(positions, t) for t in triangles]
    members = [i for i, t in enumerate(triangles) if triangle_inside(positions, t, boxes, rule)]
    if seed is None or not members:
        return set(members)
    nearest = min(members, key=lambda i: sum((centers[i][k] - seed[k]) ** 2 for k in range(3)))
    for group in connected_groups(triangles, welded_ids(positions), members).values():
        if nearest in group:
            return set(group)
    return set()


def group_count(prim, selected):
    """Seçilen üçgenlerin kaç ayrı kümeye ayrıldığı (kesimin başıboş parça bırakıp bırakmadığı)."""
    return len(connected_groups(prim["triangles"], welded_ids(prim["positions"]), sorted(selected))) if selected else 0


# --- Parça yazma -----------------------------------------------------------------------------------

def view_bytes(doc, binary, view_index):
    view = doc["bufferViews"][view_index]
    start = view.get("byteOffset", 0)
    return binary[start: start + view["byteLength"]]


def build_part(doc, binary, primitives, selections):
    """Seçilen üçgenlerden yeni GLB (belge, bayt): köşeler sıkıştırılır, görseller ve malzemeler aynen taşınır."""
    part = copy.deepcopy(doc)
    data = bytearray()
    views = []
    accessors = []

    def add_view(blob, target=None):
        pad = (4 - len(data) % 4) % 4
        data.extend(b"\0" * pad)
        view = {"buffer": 0, "byteOffset": len(data), "byteLength": len(blob)}
        if target is not None:
            view["target"] = target
        data.extend(blob)
        views.append(view)
        return len(views) - 1

    def add_accessor(blob, source, count, values, target):
        accessor = {"bufferView": add_view(blob, target), "byteOffset": 0, "componentType": source["componentType"],
                    "count": count, "type": source["type"]}
        if source.get("normalized"):
            accessor["normalized"] = True
        if ("min" in source or "max" in source) and source["componentType"] == 5126:
            width = TYPE_COMPONENTS[source["type"]]
            accessor["min"] = [min(values[k::width]) for k in range(width)]
            accessor["max"] = [max(values[k::width]) for k in range(width)]
        accessors.append(accessor)
        return len(accessors) - 1

    for prim, selected in zip(primitives, selections):
        target = part["meshes"][prim["mesh"]]["primitives"][prim["primitive"]]
        kept = [prim["triangles"][i] for i in sorted(selected)]
        remap = {}
        indices = []
        for triangle in kept:
            for vertex in triangle:
                indices.append(remap.setdefault(vertex, len(remap)))
        order = sorted(remap, key=remap.get)
        for name, accessor_index in target["attributes"].items():
            source = doc["accessors"][accessor_index]
            values, width = read_accessor(doc, binary, accessor_index)
            picked = []
            for vertex in order:
                picked.extend(values[vertex * width: vertex * width + width])
            fmt = "<%d%s" % (len(picked), COMPONENT_FORMAT[source["componentType"]])
            target["attributes"][name] = add_accessor(struct.pack(fmt, *picked), source, len(order), picked, 34962)
        index_source = {"componentType": 5125, "type": "SCALAR"}
        target["indices"] = add_accessor(struct.pack("<%dI" % len(indices), *indices), index_source, len(indices), indices, 34963)
    for image in part.get("images", []):
        if "bufferView" in image:
            image["bufferView"] = add_view(view_bytes(doc, binary, image["bufferView"]))
    part["accessors"] = accessors
    part["bufferViews"] = views
    part["buffers"][0]["byteLength"] = len(data)
    return part, bytes(data)


def part_stats(primitives, selections):
    """Parçanın sayıları ve model uzayındaki sınır kutusu."""
    triangles = 0
    vertices = set()
    low = [float("inf")] * 3
    high = [float("-inf")] * 3
    groups = 0
    for prim, selected in zip(primitives, selections):
        positions = prim["positions"]
        triangles += len(selected)
        groups += group_count(prim, selected)
        for t in selected:
            for vertex in prim["triangles"][t]:
                if (prim["primitive"], vertex) in vertices:
                    continue
                vertices.add((prim["primitive"], vertex))
                for k in range(3):
                    value = positions[3 * vertex + k]
                    low[k] = min(low[k], value)
                    high[k] = max(high[k], value)
    center = [(low[k] + high[k]) * 0.5 for k in range(3)]
    return {"triangles": triangles, "vertices": len(vertices), "connected_groups": groups,
            "aabb_min": [round(v, 6) for v in low], "aabb_max": [round(v, 6) for v in high],
            "center": [round(v, 6) for v in center]}


# --- Siluet çizimi ----------------------------------------------------------------------------------

def rasterize(primitives, selections, view, frame):
    """Seçilen üçgenlerin dik izdüşüm maskesi (bytearray; piksel başına 0/1). frame: (u0, v0, ölçek, boy)."""
    axis, sign = VIEWS[view]
    u0, v0, scale, size = frame
    mask = bytearray(size * size)
    for prim, selected in zip(primitives, selections):
        positions = prim["positions"]
        for t in selected:
            a, b, c = prim["triangles"][t]
            ax = (sign * positions[3 * a + axis] - u0) * scale
            bx = (sign * positions[3 * b + axis] - u0) * scale
            cx = (sign * positions[3 * c + axis] - u0) * scale
            ay = (v0 - positions[3 * a + 1]) * scale
            by = (v0 - positions[3 * b + 1]) * scale
            cy = (v0 - positions[3 * c + 1]) * scale
            denominator = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
            if abs(denominator) < 1e-9:
                continue
            x_low = max(int(min(ax, bx, cx)), 0)
            x_high = min(int(max(ax, bx, cx)) + 1, size - 1)
            y_low = max(int(min(ay, by, cy)), 0)
            y_high = min(int(max(ay, by, cy)) + 1, size - 1)
            for y in range(y_low, y_high + 1):
                py = y + 0.5
                row = y * size
                for x in range(x_low, x_high + 1):
                    px = x + 0.5
                    l1 = ((by - cy) * (px - cx) + (cx - bx) * (py - cy)) / denominator
                    l2 = ((cy - ay) * (px - cx) + (ax - cx) * (py - cy)) / denominator
                    if l1 >= -0.001 and l2 >= -0.001 and l1 + l2 <= 1.001:
                        mask[row + x] = 1
    return mask


def write_png(path, pixels, size):
    """RGB baytlarını PPM olarak yazar, ffmpeg ile PNG'ye çevirir."""
    ppm = path + ".ppm"
    with open(ppm, "wb") as fh:
        fh.write(b"P6\n%d %d\n255\n" % (size, size))
        fh.write(pixels)
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", ppm, path], check=True)
    os.remove(ppm)


def view_frame(primitives, view, size):
    """Bütün modelin (iki çıktının birleşimi) bu görünümdeki çerçevesi: iki çizim de aynı yerde durur."""
    axis, sign = VIEWS[view]
    us = []
    vs = []
    for prim in primitives:
        us.extend(sign * value for value in prim["positions"][axis::3])
        vs.extend(prim["positions"][1::3])
    span = max(max(us) - min(us), max(vs) - min(vs)) * (1.0 + 2.0 * SILHOUETTE_MARGIN)
    scale = size / span
    u0 = (min(us) + max(us)) * 0.5 - span * 0.5
    v0 = (min(vs) + max(vs)) * 0.5 + span * 0.5
    return u0, v0, scale, size


def write_silhouettes(folder, inside_path, outside_path, primitives, inside, outside):
    """İki çıktının önden ve yandan siluetleri ve üst üste binmiş hâli. Yazılan yolları döndürür."""
    os.makedirs(folder, exist_ok=True)
    size = SILHOUETTE_SIZE
    written = []
    inside_name = os.path.splitext(os.path.basename(inside_path))[0]
    outside_name = os.path.splitext(os.path.basename(outside_path))[0]
    for view in VIEWS:
        frame = view_frame(primitives, view, size)
        mask_in = rasterize(primitives, inside, view, frame)
        mask_out = rasterize(primitives, outside, view, frame)
        for name, mask in ((inside_name, mask_in), (outside_name, mask_out)):
            pixels = bytearray(b"\xff\xff\xff" * (size * size))
            for i, covered in enumerate(mask):
                if covered:
                    pixels[3 * i: 3 * i + 3] = bytes(FOREGROUND)
            path = os.path.join(folder, "%s_%s.png" % (name, view))
            write_png(path, bytes(pixels), size)
            written.append(path)
        pixels = bytearray(b"\xff\xff\xff" * (size * size))
        for i in range(size * size):
            if mask_in[i] and mask_out[i]:
                pixels[3 * i: 3 * i + 3] = bytes(BOTH_COLOR)
            elif mask_in[i]:
                pixels[3 * i: 3 * i + 3] = bytes(INSIDE_COLOR)
            elif mask_out[i]:
                pixels[3 * i: 3 * i + 3] = bytes(OUTSIDE_COLOR)
        path = os.path.join(folder, "overlay_%s.png" % view)
        write_png(path, bytes(pixels), size)
        written.append(path)
    return written


# --- Giriş ------------------------------------------------------------------------------------------

def parse_numbers(text, count, option):
    try:
        values = [float(part) for part in text.split(",")]
    except ValueError:
        sys.exit("--%s sayı olmalı: %s" % (option, text))
    if len(values) != count:
        sys.exit("--%s %d sayı ister: %s" % (option, count, text))
    return values


def rel(path):
    """Proje içindeki yol projeye göre, dışındaki mutlak yazılır."""
    path = os.path.abspath(path)
    return os.path.relpath(path, ROOT) if path.startswith(ROOT + os.sep) else path


def main():
    argv = sys.argv[1:]
    args = [a for a in argv if not a.startswith("--")]
    boxes = []
    rule = "centroid"
    seed = None
    report = None
    silhouettes = None
    for option in (a[2:] for a in argv if a.startswith("--")):
        name, _, value = option.partition("=")
        if name == "box":
            box = parse_numbers(value, 6, "box")
            if not all(box[k] <= box[k + 3] for k in range(3)):
                sys.exit("--box alt köşe üst köşeden küçük olmalı: %s" % value)
            boxes.append(box)
        elif name == "rule":
            if value not in RULES:
                sys.exit("--rule %s'den biri olmalı: %s" % (", ".join(RULES), value))
            rule = value
        elif name == "seed":
            seed = parse_numbers(value, 3, "seed")
        elif name == "report":
            report = value
        elif name == "silhouettes":
            silhouettes = value
        else:
            sys.exit("Bilinmeyen seçenek: --%s\n\n%s" % (name, __doc__))
    if len(args) != 3 or not boxes:
        sys.exit(__doc__)
    source, inside_path, outside_path = args
    doc, binary = read_glb(source)
    check_supported(doc)
    primitives = load_primitives(doc, binary)
    inside = [classify(prim, boxes, rule, seed) for prim in primitives]
    outside = [set(range(len(prim["triangles"]))) - selected for prim, selected in zip(primitives, inside)]
    if not all(inside) or not all(outside):
        sys.exit("Kesim bir yüzeyi boş bıraktı: kutuları ve tohumu denetleyin")
    stats = {}
    for label, path, selections in (("inside", inside_path, inside), ("outside", outside_path, outside)):
        part, data = build_part(doc, binary, primitives, selections)
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
        write_glb(path, part, data)
        stats[label] = part_stats(primitives, selections)
        print("  %s: %d üçgen, %d köşe, %d küme, %.1f MB, sınır %s → %s" % (rel(path), stats[label]["triangles"],
              stats[label]["vertices"], stats[label]["connected_groups"], os.path.getsize(path) / 1e6,
              stats[label]["aabb_min"], stats[label]["aabb_max"]))
    if report:
        record = {"source": rel(source), "boxes": boxes, "rule": rule, "seed": seed,
                  "inside": stats["inside"], "outside": stats["outside"]}
        os.makedirs(os.path.dirname(os.path.abspath(report)), exist_ok=True)
        with open(report, "w", encoding="utf-8") as fh:
            json.dump(record, fh, ensure_ascii=False, indent=1)
            fh.write("\n")
        print("  kayıt: %s" % rel(report))
    if silhouettes:
        for path in write_silhouettes(silhouettes, inside_path, outside_path, primitives, inside, outside):
            print("  çizim: %s" % path)


if __name__ == "__main__":
    main()
