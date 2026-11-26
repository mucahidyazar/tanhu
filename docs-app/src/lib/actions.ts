"use server";

// Sunucu eylemleri: düzenleme, geri dönüş, notlar, gözden geçirme, belge sürümleri. Uygulama yalnız yerelde çalışır (127.0.0.1).
import { revalidatePath } from "next/cache";
import { composePage, getDoc, metaOf, readDocText, type Status, STATUSES } from "./catalog";
import { listRevisions, restoreRevision, type SaveResult, saveText, syncDoc } from "./history";
import { writePins } from "./pins";
import { setProgress } from "./progress";
import { NO_STATUS, PROGRESS_STATES, type ProgressState } from "./statuses";
import { addNote, createRelease, deleteNote, NOTE_KINDS, type NoteKind, setReviewed, updateNote } from "./store";

const refresh = () => revalidatePath("/", "layout");

function requireDoc(id: string) {
  const doc = getDoc(id);
  if (!doc) throw new Error(`Belge bulunamadı: ${id}`);
  return doc;
}

export interface SaveInput {
  id: string;
  body: string;
  message: string;
  baseRev: number;
  force?: boolean;
  title?: string;
  summary?: string;
  status?: string;
}

export async function saveDocAction(input: SaveInput): Promise<SaveResult> {
  const doc = requireDoc(input.id);
  let text = input.body;
  if (doc.kind === "sayfa") {
    const data = metaOf(readDocText(doc));
    // Durumsuz sayfa (genel sayfalar) öyle kalır: anahtar yazılmaz, YAML tanımsız değer de kabul etmez.
    if (input.status === NO_STATUS) delete data.status;
    else if (input.status && Object.hasOwn(STATUSES, input.status)) data.status = input.status as Status;
    text = composePage(input.body, { ...data, title: input.title?.trim() || data.title, summary: input.summary?.trim() ?? data.summary });
  }
  const result = saveText(doc, text, input.message, input.baseRev, input.force ?? false);
  // Çakışmada sayfa yenilenmez: düzenleyici açık kalır, soru orada sorulur.
  if (result.ok) refresh();
  return result;
}

export async function restoreAction(id: string, n: number) {
  requireDoc(id);
  const revision = restoreRevision(id, n);
  refresh();
  return revision;
}

export async function addNoteAction(input: { docId: string; kind: string; text: string; quote: string; anchor: string; anchorTitle: string }) {
  const doc = requireDoc(input.docId);
  const text = input.text.trim();
  if (!text) throw new Error("Not boş olamaz");
  const kind: NoteKind = Object.hasOwn(NOTE_KINDS, input.kind) ? (input.kind as NoteKind) : "duzelt";
  const note = addNote({ ...input, kind, text, rev: syncDoc(doc).n });
  refresh();
  return note;
}

export async function updateNoteAction(id: string, patch: { text?: string; kind?: NoteKind; done?: boolean }) {
  updateNote(id, patch);
  refresh();
}

export async function deleteNoteAction(id: string) {
  deleteNote(id);
  refresh();
}

export async function setReviewedAction(id: string, reviewed: boolean) {
  const doc = requireDoc(id);
  setReviewed(id, reviewed ? syncDoc(doc).n : null);
  refresh();
}

export async function createReleaseAction(input: { version: string; title: string; note: string }) {
  const version = input.version.trim();
  if (!version) throw new Error("Sürüm adı boş olamaz");
  const release = createRelease({ version, title: input.title.trim(), note: input.note.trim() });
  refresh();
  return { version: release.version };
}

export async function latestRevisionAction(id: string) {
  return listRevisions(id).at(-1)?.n ?? 0;
}

export async function setProgressAction(input: { id: string; status: string; note?: string }) {
  if (!Object.hasOwn(PROGRESS_STATES, input.status)) throw new Error(`Geçersiz durum: ${input.status}`);
  const item = setProgress(input.id, input.status as ProgressState, input.note, "Site");
  refresh();
  return { id: item.id, status: item.status };
}

// Kenar çubuğunun sabitlenenleri: sıra kullanıcınındır (sürükle bırak), liste olduğu gibi yazılır.
export async function setPinsAction(pins: string[]) {
  const saved = writePins(pins);
  refresh();
  return saved;
}
