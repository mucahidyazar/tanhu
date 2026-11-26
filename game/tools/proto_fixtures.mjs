#!/usr/bin/env node
// Prototipin saf modüllerinden altın değer fikstürleri (godot.md §8.2, K29; Yol Haritası proto-fixtures): bütün alanları sırayla koşar.
//
//   node tools/proto_fixtures.mjs                    # hepsini üretir (tests/fixtures/*.json)
//   node tools/proto_fixtures.mjs --check            # yazmaz; eski ya da eksik fikstürde 1 ile çıkar
//   node tools/proto_fixtures.mjs --only=labour,progression [--proto yol] [--list]
//
// Alan düzeni: her alan kendi dosyasını yazar, bu çalıştırıcı hepsini toplar.
//   tools/proto_fixtures/<alan>.mjs   tek başına koşan Node betiği: `node tools/proto_fixtures/<alan>.mjs [--proto yol] [--check]`;
//                                     prototipi kendi yolundan içe aktarır (salt okunur), sabit girdilerle koşar ve
//                                     tests/fixtures/<ad>.json'a girdiyi ve beklenen çıktıyı yazar; --check yazmaz, farkta 1 döner.
//   tools/proto_fixtures/_*.mjs       ortak yardımcı (alan sayılmaz): _shared.mjs bekçi, kodlama, kararlı yazım ve runCli verir.
// Prototipin yolu: --proto, yoksa TANHU_PROTO, yoksa ~/Code/tests/tanhu-programatic-test; çalıştırıcı aynısını her alana geçirir.
// Tolerans: saf matematik 1e-9, birikimli benzetim 1e-6, tamsayı ve kimlik tam eşit. Değişen kural fikstüre girmez (inşaatta,
// sökümde ve onarımda T(n), dombra yerine kopuz, Serbest Gez'in ayrı sayacı; _shared.mjs CHANGED_RULES).
// GDScript tarafı: tests/support/proto_fixture.gd fikstürü okur ve karşılaştırır; tests/unit/test_proto_fixtures.gd her fikstürün
// başlığını ve üreticisini denetler.
import { spawnSync } from 'node:child_process';
import { existsSync, readdirSync } from 'node:fs';
import { basename, dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { DEFAULT_PROTO, assertProto } from './proto_fixtures/_shared.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const DOMAIN_DIR = join(HERE, 'proto_fixtures');
const TAG = 'proto_fixtures';

// Alan dosyaları, ada göre sıralı; «_» ile başlayanlar ve sınama dosyaları alan değildir.
export function domains(dir = DOMAIN_DIR) {
  if (!existsSync(dir)) return [];
  return readdirSync(dir)
    .filter((f) => f.endsWith('.mjs') && !f.startsWith('_') && !f.includes('.test.'))
    .sort()
    .map((f) => ({ name: basename(f, '.mjs'), file: join(dir, f) }));
}

// Düzen dışı fikstür betikleri (tools/proto_fixtures_<alan>.mjs): çalıştırıcı onları koşamaz (sözleşmeleri belli değil), yalnız
// uyarır; tools/proto_fixtures/<alan>.mjs'e taşınıp --proto ve --check'i alınca toplanır.
export function strays(dir = HERE) {
  if (!existsSync(dir)) return [];
  return readdirSync(dir).filter((f) => /^proto_fixtures_.+\.mjs$/.test(f)).sort();
}

export function parseRunnerArgs(argv) {
  const o = { proto: DEFAULT_PROTO, check: false, only: null, list: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--check') o.check = true;
    else if (a === '--list') o.list = true;
    else if (a === '--proto') o.proto = resolve(argv[++i] ?? '');
    else if (a.startsWith('--proto=')) o.proto = resolve(a.slice(8));
    else if (a.startsWith('--only=')) o.only = a.slice(7).split(',').map((s) => s.trim()).filter(Boolean);
    else throw new Error(`[${TAG}] bilinmeyen argüman: ${a}`);
  }
  return o;
}

function main() {
  const o = parseRunnerArgs(process.argv.slice(2));
  let list = domains();
  if (o.only) {
    const unknown = o.only.filter((n) => !list.some((d) => d.name === n));
    if (unknown.length) throw new Error(`[${TAG}] bilinmeyen alan: ${unknown.join(', ')} (var olanlar: ${list.map((d) => d.name).join(', ')})`);
    list = list.filter((d) => o.only.includes(d.name));
  }
  if (o.list) {
    for (const d of list) console.log(d.name);
    return 0;
  }
  assertProto(o.proto, TAG);
  const failed = [];
  const t0 = performance.now();
  for (const d of list) {
    const args = [d.file, '--proto', o.proto];
    if (o.check) args.push('--check');
    // Her alan ayrı süreçte koşar: biri düşerse ötekiler yine üretilir, alanların modül önbellekleri karışmaz.
    const r = spawnSync(process.execPath, args, { stdio: 'inherit', cwd: resolve(HERE, '..') });
    if (r.status !== 0) failed.push(`${d.name} (${r.status ?? r.signal})`);
  }
  for (const f of strays()) console.log(`[${TAG}] UYARI: düzen dışı fikstür betiği tools/${f} koşulmadı (tools/proto_fixtures/<alan>.mjs düzenine taşınmalı: --proto, --check)`);
  const verb = o.check ? 'denetlendi' : 'üretildi';
  const ms = Math.round(performance.now() - t0);
  if (failed.length) {
    console.log(`[${TAG}] ${list.length} alan ${verb}, ${failed.length} başarısız: ${failed.join(', ')} (${ms} ms)`);
    return 1;
  }
  console.log(`[${TAG}] ${list.length} alan ${verb} (${ms} ms)`);
  return 0;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    process.exit(main());
  } catch (err) {
    console.error(err.message ?? err);
    process.exit(1);
  }
}
