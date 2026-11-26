// Yol Haritası metinlerinde `ters tırnaklı` kimlikler kod olarak görünür (madde başlığı, not, faz ve perde metinleri).
import { Fragment } from "react";

export function InlineText({ text }: { text: string }) {
  const parts = text.split("`");
  // Tek sayıda ters tırnak varsa son parça düz metin kalır.
  return (
    <>
      {parts.map((part, i) =>
        i % 2 === 1 && i < parts.length - 1 ? (
          <code key={i} className="rounded-sm bg-muted px-1 py-px font-mono text-[0.86em]">
            {part}
          </code>
        ) : (
          <Fragment key={i}>{i % 2 === 1 ? `\`${part}` : part}</Fragment>
        ),
      )}
    </>
  );
}
