// Görev verisinin denetimi: src/lib/quests.ts'in getQuestData() sonucunu tasarım belgelerinin söylediği sayılarla
// karşılaştırır. Sayılar betikte ayrıca, doğrudan belgeden okunur: I'in ana görevi story.md §7'den ve act1.md §6'nın
// satırlarından, yan görevi act1.md §7'nin satırlarından; II–VI'nın ana ve yan görevleri story.md §10.2'den; yoldaş
// görevleri §10.3'ten (12 görev × 3 adım). Ayrıca:
// - kimlikler tekil, tür kimliğin önekine uygun; her source.href görevin kendi kimliğine gider (aynı satırı paylaşan
//   görevler de); her source.href'in, bölüm göndermesinin (refs), başka belgedeki anışın (elsewhere) ve sayfa metnindeki
//   belge bağının belge sayfası ve çapası var;
// - I'in XP toplamları: ana görevler act1.md §6 (xp), yan görevler act1.md §7 (xpMax, parça parça ödülün en çoğu);
// - II–VI'nın başlık sayıları: bütçe ve taban story.md §10.2'den, xpScale progression.md §1.2'den, bütçe = taban × görev ×
//   xpScale ve progression.md'nin «Ana görev» sütunu aynı;
// - I'in günleri: zincirin günleri act1.md §1'in sırasıyla, zaman «Gün …» diye yazılı, gün tetikte yinelenmiyor, yan
//   görevler act1.md §7'nin öbeğinde; Çocukluk'un son görevleri story.md §1'in bölüm adıyla;
// - story.md §10.2'nin «Görev puanı» sütunundaki her görevin ödülü görev puanını yazar;
// - düzyazı bayraklarında zanaat, buyruk, kürk ve yol kimliği (`cr_`, `cmd_`, `fur_`, `r_`) yok;
// - durum: her görevin Yol Haritası maddeleri progress.json'da var ve durum o maddelerden yeniden hesaplanınca aynı;
// - satır ve hücre çapası kuralının iki kopyası (quests.ts ve markdown-view.tsx) aynı kalıpları taşır ve bütün tasarım
//   belgelerinde aynı çapaları verir (canlı sunucu gerekmez); globals.css'te hücre çapasının satır vurgusu var;
// - istemci verisi (toClientView): özgün satır, sıra ve boş alan gitmez.
// Kullanım (docs-app içinden): node --experimental-strip-types --no-warnings scripts/quests-check.mjs [--live] [--progress] [--dump=dosya.json]
//   --live      her bağın sayfasını geliştirme sunucusundan (127.0.0.1:3100) çeker, çapanın sayfada olduğunu sınar. Görev
//               satırı çapası <tr id>, hücre çapası kendi satırının içinde <span id> olmalı; ikisi de sayfada tek.
//   --progress  Yol Haritası maddesi → bağlı görevler tablosunu yazar (bağ kurallarını gözle denetlemek için).
//   --dump=yol  getQuestData() sonucunu JSON olarak yazar.
// Uyuşmazlık varsa 1 ile çıkar.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { registerHooks, stripTypeScriptTypes } from "node:module";

// src/lib'in göreli içe aktarmaları uzantısızdır (Next çözer); düğüm için .ts eklenir.
registerHooks({
  resolve(spec, ctx, next) {
    if (spec.startsWith("./") && !path.extname(spec)) {
      try {
        return next(`${spec}.ts`, ctx);
      } catch {
        /* uzantısız kalsın */
      }
    }
    return next(spec, ctx);
  },
});

const APP = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DESIGN = path.resolve(APP, "../docs/design");
// quests.ts kökleri process.cwd()'den kurar (Next gibi): betik nereden çalışırsa çalışsın docs-app'te başlar.
process.chdir(APP);
const { getQuestData, docAnchors, questRowAnchors, questCellAnchors, toClientView, QUEST_ROW, DECISION_ROW, QUEST_ITEM, ACT_ORDER } = await import(path.join(APP, "src/lib/quests.ts"));

const args = process.argv.slice(2);
const live = args.includes("--live");
const showProgress = args.includes("--progress");
const dumpArg = args.find((a) => a.startsWith("--dump="));
const BASE = "http://127.0.0.1:3100";

const errors = [];
const notes = [];
const fail = (msg) => errors.push(msg);

const data = getQuestData();
const { quests } = data;
const byId = new Map(quests.map((q) => [q.id, q]));

// ---- Belgeden beklenen sayılar ----

const read = (name) => fs.readFileSync(path.join(DESIGN, `${name}.md`), "utf8");
const act1 = read("act1");
const story = read("story");

// Bir başlığın bölümü: başlıktan sonraki aynı ya da üst düzey başlığa dek.
function section(text, headingPattern) {
  const lines = text.split("\n");
  const start = lines.findIndex((l) => headingPattern.test(l));
  if (start < 0) return "";
  const depth = lines[start].match(/^#+/)[0].length;
  const end = lines.findIndex((l, i) => i > start && /^#+\s/.test(l) && l.match(/^#+/)[0].length <= depth);
  return lines.slice(start + 1, end < 0 ? undefined : end).join("\n");
}

const tableIds = (text, prefix) => text.split("\n").filter((l) => new RegExp(`^\\|\\s*\`${prefix}`).test(l)).length;
const xpTotalOf = (text) => Number(text.match(/XP toplamı (\d[\d.]*)/)?.[1]?.replace(/\./g, "") ?? NaN);

const expected = new Map(); // perde → { main, side, source }
const actOne = section(act1, /^## 6\. Ana görevler/);
const actOneSide = section(act1, /^## 7\. Yan görevler/);
const storySeven = section(story, /^## 7\. I\. Perde/);
const storyMainOne = Number(storySeven.match(/(\d+) ana görev/)?.[1] ?? NaN);
// Görevin istediği sayılar: I 22 ana, 23 yan. Ana sayı story.md §7'de de yazılıdır, yan sayının belgede sayısı yoktur.
expected.set("I", { main: 22, side: 23, source: "görev tanımı; story.md §7 ve act1.md §6–§7" });
if (storyMainOne !== 22) fail(`story.md §7 I'in ana görevini ${storyMainOne} diyor, 22 bekleniyordu.`);
if (tableIds(actOne, "mq_") !== 22) fail(`act1.md §6'da ${tableIds(actOne, "mq_")} ana görev satırı var, 22 bekleniyordu.`);
if (tableIds(actOneSide, "sq_") !== 23) fail(`act1.md §7'de ${tableIds(actOneSide, "sq_")} yan görev satırı var, 23 bekleniyordu.`);

// story.md §10.2: perde, ana görev, yan görev ve «Görev puanı» sütunu (başlıktan bulunur).
const tenTwo = section(story, /^### 10\.2 /).split("\n");
const headerCells = (line) => line.split("|").slice(1, -1).map((c) => c.trim());
const tenTwoHeader = headerCells(tenTwo.find((l) => /^\|\s*Perde\s*\|/.test(l)) ?? "");
const pointsCol = tenTwoHeader.findIndex((c) => /^Görev puanı$/i.test(c));
const baseCol = tenTwoHeader.findIndex((c) => /^Taban XP$/i.test(c));
const pointQuests = [];
const bases = new Map();
for (const line of tenTwo) {
  const m = line.match(/^\|\s*(VI|IV|V|I{1,3})\s*\|\s*(\d+)[^|]*\|[^|]*\|\s*([^|]+?)\s*\|/);
  if (!m) continue;
  const product = m[3].match(/(\d+)\D*?×\s*(\d+)/);
  expected.set(m[1], { main: Number(m[2]), side: product ? Number(product[1]) * Number(product[2]) : null, source: `story.md §10.2 («${m[3]}»)` });
  if (pointsCol >= 0) for (const id of (headerCells(line)[pointsCol] ?? "").match(/(?:mq|sq|cq)\d*_[a-z0-9_]+/g) ?? []) pointQuests.push({ act: m[1], id });
  if (baseCol >= 0) bases.set(m[1], Number((headerCells(line)[baseCol] ?? "").replace(/\./g, "")));
}
for (const act of ["II", "III", "IV", "V", "VI"]) if (!expected.has(act)) fail(`story.md §10.2'de ${act} satırı okunamadı.`);
if (pointsCol < 0) fail("story.md §10.2'de «Görev puanı» sütunu bulunamadı.");
if (baseCol < 0) fail("story.md §10.2'de «Taban XP» sütunu bulunamadı.");
const budgetLine = tenTwo.find((l) => /ana görev bütçesini verir/.test(l));
if (!budgetLine) fail("story.md §10.2'de ana görev bütçesi cümlesi («… ana görev bütçesini verir …: II 4.305, …») bulunamadı.");
const budgets = new Map([...(budgetLine?.split(":").slice(1).join(":").split(";")[0] ?? "").matchAll(/(VI|IV|V|I{1,3})\s+(\d[\d.]*)/g)].map((m) => [m[1], Number(m[2].replace(/\./g, ""))]));

const band = story.match(/(\d+) kişisel görev \(`cq_\*`\) × (\d+) adım/);
const companionsExpected = band ? { count: Number(band[1]), steps: Number(band[2]) } : null;
if (!companionsExpected) fail("story.md §10.3'te «12 kişisel görev (`cq_*`) × 3 adım» cümlesi okunamadı.");

// ---- Sayılar ----

const count = (act, kind) => quests.filter((q) => q.act === act && q.kind === kind).length;
const rows = [];
for (const act of ACT_ORDER) {
  const e = expected.get(act);
  const main = count(act, "main");
  const side = count(act, "side");
  const companion = count(act, "companion");
  // Anahtarlar console.table'ın sütun başlıklarıdır: görünen metin.
  rows.push({ Perde: act, Ana: main, Yan: side, Yoldaş: companion, Beklenen: e ? `${e.main} ana, ${e.side ?? "?"} yan` : "—" });
  if (!e) continue;
  if (e.main !== main) fail(`${act}: ${e.main} ana görev bekleniyordu, ${main} bulundu (${e.source}).`);
  if (e.side !== null && e.side !== side) fail(`${act}: ${e.side} yan görev bekleniyordu, ${side} bulundu (${e.source}).`);
}
if (count("childhood", "main") !== 2) fail(`Çocukluk: 2 ana görev (\`mq0_sheep\`, \`mq0_depart\`) bekleniyordu, ${count("childhood", "main")} bulundu.`);
if (quests.some((q) => q.act === "prologue")) fail("Önsöz sinemadır, görevi olmamalı.");

const companions = quests.filter((q) => q.kind === "companion");
if (companionsExpected) {
  if (companions.length !== companionsExpected.count) fail(`Yoldaş: ${companionsExpected.count} kişisel görev bekleniyordu, ${companions.length} bulundu.`);
  for (const q of companions) {
    if (q.steps.length !== companionsExpected.steps) fail(`\`${q.id}\`: ${companionsExpected.steps} adım bekleniyordu, ${q.steps.length} bulundu.`);
    q.steps.forEach((s, i) => {
      if (!s.threshold) fail(`\`${q.id}\` ${i + 1}. adımın düğüm eşiği yok.`);
      if (!s.detail) fail(`\`${q.id}\` ${i + 1}. adımın companions.md ayrıntısı yok.`);
    });
    if (!q.family) fail(`\`${q.id}\`: yoldaşın adı yok.`);
  }
}

// ---- Kimlik, tür, alanlar ----

const seen = new Map();
for (const q of quests) seen.set(q.id, (seen.get(q.id) ?? 0) + 1);
for (const [id, n] of seen) if (n > 1) fail(`\`${id}\` ${n} kez var: kimlik tekil olmalı.`);
const KIND_OF = { mq: "main", sq: "side", cq: "companion" };
const NOT_FLAG = /^(?:cr|cmd|fur|r)_/;
for (const q of quests) {
  const kind = KIND_OF[q.id.slice(0, 2)];
  if (kind !== q.kind) fail(`\`${q.id}\`: türü ${q.kind}, kimliğin öneki ${kind ?? "bilinmiyor"} diyor.`);
  if (!ACT_ORDER.includes(q.act)) fail(`\`${q.id}\`: bilinmeyen perde ${q.act}.`);
  if (!q.titleTr || q.titleTr === q.id) fail(`\`${q.id}\`: Türkçe adı yok.`);
  if (q.kind === "main" && q.steps.length === 0) fail(`\`${q.id}\`: ana görevin adımı ya da metni yok.`);
  for (const r of q.related) if (!seen.has(r)) fail(`\`${q.id}\`: ilişkili görev \`${r}\` yok.`);
  if (q.act !== "I") for (const f of q.flags) if (NOT_FLAG.test(f)) fail(`\`${q.id}\`: \`${f}\` bayrak sayılmış; zanaat, buyruk, kürk ve yol kimliği bayrak değildir.`);
  for (const f of q.otherIds ?? []) if (q.flags.includes(f)) fail(`\`${q.id}\`: \`${f}\` hem bayrak hem öbür kimlik.`);
  if (q.xp !== null && (q.xpMax ?? null) !== null && q.xpMax < q.xp) fail(`\`${q.id}\`: en çok XP (${q.xpMax}) ilk XP'den (${q.xp}) küçük.`);
  if ((q.xp === null) !== ((q.xpMax ?? null) === null)) fail(`\`${q.id}\`: xp ${q.xp}, xpMax ${q.xpMax}: biri varsa öbürü de olmalı.`);
}

// I'in XP toplamları: §6 ilk XP'lerle, §7 parça parça ödülün en çoğuyla tutar.
const sumOf = (kind, key) => quests.filter((q) => q.act === "I" && q.kind === kind).reduce((s, q) => s + (q[key] ?? 0), 0);
const mainOneXp = sumOf("main", "xp");
const xpTotal = xpTotalOf(actOne);
if (mainOneXp !== xpTotal) fail(`I: ana görevlerin XP toplamı ${mainOneXp}, act1.md §6 ${xpTotal} diyor.`);
if (sumOf("main", "xpMax") !== xpTotal) fail(`I: ana görevlerin en çok XP toplamı ${sumOf("main", "xpMax")}, act1.md §6 ${xpTotal} diyor.`);
const sideOneXp = sumOf("side", "xpMax");
const sideTotal = xpTotalOf(actOneSide);
if (sideOneXp !== sideTotal) fail(`I: yan görevlerin en çok XP toplamı ${sideOneXp}, act1.md §7 ${sideTotal} diyor.`);
const multiXp = quests.filter((q) => q.xpMax !== q.xp);

// II–VI'nın başlık sayıları: belgeden ayrıca okunur, acts'le ve birbiriyle karşılaştırılır.
const progressionOne = section(read("progression"), /^### 1\.2 /).split("\n");
const scaleHeader = headerCells(progressionOne.find((l) => /^\|\s*Perde\s*\|.*xpScale/.test(l)) ?? "");
const scaleCol = scaleHeader.findIndex((c) => /xpScale/.test(c));
const mainCol = scaleHeader.findIndex((c) => /^Ana görev$/i.test(c));
if (scaleCol < 0 || mainCol < 0) fail("progression.md §1.2'de «Ana görev» ve «`xpScale`» sütunlu tablo bulunamadı.");
const budgetRows = [];
for (const act of ["II", "III", "IV", "V", "VI"]) {
  const row = progressionOne.map(headerCells).find((c) => c[0] === act && scaleCol >= 0 && c.length === scaleHeader.length);
  const scale = Number((row?.[scaleCol] ?? "").replace(",", "."));
  const planned = Number((row?.[mainCol] ?? "").replace(/\./g, ""));
  const info = data.acts.find((a) => a.id === act);
  const budget = budgets.get(act);
  const base = bases.get(act);
  if (!budget) fail(`${act}: story.md §10.2'nin cümlesinde bütçe okunamadı.`);
  if (!base) fail(`${act}: story.md §10.2'de taban XP okunamadı.`);
  if (info?.xpBudget !== budget) fail(`${act}: başlık bütçesi ${info?.xpBudget}, story.md §10.2 ${budget} diyor.`);
  if (info?.baseXp !== base) fail(`${act}: başlık tabanı ${info?.baseXp}, story.md §10.2 ${base} diyor.`);
  if (info?.xpScale !== scale) fail(`${act}: başlığın xpScale'i ${info?.xpScale}, progression.md §1.2 ${scale} diyor.`);
  if (planned !== budget) fail(`${act}: progression.md §1.2'nin ana görevi ${planned}, story.md §10.2 ${budget} diyor.`);
  if (Math.round(base * count(act, "main") * scale) !== budget) fail(`${act}: taban ${base} × ${count(act, "main")} görev × xpScale ${scale} ≠ bütçe ${budget}.`);
  budgetRows.push(`${act} ${base} × ${count(act, "main")} × ${scale} = ${budget}`);
}

// I'in günleri: zincirin ardışık günleri act1.md §1'in bölüm tablosunun sırasıdır, sonda Bahar (`mq_home`).
const dayTitles = section(act1, /^## 1\. /)
  .split("\n")
  .filter((l) => /^\|\s*(?:Gün (?:VI|IV|V|I{1,3})\b|Son Gece\b)/.test(l))
  .map((l) => {
    const tr = headerCells(l)[0].split(" / ")[0].trim();
    const m = tr.match(/^Gün (\S+?),\s*(.+)$/);
    return m ? `Gün ${m[1]} · ${m[2]}` : tr;
  });
const chainDays = [];
for (const q of quests) if (q.act === "I" && q.kind === "main" && chainDays.at(-1) !== q.day) chainDays.push(q.day);
if (chainDays.join(" | ") !== [...dayTitles, "Bahar"].join(" | ")) fail(`I: zincirin günleri «${chainDays.join(" | ")}», act1.md §1 «${dayTitles.join(" | ")} | Bahar» diyor.`);
const DAY_START = /^(?:VI|IV|V|I{1,3})(?:–(?:VI|IV|V|I{1,3}))?(?:\s+(?:sabah|öğle|akşam|gece))?\s*(?:,|$)/;
for (const q of quests) {
  if (q.act !== "I") continue;
  if (q.when && !/^(?:Gün (?:VI|IV|V|I{1,3})(?:–(?:VI|IV|V|I{1,3}))?(?: · (?:sabah|öğle|akşam|gece))?|Son Gece|Bahar, .+)$/.test(q.when)) fail(`\`${q.id}\`: zaman «${q.when}» «Gün I · sabah» biçiminde değil.`);
  if (q.trigger && DAY_START.test(q.trigger)) fail(`\`${q.id}\`: gün tetikte yineleniyor («${q.trigger.slice(0, 30)}»).`);
}

// Yan görevlerin hepsi bir öbekte: I act1.md §7'nin yerinde («Yan görevler Kışlak'a bağlıdır»), II–VI story.md §11'in ailesinde.
if (!/Yan görevler Kışlak'a bağlıdır/.test(actOneSide)) fail("act1.md §7: «Yan görevler Kışlak'a bağlıdır» cümlesi yok; öbeğin adı oradan okunur.");
for (const q of quests) {
  if (q.kind !== "side") continue;
  if (!q.family) fail(`\`${q.id}\`: yan görevin öbeği yok; aile süzgecinde «Hepsi» çiplerin toplamını tutmaz.`);
  if (q.act === "I" && q.family !== "Kışlak (I. Perde)") fail(`\`${q.id}\`: öbeği «${q.family}», «Kışlak (I. Perde)» bekleniyordu.`);
}

// Çocukluk'un son görevleri: bölüm adı story.md §1'in «Bölüm» sütunudur («Köprü ve Yola Çıkış»).
for (const line of section(story, /^## 1\. /).split("\n")) {
  const id = line.match(/\|\s*`(mq0_[a-z0-9_]+)`[^|]*\|\s*$/)?.[1];
  if (!id) continue;
  const title = headerCells(line)[0].split(" / ")[0].trim();
  if (byId.get(id)?.chapter !== title) fail(`\`${id}\`: bölümü «${byId.get(id)?.chapter}», story.md §1 «${title}» diyor.`);
}

// İstemci verisi: özgün satır, sıra ve boş alan gitmez; gösterilen alanlar eksiksiz gider.
const client = toClientView(data);
const clientJson = JSON.stringify(client.quests);
if (/"(?:raw|order)":/.test(clientJson)) fail("İstemci verisinde özgün satır (raw) ya da sıra (order) var.");
if (/:null\b|:\[\]/.test(clientJson)) fail("İstemci verisinde boş alan (null, []) var.");
client.quests.forEach((c, i) => {
  const q = quests[i];
  if (c.id !== q.id) fail(`İstemci verisinin sırası bozuk: ${i}. görev \`${c.id}\`, \`${q.id}\` bekleniyordu.`);
  for (const key of ["refs", "elsewhere", "otherIds", "flags", "related", "progress"]) if ((c[key] ?? []).length !== (q[key] ?? []).length) fail(`\`${q.id}\`: istemci verisinde ${key} eksik.`);
  if ((c.description ?? null) !== (q.description ?? null) || (c.xpMax ?? c.xp ?? null) !== (q.xpMax ?? null)) fail(`\`${q.id}\`: istemci verisinde description ya da xpMax farklı.`);
  if (q.order !== quests.slice(0, i).filter((p) => p.act === q.act && p.kind === q.kind).length) fail(`\`${q.id}\`: liste belge sırasında değil (order ${q.order}); istemci sırayı listeden okur.`);
});

for (const { act, id } of pointQuests) {
  const q = byId.get(id);
  if (!q) fail(`story.md §10.2 «Görev puanı» (${act}): \`${id}\` tanımlı değil.`);
  else if (!q.reward?.includes("Görev puanı")) fail(`\`${id}\`: story.md §10.2 görev puanı veriyor, ödülü bunu yazmıyor (${q.reward ?? "boş"}).`);
}

for (const act of data.acts) {
  if (act.mainCount !== count(act.id, "main") || act.sideCount !== count(act.id, "side") || act.companionCount !== count(act.id, "companion")) {
    fail(`acts[${act.id}] sayıları görev listesiyle uyuşmuyor.`);
  }
}

// ---- Durum: Yol Haritası ----
// Bağ kuralları quests.ts'tedir; burada bağlı maddelerin var olduğu ve durumun o maddelerden aynı kuralla çıktığı
// sınanır: hepsi bitti → playable, biri bitti ya da sürüyor → in-progress, yoksa design.

const progressFile = JSON.parse(fs.readFileSync(path.join(APP, "content/progress.json"), "utf8"));
const items = new Map(progressFile.items.map((i) => [i.id, i]));
const linkedBy = new Map();
for (const q of quests) {
  const linked = (q.progress ?? []).map((id) => items.get(id));
  (q.progress ?? []).forEach((id, i) => {
    if (!linked[i]) fail(`\`${q.id}\`: Yol Haritası maddesi \`${id}\` progress.json'da yok.`);
    else linkedBy.set(id, [...(linkedBy.get(id) ?? []), q.id]);
  });
  const states = linked.filter(Boolean).map((i) => i.status);
  const status = states.length && states.every((s) => s === "bitti") ? "playable" : states.some((s) => s === "bitti" || s === "suruyor") ? "in-progress" : "design";
  if (status !== q.status) fail(`\`${q.id}\`: durumu ${q.status}, bağlı maddelerinden (${(q.progress ?? []).join(", ") || "yok"}) ${status} çıkıyor.`);
}
const unlinked = quests.filter((q) => !(q.progress ?? []).length);
const statusCount = Object.fromEntries(["playable", "in-progress", "design"].map((s) => [s, quests.filter((q) => q.status === s).length]));

// ---- Bağlar: belge sayfası ve çapa ----
// Görevin satırı (source.href), bölüm göndermeleri (refs) ve başka belgedeki anışlar (elsewhere).

const pages = new Map();
const links = [];
for (const q of quests) {
  // Yalnız satırı olmayan Çocukluk görevleri bölüm başlığına gider.
  if (q.act !== "childhood" && !q.source.href.endsWith(`#${q.id}`)) fail(`\`${q.id}\`: bağ görevin kendi kimliğine gitmiyor (${q.source.href}).`);
  links.push({ id: q.id, what: "bağ", href: q.source.href, design: true });
  for (const r of q.refs ?? []) links.push({ id: q.id, what: `gönderme ${r.label}`, href: r.href });
  for (const e of q.elsewhere ?? []) links.push({ id: q.id, what: `anış (${e.doc})`, href: e.href });
}
// Sayfa metnindeki belge bağları (giriş, sekme notları) elle yazılıdır.
const uiFiles = [path.join(APP, "src/app/quests/page.tsx"), ...fs.readdirSync(path.join(APP, "src/components/quests")).filter((f) => f.endsWith(".tsx")).map((f) => path.join(APP, "src/components/quests", f))];
for (const file of uiFiles) {
  for (const m of fs.readFileSync(file, "utf8").matchAll(/"(\/docs\/source\/[^"#]+#[^"]+)"/g)) links.push({ id: path.basename(file), what: "sayfa metni", href: m[1] });
}
for (const link of links) {
  const m = link.href.match(/^(\/docs\/source\/(design|research)\/[a-z0-9-]+)(?:#(.+))?$/);
  if (!m || (link.design && m[2] !== "design")) {
    fail(`\`${link.id}\`: ${link.what} bir kaynak belge sayfası değil (${link.href}).`);
    continue;
  }
  const [, page, , anchor] = m;
  if (!pages.has(page)) pages.set(page, docAnchors(page));
  const anchors = pages.get(page);
  if (!anchors) fail(`\`${link.id}\`: ${link.what}: ${page} sayfasının belgesi yok.`);
  else if (!anchor) fail(`\`${link.id}\`: ${link.what}: bağın çapası yok (${link.href}).`);
  else if (!anchors.has(anchor)) fail(`\`${link.id}\`: ${link.what}: #${anchor} çapası ${page} sayfasında yok.`);
}

// ---- Satır ve hücre çapası kuralı: quests.ts ve markdown-view.tsx ----
// markdown-view.tsx istemcide de çalışır, node:fs'li quests.ts'i içe aktaramaz; kural iki yerde yazılıdır. Burada iki
// kopyanın kalıpları karşılaştırılır, markdown-view.tsx'in questRowAnchors ve questCellAnchors işlevleri türleri ayıklanıp
// çalıştırılır ve bütün tasarım belgelerinde quests.ts'inkiyle aynı satıra, aynı hücre konumuna aynı çapayı verdiği sınanır.

const VIEW = path.join(APP, "src/components/doc/markdown-view.tsx");
const view = fs.readFileSync(VIEW, "utf8");
const viewConst = (name) => view.match(new RegExp(`^const ${name} = (/.+/[a-z]*);$`, "m"));
let viewAnchors = null;
for (const [name, re] of [["QUEST_ROW", QUEST_ROW], ["DECISION_ROW", DECISION_ROW], ["QUEST_ITEM", QUEST_ITEM]]) {
  const m = viewConst(name);
  if (!m) fail(`markdown-view.tsx'te \`const ${name} = /…/;\` bulunamadı.`);
  else if (m[1] !== String(re)) fail(`${name} iki kopyada farklı: markdown-view.tsx ${m[1]}, quests.ts ${re}.`);
}
const viewFn = (name) => {
  const start = view.indexOf(`function ${name}(`);
  const end = start >= 0 ? view.indexOf("\n}\n", start) : -1;
  if (start < 0 || end < 0) fail(`markdown-view.tsx'te ${name} işlevi bulunamadı.`);
  return start < 0 || end < 0 ? null : view.slice(start, end + 2);
};
const rowFn = viewFn("questRowAnchors");
const cellFn = viewFn("questCellAnchors");
if (rowFn && cellFn) {
  try {
    // Türler ayıklanır (stripTypeScriptTypes üst düzey return kabul etmez, işlevleri döndüren satır sonra eklenir).
    const code = stripTypeScriptTypes([viewConst("QUEST_ROW")?.[0], viewConst("DECISION_ROW")?.[0], viewConst("QUEST_ITEM")?.[0], rowFn, cellFn].join("\n"));
    viewAnchors = new Function(`${code}\nreturn { rows: questRowAnchors, cells: questCellAnchors };`)();
  } catch (err) {
    fail(`markdown-view.tsx'in çapa işlevleri çalıştırılamadı: ${err.message}`);
  }
}
if (!/\.doc-table tr:has\(:target\) td\s*\{/.test(fs.readFileSync(path.join(APP, "src/app/globals.css"), "utf8"))) fail("globals.css'te hücre çapasının satır vurgusu (.doc-table tr:has(:target) td) yok.");
let anchorDocs = 0;
let anchorRows = 0;
let anchorCells = 0;
if (viewAnchors) {
  const walk = (dir) => fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? walk(path.join(dir, e.name)) : e.name.endsWith(".md") ? [path.join(dir, e.name)] : []));
  for (const file of walk(DESIGN)) {
    const body = fs.readFileSync(file, "utf8").replace(/\r\n/g, "\n").replace(/^\s*#\s+.+\n+/, "");
    const lines = body.split("\n");
    const rows = questRowAnchors(lines);
    const cells = questCellAnchors(lines, rows);
    const mine = JSON.stringify([...rows]);
    const viewRows = viewAnchors.rows(body);
    const theirs = JSON.stringify([...viewRows]);
    const mineCells = JSON.stringify([...cells]);
    const theirCells = JSON.stringify([...viewAnchors.cells(lines, viewRows)]);
    anchorDocs++;
    anchorRows += rows.size;
    anchorCells += cells.size;
    if (mine !== theirs) fail(`${path.relative(DESIGN, file)}: satır çapaları iki kopyada farklı (quests.ts ${mine.length} / markdown-view.tsx ${theirs.length} karakter).`);
    if (mineCells !== theirCells) fail(`${path.relative(DESIGN, file)}: hücre çapaları iki kopyada farklı (quests.ts ${mineCells.length} / markdown-view.tsx ${theirCells.length} karakter).`);
  }
}

const liveAnchors = { rows: 0, cells: 0 };
if (live) {
  const byPage = new Map();
  for (const link of links) {
    const [page, anchor] = link.href.split("#");
    byPage.set(page, [...(byPage.get(page) ?? []), { ...link, anchor }]);
  }
  for (const [page, list] of byPage) {
    let html = "";
    try {
      const res = await fetch(`${BASE}${page}`);
      if (!res.ok) {
        fail(`${page}: sunucu ${res.status} döndü.`);
        continue;
      }
      html = await res.text();
    } catch (err) {
      fail(`${page}: geliştirme sunucusuna ulaşılamadı (${err.message}); --live için ${BASE} açık olmalı.`);
      break;
    }
    const ids = new Set([...html.matchAll(/\sid="([^"]+)"/g)].map((m) => m[1]));
    const missing = list.filter((i) => i.anchor && !ids.has(i.anchor));
    for (const i of missing) fail(`\`${i.id}\`: ${i.what}: #${i.anchor} çapası canlı sayfada yok (${page}).`);
    notes.push(`${page}: ${list.length} bağ, ${list.length - missing.length} çapa sayfada.`);

    // Çapaların ikisi de: görev satırı <tr id>, hücre çapası kendi satırının içinde <span id>; ikisi de sayfada tek.
    const name = page.match(/^\/docs\/source\/design\/([a-z0-9-]+)$/)?.[1];
    if (!name || !fs.existsSync(path.join(DESIGN, `${name}.md`))) continue;
    const lines = read(name).replace(/\r\n/g, "\n").replace(/^\s*#\s+.+\n+/, "").split("\n");
    const rows = questRowAnchors(lines);
    const cells = questCellAnchors(lines, rows);
    const occurrences = (id) => html.split(` id="${id}"`).length - 1;
    for (const id of rows.values()) {
      if (!new RegExp(`<tr\\b[^>]*\\sid="${id}"`).test(html)) fail(`#${id}: görev satırı çapası ${page} sayfasında <tr id> değil.`);
      if (occurrences(id) !== 1) fail(`#${id}: ${page} sayfasında ${occurrences(id)} kez var, tek olmalı.`);
    }
    for (const [at, id] of cells) {
      const rowId = rows.get(Number(at.split(":")[0]));
      const from = html.indexOf(` id="${rowId}"`);
      const to = html.indexOf("</tr>", from);
      const span = html.search(new RegExp(`<span\\b[^>]*\\sid="${id}"`));
      if (span < 0) fail(`#${id}: hücre çapası ${page} sayfasında <span id> değil.`);
      else if (span < from || span > to) fail(`#${id}: hücre çapası kendi satırının (#${rowId}) içinde değil (${page}).`);
      if (occurrences(id) !== 1) fail(`#${id}: ${page} sayfasında ${occurrences(id)} kez var, tek olmalı.`);
    }
    liveAnchors.rows += rows.size;
    liveAnchors.cells += cells.size;
  }
}

// ---- Rapor ----

const by = (kind) => quests.filter((q) => q.kind === kind);
const linkedCount = (kind) => by(kind).filter((q) => (q.progress ?? []).length).length;
console.log(`Görev denetimi: ${quests.length} görev (${by("main").length} ana, ${by("side").length} yan, ${companions.length} yoldaş).`);
console.table(rows);
console.log(`Yoldaş görevleri: ${companions.length} görev, ${companions.reduce((s, q) => s + q.steps.length, 0)} adım.`);
console.log(`I. Perde ana görevlerinin XP toplamı: ${mainOneXp} (act1.md §6: ${xpTotal}).`);
console.log(`I. Perde yan görevlerinin en çok XP toplamı: ${sideOneXp} (act1.md §7: ${sideTotal}); ilk XP'lerin toplamı ${sumOf("side", "xp")}.`);
console.log(`Parça parça XP veren görevler: ${multiXp.map((q) => `${q.id} ${q.xp} → ${q.xpMax}`).join(", ") || "yok"}.`);
console.log(`Ana görev bütçesi (story.md §10.2, progression.md §1.2): ${budgetRows.join("; ")}.`);
console.log(`I'in zinciri günlere göre: ${chainDays.join(" → ")}; I'de zamanı yazılı yan görev ${quests.filter((q) => q.act === "I" && q.kind === "side" && q.when).length}/${count("I", "side")}.`);
console.log(`Yan görev öbekleri: ${[...new Set(quests.filter((q) => q.kind === "side").map((q) => q.family))].map((f) => `${f} ${quests.filter((q) => q.kind === "side" && q.family === f).length}`).join(", ")}.`);
console.log(`İstemci verisi (görevler): ${Buffer.byteLength(clientJson)} B; tam veri ${Buffer.byteLength(JSON.stringify(quests))} B.`);
console.log(`Görev puanı (story.md §10.2): ${pointQuests.map((p) => p.id).join(", ")}.`);
console.log(`Bölüm göndermeleri: ${quests.reduce((s, q) => s + (q.refs ?? []).length, 0)} bağ, ${quests.filter((q) => (q.refs ?? []).length).length} görevde.`);
console.log(
  `Adımı boş görevler: ${quests.filter((q) => !q.steps.length).length}; başka belgede anılan ${quests.filter((q) => (q.elsewhere ?? []).length).length} (${quests.reduce((s, q) => s + (q.elsewhere ?? []).length, 0)} anış), tanım cümlesi olan ${quests.filter((q) => q.description).length}.`,
);
console.log(`Bayraklar: ${quests.reduce((s, q) => s + q.flags.length, 0)}; bayrak sayılmayan öbür kimlikler: ${quests.reduce((s, q) => s + (q.otherIds ?? []).length, 0)}.`);
console.log(
  `Yol Haritası: ${linkedBy.size} madde görevlere bağlı; bağlı görev ana ${linkedCount("main")}/${by("main").length}, yan ${linkedCount("side")}/${by("side").length}, yoldaş ${linkedCount("companion")}/${companions.length}; durum playable ${statusCount.playable}, in-progress ${statusCount["in-progress"]}, design ${statusCount.design}.`,
);
if (unlinked.length) console.log(`Yol Haritası maddesi olmayan görevler: ${unlinked.map((q) => q.id).join(", ")}.`);
if (viewAnchors) console.log(`Çapa kuralı: iki kopya ${anchorDocs} tasarım belgesinde aynı (${anchorRows} görev satırı çapası, ${anchorCells} hücre çapası).`);
console.log(`Bağı görevin kendi kimliğine giden: ${quests.filter((q) => q.source.href.endsWith(`#${q.id}`)).length}/${quests.length}.`);
for (const note of notes) console.log(note);
if (live) console.log(`Canlı sayfalarda sınanan çapa: ${liveAnchors.rows} görev satırı (<tr id>), ${liveAnchors.cells} hücre (kendi satırında <span id>).`);
if (showProgress) {
  console.log("\nYol Haritası maddesi → görevler:");
  for (const [id, list] of [...linkedBy].sort((a, b) => [...items.keys()].indexOf(a[0]) - [...items.keys()].indexOf(b[0]))) {
    console.log(`  ${id} [${items.get(id).status}]: ${list.join(", ")}`);
  }
}
if (data.warnings.length) {
  console.log(`\nVerinin uyarıları (${data.warnings.length}):`);
  for (const w of data.warnings) console.log(`  - ${w}`);
}

if (dumpArg) {
  const file = path.resolve(dumpArg.slice("--dump=".length));
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(data, null, 2)}\n`);
  console.log(`\nDöküm yazıldı: ${file}`);
}

if (errors.length) {
  console.log(`\nUyuşmazlık (${errors.length}):`);
  for (const e of errors) console.log(`  ✗ ${e}`);
  process.exit(1);
}
console.log("\nTamam: sayılar, kimlikler, bağlar, durum, XP başlıkları, günler ve çapa kuralı belgelerle uyuşuyor.");
