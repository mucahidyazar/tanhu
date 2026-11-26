#!/usr/bin/env node
// Şarkı çekiminin K75 ölçüsü, kredisiz (decisions.md K75; audio.md §2 «Kabul»; act0-text.md «Ölçütler»).
// Prototipten taşındı (~/Code/tests/tanhu-programatic-test/tools/song-measure.mjs ve bard-song.mjs --measure): fft, stft,
// vuruş, 1,28 kHz üstü enerji, 2–6 kHz sönümü, söz ile çalgı düzey farkı ve YIN. Yeni: sözsüz bölümlerde eş zamanlı perde
// (art arda harmonik çıkarma, kopuz.md §7) ve sözlü bölümün ayrılmış ses izinde kip ve motif (song_separate.py).
//
// Ölçütler üç sınıftır:
//   Sınır (uymayan çekim seçilmez): 23 sözcük sırayla; ses girişi 3–6 sn; dize arası ≤6 sn; boy 22–32 sn; eş zamanlı
//     perde ≤3 (giriş, dize arası cevap ve çıkışta, perdesi olan karelerin ortalaması).
//   Sayılan (çekimlerin sırası): vuruş/sn ≥2,0; 1,28 kHz üstü enerji ≥%8; 2–6 kHz sönümü ≥4 dB / 100 ms; söz ile çalgı
//     düzey farkı ≤12 dB. Söz kipi F / (F + F♯) ≥0,7 bu sınıfa yalnız denetim geçince girer.
//   Bilgi (sırayı değiştirmez): iki dizenin son üç ölçüsünde A→G→F→D; denetimi geçene dek söz kipi; vuruş ızgarası (dönem,
//     ilk vuruş, ızgaraya oturan vuruş oranı; ozanın kolu seçili çekimin ızgarasına uyar, K60, K95).
//
//   node tools/song/song_measure.mjs                    3104–3107'yi ölçer, k75_measure.json'u yazar, tabloyu basar
//   node tools/song/song_measure.mjs --takes=3106       yalnız verilen çekimler (virgülle); k75_measure.json'a dokunmaz,
//                                                       --out=<yol> verilirse oraya yazar
//   node tools/song/song_measure.mjs --no-write         JSON yazmaz
//   node tools/song/song_measure.mjs --no-separate      ayırmayı denemez: kip ve motif «ölçülemedi: kulakla»
//   node tools/song/song_measure.mjs --stems=<klasör>   önceden ayrılmış ses izleri (<tohum>.wav; denetim için
//                                                       control_3101.wav, control_3103.wav); perde burada YIN'le çıkar
//   node tools/song/song_measure.mjs --takes-dir=<yol>  çekimlerin klasörü (varsayılan ../docs/research/bard-takes)
//
// Ayırma isteğe bağlıdır ve hiçbir şey indirmez. Yorumlayıcı: SONG_SEPARATE_PYTHON (demucs ve librosa kurulu); verilmezse
// sistemin python3'ü, o da olmazsa `uv run --offline --no-python-downloads --no-project --python 3.12 --with demucs
// --with librosa` (--offline: uv yalnız önbellekten kurar). song_separate.py ağırlığı yalnız diskten okur. Kurulu değilse
// kip ve motif «ölçülemedi: kulakla» yazılır (K75 buna izin verir; son onay kulaktadır, K60). Ara dosyalar (denetim
// karışımları, ses izleri) işletim sisteminin geçici klasöründedir, oyun klasörüne ses yazılmaz. ffmpeg ister.
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

export const SR = 44100;
const HERE = dirname(fileURLToPath(import.meta.url));
export const GAME = dirname(dirname(HERE));
export const TAKES_DIR = join(GAME, '..', 'docs', 'research', 'bard-takes');
export const VO_LINES = join(GAME, 'data', 'vo_lines.json');
export const KOPUZ_CONTROL = join(GAME, 'audio', 'gen', '_wav', 'kopuz_control_d.wav');
export const OUT_JSON = join(HERE, 'k75_measure.json');
const SEPARATE_PY = join(HERE, 'song_separate.py');
const WORK = join(tmpdir(), 'tanhu-song-measure');

export const DEFAULT_TAKES = Object.freeze([3104, 3105, 3106, 3107]);
// Denetim: kipi bilinen eski çekimler (kopuz.md §7): 3101 D majör (F♯ baskın), 3103 D Dorian.
export const CONTROL_TAKES = Object.freeze({ 3101: 'major', 3103: 'dorian' });
export const CONTROL_GAP_DB = 5;  // 3106'nın söz ile çalgı düzey farkı (audio.md §2 tablosu: 5,0 dB)
export const BAR_S = 2.308;       // 6/8, noktalı dörtlük 52: bir ölçü
const LEAD_DB = -42;              // baştaki sessizliğin sınırı (prototipin bard-song.mjs'i)
export const BOUNDS = Object.freeze({ words: 23, onset: [3, 6], gap: 6, length: [22, 32], polyphony: 3 });
export const COUNTED = Object.freeze({ strokesPerSec: 2.0, hfShare: 0.08, decayDb: 4, levelGapDb: 12, fNatural: 0.7 });
const ONSET_AIM = 4.6;            // 2 ölçü giriş
const GAP_AIM = 4.6;              // dizenin ardından ≈2 ölçü kopuz cevabı
export const MIN_PITCH_FRAMES = 30;
// Sözsüz bölümlerin payları: sözden önceki 0,7 sn soluk sayılmaz (kopuz.md §7), sözcüğün bitişinden sonra 0,25 sn ses
// kuyruğu, dosyanın sonundan 0,1 sn; 0,5 sn'den kısa bölüm atılır.
export const BREATH_S = 0.7;
export const TAIL_S = 0.25;
const MIN_SECTION_S = 0.5;
export const PC_NAMES = Object.freeze(['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']);
// Vuruş ızgarası (bilgi): ana vuruşun dönemi 0,25–0,65 sn'de aranır (1,5–4 vuruş/sn; planın sekizliği 0,385 sn), vuruş ızgara
// noktasına ±35 ms'teyse oturmuş sayılır (K75'in eşlemesi 100 ms'den sık vuruş saymaz: bir noktaya iki vuruş düşmez).
export const GRID = Object.freeze({ min: 0.25, max: 0.65, step: 0.0005, tol: 0.035 });

// ---------------------------------------------------------------------------------------------------------------------
// Ses ve spektrum (prototipten)

function ff(args) {
  const r = spawnSync('ffmpeg', ['-hide_banner', '-nostats', '-v', 'error', ...args], { maxBuffer: 1 << 28 });
  if (r.status !== 0) throw new Error(`ffmpeg başarısız: ${r.stderr?.toString().slice(-400)}`);
  return r;
}

// Ses dosyası → mono Float32 örnekler (44,1 kHz).
export function decode(file) {
  const b = ff(['-i', file, '-ac', '1', '-ar', String(SR), '-f', 'f32le', '-']).stdout;
  return new Float32Array(b.buffer.slice(b.byteOffset, b.byteOffset + b.length));
}

export function fft(re, im) {
  const n = re.length;
  for (let i = 1, j = 0; i < n; i++) {
    let bit = n >> 1;
    for (; j & bit; bit >>= 1) j ^= bit;
    j ^= bit;
    if (i < j) {
      [re[i], re[j]] = [re[j], re[i]];
      [im[i], im[j]] = [im[j], im[i]];
    }
  }
  for (let len = 2; len <= n; len <<= 1) {
    const ang = (-2 * Math.PI) / len;
    const wr = Math.cos(ang), wi = Math.sin(ang);
    for (let i = 0; i < n; i += len) {
      let cr = 1, ci = 0;
      for (let k = 0; k < len / 2; k++) {
        const ar = re[i + k], ai = im[i + k];
        const br = re[i + k + len / 2] * cr - im[i + k + len / 2] * ci;
        const bi = re[i + k + len / 2] * ci + im[i + k + len / 2] * cr;
        re[i + k] = ar + br; im[i + k] = ai + bi;
        re[i + k + len / 2] = ar - br; im[i + k + len / 2] = ai - bi;
        const t = cr * wr - ci * wi; ci = cr * wi + ci * wr; cr = t;
      }
    }
  }
}

const hann = (n) => Float64Array.from({ length: n }, (_, i) => 0.5 - 0.5 * Math.cos((2 * Math.PI * i) / (n - 1)));

// Kısa süreli spektrum: { mags: Float32Array[], times: number[], size }, pencere 2048, adım 512.
export function stft(pcm, from, to, size = 2048, hop = 512) {
  const win = hann(size);
  const mags = [], times = [];
  for (let s = Math.max(0, Math.floor(from * SR)); s + size <= Math.min(pcm.length, Math.floor(to * SR)); s += hop) {
    const re = new Float64Array(size), im = new Float64Array(size);
    for (let i = 0; i < size; i++) re[i] = pcm[s + i] * win[i];
    fft(re, im);
    const m = new Float32Array(size / 2);
    for (let k = 0; k < size / 2; k++) m[k] = Math.hypot(re[k], im[k]);
    mags.push(m);
    times.push((s + size / 2) / SR);
  }
  return { mags, times, size };
}

const bin = (hz, size) => Math.round((hz * size) / SR);
const band = (m, lo, hi, size) => {
  let e = 0;
  for (let k = bin(lo, size); k <= Math.min(m.length - 1, bin(hi, size)); k++) e += m[k] * m[k];
  return e;
};

// Vuruşlar: 1–8 kHz spektral akış, uyarlanır eşik, en az 100 ms ara.
export function onsets(spec) {
  const flux = spec.mags.map((m, t) => {
    if (t === 0) return 0;
    const p = spec.mags[t - 1];
    let f = 0;
    for (let k = bin(1000, spec.size); k <= bin(8000, spec.size); k++) f += Math.max(0, m[k] - p[k]);
    return f;
  });
  const out = [];
  const w = 8;
  // Dronun küçük dalgaları vuruş sayılmasın: yerel ortancanın iki katı ve bölümün %95'lik akışının beşte biri birlikte aşılır.
  const sorted = [...flux].sort((a, b) => a - b);
  const floor = 0.2 * (sorted[Math.floor(sorted.length * 0.95)] ?? 0);
  for (let t = 1; t < flux.length - 1; t++) {
    const lo = Math.max(0, t - w), hi = Math.min(flux.length, t + w + 1);
    const local = flux.slice(lo, hi).sort((a, b) => a - b);
    const med = local[Math.floor(local.length / 2)];
    if (flux[t] > flux[t - 1] && flux[t] >= flux[t + 1] && flux[t] > Math.max(med * 2, floor) + 1e-6) {
      if (!out.length || spec.times[t] - out.at(-1) >= 0.1) out.push(spec.times[t]);
    }
  }
  return out;
}

// YIN temel frekansı (80–700 Hz), 2048 pencere, 512 adım → [{ t, hz }] (sessiz ya da belirsiz karede hz null).
// Önceden ayrılmış ses izinde (--stems) tek sesli izleyicidir; karışık seste kullanılmaz (K75). Prototipten bir fark:
// eşiğin altına inen ilk gecikmede durmaz, yerel en küçüğe iner ve parabolle ara değer bulur (ilk gecikme perdeyi
// yarım ton dek tize kaydırıyordu).
export function yinTrack(pcm, from = 0, to = pcm.length / SR) {
  const size = 2048, hop = 512, maxLag = Math.floor(SR / 80), minLag = Math.floor(SR / 700);
  const out = [];
  const d = new Float64Array(maxLag + 2), cm = new Float64Array(maxLag + 2);
  for (let s = Math.max(0, Math.floor(from * SR)); s + size + maxLag + 1 <= Math.min(pcm.length, Math.floor(to * SR)); s += hop) {
    const t = (s + size / 2) / SR;
    let energy = 0;
    for (let i = 0; i < size; i++) energy += pcm[s + i] * pcm[s + i];
    if (energy / size < 1e-5) { out.push({ t, hz: null }); continue; }
    let run = 0;
    for (let lag = 1; lag <= maxLag + 1; lag++) {
      let sum = 0;
      for (let i = 0; i < size; i++) { const x = pcm[s + i] - pcm[s + i + lag]; sum += x * x; }
      d[lag] = sum;
      run += sum;
      cm[lag] = run > 0 ? (sum * lag) / run : 1;
    }
    let best = null;
    for (let lag = minLag; lag <= maxLag; lag++) {
      if (cm[lag] < 0.15) {
        while (lag < maxLag && cm[lag + 1] < cm[lag]) lag++;
        const den = cm[lag - 1] - 2 * cm[lag] + cm[lag + 1];
        best = lag + (den > 0 ? (0.5 * (cm[lag - 1] - cm[lag + 1])) / den : 0);
        break;
      }
    }
    out.push({ t, hz: best ? SR / best : null });
  }
  return out;
}

const rmsDb = (pcm, ranges) => {
  let e = 0, n = 0;
  for (const [a, b] of ranges) {
    for (let s = Math.max(0, Math.floor(a * SR)); s < Math.min(pcm.length, Math.floor(b * SR)); s++) { e += pcm[s] * pcm[s]; n++; }
  }
  return 10 * Math.log10(e / Math.max(1, n) + 1e-12);
};

// ---------------------------------------------------------------------------------------------------------------------
// Sayılan ölçüler (prototipin measureSong'u; bölümleri ve eşikleri aynı, audio.md §2'nin 3104–3107 tablosunu verir)

export function countedMeasures(pcm, sung) {
  const length = pcm.length / SR;
  const first = sung[0].on, last = sung.at(-1).off;
  const lineBreak = sung.findIndex((w, i) => i > 0 && w.on - sung[i - 1].off > 0.6);
  const lines = lineBreak > 0 ? [[sung[0].on, sung[lineBreak - 1].off], [sung[lineBreak].on, last]] : [[first, last]];
  // Çalgı bölümleri: ilk sözcükten önce ve son sözcükten sonra (audio.md §2: «Giriş ve çıkış»).
  const inst = [[0.1, first - 0.1], [last + 0.25, length - 0.1]].filter(([a, b]) => b - a > 0.8);
  let strokes = 0, instDur = 0, hf = 0, tot = 0;
  const drops = [];
  for (const [a, b] of inst) {
    const spec = stft(pcm, a, b);
    const on = onsets(spec);
    strokes += on.length;
    instDur += b - a;
    for (const m of spec.mags) { hf += band(m, 1280, 16000, spec.size); tot += band(m, 40, 16000, spec.size); }
    // Sönüm eğimi: vuruştan sonra, bir sonraki vuruştan önce (en çok 300 ms, en az 80 ms) 2–6 kHz düşüşü, 100 ms'ye göre.
    on.forEach((t, k) => {
      const next = on[k + 1] ?? t + 1;
      const dt = Math.min(0.3, 0.75 * (next - t));
      if (dt < 0.08) return;
      const i0 = spec.times.findIndex((x) => x >= t);
      const i1 = spec.times.findIndex((x) => x >= t + dt);
      if (i0 < 0 || i1 < 0 || i1 === i0) return;
      const e0 = band(spec.mags[i0], 2000, 6000, spec.size), e1 = band(spec.mags[i1], 2000, 6000, spec.size);
      if (e0 > 0 && e1 > 0) drops.push((10 * Math.log10(e0 / e1)) / ((spec.times[i1] - spec.times[i0]) * 10));
    });
  }
  const median = (xs) => (xs.length ? [...xs].sort((a, b) => a - b)[Math.floor(xs.length / 2)] : 0);
  return {
    strokesPerSec: instDur > 0 ? strokes / instDur : 0,
    hfShare: tot > 0 ? hf / tot : 0,
    decayDb: median(drops),
    levelGapDb: Math.abs(rmsDb(pcm, lines) - rmsDb(pcm, inst)),
  };
}

// ---------------------------------------------------------------------------------------------------------------------
// Vuruş ızgarası (bilgi; K60, K95)
//
// counted.strokesPerSec vuruş sayısını giriş ve çıkışın süresine böler: sessiz baş ve kuyruk paydadadır, süsler paydın üstündedir
// (3104'te 2,12 çıkar, duyulan vuruşlar 0,40 sn arayla gelir). O ölçü K75'te kalır; kolun hızını ve fazını ızgara verir.
// Artan vuruş zamanlarına (sn) en iyi oturan eşit aralıklı ızgarayı bulur: dönem ve faz taranır, puan oturan vuruş sayısının
// rastlantıyla beklenenden (n × 2 tol / dönem) fazlasıdır; böylece dönemin katı (daha az vuruş tutar) ve kısa dönem (rastlantıyla
// çok tutar) öne geçmez. Sonra oturan vuruşlarla en küçük kareler: uzun şarkıda milisaniyelik dönem hatası birikir.
// → { period, anchor (ilk oturan vuruşun ızgara noktası), first ve last (ilk ve son oturan vuruş), lastGrid, strokes, onGrid, share, rmsMs }
export function strokeGrid(strokes, { min, max, step, tol } = GRID) {
  const n = strokes.length;
  if (n < 4) return null;
  let best = null;
  for (let g = min; g <= max + 1e-9; g += step) {
    let hits = 0, phase = 0;
    for (const p of strokes) {
      let h = 0;
      for (const t of strokes) {
        const r = (((t - p) % g) + g) % g;
        if (Math.min(r, g - r) <= tol) h++;
      }
      if (h > hits) { hits = h; phase = p; }
    }
    const score = hits - (n * 2 * tol) / g;
    if (!best || score > best.score) best = { score, period: g, phase };
  }
  let { period, phase } = best;
  const seated = () => strokes.flatMap((t) => {
    const k = Math.round((t - phase) / period);
    return Math.abs(t - (phase + k * period)) <= tol ? [[k, t]] : [];
  });
  for (let it = 0; it < 4; it++) {
    const on = seated();
    const mk = on.reduce((a, [k]) => a + k, 0) / on.length, mt = on.reduce((a, [, t]) => a + t, 0) / on.length;
    let cov = 0, den = 0;
    for (const [k, t] of on) { cov += (k - mk) * (t - mt); den += (k - mk) ** 2; }
    if (den === 0) break;
    period = cov / den;
    phase = mt - period * mk;
  }
  const on = seated();
  const [k0, first] = on[0], [k1, last] = on.at(-1);
  const rms = Math.sqrt(on.reduce((a, [k, t]) => a + (t - (phase + k * period)) ** 2, 0) / on.length);
  return { period, anchor: phase + k0 * period, first, last, lastGrid: phase + k1 * period, strokes: n, onGrid: on.length, share: on.length / n, rmsMs: rms * 1000 };
}

// ---------------------------------------------------------------------------------------------------------------------
// Eş zamanlı perde (K75 sınırı): her karede art arda harmonik çıkarma (kopuz.md §7).
//
// Kare 4096 örnek (93 ms), Hann, 2 kat sıfır dolgulu, 1024 adım. Karenin tonal tepeleri (yerel gürültü tabanının
// %30'luk diliminden ≥8 dB yüksek, karenin en güçlüsünden ≤50 dB aşağı) çıkarılır. Sonra en çok 8 kez: 55–700 Hz'de
// 1/8 yarım ton adımlı adaylardan harmonik toplamı en güçlü olanı seçilir (Klapuri 2006: genlik^0,5, ağırlık
// (f0 + 27) / (h·f0 + 320), h ≤ 16, f ≤ 5 kHz, ±35 sent); temel bir tepe olmalı ve ilk 8 harmoniğin (temel dahil) en az
// ikisi kalan payı ≥%30 olan tepelere düşmeli; temeli zayıf perdenin üst katı seçilmesin diye f0/3 ya da f0/2 en az yarı
// güçteyse o alınır. Seçilen perdenin harmonikleri
// kalan tepelerden komşu-en-büyük kuralıyla düşülür: h. harmoniğe düşen pay min(a_h, max(a_h−1, a_h+1))'dir. Böylece
// biçimlendirici (gövde) tepesi perdenin kendisinde kalır, oktav ya da on ikili katlamada artan harmonik kalanda kalır ve
// ikinci bir perde olarak sayılabilir (Batı tıngırtısında oktav telleri). Durma: aday ilk perdenin %20'sinin altına
// düşerse; bulunmuş perdenin tam katı ya da tam böleni olan aday (akraba) için %30 ve kalan payı ≥%30 olan en az üç
// harmonik gerekir. Son olarak zaman oylaması: yarım tona yuvarlanan perde ±2 karelik (±46 ms) pencerenin en az üç
// karesinde bulunmazsa sayılmaz (vuruş geçişleri ve gürültü). Ölçü, perdesi olan karelerin ortalamasıdır.
//
// 80 Hz değil 55 Hz: 3104–3107'de 60–70 Hz'lik bir dron var; aday 80'de başlarsa onun 2. ve 3. harmoniği iki ayrı perde
// sayılıyor (3104 80 Hz'le 3,05, 55 Hz'le 2,39 veriyor).
export const POLY = Object.freeze({
  size: 4096, pad: 2, hop: 1024,
  fmin: 55, fmax: 700, top: 5000, harmonics: 16, tolCents: 35, step: 0.125,
  alpha: 27, beta: 320, comp: 0.5,
  floorQ: 0.3, floorHz: 40, floorFrac: 0.1, promDb: 8, rangeDb: 50, gateDb: 35,
  hitFrac: 0.3, minHits: 2, minHitsRelated: 3, rho: 0.2, rhoRelated: 0.3, subRatio: 0.5, maxPoly: 8,
  voteFrames: 2, voteNeed: 3,
});

// Duyarlılık: sınır kararının yönteme ne kadar bağlı olduğunu göstermek için aynı ölçü birkaç değişkeyle de alınır
// (yalnız bilgi; sınır POLY'nin değeriyle verilir): yarım adım (oylama aynı süre), daha uzun oylama, daha katı tepe.
// fmin80 planın 80 Hz alt sınırıdır: aralığa girmez, yukarıdaki nedenle yalnız yazılır.
export const POLY_VARIANTS = Object.freeze({
  hop512: { hop: 512, voteFrames: 4, voteNeed: 5 },
  vote70ms: { voteFrames: 3, voteNeed: 4 },
  peak10dB: { promDb: 10 },
  fmin80: { fmin: 80 },
});

function percentile(arr, q) {
  const s = Float64Array.from(arr).sort();
  return s.length ? s[Math.min(s.length - 1, Math.floor(q * s.length))] : 0;
}

// Karenin tonal tepeleri: [{ f, amp }] (frekansa göre sıralı; parabolik ara değer).
export function framePeaks(X, df, o = POLY) {
  const half = X.length;
  const kTop = Math.min(half - 3, Math.ceil(o.top / df));
  const floor = new Float64Array(kTop + 1);
  const step = 3;
  for (let k = 1; k <= kTop; k += step) {
    const w = Math.max(3, Math.round(Math.max(o.floorHz, k * df * o.floorFrac) / df));
    const m = percentile(X.subarray(Math.max(1, k - w), Math.min(half - 1, k + w) + 1), o.floorQ);
    for (let j = k; j < Math.min(kTop + 1, k + step); j++) floor[j] = m;
  }
  let maxX = 0;
  for (let k = 2; k <= kTop; k++) if (X[k] > maxX) maxX = X[k];
  const prom = 10 ** (o.promDb / 20), rel = maxX * 10 ** (-o.rangeDb / 20);
  const peaks = [];
  for (let k = 2; k < kTop; k++) {
    const x = X[k];
    if (x > X[k - 1] && x >= X[k + 1] && x > X[k - 2] && x >= X[k + 2] && x >= floor[k] * prom && x >= rel) {
      const a = Math.log(X[k - 1] + 1e-12), b = Math.log(x + 1e-12), c = Math.log(X[k + 1] + 1e-12);
      const den = a - 2 * b + c;
      const p = den ? (0.5 * (a - c)) / den : 0;
      peaks.push({ f: (k + p) * df, amp: Math.exp(b - 0.25 * (a - c) * p) });
    }
  }
  return peaks;
}

const cents = (a, b) => 1200 * Math.log2(a / b);

function nearestPeak(peaks, f, tol) {
  let lo = 0, hi = peaks.length - 1;
  while (lo < hi) {
    const mid = (lo + hi) >> 1;
    if (peaks[mid].f < f) lo = mid + 1; else hi = mid;
  }
  let best = -1, bc = tol;
  for (let i = lo - 1; i <= lo + 1; i++) {
    if (i < 0 || i >= peaks.length) continue;
    const c = Math.abs(cents(peaks[i].f, f));
    if (c <= bc) { bc = c; best = i; }
  }
  return best;
}

function related(f0, notes, tol) {
  return notes.some((n) => {
    const up = f0 / n.f0, down = n.f0 / f0;
    const ku = Math.round(up), kd = Math.round(down);
    return (ku >= 2 && Math.abs(cents(up, ku)) < tol) || (kd >= 2 && Math.abs(cents(down, kd)) < tol);
  });
}

// Bir karenin perdeleri (MIDI, kesirli): art arda harmonik çıkarma.
export function framePitches(peaks, o = POLY) {
  const orig = peaks.map((pk) => pk.amp ** o.comp);
  const left = orig.slice();
  const notes = [];
  const evaluate = (f0) => {
    let s = 0, hits = 0, f0ok = false;
    const used = [];
    for (let h = 1; h <= o.harmonics && h * f0 <= o.top; h++) {
      const i = nearestPeak(peaks, h * f0, o.tolCents);
      if (i >= 0 && left[i] > 0) {
        s += ((f0 + o.alpha) / (h * f0 + o.beta)) * left[i];
        if (h <= 8 && left[i] >= o.hitFrac * orig[i]) { hits++; if (h === 1) f0ok = true; }
        used.push(i);
      } else used.push(-1);
    }
    return { f0, s, f0ok, used, rel: related(f0, notes, o.tolCents), hits };
  };
  const usable = (c) => c.f0ok && c.hits >= (c.rel ? o.minHitsRelated : o.minHits);
  let first = 0;
  for (let j = 1; j <= o.maxPoly; j++) {
    let best = null;
    for (let m = 69 + 12 * Math.log2(o.fmin / 440); ; m += o.step) {
      const f0 = 440 * 2 ** ((m - 69) / 12);
      if (f0 > o.fmax) break;
      const c = evaluate(f0);
      if (usable(c) && (!best || c.s > best.s)) best = c;
    }
    if (!best) break;
    for (const k of [3, 2]) {
      if (best.f0 / k < o.fmin) continue;
      const c = evaluate(best.f0 / k);
      if (usable(c) && c.s >= o.subRatio * best.s) { best = c; break; }
    }
    if (j === 1) first = best.s;
    else if (best.s < (best.rel ? o.rhoRelated : o.rho) * first) break;
    if (notes.some((n) => Math.abs(cents(n.f0, best.f0)) < 60)) break;
    notes.push(best);
    const amps = best.used.map((i) => (i >= 0 ? left[i] : 0));
    best.used.forEach((i, h) => {
      if (i < 0) return;
      const share = h === 0 ? amps[0] : Math.min(amps[h], Math.max(amps[h - 1], amps[h + 1] ?? 0));
      left[i] = Math.max(0, left[i] - share);
    });
  }
  return notes.map((n) => 69 + 12 * Math.log2(n.f0 / 440));
}

// sections: [{ name, from, to }] → { mean, frames, analyzed, total, sections: [{ name, from, to, mean, frames, pitches }] }
export function polyphony(pcm, sections, o = POLY) {
  const N = o.size * o.pad, half = N / 2, df = SR / N;
  const win = hann(o.size);
  const re = new Float64Array(N), im = new Float64Array(N);
  const frames = [];
  sections.forEach((sec, si) => {
    for (let s = Math.max(0, Math.floor(sec.from * SR)); s + o.size <= Math.min(pcm.length, Math.floor(sec.to * SR)); s += o.hop) {
      re.fill(0); im.fill(0);
      for (let i = 0; i < o.size; i++) re[i] = pcm[s + i] * win[i];
      fft(re, im);
      const X = new Float64Array(half);
      for (let k = 0; k < half; k++) X[k] = Math.hypot(re[k], im[k]);
      let p = 0;
      for (let k = Math.floor(50 / df); k <= Math.ceil(o.top / df); k++) p += X[k] * X[k];
      frames.push({ t: (s + o.size / 2) / SR, si, X, p });
    }
  });
  const gate = percentile(frames.map((f) => f.p), 0.95) * 10 ** (-o.gateDb / 10);
  const sets = frames.map((fr) => (fr.p > 0 && fr.p >= gate ? new Set(framePitches(framePeaks(fr.X, df, o), o).map(Math.round)) : null));
  const counts = sections.map(() => []);
  const timeline = [];
  for (let i = 0; i < frames.length; i++) {
    if (!sets[i]) continue;
    const near = [];
    for (let d = -o.voteFrames; d <= o.voteFrames; d++) if (sets[i + d] && frames[i + d].si === frames[i].si) near.push(sets[i + d]);
    const all = new Set(near.flatMap((s) => [...s]));
    const kept = [...all].filter((p) => near.filter((s) => s.has(p)).length >= o.voteNeed).sort((a, b) => a - b);
    if (kept.length) {
      counts[frames[i].si].push(kept.length);
      timeline.push({ si: frames[i].si, pitches: kept });
    }
  }
  const mean = (xs) => (xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : null);
  const pooled = counts.flat();
  // Bölümün en sık perdeleri (kare sayısıyla): neyin sayıldığını gösterir (ör. dize arasında sürüp giden bir ses).
  const common = (si) => {
    const n = new Map();
    for (const f of timeline) if (f.si === si) for (const p of f.pitches) n.set(p, (n.get(p) ?? 0) + 1);
    return Object.fromEntries([...n].sort((a, b) => b[1] - a[1]).slice(0, 8).map(([p, k]) => [noteName(p), k]));
  };
  return {
    mean: mean(pooled),
    frames: pooled.length,
    analyzed: sets.filter(Boolean).length,
    total: frames.length,
    sections: sections.map((sec, si) => ({ ...sec, mean: mean(counts[si]), frames: counts[si].length, pitches: common(si) })),
  };
}

export const noteName = (midi) => `${PC_NAMES[((midi % 12) + 12) % 12]}${Math.floor(midi / 12) - 1}`;

// ---------------------------------------------------------------------------------------------------------------------
// Denetim sinyalleri (sınamalar ve JSON'un «calibration» bölümü): Karplus-Strong tel, tohumlu.

export function rng(seed) {
  let s = seed >>> 0 || 1;
  return () => {
    s ^= s << 13; s >>>= 0; s ^= s >>> 17; s ^= s << 5; s >>>= 0;
    return s / 4294967296;
  };
}

export const midiHz = (m) => 440 * 2 ** ((m - 69) / 12);

// Tek tel (prototipin dombra.js'i gibi): gürültü darbesi, çekme konumu tarağı, kayıp süzgeci, kesir gecikme; out'a eklenir.
function pluck(out, hz, t0, dur, { gain, t60, pos, soft, r }) {
  const period = SR / hz;
  const loss = 0.5;
  const len = Math.floor(period - loss - 0.1);
  const frac = period - loss - len;
  const c = (1 - frac) / (1 + frac);
  const rho = 10 ** (-3 / (hz * t60));
  const line = new Float32Array(len);
  let lp = 0;
  for (let i = 0; i < len; i++) { lp += (r() * 2 - 1 - lp) * (1 - soft); line[i] = lp; }
  const comb = Math.max(1, Math.round(pos * len));
  for (let i = len - 1; i >= comb; i--) line[i] -= line[i - comb];
  let mean = 0;
  for (let i = 0; i < len; i++) mean += line[i];
  for (let i = 0; i < len; i++) line[i] -= mean / len;
  const s0 = Math.floor(t0 * SR), n = Math.min(out.length - s0, Math.floor(dur * SR));
  const fade = Math.floor(0.01 * SR);
  let idx = 0, prev = 0, apX = 0, apY = 0;
  for (let i = 0; i < n; i++) {
    const x = line[idx];
    const avg = rho * (loss * x + (1 - loss) * prev);
    prev = x;
    const y = c * avg + apX - c * apY;
    apX = avg; apY = y;
    line[idx] = y;
    idx = idx + 1 === len ? 0 : idx + 1;
    out[s0 + i] += gain * x * (i > n - fade ? (n - i) / fade : 1);
  }
}

// Batı tıngırtısı: altı telli gitar, G C D Em akorları, saniyede 2,6 vuruş (aşağı ve yukarı), teller arası 9 ms tarama.
export function synthWesternStrum(seconds = 8, seed = 1) {
  const r = rng(seed);
  const out = new Float32Array(Math.floor(seconds * SR));
  const chords = [[43, 47, 50, 55, 59, 67], [48, 52, 55, 60, 64], [50, 57, 62, 66], [40, 47, 52, 55, 59, 64]];
  let k = 0;
  for (let t = 0.05; t < seconds - 0.2; t += 1 / 2.6, k++) {
    const chord = chords[Math.floor(k / 4) % chords.length];
    const down = k % 2 === 0;
    const order = chord.map((_, i) => (down ? i : chord.length - 1 - i));
    order.forEach((si, j) => {
      const hz = midiHz(chord[si]);
      const at = t + j * 0.009;
      pluck(out, hz, at, Math.min(seconds - at, 3), { gain: 0.16, t60: 2.4 * (110 / hz) ** 0.3, pos: 0.12 + r() * 0.05, soft: down ? 0.6 : 0.75, r });
    });
  }
  return out;
}

// Kopuz (K60): ezgi bir telde (D4–A4 arası, her notası iki vuruş, aynı telde yeni nota eskisini keser), D3 ve A3 açık
// dron her üç vuruşta bir çalınır ve çınlar; saniyede 2,6 vuruş. Aynı anda en çok üç tel.
export function synthKopuzDrone(seconds = 8, seed = 2) {
  const r = rng(seed);
  const out = new Float32Array(Math.floor(seconds * SR));
  const melody = [62, 64, 65, 67, 69, 67, 65, 64, 62, 60, 62, 64, 69, 67, 65, 62];
  let k = 0;
  for (let t = 0.05; t < seconds - 0.2; t += 1 / 2.6, k++) {
    const note = midiHz(melody[Math.floor(k / 2) % melody.length]);
    pluck(out, note, t, Math.min(1 / 2.6 + 0.01, seconds - t), { gain: 0.22, t60: 1.5 * (146.8 / note) ** 0.35, pos: 0.1, soft: 0.5, r });
    if (k % 3 === 0) {
      const ring = Math.min(3 / 2.6 + 0.01, seconds - t);
      pluck(out, midiHz(50), t + 0.009, ring, { gain: 0.2, t60: 1.5, pos: 0.1, soft: 0.5, r });
      pluck(out, midiHz(57), t + 0.018, ring, { gain: 0.18, t60: 1.5 * (146.8 / 220) ** 0.35, pos: 0.1, soft: 0.5, r });
    }
  }
  return out;
}

// ---------------------------------------------------------------------------------------------------------------------
// Sözcükler ve bölümler

// Söylenen sözcükler: süresi olan, yönerge ({…}) ve bölüm başlığı ([…]) dışındakiler → [{ word, on, off }] (sn).
// Yönerge birkaç sözcüktür («{the komuz gallops on alone}»): ayracın içindeki bütün sözcükler atlanır.
export function sungWords(meta) {
  const out = [];
  let inside = false;
  for (const w of meta.words_timestamps ?? []) {
    const opens = /[{[]/.test(w.word), closes = /[}\]]/.test(w.word);
    if (opens || inside) {
      inside = !closes;
      continue;
    }
    if (w.end_ms > w.start_ms) out.push({ word: w.word, on: w.start_ms / 1000, off: w.end_ms / 1000 });
  }
  return out;
}

const norm = (s) => s.toLowerCase().replace(/[^a-z]/g, '');

// Şarkının sözcükleri sırayla, vo_lines.json'daki altyazı satırlarının (of: act0.bard.song) İngilizce metninden:
// [{ word, line }] (line 1'den başlar).
export function expectedWords(voLines = JSON.parse(readFileSync(VO_LINES, 'utf8')), songId = 'act0.bard.song') {
  const subs = voLines.lines.filter((l) => l.of === songId).sort((a, b) => (a.window?.[0] ?? 0) - (b.window?.[0] ?? 0));
  if (!subs.length) throw new Error(`vo_lines.json'da ${songId} altyazısı yok`);
  return subs.flatMap((l, i) => l.text.en.split(/\s+/).map(norm).filter(Boolean).map((word) => ({ word, line: i + 1 })));
}

export const wordsMatch = (sung, expected) => sung.length === expected.length && sung.every((w, i) => norm(w.word) === expected[i].word);

// Dize sınırı (ikinci dizenin ilk sözcüğünün sırası): sözler doğruysa altyazıdan; değilse sözcükler arasındaki en uzun ara.
export function lineSplit(sung, expected = null) {
  if (expected && wordsMatch(sung, expected)) return expected.findIndex((w) => w.line === 2);
  let best = -1, gap = 0;
  for (let i = 1; i < sung.length; i++) {
    const g = sung[i].on - sung[i - 1].off;
    if (g > gap) { gap = g; best = i; }
  }
  return best;
}

// Dizelerin söz pencereleri: [[on, off], …].
export function lineWindows(sung, split) {
  return split > 0 ? [[sung[0].on, sung[split - 1].off], [sung[split].on, sung.at(-1).off]] : [[sung[0].on, sung.at(-1).off]];
}

// Sözsüz bölümler (K75): giriş, dize arası cevap, çıkış; lead baştaki sessizlik, end dosyanın sonu (sn).
export function silentSections(sung, split, lead, end) {
  const out = [{ name: 'giriş', from: lead + 0.05, to: sung[0].on - BREATH_S }];
  if (split > 0) out.push({ name: 'dize arası', from: sung[split - 1].off + TAIL_S, to: sung[split].on - BREATH_S });
  out.push({ name: 'çıkış', from: sung.at(-1).off + TAIL_S, to: end - 0.1 });
  return out.filter((s) => s.to - s.from >= MIN_SECTION_S);
}

export function leadSilence(pcm) {
  const floor = 10 ** (LEAD_DB / 20);
  let first = 0;
  while (first < pcm.length && Math.abs(pcm[first]) < floor) first++;
  return Math.max(0, first / SR - 0.02);
}

// ---------------------------------------------------------------------------------------------------------------------
// Söz kipi ve motif (ayrılmış ses izinde)

// track: [{ t, hz }] (hz null: perdesiz). Akort sapması (yarım tonun kesri, dairesel ortalama) düşülür, sonra yuvarlanır.
export function pitchFrames(track, windows) {
  const inside = track.filter((p) => p.hz && windows.some(([a, b]) => p.t >= a && p.t <= b));
  let x = 0, y = 0;
  for (const p of inside) {
    const m = 69 + 12 * Math.log2(p.hz / 440);
    x += Math.cos(2 * Math.PI * m); y += Math.sin(2 * Math.PI * m);
  }
  const tuning = inside.length ? Math.atan2(y, x) / (2 * Math.PI) : 0;
  return { tuningCents: Math.round(tuning * 100), frames: inside.map((p) => ({ t: p.t, midi: Math.round(69 + 12 * Math.log2(p.hz / 440) - tuning) })) };
}

// Nota dizisi: aynı yarım ton en az minRun kare (≈35 ms) sürünce nota sayılır; ardışık aynı perde sınıfı birleşir.
export function noteNames(frames, minRun = 3) {
  const out = [];
  let run = 0;
  for (let i = 0; i < frames.length; i++) {
    run = i > 0 && frames[i].midi === frames[i - 1].midi ? run + 1 : 1;
    const name = PC_NAMES[((frames[i].midi % 12) + 12) % 12];
    if (run === minRun && out.at(-1) !== name) out.push(name);
  }
  return out;
}

// A→G→F→D: E geçiş notasıdır (kopuz.md §7: «A G F E D»), atılır; ardışık aynı ad birleşir.
export function hasMotif(names) {
  const seq = names.filter((n) => n !== 'E').filter((n, i, a) => i === 0 || a[i - 1] !== n);
  for (let i = 0; i + 3 < seq.length; i++) if (seq[i] === 'A' && seq[i + 1] === 'G' && seq[i + 2] === 'F' && seq[i + 3] === 'D') return true;
  return false;
}

export const modeClass = (f) => (f === null ? null : f >= COUNTED.fNatural ? 'dorian' : f <= 1 - COUNTED.fNatural ? 'major' : 'mixed');
export const MODE_TR = Object.freeze({ dorian: 'D Dorian (doğal F)', major: 'D majör (F♯)', mixed: 'karışık' });

// Söz kipi ve motif: windows dizelerin söz pencereleri. 30 kareden az perde ya da 30 kareden az F/F♯ → ölçülemedi.
export function vocalMeasures(track, windows) {
  const all = pitchFrames(track, windows.map(([a, b]) => [a - 0.1, b + 0.3]));
  const hist = Object.fromEntries(PC_NAMES.map((n) => [n, 0]));
  for (const f of all.frames) hist[PC_NAMES[((f.midi % 12) + 12) % 12]]++;
  const f = hist.F, fs = hist['F#'];
  const measurable = all.frames.length >= MIN_PITCH_FRAMES;
  const fNatural = measurable && f + fs >= MIN_PITCH_FRAMES ? f / (f + fs) : null;
  // Motif her dizenin son üç ölçüsünde (en çok dizenin başına dek) aranır.
  const motifLines = windows.map(([a, b]) => {
    const w = pitchFrames(track, [[Math.max(a, b - 3 * BAR_S), b + 0.3]]);
    return w.frames.length >= MIN_PITCH_FRAMES ? { found: hasMotif(noteNames(w.frames)), notes: noteNames(w.frames).join(' ') } : null;
  });
  return {
    frames: all.frames.length,
    tuningCents: all.tuningCents,
    histogram: hist,
    fNatural,
    mode: modeClass(fNatural),
    status: measurable ? (fNatural === null ? 'ölçülemedi: F ya da F♯ 30 kareden az' : 'ölçüldü') : 'ölçülemedi: 30 kareden az perde',
    motif: {
      lines: motifLines,
      both: motifLines.length > 1 && motifLines.every((l) => l?.found),
      any: motifLines.some((l) => l?.found),
      measurable: motifLines.every(Boolean),
    },
  };
}

// ---------------------------------------------------------------------------------------------------------------------
// Ayırma (isteğe bağlı): song_separate.py ya da önceden ayrılmış ses izleri

// Ayırma betiğini koşturacak yorumlayıcılar, sırayla: SONG_SEPARATE_PYTHON verilmişse yalnız o; değilse sistemin python3'ü
// ve uv'nin önbellekten (--offline) kurduğu Python 3.12. İlk yoklamayı geçen kullanılır.
function separatorCandidates() {
  if (process.env.SONG_SEPARATE_PYTHON) return [{ label: 'SONG_SEPARATE_PYTHON', cmd: process.env.SONG_SEPARATE_PYTHON, base: [SEPARATE_PY] }];
  return [
    { label: 'python3', cmd: 'python3', base: [SEPARATE_PY] },
    {
      label: 'uv --offline, Python 3.12',
      cmd: 'uv',
      base: ['run', '--offline', '--no-python-downloads', '--no-project', '--python', '3.12', '--with', 'demucs', '--with', 'librosa', 'python', SEPARATE_PY],
    },
  ];
}

function runSeparator(cand, args, timeout) {
  mkdirSync(WORK, { recursive: true });
  const env = { ...process.env, NUMBA_CACHE_DIR: join(WORK, 'numba'), HF_HUB_OFFLINE: '1', UV_OFFLINE: '1', PYTHONDONTWRITEBYTECODE: '1' };
  return spawnSync(cand.cmd, [...cand.base, ...args], { env, timeout, maxBuffer: 1 << 26 });
}

// Hatanın ilk iki satırı (uv'nin ve betiğin iletisi orada).
const tail = (r) => `${r.error?.message ?? ''}\n${r.stderr?.toString() ?? ''}`.split('\n').map((l) => l.trim()).filter(Boolean).slice(0, 2).join(' / ').slice(0, 240);

// → { available, backend, model?, cand?, reason? }. stems: önceden ayrılmış ses izlerinin klasörü.
export function separationBackend({ stems = null, disabled = false } = {}) {
  if (disabled) return { available: false, backend: null, reason: '--no-separate' };
  if (stems) return existsSync(stems) ? { available: true, backend: 'stems', dir: stems, model: 'önceden ayrılmış ses izi + YIN' } : { available: false, backend: 'stems', reason: `klasör yok: ${stems}` };
  const reasons = [];
  for (const cand of separatorCandidates()) {
    const r = runSeparator(cand, ['--probe'], 180000);
    if (r.status === 0) {
      try {
        const info = JSON.parse(r.stdout.toString().trim().split('\n').at(-1));
        return { available: true, backend: 'demucs', cand, model: `${info.model} (Demucs ${info.demucs}, ${cand.label}) + librosa.pyin ${info.librosa}` };
      } catch {
        reasons.push(`${cand.label}: yoklama çıktısı okunamadı`);
        continue;
      }
    }
    reasons.push(`${cand.label}: ${tail(r) || `çıkış ${r.status}`}`);
  }
  return { available: false, backend: 'demucs', reason: `Demucs kullanılamıyor, indirme yapılmaz (${reasons.join('; ')})` };
}

// Önbellek anahtarı dosyanın içeriğidir: aynı karışım yeniden yazılınca ayırma yinelenmez.
const fileKey = (file) => createHash('sha1').update(readFileSync(file)).digest('hex').slice(0, 12);

// Ses izinin perde dizisi: [{ t, hz }] ya da { error }. name: ses izi adı (--stems'te dosya adı).
export function vocalTrack(sep, file, name) {
  if (sep.backend === 'stems') {
    const stem = ['wav', 'flac', 'mp3'].map((e) => join(sep.dir, `${name}.${e}`)).find(existsSync);
    return stem ? yinTrack(decode(stem)) : { error: `ses izi yok: ${join(sep.dir, `${name}.wav`)}` };
  }
  mkdirSync(WORK, { recursive: true });
  const out = join(WORK, `${name}-${fileKey(file)}.f0.json`);
  if (!existsSync(out)) {
    const r = runSeparator(sep.cand, [file, out, `--stem-out=${join(WORK, `${name}-vocals.wav`)}`], 1800000);
    if (r.status !== 0 || !existsSync(out)) return { error: `ayırma başarısız: ${tail(r)}` };
  }
  const j = JSON.parse(readFileSync(out, 'utf8'));
  return j.f0.map((hz, i) => ({ t: (i * j.hop) / j.sr, hz }));
}

// Denetim karışımı: çekimin söz pencerelerindeki düzeyden CONTROL_GAP_DB aşağıda kodla kopuz (ffmpeg amix).
export function controlGainDb(takePcm, windows, kopuzPcm) {
  return rmsDb(takePcm, windows) - CONTROL_GAP_DB - rmsDb(kopuzPcm, [[0, kopuzPcm.length / SR]]);
}

export function mixControl(takeFile, kopuzFile, gainDb, out) {
  ff(['-y', '-i', takeFile, '-i', kopuzFile, '-filter_complex',
    `[0:a]aresample=${SR},aformat=sample_fmts=fltp:channel_layouts=mono[v];` +
    `[1:a]aresample=${SR},aformat=sample_fmts=fltp:channel_layouts=mono,volume=${gainDb.toFixed(2)}dB[k];` +
    '[v][k]amix=inputs=2:duration=first:normalize=0[m]', '-map', '[m]', '-c:a', 'pcm_f32le', out]);
  return out;
}

// Denetim (K75): 3101 ve 3103 kodla kopuzla karıştırılır; araç ikisinin kipini doğru bulursa söz kipi sayılan ölçü olur.
export function runControl(sep, { takesDir = TAKES_DIR, kopuz = KOPUZ_CONTROL } = {}) {
  const base = { gapDb: CONTROL_GAP_DB, kopuz: relative(GAME, kopuz), takes: {} };
  if (!existsSync(kopuz)) return { ...base, ran: false, passed: false, reason: `denetim kopuzu yok: ${relative(GAME, kopuz)}` };
  if (!sep.available) return { ...base, ran: false, passed: false, reason: `ayırma yok: ${sep.reason}` };
  const kopuzPcm = decode(kopuz);
  mkdirSync(WORK, { recursive: true });
  let passed = true, ran = true;
  for (const [seed, expected] of Object.entries(CONTROL_TAKES)) {
    const meta = JSON.parse(readFileSync(join(takesDir, `${seed}.json`), 'utf8'));
    const file = join(takesDir, `${seed}.mp3`);
    const sung = sungWords(meta);
    const windows = lineWindows(sung, lineSplit(sung));
    const gainDb = controlGainDb(decode(file), windows, kopuzPcm);
    const mix = mixControl(file, kopuz, gainDb, join(WORK, `control_${seed}.wav`));
    const track = vocalTrack(sep, mix, `control_${seed}`);
    if (track.error) {
      base.takes[seed] = { expected, error: track.error, mix };
      passed = ran = false;
      continue;
    }
    const v = vocalMeasures(track, windows);
    const ok = v.mode === expected;
    passed &&= ok;
    base.takes[seed] = { expected, found: v.mode, fNatural: round(v.fNatural), frames: v.frames, ok, kopuzGainDb: round(gainDb, 2) };
  }
  return { ...base, ran, passed, ...(ran ? {} : { reason: 'denetim karışımının ses izi çıkarılamadı' }) };
}

// ---------------------------------------------------------------------------------------------------------------------
// Çekimin ölçüsü

const round = (x, d = 3) => (x === null || x === undefined || Number.isNaN(x) ? null : Math.round(x * 10 ** d) / 10 ** d);

export function measureTake(seed, { takesDir = TAKES_DIR, expected = expectedWords(), sep = { available: false, reason: '' }, controlPassed = false } = {}) {
  const meta = JSON.parse(readFileSync(join(takesDir, `${seed}.json`), 'utf8'));
  const file = join(takesDir, `${seed}.mp3`);
  const pcm = decode(file);
  const sung = sungWords(meta);
  if (!sung.length) throw new Error(`${seed}: sözcük zamanı yok`);
  const lead = leadSilence(pcm);
  const end = pcm.length / SR;
  const length = end - lead;
  const split = lineSplit(sung, expected);
  const onset = sung[0].on - lead;
  const gap = split > 0 ? sung[split].on - sung[split - 1].off : null;
  const silent = silentSections(sung, split, lead, end);
  const poly = polyphony(pcm, silent);
  const variants = Object.fromEntries(Object.entries(POLY_VARIANTS).map(([k, v]) => [k, round(polyphony(pcm, silent, { ...POLY, ...v }).mean, 2)]));
  const spread = [round(poly.mean, 2), ...Object.entries(variants).filter(([k]) => k !== 'fmin80').map(([, v]) => v)].filter((v) => v !== null);
  const c = countedMeasures(pcm, sung);
  const windows = lineWindows(sung, split);
  // Izgara bütün dosyanın vuruşlarından, saatler işlenmiş dosyanındır (baştaki sessizlik kesilir: onset ve boy gibi).
  const grid = strokeGrid(onsets(stft(pcm, lead, end)).map((t) => t - lead));

  const bounds = {
    words: { value: sung.length, ok: wordsMatch(sung, expected), sung: sung.map((w) => w.word).join(' ') },
    onset: { value: round(onset), ok: onset >= BOUNDS.onset[0] && onset <= BOUNDS.onset[1] },
    gap: { value: round(gap), ok: gap !== null && gap <= BOUNDS.gap },
    length: { value: round(length), ok: length >= BOUNDS.length[0] && length <= BOUNDS.length[1] },
    polyphony: {
      value: round(poly.mean, 2),
      ok: poly.mean !== null && poly.mean <= BOUNDS.polyphony,
      frames: poly.frames,
      analyzed: poly.analyzed,
      total: poly.total,
      range: spread.length ? [Math.min(...spread), Math.max(...spread)] : null,
      variants,
      sections: poly.sections.map((s) => ({ name: s.name, from: round(s.from, 2), to: round(s.to, 2), mean: round(s.mean, 2), frames: s.frames, pitches: s.pitches })),
    },
  };
  const counted = {
    strokesPerSec: { value: round(c.strokesPerSec, 2), ok: c.strokesPerSec >= COUNTED.strokesPerSec },
    hfShare: { value: round(c.hfShare, 5), ok: c.hfShare >= COUNTED.hfShare },
    decayDb: { value: round(c.decayDb, 1), ok: c.decayDb >= COUNTED.decayDb },
    levelGapDb: { value: round(c.levelGapDb, 1), ok: c.levelGapDb <= COUNTED.levelGapDb },
  };
  // Söz kipi ve motif: yalnız ayrılmış ses izinde (K75).
  let vocal = { status: 'ölçülemedi: kulakla', reason: sep.available ? '' : `ayırma yok: ${sep.reason}` };
  if (sep.available) {
    const track = vocalTrack(sep, file, String(seed));
    if (track.error) vocal = { status: 'ölçülemedi: kulakla', reason: track.error };
    else {
      const v = vocalMeasures(track, windows);
      vocal = { ...v, fNatural: round(v.fNatural), reason: '' };
      if (v.status !== 'ölçüldü') vocal.status = `${v.status}: kulakla`;
    }
  }
  const info = {
    fNatural: { class: controlPassed ? 'sayılan' : 'bilgi', value: vocal.fNatural ?? null, mode: vocal.mode ?? null, status: vocal.status },
    motif: {
      value: vocal.motif ? vocal.motif.both : null,
      lines: vocal.motif ? vocal.motif.lines : null,
      status: vocal.motif?.measurable ? (vocal.motif.both ? 'iki dizede var' : vocal.motif.any ? 'bir dizede var' : 'bulunamadı') : 'ölçülemedi: kulakla',
    },
    vocal: { frames: vocal.frames ?? 0, tuningCents: vocal.tuningCents ?? null, histogram: vocal.histogram ?? null, reason: vocal.reason },
    strokeGrid: grid ? {
      class: 'bilgi',
      period: round(grid.period, 4),
      strokesPerSec: round(1 / grid.period),
      anchor: round(grid.anchor),
      first: round(grid.first),
      last: round(grid.last),
      lastGrid: round(grid.lastGrid),
      strokes: grid.strokes,
      onGrid: grid.onGrid,
      share: round(grid.share, 2),
      rmsMs: round(grid.rmsMs, 0),
    } : { class: 'bilgi', status: 'ölçülemedi: 4 vuruştan az' },
  };
  if (controlPassed && vocal.fNatural !== null && vocal.fNatural !== undefined) counted.fNatural = { value: vocal.fNatural, ok: vocal.fNatural >= COUNTED.fNatural };
  const misses = Object.entries(bounds).filter(([, b]) => !b.ok).map(([k]) => k);
  const score = Math.abs(onset - ONSET_AIM) + 0.5 * Math.abs((gap ?? 0) - GAP_AIM) + Math.max(0, BOUNDS.length[0] - length) + Math.max(0, length - BOUNDS.length[1]);
  const passed = Object.values(counted).filter((m) => m.ok).length;
  return {
    seed,
    file: relative(GAME, file),
    lead: round(lead),
    fits: misses.length === 0,
    misses,
    bounds,
    counted,
    passed,
    total: Object.keys(counted).length,
    info,
    score: round(score, 2),
  };
}

// Sıra: sınırlara uyan önce, sonra geçen sayılan ölçülerin oranı, sonra puan (audio.md §2 «Sıra»).
export const rank = (rows) => [...rows].sort((a, b) => Number(b.fits) - Number(a.fits) || b.passed / b.total - a.passed / a.total || a.score - b.score);

// ---------------------------------------------------------------------------------------------------------------------
// Rapor

const num = (x, d) => (x === null || x === undefined ? '—' : x.toFixed(d).replace('.', ','));
const mark = (ok) => (ok ? '✓' : '✗');
const pad = (s, n) => String(s).padEnd(n);

export function table(rows) {
  const head = [
    `${pad('Tohum', 6)}│ ${pad('SINIR: sözcük', 14)}${pad('giriş', 9)}${pad('dize arası', 12)}${pad('boy', 9)}${pad('eş zamanlı perde', 18)}` +
      `│ ${pad('SAYILAN: vuruş/sn', 18)}${pad('1,28 kHz üstü', 15)}${pad('sönüm', 9)}${pad('düzey farkı', 13)}│ BİLGİ: söz kipi; motif; vuruş ızgarası`,
  ];
  const lines = rows.map((r) => {
    const b = r.bounds, c = r.counted;
    const kip = r.info.fNatural.value === null ? r.info.fNatural.status : `${num(r.info.fNatural.value, 2)} ${MODE_TR[r.info.fNatural.mode] ?? ''} (${r.info.fNatural.class})`;
    const g = r.info.strokeGrid;
    const izgara = g.period ? `${num(g.period, 3)} sn, ilk ${num(g.first, 2)}, %${num(g.share * 100, 0)} (${g.onGrid}/${g.strokes})` : g.status;
    return `${pad(r.seed, 6)}│ ${pad(`${b.words.value} ${mark(b.words.ok)}`, 14)}${pad(`${num(b.onset.value, 2)} ${mark(b.onset.ok)}`, 9)}` +
      `${pad(`${num(b.gap.value, 2)} ${mark(b.gap.ok)}`, 12)}${pad(`${num(b.length.value, 2)} ${mark(b.length.ok)}`, 9)}` +
      `${pad(`${num(b.polyphony.value, 2)} ${mark(b.polyphony.ok)}`, 18)}│ ${pad(`${num(c.strokesPerSec.value, 2)} ${mark(c.strokesPerSec.ok)}`, 18)}` +
      `${pad(`%${num(c.hfShare.value * 100, 1)} ${mark(c.hfShare.ok)}`, 15)}${pad(`${num(c.decayDb.value, 1)} ${mark(c.decayDb.ok)}`, 9)}` +
      `${pad(`${num(c.levelGapDb.value, 1)} ${mark(c.levelGapDb.ok)}`, 13)}│ ${kip}; ${r.info.motif.status}; ${izgara}`;
  });
  return [...head, ...lines].join('\n');
}

function calibration() {
  const sec = (s) => [{ name: 'tümü', from: 0, to: s }];
  const out = {
    western_strum: round(polyphony(synthWesternStrum(8, 1), sec(8)).mean, 2),
    kopuz_drone_melody: round(polyphony(synthKopuzDrone(8, 2), sec(8)).mean, 2),
  };
  if (existsSync(KOPUZ_CONTROL)) {
    const k = decode(KOPUZ_CONTROL);
    out.kopuz_control_d = round(polyphony(k, [{ name: 'tümü', from: 0.05, to: k.length / SR - 0.1 }]).mean, 2);
  }
  return out;
}

const localDate = () => {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
};

export function run({ takes = DEFAULT_TAKES, takesDir = TAKES_DIR, write = true, out = OUT_JSON, separate = true, stems = null, log = console.log } = {}) {
  const expected = expectedWords();
  if (expected.length !== BOUNDS.words) throw new Error(`altyazıda ${expected.length} sözcük var, ${BOUNDS.words} bekleniyordu`);
  const sep = separationBackend({ stems, disabled: !separate });
  const control = runControl(sep, { takesDir });
  const rows = takes.map((seed) => measureTake(seed, { takesDir, expected, sep, controlPassed: control.passed }));
  const order = rank(rows);
  const s3106 = rows.find((r) => r.seed === 3106);
  const result = {
    tool: 'tools/song/song_measure.mjs',
    decision: 'K75',
    date: localDate(),
    takesDir: relative(GAME, takesDir),
    thresholds: { bounds: BOUNDS, counted: COUNTED },
    polyphonyMethod: {
      ...POLY,
      sections: `giriş, dize arası, çıkış (sözden önce ${num(BREATH_S, 1)} sn soluk, sözcükten sonra ${num(TAIL_S, 2)} sn kuyruk düşülür)`,
      variants: POLY_VARIANTS,
    },
    strokeGridMethod: GRID,
    calibration: calibration(),
    separation: { available: sep.available, backend: sep.backend, model: sep.model ?? null, reason: sep.reason ?? '' },
    control,
    takes: rows,
    ranking: order.map((r) => r.seed),
    polyphony3106: s3106 ? { value: s3106.bounds.polyphony.value, ok: s3106.bounds.polyphony.ok, range: s3106.bounds.polyphony.range } : null,
  };
  log(`K75 şarkı ölçüsü (kredisiz): ${takes.join(', ')} · ${relative(GAME, takesDir)}`);
  log(table(rows));
  log(`Eş zamanlı perde, denetim sinyalleri: Batı tıngırtısı ${num(result.calibration.western_strum, 2)}, tek tel ezgi + açık dron ` +
    `${num(result.calibration.kopuz_drone_melody, 2)}${result.calibration.kopuz_control_d === undefined ? '' : `, kodla kopuz (kopuz_control_d) ${num(result.calibration.kopuz_control_d, 2)}`}`);
  const span = (p) => (p.range ? `${num(p.range[0], 2)}–${num(p.range[1], 2)}` : '—');
  for (const r of rows) {
    const p = r.bounds.polyphony;
    log(`  ${r.seed} eş zamanlı perde ${num(p.value, 2)} (duyarlılık ${span(p)}; 80 Hz'le ${num(p.variants.fmin80, 2)}): ` +
      `${p.sections.map((s) => `${s.name} ${num(s.mean, 2)} (${s.frames} kare)`).join(', ')}`);
  }
  log(`Ayırma: ${sep.available ? sep.model : `yok (${sep.reason})`}`);
  log(`Denetim (3101 D majör, 3103 D Dorian; kodla kopuz ${CONTROL_GAP_DB} dB altta): ${control.ran ? (control.passed ? 'geçti: söz kipi sayılan ölçü' : 'geçmedi: söz kipi bilgi kalır') : `koşulamadı (${control.reason}): söz kipi bilgi kalır`}`);
  log(`Sıra: ${order.map((r) => `${r.seed}${r.fits ? '' : ` (sınır dışı: ${r.misses.join(', ')})`} ${r.passed}/${r.total}`).join(' > ')}`);
  if (s3106) {
    const p = s3106.bounds.polyphony;
    log(p.ok
      ? `3106 eş zamanlı perde sınırını geçiyor: ${num(p.value, 2)} ≤ ${BOUNDS.polyphony} (duyarlılık ${span(p)})`
      : `UYARI: 3106 eş zamanlı perde sınırını geçmiyor (${num(p.value, 2)} > ${BOUNDS.polyphony}): kullanıcı dinlemeden önce söylenmeli`);
  }
  if (write) {
    writeFileSync(out, `${JSON.stringify(result, null, 1)}\n`);
    log(`Yazıldı: ${relative(GAME, out)}`);
  }
  return result;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const args = process.argv.slice(2);
  const opt = (name) => args.find((a) => a.startsWith(`--${name}=`))?.slice(name.length + 3);
  try {
    // k75_measure.json K75 koşusudur (3104–3107): başka çekim kümesi yalnız --out verilirse yazılır.
    const takes = opt('takes') ? opt('takes').split(',').map(Number) : DEFAULT_TAKES;
    const subset = takes.join() !== DEFAULT_TAKES.join();
    if (subset && !opt('out') && !args.includes('--no-write')) console.log('--takes: k75_measure.json yazılmaz (--out=<yol> ile yazılır)');
    run({
      takes,
      takesDir: opt('takes-dir') ?? TAKES_DIR,
      write: !args.includes('--no-write') && (!subset || Boolean(opt('out'))),
      out: opt('out') ?? OUT_JSON,
      separate: !args.includes('--no-separate'),
      stems: opt('stems') ?? null,
    });
  } catch (e) {
    console.error(e.message);
    process.exitCode = 1;
  }
}
