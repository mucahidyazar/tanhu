#!/usr/bin/env node
// Hayatta kalma fikstürü (godot.md §8.2, K29; economy.md §5.1–§5.3, §5.6; time.md §10.5): prototipin src/game/needs.js modülü
// (Tokluk / Fullness). Ateş, pişirme, av ve yara prototipte saf modül değildir (survival.md §6'nın campfire.js, cooking.js, hunting.js
// satırları yazılmadı): onların beklenen değerleri alan belgesinden yazılır (tests/unit/test_survival_*.gd).
//   tests/fixtures/needs.json  bant eşikleri, zorluğun foodK'si, dakika başına oran (uyanık, dinlenme, uyku, Son Gece, beceri çarpanı),
//                              senaryolar (update, eat, add, fromJSON, toJSON art arda; Tokluk ve bant her adımdan sonra).
// Eşya tablosu fikstürün içindedir (items): prototipin ve Godot'nun eşya kataloğundan bağımsız, aynı Tokluk değerleriyle iki yanda koşar.
//
//   node tools/proto_fixtures/survival.mjs [--proto yol] [--check]
import { TOL, isMain, protoImport, protoSha, runCli } from './_shared.mjs';

const NEEDS = 'src/game/needs.js';
const DEPS = ['src/data/difficulty.js'];

// Senaryoların eşya tablosu (economy.md §5.2'nin Tokluk sütunu; taş yiyecek değildir).
export const ITEMS = {
  meal: { food: { fullness: 35 } },
  stew: { food: { fullness: 55, buff: { sec: 360, grip: 1, staRegen: 1.2 } } },
  spit_meat: { food: { fullness: 30, buff: { sec: 180, grip: 1 } } },
  ember_fish: { food: { fullness: 25 } },
  meat: { food: { fullness: 12 } },
  burnt: { food: { fullness: 5 } },
  millet: { food: { fullness: 4 } },
  qurt: { food: { fullness: 12 } },
  stone: {},
};

// Senaryolar: [kimlik, kurucu seçenekleri, işlemler]. İşlem: ['update', dk, seçenek] | ['eat', id, kalite] | ['add', n] |
// ['fromJSON', nesne] | ['toJSON'] | ['enabled', bool]. Kurucunun mods'u nesnedir (anahtar → değer), lastNight sabit bool.
const SCRIPTS = [
  ['day_normal', { diff: 'normal' }, [
    ['update', 60], ['update', 960], ['eat', 'meal', 2], ['eat', 'meal', 3], ['update', 480, { sleep: true }], ['eat', 'stew', 1], ['toJSON'],
  ]],
  ['day_story', { diff: 'story' }, [['update', 600], ['update', 240, { rest: true }], ['update', 480, { sleep: true }], ['toJSON']]],
  ['day_hard', { diff: 'hard', fullness: 80 }, [['update', 30], ['update', 333.3], ['update', 0.25], ['update', 1e-7], ['toJSON']]],
  ['last_night', { diff: 'normal', fullness: 95, lastNight: true }, [
    ['update', 130], ['update', 630], ['update', 60, { lastNight: false }], ['update', 60, { sleep: true }], ['toJSON'],
  ]],
  ['bands_cross', { diff: 'normal', fullness: 76 }, [
    ['update', 12], ['update', 12.0001], ['update', 600], ['update', 299.9], ['update', 1], ['update', 5], ['eat', 'burnt', 2], ['add', 70],
    ['add', -0.5], ['add', 0], ['add', 1000], ['add', -1000], ['toJSON'],
  ]],
  ['quality_and_mods', { diff: 'normal', fullness: 10, mods: { mealFull: 1.5, fullnessDecay: 0.85 } }, [
    ['eat', 'meal', 2], ['eat', 'meal', 3], ['eat', 'meal', 1], ['update', 120], ['eat', 'spit_meat', 3], ['eat', 'spit_meat', 7], ['eat', 'stone', 3],
    ['eat', 'nope', 2], ['eat', 'meal+', 2], ['toJSON'],
  ]],
  ['disabled', { diff: 'normal', enabled: false }, [['update', 600], ['eat', 'meal', 2], ['toJSON']]],
  ['spent_stays', { diff: 'normal', fullness: 0 }, [['update', 60], ['eat', 'millet', 2], ['update', 47.99], ['update', 0.02], ['update', 10], ['toJSON']]],
  ['json', { diff: 'normal' }, [
    ['fromJSON', { fullness: 42.4567 }], ['toJSON'], ['fromJSON', { fullness: 'x' }], ['fromJSON', null], ['fromJSON', { fullness: 140 }],
    ['fromJSON', { fullness: -3 }], ['toJSON'], ['update', 1.37], ['toJSON'],
  ]],
];

function snapshot(n) {
  return { fullness: n.fullness, band: n.band() };
}

async function buildNeeds(proto) {
  const M = await protoImport(proto, NEEDS);
  const { FULLNESS, QUALITY_K, BAND_EFFECTS, bandOf, foodK, Needs } = M;
  const cases = [];
  for (const f of [-1, 0, 1e-10, 1e-9, 2e-9, 0.01, 24.999, 25, 25.001, 50, 74.99, 75, 99, 100, 140]) {
    cases.push({ id: `bandOf/${f}`, fn: 'bandOf', in: [f], out: bandOf(f) });
  }
  for (const d of ['story', 'normal', 'hard', 'nope', null]) cases.push({ id: `foodK/${d}`, fn: 'foodK', in: [d], out: foodK(d) });
  for (const row of [{ fullness: 0.5 }, { foodK: 2, fullness: 3 }, {}]) cases.push({ id: `foodK/row/${JSON.stringify(row)}`, fn: 'foodK', in: [row], out: foodK(row) });
  for (const diff of ['story', 'normal', 'hard']) {
    for (const opts of [{}, { rest: true }, { sleep: true }, { sleep: true, rest: true }, { lastNight: true }, { rest: true, lastNight: true }]) {
      for (const mods of [null, { fullnessDecay: 0.85 }]) {
        const n = new Needs({ diff, mod: mods ? (k, def) => mods[k] ?? def : null });
        cases.push({ id: `rate/${diff}/${JSON.stringify(opts)}/${mods ? 'decay' : 'plain'}`, fn: 'rate', in: [diff, opts, mods], out: n.rate(opts) });
      }
    }
  }
  for (const [id, ctor, ops] of SCRIPTS) {
    const mods = ctor.mods ?? null;
    const n = new Needs({
      items: ITEMS,
      diff: ctor.diff ?? 'normal',
      mod: mods ? (k, def) => mods[k] ?? def : null,
      lastNight: ctor.lastNight === undefined ? null : () => ctor.lastNight,
      enabled: ctor.enabled ?? true,
      ...(ctor.fullness === undefined ? {} : { fullness: ctor.fullness }),
    });
    const bands = [];
    n.bus = { emit: (name, payload) => bands.push([name, payload.band]) };
    const steps = [{ op: ['new'], ret: null, ...snapshot(n) }];
    for (const op of ops) {
      let ret = null;
      switch (op[0]) {
        case 'update': ret = n.update(op[1], op[2] ?? {}); break;
        case 'eat': ret = n.eat(op[1], { quality: op[2] }); break;
        case 'add': ret = n.add(op[1]); break;
        case 'fromJSON': n.fromJSON(op[1]); break;
        case 'toJSON': ret = n.toJSON(); break;
        case 'enabled': n.enabled = op[1]; break;
        default: throw new Error(`bilinmeyen işlem ${op[0]}`);
      }
      steps.push({ op, ret, ...snapshot(n), bands: bands.splice(0) });
    }
    cases.push({ id: `script/${id}`, fn: 'script', in: [ctor, ops], out: steps });
  }
  return {
    meta: {
      v: 1,
      tool: 'tools/proto_fixtures/survival.mjs',
      proto: [NEEDS, ...DEPS],
      proto_sha: protoSha(proto, [NEEDS, ...DEPS]),
      kind: 'sim',
      tol: TOL.sim,
      note: 'economy.md §5.3, time.md §10.5: Tokluk oyun dakikasıyla düşer (uyanık 5/sa × foodK; dinlenme ×0,5, uyku ×0,25, Son Gece ×1,2; Kurutma Sırığı fullnessDecay). Senaryoların eşya tablosu fikstürün items alanıdır. eat\'in kalitesi prototipte {quality} seçeneğidir, Godot\'da konumlu argümandır. bands: o işlemde yayılan need:band olayları (Godot\'da band_changed).',
    },
    constants: { FULLNESS, QUALITY_K, BAND_EFFECTS },
    items: ITEMS,
    cases,
  };
}

if (isMain(import.meta.url)) {
  runCli('survival fixture', [{ name: 'needs', build: buildNeeds }]).then((code) => process.exit(code), (err) => {
    console.error(err);
    process.exit(1);
  });
}

export { buildNeeds };
