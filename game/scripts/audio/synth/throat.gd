class_name SynthThroat
extends RefCounted
## Boğaz sesi: kargıra (audio.md §2 «Boğaz dronu»; prototipin instruments/throat.js'inin kargyraa_e dronu): testere kök
## ve yarım frekanslı genlik oynaması (periyot ikilenmesi: alt oktav duyulur), alt oktav testeresi, yavaş biçimlendirici
## süpürmesi; dar bant geçiren (Q≈30) harmonikler arasında gezinir (sıgıt). `erlik`'te E'de çalar (E2, alt oktav E1).
## Dönem kanıtı yok: skor dronudur, görünmez.
##
## Roller (role):
##   "kargyraa" (varsayılan): döngülü dron, tam ölçü (vuruş bilgili Ogg; MusicBank'ın 0. katmanı). Her periyodik bileşen
##     döngüye sığar, kuyruk başa katlanır.
##   "slide": A↘D kargıra kayışı (audio.md §3 `erlik`: ters motif yerine): A2'de tutar, D2'ye iner, D'de söner. Cümle
##     katmanıdır (Playlist; boş cümle kopyalarının arasında seyrek).
## params: root (MIDI, 40 = E2), tempo, bars, sygyt (harmonik listesi; kipte kalanlar: E'de 8 E, 12 B, 16 E), growl
## (0..1, periyot ikilenmesinin derinliği), from / to (kayışın perdeleri, MIDI 45 A2 → 38 D2), rate (22050), fold, gain_db.

const SYGYT_Q := 30.0
const SYGYT_BOOST := 9.0
const THROAT_RMS := 0.14
const CONTROL_BLOCK := 32
## E Frigyen'de kalan harmonikler: 9. (F♯) ve 10. (G♯) kipte değildir, ezgideki F ve G ile çatışırdı.
const KARGYRAA_SYGYT: Array[int] = [8, 12, 16, 12, 8, 12]
## Kayış: A2'den D2'ye (tam beşli aşağı), tutuş ve iniş süreleri (sn).
const SLIDE_FROM := 45
const SLIDE_TO := 38
const SLIDE_HOLD := 0.55
const SLIDE_GLIDE := 1.7
const SLIDE_TAIL := 0.9
const SLIDE_START := 0.25
const SLIDE_PEAK := 0.5


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	if str(params.get("role", "kargyraa")) == "slide":
		return render_slide(params, rng)
	return render_drone(params, rng)


## Döngülü kargıra dronu.
static func render_drone(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := float(int(params.get("rate", 22050)))
	var bpm := float(params.get("tempo", 52.0))
	var bars := maxi(int(params.get("bars", 8)), 1)
	var loop_n := SynthSequencer.bar_samples(bpm, bars, int(sr))
	var loop_s := float(loop_n) / sr
	var fade_n := int(float(params.get("fold", 2.0)) * sr)
	var n := loop_n + fade_n
	# Kök döngüye tam periyot sığsın diye en yakın uygun perdeye çekilir (≤1 sent); yarım frekans da sığsın diye çift.
	var hz := roundf(SynthDsp.midi_hz(float(params.get("root", 40))) * loop_s * 0.5) * 2.0 / loop_s
	var growl := clampf(float(params.get("growl", 0.6)), 0.0, 1.0)
	var phase := rng.randf() * TAU
	var ratio := SynthDsp.zeros(n)
	for i in n:
		ratio[i] = pow(2.0, 3.0 * sin(TAU * 3.0 * float(i) / float(loop_n) + phase) / 1200.0)
	var voice := _voice(n, sr, hz, ratio, growl, 0.42, rng)
	var out := SynthDsp.zeros(n)
	var f_phase := rng.randf() * 0.6
	for spec: Array in [[300.0, 520.0, 2.0, 1.0, 5.0], [700.0, 1000.0, 1.0, 0.6, 6.0]]:
		var curve := SynthDsp.zeros(int(ceil(float(n) / CONTROL_BLOCK)) + 1)
		var mid := (float(spec[0]) + float(spec[1])) * 0.5
		var amp := (float(spec[1]) - float(spec[0])) * 0.5
		for k in curve.size():
			var x := TAU * float(spec[2]) * float(k * CONTROL_BLOCK) / float(loop_n)
			curve[k] = mid + amp * (sin(x + f_phase) + 0.15 * sin(3.0 * x + f_phase * 2.0))
		SynthDsp.add_sweep(voice, out, sr, curve, CONTROL_BLOCK, float(spec[4]), float(spec[3]) * 0.8)
	SynthDsp.add_band(voice, out, sr, 2400.0, 7.0, 0.06 * 0.8)
	for i in n:
		out[i] += voice[i] * 0.04 * 0.8
	var air := SynthDsp.zeros(n)
	SynthDsp.add_band(SynthDsp.white(n, rng), air, sr, 900.0, 0.6, 1.0)
	for i in n:
		out[i] += air[i] * 0.04 * 0.8 * (0.7 + 0.3 * sin(TAU * 2.0 * float(i) / float(loop_n) + phase))
	var harmonics: Array = params["sygyt"] if params.get("sygyt") is Array else KARGYRAA_SYGYT
	if not harmonics.is_empty():
		_add_sygyt(voice, out, sr, hz, harmonics, loop_n, float(params.get("sygyt_gain", 0.05)))
	SynthDsp.biquad_in_place(out, SynthDsp.biquad_coeffs("lowpass", 2200.0, 0.5, sr))
	SynthDsp.biquad_in_place(out, SynthDsp.biquad_coeffs("highpass", 30.0, 0.6, sr))
	var looped := SynthDsp.fold_loop(out, loop_n, fade_n, false)
	_normalize(looped, params)
	return looped


## A↘D kayışı: kargıra sesi A2'de tutar, D2'ye iner, D'de söner (cümle içinde biter).
static func render_slide(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := float(int(params.get("rate", 22050)))
	var bpm := float(params.get("tempo", 52.0))
	var bars := maxi(int(params.get("bars", 2)), 1)
	var n := SynthSequencer.bar_samples(bpm, bars, int(sr))
	var curve := slide_curve(params, sr, n)
	var ratio := SynthDsp.zeros(n)
	var base := curve[0] if curve.size() > 0 else 110.0
	for i in n:
		ratio[i] = curve[i] / base
	var growl := clampf(float(params.get("growl", 0.7)), 0.0, 1.0)
	var voice := _voice(n, sr, base, ratio, growl, 0.3, rng)
	var out := SynthDsp.zeros(n)
	# Ağız «o»dan «a»ya açılır, inişte yeniden kapanır.
	var f1 := SynthDsp.zeros(int(ceil(float(n) / CONTROL_BLOCK)) + 1)
	for k in f1.size():
		var t := float(k * CONTROL_BLOCK) / sr
		f1[k] = 380.0 + 140.0 * sin(PI * clampf((t - SLIDE_START) / (SLIDE_HOLD + SLIDE_GLIDE + SLIDE_TAIL), 0.0, 1.0))
	SynthDsp.add_sweep(voice, out, sr, f1, CONTROL_BLOCK, 5.0, 1.0)
	SynthDsp.add_band(voice, out, sr, 850.0, 6.0, 0.5)
	SynthDsp.add_band(voice, out, sr, 2400.0, 7.0, 0.05)
	var air := SynthDsp.zeros(n)
	SynthDsp.add_band(SynthDsp.white(n, rng), air, sr, 700.0, 0.8, 1.0)
	var end_t := SLIDE_START + SLIDE_HOLD + SLIDE_GLIDE + SLIDE_TAIL
	for i in n:
		var t := float(i) / sr
		var env := clampf((t - SLIDE_START) / 0.18, 0.0, 1.0) * clampf((end_t - t) / 0.6, 0.0, 1.0)
		out[i] = (out[i] + voice[i] * 0.03 + air[i] * 0.05) * env
	SynthDsp.biquad_in_place(out, SynthDsp.biquad_coeffs("lowpass", 2400.0, 0.5, sr))
	SynthDsp.biquad_in_place(out, SynthDsp.biquad_coeffs("highpass", 30.0, 0.6, sr))
	SynthDsp.fade_edges(out, 0, int(0.02 * sr))
	# Kayış cümlenin bir bölümünde çalar: düzeyi tepeyle kurulur (RMS'e çekilseydi sessiz bölüm onu taşırırdı).
	var peak := SynthDsp.peak(out)
	if peak > 0.0:
		SynthDsp.scale_in_place(out, SLIDE_PEAK / peak * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out


## Kayışın temel perdesi (Hz, örnek başına): SLIDE_START'a dek ve tutuşta A, iniş yumuşak (kosinüs) D'ye, sonra D.
static func slide_curve(params: Dictionary, sr: float, n: int) -> PackedFloat32Array:
	var from_hz := SynthDsp.midi_hz(float(params.get("from", SLIDE_FROM)))
	var to_hz := SynthDsp.midi_hz(float(params.get("to", SLIDE_TO)))
	var out := SynthDsp.zeros(n)
	var g0 := SLIDE_START + SLIDE_HOLD
	for i in n:
		var t := float(i) / sr
		var u := clampf((t - g0) / SLIDE_GLIDE, 0.0, 1.0)
		var w := 0.5 - 0.5 * cos(PI * u)
		out[i] = from_hz * pow(to_hz / from_hz, w)
	return out


## Kayışın başladığı ve bittiği an (sn): A'nın tutuşu ve D'nin sönüşü (sınama perdeyi bu aralıklarda ölçer).
static func slide_times() -> Dictionary:
	return {"hold_from": SLIDE_START, "glide_from": SLIDE_START + SLIDE_HOLD,
		"glide_to": SLIDE_START + SLIDE_HOLD + SLIDE_GLIDE, "end": SLIDE_START + SLIDE_HOLD + SLIDE_GLIDE + SLIDE_TAIL}


## Kargıra kaynağı: testere kök, yarım frekanslı sinüsle genlik oynaması (growl) ve alt oktav testeresi; hepsi aynı
## perde eğrisini (ratio) izler: tek boğaz birlikte kayar.
static func _voice(n: int, sr: float, hz: float, ratio: PackedFloat32Array, growl: float, sub: float,
		rng: RandomNumberGenerator) -> PackedFloat32Array:
	var saw := SynthDsp.zeros(n)
	var freq := SynthDsp.zeros(n)
	for i in n:
		freq[i] = hz * ratio[i]
	SynthDsp.add_saw(saw, sr, freq, 0.5, rng.randf())
	var half := SynthDsp.zeros(n)
	for i in n:
		freq[i] = hz * 0.5 * ratio[i]
	SynthDsp.add_saw(half, sr, freq, sub * growl, rng.randf())
	var out := SynthDsp.zeros(n)
	var ph := rng.randf()
	for i in n:
		ph += hz * 0.5 * ratio[i] / sr
		if ph >= 1.0:
			ph -= 1.0
		var am := 1.0 - growl * 0.5 + growl * 0.5 * sin(TAU * ph)
		out[i] = saw[i] * am + half[i]
	return out


## Sıgıt: dar süzgeç harmonikler arasında 0,35 sn'de kayar; döngüde iki kez kabarıp söner (Erlik'te seyrek ve soğuk).
static func _add_sygyt(voice: PackedFloat32Array, out: PackedFloat32Array, sr: float, hz: float, harmonics: Array,
		loop_n: int, gain: float) -> void:
	var n := voice.size()
	var count := harmonics.size()
	var hold := float(loop_n) / sr / float(count)
	var curve := SynthDsp.zeros(int(ceil(float(n) / CONTROL_BLOCK)) + 1)
	for k in curve.size():
		var t := fmod(float(k * CONTROL_BLOCK) / sr, float(loop_n) / sr)
		var j := mini(int(t / hold), count - 1)
		var from := hz * float(harmonics[j])
		var to := hz * float(harmonics[(j + 1) % count])
		var into := t - float(j) * hold - (hold - 0.35)
		curve[k] = from * pow(to / from, clampf(into / 0.35, 0.0, 1.0)) if into > 0.0 else from
	var band := SynthDsp.zeros(n)
	SynthDsp.add_sweep(voice, band, sr, curve, CONTROL_BLOCK, SYGYT_Q, 1.0)
	for i in n:
		var u := fmod(float(i) / float(loop_n), 1.0)
		var e := 0.5 - 0.5 * cos(TAU * 2.0 * u)
		out[i] += band[i] * e * gain * SYGYT_BOOST


static func _normalize(buf: PackedFloat32Array, params: Dictionary) -> void:
	var r := SynthDsp.rms(buf)
	if r > 0.0:
		SynthDsp.scale_in_place(buf, THROAT_RMS / r * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
