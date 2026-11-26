// Belge kataloğu: derlenmiş sayfalar (content/pages) ve kaynak belgeler (docs/design, docs/research). Tek kimlik, tek yol.
import fs from "node:fs";
import path from "node:path";
import matter from "gray-matter";
import { sourceAlias } from "./ids";
import { countCallouts } from "./markdown";
import { type Status, STATUSES } from "./statuses";

export { type Status, STATUSES };

export const APP_ROOT = process.cwd();
export const REPO_ROOT = path.resolve(APP_ROOT, "..");
export const PAGES_DIR = path.join(APP_ROOT, "content", "pages");
export const DATA_DIR = path.join(APP_ROOT, "data");

export const CATEGORIES = [
  { id: "general", title: "Genel", blurb: "Oyunun özeti, araştırma ve tasarım turu, karar bekleyenler, notların ve sözlük." },
  { id: "story", title: "Hikâye", blurb: "Mete'nin hayatı perde perde: Önsöz, Çocukluk, I–VI, Sonsöz; kadro, mitoloji ve tarih." },
  { id: "world", title: "Dünya", blurb: "Harita, bölgeler, yolculuk, zaman, hava ve hayvanlar." },
  { id: "gameplay", title: "Oynanış", blurb: "Kamera, açık dünya, yoldaşlar, gelişim, dövüş, kamp ve ordu." },
  { id: "economy", title: "Ekonomi", blurb: "Envanter, malzeme, toplama, zanaat, takas ve denge." },
  { id: "buildings", title: "Yapılar", blurb: "Yurtlar, inşa ve emek, yapı kataloğu, hasar." },
  { id: "settlement", title: "Yerleşim ve Hanlık", blurb: "Obadan Tanhu Avlusu'na, haneler, ordugâh." },
  { id: "presentation", title: "Görsel ve Ses", blurb: "Görsel dil, müzik, seslendirme, arayüz." },
  { id: "development", title: "Geliştirme", blurb: "Özellikler özeti, mimari ve varlık hattı. Yol haritası ayrı sayfada." },
] as const;

export const SOURCE_GROUPS = [
  { id: "source/design", title: "Tasarım belgeleri", dir: "docs/design" },
  { id: "source/design/d2", title: "İkinci tasarım turu (d2)", dir: "docs/design/d2" },
  { id: "source/design/d3", title: "Üçüncü tasarım turu (d3)", dir: "docs/design/d3" },
  { id: "source/research", title: "Araştırma", dir: "docs/research" },
  { id: "source/game", title: "Godot projesi", dir: "game" },
  { id: "source/game/docs", title: "Godot belgeleri", dir: "game/docs" },
] as const;

export interface Doc {
  id: string;
  kind: "sayfa" | "kaynak";
  group: string;
  title: string;
  summary: string;
  status: Status | null;
  order: number;
  file: string;
  relPath: string;
  sources: string[];
  conflicts: number;
  questions: number;
  mtimeMs: number;
}

interface CacheRow {
  mtimeMs: number;
  doc: Doc;
}

const cache = new Map<string, CacheRow>();

// Ön bilgi. YAML bozuksa (örneğin özette tırnaksız iki nokta) satır satır okunur: tek dosya siteyi düşürmez.
function parseFront(raw: string): { data: Record<string, unknown>; content: string } {
  try {
    // Seçenek vermek gray-matter'ın önbelleğini atlar: hatalı metni önbellekten boş döndürüyor.
    const { data, content } = matter(raw, {});
    return { data, content };
  } catch {
    const match = raw.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?/);
    if (!match) return { data: {}, content: raw };
    const data: Record<string, unknown> = {};
    let list: string[] | null = null;
    for (const line of match[1].split(/\r?\n/)) {
      const item = line.match(/^\s*-\s+(.*)$/);
      if (item && list) {
        list.push(item[1].trim());
        continue;
      }
      const pair = line.match(/^([A-Za-z_]+):\s*(.*)$/);
      if (!pair) continue;
      list = pair[2] === "" ? [] : null;
      data[pair[1]] = list ?? pair[2].trim().replace(/^["']|["']$/g, "");
    }
    return { data, content: raw.slice(match[0].length) };
  }
}

function pageDoc(file: string): Doc {
  const raw = fs.readFileSync(file, "utf8");
  const { data, content } = parseFront(raw);
  const rel = path.relative(PAGES_DIR, file).replace(/\\/g, "/").replace(/\.md$/, "");
  return {
    id: rel,
    kind: "sayfa",
    group: rel.split("/")[0],
    title: String(data.title ?? path.basename(rel)),
    summary: String(data.summary ?? ""),
    status: String(data.status) in STATUSES ? (data.status as Status) : null,
    order: Number(data.order ?? 999),
    file,
    relPath: path.relative(REPO_ROOT, file).replace(/\\/g, "/"),
    sources: Array.isArray(data.sources) ? data.sources.map(String) : [],
    conflicts: countCallouts(content, "CELISKI"),
    questions: countCallouts(content, "ACIK"),
    mtimeMs: 0,
  };
}

function sourceDoc(file: string, group: string): Doc {
  const raw = fs.readFileSync(file, "utf8");
  const relPath = path.relative(REPO_ROOT, file).replace(/\\/g, "/");
  const name = path.basename(file, ".md");
  const h1 = raw.match(/^#\s+(.+)$/m)?.[1]?.trim();
  return {
    // Adres İngilizcedir: Türkçe dosya adının takma adı kullanılır (ids.ts, legacy-ids.json).
    id: `${group}/${sourceAlias(name)}`,
    kind: "kaynak",
    group,
    title: h1 ? `${h1}` : name,
    summary: relPath,
    status: null,
    order: 0,
    file,
    relPath,
    sources: [],
    conflicts: 0,
    questions: 0,
    mtimeMs: 0,
  };
}

function load(file: string, make: () => Doc): Doc {
  const { mtimeMs } = fs.statSync(file);
  const hit = cache.get(file);
  if (hit && hit.mtimeMs === mtimeMs) return hit.doc;
  const doc = { ...make(), mtimeMs };
  cache.set(file, { mtimeMs, doc });
  return doc;
}

function walk(dir: string): string[] {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) return walk(full);
    return e.name.endsWith(".md") ? [full] : [];
  });
}

export function allDocs(): Doc[] {
  const pages = walk(PAGES_DIR).map((file) => load(file, () => pageDoc(file)));
  const sources = SOURCE_GROUPS.flatMap((g) => {
    const dir = path.join(REPO_ROOT, g.dir);
    if (!fs.existsSync(dir)) return [];
    return fs
      .readdirSync(dir)
      .filter((f) => f.endsWith(".md"))
      .sort()
      .map((f) => {
        const file = path.join(dir, f);
        return load(file, () => sourceDoc(file, g.id));
      });
  });
  return [...pages, ...sources];
}

export function getDoc(id: string): Doc | null {
  return allDocs().find((d) => d.id === id) ?? null;
}

export const groupTitle = (group: string) =>
  CATEGORIES.find((c) => c.id === group)?.title ?? SOURCE_GROUPS.find((g) => g.id === group)?.title ?? group;

export function readDocText(doc: Doc): string {
  return fs.readFileSync(doc.file, "utf8");
}

// Dosya metninden görünen gövde: sayfada ön bilgi, kaynak belgede en baştaki # başlık başlığa taşınır.
export function bodyOf(doc: Doc, text: string): string {
  if (doc.kind === "sayfa") return parseFront(text).content.replace(/^\n+/, "");
  return text.replace(/^\s*#\s+.+\n+/, "");
}

export function metaOf(text: string): Record<string, unknown> {
  return parseFront(text).data;
}

export function composePage(body: string, data: Record<string, unknown>): string {
  // lineWidth -1: uzun özet satırı kırılmaz, sürüm farkında gürültü olmaz.
  return matter.stringify(`\n${body.replace(/^\n+/, "").replace(/\n*$/, "\n")}`, data, { lineWidth: -1 } as matter.GrayMatterOption<string, never>);
}
