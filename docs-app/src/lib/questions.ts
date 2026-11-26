// Karar bekleyenler: sayfalardaki çözülmemiş [!ACIK] (açık soru) ve [!CELISKI] (notla tasarımın ayrıştığı yer) kutuları
// tek listede toplanır. Ayrı bir açık sorular sayfası yoktur: liste «Karar Bekleyenler» sayfasının altında durur.
import { allDocs, bodyOf, readDocText } from "./catalog";
import { scanHeadings } from "./markdown";

export type PendingKind = "acik" | "celiski";

export interface OpenQuestion {
  kind: PendingKind;
  docId: string;
  docTitle: string;
  group: string;
  order: number;
  anchor: string;
  section: string;
  text: string;
}

const MARK: Record<PendingKind, RegExp> = { acik: /^>\s*\[!ACIK\]/, celiski: /^>\s*\[!CELISKI\]/ };

export function pendingItems(kinds: PendingKind[] = ["celiski", "acik"]): OpenQuestion[] {
  const out: OpenQuestion[] = [];
  for (const doc of allDocs()) {
    if (doc.kind !== "sayfa" || doc.questions + doc.conflicts === 0) continue;
    const body = bodyOf(doc, readDocText(doc));
    const headings = scanHeadings(body);
    const lines = body.split("\n");
    for (let i = 0; i < lines.length; i++) {
      const kind = kinds.find((k) => MARK[k].test(lines[i]));
      if (!kind) continue;
      const parts = [lines[i].replace(/^>\s*\[![A-Z]+\]\s*/, "")];
      while (i + 1 < lines.length && lines[i + 1].startsWith(">")) {
        i += 1;
        parts.push(lines[i].replace(/^>\s?/, ""));
      }
      const current = headings.filter((h) => h.line <= i + 1).at(-1);
      out.push({ kind, docId: doc.id, docTitle: doc.title, group: doc.group, order: doc.order, anchor: current?.id ?? "", section: current?.text ?? "", text: parts.join("\n").trim() });
    }
  }
  return out;
}

// Geriye uyum: yalnız açık sorular.
export const openQuestions = () => pendingItems(["acik"]);
