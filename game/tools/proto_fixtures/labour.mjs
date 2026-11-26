#!/usr/bin/env node
// Emek fikstürü (godot.md §8.2, K29): prototipin src/game/labour.js modülünün yalnız değişmeyen hesapları: tezgâh eğrisi eff,
// ağırlık ve ustalık (önder ve usta kuralı), ekip seçimi, çarpanlar (K_gece, K_tok, K_hava), taşıma ve günlük emek (dayCapacity,
// restWindow). İnşaat, söküm ve onarımın süresi T(n) ile işler (K50) ve fikstüre girmez: stepRate, simulate, etaMinutes, remaining,
// deriveSteps ve repairWork bekçidedir (_shared.mjs CHANGED_RULES); beklenenleri tests/unit/test_labour.gd structures.md §2.4 ve
// d2/labour-model.json v3'ten yazar.
//
//   node tools/proto_fixtures/labour.mjs [--proto yol] [--check]   → tests/fixtures/labour.json
import { TOL, isMain, protoImport, protoSha, runCli } from './_shared.mjs';

const MODULE = 'src/game/labour.js';

// classAt sözlükte işlev olamaz: [[başı, sonu, sınıf], …] (gün dakikası) parça parça tablosu yazılır, burada işleve çevrilir.
function classAtOf(table) {
  return (m) => {
    for (const [a, b, cls] of table) if (m >= a && m < b) return cls;
    return 'day';
  };
}

function dayInfoCall(info) {
  if (!info || !Array.isArray(info.classAt)) return info;
  return { ...info, classAt: classAtOf(info.classAt) };
}

export async function build(proto) {
  const L = await protoImport(proto, MODULE);
  const { LABOUR, eff, weightOf, isMaster, crewOn, nightK, fedK, weatherK, haulCap, haulTrip, haulTrips, haulWork, dayCapacity, restWindow } = L;
  const cases = [];
  const add = (fn, args, out, id = null) => cases.push({ id: id ?? `${fn}/${cases.filter((c) => c.fn === fn).length}`, fn, in: args, out });
  const run = (fn, f, args, id = null) => add(fn, args, f(...args), id);

  // Tezgâh eğrisi (structures.md §2.4 «Tezgâh eğrisi», K21): W ≤ 1 doğrusal, sonra 10 · (1 − 0,9^W).
  for (const W of [NaN, -1, 0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.5, 2.75, 3, 3.25, 4, 5, 6, 7, 8, 9, 10, 12, 20, 100]) run('eff', eff, [W], `eff/${W}`);

  // Ağırlık: rolün ağırlığı ya da verilen w; adlı büyük usta ≤1,25, eksi 0.
  const people = [
    { role: 'usta' }, { role: 'hand' }, { role: 'apprentice' }, { role: 'elder' }, { role: 'child' }, { role: 'mete' }, { role: 'guest' }, {},
    { role: 'usta', w: 1.25 }, { role: 'usta', w: 1.4 }, { role: 'hand', w: -0.5 }, { role: 'child', w: 0.6 },
  ];
  for (const m of people) run('weightOf', weightOf, [m]);

  // Ustalık: her yetişkin home ustasıdır; usta ve yaşlı kendi zanaatında; çırak ve Çocuk hiçbir zanaatta.
  const crafted = [
    { role: 'usta' }, { role: 'usta', crafts: ['cr_carpenter'] }, { role: 'usta', crafts: ['cr_felter'] }, { role: 'usta', crafts: ['wood'] },
    { role: 'usta', crafts: ['cr_smith', 'cr_bowyer'] }, { role: 'hand' }, { role: 'hand', crafts: ['cr_carpenter'] }, { role: 'apprentice', crafts: ['cr_carpenter'] },
    { role: 'elder', crafts: ['cr_earth'] }, { role: 'elder' }, { role: 'child' }, { role: 'mete' }, { role: 'guest' },
  ];
  for (const m of crafted) for (const craft of ['home', 'wood', 'earth', ['wood', 'earth'], ['home', 'wood']]) run('isMaster', isMaster, [m, craft]);

  // Ekip seçimi: el sınırına (max) dek en ağır üyeler W'yi verir; önder, usta, Mete ve ham payın ustası adıma girebilen bütün ekipten.
  const OKTAR = { id: 'oktar', role: 'usta', crafts: ['cr_carpenter'] };
  const ERKA = { id: 'erka', role: 'usta', crafts: ['cr_felter'] };
  const DENGIZ = { id: 'dengiz', role: 'apprentice' };
  const CHILD = { id: 'child', role: 'child' };
  const METE = { id: 'mete', role: 'mete' };
  const hands = (n) => Array.from({ length: n }, (_, i) => ({ id: `h${i}`, role: 'hand' }));
  const crews = [
    ['camp3', { max: 8 }, [OKTAR, ERKA, DENGIZ], 'home'],
    ['camp3_child', { max: 8 }, [OKTAR, ERKA, DENGIZ, CHILD], 'home'],
    ['camp3_child_esik', { max: 4, child: false }, [OKTAR, ERKA, DENGIZ, CHILD], 'home'],
    ['nine_hands_max8', { max: 8 }, hands(9), 'home'],
    ['twelve_hands_max12', { max: 12 }, hands(12), 'home'],
    ['named_master', { max: 8 }, [{ id: 'nanay', role: 'usta', w: 1.25 }, ...hands(7)], 'home'],
    ['heavy_first', { max: 2 }, [CHILD, DENGIZ, { id: 'big', role: 'usta', w: 1.25 }, ...hands(1)], 'home'],
    ['child_alone', { max: 8 }, [CHILD], 'home'],
    ['elder_alone', { max: 8 }, [{ id: 'old', role: 'elder' }], 'home'],
    ['elder_alone_wood', { max: 8 }, [{ id: 'old', role: 'elder' }], 'wood'],
    ['apprentice_alone_wood', { max: 8 }, [DENGIZ], 'wood'],
    ['hands_wood_no_master', { max: 6 }, hands(3), 'wood'],
    ['carpenter_wood', { max: 6 }, [OKTAR, ...hands(2)], 'wood'],
    ['raw_kerege_no_carpenter', { max: 8, rawRole: 'cr_carpenter' }, [ERKA, DENGIZ], 'home'],
    ['raw_kerege_carpenter', { max: 8, rawRole: 'cr_carpenter' }, [OKTAR, DENGIZ], 'home'],
    ['raw_axle_either', { max: 4, rawRole: ['cr_cartwright', 'cr_carpenter'] }, [OKTAR], 'wood'],
    ['raw_apprentice_cannot', { max: 4, rawRole: 'cr_carpenter' }, [{ id: 'a', role: 'apprentice', crafts: ['cr_carpenter'] }], 'wood'],
    ['mete_and_hands', { max: 8 }, [METE, ...hands(7)], 'home'],
    ['zero_max', { max: 0 }, hands(3), 'home'],
    ['default_max', {}, hands(10), 'home'],
    ['empty', { max: 8 }, [], 'home'],
    ['zero_weight_skipped', { max: 8 }, [{ id: 'z', role: 'hand', w: 0 }, ...hands(1)], 'home'],
    ['multi_craft', { max: 6 }, [{ id: 'old', role: 'elder', crafts: ['cr_smith'] }, ...hands(2)], ['wood', 'earth']],
  ];
  for (const [id, step, members, craft] of crews) {
    const o = crewOn(step, members, null, craft);
    add('crewOn', [step, members, craft], { heads: o.heads, W: o.W, lead: o.lead, usta: o.usta, mete: o.mete, raw: o.raw }, `crewOn/${id}`);
  }

  // Çarpanlar.
  for (const cls of ['lit', 'day', 'dim', 'dark', 'dusk', null]) run('nightK', nightK, [cls], `nightK/${cls}`);
  for (const [food, fed] of [[100, null], [35, null], [34.999, null], [15, null], [14.999, null], [0, null], [null, null], [NaN, null], ['x', null], [50, 1], [10, 0.9], [100, 0.7]]) {
    run('fedK', fedK, [food, fed], `fedK/${food}/${fed}`);
  }
  const ids = [...Object.keys(LABOUR.WEATHER), 'unknown', null];
  for (const id of ids) {
    for (let bits = 0; bits < 8; bits++) {
      const step = { felt: Boolean(bits & 1), tall: Boolean(bits & 2), lattice: Boolean(bits & 4) };
      const r = weatherK(step, id);
      add('weatherK', [step, id], { k: r.k, hold: r.hold, reason: r.reason }, `weatherK/${id}/${bits}`);
    }
  }

  // Taşıma (structures.md §2.4 «Taşıma»): sefer süresi, sefer sayısı, emek.
  const carriers = ['adult', 'apprentice', 'child', 'cart', { cart: true }, { cart: true, cap: 80 }, { cap: 28 }, 28, 'unknown'];
  for (const c of carriers) run('haulCap', haulCap, [c]);
  for (const d of [-5, 0, 25, 50, 100, 150, 151]) for (const c of ['adult', 'cart']) run('haulTrip', haulTrip, [d, c], `haulTrip/${d}/${typeof c === 'string' ? c : 'obj'}`);
  for (const load of [-1, 0, 1, 6, 20, 21, 58, 59, 60, 61, 89, 146, 159]) for (const c of ['adult', 'apprentice', 'child', 'cart', 0]) run('haulTrips', haulTrips, [load, c], `haulTrips/${load}/${c}`);
  for (const [load, d, c] of [[58, 25, 'adult'], [58, 50, 'adult'], [58, 100, 'adult'], [58, 150, 'adult'], [58, 50, 'cart'], [89, 25, 'adult'], [89, 50, 'adult'], [89, 100, 'adult'], [89, 150, 'adult'], [89, 50, 'cart'], [159, 25, 'adult'], [159, 50, 'adult'], [159, 100, 'adult'], [159, 150, 'adult'], [159, 50, 'cart'], [146, 25, 'adult'], [146, 50, 'adult'], [146, 100, 'adult'], [146, 150, 'adult'], [146, 50, 'cart'], [0, 50, 'adult'], [30, 40, { cap: 28 }]]) {
    run('haulWork', haulWork, [load, d, c], `haulWork/${load}/${d}/${typeof c === 'string' ? c : 'obj'}`);
  }

  // Günlük emek (d2/core.md §2.5, structures.md §2.4 «Gece emri ve günlük emek»).
  const dec = (doy) => -23.44 * Math.cos((2 * Math.PI * (doy + 10)) / 365);
  const days = { winter: 14, spring: 104, summer: 195, autumn: 287 };
  const capCases = [
    ['build_lit', ['build', null, true]],
    ['build_lit_work', ['build', null, true, 'work']],
    ['herd', ['herd']],
    ['workshop_lit', ['produce', { window: LABOUR.WINDOW.camp }, true]],
    ['build_rest_lit_kislak', ['build', { window: LABOUR.WINDOW.kislak }, true, 'rest']],
    ['build_no_info', ['build']],
    ['produce_no_info', ['produce']],
    ['camp_pinned', ['produce', { lat: 47.35, dec: 7.4223, window: restWindow('camp') }]],
    ['hexi_day1', ['produce', { lat: 38.9, dec: dec(335), window: restWindow('kislak') }]],
    ['class_day', ['produce', { window: [360, 1320], classAt: [[0, 1440, 'day']] }]],
    ['class_dark', ['produce', { window: [360, 1320], classAt: [[0, 1440, 'dark']] }]],
    ['class_dim_morning', ['build', { classAt: [[0, 720, 'dim'], [720, 1440, 'day']] }]],
    ['class_mixed_rest', ['build', { window: [420, 1380], classAt: [[0, 480, 'dark'], [480, 1080, 'day'], [1080, 1200, 'dim'], [1200, 1440, 'lit']] }, false, 'rest']],
    ['night_window_text', ['produce', { lat: 43.5, dec: 0, window: ['20:00', '04:00'] }]],
    ['polar_day', ['produce', { lat: 80, dec: 23.44, window: [360, 1320] }]],
    ['polar_night', ['build', { lat: 80, dec: -23.44 }]],
  ];
  for (const [season, doy] of Object.entries(days)) {
    const info = { lat: 43.5, dec: dec(doy), window: restWindow('own_seat', season) };
    capCases.push([`outdoor_${season}`, ['produce', info]]);
    capCases.push([`build_unlit_${season}`, ['build', info]]);
    capCases.push([`build_rest_${season}`, ['build', info, false, 'rest']]);
    capCases.push([`workshop_lit_${season}`, ['produce', info, true]]);
  }
  for (const [id, args] of capCases) {
    const call = [...args];
    call[1] = dayInfoCall(call[1]);
    add('dayCapacity', args, dayCapacity(...call), `dayCapacity/${id}`);
  }
  for (const [place, season] of [['camp', null], ['kislak', null], ['camp', 'winter'], ['own_camp', 'summer'], ['own_seat', 'autumn'], ['own_seat', 'spring'], ['own_seat', 'winter'], ['road', null]]) {
    run('restWindow', restWindow, [place, season], `restWindow/${place}/${season}`);
  }

  // Taşınan tablolar: data/structures/labour.json bunlarla aynı sayıları taşır (değişmeyen kurallar).
  const N = LABOUR.NIGHT;
  const constants = {
    DAY: LABOUR.DAY,
    REAL_S_PER_MIN: LABOUR.REAL_S_PER_MIN,
    B: LABOUR.B,
    SITE_MAX: LABOUR.SITE_MAX,
    NO_USTA: LABOUR.NO_USTA,
    LEAD_W: LABOUR.LEAD_W,
    ROLE_W: { ...LABOUR.ROLE_W },
    MASTER_W_MAX: LABOUR.MASTER_W_MAX,
    ROLE_USTA: { ...LABOUR.ROLE_USTA },
    CRAFT_OF: { ...LABOUR.CRAFT_OF },
    NIGHT: { lit: N.lit, day: N.day, dim: N.dim, dark: N.dark, torchDarkHours: N.torchDarkHours, fireLightPad: N.fireLightPad, dayLevel: N.dayLevel, dimLevel: N.dimLevel },
    FED: { ...LABOUR.FED },
    REPAIR: { ...LABOUR.REPAIR },
    DISMANTLE: LABOUR.DISMANTLE,
    HAUL: JSON.parse(JSON.stringify(LABOUR.HAUL)),
    QUICK_RAISE: LABOUR.QUICK_RAISE,
    CAP: { ...LABOUR.CAP },
    WINDOW: Object.fromEntries(Object.entries(LABOUR.WINDOW).map(([k, v]) => [k, [...v]])),
    WEATHER: JSON.parse(JSON.stringify(LABOUR.WEATHER)),
    RESUME_MIN: LABOUR.RESUME_MIN,
  };

  return {
    meta: {
      v: 1,
      tool: 'tools/proto_fixtures/labour.mjs',
      proto: [MODULE],
      proto_sha: protoSha(proto, [MODULE]),
      kind: 'math',
      tol: TOL.math,
      note: 'Yalnız değişmeyen hesaplar (K29): tezgâh eff, ağırlık ve ustalık, ekip seçimi (W, baş, önder, usta, Mete, ham pay), K_gece, K_tok, K_hava, taşıma, dayCapacity ve restWindow. İnşaat, söküm ve onarım T(n) ile işler (K50), fikstüre girmez. dayCapacity girdisindeki classAt [[başı, sonu, sınıf], …] tablosudur (gün dakikası, [başı, sonu)); tabloda olmayan dakika «day».',
    },
    constants,
    cases,
  };
}

if (isMain(import.meta.url)) {
  runCli('labour fixture', [{ name: 'labour', build }]).then((code) => process.exit(code), (err) => {
    console.error(err);
    process.exit(1);
  });
}
