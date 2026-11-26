// İki metin arasındaki fark: bölüm (hunk) bölüm satırlar, değişen satır çiftlerinde sözcük vurgusu. Belgelerde satırlar uzun olduğu
// için yalnız satır farkı yetmez.
import { diffWordsWithSpace, structuredPatch } from "diff";

export interface Span {
  text: string;
  mark: boolean;
}

export interface DiffLine {
  type: "ctx" | "add" | "del";
  oldLine: number | null;
  newLine: number | null;
  spans: Span[];
}

export interface DiffHunk {
  lines: DiffLine[];
}

const plain = (text: string): Span[] => [{ text, mark: false }];

// Karşılıklı silinen ve eklenen satır: yalnız değişen sözcükler vurgulanır. Çok farklıysa bütün satır düz kalır.
function wordSpans(before: string, after: string): { del: Span[]; add: Span[] } {
  const parts = diffWordsWithSpace(before, after);
  const same = parts.filter((p) => !p.added && !p.removed).reduce((sum, p) => sum + p.value.length, 0);
  if (same < Math.max(before.length, after.length) * 0.3) return { del: plain(before), add: plain(after) };
  return {
    del: parts.filter((p) => !p.added).map((p) => ({ text: p.value, mark: !!p.removed })),
    add: parts.filter((p) => !p.removed).map((p) => ({ text: p.value, mark: !!p.added })),
  };
}

export function diffDocs(before: string, after: string): DiffHunk[] {
  const patch = structuredPatch("a", "b", before, after, "", "", { context: 3 });
  return patch.hunks.map((hunk) => {
    const lines: DiffLine[] = [];
    let oldLine = hunk.oldStart;
    let newLine = hunk.newStart;
    const raw = hunk.lines.filter((l) => !l.startsWith("\\"));
    for (let i = 0; i < raw.length; ) {
      const row = raw[i];
      if (row.startsWith(" ")) {
        lines.push({ type: "ctx", oldLine: oldLine++, newLine: newLine++, spans: plain(row.slice(1)) });
        i++;
        continue;
      }
      // Art arda silinen ve eklenen satırlar sırayla eşlenir.
      const dels: string[] = [];
      const adds: string[] = [];
      while (raw[i]?.startsWith("-")) dels.push(raw[i++].slice(1));
      while (raw[i]?.startsWith("+")) adds.push(raw[i++].slice(1));
      const delSpans: Span[][] = dels.map(plain);
      const addSpans: Span[][] = adds.map(plain);
      for (let k = 0; k < Math.min(dels.length, adds.length); k++) {
        const pair = wordSpans(dels[k], adds[k]);
        delSpans[k] = pair.del;
        addSpans[k] = pair.add;
      }
      for (const spans of delSpans) lines.push({ type: "del", oldLine: oldLine++, newLine: null, spans });
      for (const spans of addSpans) lines.push({ type: "add", oldLine: null, newLine: newLine++, spans });
    }
    return { lines };
  });
}
