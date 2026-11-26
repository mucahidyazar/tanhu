class_name NodeStore
extends RefCounted
## Toplama düğümlerinin kaydı (saf; economy.md §3.2, §3.5, §11.1; godot.md §3 «Toplama», §4.5): dünyanın bütün düğümleri tipli dizilerde
## (24 B/düğüm), 100 m'lik parça dizini, hak ve tükenme, iki evreli düğüm (dal kır, sonra kes), ikinci eylem (ağ), vuruş ilerlemesi
## (şafağa dek düğümde), sıralı verim, şafak, yerleşimin uzaktan alımı (applyTaken) ve kayıt. Prototipin world/node-store.js'inin
## Godot'su; yerleşim, sıra ve kayıt biçimi bit bit aynıdır (tests/fixtures/gathering.json). Yer yığınları burada değildir: sığmayan verim
## Inventory.receive'in yer yığınına düşer (Inventory'nin yığınları, GroundPile görünüşü).
##
## Tür tablosu data/economy/node_kinds.json'dadır; tür sırası kimliktir (tür Uint8 tutulur, yerleşim tohumu 7000 + sıra). Bayraklar:
## PERM kalıcı (kayda geçer), DEPLETED bugün hakkı yok, STAGE ikinci evre açık, STRUCK yıldırım düşmüş ağaç.
##   var store := NodeStore.new(NodeStore.placement("hexi_winter"))     # 3.270 kayıt (economy.md §3.5)
##   store.consume(i)                         # → kalan hak; son evre bitince bugün tükenmiş (dawn) ya da kalıcı (perm, none)
##   store.on_dawn(day)                       # yenilenenler döner, kalıcı bit kalır, vuruş ilerlemesi silinir
##   store.query(x0, z0, x1, z1, out)         # kutudaki düğümler (parça dizininden, ayırmasız)
##   store.to_dict() / store.from_dict(d)     # {perm: base64, part, day, seq, struck}

const DATA_PATH := "res://data/economy/node_kinds.json"

const F_PERM := 1
const F_DEPLETED := 2
const F_STAGE := 4
const F_STRUCK := 8

## Parça boyu (m; navmesh karosuyla aynı, §11.1), ağaçlar arası en az (§3.5), ret denemesi (sonuncusu yine yazılır: kayıt sayısı kesin
## kalır), gürültü eşiği (fbm2(x·0,03 + k, z·0,03 − k, 2) bunun altındaysa ret), applyTaken sırasının tohumlu sapması (m).
const CHUNK := 100.0
const TREE_GAP := 3.0
const TRIES := 12
const NOISE_CUT := -0.05
const ORDER_JITTER := 6.0
const MASK := 0xFFFFFFFF
const TWO32 := 4294967296.0
const B64 := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

static var _data: Dictionary = {}
static var _perm := PackedInt32Array()

## Tür tablosu (kimlik → satır), sırası ve sıranın dizini; satırlar (sırayla).
var kinds: Dictionary = {}
var kind_ids := PackedStringArray()
var kind_index: Dictionary = {}
var rows: Array = []
var seed := 0
## Zemin yüksekliği: (x, z) -> float. Ret: (x, z, tür) -> bool (yol, ocak, yapı ayak izi; dünya verir).
var height_at: Callable
## Her değişimde artar (görünüş ve sıcak liste yeniden okur).
var version := 0
var count := 0

var x := PackedFloat32Array()
var z := PackedFloat32Array()
var y := PackedFloat32Array()
var yaw := PackedFloat32Array()
var scale := PackedFloat32Array()
var kind := PackedByteArray()
var charges := PackedByteArray()
var flags := PackedByteArray()
var tone := PackedByteArray()

## Seyrek gün durumu: vuruş ilerlemesi (şafağa dek), sıralı verim konumu (kalıcı), ikinci eylemin hakkı (şafağa dek), bugün dokunulanlar
## (kaydın day listesi), bugün tüketilen hak (aşırmanın sessiz hakkı).
var hits: Dictionary = {}
var seq: Dictionary = {}
var alt: Dictionary = {}
var touched: Dictionary = {}
var day_count: Dictionary = {}
## Küme kimliği → [[ilk, son), …] ve applyTaken sırası (küme başına bir kez).
var clusters: Dictionary = {}
var _orders: Dictionary = {}

## Parça dizini: kutu başı, genişlik, yükseklik; parça başına başlangıç (sayma sıralaması) ve sıra.
var cx0 := 0.0
var cz0 := 0.0
var cw := 1
var ch := 1
var chunk_start := PackedInt32Array()
var order := PackedInt32Array()


## spec: [{id?, kind, at: [x, z], r?, n?}] (economy.md §3.5). opts: seed, height_at (Callable), reject (Callable), kinds (sınama tablosu:
## {id: satır}; sırası sözlüğün sırasıdır).
func _init(spec: Array = [], opts: Dictionary = {}) -> void:
	var table: Variant = opts.get("kinds")
	if table is Dictionary and not (table as Dictionary).is_empty():
		kinds = table
		kind_ids = PackedStringArray((table as Dictionary).keys())
	else:
		kinds = NodeStore.kind_table()
		kind_ids = NodeStore.ids()
	for k in kind_ids.size():
		kind_index[kind_ids[k]] = k
		rows.append(kinds[kind_ids[k]])
	seed = int(opts.get("seed", 0))
	height_at = opts.get("height_at", Callable())
	var n := 0
	for e: Variant in spec:
		if e is Dictionary and kind_index.has(str((e as Dictionary).get("kind", ""))):
			n += maxi(0, floori(float((e as Dictionary).get("n", 1))))
	count = n
	# Packed diziler değerle taşınır: her biri kendi alanında büyütülür.
	x.resize(n)
	z.resize(n)
	y.resize(n)
	yaw.resize(n)
	scale.resize(n)
	kind.resize(n)
	charges.resize(n)
	flags.resize(n)
	tone.resize(n)
	_build(spec, opts.get("reject", Callable()))
	_index()


# --- Veri -------------------------------------------------------------------------------------------------------------

## data/economy/node_kinds.json (bir kez okunur).
static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if FileAccess.file_exists(DATA_PATH) else null
		_data = parsed if parsed is Dictionary else {}
	return _data


static func reset_cache() -> void:
	_data = {}


static func kind_table() -> Dictionary:
	return data().get("kinds", {})


## Tür sırası (kimlik).
static func ids() -> PackedStringArray:
	return PackedStringArray(kind_table().keys())


static func kind_row(kind_id: String) -> Dictionary:
	return kind_table().get(kind_id, {})


## Araç satırı (cls, tier, T0, gesture, fixed); bilinmeyen boş.
static func tool_row(tool_id: String) -> Dictionary:
	return (data().get("tools", {}) as Dictionary).get(tool_id, {})


## Toplamanın sabitleri (gather: contactK, window, staCost …).
static func constants() -> Dictionary:
	return data().get("gather", {})


## Yerleşim (economy.md §3.5): "hexi_winter" (I. Perde, 3.270 kayıt), "tanhu_camp" (ana kampın kütüğü).
static func placement(zone: String) -> Array:
	return (data().get("placements", {}) as Dictionary).get(zone, [])


## Oyuncu metni (messages; dil "tr" ya da "en"), {anahtar} yerine konur.
static func message(key: String, lang := "tr", args := {}) -> String:
	var m: Variant = (data().get("messages", {}) as Dictionary).get(key)
	var text := Catalog.pick(m, lang) if m != null else key
	for k: String in args:
		text = text.replace("{%s}" % k, str(args[k]))
	return text


# --- Kurulum -----------------------------------------------------------------------------------------------------------

func _build(spec: Array, reject: Callable) -> void:
	var streams := {}
	var trees := {}
	var i := 0
	for e: Variant in spec:
		if not e is Dictionary:
			continue
		var d: Dictionary = e
		var kind_id := str(d.get("kind", ""))
		if not kind_index.has(kind_id):
			continue
		var k: int = kind_index[kind_id]
		var row: Dictionary = rows[k]
		var r: WeatherRng = streams.get(k)
		if r == null:
			r = WeatherRng.new((WeatherRng.imul(seed, 0x9e3779b1) + 7000 + k) & MASK)
			streams[k] = r
		var n := maxi(0, floori(float(d.get("n", 1))))
		var at: Array = d.get("at", [0.0, 0.0])
		var cx := float(at[0]) if at.size() > 0 else 0.0
		var cz := float(at[1]) if at.size() > 1 else 0.0
		var big_r := float(d.get("r", 0.0))
		var start := i
		var tree := bool(row.get("tree", false))
		for j in n:
			var px := cx
			var pz := cz
			if big_r > 0.0:
				for t in TRIES:
					var a := r.next() * TAU
					var dist := big_r * sqrt(r.next())
					px = cx + cos(a) * dist
					pz = cz + sin(a) * dist
					if NodeStore.fbm2(px * 0.03 + k, pz * 0.03 - k, 2) < NOISE_CUT:
						continue
					if reject.is_valid() and bool(reject.call(px, pz, kind_id)):
						continue
					if tree and _near(trees, px, pz):
						continue
					break
			x[i] = px
			z[i] = pz
			y[i] = float(height_at.call(px, pz)) if height_at.is_valid() else 0.0
			yaw[i] = r.next() * TAU
			scale[i] = lerpf(0.85, 1.15, r.next())
			tone[i] = floori(r.next() * 256.0)
			kind[i] = k
			charges[i] = int(row.get("charges", 1))
			if tree:
				_keep(trees, i)
			i += 1
		var cid := str(d.get("id", "")) if str(d.get("id", "")) != "" else "%s@%s,%s" % [kind_id, NodeStore._js_num(cx), NodeStore._js_num(cz)]
		var ranges: Array = clusters.get(cid, [])
		ranges.append([start, i])
		clusters[cid] = ranges


static func _cell_key(ix: int, iz: int) -> int:
	return ix * 100003 + iz


func _near(trees: Dictionary, px: float, pz: float) -> bool:
	var ix := floori(px / TREE_GAP)
	var iz := floori(pz / TREE_GAP)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var cell: Variant = trees.get(NodeStore._cell_key(ix + dx, iz + dz))
			if cell == null:
				continue
			for j: int in cell:
				var ddx := float(x[j]) - px
				var ddz := float(z[j]) - pz
				if sqrt(ddx * ddx + ddz * ddz) < TREE_GAP:
					return true
	return false


func _keep(trees: Dictionary, i: int) -> void:
	var key := NodeStore._cell_key(floori(x[i] / TREE_GAP), floori(z[i] / TREE_GAP))
	if trees.has(key):
		(trees[key] as Array).append(i)
	else:
		trees[key] = [i]


## 100 m'lik parçalar: sayma sıralaması (chunk_start, order).
func _index() -> void:
	var n := count
	var x0 := INF
	var z0 := INF
	var x1 := -INF
	var z1 := -INF
	for i in n:
		x0 = minf(x0, x[i])
		x1 = maxf(x1, x[i])
		z0 = minf(z0, z[i])
		z1 = maxf(z1, z[i])
	if n == 0:
		x0 = 0.0
		z0 = 0.0
		x1 = 0.0
		z1 = 0.0
	cx0 = floorf(x0 / CHUNK) * CHUNK
	cz0 = floorf(z0 / CHUNK) * CHUNK
	cw = maxi(1, floori((x1 - cx0) / CHUNK) + 1)
	ch = maxi(1, floori((z1 - cz0) / CHUNK) + 1)
	var cells := cw * ch
	chunk_start = PackedInt32Array()
	chunk_start.resize(cells + 1)
	order = PackedInt32Array()
	order.resize(n)
	var cell_of := PackedInt32Array()
	cell_of.resize(n)
	for i in n:
		var c := _cell_of(x[i], z[i])
		cell_of[i] = c
		chunk_start[c + 1] += 1
	for c in cells:
		chunk_start[c + 1] += chunk_start[c]
	var fill := chunk_start.slice(0, cells)
	for i in n:
		order[fill[cell_of[i]]] = i
		fill[cell_of[i]] += 1


func _cell_of(px: float, pz: float) -> int:
	var i := clampi(floori((px - cx0) / CHUNK), 0, cw - 1)
	var j := clampi(floori((pz - cz0) / CHUNK), 0, ch - 1)
	return j * cw + i


# --- Okuma -------------------------------------------------------------------------------------------------------------

func kind_of(i: int) -> String:
	return kind_ids[kind[i]] if i >= 0 and i < count else ""


func row_of(i: int) -> Dictionary:
	return rows[kind[i]] if i >= 0 and i < count else {}


func stage(i: int) -> int:
	return 1 if (flags[i] & F_STAGE) != 0 else 0


## Şu anki evrenin satırı (ilk evre ya da then).
func stage_of(i: int) -> Dictionary:
	var row := row_of(i)
	return NodeStore._stage_row(row, stage(i)) if not row.is_empty() else {}


static func _stage_row(row: Dictionary, s: int) -> Dictionary:
	if s == 0 or not row.get("then") is Dictionary:
		return row
	return row["then"]


## Bugün işlenebilir mi (kalıcı ya da bugün tükenmiş değil)?
func available(i: int) -> bool:
	if i < 0 or i >= count:
		return false
	return (flags[i] & (F_PERM | F_DEPLETED)) == 0


func hits_of(i: int) -> int:
	return int(hits.get(i, 0))


func position_of(i: int) -> Vector3:
	return Vector3(x[i], y[i], z[i]) if i >= 0 and i < count else Vector3.ZERO


## (x0, z0)–(x1, z1) kutusundaki düğümler (out'a eklenir; çağıran temizler). Döner: out.
func query(x0: float, z0: float, x1: float, z1: float, out: PackedInt32Array = PackedInt32Array()) -> PackedInt32Array:
	if count == 0:
		return out
	var i0 := maxi(0, floori((x0 - cx0) / CHUNK))
	var i1 := mini(cw - 1, floori((x1 - cx0) / CHUNK))
	var j0 := maxi(0, floori((z0 - cz0) / CHUNK))
	var j1 := mini(ch - 1, floori((z1 - cz0) / CHUNK))
	for j in range(j0, j1 + 1):
		for ci in range(i0, i1 + 1):
			var c := j * cw + ci
			for k in range(chunk_start[c], chunk_start[c + 1]):
				var i := order[k]
				if x[i] >= x0 and x[i] <= x1 and z[i] >= z0 and z[i] <= z1:
					out.append(i)
	return out


## (px, pz)'ye en yakın işlenebilir düğüm (yarıçap içinde; boy payı türün r'sidir: kenarına uzaklık). filter: (i) -> bool. Yoksa -1.
func nearest(px: float, pz: float, reach: float, filter := Callable()) -> int:
	var best := -1
	var best_d := INF
	var found := query(px - reach - 2.0, pz - reach - 2.0, px + reach + 2.0, pz + reach + 2.0)
	for i in found:
		if not available(i):
			continue
		var dx := float(x[i]) - px
		var dz := float(z[i]) - pz
		var d := sqrt(dx * dx + dz * dz) - maxf(0.0, float(rows[kind[i]].get("r", 0.4)) - 0.5)
		if d > reach or d >= best_d:
			continue
		if filter.is_valid() and not bool(filter.call(i)):
			continue
		best = i
		best_d = d
	return best


# --- Değişim -----------------------------------------------------------------------------------------------------------

## n hak tüketir → şu an kalan hak. İlk evre bitince ikinci evre açılır (kalan onun hakkıdır); son evre bitince bugün tükenmiş (dawn) ya
## da kalıcı (perm, none) olur.
func consume(i: int, n := 1) -> int:
	if not available(i):
		return 0
	var row: Dictionary = rows[kind[i]]
	var s := stage(i)
	var st := NodeStore._stage_row(row, s)
	version += 1
	touched[i] = true
	day_count[i] = int(day_count.get(i, 0)) + n
	var left := int(charges[i]) - n
	if left > 0:
		charges[i] = left
		return left
	charges[i] = 0
	hits.erase(i)
	if s == 0 and row.get("then") is Dictionary:
		flags[i] |= F_STAGE
		charges[i] = int((row["then"] as Dictionary).get("charges", 1))
		return charges[i]
	flags[i] |= F_DEPLETED if NodeStore._renews(st) else (F_PERM | F_DEPLETED)
	return 0


static func _renews(row: Dictionary) -> bool:
	return str(row.get("renew", "dawn")) == "dawn"


## İkinci eylemin (alt) bugün kalan hakkı.
func alt_left(i: int) -> int:
	var row := row_of(i)
	if not row.get("alt") is Dictionary:
		return 0
	return int(alt[i]) if alt.has(i) else int((row["alt"] as Dictionary).get("charges", 1))


func consume_alt(i: int, n := 1) -> int:
	var left := maxi(0, alt_left(i) - n)
	alt[i] = left
	touched[i] = true
	version += 1
	return left


## Vuruş ilerlemesi şafağa dek düğümde kalır (§3.1).
func add_hit(i: int) -> int:
	var h := int(hits.get(i, 0)) + 1
	hits[i] = h
	touched[i] = true
	return h


func clear_hits(i: int) -> void:
	hits.erase(i)


## Sıralı verimin konumu (mutfak artığı, balık): kalıcıdır, şafakta sıfırlanmaz.
func next_seq(i: int) -> int:
	var n := int(seq.get(i, 0))
	seq[i] = n + 1
	return n


## Stoğa ekler (kampın ikizi sabah +4); türün hakkını aşmaz. Kalıcı düğüm geri gelmez.
func restock(i: int, n: int) -> int:
	if i < 0 or i >= count or (flags[i] & F_PERM) != 0 or n <= 0:
		return int(charges[i]) if i >= 0 and i < count else 0
	var full := int(stage_of(i).get("charges", 1))
	charges[i] = mini(full, int(charges[i]) + n)
	if charges[i] > 0:
		flags[i] &= ~F_DEPLETED
	touched[i] = true
	version += 1
	return charges[i]


## Hikâye yazımı (Gün III sabahı Odunluk stoğu 0, a1): 0 hakkı türün kuralıyla tüketir.
func set_charges(i: int, n: int) -> void:
	if i < 0 or i >= count:
		return
	if n <= 0:
		if available(i):
			consume(i, charges[i])
		return
	charges[i] = mini(255, n)
	flags[i] &= ~(F_DEPLETED | F_PERM)
	touched[i] = true
	version += 1


func mark_struck(i: int) -> bool:
	if i < 0 or i >= count or not bool(rows[kind[i]].get("tree", false)):
		return false
	flags[i] |= F_STRUCK
	version += 1
	return true


# --- Şafak ---------------------------------------------------------------------------------------------------------------

## Yenilenenler döner, kalıcı bit kalır (§3.2). renew_k: (tür) -> k; k < 1 ise düğümlerin k payı (gün tohumlu) döner, k ≥ 1 ise hak ×k
## (mantar, weather.md §8.14). Vuruş ilerlemesi, ikinci eylemin hakkı ve günün sayaçları silinir. Döner: {renewed}.
func on_dawn(day := 0, renew_k := Callable()) -> Dictionary:
	var renewed := 0
	for i in count:
		var f := flags[i]
		if (f & F_PERM) != 0:
			continue
		var row: Dictionary = rows[kind[i]]
		if not NodeStore._renews(row):
			continue
		var k := float(renew_k.call(kind_ids[kind[i]])) if renew_k.is_valid() else 1.0
		var full := int(row.get("charges", 1))
		var was := int(charges[i]) | ((f & (F_DEPLETED | F_STAGE)) << 8)
		flags[i] = f & ~(F_DEPLETED | F_STAGE)
		if k < 1.0:
			var on := float(NodeStore.hash32(i, day)) / TWO32 < k
			charges[i] = full if on else 0
			if not on:
				flags[i] |= F_DEPLETED
		else:
			charges[i] = mini(255, NodeStore.js_round(full * k))
		if was != int(charges[i]):
			renewed += 1
	hits.clear()
	alt.clear()
	day_count.clear()
	# Yenilenmeyen ama bugün dokunulan (kısmi stok, kalıcı kaya) düğümler kayıtta part listesinde kalır.
	for i: int in touched.keys():
		if NodeStore._renews(rows[kind[i]]) or (flags[i] & F_PERM) != 0:
			touched.erase(i)
	version += 1
	return {"renewed": renewed}


# --- Uzak alım (K23) -------------------------------------------------------------------------------------------------------

## Kümenin düğümleri tohumlu sırayla: kümenin kenarındaki tohumlu bir noktadan içeri (kesim yeri görünür büyür), küçük sapmayla.
func order_of(cluster: String, kind_id := "") -> PackedInt32Array:
	var key := "%s|%s" % [cluster, kind_id] if not kind_id.is_empty() else cluster
	if _orders.has(key):
		return _orders[key]
	var k: int = kind_index.get(kind_id, -1) if not kind_id.is_empty() else -1
	var list: Array[int] = []
	var mx := 0.0
	var mz := 0.0
	for pair: Array in clusters.get(cluster, []):
		for i in range(int(pair[0]), int(pair[1])):
			if k >= 0 and kind[i] != k:
				continue
			list.append(i)
			mx += x[i]
			mz += z[i]
	if not list.is_empty():
		mx /= list.size()
		mz /= list.size()
	var big_r := 0.0
	for i in list:
		big_r = maxf(big_r, NodeStore._hypot(float(x[i]) - mx, float(z[i]) - mz))
	var h := NodeStore.hash32(WeatherRng.str_hash(cluster), seed)
	var a := (float(h) / TWO32) * TAU
	var ex := mx + cos(a) * big_r
	var ez := mz + sin(a) * big_r
	var key_of := {}
	for i in list:
		key_of[i] = NodeStore._hypot(float(x[i]) - ex, float(z[i]) - ez) + (float(NodeStore.hash32(i, h)) / TWO32) * ORDER_JITTER
	list.sort_custom(func(p: int, q: int) -> bool:
		var kp: float = key_of[p]
		var kq: float = key_of[q]
		return kp < kq or (kp == kq and p < q))
	var out := PackedInt32Array(list)
	_orders[key] = out
	return out


## Bir düğümde evreler boyunca kalan hak (applyTaken birimi).
func remaining(i: int) -> int:
	if i < 0 or i >= count:
		return 0
	var f := flags[i]
	if (f & (F_PERM | F_DEPLETED)) != 0:
		return 0
	if (f & F_STAGE) != 0:
		return charges[i]
	var row: Dictionary = rows[kind[i]]
	return int(charges[i]) + (int((row["then"] as Dictionary).get("charges", 1)) if row.get("then") is Dictionary else 0)


static func _total_charges(row: Dictionary) -> int:
	return int(row.get("charges", 1)) + (int((row["then"] as Dictionary).get("charges", 1)) if row.get("then") is Dictionary else 0)


## Yerleşimin uzaktan aldığı n hakkı kümenin düğümlerine sırayla işler (settlement.md §9.5): sıranın ilk n hakkı alınmış sayılır. Mutlaktır:
## aynı n ikinci kez bir şey değiştirmez; oyuncunun kendi tükettiği önekteyse sayılır. kind_id: karışık kümede tek tür. → işlenen hak.
func apply_taken(cluster: String, n: int, kind_id := "") -> int:
	var left := maxi(0, n)
	var total0 := left
	if left == 0:
		return 0
	for i in order_of(cluster, kind_id):
		if left <= 0:
			break
		var total := NodeStore._total_charges(rows[kind[i]])
		var take := mini(total, left)
		left -= take
		var target := total - take
		var rem := remaining(i)
		while rem > target:
			consume(i, 1)
			rem -= 1
	return total0 - left


# --- Kayıt -------------------------------------------------------------------------------------------------------------------

## {perm: base64, part: [[i, c]], day: [[i, c, h?, s?, a?]], seq: [[i, n]], struck: [i]}. perm 3.270 bitte 409 B; day yalnız bugün
## dokunulan yenilenebilirler (şafakta boşalır); part yenilenmeyenlerin kısmi stoğu.
func to_dict() -> Dictionary:
	var bits := PackedByteArray()
	bits.resize(ceili(count / 8.0))
	var part: Array = []
	var day: Array = []
	var struck: Array = []
	for i in count:
		var f := flags[i]
		if (f & F_PERM) != 0:
			bits[i >> 3] |= 1 << (i & 7)
		if (f & F_STRUCK) != 0 and (f & F_PERM) == 0:
			struck.append(i)
	var keys: Array = touched.keys()
	keys.sort()
	for i: int in keys:
		var f := flags[i]
		if (f & F_PERM) != 0:
			continue
		var row: Dictionary = rows[kind[i]]
		var s := 1 if (f & F_STAGE) != 0 else 0
		var h := int(hits.get(i, 0))
		var a := int(alt[i]) if alt.has(i) else -1
		if NodeStore._renews(row):
			var e: Array = [i, int(charges[i])]
			if h != 0 or s != 0 or a >= 0:
				e.append(h)
			if s != 0 or a >= 0:
				e.append(s)
			if a >= 0:
				e.append(a)
			day.append(e)
		else:
			if int(charges[i]) != int(row.get("charges", 1)):
				part.append([i, int(charges[i])])
			if h != 0:
				day.append([i, int(charges[i]), h])
	var seq_list: Array = []
	var seq_keys: Array = seq.keys()
	seq_keys.sort()
	for i: int in seq_keys:
		seq_list.append([i, int(seq[i])])
	return {"perm": NodeStore.to_base64(bits), "part": part, "day": day, "seq": seq_list, "struck": struck}


## Kayıttan: önce taze duruma döner, sonra kalıcı bitler, kısmi stok, günün durumu (keep_day false ise atlanır: nodesV uymadı ya da gün
## geçti), sıra konumu. Bozuk alan atlanır. Döner: okundu mu (sözlük değilse false).
func from_dict(o: Variant, keep_day := true) -> bool:
	reset()
	if not o is Dictionary:
		return false
	var d: Dictionary = o
	var bits := NodeStore.from_base64(d.get("perm"), ceili(count / 8.0))
	for i in count:
		if (bits[i >> 3] & (1 << (i & 7))) == 0:
			continue
		flags[i] = F_PERM | F_DEPLETED
		charges[i] = 0
	for e: Variant in (d.get("part") if d.get("part") is Array else []):
		if not _ok_entry(e) or (flags[int(e[0])] & F_PERM) != 0:
			continue
		var i := int(e[0])
		var row: Dictionary = rows[kind[i]]
		charges[i] = clampi(NodeStore._int_or(e, 1), 0, int(row.get("charges", 1)))
		touched[i] = true
		if charges[i] == 0:
			flags[i] |= F_PERM | F_DEPLETED
	if keep_day:
		for e: Variant in (d.get("day") if d.get("day") is Array else []):
			if not _ok_entry(e) or (flags[int(e[0])] & F_PERM) != 0:
				continue
			var i := int(e[0])
			var row: Dictionary = rows[kind[i]]
			var list: Array = e
			var s := 1 if list.size() > 3 and NodeStore._num(list[3]) and int(list[3]) == 1 and row.get("then") is Dictionary else 0
			var st := NodeStore._stage_row(row, s)
			if s != 0:
				flags[i] |= F_STAGE
			if NodeStore._renews(row) or s != 0:
				charges[i] = clampi(NodeStore._int_or(list, 1), 0, int(st.get("charges", 1)))
				if charges[i] == 0:
					flags[i] |= F_DEPLETED if NodeStore._renews(st) else (F_PERM | F_DEPLETED)
			if list.size() > 2 and NodeStore._num(list[2]) and int(list[2]) > 0:
				hits[i] = int(list[2])
			if list.size() > 4 and NodeStore._num(list[4]) and int(list[4]) >= 0 and row.get("alt") is Dictionary:
				alt[i] = int(list[4])
			touched[i] = true
	for e: Variant in (d.get("seq") if d.get("seq") is Array else []):
		if _ok_entry(e) and (e as Array).size() > 1 and NodeStore._num(e[1]) and int(e[1]) >= 0:
			seq[int(e[0])] = int(e[1])
	for v: Variant in (d.get("struck") if d.get("struck") is Array else []):
		if NodeStore._num(v) and int(v) >= 0 and int(v) < count:
			mark_struck(int(v))
	version += 1
	return true


func _ok_entry(e: Variant) -> bool:
	return e is Array and (e as Array).size() > 0 and NodeStore._num(e[0]) and float(e[0]) == floorf(float(e[0])) \
		and int(e[0]) >= 0 and int(e[0]) < count


static func _int_or(list: Array, at: int) -> int:
	return int(list[at]) if list.size() > at and NodeStore._num(list[at]) else 0


static func _num(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v))


## Taze durum: konumlar aynı, haklar tam, bitler ve gün durumu silinir.
func reset() -> void:
	for i in count:
		flags[i] = 0
		charges[i] = int(rows[kind[i]].get("charges", 1))
	hits.clear()
	seq.clear()
	alt.clear()
	touched.clear()
	day_count.clear()
	version += 1


## Tür başına kayıt sayısı.
func count_by_kind() -> Dictionary:
	var out := {}
	for i in count:
		var id := kind_ids[kind[i]]
		out[id] = int(out.get(id, 0)) + 1
	return out


# --- Prototipin sayı yardımcıları (bit bit) ----------------------------------------------------------------------------------

## 32 bit tamsayı karması (node-store.js hash32): belirlenimli, ayırmasız.
static func hash32(a: int, b := 0) -> int:
	var h := WeatherRng.imul((a & MASK) ^ 0x9e3779b9, 0x85ebca6b) ^ WeatherRng.imul((b + 0x632be59b) & MASK, 0xc2b2ae35)
	h &= MASK
	h ^= h >> 15
	h = WeatherRng.imul(h, 0x2c1b3c6d)
	h ^= h >> 12
	h = WeatherRng.imul(h, 0x297a2d39)
	return (h ^ (h >> 15)) & MASK


## Saf base64 (prototipin toBase64'ü; dolgu «=»).
static func to_base64(bytes: PackedByteArray) -> String:
	var out := ""
	var i := 0
	while i < bytes.size():
		var a := bytes[i]
		var b := bytes[i + 1] if i + 1 < bytes.size() else 0
		var c := bytes[i + 2] if i + 2 < bytes.size() else 0
		var n := (a << 16) | (b << 8) | c
		out += B64[(n >> 18) & 63] + B64[(n >> 12) & 63]
		out += B64[(n >> 6) & 63] if i + 1 < bytes.size() else "="
		out += B64[n & 63] if i + 2 < bytes.size() else "="
		i += 3
	return out


## Saf base64 çözümü (prototipin fromBase64'ü): yazı değilse ya da bozuksa okunan kadarı, kalan sıfır.
static func from_base64(text: Variant, size: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(maxi(0, size))
	if not text is String:
		return out
	var s: String = text
	var k := 0
	var i := 0
	while i < s.length() and k < size:
		var v: Array[int] = []
		for j in 4:
			v.append(B64.find(s[i + j]) if i + j < s.length() and s[i + j] != "=" else -1)
		if v[0] < 0 or v[1] < 0:
			break
		var n := (v[0] << 18) | (v[1] << 12) | ((0 if v[2] < 0 else v[2]) << 6) | (0 if v[3] < 0 else v[3])
		out[k] = (n >> 16) & 255
		k += 1
		if v[2] >= 0 and k < size:
			out[k] = (n >> 8) & 255
			k += 1
		if v[3] >= 0 and k < size:
			out[k] = n & 255
			k += 1
		i += 4
	return out


## JS'nin Math.round'u (yarım +∞'a).
static func js_round(v: float) -> int:
	return floori(v + 0.5)


## JS'nin sayı yazımı (küme kimliği «tür@x,z»): tamsayı noktasız, kesirli en kısa gösterimle.
static func _js_num(v: float) -> String:
	if v == floorf(v) and absf(v) < 1e15:
		return str(int(v))
	return String.num(v, 6).rstrip("0").rstrip(".")


static func _hypot(a: float, b: float) -> float:
	return sqrt(a * a + b * b)


## Prototipin core/math.js'i: Perlin noise2 (1337 tohumlu permütasyon) ve fbm2 (oktav başına +17,3 / −9,1 kayma).
static func noise2(px: float, py: float) -> float:
	if _perm.is_empty():
		NodeStore._build_perm()
	var xi := floori(px)
	var yi := floori(py)
	var bx := xi & 255
	var by := yi & 255
	var fx := px - xi
	var fy := py - yi
	var u := NodeStore._fade(fx)
	var v := NodeStore._fade(fy)
	var a := _perm[bx] + by
	var b := _perm[bx + 1] + by
	return lerpf(lerpf(NodeStore._g2(_perm[a], fx, fy), NodeStore._g2(_perm[b], fx - 1.0, fy), u),
		lerpf(NodeStore._g2(_perm[a + 1], fx, fy - 1.0), NodeStore._g2(_perm[b + 1], fx - 1.0, fy - 1.0), u), v)


static func fbm2(px: float, py: float, oct := 4, lac := 2.0, gain := 0.5) -> float:
	var amp := 1.0
	var freq := 1.0
	var s := 0.0
	var n := 0.0
	for i in oct:
		s += amp * NodeStore.noise2(px * freq + i * 17.3, py * freq - i * 9.1)
		n += amp
		amp *= gain
		freq *= lac
	return s / n


static func _build_perm() -> void:
	var r := WeatherRng.new(1337)
	var p: Array[int] = []
	for i in 256:
		p.append(i)
	for i in range(255, 0, -1):
		var j := floori(r.next() * (i + 1))
		var t := p[i]
		p[i] = p[j]
		p[j] = t
	_perm.resize(512)
	for i in 512:
		_perm[i] = p[i & 255]


static func _fade(t: float) -> float:
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


static func _g2(h: int, px: float, py: float) -> float:
	match h & 7:
		0:
			return px + py
		1:
			return -px + py
		2:
			return px - py
		3:
			return -px - py
		4:
			return px
		5:
			return -px
		6:
			return py
	return -py
