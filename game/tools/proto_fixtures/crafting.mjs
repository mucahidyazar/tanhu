#!/usr/bin/env node
// Zanaat fikstürü (godot.md §8.2, K29; Yol Haritası crafting): prototipin game/craft.js'i: tarif çözümü (inputsOf, fineRole, canCraft,
// craftHand, unitMinutes, recipesAt), tezgâhın saati (Workshop.tick: eff(W), gece sınıfı, açık tezgâhta hava, bekleme yuvası ve kurutma,
// usta, malzeme, üretim penceresi ve gece vardiyası, meşale, İnce İş, Kazan Ocağı'nın defter payı ve Aşçı, dolu yuva, uzun ve kısa adım,
// NPC el işi ve dolu kap, iade ve kayıt) ve tabloları (tezgâh, rol). Etiket çözümü Godot'nun kullandığı modelden (docs/design/d2/
// econ-model.json items.tags): sahte kap (Box) Godot'da sınırsız ItemContainer'dır. Prototipin tarif tablosu K48, K51 ve K58'den önceki
// modeldir: yalnız iki tabloda da olan tarifler karşılaştırılır.
//
//   node tools/proto_fixtures/crafting.mjs [--proto yol] [--check]   → tests/fixtures/crafting.json
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { GAME, TOL, isMain, protoImport, protoSha, runCli } from './_shared.mjs';

const MODULES = ['src/game/craft.js', 'src/data/craft-recipes.js', 'src/data/stations.js'];
const MODEL = JSON.parse(readFileSync(join(GAME, '../docs/design/d2/econ-model.json'), 'utf8'));

// Etiketi modelin eşya tablosundan çözen sahte kap (prototipin test/craft.test.js Box'u). cap adet sınırıdır (Godot'da Yük; senaryolar
// yalnız 0 ve sınırsızı kullanır).
class Box {
  constructor(contents = {}, cap = Infinity) {
    this.m = new Map(Object.entries(contents));
    this.cap = cap;
  }
  _match(id, ref) {
    const base = id.endsWith('+') ? id.slice(0, -1) : id;
    if (ref.startsWith('tag:')) return !!MODEL.items[base]?.tags?.includes(ref.slice(4));
    return id === ref || (!ref.endsWith('+') && id.endsWith('+') && base === ref);
  }
  count(ref) {
    let s = 0;
    for (const [id, n] of this.m) if (this._match(id, ref)) s += n;
    return s;
  }
  remove(ref, n) {
    const out = [];
    for (const id of [...this.m.keys()].sort((a, b) => (a === ref ? -1 : b === ref ? 1 : 0))) {
      if (n <= 0) break;
      const have = this.m.get(id);
      if (!this._match(id, ref)) continue;
      const k = Math.min(have, n);
      if (have - k > 0) this.m.set(id, have - k);
      else this.m.delete(id);
      n -= k;
      out.push({ id, n: k });
    }
    return out;
  }
  add(id, n) {
    let total = 0;
    for (const v of this.m.values()) total += v;
    const added = Math.max(0, Math.min(n, this.cap - total));
    if (added > 0) this.m.set(id, (this.m.get(id) ?? 0) + added);
    return { added, rest: n - added };
  }
  list() {
    return [...this.m].map(([id, n]) => ({ id, n })).sort((p, q) => (p.id < q.id ? -1 : 1));
  }
}

const CLEAR = { type: 'clear', dryK: 1 };
const RAIN = { type: 'rain', dryK: 0 };
const res = (r) => ({ done: r.done, used: r.used, wait: r.wait ?? {}, night_min: r.nightMin, torches: r.torches });

// Senaryo: {station, pool: {id: n}, cap?, ops: [{order: [tarif, n, {fine, night}]} | {tick: [dk, opts]} | {add: [id, n]} | {cancel: i} |
// {crew: {W, roles}} | {cap: n} | {set_wm: [i, wm]}]}; her tick'in sonucu, sonda kuyruk, yuvalar, kap ve kayıt.
function runWorkshop(C, sc) {
  const ws = new C.Workshop({ id: sc.id, station: sc.station });
  const pool = new Box(sc.pool ?? {}, sc.cap ?? Infinity);
  const trace = [];
  for (const op of sc.ops) {
    if (op.order) trace.push(['order', ws.order(op.order[0], op.order[1] ?? 1, op.order[2] ?? {})]);
    else if (op.tick) {
      const o = { ...(op.tick[1] ?? {}) };
      if (o.weather === 'CLEAR') o.weather = CLEAR;
      if (o.weather === 'RAIN') o.weather = RAIN;
      trace.push(['tick', res(ws.tick(op.tick[0], { pool, ...o })), ws.queue.map((q) => [q.recipe, q.n, q.wm, q.have, q.ready]), ws.cures.map((c) => [c.recipe, c.left, c.paused]), ws.cureWait ?? '']);
    } else if (op.add) trace.push(['add', pool.add(op.add[0], op.add[1]).added]);
    else if (op.cancel !== undefined) trace.push(['cancel', ws.cancel(op.cancel)]);
    else if (op.crew) ws.crew = op.crew;
    else if (op.cap !== undefined) pool.cap = op.cap;
    else if (op.set_wm) ws.queue[op.set_wm[0]].wm = op.set_wm[1];
  }
  return { trace, pool: pool.list(), json: ws.toJSON(), outbox: ws.outbox.map((e) => [e.id, e.n]) };
}

const SCENARIOS = [
  { id: 'felt_batch_four_hands', station: 'felt_yard', pool: { wool: 12 }, ops: [{ order: ['rc_felt_batch', 1] },
    ...Array.from({ length: 9 }, () => ({ tick: [60, { crewW: 4, lit: 'day', weather: 'CLEAR' }] }))] },
  { id: 'crew_clamped', station: 'wood_shop', pool: { wood_pine: 12 }, ops: [{ order: ['rc_uuk_set'] }, { tick: [60, { crewW: 4 }] }] },
  { id: 'no_crew', station: 'wood_shop', pool: { wood_pine: 12 }, ops: [{ order: ['rc_uuk_set'] }, { tick: [60, { crewW: 0 }] }] },
  { id: 'felt_rain', station: 'felt_yard', pool: { wool: 12 }, ops: [{ order: ['rc_felt_batch'] }, { tick: [60, { crewW: 4, weather: 'RAIN' }] }, { set_wm: [0, 420] },
    { tick: [1, { crewW: 4, weather: 'CLEAR' }] }, { tick: [120, { crewW: 4, weather: 'RAIN' }] }, { tick: [60, { crewW: 0, weather: 'drizzle' }] },
    { tick: [60, { crewW: 0, weather: { type: 'wind', dryK: 1.3 } }] }] },
  { id: 'kitchen_roofed', station: 'kitchen', pool: { bone: 3 }, ops: [{ order: ['rc_glue'] }, { tick: [120, { crewW: 3, weather: 'RAIN' }] }, { tick: [60, { crewW: 3, weather: 'RAIN' }] }] },
  { id: 'master_needed', station: 'wood_shop', pool: { wood_pine: 8, rope: 2 }, ops: [{ order: ['rc_kerege_set'] }, { tick: [60, { crewW: 3 }] },
    { tick: [60, { crewW: 3, roles: { cr_carpenter: 'apprentice' } }] }, { crew: { W: 3, roles: ['cr_carpenter'] } }, { tick: [60, {}] }] },
  { id: 'wheel_cartwright', station: 'wood_shop', pool: { wood_elm: 2 }, ops: [{ order: ['rc_wheel_pair'] }, { tick: [60, { crewW: 1, roles: ['cr_cartwright'] }] }] },
  { id: 'material_wait', station: 'smithy', pool: { iron_bar: 1 }, ops: [{ order: ['rc_heads_iron'] }, { tick: [60, { crewW: 2 }] }, { add: ['charcoal', 1] }, { tick: [60, { crewW: 2 }] }] },
  { id: 'rest_window', station: 'wood_shop', pool: { wood_pine: 24 }, ops: [{ order: ['rc_uuk_set', 2] }, { tick: [60, { crewW: 3, window: false }] }] },
  { id: 'night_shift_dark', station: 'wood_shop', pool: { wood_pine: 24 }, ops: [{ order: ['rc_uuk_set', 2, { night: true }] }, { tick: [60, { crewW: 3, window: false, lit: 'dark' }] }] },
  { id: 'lit_torch', station: 'wood_shop', pool: { wood_pine: 36, torch: 1 }, ops: [{ order: ['rc_uuk_set', 3, { night: true }] }, { tick: [480, { crewW: 3, window: false, lit: 'lit', dark: true }] }] },
  { id: 'lit_day_no_torch', station: 'wood_shop', pool: { torch: 2 }, ops: [{ tick: [60, { crewW: 3, lit: true, dark: false }] }] },
  { id: 'fine_bow', station: 'fletchery', pool: { horn: 2, sinew: 3, wood_pine: 1, glue: 1 }, ops: [{ order: ['rc_thumb_ring', 1, { fine: true }] }, { order: ['rc_hun_bow', 1, { fine: true }] },
    ...Array.from({ length: 20 }, () => ({ tick: [60, { crewW: 3, roles: ['cr_bowyer'] }] })), ...Array.from({ length: 25 }, () => ({ tick: [60, { crewW: 0 }] }))] },
  { id: 'kitchen_ration', station: 'kitchen', pool: { meat: 1 }, ops: [{ order: ['rc_cauldron_meat'] }, { tick: [60, { crewW: 1 }] }] },
  { id: 'cook_speed', station: 'kitchen', pool: { millet: 10 }, ops: [{ order: ['rc_meal_batch'] }, { tick: [10, { crewW: 1, roles: ['cr_cook'] }] }] },
  { id: 'slot_wait', station: 'smithy', pool: { ore_iron: 8, charcoal: 6 }, ops: [{ order: ['rc_bloom', 2] }, { tick: [240, { crewW: 3, roles: ['cr_smith'] }] },
    { tick: [240 / 2.71 + 720, { crewW: 3, roles: ['cr_smith'] }] }] },
  { id: 'npc_rope', station: 'wood_shop', pool: { reed: 9 }, ops: [{ order: ['rc_rope', 3] }, { tick: [60, { crewW: 3 }] }] },
  { id: 'outbox', station: 'wood_shop', pool: { wood_pine: 1 }, cap: 0, ops: [{ order: ['rc_pole'] }, { tick: [60, { crewW: 1 }] }, { cap: Infinity }, { tick: [1, { crewW: 0 }] }] },
  { id: 'cancel_save', station: 'tannery', pool: { hide: 7, rope: 2, salt: 1 }, ops: [{ order: ['rc_hide_lamellar'] }, { order: ['rc_leather', 1] }, { tick: [60, { crewW: 3 }] },
    { cancel: 5 }] },
];
// Uzun adım kısa adımlarla aynı sonucu verir.
const STEPS = [1800, 60, 10];

export async function build(proto) {
  const C = await protoImport(proto, 'src/game/craft.js');
  const R = await protoImport(proto, 'src/data/craft-recipes.js');
  const S = await protoImport(proto, 'src/data/stations.js');
  const cases = [];
  const add = (fn, args, out, id) => cases.push({ id, fn, in: args, out });

  for (const w of [0, 0.5, 1, 2, 3, 4, 6, 8, 12]) add('crew_eff', [w], C.crewEff(w), `crew_eff/${w}`);
  for (const [r, w, fine] of [['rc_felt_batch', 4, false], ['rc_hun_bow', 3, true], ['rc_uuk_set', 1, false], ['rc_rope', 0, false], ['rc_meal', 2, false]]) {
    add('unit_minutes', [r, w, fine], C.unitMinutes(r, w, { fine }), `unit_minutes/${r}/${w}`);
  }
  for (const [r, fine] of [['rc_hun_bow', true], ['rc_hun_bow', false], ['rc_rope', false], ['rc_felt_coat', true], ['rc_leather', false]]) {
    add('inputs_of', [r, fine], C.inputsOf(r, { fine }), `inputs_of/${r}/${fine}`);
  }
  for (const r of ['rc_hun_bow', 'rc_felt_coat', 'rc_iron_bracer', 'rc_rope', 'rc_hide_lamellar', 'rc_saddle_war', 'rc_iron_lamellar']) add('fine_role', [r], C.fineRole(r), `fine_role/${r}`);
  const can = [
    ['rope_short', 'rc_rope', { reed: 2, hide: 1, salt: 1 }, {}],
    ['rope_ok', 'rc_rope', { reed: 3 }, {}],
    ['felt_station', 'rc_felt', { wool: 2 }, {}],
    ['felt_two_stations', 'rc_felt', { wool: 2 }, { station: ['hearth', 'felt_yard'] }],
    ['leather_tag_tan', 'rc_leather', { hide: 1, salt: 1 }, { station: 'tannery' }],
    ['dye_kitchen', 'rc_dye', { madder: 2 }, { station: 'kitchen' }],
    ['arrow_skill', 'rc_arrow_bronze', { arrowhead_bronze: 5, arrow_shaft: 5, feather: 1 }, {}],
    ['arrow_skill_ok', 'rc_arrow_bronze', { arrowhead_bronze: 5, arrow_shaft: 5, feather: 1 }, { skills: ['trilobate'] }],
    ['kerege_master', 'rc_kerege_set', { wood_pine: 8, rope: 2 }, { station: 'wood_shop' }],
    ['iron_bar_kujul', 'rc_iron_bar', { ore_iron: 4 }, { station: 'smithy', role: 'kujul' }],
    ['rope_two_units', 'rc_rope', { reed: 3 }, { n: 2 }],
    ['fine_no_master', 'rc_hun_bow', { horn: 2, sinew: 3, wood_pine: 1, glue: 1 }, { station: 'fletchery', fine: true }],
    ['fine_master', 'rc_hun_bow', { horn: 2, sinew: 3, wood_pine: 1, glue: 1 }, { station: 'fletchery', fine: true, role: ['cr_bowyer'] }],
    ['fine_none', 'rc_rope', { reed: 3 }, { fine: true, role: ['cr_bowyer'] }],
    ['copper_bit', 'rc_copper_bit', { ore_copper: 1 }, { station: 'smithy' }],
    ['door_frame', 'rc_door_frame', { wood_pine: 2, wood_willow: 1, iron_bar: 1 }, { station: 'wood_shop' }],
  ];
  for (const [id, r, inv, opts] of can) add('can_craft', [r, inv, opts], C.canCraft(r, { inv: new Box(inv), ...opts }), `can_craft/${id}`);
  const hand = [
    ['rope_first', 'rc_rope', { reed: 7 }, { first: true }],
    ['rope_short', 'rc_rope', { reed: 2 }, {}],
    ['felt_batch_not_hand', 'rc_felt_batch', { wool: 12 }, {}],
    ['yurt_kit', 'rc_yurt_kit', { door_frame: 1, kerege_set: 1, yurt_crown: 1, pole: 2, uuk_set: 1, chiy: 1, felt: 6, rope: 6 }, {}],
    ['sling', 'rc_sling', { hide: 1, wool: 1 }, {}],
    ['pole_tag', 'rc_pole', { wood_willow: 1 }, { n: 1 }],
    ['shafts_light', 'rc_shafts', { wood_willow: 1, hide: 1 }, {}],
    ['copper_two', 'rc_copper_bit', { ore_copper: 3 }, { n: 2 }],
  ];
  for (const [id, r, inv, opts] of hand) {
    const box = new Box(inv);
    const out = C.craftHand(r, box, opts);
    add('craft_hand', [r, inv, opts], { out: out ?? {}, pool: box.list() }, `craft_hand/${id}`);
  }
  const common = Object.keys(R.RECIPES);
  for (const st of ['wood_shop', 'kitchen', 'smithy', 'felt_yard', 'hand']) add('recipes_at', [st, common], C.recipesAt(st).filter((id) => common.includes(id)).sort(), `recipes_at/${st}`);
  for (const sc of SCENARIOS) add('workshop', [sc], runWorkshop(C, sc), `workshop/${sc.id}`);
  for (const step of STEPS) {
    const ws = new C.Workshop({ station: 'felt_yard' });
    const pool = new Box({ wool: 36 });
    ws.order('rc_felt_batch', 3);
    for (let t = 0; t < 1800; t += step) ws.tick(step, { crewW: 4, weather: CLEAR, pool });
    add('long_step', [step], [pool.count('felt'), ws.queue.length, ws.cures.map((c) => c.left)], `long_step/${step}`);
  }
  // Kayıt gidiş dönüşü: tablo değişse de açılır.
  const ws = new C.Workshop({ id: 'tannery_1', station: 'tannery' });
  ws.order('rc_hide_lamellar');
  ws.order('rc_leather', 1);
  ws.tick(60, { crewW: 3, pool: new Box({ hide: 7, rope: 2, salt: 1 }) });
  const saved = JSON.parse(JSON.stringify(ws.toJSON()));
  const junk = new C.Workshop({ station: 'tannery' }).fromJSON({ q: [['rc_gone', 1, 0, 0]], cures: [['rc_gone', 2]] });
  add('workshop_json', [saved], { back: new C.Workshop({ id: 'tannery_1', station: 'tannery' }).fromJSON(saved).toJSON(), junk: junk.toJSON() }, 'workshop/json');

  const recipes = {};
  for (const [id, r] of Object.entries({ ...R.RECIPES, ...R.A1_RECIPES })) {
    recipes[id] = { station: r.station, who: r.who, role: r.role, in: r.in, out: r.out, wh: r.wh, hold: r.holdS, cure: r.cureH, act: r.act, a1: r.a1, skill: r.skill,
      seasons: r.seasons, fine: r.fine };
  }
  const stations = {};
  for (const [id, s] of Object.entries(S.STATIONS)) stations[id] = { tr: s.tr, en: s.en, crewMax: s.crewMax, slots: s.cureSlots, open: s.open, dry: s.dry, act: s.act, structure: s.structure };
  const roles = {};
  for (const [id, r] of Object.entries(S.ROLES)) roles[id] = { tr: r.tr, en: r.en, station: r.station, craft: r.craft, tier: r.tier, speedK: r.speedK ?? null, speedFor: r.speedFor ?? null };
  return {
    meta: {
      v: 1, tool: 'tools/proto_fixtures/crafting.mjs', proto: MODULES, proto_sha: protoSha(proto, MODULES), kind: 'sim', tol: TOL.sim,
      note: 'Tezgâhın saati birikimli benzetimdir (1e-6). Sahte kap etiketi d2/econ-model.json items.tags ile çözer; Godot\'da sınırsız ItemContainer. Prototipin tarif tablosu K48, K51, K58 öncesidir: karşılaştırma ortak kimliklerdedir.',
    },
    constants: { recipes, stations, roles, named: JSON.parse(JSON.stringify(S.NAMED_MASTERS)), dry_by_type: JSON.parse(JSON.stringify(C.DRY_BY_TYPE)),
      craft_labour: JSON.parse(JSON.stringify(C.CRAFT_LABOUR)) },
    cases,
  };
}

if (isMain(import.meta.url)) process.exit(await runCli('crafting', [{ name: 'crafting', build }]));
