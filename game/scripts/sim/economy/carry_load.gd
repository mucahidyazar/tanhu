class_name CarryLoad
extends RefCounted
## Yük'ün kuralları (saf, statik; economy.md §4.1, §4.7; progression.md §2.3 loadMax, loadMul, mountLoadK). Sayılar
## data/economy/containers.json «carry»dadır.
##   CarryLoad.cap_of(3, false, 0.0)         # 21: 12 + 3 × Bilek (+ Sırt Yükü 8 + kuşak)
##   CarryLoad.speed_k(0.5)                  # 0,85: 1 − 0,3 × doluluk; Sırt Yükü ile (slow_from 0,5) yarıya dek 1
##   CarryLoad.can_run(0.8), can_jump(0.6)   # false, false: koşu ≤ 0,75, zıplama ≤ 0,5
##   CarryLoad.mount_speed_k(1.0)            # 0,85: terki yarısına dek ×1, üstünde 1 − 0,3 × (l − 0,5)


## «carry» bölümü.
static func rules() -> Dictionary:
	var c: Variant = ItemContainer.rules().get("carry", {})
	return c if c is Dictionary else {}


static func _num(key: String, fallback: float) -> float:
	var v: Variant = rules().get(key, fallback)
	return float(v) if v is int or v is float else fallback


## Heybenin sınırı (Yük): 12 + 3 × Bilek + Sırt Yükü (8) + kuşak ve öteki giyim (gear.load).
static func cap_of(grip: float, carry_pack: bool, gear_load: float) -> float:
	return _num("base", 12.0) + _num("per_grip", 3.0) * grip + (_num("carry_pack", 8.0) if carry_pack else 0.0) + gear_load


## Doluluk: Yük / sınır (sınır 0 iken yük varsa 1).
static func frac(load_amount: float, cap: float) -> float:
	if cap > 0.0:
		return load_amount / cap
	return 1.0 if load_amount > 0.0 else 0.0


## Hız çarpanı: 1 − 0,3 × clamp((l − s) / (1 − s), 0, 1); yarıda 0,85, tamda 0,7; Sırt Yükü (s 0,5) yarıya dek 1. Sınırı aşan yük
## 0,7'nin altına düşürmez. Kızak sürüklenirken ayrıca ×0,9.
static func speed_k(load_frac: float, slow_from := 0.0, sled := false) -> float:
	var l := clampf(load_frac, 0.0, 1.0)
	var s := clampf(slow_from, 0.0, 0.99)
	var k := 1.0 - _num("slow_k", 0.3) * clampf((l - s) / (1.0 - s), 0.0, 1.0)
	return k * _num("sled_k", 0.9) if sled else k


static func can_run(load_frac: float) -> bool:
	return load_frac <= _num("run_frac", 0.75) + 1e-9


static func can_jump(load_frac: float) -> bool:
	return load_frac <= _num("jump_frac", 0.5) + 1e-9


## Koşunun takat gideri çarpanı: 1 + doluluk (tam yükte ×2).
static func run_cost_k(load_frac: float) -> float:
	return 1.0 + _num("run_cost_k", 1.0) * clampf(load_frac, 0.0, 1.0)


## Sırttaki yığının kademesi 0–5 (doluluk 0,1 / 0,3 / 0,5 / 0,75 / 1; Mete öne eğilir).
static func back_stage(load_frac: float) -> int:
	var stage := 0
	for t: Variant in rules().get("back_stages", [0.1, 0.3, 0.5, 0.75, 1.0]):
		if load_frac >= float(t) - 1e-9:
			stage += 1
	return stage


## Binek yükünün hız çarpanı (l = terki / binek Yük'ü): yarısına dek 1, üstünde 1 − 0,3 × (l − 0,5); dolu terkide 0,85.
static func mount_speed_k(load_frac: float) -> float:
	var l := clampf(load_frac, 0.0, 1.0)
	var free := _num("mount_free", 0.5)
	return 1.0 if l <= free else 1.0 - _num("mount_slow_k", 0.3) * (l - free)


## Dörtnal: terkinin dörtte üçüne dek.
static func can_gallop(load_frac: float) -> bool:
	return load_frac <= _num("gallop_frac", 0.75) + 1e-9


## Bedenin sabit sınırı (Yük; çocuk 6) ya da -1 (yetişkin: formül).
static func body_cap(body: String) -> float:
	var b: Variant = (ItemContainer.rules().get("bodies", {}) as Dictionary).get(body, {})
	var c: Variant = (b as Dictionary).get("cap") if b is Dictionary else null
	return float(c) if c is int or c is float else -1.0


## Binek Yük'ü: data/fauna/mounts.json satırının load'u, yoksa containers.json mount_load (I.–VI. Perde bineklerinin yedeği), o da yoksa 0.
static func mount_cap(mount_id: String) -> float:
	var row := Mount.row_of(mount_id)
	if row.has("load"):
		return float(row["load"])
	var table: Variant = ItemContainer.rules().get("mount_load", {})
	return float((table as Dictionary).get(mount_id, 0.0)) if table is Dictionary else 0.0


## Araba ve yük hayvanının sınırı (Yük; bilinmeyen 0).
static func cart_cap(cart_id: String) -> float:
	var table: Variant = ItemContainer.rules().get("carts", {})
	return float((table as Dictionary).get(cart_id, 0.0)) if table is Dictionary else 0.0
