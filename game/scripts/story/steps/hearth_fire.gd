class_name HearthFire
extends RefCounted
## «Ocak»ın ateşi (saf; Önsöz, K110; story.md §3 «Göl Obası'nda üç gün»; K108'in ateş kurma dili): menü ateşinin yerinde tipinin çatlattığı
## ocak boştur; üç taş üçgen dizilir («Üç taş. Hep üç.»), odun konur, ozanın verdiği ak taş kara taşa vurulur, kıvılcım kavı tutuşturur
## (K108: yakma 3–5 sn), ateş odunla beslendikçe evre evre büyür. Görünüşü HearthView'dur (hearth_view.gd); adımı hearth_build.gd sürer.
##
## Evreler (stage): 0 kav tutuştu, 1 küçük, 2 orta, 3 büyük (harlandı). Her evrede ışığın yarıçapı genişler (≈2, 4, 7, 10 m; RADII), alevin
## boyu, kıvılcım ve duman büyür. Görünüş evreye yumuşakça yetişir (stage_f, GROW_S). Büyük evrede ateş bir an parlar (harlama), sonra
## menü ateşinin ölçüsüne oturur (settle): ışık 10 m'den menünün 8 m'sine, enerjisi menününkine iner; oturan ateş menünün ateşidir
## (Camp/Campfire; menü karesi değişmez, test_main_menu). Tutuşma: ilk vuruştan sonra kindle_s (tohumla 3–5 sn) dolunca gelen ilk vuruş
## kavı tutuşturur; arada kav için için tüter (smolder). Ceza yoktur: vurmayı bırakan oyuncunun kavı yavaşça söner, yeniden vurulur.
##   var f := HearthFire.new(seed)
##   f.place_stone() × 3; f.lay_wood(3)
##   f.strike(now)         # {spark, caught}
##   f.feed()              # bir evre büyür
##   f.tick(dt)            # stage_f, settle
##   HearthFire.light_radius(f.stage_f)

## Ocak taşlarının üçgeni: ateşin merkezinden uzaklık (m) ve açılar (derece; +X'ten, yukarıdan bakınca saat yönünün tersine).
const STONE_RADIUS := 0.46
const STONE_ANGLES: Array[float] = [90.0, 210.0, 330.0]
## Evrelerin eğrisi: ışığın yarıçapı (m; ≈2, 4, 7, 10), ışığın enerjisi, alevin ölçeği (1 = menü ateşi), kıvılcım sayısı, dumanın boyu.
const RADII: Array[float] = [2.0, 4.0, 7.0, 10.0]
const ENERGY: Array[float] = [1.0, 1.8, 2.7, 3.6]
const FLAME: Array[float] = [0.28, 0.52, 0.78, 1.0]
const SPARKS: Array[int] = [4, 10, 18, 24]
const SMOKE: Array[Vector2] = [Vector2(0.5, 1.4), Vector2(0.8, 2.1), Vector2(1.05, 2.7), Vector2(1.3, 3.2)]
## Menü ateşinin ölçüsü (scenes/world/world.tscn Camp/Campfire): oturan ateş buna iner.
const MENU_RANGE := 8.0
const MENU_ENERGY := 3.3
## Görünüşün evreye yetişme süresi (sn), harlamanın parlaması ve oturuş süresi (sn).
const GROW_S := 1.8
const FLARE_K := 1.35
const SETTLE_S := 1.6
## Tutuşmanın en kısa ve en uzun süresi (sn; K108), kavın tütmesinin vuruş başına artışı ve sönüşü (/sn).
const KINDLE_S := Vector2(3.0, 5.0)
const SMOLDER_PER_STRIKE := 0.22
const SMOLDER_DECAY := 0.12
## Kaç odun konur (yakmadan önce) ve kaçı beslenir: altı parçanın üçü kurulur, üçü üç evreyi büyütür.
const LAY_PIECES := 3

var stones := 0
var wood_laid := 0
var strikes := 0
var lit := false
var stage := -1
## Görünüşün evresi (yumuşak; -1 sönük, 0..3).
var stage_f := -1.0
## Kavın tütmesi [0, 1].
var smolder := 0.0
## İlk vuruşun anı (sn; tutuşma kindle_s sonra) ve bu ateşin tutuşma süresi.
var first_strike := -1.0
var kindle_s := 4.0
## Harlama: 0 yok, 1 parlıyor (büyük evre ilk geldiğinde), oturuşun ilerlemesi [0, 1].
var flare := 0.0
var settled := 0.0
var settling := false


func _init(seed_value: int = 1040) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	kindle_s = rng.randf_range(KINDLE_S.x, KINDLE_S.y)


## Taşın ateşe göre yeri (saf; yerel XZ, m).
static func stone_offset(index: int) -> Vector3:
	var a := deg_to_rad(STONE_ANGLES[clampi(index, 0, STONE_ANGLES.size() - 1)])
	return Vector3(cos(a) * STONE_RADIUS, 0.0, -sin(a) * STONE_RADIUS)


func stones_done() -> bool:
	return stones >= STONE_ANGLES.size()


## Bir taş dizer; dizilen taşın sırası (dolduysa -1).
func place_stone() -> int:
	if stones_done():
		return -1
	stones += 1
	return stones - 1


## Odun koyar (taşlar dizilmeden konmaz). Konan toplam.
func lay_wood(pieces: int = LAY_PIECES) -> int:
	if not stones_done() or lit:
		return wood_laid
	wood_laid = mini(wood_laid + maxi(pieces, 0), LAY_PIECES)
	return wood_laid


func ready_to_strike() -> bool:
	return stones_done() and wood_laid >= LAY_PIECES and not lit


## Ak taşı kara taşa vurur (now: sn). Her vuruş kıvılcımdır; kindle_s dolunca gelen vuruş kavı tutuşturur. {spark, caught}.
func strike(now: float) -> Dictionary:
	if not ready_to_strike():
		return {"spark": false, "caught": false}
	strikes += 1
	if first_strike < 0.0:
		first_strike = now
	smolder = minf(smolder + SMOLDER_PER_STRIKE, 1.0)
	var caught := now - first_strike >= kindle_s - 0.0001 and strikes >= 2
	if caught:
		lit = true
		stage = 0
		smolder = 0.0
	return {"spark": true, "caught": caught}


## Ateşi bir odunla besler: bir evre büyür (en çok büyük). Büyüdü mü?
func feed() -> bool:
	if not lit or stage >= RADII.size() - 1:
		return false
	stage += 1
	if stage == RADII.size() - 1:
		flare = 1.0
	return true


func is_full() -> bool:
	return lit and stage >= RADII.size() - 1


## Görünüş evreye yetişti mi (büyük evrede: alev tam boyda)?
func grown() -> bool:
	return lit and stage_f >= float(stage) - 0.02


## Harlanan ateşi menü ateşinin ölçüsüne oturtmaya başlar (sinemaya geçişle; SETTLE_S sürer).
func begin_settle() -> void:
	if is_full():
		settling = true


func tick(dt: float) -> void:
	if lit:
		stage_f = move_toward(stage_f if stage_f >= 0.0 else 0.0, float(stage), dt / GROW_S)
	else:
		smolder = maxf(smolder - SMOLDER_DECAY * dt, 0.0)
		# Vuruş arası uzun beklemede kav söner: tutuşma yeniden sayılır.
		if smolder <= 0.0 and first_strike >= 0.0:
			first_strike = -1.0
			strikes = 0
	flare = maxf(flare - dt / 0.9, 0.0)
	if settling:
		settled = minf(settled + dt / SETTLE_S, 1.0)


# --- Eğriler (saf) -------------------------------------------------------------------------------------

## Işığın yarıçapı (m): evreler arasında doğrusal, sönükken 0.
static func light_radius(sf: float) -> float:
	return _curve(RADII, sf)


static func light_energy(sf: float) -> float:
	return _curve(ENERGY, sf)


static func flame_scale(sf: float) -> float:
	return _curve(FLAME, sf)


static func spark_count(sf: float) -> int:
	if sf < 0.0:
		return 0
	return SPARKS[clampi(int(round(sf)), 0, SPARKS.size() - 1)]


static func smoke_size(sf: float) -> Vector2:
	if sf < 0.0:
		return Vector2.ZERO
	var i := clampi(int(floor(sf)), 0, SMOKE.size() - 1)
	var j := mini(i + 1, SMOKE.size() - 1)
	return SMOKE[i].lerp(SMOKE[j], clampf(sf - float(i), 0.0, 1.0))


## Işığın o anki menzili ve enerjisi (harlama ve oturuşla): {range, energy}.
func light_now() -> Dictionary:
	var r := HearthFire.light_radius(stage_f)
	var e := HearthFire.light_energy(stage_f) * (1.0 + (FLARE_K - 1.0) * flare)
	if settling:
		var k := smoothstep(0.0, 1.0, settled)
		r = lerpf(r, MENU_RANGE, k)
		e = lerpf(e, MENU_ENERGY, k)
	return {"range": r, "energy": e}


static func _curve(values: Array, sf: float) -> float:
	if sf < 0.0:
		return 0.0
	var i := clampi(int(floor(sf)), 0, values.size() - 1)
	var j := mini(i + 1, values.size() - 1)
	return lerpf(float(values[i]), float(values[j]), clampf(sf - float(i), 0.0, 1.0))
