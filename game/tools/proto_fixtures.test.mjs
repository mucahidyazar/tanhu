// Prototip fikstürü çalıştırıcısının ve ortak yardımcısının sınamaları (Yol Haritası proto-fixtures):
//   node --test tools/proto_fixtures.test.mjs
// Kodlama (Infinity, NaN, undefined, Map, Set), kararlı yazım, değişen kural bekçisi, alan düzeni ve bu maddenin fikstürlerinin
// güncelliği (--check; prototip yoksa o sınama atlanır).
import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { CHANGED_RULES, DEFAULT_PROTO, TOL, encode, parseArgs, pretty, protoImport, writeFixture } from './proto_fixtures/_shared.mjs';
import { domains, parseRunnerArgs, strays } from './proto_fixtures.mjs';

const RUNNER = fileURLToPath(new URL('./proto_fixtures.mjs', import.meta.url));
const HAS_PROTO = existsSync(join(DEFAULT_PROTO, 'src/game/labour.js'));

test('encode: sayı olmayan sayılar yazıyla, undefined atlanır, Map ve Set düz değere iner, işlev yazılamaz', () => {
  assert.deepEqual(encode({ a: Infinity, b: -Infinity, c: NaN, d: -0, e: undefined, f: [1, undefined] }), { a: 'inf', b: '-inf', c: 'nan', d: 0, f: [1, null] });
  assert.deepEqual(encode(new Map([['x', 1]])), { x: 1 });
  assert.deepEqual(encode(new Set(['a', 'b'])), ['a', 'b']);
  assert.deepEqual(encode(new Float64Array([0.5, 2])), [0.5, 2]);
  assert.throws(() => encode({ f: () => 1 }), /işlev yazılamaz: \$\.f/);
  assert.throws(() => encode({ n: 1n }), /bigint/);
});

test('pretty: kararlı ve okunur; düz değer dizileri tek satırda', () => {
  const v = { a: [1, 2, 3], b: { c: 'x', d: [[1, 2], [3]] }, e: [] };
  const text = pretty(v);
  assert.equal(text, pretty(JSON.parse(JSON.stringify(v))));
  assert.ok(text.includes('"a": [1, 2, 3]'));
  assert.deepEqual(JSON.parse(text), v);
});

test('writeFixture: aynı veri aynı baytlar; check yazmaz, farkı söyler', () => {
  const dir = mkdtempSync(join(tmpdir(), 'proto_fixtures_'));
  try {
    const data = { meta: { v: 1 }, cases: [{ id: 'a', fn: 'f', in: [1], out: Infinity }] };
    assert.equal(writeFixture('x', data, { check: true, dir }).same, false, 'Dosya yoksa eski sayılır');
    assert.equal(existsSync(join(dir, 'x.json')), false, 'check yazmaz');
    writeFixture('x', data, { dir });
    assert.equal(writeFixture('x', data, { check: true, dir }).same, true);
    assert.match(readFileSync(join(dir, 'x.json'), 'utf8'), /"out": "inf"/);
    assert.equal(writeFixture('x', { ...data, meta: { v: 2 } }, { check: true, dir }).same, false);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('toleranslar: saf matematik 1e-9, birikimli benzetim 1e-6, tam eşit 0', () => {
  assert.deepEqual({ ...TOL }, { math: 1e-9, sim: 1e-6, exact: 0 });
});

test('değişen kural bekçisi: T(n), kopuz ve Serbest Gez sayacı listede', () => {
  assert.deepEqual([...CHANGED_RULES['src/game/labour.js'].exports], ['stepRate', 'simulate', 'etaMinutes', 'remaining', 'deriveSteps', 'repairWork']);
  assert.equal(CHANGED_RULES['src/audio/instruments/dombra.js'].exports, '*');
  assert.deepEqual([...CHANGED_RULES['src/game/world-clock.js'].exports], ['roamMoonAge']);
});

test('bekçi: değişmeyen hesap okunur, değişen kural hata atar', { skip: !HAS_PROTO && 'prototip yok' }, async () => {
  const L = await protoImport(DEFAULT_PROTO, 'src/game/labour.js');
  assert.equal(typeof L.eff, 'function');
  assert.ok(Math.abs(L.eff(3) - 2.71) < 0.005);
  assert.throws(() => L.stepRate, /değişen kural fikstüre girmez: src\/game\/labour.js stepRate \(K50/);
  assert.throws(() => {
    const { simulate } = L;
    return simulate;
  }, /K50/, 'Yapı bozma da bekçiye takılır');
  const C = await protoImport(DEFAULT_PROTO, 'src/game/world-clock.js');
  assert.equal(typeof C.parseClock, 'function', 'Saatin değişmeyen hesabı okunur');
  assert.throws(() => C.roamMoonAge, /K67/);
});

test('argümanlar: --proto, --check; bilinmeyen argüman hatadır', () => {
  assert.deepEqual(parseArgs(['--proto=/x', '--check']), { proto: '/x', check: true });
  assert.throws(() => parseArgs(['--nope']), /bilinmeyen argüman/);
  const r = parseRunnerArgs(['--only=labour, progression', '--list']);
  assert.deepEqual(r.only, ['labour', 'progression']);
  assert.equal(r.list, true);
});

test('alan düzeni: tools/proto_fixtures/<alan>.mjs, «_» ile başlayan yardımcı alan sayılmaz', () => {
  const names = domains().map((d) => d.name);
  assert.ok(names.includes('labour') && names.includes('progression'), names.join(', '));
  assert.ok(!names.some((n) => n.startsWith('_')));
  assert.deepEqual([...names].sort(), names, 'Ada göre sıralı');
  for (const s of strays()) assert.match(s, /^proto_fixtures_.+\.mjs$/);
  const list = spawnSync(process.execPath, [RUNNER, '--list'], { encoding: 'utf8' });
  assert.equal(list.status, 0, list.stderr);
  assert.deepEqual(list.stdout.trim().split('\n'), names);
  const bad = spawnSync(process.execPath, [RUNNER, '--only=nope'], { encoding: 'utf8' });
  assert.equal(bad.status, 1);
  assert.match(bad.stderr, /bilinmeyen alan: nope/);
});

test('bu maddenin fikstürleri güncel (--check)', { skip: !HAS_PROTO && 'prototip yok' }, () => {
  const r = spawnSync(process.execPath, [RUNNER, '--check', '--only=labour,progression'], { encoding: 'utf8' });
  assert.equal(r.status, 0, r.stdout + r.stderr);
  assert.match(r.stdout, /labour\.json: güncel/);
  assert.match(r.stdout, /progress\.json: güncel/);
  assert.match(r.stdout, /derive\.json: güncel/);
});
