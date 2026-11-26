#!/usr/bin/env node
// Envanter fikstürü (godot.md §8.2, K29; Yol Haritası inventory): prototipin saf kap ve heybe modülleri (src/game/container.js,
// items.js, inventory.js; tabloları src/data/items.js, gear.js) sabit işlem dizileriyle koşar. Durumlar:
//   stack_load10 [id, n] → onda bir Yük      tab_of [id] → [sekme, yuva tutar mı]      matches [id, ref] → bool
//   container_ops {boxes, ops} → her işlemin sonucu (ItemContainer: canTake, add, remove, transfer, transferAll, onDawn, toJSON …)
//   inventory_ops {setup, ops} → her işlemin sonucu (Inventory: Yük ve hız, terki taşması, sekmeler, kuşam, sadak, el koyma, şafak)
// GDScript tarafı tests/unit/test_inventory_proto.gd aynı işlemleri ItemContainer ve Inventory üstünde koşar (ProtoFixture.run_cases).
// Değişen kural fikstüre girmez: Godot'nun eklediği satırlar (Çocukluk'un avı, Kemik Gem), adı ya da sayısı ekonomi modeliyle düzelen
// satırlar (bolt, grain_sack, Kışlak kılığı) ve prototipte olmayan model satırları (cowrie ...) işlemlerde kullanılmaz.
//
//   node tools/proto_fixtures/inventory.mjs [--proto yol] [--check]   → tests/fixtures/inventory.json
import { TOL, isMain, protoImport, protoSha, runCli } from './_shared.mjs';

const MODULES = ['src/game/container.js', 'src/game/items.js', 'src/game/inventory.js', 'src/data/items.js', 'src/data/gear.js'];

// ---------- Kap senaryoları ----------
// Kaplar: { ad: { kind, cap10?, accept? } }; işlem: [ad, kap, ...argümanlar]. Süzgeç etiketle verilir (filter_tag).
const CONTAINER_CASES = [
  {
    id: 'container/limits',
    note: 'sandık: sınır, kabul ve yuvasız kap',
    boxes: { chest: { kind: 'chest' }, granary: { kind: 'granary' }, treasury: { kind: 'treasury' }, armoury: { kind: 'armoury' }, shed: { kind: 'shed' }, sled: { kind: 'sled' } },
    ops: [
      ['can_take', 'chest', 'stone', 20], ['can_take', 'chest', 'arrow_bone', 2000], ['add', 'chest', 'stone', 11], ['free10', 'chest'],
      ['can_take', 'chest', 'stone', 5], ['can_take', 'chest', 'wood_pine', 5], ['can_take', 'chest', 'arrow_bone', 200],
      ['can_take', 'granary', 'wood_pine', 1], ['add', 'granary', 'wood_pine', 1], ['can_take', 'granary', 'millet', 10], ['can_take', 'granary', 'meat', 4],
      ['add_over', 'granary', 'wood_pine', 1], ['can_take', 'treasury', 'gold_old', 3], ['can_take', 'treasury', 'fur_sable', 3], ['can_take', 'treasury', 'felt', 3],
      ['can_take', 'armoury', 'hun_bow+', 1], ['can_take', 'armoury', 'arrow_iron', 10], ['can_take', 'armoury', 'meal', 1],
      ['can_take', 'shed', 'fodder', 1], ['can_take', 'shed', 'hay', 1], ['can_take', 'shed', 'stone', 1], ['can_take', 'shed', 'rope', 1],
      ['can_take', 'sled', 'wood_pine', 9], ['can_take', 'sled', 'rope', 1], ['load10', 'chest'],
    ],
  },
  {
    id: 'container/slots',
    note: 'Heybe: 24 ortak yuva, sırt yükü yuva tutmaz',
    boxes: { pack: { kind: 'pack', cap10: 10000 }, meal: { kind: 'pack', cap10: 10000 }, chest: { kind: 'chest', cap10: 10000 }, cache: { kind: 'cache' } },
    ops: [
      ['can_take', 'pack', 'rope', 1000], ['add', 'pack', 'rope', 470], ['slots_used', 'pack'], ['can_take', 'pack', 'rope', 20], ['can_take', 'pack', 'felt', 1],
      ['can_take', 'pack', 'stone', 1], ['add', 'meal', 'meal', 230], ['can_take', 'meal', 'rope', 1], ['can_take', 'meal', 'rope', 30],
      ['add', 'chest', 'rope', 470], ['can_take', 'chest', 'felt', 1], ['add', 'cache', 'dried_meat', 70], ['add', 'cache', 'stone', 2], ['slots_used', 'cache'],
    ],
  },
  {
    id: 'container/partial',
    note: 'kısmi aktarma, etiket, kabul',
    boxes: { pack: { kind: 'pack', cap10: 400 }, sled: { kind: 'sled' }, a: { kind: 'chest' }, b: { kind: 'stash', cap10: 100 }, c: { kind: 'granary' } },
    ops: [
      ['add', 'pack', 'stone', 6], ['transfer', 'pack', 'sled', 'stone', 6], ['count', 'pack', 'stone'], ['load10', 'sled'],
      ['add', 'a', 'wood_pine', 2], ['add', 'a', 'wood_willow', 3], ['add', 'a', 'rope', 4], ['transfer', 'a', 'b', 'tag:wood', 5],
      ['count', 'b', 'tag:wood'], ['count', 'a', 'tag:wood'], ['transfer', 'a', 'c', 'rope', 4], ['list', 'a'], ['list', 'b'],
    ],
  },
  {
    id: 'container/bulk',
    note: 'toplu aktarma: Sırtı Boşalt ve Eksikleri Al',
    boxes: { pack: { kind: 'pack', cap10: 1000 }, store: { kind: 'store_yurt' }, site: { kind: 'site', cap10: 60 }, full: { kind: 'stash', cap10: 20 }, big: { kind: 'chest' }, small: { kind: 'stash', cap10: 50 } },
    ops: [
      ['add', 'pack', 'stone', 2], ['add', 'pack', 'wood_pine', 2], ['add', 'pack', 'rope', 3], ['add', 'pack', 'meal', 2],
      ['transfer_all', 'pack', 'store', null, { filter_tag: 'tag:bulk' }], ['list', 'pack'],
      ['transfer_all', 'store', 'site', [{ id: 'tag:wood', n: 3 }, { id: 'stone', n: 1 }]], ['transfer_all', 'pack', 'full', null],
      ['add', 'big', 'stone', 3], ['transfer_all', 'big', 'small', null],
    ],
  },
  {
    id: 'container/perish',
    note: 'bozulma: gün parçaları, kış dünyasında balık, aktarma gün taşır',
    boxes: { c: { kind: 'chest' }, pack: { kind: 'pack', cap10: 200 }, chest: { kind: 'chest' } },
    ops: [
      ['add_day', 'c', 'meat', 1, 9], ['add_day', 'c', 'meat', 2, 10], ['add_day', 'c', 'fish', 2, 9], ['add_day', 'c', 'dried_meat', 3, 1],
      ['days_of', 'c', 'meat'], ['on_dawn', 'c', 11, false], ['count', 'c', 'meat'], ['count', 'c', 'spoiled'], ['count', 'c', 'fish'], ['load10', 'c'],
      ['on_dawn', 'c', 12, true], ['on_dawn', 'c', 13, true], ['count', 'c', 'spoiled'], ['on_dawn', 'c', 14, true],
      ['add_day', 'pack', 'meat', 2, 4], ['add_day', 'pack', 'meat', 3, 5], ['on_dawn', 'pack', 5, true], ['remove', 'pack', 'meat', 1],
      ['days_of', 'pack', 'meat'], ['transfer', 'pack', 'chest', 'meat', 2], ['days_of', 'chest', 'meat'], ['days_of', 'pack', 'meat'],
      ['on_dawn', 'chest', 6, true], ['on_dawn', 'chest', 7, true], ['add', 'chest', 'meat_small', 2], ['days_of', 'chest', 'meat_small'],
      ['to_json', 'c'], ['to_json', 'chest'],
    ],
  },
  {
    id: 'container/bundle',
    note: 'bohça: yurt_kit şantiyede açılır',
    boxes: { cart: { kind: 'cart', cap10: 600 }, site: { kind: 'site', cap10: 1112, accept: ['door_frame', 'kerege_set', 'yurt_crown', 'pole', 'uuk_set', 'chiy', 'felt', 'rope', 'stone'] },
      tent: { kind: 'site', accept: ['pole', 'rope', 'felt'] }, box: { kind: 'chest' } },
    ops: [
      ['can_take', 'cart', 'yurt_kit', 2], ['add', 'cart', 'yurt_kit', 1], ['transfer_unpack', 'cart', 'site', 'yurt_kit', 1], ['count', 'cart', 'yurt_kit'],
      ['list', 'site'], ['load10', 'site'], ['add', 'box', 'tent_kit', 1], ['transfer_unpack', 'box', 'tent', 'tent_kit', 1], ['count', 'box', 'tent_kit'],
    ],
  },
];

function runContainerOps(C, I, cs) {
  const { makeContainer, transfer, transferAll } = C;
  const { matches } = I;
  const boxes = {};
  for (const [name, def] of Object.entries(cs.boxes)) {
    const opts = {};
    if (def.cap10 !== undefined) opts.cap10 = def.cap10;
    if (def.accept) opts.accept = (id) => def.accept.some((ref) => matches(id, ref));
    boxes[name] = makeContainer(def.kind, opts);
  }
  const out = [];
  for (const op of cs.ops) {
    const [kind, a, ...args] = op;
    const c = boxes[a];
    let r;
    switch (kind) {
      case 'add': r = c.add(args[0], args[1]); break;
      case 'add_over': r = c.add(args[0], args[1], { allowOver: true }); break;
      case 'add_day': r = c.add(args[0], args[1], { day: args[2] }); break;
      case 'can_take': r = c.canTake(args[0], args[1]); break;
      case 'free10': r = c.free10(); break;
      case 'load10': r = c.load10(); break;
      case 'slots_used': r = c.slotsUsed(); break;
      case 'count': r = c.count(args[0]); break;
      case 'list': r = c.list(); break;
      case 'days_of': r = c.daysOf(args[0]); break;
      case 'remove': r = c.remove(args[0], args[1]); break;
      case 'on_dawn': r = c.onDawn(args[0], { perishFish: args[1] }); break;
      case 'to_json': r = c.toJSON(); break;
      case 'transfer': r = transfer(c, boxes[args[0]], args[1], args[2]); break;
      case 'transfer_unpack': r = transfer(c, boxes[args[0]], args[1], args[2], { unpack: true }); break;
      case 'transfer_all': {
        const tag = args[2]?.filter_tag;
        r = transferAll(c, boxes[args[0]], args[1], { filter: tag ? (id) => matches(id, tag) : null });
        break;
      }
      default: throw new Error(`bilinmeyen kap işlemi ${kind}`);
    }
    out.push(r ?? null);
  }
  return out;
}

// ---------- Heybe senaryoları ----------
// Kurulum: { cap, slowFrom?, day? }; işlem: [ad, ...argümanlar].
const INVENTORY_CASES = [
  {
    id: 'inventory/speed',
    note: 'Yük ve hız: yarıda 0,85, tamda 0,7; dörtte üçte koşu yok',
    setup: { cap: 24 },
    ops: [['capacity'], ['speedK'], ['add', 'ore_iron', 3], ['load'], ['loadFrac'], ['speedK'], ['canRun'], ['canJump'], ['add', 'ore_iron', 2],
      ['loadFrac'], ['canRun'], ['canJump'], ['add', 'ore_iron', 1], ['speedK'], ['add_over', 'stone', 2], ['speedK'], ['load']],
  },
  {
    id: 'inventory/carry_pack',
    note: 'Sırt Yükü: yarıya dek ×1',
    setup: { cap: 32, slowFrom: 0.5 },
    ops: [['add', 'ore_iron', 4], ['load'], ['speedK'], ['add', 'ore_iron', 4], ['speedK'], ['remove', 'ore_iron', 2], ['speedK']],
  },
  {
    id: 'inventory/limit_sled',
    note: 'sınır, sığmayan kalır; kızak +12 ve ×0,9',
    setup: { cap: 21 },
    ops: [['add', 'stone', 5], ['add', 'stone', 1], ['add_over', 'wood_pine', 1], ['load'], ['sled_add', 'wood_pine', 3], ['sledOn', true], ['capacity'],
      ['load'], ['speedK'], ['sledOn', false], ['capacity']],
  },
  {
    id: 'inventory/saddlebags',
    note: 'terki: binek Yük\'ü, taşma',
    setup: { cap: 21 },
    ops: [['bag_cap', 'yakwe'], ['bag_cap', 'offering_stallion'], ['bag_cap', 'spare_horse'], ['add_mount', 'wood_pine', 8, 'yakwe'],
      ['pack_count', 'wood_pine'], ['bag_count', 'yakwe', 'wood_pine'], ['add_mount', 'stone', 30, 'yakwe'], ['bag_load', 'yakwe']],
  },
  {
    id: 'inventory/tabs',
    note: 'sekmeler ve 24 ortak yuva',
    setup: { cap: 500 },
    ops: [['add', 'stone', 2], ['add', 'meal', 3], ['add', 'herb_wormwood', 2], ['add', 'rope', 4], ['add', 'axe_bronze', 1], ['add', 'axe_bronze', 1],
      ['add', 'tally_farnak', 1], ['tab', 'back'], ['tab', 'food'], ['tab', 'craft'], ['tab', 'tools'], ['tab', 'keepsakes'], ['load'],
      ['has', 'axe_bronze'], ['count', 'tag:herb'], ['slotsUsed'], ['add', 'felt', 210], ['slotsFree'], ['add', 'reed', 1], ['add', 'stone', 1]],
  },
  {
    id: 'inventory/remove',
    note: 'çıkarma: etiket, araç, kuşanılan',
    setup: { cap: 40 },
    ops: [['add', 'wood_pine', 2], ['add', 'wood_willow', 2], ['add', 'pick_bronze', 1], ['count', 'tag:wood'], ['remove', 'tag:wood', 3],
      ['remove', 'pick_bronze', 1], ['has', 'pick_bronze'], ['equip', 'hands', 'glove_sak'], ['count', 'glove_sak'], ['remove', 'glove_sak', 1],
      ['equipped', 'hands'], ['remove', 'stone', 2]],
  },
  {
    id: 'inventory/equip',
    note: 'kuşam: yuva denetimi, eskisi heybeye, gearBlock',
    setup: { cap: 30 },
    ops: [['add', 'felt_boots', 1], ['equip', 'head', 'felt_boots'], ['equip', 'feet', 'stone'], ['equip', 'feet', 'felt_boots'], ['pack_count', 'felt_boots'],
      ['load'], ['equip', 'feet', 'fur_boots'], ['pack_count', 'felt_boots'], ['equip', 'feet', 'felt_boots'], ['equip', 'body', 'hide_lamellar'],
      ['equip', 'belt', 'pouch_belt'], ['equip', 'neck', 'gold_torque'], ['equip', 'bow', 'hun_bow+'], ['gear'], ['unequip', 'feet'], ['equipped', 'feet'], ['gear']],
  },
  {
    id: 'inventory/quiver',
    note: 'sadak: doldurma, atış, çıkınca oklar heybeye',
    setup: { cap: 30 },
    ops: [['add', 'arrow_bone', 20], ['quiverCap'], ['equip', 'quiver', 'quiver_farnak'], ['quiverCap'], ['fillQuiver'], ['pack_count', 'arrow_bone'],
      ['spendArrow', 'arrow_bone'], ['arrows'], ['spendArrow', 'arrow_iron'], ['unequip', 'quiver'], ['arrows'], ['pack_count', 'arrow_bone']],
  },
  {
    id: 'inventory/seize',
    note: 'el koyma ve geri alma',
    setup: { cap: 60 },
    ops: [['add', 'notch_stick', 1], ['add', 'tally_farnak', 1], ['add', 'tally_kantu', 1], ['add', 'meal', 2], ['add', 'rope', 3], ['add', 'hoof_wraps', 1],
      ['add', 'knife_iron', 1], ['add', 'axe_bronze', 1], ['add', 'net', 1], ['equip', 'body', 'hostage_coat'], ['equip', 'cape', 'wolf_pelt'],
      ['equip', 'hands', 'glove_sak'], ['equip', 'feet', 'felt_boots'], ['equip', 'belt', 'plaque'], ['equip', 'neck', 'shrieker'],
      ['equip', 'blade', 'akinakes'], ['equip', 'quiver', 'quiver_farnak'], ['add', 'arrow_bone', 5], ['fillQuiver'], ['chest_add', 'felt', 3],
      ['stash_add', 'way_camp', 'dried_meat', 4], ['cache_add', 'RB07', 'dried_meat', 6], ['bag_add', 'yakwe', 'hay', 2], ['seize'],
      ['pack_list_sorted'], ['equipment'], ['has_tool', 'axe_bronze'], ['cache_count', 'dried_meat'], ['chest_empty'], ['restoreSeized'],
      ['pack_count', 'meal'], ['pack_count', 'dried_meat'], ['has_tool', 'net'], ['equipped', 'blade'], ['equipped', 'quiver'], ['arrows']],
  },
  {
    id: 'inventory/dawn',
    note: 'şafak: gün anahtarı, ikinci şafakta bozulma, ilk şafakta eşleme',
    setup: { cap: 40 },
    ops: [['add', 'meat', 2], ['chest_add_day', 'fish', 1], ['onDawn', 1042], ['day'], ['pack_days', 'meat'], ['add', 'meat', 1], ['pack_days', 'meat'],
      ['onDawn', 1043], ['pack_count', 'spoiled'], ['pack_count', 'meat'], ['onDawn', 1043], ['add', 'meat', 3], ['longSkip', 3], ['day'],
      ['pack_count', 'meat'], ['pack_count', 'spoiled']],
  },
];

function runInventoryOps(InventoryClass, cs) {
  const s = cs.setup;
  const inv = new InventoryClass({ cap: () => s.cap, slowFrom: s.slowFrom === undefined ? null : () => s.slowFrom, day: s.day ?? 0 });
  const out = [];
  for (const [kind, ...a] of cs.ops) {
    let r;
    switch (kind) {
      case 'capacity': r = inv.capacity(); break;
      case 'load': r = inv.load(); break;
      case 'loadFrac': r = inv.loadFrac(); break;
      case 'speedK': r = inv.speedK(); break;
      case 'canRun': r = inv.canRun(); break;
      case 'canJump': r = inv.canJump(); break;
      case 'add': r = inv.add(a[0], a[1]); break;
      case 'add_over': r = inv.add(a[0], a[1], { allowOver: true }); break;
      case 'add_mount': r = inv.add(a[0], a[1], { mount: a[2] }); break;
      case 'remove': r = inv.remove(a[0], a[1]); break;
      case 'count': r = inv.count(a[0]); break;
      case 'has': r = inv.has(a[0]); break;
      case 'has_tool': r = inv.hasTool(a[0]); break;
      case 'tab': r = inv.tab(a[0]); break;
      case 'slotsUsed': r = inv.pack.slotsUsed(); break;
      case 'slotsFree': r = inv.pack.slotsFree(); break;
      case 'pack_count': r = inv.pack.count(a[0]); break;
      case 'pack_days': r = inv.pack.daysOf(a[0]); break;
      case 'pack_list_sorted': r = inv.pack.list().map((it) => it.id).sort(); break;
      case 'equip': r = inv.equip(a[0], a[1]); break;
      case 'unequip': r = inv.unequip(a[0]); break;
      case 'equipped': r = inv.equipped(a[0]); break;
      case 'equipment': r = inv.snapshot().equip; break;
      case 'gear': {
        const g = inv.equipBlock();
        r = { dr: g.dr, statBonus: g.statBonus, load: g.load, noise: g.noise, visMul: g.visMul, snowSpeed: g.snowSpeed, trackMul: g.trackMul, quiverCap: g.quiverCap, bow: g.bow };
        break;
      }
      case 'quiverCap': r = inv.quiverCap(); break;
      case 'fillQuiver': r = inv.fillQuiver(); break;
      case 'spendArrow': r = inv.spendArrow(a[0]); break;
      case 'arrows': r = { ...inv.arrows }; break;
      case 'sled_add': r = inv.sled.add(a[0], a[1]); break;
      case 'sledOn': inv.sledOn = a[0]; r = null; break;
      case 'bag_cap': r = inv.saddlebags(a[0]).cap; break;
      case 'bag_count': r = inv.saddlebags(a[0]).count(a[1]); break;
      case 'bag_load': r = inv.saddlebags(a[0]).load(); break;
      case 'bag_add': r = inv.saddlebags(a[0]).add(a[1], a[2]); break;
      case 'chest_add': r = inv.chest.add(a[0], a[1]); break;
      case 'chest_add_day': r = inv.chest.add(a[0], a[1], { day: inv.day }); break;
      case 'chest_empty': r = inv.chest.isEmpty(); break;
      case 'stash_add': r = inv.stash(a[0]).add(a[1], a[2]); break;
      case 'cache_add': r = inv.cache.add(a[1], a[2], { rb: a[0] }); break;
      case 'cache_count': r = inv.cache.count(a[0]); break;
      case 'seize': {
        const res = inv.seize();
        r = { items: [...res.items].sort((x, y) => x.id.localeCompare(y.id)), tools: [...res.tools].sort(), equip: res.equip, arrows: { ...inv.seized.arrows } };
        break;
      }
      case 'restoreSeized': {
        const res = inv.restoreSeized();
        r = { items: res.items.length, tools: [...res.tools].sort(), equip: res.equip };
        break;
      }
      case 'onDawn': r = inv.onDawn(a[0]); break;
      // Uzun atlama (clock:skip long): bir kez, şafak sayısı kadar ileri.
      case 'longSkip': r = inv._advance(inv.day + a[0]); break;
      case 'day': r = inv.day; break;
      default: throw new Error(`bilinmeyen heybe işlemi ${kind}`);
    }
    out.push(r ?? null);
  }
  return out;
}

const ITEM_PROBES = [['arrow_bone', 10], ['arrow_bone', 11], ['arrowhead_iron', 60], ['wood_pine', 3], ['feather', 30], ['arrow_shaft', 1], ['stone', 0], ['meat_small', 7]];
const TAB_PROBES = ['stone', 'meal', 'herb_wormwood', 'rope', 'axe_bronze', 'tally_farnak', 'hide', 'felt_boots', 'shrieker', 'wood_tamarisk', 'yurt_kit'];
const MATCH_PROBES = [['wood_larch', 'tag:wood'], ['wood_birch', 'tag:wood_light'], ['wood_larch', 'tag:wood_hard'], ['wood_pine', 'tag:wood_light'],
  ['stone', 'tag:wood'], ['sprig_juniper', 'tag:wood'], ['sprig_juniper', 'tag:fuel'], ['hun_bow+', 'hun_bow'], ['hun_bow', 'hun_bow+'],
  ['hun_bow+', 'hun_bow+'], ['hun_bow+', 'tag:gear']];

export async function build(proto) {
  const C = await protoImport(proto, 'src/game/container.js');
  const I = await protoImport(proto, 'src/game/items.js');
  const { Inventory } = await protoImport(proto, 'src/game/inventory.js');
  const cases = [];
  for (const [id, n] of ITEM_PROBES) cases.push({ id: `stack_load10/${id}/${n}`, fn: 'stack_load10', in: [id, n], out: I.stackLoad10(id, n) });
  for (const id of TAB_PROBES) cases.push({ id: `tab_of/${id}`, fn: 'tab_of', in: [id], out: [I.tabOf(id), I.usesSlot(id)] });
  for (const [id, ref] of MATCH_PROBES) cases.push({ id: `matches/${id}/${ref}`, fn: 'matches', in: [id, ref], out: I.matches(id, ref) });
  for (const cs of CONTAINER_CASES) {
    cases.push({ id: cs.id, fn: 'container_ops', note: cs.note, in: { boxes: cs.boxes, ops: cs.ops }, out: runContainerOps(C, I, cs) });
  }
  for (const cs of INVENTORY_CASES) {
    cases.push({ id: cs.id, fn: 'inventory_ops', note: cs.note, in: { setup: cs.setup, ops: cs.ops }, out: runInventoryOps(Inventory, cs) });
  }
  return {
    meta: {
      v: 1,
      tool: 'tools/proto_fixtures/inventory.mjs',
      proto: MODULES,
      proto_sha: protoSha(proto, MODULES),
      kind: 'math',
      tol: TOL.math,
      note: 'Kap ve heybe: onda bir Yük, yuva, kabul, aktarma, bozulma, bohça, hız, terki, sekmeler, kuşam, sadak, el koyma, şafak. Sayılar 1e-9, tamsayı ve kimlik tam eşit.',
    },
    cases,
  };
}

if (isMain(import.meta.url)) {
  runCli('inventory', [{ name: 'inventory', build }]).then((code) => process.exit(code), (err) => {
    console.error(err.message ?? err);
    process.exit(1);
  });
}
