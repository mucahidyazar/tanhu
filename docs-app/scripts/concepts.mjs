#!/usr/bin/env node
// Varlık kataloğundaki (docs/assets/catalog.json) görseli eksik satırlar için gpt-image-2 konsepti üretir ve sitenin küçük
// görsellerini yazar. Konseptler Godot projesinin Meshy hattının okuduğu yere gider: game/assets/_concepts/<id>.png
// (.gdignore'lı, Godot içe aktarmaz). Onaylanınca yanına <id>.ok konur; meshy_dispatch.py yalnız onaylıları gönderir.
//
//   node scripts/concepts.mjs [--jobs=3] [--only=id1,id2] [--group=evcil] [--all]   eksik konseptleri üretir, sonra küçük görseller
//   node scripts/concepts.mjs --thumbs                                                yalnız küçük görselleri yeniden yazar
//   node scripts/concepts.mjs --encyclopedia [--jobs=3] [--only=...]                 ansiklopedi kişilerinin görselleri:
//        art (tam boy), profil ve T-poz (3B modeli yoksa); profil ve poz her zaman art'tan türer (tutarlılık). Çıktı
//        docs/assets/encyclopedia/<id>/{art,portrait,pose}.{png,webp}; var olan görsele dokunmaz, kaldığı yerden sürer.
//
// Öncelik: katalog satırının priority alanı 1 olanlar şimdi üretilir; --all 2'leri de katar (--only her zaman üretir).
//
// Üretim Codex CLI'nin görsel aracını kullanır (game/tools/imagegen/gen.sh, ChatGPT hesabı); kredi harcamaz, kota sınırlıdır.
// Var olan konsepte dokunmaz: yarıda kalırsa kaldığı yerden sürer.
import { spawn } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
// sharp Next.js ile gelir (node_modules/sharp); ayrı kurulum gerekmez.
import sharp from 'sharp';

const APP = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const ROOT = resolve(APP, '..');
const GAME = join(ROOT, 'game');
const CATALOG = join(ROOT, 'docs', 'assets', 'catalog.json');
const THUMBS = join(ROOT, 'docs', 'assets', 'thumbs');
const CONCEPTS = join(GAME, 'assets', '_concepts');
const GEN = join(GAME, 'tools', 'imagegen', 'gen.sh');
const PLAN = JSON.parse(readFileSync(join(GAME, 'tools', 'asset_plan.json'), 'utf8'));
const REF = { camp: join(GAME, 'assets', '_reference', 'style_camp.png'), mete: join(GAME, 'assets', '_reference', 'style_mete.png') };

// Simge ve resim üslubu: 3B'si olmayan varlıklar için (beceri, durum, eşya simgesi).
// Ansiklopedi levhası: kitabın dikey resmi; kişi ya da tanrı tek figür, sahne olabilir.
const PLATE_STYLE = 'Hand-painted book illustration plate in the same Ghibli-like painterly gouache style, colours and level of detail as the reference images, Central Asian steppe of the 3rd century BC, one main figure or a single scene, soft dramatic light, deep night blues with warm gold firelight accents, vertical 3:4 composition, the whole figure or scene readable at small size, no text, no letters, no frame, no border.';
const ICON_STYLE = 'Square game icon, single object or symbol centered, hand-painted gouache in the same Ghibli-like painterly style and earthy palette as the reference image, soft even light, plain warm parchment background, thick soft edges readable at small size, no text, no letters, no frame, no border.';

const args = process.argv.slice(2);
const opt = (name) => args.find((a) => a.startsWith(`--${name}=`))?.slice(name.length + 3);
const jobs = Number(opt('jobs') ?? 3);
const only = opt('only')?.split(',');
const groupOnly = opt('group');
const all = args.includes('--all');

const catalog = existsSync(CATALOG) ? JSON.parse(readFileSync(CATALOG, 'utf8')) : { assets: [] };
mkdirSync(CONCEPTS, { recursive: true });
mkdirSync(THUMBS, { recursive: true });

function promptOf(row) {
  const kind = row.imageKind ?? 'object';
  if (kind === 'icon') return `${row.prompt} ${ICON_STYLE}`;
  const base = `${row.prompt} ${PLAN.style_suffix}`;
  return kind === 'character' ? `${base} ${PLAN.character_suffix}` : base;
}

function refsOf(row) {
  const kind = row.imageKind ?? 'object';
  return kind === 'character' ? [REF.mete, REF.camp] : [REF.camp];
}

function run(row) {
  return new Promise((done) => {
    const out = join(CONCEPTS, `${row.id}.png`);
    const argv = [GEN, '--model', 'gpt-6-sol', '--timeout-sec', '400', '--prompt', promptOf(row), '--out', out];
    for (const r of refsOf(row)) argv.push('--ref', r);
    const child = spawn('bash', argv, { stdio: ['ignore', 'pipe', 'pipe'] });
    let err = '';
    child.stderr.on('data', (d) => { err += d; });
    child.on('close', async (code) => {
      const limited = /usage limit|rate limit|quota/i.test(err);
      const ok = code === 0 && existsSync(out);
      // Küçük görsel hemen yazılır: site görseli üretim sürerken gösterir.
      if (ok) await thumb(row.id, out).catch((e) => console.log(`küçük görsel yazılamadı ${row.id}: ${e.message}`));
      console.log(ok ? `ok ${row.id}` : `HATA ${row.id} (${code})${limited ? ': kota' : ''}`);
      done({ id: row.id, ok, limited });
    });
  });
}

async function generate() {
  const todo = catalog.assets.filter((row) => {
    if (only && !only.includes(row.id)) return false;
    if (groupOnly && row.group !== groupOnly) return false;
    if (!row.prompt) return false;
    if (!only && !all && (row.priority ?? 2) > 1) return false;
    const target = row.image ?? `game/assets/_concepts/${row.id}.png`;
    return !existsSync(join(ROOT, target));
  });
  console.log(`${todo.length} konsept üretilecek, aynı anda ${jobs}.`);
  let stop = false;
  const queue = [...todo];
  const worker = async () => {
    while (queue.length && !stop) {
      const row = queue.shift();
      const r = await run(row);
      if (r.limited) stop = true;
    }
  };
  await Promise.all(Array.from({ length: jobs }, worker));
  if (stop) console.log('Görsel kotası doldu: kalanlar sonra üretilir (betik kaldığı yerden sürer).');
  // Görseli üretilmiş satırların yolu kataloğa yazılır. Katalog üretim sürerken başkasınca değişmiş olabilir: dosya
  // yeniden okunur, yalnız image alanı eklenir, yerine geçici dosyadan taşınarak yazılır.
  const fresh = JSON.parse(readFileSync(CATALOG, 'utf8'));
  let changed = 0;
  for (const row of fresh.assets) {
    const rel = `game/assets/_concepts/${row.id}.png`;
    if (!row.image && existsSync(join(ROOT, rel))) { row.image = rel; changed++; }
  }
  if (changed) {
    const tmp = `${CATALOG}.${process.pid}.tmp`;
    writeFileSync(tmp, `${JSON.stringify(fresh, null, 1)}\n`);
    renameSync(tmp, CATALOG);
    console.log(`${changed} satırın görsel yolu kataloğa yazıldı.`);
  }
}

// 320 piksellik küçük görsel: docs/assets/thumbs/<id>.webp (site tablolarda ve sayfalarda bunu gösterir).
async function thumb(id, src) {
  await sharp(src).resize(320, 320, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } }).webp({ quality: 82 }).toFile(join(THUMBS, `${id}.webp`));
}

async function thumbs() {
  let n = 0;
  for (const row of JSON.parse(readFileSync(CATALOG, 'utf8')).assets) {
    const rel = row.image ?? `game/assets/_concepts/${row.id}.png`;
    const src = join(ROOT, rel);
    if (!existsSync(src)) continue;
    await thumb(row.id, src);
    n++;
  }
  console.log(`${n} küçük görsel yazıldı (${THUMBS}).`);
}

// Ansiklopedi kişilerinin görselleri (E5): her kişi için art (tam boy), profil (baş ve omuz) ve T-poz (3B modeli yoksa).
// Tutarlılık için önce art çizilir; profil ve T-poz art'ı referans alır. Kişinin var olan portresi varsa (docs/media/ui/
// portraits) art o portreye bakılarak çizilir (yüz korunur); profil yine art'tan türer. Çıktı docs/assets/encyclopedia/<id>/.
const ART_STYLE = 'Full-body character illustration: one figure standing, three-quarter front view, the whole figure visible from head to feet with a small margin, hand-painted semi-realistic painterly style with the same colours, brushwork and level of detail as the style reference, Central Asian steppe of the 3rd century BC, warm soft light, plain light warm off-white background with only a very soft floor shadow, no text, no letters, no frame, no border.';
const PORTRAIT_STYLE = 'Head-and-shoulders portrait of exactly the same character as the character reference image: same face, age, hair, beard, headwear, jewellery and clothing colours; slight three-quarter view looking toward the viewer, the same painterly style as the reference, plain warm parchment background, soft light, square composition, no text, no frame.';
const POSE_STYLE = 'Character reference sheet for 3D modelling: exactly the same character as the character reference image, standing in a strict T-pose, seen straight from the front, arms stretched out horizontally at shoulder height with palms facing down and fingers together, legs straight and slightly apart, neutral face, same clothing, armour, colours and proportions, nothing held in the hands, plain flat light grey background, even studio lighting, no shadow, the whole body visible with a small margin, no text.';

function gen1(prompt, out, refs) {
  return new Promise((done) => {
    const argv = [GEN, '--model', 'gpt-6-sol', '--timeout-sec', '420', '--prompt', prompt, '--out', out];
    for (const r of refs) argv.push('--ref', r);
    const child = spawn('bash', argv, { stdio: ['ignore', 'pipe', 'pipe'] });
    let err = '';
    child.stderr.on('data', (d) => { err += d; });
    child.on('close', (code) => done({ ok: code === 0 && existsSync(out), limited: /usage limit|rate limit|quota/i.test(err), code }));
  });
}

async function encyclopediaImages() {
  const ENC = join(APP, 'content', 'encyclopedia.json');
  const BASE = join(ROOT, 'docs', 'assets', 'encyclopedia');
  const book = JSON.parse(readFileSync(ENC, 'utf8'));
  const people = book.entries.filter((e) => (e.kind ?? 'person') !== 'place' && (e.artPrompt || e.imagePrompt) && (!only || only.includes(e.id)));
  console.log(`${people.length} kişinin görselleri denetleniyor, aynı anda ${jobs}.`);
  let stop = false;
  const queue = [...people];
  const one = async (e) => {
    const dir = join(BASE, e.id);
    mkdirSync(dir, { recursive: true });
    const portraitSrc = e.portrait ? join(ROOT, 'docs', 'media', 'ui', 'portraits', `${e.portrait}.webp`) : null;
    const hasPortrait = portraitSrc && existsSync(portraitSrc);
    let portraitPng = null;
    if (hasPortrait) {
      portraitPng = join(dir, '_portrait-ref.png');
      if (!existsSync(portraitPng)) await sharp(portraitSrc).png().toFile(portraitPng);
    }
    const style = e.chapter === 'gods' ? [REF.camp] : [REF.mete, REF.camp];
    const art = join(dir, 'art.png');
    if (!existsSync(art)) {
      const keep = hasPortrait ? ' Keep exactly the same face, hair, beard and headwear as the portrait reference.' : '';
      const r = await gen1(`${e.artPrompt ?? e.imagePrompt}${keep} ${ART_STYLE}`, art, hasPortrait ? [portraitPng, ...style] : style);
      console.log(r.ok ? `ok ${e.id} art` : `HATA ${e.id} art (${r.code})${r.limited ? ': kota' : ''}`);
      if (r.limited) return true;
      if (!r.ok) return false;
    }
    await sharp(art).resize({ height: 1100, withoutEnlargement: true }).webp({ quality: 84 }).toFile(join(dir, 'art.webp'));
    const tasks = [];
    // Profil her zaman art'tan türer (eski portre yalnız art'ın yüz referansıdır): taç, giysi ve zemin art'la aynı olsun.
    if (!existsSync(join(dir, 'portrait.png'))) tasks.push(['portrait', PORTRAIT_STYLE]);
    if (!e.model && !existsSync(join(dir, 'pose.png'))) tasks.push(['pose', POSE_STYLE]);
    const results = await Promise.all(tasks.map(([kind, styleText]) => gen1(`${e.name}. ${styleText}`, join(dir, `${kind}.png`), [art]).then((r) => ({ kind, ...r }))));
    for (const r of results) console.log(r.ok ? `ok ${e.id} ${r.kind}` : `HATA ${e.id} ${r.kind} (${r.code})${r.limited ? ': kota' : ''}`);
    if (existsSync(join(dir, 'portrait.png'))) await sharp(join(dir, 'portrait.png')).resize(512, 512, { fit: 'cover', position: 'top' }).webp({ quality: 86 }).toFile(join(dir, 'portrait.webp'));
    if (existsSync(join(dir, 'pose.png'))) await sharp(join(dir, 'pose.png')).resize({ height: 1100, withoutEnlargement: true }).webp({ quality: 84 }).toFile(join(dir, 'pose.webp'));
    return results.some((r) => r.limited);
  };
  const worker = async () => {
    while (queue.length && !stop) {
      if (await one(queue.shift())) stop = true;
    }
  };
  await Promise.all(Array.from({ length: jobs }, worker));
  if (stop) console.log('Görsel kotası doldu: kalanlar sonra üretilir (betik kaldığı yerden sürer).');
}

if (args.includes('--encyclopedia')) {
  await encyclopediaImages();
} else {
  if (!args.includes('--thumbs')) await generate();
  await thumbs();
}
