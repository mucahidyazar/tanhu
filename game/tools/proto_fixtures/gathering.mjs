#!/usr/bin/env node
// Toplama fikstürü (godot.md §8.2, K29; Yol Haritası gathering): prototipin world/node-store.js'i (yerleşim, parça dizini, hak ve tükenme,
// şafak, uzak alım, kayıt) ve game/gather.js'i (vuruş süresi, Tam Vuruş penceresi ve yargısı, araç kademesi, durum makinesinin senaryoları:
// vuruş, tutuş, Tam Vuruş +1 birikimi, stamina, yer yığını, sıralı verim, ikinci eylem, gece gürültüsü, koşullu ve etkili düğümler). Yer
// yığınları Godot'da Inventory'nindir: senaryoların sahte heybesi sığmayanı yığına yazar, NodeStore'un yığın yuvaları fikstüre girmez.
//
//   node tools/proto_fixtures/gathering.mjs [--proto yol] [--check]   → tests/fixtures/gathering.json
import { TOL, isMain, protoImport, protoSha, runCli } from './_shared.mjs';

const MODULES = ['src/world/node-store.js', 'src/game/gather.js', 'src/data/node-kinds.js', 'src/core/math.js'];
const DT = 0.02;

// Sahte servisler (prototipin test/gather.test.js'indeki bed): düğüm deposu gerçek; oyun, girdi, heybe, veri yolu ve ilerleme sahte.
function bed(G, NS, opts) {
  const { nodes, cap = 100, tools = [], mods = {}, foot = 3, dark = false, assist = 'off', diff = 'normal', cond = {}, seen = true, yieldK = 1 } = opts;
  const store = new NS.NodeStore(nodes);
  const events = [];
  const axes = [];
  const ledger = [];
  const toasts = [];
  const flags = new Map(seen ? [['_seen.strike_ring', true]] : []);
  const handle = {
    axis: [0, 0], down: new Set(), heldSet: new Set(),
    pressed(a) { return this.down.has(a); },
    held(a) { return this.heldSet.has(a); },
    moveAxis(out) { out[0] = this.axis[0]; out[1] = this.axis[1]; return out; },
  };
  const actor = { profile: { id: 'mete' }, plays: [], crouchWant: 0, play(n, d) { this.plays.push([n, d]); } };
  const game = {
    pos: { x: 0, z: 0 }, y: 0, heading: 0, stats: { sta: 100, staMax: 100 }, restT: 1, handle, actor, path: null, goal: null, riding: null, mounting: null,
    moveTo(x, z, { onArrive }) { this.path = [[x, z]]; this.goal = { onArrive }; return true; },
    stop() { this.path = null; this.goal = null; },
  };
  const items = new Map();
  const inventory = {
    has: (id) => tools.includes(id),
    add(id, n) {
      let used = 0;
      for (const v of items.values()) used += v;
      const added = Math.max(0, Math.min(n, cap - used));
      if (added) items.set(id, (items.get(id) ?? 0) + added);
      return { added, rest: n - added };
    },
  };
  const ring = { starts: [], resolved: [], start(o) { this.starts.push(o); }, resolve(c) { this.resolved.push(c); }, setTime() {}, stop() {} };
  const ctx = {
    game, inventory, flags: { get: (k) => flags.get(k), set: (k, v) => flags.set(k, v) },
    bus: { emit: (name, payload) => events.push([name, payload]), on() {}, offOwner() {} },
    audio: { sfx: { play() {} } },
    ui: { toast: { show: (text) => toasts.push(text) } },
    settings: { get: (k) => (k === 'game.ringAssist' ? assist : undefined) },
    app: { difficulty: diff },
    progress: { derived: () => ({ strikeMul: 1, sense: 15, mods, stats: { foot } }), setAxis: (a, n) => axes.push([a, n]) },
    supply: { get: () => ({ add: (line, n) => ledger.push([line, n]) }) },
    cond: { get: (path) => cond[path] },
    worldClock: { dark, abs: 600 },
    nodes: { store, ring, flash() {}, yieldK: () => yieldK, takerFor: () => null },
  };
  const sys = new G.GatherSystem();
  sys.attach(ctx);
  return { sys, store, game, handle, items, events, axes, ledger, toasts, ring, flags };
}

// Senaryo: adımlar sırayla. {act: 'tap' | 'start' | 'complete' | 'cancel', i} ya da {run: sn, held?, press?: [t...], axis?: [x, z], dawn?}.
function runScenario(G, NS, sc) {
  const b = bed(G, NS, sc);
  const trace = [];
  for (const step of sc.steps) {
    if (step.act) {
      b.sys.act(step.i ?? 0, step.act);
      continue;
    }
    if (step.dawn !== undefined) {
      b.store.onDawn({ day: step.dawn });
      continue;
    }
    if (step.restock) {
      b.store.restock(step.restock[0], step.restock[1]);
      continue;
    }
    if (step.sta !== undefined) {
      b.game.stats.sta = step.sta;
      continue;
    }
    b.handle.axis = step.axis ?? [0, 0];
    if (step.held) b.handle.heldSet.add('use');
    else b.handle.heldSet.delete('use');
    const n = Math.round(step.run / DT);
    for (let k = 0; k < n; k++) {
      const t = b.sys.t;
      for (const at of step.press ?? []) if (Math.abs(t - at) < DT / 2) b.handle.down.add('use');
      b.sys.preUpdate(DT);
      b.handle.down.clear();
    }
  }
  const pick = (name) => b.events.filter(([e]) => e === name).map(([, p]) => p);
  return {
    items: Object.fromEntries([...b.items].sort((p, q) => (p[0] < q[0] ? -1 : 1))),
    hits: pick('node:hit').map((p) => p.index),
    yields: pick('gather:yield').map((p) => [p.item, p.n, p.kind, p.pile ?? 0, Boolean(p.clean)]),
    depleted: pick('node:depleted').map((p) => p.index),
    noise: pick('noise').map((p) => p.r),
    rings: b.ring.starts.map((s) => [s.T, s.window, Boolean(s.gold)]),
    judged: [...b.ring.resolved],
    stamina: b.game.stats.sta,
    axes: b.axes, ledger: b.ledger, toasts: b.toasts.length,
    state: b.sys.state === 'idle' ? 'idle' : b.sys.state,
    charges: Array.from(b.store.charges.slice(0, b.store.count)),
    flags: Array.from(b.store.flags.slice(0, b.store.count)),
    store_hits: Array.from({ length: b.store.count }, (_, i) => b.store.hitsOf(i)),
  };
}

const one = (kind, at = [1, 0]) => [{ id: kind, kind, at }];
const two = (kind) => [{ id: 'p', kind, at: [1, 0] }, { id: 'q', kind, at: [0, 1] }];
// Her vuruşta temas anında (0,72 T) yeni basış: T = 1 için.
const PRESS5 = [0.72];

const SCENARIOS = [
  { id: 'pine_held', nodes: one('node_pine'), tools: ['axe_bronze'], steps: [{ act: 'tap' }, { run: 5.3, held: true }, { run: 0.2 }] },
  { id: 'tap_once_then_move', nodes: one('node_pine'), tools: ['axe_bronze'], steps: [{ act: 'tap' }, { run: 1.1 }, { act: 'tap' }, { run: 0.3 }, { run: 0.6, axis: [1, 0] }, { dawn: 2 }] },
  { id: 'clean_last_strikes', nodes: two('node_pine'), tools: ['axe_bronze'], steps: [
    { act: 'tap', i: 0 }, { run: 5.2, held: true, press: PRESS5 }, { run: 0.2 },
    { act: 'tap', i: 1 }, { run: 5.2, held: true, press: PRESS5 }, { run: 0.2 }] },
  { id: 'held_no_clean', nodes: one('node_pine'), tools: ['axe_bronze'], steps: [{ act: 'tap' }, { run: 5.3, held: true }] },
  { id: 'miss_early', nodes: one('node_pine'), tools: ['axe_bronze'], steps: [{ act: 'tap' }, { run: 1.1, press: [0.5] }] },
  { id: 'skill_window', nodes: one('node_pine'), tools: ['axe_bronze'], mods: { strikeWindow: 0.3, cleanBonus: 1 }, steps: [{ act: 'tap' }, { run: 5.2, held: true, press: PRESS5 }, { run: 0.2 }] },
  { id: 'assist_wide_story', nodes: one('node_pine'), tools: ['axe_bronze'], assist: 'wide', diff: 'story', steps: [{ act: 'tap' }, { run: 0.1 }] },
  { id: 'assist_auto', nodes: two('node_pine'), tools: ['axe_bronze'], assist: 'auto', mods: { cleanBonus: 1 }, steps: [
    { act: 'tap', i: 0 }, { run: 5.2, held: true }, { run: 0.2 }, { act: 'tap', i: 1 }, { run: 5.2, held: true }, { run: 0.2 }] },
  { id: 'first_ring_half_speed', nodes: one('node_pine'), tools: ['axe_bronze'], seen: false, steps: [{ act: 'tap' }, { run: 2.1 }] },
  { id: 'tired', nodes: one('node_pine'), tools: ['axe_bronze'], steps: [{ sta: 0 }, { act: 'tap' }, { run: 1.6 }] },
  { id: 'iron_axe', nodes: one('node_pine'), tools: ['axe_iron'], steps: [{ act: 'tap' }, { run: 4.3, held: true }] },
  { id: 'no_tool', nodes: one('node_pine'), steps: [{ act: 'tap' }, { run: 1 }] },
  { id: 'pile_overflow', nodes: one('node_pine'), tools: ['axe_bronze'], cap: 1, steps: [{ act: 'tap' }, { run: 5.3, held: true }] },
  { id: 'reed_hold', nodes: one('node_reed'), steps: [{ act: 'start' }, { act: 'cancel' }, { act: 'start' }, { run: 1 }, { act: 'complete' }, { act: 'tap' }, { run: 2.1 }] },
  { id: 'kitchen_scraps_three_days', nodes: one('node_kitchen_scraps'), steps: [
    { act: 'start' }, { act: 'complete' }, { act: 'start' }, { act: 'complete' }, { act: 'start' }, { act: 'complete' }, { dawn: 0 },
    { act: 'start' }, { act: 'complete' }, { act: 'start' }, { act: 'complete' }, { act: 'start' }, { act: 'complete' }, { dawn: 1 },
    { act: 'start' }, { act: 'complete' }, { act: 'start' }, { act: 'complete' }, { act: 'start' }, { act: 'complete' }] },
  { id: 'fish_seq', nodes: one('node_fish_spot'), tools: ['net'], steps: [{ act: 'start' }, { act: 'complete' }, { act: 'start' }, { act: 'complete' }] },
  { id: 'ice_hole_net_then_ice', nodes: one('node_ice_hole'), tools: ['net'], steps: [{ act: 'start' }, { act: 'complete' }, { act: 'start' }, { act: 'complete' }] },
  { id: 'night_noise', nodes: [{ id: 'p', kind: 'node_pine', at: [1, 0] }, { id: 'r', kind: 'node_reed', at: [0, 1] }], tools: ['axe_bronze'], dark: true, steps: [
    { act: 'tap', i: 0 }, { run: 1 }, { act: 'start', i: 1 }, { act: 'complete', i: 1 }] },
  { id: 'night_quiet_foot', nodes: one('node_reed'), dark: true, foot: 4, steps: [{ act: 'start' }, { act: 'complete' }] },
  { id: 'dung_after_rain', nodes: one('node_dung'), yieldK: 0.5, steps: [{ act: 'start' }, { act: 'complete' }, { act: 'start' }, { act: 'complete' }] },
  { id: 'pilfer_over', nodes: one('node_pilfer'), steps: [{ act: 'start' }, { act: 'complete' }, { act: 'start' }, { act: 'complete' }] },
  { id: 'pilfer_ledger_eye', nodes: one('node_pilfer'), mods: { hiddenPilfer: 1 }, steps: [{ act: 'start' }, { act: 'complete' }, { act: 'start' }, { act: 'complete' }] },
  { id: 'stores_sack', nodes: one('node_stores_sack'), cond: { a1_last_night: true }, steps: [{ act: 'start' }, { act: 'complete' }] },
  { id: 'juniper_stages', nodes: one('node_juniper'), tools: ['axe_bronze'], steps: [
    { act: 'start' }, { act: 'complete' }, { act: 'start' }, { act: 'complete' }, { act: 'start' }, { act: 'complete' }, { act: 'tap' }, { run: 5.3, held: true }] },
  { id: 'ore_bonus_every', nodes: one('node_vein_iron'), tools: ['pick_bronze'], mods: { oreBonusEvery: 2 }, steps: [{ act: 'tap' }, { run: 16.6, held: true }] },
  { id: 'boulder_pick', nodes: one('node_boulder'), tools: ['pick_bronze'], steps: [{ act: 'tap' }, { run: 13.5, held: true, press: [0.792] }] },
  { id: 'woodpile_fixed', nodes: one('node_woodpile'), steps: [{ act: 'tap' }, { run: 6.1, held: true }] },
];

export async function build(proto) {
  const NS = await protoImport(proto, 'src/world/node-store.js');
  const G = await protoImport(proto, 'src/game/gather.js');
  const K = await protoImport(proto, 'src/data/node-kinds.js');
  const M = await protoImport(proto, 'src/core/math.js');
  const cases = [];
  const add = (fn, args, out, id) => cases.push({ id, fn, in: args, out });

  // Saf sayı yardımcıları (bit bit).
  for (const [a, b] of [[0, 0], [1, 0], [0, 1], [42, 1042], [3269, 7], [0xffffffff, 0], [123456789, 987654321], [7, -1], [2 ** 31, 5]]) {
    add('hash32', [a, b], NS.hash32(a, b), `hash32/${a}/${b}`);
  }
  for (const [x, y] of [[0, 0], [0.5, 0.25], [12.9, -3.3], [-100.25, 47.5], [13.37, 2.71], [431.2 * 0.03 + 2, 10.1 * 0.03 - 2]]) {
    add('noise2', [x, y], M.noise2(x, y), `noise2/${x}/${y}`);
    add('fbm2', [x, y, 2], M.fbm2(x, y, 2), `fbm2/${x}/${y}`);
  }
  const rng = M.rng(7002);
  add('rng', [7002, 6], Array.from({ length: 6 }, () => rng()), 'rng/7002');
  for (const bytes of [[], [1], [1, 2], [1, 2, 3, 4], [255, 0, 128, 7, 9]]) add('base64', [bytes], NS.toBase64(new Uint8Array(bytes)), `base64/${bytes.length}`);

  // I. Perde yerleşimi (§3.5): 3.270 kayıt, tür sayıları, altın karma, örnek düğümler, parça dizini, sorgular.
  const a1 = new NS.NodeStore(K.ACT1_NODES);
  let h = 0;
  for (let i = 0; i < a1.count; i++) h = (h * 31 + Math.round(a1.x[i] * 10) * 7 + Math.round(a1.z[i] * 10)) % 1000000007;
  const sample = [0, 1, 2, 3, 100, 419, 420, 500, 1319, 1320, 1400, 1700, 2000, 2500, 3000, 3261, 3262, 3269].map((i) => [i, a1.kindOf(i), a1.x[i], a1.z[i], a1.yaw[i], a1.scale[i], a1.tone[i]]);
  const boxes = [[380, -40, 480, 60], [-400, -600, -100, -300], [0, 0, 1, 1], [-60, -200, 160, -140]];
  const queries = boxes.map((bx) => {
    const got = [];
    a1.query(bx[0], bx[1], bx[2], bx[3], (i) => got.push(i));
    got.sort((p, q) => p - q);
    return [bx, got.length, got.slice(0, 12), got.reduce((s, i) => (s * 33 + i) % 1000000007, 0)];
  });
  add('placement', ['hexi_winter', 0], {
    count: a1.count, by_kind: a1.countByKind(), hash: h, sample, cx0: a1.cx0, cz0: a1.cz0, cw: a1.cw, ch: a1.ch,
    chunk_start: Array.from(a1.chunkStart), queries,
  }, 'placement/hexi_winter');
  const s1 = new NS.NodeStore(K.ACT1_NODES, { seed: 1 });
  add('placement_seed', ['hexi_winter', 1, [0, 500, 1320, 3000]], [0, 500, 1320, 3000].map((i) => [s1.x[i], s1.z[i], s1.tone[i]]), 'placement/seed1');
  const rejectBox = [-5, -5, 5, 5];
  const rj = new NS.NodeStore([{ id: 'r', kind: 'node_reed', at: [0, 0], r: 12, n: 30 }, { id: 'p', kind: 'node_pine', at: [20, 0], r: 6, n: 8 }], {
    seed: 3, reject: (x, z) => x >= rejectBox[0] && x <= rejectBox[2] && z >= rejectBox[1] && z <= rejectBox[3],
  });
  add('placement_reject', [rejectBox, 3], Array.from({ length: rj.count }, (_, i) => [rj.x[i], rj.z[i]]), 'placement/reject');

  // Hak ve tükenme, iki evre, şafak (prototipin node-store.test.js «consume» senaryosu).
  const st = new NS.NodeStore(K.ACT1_NODES);
  const first = (kind) => { for (let i = 0; i < st.count; i++) if (st.kindOf(i) === kind) return i; return -1; };
  const pine = first('node_pine'), reed = first('node_reed'), juniper = first('node_juniper'), boulder = first('node_boulder'), woodpile = first('node_woodpile');
  const log = [];
  log.push(['consume', pine, st.consume(pine)]);
  for (let k = 0; k < 3; k++) log.push(['consume', reed, st.consume(reed)]);
  for (let k = 0; k < 3; k++) log.push(['consume', juniper, st.consume(juniper)]);
  log.push(['hit', juniper, st.addHit(juniper)], ['hit', juniper, st.addHit(juniper)]);
  st.consume(boulder);
  st.consume(boulder);
  for (let k = 0; k < 16; k++) st.consume(woodpile);
  const noPiles = (j) => { delete j.piles; return j; };
  const before = noPiles(st.toJSON());
  const dawn1 = st.onDawn({ day: 1042 });
  const after = noPiles(st.toJSON());
  for (let k = 0; k < 4; k++) log.push(['consume', juniper, st.consume(juniper)]);
  st.onDawn({ day: 1043 });
  add('consume_dawn', [{ pine, reed, juniper, boulder, woodpile }], {
    log, before, renewed: dawn1.renewed, after, final: noPiles(st.toJSON()),
    states: [pine, reed, juniper, boulder, woodpile].map((i) => [st.charges[i], st.flags[i], st.available(i)]),
  }, 'store/consume_dawn');

  // Mantarın hava çarpanı: gün tohumlu (k < 1) ve ×2 (k ≥ 1).
  const fungi = new NS.NodeStore(K.ACT1_NODES);
  const fid = [];
  for (let i = 0; i < fungi.count; i++) if (fungi.kindOf(i) === 'node_mushroom') fid.push(i);
  const renewK = (wet) => (id) => (K.NODE_KINDS[id].weather?.wet ? (wet ? 2 : 0.5) : 1);
  fungi.onDawn({ day: 1042, renewK: renewK(false) });
  const dry = fid.map((i) => (fungi.available(i) ? 1 : 0));
  fungi.onDawn({ day: 1043, renewK: renewK(true) });
  add('dawn_weather', [1042, 1043], { dry, wet: fid.map((i) => fungi.charges[i]) }, 'store/dawn_weather');

  // Kayıt gidiş dönüşü (prototipin «perm gidiş dönüş» senaryosu; yığınsız).
  const sv = new NS.NodeStore(K.ACT1_NODES);
  const pines = [];
  for (let i = 0; i < sv.count && pines.length < 40; i++) if (sv.kindOf(i) === 'node_pine') pines.push(i);
  for (const i of pines) sv.consume(i);
  const sb = (k) => { for (let i = 0; i < sv.count; i++) if (sv.kindOf(i) === k) return i; return -1; };
  sv.consume(sb('node_boulder'));
  sv.consume(sb('node_reed'));
  for (let k = 0; k < 3; k++) sv.consume(sb('node_juniper'));
  sv.addHit(sb('node_juniper'));
  sv.addHit(sb('node_reed') + 7);
  sv.nextSeq(sb('node_kitchen_scraps'));
  sv.nextSeq(sb('node_kitchen_scraps'));
  sv.markStruck(sb('node_pine') + 500);
  const saved = sv.toJSON();
  delete saved.piles;
  const stale = new NS.NodeStore(K.ACT1_NODES);
  stale.fromJSON(saved, { keepDay: false });
  const broken = new NS.NodeStore(K.ACT1_NODES);
  broken.fromJSON({ perm: 42, part: 'x', day: [[-1, 2], ['a']], piles: [{ x: 'n' }] });
  const brokenJson = broken.toJSON();
  delete brokenJson.piles;
  const staleJson = stale.toJSON();
  delete staleJson.piles;
  add('save', [{ pines: pines.length }], { saved, stale: staleJson, broken: brokenJson }, 'store/save');

  // Uzak alım (K23): mutlak, belirlenimli, kenardan içeri; yenilenen kümede gün; iki evreli söğüt.
  const at = new NS.NodeStore(K.ACT1_NODES);
  const taken = at.applyTaken('a1_cut_yard', 100);
  const once = at.toJSON();
  at.applyTaken('a1_cut_yard', 100);
  const again = at.toJSON();
  const order = Array.from(at.orderOf('a1_cut_yard'));
  const reeds = new NS.NodeStore(K.ACT1_NODES);
  reeds.applyTaken('a1_west_reeds', 30);
  const reedOrder = Array.from(reeds.orderOf('a1_west_reeds').slice(0, 12));
  const willow = new NS.NodeStore(K.ACT1_NODES);
  willow.applyTaken('a1_ford_willow', 3);
  const [w0, w1] = willow.orderOf('a1_ford_willow');
  const mixed = new NS.NodeStore(K.ACT1_NODES);
  add('apply_taken', ['a1_cut_yard', 100], {
    taken, perm_once: once.perm, same_again: once.perm === again.perm, order_head: order.slice(0, 30), order_len: order.length,
    order_sum: order.reduce((s, i) => (s * 31 + i) % 1000000007, 0), reed_order: reedOrder, reed_json: reeds.toJSON().day,
    willow: [w0, willow.flags[w0], w1, willow.flags[w1], willow.charges[w1]], unknown: mixed.applyTaken('no_such_cluster', 5),
    by_kind: Array.from(mixed.orderOf('a1_slope', 'node_pine').slice(0, 8)),
  }, 'store/apply_taken');

  // Toplamanın saf hesapları.
  for (const [T0, mul, tired] of [[1, 1, false], [1, 1.12, false], [1.1, 1, false], [1, 1, true], [1.1, 0.88, true], [1, 0.05, false]]) {
    add('strike_t', [T0, mul, tired], G.strikeT(T0, mul, tired), `strike_t/${T0}/${mul}/${tired}`);
  }
  for (const [skill, diff, assist] of [[null, 1, 'off'], [0.3, 1, 'off'], [null, 1.3, 'off'], [null, 0.8, 'off'], [null, 1, 'wide'], [0.3, 0.8, 'wide'], [null, 1.3, 'auto']]) {
    add('ring_window', [skill, diff, assist], G.ringWindow({ skill, diff, assist }), `ring_window/${skill}/${diff}/${assist}`);
  }
  for (const [t, T, w] of [[0.72, 1, 0.18], [0.81, 1, 0.18], [0.82, 1, 0.18], [0.62, 1, 0.18], [0.63, 1, 0.18], [1.584, 2, 0.18], [0.792, 1.1, 0.3]]) {
    add('ring_judge', [t, T, w], G.ringJudge(t, T, w), `ring_judge/${t}/${T}/${w}`);
  }
  const hitsOut = {};
  for (const [id, row] of Object.entries(K.NODE_KINDS)) {
    for (const st2 of [row, row.then, row.alt].filter(Boolean)) {
      if (st2.action !== 'strike') continue;
      for (const tool of ['', 'axe_bronze', 'axe_iron', 'pick_bronze', 'pick_iron', 'knife_iron', 'site_axe', 'site_wedge']) {
        hitsOut[`${id}${st2 === row.then ? '.then' : ''}|${tool}`] = G.strikeHits(st2, tool || null);
      }
    }
  }
  add('strike_hits', [], hitsOut, 'strike_hits/all');

  // Durum makinesinin senaryoları (dt 0,02 sn).
  for (const sc of SCENARIOS) {
    const { id, steps, ...cfg } = sc;
    add('scenario', [{ ...cfg, steps }], runScenario(G, NS, sc), `scenario/${id}`);
  }

  const kinds = JSON.parse(JSON.stringify(K.NODE_KINDS));
  return {
    meta: {
      v: 1, tool: 'tools/proto_fixtures/gathering.mjs', proto: MODULES, proto_sha: protoSha(proto, MODULES), kind: 'math', tol: TOL.math,
      note: 'Yerleşim ve kayıt bit bit (float32 konumlar), saf hesaplar 1e-9; senaryolar dt 0,02 ile birebir. Yer yığını Inventory\'nindir: sahte heybe sığmayanı pile sayar. Godot\'nun eklediği alanlar (clip) ve K58 türü (node_woad) tabloya prototipten sonra girdi.',
    },
    constants: {
      gather: JSON.parse(JSON.stringify(G.GATHER)), child: JSON.parse(JSON.stringify(G.CHILD_GATHER)), tools: JSON.parse(JSON.stringify(K.TOOLS)),
      kinds, kind_ids: [...K.KIND_IDS], dynamic: [...K.DYNAMIC_KINDS], nodes_v: K.NODES_V, act1_nodes: JSON.parse(JSON.stringify(K.ACT1_NODES)),
      camp_nodes: JSON.parse(JSON.stringify(K.CAMP_NODES)),
    },
    cases,
  };
}

if (isMain(import.meta.url)) process.exit(await runCli('gathering', [{ name: 'gathering', build }]));
