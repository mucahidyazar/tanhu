extends TestCase
## Oynanan sahnelerin sözü (SceneVoice; E20/7, K61): söz hemen ya da sırayla başlar, sesli satırın süresi sesin süresidir (ana sözün payı
## dahil) ve altyazısı sesin bitişinden TAIL sonra söner; sıradaki söz önceki bitince gap sonra başlar, koşulu tutmayan düşer; isteğe bağlı
## sözler söz sırası başlarken bırakılır; tepki sözü konuşulurken düşer, aynı rol aynı olayda 45 sn konuşmaz, olayın son çeşidi tekrarlanmaz;
## sesi olmayan satır altyazının okuma süresiyle akar. Saat sınamanın elindedir (tick), AudioManager yoktur: süre veriden okunur.

const PREFIX := "act0.child."


func _voice(shown: Array) -> SceneVoice:
	var v := SceneVoice.new()
	v.prefix = PREFIX
	v.show = func(key: String, seconds: float) -> void: shown.append([key, seconds])
	v.text_seconds = func(_key: String) -> float: return 2.0
	return v


func test_lines_start_now_or_wait_for_the_voice() -> void:
	var shown: Array = []
	var v := _voice(shown)
	assert_true(v.has_audio("wake"), "Lan Hatun'un sözü sesli (içe aktarılmış)")
	var first := v.say("wake")
	assert_almost(first, SceneVoice.MAIN_LEAD + VoLines.seconds(PREFIX + "wake"), 0.001, "Söz hemen başlar; süresi sesin süresi")
	assert_eq(shown.size(), 1)
	assert_almost(float(shown[0][1]), SceneVoice.subtitle_seconds(first), 0.001, "Altyazı sesin bitişinden TAIL sonra söner")
	var second := v.say("wake_count")
	assert_almost(second, first + v.gap + v.length("wake_count"), 0.001, "Konuşulurken gelen söz sıraya girer; bitişi beklemeyi de sayar")
	assert_false(v.is_free())
	assert_almost(v.remaining(), second, 0.001, "Kalan: çalan söz, ara ve sıradaki söz")
	v.tick(first + v.gap - 0.02)
	assert_eq(shown.size(), 1, "Önceki söz ve ara bitmeden sıradaki başlamaz")
	v.tick(first + v.gap + 0.02)
	assert_eq(shown.size(), 2)
	assert_eq(str(shown[1][0]), "wake_count")
	v.tick(first + v.gap + 0.02 + v.length("wake_count") + 0.01)
	assert_true(v.is_free(), "Sözler bitti")
	assert_eq(v.say(""), 0.0, "Boş anahtar söylenmez")


func test_conditions_and_optional_lines_drop() -> void:
	var shown: Array = []
	var v := _voice(shown)
	var waiting := [true]
	v.say("sheep_first")
	v.say("stand_still", func() -> bool: return bool(waiting[0]), true)
	v.say("mouse_spared", Callable(), true)
	v.say("look_down")
	# Koşul söz başlarken sorulur: bekleme bittiyse söz düşer, sıradaki gelir.
	waiting[0] = false
	v.tick(v.length("sheep_first") + v.gap + 0.01)
	assert_eq(str(shown[-1][0]), "mouse_spared", "Koşulu tutmayan söz düştü")
	# Söz sırası başlarken isteğe bağlı sözler bırakılır, zorunlu söz kalır.
	v.say("stand_still", Callable(), true)
	v.drop_optional()
	v.tick(100.0)
	assert_eq(str(shown[-1][0]), "look_down", "İsteğe bağlı söz bırakıldı, zorunlu söz söylendi")
	v.tick(200.0)
	assert_true(v.is_free())
	# Koşulu tutmayan söz boşken de söylenmez.
	assert_eq(v.say("my_bird", func() -> bool: return false), 0.0)
	assert_eq(str(shown[-1][0]), "look_down")


func test_barks_wait_45_seconds_per_role_and_do_not_repeat() -> void:
	var shown: Array = []
	var v := _voice(shown)
	var entries := [
		{"by": "yanchi_child", "line": "bark.miss.yanchi_child.1"}, {"by": "yanchi_child", "line": "bark.miss.yanchi_child.2"},
		{"by": "luhun_child", "line": "bark.miss.luhun_child.1"}, {"by": "luhun_child", "line": "bark.miss.luhun_child.2"},
	]
	assert_almost(v.length("bark.miss.yanchi_child.1"), VoLines.seconds(PREFIX + "bark.miss.yanchi_child.1"), 0.001, "Havuz sözü (C) payı beklemez")
	v.say("wake")
	assert_eq(v.bark("miss", entries), "", "Konuşulurken tepki sözü düşer")
	v.tick(30.0)
	var first := v.bark("miss", entries)
	assert_false(first.is_empty(), "Boşken tepki sözü söylenir")
	var role := "yanchi_child" if first.contains("yanchi") else "luhun_child"
	assert_false(v.bark_ready("miss", role), "Konuşan rol bu olayda bekler")
	v.tick(40.0)
	var second := v.bark("miss", entries)
	assert_false(second.is_empty(), "Öteki rol konuşabilir")
	assert_false(second.contains(role), "Aynı rol 45 sn dolmadan konuşmaz")
	v.tick(55.0)
	assert_eq(v.bark("miss", entries), "", "İki rol de bekliyor")
	v.tick(30.0 + SceneVoice.COOLDOWN + 0.1)
	var third := v.bark("miss", entries)
	assert_ne(third, second, "Olayın son çeşidi tekrarlanmaz")
	assert_true(third.contains(role), "45 sn sonra ilk rol yine konuşur")
	assert_eq(v.bark("flush", []), "", "Çeşidi olmayan olay sessiz")


func test_unvoiced_line_flows_with_its_reading_time() -> void:
	var shown: Array = []
	var v := _voice(shown)
	v.prefix = "act0.yok."
	assert_false(v.has_audio("wake"))
	assert_almost(v.say("wake"), 2.0, 0.001, "Sesi olmayan satır altyazının okuma süresiyle akar (K89)")
	assert_almost(float(shown[0][1]), 2.0, 0.001)
	assert_almost(SceneVoice.subtitle_seconds(0.4), SceneVoice.MIN_SUB, 0.001, "Kısa sözün altyazısı en az MIN_SUB")
