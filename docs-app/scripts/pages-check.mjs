// Site sayfalarının denetimi: ön bilgi, başlık, tablo, çit, bağ, bölüm, medya, kaynak yolu, [!NOT] alıntısı, varlık kimliği.
// Kullanım (docs-app içinden): node --experimental-strip-types --no-warnings scripts/pages-check.mjs [--parity]
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire, registerHooks } from "node:module";

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
const REPO = path.resolve(APP, "..");
const PAGES = path.join(APP, "content/pages");
const require = createRequire(path.join(APP, "package.json"));
const matter = require("gray-matter");
const { scanHeadings, extractHeadings } = await import(path.join(APP, "src/lib/markdown.ts"));

const STATUSES = new Set(["oyunda", "kismen", "tasarim", "yeni"]);
const CALLOUT_KINDS = new Set(["NOT", "CELISKI", "ONERI", "ACIK", "DURUM"]);
const CATEGORIES = new Set(["general", "story", "world", "gameplay", "economy", "buildings", "settlement", "presentation", "development"]);
// Uzun önek önce: «source/design/d3/brief» d3 klasöründen okunur.
const SOURCE_DIRS = {
  "source/design/d2": "docs/design/d2",
  "source/design/d3": "docs/design/d3",
  "source/design": "docs/design",
  "source/research": "docs/research",
  "source/game/docs": "game/docs",
  "source/game": "game",
};
const LEGACY = JSON.parse(fs.readFileSync(path.join(APP, "src/lib/legacy-ids.json"), "utf8"));
const FILE_OF_ALIAS = Object.fromEntries(Object.entries(LEGACY.sourceNames).map(([file, alias]) => [alias, file]));
const APP_ROUTES = new Set(["/", "/notes", "/releases", "/roadmap", "/assets", "/encyclopedia", "/animations", "/quests"]);
const EXPECTED = `general/overview general/design-round general/pending-decisions general/my-notes general/glossary
story/spine story/prologue story/childhood story/act-1 story/act-1-days story/act-2 story/act-3 story/act-4 story/act-5 story/act-6 story/epilogue story/chronicle story/cast story/mythology story/history-sources
world/map world/regions world/travel world/time-calendar world/weather world/animals
gameplay/camera-controls gameplay/open-world-quests gameplay/companions gameplay/progression gameplay/combat gameplay/fire-cooking-hunting gameplay/overnight-camp gameplay/army
economy/inventory-load economy/materials economy/gathering economy/crafting economy/money-traders economy/balance
buildings/yurts buildings/construction-labour buildings/catalog buildings/damage-repair
settlement/encampment settlement/households settlement/production-storage settlement/war-camp-caravans settlement/court settlement/plan-mode
presentation/visual-language presentation/sound-music presentation/voice-over presentation/ui-menus
development/features development/architecture development/asset-pipeline`.split(/\s+/);

// Varlık kataloğu: «```varlik» bloklarındaki kimlikler ve /assets/<tür> bağları buna göre denetlenir.
const CATALOG_FILE = path.join(REPO, "docs/assets/catalog.json");
const catalog = fs.existsSync(CATALOG_FILE) ? JSON.parse(fs.readFileSync(CATALOG_FILE, "utf8")) : null;
const assetIds = new Set((catalog?.assets ?? []).map((a) => a.id));
const assetGroups = new Set((catalog?.groups ?? []).map((g) => g.id));

// İlerleme: «```ilerleme» bloklarındaki perde ve faz kimlikleri buna göre denetlenir.
const PROGRESS_FILE = path.join(APP, "content/progress.json");
const progress = fs.existsSync(PROGRESS_FILE) ? JSON.parse(fs.readFileSync(PROGRESS_FILE, "utf8")) : null;
const progressIds = new Set([...(progress?.acts ?? []), ...(progress?.phases ?? [])].map((x) => x.id));
// Madde bağı: /roadmap#item-<madde kimliği>.
const progressItemIds = new Set((progress?.items ?? []).map((x) => `item-${x.id}`));

// Ansiklopedi: /encyclopedia/<kimlik> bağları ve dosyanın kendi tutarlılığı (bölüm, bağlar, portre, kaynak bağı).
const ENC_FILE = path.join(APP, "content/encyclopedia.json");
const encyclopedia = fs.existsSync(ENC_FILE) ? JSON.parse(fs.readFileSync(ENC_FILE, "utf8")) : null;
const encIds = new Set((encyclopedia?.entries ?? []).map((e) => e.id));

const walk = (dir) =>
  fs.existsSync(dir)
    ? fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
        const full = path.join(dir, e.name);
        return e.isDirectory() ? walk(full) : e.name.endsWith(".md") ? [full] : [];
      })
    : [];

const pages = walk(PAGES).sort();
const ids = pages.map((f) => path.relative(PAGES, f).replace(/\.md$/, ""));
const problems = [];
const warn = (id, msg) => problems.push(`${id}: ${msg}`);

// Hedef belgenin gövdesi ve başlık kimlikleri
function target(id) {
  if (ids.includes(id)) {
    const raw = fs.readFileSync(path.join(PAGES, `${id}.md`), "utf8");
    const m = raw.match(/^---\r?\n[\s\S]*?\r?\n---\r?\n?/);
    return raw.slice(m ? m[0].length : 0).replace(/^\n+/, "");
  }
  for (const [prefix, dir] of Object.entries(SOURCE_DIRS)) {
    if (id.startsWith(`${prefix}/`)) {
      const name = id.slice(prefix.length + 1);
      if (name.includes("/")) continue;
      // Takma ad klasöre bağlıdır: «companions» araştırmada yoldaslar.md, tasarımda companions.md'dir. Önce adın kendisi.
      const file = [name, FILE_OF_ALIAS[name]].filter(Boolean).map((n) => path.join(REPO, dir, `${n}.md`)).find((f) => fs.existsSync(f));
      if (file) return fs.readFileSync(file, "utf8").replace(/^\s*#\s+.+\n+/, "");
    }
  }
  return null;
}

const isGroup = (id) => CATEGORIES.has(id) || id === "source" || id in SOURCE_DIRS;

// Kullanıcının sözleri: [!NOT] alıntıları bunların birinde aynen geçmeli. Notlarım sayfası ham notu, cevap defteri (d3/register.md)
// ek istekleri ve cevapları, tasarım belgeleri (decisions.md ve alan belgeleri) kendi konularındaki sözleri tutar.
const designDocs = fs.readdirSync(path.join(REPO, "docs/design"), { recursive: true })
  .filter((f) => String(f).endsWith(".md"))
  .map((f) => path.join(REPO, "docs/design", String(f)));
const rawNote = [path.join(PAGES, "general/my-notes.md"), ...designDocs].map((f) => fs.readFileSync(f, "utf8")).join("\n");
const norm = (s) => s.replace(/\s+/g, " ").trim();
const userWords = norm(rawNote);

let links = 0;
let mediaCount = 0;
let assetRefs = 0;
let progressRefs = 0;
const openBoxes = [];
const inbound = new Map(ids.map((i) => [i, 0]));

for (const file of pages) {
  const id = path.relative(PAGES, file).replace(/\.md$/, "");
  const raw = fs.readFileSync(file, "utf8");
  let data;
  let body;
  try {
    const parsed = matter(raw, {});
    data = parsed.data;
    body = parsed.content;
  } catch (e) {
    warn(id, `YAML bozuk: ${String(e.message).split("\n")[0]}`);
    const m = raw.match(/^---\r?\n[\s\S]*?\r?\n---\r?\n?/);
    data = {};
    body = raw.slice(m ? m[0].length : 0);
  }
  if (Object.keys(data).length) {
    if (typeof data.title !== "string" || !data.title) warn(id, "title yok");
    if (typeof data.order !== "number") warn(id, `order sayı değil: ${data.order}`);
    if (typeof data.summary !== "string" || !data.summary) warn(id, "summary yok");
    if (!Array.isArray(data.sources)) warn(id, "sources dizi değil");
    if (data.status !== undefined && !STATUSES.has(data.status)) warn(id, `geçersiz status: ${data.status}`);
    if (data.status === undefined && !id.startsWith("general/")) warn(id, "status yok");
    for (const s of data.sources ?? []) {
      const clean = String(s).split("#")[0].split(" ")[0];
      if (!fs.existsSync(path.join(REPO, clean))) warn(id, `kaynak yolu yok: ${s}`);
    }
  }

  // Satır taraması
  const lines = body.split("\n");
  let fence = "";
  let tableCols = 0;
  let quoteKind = null;
  let quote = [];
  const flushQuote = () => {
    if (quoteKind === "NOT") {
      // Alıntı işaretleri ve üç nokta metne dahil değil; kalanın her parçası (paragraf paragraf) kullanıcının sözlerinde aynen geçmeli.
      const parts = quote
        .join("\n")
        .split(/\n\s*\n/)
        .flatMap((para) => norm(para).replace(/[«»]/g, "").split(/\s*(?:\.\.\.|…)\s*/))
        .map((p) => p.trim())
        .filter(Boolean);
      for (const part of parts) {
        if (!userWords.includes(part)) warn(id, `[!NOT] kullanıcının sözlerinde yok: «${part.slice(0, 110)}»`);
      }
    }
    quoteKind = null;
    quote = [];
  };
  let fenceLang = "";
  lines.forEach((line, i) => {
    const at = i + 1;
    const marker = line.match(/^ {0,3}(`{3,}|~{3,})\s*([A-Za-z0-9_-]*)/);
    if (marker) {
      if (!fence) {
        fence = marker[1][0];
        fenceLang = marker[2] ?? "";
      } else if (marker[1][0] === fence) {
        fence = "";
        fenceLang = "";
      }
      flushQuote();
      return;
    }
    if (fence) {
      if (fenceLang === "ilerleme") {
        for (const ref of line.split(/[\s,]+/).filter(Boolean)) {
          progressRefs += 1;
          if (!progressIds.has(ref)) warn(id, `satır ${at}: İlerleme'de olmayan perde ya da faz ${ref}`);
        }
      }
      if (fenceLang === "varlik") {
        for (const assetId of line.split(/[\s,]+/).filter(Boolean)) {
          assetRefs += 1;
          if (!catalog) warn(id, `satır ${at}: varlık kataloğu yok, kimlik denetlenemedi: ${assetId}`);
          else if (!assetIds.has(assetId)) warn(id, `satır ${at}: katalogda olmayan varlık ${assetId}`);
        }
      }
      return;
    }
    if (/^# /.test(line)) warn(id, `satır ${at}: gövdede H1`);
    // Çıplak tablo: sütun sayısı
    if (/^\s*\|/.test(line)) {
      const cells = line.replace(/\\\|/g, "").replace(/`[^`]*`/g, (m) => m.replace(/\|/g, "")).trim().replace(/^\||\|$/g, "").split("|").length;
      if (tableCols && cells !== tableCols) warn(id, `satır ${at}: tablo sütunu ${cells}, beklenen ${tableCols}`);
      tableCols = tableCols || cells;
    } else {
      tableCols = 0;
    }
    // Kutular
    const callout = line.match(/^>\s*\[!([^\]]+)\]/);
    if (callout) {
      flushQuote();
      if (!CALLOUT_KINDS.has(callout[1])) warn(id, `satır ${at}: bilinmeyen kutu ${callout[1]}`);
      if (callout[1] === "ACIK" || callout[1] === "CELISKI") openBoxes.push(`${id}:${at} ${callout[1]}`);
      quoteKind = callout[1];
      const rest = line.replace(/^>\s*\[![^\]]+\]\s*/, "");
      if (rest) quote.push(rest);
    } else if (quoteKind && /^>/.test(line)) {
      quote.push(line.replace(/^>\s?/, ""));
    } else if (quoteKind) {
      flushQuote();
    }
    // Bağlar
    for (const m of line.matchAll(/\]\((\/[^)\s]*)\)/g)) {
      const href = m[1];
      links += 1;
      const [pathAndQuery, anchor] = href.split("#");
      const [p, query = ""] = pathAndQuery.split("?");
      // Notlarım, Notlar sayfasının «Yazdığın notlar» görünümüne taşındı: bu bağ o sayfaya bağ sayılır.
      if (p === "/notes" && new URLSearchParams(query).get("view") === "written" && inbound.has("general/my-notes") && id !== "general/my-notes") {
        inbound.set("general/my-notes", inbound.get("general/my-notes") + 1);
      }
      if (p.startsWith("/docs/")) {
        const to = decodeURIComponent(p.slice("/docs/".length));
        if (isGroup(to)) continue;
        const text = target(to);
        if (text === null) {
          warn(id, `satır ${at}: kırık bağ ${href}`);
          continue;
        }
        if (inbound.has(to) && to !== id) inbound.set(to, inbound.get(to) + 1);
        // Karar satırı çapası: #k45, hedefte «| K45 |» satırı varsa geçerlidir.
        const rowAnchor = anchor && /^k\d{1,3}$/.test(anchor) && new RegExp(`^\\|\\s*K${anchor.slice(1)}\\s*\\|`, "m").test(text);
        if (anchor && !rowAnchor && !scanHeadings(text).some((h) => h.id === anchor)) warn(id, `satır ${at}: bölüm yok ${href}`);
      } else if (p.startsWith("/media/")) {
        mediaCount += 1;
        const rel = decodeURIComponent(p.slice("/media/".length));
        if (!/^(docs|game)\//.test(rel)) warn(id, `satır ${at}: izinsiz medya ${href}`);
        else if (!fs.existsSync(path.join(REPO, rel))) warn(id, `satır ${at}: medya yok ${href}`);
      } else if (p.startsWith("/assets/")) {
        const group = p.slice("/assets/".length);
        if (catalog && !assetGroups.has(group)) warn(id, `satır ${at}: varlık türü yok ${href}`);
        if (catalog && anchor && !assetIds.has(anchor)) warn(id, `satır ${at}: varlık yok ${href}`);
      } else if (p.startsWith("/encyclopedia/")) {
        if (encyclopedia && !encIds.has(p.slice("/encyclopedia/".length))) warn(id, `satır ${at}: ansiklopedide olmayan kayıt ${href}`);
      } else if (p === "/roadmap" && anchor && progress && !progressIds.has(anchor) && !progressItemIds.has(anchor)) {
        warn(id, `satır ${at}: Yol Haritası'nda olmayan ${anchor.startsWith("item-") ? "madde" : "bölüm"} ${href}`);
      } else if (!APP_ROUTES.has(p)) {
        warn(id, `satır ${at}: bilinmeyen iç bağ ${href}`);
      }
    }
  });
  flushQuote();
  if (fence) warn(id, "kapanmamış kod çiti");
  // Düz yolla yazılmış bağ kontrolü
  if (/\]\((?!\/|https?:|#)[^)]+\)/.test(body)) {
    for (const m of body.matchAll(/\]\(((?!\/|https?:|#)[^)]+)\)/g)) warn(id, `göreli bağ: ${m[1]}`);
  }
}

// Ansiklopedi dosyasının kendi tutarlılığı.
if (encyclopedia) {
  const chapters = new Set((encyclopedia.chapters ?? []).map((c) => c.id));
  const icons = new Set(["sun", "bow", "yurt", "horse", "tower", "people", "star"]);
  for (const c of encyclopedia.chapters ?? []) if (c.icon && !icons.has(c.icon)) problems.push(`ansiklopedi: bölüm ${c.id} bilinmeyen simge ${c.icon}`);
  const seen = new Set();
  for (const e of encyclopedia.entries ?? []) {
    if (seen.has(e.id)) problems.push(`ansiklopedi: çift kimlik ${e.id}`);
    seen.add(e.id);
    if (!chapters.has(e.chapter)) problems.push(`ansiklopedi: ${e.id} bölümü yok (${e.chapter})`);
    if (!["mit", "tarih", "kurgu"].includes(e.era)) problems.push(`ansiklopedi: ${e.id} çağı geçersiz (${e.era})`);
    for (const r of e.relations ?? []) if (!encIds.has(r.id)) problems.push(`ansiklopedi: ${e.id} bağı yok: ${r.id}`);
    if (e.portrait && !fs.existsSync(path.join(REPO, "docs/media/ui/portraits", `${e.portrait}.webp`))) problems.push(`ansiklopedi: ${e.id} portresi yok: ${e.portrait}`);
    if (e.body !== undefined && !Array.isArray(e.body)) problems.push(`ansiklopedi: ${e.id} body dizi değil`);
    for (const src of e.sources ?? []) {
      const [p] = String(src.href ?? "").split("#");
      if (!src.href) problems.push(`ansiklopedi: ${e.id} kaynağında href yok`);
      else if (p.startsWith("/docs/") && target(decodeURIComponent(p.slice(6))) === null && !isGroup(p.slice(6))) problems.push(`ansiklopedi: ${e.id} kırık kaynak bağı ${src.href}`);
    }
  }
}

const missing = EXPECTED.filter((e) => !ids.includes(e));
const extra = ids.filter((i) => !EXPECTED.includes(i));
console.log(`sayfa: ${ids.length}/${EXPECTED.length}, bağ: ${links}, medya: ${mediaCount}, varlık kimliği: ${assetRefs}, yol haritası bloğu: ${progressRefs}`);
if (openBoxes.length) console.log(`açık kutu (ACIK/ÇELİŞKİ): ${openBoxes.length}\n  ${openBoxes.join("\n  ")}`);
if (missing.length) console.log(`eksik: ${missing.join(" ")}`);
if (extra.length) console.log(`fazla: ${extra.join(" ")}`);
const lonely = [...inbound].filter(([, n]) => n === 0).map(([i]) => i);
if (lonely.length) console.log(`başka sayfadan bağ almayan: ${lonely.join(" ")}`);
console.log(problems.length ? problems.join("\n") : "sorun yok");

if (process.argv.includes("--parity")) {
  const sourceFiles = Object.entries(SOURCE_DIRS).flatMap(([prefix, dir]) =>
    fs
      .readdirSync(path.join(REPO, dir))
      .filter((f) => f.endsWith(".md"))
      .map((f) => `${prefix}/${f.replace(/\.md$/, "")}`),
  );
  let same = 0;
  const diffs = [];
  for (const docId of [...ids, ...sourceFiles]) {
    const text = target(docId);
    if (text === null) continue;
    const a = extractHeadings(text).map((h) => `${h.line}:${h.id}`);
    const b = scanHeadings(text).map((h) => `${h.line}:${h.id}`);
    if (a.join("|") === b.join("|")) same += 1;
    else {
      const onlyA = a.filter((x) => !b.includes(x)).slice(0, 4);
      const onlyB = b.filter((x) => !a.includes(x)).slice(0, 4);
      diffs.push(`${docId}\n  remark: ${onlyA.join(", ")}\n  tarama: ${onlyB.join(", ")}`);
    }
  }
  console.log(`\nbaşlık eşleşmesi: ${same} belge aynı, ${diffs.length} farklı`);
  if (diffs.length) console.log(diffs.join("\n"));
}
