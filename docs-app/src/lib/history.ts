// Sürüm geçmişi: her belgenin her sürümü diskte tam metin durur (data/history/<kimlik>/). Uygulama dışından gelen değişiklik de
// (elle ya da başka bir araçla) belge açılınca yeni sürüm olarak yakalanır. Hiçbir sürüm silinmez; geri dönüş yeni sürümdür.
import { createHash } from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { diffLines } from "diff";
import { allDocs, DATA_DIR, type Doc, getDoc, readDocText } from "./catalog";

export type RevisionKind = "ilk" | "duzenleme" | "geri-donus" | "disaridan";

export interface Revision {
  n: number;
  at: string;
  kind: RevisionKind;
  message: string;
  hash: string;
  added: number;
  removed: number;
}

export interface ActivityRow extends Revision {
  docId: string;
  title: string;
}

const HISTORY = path.join(DATA_DIR, "history");
const dirOf = (id: string) => path.join(HISTORY, ...id.split("/"));
const indexOf = (id: string) => path.join(dirOf(id), "revisions.json");
const textOf = (id: string, n: number) => path.join(dirOf(id), `${String(n).padStart(5, "0")}.md`);
const hashOf = (text: string) => createHash("sha1").update(text).digest("hex").slice(0, 16);

export function writeAtomic(file: string, data: string) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const tmp = `${file}.${process.pid}.${Date.now()}.tmp`;
  fs.writeFileSync(tmp, data);
  fs.renameSync(tmp, file);
}

export function listRevisions(id: string): Revision[] {
  const file = indexOf(id);
  if (!fs.existsSync(file)) return [];
  return JSON.parse(fs.readFileSync(file, "utf8")) as Revision[];
}

export function readRevision(id: string, n: number): string | null {
  const file = textOf(id, n);
  return fs.existsSync(file) ? fs.readFileSync(file, "utf8") : null;
}

function lineStats(before: string, after: string) {
  let added = 0;
  let removed = 0;
  for (const part of diffLines(before, after)) {
    if (part.added) added += part.count ?? 0;
    if (part.removed) removed += part.count ?? 0;
  }
  return { added, removed };
}

function append(id: string, text: string, kind: RevisionKind, message: string): Revision {
  const list = listRevisions(id);
  const prev = list.at(-1);
  const stats = prev ? lineStats(readRevision(id, prev.n) ?? "", text) : { added: text.split("\n").length, removed: 0 };
  const rev: Revision = { n: (prev?.n ?? 0) + 1, at: new Date().toISOString(), kind, message, hash: hashOf(text), ...stats };
  writeAtomic(textOf(id, rev.n), text);
  writeAtomic(indexOf(id), `${JSON.stringify([...list, rev], null, 1)}\n`);
  return rev;
}

// Belgenin bugünkü metni son sürümden farklıysa yeni sürüm açar. → son sürüm
export function syncDoc(doc: Doc): Revision {
  const text = readDocText(doc);
  const last = listRevisions(doc.id).at(-1);
  if (!last) return append(doc.id, text, "ilk", "İlk kayıt");
  if (last.hash === hashOf(text)) return last;
  return append(doc.id, text, "disaridan", "Uygulama dışında değişti");
}

export function syncAll(): Doc[] {
  const docs = allDocs();
  for (const doc of docs) syncDoc(doc);
  return docs;
}

export type SaveResult =
  | { ok: true; unchanged: boolean; revision: Revision }
  | { ok: false; conflict: true; latest: Revision };

// baseRev: düzenleyicinin açıldığı sürüm. Arada belge değiştiyse force olmadan yazılmaz.
export function saveText(doc: Doc, text: string, message: string, baseRev: number, force = false): SaveResult {
  const latest = syncDoc(doc);
  if (latest.hash === hashOf(text)) return { ok: true, unchanged: true, revision: latest };
  if (latest.n !== baseRev && !force) return { ok: false, conflict: true, latest };
  writeAtomic(doc.file, text);
  return { ok: true, unchanged: false, revision: append(doc.id, text, "duzenleme", message.trim() || "Düzenleme") };
}

export function restoreRevision(id: string, n: number): Revision {
  const doc = getDoc(id);
  const text = readRevision(id, n);
  if (!doc || text === null) throw new Error("Sürüm bulunamadı");
  syncDoc(doc);
  writeAtomic(doc.file, text);
  return append(id, text, "geri-donus", `${n}. sürüme dönüldü`);
}

export function activity(limit = 40): ActivityRow[] {
  return allDocs()
    .flatMap((doc) => listRevisions(doc.id).map((r) => ({ ...r, docId: doc.id, title: doc.title })))
    .filter((r) => r.kind !== "ilk")
    .sort((a, b) => b.at.localeCompare(a.at))
    .slice(0, limit);
}
