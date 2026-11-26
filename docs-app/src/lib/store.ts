// Notlar, gözden geçirme işaretleri ve belge sürümleri (data/*.json). Düz JSON: başka araçlar ve sonraki oturumlar da okuyabilir.
import { randomUUID } from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { allDocs, DATA_DIR } from "./catalog";
import { listRevisions, syncAll, writeAtomic } from "./history";
import { NOTE_KINDS, type NoteKind } from "./statuses";

export { NOTE_KINDS, type NoteKind };

const NOTES = path.join(DATA_DIR, "notes.json");
const REVIEW = path.join(DATA_DIR, "review.json");
const RELEASES = path.join(DATA_DIR, "releases.json");

function readJson<T>(file: string, fallback: T): T {
  if (!fs.existsSync(file)) return fallback;
  return JSON.parse(fs.readFileSync(file, "utf8")) as T;
}
const writeJson = (file: string, value: unknown) => writeAtomic(file, `${JSON.stringify(value, null, 1)}\n`);

// ---------- Notlar ----------

export interface Note {
  id: string;
  docId: string;
  kind: NoteKind;
  text: string;
  quote: string;
  anchor: string;
  anchorTitle: string;
  rev: number;
  done: boolean;
  at: string;
  doneAt: string | null;
}

export const listNotes = () => readJson<Note[]>(NOTES, []);

export function addNote(input: Pick<Note, "docId" | "kind" | "text" | "quote" | "anchor" | "anchorTitle" | "rev">): Note {
  const note: Note = { ...input, id: randomUUID().slice(0, 8), done: false, at: new Date().toISOString(), doneAt: null };
  writeJson(NOTES, [...listNotes(), note]);
  return note;
}

export function updateNote(id: string, patch: Partial<Pick<Note, "text" | "kind" | "done">>) {
  const notes = listNotes().map((n) => {
    if (n.id !== id) return n;
    const doneAt = patch.done === undefined ? n.doneAt : patch.done ? new Date().toISOString() : null;
    return { ...n, ...patch, doneAt };
  });
  writeJson(NOTES, notes);
}

export function deleteNote(id: string) {
  writeJson(NOTES, listNotes().filter((n) => n.id !== id));
}

// ---------- Gözden geçirme ----------

export type ReviewMap = Record<string, { rev: number; at: string }>;

export const readReview = () => readJson<ReviewMap>(REVIEW, {});

export function setReviewed(docId: string, rev: number | null) {
  const map = readReview();
  if (rev === null) delete map[docId];
  else map[docId] = { rev, at: new Date().toISOString() };
  writeJson(REVIEW, map);
}

// ---------- Belge sürümleri ----------

export interface Release {
  version: string;
  title: string;
  note: string;
  at: string;
  snapshot: Record<string, number>;
}

export const listReleases = () => readJson<Release[]>(RELEASES, []);

export function nextVersion(): string {
  const last = listReleases().at(-1)?.version;
  const match = last?.match(/^v(\d+)\.(\d+)$/);
  return match ? `v${match[1]}.${Number(match[2]) + 1}` : "v0.1";
}

export function createRelease(input: { version: string; title: string; note: string }): Release {
  const docs = syncAll();
  const snapshot: Record<string, number> = {};
  for (const doc of docs) snapshot[doc.id] = listRevisions(doc.id).at(-1)?.n ?? 1;
  const release: Release = { ...input, at: new Date().toISOString(), snapshot };
  writeJson(RELEASES, [...listReleases(), release]);
  return release;
}

export interface ChangedDoc {
  id: string;
  title: string;
  from: number;
  to: number;
}

// Sürüm anından bugüne (ya da iki sürüm arasında) değişen belgeler.
export function changedBetween(from: Record<string, number> | null, to: Record<string, number> | null = null): ChangedDoc[] {
  return allDocs().flatMap((doc) => {
    const latest = to ? to[doc.id] : listRevisions(doc.id).at(-1)?.n;
    const base = from?.[doc.id] ?? 0;
    if (latest === undefined || latest === base) return [];
    return [{ id: doc.id, title: doc.title, from: base, to: latest }];
  });
}
