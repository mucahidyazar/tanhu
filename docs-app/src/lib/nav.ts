// Kenar çubuğunun verisi: kategoriler, sayfa işaretleri, sayaçlar.
import { allDocs, CATEGORIES, type Doc, SOURCE_GROUPS, type Status } from "./catalog";
import { listRevisions } from "./history";
import { readCatalog } from "./assets";
import { readPins } from "./pins";
import { readProgress, type Tally, tally } from "./progress";
import { listNotes, listReleases, readReview, type ReviewMap } from "./store";

export interface NavItem {
  id: string;
  title: string;
  label: string;
  status: Status | null;
  conflicts: number;
  notes: number;
  review: "tamam" | "degisti" | null;
}

export interface NavGroup {
  id: string;
  title: string;
  items: NavItem[];
}

export interface NavData {
  categories: NavGroup[];
  sources: NavGroup[];
  openNotes: number;
  openQuestions: number;
  pending: number;
  progress: Tally;
  pins: string[];
  assets: { id: string; title: string; count: number }[];
  release: string | null;
  reviewed: number;
  total: number;
}

function reviewState(map: ReviewMap, doc: Doc): NavItem["review"] {
  const row = map[doc.id];
  if (!row) return null;
  const latest = listRevisions(doc.id).at(-1)?.n ?? row.rev;
  return latest > row.rev ? "degisti" : "tamam";
}

export function buildNav(): NavData {
  const docs = allDocs();
  const notes = listNotes().filter((n) => !n.done);
  const review = readReview();
  const item = (doc: Doc, label: string): NavItem => ({
    id: doc.id,
    title: doc.title,
    label,
    status: doc.status,
    conflicts: doc.conflicts,
    notes: notes.filter((n) => n.docId === doc.id).length,
    review: reviewState(review, doc),
  });
  const pages = docs.filter((d) => d.kind === "sayfa");
  // Kategori listesinde gösterilmeyenler: «Notlarım» Notlar sayfasına katıldı (/notes), «Karar Bekleyenler» kenar çubuğunun
  // «Çalışma» başlığında sayacıyla durur.
  const OUTSIDE_CATEGORIES = new Set(["general/my-notes", "general/pending-decisions"]);
  const categories = CATEGORIES.map((c) => ({
    id: c.id,
    title: c.title,
    items: pages
      .filter((d) => d.group === c.id && !OUTSIDE_CATEGORIES.has(d.id))
      .sort((a, b) => a.order - b.order)
      .map((d) => item(d, d.title)),
  })).filter((g) => g.items.length > 0);
  const sources = SOURCE_GROUPS.map((g) => ({
    id: g.id,
    title: g.title,
    items: docs.filter((d) => d.group === g.id).map((d) => item(d, d.id.split("/").at(-1) ?? d.title)),
  })).filter((g) => g.items.length > 0);
  return {
    categories,
    sources,
    openNotes: notes.length,
    openQuestions: pages.reduce((sum, d) => sum + d.questions, 0),
    pending: pages.reduce((sum, d) => sum + d.questions + d.conflicts, 0),
    progress: tally(readProgress().items),
    pins: readPins(),
    assets: (() => {
      const catalog = readCatalog();
      return catalog.groups.map((g) => ({ id: g.id, title: g.title, count: catalog.assets.filter((a) => a.group === g.id).length }));
    })(),
    release: listReleases().at(-1)?.version ?? null,
    reviewed: pages.filter((d) => reviewState(review, d) === "tamam").length,
    total: pages.length,
  };
}
