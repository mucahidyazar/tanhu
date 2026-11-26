#!/usr/bin/env node
// İlerleme dosyasının (content/progress.json) denetimi: Perde > Faz > Madde düzeni, tekil kimlikler, geçerli durumlar,
// tasarım bağları. --baseline verilirse eski dosyada bitmiş ya da süren her madde yeni dosyada aynı durumla ve geçmişi
// korunarak durmalı (geçmiş yalnız uzayabilir); silinen «yapılacak» maddeler listelenir.
//
//   node scripts/progress-check.mjs [dosya] [--baseline=eski.json]
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const APP = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
const file = args.find((a) => !a.startsWith('--')) ?? path.join(APP, 'content', 'progress.json');
const baselineFile = args.find((a) => a.startsWith('--baseline='))?.slice('--baseline='.length);
const STATES = new Set(['yapilacak', 'suruyor', 'bitti']);

const errors = [];
const warnings = [];
const data = JSON.parse(fs.readFileSync(file, 'utf8'));

for (const key of ['acts', 'phases', 'items']) if (!Array.isArray(data[key])) errors.push(`${key} dizi değil`);
if (errors.length) {
  console.log(errors.join('\n'));
  process.exit(1);
}

const unique = (list, what) => {
  const seen = new Set();
  for (const x of list) {
    if (!x.id || typeof x.id !== 'string') errors.push(`${what}: kimliksiz kayıt ${JSON.stringify(x).slice(0, 80)}`);
    else if (seen.has(x.id)) errors.push(`${what}: çift kimlik ${x.id}`);
    seen.add(x.id);
  }
  return seen;
};
const actIds = unique(data.acts, 'perde');
const phaseIds = unique(data.phases, 'faz');
unique(data.items, 'madde');

const pageExists = (href) => {
  const id = href.replace(/^\/docs\//, '').split('#')[0];
  return fs.existsSync(path.join(APP, 'content', 'pages', `${id}.md`)) || id.startsWith('source/');
};
for (const a of data.acts) {
  if (!a.title) errors.push(`perde ${a.id}: başlık yok`);
  if (!a.summary) warnings.push(`perde ${a.id}: özet yok`);
}
for (const p of data.phases) {
  if (!actIds.has(p.act)) errors.push(`faz ${p.id}: perdesi yok (${p.act})`);
  if (!p.title) errors.push(`faz ${p.id}: başlık yok`);
}
for (const a of data.acts) if (!data.phases.some((p) => p.act === a.id)) warnings.push(`perde ${a.id}: fazı yok`);
for (const a of data.acts) {
  if (a.page && !a.page.startsWith('/docs/')) errors.push(`perde ${a.id}: sayfa bağı /docs/ ile başlamalı: ${a.page}`);
  else if (a.page && !pageExists(a.page)) warnings.push(`perde ${a.id}: sayfası henüz yok ${a.page}`);
  if (a.systems !== undefined && !Array.isArray(a.systems)) errors.push(`perde ${a.id}: systems dizi değil`);
}
for (const p of data.phases) {
  if (p.requires !== undefined && !Array.isArray(p.requires)) errors.push(`faz ${p.id}: requires dizi değil`);
  for (const r of p.requires ?? []) if (!phaseIds.has(r)) errors.push(`faz ${p.id}: önkoşul fazı yok (${r})`);
}
for (const p of data.phases) if (!data.items.some((i) => i.phase === p.id)) warnings.push(`faz ${p.id}: maddesi yok`);


for (const it of data.items) {
  if (!phaseIds.has(it.phase)) errors.push(`madde ${it.id}: fazı yok (${it.phase})`);
  if (!it.title) errors.push(`madde ${it.id}: başlık yok`);
  if (!STATES.has(it.status)) errors.push(`madde ${it.id}: geçersiz durum ${it.status}`);
  if ('milestone' in it) warnings.push(`madde ${it.id}: eski «milestone» alanı duruyor`);
  for (const h of it.history ?? []) if (!h.at || !STATES.has(h.status)) errors.push(`madde ${it.id}: bozuk geçmiş kaydı ${JSON.stringify(h)}`);
  for (const d of it.design ?? []) {
    if (!d.startsWith('/docs/')) errors.push(`madde ${it.id}: tasarım bağı /docs/ ile başlamalı: ${d}`);
    else if (!pageExists(d)) warnings.push(`madde ${it.id}: sayfa henüz yok ${d}`);
  }
  for (const p of it.paths ?? []) {
    if (p.startsWith('/') || p.startsWith('game/')) errors.push(`madde ${it.id}: yol game/ klasörüne göre yazılmalı: ${p}`);
  }
}

if (baselineFile) {
  const base = JSON.parse(fs.readFileSync(baselineFile, 'utf8'));
  const now = new Map(data.items.map((i) => [i.id, i]));
  const removed = [];
  for (const old of base.items ?? []) {
    const cur = now.get(old.id);
    if (!cur) {
      if (old.status === 'yapilacak') removed.push(old.id);
      else errors.push(`madde ${old.id}: eski dosyada «${old.status}», yenisinde yok`);
      continue;
    }
    if (old.status !== 'yapilacak' && cur.status !== old.status) errors.push(`madde ${old.id}: durum «${old.status}» iken «${cur.status}» oldu`);
    const a = JSON.stringify(old.history ?? []);
    const b = JSON.stringify((cur.history ?? []).slice(0, (old.history ?? []).length));
    if (a !== b) errors.push(`madde ${old.id}: geçmişi değişti (yalnız sonuna eklenebilir)`);
  }
  if (removed.length) console.log(`Silinen yapılacak maddeler (${removed.length}): ${removed.join(', ')}`);
}

for (const a of data.acts) {
  const phases = data.phases.filter((p) => p.act === a.id);
  const items = data.items.filter((i) => phases.some((p) => p.id === i.phase));
  console.log(`${a.title}: ${phases.length} faz, ${items.length} madde, ${items.filter((i) => i.status === 'bitti').length} bitti`);
}
console.log(`Toplam: ${data.acts.length} perde, ${data.phases.length} faz, ${data.items.length} madde`);
if (warnings.length) console.log(`\nUyarı (${warnings.length}):\n  ${warnings.join('\n  ')}`);
if (errors.length) {
  console.log(`\nHATA (${errors.length}):\n  ${errors.join('\n  ')}`);
  process.exit(1);
}
console.log('\nDüzen geçerli.');
