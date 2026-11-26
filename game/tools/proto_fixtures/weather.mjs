#!/usr/bin/env node
// Hava fikstürü (godot.md §8.2, K29): prototipin saf hava çekirdeğini (src/game/weather-core.js) kendi yolundan içe aktarır, sabit
// girdilerle koşar ve tests/fixtures/weather_core.json'a girdiyi ve beklenen çıktıyı yazar. Prototip salt okunur kalır.
//
//   node tools/proto_fixtures/weather.mjs [--proto yol] [--out yol] [--check]
//
// Kapsam: tohum (hash32, strHash, mulberry32), gün içi eğriler, hedef paylar ve ayarlı ağırlıklar (kampın K67 satırları dahil:
// prototipte yoklar, aynı satır kuralıyla buraya eklenir), plan dizileri (tür, sınır, kaynak, cephe, hücre), karışım ve kilit, kısa
// benzetim, ıslaklık, kar örtüsü ve kabuk, W26'nın 150 kışı, fırtına hücresinin şimşek dizisi, yıldırım hedefi, işaretler, fx.
// GDScript testleri (tests/unit/test_weather_*.gd) dosyayı okur: kimlik ve tür tam eşit, kayan değer 1e-9 (birikimli 1e-6).
// tools/proto_fixtures.mjs bu dosyayı içe aktarabilir (export build); tek başına da koşar. --check dosyayı yazmaz, farkı söyler.
import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { homedir } from 'node:os';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const GAME = resolve(HERE, '../..');

function args(argv) {
  const o = { proto: process.env.TANHU_PROTO ?? join(homedir(), 'Code/tests/tanhu-programatic-test'), out: join(GAME, 'tests/fixtures/weather_core.json'), check: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--proto') o.proto = resolve(argv[++i]);
    else if (a.startsWith('--proto=')) o.proto = resolve(a.slice(8));
    else if (a === '--out') o.out = resolve(argv[++i]);
    else if (a === '--check') o.check = true;
    else throw new Error(`[weather fixture] unknown argument ${a}`);
  }
  return o;
}

const r12 = (x) => (Number.isFinite(x) ? Number(x.toPrecision(17)) : x === Infinity ? 'inf' : x === -Infinity ? '-inf' : null);

export async function build({ proto }) {
  const core = await import(join(proto, 'src/game/weather-core.js'));
  const WT = await import(join(proto, 'src/data/weather-types.js'));
  const CL = await import(join(proto, 'src/data/climates.js'));
  const DL = await import(join(proto, 'src/game/daylight.js'));
  const { TYPES, TYPE_IDS } = WT;
  const { Planner, WetState, SnowPack, Rng, hash32, strHash, simulate, calibrate, targetShares, signsFor, stormEvents, strikePick, typeHours, blend, paramsOf, fxFor, newFx, frontKind, skyRead } = core;

  // Kampın K67 satırları (weather.md §4.2): prototipin CLIMATES'ında yoklar; aynı row() kuralıyla eklenir.
  const COLS = ['clear', 'cloud', 'overcast', 'fog', 'drizzle', 'rain', 'downpour', 'thunderstorm', 'dry_storm', 'wind', 'gale', 'sleet', 'snow', 'heavy_snow', 'blizzard', 'dust_storm'];
  const share = (values) => {
    const out = {};
    COLS.forEach((id, i) => {
      if (values[i] > 0) out[id] = values[i];
    });
    return Object.freeze(out);
  };
  const row = (values, pHail, wind, extra = {}) => Object.freeze({ share: share(values), pHail, wind, showery: 0, curves: CL.CURVES, ...extra });
  const CLIMATES = {
    ...CL.CLIMATES,
    orkhon: Object.freeze({
      ...CL.CLIMATES.orkhon,
      camp_summer: row([29, 26, 11, 4, 4, 10, 3, 5, 1, 5.5, 1.5, 0, 0, 0, 0, 0], 0.25, { dir: 290, storm: 270 }, { showery: 0.6 }),
      camp_autumn: row([45, 20, 10, 5, 2, 3, 0, 0.5, 0, 8, 2, 1.5, 2.5, 0.5, 0, 0], 0.1, { dir: 290 }),
      camp_winter: row([51.5, 16, 10, 6, 0, 0, 0, 0, 0, 5, 2, 0.5, 6, 1.5, 1.5, 0], 0, { dir: 290 }),
    }),
  };
  const ACT1 = ['heavy_snow', 'blizzard'];
  // camp3'ün ocağı yanana dek dışlanan sev ≥3 türler (weather.md §6.3; prototipin _exclude sırası).
  const QUIET = TYPE_IDS.filter((id) => TYPES[id].sev >= 3);
  const key = (climate, season, exclude) => `${climate}:${season}:${[...exclude].sort().join(',')}`;

  // --- Tohum ---
  const zones = ['', 'sim', 'tanhu_camp', 'hexi_winter', 'tanhu_ordu', 'steppe_south', 'gobi', 'longcheng', 'whistle_field', 'orkhon'];
  const rng = {
    str_hash: Object.fromEntries(zones.map((z) => [z, strHash(z)])),
    hash32: [],
    mulberry: [],
  };
  for (const [a, b, c, d] of [[0, 0, 0, 0], [1, 2, 3, 0], [0x7a17c0de, strHash('steppe_south'), -96, 0], [2654435761, 5, 112416, 0x51ed], [4294967295, 4294967295, -1, 0x91a2e], [12345, strHash('longcheng'), 400, 0x5f3759df], [0x5eed, 0, Math.floor(-24 * 4), 0]]) {
    rng.hash32.push([a, b, c, d, hash32(a, b, c, d)]);
  }
  for (const seed of [1, 0x5eed, 2048377054, 4294967295]) {
    const r = new Rng(seed);
    rng.mulberry.push({ seed, values: Array.from({ length: 8 }, () => r.next()) });
  }

  // --- Eğriler ---
  const curves = Object.fromEntries(Object.entries(CL.CURVES).map(([k, v]) => [k, [...v]]));

  // --- Paylar ve ağırlıklar ---
  const rowsList = [];
  for (const [climate, seasons] of Object.entries(CLIMATES)) for (const season of Object.keys(seasons)) rowsList.push([climate, season, []]);
  rowsList.push(['hexi', 'winter', ACT1]);
  for (const s of ['camp_spring', 'camp_summer', 'camp_autumn', 'camp_winter']) rowsList.push(['orkhon', s, QUIET]);
  const targets = {};
  const weights = {};
  const t0 = performance.now();
  for (const [climate, season, exclude] of rowsList) {
    const k = key(climate, season, exclude);
    const tgt = targetShares(climate, season, exclude, CLIMATES);
    targets[k] = tgt;
    weights[k] = { ...calibrate(tgt, { climate, season, exclude, climates: CLIMATES }) };
  }
  const calMs = performance.now() - t0;
  const W = (climate, season, exclude = []) => weights[key(climate, season, exclude)];

  // --- Plan dizileri ---
  const brief = (s) => ({ type: s.type, t0: s.t0, t1: s.t1, src: s.src, front: s.front ? { ...s.front } : null, cell: s.cell ? [...s.cell] : null, g: s.g, seed: s.seed });
  function chain(p, from, to) {
    const out = [];
    let last = -Infinity;
    for (let h = from; h <= to; h += 0.5) {
      p.advance(h);
      for (const s of p.plan) if (s.t0 > last && s.t0 <= h + 12) {
        out.push(brief(s));
        last = s.t0;
      }
    }
    return out;
  }
  const planCases = [
    { climate: 'orkhon', season: 'camp_spring', exclude: [], seed: 12345, zone: 'tanhu_camp', from: 28104.77, hours: 96 },
    { climate: 'orkhon', season: 'camp_spring', exclude: QUIET, seed: 99, zone: 'tanhu_camp', from: 28104.77, hours: 48 },
    { climate: 'orkhon', season: 'summer', exclude: [], seed: 12345, zone: 'longcheng', from: 100, hours: 240 },
    { climate: 'steppe_south', season: 'winter', exclude: [], seed: 2048377054, zone: 'steppe_south', from: 0, hours: 240 },
    { climate: 'hexi', season: 'winter', exclude: ACT1, seed: 9, zone: 'hexi_winter', from: 500, hours: 120 },
    { climate: 'gobi', season: 'spring', exclude: [], seed: 4242, zone: 'whistle_field', from: 3000.25, hours: 120 },
    { climate: 'hangai', season: 'summer', exclude: [], seed: 7, zone: 'hangai', from: 777.5, hours: 120 },
    { climate: 'orkhon', season: 'camp_winter', exclude: [], seed: 31337, zone: 'tanhu_camp', from: 33000, hours: 120 },
  ];
  const plans = planCases.map((c) => {
    const p = new Planner({ climate: c.climate, season: c.season, exclude: c.exclude, seed: c.seed, zone: c.zone, weights: W(c.climate, c.season, c.exclude), climates: CLIMATES });
    p.start(c.from);
    return { ...c, plan: chain(p, c.from, c.from + c.hours) };
  });

  // --- Karışım, kilit, varış ---
  const mixOf = (m) => ({ a: m.a.type, b: m.b.type, k: m.k, seg_t0: m.seg.t0, lock: m.lock ? m.lock.id : null });
  const mixCases = [];
  {
    const p = new Planner({ climate: 'orkhon', season: 'summer', seed: 555, zone: 'longcheng', weights: W('orkhon', 'summer'), climates: CLIMATES }).start(200);
    const samples = [];
    for (let h = 200; h < 236; h += 0.0137) samples.push([h, mixOf(p.advance(h).at(h, {}))]);
    mixCases.push({ id: 'blend', climate: 'orkhon', season: 'summer', seed: 555, zone: 'longcheng', from: 200, samples: samples.filter((_, i) => i % 7 === 0) });
  }
  {
    const p = new Planner({ climate: 'hexi', season: 'winter', exclude: ACT1, seed: 77, zone: 'hexi_winter', weights: W('hexi', 'winter', ACT1), climates: CLIMATES }).start(1000);
    const out = [];
    const ev = (h, what) => out.push([h, what, mixOf(p.advance(h).at(h, {})), p.plan.map((s) => `${s.type}|${s.t0}|${s.t1}|${s.src}`)]);
    ev(1000, 'start');
    p.now = 1001.2;
    p.lock('a1_last_night', { type: 'snow', params: { snow: 0.35 }, keys: [{ k: 0, params: { fogFarAbs: 1400, cloud: 0.3, wind: 1.5 } }, { k: 0.66, params: { wind: 1.5 } }, { k: 1, params: { fogFarAbs: 140, cloud: 0.9, wind: 6 } }], blend: 6, at: 1001.2 });
    ev(1001.2, 'lock');
    ev(1001.21, 'lock+36s');
    p.progress('a1_last_night', 0.5);
    ev(1002, 'progress');
    p.now = 1003;
    p.lock('a1_kara_boran', { type: 'kara_boran', blend: 6, at: 1003 });
    ev(1003.02, 'kara_boran');
    p.release('a1_kara_boran', { blend: 8, at: 1004 });
    ev(1004.01, 'release_top');
    p.release('a1_last_night', { blend: 6, at: 1005 });
    ev(1005, 'release_all');
    ev(1005.02, 'resume');
    ev(1010, 'later');
    mixCases.push({ id: 'locks', climate: 'hexi', season: 'winter', exclude: ACT1, seed: 77, zone: 'hexi_winter', events: out });
  }
  {
    const p = new Planner({ climate: 'orkhon', season: 'summer', seed: 4040, zone: 'longcheng', weights: W('orkhon', 'summer'), climates: CLIMATES }).start(5000);
    p.arrive(5000.4, 1);
    const samples = [];
    for (let h = 5000.4; h < 5004; h += 0.05) samples.push([h, mixOf(p.advance(h).at(h, {}))]);
    mixCases.push({ id: 'arrival', climate: 'orkhon', season: 'summer', seed: 4040, zone: 'longcheng', from: 5000, arrive: [5000.4, 1], samples });
  }
  {
    // Mevsim ve dışlama değişimi: şimdiki grup kalır, sonrası yeni satırla.
    const p = new Planner({ climate: 'orkhon', season: 'camp_spring', exclude: QUIET, seed: 808, zone: 'tanhu_camp', weights: W('orkhon', 'camp_spring', QUIET), climates: CLIMATES }).start(28104.77);
    p.advance(28110);
    const before = p.plan.map((s) => `${s.type}|${s.t0}|${s.t1}|${s.src}`);
    // setExclude ve setRow ağırlığı calibrate'ten okur: CLIMATES geçirilmiş olmalı.
    p.climates = CLIMATES;
    p.setExclude([], 28110);
    const afterExclude = p.plan.map((s) => `${s.type}|${s.t0}|${s.t1}|${s.src}`);
    p.setRow('orkhon', 'camp_summer', 28111);
    const afterRow = p.plan.map((s) => `${s.type}|${s.t0}|${s.t1}|${s.src}`);
    mixCases.push({ id: 'rows', climate: 'orkhon', season: 'camp_spring', exclude: QUIET, seed: 808, zone: 'tanhu_camp', from: 28104.77, before, afterExclude, afterRow });
  }
  {
    // Kayıt: toJSON ve fromJSON aynı devamı verir.
    const p = new Planner({ climate: 'steppe_south', season: 'summer', seed: 777, zone: 'tanhu_ordu', weights: W('steppe_south', 'summer'), climates: CLIMATES }).start(240);
    p.advance(251.37);
    const saved = p.toJSON();
    const q = new Planner({ climate: 'steppe_south', season: 'summer', seed: 777, zone: 'tanhu_ordu', weights: W('steppe_south', 'summer'), climates: CLIMATES });
    q.fromJSON({ ...saved, at: 251.37 });
    const cont = chain(q, 251.37, 300);
    mixCases.push({ id: 'save', climate: 'steppe_south', season: 'summer', seed: 777, zone: 'tanhu_ordu', from: 240, at: 251.37, saved, cont });
  }

  // --- Kısa benzetim ---
  const sims = [];
  for (const [climate, season, exclude, days, seed] of [['orkhon', 'camp_spring', [], 120, 99], ['steppe_south', 'winter', [], 120, 31], ['gobi', 'summer', [], 120, 5]]) {
    const r = simulate({ climate, season, exclude, days, seed, weights: W(climate, season, exclude), climates: CLIMATES });
    sims.push({ climate, season, exclude, days, seed, share: r.share, hours: r.hours, per_day: r.perDay });
  }

  // --- Islaklık ---
  const wet = [];
  {
    const w = new WetState({ accumulate: true });
    const steps = [['rain', 0.25, false], ['rain', 1.15, false], ['downpour', 0.4, false], ['clear', 2, false], ['clear', 3, true], ['snow', 1, false], ['heavy_snow', 2.5, false], ['rain', 0.5, false], ['clear', 4, false], ['sleet', 1, false], ['wind', 2, false], ['fog', 3, true]];
    const out = [];
    for (const [type, dtH, night] of steps) {
      w.step(dtH, TYPES[type].params, { night, summer: false });
      out.push([type, dtH, night, w.ground, w.felt, w.mud, w.puddle, w.snow]);
    }
    wet.push({ id: 'accumulate', accumulate: true, steps: out });
    const v = new WetState({ accumulate: false });
    const out2 = [];
    for (const [type, dtH, night] of [['snow', 1, false], ['snow', 2, true], ['clear', 1, false], ['rain', 1, false]]) {
      v.step(dtH, TYPES[type].params, { night, accumulate: false, summer: true });
      out2.push([type, dtH, night, v.ground, v.felt, v.mud, v.puddle, v.snow]);
    }
    wet.push({ id: 'camp', accumulate: false, steps: out2 });
  }

  // --- Kar örtüsü: saat saat gerçek planla (3 kış) ---
  const packs = [];
  for (const [climate, seed, exclude] of [['steppe_south', 2048377054, []], ['kerulen', 11, []]]) {
    const p = new Planner({ climate, season: 'winter', exclude, seed, zone: climate, weights: W(climate, 'winter', exclude), climates: CLIMATES });
    const pack = new SnowPack();
    const frac = new Float64Array(TYPE_IDS.length);
    const lat = CL.CLIMATE_LAT[climate];
    let dec = 0;
    const sun = {};
    const sunEl = (h) => DL.sunAt(lat, dec, (((h % 24) + 24) % 24) * 60, sun).el;
    const opts = { season: 'winter', sunEl, seed, zoneHash: strHash(climate) };
    p.start(0);
    const days = [];
    for (let d = 0; d < 360; d++) {
      if (d % 120 === 0) pack.reset();
      dec = DL.solarDec((319 + (d % 120)) % 365);
      for (let k = 0; k < 24; k++) {
        const h = d * 24 + k;
        p.advance(h);
        typeHours(p.plan, h, h + 1, frac);
        pack.hour(h, frac, opts);
        if (k === 5) days.push([d, pack.snowpack, pack.deep, pack.crust, pack.formed]);
      }
    }
    packs.push({ climate, seed, lat, days });
  }

  // --- W26: 150 kış ---
  const t1 = performance.now();
  const winter = {};
  for (const [id, climate, exclude] of [['steppe_south', 'steppe_south', []], ['gobi', 'gobi', []], ['hexi_act1', 'hexi', ACT1], ['orkhon', 'orkhon', []]]) {
    winter[id] = { climate, exclude, ...core.winterStats(climate, { exclude, lat: CL.CLIMATE_LAT[climate] }) };
  }
  const winterMs = performance.now() - t1;

  // --- Fırtına hücresi ---
  const storms = [];
  for (const c of [{ t0: 1000.25, t1: 1001.9, seed: 12345, zone: 'longcheng', near: 0.6, rate: 1, flowX: 0.871, flowZ: 0.49 }, { t0: 222.5, t1: 224, seed: 99, zone: 'tanhu_camp', near: 0.25, rate: 1, flowX: -0.5, flowZ: 0.866 }, { t0: 50, t1: 51.2, seed: 7, zone: 'gobi', near: 0, rate: 1, flowX: 1, flowZ: 0 }]) {
    const ev = stormEvents({ ...c, zoneHash: strHash(c.zone) }, []);
    storms.push({ ...c, events: ev.map((e) => ({ ...e })) });
  }

  // --- Yıldırım hedefi ---
  const cands = [
    { id: 'pine1', kind: 'tree', x: 10, z: 5, h: 12, lone: true },
    { id: 'pine2', kind: 'tree', x: -20, z: 30, h: 9, lone: 'edge' },
    { id: 'yurt_a', key: 's1', kind: 'structure', x: 3, z: -4, h: 8.6 },
    { id: 'banner', key: 's2', kind: 'pole', x: 6, z: -2, h: 10 },
    { id: 'tower', key: 's3', kind: 'tower', x: 40, z: 0, h: 7 },
    { id: 'forest', kind: 'tree', x: 0, z: 20, h: 14, lone: 'forest' },
    { id: 'site', kind: 'structure', x: 1, z: 1, h: 8.6, building: true },
  ];
  const strikes = [];
  for (const [point, rules] of [
    [[0, 0], {}],
    [[8, 4], { child: { x: 0, z: 0 } }],
    [[5, -3], { now: 100, struck: { s1: 90 } }],
    [[5, -3], { structures: false }],
    [[30, 30], { player: { x: 31, z: 31, mounted: true, open: true, ridge: 0 } }],
    [[60, 60], { player: { x: 61, z: 61, mounted: false, open: true, ridge: 4 } }],
    [[60, 60], { player: { x: 61, z: 61, mounted: false, open: true, ridge: 4 }, difficulty: 'story' }],
    [[-100, -100], {}],
  ]) {
    const t = strikePick(cands, point, rules);
    strikes.push({ point, rules, target: t ? t.id : null });
  }

  // --- İşaretler ---
  const signs = [];
  {
    const p = new Planner({ climate: 'orkhon', season: 'summer', seed: 12345, zone: 'longcheng', weights: W('orkhon', 'summer'), climates: CLIMATES }).start(100);
    const s = { list: [], n: 0, front: null, hud: null, clearing: false };
    for (let h = 100; h < 172; h += 0.25) {
      p.advance(h);
      for (const diffK of [1, 1.5]) {
        signsFor(p.plan, h, { diffK, act1: false, quietUntil: -Infinity, prev: p.prev, lock: null }, s);
        if (s.n || s.clearing) signs.push({ h, diffK, list: s.list.slice(0, s.n).map((e) => [e.id, e.ch, e.type, e.inH, e.t0]), front: s.front ? [s.front.type, s.front.inH] : null, hud: s.hud, clearing: s.clearing });
      }
    }
  }
  const sky = [];
  {
    const p = new Planner({ climate: 'orkhon', season: 'summer', seed: 12345, zone: 'longcheng', weights: W('orkhon', 'summer'), climates: CLIMATES }).start(100);
    for (let h = 100; h < 172; h += 1.5) {
      p.advance(h);
      const r = skyRead(p.plan, h, 6, {});
      sky.push({ h, kind: r.kind, type: r.type, at: r.at, end: r.end });
    }
  }

  // --- Tür vektörleri ve karışım ---
  const PK = WT.PARAM_KEYS;
  const vec = (p) => ({ ...Object.fromEntries(PK.map((k) => [k, r12(p[k])])), tone: [...p.tone], fogTint: p.fogTint ? [...p.fogTint] : null });
  const params = {};
  for (const id of TYPE_IDS) {
    params[id] = vec(paramsOf(id));
    if (WT.DRY_DUST[id]) params[`${id}:dry`] = vec(paramsOf(id, { dry: true }));
  }
  const blends = [];
  for (const [a, b, k] of [['clear', 'rain', 0.5], ['overcast', 'fog', 0.25], ['blizzard', 'kara_boran', 0.6], ['snow', 'blizzard', 0.3], ['clear', 'clear', 1], ['dust_storm', 'wind', 0.9]]) {
    const out = {};
    blend(paramsOf(a), paramsOf(b), k, out);
    blends.push({ a, b, k, out: { ...Object.fromEntries(PK.map((kk) => [kk, r12(out[kk])])), tone: [...out.tone], fogTint: [...out.fogTint], hasTint: out.hasTint } });
  }
  const fxs = [];
  for (const c of [
    { a: 'rain', b: 'downpour', k: 0.3, wet: [0.5, 0.6, 0.3, 0, 0.2], opts: { gust: 1.2, night: false } },
    { a: 'clear', b: 'clear', k: 1, wet: [0, 0, 0, 0, 0], opts: { night: true, moonUp: true } },
    { a: 'blizzard', b: 'blizzard', k: 1, wet: [0.1, 0.2, 0.1, 0, 0.9], opts: { snowGround: true, accumulate: true, snowFelt: 0.5 } },
    { a: 'thunderstorm', b: 'hail', k: 0.7, wet: [0.8, 0.9, 0.6, 0, 0], opts: { strikeRisk: 1, hail: { size: 'large', minutes: 18 } } },
    { a: 'wind', b: 'gale', k: 0.5, wet: [0, 0, 0, 0, 0.4], opts: { snowGround: true, gust: 8 } },
    { a: 'snow', b: 'snow', k: 1, wet: [0.2, 0.1, 0, 0, 0.7], opts: { pin: { mask: 0, trackK: 1, douse: 0 }, accumulate: false } },
  ]) {
    const w = new WetState();
    [w.ground, w.felt, w.mud, w.bow, w.snow] = c.wet;
    const p = blend(paramsOf(c.a), paramsOf(c.b), c.k, {});
    const fx = fxFor(p, w, { a: c.a, b: c.b, k: c.k, ...c.opts }, newFx());
    const o = {};
    for (const [kk, v] of Object.entries(fx)) o[kk] = typeof v === 'number' ? r12(v) : v;
    fxs.push({ ...c, fx: o });
  }

  // --- Ek: cephe türü ---
  const fronts = [];
  for (const [seg, before] of [[{ type: 'rain', src: 'sim' }, { type: 'clear' }], [{ type: 'downpour', src: 'sim' }, { type: 'rain' }], [{ type: 'rain', src: 'sim' }, { type: 'downpour' }], [{ type: 'fog', src: 'sim' }, { type: 'overcast' }], [{ type: 'overcast', src: 'build' }, { type: 'clear' }], [{ type: 'snow', src: 'story' }, { type: 'clear' }], [{ type: 'blizzard', src: 'sim' }, { type: 'snow' }]]) {
    fronts.push({ seg, before, kind: frontKind(seg, before) });
  }

  const PROTO_FILES = ['src/game/weather-core.js', 'src/data/weather-types.js', 'src/data/climates.js', 'src/game/daylight.js'];
  const protoSha = Object.fromEntries(PROTO_FILES.map((rel) => [rel, createHash('sha1').update(readFileSync(join(proto, rel))).digest('hex')]));
  return {
    meta: {
      v: 1,
      tool: 'tools/proto_fixtures/weather.mjs',
      proto: PROTO_FILES,
      proto_sha: protoSha,
      kind: 'sim',
      tol: 1e-9,
      date: new Date().toISOString().slice(0, 10),
      note: 'Kampın camp_summer, camp_autumn, camp_winter satırları prototipte yoktur; weather.md §4.2\'den aynı satır kuralıyla eklenip ayarlandı. Ağırlıklar calibrate(target, { climate, season, exclude }) varsayılanlarıyla (tohum 0x5eed, turlar 800×4 + 2000×4).',
      calibrate_ms: Math.round(calMs),
      winter_ms: Math.round(winterMs),
      quiet: QUIET,
      act1: ACT1,
    },
    type_ids: [...TYPE_IDS],
    rng,
    curves,
    targets,
    weights,
    plans,
    mix: mixCases,
    sims,
    wet,
    packs,
    winter,
    storms,
    strikes: { cands, cases: strikes },
    signs,
    sky,
    params,
    blends,
    fxs,
    fronts,
  };
}

function stringify(v) {
  return JSON.stringify(v, (k, x) => (typeof x === 'number' && !Number.isFinite(x) ? (x > 0 ? 'inf' : x < 0 ? '-inf' : null) : x));
}

async function main() {
  const o = args(process.argv.slice(2));
  if (!existsSync(join(o.proto, 'src/game/weather-core.js'))) throw new Error(`[weather fixture] prototype not found: ${o.proto}`);
  const t0 = performance.now();
  const data = await build(o);
  const text = `${stringify(data)}\n`;
  if (o.check) {
    const old = existsSync(o.out) ? readFileSync(o.out, 'utf8') : '';
    const a = JSON.parse(old || '{}'), b = JSON.parse(text);
    delete a.meta;
    delete b.meta;
    const same = JSON.stringify(a) === JSON.stringify(b);
    console.log(same ? '[weather fixture] aynı' : '[weather fixture] FARKLI');
    process.exit(same ? 0 : 1);
  }
  writeFileSync(o.out, text);
  console.log(`[weather fixture] ${o.out} (${(text.length / 1024).toFixed(1)} KB, ${Math.round(performance.now() - t0)} ms; ayar ${data.meta.calibrate_ms} ms, W26 ${data.meta.winter_ms} ms)`);
  for (const [id, w] of Object.entries(data.winter)) console.log(`  W26 ${id}: derin kar ${w.deepSnowShare.toFixed(4)}, kabuk/kış ${w.crustPerWinter.toFixed(3)}, kabuklu gün ${w.crustDayShare.toFixed(4)}`);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
