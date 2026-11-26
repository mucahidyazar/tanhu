// Varlık kataloğu: docs/assets/catalog.json. Her satır bir oyun varlığıdır: görseli, 3B gereği, 3B durumu,
// en mantıklı üretim yolu ve Meshy'nin en kaliteli en son modeliyle kredisi. Görsel ve model yolları proje köküne göredir.
import fs from "node:fs";
import path from "node:path";
import { REPO_ROOT } from "./catalog";

export const CATALOG_FILE = path.join(REPO_ROOT, "docs", "assets", "catalog.json");
export const THUMB_DIR = path.join(REPO_ROOT, "docs", "assets", "thumbs");

export type Need3d = "evet" | "hayir" | "kismen";
export type AssetPath = "meshy" | "blender" | "tripo" | "programatik" | "2b";

export interface MeshyCost {
  credits: number | null;
  detail: string;
}

export interface AssetRow {
  id: string;
  group: string;
  tr: string;
  en?: string;
  act?: string;
  need3d: Need3d;
  path: AssetPath;
  pathNote?: string;
  meshy: MeshyCost;
  image?: string;
  model?: string;
  status3d?: "var" | "yok" | "kismen";
  design?: string;
  note?: string;
  // Yerini bugün ücretsiz bir varlığın tuttuğu satır (E7.5): FREE_ASSETS.json kimlikleri; duruma göre sonra Meshy ile üretilir.
  free?: string[];
}

export interface AssetGroup {
  id: string;
  title: string;
  summary: string;
}

export interface PathInfo {
  id: AssetPath;
  title: string;
  summary: string;
}

export interface Catalog {
  updated: string;
  meshy: { model: string; settings: string; static: number; rig: number; action: number; retexture: number; note: string; source: string };
  paths: PathInfo[];
  groups: AssetGroup[];
  assets: AssetRow[];
}

export const NEED3D: Record<Need3d, string> = { evet: "Gerekli", kismen: "Kısmen", hayir: "Gerekmez" };
export const STATUS3D = { var: "Var", kismen: "Kısmen", yok: "Yok" } as const;

const EMPTY: Catalog = {
  updated: "",
  meshy: { model: "", settings: "", static: 0, rig: 0, action: 0, retexture: 0, note: "", source: "" },
  paths: [],
  groups: [],
  assets: [],
};

// Ücretsiz kanaldan geçici olarak alınan varlıklar (E7.5, K89): game/assets/_free/FREE_ASSETS.json.
export const FREE_ASSETS_FILE = path.join(REPO_ROOT, "game", "assets", "_free", "FREE_ASSETS.json");

export interface FreeAsset {
  id: string;
  name: string;
  kind: "texture" | "model" | "hdri" | "sound";
  source: string;
  url: string;
  license: string;
  author: string;
  sizeMB: number;
  plannedUse: string;
  usedIn: string[];
  replaceLater: boolean;
  regenWith: string;
  /** Yerine geçen Meshy modeli; kayıt kodla çizimin yedeği olarak durur. */
  replacedBy?: string | string[];
  /** Model yoksa kullanan düğümler. */
  fallbackIn?: string[];
}

export function readFreeAssets(): { rule: string; assets: FreeAsset[] } {
  try {
    const data = JSON.parse(fs.readFileSync(FREE_ASSETS_FILE, "utf8")) as { rule?: string; assets?: FreeAsset[] };
    return { rule: data.rule ?? "", assets: Array.isArray(data.assets) ? data.assets : [] };
  } catch {
    return { rule: "", assets: [] };
  }
}

export function readCatalog(): Catalog {
  if (!fs.existsSync(CATALOG_FILE)) return EMPTY;
  try {
    return JSON.parse(fs.readFileSync(CATALOG_FILE, "utf8")) as Catalog;
  } catch {
    return EMPTY;
  }
}

const inRepo = (rel: string) => {
  const full = path.resolve(REPO_ROOT, rel);
  return !path.relative(REPO_ROOT, full).startsWith("..") && fs.existsSync(full);
};

// 3B durumu: model yolu varsa dosyaya bakılır; elle yazılan değer önceliklidir.
export function status3dOf(row: AssetRow): keyof typeof STATUS3D {
  if (row.status3d) return row.status3d;
  if (row.model && inRepo(row.model)) return "var";
  return "yok";
}

// Görselin yolu: katalogda yazılı olan; yazılı değilse Godot hattının konsept yeri (game/assets/_concepts/<id>.png).
// Konsept betiği (scripts/concepts.mjs) görseli oraya yazar: katalog güncellenmeden de görünür.
function imagePathOf(row: AssetRow): string | null {
  if (row.image && inRepo(row.image)) return row.image;
  const concept = `game/assets/_concepts/${row.id}.png`;
  return inRepo(concept) ? concept : null;
}

// Tablo için küçük görsel: docs/assets/thumbs/<id>.webp; yoksa özgün görsel; o da yoksa yok.
export function thumbOf(row: AssetRow): string | null {
  if (fs.existsSync(path.join(THUMB_DIR, `${row.id}.webp`))) return `/media/docs/assets/thumbs/${row.id}.webp`;
  const image = imagePathOf(row);
  return image ? `/media/${image}` : null;
}

export function imageOf(row: AssetRow): string | null {
  const image = imagePathOf(row);
  return image ? `/media/${image}` : null;
}

export interface GroupTally {
  count: number;
  need: number;
  have: number;
  creditsNeeded: number;
  creditsAll: number;
  images: number;
}

export function tallyAssets(rows: AssetRow[]): GroupTally {
  const credits = (r: AssetRow) => r.meshy.credits ?? 0;
  return {
    count: rows.length,
    need: rows.filter((r) => r.need3d !== "hayir").length,
    have: rows.filter((r) => status3dOf(r) === "var").length,
    // Gerekli ve kısmen gerekli olup henüz modeli olmayanların bedeli: yapılacak işin kredisi.
    creditsNeeded: rows.filter((r) => r.need3d !== "hayir" && status3dOf(r) !== "var").reduce((s, r) => s + credits(r), 0),
    creditsAll: rows.reduce((s, r) => s + credits(r), 0),
    images: rows.filter((r) => thumbOf(r) !== null).length,
  };
}

// Sayfalarda gösterilen küçük varlık kartı. İstemciye de gider: yalnız ad, tür ve küçük görselin adresi.
export interface AssetCard {
  id: string;
  tr: string;
  group: string;
  thumb: string | null;
}

const cardOf = (row: AssetRow): AssetCard => ({ id: row.id, tr: row.tr, group: row.group, thumb: thumbOf(row) });

// «```varlik» bloklarının kimlikleri bu tablodan çözülür.
export function assetCards(catalog = readCatalog()): Record<string, AssetCard> {
  return Object.fromEntries(catalog.assets.map((row) => [row.id, cardOf(row)]));
}

// Bir sayfaya bağlı varlıklar: satırın design alanı o sayfanın adresidir (bölüm bağı da olur). Görseli olanlar önce.
export function assetsOfPage(docId: string, catalog = readCatalog()): AssetCard[] {
  const href = `/docs/${docId}`;
  return catalog.assets
    .filter((row) => row.design?.split("#")[0] === href)
    .map(cardOf)
    .sort((a, b) => Number(b.thumb !== null) - Number(a.thumb !== null));
}
