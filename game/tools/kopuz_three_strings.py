#!/usr/bin/env python3
"""
Kopuzun Meshy ağında dört tel izi vardır, K60 ve konsept üç tel ister. Bu araç ham ağdan üç telli oyun kopyasını kredisiz çıkarır;
Meshy'yi çağırmaz, ham dosya (assets/_meshy_raw/kopuz/kopuz.glb) değişmez.

Ağ tek parçadır ama teller tahtanın ≈4 cm (model birimi) üstünde boşlukta durur, eşiğe, kuyruğa ve burgulara değer: tel çıkınca altında
tahta bütündür, delik açılmaz. Dört tel ölçüldü (model uzayında; dıştan içe A, B, C, D): A ve D iki dıştadır, tamdır ve yerinde kalır. İç
iki telin ikisi de yer yer kopuktur: B altta sağlam, üstte (y ≈ −0,06…0,02) kopuk; C üstte sağlam, altta (y ≈ −0,42…−0,26) kopuk. Bu yüzden
orta tel ikisinden kurulur:
  - C'nin alt parçası ve B'nin üst parçası çıkar;
  - B'nin altı ve C'nin üstü ortaya (x = 0) taşınır, düğüme ve burguya yaklaşınca yerine döner.
Kuyruğun dört düğümü kalır: süstür, yalnız en yakından sayılır, çıkarılınca kuyrukta iz bırakır.
Kesimin açtığı küçük ağızlar yelpazeyle kapatılır (tek yüzlü malzemede delik görünmesin), kopan başıboş parçalar atılır. Köşe, UV ve
normal dışında bir şey değişmez; boy ve sınır kutusu aynı kalır.

Üçgen kesilmez, kesit mevcut kenarları izler. Kayıt assets/props/kopuz/strings.json.

Kullanım (game/ klasöründe):
  python3 tools/kopuz_three_strings.py            # oyun kopyasını yazar (glb_prepare ile); sonra source tools/_godot_lock.sh; godot_import_locked
  python3 tools/kopuz_three_strings.py --out=<ham_cikti.glb> [--no-prepare]    # yalnız 8K dokulu ara çıktı
"""
import copy
import json
import os
import struct
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from glb_prepare import read_glb, write_glb  # noqa: E402
from glb_split_region import build_part, classify, load_primitives, read_accessor, welded_ids  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "assets", "_meshy_raw", "kopuz", "kopuz.glb")
GAME = os.path.join(ROOT, "assets", "props", "kopuz", "kopuz.glb")
RECORD = os.path.join(ROOT, "assets", "props", "kopuz", "strings.json")

# Tellerin katmanı: tahtanın üstü (model uzayı, z).
STRING_Z = 0.056
Z_TOP = 0.115
# Alt bölgede teller birbirinden uzaktır, kutularla seçilir: C'nin altı eşiğin iki yanında (kutu: x0, y0, z0, x1, y1, z1). Kuyruktaki dört
# düğüm kalır: kuyruğun süsüdür, ağı bozmadan çıkmaz.
C_LOWER = [(0.0035, -0.852, STRING_Z, 0.0255, -0.7005, Z_TOP), (0.0035, -0.6745, STRING_Z, 0.0255, -0.30, Z_TOP)]
# Eşiğin üstünde telin eşiği aşan uzun üçgenleri de çıkar (eşiğin kendi üçgenleri bu boydan kısadır).
BRIDGE = (0.0035, -0.7005, STRING_Z, 0.0255, -0.6745, Z_TOP)
BRIDGE_SPAN = 0.022
# Üstte teller yan yanadır, boruları bağlantıyla seçilir: kutu ve tohum (sap boyunca dış tel ile iç tel birbirine değmez).
UPPER_RIGHT = (-0.002, -0.30, STRING_Z, 0.045, 0.70, Z_TOP)
UPPER_LEFT = (-0.045, -0.30, STRING_Z, 0.002, 0.70, Z_TOP)
C_UPPER_SEED = (0.0112, 0.07, 0.082)
B_UPPER_SEED = (-0.011, 0.10, 0.08)
# İç tellerin orta çizgisi: (y, x) (ölçüldü; aradakiler doğrusal).
LINE_B = [(-0.925, -0.018), (-0.86, -0.014), (-0.62, -0.0145), (-0.38, -0.0135), (-0.26, -0.0125), (-0.05, -0.012)]
LINE_C = [(-0.26, 0.0156), (-0.05, 0.0125), (0.07, 0.0112), (0.31, 0.0107), (0.55, 0.0092), (0.72, 0.0078)]
# B'nin altı ortaya taşınırken seçilen köşeler: orta çizgiye uzaklık. Düğüme ve burguya yaklaşınca taşıma söner: telin ucu yerinde kalır.
B_MOVE = (-0.925, -0.05)
B_HALF = 0.0058
KNOT_FADE_FROM, KNOT_FADE_TO = -0.87, -0.72
FADE_FROM, FADE_TO = 0.60, 0.72
# Kesimden kopan bu kadar küçük küme atılır.
LOOSE_TRIANGLES = 32


def line_x(line, y):
	"""Orta çizginin y'deki x'i (doğrusal; uçlarda sabit)."""
	if y <= line[0][0]:
		return line[0][1]
	for (y0, x0), (y1, x1) in zip(line, line[1:]):
		if y <= y1:
			return x0 + (x1 - x0) * (y - y0) / (y1 - y0)
	return line[-1][1]


def smoothstep(a, b, t):
	u = max(0.0, min(1.0, (t - a) / (b - a)))
	return u * u * (3.0 - 2.0 * u)


def removed_triangles(prim):
	"""Çıkan üçgenler: C'nin altı, B'nin üst borusu."""
	out = set(classify(prim, C_LOWER, "centroid", None))
	out.update(classify(prim, [UPPER_LEFT], "centroid", B_UPPER_SEED))
	positions = prim["positions"]
	for t in classify(prim, [BRIDGE], "centroid", None):
		heights = [positions[3 * v + 1] for v in prim["triangles"][t]]
		if max(heights) - min(heights) > BRIDGE_SPAN:
			out.add(t)
	return out


def loose_groups(triangles, welded, kept):
	"""Kalan üçgenlerin kümeleri içinde küçük olanlar (kesimden kopan başıboş parçalar)."""
	parent = {}

	def find(x):
		parent.setdefault(x, x)
		while parent[x] != x:
			parent[x] = parent[parent[x]]
			x = parent[x]
		return x

	for t in kept:
		a, b, c = (welded[v] for v in triangles[t])
		parent[find(a)] = find(b)
		parent[find(c)] = find(b)
	groups = {}
	for t in kept:
		groups.setdefault(find(welded[triangles[t][0]]), []).append(t)
	out = set()
	for members in groups.values():
		if len(members) <= LOOSE_TRIANGLES:
			out.update(members)
	return out


def open_edges(triangles, welded, members):
	"""Tek üçgene ait yönlü kenarlar: (kaynaşık a, kaynaşık b) → (köşe a, köşe b)."""
	seen = {}
	for t in members:
		tri = triangles[t]
		for i in range(3):
			a, b = tri[i], tri[(i + 1) % 3]
			key = (min(welded[a], welded[b]), max(welded[a], welded[b]))
			seen.setdefault(key, []).append((a, b))
	return {key: rows[0] for key, rows in seen.items() if len(rows) == 1}


def caps(positions, new_edges, welded, attributes):
	"""Yeni açılan ağızlar yelpazeyle kapanır: ağız başına bir merkez köşesi (konumu ortalama, normali ortalama, UV'si merkeze en yakın
	köşenin UV'si). Attributes'a köşe ekler, üçgenleri döner."""
	parent = {}

	def find(x):
		parent.setdefault(x, x)
		while parent[x] != x:
			parent[x] = parent[parent[x]]
			x = parent[x]
		return x

	for a, b in new_edges:
		parent[find(a)] = find(b)
	loops = {}
	for key, verts in new_edges.items():
		loops.setdefault(find(key[0]), []).append(verts)
	triangles = []
	for edges in loops.values():
		corners = sorted({v for pair in edges for v in pair})
		center = [sum(positions[3 * v + k] for v in corners) / len(corners) for k in range(3)]
		nearest = min(corners, key=lambda v: sum((positions[3 * v + k] - center[k]) ** 2 for k in range(3)))
		index = len(positions) // 3
		positions.extend(center)
		for name, (values, width) in attributes.items():
			if name == "POSITION":
				continue
			if name == "NORMAL":
				normal = [sum(values[3 * v + k] for v in corners) for k in range(3)]
				length = max(sum(c * c for c in normal) ** 0.5, 1e-9)
				values.extend(c / length for c in normal)
			else:
				values.extend(values[nearest * width: nearest * width + width])
		# Kalan üçgende a → b ise kapakta b → a: yön ağla tutarlı.
		for a, b in edges:
			triangles.append((b, a, index))
	return triangles, len(loops)


def center_strings(positions, triangles, welded, c_upper):
	"""Orta telin iki parçası ortaya taşınır: B'nin altı (orta çizgiye yakın köşeler), C'nin üst borusu (bağlantıyla seçilen köşeler, aynı
	noktadaki UV dikişi köşeleriyle). Döner: taşınan köşe sayısı."""
	tube = {welded[v] for t in c_upper for v in triangles[t]}
	moved = 0
	for v in range(len(welded)):
		x, y, z = positions[3 * v], positions[3 * v + 1], positions[3 * v + 2]
		if welded[v] in tube:
			positions[3 * v] = x - line_x(LINE_C, y) * (1.0 - smoothstep(FADE_FROM, FADE_TO, y))
			moved += 1
		elif z >= STRING_Z and B_MOVE[0] <= y <= B_MOVE[1]:
			center = line_x(LINE_B, y)
			if abs(x - center) < B_HALF:
				positions[3 * v] = x - center * smoothstep(KNOT_FADE_FROM, KNOT_FADE_TO, y)
				moved += 1
	return moved


def pack_attribute(doc, data, source, values):
	"""Yeni görünüm ve erişimci (ikili verinin sonuna): build_part bunları okur, köşeleri sıkıştırır."""
	fmt = {5126: "f", 5125: "I", 5123: "H", 5121: "B"}[source["componentType"]]
	blob = struct.pack("<%d%s" % (len(values), fmt), *values)
	pad = (4 - len(data) % 4) % 4
	data.extend(b"\0" * pad)
	doc["bufferViews"].append({"buffer": 0, "byteOffset": len(data), "byteLength": len(blob)})
	data.extend(blob)
	accessor = {"bufferView": len(doc["bufferViews"]) - 1, "byteOffset": 0, "componentType": source["componentType"], "type": source["type"]}
	width = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[source["type"]]
	accessor["count"] = len(values) // width
	if source.get("normalized"):
		accessor["normalized"] = True
	if "min" in source or "max" in source:
		accessor["min"] = source.get("min", [])
		accessor["max"] = source.get("max", [])
	doc["accessors"].append(accessor)
	return len(doc["accessors"]) - 1


def build(raw_path):
	"""Ham ağdan üç telli ağ: (belge, ikili veri, kayıt)."""
	doc, binary = read_glb(raw_path)
	primitives = load_primitives(doc, binary)
	if len(primitives) != 1:
		sys.exit("Tek yüzeyli ağ bekleniyor")
	prim = primitives[0]
	positions = prim["positions"] = list(prim["positions"])
	triangles = prim["triangles"]
	target = doc["meshes"][prim["mesh"]]["primitives"][prim["primitive"]]
	attributes = {}
	for name, index in target["attributes"].items():
		values, width = read_accessor(doc, binary, index)
		attributes[name] = (list(values), width)
	attributes["POSITION"] = (positions, 3)
	welded = welded_ids(positions)
	removed = removed_triangles(prim)
	c_upper = classify(prim, [UPPER_RIGHT], "centroid", C_UPPER_SEED)
	kept = [t for t in range(len(triangles)) if t not in removed]
	loose = loose_groups(triangles, welded, kept)
	kept = [t for t in kept if t not in loose]
	before = open_edges(triangles, welded, range(len(triangles)))
	after = open_edges(triangles, welded, kept)
	new_edges = {key: verts for key, verts in after.items() if key not in before}
	moved = center_strings(positions, triangles, welded, c_upper)
	cap_triangles, cap_count = caps(positions, new_edges, welded, attributes)
	all_triangles = [triangles[t] for t in kept] + cap_triangles
	new_doc = copy.deepcopy(doc)
	data = bytearray(binary)
	new_target = new_doc["meshes"][prim["mesh"]]["primitives"][prim["primitive"]]
	for name, (values, _) in attributes.items():
		source = doc["accessors"][target["attributes"][name]]
		new_target["attributes"][name] = pack_attribute(new_doc, data, source, values)
	indices = [v for tri in all_triangles for v in tri]
	new_target["indices"] = pack_attribute(new_doc, data, {"componentType": 5125, "type": "SCALAR"}, indices)
	new_doc["buffers"][0]["byteLength"] = len(data)
	final_prim = load_primitives(new_doc, bytes(data))[0]
	selection = set(range(len(all_triangles)))
	part, part_data = build_part(new_doc, bytes(data), [final_prim], [selection])
	record = {
		"source": os.path.relpath(raw_path, ROOT),
		"note": "K60 üç tel ister, ağda dört tel izi vardı: C'nin altı ile B'nin üstü çıktı, B'nin altı ve C'nin üstü ortaya taşındı; kuyruğun dört düğümü kaldı.",
		"triangles_before": len(triangles),
		"triangles_removed": len(removed),
		"triangles_loose": len(loose),
		"triangles_caps": len(cap_triangles),
		"openings_capped": cap_count,
		"vertices_moved": moved,
		"triangles_after": len(all_triangles),
	}
	return part, part_data, record


def main():
	out = None
	prepare = True
	for arg in sys.argv[1:]:
		if arg.startswith("--out="):
			out = arg[len("--out="):]
		elif arg == "--no-prepare":
			prepare = False
		else:
			sys.exit(__doc__)
	part, data, record = build(RAW)
	# Ara çıktı oyunun klasörüne yazılmaz: Godot içe aktarmaya kalkmasın.
	with tempfile.TemporaryDirectory() as folder:
		temp = out or os.path.join(folder, "kopuz.glb")
		write_glb(temp, part, data)
		print("  %d → %d üçgen (%d çıktı, %d başıboş, %d kapak), %d köşe taşındı" % (record["triangles_before"], record["triangles_after"],
				record["triangles_removed"], record["triangles_loose"], record["triangles_caps"], record["vertices_moved"]))
		if prepare:
			subprocess.run([sys.executable, os.path.join(ROOT, "tools", "glb_prepare.py"), temp, GAME], check=True)
			with open(RECORD, "w", encoding="utf-8") as fh:
				json.dump(record, fh, ensure_ascii=False, indent=1)
				fh.write("\n")


if __name__ == "__main__":
	main()
