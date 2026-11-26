#!/usr/bin/env node
// İlerleme fikstürleri (godot.md §8.2, K29; progression.md §1–§4): prototipin src/game/progress.js ve src/game/derive.js modülleri.
//   tests/fixtures/progress.json  XP eğrisi, perde tavanı, aşkın puan, köken, stat harcama, beceri durum makinesi, mods katlama, kayıt
//                                 gidiş dönüşü. Beceri tablosu prototipinki değildir: tablo K32 ve K43'le değişti (dört yeni ad, yeni
//                                 usta koşulları), bu yüzden durum makinesi kuralları bu dosyadaki küçük sentetik tabloyla koşar.
//   tests/fixtures/derive.json    progression.md §2.3'ün türetilen değerleri: stat, seviye, yara, Tokluk, yük, zemin, yay, çan, binek,
//                                 donanım, süreli yemek ve beceri anahtarlarından (sayı 1e-9).
//
//   node tools/proto_fixtures/progression.mjs [--proto yol] [--check]
import { TOL, isMain, protoImport, protoSha, runCli } from './_shared.mjs';

const PROGRESS = 'src/game/progress.js';
const DERIVE = 'src/game/derive.js';
// derive.js'in okuduğu tablolar (zorluk satırı ve yaylar) ve pullFactor: fikstürün kaynağı bunlardır.
const DERIVE_DEPS = ['src/data/difficulty.js', 'src/data/weapons.js', 'src/game/damage.js', 'src/core/math.js'];

// Durum makinesinin sentetik tablosu: her satır bir kuralı sınar (bedava, puan, seviye ve tier tabanı, önkoşul, usta koşulu, gizli
// ad, ustasız satır, etkin beceri). Koşullar cond.js'in Progression'da kullanılan altkümesidir.
export const SKILL_ROWS = [
  { id: 'free_a', tree: 't1', tier: 1, level: 1, act: 1, kind: 'passive', free: true, requires: [], teach: { who: 'farnak', when: 'gift' }, mods: { mount: true } },
  { id: 'pt_a', tree: 't1', tier: 1, level: 1, act: 1, kind: 'passive', free: false, requires: [], teach: { who: 'ardoksha', when: 'quest:q1.done' }, mods: { load: 8, slowFrom: { set: 0.5 } } },
  { id: 'pt_b', tree: 't1', tier: 2, level: 3, act: 1, kind: 'passive', free: false, requires: [], teach: { who: 'ardoksha', when: 'trust>=40' }, mods: { load: 2, draw: { mul: 0.85 }, form: ['line'] } },
  { id: 'pt_c', tree: 't1', tier: 2, level: 3, act: 1, kind: 'active', free: false, requires: ['pt_a'], teach: { who: ['opia', 'palak'], when: 'opia_fate==covered || quest:q2.done' }, mods: { dmg: { mul: 1.3 } }, cooldown: 6, stamina: 8 },
  { id: 'pt_d', tree: 't2', tier: 1, level: 1, act: 1, kind: 'passive', free: false, requires: ['stat.wind>=5'], teach: { who: 'kantu', when: 'tally_kantu' }, mods: { draw: { mul: 0.9 }, form: ['crescent', 'line'], slowFrom: { set: 0.4 }, windArrow: true } },
  { id: 'tier_h', tree: 't2', tier: 2, level: 1, act: 1, kind: 'passive', free: false, requires: [], teach: { who: 'mene', when: '!crow_hush && ties.mene>=2' }, mods: { turn: { mul: 1.25 }, sense: 6 } },
  { id: 'act2_e', tree: 't2', tier: 3, level: 6, act: 2, kind: 'passive', free: false, requires: ['pt_b'], teach: { who: 'm_quarter', when: 'm_quarter' }, mods: { sense: 4, turn: { mul: 1.2 } } },
  { id: 'hid_f', tree: 't3', tier: 3, level: 6, act: 2, kind: 'passive', free: false, requires: ['whistling_arrow'], teach: { who: 'm_bowyer', when: 'm_bowyer' }, hideName: true, mods: { spread: { mul: 0.8 } } },
  { id: 'no_master_g', tree: 't3', tier: 2, level: 4, act: 2, kind: 'passive', free: false, requires: ['act1_done'], teach: {}, mods: { overhear: ['hun', 'yuezhi'] } },
  { id: 'either_i', tree: 't3', tier: 2, level: 3, act: 1, kind: 'passive', free: false, requires: ['skill:pt_a || skill:pt_b', 'level>=3'], teach: { who: 'uldin', when: 'names_known>=10' }, mods: { dodgeT: { set: 0.35 }, dodgeCost: { set: 10 } } },
];

// Senaryolar: [işlem, …]; her işlemden sonra sonuç ve oyuncunun durumu yazılır. GDScript tarafı aynı işlemleri Progression'da koşar.
//   addXp n | actChange n | spendStat id | learn id | teach id | grantPoint id | flag yol değer | setBar yuva id | checkTeach |
//   reset köken | restore oyuncu perde | states | block id | mods | mod anahtar varsayılan
const SCRIPTS = [
  ['xp_act1', 'origin_load', [
    ['addXp', 249], ['addXp', 1], ['addXp', 2615], ['addXp', 1710], ['addXp', 425], ['addXp', 0], ['addXp', -5], ['addXp', 2.4], ['addXp', 0.4],
    ['actChange', 2], ['actChange', 2], ['actChange', 1], ['addXp', 1600], ['actChange', 4], ['addXp', 3000],
  ]],
  ['xp_overflow', 'origin_stable', [
    ['actChange', 6], ['addXp', 69000], ['addXp', 1799], ['addXp', 1], ['addXp', 3600], ['addXp', 1800], ['addXp', 9000],
  ]],
  ['xp_budget_k43', 'origin_listener', [['addXp', 4575], ['actChange', 2], ['addXp', 7175], ['actChange', 3], ['addXp', 49], ['addXp', 1]]],
  ['stats', 'origin_load', [
    ['spendStat', 'grip'], ['addXp', 4575], ['spendStat', 'grip'], ['spendStat', 'grip'], ['spendStat', 'grip'], ['spendStat', 'grip'],
    ['spendStat', 'luck'], ['spendStat', 'word'], ['spendStat', 'eye'], ['actChange', 2], ['addXp', 6000], ['spendStat', 'grip'], ['spendStat', 'grip'],
  ]],
  ['no_origin', null, [['addXp', 250], ['spendStat', 'eye'], ['spendStat', 'eye'], ['spendStat', 'foot']]],
  ['unknown_origin', 'origin_nope', [['states']]],
  ['skills_flow', 'origin_load', [
    ['states'], ['block', 'pt_a'], ['flag', 'trust', 45], ['states'], ['flag', 'quest:q1.done', true], ['states'], ['block', 'pt_a'], ['learn', 'pt_a'],
    ['flag', 'gift', true], ['states'], ['addXp', 250], ['block', 'pt_a'], ['learn', 'pt_a'], ['mods'], ['block', 'pt_b'], ['learn', 'pt_b'],
    ['addXp', 550], ['block', 'pt_b'], ['learn', 'pt_b'], ['mods'], ['block', 'pt_c'], ['flag', 'opia_fate', 'other'], ['block', 'pt_c'],
    ['flag', 'opia_fate', 'covered'], ['block', 'pt_c'], ['grantPoint', 'mq_herd_school'], ['grantPoint', 'mq_herd_school'], ['grantPoint', ''],
    ['learn', 'pt_c'], ['mods'], ['setBar', 0, 'pt_c'], ['setBar', 1, 'pt_c'], ['setBar', 6, 'pt_c'], ['setBar', -1, 'pt_c'], ['setBar', 2, 'dried_meat'],
    ['setBar', 3, 'act2_e'], ['setBar', 2, null], ['block', 'pt_d'], ['flag', 'tally_kantu', true], ['block', 'pt_d'], ['flag', 'ties.mene', 1],
    ['block', 'tier_h'], ['flag', 'ties.mene', 2], ['block', 'tier_h'], ['flag', 'crow_hush', true], ['block', 'tier_h'], ['flag', 'crow_hush', false],
    ['addXp', 900], ['learn', 'tier_h'], ['block', 'either_i'], ['flag', 'names_known', 10], ['block', 'either_i'], ['learn', 'either_i'],
    ['teach', 'pt_d'], ['teach', 'pt_d'], ['teach', 'nope'], ['block', 'pt_d'], ['learn', 'pt_d'], ['learn', 'nope'], ['block', 'nope'], ['mods'],
    ['mod', 'load', 0], ['mod', 'draw', 1], ['mod', 'slowFrom', 0], ['mod', 'turn', 1], ['mod', 'sense', 0], ['mod', 'missing', 5], ['mod', 'missing', null],
  ]],
  ['sentenced', 'origin_stable', [
    ['flag', 'quest:q1.done', true], ['flag', 'trust', 50], ['flag', 'gift', true], ['states'], ['flag', 'sentenced', true], ['states'],
    ['block', 'pt_b'], ['block', 'pt_d'], ['flag', 'tally_kantu', true], ['states'], ['teach', 'pt_d'], ['states'], ['actChange', 2], ['states'],
  ]],
  ['hidden_and_masterless', 'origin_load', [
    ['states'], ['flag', 'whistling_arrow', true], ['states'], ['actChange', 2], ['states'], ['flag', 'm_bowyer', true], ['states'],
    ['flag', 'act1_done', true], ['states'], ['block', 'no_master_g'], ['addXp', 4600], ['block', 'no_master_g'], ['learn', 'no_master_g'],
    ['block', 'hid_f'], ['learn', 'hid_f'], ['addXp', 2000], ['block', 'act2_e'], ['flag', 'trust', 40], ['flag', 'm_quarter', true], ['block', 'act2_e'],
    ['learn', 'pt_b'], ['block', 'act2_e'], ['learn', 'act2_e'], ['mods'],
  ]],
  // Geçerli kayıt (progression.md §13.3'ün doğrulaması bir şey değiştirmez): Σstat + statPoints = 15 + 1 + (Sv − 1), skillPoints =
  // (Sv − 1) + pointsGranted + overflow − harcanan.
  ['restore', 'origin_load', [
    ['restore', {
      name: 'Mete', origin: 'origin_stable', appearance: null, level: 4, xp: 1800, statPoints: 1, skillPoints: 1, pointsGranted: ['mq_herd_school'],
      overflowPoints: 0, respecTokens: 0, stats: { grip: 4, wind: 3, foot: 5, eye: 3, word: 3 },
      skills: { pt_b: { at: 3, src: 'point' }, free_a: { at: 1, src: 'free' }, pt_a: { at: 2, src: 'point' }, pt_c: { at: 4, src: 'point' } },
      teach: ['pt_a', 'pt_b', 'free_a', 'pt_c'], lostMaster: ['pt_d'], bar: ['pt_c', null, 'dried_meat', null, null, null],
    }, 1],
    ['states'], ['mods'], ['mod', 'load', 0], ['mod', 'slowFrom', 0], ['mod', 'draw', 1], ['addXp', 1200], ['block', 'tier_h'], ['actChange', 2], ['states'],
  ]],
];

function playerState(p) {
  const s = p.playerJSON();
  return {
    act: p.act, level: s.level, xp: s.xp, statPoints: s.statPoints, skillPoints: s.skillPoints, pointsGranted: s.pointsGranted,
    overflowPoints: s.overflowPoints, respecTokens: s.respecTokens, origin: s.origin, originBond: p.originBond, stats: s.stats,
    skills: s.skills, teach: s.teach, lostMaster: s.lostMaster, bar: s.bar,
  };
}

function runScript(Progress, origin, ops) {
  const world = new Map();
  let p = null;
  const ctx = {
    get(path) {
      if (path === 'level') return p.level;
      if (path === 'act') return p.act;
      if (path.startsWith('stat.')) return p.stats[path.slice(5)];
      if (path.startsWith('skill:')) return p.learned.has(path.slice(6));
      return world.get(path);
    },
  };
  p = new Progress({ tables: { skills: SKILL_ROWS }, cond: ctx });
  p.resetPlayer({ origin });
  const out = [];
  for (const op of ops) {
    const [name, a, b] = op;
    let r = null;
    switch (name) {
      case 'addXp': r = p.addXp(a); break;
      case 'actChange': r = p.actChange(a); break;
      case 'spendStat': r = p.spendStat(a); break;
      case 'learn': r = p.learn(a); break;
      case 'teach': r = p.teach(a); break;
      case 'grantPoint': r = p.grantPoint(a); break;
      case 'setBar': r = p.setBar(a, b); break;
      case 'checkTeach': p.checkTeach(); break;
      case 'flag':
        // Bayrak yazılınca ilerlemenin dinleyicisi (progress.js 'flag:set'): sentenced onSentenced, öteki checkTeach.
        world.set(a, b);
        if (a === 'sentenced' && b) p.onSentenced();
        else p.checkTeach();
        break;
      case 'restore': p.restorePlayer(a, { world: { act: b } }); break;
      case 'states': r = Object.fromEntries(SKILL_ROWS.map((row) => [row.id, p.skillState(row.id)])); break;
      case 'block': r = p.learnBlock(a); break;
      case 'mods': r = { ...p.mods() }; break;
      case 'mod': r = p.mod(a, b ?? undefined); break;
      default: throw new Error(`bilinmeyen işlem ${name}`);
    }
    out.push({ op, r: r === undefined ? null : r, s: playerState(p) });
  }
  return out;
}

async function buildProgress(proto) {
  const P = await protoImport(proto, PROGRESS);
  const cases = [];
  for (const base of [0, 1, 10, 18, 20, 25, 30, 35, 40, 177, 178, 192, 205, 206, 2460]) {
    for (const act of [1, 2, 3, 4, 5, 6, 7]) cases.push({ id: `scaleXp/${base}/${act}`, fn: 'scaleXp', in: [base, act], out: P.scaleXp(base, act) });
  }
  for (const korku of [0, 3, 4, 9, 10, 36]) cases.push({ id: `dreadEffects/${korku}`, fn: 'dreadEffects', in: [korku], out: { ...P.dreadEffects(korku) } });
  for (const [id, origin, ops] of SCRIPTS) cases.push({ id: `script/${id}`, fn: 'script', in: { origin, ops }, out: runScript(P.Progress, origin, ops) });
  return {
    meta: {
      v: 1,
      tool: 'tools/proto_fixtures/progression.mjs',
      proto: [PROGRESS, 'src/game/cond.js'],
      proto_sha: protoSha(proto, [PROGRESS, 'src/game/cond.js']),
      kind: 'exact',
      tol: TOL.exact,
      note: 'Seviye, XP, perde tavanı, aşkın puan, köken, stat, beceri durum makinesi, mods katlama ve oyuncu kaydı. Beceri tablosu skills (sentetik; gerçek tablo data/progression/skills.json, K32 ve K43 ile değişti). script durumlarında her işlemden sonra { op, r, s } yazılır; s oyuncunun durumudur (teach ve lostMaster ekleniş sırasıyla). flag işlemi bayrağı yazar ve ilerlemenin bayrak dinleyicisini çağırır (sentenced → onSentenced, öteki → checkTeach). Koşul bağlamı: level, act, stat.<id>, skill:<id> ilerlemeden; gerisi bayraklardan.',
    },
    constants: {
      xpCurve: [...P.xpCurve], levelCaps: [...P.levelCaps], statCaps: [...P.statCaps], xpScale: [...P.xpScale],
      axisCaps: JSON.parse(JSON.stringify(P.axisCaps)), origins: JSON.parse(JSON.stringify(P.origins)), STAT_IDS: [...P.STAT_IDS],
    },
    skills: SKILL_ROWS,
    cases,
  };
}

// --- derive ---

function deriveInputs(BOWS) {
  const out = [];
  const add = (id, input) => out.push([id, input]);
  add('empty', {});
  const stats = (o) => ({ grip: 3, wind: 3, foot: 3, eye: 3, word: 3, ...o });
  for (const s of ['grip', 'wind', 'foot', 'eye', 'word']) for (let v = 3; v <= 12; v++) add(`stat/${s}/${v}`, { stats: stats({ [s]: v }) });
  for (const level of [1, 2, 5, 8, 11, 14, 17, 20]) add(`level/${level}`, { level, stats: stats({ grip: 5 }) });
  for (const [diff, limit] of [['story', 5], ['normal', 3], ['hard', 2]]) {
    for (let w = 0; w <= 4; w++) {
      add(`wounds/${diff}/${w}`, { wounds: w, stats: stats({ wind: w === 4 ? 9 : 3 }), diff: { woundLimit: limit, staRegen: diff === 'story' ? 1.15 : diff === 'hard' ? 0.9 : 1, wetBowK: diff === 'story' ? 0.5 : 1 } });
      add(`last_tooth/${diff}/${w}`, { wounds: w, mods: { speed: 1.15, dmg: 1.25 }, diff: { woundLimit: limit } });
    }
  }
  for (const fullness of [100, 25, 24.9, 0]) for (const wind of [3, 7]) add(`fullness/${fullness}/${wind}`, { fullness, stats: stats({ wind }) });
  for (const [grip, mods, loads] of [[3, null, [0, 6, 10.5, 15.75, 21, 25]], [4, null, [0, 12, 24, 30]], [4, { load: 8, slowFrom: { set: 0.5 } }, [16, 24, 32]], [3, { slowFrom: 0.99 }, [10, 21]]]) {
    for (const load of loads) add(`load/${grip}/${mods ? Object.keys(mods).join('+') : 'none'}/${load}`, { stats: stats({ grip }), mods, load });
  }
  add('load/gear', { gear: { load: 4, statBonus: { grip: 1 } }, load: 12 });
  for (const ground of ['path', 'deep', 'shelter']) {
    add(`ground/${ground}`, { env: { ground } });
    add(`ground/${ground}/drift`, { env: { ground }, mods: { deepSnowSpeed: { set: 0.85 }, deepSnowRegen: { set: 1 } }, gear: { snowSpeed: 1.05 } });
  }
  add('ground/shelter_flag', { env: { shelter: true } });
  const bowRow = (id) => ({ id, ...BOWS[id] });
  for (const [id, grip, eye] of [['toy_bow', 3, 3], ['loan_bow', 3, 5], ['fallen_bow', 4, 3], ['hun_bow', 3, 3], ['hun_bow', 5, 7], ['hun_bow', 9, 12], ['heavy_bow', 5, 3], ['heavy_bow', 7, 3], ['great_bow', 3, 3], ['han_crossbow', 3, 3]]) {
    add(`bow/${id}/${grip}/${eye}`, { stats: stats({ grip, eye }), bow: bowRow(id) });
  }
  // Yay kimlikle (İnce İş «+»): JS BOWS'tan okur; GDScript tarafı aynı satırları girdideki bows'tan alır.
  for (const ref of ['hun_bow', 'hun_bow+', 'toy_bow', 'han_crossbow+', 'no_such_bow']) {
    const base = ref.endsWith('+') ? ref.slice(0, -1) : ref;
    add(`bow_id/${ref}`, { stats: stats({ grip: 5 }), bow: ref, bows: BOWS[base] ? { [base]: { ...BOWS[base] } } : {} });
  }
  for (const wet of [0, 0.1, 0.13, 0.3, 0.5, 0.87, 1, 2, -1]) {
    add(`wet/hun/${wet}`, { stats: stats({ grip: 5 }), bow: bowRow('hun_bow'), env: { wetBow: wet } });
  }
  add('wet/loan', { bow: bowRow('loan_bow'), env: { wetBow: 1 } });
  add('wet/crossbow_story', { bow: bowRow('han_crossbow'), env: { wetBow: 0.75 }, diff: { wetBowK: 0.5 } });
  add('wet/loan_id', { bow: 'loan_bow', bows: { loan_bow: { ...BOWS.loan_bow } }, env: { wetBow: 1 } });
  add('bow/mods', { stats: stats({ grip: 5, eye: 6 }), bow: bowRow('hun_bow'), mods: { draw: { mul: 0.85 }, spread: { mul: 0.8 }, rideSpread: { mul: 0.6 }, gallopDrawPenalty: { set: 0 }, pen: 0.15, saddleShot: true }, gear: { drawMul: 0.95, spreadMul: 0.9, saddleSpreadMul: 0.8, saddleDrawMul: 1.1 } });
  add('bow/spread_floor', { stats: stats({ eye: 20 }), bow: bowRow('hun_bow'), mods: { spread: { mul: 0.2 } } });
  add('bow/pen_clamp', { mods: { pen: 1.7 } });
  for (const bell of [null, { on: true }, { on: true, plug: true }, { on: false, plug: true }]) {
    for (const foot of [3, 7, 12]) add(`bell/${bell ? (bell.on ? (bell.plug ? 'plug' : 'on') : 'off') : 'none'}/${foot}`, { stats: stats({ foot }), bell });
  }
  add('bell/snow_step', { bell: { on: true }, mods: { noiseCrouch: { set: 1.2 } } });
  add('bell/gear_noise', { bell: { on: false }, stats: stats({ foot: 12 }), gear: { noise: 0.5 } });
  const horse = { base: 10.5, spur: 3, saddled: true, load: 0, cap: 50 };
  for (const bond of [0, 40, 100, 140, -10]) add(`mount/bond/${bond}`, { bond, mount: horse });
  for (const load of [0, 25, 30, 37.5, 40, 50, 60]) add(`mount/load/${load}`, { bond: 40, mount: { ...horse, load } });
  add('mount/bareback', { bond: 40, mount: { ...horse, saddled: false } });
  add('mount/gear_unsaddled', { bond: 40, mount: { base: 10.5 }, gear: { saddled: false } });
  add('mount/no_spur', { bond: 40, mount: { base: 12 } });
  for (const [route, kut] of [[null, 0], ['R1', 0], ['R1', 5], ['R2', 6]]) add(`mount/blizzard/${route}/${kut}`, { bond: 60, mount: horse, env: { blizzard: true, route }, axes: { kut } });
  add('mount/shelter', { bond: 60, mount: horse, env: { shelter: true } });
  add('mount/mods', { bond: 50, mount: horse, mods: { turn: { mul: 1.25 }, horseDrain: { mul: 0.8 }, gallop: 2, bondGain: { mul: 1.25 }, mount: true, cartSpeed: 1, jolt: { mul: 0.5 } }, gear: { gallop: 0.5, turnMul: 1.1 } });
  for (const [debt, hearths] of [['none', 4], ['ash', 0], ['ash', 4], ['open', 12], ['ash', 20]]) add(`ash/${debt}/${hearths}`, { flags: { debt_erlik: debt }, axes: { hearths_out: hearths } });
  add('ash/flag_hearths', { flags: { debt_erlik: 'ash', hearths_out: 3 } });
  for (const korku of [0, 4, 10]) add(`dread/${korku}`, { axes: { korku }, stats: stats({ word: 6 }), mods: { trustGain: { mul: 1.15 } } });
  add('mods/combat', { stats: stats({ foot: 8, eye: 5 }), mods: { dodgeT: { set: 0.35 }, dodgeCost: { set: 10 }, slingRange: { set: 26 }, slingStun: { set: 2 }, sense: 6, oreSense: 15 } });
  add('mods/dodge_floor', { stats: stats({ foot: 40 }) });
  add('gear/full', {
    stats: stats({ grip: 4 }),
    gear: { statBonus: { grip: 1, eye: 2 }, hp: 15, load: 6, noise: -0.3, gallop: 0.5, runMul: 1.05, drawMul: 0.9, spreadMul: 0.9, turnMul: 1.1, visMul: 0.85, snowSpeed: 1.1, trackMul: 0.7, saddleSpreadMul: 0.8, saddleDrawMul: 1.1, dr: { slash: 20, pierce: 70, blunt: -30, fire: 5 }, courtOnly: true },
  });
  add('buff', { stats: stats({ wind: 4 }), buff: { grip: 1, wind: 2, sta: 10, staRegen: 1.2, runMul: 1.1, visMul: 0.9 } });
  add('labour_neutral_override', { mods: { buildTime: { mul: 0.7 }, helpers: 1, repairTime: { mul: 0.5 }, repairCost: { set: 0.25 }, overhear: ['hun', 'yuezhi'] } });
  add('acceptance_7', { stats: stats({ wind: 3 }), wounds: 2 });
  add('acceptance_26', { stats: stats({ wind: 5 }), env: { ground: 'path' }, fullness: 60 });
  add('acceptance_27', { bond: 40, mount: horse });
  return out;
}

async function buildDerive(proto) {
  const D = await protoImport(proto, DERIVE);
  const { BOWS } = await protoImport(proto, 'src/data/weapons.js');
  const { DIFFICULTY } = await protoImport(proto, 'src/data/difficulty.js');
  const cases = [];
  for (const [id, input] of deriveInputs(BOWS)) cases.push({ id: `derive/${id}`, fn: 'derive', in: input, out: D.derive(input) });
  for (const l of [-1, 0, 0.25, 0.5, 0.51, 0.75, 0.9, 1, 1.5]) cases.push({ id: `mountLoadK/${l}`, fn: 'mountLoadK', in: [l], out: D.mountLoadK(l) });
  for (const w of [-1, 0, 0.12, 0.125, 0.13, 0.37, 0.375, 0.6, 1, 3]) cases.push({ id: `stepWet/${w}`, fn: 'stepWet', in: [w], out: D.stepWet(w) });
  const d = D.derive({ bond: 40, mount: { base: 10.5 } });
  for (const speed of [0, 3, 6.27, 12.54, 20]) cases.push({ id: `turnRateAt/${speed}`, fn: 'turnRateAt', in: [{ gallop: d.gallop, turnRate: { ...d.turnRate } }, speed], out: D.turnRateAt(d, speed) });
  cases.push({ id: 'turnRateAt/no_gallop', fn: 'turnRateAt', in: [{ gallop: null, turnRate: { still: 4.4, top: 2.8 } }, 5], out: D.turnRateAt({ gallop: null, turnRate: { still: 4.4, top: 2.8 } }, 5) });
  const normal = DIFFICULTY.normal;
  return {
    meta: {
      v: 1,
      tool: 'tools/proto_fixtures/progression.mjs',
      proto: [DERIVE, ...DERIVE_DEPS],
      proto_sha: protoSha(proto, [DERIVE, ...DERIVE_DEPS]),
      kind: 'math',
      tol: TOL.math,
      note: 'progression.md §2.3. derive girdisi prototipin alan adlarıdır; diff verilmezse Normal satırı (staRegen 1, woundLimit 3, wetBowK 1). bow satır (kimlik ve sayılar) ya da kimliktir; kimlikli durumda bows o satırı taşır (prototip kendi BOWS tablosunu okur, Godot girdinin bows\'unu). Çıktının yay alanları yaysız null, binek alanları bineksiz null ya da 0.',
    },
    constants: { difficultyNormal: { staRegen: normal.staRegen, woundLimit: normal.woundLimit, wetBowK: normal.wetBowK } },
    cases,
  };
}

if (isMain(import.meta.url)) {
  runCli('progression fixture', [{ name: 'progress', build: buildProgress }, { name: 'derive', build: buildDerive }]).then((code) => process.exit(code), (err) => {
    console.error(err);
    process.exit(1);
  });
}

export { buildDerive, buildProgress };
