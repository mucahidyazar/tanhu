// Görevler: ana hikâye (mq*), yan (sq*) ve yoldaş (cq*) görevleri tasarım belgelerinden okunur; belgeler yalnız okunur,
// sonuç dosyaların değişme zamanına göre sunucuda önbellekte tutulur. Kaynaklar:
// - act1.md §1 günlerin adları (Gün I, Gösteri … Son Gece), §6 ana görevler ve §7 yan görevler (I. Perde); bayrak
//   sütunları ve §16'nın ant ve bayrak tabloları bayrak süzgecini besler.
// - story.md §1 bölümlerin yayı (perde adı, tarih, soru), §5–§6 Çocukluk ve Yola Çıkış (mq0_*), §7 I'in görev sayısı,
//   §10.2 perde başına sayılar, kalıp, taban XP, ana görev bütçesi ve görev puanı veren görevler, §10.3 yan görev
//   aileleri, §11 II–VI'nın ana zinciri, aile tabloları ve «Seçimler» maddeleri (bayrak süzgeci), §14.4 yoldaşların
//   kişisel görevleri (cq_*).
// - progression.md §1.2: perde başına xpScale.
// - companions.md: adımların düğüm eşiği (`ties` ≥3/6/9), adımın ayrıntılı metni ve yoldaşın sonu.
// - act0-text.md: Önsöz'den sonraki sıra (mq0_* kimliğinin adı ve tarihi).
// - Öbür tasarım ve araştırma belgeleri: görev metnindeki «`settlement.md` §5.6» gibi göndermelerin başlıkları (refs) ve
//   adımı boş görevin başka belgelerde anıldığı yerler (elsewhere, description).
// - content/progress.json: görevin bağlı olduğu Yol Haritası maddeleri ve durumu (kurallar «Durum» bölümünde).
// Bağ (source.href) görevin kendi kimliğine gider: tablo satırının çapasını ve aynı hücrede «;» ile ardından gelen
// görevlerin hücre çapasını markdown-view.tsx aynı kuralla verir (questRowAnchors, questCellAnchors;
// scripts/quests-check.mjs iki kopyayı karşılaştırır); satırı olmayan görev bölüm başlığına bağlanır.
// Bu dosya node:fs kullanır: yalnız sunucuda ve scripts/quests-check.mjs'te çalışır. Göreli içe aktarmalar uzantısızdır,
// betik bunları .ts'e çözer.
import fs from "node:fs";
import path from "node:path";
import { extractHeadings, type Heading, scanHeadings } from "./markdown";
import { fold } from "./text";

// ---- Veri sözleşmesi (arayüz bunu kullanır) ----

export type QuestKind = "main" | "side" | "companion";
export type ActId = "prologue" | "childhood" | "I" | "II" | "III" | "IV" | "V" | "VI";
// detail sözleşmeye ektir: yoldaş adımında companions.md'nin ayrıntılı metni, Çocukluk adımında öteki sütunlar.
export type QuestStep = { text: string; label?: string | null; when?: string | null; threshold?: string | null; detail?: string | null };
export type QuestStatus = "playable" | "in-progress" | "design";
// Sözleşmeye ek: görev metnindeki bölüm göndermesinin bağı. «§8.3» alanın kendi belgesindedir (yoldaş adımının
// ayrıntısı ve sonu companions.md'den gelir), «`settlement.md` §5.6» adı geçen belgededir. label «act1.md §8.3»,
// title bölümün başlığı.
export type QuestRef = { label: string; title: string; href: string };
// Sözleşmeye ek: görevin başka bir belgede anıldığı yer: belge, bölümün başlığı, bağ ve görevi anan cümle ya da hücre.
export type QuestMention = { doc: string; title: string; href: string; text: string };
export type Quest = {
  id: string;
  kind: QuestKind;
  act: ActId;
  titleTr: string;
  titleEn: string | null;
  family: string | null;
  when: string | null;
  trigger: string | null;
  steps: QuestStep[];
  reward: string | null;
  xp: number | null;
  outcome: string | null;
  flags: string[];
  // Sözleşmeye ek: düzyazıda geçen, bayrak sayılmayan yapılı kimlikler (zanaat, buyruk, olay, hava kilidi, beceri…).
  otherIds?: string[];
  related: string[];
  order: number;
  branch: string | null;
  source: { doc: string; title: string; href: string };
  status: QuestStatus;
  raw?: string;
  // Sözleşmeye ekler: yer (II–VI ana zincirinin «Yer» sütunu), görevin geçtiği perdeler (yoldaş görevi birden çok
  // perdeye yayılır; ötekilerde tek perde), görevin bağlı olduğu Yol Haritası maddelerinin kimlikleri (durum bunlardan).
  place?: string | null;
  acts?: ActId[];
  progress?: string[];
  // Sözleşmeye ekler: ödülün verebileceği en çok XP (parça parça ödülde toplam: «3×35 XP» 105, «Direk başına 5 XP …;
  // hepsinde 20 XP» 11 direkle 75; tek ödülde xp'ye eşit, xp yoksa null), metindeki bölüm göndermelerinin bağları,
  // adımı boş görevin başka belgedeki tanım cümlesi («- `sq_red_dog`: …» maddesinin ilk cümlesi) ve başka belgelerde
  // anıldığı yerler (yalnız adımı boş görevde dolar; öbürlerinde boş).
  xpMax?: number | null;
  refs?: QuestRef[];
  description?: string | null;
  elsewhere?: QuestMention[];
  // Sözleşmeye ekler: I. Perde ana zincirinde görevin günü (act1.md §1: «Gün I · Gösteri», «Son Gece»; zincir bununla
  // gruplanır) ve birden çok bölümlü perdede son görevin bölümü (story.md §1: «Köprü ve Yola Çıkış»).
  day?: string | null;
  chapter?: string | null;
};
// question, level, structure sözleşmeye ektir: perdenin sorusu (§1), seviye ve ana zincir kalıbı (§10.2). baseXp, xpScale
// ve xpBudget de ektir: story.md §10.2'nin ortalama tabanı, progression.md §1.2'nin çarpanı ve story.md §10.2'nin ana görev
// bütçesi (taban × görev × xpScale). Belgeden okunamayan sayı null kalır, arayüz onu göstermez.
export type ActInfo = {
  id: ActId;
  tr: string;
  en: string | null;
  years: string | null;
  mainCount: number;
  sideCount: number;
  companionCount: number;
  note?: string | null;
  question?: string | null;
  level?: string | null;
  structure?: string | null;
  baseXp?: number | null;
  xpScale?: number | null;
  xpBudget?: number | null;
};
export type QuestFamily = { name: string; en?: string | null; system: string | null; trigger: string | null; reward: string | null; acts: string | null };
export type QuestData = { quests: Quest[]; acts: ActInfo[]; families: QuestFamily[]; warnings: string[]; generatedAt: string };

// İstemciye giden veri (toClientView): yalnız kartların ve süzgeçlerin kullandığı alanlar; boş alan (null, []) yazılmaz.
// Belgedeki özgün satır (raw) «Ayrıntı»da /quests/raw'dan gelir, sıra (order) listenin kendi sırasıdır.
type ClientQuestKeys = "id" | "kind" | "act" | "titleTr" | "status";
export type ClientQuest = Pick<Quest, ClientQuestKeys> &
  Partial<Omit<Quest, ClientQuestKeys | "raw" | "order" | "source">> & { source: Pick<Quest["source"], "doc" | "href"> };
type ClientActKeys = "id" | "tr" | "mainCount";
export type ClientAct = Pick<ActInfo, ClientActKeys> & Partial<Omit<ActInfo, ClientActKeys | "sideCount" | "companionCount">>;
export type QuestView = { quests: ClientQuest[]; acts: ClientAct[]; families: QuestFamily[] };

export const ACT_ORDER: ActId[] = ["prologue", "childhood", "I", "II", "III", "IV", "V", "VI"];
const KIND_ORDER: QuestKind[] = ["main", "side", "companion"];

// catalog.ts ile aynı kökler (o dosya JSON içe aktardığı için betikten yüklenemez).
const APP_ROOT = process.cwd();
const REPO_ROOT = path.resolve(APP_ROOT, "..");
const DESIGN_DIR = path.join(REPO_ROOT, "docs", "design");
const RESEARCH_DIR = path.join(REPO_ROOT, "docs", "research");
const PROGRESS_FILE = path.join(APP_ROOT, "content", "progress.json");
const LEGACY_FILE = path.join(APP_ROOT, "src", "lib", "legacy-ids.json");
const DOC_NAMES = ["act1", "story", "companions", "act0-text"] as const;
type Group = "design" | "research";
const GROUP_DIRS: Record<Group, string> = { design: DESIGN_DIR, research: RESEARCH_DIR };

// ---- Kimlik kalıpları ----

const QUEST_ID = /^(?:mq|sq|cq)\d*_[a-z0-9_]+$/;
const QUEST_MENTION = /(^|[^A-Za-z0-9_])((?:mq|sq|cq)\d*_[a-z0-9_]+)/g;
// Tablo satırının görev çapası: ilk hücresi ya da ilk hücreden sonraki hücresi `mq_count` gibi bir görev kimliğiyle
// başlayan satır. Karar satırı («| K45 |») kendi çapasını alır. markdown-view.tsx'teki kopyayla aynı kalmalı:
// scripts/quests-check.mjs iki kopyanın kalıplarını ve çapalarını bütün tasarım belgelerinde karşılaştırır.
export const QUEST_ROW = /^\s*\|\s*(?:[^|]*\|\s*)??`((?:mq|sq|cq)\d*_[a-z0-9_]+)`/;
export const DECISION_ROW = /^\s*\|\s*[*_]*K\d{1,3}[*_]*\s*\|/;
// Aynı hücrede «;» ile ardından gelen görev (story.md §11'in aile tabloları). markdown-view.tsx'teki kopyayla aynı kalmalı.
export const QUEST_ITEM = /;\s*`((?:mq|sq|cq)\d*_[a-z0-9_]+)`/g;
const ROMAN = /^(VI|IV|V|I{1,3})(?![A-Za-z])/;
// Yoldaş adımının perde ve dilimi: «II», «IV-A», «VI-d ya da VI-e», «III ya da IV», «V'in …».
const ACT_TOKEN = /^((?:VI|IV|V|I{1,3})(?:-[a-eA-E])?(?:\s+ya da\s+(?:VI|IV|V|I{1,3})(?:-[a-eA-E])?)?)(?![A-Za-z])/;
// I. Perde yan görevinin günü: «I», «III gece», «II–IV», «II akşam».
const DAY_TOKEN = /^((?:VI|IV|V|I{1,3})(?:–(?:VI|IV|V|I{1,3}))?(?:\s+(?:sabah|öğle|akşam|gece))?)(?=\s*(?:,|$))/;
const MONTHS = "Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|Ağustos|Eylül|Ekim|Kasım|Aralık";

// ---- Belge, tablo ve metin yardımcıları ----

interface Row {
  line: number;
  cells: string[];
  raw: string;
}

interface Table {
  line: number;
  header: string[];
  keys: string[];
  rows: Row[];
}

interface SourceDoc {
  name: string;
  group: Group;
  file: string;
  title: string;
  href: string;
  // Gövde satırları (en baştaki # başlık çıkmış, catalog.ts bodyOf); satır numaraları 1'den ve gövdeye göredir.
  lines: string[];
  // Gövde satırını dosya satırına çevirmek için eklenecek sayı (uyarılar dosya satırını yazar).
  offset: number;
  headings: Heading[];
  tables: Table[];
  anchors: Map<number, string>;
  // Hücre çapaları: «satır:sütun» → görev kimliği (questCellAnchors).
  cells: Map<string, string>;
}

function readAliases(): Record<string, string> {
  try {
    return (JSON.parse(fs.readFileSync(LEGACY_FILE, "utf8")) as { sourceNames?: Record<string, string> }).sourceNames ?? {};
  } catch {
    return {};
  }
}

// Okuma ekranı kaynak belgede en baştaki # başlığı gövdeden çıkarır; başlık kimlikleri ve satırlar gövdeye göredir.
const bodyOf = (text: string) => text.replace(/^\s*#\s+.+\n+/, "");
const readText = (file: string) => fs.readFileSync(file, "utf8").replace(/\r\n/g, "\n");

// Adres catalog.ts'inkidir: /docs/source/<grup>/<takma ad ya da dosya adı>. Başlıklar dört kaynak belgede sitenin
// çözümleyicisiyle (extractHeadings), göndermelerin ve anışların öbür belgelerinde hızlı taramayla (scanHeadings, aynı
// kimlikler; scripts/quests-check.mjs her bağın çapasını çözümleyicinin çapalarıyla sınar).
const PRECISE = new Set<string>(DOC_NAMES);

function loadDoc(name: string, group: Group, aliases: Record<string, string>): SourceDoc | null {
  const file = path.join(GROUP_DIRS[group], `${name}.md`);
  if (!fs.existsSync(file)) return null;
  const text = readText(file);
  const body = bodyOf(text);
  const lines = body.split("\n");
  const anchors = questRowAnchors(lines);
  return {
    name,
    group,
    file,
    title: text.match(/^#\s+(.+)$/m)?.[1]?.trim() ?? name,
    href: `/docs/source/${group}/${aliases[name] ?? name}`,
    lines,
    offset: text.split("\n").length - lines.length,
    headings: group === "design" && PRECISE.has(name) ? extractHeadings(body) : scanHeadings(body),
    tables: parseTables(lines),
    anchors,
    cells: questCellAnchors(lines, anchors),
  };
}

const listDocs = (group: Group) =>
  fs.existsSync(GROUP_DIRS[group])
    ? fs
        .readdirSync(GROUP_DIRS[group])
        .filter((f) => f.endsWith(".md"))
        .sort()
        .map((f) => f.slice(0, -3))
    : [];

// Derleme boyunca belgeleri bir kez okur: önce tasarım, yoksa araştırma belgesi («`ses-tasarimi.md` §12»).
interface Library {
  get(name: string, group?: Group): SourceDoc | null;
}

function makeLibrary(aliases: Record<string, string>): Library {
  const cache = new Map<string, SourceDoc | null>();
  return {
    get(name, group) {
      for (const g of group ? [group] : (["design", "research"] as Group[])) {
        const key = `${g}/${name}`;
        if (!cache.has(key)) cache.set(key, loadDoc(name, g, aliases));
        const doc = cache.get(key);
        if (doc) return doc;
      }
      return null;
    },
  };
}

// Tablo satırını hücrelere böler. GFM'deki gibi kaçışsız «|» ayırır (ters tırnak içinde de), «\|» hücrede «|» olur.
function splitRow(line: string): string[] {
  let s = line.trim();
  if (s.startsWith("|")) s = s.slice(1);
  if (s.endsWith("|") && !s.endsWith("\\|")) s = s.slice(0, -1);
  const cells: string[] = [];
  let cur = "";
  for (let k = 0; k < s.length; k++) {
    if (s[k] === "\\" && s[k + 1] === "|") {
      cur += "|";
      k++;
    } else if (s[k] === "|") {
      cells.push(cur.trim());
      cur = "";
    } else cur += s[k];
  }
  cells.push(cur.trim());
  return cells;
}

const isRow = (line: string) => /^\s*\|/.test(line);
const isDelimiter = (line: string) => /^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?\s*$/.test(line);
const headerKey = (cell: string) => fold(cell.replace(/[`*]/g, "")).trim();

// Çit (```) içindeki satırlar atlanır, tıpkı başlık taramasında olduğu gibi.
function eachLine(lines: string[], visit: (line: string, index: number) => void) {
  let fence = "";
  lines.forEach((line, index) => {
    const marker = line.match(/^ {0,3}(`{3,}|~{3,})/);
    if (marker) {
      if (!fence) fence = marker[1][0];
      else if (marker[1][0] === fence) fence = "";
      return;
    }
    if (!fence) visit(line, index);
  });
}

function parseTables(lines: string[]): Table[] {
  const out: Table[] = [];
  let open: Table | null = null;
  eachLine(lines, (line, index) => {
    if (open && isRow(line) && !isDelimiter(line)) {
      open.rows.push({ line: index + 1, cells: splitRow(line), raw: line });
      return;
    }
    if (open && isDelimiter(line) && open.rows.length === 0 && index + 1 === open.line + 1) return;
    open = null;
    if (isRow(line) && isDelimiter(lines[index + 1] ?? "")) {
      const header = splitRow(line);
      open = { line: index + 1, header, keys: header.map(headerKey), rows: [] };
      out.push(open);
    }
  });
  return out;
}

// Karar satırının çapası: «| K65 |» → «k65» (markdown-view.tsx'in tr bileşeni ilk hücresi K65 olan satıra verir).
const decisionAnchor = (line: string) => (DECISION_ROW.test(line) ? `k${line.match(/K(\d{1,3})/)?.[1]}` : null);

// Satır numarası → görev çapası. Kimlik sayfada ilk geçtiği satırda çapa olur (aynı kimlik ikinci satıra verilmez).
export function questRowAnchors(lines: string[]): Map<number, string> {
  const out = new Map<number, string>();
  const seen = new Set<string>();
  eachLine(lines, (line, index) => {
    if (DECISION_ROW.test(line)) return;
    const id = line.match(QUEST_ROW)?.[1];
    if (!id || seen.has(id)) return;
    seen.add(id);
    out.set(index + 1, id);
  });
  return out;
}

// Hücre çapaları: satırın çapası olan görevin hücresinde «;» ile ardından gelen görevler («`sq2_first_yurts` …; `sq2_freed` …;
// `sq2_bellows` …») kendi kimliğiyle hücre içinde görünmez çapa alır. Anahtar «satır:sütun», ters tırnağın yeri (1'den).
// Kimlik sayfada bir satırın çapasıysa ya da önceki bir hücrede çapa aldıysa verilmez. Kopyası markdown-view.tsx'te.
export function questCellAnchors(lines: string[], rows: Map<number, string>): Map<string, string> {
  const out = new Map<string, string>();
  const taken = new Set(rows.values());
  for (const [line, id] of rows) {
    const text = lines[line - 1] ?? "";
    const start = text.indexOf(`\`${id}\``);
    const end = text.indexOf("|", start);
    for (const m of text.slice(start, end < 0 ? undefined : end).matchAll(QUEST_ITEM)) {
      if (taken.has(m[1])) continue;
      taken.add(m[1]);
      out.set(`${line}:${start + (m.index ?? 0) + m[0].indexOf("`") + 1}`, m[1]);
    }
  }
  return out;
}

// Metni ayraçta böler; ters tırnak, parantez, köşeli parantez ve « » içindeki ayraçlar bölmez.
function splitTop(text: string, sep: string, limit = Infinity): string[] {
  const out: string[] = [];
  let depth = 0;
  let quote = 0;
  let code = false;
  let start = 0;
  for (let k = 0; k < text.length; k++) {
    const c = text[k];
    if (c === "`") code = !code;
    if (code || c === "`") continue;
    if (c === "«") quote++;
    else if (c === "»") quote = Math.max(0, quote - 1);
    else if (c === "(" || c === "[") depth++;
    else if (c === ")" || c === "]") depth = Math.max(0, depth - 1);
    else if (depth === 0 && quote === 0 && out.length < limit && text.startsWith(sep, k)) {
      out.push(text.slice(start, k).trim());
      start = k + sep.length;
      k += sep.length - 1;
    }
  }
  out.push(text.slice(start).trim());
  return out.filter((part, i, all) => part !== "" || all.length === 1);
}

// «Sayım / The Count» → ["Sayım", "The Count"]; İngilizcesi yoksa null.
function splitTitle(text: string): [string, string | null] {
  const [tr, en] = splitTop(text.trim(), " / ", 1);
  return [tr ?? "", en?.trim() || null];
}

// Hücrenin başındaki görev kimliği ve ardındaki metin: «`mq_count` Sayım / The Count».
function leadingId(cell: string): { id: string; rest: string } | null {
  const m = cell.match(/^`((?:mq|sq|cq)\d*_[a-z0-9_]+)`\s*(.*)$/);
  return m ? { id: m[1], rest: m[2].trim() } : null;
}

const codesOf = (text: string) => [...text.matchAll(/`([^`]+)`/g)].map((m) => m[1]);

function mentionsOf(text: string): string[] {
  const out: string[] = [];
  for (const m of text.matchAll(QUEST_MENTION)) if (!out.includes(m[2])) out.push(m[2]);
  return out;
}

// Sondaki üst düzey parantez açıklamadır: «Pazar / The Market (ilk kabuk …)» → başlık ve açıklama.
function trailingParen(text: string): { head: string; paren: string | null } {
  const s = text.trim();
  if (!s.endsWith(")")) return { head: s, paren: null };
  let depth = 0;
  for (let k = s.length - 1; k >= 0; k--) {
    if (s[k] === ")") depth++;
    else if (s[k] === "(") depth--;
    if (depth === 0) return k > 0 ? { head: s.slice(0, k).trim(), paren: s.slice(k + 1, -1).trim() } : { head: s, paren: null };
  }
  return { head: s, paren: null };
}

// Ödüldeki ilk XP sayısı (sözleşmenin xp'si): «30 XP» 30, «XP yoktur» 0.
function xpOf(reward: string | null): number | null {
  if (!reward) return null;
  const m = reward.match(/(\d[\d.]*)\s*XP\b/);
  if (m) return Number(m[1].replace(/\./g, ""));
  return /XP\s+(?:yok|vermez)/i.test(reward) ? 0 : null;
}

// Ödülün verebileceği en çok XP: ödüldeki bütün XP tutarlarının toplamı; «3×35 XP» 105, «20 XP (en çok 3)» 60,
// «10 adda 60 XP …; 31'de 60 XP» 120, «Direk başına 5 XP … hepsinde 20 XP» adımlardaki sayıyla («Kalan 11 direk»)
// 11 × 5 + 20 = 75. Birimin sayısı adımlarda ve tetikte yoksa birim bir kez sayılır, onMissing çağrılır.
function xpMaxOf(reward: string | null, context: string, onMissing: (unit: string) => void): number | null {
  if (!reward) return null;
  const parts = [...reward.matchAll(/(?:(\d+)\s*×\s*)?(\d[\d.]*)\s*XP\b(?:\s*\(en çok (\d+)\))?/g)];
  if (!parts.length) return xpOf(reward);
  let total = 0;
  for (const m of parts) {
    let n = Number(m[2].replace(/\./g, ""));
    if (m[1]) n *= Number(m[1]);
    if (m[3]) n *= Number(m[3]);
    const unit = reward.slice(0, m.index ?? 0).match(/([A-Za-zÇĞİÖŞÜçğıöşü]+) başına\s*$/)?.[1];
    if (unit) {
      const count = fold(context).match(new RegExp(`(\\d+)\\s+${fold(unit)}`))?.[1];
      if (count) n *= Number(count);
      else onMissing(unit);
    }
    total += n;
  }
  return total;
}

function step(text: string, extra: Partial<QuestStep> = {}): QuestStep {
  return { text, label: null, when: null, threshold: null, detail: null, ...extra };
}

// Hücreyi «;» ile adımlara böler (belgenin kendi ayracı); boş hücre adımsızdır.
const stepsOf = (cell: string) => splitTop(cell, ";").filter(Boolean).map((text) => step(text));

function headingAt(doc: SourceDoc, line: number, maxDepth = 6): Heading | null {
  let hit: Heading | null = null;
  for (const h of doc.headings) {
    if (h.line > line) break;
    if (h.depth <= maxDepth) hit = h;
  }
  return hit;
}

function sectionEnd(doc: SourceDoc, heading: Heading): number {
  return doc.headings.find((h) => h.line > heading.line && h.depth <= heading.depth)?.line ?? doc.lines.length + 1;
}

// Görevin bağı: görevin satırdaki hücre çapası varsa o (aynı satırda birden çok görev), yoksa satırın çapası, o da yoksa
// satırın bölüm başlığı.
function sourceOf(doc: SourceDoc, line: number, id?: string): Quest["source"] {
  const heading = headingAt(doc, line, 3);
  const cell = id && [...doc.cells].some(([at, cellId]) => cellId === id && at.startsWith(`${line}:`));
  const hash = (cell ? id : doc.anchors.get(line)) ?? heading?.id ?? null;
  return { doc: `${doc.name}.md`, title: heading?.text ?? doc.title, href: hash ? `${doc.href}#${hash}` : doc.href };
}

const where = (doc: SourceDoc, line: number) => `${doc.name}.md satır ${line + doc.offset}`;

// «- **Etiket.** metin» maddesi [from, to) satırları arasında; iki boşlukla girintili devam satırları maddeye katılır.
function labelledBullet(doc: SourceDoc, from: number, to: number, label: string): { line: number; text: string; raw: string } | null {
  for (let i = Math.max(0, from - 1); i < Math.min(to - 1, doc.lines.length); i++) {
    const m = doc.lines[i].match(/^\s*- \*\*([^*]+?)\*\*\s*(.*)$/);
    if (!m || headerKey(m[1].replace(/[.:]\s*$/, "")) !== headerKey(label)) continue;
    const text = [m[2]];
    const raw = [doc.lines[i]];
    for (let j = i + 1; j < doc.lines.length && /^ {2,}\S/.test(doc.lines[j]) && !/^\s*- /.test(doc.lines[j]); j++) {
      text.push(doc.lines[j].trim());
      raw.push(doc.lines[j]);
    }
    return { line: i + 1, text: text.join(" ").trim(), raw: raw.join("\n") };
  }
  return null;
}

// Metni üst düzey «. » ile cümlelere böler (ters tırnaklı `progression.md` cümleyi bölmez); bölünen nokta geri eklenir.
const sentencesOf = (text: string) => splitTop(text, ". ").map((s) => (/[.!?]["»)]?$/.test(s) ? s : `${s}.`));

// ---- Bayraklar ----
// Bayrak ters tırnak içindeki kimliktir. Görev kimliği, belge adı (`x.md`), tuş (`G`), bağ değeri (`ties.*`) ve
// ifade bayrak değildir; `bell_fate=mene` → bell_fate. Sütun kipinde (act1.md «Bayraklar», «Ödül, bayrak», «Seçim»)
// her kimlik alınır. Düzyazı kipinde (II–VI metinleri, yoldaş adımları, Çocukluk'un seçimi) yalnız bilinen bayrak
// alınır (knownFlags); zanaat, buyruk, kürk ve yol kimlikleri (`cr_`, `cmd_`, `fur_`, `r_`) hiçbir zaman bayrak
// sayılmaz. Düzyazıdaki öbür yapılı kimlikler (`four_winds`, `a5_yada`, `cr_bowyer`; harita kimlikleri hariç)
// otherIds'e yazılır: bilgi düşmez, «Bayraklar» altında da görünmez.
const NOT_FLAG = /^(?:cr|cmd|fur|r)_/;
// Yapılı kimlik: alt çizgi, nokta ya da [] taşır (`court_path`, `ledger.*`, `saved[]`); `open`, `kept` gibi değerler değil.
const STRUCTURED = /[_.[]/;

interface FlagFilter {
  known: Set<string>;
  // Harita ve iç harita kimlikleri (story.md «İç haritalar», «Yer» sütunu): otherIds'e de yazılmaz.
  places: Set<string>;
}

function cleanFlag(token: string): string | null {
  const t = token.trim().replace(/\s*(?:=|≥|≤|<|>).*$/, "");
  if (!t || QUEST_ID.test(t) || t === "ties" || t.startsWith("ties.")) return null;
  if (/\.(?:md|json|gd|tscn|js|mjs|ts)$/.test(t) || /^[A-Z]$/.test(t)) return null;
  return /^[A-Za-z_][A-Za-z0-9_]*(?:\[\])?(?:\.(?:[A-Za-z0-9_]+|\*))*$/.test(t) ? t : null;
}

function flagsOf(texts: (string | null | undefined)[], mode: "column" | "prose", filter: FlagFilter): string[] {
  const out: string[] = [];
  for (const text of texts) {
    if (!text) continue;
    for (const token of codesOf(text)) {
      const flag = cleanFlag(token);
      if (!flag || out.includes(flag)) continue;
      if (mode === "prose" && (!filter.known.has(flag) || NOT_FLAG.test(flag))) continue;
      out.push(flag);
    }
  }
  return out;
}

// Düzyazıdaki bayrak olmayan yapılı kimlikler; harita ve yol kimlikleri (`whistle_field`, `r_tanhu_hangai`) hariç.
function otherIdsOf(texts: (string | null | undefined)[], flags: string[], filter: FlagFilter): string[] {
  const out: string[] = [];
  for (const text of texts) {
    if (!text) continue;
    for (const token of codesOf(text)) {
      const id = cleanFlag(token);
      if (!id || out.includes(id) || flags.includes(id) || filter.places.has(id) || id.startsWith("r_") || !STRUCTURED.test(id)) continue;
      out.push(id);
    }
  }
  return out;
}

// Düzyazı alanlarının bayrakları ve öbür kimlikleri birlikte.
function proseIds(texts: (string | null | undefined)[], filter: FlagFilter): { flags: string[]; otherIds: string[] } {
  const flags = flagsOf(texts, "prose", filter);
  return { flags, otherIds: otherIdsOf(texts, flags, filter) };
}

// ---- Ayrıştırma bağlamı ----

interface Ctx {
  quests: Quest[];
  defined: Map<string, string>;
  // Görevin tanım yeri (belge adı ve gövde satırı): başka belgelerdeki anışlar taranırken atlanır.
  origins: Map<string, { doc: string; line: number }>;
  warnings: string[];
  filter: FlagFilter;
}

function define(ctx: Ctx, quest: Quest, doc: SourceDoc, line: number) {
  const at = where(doc, line);
  const first = ctx.defined.get(quest.id);
  if (first) {
    ctx.warnings.push(`Yinelenen görev kimliği \`${quest.id}\` (${at}); ilk tanım esas alındı (${first}).`);
    return;
  }
  ctx.defined.set(quest.id, at);
  ctx.origins.set(quest.id, { doc: doc.name, line });
  ctx.quests.push(quest);
}

type QuestFields = Pick<Quest, "id" | "kind" | "act" | "titleTr" | "source"> & Partial<Quest>;

// Alanlar sözleşmenin sırasıyla yazılır; ilişki, sıra, durum, göndermeler ve başka belgeler sonra doldurulur.
function makeQuest(f: QuestFields): Quest {
  return {
    id: f.id,
    kind: f.kind,
    act: f.act,
    titleTr: f.titleTr || f.id,
    titleEn: f.titleEn ?? null,
    family: f.family ?? null,
    when: f.when ?? null,
    trigger: f.trigger ?? null,
    steps: f.steps ?? [],
    reward: f.reward ?? null,
    xp: f.xp ?? null,
    outcome: f.outcome ?? null,
    flags: f.flags ?? [],
    otherIds: f.otherIds ?? [],
    related: [],
    order: 0,
    branch: f.branch ?? null,
    source: f.source,
    status: "design",
    raw: f.raw,
    place: f.place ?? null,
    acts: f.acts ?? [f.act],
    progress: [],
    xpMax: f.xpMax ?? f.xp ?? null,
    refs: [],
    description: null,
    elsewhere: [],
    day: f.day ?? null,
    chapter: f.chapter ?? null,
  };
}

const col = (table: Table, test: (key: string) => boolean) => table.keys.findIndex(test);
const cellAt = (row: Row, index: number) => (index >= 0 ? (row.cells[index] ?? "").trim() : "");

// ---- Bilinen bayraklar ----

// Bilinen bayraklar dört yerden okunur:
// 1. act1.md'nin bayrak sütunları: «Bayraklar», «Bayrak» (§16), «Ödül, bayrak», «Seçim → yankı» ve antlar tablosunun
//    kimlik sütunu (§16, «id | Kime | …»); her kimlik.
// 2. story.md §11'in «- **Seçimler …**» maddeleri, girintili alt maddeleri ve «Bayraklar: …» satırıyla. Yapılı kimlik
//    her yerde; tek sözcüklük kimlik yalnız liste öğesiyse (V'in «Kamın Alameti, `corner`, `corner_why`»): «`debt_erlik`
//    `open` ya da `ash`», «yanarsa `kept`» gibi değerler bayrak değildir.
// 3. story.md §12 «Son Sayım» tablosunun «Okuduğu» sütunu (`hearth_ember`, `court_path`, `count_keeper`); yapılı kimlik.
// 4. progression.md'nin «II–VI'nın adlı olayları» tablosunun «Olay» sütunu (`muster_law`, `land_counsel`, `nan_fate`);
//    yapılı kimlik.
function knownFlags(act1: SourceDoc | null, story: SourceDoc | null, progression: SourceDoc | null): FlagFilter {
  const known = new Set<string>();
  const places = new Set<string>();
  const add = (set: Set<string>, text: string, test: (flag: string, at: number) => boolean = () => true) => {
    for (const m of text.matchAll(/`([^`]+)`/g)) {
      const flag = cleanFlag(m[1]);
      if (flag && test(flag, m.index ?? 0)) set.add(flag);
    }
  };
  const structured = (flag: string) => STRUCTURED.test(flag);
  const isFlagColumn = (keys: string[], i: number) =>
    keys[i] === "bayraklar" || keys[i] === "bayrak" || keys[i].startsWith("odul, bayrak") || keys[i].startsWith("secim") || (i === 0 && keys[1] === "kime");
  for (const table of act1?.tables ?? []) {
    const flagCols = table.keys.map((_, i) => i).filter((i) => isFlagColumn(table.keys, i));
    for (const row of table.rows) for (const i of flagCols) add(known, cellAt(row, i));
  }
  const lines = story?.lines ?? [];
  lines.forEach((line, i) => {
    if (!/^- \*\*Seçimler\b/.test(line)) return;
    for (let j = i; j === i || (j < lines.length && /^\s{2,}\S/.test(lines[j])); j++) {
      const text = lines[j];
      add(known, text, (flag, at) => {
        if (structured(flag)) return true;
        const before = text.slice(0, at).trimEnd();
        const after = text.slice(at).replace(/^`[^`]+`/, "").trimStart();
        return /(?:^\s*-|[,:;]|\*\*)$/.test(before) && /^(?:$|[,.;:])/.test(after);
      });
    }
  });
  const column = (doc: SourceDoc | null, first: string, key: string) => {
    for (const table of doc?.tables ?? []) {
      const i = col(table, (k) => k === key);
      if (table.keys[0] !== first || i < 0) continue;
      for (const row of table.rows) add(known, cellAt(row, i), structured);
    }
  };
  column(story, "satir", "okudugu");
  column(progression, "perde", "olay");
  // Harita kimlikleri: story.md'nin «İç haritalar» maddeleri ve ana zincirin «Yer» sütunu.
  for (const line of lines) if (/^- \*\*İç haritalar\.\*\*/.test(line)) add(places, line);
  for (const table of story?.tables ?? []) {
    const placeCol = col(table, (k) => k === "yer");
    if (placeCol >= 0 && table.keys.includes("gorev")) for (const row of table.rows) add(places, cellAt(row, placeCol));
  }
  for (const flag of known) places.delete(flag);
  return { known, places };
}

// ---- I. Perde: act1.md §1, §6 ve §7 ----

const NIGHT_KEY = "gece";

// §1'in bölüm tablosu, günlerin adları: «Gün I, Gösteri / The Showing» → I: «Gün I · Gösteri», «Son Gece / …» → gece.
function parseDays(doc: SourceDoc): Map<string, string> {
  const out = new Map<string, string>();
  const table = doc.tables.find((t) => t.keys[0] === "bolum" && t.keys[1]?.startsWith("saat"));
  for (const row of table?.rows ?? []) {
    const [tr] = splitTitle(cellAt(row, 0));
    const day = tr.match(/^Gün (VI|IV|V|I{1,3})(?:,\s*(.+))?$/);
    if (day) out.set(day[1], day[2] ? `Gün ${day[1]} · ${day[2]}` : `Gün ${day[1]}`);
    else if (/^son gece$/i.test(tr)) out.set(NIGHT_KEY, tr);
  }
  return out;
}

// «Gün» sütununda «Gece» Son Gece'dir (§8.5: Gün V gecesinden şafağa).
const isNight = (cell: string) => /^gece$/i.test(cell.trim());

// Zaman, perde numarasıyla karışmasın: «III gece» → «Gün III · gece», «II–IV» → «Gün II–IV», «Gece» → «Son Gece»; tarih
// («Bahar, 11 Nisan MÖ 209») olduğu gibi kalır.
function dayLabel(cell: string, days: Map<string, string>): string {
  if (isNight(cell)) return days.get(NIGHT_KEY) ?? "Son Gece";
  const token = cell.match(DAY_TOKEN)?.[1];
  if (!token) return cell;
  const [range, part] = token.split(/\s+/);
  return part ? `Gün ${range} · ${part}` : `Gün ${range}`;
}

// Zincirin grubu: günün başlığı; gün değilse hücrenin ilk parçası («Bahar, 11 Nisan MÖ 209» → «Bahar»).
function dayGroup(cell: string, days: Map<string, string>): string | null {
  if (isNight(cell)) return days.get(NIGHT_KEY) ?? "Son Gece";
  const roman = cell.match(DAY_TOKEN)?.[1].split(/[\s–]/)[0];
  if (roman) return days.get(roman) ?? `Gün ${roman}`;
  return cell.split(",")[0].trim() || null;
}

// Tetiğin başındaki gün zaman alanına geçer, tetikte yinelenmez: «III gece, `ties.mene` ≥2» → «`ties.mene` ≥2»; tek başına
// günse tetik yoktur. Kalanın ilk harfi büyür («II–III, pazar» → «Pazar»).
function triggerWithoutDay(trigger: string | null): string | null {
  const rest = trigger?.replace(DAY_TOKEN, "").replace(/^\s*,\s*/, "").trim();
  return rest ? rest.charAt(0).toLocaleUpperCase("tr-TR") + rest.slice(1) : null;
}

// §7: «Yan görevler Kışlak'a bağlıdır.» I'in yan görevleri aileye ayrılmaz (tabloda aile sütunu yok); bağlı oldukları yer
// süzgeçte aile gibi bir öbektir. Cümle okunamazsa öbek yazılmaz, görevler «Ailesi yazılmamış» görünür.
function actOneGroup(doc: SourceDoc, warnings: string[]): string | null {
  const heading = doc.headings.find((h) => /yan görevler/i.test(h.text));
  const place = heading ? doc.lines.slice(heading.line, sectionEnd(doc, heading) - 1).join(" ").match(/Yan görevler (\S+?)'[ayeı] bağlıdır/)?.[1] : null;
  if (!place) warnings.push("act1.md §7: yan görevlerin bağlı olduğu yer okunamadı («Yan görevler …'a bağlıdır»); aile öbeği yazılmadı.");
  return place ? `${place} (I. Perde)` : null;
}

function parseActOne(doc: SourceDoc, ctx: Ctx) {
  const act: ActId = (doc.title.match(ROMAN)?.[1] as ActId | undefined) ?? "I";
  const days = parseDays(doc);
  if (!days.size) ctx.warnings.push("act1.md §1: günlerin adları (Bölüm | Saat tablosu) okunamadı; gün başlıkları adsız yazıldı.");
  const group = actOneGroup(doc, ctx.warnings);
  for (const table of doc.tables) {
    const k = table.keys;
    if (!k[0]?.startsWith("id")) continue;
    const isMain = k.includes("bayraklar") && k.some((x) => x.startsWith("dallanma"));
    const isSide = k.includes("adimlar") && k.some((x) => x.startsWith("secim"));
    if (!isMain && !isSide) continue;
    for (const row of table.rows) {
      const head = leadingId(cellAt(row, 0));
      if (!head) {
        ctx.warnings.push(`Görev satırı okunamadı: ilk hücrede görev kimliği yok (${where(doc, row.line)}).`);
        continue;
      }
      const [titleTr, titleEn] = splitTitle(head.rest);
      const xpMissing = (unit: string) =>
        ctx.warnings.push(`\`${head.id}\`: ödül «${unit} başına» XP diyor, adımlarda ${unit.toLocaleLowerCase("tr-TR")} sayısı yok; en çok XP tek ${unit.toLocaleLowerCase("tr-TR")} sayıldı (${where(doc, row.line)}).`);
      if (isMain) {
        const work = cellAt(row, col(table, (x) => x.startsWith("tetik")));
        const flags = cellAt(row, col(table, (x) => x === "bayraklar"));
        const reward = cellAt(row, col(table, (x) => x === "odul")) || null;
        const dayCell = cellAt(row, col(table, (x) => x === "gun"));
        define(
          ctx,
          makeQuest({
            id: head.id,
            kind: "main",
            act,
            titleTr,
            titleEn,
            when: dayCell ? dayLabel(dayCell, days) : null,
            day: dayCell ? dayGroup(dayCell, days) : null,
            steps: stepsOf(work),
            reward,
            xp: xpOf(reward),
            xpMax: xpMaxOf(reward, work, xpMissing),
            outcome: cellAt(row, col(table, (x) => x.startsWith("dallanma"))) || null,
            flags: flagsOf([flags], "column", ctx.filter),
            branch: /\bson görev/i.test(work) ? "Son görev" : null,
            source: sourceOf(doc, row.line),
            raw: row.raw,
          }),
          doc,
          row.line,
        );
      } else {
        const trigger = cellAt(row, col(table, (x) => x === "tetik")) || null;
        const reward = cellAt(row, col(table, (x) => x.startsWith("odul"))) || null;
        const outcome = cellAt(row, col(table, (x) => x.startsWith("secim"))) || null;
        const work = cellAt(row, col(table, (x) => x === "adimlar"));
        define(
          ctx,
          makeQuest({
            id: head.id,
            kind: "side",
            act,
            titleTr,
            titleEn,
            family: group,
            when: trigger?.match(DAY_TOKEN) ? dayLabel(trigger, days) : null,
            trigger: triggerWithoutDay(trigger),
            steps: stepsOf(work),
            reward,
            xp: xpOf(reward),
            xpMax: xpMaxOf(reward, `${work} ${trigger ?? ""}`, xpMissing),
            outcome,
            flags: flagsOf([reward, outcome], "column", ctx.filter),
            source: sourceOf(doc, row.line),
            raw: row.raw,
          }),
          doc,
          row.line,
        );
      }
    }
  }
}

// ---- story.md: sayılar, aileler, bölümler ----

interface ActCounts {
  main: number | null;
  structure: string | null;
  side: number | null;
  sideRaw: string | null;
  level: string | null;
  // «Görev puanı» sütunu: görev puanı veren görevlerin kimlikleri.
  points: string[];
  // «Taban XP» sütunu: görev başına ortalama taban (progression.md §1.2).
  base: number | null;
}

const isCountsTable = (t: Table) => t.keys[0] === "perde" && t.keys.includes("ana gorev") && t.keys.includes("yan gorev");

function parseCounts(doc: SourceDoc): Map<ActId, ActCounts> {
  const out = new Map<ActId, ActCounts>();
  const table = doc.tables.find(isCountsTable);
  if (!table) return out;
  const main = col(table, (k) => k === "ana gorev");
  const side = col(table, (k) => k === "yan gorev");
  const level = col(table, (k) => k === "seviye");
  const points = col(table, (k) => k === "gorev puani");
  const base = col(table, (k) => k === "taban xp");
  for (const row of table.rows) {
    const act = cellAt(row, 0).match(ROMAN)?.[1] as ActId | undefined;
    if (!act) continue;
    const mainCell = cellAt(row, main);
    const sideCell = cellAt(row, side);
    const product = sideCell.match(/(\d+)\D*?×\s*(\d+)/);
    out.set(act, {
      main: mainCell.match(/^\d+/) ? Number(mainCell.match(/^\d+/)![0]) : null,
      structure: mainCell.match(/\(([^)]+)\)/)?.[1]?.trim() ?? null,
      side: product ? Number(product[1]) * Number(product[2]) : sideCell.match(/^\d+$/) ? Number(sideCell) : null,
      sideRaw: sideCell || null,
      level: cellAt(row, level) || null,
      points: mentionsOf(cellAt(row, points)),
      base: /^\d[\d.]*$/.test(cellAt(row, base)) ? Number(cellAt(row, base).replace(/\./g, "")) : null,
    });
  }
  return out;
}

// §10.2, tablonun altındaki cümle: «Taban × görev × `xpScale` ana görev bütçesini verir (…): II 4.305, III 6.490, …; hepsi …».
function parseBudgets(doc: SourceDoc): Map<ActId, number> {
  const out = new Map<ActId, number>();
  const table = doc.tables.find(isCountsTable);
  if (!table) return out;
  const heading = headingAt(doc, table.line, 3);
  const end = heading ? sectionEnd(doc, heading) - 1 : doc.lines.length;
  const list = doc.lines
    .slice(table.line, end)
    .map((line) => line.match(/ana görev bütçesini verir[^:]*:\s*([^;]+)/)?.[1])
    .find(Boolean);
  for (const m of list?.matchAll(/(?:^|[\s,])(VI|IV|V|I{1,3})\s+(\d[\d.]*)/g) ?? []) out.set(m[1] as ActId, Number(m[2].replace(/\./g, "")));
  return out;
}

// progression.md §1.2, «`xpScale`» sütunu: «1,75» → 1.75.
function parseScales(doc: SourceDoc | null): Map<ActId, number> {
  const out = new Map<ActId, number>();
  const table = doc?.tables.find((t) => t.keys[0] === "perde" && t.keys.includes("xpscale"));
  if (!table) return out;
  const scale = col(table, (k) => k === "xpscale");
  for (const row of table.rows) {
    const act = cellAt(row, 0).match(ROMAN)?.[1] as ActId | undefined;
    const value = Number(cellAt(row, scale).replace(",", "."));
    if (act && value > 0) out.set(act, value);
  }
  return out;
}

function parseFamilies(doc: SourceDoc): QuestFamily[] {
  const table = doc.tables.find((t) => t.keys[0] === "aile" && t.keys.includes("sistem"));
  if (!table) return [];
  const pick = (row: Row, key: string) => cellAt(row, col(table, (k) => k === key)) || null;
  return table.rows.map((row) => {
    const [name, en] = splitTitle(cellAt(row, 0));
    // «Yoldaş / Companion (K71)»: karar göndermesi addan düşer.
    const strip = (s: string | null) => s?.replace(/\s*\(K\d+[^)]*\)\s*$/, "").trim() || null;
    return { name: strip(name) ?? name, en: strip(en), system: pick(row, "sistem"), trigger: pick(row, "tetik"), reward: pick(row, "odul"), acts: pick(row, "etkin") };
  });
}

// story.md §1 «Bölümlerin yayı»: perde adı, tarih, soru, oyuncunun işi ve bölümün son görevi.
interface Arc {
  act: ActId;
  title: string;
  tr: string;
  en: string | null;
  years: string | null;
  question: string | null;
  note: string | null;
  finale: string;
}

function normalizeYears(text: string): string | null {
  const parts = text.split(/;\s*/).filter(Boolean);
  // Son parça yaşsa düşer: «2–7 Aralık 210; Ev 11 Nisan 209; 24».
  if (parts.length > 1 && /^\d{1,2}(?:–\d{1,2})?$/.test(parts[parts.length - 1])) parts.pop();
  let out = parts.join("; ").replace(new RegExp(`(\\d{1,2}(?:–\\d{1,2})? (?:${MONTHS})) (\\d{3})\\b`, "g"), "$1 MÖ $2");
  if (!out.includes("MÖ") && /^\d{3}/.test(out)) out = `MÖ ${out}`;
  return out || null;
}

function parseArcs(doc: SourceDoc): Arc[] {
  const table = doc.tables.find((t) => t.keys[0] === "bolum" && t.keys.includes("son gorev"));
  if (!table) return [];
  const out: Arc[] = [];
  for (const row of table.rows) {
    const title = cellAt(row, 0);
    const key = headerKey(title);
    const roman = title.match(ROMAN)?.[1] as ActId | undefined;
    const act: ActId | null = key.startsWith("onsoz") ? "prologue" : key.startsWith("cocukluk") || key.startsWith("kopru") ? "childhood" : roman ?? null;
    if (!act) continue;
    let [tr, en] = splitTitle(title);
    if (roman) tr = tr.replace(ROMAN, `${roman}. Perde`);
    out.push({
      act,
      title,
      tr,
      en,
      years: normalizeYears(cellAt(row, col(table, (k) => k.startsWith("tarih")))),
      question: cellAt(row, col(table, (k) => k === "soru")) || null,
      note: cellAt(row, col(table, (k) => k === "oyuncu")) || null,
      finale: cellAt(row, col(table, (k) => k === "son gorev")),
    });
  }
  return out;
}

// ---- Çocukluk ve Yola Çıkış (mq0_*) ----
// Kimliğin adı ve tarihi satır içi tanımdan gelir: «**Yola Çıkış** (`mq0_depart`, 15 Aralık MÖ 213, …)» ya da
// «Çocukluk «Koyun Sırtında» (`mq0_sheep`, 22 Eylül MÖ 228, …)». Tanımın yeri story.md'de adı taşıyan başlıktır
// (§5 «Koyun Sırtında»), başlık yoksa story.md'deki satır içi tanımın kendisi (§6); adımlar oradaki «Adım» tablosudur.
const INLINE_DEF = new RegExp(
  "(?:\\*\\*([^*]+?)\\*\\*|([A-ZÇĞİÖŞÜ][^\\s(«»→.;:]*(?:\\s+[A-ZÇĞİÖŞÜ][^\\s(«»→.;:]*)*)(?:\\s+«([^»]+)»)?)\\s*\\(`(mq0_[a-z0-9_]+)`,\\s*([^,)]+)",
  "g",
);

function parseChildhood(story: SourceDoc, others: SourceDoc[], arcs: Arc[], ctx: Ctx) {
  const defs = new Map<string, { title: string; when: string; doc: SourceDoc; line: number }>();
  for (const doc of [story, ...others]) {
    eachLine(doc.lines, (line, index) => {
      for (const m of line.matchAll(INLINE_DEF)) {
        const id = m[4];
        if (!defs.has(id)) defs.set(id, { title: (m[3] ?? m[1] ?? m[2] ?? "").trim(), when: m[5].trim(), doc, line: index + 1 });
      }
    });
  }
  // Tanımın yeri: belge, satır ve bölümün sonu (adım tablosu ve seçim maddesi bu aralıkta aranır).
  const found: { id: string; doc: SourceDoc; line: number; end: number; def: { title: string; when: string } }[] = [];
  for (const [id, def] of defs) {
    const heading = story.headings.find((h) => h.text.includes(`«${def.title}»`) || h.text.endsWith(` ${def.title}`));
    if (heading) {
      found.push({ id, doc: story, line: heading.line, end: sectionEnd(story, heading), def });
      continue;
    }
    if (def.doc === story) {
      const parent = headingAt(story, def.line, 3);
      found.push({ id, doc: story, line: def.line, end: parent ? sectionEnd(story, parent) : story.lines.length + 1, def });
      continue;
    }
    ctx.warnings.push(`\`${id}\` için story.md'de bölüm bulunamadı; yalnız ${def.doc.name}.md'deki satır içi tanım okundu.`);
    found.push({ id, doc: def.doc, line: def.line, end: def.line + 1, def });
  }
  found.sort((a, b) => Number(a.doc !== story) - Number(b.doc !== story) || a.line - b.line);
  for (const { id, doc, line, end, def } of found) {
    const table = doc.tables.find((t) => t.line > line && t.line < end && t.keys[0] === "adim");
    const steps: QuestStep[] = [];
    if (table) {
      const text = col(table, (k) => k === "ne olur");
      const when = col(table, (k) => k === "sure");
      for (const row of table.rows) {
        const detail = table.header
          .map((h, i) => (i === 0 || i === text || i === when || !cellAt(row, i) ? null : `${h}: ${cellAt(row, i)}`))
          .filter(Boolean)
          .join(" · ");
        steps.push(step(cellAt(row, text), { label: cellAt(row, 0) || null, when: cellAt(row, when) || null, detail: detail || null }));
      }
    }
    const arc = arcs.find((a) => a.finale.startsWith(`\`${id}\``));
    const [arcTr, arcEn] = arc ? splitTitle(arc.title) : ["", null];
    const choice = labelledBullet(doc, line, end, "Küçük seçim");
    const head = doc.lines[line - 1] ?? "";
    define(
      ctx,
      makeQuest({
        id,
        kind: "main",
        act: "childhood",
        titleTr: def.title,
        titleEn: arcTr.includes(def.title) ? arcEn : null,
        when: def.when,
        steps,
        outcome: choice?.text ?? null,
        ...proseIds([choice?.text], ctx.filter),
        branch: arc ? "Son görev" : null,
        chapter: arcTr || null,
        source: sourceOf(doc, line),
        raw: [head, ...(table ? [doc.lines[table.line - 1], ...table.rows.map((r) => r.raw)] : [])].join("\n"),
      }),
      doc,
      line,
    );
  }
}

// ---- II–VI: §11'in ana zinciri ve aile tabloları ----

function actOfTable(doc: SourceDoc, table: Table): ActId | null {
  for (let i = doc.headings.length - 1; i >= 0; i--) {
    const h = doc.headings[i];
    if (h.line > table.line || h.depth > 3) continue;
    const m = h.text.match(/(?:^|\s)(VI|IV|V|I{1,3})\. Perde\b/);
    return m ? (m[1] as ActId) : null;
  }
  return null;
}

// Kalıp «4 + 3×2 + 2»: açılış, kol sayısı × kol başına görev, kapanış (sonuncusu son görev).
function parseStructure(text: string | null) {
  const m = text?.match(/(\d+)\s*\+\s*(\d+)\s*×\s*(\d+)\s*\+\s*(\d+)/);
  return m ? { open: Number(m[1]), branches: Number(m[2]), per: Number(m[3]), close: Number(m[4]) } : null;
}

function parseActMain(doc: SourceDoc, table: Table, act: ActId, counts: ActCounts | undefined, ctx: Ctx) {
  const idCol = col(table, (k) => k === "gorev");
  const titleCol = col(table, (k) => k === "tr / en");
  const whenCol = col(table, (k) => k === "gun");
  const placeCol = col(table, (k) => k === "yer");
  const textCol = col(table, (k) => k === "ne olur");
  const shape = parseStructure(counts?.structure ?? null);
  const n = table.rows.length;
  const fits = shape && shape.open + shape.branches * shape.per + shape.close === n;
  if (shape && !fits) ctx.warnings.push(`${act}: kalıp «${counts?.structure}» ${shape.open + shape.branches * shape.per + shape.close} görev ister, tabloda ${n} satır var; bölüm adları yalnız «Kol» işaretinden okundu.`);
  const end = headingAt(doc, table.line, 3);
  const finale = labelledBullet(doc, table.rows[n - 1]?.line ?? table.line, end ? sectionEnd(doc, end) : doc.lines.length + 1, "Son görev ve bitiş");
  const perBranch = new Map<string, number>();
  let branchLabel: string | null = null;
  table.rows.forEach((row, i) => {
    const head = leadingId(cellAt(row, idCol));
    if (!head) {
      ctx.warnings.push(`Görev satırı okunamadı: «Görev» hücresinde kimlik yok (${where(doc, row.line)}).`);
      return;
    }
    const [titleTr, titleEn] = splitTitle(cellAt(row, titleCol));
    let text = cellAt(row, textCol);
    const marker = text.match(/^Kol ([A-Z])\.\s*/);
    if (marker) {
      branchLabel = `Kol ${marker[1]}`;
      text = text.slice(marker[0].length);
    }
    let branch: string | null = null;
    if (fits && shape) {
      const branchEnd = shape.open + shape.branches * shape.per;
      if (i < shape.open) branch = "Açılış";
      else if (i < branchEnd) branch = branchLabel ?? "Kol";
      else branch = i === n - 1 ? "Son görev" : "Kapanış";
      if (marker && (i < shape.open || i >= branchEnd)) ctx.warnings.push(`${act}: \`${head.id}\` «Kol ${marker[1]}» diyor ama kalıba göre kol bölgesinde değil (${where(doc, row.line)}).`);
      if (branch.startsWith("Kol")) perBranch.set(branch, (perBranch.get(branch) ?? 0) + 1);
    } else {
      branch = marker ? branchLabel : /^son görev$/i.test(text) ? "Son görev" : null;
    }
    const isFinale = /^son görev$/i.test(text);
    if (isFinale && i !== n - 1) ctx.warnings.push(`${act}: \`${head.id}\` «Son görev» diyor ama zincirin son satırı değil (${where(doc, row.line)}).`);
    const steps = isFinale && finale ? [step(finale.text, { label: "Son görev ve bitiş" })] : text ? [step(text)] : [];
    define(
      ctx,
      makeQuest({
        id: head.id,
        kind: "main",
        act,
        titleTr,
        titleEn,
        when: cellAt(row, whenCol) || null,
        steps,
        ...proseIds(steps.map((s) => s.text), ctx.filter),
        branch,
        source: sourceOf(doc, row.line),
        raw: isFinale && finale ? `${row.raw}\n${finale.raw}` : row.raw,
        place: cellAt(row, placeCol) || null,
      }),
      doc,
      row.line,
    );
  });
  if (fits && shape) {
    for (const [label, count] of perBranch) {
      if (count !== shape.per) ctx.warnings.push(`${act}: ${label} ${count} görev, kalıp kol başına ${shape.per} diyor.`);
    }
  }
}

function parseActSide(doc: SourceDoc, table: Table, act: ActId, ctx: Ctx) {
  const listCol = col(table, (k) => k === "gorevler");
  for (const row of table.rows) {
    const family = cellAt(row, 0) || null;
    for (const item of splitTop(cellAt(row, listCol), ";")) {
      const head = leadingId(item);
      if (!head) {
        ctx.warnings.push(`Yan görev öğesi okunamadı: «${item.slice(0, 40)}» (${where(doc, row.line)}).`);
        continue;
      }
      const { head: title, paren } = trailingParen(head.rest);
      const [titleTr, titleEn] = splitTitle(title);
      define(
        ctx,
        makeQuest({
          id: head.id,
          kind: "side",
          act,
          titleTr,
          titleEn,
          family,
          steps: paren ? [step(paren)] : [],
          ...proseIds([paren], ctx.filter),
          source: sourceOf(doc, row.line, head.id),
          raw: item,
        }),
        doc,
        row.line,
      );
    }
  }
}

// ---- Yoldaş görevleri: story.md §14.4 ve companions.md ----

// companions.md: «Adım n, n. düğümü ister (§4.3: 1. adım `ties` ≥3, 2. adım ≥6, 3. adım ≥9)»; yoksa §4.3'ün tablosu.
function stepThresholds(doc: SourceDoc | null): Map<number, string> {
  const out = new Map<number, string>();
  if (!doc) return out;
  eachLine(doc.lines, (line) => {
    for (const m of line.matchAll(/(\d)\. adım (?:`ties` )?≥\s*(\d+)/g)) if (!out.has(Number(m[1]))) out.set(Number(m[1]), `\`ties\` ≥${m[2]}`);
  });
  if (out.size) return out;
  const table = doc.tables.find((t) => t.keys[0] === "dugum" && t.keys.includes("ties"));
  for (const row of table?.rows ?? []) {
    const n = row.raw.match(/adım(?:ı)? (\d)/)?.[1];
    const low = cellAt(row, 1).match(/(\d+)/)?.[1];
    if (n && low) out.set(Number(n), `\`ties\` ≥${low}`);
  }
  return out;
}

// companions.md §1.3: «**Kişisel görev «…»** (`cq_x`)… 1) … 2) … 3) …» ve aynı kişinin «**Sonu.**» maddesi.
function companionDetails(doc: SourceDoc | null): Map<string, { steps: string[]; ending: string | null; line: number }> {
  const out = new Map<string, { steps: string[]; ending: string | null; line: number }>();
  if (!doc) return out;
  doc.lines.forEach((line, index) => {
    const m = line.match(/^- \*\*Kişisel görev «[^»]*»\*\* \(`(cq_[a-z0-9_]+)`\)(.*)$/);
    if (!m) return;
    const rest = m[2];
    const steps: string[] = [];
    let from = 0;
    for (let n = 1; n <= 9; n++) {
      const re = new RegExp(`(?:^|\\s)${n}\\)\\s`, "g");
      re.lastIndex = from;
      const hit = re.exec(rest);
      if (!hit) break;
      if (n > 1) steps[n - 2] = rest.slice(from, hit.index).trim();
      from = hit.index + hit[0].length;
    }
    if (from > 0) steps.push(rest.slice(from).trim());
    let ending: string | null = null;
    for (let j = index + 1; j < doc.lines.length && !/^\*\*|^#/.test(doc.lines[j]); j++) {
      const end = doc.lines[j].match(/^- \*\*Sonu\.\*\*\s*(.*)$/);
      if (end) {
        ending = end[1].trim();
        break;
      }
    }
    out.set(m[1], { steps, ending, line: index + 1 });
  });
  return out;
}

function parseCompanions(story: SourceDoc, companions: SourceDoc | null, ctx: Ctx) {
  const table = story.tables.find((t) => t.keys[0] === "gorev" && t.keys.includes("yoldas") && t.keys.some((k) => /^\d\. adim/.test(k)));
  if (!table) {
    ctx.warnings.push("story.md'de yoldaş görevleri tablosu (Görev | Yoldaş | TR / EN | 1. adım …) bulunamadı.");
    return;
  }
  const heading = headingAt(story, table.line, 3);
  const intro = heading ? story.lines.slice(heading.line, table.line - 1).join(" ") : "";
  const reward = sentencesOf(intro).find((s) => /Adım ödülü/.test(s)) ?? null;
  const thresholds = stepThresholds(companions);
  const details = companionDetails(companions);
  const stepCols = table.keys.map((k, i) => (/^\d\. adim/.test(k) ? i : -1)).filter((i) => i >= 0);
  // Adımın perdesi: önekteki perde («IV-A», «III ya da IV»), yoksa önekteki ana görevin perdesi (`mq4_dailin_ordos`).
  const actOfStep = (when: string | null): { token: string | null; act: ActId | null; all: ActId[] } => {
    const token = when?.match(ACT_TOKEN)?.[1] ?? null;
    if (token) {
      const all = [...token.matchAll(/(VI|IV|V|I{1,3})(?![A-Za-z])/g)].map((m) => m[1] as ActId);
      return { token, act: all[0] ?? null, all };
    }
    const quest = mentionsOf(when ?? "")
      .map((id) => ctx.quests.find((q) => q.id === id))
      .find(Boolean);
    return { token: quest ? quest.act : null, act: quest?.act ?? null, all: quest ? [quest.act] : [] };
  };
  for (const row of table.rows) {
    const head = leadingId(cellAt(row, 0));
    if (!head) {
      ctx.warnings.push(`Yoldaş görevi satırı okunamadı (${where(story, row.line)}).`);
      continue;
    }
    const who = cellAt(row, col(table, (k) => k === "yoldas"));
    const { head: companion, paren: condition } = trailingParen(who);
    const [titleTr, titleEn] = splitTitle(cellAt(row, col(table, (k) => k === "tr / en")));
    const detail = details.get(head.id);
    if (companions && !detail) ctx.warnings.push(`\`${head.id}\`: companions.md'de «Kişisel görev» maddesi bulunamadı.`);
    const steps: QuestStep[] = [];
    const tokens: { token: string | null; act: ActId | null; all: ActId[] }[] = [];
    stepCols.forEach((ci, n) => {
      const cell = cellAt(row, ci);
      const [prefix, ...rest] = splitTop(cell, ": ", 1);
      const timed = rest.length > 0 && (ROMAN.test(prefix) || /^`(?:mq|sq|cq)\d*_/.test(prefix));
      const when = timed ? prefix : null;
      tokens.push(actOfStep(when));
      steps.push(
        step(timed ? rest.join(": ") : cell, {
          label: table.header[ci],
          when,
          threshold: thresholds.get(n + 1) ?? null,
          detail: detail?.steps[n] ?? null,
        }),
      );
    });
    const first = tokens.find((t) => t.act);
    const last = [...tokens].reverse().find((t) => t.act);
    const acts = ACT_ORDER.filter((a) => tokens.some((t) => t.all.includes(a)));
    if (!first?.act) ctx.warnings.push(`\`${head.id}\`: adımlardan perde okunamadı; II sayıldı (${where(story, row.line)}).`);
    define(
      ctx,
      makeQuest({
        id: head.id,
        kind: "companion",
        act: first?.act ?? "II",
        titleTr,
        titleEn,
        family: companion || null,
        when: first?.token ? (last?.token && last.token !== first.token ? `${first.token} – ${last.token}` : first.token) : null,
        trigger: condition,
        steps,
        reward,
        xp: xpOf(reward),
        outcome: detail?.ending ?? null,
        ...proseIds(steps.flatMap((s) => [s.text, s.detail]), ctx.filter),
        source: sourceOf(story, row.line),
        raw: row.raw,
        acts: acts.length ? acts : undefined,
      }),
      story,
      row.line,
    );
  }
}

// ---- Görev puanı: story.md §10.2 ----
// II–VI'da görev başına ödül sütunu yoktur; «Görev puanı» sütununun görevleri birer beceri puanı verir
// (`progression.md` §1.4: perdenin görev puanı sütundaki görev sayısıdır). I'de aynı ödül act1.md'nin «+1 beceri»sidir.
const QUEST_POINT = "Görev puanı (+1 beceri; `story.md` §10.2)";

function applyQuestPoints(quests: Quest[], counts: Map<ActId, ActCounts>, warnings: string[]) {
  for (const [act, c] of counts) {
    for (const id of c.points) {
      const q = quests.find((x) => x.id === id);
      if (!q) {
        warnings.push(`${act}: story.md §10.2 «Görev puanı» sütunu tanımsız görevi anıyor: \`${id}\`.`);
        continue;
      }
      if (q.act !== act) warnings.push(`\`${id}\`: story.md §10.2 onu ${act}'in görev puanı sayıyor, görev ${q.act} perdesinde.`);
      if (!q.reward?.includes("Görev puanı")) q.reward = q.reward ? `${q.reward}; ${QUEST_POINT}` : QUEST_POINT;
    }
  }
}

// ---- Bölüm göndermeleri ----
// «§8.3», «`settlement.md` §5.6», «`story.md` §8, §14.2». Belge adı yazılmamışsa önceki göndermenin belgesi (yalnız
// virgül ya da «ve» ile ayrılmışsa), yoksa alanın kendi belgesi. Bölüm, numarası tutan başlıktır («8.3 Toy ve
// baskın …», «10. Kovalamaca …»). Belge önce docs/design'da, yoksa docs/research'te aranır.
const SECTION_REF = /(?:`([a-z0-9][a-z0-9-]*)\.md`\s*|\b([a-z0-9][a-z0-9-]*)\.md\s+)?§\s?(\d+(?:\.\d+)*)/g;
const headingNumber = (text: string) => text.match(/^(\d+(?:\.\d+)*)\.?(?=\s|$)/)?.[1] ?? null;

function refsOf(texts: { text: string | null | undefined; doc: string }[], lib: Library, onMissing: (label: string) => void): QuestRef[] {
  const out: QuestRef[] = [];
  for (const { text, doc } of texts) {
    if (!text) continue;
    let last: { doc: string; end: number } | null = null;
    for (const m of text.matchAll(SECTION_REF)) {
      const start = m.index ?? 0;
      const named: string | null = m[1] ?? m[2] ?? null;
      const carried: string | null = !named && last && /^\s*(?:,|ve)?\s*$/.test(text.slice(last.end, start)) ? last.doc : null;
      const name: string = named ?? carried ?? doc;
      last = { doc: name, end: start + m[0].length };
      const label = `${name}.md §${m[3]}`;
      const target = lib.get(name);
      const heading = target?.headings.find((h) => headingNumber(h.text) === m[3]);
      if (!target || !heading) {
        onMissing(label);
        continue;
      }
      const href = `${target.href}#${heading.id}`;
      if (!out.some((r) => r.href === href)) out.push({ label, title: heading.text, href });
    }
  }
  return out;
}

// Alanların belgesi: görevin kendi belgesi; yoldaş adımının ayrıntısı ve yoldaşın sonu companions.md'dendir.
function refTexts(q: Quest): { text: string | null | undefined; doc: string }[] {
  const own = q.source.doc.replace(/\.md$/, "");
  const fromCompanions = q.kind === "companion" ? "companions" : own;
  return [
    { text: q.when, doc: own },
    { text: q.place, doc: own },
    { text: q.trigger, doc: own },
    ...q.steps.flatMap((s) => [
      { text: s.when, doc: own },
      { text: s.text, doc: own },
      { text: s.detail, doc: fromCompanions },
    ]),
    { text: q.reward, doc: own },
    { text: q.outcome, doc: fromCompanions },
  ];
}

// ---- Başka belgelerde: adımı boş görevler ----
// story.md'nin aile tablosunda yalnız adı yazılı görevin (adımı boş) başka yerlerdeki anışları: docs/design'ın bütün
// belgeleri taranır, görevin kendi tanım satırı atlanır. Tablo satırında görevi anan hücre (kısa ilk hücresiyle),
// düzyazıda görevi anan cümle alınır. «- `sq_red_dog`: …» biçimli madde tanımdır: ilk cümlesi description olur.
const MENTION_LIMIT = 280;

function clip(text: string): string {
  if (text.length <= MENTION_LIMIT) return text;
  let cut = text.slice(0, MENTION_LIMIT - 1);
  cut = cut.slice(0, Math.max(cut.lastIndexOf(" "), 1));
  // Kesik bir ters tırnak çifti bırakılmaz.
  if ((cut.match(/`/g) ?? []).length % 2 === 1) cut = cut.slice(0, cut.lastIndexOf("`")).trimEnd();
  return `${cut}…`;
}

// Sığan en geniş parça: bütün metin, yoksa görevi anan cümle, yoksa o cümlenin «;» ile ayrılan bölümü, yoksa kırpılmışı.
function excerpt(text: string, has: (t: string) => boolean): string {
  if (text.length <= MENTION_LIMIT) return text;
  const sentence = sentencesOf(text).find(has) ?? text;
  if (sentence.length <= MENTION_LIMIT) return sentence;
  return clip(splitTop(sentence, "; ").find(has) ?? sentence);
}

function mentionText(line: string, id: string): string {
  const has = (t: string) => mentionsOf(t).includes(id);
  if (isRow(line)) {
    const cells = splitRow(line);
    const i = cells.findIndex(has);
    const cell = excerpt(cells[i] ?? line.trim(), has);
    return i > 0 && cells[0] && cells[0].length <= 60 ? `${cells[0]} — ${cell}` : cell;
  }
  return excerpt(line.trim().replace(/^(?:[-*+]|\d+\.)\s+/, "").replace(/^>\s*/, ""), has);
}

function fillElsewhere(quests: Quest[], lib: Library, origins: Map<string, { doc: string; line: number }>) {
  const bare = quests.filter((q) => q.steps.length === 0);
  if (!bare.length) return;
  for (const name of listDocs("design")) {
    const text = readText(path.join(DESIGN_DIR, `${name}.md`));
    const here = bare.filter((q) => text.includes(q.id));
    if (!here.length) continue;
    const doc = lib.get(name, "design");
    if (!doc) continue;
    eachLine(doc.lines, (line, index) => {
      const ids = mentionsOf(line);
      for (const q of here) {
        if (!ids.includes(q.id)) continue;
        const origin = origins.get(q.id);
        if (origin && origin.doc === doc.name && origin.line === index + 1) continue;
        // Tanım maddesinin ilk cümlesi description olur, anış olarak yinelenmez.
        const definition = line.match(new RegExp(`^\\s*[-*]\\s+\`${q.id}\`\\s*:\\s*(.+)$`));
        if (definition && !q.description) {
          q.description = sentencesOf(definition[1])[0] ?? null;
          continue;
        }
        const heading = headingAt(doc, index + 1);
        // Satırın çapası: görev satırı kimliği, karar satırı «k65», yoksa bölüm başlığı.
        const hash = doc.anchors.get(index + 1) ?? decisionAnchor(line) ?? heading?.id ?? null;
        q.elsewhere?.push({ doc: `${doc.name}.md`, title: heading?.text ?? doc.title, href: hash ? `${doc.href}#${hash}` : doc.href, text: mentionText(line, q.id) });
      }
    });
  }
}

// Adımı boş görevin göndermeleri: anışlarındaki bölüm göndermeleri (anışın kendi belgesinde) ve ailesinin sistemi (story.md
// §10.3: «Av döngüsü (`fauna.md` §4)»). Kartta başka metin olmadığından görevi anlatan bölüme buradan gidilir.
function fillBareRefs(quests: Quest[], families: QuestFamily[], lib: Library, warnings: string[]) {
  for (const q of quests) {
    if (q.steps.length) continue;
    const family = families.find((f) => fold(f.name) === fold(q.family ?? ""));
    const texts = [...(q.elsewhere ?? []).map((e) => ({ text: e.text, doc: e.doc.replace(/\.md$/, "") })), { text: family?.system, doc: "story" }];
    q.refs = refsOf(texts, lib, (label) => warnings.push(`Bölüm göndermesi çözülemedi: «${label}» (\`${q.id}\` anışı ya da ailesi); belge ya da o numaralı başlık yok.`));
  }
}

// ---- Durum: content/progress.json ----
// Görev ile Yol Haritası maddesi arasındaki bağ yalnız maddenin başlığından kurulur; not, yol ve geçmiş sayılmaz (oradaki
// anış çoğu kez yan anıştır: «army» maddesinin notundaki `mq3_east` toplu savaşın ilk sahnesini söyler, görevi yapmaz).
// Bağın dört kaynağı:
// 1. Başlıktaki ters tırnaklı görev kimliği; «`mq_herd_school`'dan `mq_last_meal`'e» aralığı belge sırasıyla açılır.
// 2. «II. Perde ana zinciri» diye başlayan madde o perdenin bütün ana görevlerini, «IV'ün yoldaşları» diye başlayan
//    madde adımı o perdede olan bütün yoldaş görevlerini kapsar.
// 3. Görevin Türkçe adı: yalnız tasarımı bir hikâye sayfası (/docs/story/…) olan maddede, maddenin perdesindeki ana ve
//    yan görevlerde, ad büyük küçük harfiyle tam ve liste ayraçlarıyla («:», «,», «;», «ve», parantez) çevrili geçerse.
//    «Av», «Toy», «Elçi» gibi kısa adlar böylece yalnız kendi perdesinde ve liste öğesi olarak eşleşir («Av ailesi»,
//    «Dailin Sayımı» eşleşmez); aynı perdede aynı adı taşıyan iki görevin adı bağ kurmaz. Yapı ve sistem maddeleri
//    (Divan, Kuyu, Kara Boran havası) hikâye sayfasına bağlı olmadığından görevle ad üzerinden eşleşmez.
// 4. PROGRESS_LINKS: başka adla ya da çekimli anılan görevler (add), adı geçse de maddenin işi olmayanlar (skip).
// Durum: bağlı maddelerin hepsi bitti ise «playable», biri bitti ya da sürüyor ise «in-progress», bağı yoksa ya da
// hiçbiri başlamadıysa «design». Durum yaklaşıktır: madde görevin bütün işini kapsamayabilir.
const PROGRESS_LINKS: Record<string, { add?: string[]; skip?: string[] }> = {
  // Sayım, Koyun Sırtında'nın dördüncü adımıdır (story.md §5).
  "childhood-count": { add: ["mq0_sheep"] },
  // «İş Tahtası'ndan Yar Bakışı'na»: İlk Çetele'nin son adımları (Yakve'ye bin, Yar Bakışı; act1.md §6).
  "day1-board-lookout": { add: ["mq_first_tally"] },
  // Tipi prototipi Kara Boran'ın kovalamacasıdır (act1.md §10).
  "tipi-prototype": { add: ["mq_blizzard"] },
  // «Sazlık baskını» Sazlık Yanıyor'dur (act1.md §8.3).
  "big-scenes-crown-raid": { add: ["mq_reeds"] },
  // «Gök Açılır» Gördüm'ün sahnesidir (act1.md §8.6).
  "last-night": { add: ["mq_saw"] },
  // Akış testi görevin işi değildir; «Kara Boran» orada sınanan bölümün adıdır.
  "act1-flow-test": { skip: ["mq_blizzard"] },
  // «Teoman'ın payı» Pay'dır; Köz Kabı, Ocak Yeri seçimi ve ilk yurt Kendi Ocağın'dır (story.md §11.1).
  "act2-opening": { add: ["mq2_allotment", "mq2_own_hearth"] },
  // «kendi atı» Kendi Atı'dır (küçük harfle yazılmış).
  "act2-trials": { add: ["mq2_own_horse"] },
  // `mq2_strung_bow` burada Luhun'un katılış koşuludur.
  "act2-companions": { skip: ["mq2_strung_bow"] },
};

interface ProgressItem {
  id: string;
  phase?: string;
  title?: string;
  status?: string;
  design?: string[];
}

const PHASE_ACTS: Record<string, ActId> = { prologue: "prologue", childhood: "childhood", "act-1": "I", "act-2": "II", "act-3": "III", "act-4": "IV", "act-5": "V", "act-6": "VI" };
const CHAIN_ITEM = /^(VI|IV|V|I{1,3})\. Perde ana zinciri(?=[\s:,;]|$)/;
const PARTY_ITEM = /^(VI|IV|V|I{1,3})'\S* yoldaşları(?=[\s:,;]|$)/;
const RANGE = /`((?:mq|sq|cq)\d*_[a-z0-9_]+)`'[dt][ae]n\s+`((?:mq|sq|cq)\d*_[a-z0-9_]+)`'y?[ae](?![a-zçğıöşü])/g;
const NAME_BEFORE = String.raw`(?:^|[:;,(«]\s*|\sve\s+)`;
const NAME_AFTER = String.raw`(?=$|\s*[:;,)»]|\s+ve\s|\s+\()`;
const escapeRe = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

// «`a`'dan `b`'e»: a ile b aynı perdenin aynı türündeyse aradaki görevler de (belge sırası, iki uç dahil).
function rangeOf(quests: Quest[], from: string, to: string, item: string, warnings: string[]): string[] {
  const a = quests.find((q) => q.id === from);
  const b = quests.find((q) => q.id === to);
  if (!a || !b || a.act !== b.act || a.kind !== b.kind) {
    warnings.push(`Yol Haritası \`${item}\`: «\`${from}\`'dan \`${to}\`'e» aralığı aynı perdenin aynı türünde değil; yalnız iki uç bağlandı.`);
    return [];
  }
  const line = quests.filter((q) => q.act === a.act && q.kind === a.kind);
  const [i, j] = [line.indexOf(a), line.indexOf(b)].sort((x, y) => x - y);
  return line.slice(i, j + 1).map((q) => q.id);
}

// Görev kimliği → bağlı maddeler (progress.json sırasıyla). quests belge sırasındadır (aralık bu sırayla açılır).
function progressLinks(quests: Quest[], warnings: string[]): Map<string, ProgressItem[]> {
  const out = new Map<string, ProgressItem[]>();
  if (!fs.existsSync(PROGRESS_FILE)) return out;
  let data: { phases?: { id: string; act?: string }[]; items?: ProgressItem[] };
  try {
    data = JSON.parse(fs.readFileSync(PROGRESS_FILE, "utf8"));
  } catch (err) {
    warnings.push(`content/progress.json okunamadı: ${(err as Error).message}`);
    return out;
  }
  const byId = new Map(quests.map((q) => [q.id, q]));
  const phaseAct = new Map((data.phases ?? []).map((p) => [p.id, PHASE_ACTS[p.act ?? ""] ?? null]));
  const items = data.items ?? [];
  const itemIds = new Set(items.map((i) => i.id));
  for (const [itemId, fix] of Object.entries(PROGRESS_LINKS)) {
    if (!itemIds.has(itemId)) warnings.push(`Yol Haritası bağ tablosu (quests.ts PROGRESS_LINKS) \`${itemId}\` maddesini anıyor, progress.json'da yok.`);
    for (const id of [...(fix.add ?? []), ...(fix.skip ?? [])]) if (!byId.has(id)) warnings.push(`Yol Haritası bağ tablosu (\`${itemId}\`) tanımsız görevi anıyor: \`${id}\`.`);
  }
  for (const item of items) {
    const title = item.title ?? "";
    const linked = new Set<string>();
    for (const id of mentionsOf(title)) if (byId.has(id)) linked.add(id);
    for (const m of title.matchAll(RANGE)) for (const id of rangeOf(quests, m[1], m[2], item.id, warnings)) linked.add(id);
    const chain = title.match(CHAIN_ITEM)?.[1];
    if (chain) for (const q of quests) if (q.act === chain && q.kind === "main") linked.add(q.id);
    const party = title.match(PARTY_ITEM)?.[1];
    if (party) for (const q of quests) if (q.kind === "companion" && (q.acts ?? [q.act]).includes(party as ActId)) linked.add(q.id);
    const act = phaseAct.get(item.phase ?? "") ?? null;
    if (act && (item.design ?? []).some((h) => h.startsWith("/docs/story/"))) {
      const pool = quests.filter((q) => q.act === act && q.kind !== "companion");
      for (const q of pool) {
        if (pool.some((p) => p !== q && p.titleTr === q.titleTr)) continue;
        if (new RegExp(`${NAME_BEFORE}${escapeRe(q.titleTr)}${NAME_AFTER}`).test(title)) linked.add(q.id);
      }
    }
    const fix = PROGRESS_LINKS[item.id];
    for (const id of fix?.add ?? []) if (byId.has(id)) linked.add(id);
    for (const id of fix?.skip ?? []) linked.delete(id);
    for (const id of linked) out.set(id, [...(out.get(id) ?? []), item]);
  }
  return out;
}

function statusOf(items: ProgressItem[]): QuestStatus {
  if (items.length && items.every((i) => i.status === "bitti")) return "playable";
  if (items.some((i) => i.status === "bitti" || i.status === "suruyor")) return "in-progress";
  return "design";
}

// ---- Derleme ----

function textsOf(q: Quest): string {
  return [q.raw ?? "", q.trigger ?? "", q.outcome ?? "", q.reward ?? "", ...q.steps.flatMap((s) => [s.text, s.when ?? "", s.detail ?? ""])].join("\n");
}

function build(): QuestData {
  const warnings: string[] = [];
  const aliases = readAliases();
  const lib = makeLibrary(aliases);
  const docs = new Map<string, SourceDoc>();
  for (const name of DOC_NAMES) {
    const doc = lib.get(name, "design");
    if (doc) docs.set(name, doc);
    else warnings.push(`docs/design/${name}.md bulunamadı.`);
  }
  const act1 = docs.get("act1") ?? null;
  const story = docs.get("story") ?? null;
  const companions = docs.get("companions") ?? null;
  const ctx: Ctx = { quests: [], defined: new Map(), origins: new Map(), warnings, filter: knownFlags(act1, story, lib.get("progression", "design")) };

  const arcs = story ? parseArcs(story) : [];
  const counts = story ? parseCounts(story) : new Map<ActId, ActCounts>();
  const budgets = story ? parseBudgets(story) : new Map<ActId, number>();
  const scales = parseScales(lib.get("progression", "design"));
  const families = story ? parseFamilies(story) : [];
  if (story) parseChildhood(story, [docs.get("act0-text"), act1].filter((d): d is SourceDoc => Boolean(d)), arcs, ctx);
  if (act1) parseActOne(act1, ctx);
  if (story) {
    for (const table of story.tables) {
      const act = actOfTable(story, table);
      if (!act) continue;
      if (table.keys.includes("gorev") && table.keys.includes("tr / en") && table.keys.includes("ne olur")) parseActMain(story, table, act, counts.get(act), ctx);
      else if (table.keys[0] === "aile" && table.keys[1] === "gorevler") parseActSide(story, table, act, ctx);
    }
    parseCompanions(story, companions, ctx);
  }
  applyQuestPoints(ctx.quests, counts, warnings);

  // İlişkiler: görevin metninde geçen öbür görevler, ardından onu anan görevler (ikisi de var olan kimlikler).
  const ids = new Set(ctx.quests.map((q) => q.id));
  // Belgede anılıp hiçbir tabloda ya da bölümde tanımlanmayan kimlik: yazım hatası ya da eksik satır olabilir.
  for (const doc of docs.values()) {
    const missing = new Map<string, number>();
    eachLine(doc.lines, (line, index) => {
      for (const id of mentionsOf(line)) if (!ids.has(id) && !missing.has(id)) missing.set(id, index + 1);
    });
    for (const [id, line] of missing) warnings.push(`Tanımsız görev kimliği anılıyor: \`${id}\` (${where(doc, line)}).`);
  }
  const own = new Map(ctx.quests.map((q) => [q.id, mentionsOf(textsOf(q)).filter((id) => id !== q.id && ids.has(id))]));
  const back = new Map<string, string[]>();
  for (const q of ctx.quests) for (const id of own.get(q.id) ?? []) back.set(id, [...(back.get(id) ?? []), q.id]);
  const progress = progressLinks(ctx.quests, warnings);
  for (const q of ctx.quests) {
    q.related = [...new Set([...(own.get(q.id) ?? []), ...(back.get(q.id) ?? [])])];
    const items = progress.get(q.id) ?? [];
    q.progress = items.map((i) => i.id);
    q.status = statusOf(items);
    const missing = new Set<string>();
    q.refs = refsOf(refTexts(q), lib, (label) => missing.add(label));
    for (const label of missing) warnings.push(`Bölüm göndermesi çözülemedi: «${label}» (\`${q.id}\`); belge ya da o numaralı başlık yok.`);
  }
  fillElsewhere(ctx.quests, lib, ctx.origins);
  fillBareRefs(ctx.quests, families, lib, warnings);

  // Sıra: perde, tür, belge sırası; order perde ve tür içinde 0'dan.
  const rank = (q: Quest) => ACT_ORDER.indexOf(q.act) * 10 + KIND_ORDER.indexOf(q.kind);
  const quests = ctx.quests.map((q, i) => ({ q, i })).sort((a, b) => rank(a.q) - rank(b.q) || a.i - b.i).map(({ q }) => q);
  const seen = new Map<number, number>();
  for (const q of quests) {
    const n = seen.get(rank(q)) ?? 0;
    q.order = n;
    seen.set(rank(q), n + 1);
  }

  const count = (act: ActId, kind: QuestKind) => quests.filter((q) => q.act === act && q.kind === kind).length;
  checkCounts(quests, counts, story, act1, count, warnings);
  checkBudgets(counts, budgets, scales, count, warnings);

  const acts: ActInfo[] = ACT_ORDER.map((id) => {
    const rows = arcs.filter((a) => a.act === id);
    const [main, ...more] = rows;
    const join = (pick: (a: Arc) => string | null, sep: string) => rows.map(pick).filter(Boolean).join(sep) || null;
    const years = main ? [main.years, ...more.map((a) => (a.years ? `${a.tr} ${a.years}` : null))].filter(Boolean).join("; ") || null : null;
    const c = counts.get(id);
    if (!main) warnings.push(`${id}: story.md §1 «Bölümlerin yayı» tablosunda satırı yok; perde adı kimlikten yazıldı.`);
    return {
      id,
      tr: main?.tr ?? id,
      en: main?.en ?? null,
      years,
      mainCount: count(id, "main"),
      sideCount: count(id, "side"),
      companionCount: count(id, "companion"),
      note: join((a) => a.note, "; "),
      question: join((a) => a.question, " "),
      level: c?.level ?? null,
      structure: c?.structure ?? null,
      baseXp: c?.base ?? null,
      xpScale: scales.get(id) ?? null,
      xpBudget: budgets.get(id) ?? null,
    };
  });

  return { quests, acts, families, warnings, generatedAt: new Date().toISOString() };
}

// Belgelerin verdiği sayılarla karşılaştırma: II–VI §10.2'den, I'in ana görevi story.md §7'den, yoldaş §10.3'ten; I'in
// XP toplamları act1.md §6 (xp) ve §7'den (xpMax: parça parça ödülün en çoğu).
function checkCounts(
  quests: Quest[],
  counts: Map<ActId, ActCounts>,
  story: SourceDoc | null,
  act1: SourceDoc | null,
  count: (act: ActId, kind: QuestKind) => number,
  warnings: string[],
) {
  for (const [act, c] of counts) {
    if (c.main !== null && c.main !== count(act, "main")) warnings.push(`${act}: ${c.main} ana görev bekleniyordu, ${count(act, "main")} bulundu (story.md §10.2).`);
    if (c.side !== null && c.side !== count(act, "side")) warnings.push(`${act}: ${c.side} yan görev bekleniyordu (${c.sideRaw}), ${count(act, "side")} bulundu (story.md §10.2).`);
  }
  if (story) {
    const seven = story.headings.find((h) => /(?:^|\s)I\. Perde\b/.test(h.text));
    const text = seven ? story.lines.slice(seven.line, sectionEnd(story, seven) - 1).join(" ") : "";
    const expected = text.match(/(\d+) ana görev/)?.[1];
    if (expected && Number(expected) !== count("I", "main")) warnings.push(`I: ${expected} ana görev bekleniyordu, ${count("I", "main")} bulundu (story.md §7).`);
    const band = story.lines.join(" ").match(/(\d+) kişisel görev \(`cq_\*`\) × (\d+) adım/);
    if (band) {
      const companions = quests.filter((q) => q.kind === "companion");
      if (companions.length !== Number(band[1])) warnings.push(`Yoldaş: ${band[1]} kişisel görev bekleniyordu, ${companions.length} bulundu (story.md §10.3).`);
      for (const q of companions) if (q.steps.length !== Number(band[2])) warnings.push(`\`${q.id}\`: ${band[2]} adım bekleniyordu, ${q.steps.length} bulundu.`);
    }
  }
  if (act1) {
    const totalOf = (pattern: RegExp) => {
      const h = act1.headings.find((x) => pattern.test(x.text));
      const total = h ? act1.lines.slice(h.line, sectionEnd(act1, h) - 1).join(" ").match(/XP toplamı (\d[\d.]*)/)?.[1] : undefined;
      return total ? Number(total.replace(/\./g, "")) : null;
    };
    const sum = (kind: QuestKind, pick: (q: Quest) => number | null | undefined) => quests.filter((q) => q.act === "I" && q.kind === kind).reduce((s, q) => s + (pick(q) ?? 0), 0);
    const six = totalOf(/ana görevler/i);
    if (six !== null && six !== sum("main", (q) => q.xp)) warnings.push(`I: ana görevlerin XP toplamı ${sum("main", (q) => q.xp)}, act1.md §6 ${six} diyor.`);
    const seven = totalOf(/yan görevler/i);
    if (seven !== null && seven !== sum("side", (q) => q.xpMax)) warnings.push(`I: yan görevlerin en çok XP toplamı ${sum("side", (q) => q.xpMax)}, act1.md §7 ${seven} diyor.`);
  }
  if (count("childhood", "main") === 0) warnings.push("Çocukluk: `mq0_*` görevi bulunamadı (act0-text.md, story.md §5–§6).");
}

// story.md §10.2'nin ana görev bütçesi: her perdede okunur ve taban × görev × xpScale'e (en yakın tam sayı) eşittir.
function checkBudgets(
  counts: Map<ActId, ActCounts>,
  budgets: Map<ActId, number>,
  scales: Map<ActId, number>,
  count: (act: ActId, kind: QuestKind) => number,
  warnings: string[],
) {
  for (const [act, c] of counts) {
    const budget = budgets.get(act);
    if (budget === undefined) {
      warnings.push(`${act}: story.md §10.2'de ana görev bütçesi okunamadı; perde başlığında gösterilmez.`);
      continue;
    }
    const scale = scales.get(act);
    if (!c.base) warnings.push(`${act}: story.md §10.2'de taban XP okunamadı; perde başlığında gösterilmez.`);
    if (!scale) warnings.push(`${act}: progression.md §1.2'de \`xpScale\` okunamadı.`);
    const product = c.base && scale ? Math.round(c.base * count(act, "main") * scale) : null;
    if (product !== null && product !== budget) warnings.push(`${act}: story.md §10.2'nin bütçesi ${budget}, taban × görev × \`xpScale\` ${product}.`);
  }
}

// ---- İstemci verisi ----

// Boş alan (null, undefined, []) yazılmaz: 196 görevde sayfanın yükünün önemli bir payıdır.
function compact<T extends object>(value: T): Partial<T> {
  const out: Partial<T> = {};
  for (const key of Object.keys(value) as (keyof T)[]) {
    const v = value[key];
    if (v !== null && v !== undefined && !(Array.isArray(v) && v.length === 0)) out[key] = v;
  }
  return out;
}

// Sayfanın istemciye verdiği veri: kartların ve süzgeçlerin kullanmadığı alan gitmez. acts yalnız görev birden çok perdeye
// yayılıyorsa, xpMax yalnız xp'den farklıysa yazılır.
export function toClientView(data: Pick<QuestData, "quests" | "acts" | "families">): QuestView {
  return {
    quests: data.quests.map((q) => {
      const { raw: _raw, order: _order, source, steps, acts, xpMax, ...rest } = q;
      const single = !acts || (acts.length === 1 && acts[0] === q.act);
      return {
        ...(compact(rest) as Pick<Quest, ClientQuestKeys>),
        source: { doc: source.doc, href: source.href },
        ...(steps.length ? { steps: steps.map((s) => compact(s) as QuestStep) } : {}),
        ...(single ? {} : { acts }),
        ...(xpMax !== null && xpMax !== undefined && xpMax !== q.xp ? { xpMax } : {}),
      };
    }),
    acts: data.acts.map(({ sideCount: _side, companionCount: _companion, ...rest }) => compact(rest) as ClientAct),
    families: data.families,
  };
}

// ---- Önbellek ----

let cache: { key: string; data: QuestData } | null = null;

// Anahtar: okunan bütün belgeler (tasarım ve araştırma klasörlerinin .md dosyaları), progress.json ve takma adlar.
// Klasör listesi de anahtardadır: yeni belge eklenince sonuç yenilenir.
const sourceFiles = () => [
  ...(["design", "research"] as Group[]).flatMap((g) => listDocs(g).map((n) => path.join(GROUP_DIRS[g], `${n}.md`))),
  PROGRESS_FILE,
  LEGACY_FILE,
];

function stamp(file: string): string {
  try {
    return `${file}:${fs.statSync(file).mtimeMs}`;
  } catch {
    return `${file}:yok`;
  }
}

// Sunucu tarafı: belgeler ya da progress.json değişmedikçe aynı sonuç döner.
export function getQuestData(): QuestData {
  const key = sourceFiles().map(stamp).join("|");
  if (cache?.key === key) return cache.data;
  const data = build();
  cache = { key, data };
  return data;
}

// Denetim için: bir kaynak belge sayfasındaki çapalar (başlık kimlikleri, görev satırı, hücre ve karar satırı çapaları); belge yoksa null.
// page «/docs/source/design/act1», «/docs/source/research/sound-design» ya da yalnız ad («act1», tasarım belgesi).
// Adres takma adsa (legacy-ids.json, ör. ses-tasarimi.md → sound-design) dosya adına çevrilir; aynı adlı dosya önce gelir
// (tasarımın companions.md'si kendi adıdır, araştırmanın yoldaslar.md'si companions takma adını taşır).
export function docAnchors(page: string): Set<string> | null {
  const m = page.match(/^(?:\/docs\/source\/(design|research)\/)?([a-z0-9-]+)$/);
  if (!m) return null;
  const dir = GROUP_DIRS[(m[1] ?? "design") as Group];
  const base = fs.existsSync(path.join(dir, `${m[2]}.md`)) ? m[2] : Object.entries(readAliases()).find(([, alias]) => alias === m[2])?.[0];
  const file = base ? path.join(dir, `${base}.md`) : null;
  if (!file || !fs.existsSync(file)) return null;
  const body = bodyOf(readText(file));
  const lines = body.split("\n");
  const decisions: string[] = [];
  eachLine(lines, (line) => {
    const anchor = decisionAnchor(line);
    if (anchor) decisions.push(anchor);
  });
  const rows = questRowAnchors(lines);
  return new Set([...extractHeadings(body).map((h) => h.id), ...rows.values(), ...questCellAnchors(lines, rows).values(), ...decisions]);
}
