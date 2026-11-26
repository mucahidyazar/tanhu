class_name GroundPile
extends Procedural3D
## Yer yığını (economy.md §4.5 «Yer Yığını»: sınırsız, dünyada en çok 24): bırakılan ya da sığmayan eşya oyuncunun ayağının dibinde
## bağlı bir torba olur. İçerik Inventory'nin yığın kabındadır (pile: ItemContainer); düğüm yalnız görünüştür. Oyuncu E ile alır:
## yerdeki hedefin sözleşmesi (PlayerController.pickup_in_reach: «fallen_game» grubu, is_down, collect) aynen işler; collect
## {kind: "ground_pile", pile} döndürür, HudBag.on_collected sığdığı kadar heybeye alır, boşalan yığını Inventory kaldırır (düğüm
## silinir). Yığın büyüdükçe torba bir kademe büyür (en çok üç torba). Kodla çizilir: lathe torba, ağzı bağlı, açık keçe rengi.

const KIND := "ground_pile"
const GROUP := &"fallen_game"
## Torbanın profili (yarıçap, yükseklik; m) ve rengi.
const PROFILE := [Vector2(0.0, 0.0), Vector2(0.15, 0.015), Vector2(0.21, 0.09), Vector2(0.2, 0.19), Vector2(0.13, 0.27), Vector2(0.06, 0.3),
	Vector2(0.075, 0.335), Vector2(0.05, 0.37), Vector2(0.0, 0.375)]
## Açık keçe torba, koyu bağ: otta da patikada da okunur (kahverengi torba patikanın toprağında kayboluyordu).
const SACK := Color("#cdbb96")
const CORD := Color("#5a3a24")
## Uzak kadrajda (28 m, K98) okunsun diye torba gerçek boyunun biraz üstündedir.
const SCALE := 1.35
## Torbanın vurulma yarıçapı (yerdeki hedefin erimi için).
var hit_radius := 0.35
var pile: ItemContainer


func _ready() -> void:
	add_to_group(GROUP)
	super._ready()


## İçerik değişti: torba sayısı yeniden kurulur.
func refresh() -> void:
	queue_rebuild()


func is_down() -> bool:
	return pile != null and not pile.is_empty()


func is_hittable() -> bool:
	return false


func hit_center() -> Vector3:
	return global_position + Vector3(0.0, 0.18, 0.0)


## Oyuncu aldı (PlayerController._finish_collect): içerik HudBag.on_collected'ta heybeye geçer.
func collect() -> Dictionary:
	return {"kind": KIND, "pile": pile}


## Kaç torba: Yük'e göre 1–3.
func sacks() -> int:
	if pile == null:
		return 1
	var l := pile.load_amount()
	return 1 if l < 4.0 else (2 if l < 12.0 else 3)


func _build() -> void:
	var mesh := MeshKit.lathe(PackedVector2Array(PROFILE), 14)
	var mat := Style.toon(SACK)
	var cord := Style.toon(CORD)
	var spots: Array = [Vector3.ZERO, Vector3(0.28, 0.0, 0.12), Vector3(-0.12, 0.0, 0.27)]
	for i in sacks():
		var xf := Transform3D(Basis(Vector3.UP, 0.7 * i).scaled(Vector3.ONE * (1.0 - 0.12 * i) * SCALE), (spots[i] as Vector3) * SCALE)
		add_mesh(mesh, mat, xf)
		add_mesh(Procedural3D.torus(0.05, 0.075), cord, xf * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.3, 0.0)))
