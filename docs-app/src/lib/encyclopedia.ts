// Ansiklopedi: oyunun mitolojisi ve önemli kişileri, oyunun Destan Kitabı görünümünde bir kitap. Veri
// content/encyclopedia.json'dadır (biçim aşağıda); görseller sırayla: kaydın levhası (docs/assets/encyclopedia/<id>.webp,
// scripts/concepts.mjs --encyclopedia üretir), portresi (docs/media/ui/portraits/<ad>.webp), varlık kataloğundaki görseli.
import fs from "node:fs";
import path from "node:path";
import { imageOf, readCatalog } from "./assets";
import { APP_ROOT, REPO_ROOT } from "./catalog";

export const ENCYCLOPEDIA_FILE = path.join(APP_ROOT, "content", "encyclopedia.json");
export const PLATE_DIR = path.join(REPO_ROOT, "docs", "assets", "encyclopedia");

// Kaydın çağı: mit (inanç ve söylence; kaynağı çoğu zaman Mete'den yüzyıllar sonradır), tarih (kaynakta adı geçen
// kişi ya da olay), kurgu (oyunun yarattığı kişi).
export type EncyclopediaEra = "mit" | "tarih" | "kurgu";
export const ERA_LABEL: Record<EncyclopediaEra, string> = { mit: "Mit", tarih: "Tarih", kurgu: "Kurgu" };

export interface EncyclopediaFact {
  label: string;
  value: string;
}

export interface EncyclopediaLink {
  label: string;
  href: string;
}

export interface EncyclopediaRelation {
  id: string;
  label: string;
}

// Numaralı bölüm: «01 Kimliği», «02 Gelenekteki Görünüşü», «03 Anlatı Notu».
export interface EncyclopediaSection {
  title: string;
  text: string;
}

// Soy bağları: üst soy (ata, ana, baba), alt soy (çocuklar), yan bağlar (eş, kardeş, düşman).
export interface EncyclopediaLineage {
  up?: EncyclopediaRelation[];
  down?: EncyclopediaRelation[];
  side?: EncyclopediaRelation[];
  note?: string;
}

export interface EncyclopediaEntry {
  id: string;
  chapter: string;
  group?: string;
  name: string;
  altNames?: string[];
  epithet?: string;
  era: EncyclopediaEra;
  eraNote?: string;
  facts?: EncyclopediaFact[];
  sections?: EncyclopediaSection[];
  summary?: string;
  body?: string[];
  quote?: { text: string; source: string };
  relations?: EncyclopediaRelation[];
  lineage?: EncyclopediaLineage;
  acts?: string[];
  sources?: EncyclopediaLink[];
  sourceNote?: string;
  // Kişinin kendini tanıttığı iki cümle: söylenen İngilizce, altyazı Türkçe (K5); ses dosyası docs/media/audio/vo/en/ency.<id>.mp3.
  intro?: { en: string; tr: string };
  voice?: { id: string; name: string; note?: string };
  // Oyunda konuşmayan kişi (Umay, Mene; K86): hoparlör çıkmaz, iki cümle yazı olarak durur.
  speaks?: boolean;
  // Sesi kullanıcının seçimini bekleyen kişi (K87): tanıtım seçimden sonra okunur.
  voicePending?: boolean;
  // Godot projesindeki 3B model (game/ altında .glb); yoksa görünümde T-poz görseli.
  model?: string;
  portrait?: string;
  asset?: string;
  imagePrompt?: string;
  artPrompt?: string;
}

export interface EncyclopediaChapter {
  id: string;
  title: string;
  summary?: string;
  icon?: "sun" | "bow" | "yurt" | "horse" | "tower" | "people" | "star";
}

export interface Encyclopedia {
  updated: string;
  title: string;
  intro?: string;
  chapters: EncyclopediaChapter[];
  entries: EncyclopediaEntry[];
}

// İstemciye giden kayıt: görsellerin çözülmüş adresleri eklenir.
// portrait: profil; art: tam boy resim; pose: T-poz (3B üretiminin girdisi); modelUrl: var olan 3B model; audio: tanıtım sesi.
export interface EncyclopediaView extends EncyclopediaEntry {
  image: string | null;
  portraitUrl: string | null;
  artUrl: string | null;
  poseUrl: string | null;
  modelUrl: string | null;
  audioUrl: string | null;
}

const EMPTY: Encyclopedia = { updated: "", title: "Ansiklopedi", chapters: [], entries: [] };

const ICONS = new Set(["sun", "bow", "yurt", "horse", "tower", "people", "star"]);
const ERAS = new Set(["mit", "tarih", "kurgu"]);
const strings = (v: unknown): string[] => (Array.isArray(v) ? v.filter((x) => typeof x === "string") : typeof v === "string" && v ? [v] : []);
const str = (v: unknown): string | undefined => (typeof v === "string" && v.trim() ? v : undefined);

// Elle ya da ajanla yazılan dosyanın yanlışları kitabı düşürmesin: diziler diziye, eksik bağlar atılır, bilinmeyen çağ
// «kurgu», bilinmeyen simge «star» olur; kimliği ya da adı olmayan kayıt atlanır.
function normalizeEntry(e: Record<string, unknown>): EncyclopediaEntry | null {
  const id = str(e.id);
  const name = str(e.name);
  if (!id || !name) return null;
  const links = (v: unknown) =>
    (Array.isArray(v) ? v : []).filter((x): x is Record<string, unknown> => !!x && typeof x === "object").flatMap((x) => (str(x.href) ? [{ label: str(x.label) ?? String(x.href), href: String(x.href) }] : []));
  const facts = (Array.isArray(e.facts) ? e.facts : []).filter((x): x is Record<string, unknown> => !!x && typeof x === "object").flatMap((x) => (str(x.label) && str(x.value) ? [{ label: String(x.label), value: String(x.value) }] : []));
  const relations = (Array.isArray(e.relations) ? e.relations : []).filter((x): x is Record<string, unknown> => !!x && typeof x === "object").flatMap((x) => (str(x.id) ? [{ id: String(x.id), label: str(x.label) ?? "" }] : []));
  const quote = e.quote && typeof e.quote === "object" && str((e.quote as Record<string, unknown>).text) ? { text: String((e.quote as Record<string, unknown>).text), source: str((e.quote as Record<string, unknown>).source) ?? "" } : undefined;
  return {
    id,
    name,
    chapter: str(e.chapter) ?? "",
    group: str(e.group),
    altNames: strings(e.altNames),
    epithet: str(e.epithet),
    era: (ERAS.has(String(e.era)) ? e.era : "kurgu") as EncyclopediaEra,
    eraNote: str(e.eraNote),
    facts,
    summary: str(e.summary),
    body: strings(e.body),
    quote,
    relations,
    acts: strings(e.acts),
    sources: links(e.sources),
    sourceNote: str(e.sourceNote),
    sections: (Array.isArray(e.sections) ? e.sections : []).filter((x): x is Record<string, unknown> => !!x && typeof x === "object").flatMap((x) => (str(x.title) && str(x.text) ? [{ title: String(x.title), text: String(x.text) }] : [])),
    lineage: lineageOf(e.lineage),
    intro: e.intro && typeof e.intro === "object" && str((e.intro as Record<string, unknown>).en) ? { en: String((e.intro as Record<string, unknown>).en), tr: str((e.intro as Record<string, unknown>).tr) ?? "" } : undefined,
    voice: e.voice && typeof e.voice === "object" && str((e.voice as Record<string, unknown>).id) ? { id: String((e.voice as Record<string, unknown>).id), name: str((e.voice as Record<string, unknown>).name) ?? "", note: str((e.voice as Record<string, unknown>).note) } : undefined,
    speaks: e.speaks === false ? false : undefined,
    voicePending: e.voicePending === true ? true : undefined,
    model: str(e.model),
    portrait: str(e.portrait),
    asset: str(e.asset),
    imagePrompt: str(e.imagePrompt),
    artPrompt: str(e.artPrompt),
  };
}

function lineageOf(v: unknown): EncyclopediaLineage | undefined {
  if (!v || typeof v !== "object") return undefined;
  const o = v as Record<string, unknown>;
  const rel = (x: unknown) => (Array.isArray(x) ? x : []).filter((r): r is Record<string, unknown> => !!r && typeof r === "object" && !!str(r.id)).map((r) => ({ id: String(r.id), label: str(r.label) ?? "" }));
  const out = { up: rel(o.up), down: rel(o.down), side: rel(o.side), note: str(o.note) };
  return out.up.length || out.down.length || out.side.length ? out : undefined;
}

export function readEncyclopedia(): Encyclopedia {
  if (!fs.existsSync(ENCYCLOPEDIA_FILE)) return EMPTY;
  try {
    const data = JSON.parse(fs.readFileSync(ENCYCLOPEDIA_FILE, "utf8")) as Record<string, unknown>;
    const chapters = (Array.isArray(data.chapters) ? data.chapters : [])
      .filter((c): c is Record<string, unknown> => !!c && typeof c === "object" && !!str(c.id))
      .map((c) => ({ id: String(c.id), title: str(c.title) ?? String(c.id), summary: str(c.summary), icon: (ICONS.has(String(c.icon)) ? c.icon : "star") as EncyclopediaChapter["icon"] }));
    const entries = (Array.isArray(data.entries) ? data.entries : []).flatMap((e) => (e && typeof e === "object" ? [normalizeEntry(e as Record<string, unknown>)] : [])).filter((e): e is EncyclopediaEntry => e !== null);
    return { updated: str(data.updated) ?? "", title: str(data.title) ?? EMPTY.title, intro: str(data.intro), chapters, entries };
  } catch {
    return EMPTY;
  }
}

const exists = (rel: string) => fs.existsSync(path.join(REPO_ROOT, rel));

// Kişinin görselleri docs/assets/encyclopedia/<id>/ klasöründedir: portrait.webp, art.webp, pose.webp
// (scripts/concepts.mjs --encyclopedia üretir; profil ve poz art'tan türetilir, böylece tutarlıdır).
const first = (...rels: (string | null | undefined)[]) => {
  for (const rel of rels) if (rel && exists(rel)) return `/media/${rel}`;
  return null;
};

export function imagesOfEntry(entry: EncyclopediaEntry, catalog = readCatalog()) {
  const dir = `docs/assets/encyclopedia/${entry.id}`;
  const row = entry.asset ? catalog.assets.find((a) => a.id === entry.asset) : null;
  const portraitUrl = first(`${dir}/portrait.webp`, `${dir}/portrait.png`, entry.portrait ? `docs/media/ui/portraits/${entry.portrait}.webp` : null) ?? (row ? imageOf(row) : null);
  const artUrl = first(`${dir}/art.webp`, `${dir}/art.png`, `docs/assets/encyclopedia/${entry.id}.webp`, `docs/assets/encyclopedia/${entry.id}.png`);
  const poseUrl = first(`${dir}/pose.webp`, `${dir}/pose.png`);
  const model = entry.model?.replace(/^\/+/, "");
  const modelUrl = model && model.endsWith(".glb") && exists(model) ? `/media/${model}` : null;
  const audioUrl = first(`docs/media/audio/vo/en/ency.${entry.id}.mp3`);
  return { portraitUrl, artUrl, poseUrl, modelUrl, audioUrl };
}

export function imageOfEntry(entry: EncyclopediaEntry, catalog = readCatalog()): string | null {
  const i = imagesOfEntry(entry, catalog);
  return i.portraitUrl ?? i.artUrl;
}

export function encyclopediaView(): { book: Omit<Encyclopedia, "entries">; entries: EncyclopediaView[] } {
  const data = readEncyclopedia();
  const catalog = readCatalog();
  const { entries, ...book } = data;
  // Bölüm sırası korunur; bölümü olmayan kayıt sona düşer.
  const order = new Map(data.chapters.map((c, i) => [c.id, i]));
  const sorted = [...entries].sort((a, b) => (order.get(a.chapter) ?? 99) - (order.get(b.chapter) ?? 99));
  return {
    book,
    entries: sorted.map((e) => {
      const images = imagesOfEntry(e, catalog);
      return { ...e, ...images, image: images.portraitUrl ?? images.artUrl };
    }),
  };
}
