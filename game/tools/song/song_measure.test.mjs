// tools/song/song_measure.mjs sınamaları (K75): node --test tools/song/song_measure.test.mjs
// GDScript koşusuna girmez (tools/run_tests.sh değil). ffmpeg ister; gerçek çekim sınamaları ../docs/research/bard-takes'i
// okur. Demucs sınaması yalnız Demucs kuruluysa koşar (hiçbir şey indirilmez), değilse atlanır.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import {
  BAR_S, BOUNDS, KOPUZ_CONTROL, MIN_PITCH_FRAMES, OUT_JSON, SR, TAKES_DIR,
  controlGainDb, countedMeasures, decode, expectedWords, hasMotif, lineSplit, lineWindows, measureTake, midiHz,
  mixControl, noteNames, polyphony, run, runControl, separationBackend, silentSections, strokeGrid, sungWords,
  synthKopuzDrone, synthWesternStrum, vocalMeasures, yinTrack,
} from './song_measure.mjs';

const whole = (seconds) => [{ name: 'tümü', from: 0, to: seconds }];
const take = (seed) => join(TAKES_DIR, `${seed}.mp3`);
const haveTakes = [3101, 3106].every((s) => existsSync(take(s)) && existsSync(join(TAKES_DIR, `${s}.json`)));
const rms = (pcm, from, to) => {
  let e = 0, n = 0;
  for (let s = Math.floor(from * SR); s < Math.min(pcm.length, Math.floor(to * SR)); s++) { e += pcm[s] * pcm[s]; n++; }
  return 10 * Math.log10(e / Math.max(1, n) + 1e-12);
};

// --- Eş zamanlı perde (sınır ≤3) ---

test('eş zamanlı perde: sentetik Batı tıngırtısı akorunda 3\'ü geçer (≈4,3)', () => {
  const r = polyphony(synthWesternStrum(8, 1), whole(8));
  assert.ok(r.frames > 200, `perdeli kare ${r.frames}`);
  assert.ok(r.mean > BOUNDS.polyphony, `tıngırtı ${r.mean}`);
  assert.ok(r.mean >= 3.8 && r.mean <= 5.0, `tıngırtı ≈4,3 olmalı: ${r.mean}`);
});

test('eş zamanlı perde: tek tel ezgi + açık dron 3\'ü geçmez (≈2–2,6)', () => {
  const r = polyphony(synthKopuzDrone(8, 2), whole(8));
  assert.ok(r.frames > 200, `perdeli kare ${r.frames}`);
  assert.ok(r.mean <= BOUNDS.polyphony, `kopuz ${r.mean}`);
  assert.ok(r.mean >= 1.8 && r.mean <= 2.8, `kopuz ≈2–2,6 olmalı: ${r.mean}`);
});

test('eş zamanlı perde: tohum ve gürültüyle ayrım sürer', () => {
  for (const seed of [3, 7]) {
    const strum = synthWesternStrum(6, seed), kopuz = synthKopuzDrone(6, seed);
    // Beyaz gürültü, sinyalin 25 dB altında.
    const noisy = (x, s) => {
      let r = s, e = 0;
      for (const v of x) e += v * v;
      const g = Math.sqrt(e / x.length) * 10 ** (-25 / 20) * Math.sqrt(3);
      return x.map((v) => { r = (r * 1664525 + 1013904223) >>> 0; return v + g * (r / 2 ** 31 - 1); });
    };
    assert.ok(polyphony(noisy(strum, seed), whole(6)).mean > 3.5, `tıngırtı, tohum ${seed}`);
    assert.ok(polyphony(noisy(kopuz, seed), whole(6)).mean < 2.8, `kopuz, tohum ${seed}`);
  }
});

test('eş zamanlı perde: oyunun kodla kopuzu (kopuz_control_d) 3\'ü geçmez', (t) => {
  if (!existsSync(KOPUZ_CONTROL)) return t.skip('audio/gen/_wav/kopuz_control_d.wav yok (tools/bake_music.sh)');
  const pcm = decode(KOPUZ_CONTROL);
  const r = polyphony(pcm, [{ name: 'tümü', from: 0.05, to: pcm.length / SR - 0.1 }]);
  assert.ok(r.mean <= BOUNDS.polyphony && r.mean >= 1.5, `kodla kopuz ${r.mean}`);
});

// --- Sözcükler ve bölümler ---

test('sözcükler: yönergeler atlanır, altyazıdan 23 sözcük ve dize sınırı', () => {
  const meta = { words_timestamps: [
    { word: '[Intro]', start_ms: 0, end_ms: 0 }, { word: '{solo', start_ms: 0, end_ms: 0 }, { word: 'komuz', start_ms: 0, end_ms: 0 },
    { word: 'alone}', start_ms: 0, end_ms: 0 }, { word: 'One', start_ms: 5080, end_ms: 5480 },
    { word: '{the', start_ms: 10020, end_ms: 10020 }, { word: 'komuz', start_ms: 10020, end_ms: 10020 },
    { word: 'gallops}', start_ms: 10020, end_ms: 10020 }, { word: 'and', start_ms: 14880, end_ms: 15060 },
  ] };
  assert.deepEqual(sungWords(meta).map((w) => w.word), ['One', 'and']);
  const expected = expectedWords();
  assert.equal(expected.length, BOUNDS.words);
  assert.equal(expected[0].word, 'one');
  assert.equal(expected.at(-1).word, 'bell');
  assert.equal(expected.findIndex((w) => w.line === 2), 11);
  const sung = expected.map((w, i) => ({ word: w.word, on: i < 11 ? 4.7 + 0.45 * i : 14.5 + 0.4 * (i - 11), off: i < 11 ? 5.0 + 0.45 * i : 14.8 + 0.4 * (i - 11) }));
  assert.equal(lineSplit(sung, expected), 11);
  sung[3].word = 'counting';  // sözler tutmazsa en uzun ara
  assert.equal(lineSplit(sung, expected), 11);
  assert.equal(lineSplit([{ on: 0, off: 1 }, { on: 1.2, off: 2 }, { on: 5, off: 6 }, { on: 6.1, off: 7 }]), 2);
});

test('sözsüz bölümler sözcük zamanlarından doğru kesilir', () => {
  const line1 = [[4.7, 5.1], [5.2, 6.6], [6.7, 7.5], [7.6, 9.6]];
  const line2 = [[14.5, 15.0], [15.1, 16.4], [16.5, 18.1], [18.2, 19.0]];
  const sung = [...line1, ...line2].map(([on, off], i) => ({ word: `w${i}`, on, off }));
  const s = silentSections(sung, 4, 0.3, 27.3);
  assert.deepEqual(s.map((x) => x.name), ['giriş', 'dize arası', 'çıkış']);
  const near = (a, b) => assert.ok(Math.abs(a - b) < 1e-9, `${a} ≠ ${b}`);
  near(s[0].from, 0.35); near(s[0].to, 4.0);    // sözden önceki 0,7 sn soluk düşülür
  near(s[1].from, 9.85); near(s[1].to, 13.8);   // dizenin son sözcüğünden 0,25 sn sonra, sonraki sözden 0,7 sn önce
  near(s[2].from, 19.25); near(s[2].to, 27.2);
  assert.deepEqual(lineWindows(sung, 4), [[4.7, 9.6], [14.5, 19.0]]);
  // Kopuzun cevabı yoksa (dize arası 0,16 sn) bölüm düşer.
  const tight = sung.map((w, i) => (i >= 4 ? { ...w, on: w.on - 4.74, off: w.off - 4.74 } : w));
  assert.deepEqual(silentSections(tight, 4, 0.3, 22.5).map((x) => x.name), ['giriş', 'çıkış']);
});

// --- Söz kipi ve motif (ayrılmış ses izinde) ---

// Perde dizisi: notalar (MIDI) art arda, her biri dur sn, 11,6 ms adım.
const track = (lines) => {
  const out = [];
  for (const { from, notes, dur = 0.3 } of lines) notes.forEach((m, i) => {
    for (let t = from + i * dur; t < from + (i + 1) * dur - 1e-9; t += 256 / 22050) out.push({ t, hz: midiHz(m) * 2 ** ((8 * Math.sin(40 * t)) / 1200) });
  });
  return out.sort((a, b) => a.t - b.t);
};
const DORIAN = [50, 52, 53, 55, 57, 57, 55, 53, 52, 50];        // D E F G A · A G F E D
const MAJOR = [50, 54, 55, 57, 61, 62, 64, 62];                // D F♯ G A C♯ D E D (3101'in dizesi)

test('söz kipi ve motif: D Dorian ve iki dizede A G F D', () => {
  const v = vocalMeasures(track([{ from: 1, notes: DORIAN }, { from: 6, notes: DORIAN }]), [[1, 4], [6, 9]]);
  assert.equal(v.status, 'ölçüldü');
  assert.equal(v.fNatural, 1);
  assert.equal(v.mode, 'dorian');
  assert.equal(v.motif.both, true);
  assert.equal(hasMotif(['D', 'E', 'D', 'A', 'G', 'F', 'E', 'D', 'C', 'D']), true);  // 3103: geçiş notası E
  assert.equal(hasMotif(['D', 'F#', 'G', 'A', 'C#', 'D', 'E', 'D']), false);
});

test('söz kipi: D majör F♯ baskın, motif yok; motif yalnız son üç ölçüde aranır', () => {
  const v = vocalMeasures(track([{ from: 1, notes: MAJOR }, { from: 6, notes: MAJOR }]), [[1, 3.4], [6, 8.4]]);
  assert.equal(v.fNatural, 0);
  assert.equal(v.mode, 'major');
  assert.equal(v.motif.any, false);
  // Motif dizenin başında, son üç ölçüden önce: bulunmaz.
  const early = track([{ from: 1, notes: [57, 55, 53, 50, ...Array(26).fill(50)], dur: 0.3 }]);
  const w = [[1, 1 + 30 * 0.3]];
  assert.ok(30 * 0.3 - 3 * BAR_S > 4 * 0.3, 'motif son üç ölçünün dışında kalmalı');
  assert.equal(vocalMeasures(early, w).motif.any, false);
  assert.deepEqual(noteNames(track([{ from: 0, notes: [57, 55, 53, 50] }]).map((p) => ({ midi: Math.round(69 + 12 * Math.log2(p.hz / 440)) }))), ['A', 'G', 'F', 'D']);
});

test('söz kipi: 30 kareden az perde «ölçülemedi»', () => {
  const few = Array.from({ length: MIN_PITCH_FRAMES - 1 }, (_, i) => ({ t: 1 + i * 0.0116, hz: midiHz(53) }));
  const v = vocalMeasures([...few, { t: 2, hz: null }], [[1, 3]]);
  assert.equal(v.fNatural, null);
  assert.equal(v.mode, null);
  assert.match(v.status, /^ölçülemedi/);
  assert.equal(v.motif.measurable, false);
  // Perde yeterli ama F ve F♯ yok: kip yine ölçülemez.
  const noF = vocalMeasures(track([{ from: 1, notes: [50, 57, 50, 57, 50, 57] }]), [[1, 3]]);
  assert.equal(noF.fNatural, null);
  assert.match(noF.status, /F ya da F♯/);
});

test('ses izi (--stems) yolu: YIN sentetik sesten kipi ve motifi bulur', () => {
  // Testere benzeri ses: 10 harmonik, 5,5 Hz titreşim; iki dize D Dorian, aralarında sessizlik.
  const pcm = new Float32Array(Math.floor(9.5 * SR));
  for (const from of [1, 6]) DORIAN.forEach((m, i) => {
    const f = midiHz(m), s0 = Math.floor((from + i * 0.3) * SR);
    let ph = 0;
    for (let s = 0; s < 0.3 * SR; s++) {
      ph += (2 * Math.PI * f * 2 ** ((15 * Math.sin((2 * Math.PI * 5.5 * s) / SR)) / 1200)) / SR;
      let v = 0;
      for (let h = 1; h <= 10; h++) v += Math.sin(h * ph) / h;
      pcm[s0 + s] = 0.2 * v * Math.min(1, s / 200, (0.3 * SR - s) / 200);
    }
  });
  const v = vocalMeasures(yinTrack(pcm), [[1, 4], [6, 9]]);
  assert.equal(v.mode, 'dorian', JSON.stringify(v.histogram));
  assert.equal(v.motif.both, true, JSON.stringify(v.motif));
});

// --- Vuruş ızgarası (bilgi) ---

// Izgara: k. nokta from + k × dönem; sapma ±15 ms, her 5. noktadan sonra yarım adımda süs vuruşu.
const gridStrokes = (from, period, count) => {
  const out = [];
  for (let k = 0; k < count; k++) {
    out.push(from + k * period + 0.015 * Math.sin(k * 1.7));
    if (k % 5 === 2) out.push(from + (k + 0.5) * period);
  }
  return out;
};

test('vuruş ızgarası: dönem, ilk ve son vuruş, oran; süs vuruşu oturmaz', () => {
  const g = strokeGrid(gridStrokes(1, 0.4, 50));
  assert.ok(Math.abs(g.period - 0.4) < 0.001, `dönem ${g.period}`);
  assert.ok(Math.abs(g.anchor - 1) < 0.02, `çapa ${g.anchor}`);
  assert.ok(Math.abs(g.first - 1) < 0.001, `ilk ${g.first}`);
  assert.ok(Math.abs(g.lastGrid - (1 + 49 * 0.4)) < 0.03, `son nokta ${g.lastGrid}`);
  assert.equal(g.strokes, 60);
  assert.equal(g.onGrid, 50);
  assert.equal(g.share.toFixed(2), '0.83');
  assert.ok(g.rmsMs < 15, `hata ${g.rmsMs} ms`);
});

test('vuruş ızgarası: dönemin katını ya da yarısını seçmez; az vuruşta ölçülmez', () => {
  // Süssüz düz ızgarada aranan aralıktaki kat (0,6 sn) ve yarım dönem (0,25 sn) öne geçmemeli.
  const flat = (from, period, count) => Array.from({ length: count }, (_, k) => from + k * period);
  assert.ok(Math.abs(strokeGrid(flat(0.5, 0.3, 60)).period - 0.3) < 0.001, 'dönem 0,3 (katı 0,6 değil)');
  assert.ok(Math.abs(strokeGrid(flat(2, 0.5, 40)).period - 0.5) < 0.001, 'dönem 0,5 (yarısı 0,25 değil)');
  assert.equal(strokeGrid([1, 1.4, 1.8]), null);
});

// --- Gerçek çekimler ---

test('sayılan ölçüler prototipin 3106 sayılarını verir (audio.md §2)', (t) => {
  if (!haveTakes) return t.skip('çekim dosyaları yok');
  const pcm = decode(take(3106));
  const c = countedMeasures(pcm, sungWords(JSON.parse(readFileSync(join(TAKES_DIR, '3106.json'), 'utf8'))));
  assert.equal(c.strokesPerSec.toFixed(2), '3.74');
  assert.equal((c.hfShare * 100).toFixed(1), '10.6');
  assert.equal(c.decayDb.toFixed(1), '19.5');
  assert.equal(c.levelGapDb.toFixed(1), '5.0');
});

test('çekim 3106: sınırlar, üç sözsüz bölüm ve ayırma yoksa «ölçülemedi: kulakla»', (t) => {
  if (!haveTakes) return t.skip('çekim dosyaları yok');
  const r = measureTake(3106, { sep: { available: false, reason: 'sınama' } });
  assert.equal(r.bounds.words.ok, true);
  assert.equal(r.bounds.onset.value.toFixed(2), '4.72');
  assert.equal(r.bounds.gap.value.toFixed(2), '4.86');
  assert.equal(r.bounds.length.value.toFixed(2), '27.35');
  assert.deepEqual(r.bounds.polyphony.sections.map((s) => s.name), ['giriş', 'dize arası', 'çıkış']);
  assert.equal(typeof r.bounds.polyphony.value, 'number');
  assert.equal(r.info.fNatural.status, 'ölçülemedi: kulakla');
  assert.equal(r.info.fNatural.class, 'bilgi');
  assert.equal(r.info.motif.status, 'ölçülemedi: kulakla');
  assert.equal(r.total, 4);  // kip sayılana girmez
});

test('çekim 3104: vuruş ızgarası K75 sayısından değil vuruşların aralığından', (t) => {
  if (!existsSync(take(3104))) return t.skip('çekim dosyası yok');
  const r = measureTake(3104, { sep: { available: false, reason: 'sınama' } });
  const g = r.info.strokeGrid;
  assert.equal(g.class, 'bilgi');
  assert.ok(Math.abs(g.period - 0.399) < 0.002, `dönem ${g.period}`);
  assert.ok(Math.abs(g.first - 2.31) < 0.02, `ilk vuruş ${g.first} (saat işlenmiş dosyanın: baştaki sessizlik düşülür)`);
  assert.ok(Math.abs(g.last - 22.62) < 0.02, `son vuruş ${g.last}`);
  assert.ok(g.share >= 0.6, `oran ${g.share}`);
  assert.equal(r.counted.strokesPerSec.value, 2.12, 'K75 ölçüsü değişmez');
  assert.ok(Math.abs(1 / g.period - 2.12) > 0.3, 'Izgara sessiz baş ve kuyruğu bölmez');
});

test('denetim karışımı: kodla kopuz söz düzeyinin 5 dB altında', (t) => {
  if (!haveTakes || !existsSync(KOPUZ_CONTROL)) return t.skip('çekim ya da denetim kopuzu yok');
  const pcm = decode(take(3101));
  const sung = sungWords(JSON.parse(readFileSync(join(TAKES_DIR, '3101.json'), 'utf8')));
  const windows = lineWindows(sung, lineSplit(sung));
  const kopuz = decode(KOPUZ_CONTROL);
  const gain = controlGainDb(pcm, windows, kopuz);
  const dir = mkdtempSync(join(tmpdir(), 'song-measure-test-'));
  try {
    const mix = decode(mixControl(take(3101), KOPUZ_CONTROL, gain, join(dir, 'mix.wav')));
    assert.ok(Math.abs(mix.length - pcm.length) < SR * 0.05, 'karışım çekimin boyunda');
    // Karışımdan çekim çıkarılınca kalan kopuzdur: düzeyi kopuz + kazanç.
    const rest = mix.map((v, i) => v - (pcm[i] ?? 0));
    const voiceDb = 10 * Math.log10(windows.reduce((e, [a, b]) => e + (b - a) * 10 ** (rms(pcm, a, b) / 10), 0) / windows.reduce((d, [a, b]) => d + b - a, 0));
    const restDb = rms(rest, 0, Math.min(rest.length, kopuz.length) / SR);
    const kopuzDb = rms(kopuz, 0, Math.min(rest.length, kopuz.length) / SR) + gain;
    assert.ok(Math.abs(restDb - kopuzDb) < 0.3, `karışımdaki kopuz ${restDb} dB, beklenen ${kopuzDb}`);
    assert.ok(Math.abs(voiceDb - (rms(kopuz, 0, kopuz.length / SR) + gain) - 5) < 0.2, 'söz ile kopuz arası 5 dB');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('ayırma betiği kurulu değilse 3 ile çıkar, indirmez', (t) => {
  const r = spawnSync('python3', [join(import.meta.dirname, 'song_separate.py'), '--probe'], { timeout: 120000 });
  if (r.error) return t.skip(`python3 yok: ${r.error.message}`);
  if (r.status === 0) {
    assert.equal(JSON.parse(r.stdout.toString().trim().split('\n').at(-1)).ok, true);
  } else {
    assert.equal(r.status, 3, r.stderr.toString());
    assert.match(r.stderr.toString(), /yok/);
  }
});

test('denetim: Demucs kuruluysa 3101 D majör, 3103 D Dorian bulunur', { timeout: 175000 }, (t) => {
  const sep = separationBackend();
  if (!sep.available) return t.skip(`Demucs kurulu değil, indirilmez: ${sep.reason}`);
  const c = runControl(sep);
  assert.equal(c.ran, true, c.reason);
  assert.equal(c.takes[3101].found, 'major', JSON.stringify(c.takes[3101]));
  assert.equal(c.takes[3103].found, 'dorian', JSON.stringify(c.takes[3103]));
  assert.equal(c.passed, true);
});

// --- Araç ve sonucu ---

test('run: tablo ve sonuç (yazmadan, ayırmasız)', (t) => {
  if (!haveTakes) return t.skip('çekim dosyaları yok');
  const lines = [];
  const r = run({ takes: [3106], write: false, separate: false, log: (s) => lines.push(s) });
  assert.equal(r.takes.length, 1);
  assert.deepEqual(r.ranking, [3106]);
  assert.equal(r.control.ran, false);
  assert.equal(typeof r.polyphony3106.value, 'number');
  assert.ok(r.calibration.western_strum > 3 && r.calibration.kopuz_drone_melody <= 3, JSON.stringify(r.calibration));
  const text = lines.join('\n');
  assert.match(text, /SINIR/);
  assert.match(text, /SAYILAN/);
  assert.match(text, /BİLGİ/);
  assert.match(text, /3106 eş zamanlı perde/);
});

test('k75_measure.json: 3104–3107, üç sınıf ve 3106\'nın eş zamanlı perdesi', (t) => {
  if (!existsSync(OUT_JSON)) return t.skip('k75_measure.json yok: node tools/song/song_measure.mjs');
  const j = JSON.parse(readFileSync(OUT_JSON, 'utf8'));
  assert.equal(j.decision, 'K75');
  assert.deepEqual(j.takes.map((r) => r.seed), [3104, 3105, 3106, 3107]);
  assert.deepEqual([...j.ranking].sort(), [3104, 3105, 3106, 3107]);
  for (const r of j.takes) {
    assert.deepEqual(Object.keys(r.bounds), ['words', 'onset', 'gap', 'length', 'polyphony'], `${r.seed} sınır`);
    assert.equal(typeof r.bounds.polyphony.value, 'number', `${r.seed} eş zamanlı perde`);
    for (const k of ['strokesPerSec', 'hfShare', 'decayDb', 'levelGapDb']) assert.equal(typeof r.counted[k].value, 'number', `${r.seed} ${k}`);
    assert.ok(r.info.fNatural && r.info.motif, `${r.seed} bilgi`);
    assert.equal(r.info.strokeGrid.class, 'bilgi', `${r.seed} ızgara`);
    for (const k of ['period', 'first', 'share']) assert.equal(typeof r.info.strokeGrid[k], 'number', `${r.seed} ızgara ${k}`);
    if (!j.separation.available) {
      assert.equal(r.info.fNatural.status, 'ölçülemedi: kulakla');
      assert.equal(r.info.motif.status, 'ölçülemedi: kulakla');
    }
    assert.equal(r.info.fNatural.class, j.control.passed ? 'sayılan' : 'bilgi');
  }
  assert.equal(j.polyphony3106.value, j.takes.find((r) => r.seed === 3106).bounds.polyphony.value);
  assert.ok(j.calibration.western_strum > 3 && j.calibration.kopuz_drone_melody <= 3);
});
