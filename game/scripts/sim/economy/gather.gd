class_name Gather
extends RefCounted
## Toplama (saf; economy.md §3.1, §3.3, §3.4, §3.7; godot.md §3 «Toplama»): düğüme vuruş ve tutuş, Tam Vuruş halkasının zamanlaması,
## stamina, araç kademesi, verim (önce Heybe, sığmazsa terki, sonra yer yığını: Inventory.receive), ikinci evre ve ikinci eylem, sıralı verim,
## gece gürültüsü, koşullu ve etkili düğümler. Prototipin game/gather.js'inin Godot'su; sayılar ve kurallar aynıdır (tests/fixtures/
## gathering.json). Girdi, ses ve görünüş sürücünündür (GatherLayer): bu sınıf yalnız durum ve sinyaldir.
##
## Kurallar (sayılar data/economy/node_kinds.json «gather»): vuruş süresi T = T0 / (1 + 0,06 × (Bilek − 3)) (strike_mul Derive'dan),
## stamina bitmişse ×1,5 ve halka kapalı; temas 0,72 T; Tam Vuruş halkası temasa ortalı, pencere 0,18 sn (clean_strike 0,30; zorluk
## strikeRing; Halka Yardımı Geniş ×1,5, Otomatik son vuruşu kendiliğinden tam yapar); pencerede yeni basış gerekir, basılı tutmak tam vuruş
## yapmaz, cezası da yoktur; tam vuruşun staminası yarımdır; +1 ürün yalnız hakkın son (altın) vuruşunda, %50 birikimle (zar yok),
## clean_strike ile kesin; her n'inci cevherde +1 (ore_nose). İlk halka yarım hızdadır (a1 §12). Tutuş: süre dolar, bırakınca sıfırlanır,
## ceza yok, stamina harcamaz. Hareket keser, vuruş ilerlemesi şafağa dek düğümde kalır. Toplamak XP vermez (Progression «gather» sıfır
## kaynaktır); Tam Vuruş becerisi (strikeWindow, cleanBonus) ve Cevher Burnu (oreBonusEvery) Progression.mods()'tan okunur.
##   var g := Gather.new(store, inventory)
##   g.mods = progression.mods                        # Callable: () -> Dictionary
##   g.begin(i, true)                                  # E'ye basıldı (tutuşta basılı kalmalı)
##   g.step(dt, pressed_now, held, moved)              # her kare

## Vuruş başladı: {index, T, window, gold, ring, contact_k, gesture, tool, cls}.
signal swing_started(info: Dictionary)
## Halka yargılandı (tam mı, Otomatik yardımla mı).
signal ring_judged(clean: bool, auto: bool)
## Vuruşun teması: {kind, cls, ore, tree, at, hits, need}.
signal struck(index: int, info: Dictionary)
## Tutuş başladı: {index, seconds, clip, alt}.
signal hold_started(info: Dictionary)
## Verim: info {clean, kind, to (kap → adet), piled, at}.
signal yielded(index: int, item_id: String, n: int, info: Dictionary)
## Düğümün bugünkü (ya da kalıcı) hakkı bitti: {tree, at}.
signal depleted(index: int, kind_id: String, info: Dictionary)
## Gece gürültüsü (yalnız karanlıkta): dünya noktası ve yarıçap (m).
signal noise_made(at: Vector2, radius: float)
## Başka sistemin işi (tuzak, ağ deliği, zula): use türün kimliği.
signal used(index: int, kind_id: String, use: String, alt: bool)
## Alınamayan iş: reason need_tool | load_full | pile, text oyuncunun dilinde.
signal refused(reason: String, text: String)
## İş bitti ya da kesildi (sürücü pozu bırakır).
signal stopped

enum State { IDLE, SWING, HOLD }

## K46 (#28): at üstünde toplanan düğümler (araç El, eylem ≤2 sn, eğilip alınan).
const MOUNT_KINDS: Array[String] = ["node_deadfall", "node_wormwood", "node_rosehip", "node_buckthorn", "node_herb_sleep", "node_dung"]
## At üstünde tutuş ×1,5 (knee_steer ile ×1).
const MOUNT_HOLD_K := 1.5
const HAND_TOOL := {"cls": "hand", "tier": 0, "gesture": "reach"}

var store: NodeStore
## Heybe: Inventory (receive, has_tool, count) ya da aynı yüzü taşıyan nesne.
var inventory: Object
## Beceri anahtarları: () -> Dictionary (Progression.mods). Verilmezse boş.
var mods: Callable
## Vuruş hızı (Derive.strikeMul: 1 + 0,06 × (Bilek − 3)) ve Ayak.
var strike_mul := 1.0
var foot := 3
## Takat: stamina ve stamina_max taşıyan nesne (Vitals). Bedel yüz üzerindendir, tavana oranlanır.
var stamina: Object
## Zorluğun halka çarpanı (difficulty.json strikeRing) ve Halka Yardımı (off, wide, auto).
var diff_k := 1.0
var assist := "off"
## İlk halka yarım hızda (a1 §12): doğruyken sonraki vuruş ×2 sürer ve bayrak düşer (sürücü kalıcı işarete yazar: ring_seen).
var first_ring := false
## Karanlık mı (güneş −6°'nin altında): () -> bool. Koşul: (ifade) -> bool. Verim çarpanı: (tür) -> k. Etkiler: (liste, kaynak) -> void.
## XP: (kaynak, opts) -> int (Progression.award). Yer yığınının noktası: (düğüm) -> Vector3.
var dark: Callable
var cond: Callable
var yield_k: Callable
var apply_fx: Callable
var award: Callable
var spill_at: Callable
## Taşmanın terkisi: () -> String (yakındaki ya da binilen bineğin terki anahtarı; "" yok). Verilmezse Inventory.near_mount.
var mount_key: Callable
## Oyuncunun dili, Çocuk mu, binekte mi (K46).
var lang := "tr"
var child := false
var riding := false

var state := State.IDLE
var index := -1
var alt_action := false
## Vuruşta geçen süre ve vuruşun süresi (sn), hakkın istediği vuruş.
var t := 0.0
var T := 0.0
var hits_need := 0
var contact_done := false
## Hakkı bitiren vuruşun verimi pencereyi bekliyor.
var pending := false
var judged := false
var clean := false
var gold := false
var auto_clean := false
var ring_on := false
var window := 0.18
var tool_id := ""
var tool_cls := "hand"
var hold_t := 0.0
var hold_s := 0.0
var driven := false
## Tam Vuruş +1 birikimi ve cevher hakkı sayacı.
var bonus_acc := 0.0
var ore_count := 0

var _yield_acc: Dictionary = {}
var _const: Dictionary = {}


func _init(p_store: NodeStore = null, p_inventory: Object = null) -> void:
	store = p_store
	inventory = p_inventory
	_const = NodeStore.constants()
	window = float(_const.get("window", 0.18))


# --- Saf hesaplar -----------------------------------------------------------------------------------------------------

static func c(key: String, fallback: Variant = 0.0) -> Variant:
	return NodeStore.constants().get(key, fallback)


## Vuruş süresi: T0 / strike_mul, yorgunken ×1,5.
static func strike_t(t0: float, p_strike_mul := 1.0, tired := false) -> float:
	return (t0 / maxf(0.1, p_strike_mul)) * (float(c("tiredK", 1.5)) if tired else 1.0)


## Tam Vuruş penceresi (sn): beceri (mods.strikeWindow; null ise 0,18), zorluk ve Halka Yardımı.
static func ring_window(skill: Variant = null, diff := 1.0, p_assist := "off") -> float:
	var base := float(skill) if skill is float or skill is int else float(c("window", 0.18))
	return base * diff * (float(c("wideK", 1.5)) if p_assist == "wide" else 1.0)


## Halka temas anına ortalıdır: |t − contactK·T| ≤ pencere / 2.
static func ring_judge(p_t: float, p_T: float, p_window: float, contact_k := -1.0) -> bool:
	var k := contact_k if contact_k >= 0.0 else float(c("contactK", 0.72))
	return absf(p_t - k * p_T) <= p_window / 2.0 + 1e-9


## Aracın kademesi vuruşu kısaltır (§3.3: tunç 5, demir 4); sabit araçta sayı aynıdır. En az 1.
static func strike_hits(row: Dictionary, p_tool_id: String) -> int:
	var base := int(row.get("hits", 1))
	if row.get("fixed") or row.get("tool") == null or str(row.get("tool", "")).is_empty() or p_tool_id.is_empty():
		return base
	var need := int(NodeStore.tool_row(str(row["tool"])).get("tier", 1))
	var have := int(NodeStore.tool_row(p_tool_id).get("tier", need))
	return maxi(1, base - maxi(0, have - need))


## Birikimli taban: k katsayısının kesirli payı türde birikir, zar yok (tezek ×0,5: iki haktan biri).
static func scaled(acc: Dictionary, key: String, n: int, k: float) -> int:
	if k == 1.0:
		return n
	var was := float(acc.get(key, 0.0))
	var now := was + n * k
	acc[key] = now
	return floori(now + 1e-9) - floori(was + 1e-9)


# --- Araç ve sunum ----------------------------------------------------------------------------------------------------------

func _mods() -> Dictionary:
	if child or not mods.is_valid():
		return {}
	var m: Variant = mods.call()
	return m if m is Dictionary else {}


func has_tool(p_tool_id: String) -> bool:
	if p_tool_id.is_empty():
		return true
	if NodeStore.tool_row(p_tool_id).get("fixed", false):
		return true
	if inventory == null:
		return false
	if inventory.has_method(&"has_tool") and bool(inventory.call(&"has_tool", p_tool_id)):
		return true
	return inventory.has_method(&"count") and int(inventory.call(&"count", p_tool_id)) > 0


## Satırın aracı: sabit araç, sahip olunan en iyi araç (aynı sınıf, kademesi yeterli), toolAlt ya da "" (el). Araç yoksa null.
func tool_for(row: Dictionary) -> Variant:
	if row.get("fixed"):
		return str(row["fixed"])
	var need_id: Variant = row.get("tool")
	if need_id == null or str(need_id).is_empty():
		return ""
	var need := NodeStore.tool_row(str(need_id))
	var best: Variant = null
	var tier := -1
	var tools: Dictionary = NodeStore.data().get("tools", {})
	for id: String in tools:
		var tool: Dictionary = tools[id]
		if tool.get("fixed", false) or str(tool.get("cls", "")) != str(need.get("cls", "")):
			continue
		if int(tool.get("tier", 0)) < int(need.get("tier", 0)) or int(tool.get("tier", 0)) <= tier:
			continue
		if not has_tool(id):
			continue
		best = id
		tier = int(tool.get("tier", 0))
	if best == null and row.get("toolAlt") and has_tool(str(row["toolAlt"])):
		best = str(row["toolAlt"])
	return best


func _cond(expr: Variant) -> bool:
	if expr == null or str(expr).is_empty():
		return true
	return cond.is_valid() and bool(cond.call(str(expr)))


## Düğümün şu anki eylemi: aracı varsa ikinci eylem (ağ), yoksa evrenin satırı.
func action_row(i: int) -> Dictionary:
	var row := store.row_of(i)
	var a: Variant = row.get("alt")
	if a is Dictionary and store.alt_left(i) > 0:
		var at: Variant = (a as Dictionary).get("tool")
		if at == null or str(at).is_empty() or has_tool(str(at)):
			return a
	return store.stage_of(i)


## Sunum: {label, hold (sn; 0 vuruş), enabled, deny, alt, row, verb}; sunulmuyorsa boş.
func offer(i: int) -> Dictionary:
	if store == null or not store.available(i):
		return {}
	var row := store.row_of(i)
	if not _cond(row.get("when")):
		return {}
	if child and not row.get("child", false):
		return {}
	if row.get("carry") is Dictionary:
		return {}
	var kind_id := store.kind_of(i)
	if riding and not MOUNT_KINDS.has(kind_id):
		return {}
	var st := action_row(i)
	var o := {"enabled": true, "deny": "", "alt": st == row.get("alt"), "row": st}
	o["label"] = Catalog.pick(st.get("prompt", row.get("prompt")), lang)
	var hold := float(st.get("holdS", 1.0)) if str(st.get("action", "hold")) == "hold" else 0.0
	if riding and hold > 0.0 and not _mods().get("rideGather", false):
		hold *= MOUNT_HOLD_K
	o["hold"] = hold
	var need: Variant = st.get("tool")
	if need != null and not str(need).is_empty() and tool_for(st) == null:
		o["enabled"] = false
		o["deny"] = need_tool_text(str(need))
	return o


## «Önce Tunç Balta gerek» (aracın adı eşya kataloğundan).
func need_tool_text(p_tool_id: String) -> String:
	return NodeStore.message("need_tool", lang, {"tool": ItemCatalog.name_of(p_tool_id, lang)})


## «Yük dolu» (data/economy/containers.json messages.pack_full).
static func pack_full_text(p_lang := "tr") -> String:
	var m: Variant = (ItemContainer.rules().get("messages", {}) as Dictionary).get("pack_full")
	return Catalog.pick(m, p_lang) if m != null else "Yük dolu"


# --- İş -------------------------------------------------------------------------------------------------------------------

## İşi başlatır (erişimde; yürümeyi sürücü yapar). driven: E basılı tutuluyor (tutuşta bırakmak sıfırlar). → başladı mı.
func begin(i: int, p_driven := true) -> bool:
	var o := offer(i)
	if o.is_empty():
		return false
	if not o["enabled"]:
		refused.emit("need_tool", str(o["deny"]))
		return false
	cancel()
	if float(o["hold"]) > 0.0:
		_start_hold(i, o, p_driven)
	else:
		_start_swing(i, o)
	return true


func is_busy() -> bool:
	return state != State.IDLE


## İşi keser: süren vuruşun hakkı bittiyse verimi verilir. Vuruş ilerlemesi düğümde kalır.
func cancel() -> void:
	var was := state
	if was == State.SWING and pending:
		_complete_charge()
	state = State.IDLE
	index = -1
	hold_t = 0.0
	ring_on = false
	if was != State.IDLE:
		stopped.emit()


## Bir kare. pressed: E'ye bu karede yeni basıldı; held: E basılı; moved: oyuncu yürüdü, zıpladı ya da bindi.
func step(dt: float, pressed := false, held := false, moved := false) -> void:
	if state == State.IDLE:
		return
	if store == null or moved or not store.available(index):
		cancel()
		return
	if state == State.SWING:
		_swing(dt, pressed, held)
	else:
		_hold(dt, held)


# --- Vuruş ------------------------------------------------------------------------------------------------------------------

func _sta_scale() -> float:
	return (float(stamina.get("stamina_max")) / 100.0) if stamina else 1.0


func _tired() -> bool:
	return stamina != null and float(stamina.get("stamina")) <= 0.0


func _start_swing(i: int, o: Dictionary) -> void:
	var row: Dictionary = o["row"]
	var tid: Variant = tool_for(row)
	tool_id = str(tid) if tid != null else ""
	var tool := NodeStore.tool_row(tool_id) if not tool_id.is_empty() else HAND_TOOL
	var tired := _tired()
	var first := first_ring and not child
	state = State.SWING
	index = i
	alt_action = bool(o["alt"])
	tool_cls = str(tool.get("cls", "hand"))
	T = Gather.strike_t(float(tool.get("T0", 1.0)), strike_mul, tired) / (float(_const.get("firstK", 0.5)) if first else 1.0)
	t = 0.0
	contact_done = false
	pending = false
	judged = false
	clean = false
	auto_clean = false
	hits_need = Gather.strike_hits(row, tool_id)
	gold = store.hits_of(i) + 1 >= hits_need
	ring_on = not tired
	if first:
		first_ring = false
	window = Gather.ring_window(_mods().get("strikeWindow"), diff_k, assist)
	swing_started.emit({"index": i, "T": T, "window": window, "gold": gold, "ring": ring_on, "contact_k": float(_const.get("contactK", 0.72)),
		"gesture": str(tool.get("gesture", "chop")), "tool": tool_id, "cls": tool_cls, "first": first})


func _swing(dt: float, pressed: bool, held: bool) -> void:
	t += dt
	var contact_at := float(_const.get("contactK", 0.72)) * T
	var close_at := contact_at + window / 2.0
	if ring_on and not judged and pressed:
		_judge(Gather.ring_judge(t, T, window, float(_const.get("contactK", 0.72))), false)
	# Otomatik yardım: son vuruş kendiliğinden tam, +1 yine %50.
	if ring_on and not judged and gold and t >= contact_at and assist == "auto":
		_judge(true, true)
	if not contact_done and t >= contact_at:
		_contact()
	if pending and (judged or not ring_on or t >= close_at):
		_complete_charge()
	if state != State.SWING or t < T:
		return
	if pending:
		_complete_charge()
	var i := index
	# E basılı kaldıkça vuruş sürer; bırakılınca bu vuruşla biter.
	if held and store.available(i):
		var o := offer(i)
		if not o.is_empty() and o["enabled"] and float(o["hold"]) == 0.0:
			_start_swing(i, o)
			return
	cancel()


func _judge(p_clean: bool, auto: bool) -> void:
	judged = true
	clean = p_clean
	auto_clean = auto and p_clean
	ring_judged.emit(p_clean, auto)
	if not p_clean:
		return
	# Temas geçtiyse tam vuruşun yarım bedeli geri verilir.
	if contact_done and stamina:
		var back := float((_const.get("staCost", {}) as Dictionary).get(tool_cls, 0.0)) * (1.0 - float(_const.get("cleanStaK", 0.5))) * _sta_scale()
		stamina.set("stamina", minf(float(stamina.get("stamina_max")), float(stamina.get("stamina")) + back))


func _contact() -> void:
	contact_done = true
	var i := index
	var kind_row := store.row_of(i)
	var h := store.add_hit(i)
	var cost := float((_const.get("staCost", {}) as Dictionary).get(tool_cls, 0.0)) * (float(_const.get("cleanStaK", 0.5)) if clean else 1.0) * _sta_scale()
	if stamina and cost > 0.0:
		stamina.set("stamina", maxf(0.0, float(stamina.get("stamina")) - cost))
	struck.emit(i, {"kind": store.kind_of(i), "cls": tool_cls, "ore": kind_row.get("ore", false), "tree": kind_row.get("tree", false),
		"at": store.position_of(i), "hits": h, "need": hits_need})
	_noise(kind_row, tool_cls, i)
	if h >= hits_need:
		pending = true


## Hakkı bitiren vuruşun verimi: +1 yalnız son halka altınsa ve tamsa (birikim %50, beceriyle kesin), her n'inci cevherde +1.
func _complete_charge() -> void:
	pending = false
	var i := index
	if store == null or i < 0 or not store.available(i):
		return
	var row := action_row(i)
	var kind_row := store.row_of(i)
	var kind_id := store.kind_of(i)
	store.clear_hits(i)
	var m := _mods()
	var bonus := 0
	if gold and clean:
		bonus_acc += float(_const.get("cleanBonus", 0.5)) if auto_clean else float(m.get("cleanBonus", _const.get("cleanBonus", 0.5)))
		if bonus_acc >= 1.0 - 1e-9:
			bonus = 1
			bonus_acc -= 1.0
	var every := int(m.get("oreBonusEvery", 0)) if m.get("oreBonusEvery") is float or m.get("oreBonusEvery") is int else 0
	if kind_row.get("ore", false) and every > 0:
		ore_count += 1
		if ore_count % every == 0:
			bonus += 1
	var struck_tree: bool = (store.flags[i] & NodeStore.F_STRUCK) != 0 and bool(kind_row.get("tree", false))
	_deliver(i, row, clean, bonus, {"charcoal": 2} if struck_tree else {})
	if alt_action:
		store.consume_alt(i)
	else:
		store.consume(i)
	if not store.available(i):
		depleted.emit(i, kind_id, {"tree": kind_row.get("tree", false), "at": store.position_of(i)})


## Gece gürültüsü (§3.1): yalnız karanlıkta; tutuşta Ayak ≥4 sessiz. Hava maskesini gizlilik uygular.
func _noise(kind_row: Dictionary, cls: String, i: int) -> void:
	if not dark.is_valid() or not bool(dark.call()):
		return
	var table: Dictionary = kind_row.get("noise", {}) if kind_row.get("noise") is Dictionary else {}
	var r := float(table.get(cls, 0.0))
	if cls == "hand" and foot >= int(_const.get("quietFoot", 4)):
		r = 0.0
	if r > 0.0:
		noise_made.emit(Vector2(store.x[i], store.z[i]), r)


# --- Tutuş ------------------------------------------------------------------------------------------------------------------

func _start_hold(i: int, o: Dictionary, p_driven: bool) -> void:
	state = State.HOLD
	index = i
	alt_action = bool(o["alt"])
	tool_cls = "hand"
	hold_t = 0.0
	hold_s = maxf(0.05, float(o["hold"]))
	driven = p_driven
	hold_started.emit({"index": i, "seconds": hold_s, "clip": str(store.row_of(i).get("clip", "collect")), "alt": alt_action})


## Tutuşun ilerlemesi (0..1; tutuş yoksa 0).
func hold_k() -> float:
	return clampf(hold_t / hold_s, 0.0, 1.0) if state == State.HOLD and hold_s > 0.0 else 0.0


func _hold(dt: float, held: bool) -> void:
	if driven and not held:
		# Bırakınca sıfırlanır, ceza yok.
		cancel()
		return
	hold_t += dt
	if hold_t >= hold_s:
		finish_hold()


## Tutuş bitti (sürücü E'nin tutuşunu sayıyorsa da çağırır).
func finish_hold() -> void:
	var i := index
	var was_alt := alt_action
	state = State.IDLE
	index = -1
	if store == null or i < 0 or not store.available(i):
		stopped.emit()
		return
	var kind_row := store.row_of(i)
	var kind_id := store.kind_of(i)
	var row: Dictionary = kind_row["alt"] if was_alt and kind_row.get("alt") is Dictionary else store.stage_of(i)
	_noise(kind_row, "hand", i)
	if kind_row.get("use") != null and not str(kind_row.get("use", "")).is_empty():
		used.emit(i, kind_id, str(kind_row["use"]), was_alt)
		stopped.emit()
		return
	_deliver(i, row, false, 0, {})
	if was_alt:
		store.consume_alt(i)
	else:
		store.consume(i)
	_overflow(i, kind_row, kind_id)
	if not store.available(i):
		depleted.emit(i, kind_id, {"tree": kind_row.get("tree", false), "at": store.position_of(i)})
	stopped.emit()


## Günün sessiz hakkını aşan aşırma (Ambar Dikişi): Güven −4 ve Ardokşa'nın sözü; Hesap Gözü +1 sessiz.
func _overflow(i: int, kind_row: Dictionary, kind_id: String) -> void:
	if kind_row.get("over") == null or not (kind_row.get("silent") is float or kind_row.get("silent") is int):
		return
	var used_n := int(store.day_count.get(i, 0))
	var silent := int(kind_row["silent"]) + int(_mods().get("hiddenPilfer", 0))
	if used_n > silent and apply_fx.is_valid():
		apply_fx.call(kind_row["over"], kind_id)


# --- Verim ------------------------------------------------------------------------------------------------------------------

## Hakkın ürünü: önce sırta, sığmayan terkiye, o da dolarsa düğümün dibinde yer yığını (Inventory.receive). → {eşya: adet}.
func _deliver(i: int, row: Dictionary, p_clean: bool, bonus: int, extra: Dictionary) -> Dictionary:
	var kind_id := store.kind_of(i)
	var kind_row := store.row_of(i)
	var yields := {}
	var k := float(yield_k.call(kind_id)) if yield_k.is_valid() else 1.0
	var seq_pos := -1
	for yv: Variant in row.get("yield", []):
		var y: Dictionary = yv
		var n := 1
		if y.get("seq") is Array:
			if seq_pos < 0:
				seq_pos = store.next_seq(i)
			var s: Array = y["seq"]
			n = int(s[seq_pos % s.size()])
		else:
			n = int(y.get("n", 1))
		n = Gather.scaled(_yield_acc, "%s|%s" % [kind_id, y["item"]], n, k)
		if n > 0:
			yields[str(y["item"])] = int(yields.get(str(y["item"]), 0)) + n
	var seq_items: Variant = row.get("seqItems")
	if seq_items is Array and not (seq_items as Array).is_empty():
		if seq_pos < 0:
			seq_pos = store.next_seq(i)
		var id := str(seq_items[seq_pos % (seq_items as Array).size()])
		yields[id] = int(yields.get(id, 0)) + 1
	if bonus > 0:
		var first := ""
		if not (row.get("yield", []) as Array).is_empty():
			first = str(row["yield"][0]["item"])
		elif seq_items is Array and not (seq_items as Array).is_empty():
			first = str(seq_items[0])
		if not first.is_empty():
			yields[first] = int(yields.get(first, 0)) + bonus
	for id: String in extra:
		yields[id] = int(yields.get(id, 0)) + int(extra[id])
	var at := store.position_of(i)
	var spill: Vector3 = spill_at.call(i) if spill_at.is_valid() else at
	var piled_any := 0
	for item: String in yields:
		var n: int = yields[item]
		var to := {}
		var piled := 0
		if inventory and inventory.has_method(&"receive"):
			var opts := {"spill_at": spill}
			if mount_key.is_valid():
				opts["mount"] = str(mount_key.call())
			var r: Dictionary = inventory.call(&"receive", item, n, "gather", opts)
			to = r.get("to", {})
			for key: String in to:
				if key.begins_with("pile."):
					piled += int(to[key])
		yielded.emit(i, item, n, {"clean": p_clean, "kind": kind_id, "to": to, "piled": piled, "at": at})
		piled_any += piled
	if piled_any > 0:
		refused.emit("pile", "%s · %s" % [Gather.pack_full_text(lang), NodeStore.message("pile_left", lang)])
	var fx: Variant = row.get("fx", kind_row.get("fx"))
	if fx != null and apply_fx.is_valid():
		apply_fx.call(fx, kind_id)
	if award.is_valid():
		award.call("gather", {"kind": kind_id})
	return yields
