// Godot ilerlemesi: content/progress.json. Yol haritası Perde > Faz > Madde düzenindedir: her perdenin fazları, her
// fazın maddeleri (işler). Site bir maddeyi işaretler; Godot'da çalışan bir oturum da dosyayı doğrudan düzenleyebilir
// (biçim README'de). Kanıt yolları game/ klasörüne göredir ("res://" öneki de kabul edilir).
import fs from "node:fs";
import path from "node:path";
import { APP_ROOT, REPO_ROOT } from "./catalog";
import { writeAtomic } from "./history";
import { PROGRESS_STATES, type ProgressState } from "./statuses";

export const PROGRESS_FILE = path.join(APP_ROOT, "content", "progress.json");
export const GAME_DIR = path.join(REPO_ROOT, "game");

export interface ProgressEvent {
  at: string;
  status: ProgressState;
  note?: string;
  by?: string;
}

export interface ProgressItem {
  id: string;
  phase: string;
  title: string;
  area?: string;
  status: ProgressState;
  design?: string[];
  paths?: string[];
  note?: string;
  history?: ProgressEvent[];
}

// Perde: hikâyenin bölümü (Önsöz, Çocukluk, I–VI, Sonsöz) ya da perdeye bağlı olmayan iş kümesi (Temel, Yayın).
// goal: perdenin yapım hedefi (bir paragraf); systems: perdenin oyuna getirdiği sistemler; page: perdenin hikâye sayfası.
export interface Act {
  id: string;
  title: string;
  summary: string;
  goal?: string;
  systems?: string[];
  page?: string;
}

// Faz: bir perdenin içindeki sıralı iş dilimi; çıkış ölçütü sağlanınca biter. requires: önce bitmesi gereken fazlar.
export interface Phase {
  id: string;
  act: string;
  title: string;
  summary?: string;
  exit?: string;
  requires?: string[];
}

export interface ProgressData {
  updated: string;
  acts: Act[];
  phases: Phase[];
  items: ProgressItem[];
}

export interface Evidence {
  path: string;
  exists: boolean;
  modified: string | null;
}

export interface Tally {
  total: number;
  bitti: number;
  suruyor: number;
  yapilacak: number;
  percent: number;
}

const EMPTY: ProgressData = { updated: "", acts: [], phases: [], items: [] };

// Eski biçim (milestones + items[].milestone) okunur: her dönüm noktası tek fazlı bir perde sayılır.
interface LegacyData {
  updated?: string;
  acts?: Act[];
  phases?: Phase[];
  milestones?: { id: string; title: string; summary: string }[];
  items?: (Partial<ProgressItem> & { milestone?: string })[];
}

function normalize(raw: LegacyData): ProgressData {
  const items = (raw.items ?? []) as (ProgressItem & { milestone?: string })[];
  if (Array.isArray(raw.acts) && Array.isArray(raw.phases)) return { updated: raw.updated ?? "", acts: raw.acts, phases: raw.phases, items };
  const acts = (raw.milestones ?? []).map((m) => ({ id: m.id, title: m.title, summary: m.summary }));
  const phases = acts.map((a) => ({ id: `${a.id}-f1`, act: a.id, title: a.title }));
  for (const item of items) if (!item.phase && item.milestone) item.phase = `${item.milestone}-f1`;
  return { updated: raw.updated ?? "", acts, phases, items };
}

export function readProgress(): ProgressData {
  if (!fs.existsSync(PROGRESS_FILE)) return EMPTY;
  try {
    const data = normalize(JSON.parse(fs.readFileSync(PROGRESS_FILE, "utf8")) as LegacyData);
    // Elle yazılmış bilinmeyen durum «yapılacak» sayılır: sayfa bozulmaz.
    for (const item of data.items) if (!Object.hasOwn(PROGRESS_STATES, item.status)) item.status = "yapilacak";
    return data;
  } catch {
    return EMPTY;
  }
}

export function tally(items: ProgressItem[]): Tally {
  const count = (s: ProgressState) => items.filter((i) => i.status === s).length;
  const total = items.length;
  const bitti = count("bitti");
  // Süren iş yarım sayılır: çubuk ilerlemeyi bitince değil, başlayınca da gösterir.
  const percent = total ? Math.round(((bitti + count("suruyor") * 0.5) / total) * 100) : 0;
  return { total, bitti, suruyor: count("suruyor"), yapilacak: count("yapilacak"), percent };
}

// Perdenin fazları dosyadaki sırayla; bir fazın maddeleri; bir perdenin bütün maddeleri.
export const phasesOf = (data: ProgressData, actId: string) => data.phases.filter((p) => p.act === actId);
export const itemsOfPhase = (data: ProgressData, phaseId: string) => data.items.filter((i) => i.phase === phaseId);
export function itemsOfAct(data: ProgressData, actId: string): ProgressItem[] {
  const ids = new Set(phasesOf(data, actId).map((p) => p.id));
  return data.items.filter((i) => ids.has(i.phase));
}
// Fazı dosyada olmayan maddeler: sayfada ayrı bir başlık altında görünür, kaybolmaz.
export function orphanItems(data: ProgressData): ProgressItem[] {
  const ids = new Set(data.phases.map((p) => p.id));
  return data.items.filter((i) => !ids.has(i.phase));
}

export function evidenceOf(item: ProgressItem): Evidence[] {
  return (item.paths ?? []).map((raw) => {
    const rel = raw.replace(/^res:\/\//, "").replace(/^\/+/, "");
    const full = path.resolve(GAME_DIR, rel);
    const inside = !path.relative(GAME_DIR, full).startsWith("..");
    if (!inside || !fs.existsSync(full)) return { path: rel, exists: false, modified: null };
    return { path: rel, exists: true, modified: fs.statSync(full).mtime.toISOString() };
  });
}

// Sayfalardaki «```ilerleme» bloğu için yalın görünüm: istemciye de gider, dosya yolu ve geçmiş taşımaz.
export interface ProgressView {
  acts: Act[];
  phases: Phase[];
  items: { id: string; phase: string; title: string; area?: string; status: ProgressState }[];
}

export function progressView(data = readProgress()): ProgressView {
  return {
    acts: data.acts,
    phases: data.phases,
    items: data.items.map((i) => ({ id: i.id, phase: i.phase, title: i.title, ...(i.area ? { area: i.area } : {}), status: i.status })),
  };
}

// Bir maddenin durumunu yazar. Ham dosya okunur ve yalnız o madde yamanır: görünüm katmanının düzeltmeleri (eski biçimin
// çevrilmesi, bilinmeyen durumun «yapılacak» sayılması) dosyaya geçmez, bilinmeyen üst alanlar korunur. Dosya bozuksa ya
// da items dizi değilse hiçbir şey yazılmaz. Her yazmadan önce bir önceki hâl progress.json.bak'a kopyalanır.
export function setProgress(id: string, status: ProgressState, note: string | undefined, by: string): ProgressItem {
  const raw = JSON.parse(fs.readFileSync(PROGRESS_FILE, "utf8")) as Record<string, unknown>;
  if (!Array.isArray(raw.items)) throw new Error("progress.json'da items dizisi yok: dosya elle düzeltilmeli");
  if ("acts" in raw && !Array.isArray(raw.acts)) throw new Error("progress.json'da acts dizi değil: dosya elle düzeltilmeli");
  if ("phases" in raw && !Array.isArray(raw.phases)) throw new Error("progress.json'da phases dizi değil: dosya elle düzeltilmeli");
  const items = raw.items as ProgressItem[];
  const item = items.find((i) => i.id === id);
  if (!item) throw new Error(`İş bulunamadı: ${id}`);
  const text = note?.trim();
  if (item.status === status && (text === undefined || text === (item.note ?? ""))) return item;
  item.status = status;
  if (text !== undefined) item.note = text || undefined;
  const at = new Date().toISOString();
  item.history = [...(item.history ?? []), { at, status, ...(text ? { note: text } : {}), by }];
  raw.updated = at;
  fs.copyFileSync(PROGRESS_FILE, `${PROGRESS_FILE}.bak`);
  writeAtomic(PROGRESS_FILE, `${JSON.stringify(raw, null, 2)}\n`);
  return item;
}
