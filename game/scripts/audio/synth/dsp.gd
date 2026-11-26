class_name SynthDsp
extends RefCounted
## Kodla ses üretiminin ortak yapı taşları (K28, K61; audio.md §2, godot.md §3.3): biquad süzgeçler, bant sınırlı testere,
## zarf, beyaz ve pembe gürültü, tohumlu RNG, kesintisiz döngü katlaması ve düzey ölçerler.
##
## Oyun çalışırken sentez yoktur: çalgılar `tools/bake_music.gd` ile önceden dosyaya basılır. Bu klasördeki her çalgı
## saf bir sınıftır (RefCounted, class_name Synth<Ad>) ve aynı imzayı taşır:
##   static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array   # mono, params.rate Hz
## Araç çalgıyı adından yükler (res://scripts/audio/synth/<ad>.gd); yeni çalgı yeni dosyadır, bu dosyalara dokunmaz.
## Aynı tohum aynı örnekleri verir: rastgele her şey verilen RNG'den, sabit sırayla çekilir.
##
## Packed diziler başvuruyla geçer: add_* ve *_in_place işlevleri verilen diziyi değiştirir.

## Varsayılan örnekleme hızı (Hz): müzik 44,1 kHz; dron ve ortam döngüleri tarifte 22,05 kHz verir.
const RATE := 44100


# --- Tohum, gürültü, perde ------------------------------------------------------------------

## Tohumlu RNG (aynı tohum aynı dizi).
static func make_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## Beyaz gürültü [-1, 1].
static func white(n: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = rng.randf() * 2.0 - 1.0
	return out


## Pembe gürültü (Paul Kellet'in süzgeci; −3 dB/oktav), yaklaşık [-1, 1].
static func pink(n: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(n)
	var b0 := 0.0
	var b1 := 0.0
	var b2 := 0.0
	var b3 := 0.0
	var b4 := 0.0
	var b5 := 0.0
	var b6 := 0.0
	for i in n:
		var w := rng.randf() * 2.0 - 1.0
		b0 = 0.99886 * b0 + w * 0.0555179
		b1 = 0.99332 * b1 + w * 0.0750759
		b2 = 0.96900 * b2 + w * 0.1538520
		b3 = 0.86650 * b3 + w * 0.3104856
		b4 = 0.55000 * b4 + w * 0.5329522
		b5 = -0.7616 * b5 - w * 0.0168980
		out[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362) * 0.11
		b6 = w * 0.115926
	return out


static func midi_hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


static func cents_ratio(cents: float) -> float:
	return pow(2.0, cents / 1200.0)


static func db_to_gain(db: float) -> float:
	return pow(10.0, db / 20.0)


static func gain_to_db(gain: float) -> float:
	return 20.0 * log(maxf(gain, 1e-12)) / log(10.0)


static func zeros(n: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(maxi(n, 0))
	return out


# --- Süzgeçler (RBJ biquad) --------------------------------------------------------------------

## Biquad katsayıları [b0, b1, b2, a1, a2] (a0 ile bölünmüş). type: lowpass, highpass, bandpass (tepe 0 dB),
## peak (gain_db ile), lowshelf, highshelf.
static func biquad_coeffs(type: String, hz: float, q: float, sr: float, gain_db: float = 0.0) -> PackedFloat64Array:
	var w := TAU * clampf(hz, 1.0, sr * 0.49) / sr
	var cw := cos(w)
	var sw := sin(w)
	var alpha := sw / (2.0 * maxf(q, 0.001))
	var a := pow(10.0, gain_db / 40.0)
	var b0 := 0.0
	var b1 := 0.0
	var b2 := 0.0
	var a0 := 1.0
	var a1 := 0.0
	var a2 := 0.0
	match type:
		"lowpass":
			b0 = (1.0 - cw) * 0.5
			b1 = 1.0 - cw
			b2 = (1.0 - cw) * 0.5
			a0 = 1.0 + alpha
			a1 = -2.0 * cw
			a2 = 1.0 - alpha
		"highpass":
			b0 = (1.0 + cw) * 0.5
			b1 = -(1.0 + cw)
			b2 = (1.0 + cw) * 0.5
			a0 = 1.0 + alpha
			a1 = -2.0 * cw
			a2 = 1.0 - alpha
		"bandpass":
			b0 = alpha
			b1 = 0.0
			b2 = -alpha
			a0 = 1.0 + alpha
			a1 = -2.0 * cw
			a2 = 1.0 - alpha
		"peak":
			b0 = 1.0 + alpha * a
			b1 = -2.0 * cw
			b2 = 1.0 - alpha * a
			a0 = 1.0 + alpha / a
			a1 = -2.0 * cw
			a2 = 1.0 - alpha / a
		"lowshelf", "highshelf":
			var sign := 1.0 if type == "lowshelf" else -1.0
			var sq := 2.0 * sqrt(a) * alpha
			b0 = a * ((a + 1.0) - sign * (a - 1.0) * cw + sq)
			b1 = sign * 2.0 * a * ((a - 1.0) - sign * (a + 1.0) * cw)
			b2 = a * ((a + 1.0) - sign * (a - 1.0) * cw - sq)
			a0 = (a + 1.0) + sign * (a - 1.0) * cw + sq
			a1 = -sign * 2.0 * ((a - 1.0) + sign * (a + 1.0) * cw)
			a2 = (a + 1.0) + sign * (a - 1.0) * cw - sq
	return PackedFloat64Array([b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0])


## Biquad'dan geçirir: input'u süzer, out'a gain ile ekler (out == input ise yerinde değiştirmez, yeni dizi ver).
static func add_biquad(input: PackedFloat32Array, out: PackedFloat32Array, c: PackedFloat64Array, gain: float = 1.0) -> void:
	var b0 := c[0]
	var b1 := c[1]
	var b2 := c[2]
	var a1 := c[3]
	var a2 := c[4]
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	var n := mini(input.size(), out.size())
	for i in n:
		var x := input[i]
		var y := b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		out[i] += gain * y


## Biquad'dan geçen yeni dizi.
static func biquad(input: PackedFloat32Array, c: PackedFloat64Array) -> PackedFloat32Array:
	var out := zeros(input.size())
	add_biquad(input, out, c, 1.0)
	return out


## Yerinde biquad.
static func biquad_in_place(buf: PackedFloat32Array, c: PackedFloat64Array) -> void:
	var b0 := c[0]
	var b1 := c[1]
	var b2 := c[2]
	var a1 := c[3]
	var a2 := c[4]
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	for i in buf.size():
		var x := buf[i]
		var y := b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		buf[i] = y


## RBJ bant geçiren (tepe 0 dB): input süzülüp out'a gain ile eklenir.
static func add_band(input: PackedFloat32Array, out: PackedFloat32Array, sr: float, hz: float, q: float, gain: float) -> void:
	add_biquad(input, out, biquad_coeffs("bandpass", hz, q, sr), gain)


## Kayan bant geçiren: merkez sıklığı denetim eğrisinden (her `block` örnekte bir değer) okunur (biçimlendirici
## süpürmesi, sıgıt). input süzülüp out'a gain ile eklenir.
static func add_sweep(input: PackedFloat32Array, out: PackedFloat32Array, sr: float, hz_curve: PackedFloat32Array,
		block: int, q: float, gain: float) -> void:
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	var b0 := 0.0
	var a1 := 0.0
	var a2 := 0.0
	var n := mini(input.size(), out.size())
	var last := hz_curve.size() - 1
	for i in n:
		if i % block == 0:
			var hz := hz_curve[mini(i / block, last)]
			var w := TAU * clampf(hz, 1.0, sr * 0.45) / sr
			var alpha := sin(w) / (2.0 * q)
			var a0 := 1.0 + alpha
			b0 = alpha / a0
			a1 = -2.0 * cos(w) / a0
			a2 = (1.0 - alpha) / a0
		var x := input[i]
		var y := b0 * (x - x2) - a1 * y1 - a2 * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		out[i] += gain * y


## Tek kutuplu alçak geçiren, yerinde.
static func lowpass1_in_place(buf: PackedFloat32Array, hz: float, sr: float) -> void:
	var k := 1.0 - exp(-TAU * hz / sr)
	var lp := 0.0
	for i in buf.size():
		lp += (buf[i] - lp) * k
		buf[i] = lp


## Tek kutuplu yüksek geçiren, yerinde (DC ve gürültünün en altını atar).
static func highpass1_in_place(buf: PackedFloat32Array, hz: float, sr: float) -> void:
	var k := 1.0 - exp(-TAU * hz / sr)
	var lp := 0.0
	for i in buf.size():
		lp += (buf[i] - lp) * k
		buf[i] = buf[i] - lp


## Dördüncü dereceden (iki Butterworth biquad) bant: lo altı ve hi üstü atılır. Ölçerler kullanır.
static func band_limit(buf: PackedFloat32Array, sr: float, lo: float, hi: float) -> PackedFloat32Array:
	var out := buf.duplicate()
	if lo > 0.0:
		biquad_in_place(out, biquad_coeffs("highpass", lo, 0.5412, sr))
		biquad_in_place(out, biquad_coeffs("highpass", lo, 1.3066, sr))
	if hi > 0.0 and hi < sr * 0.49:
		biquad_in_place(out, biquad_coeffs("lowpass", hi, 0.5412, sr))
		biquad_in_place(out, biquad_coeffs("lowpass", hi, 1.3066, sr))
	return out


# --- Salıngaç ve zarf ---------------------------------------------------------------------------

## Bant sınırlı testere (PolyBLEP): örnek başına sıklık eğrisi (Hz), out'a amp ile eklenir. Son evreyi döndürür.
static func add_saw(out: PackedFloat32Array, sr: float, freq: PackedFloat32Array, amp: float, phase: float = 0.0) -> float:
	var ph := phase
	var n := mini(out.size(), freq.size())
	for i in n:
		var dt := freq[i] / sr
		ph += dt
		if ph >= 1.0:
			ph -= 1.0
		var v := 2.0 * ph - 1.0
		if ph < dt:
			var x := ph / dt
			v -= x + x - x * x - 1.0
		elif ph > 1.0 - dt:
			var x := (ph - 1.0) / dt
			v -= x * x + x + x + 1.0
		out[i] += amp * v
	return ph


## Denetim eğrisi: fn(sn) her `block` örnekte bir çağrılır, arası doğrusal ara değerlenir (titreşim, zarf).
static func control(n: int, sr: float, fn: Callable, block: int = 16) -> PackedFloat32Array:
	var out := zeros(n)
	var prev: float = fn.call(0.0)
	var i := 0
	while i < n:
		var end := mini(n, i + block)
		var next: float = fn.call(float(end) / sr)
		var step := (next - prev) / float(block)
		var v := prev
		for j in range(i, end):
			out[j] = v
			v += step
		prev = next
		i = end
	return out


## Yumuşak (kosinüs) ara değerli, periyodik gezinme eğrisi, örnek başına: `points` noktası `period` örneğe eşit aralıkla
## dizilir, son nokta ilkine döner; n örnek boyunca (döngüden uzunsa başa sarar). Döngüde dikiş olmaz.
static func periodic(points: PackedFloat32Array, n: int, period: int) -> PackedFloat32Array:
	var out := zeros(n)
	var k := points.size()
	if k == 0 or period <= 0:
		return out
	var step := float(period) / float(k)
	for i in n:
		var x := float(i % period) / step
		var j := int(x)
		var u := x - float(j)
		var w := (1.0 - cos(u * PI)) * 0.5
		var a := points[j % k]
		out[i] = a + (points[(j + 1) % k] - a) * w
	return out


## [lo, hi] arasında n rastgele gezinme noktası.
static func anchors(n: int, lo: float, hi: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := zeros(n)
	for i in n:
		out[i] = lo + (hi - lo) * rng.randf()
	return out


## Örnek başına eğriyi denetim hızına indirir (her block örnekte bir değer; add_sweep için).
static func decimate(curve: PackedFloat32Array, block: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var i := 0
	while i < curve.size():
		out.append(curve[i])
		i += block
	return out


# --- Karışım ve biçim ----------------------------------------------------------------------------

## src'yi out'a offset örnekten başlayarak gain ile ekler (taşan kısım atılır).
static func mix_into(out: PackedFloat32Array, src: PackedFloat32Array, offset: int, gain: float = 1.0) -> void:
	var start := maxi(offset, 0)
	var skip := start - offset
	var n := mini(src.size() - skip, out.size() - start)
	for i in n:
		out[start + i] += src[skip + i] * gain


static func scale_in_place(buf: PackedFloat32Array, k: float) -> void:
	for i in buf.size():
		buf[i] *= k


## Baştan in_n, sondan out_n örneği doğrusal söndürür.
static func fade_edges(buf: PackedFloat32Array, in_n: int, out_n: int) -> void:
	var n := buf.size()
	for i in mini(in_n, n):
		buf[i] *= float(i) / float(in_n)
	for i in mini(out_n, n):
		buf[n - 1 - i] *= float(i) / float(out_n)


## Kesintisiz döngü: data `loop_n + fade_n` örnektir; kuyruğun ilk fade_n örneği başa katlanır (eşit güçte, ilintisiz
## gürültüde düzey düşmez; equal_power kapalıysa doğrusal). Sonuç loop_n örnektir; baş ve son aynı evrede buluşur.
static func fold_loop(data: PackedFloat32Array, loop_n: int, fade_n: int, equal_power: bool = true) -> PackedFloat32Array:
	var out := data.slice(0, loop_n)
	var f := mini(fade_n, data.size() - loop_n)
	for i in f:
		var a := float(i) / float(f)
		var gin := sin(a * PI * 0.5) if equal_power else a
		var gout := cos(a * PI * 0.5) if equal_power else 1.0 - a
		out[i] = data[i] * gin + data[loop_n + i] * gout
	return out


## Nota sonu: from örnekten başlayıp len örnekte sıfıra iner (parmakla susturma), sonrası sıfır.
static func release(buf: PackedFloat32Array, from: int, length: int) -> void:
	var n := buf.size()
	for i in range(maxi(from, 0), n):
		var k := i - from
		buf[i] *= 0.0 if k >= length else 1.0 - float(k) / float(length)


## Perde kayışı: nota `cents`ten (eksi: alttan) başlayıp `seconds` içinde doğrusal olarak asıl perdeye varır.
## Tampon doğrusal ara değerle yeniden örneklenir; uzunluk aynı kalır.
static func glide(buf: PackedFloat32Array, cents: float, seconds: float, sr: float) -> PackedFloat32Array:
	var n := buf.size()
	var out := zeros(n)
	var g := maxi(int(seconds * sr), 1)
	var pos := 0.0
	for i in n:
		var j := int(pos)
		if j >= n - 1:
			break
		var u := pos - float(j)
		out[i] = buf[j] + (buf[j + 1] - buf[j]) * u
		var c := cents * (1.0 - float(i) / float(g)) if i < g else 0.0
		pos += pow(2.0, c / 1200.0) if i < g else 1.0
	return out


# --- Ölçerler -----------------------------------------------------------------------------------

static func peak(buf: PackedFloat32Array) -> float:
	var m := 0.0
	for i in buf.size():
		m = maxf(m, absf(buf[i]))
	return m


static func rms(buf: PackedFloat32Array, from: int = 0, to: int = -1) -> float:
	var end := buf.size() if to < 0 else mini(to, buf.size())
	var start := clampi(from, 0, end)
	if end <= start:
		return 0.0
	var s := 0.0
	for i in range(start, end):
		s += buf[i] * buf[i]
	return sqrt(s / float(end - start))


static func energy(buf: PackedFloat32Array) -> float:
	var s := 0.0
	for i in buf.size():
		s += buf[i] * buf[i]
	return s


## Pencereli RMS düzeyi (dB), her hop örnekte bir pencere.
static func envelope_db(buf: PackedFloat32Array, win: int, hop: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var i := 0
	while i + win <= buf.size():
		out.append(gain_to_db(rms(buf, i, i + win)))
		i += hop
	return out


## Sönme süresi (T60, saniye): pencereli düzeyin tepeden sonra `top` ile `bottom` dB aşağısı arasındaki
## eğimine (en küçük kareler) göre. Eğim yoksa 0.
static func t60(buf: PackedFloat32Array, sr: float, top: float = 5.0, bottom: float = 35.0) -> float:
	var win := int(sr * 0.02)
	var hop := int(sr * 0.01)
	var env := envelope_db(buf, win, hop)
	if env.is_empty():
		return 0.0
	var peak_i := 0
	for i in env.size():
		if env[i] > env[peak_i]:
			peak_i = i
	var pk := env[peak_i]
	var xs := PackedFloat32Array()
	var ys := PackedFloat32Array()
	for i in range(peak_i, env.size()):
		var drop := pk - env[i]
		if drop >= bottom:
			break
		if drop >= top:
			xs.append(float(i) * float(hop) / sr)
			ys.append(env[i])
	if xs.size() < 3:
		return 0.0
	var mx := 0.0
	var my := 0.0
	for i in xs.size():
		mx += xs[i]
		my += ys[i]
	mx /= xs.size()
	my /= xs.size()
	var num := 0.0
	var den := 0.0
	for i in xs.size():
		num += (xs[i] - mx) * (ys[i] - my)
		den += (xs[i] - mx) * (xs[i] - mx)
	var slope := num / den if den > 0.0 else 0.0
	return -60.0 / slope if slope < 0.0 else 0.0


## Kesim sıklığı üstündeki enerjinin payı (40 Hz – 16 kHz içinde; şarkı ölçüsünün «1,28 kHz üstü enerji»si).
static func hf_share(buf: PackedFloat32Array, sr: float, cutoff: float = 1280.0) -> float:
	var total := energy(band_limit(buf, sr, 40.0, 16000.0))
	if total <= 0.0:
		return 0.0
	return energy(band_limit(buf, sr, cutoff, 16000.0)) / total


## Vuruş sonrası sönüm eğimi (dB / 100 ms), şarkı ölçüsünün yöntemiyle: bandın (2–6 kHz) vuruş anındaki pencere
## düzeyi ile min(0,3 sn, 0,75 × sonraki vuruşa kalan) sonraki düzeyin farkı; vuruşların ortancası.
static func band_decay(buf: PackedFloat32Array, sr: float, onsets: PackedFloat32Array, lo: float = 2000.0,
		hi: float = 6000.0) -> float:
	var band := band_limit(buf, sr, lo, hi)
	var win := 2048
	var drops := PackedFloat32Array()
	for k in onsets.size():
		var t := onsets[k]
		var next := onsets[k + 1] if k + 1 < onsets.size() else t + 1.0
		var dt := minf(0.3, 0.75 * (next - t))
		if dt < 0.08:
			continue
		var i0 := int(t * sr)
		var i1 := int((t + dt) * sr)
		if i1 + win > band.size():
			continue
		var e0 := rms(band, i0, i0 + win)
		var e1 := rms(band, i1, i1 + win)
		if e0 > 0.0 and e1 > 0.0:
			drops.append(20.0 * log(e0 / e1) / log(10.0) / (dt * 10.0))
	if drops.is_empty():
		return 0.0
	drops.sort()
	return drops[drops.size() / 2]


# --- Dosya ---------------------------------------------------------------------------------------

## 16 bit PCM mono AudioStreamWAV (taşan örnek kırpılır). save_to_wav ile yazılır.
static func to_wav(buf: PackedFloat32Array, sr: int) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, clampi(int(round(buf[i] * 32767.0)), -32768, 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sr
	wav.stereo = false
	wav.data = data
	return wav
