class_name FlockStone
extends FlockStep
## «Çobanlık» 5: ak taş (tür «flock_stone»). Luhun meydan okur: «Sazlığın dibinde ak bir taş var. Çıkaran bey olur.» Taş sazlığın dibinde,
## yüzme derinliğindedir; yaklaşınca suyun altından soluk parlar (ChildhoodLake). Oyuncu üstünde E ile dalar (ChildSwim: 1,5 sn, dip görünür),
## taş erimdeyse alınır: Yançi «Çıkardı! Ak taş onun!», Mete «Bunu anama vereceğim.»; taş Mete'nin heybesine girer (white_stone), yolculuğa
## white_stone işareti yazılır. Iska dalış bedavadır. Luhun ve Yançi sazlığın önünde suda bekler. Veri: dare_line, got_line, mine_line, item,
## flag, kids {kişi: işaret}.

var _linked := false
var _got := false


func start() -> void:
	phase = "dare"
	var wait := say(str(step.get("dare_line", "stone_dare")))
	at(clock + maxf(wait, 0.5), func() -> void: phase = "dive")
	for id: String in (step.get("kids", {}) as Dictionary):
		var m := mover(id)
		if m:
			m.go([point(step["kids"][id])], pace(1.2))
	_link()


func _link() -> void:
	var sw := player().swim
	if sw and not _linked:
		_linked = true
		sw.dived.connect(_on_dived)


func _on_dived(found: bool) -> void:
	if not found or _got:
		return
	_got = true
	phase = "got"
	state()["stone"] = true
	var item := str(step.get("item", "white_stone"))
	if scene.inventory and ItemCatalog.has(item):
		scene.inventory.add(item, 1, "flock")
	flag(str(step.get("flag", "white_stone")))
	sfx("sfx_kids_laugh", player().global_position, -6.0)
	E21Shots.shot(scene, "flock_stone", 0.2)
	say(str(step.get("got_line", "stone_got")))
	var wait := say(str(step.get("mine_line", "stone_mine")))
	at(clock + maxf(wait, 1.0) + 0.4, done)


func tick(delta: float) -> void:
	tick_followers(delta)
	for id: String in (step.get("kids", {}) as Dictionary):
		tick_swimmer(id)
	_link()


func target(_from: Vector3) -> Vector3:
	var l := lake()
	return l.stone_position() if l and not _got else Vector3.INF


func cleanup() -> void:
	var sw := player().swim if is_instance_valid(player()) else null
	if sw and sw.dived.is_connected(_on_dived):
		sw.dived.disconnect(_on_dived)


func preset() -> void:
	var l := lake()
	if l:
		l.take_stone()
	state()["stone"] = true
	var item := str(step.get("item", "white_stone"))
	if scene.inventory and ItemCatalog.has(item) and not scene.inventory.has(item):
		scene.inventory.add(item, 1, "flock")
	flag(str(step.get("flag", "white_stone")))


func autoplay(bot: Node, _delta: float) -> void:
	if phase != "dive":
		bot.call(&"halt")
		return
	var l := lake()
	var stone := l.stone_position() if l else Vector3.INF
	if stone == Vector3.INF:
		bot.call(&"halt")
		return
	# Kıyıdan taşın önüne koşar, sonra taşa yüzer.
	if bool(bot.call(&"follow", ["lake_wade", "stone_shore", stone], "stone", true, 0.9)):
		var sw := player().swim
		if sw and sw.can_dive():
			player().interact()


func line_keys() -> Array:
	return [str(step.get("dare_line", "stone_dare")), str(step.get("got_line", "stone_got")), str(step.get("mine_line", "stone_mine"))]
