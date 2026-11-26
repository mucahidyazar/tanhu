// Prototip fikstürlerinin ortak yardımcıları (godot.md §8.2, K29): prototipin yolu, değişen kural bekçisi, sayı kodlaması,
// kararlı JSON yazımı ve --check. Alan dosyaları (tools/proto_fixtures/<alan>.mjs) isterse bunu kullanır; adı «_» ile başladığı
// için tools/proto_fixtures.mjs onu alan saymaz.
//
// Fikstür dosyasının önerilen biçimi (tests/fixtures/<ad>.json):
//   { "meta": { "v": 1, "tool": "tools/proto_fixtures/<alan>.mjs", "proto": ["src/game/x.js", …], "proto_sha": { yol: sha1 },
//               "kind": "math" | "sim" | "exact", "tol": 1e-9, "note": "…" },
//     "constants": { … },                       // isteğe bağlı: taşınan tabloların prototipteki değeri
//     "cases": [ { "id": "eff/1.5", "fn": "eff", "in": [1.5], "out": 1.4598…, "tol"?: 1e-6 }, … ] }
// Tolerans: saf matematik 1e-9, birikimli benzetim 1e-6, tamsayı ve kimlik tam eşit (TOL). Sayı olmayan değerler JSON'da yazılamaz:
// Infinity "inf", -Infinity "-inf", NaN "nan" olur (hava fikstürüyle aynı yazım; GDScript yardımcısı tests/support/proto_fixture.gd
// sayı beklenen yerde bunları sayıya çevirir).
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
// Godot projesinin kökü (game/) ve fikstür klasörü.
export const GAME = resolve(HERE, '../..');
export const FIXTURE_DIR = join(GAME, 'tests/fixtures');
export const DEFAULT_PROTO = process.env.TANHU_PROTO ?? join(homedir(), 'Code/tests/tanhu-programatic-test');

// Toleranslar (godot.md §8.2).
export const TOL = Object.freeze({ math: 1e-9, sim: 1e-6, exact: 0 });

// Değişen kural fikstüre girmez (godot.md §3.2 madde 8, K29). Bekçi bu dışa aktarımlara erişimi durdurur: beklenen değerleri alan
// belgesinden ve d2 modellerinden yazılır. '*' modülün hepsidir.
export const CHANGED_RULES = Object.freeze({
  'src/game/labour.js': Object.freeze({
    exports: Object.freeze(['stepRate', 'simulate', 'etaMinutes', 'remaining', 'deriveSteps', 'repairWork']),
    why: 'K50: inşaat, söküm ve onarım T(n) = taban × 0,75^(min(n, 8) − 1) ile işler; beklenen değerler structures.md §2.4 ve d2/labour-model.json v3’tendir',
  }),
  'src/audio/instruments/dombra.js': Object.freeze({ exports: '*', why: 'K60: dombra yerine kopuz' }),
  'src/game/world-clock.js': Object.freeze({
    exports: Object.freeze(['roamMoonAge']),
    why: 'K67: Serbest Gez ayrı sayaç tutmaz, oyunun tek takvimini okur',
  }),
});

// Komut satırı: --proto <yol> (ya da --proto=<yol>), --check. Bilinmeyen argüman hatadır.
export function parseArgs(argv, tag = 'proto fixtures') {
  const o = { proto: DEFAULT_PROTO, check: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--proto') o.proto = resolve(argv[++i] ?? '');
    else if (a.startsWith('--proto=')) o.proto = resolve(a.slice(8));
    else if (a === '--check') o.check = true;
    else throw new Error(`[${tag}] bilinmeyen argüman: ${a}`);
  }
  return o;
}

// Prototip kökü geçerli mi (src/game var mı)?
export function assertProto(proto, tag = 'proto fixtures') {
  if (!existsSync(join(proto, 'src/game'))) throw new Error(`[${tag}] prototip bulunamadı: ${proto} (TANHU_PROTO ya da --proto)`);
}

// Prototip modülünü kendi yolundan içe aktarır; değişen kural dışa aktarımı okununca hata atar. Prototip salt okunur kalır.
export async function protoImport(proto, rel) {
  const ns = await import(pathToFileURL(join(proto, rel)).href);
  const rule = CHANGED_RULES[rel];
  if (!rule) return ns;
  return new Proxy(ns, {
    get(target, key, receiver) {
      if (typeof key === 'string' && (rule.exports === '*' || rule.exports.includes(key))) {
        throw new Error(`değişen kural fikstüre girmez: ${rel} ${key} (${rule.why})`);
      }
      return Reflect.get(target, key, receiver);
    },
  });
}

// Prototip dosyalarının içerik özeti: fikstürü yazan sürüm bellidir (prototip değişirse --check farkı gösterir).
export function protoSha(proto, rels) {
  const out = {};
  for (const rel of rels) out[rel] = createHash('sha1').update(readFileSync(join(proto, rel))).digest('hex');
  return out;
}

// JSON'a yazılabilir derin kopya: sayı olmayan sayılar yazıyla, nesnede undefined atlanır, dizide null olur; işlev yazılamaz.
export function encode(value, path = '$') {
  if (typeof value === 'number') {
    if (Number.isNaN(value)) return 'nan';
    if (value === Infinity) return 'inf';
    if (value === -Infinity) return '-inf';
    return Object.is(value, -0) ? 0 : value;
  }
  if (value === null || typeof value === 'string' || typeof value === 'boolean') return value;
  if (value === undefined) return null;
  if (typeof value === 'function') throw new TypeError(`fikstüre işlev yazılamaz: ${path}`);
  if (typeof value === 'bigint') throw new TypeError(`fikstüre bigint yazılamaz: ${path}`);
  if (value instanceof Map) return encode(Object.fromEntries(value), path);
  if (value instanceof Set) return encode([...value], path);
  if (ArrayBuffer.isView(value)) return encode([...value], path);
  if (Array.isArray(value)) return value.map((v, i) => encode(v, `${path}[${i}]`));
  const out = {};
  for (const [k, v] of Object.entries(value)) {
    if (v === undefined) continue;
    out[k] = encode(v, `${path}.${k}`);
  }
  return out;
}

const isScalar = (v) => v === null || typeof v !== 'object';

// Kararlı ve okunur JSON: nesneler girintili, yalnız düz değer taşıyan diziler tek satırda. Aynı girdi aynı baytları verir.
export function pretty(value, indent = '') {
  if (isScalar(value)) return JSON.stringify(value);
  const next = `${indent}\t`;
  if (Array.isArray(value)) {
    if (value.length === 0) return '[]';
    if (value.every(isScalar)) return `[${value.map((v) => JSON.stringify(v)).join(', ')}]`;
    return `[\n${value.map((v) => next + pretty(v, next)).join(',\n')}\n${indent}]`;
  }
  const keys = Object.keys(value);
  if (keys.length === 0) return '{}';
  return `{\n${keys.map((k) => `${next}${JSON.stringify(k)}: ${pretty(value[k], next)}`).join(',\n')}\n${indent}}`;
}

// Fikstürü yazar ya da (check) diskteki dosyayla karşılaştırır. → { file, same, bytes }.
export function writeFixture(name, data, { check = false, dir = FIXTURE_DIR } = {}) {
  const file = join(dir, `${name}.json`);
  const text = `${pretty(encode(data))}\n`;
  const old = existsSync(file) ? readFileSync(file, 'utf8') : null;
  const same = old === text;
  if (!check && !same) writeFileSync(file, text);
  return { file, same, bytes: Buffer.byteLength(text) };
}

// Alan dosyasının komut satırı: node tools/proto_fixtures/<alan>.mjs [--proto yol] [--check]. outputs [{ name, build(proto) }]:
// her biri tests/fixtures/<name>.json yazar. --check yazmaz, eski ya da eksik dosyada 1 ile çıkar.
export async function runCli(tag, outputs, argv = process.argv.slice(2)) {
  const o = parseArgs(argv, tag);
  assertProto(o.proto, tag);
  let stale = 0;
  for (const { name, build } of outputs) {
    const t0 = performance.now();
    const data = await build(o.proto);
    const r = writeFixture(name, data, { check: o.check });
    const where = relative(GAME, r.file);
    const n = Array.isArray(data.cases) ? `, ${data.cases.length} durum` : '';
    if (o.check) {
      console.log(`[${tag}] ${where}: ${r.same ? 'güncel' : 'ESKİ (yeniden üret: node ' + relative(GAME, process.argv[1] ?? '') + ')'}${n}`);
      if (!r.same) stale++;
    } else {
      console.log(`[${tag}] ${where} ${r.same ? 'değişmedi' : 'yazıldı'} (${(r.bytes / 1024).toFixed(1)} KB${n}, ${Math.round(performance.now() - t0)} ms)`);
    }
  }
  return stale === 0 ? 0 : 1;
}

// Doğrudan çalıştırılan dosya mı (import edilince main koşmasın)?
export function isMain(importMetaUrl) {
  return Boolean(process.argv[1]) && resolve(process.argv[1]) === fileURLToPath(importMetaUrl);
}
