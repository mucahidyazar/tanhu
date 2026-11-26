// Tam metin arama: bütün belgelerde, Türkçe harfleri katlayarak. Başlıktaki eşleşme öne geçer; sonuç en yakın bölüme bağlanır.
import { allDocs, bodyOf, groupTitle, readDocText } from "./catalog";
import { readEncyclopedia } from "./encyclopedia";
import { scanHeadings } from "./markdown";
import { fold } from "./text";

export interface SearchHit {
  id: string;
  title: string;
  group: string;
  snippet: string;
  anchor: string;
  section: string;
  kind: "sayfa" | "kaynak" | "ansiklopedi";
  href?: string;
}

const MAX_HITS = 40;

function snippetAround(body: string, at: number, length: number) {
  const start = Math.max(0, body.lastIndexOf("\n", at) + 1, at - 70);
  const end = Math.min(body.length, at + length + 110);
  return `${start > 0 && body[start - 1] !== "\n" ? "…" : ""}${body.slice(start, end).replace(/\s+/g, " ").replace(/[*`|#>]/g, "").trim()}…`;
}

export function search(query: string): SearchHit[] {
  const q = fold(query.trim());
  if (q.length < 2) return [];
  const scored: Array<SearchHit & { score: number }> = [];
  for (const doc of allDocs()) {
    const titleHit = fold(doc.title).includes(q);
    const body = bodyOf(doc, readDocText(doc));
    // Katlama harf sayısını korur (tek harf tek harfe): konum özgün metinde de geçerlidir.
    const at = fold(body).indexOf(q);
    if (!titleHit && at < 0) continue;
    let anchor = "";
    let section = "";
    if (at >= 0) {
      const line = body.slice(0, at).split("\n").length;
      const current = scanHeadings(body).filter((h) => h.line <= line).at(-1);
      anchor = current?.id ?? "";
      section = current?.text ?? "";
    }
    scored.push({
      id: doc.id,
      title: doc.title,
      group: groupTitle(doc.group),
      kind: doc.kind,
      anchor,
      section,
      snippet: at >= 0 ? snippetAround(body, at, q.length) : doc.summary,
      score: (titleHit ? 100 : 0) + (doc.kind === "sayfa" ? 10 : 0) + (at >= 0 ? 1 : 0),
    });
  }
  // Ansiklopedi kayıtları: ad, öteki adlar, san ve metin.
  for (const e of readEncyclopedia().entries) {
    const head = fold([e.name, ...(e.altNames ?? []), e.epithet ?? ""].join(" "));
    const text = [e.summary ?? "", ...(e.body ?? [])].join("\n");
    const at = fold(text).indexOf(q);
    const nameHit = head.includes(q);
    if (!nameHit && at < 0) continue;
    scored.push({
      id: `encyclopedia/${e.id}`,
      title: e.name,
      group: "Ansiklopedi",
      kind: "ansiklopedi",
      href: `/encyclopedia/${e.id}`,
      anchor: "",
      section: e.epithet ?? "",
      snippet: at >= 0 ? snippetAround(text, at, q.length) : e.summary ?? "",
      score: (nameHit ? 120 : 0) + (at >= 0 ? 1 : 0),
    });
  }
  return scored
    .sort((a, b) => b.score - a.score || a.title.localeCompare(b.title, "tr"))
    .slice(0, MAX_HITS)
    .map(({ score: _score, ...hit }) => hit);
}
