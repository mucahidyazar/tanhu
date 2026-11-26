// İki sürümün farkı: değişen bölümler, sözcük vurgusuyla; değişmeyen uzun aralıklar katlanır.
import type { DiffHunk, DiffLine } from "@/lib/diff";

function Line({ line }: { line: DiffLine }) {
  const cls = line.type === "add" ? "diff-add" : line.type === "del" ? "diff-del" : "";
  return (
    <div className={`diff-line ${cls}`}>
      <span className="diff-num">{line.oldLine ?? ""}</span>
      <span className="diff-num">{line.newLine ?? ""}</span>
      <span className="diff-sign">{line.type === "add" ? "+" : line.type === "del" ? "−" : ""}</span>
      <span className="diff-text">
        {line.spans.map((s, i) => (s.mark ? <mark key={i}>{s.text}</mark> : <span key={i}>{s.text}</span>))}
      </span>
    </div>
  );
}

export function DiffView({ hunks }: { hunks: DiffHunk[] }) {
  if (hunks.length === 0) return <p className="rounded-md border bg-card p-4 text-muted-foreground">Bu iki sürümün metni aynı.</p>;
  return (
    <div className="diff overflow-hidden rounded-md border bg-card">
      {hunks.map((hunk, i) => (
        <div key={i}>
          {i > 0 && <div className="diff-gap">değişmeyen satırlar</div>}
          {hunk.lines.map((line, k) => (
            <Line key={k} line={line} />
          ))}
        </div>
      ))}
    </div>
  );
}
