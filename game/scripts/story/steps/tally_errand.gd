class_name TallyErrand
extends RefCounted
## «Ebenin Çetelesi»nin envanter yolu (saf; Çocukluk, 21 Eylül MÖ 228; K110, story.md §5 «İki yeni gün»): Lan Hatun'un kurut torbası
## heybeye girer, Hereka'ya verilince düşer; Hereka'nın yedi çentikli çetelesi heybeye girer, 22 Eylül'ün sayımında sayıcıya verilince
## düşer («Hereka'nın çentikleri. Yedi.»). Eşyalar data/economy/items.json'dadır (görevlik: Görevlik sekmesi, bırakılmaz); çetelenin
## simgesi kodla çizilir (HudItemIcon «tally», satırın notches'ı kadar çentik), elde görünen çubuğu TallyStick'tir (tally_stick.gd).
##   TallyErrand.give_curd(inv)    # Lan Hatun: «Bu kurutu Hereka Ebe'ye götür»
##   TallyErrand.hand_curd(inv)    # Hereka'ya verildi
##   TallyErrand.take_stick(inv)   # «Al. Yedi çentik»
##   TallyErrand.has_stick(inv)    # sayım günü: sayıcı count_stick'i söyler mi?
##   TallyErrand.give_stick(inv)   # sayıcıya verildi

const CURD := "qurt_gift"
const STICK := "tally_hereka"
## Çetelenin çentikleri (bu yıl Ebe Obası'nda doğanlar).
const NOTCHES := 7
const SOURCE := "story"


## Kurut torbası heybeye (zaten varsa ikincisi verilmez). Döner: heybede var mı.
static func give_curd(inv: Inventory) -> bool:
	if inv == null:
		return false
	if not inv.has(CURD):
		inv.add(CURD, 1, SOURCE, true)
	return inv.has(CURD)


## Kurut Hereka'ya verildi: heybeden düşer. Döner: verildi mi (heybede yoksa false: ceza yok, söz yine akar).
static func hand_curd(inv: Inventory) -> bool:
	if inv == null or not inv.has(CURD):
		return false
	return not inv.remove(CURD, 1).is_empty()


## Hereka'nın çetelesi heybeye (zaten varsa ikincisi verilmez). Döner: heybede var mı.
static func take_stick(inv: Inventory) -> bool:
	if inv == null:
		return false
	if not inv.has(STICK):
		inv.add(STICK, 1, SOURCE, true)
	return inv.has(STICK)


static func has_stick(inv: Inventory) -> bool:
	return inv != null and inv.has(STICK)


static func has_curd(inv: Inventory) -> bool:
	return inv != null and inv.has(CURD)


## Çetele sayıcıya verildi: heybeden düşer. Döner: verildi mi.
static func give_stick(inv: Inventory) -> bool:
	if inv == null or not inv.has(STICK):
		return false
	return not inv.remove(STICK, 1).is_empty()


## Çetelenin çentik sayısı (satırın notches'ı; yoksa NOTCHES).
static func notches() -> int:
	return int(ItemCatalog.row(STICK).get("notches", NOTCHES))
