class_name SynthDrone
extends RefCounted
## Boğaz dronu (audio.md §2 «Boğaz dronu»; prototipin instruments/throat.js renderDrone'u, tek kanal): testere kök (D2)
## ve alt oktav (D1), yavaş biçimlendirici süpürmesi; kampın dronunda dar bant geçiren (Q≈30) kipteki harmonikler
## (8. D, 9. E, 12. A) arasında gezinir (sıgıt): «çok hafif boğaz dronu». Dönem kanıtı yok, skor dronudur.
##
## Döngü tam ölçüdür (vuruş bilgili Ogg; MusicBank'ın 0. katmanı): bars × ölçü. Her periyodik bileşen döngüye sığar,
## kuyruk başa katlanır (doğrusal; ses ilintili olduğu için kabarmaz): döngü noktası duyulmaz. Düzey RMS'e çekilir:
## karışımı katman sesi kurar.
## params: drone ("camp", "low", "low_e", "winter_e", "sky_f"), tempo, bars, rate (22050: içerik 4,2 kHz altında), fold (sn),
## gain_db.

const SYGYT_Q := 30.0
const SYGYT_BOOST := 9.0
const DRONE_RMS := 0.14
const CONTROL_BLOCK := 32
## Dron türleri (prototipin DRONES'u; süreler döngünün kesri). f1, f2: [alt, üst, döngüdeki periyot sayısı];
## f3: [Hz, kazanç]; sygyt: harmonikler, her birinin döngüdeki payı, kazanç ve şarkı aralıkları (döngünün kesri).
## Kamp D2: sıgıt yalnız kipteki harmoniklerde gezer; 10. harmonik F♯ olurdu, ezgideki F ile çatışır.
const DRONES := {
	"camp": {
		"hz": 73.416, "level": 0.8, "saw": 0.5, "sub": 0.05, "fifth": 0.0,
		"f1": [380.0, 620.0, 2], "f2": [800.0, 1150.0, 1], "f3": [2500.0, 0.12],
		"sygyt": {"h": [8, 9, 8, 12, 9, 8], "hold": [3.2, 2.4, 2.8, 3.0, 2.2, 3.4], "gain": 0.07,
			"sing": [[0.1, 0.575], [0.675, 0.975]]},
		"breath": 0.025, "lp": 3200.0, "hp": 85.0,
	},
	"low": {
		"hz": 73.416, "level": 0.85, "saw": 0.5, "sub": 0.14, "fifth": 0.0,
		"f1": [260.0, 420.0, 1], "f2": [600.0, 900.0, 2], "f3": [2300.0, 0.05],
		"breath": 0.02, "lp": 1600.0, "hp": 50.0,
	},
	"low_e": {
		"hz": 82.407, "level": 0.85, "saw": 0.5, "sub": 0.14, "fifth": 0.0,
		"f1": [260.0, 440.0, 2], "f2": [620.0, 920.0, 1], "f3": [2300.0, 0.05],
		"breath": 0.02, "lp": 1600.0, "hp": 55.0,
	},
	"winter_e": {
		"hz": 82.407, "level": 0.8, "saw": 0.5, "sub": 0.08, "fifth": 0.1,
		"f1": [300.0, 520.0, 2], "f2": [700.0, 1050.0, 1], "f3": [2300.0, 0.06],
		"breath": 0.03, "lp": 2400.0, "hp": 60.0,
	},
	"sky_f": {
		"hz": 87.307, "level": 0.75, "saw": 0.45, "sub": 0.04, "fifth": 0.15,
		"f1": [500.0, 760.0, 2], "f2": [1000.0, 1400.0, 1], "f3": [2700.0, 0.1],
		"sygyt": {"h": [8, 10, 9, 12, 10, 8], "hold": [2.8, 2.6, 2.2, 3.4, 2.4, 3.0], "gain": 0.16,
			"sing": [[0.055, 0.53], [0.61, 0.945]]},
		"breath": 0.02, "lp": 4200.0, "hp": 75.0,
	},
}


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := float(int(params.get("rate", 22050)))
	var def: Dictionary = DRONES.get(str(params.get("drone", "camp")), DRONES["camp"])
	var bpm := float(params.get("tempo", 52.0))
	var bars := maxi(int(params.get("bars", 8)), 1)
	var loop_n := SynthSequencer.bar_samples(bpm, bars, int(sr))
	var loop_s := float(loop_n) / sr
	var fade_n := int(float(params.get("fold", 2.0)) * sr)
	var n := loop_n + fade_n
	# Kök döngüye tam periyot sığsın diye en yakın uygun perdeye çekilir (≤1 sent).
	var hz := roundf(float(def["hz"]) * loop_s) / loop_s
	var phase := rng.randf() * TAU
	# Tek boğaz birlikte kayar: kök, alt oktav ve beşli aynı sent eğrisini izler (±3 sent, döngüde 3 periyot).
	var ratio := SynthDsp.zeros(n)
	for i in n:
		ratio[i] = pow(2.0, 3.0 * sin(TAU * 3.0 * float(i) / float(loop_n) + phase) / 1200.0)
	var voice := SynthDsp.zeros(n)
	_add_voice(voice, sr, ratio, hz, float(def["saw"]), rng.randf())
	if float(def["sub"]) > 0.0:
		_add_voice(voice, sr, ratio, hz * 0.5, float(def["sub"]), rng.randf())
	if float(def["fifth"]) > 0.0:
		_add_voice(voice, sr, ratio, hz * 1.5, float(def["fifth"]), rng.randf())
	var out := SynthDsp.zeros(n)
	var level := float(def["level"])
	var f_phase := rng.randf() * 0.6
	for spec: Array in [[def["f1"], 1.0, 5.0], [def["f2"], 0.6, 6.0]]:
		var band: Array = spec[0]
		var lo := float(band[0])
		var hi := float(band[1])
		var cycles := float(band[2])
		var mid := (lo + hi) * 0.5
		var amp := (hi - lo) * 0.5
		var curve := SynthDsp.zeros(int(ceil(float(n) / CONTROL_BLOCK)) + 1)
		for k in curve.size():
			var x := TAU * cycles * float(k * CONTROL_BLOCK) / float(loop_n)
			curve[k] = mid + amp * (sin(x + f_phase) + 0.15 * sin(3.0 * x + f_phase * 2.0))
		SynthDsp.add_sweep(voice, out, sr, curve, CONTROL_BLOCK, float(spec[2]), float(spec[1]) * level)
	var f3: Array = def["f3"]
	SynthDsp.add_band(voice, out, sr, float(f3[0]), 7.0, float(f3[1]) * level)
	for i in n:
		out[i] += voice[i] * 0.04 * level
	# Nefes: 900 Hz civarı gürültü, döngüde iki kez kabarır.
	var air := SynthDsp.zeros(n)
	SynthDsp.add_band(SynthDsp.white(n, rng), air, sr, 900.0, 0.6, 1.0)
	var breath := float(def["breath"])
	for i in n:
		out[i] += air[i] * breath * level * (0.7 + 0.3 * sin(TAU * 2.0 * float(i) / float(loop_n) + phase))
	if def.get("sygyt") is Dictionary:
		_add_sygyt(voice, out, sr, hz, def["sygyt"], loop_n, level)
	SynthDsp.biquad_in_place(out, SynthDsp.biquad_coeffs("lowpass", float(def["lp"]), 0.5, sr))
	SynthDsp.biquad_in_place(out, SynthDsp.biquad_coeffs("highpass", float(def["hp"]), 0.6, sr))
	# Süzgeçlerin açılış geçişi ve döngü noktası: kuyruk başa katlanır.
	var looped := SynthDsp.fold_loop(out, loop_n, fade_n, false)
	var r := SynthDsp.rms(looped)
	if r > 0.0:
		SynthDsp.scale_in_place(looped, DRONE_RMS / r * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return looped


static func _add_voice(out: PackedFloat32Array, sr: float, ratio: PackedFloat32Array, hz: float, amp: float, phase: float) -> void:
	var freq := SynthDsp.zeros(ratio.size())
	for i in ratio.size():
		freq[i] = hz * ratio[i]
	SynthDsp.add_saw(out, sr, freq, amp, phase)


## Sıgıt: dar süzgeç harmonikler arasında 0,35 sn'de kayar; şarkı aralıklarında 1,5 sn'de kabarıp söner.
static func _add_sygyt(voice: PackedFloat32Array, out: PackedFloat32Array, sr: float, hz: float, def: Dictionary,
		loop_n: int, level: float) -> void:
	var n := voice.size()
	var h: Array = def["h"]
	var hold: Array = def["hold"]
	var total_hold := 0.0
	for x: Variant in hold:
		total_hold += float(x)
	var loop_s := float(loop_n) / sr
	var curve := SynthDsp.zeros(int(ceil(float(n) / CONTROL_BLOCK)) + 1)
	for k in curve.size():
		var t := fmod(float(k * CONTROL_BLOCK) / sr, loop_s) / loop_s * total_hold
		var acc := 0.0
		var j := 0
		while j < hold.size() - 1 and t > acc + float(hold[j]):
			acc += float(hold[j])
			j += 1
		var from := hz * float(h[j])
		var to := hz * float(h[(j + 1) % h.size()])
		var into := t - acc - (float(hold[j]) - 0.35)
		curve[k] = from * pow(to / from, clampf(into / 0.35, 0.0, 1.0)) if into > 0.0 else from
	var band := SynthDsp.zeros(n)
	SynthDsp.add_sweep(voice, band, sr, curve, CONTROL_BLOCK, SYGYT_Q, 1.0)
	var gain := float(def["gain"]) * SYGYT_BOOST * level
	var ramp := 1.5 / loop_s
	for i in n:
		var u := fmod(float(i) / float(loop_n), 1.0)
		var e := 0.0
		for w: Variant in def["sing"]:
			var a := float(w[0])
			var b := float(w[1])
			if u >= a and u <= b:
				e = maxf(e, minf(clampf((u - a) / ramp, 0.0, 1.0), clampf((b - u) / ramp, 0.0, 1.0)))
		out[i] += band[i] * e * gain
