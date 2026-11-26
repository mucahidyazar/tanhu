class_name StructureCatalog
extends RefCounted
## Kışlak'ın yurt dışı yapıları (building-catalog; act1.md §4 «Kışlak yerleşimi», structures.md §4, settlement.md §7): her tür aşama
## kitinin tek ağıdır (StagedMesh; aşamaları data/structures/structures.json'un adımlarıyla aynı), kodla kurulur, köşe renklidir; küçük
## yapı ≤6k üçgen, ≤2 çizim (act1.md §9.3). Ağ önbelleklidir (tür|ayar). Ölçüler Godot'nundur (m): Hane Yurdu'nun duvarı 3,3 m'dir.
## Ayrıca kurulan düğümler (ateş, ağılın örnekli panoları, kara bez) StructureKit'tedir.
##
## Türler ve aşamaları (staged: kurulum ve geri düşüş; yoksa aşama 0, yıkılmaz):
##   stable        Ahır ve Ağıl: 5 aşama (zemin ve oluk, direk, bölme ve duvar, kiriş, çatı; Kışlak'ta saz ve keçe dam), yanında ağıl
##   tower         Kule: 4 aşama (ayak, çapraz, platform, korkuluk); platform 5 m, merdivenli
##   kantu_shed    Kantu'nun Barakası (shed, açık): 5 aşama (ayak, direk, kiriş, dallık, saz örtü)
##   felt_yard     Keçe Avlusu: 4 aşama (zemin, direk ve çit, germe çerçevesi, döğme hasırı ve çiy), 14 × 10 m
##   tent_qiang    Çiang çadırı (kara çadır): 3 aşama (kazık, direk ve ip, örtü), 6,5 × 5 m, h 3
##   great_hearth  Ulu Ocak: r 12 m meydan (ezik zemin), taş halka, oturak kütükleri (ateşi StructureKit kurar)
##   count_stone, work_board, kitchen (Mutfak Kazanı ve kurutma sırıkları), woodpile, latrine, watch_fire, yurt_pad, hollow_gate,
##   offering_pen (çit ve kapı: panolar örneklidir)
##   var mesh := StructureCatalog.mesh("tower")
##   StructureCatalog.stages_of("tower")      # 3 (en son aşama)

static var _cache: Dictionary = {}

## Ahırın yarı ölçüsü (m; yerel x boyu, z derinliği) ve bölmesi.
const STABLE_HALF := Vector2(6.5, 3.2)
const STABLE_STALLS := 8
const WOOD := Color("#6b4a2e")
const WOOD_DARK := Color("#4a3322")
const WOOD_LIGHT := Color("#8a6a44")
const THATCH := Color("#b89a62")
const STONE := Color("#8a8276")
const FELT := Color("#c9b896")
const ROPE := Color("#a88a62")


static func forget() -> void:
	_cache.clear()


## Türün en son aşaması (0: aşamasız).
static func stages_of(kind: String) -> int:
	match kind:
		"stable", "kantu_shed", "shed", "granary":
			return 4
		"tower", "felt_yard":
			return 3
		"tent_qiang", "tent":
			return 2
		"offering_pen", "pen", "fence", "hollow_gate", "gate":
			return 1
	return 0


## Türün emek satırı (Labour.steps_of): Kışlak'ın adları structures.json türlerine.
static func labour_kind(kind: String) -> String:
	match kind:
		"kantu_shed":
			return "shed"
		"tent_qiang":
			return "tent"
		"offering_pen", "hollow_gate":
			return "pen"
	return kind


static func has(kind: String) -> bool:
	return ["stable", "tower", "kantu_shed", "shed", "felt_yard", "tent_qiang", "great_hearth", "count_stone", "work_board", "kitchen",
		"woodpile", "latrine", "watch_fire", "yurt_pad", "hollow_gate", "offering_pen", "gate", "lantern", "black_cloth"].has(kind)


## Önbellekli ağ.
static func mesh(kind: String, variant: String = "") -> ArrayMesh:
	var key := "%s|%s" % [kind, variant]
	if _cache.has(key):
		return _cache[key]
	var sm := StagedMesh.new()
	match kind:
		"stable":
			StructureCatalog._stable(sm, variant)
		"tower":
			StructureCatalog._tower(sm)
		"kantu_shed", "shed":
			StructureCatalog._shed(sm)
		"felt_yard":
			StructureCatalog._felt_yard(sm)
		"tent_qiang":
			StructureCatalog._tent_qiang(sm)
		"great_hearth":
			StructureCatalog._great_hearth(sm)
		"count_stone":
			StructureCatalog._count_stone(sm)
		"work_board":
			StructureCatalog._work_board(sm)
		"kitchen":
			StructureCatalog._kitchen(sm)
		"woodpile":
			StructureCatalog._woodpile(sm)
		"latrine":
			StructureCatalog._latrine(sm)
		"watch_fire":
			StructureCatalog._watch_fire(sm)
		"yurt_pad":
			StructureCatalog._yurt_pad(sm)
		"hollow_gate", "offering_pen", "gate":
			StructureCatalog._gate(sm, 3.2)
		"lantern":
			StructureCatalog._lantern(sm)
		"black_cloth":
			StructureCatalog._black_cloth(sm)
	var m := sm.commit()
	_cache[key] = m
	return m


## Ahırın bölmeleri (yerel): atın yeri (arka duvardan 1,7 m) ve yönü (yerel +Z, kapıya). StructureKit.stable_stalls dünyaya çevirir.
static func stable_stalls() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for k in STABLE_STALLS:
		var x := -STABLE_HALF.x + (float(k) + 0.5) * STABLE_HALF.x * 2.0 / float(STABLE_STALLS)
		out.append(Vector2(x, -STABLE_HALF.y + 1.7))
	return out


## Ayak izi (yerel): {circles: [Vector3(x, z, r)], boxes: [[merkez, yarı, açı]]} ve engelin başladığı aşama.
static func footprint(kind: String) -> Dictionary:
	match kind:
		"stable":
			return {"boxes": [[Vector2(0, -STABLE_HALF.y), Vector2(STABLE_HALF.x, 0.2), 0.0], [Vector2(-STABLE_HALF.x, 0), Vector2(0.2, STABLE_HALF.y), 0.0],
				[Vector2(STABLE_HALF.x, 0), Vector2(0.2, STABLE_HALF.y), 0.0]], "min_stage": 2}
		"tower":
			return {"circles": [Vector3(-1.2, -1.2, 0.3), Vector3(1.2, -1.2, 0.3), Vector3(-1.2, 1.2, 0.3), Vector3(1.2, 1.2, 0.3)], "min_stage": 1}
		"kantu_shed", "shed":
			return {"circles": [Vector3(-3.0, -2.0, 0.25), Vector3(3.0, -2.0, 0.25), Vector3(-3.0, 2.0, 0.25), Vector3(3.0, 2.0, 0.25)], "boxes": [[Vector2(0, -0.4), Vector2(2.2, 1.0), 0.0]], "min_stage": 1}
		"felt_yard":
			return {"boxes": [[Vector2(-2.5, 0), Vector2(1.6, 0.4), 0.0], [Vector2(2.5, 0.8), Vector2(1.6, 0.4), 0.0]], "min_stage": 2}
		"tent_qiang":
			return {"boxes": [[Vector2.ZERO, Vector2(3.0, 2.3), 0.0]], "min_stage": 2}
		"great_hearth":
			return {"circles": [Vector3(0, 0, 1.6)], "min_stage": 0}
		"count_stone":
			return {"circles": [Vector3(0, 0, 0.6)], "min_stage": 0}
		"work_board":
			return {"boxes": [[Vector2.ZERO, Vector2(0.95, 0.2), 0.0]], "min_stage": 0}
		"kitchen":
			return {"circles": [Vector3(0, 0, 1.0)], "min_stage": 0}
		"woodpile":
			return {"boxes": [[Vector2.ZERO, Vector2(1.7, 0.7), 0.0]], "min_stage": 0}
		"latrine":
			return {"boxes": [[Vector2(0, -0.8), Vector2(1.1, 0.12), 0.0], [Vector2(-1.05, 0), Vector2(0.12, 0.8), 0.0], [Vector2(1.05, 0), Vector2(0.12, 0.8), 0.0]], "min_stage": 0}
		"watch_fire":
			return {"circles": [Vector3(0, 0, 0.7)], "min_stage": 0}
		"gate", "hollow_gate", "offering_pen":
			return {"circles": [Vector3(-1.6, 0, 0.2), Vector3(1.6, 0, 0.2)], "min_stage": 0}
		"lantern":
			return {"circles": [Vector3(0, 0, 0.25)], "min_stage": 0}
		"black_cloth":
			return {"circles": [Vector3(-1.1, 0, 0.12), Vector3(1.1, 0, 0.12)], "min_stage": 0}
	return {"min_stage": 99}


# --- Yardımcılar ----------------------------------------------------------------------------------------------

static func _post(sm: StagedMesh, at: Vector3, h: float, w: float = 0.16, col: Color = WOOD) -> void:
	sm.box(Transform3D(Basis(Vector3.UP, fposmod(at.x * 0.7 + at.z, 0.4) - 0.2), at + Vector3(0, h * 0.5, 0)), Vector3(w, h, w), col)


## Saz ya da keçe dam paneli (iki eğimli): sırt boyunca n şerit (ince yüzey).
static func _roof(sm: StagedMesh, half_w: float, half_d: float, eave: float, ridge: float, col: Color, cls: int, stage: int, base_order: float, felt_band: bool) -> void:
	for side: float in [-1.0, 1.0]:
		var rows := 4
		for r in rows:
			var t0 := float(r) / float(rows)
			var t1 := float(r + 1) / float(rows)
			var z0 := side * half_d * (1.0 - t0)
			var z1 := side * half_d * (1.0 - t1)
			var y0 := lerpf(eave, ridge, t0)
			var y1 := lerpf(eave, ridge, t1)
			var o := base_order + (0.5 if side > 0.0 else 0.0) * 0.5 + float(r) * 0.1
			sm.part(stage, clampf(o, 0.0, 0.95), StagedMesh.MODE_POP, Vector3(0, y0, z0), cls)
			var nrm := Vector3(0, half_d, side * (ridge - eave)).normalized()
			var shade := 1.0 - 0.06 * float(r % 2)
			var c := Color(col.r * shade, col.g * shade, col.b * shade)
			var a := sm.vertex(StagedMesh.THIN, Vector3(-half_w, y0, z0), nrm, c, Vector2(0, t0))
			var b := sm.vertex(StagedMesh.THIN, Vector3(half_w, y0, z0), nrm, c, Vector2(1, t0))
			var cc := sm.vertex(StagedMesh.THIN, Vector3(half_w, y1, z1), nrm, c, Vector2(1, t1))
			var d := sm.vertex(StagedMesh.THIN, Vector3(-half_w, y1, z1), nrm, c, Vector2(0, t1))
			# Dışarıdan bakınca saat yönü ön yüzdür: +z eğiminde a d cc b, −z eğiminde a b cc d.
			if side > 0.0:
				sm.quad(StagedMesh.THIN, a, d, cc, b)
			else:
				sm.quad(StagedMesh.THIN, a, b, cc, d)
	if felt_band:
		# Kışlak: sırtın üstünde keçe şerit ve onu tutan taşlar.
		sm.part(stage, 0.92, StagedMesh.MODE_POP, Vector3(0, ridge, 0), StagedMesh.CLS_FELT)
		sm.box(Transform3D(Basis.IDENTITY, Vector3(0, ridge + 0.04, 0)), Vector3(half_w * 2.0 + 0.2, 0.06, 1.2), FELT.darkened(0.15))
		for k in 5:
			var x := (float(k) / 4.0 - 0.5) * half_w * 1.8
			sm.blob(Vector3(x, ridge + 0.05, 0.45), Vector3(0.12, 0.1, 0.1), 300 + k, STONE)
			sm.blob(Vector3(x + 0.3, ridge + 0.05, -0.45), Vector3(0.12, 0.1, 0.1), 310 + k, STONE)


# --- Ahır ve ağıl ---------------------------------------------------------------------------------------------

## Ahır (structures.md §4.1; Kışlak'ta dam saz ve keçe): 13 × 6,4 m, sekiz atlık (bölme 1,6 m); önü (yerel +Z) açık, arkası tahta; atlar
## arka duvar boyunca durur (stable_stalls), önü kapıya.
static func _stable(sm: StagedMesh, _variant: String) -> void:
	var hw := STABLE_HALF.x
	var hd := STABLE_HALF.y
	var eave := 2.4
	var ridge := 3.7
	# 0 zemin ve oluk: saman izli zemin, yemlik oluğu.
	sm.part(0, 0.1, StagedMesh.MODE_RISE, Vector3.ZERO, StagedMesh.CLS_STONE)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.02, 0)), Vector3(hw * 2.0, 0.04, hd * 2.0), Color("#8a7a58"))
	sm.part(0, 0.6, StagedMesh.MODE_RISE, Vector3(0, 0, -hd + 0.4), StagedMesh.CLS_WOOD)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.35, -hd + 0.45)), Vector3(hw * 1.8, 0.3, 0.45), WOOD_DARK)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.46, -hd + 0.45)), Vector3(hw * 1.75, 0.06, 0.32), THATCH)
	# 1 direk: 4 × 2 sıra.
	var xs: Array[float] = [-hw, -hw / 3.0, hw / 3.0, hw]
	var i := 0
	for x: float in xs:
		for z: float in [-hd, hd]:
			sm.part(1, 0.1 + 0.08 * float(i), StagedMesh.MODE_RISE, Vector3(x, 0, z), StagedMesh.CLS_WOOD)
			StructureCatalog._post(sm, Vector3(x, 0, z), eave + (0.0 if z > 0.0 else 0.0), 0.2)
			i += 1
	# 2 bölme ve duvar: arka tahta duvar, yan duvarlar, bölme korkulukları.
	for k in 10:
		var x := -hw + (float(k) + 0.5) * hw * 0.2
		sm.part(2, float(k) / 10.0 * 0.6, StagedMesh.MODE_RISE, Vector3(x, 0, -hd), StagedMesh.CLS_WOOD)
		sm.box(Transform3D(Basis.IDENTITY, Vector3(x, eave * 0.5, -hd - 0.04)), Vector3(hw * 0.2 - 0.02, eave, 0.08), WOOD.lightened(0.04 * float(k % 3)))
	for s: float in [-1.0, 1.0]:
		for k in 4:
			var z := -hd + (float(k) + 0.5) * hd * 0.5
			sm.part(2, 0.62 + 0.04 * float(k), StagedMesh.MODE_RISE, Vector3(s * hw, 0, z), StagedMesh.CLS_WOOD)
			sm.box(Transform3D(Basis.IDENTITY, Vector3(s * (hw + 0.04), eave * 0.42, z)), Vector3(0.08, eave * 0.84, hd * 0.5 - 0.02), WOOD.darkened(0.05))
	for k in STABLE_STALLS - 1:
		var x := -hw + float(k + 1) * hw * 2.0 / float(STABLE_STALLS)
		sm.part(2, 0.82 + 0.02 * float(k), StagedMesh.MODE_POP, Vector3(x, 0.9, -hd), StagedMesh.CLS_WOOD)
		sm.beam(Vector3(x, 1.0, -hd + 0.2), Vector3(x, 1.0, -hd + 2.6), 0.07, 0.1, WOOD_LIGHT)
		sm.beam(Vector3(x, 0.55, -hd + 0.2), Vector3(x, 0.55, -hd + 2.6), 0.07, 0.1, WOOD_LIGHT)
	sm.beam(Vector3(-hw, 1.05, hd), Vector3(hw, 1.05, hd), 0.08, 0.1, WOOD_LIGHT)
	# 3 kiriş: saçak kirişleri, mahya, mertekler.
	sm.part(3, 0.1, StagedMesh.MODE_POP, Vector3(0, eave, -hd), StagedMesh.CLS_WOOD)
	sm.beam(Vector3(-hw - 0.3, eave + 0.05, -hd), Vector3(hw + 0.3, eave + 0.05, -hd), 0.18, 0.18, WOOD_DARK)
	sm.part(3, 0.25, StagedMesh.MODE_POP, Vector3(0, eave, hd), StagedMesh.CLS_WOOD)
	sm.beam(Vector3(-hw - 0.3, eave + 0.05, hd), Vector3(hw + 0.3, eave + 0.05, hd), 0.18, 0.18, WOOD_DARK)
	for s: float in [-1.0, 1.0]:
		sm.part(3, 0.4, StagedMesh.MODE_RISE, Vector3(s * hw, eave, 0), StagedMesh.CLS_WOOD)
		sm.beam(Vector3(s * hw, eave, 0), Vector3(s * hw, ridge, 0), 0.16, 0.16, WOOD_DARK)
	sm.part(3, 0.55, StagedMesh.MODE_POP, Vector3(0, ridge, 0), StagedMesh.CLS_WOOD)
	sm.beam(Vector3(-hw - 0.3, ridge, 0), Vector3(hw + 0.3, ridge, 0), 0.16, 0.16, WOOD_DARK)
	for k in 8:
		var x := -hw + float(k) * hw * 2.0 / 7.0
		sm.part(3, 0.62 + 0.04 * float(k), StagedMesh.MODE_POP, Vector3(x, ridge, 0), StagedMesh.CLS_WOOD)
		for z: float in [-hd - 0.4, hd + 0.4]:
			sm.beam(Vector3(x, eave - 0.1, z), Vector3(x, ridge + 0.02, 0), 0.08, 0.06, WOOD)
	# 4 çatı: saz dam, Kışlak'ta sırtta keçe.
	StructureCatalog._roof(sm, hw + 0.35, hd + 0.5, eave - 0.12, ridge + 0.1, THATCH, StagedMesh.CLS_REED, 4, 0.0, true)
	# Asılı eyer ve fener (duvar eşyası).
	sm.part(4, 0.96, StagedMesh.MODE_POP, Vector3(0, 1.5, -hd), StagedMesh.CLS_WOOD)
	for k in 2:
		var x := (float(k) - 0.5) * hw
		sm.box(Transform3D(Basis.IDENTITY, Vector3(x, 1.5, -hd + 0.15)), Vector3(0.5, 0.18, 0.3), Color("#6a3a22"))


# --- Kule -----------------------------------------------------------------------------------------------------

static func _tower(sm: StagedMesh) -> void:
	var h := 5.2
	var r := 1.2
	var legs: Array[Vector3] = [Vector3(-r, 0, -r), Vector3(r, 0, -r), Vector3(r, 0, r), Vector3(-r, 0, r)]
	# 0 ayak: taş ayaklar.
	for k in 4:
		sm.part(0, 0.15 * float(k), StagedMesh.MODE_POP, legs[k], StagedMesh.CLS_STONE)
		sm.blob(legs[k] + Vector3(0, -0.05, 0), Vector3(0.38, 0.32, 0.38), 120 + k, STONE)
	# 1 çapraz: bacaklar ve çapraz kuşaklar.
	for k in 4:
		var leg: Vector3 = legs[k]
		var top := leg * 0.8 + Vector3(0, h + 0.2, 0)
		sm.part(1, 0.06 * float(k), StagedMesh.MODE_RISE, legs[k], StagedMesh.CLS_WOOD)
		sm.beam(legs[k] + Vector3(0, 0.1, 0), top, 0.2, 0.2, WOOD_DARK)
	for k in 4:
		var a: Vector3 = legs[k]
		var b: Vector3 = legs[(k + 1) % 4]
		for lvl in 2:
			var y0 := 0.5 + float(lvl) * 2.3
			var y1 := y0 + 2.1
			var a0 := a * (1.0 - 0.2 * y0 / h) + Vector3(0, y0, 0)
			var b1 := b * (1.0 - 0.2 * y1 / h) + Vector3(0, y1, 0)
			var b0 := b * (1.0 - 0.2 * y0 / h) + Vector3(0, y0, 0)
			var a1 := a * (1.0 - 0.2 * y1 / h) + Vector3(0, y1, 0)
			sm.part(1, 0.3 + 0.08 * float(k) + 0.15 * float(lvl), StagedMesh.MODE_POP, (a0 + b1) * 0.5, StagedMesh.CLS_WOOD)
			sm.beam(a0, b1, 0.09, 0.09, WOOD)
			sm.beam(b0, a1, 0.09, 0.09, WOOD)
	# 2 platform.
	sm.part(2, 0.2, StagedMesh.MODE_POP, Vector3(0, h, 0), StagedMesh.CLS_WOOD)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, h + 0.25, 0)), Vector3(r * 2.4, 0.16, r * 2.4), WOOD_LIGHT)
	for k in 6:
		var x := (float(k) / 5.0 - 0.5) * r * 2.2
		sm.part(2, 0.35 + 0.08 * float(k), StagedMesh.MODE_POP, Vector3(x, h + 0.35, 0), StagedMesh.CLS_WOOD)
		sm.beam(Vector3(x, h + 0.36, -r * 1.15), Vector3(x, h + 0.36, r * 1.15), 0.24, 0.05, WOOD.lightened(0.05 * float(k % 2)))
	# Merdiven.
	sm.part(2, 0.85, StagedMesh.MODE_RISE, Vector3(0, 0, r + 0.9), StagedMesh.CLS_WOOD)
	for s: float in [-0.25, 0.25]:
		sm.beam(Vector3(s, 0, r + 1.1), Vector3(s, h + 0.3, r * 0.9), 0.07, 0.07, WOOD)
	for k in 9:
		var t := (float(k) + 0.6) / 10.0
		var z := lerpf(r + 1.1, r * 0.9, t)
		sm.beam(Vector3(-0.28, h * t, z), Vector3(0.28, h * t, z), 0.05, 0.05, WOOD_LIGHT)
	# 3 korkuluk ve gölgelik direği.
	for k in 4:
		var a: Vector3 = legs[k] * 1.0
		var b: Vector3 = legs[(k + 1) % 4] * 1.0
		sm.part(3, 0.15 * float(k), StagedMesh.MODE_RISE, a + Vector3(0, h + 0.33, 0), StagedMesh.CLS_WOOD)
		StructureCatalog._post(sm, a + Vector3(0, h + 0.33, 0), 1.0, 0.1, WOOD_DARK)
		sm.beam(a + Vector3(0, h + 1.25, 0), b + Vector3(0, h + 1.25, 0), 0.08, 0.08, WOOD)
		sm.beam(a + Vector3(0, h + 0.8, 0), b + Vector3(0, h + 0.8, 0), 0.06, 0.06, WOOD_LIGHT)
	sm.part(3, 0.8, StagedMesh.MODE_RISE, Vector3(r, h + 0.33, -r), StagedMesh.CLS_WOOD)
	sm.beam(Vector3(r, h + 0.33, -r), Vector3(r, h + 3.0, -r), 0.07, 0.07, WOOD_DARK)
	sm.part(3, 0.9, StagedMesh.MODE_POP, Vector3(r, h + 3.0, -r), StagedMesh.CLS_FELT)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(r + 0.35, h + 2.75, -r)), Vector3(0.7, 0.45, 0.03), Color("#6b2130"))


# --- Sundurma (Kantu'nun Barakası) -----------------------------------------------------------------------------

static func _shed(sm: StagedMesh) -> void:
	var hw := 3.0
	var hd := 2.0
	var eave := 2.1
	var ridge := 2.9
	sm.part(0, 0.2, StagedMesh.MODE_RISE, Vector3.ZERO, StagedMesh.CLS_STONE)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.02, 0)), Vector3(hw * 2.0 + 0.4, 0.04, hd * 2.0 + 0.4), Color("#7a6a50"))
	var k := 0
	for x: float in [-hw, 0.0, hw]:
		for z: float in [-hd, hd]:
			sm.part(1, 0.12 * float(k), StagedMesh.MODE_RISE, Vector3(x, 0, z), StagedMesh.CLS_WOOD)
			StructureCatalog._post(sm, Vector3(x, 0, z), eave, 0.18)
			k += 1
	sm.part(2, 0.1, StagedMesh.MODE_POP, Vector3(0, eave, -hd), StagedMesh.CLS_WOOD)
	sm.beam(Vector3(-hw - 0.2, eave, -hd), Vector3(hw + 0.2, eave, -hd), 0.16, 0.16, WOOD_DARK)
	sm.part(2, 0.3, StagedMesh.MODE_POP, Vector3(0, eave, hd), StagedMesh.CLS_WOOD)
	sm.beam(Vector3(-hw - 0.2, eave, hd), Vector3(hw + 0.2, eave, hd), 0.16, 0.16, WOOD_DARK)
	sm.part(2, 0.5, StagedMesh.MODE_POP, Vector3(0, ridge, 0), StagedMesh.CLS_WOOD)
	sm.beam(Vector3(-hw - 0.2, ridge, 0), Vector3(hw + 0.2, ridge, 0), 0.14, 0.14, WOOD_DARK)
	for x: float in [-hw, 0.0, hw]:
		sm.part(2, 0.6, StagedMesh.MODE_RISE, Vector3(x, eave, 0), StagedMesh.CLS_WOOD)
		sm.beam(Vector3(x, eave, 0), Vector3(x, ridge, 0), 0.12, 0.12, WOOD)
	# 3 dallık: merteklerin üstünde dal katmanı.
	for j in 7:
		var x := -hw + float(j) * hw * 2.0 / 6.0
		sm.part(3, float(j) / 7.0 * 0.8, StagedMesh.MODE_POP, Vector3(x, ridge, 0), StagedMesh.CLS_WOOD)
		for z: float in [-hd - 0.3, hd + 0.3]:
			sm.beam(Vector3(x, eave - 0.05, z), Vector3(x, ridge + 0.02, 0), 0.06, 0.05, Color("#5a4632"))
	# 4 saz örtü.
	StructureCatalog._roof(sm, hw + 0.3, hd + 0.4, eave - 0.1, ridge + 0.08, THATCH.darkened(0.06), StagedMesh.CLS_REED, 4, 0.0, false)
	# İçeride odun ve saman yığını, bir tezgâh (Kantu'nun işi).
	sm.part(4, 0.95, StagedMesh.MODE_POP, Vector3(0, 0, -1.0), StagedMesh.CLS_WOOD)
	for j in 6:
		var y := 0.1 + float(j / 3) * 0.2
		var z := -1.2 + float(j % 3) * 0.22
		sm.log_between(Vector3(-1.8, y, z), Vector3(0.8, y, z), 0.1, 6, WOOD.darkened(0.06 * float(j % 2)))
	sm.box(Transform3D(Basis.IDENTITY, Vector3(1.8, 0.4, -0.6)), Vector3(1.2, 0.8, 1.3), THATCH)


# --- Keçe Avlusu ----------------------------------------------------------------------------------------------

static func _felt_yard(sm: StagedMesh) -> void:
	var hw := 7.0
	var hd := 5.0
	sm.part(0, 0.2, StagedMesh.MODE_RISE, Vector3.ZERO, StagedMesh.CLS_STONE)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.015, 0)), Vector3(hw * 2.0, 0.03, hd * 2.0), Color("#8a7a5c"))
	# 1 direk ve alçak çit (kapı +Z ortada açık).
	var corners: Array[Vector3] = [Vector3(-hw, 0, -hd), Vector3(hw, 0, -hd), Vector3(hw, 0, hd), Vector3(-hw, 0, hd)]
	for k in 4:
		sm.part(1, 0.1 * float(k), StagedMesh.MODE_RISE, corners[k], StagedMesh.CLS_WOOD)
		StructureCatalog._post(sm, corners[k], 1.6, 0.16)
	for k in 4:
		var a: Vector3 = corners[k]
		var b: Vector3 = corners[(k + 1) % 4]
		var gap := k == 2
		var n := 6
		for j in n:
			var t0 := float(j) / float(n)
			var t1 := float(j + 1) / float(n)
			if gap and (j == 2 or j == 3):
				continue
			var p0 := a.lerp(b, t0)
			var p1 := a.lerp(b, t1)
			sm.part(1, 0.45 + 0.4 * (float(k) + t0) / 4.0, StagedMesh.MODE_POP, p0, StagedMesh.CLS_WOOD)
			sm.beam(p0 + Vector3(0, 0.75, 0), p1 + Vector3(0, 0.75, 0), 0.06, 0.06, WOOD_LIGHT)
			sm.beam(p1, p1 + Vector3(0, 0.9, 0), 0.07, 0.07, WOOD)
	# 2 germe çerçeveleri: iki çerçeve, gerili keçe.
	for f in 2:
		var cx := -2.5 + 5.0 * float(f)
		var cz := 0.8 * float(f)
		sm.part(2, 0.1 + 0.45 * float(f), StagedMesh.MODE_RISE, Vector3(cx, 0, cz), StagedMesh.CLS_WOOD)
		for s: float in [-1.0, 1.0]:
			sm.beam(Vector3(cx + s * 1.5, 0, cz), Vector3(cx + s * 1.5, 1.9, cz), 0.08, 0.08, WOOD)
		sm.beam(Vector3(cx - 1.6, 1.85, cz), Vector3(cx + 1.6, 1.85, cz), 0.07, 0.07, WOOD)
		sm.beam(Vector3(cx - 1.6, 0.25, cz), Vector3(cx + 1.6, 0.25, cz), 0.07, 0.07, WOOD)
		sm.part(2, 0.3 + 0.45 * float(f), StagedMesh.MODE_RISE, Vector3(cx, 1.85, cz), StagedMesh.CLS_FELT)
		sm.box(Transform3D(Basis.IDENTITY, Vector3(cx, 1.05, cz)), Vector3(2.8, 1.5, 0.03), FELT.lerp(Color("#efe3c6"), 0.4 * float(f)))
	# 3 döğme hasırı ve çiy rüzgârlığı.
	for m in 3:
		var x := -4.5 + float(m) * 3.0
		sm.part(3, 0.1 + 0.15 * float(m), StagedMesh.MODE_RISE, Vector3(x, 0, -2.5), StagedMesh.CLS_REED)
		sm.box(Transform3D(Basis(Vector3.UP, 0.1 * float(m)), Vector3(x, 0.04, -2.6)), Vector3(2.2, 0.05, 1.4), THATCH.darkened(0.08 * float(m % 2)))
		sm.part(3, 0.2 + 0.15 * float(m), StagedMesh.MODE_POP, Vector3(x, 0.1, -2.6), StagedMesh.CLS_FELT)
		sm.log_between(Vector3(x - 0.9, 0.14, -2.4), Vector3(x + 0.9, 0.14, -2.4), 0.09, 8, Color("#d8c8a8"))
	sm.part(3, 0.7, StagedMesh.MODE_RISE, Vector3(0, 0, -hd + 0.3), StagedMesh.CLS_REED, {"pattern": 9})
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.8, -hd + 0.3)), Vector3(hw * 1.6, 1.6, 0.05), THATCH)
	# Yün yığını ve kova.
	sm.part(3, 0.85, StagedMesh.MODE_POP, Vector3(4.6, 0, 2.6), StagedMesh.CLS_FELT)
	sm.blob(Vector3(4.6, 0, 2.6), Vector3(0.8, 0.5, 0.6), 7, Color("#e8dcc0"), 1)


# --- Çiang çadırı ---------------------------------------------------------------------------------------------

static func _tent_qiang(sm: StagedMesh) -> void:
	var hw := 3.25
	var hd := 2.5
	var h := 3.0
	var black := Color("#2f2a26")
	# 0 kazıklar: 14 ipin kazığı, +2,5 m.
	for k in 14:
		var a := TAU * float(k) / 14.0
		var p := Vector3(sin(a) * (hw + 2.5), 0, cos(a) * (hd + 2.2))
		sm.part(0, float(k) / 14.0 * 0.8, StagedMesh.MODE_POP, p, StagedMesh.CLS_WOOD)
		sm.beam(p + Vector3(0, -0.05, 0), p + Vector3(0, 0.35, 0), 0.05, 0.05, WOOD_DARK)
	# 1 direk ve ip: iki dikme, sırt sırığı, altı dış sırık, ipler.
	for s: float in [-1.0, 1.0]:
		sm.part(1, 0.1, StagedMesh.MODE_RISE, Vector3(s * hw * 0.6, 0, 0), StagedMesh.CLS_WOOD)
		sm.beam(Vector3(s * hw * 0.6, 0, 0), Vector3(s * hw * 0.6, h, 0), 0.1, 0.1, WOOD_DARK)
	sm.part(1, 0.25, StagedMesh.MODE_POP, Vector3(0, h, 0), StagedMesh.CLS_WOOD)
	sm.beam(Vector3(-hw * 0.65, h, 0), Vector3(hw * 0.65, h, 0), 0.09, 0.09, WOOD_DARK)
	for k in 6:
		var a := TAU * float(k) / 6.0 + 0.5
		var p := Vector3(sin(a) * (hw + 0.9), 0, cos(a) * (hd + 0.8))
		sm.part(1, 0.35 + 0.05 * float(k), StagedMesh.MODE_RISE, p, StagedMesh.CLS_WOOD)
		sm.beam(p, Vector3(sin(a) * (hw + 0.5), 1.9, cos(a) * (hd + 0.4)), 0.06, 0.06, WOOD)
	for k in 14:
		var a := TAU * float(k) / 14.0
		var stake := Vector3(sin(a) * (hw + 2.5), 0.3, cos(a) * (hd + 2.2))
		var top := Vector3(sin(a) * hw * 0.9, 1.6, cos(a) * hd * 0.85)
		sm.part(1, 0.65 + 0.02 * float(k), StagedMesh.MODE_STRIP, Vector3.ZERO, StagedMesh.CLS_ROPE)
		sm.ribbon(PackedVector3Array([top, stake]), PackedVector3Array([Vector3.UP, Vector3.UP]), 0.025, Color("#8a6a3a"), true)
	# 2 örtü: iki yamuk yarı (eğimli dam), yanlar; ortada yarık (duman).
	for side: float in [-1.0, 1.0]:
		sm.part(2, 0.1 + (0.4 if side > 0.0 else 0.0), StagedMesh.MODE_RISE, Vector3(0, h, 0), StagedMesh.CLS_FELT)
		var nrm := Vector3(0, hd, side * (h - 1.0)).normalized()
		var a := sm.vertex(StagedMesh.THIN, Vector3(-hw, 1.0, side * hd), nrm, black)
		var b := sm.vertex(StagedMesh.THIN, Vector3(hw, 1.0, side * hd), nrm, black)
		var c := sm.vertex(StagedMesh.THIN, Vector3(hw * 0.65, h - 0.05, side * 0.18), nrm, black.lightened(0.06))
		var d := sm.vertex(StagedMesh.THIN, Vector3(-hw * 0.65, h - 0.05, side * 0.18), nrm, black.lightened(0.06))
		if side > 0.0:
			sm.quad(StagedMesh.THIN, a, d, c, b)
		else:
			sm.quad(StagedMesh.THIN, a, b, c, d)
		# Yan duvar (alçak).
		var e := sm.vertex(StagedMesh.THIN, Vector3(-hw, 0.0, side * hd), Vector3(0, 0, side), black.darkened(0.1))
		var f := sm.vertex(StagedMesh.THIN, Vector3(hw, 0.0, side * hd), Vector3(0, 0, side), black.darkened(0.1))
		var g := sm.vertex(StagedMesh.THIN, Vector3(hw, 1.0, side * hd), Vector3(0, 0, side), black)
		var hh := sm.vertex(StagedMesh.THIN, Vector3(-hw, 1.0, side * hd), Vector3(0, 0, side), black)
		if side > 0.0:
			sm.quad(StagedMesh.THIN, e, hh, g, f)
		else:
			sm.quad(StagedMesh.THIN, e, f, g, hh)
	for s: float in [-1.0, 1.0]:
		sm.part(2, 0.85, StagedMesh.MODE_RISE, Vector3(s * hw, 0, 0), StagedMesh.CLS_FELT)
		var pts := [Vector3(s * hw, 0, -hd), Vector3(s * hw, 0, hd), Vector3(s * hw, 1.0, hd), Vector3(s * hw * 0.65, h - 0.05, 0.18), Vector3(s * hw * 0.65, h - 0.05, -0.18), Vector3(s * hw, 1.0, -hd)]
		var ids := PackedInt32Array()
		for p: Vector3 in pts:
			ids.append(sm.vertex(StagedMesh.THIN, p, Vector3(s, 0.3, 0).normalized(), black.darkened(0.05)))
		var tris := [[0, 1, 2], [0, 2, 5], [5, 2, 3], [5, 3, 4]]
		for t: Array in tris:
			if s > 0.0:
				sm.tri(StagedMesh.THIN, ids[t[0]], ids[t[1]], ids[t[2]])
			else:
				sm.tri(StagedMesh.THIN, ids[t[0]], ids[t[2]], ids[t[1]])


# --- Ulu Ocak ve küçük yapılar ---------------------------------------------------------------------------------

## Ulu Ocak (r 12 m meydan): ezik zemin, iri taş halka, dört oturak kütüğü ve keçe minderler (ateşi Campfire'dır).
static func _great_hearth(sm: StagedMesh) -> void:
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_STONE)
	for k in 12:
		var a := TAU * float(k) / 12.0
		sm.blob(Vector3(sin(a) * 1.45, 0.0, cos(a) * 1.45), Vector3(0.32, 0.26, 0.26), 200 + k, STONE.lightened(0.04 * float(k % 3)), 1)
	sm.disc(Vector3(0, 0.02, 0), 1.3, 16, Color("#2a1e18"))
	for k in 4:
		var a := TAU * float(k) / 4.0 + 0.4
		var c := Vector3(sin(a) * 4.6, 0.0, cos(a) * 4.6)
		var tdir := Vector3(cos(a), 0, -sin(a)) * 1.3
		sm.log_between(c - tdir + Vector3(0, 0.2, 0), c + tdir + Vector3(0, 0.2, 0), 0.2, 8, WOOD.darkened(0.06 * float(k % 2)))
		var m := Vector3(sin(a + 0.8) * 4.4, 0.0, cos(a + 0.8) * 4.4)
		sm.box(Transform3D(Basis(Vector3.UP, a + 0.8), m + Vector3(0, 0.05, 0)), Vector3(1.3, 0.1, 0.8), [Color("#7a2822"), Color("#2f4860"), Color("#6b2130"), Color("#c9a24f")][k])


static func _count_stone(sm: StagedMesh) -> void:
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_STONE)
	sm.blob(Vector3.ZERO, Vector3(0.45, 1.05, 0.3), 501, Color("#7a766e"), 1)
	# Çentikler: on ikişerli sıralar (sayım).
	for row in 3:
		for k in 10:
			var x := -0.2 + float(k) * 0.045
			sm.box(Transform3D(Basis.IDENTITY, Vector3(x, 0.85 + 0.22 * float(row), 0.25)), Vector3(0.012, 0.13, 0.02), Color("#3a3430"))
	for k in 3:
		var a := TAU * float(k) / 3.0 + 0.6
		sm.blob(Vector3(sin(a) * 0.95, 0, cos(a) * 0.95), Vector3(0.22, 0.18, 0.2), 510 + k, STONE)


static func _work_board(sm: StagedMesh) -> void:
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_WOOD)
	for s: float in [-0.8, 0.8]:
		StructureCatalog._post(sm, Vector3(s, 0, 0), 2.1, 0.14, WOOD_DARK)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 1.45, 0.05)), Vector3(1.8, 0.95, 0.06), WOOD_LIGHT)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 2.0, 0.05)), Vector3(1.95, 0.12, 0.16), WOOD_DARK)
	# Asılı çetele çubukları (işler).
	for k in 7:
		var x := -0.7 + float(k) * 0.23
		sm.box(Transform3D(Basis(Vector3.BACK, 0.05 * float(k % 3) - 0.05), Vector3(x, 1.4, 0.11)), Vector3(0.05, 0.42, 0.03), Color("#d8c8a0").darkened(0.08 * float(k % 2)))
		sm.box(Transform3D(Basis.IDENTITY, Vector3(x, 1.68, 0.1)), Vector3(0.03, 0.03, 0.06), Color("#3a3634"))
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0.95, 1.95, 0.08)), Vector3(0.3, 0.2, 0.02), Color("#6b2130"))


## Mutfak Kazanı ve kurutma sırıkları (act1.md: kazan (20,14), sırıklar (26,20): yerel (6, 6)).
static func _kitchen(sm: StagedMesh) -> void:
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_STONE)
	for k in 6:
		var a := TAU * float(k) / 6.0
		sm.blob(Vector3(sin(a) * 0.75, 0, cos(a) * 0.75), Vector3(0.24, 0.24, 0.2), 600 + k, STONE)
	sm.disc(Vector3(0, 0.02, 0), 0.7, 12, Color("#2a1e18"))
	var prof := PackedVector2Array([Vector2(0.18, 0.35), Vector2(0.55, 0.42), Vector2(0.68, 0.62), Vector2(0.64, 0.86), Vector2(0.58, 0.92)])
	sm.lathe(prof, 16, 0.0, TAU, Color("#3a3634"), StagedMesh.SOLID)
	sm.disc(Vector3(0, 0.84, 0), 0.6, 14, Color("#8a6a4a"))
	for k in 3:
		var a := TAU * float(k) / 3.0 + 0.3
		sm.beam(Vector3(sin(a) * 1.1, 0, cos(a) * 1.1), Vector3(0, 2.1, 0), 0.07, 0.07, WOOD_DARK)
	sm.beam(Vector3(0, 2.1, 0), Vector3(0, 0.95, 0), 0.02, 0.02, Color("#3a3634"))
	# Odun ve kepçe, kâseler.
	sm.log_between(Vector3(1.2, 0.08, -0.6), Vector3(1.9, 0.08, -0.2), 0.08, 6, WOOD)
	sm.log_between(Vector3(1.3, 0.2, -0.5), Vector3(1.95, 0.2, -0.1), 0.08, 6, WOOD.darkened(0.08))
	# Kurutma sırıkları: (6, 6) yerel, iki sıra, asılı et ve ot.
	for row in 2:
		var z := 6.0 + float(row) * 1.6
		for s: float in [-1.0, 1.0]:
			sm.beam(Vector3(6.0 + s * 1.6, 0, z), Vector3(6.0 + s * 1.6, 1.9, z), 0.08, 0.08, WOOD)
		sm.beam(Vector3(4.2, 1.85, z), Vector3(7.8, 1.85, z), 0.06, 0.06, WOOD_LIGHT)
		for k in 7:
			var x := 4.6 + float(k) * 0.45
			var hues: Array[Color] = [Color("#7a3b26"), Color("#8a4a2a"), Color("#a58a3f"), Color("#7c9a3a")]
			var c: Color = hues[(k + row) % 4]
			sm.box(Transform3D(Basis.IDENTITY, Vector3(x, 1.55, z)), Vector3(0.12, 0.55, 0.05), c)


static func _woodpile(sm: StagedMesh) -> void:
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_WOOD)
	for row in 4:
		var n := 6 - row
		for k in n:
			var x := (float(k) - float(n - 1) * 0.5) * 0.4
			sm.log_between(Vector3(-1.5, 0.14 + 0.24 * float(row), x * 0.0 + (float(k) - float(n - 1) * 0.5) * 0.25), Vector3(1.5, 0.14 + 0.24 * float(row), (float(k) - float(n - 1) * 0.5) * 0.25), 0.13, 7, WOOD.darkened(0.04 * float((k + row) % 3)))
	# Kesme kütüğü ve balta.
	sm.cylinder(Vector3(2.2, 0, 0.6), 0.32, 0.3, 0.55, 10, WOOD_LIGHT)
	sm.beam(Vector3(2.2, 0.55, 0.6), Vector3(2.45, 1.15, 0.7), 0.04, 0.04, WOOD_DARK)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(2.2, 0.58, 0.6)), Vector3(0.18, 0.08, 0.06), Color("#6a6a6a"))
	for k in 8:
		sm.box(Transform3D(Basis(Vector3.UP, float(k)), Vector3(1.9 + 0.12 * float(k % 4), 0.03, 1.1 + 0.1 * float(k / 4))), Vector3(0.2, 0.04, 0.08), WOOD_LIGHT)


static func _latrine(sm: StagedMesh) -> void:
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_WOOD)
	sm.disc(Vector3(0, 0.01, 0), 0.5, 10, Color("#2a241e"))
	for s: float in [-0.25, 0.25]:
		sm.box(Transform3D(Basis.IDENTITY, Vector3(s, 0.05, 0)), Vector3(0.2, 0.08, 1.2), WOOD)
	# Örgü perde: üç yanı.
	var walls := [[Vector3(-1.05, 0, -0.8), Vector3(1.05, 0, -0.8)], [Vector3(-1.05, 0, -0.8), Vector3(-1.05, 0, 0.8)], [Vector3(1.05, 0, -0.8), Vector3(1.05, 0, 0.8)]]
	for w: Array in walls:
		var a: Vector3 = w[0]
		var b: Vector3 = w[1]
		sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_REED, {"pattern": 9})
		sm.box(Transform3D(Basis(Vector3.UP, atan2(b.x - a.x, b.z - a.z)), (a + b) * 0.5 + Vector3(0, 0.8, 0)), Vector3(0.06, 1.6, a.distance_to(b)), THATCH.darkened(0.1))
		sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_WOOD)
		for p: Vector3 in [a, b]:
			StructureCatalog._post(sm, p, 1.8, 0.08, WOOD_DARK)


static func _watch_fire(sm: StagedMesh) -> void:
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_STONE)
	for k in 7:
		var a := TAU * float(k) / 7.0
		sm.blob(Vector3(sin(a) * 0.5, 0, cos(a) * 0.5), Vector3(0.15, 0.13, 0.13), 700 + k, STONE)
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_GLOW)
	sm.disc(Vector3(0, 0.03, 0), 0.38, 10, Color("#ff7a2a"))
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_WOOD)
	for k in 3:
		var a := TAU * float(k) / 3.0
		sm.log_between(Vector3(sin(a) * 0.4, 0.06, cos(a) * 0.4), Vector3(sin(a + PI) * 0.1, 0.18, cos(a + PI) * 0.1), 0.05, 6, Color("#3a2618"))
	sm.log_between(Vector3(-0.8, 0.18, 1.3), Vector3(0.8, 0.18, 1.3), 0.17, 8, WOOD)


## Yeni Yurt pedi (Gün I seçimi): sekiz kazık, ip halkası, üç taş: aşama 0'ın görünüşü (şantiye açılınca yerine yurt gelir).
static func _yurt_pad(sm: StagedMesh) -> void:
	var r := 3.75
	var pts := PackedVector3Array()
	var nrms := PackedVector3Array()
	for k in 8:
		var a := TAU * float(k) / 8.0 + 0.2
		var p := Vector3(sin(a) * r, 0, cos(a) * r)
		sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_WOOD)
		sm.beam(p + Vector3(0, -0.05, 0), p + Vector3(0, 0.5, 0), 0.05, 0.05, WOOD)
		pts.append(p + Vector3(0, 0.36, 0))
		nrms.append(Vector3(p.x, 0, p.z).normalized())
	pts.append(pts[0])
	nrms.append(nrms[0])
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_ROPE)
	sm.ribbon(pts, nrms, 0.022, Color("#c8b48a"))
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_STONE)
	for k in 3:
		sm.blob(Vector3(0.3 * float(k) - 0.3, 0, 0.25), Vector3(0.13, 0.12, 0.11), 800 + k, STONE)


## Kapı: iki direk, kiriş, iki kanat (ağıl ve Esir Çukuru); en w m.
static func _gate(sm: StagedMesh, w: float) -> void:
	for s: float in [-1.0, 1.0]:
		sm.part(0, 0.2, StagedMesh.MODE_RISE, Vector3(s * w * 0.5, 0, 0), StagedMesh.CLS_WOOD)
		StructureCatalog._post(sm, Vector3(s * w * 0.5, 0, 0), 2.3, 0.2, WOOD_DARK)
	sm.part(0, 0.5, StagedMesh.MODE_POP, Vector3(0, 2.2, 0), StagedMesh.CLS_WOOD)
	sm.beam(Vector3(-w * 0.5 - 0.3, 2.25, 0), Vector3(w * 0.5 + 0.3, 2.25, 0), 0.16, 0.16, WOOD_DARK)
	for s: float in [-1.0, 1.0]:
		sm.part(1, 0.3 + (0.3 if s > 0.0 else 0.0), StagedMesh.MODE_RISE, Vector3(s * w * 0.25, 0, 0), StagedMesh.CLS_WOOD)
		for k in 3:
			var y := 0.3 + float(k) * 0.42
			sm.beam(Vector3(s * 0.05, y, 0.05), Vector3(s * (w * 0.5 - 0.1), y, 0.05), 0.07, 0.09, WOOD)
		sm.beam(Vector3(s * 0.05, 0.25, 0.06), Vector3(s * (w * 0.5 - 0.1), 1.2, 0.06), 0.06, 0.07, WOOD_LIGHT)


## Fener direği (act1.md «lantern»; sq_lamp_oil): direk, kol, asılı fener (gece parıltısı CLS_GLOW; gerçek ışık yok).
static func _lantern(sm: StagedMesh) -> void:
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_WOOD)
	StructureCatalog._post(sm, Vector3.ZERO, 2.4, 0.12, WOOD_DARK)
	sm.beam(Vector3(0, 2.3, 0), Vector3(0, 2.3, 0.55), 0.06, 0.06, WOOD_DARK)
	sm.beam(Vector3(0, 2.3, 0.5), Vector3(0, 2.05, 0.5), 0.015, 0.015, Color("#3a3634"))
	sm.cylinder(Vector3(0, 1.8, 0.5), 0.1, 0.08, 0.25, 6, Color("#5a4632"))
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_GLOW)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 1.92, 0.5)), Vector3(0.13, 0.13, 0.13), Color("#ffb060"))
	for k in 3:
		var a := TAU * float(k) / 3.0
		sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_STONE)
		sm.blob(Vector3(sin(a) * 0.22, 0, cos(a) * 0.22), Vector3(0.12, 0.1, 0.1), 900 + k, STONE)


## Dokuz şeritli kara bez (Esir Çukuru'nun kuzey çitinde; Hunların Kara Nama'sı, story.md §9): iki direk arasında.
static func _black_cloth(sm: StagedMesh) -> void:
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_WOOD)
	for s: float in [-1.1, 1.1]:
		StructureCatalog._post(sm, Vector3(s, 0, 0), 2.0, 0.1, WOOD_DARK)
	sm.beam(Vector3(-1.15, 1.9, 0.0), Vector3(1.15, 1.9, 0.0), 0.05, 0.05, WOOD_DARK)
	sm.part(0, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_FELT)
	for k in 9:
		var x := (float(k) - 4.0) * 0.22
		var c := Color("#1e1a18") if k % 2 == 0 else Color("#3a3230")
		sm.box(Transform3D(Basis.IDENTITY, Vector3(x, 1.3, 0.04)), Vector3(0.2, 1.1 - 0.06 * float(k % 3), 0.02), c)


## Örgü çit panosu (2,2 m; ağıl ve çukur çiti; örnekli): iki kazık, sık örgü (ince yüzey). broken: kırık pano (çit deliği).
static func wattle_panel(broken: bool = false) -> ArrayMesh:
	var key := "wattle|%s" % broken
	if _cache.has(key):
		return _cache[key]
	var sm := StagedMesh.new()
	sm.part(1, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_WOOD)
	for s: float in [-1.1, 1.1]:
		sm.beam(Vector3(s, -0.05, 0), Vector3(s, 1.25 if not broken or s < 0.0 else 0.6, 0), 0.08, 0.08, WOOD_DARK)
	sm.part(1, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_REED)
	var rows := 5 if not broken else 2
	for k in rows:
		var y := 0.18 + float(k) * 0.2
		var pts := PackedVector3Array()
		var nrms := PackedVector3Array()
		for j in 7:
			var t := float(j) / 6.0
			pts.append(Vector3(lerpf(-1.1, 1.1, t), y, 0.04 * sin(t * PI * 3.0 + float(k))))
			nrms.append(Vector3(0, 0, 1))
		sm.ribbon(pts, nrms, 0.15, Color("#6a5842").darkened(0.06 * float(k % 2)))
	var m := sm.commit()
	_cache[key] = m
	return m
