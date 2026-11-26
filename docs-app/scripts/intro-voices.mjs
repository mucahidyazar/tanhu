#!/usr/bin/env node
// Ansiklopedi kişilerinin tanıtım sesleri (E5): her kişi kendini iki cümleyle tanıtır. Söylenen İngilizcedir, Türkçesi
// altyazıdır (K5, K61). Ses seçimi ElevenLabs kütüphanesinde aramayla yapılır (ücretsiz); seslendirme ücretlidir
// (karakter başına, eleven_v3). Anahtar prototipin .env dosyasından okunur (tools/elevenlabs-api.mjs), yazdırılmaz.
//
//   node scripts/intro-voices.mjs cast [--force]        sesi olmayan kayıtlara voiceBrief'e göre kütüphaneden ses seçer
//   node scripts/intro-voices.mjs cost                  üretilecek satırların karakter toplamı (ücretsiz)
//   node scripts/intro-voices.mjs gen [--only=a,b] [--force]   tanıtım seslerini üretir: docs/media/audio/vo/en/ency.<id>.mp3
//
// Aynı ses ve aynı metin bir kez üretilir (docs/media/audio/vo/en/ency.manifest.json karması); --force yeniden üretir.
// K86: her gen turu önce cost'un toplamıyla kullanıcıya sorulur; konuşmayanlar ve sesi seçim bekleyenler atlanır.
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const APP = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const ROOT = resolve(APP, '..');
const ENC = join(APP, 'content', 'encyclopedia.json');
const OUT = join(ROOT, 'docs', 'media', 'audio', 'vo', 'en');
const MANIFEST = join(OUT, 'ency.manifest.json');
const PROTO = '/Users/mucahidyazar/Code/tests/tanhu-programatic-test';
const { call, tts } = await import(join(PROTO, 'tools', 'elevenlabs-api.mjs'));

const MODEL = 'eleven_v3';
// eleven_v3 kararlılığı yalnız 0, 0,5 ve 1 alır; 0,5 «doğal» (K17).
const SETTINGS = { stability: 0.5 };
// Yerleşik sesler: ozan David, anlatıcı Eldrin (K17). Kişiye özel ses yoksa bunlar kullanılmaz: her kişinin kendi sesi olur.
const RESERVED = new Set(['BNgbHR0DNeZixGQVzloa', 'LvmvHEBEmMJBJw9UuhwO']);

const args = process.argv.slice(2);
const cmd = args[0];
const opt = (name) => args.find((a) => a.startsWith(`--${name}=`))?.slice(name.length + 3);
const only = opt('only')?.split(',');
const force = args.includes('--force');

const readBook = () => JSON.parse(readFileSync(ENC, 'utf8'));
const writeBook = (book) => {
  const tmp = `${ENC}.tmp`;
  writeFileSync(tmp, `${JSON.stringify(book, null, 2)}\n`);
  renameSync(tmp, ENC);
};
const readManifest = () => (existsSync(MANIFEST) ? JSON.parse(readFileSync(MANIFEST, 'utf8')) : {});
const hashOf = (voice, text) => createHash('sha1').update(`${MODEL}|${voice}|${JSON.stringify(SETTINGS)}|${text}`).digest('hex').slice(0, 16);

// voiceBrief: { gender: male|female, age: young|middle_aged|old, accent?, tone?: string[] } → kütüphane araması.
// Her tını sözcüğü ayrı aranır (birlikte aranınca sonuç çoğu zaman boş kalıyor), sonuçlar birleşip puanlanır: ad ve
// tanımda geçen tını sözcüğü, karakter ya da anlatı kullanımı, yaygınlık; belirgin yabancı şive geri düşer.
const NEUTRAL_ACCENTS = new Set(['standard', 'american', 'british', 'transatlantic', undefined, null, '']);
// MÖ 3. yüzyıl bozkır ve saray destanına uymayan ses tanımları seçilmez (çizgi film, reklam, çağdaş ya da cilveli tını).
const BANNED = /\b(gnome|goblin|elf|elves|santa|claus|jolly|bear|cowboy|outlaw|western|pirate|robot|cartoon|anime|chipmunk|seductive|sultry|sexy|flirty|asmr|podcast|news|newscaster|commercial|advert|radio|dj|youtube|tiktok|meme|funny|comedic|comedy|silly|snarky|grumpy|goofy|magical|gamer|surfer|valley|country|southern|texan|texas|cajun|modern|corporate|customer|support|assistant|teen|teenager|kid|kids|baby|bedtime|cozy|cosy|lovable|cute|bubbly|influencer|vlog|sports|announcer|trailer|hype)\b/i;
// Destanın sesine yakın sözcükler küçük artı alır.
const EPIC = /\b(epic|storyteller|story|king|queen|warrior|noble|regal|ancient|wise|deep|commanding|authoritative|mythology|mythic|legend|legendary|elder|narrator|dramatic|grave|calm|warm)\b/i;
// Aynı arama bir koşuda bir kez yapılır (pek çok kişinin tını sözcüğü ortaktır).
const searchCache = new Map();
const cachedCall = (url) => {
  if (!searchCache.has(url)) searchCache.set(url, call(url));
  return searchCache.get(url);
};
// İnsan kişiye iblis ve şeytan tınısı verilmez (tanrılar ve yeraltı varlıkları hariç).
const DEMONIC = /\b(demon|demonic|unholy|devil|satan|satanic|hellish)\b/i;
async function searchVoices(brief, kind = 'person', pageSize = 30) {
  const base = { page_size: String(pageSize), language: 'en' };
  if (brief.gender) base.gender = brief.gender;
  if (brief.age) base.age = brief.age;
  if (brief.accent) base.accent = brief.accent;
  const terms = [...(brief.tone ?? [])];
  const queries = terms.length ? [...terms.map((t) => ({ search: t })), { search: terms.slice(0, 2).join(' ') }] : [{}];
  const seen = new Map();
  for (const q of queries) {
    for (const useCase of ['characters_animation', 'narrative_story']) {
      const data = await cachedCall(`/v1/shared-voices?${new URLSearchParams({ ...base, ...q, use_case: useCase })}`);
      for (const v of data.voices ?? []) if (!seen.has(v.voice_id)) seen.set(v.voice_id, v);
    }
  }
  if (!seen.size) {
    const data = await cachedCall(`/v1/shared-voices?${new URLSearchParams(base)}`);
    for (const v of data.voices ?? []) seen.set(v.voice_id, v);
  }
  const score = (v) => {
    const text = `${v.name ?? ''} ${v.descriptive ?? ''} ${v.description ?? ''}`.toLowerCase();
    let s = 0;
    for (const t of terms) if (text.includes(t.toLowerCase())) s += 3;
    if (v.use_case === 'characters_animation') s += 1.5;
    if (v.use_case === 'narrative_story') s += 1;
    if (EPIC.test(text)) s += 1;
    if (!NEUTRAL_ACCENTS.has(v.accent)) s -= 6;
    s += Math.log10(1 + (v.cloned_by_count ?? 0)) * 0.6;
    return s;
  };
  const textOf = (v) => `${v.name ?? ''} ${v.descriptive ?? ''} ${v.description ?? ''}`;
  let pool = [...seen.values()].filter((v) => !BANNED.test(textOf(v)) && (kind === 'god' || !DEMONIC.test(textOf(v))));
  // Tarafsız şiveli aday varsa belirgin şiveliler elenir (İngilizce söz, şivesiz okunur).
  if (pool.some((v) => NEUTRAL_ACCENTS.has(v.accent))) pool = pool.filter((v) => NEUTRAL_ACCENTS.has(v.accent));
  return pool.sort((a, b) => score(b) - score(a));
}

async function cast() {
  const book = readBook();
  const used = new Set(book.entries.map((e) => e.voice?.id).filter(Boolean));
  let changed = 0;
  for (const e of book.entries) {
    if (!speaksNow(e)) continue;
    if (e.voice?.id && !force) continue;
    const brief = e.voiceBrief ?? { gender: 'male', age: 'middle_aged' };
    const free = (v) => !used.has(v.voice_id) && !RESERVED.has(v.voice_id);
    // Ayrılmış (anlatıcı, ozan) ya da başkasına verilmiş ses hiçbir koşulda seçilmez: aday kalmazsa arama genişler.
    let pick = (await searchVoices(brief, e.kind)).find(free);
    if (!pick) pick = (await searchVoices({ gender: brief.gender, age: brief.age, accent: brief.accent }, e.kind, 100)).find(free);
    if (!pick) {
      console.log(`SES YOK ${e.id}: ${JSON.stringify(brief)}`);
      continue;
    }
    used.add(pick.voice_id);
    e.voice = { id: pick.voice_id, name: pick.name, note: ['kütüphane', pick.gender, pick.age, pick.accent, pick.descriptive].filter(Boolean).join(', ') };
    changed++;
    console.log(`${e.id}: ${pick.name} (${e.voice.note})`);
  }
  if (changed) writeBook(book);
  console.log(`${changed} kişiye ses seçildi.`);
}

// K86: konuşmayan kişi (speaks: false) sesle tanıtılmaz; sesi kullanıcının seçimini bekleyen kişinin (voicePending, K87)
// tanıtımı seçimden sonra okunur. Sesi audio.md §5'te seçilmiş kişide o ses kullanılır (kayıttaki voice).
const speaksNow = (e) => Boolean(e.intro?.en) && e.speaks !== false && !e.voicePending;

function todo(book) {
  const manifest = readManifest();
  return book.entries.filter((e) => {
    if (!speaksNow(e) || !e.voice?.id) return false;
    if (only && !only.includes(e.id)) return false;
    const file = join(OUT, `ency.${e.id}.mp3`);
    return force || !existsSync(file) || manifest[e.id]?.hash !== hashOf(e.voice.id, e.intro.en);
  });
}

function ff(argv, input = null) {
  const r = spawnSync('ffmpeg', ['-hide_banner', '-nostats', ...argv], { input, maxBuffer: 1 << 28 });
  if (r.status !== 0) throw new Error(`ffmpeg başarısız: ${r.stderr?.toString().slice(-300)}`);
  return r;
}

// Mono, −18 LUFS (anlatıcı satırlarıyla aynı), baştaki ve sondaki sessizlik kırpılır.
function master(raw, out) {
  const src = `${out}.raw.mp3`;
  writeFileSync(src, raw);
  const trim = 'silenceremove=start_periods=1:start_threshold=-50dB,areverse,silenceremove=start_periods=1:start_threshold=-50dB,areverse';
  const pass1 = ff(['-i', src, '-ac', '1', '-af', `${trim},loudnorm=I=-18:TP=-1.5:LRA=11:print_format=json`, '-f', 'null', '-']).stderr.toString();
  const m = JSON.parse(pass1.slice(pass1.lastIndexOf('{'), pass1.lastIndexOf('}') + 1));
  const ln = `loudnorm=I=-18:TP=-1.5:LRA=11:measured_I=${m.input_i}:measured_TP=${m.input_tp}:measured_LRA=${m.input_lra}:measured_thresh=${m.input_thresh}:offset=${m.target_offset}:linear=true`;
  ff(['-v', 'error', '-y', '-i', src, '-ac', '1', '-af', `${trim},${ln}`, '-ar', '44100', '-c:a', 'libmp3lame', '-b:a', '128k', out]);
  spawnSync('rm', ['-f', src]);
}

async function gen() {
  const book = readBook();
  const list = todo(book);
  mkdirSync(OUT, { recursive: true });
  const manifest = readManifest();
  let chars = 0;
  for (const e of list) {
    const out = join(OUT, `ency.${e.id}.mp3`);
    try {
      const { audio, chars: spent } = await tts({ voice: e.voice.id, text: e.intro.en, model: MODEL, settings: SETTINGS });
      master(audio, out);
      manifest[e.id] = { hash: hashOf(e.voice.id, e.intro.en), voice: e.voice.id, chars: spent ?? e.intro.en.length };
      chars += spent ?? e.intro.en.length;
      writeFileSync(MANIFEST, `${JSON.stringify(manifest, null, 1)}\n`);
      console.log(`ok ${e.id} (${e.voice.name})`);
    } catch (err) {
      console.log(`HATA ${e.id}: ${err.message}`);
    }
  }
  console.log(`${list.length} satır, ≈${chars} karakter harcandı.`);
}

try {
  if (cmd === 'cast') await cast();
  else if (cmd === 'cost') {
    const book = readBook();
    const list = todo(book);
    const uncast = book.entries.filter((e) => speaksNow(e) && !e.voice?.id);
    console.log(`${list.length} satır, ${list.reduce((s, e) => s + e.intro.en.length, 0)} karakter (eleven_v3).`);
    if (uncast.length) console.log(`Sesi seçilmemiş ${uncast.length} kişi daha var (${uncast.reduce((s, e) => s + e.intro.en.length, 0)} karakter): önce cast.`);
    const skipped = book.entries.filter((e) => e.intro?.en && !speaksNow(e));
    if (skipped.length) console.log(`Atlanan ${skipped.length}: ${skipped.map((e) => `${e.id}${e.speaks === false ? ' (konuşmaz)' : ' (ses seçimi bekliyor)'}`).join(', ')}`);
  } else if (cmd === 'gen') await gen();
  else console.log('Kullanım: node scripts/intro-voices.mjs cast [--force] | cost | gen [--only=a,b] [--force]');
} catch (e) {
  console.error(e.message);
  process.exitCode = 1;
}
