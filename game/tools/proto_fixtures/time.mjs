#!/usr/bin/env node
// Saat, takvim ve gün ışığı fikstürü (godot.md §8.2, K29): prototipin saf modüllerini (src/game/daylight.js, calendar.js,
// world-clock.js) kendi yolundan içe aktarır, sabit girdilerle koşar ve tests/fixtures/time_core.json'a girdiyi ve beklenen çıktıyı
// yazar. Prototip salt okunur kalır.
//
//   node tools/proto_fixtures/time.mjs [--proto yol] [--out yol] [--check]
//
// Kapsam: solarDec, sunAt, moonAt, dayInfo, phaseAt, skyKeys, skyAt, lightSource, lightLevel, nightClass (daylight.js); yearOf,
// doyOf, seasonOf, moonAgeAt, moonIllumAt, lunarMonthAt (calendar.js); WorldClock'un olay sırası (world-clock.js) ana kampta.
// Değişen kural fikstüre girmez (§3.2 madde 8): Serbest Gez'in eski ayrı ayı (roamMoonAge) ve ana kampın iğneli sapması yerine K67'nin
// kuralı girdi olarak verilir (WorldClock'a gün bilgisi: sapma tarihten, açılış payıyla −0,0127°). Dailin ve Lung-çeng günleri
// prototipte yoktur; beklenen değerleri time.md §17'dendir (test_game_calendar.gd).
// GDScript testleri (tests/unit/test_daylight.gd, test_game_calendar.gd, test_game_clock.gd) dosyayı okur: kimlik tam eşit, kayan değer 1e-9.
// tools/proto_fixtures.mjs bu dosyayı içe aktarabilir (export build); tek başına da koşar. --check dosyayı yazmaz, farkı söyler.
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { homedir } from 'node:os';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const GAME = resolve(HERE, '../..');
const CAMP_DEC_OFFSET = -0.0127;

function args(argv) {
  const o = { proto: process.env.TANHU_PROTO ?? join(homedir(), 'Code/tests/tanhu-programatic-test'), out: join(GAME, 'tests/fixtures/time_core.json'), check: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--proto') o.proto = resolve(argv[++i]);
    else if (a === '--out') o.out = resolve(argv[++i]);
    else if (a === '--check') o.check = true;
    else throw new Error(`[time fixture] unknown argument ${a}`);
  }
  return o;
}

const r17 = (x) => (Number.isFinite(x) ? Number(x.toPrecision(17)) : null);
const pick = (o, keys) => Object.fromEntries(keys.map((k) => [k, r17(o[k])]));
// dayInfo'nun anahtarları GDScript'te yılan yazımıdır.
const INFO_KEYS = [['sunrise', 'sunrise'], ['sunset', 'sunset'], ['civilDawn', 'civil_dawn'], ['civilDusk', 'civil_dusk'],
  ['nauticalDawn', 'nautical_dawn'], ['nauticalDusk', 'nautical_dusk'], ['dawnAt', 'dawn_at'], ['duskAt', 'dusk_at']];

export async function build({ proto }) {
  const DL = await import(join(proto, 'src/game/daylight.js'));
  const CAL = await import(join(proto, 'src/game/calendar.js'));
  const WC = await import(join(proto, 'src/game/world-clock.js'));
  const { solarDec, sunAt, moonAt, dayInfo, phaseAt, skyKeys, skyAt, lightSource, lightLevel, nightClass } = DL;

  // Girdiler: ana kamp (47,35°), Kışlak (38,9°), Ordos (39°), Gobi (43,5°); yılın birkaç günü ve günün dakikaları.
  const lats = [38.9, 39.0, 43.5, 47.35];
  const doys = [0, 25, 74, 100, 134, 172, 234, 264, 269, 319, 335, 354];
  const minutes = [0, 180, 270, 300, 330, 345, 363, 400, 480, 520, 600, 660, 720, 810, 820, 886.18, 930, 1000, 1090, 1118, 1140, 1180, 1200, 1260, 1380, 1439.5];
  const ages = [0, 3.7, 7.38, 11.2, 14.765294, 18.9, 23.508344777777722, 27.4];

  const daylight = { solar_dec: [], sun: [], moon: [], day_info: [], phase_at: [], sky_keys: [], sky_at: [], light_source: [], light_level: [], night_class: [] };
  for (const doy of [...doys, 100.5, 365]) daylight.solar_dec.push([doy, r17(solarDec(doy))]);
  for (const lat of lats) {
    for (const doy of doys) {
      const dec = solarDec(doy);
      const info = dayInfo({ lat, dec });
      const infoOut = {};
      for (const [js, gd] of INFO_KEYS) infoOut[gd] = r17(info[js]);
      infoOut.phases = info.phases.map(([id, from, to]) => [id, r17(from), r17(to)]);
      daylight.day_info.push([lat, r17(dec), infoOut]);
      const golden = lat === 47.35 ? 820 : null;
      const menu = lat === 47.35 && doy === 100 ? 886.18 : null;
      const keys = skyKeys(info, { golden, menu });
      daylight.sky_keys.push([lat, r17(dec), golden, menu, keys.flatMap((k) => [r17(k.m), r17(k.s)])]);
      for (const minute of minutes) {
        const sun = sunAt(lat, dec, minute, {});
        daylight.sun.push([lat, r17(dec), minute, pick(sun, ['x', 'y', 'z', 'el', 'az'])]);
        daylight.phase_at.push([lat, r17(dec), minute, phaseAt(info, minute)]);
        daylight.sky_at.push([lat, r17(dec), golden, menu, minute, r17(skyAt(keys, minute))]);
        for (const age of [ages[(Math.round(minute) + doy) % ages.length]]) {
          const moon = moonAt(lat, dec, minute, age, {});
          daylight.moon.push([lat, r17(dec), minute, age, pick(moon, ['x', 'y', 'z', 'el', 'az', 'illum'])]);
          const src = lightSource(info, minute, sun, moon, {});
          daylight.light_source.push([lat, r17(dec), minute, age, pick(src, ['x', 'y', 'z', 'k'])]);
        }
      }
    }
  }
  // Ana kampın K67 günü: 11 Nisan'ın sapması tarihten, açılış payıyla (prototipin iğnesi değil).
  const campDec = solarDec(100) + CAMP_DEC_OFFSET;
  const campInfo = dayInfo({ lat: 47.35, dec: campDec });
  const campKeys = skyKeys(campInfo, { golden: 820, menu: 886.18 });
  daylight.camp = {
    dec: r17(campDec),
    menu_sun: pick(sunAt(47.35, campDec, 886.18, {}), ['x', 'y', 'z', 'el', 'az']),
    menu_s: r17(skyAt(campKeys, 886.18)),
    keys: campKeys.flatMap((k) => [r17(k.m), r17(k.s)]),
  };
  for (const sunEl of [-20, -12, -9, -6, -3, -0.833, 0, 3, 6, 30]) {
    for (const [moonEl, illum, cloud] of [[-5, 1, 0], [10, 0.5, 0], [30, 1, 0], [45, 1, 0.6], [15, 0.36, 0.2]]) {
      daylight.light_level.push([sunEl, moonEl, illum, cloud, r17(lightLevel(sunEl, moonEl, illum, cloud))]);
    }
  }
  for (const level of [0, 0.05, 0.2, 0.25, 0.249, 0.35, 0.5, 0.499, 0.6, 1]) {
    for (const lit of [false, true]) daylight.night_class.push([level, lit, nightClass(level, lit)]);
  }

  const calendar = { days: [], moon: [] };
  for (const dayN of [-7785, -5600, -41, -1, 0, 1, 340, 341, 1041, 1046, 1171, 1205, 1305, 1390, 1472, 1694, 2698, 3436, 3525, 5238, 13270, 14097]) {
    calendar.days.push([dayN, CAL.yearOf(dayN), CAL.doyOf(dayN), CAL.seasonOf(CAL.doyOf(dayN))]);
  }
  for (const dayN of [-7785, -5600, -41, 1041, 1044, 1171, 1472, 1694, 2698, 3436, 3525, 4322, 5238, 14097]) {
    for (const minute of [0, 363, 886.18, 1080, 1439]) {
      const abs = dayN * 1440 + minute;
      calendar.moon.push([abs, r17(CAL.moonAgeAt(abs)), r17(CAL.moonIllumAt(abs)), CAL.lunarMonthAt(abs)]);
    }
  }

  // WorldClock: ana kampta K67 gün bilgisiyle olay sırası (saat başı, şafak, akşam, evre; dilim olayı GDScript'te evre olayının içindedir).
  const info = (day) => dayInfo({ lat: 47.35, dec: solarDec(CAL.doyOf(day)) + CAMP_DEC_OFFSET });
  const record = (bus) => {
    const log = [];
    bus.emit = (name, p) => {
      if (name === 'clock:hour') log.push(['hour', p.day, r17(p.abs), p.hour, p.skipping]);
      else if (name === 'dawn' || name === 'dusk') log.push([name, p.day, r17(p.abs), null, p.skipping]);
      else if (name === 'clock:phase') log.push(['phase', p.day, null, p.phase, p.skipping]);
      else if (name === 'clock:skip') log.push(['skip', p.dawns, r17(p.minutes), p.long, p.days]);
    };
    return log;
  };
  const clock = {};
  {
    const bus = {};
    const log = record(bus);
    const c = new WC.WorldClock({ bus, day: 1171, minute: 886.18, info });
    c.skip(720, { reason: 'wait' });
    clock.skip_720 = { from: [1171, 886.18], phase_before: 'golden', log, day: c.day, minute: r17(c.minute), phase: c.phase };
  }
  {
    const bus = {};
    const log = record(bus);
    const c = new WC.WorldClock({ bus, day: 1171, minute: 886.18, info });
    c.skip(2880, { reason: 'dev' });
    clock.skip_2880 = { from: [1171, 886.18], log, day: c.day, minute: r17(c.minute), phase: c.phase };
  }
  {
    // 17:30'dan 30 gerçek sn, 1/60 sn'lik karelerle: 17:38 (batış − 60) Akşam evresi.
    const bus = {};
    const log = record(bus);
    const c = new WC.WorldClock({ bus, day: 1171, minute: 1050, info });
    for (let i = 0; i < 1800; i++) c.advance(1 / 60);
    clock.frames_dusk = { from: [1171, 1050], frames: 1800, dt: 1 / 60, log, day: c.day, minute: r17(c.minute), phase: c.phase };
  }
  {
    // Gece yarısından Tan'a: 03:30'dan 06:30'a atlama.
    const bus = {};
    const log = record(bus);
    const c = new WC.WorldClock({ bus, day: 1172, minute: 210, info });
    c.skip(180, { reason: 'sleep', sleep: true });
    clock.skip_dawn = { from: [1172, 210], log, day: c.day, minute: r17(c.minute), phase: c.phase };
  }
  const nextOf = {};
  {
    const c = new WC.WorldClock({ day: 1171, minute: 886.18, info });
    for (const t of ['dawn', 'morning', 'noon', 'golden', 'dusk', 'night', '05:45', '14:00', 'civilDawn-30', 'sunrise+30', 'sunset', 'duskAt']) nextOf[t] = r17(c.next(t));
  }
  clock.next = { from: [1171, 886.18], targets: nextOf };

  return {
    meta: {
      source: 'tools/proto_fixtures/time.mjs', proto: 'src/game/daylight.js, calendar.js, world-clock.js',
      note: 'K67: ana kampın sapması tarihten + CAMP_DEC_OFFSET (−0,0127°); fikstür prototipin saf hesabıdır, Godot sınaması 1e-9 ile karşılaştırır.',
    },
    daylight, calendar, clock,
  };
}

async function main() {
  const o = args(process.argv.slice(2));
  if (!existsSync(join(o.proto, 'src/game/daylight.js'))) throw new Error(`[time fixture] prototip bulunamadı: ${o.proto}`);
  const data = await build(o);
  const text = `${JSON.stringify(data)}\n`;
  if (o.check) {
    const old = existsSync(o.out) ? readFileSync(o.out, 'utf8') : '';
    console.log(old === text ? '[time fixture] aynı' : '[time fixture] FARKLI');
    process.exit(old === text ? 0 : 1);
  }
  writeFileSync(o.out, text);
  console.log(`[time fixture] yazıldı: ${o.out} (${(text.length / 1024).toFixed(1)} KB)`);
}

if (import.meta.url === `file://${process.argv[1]}`) main().catch((err) => {
  console.error(err);
  process.exit(1);
});
