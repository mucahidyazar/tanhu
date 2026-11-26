"use client";

// Sağ kenar: içindekiler (okunan bölüm işaretli) ve bu sayfanın notları.
import { useEffect, useState } from "react";
import { NoteRow } from "@/components/doc/note-row";
import type { Heading } from "@/lib/markdown";
import type { Note } from "@/lib/store";
import { cn } from "@/lib/utils";

function useActiveHeading(ids: string[]) {
  const [active, setActive] = useState<string | null>(null);
  useEffect(() => {
    if (ids.length === 0) return;
    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries.filter((e) => e.isIntersecting).sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top);
        if (visible[0]) setActive(visible[0].target.id);
      },
      { rootMargin: "0px 0px -75% 0px" },
    );
    for (const id of ids) {
      const el = document.getElementById(id);
      if (el) observer.observe(el);
    }
    return () => observer.disconnect();
  }, [ids]);
  return active;
}

export function DocRail({ headings, notes }: { headings: Heading[]; notes: Note[] }) {
  const toc = headings.filter((h) => h.depth <= 3);
  const [ids] = useState(() => toc.map((h) => h.id));
  const active = useActiveHeading(ids);
  const open = notes.filter((n) => !n.done);
  const done = notes.filter((n) => n.done);
  return (
    <div className="space-y-6">
      {toc.length > 1 && (
        <nav aria-label="Bu sayfada" className="hidden xl:block">
          <h2 className="mb-2 font-display text-[0.7rem] font-medium uppercase tracking-[0.16em] text-muted-foreground">Bu sayfada</h2>
          <ul className="space-y-0.5 border-l text-[0.85rem] leading-snug">
            {toc.map((h) => (
              <li key={h.id}>
                <a
                  href={`#${h.id}`}
                  className={cn(
                    "-ml-px block border-l py-0.5 pr-1 text-muted-foreground hover:text-foreground",
                    h.depth === 3 ? "pl-5" : "pl-3",
                    active === h.id && "border-bronze font-medium text-foreground",
                  )}
                >
                  {h.text}
                </a>
              </li>
            ))}
          </ul>
        </nav>
      )}
      <section id="notlar" aria-label="Bu sayfanın notları" className="scroll-mt-6">
        <h2 className="mb-2 font-display text-[0.7rem] font-medium uppercase tracking-[0.16em] text-muted-foreground">Notlar{open.length > 0 ? ` · ${open.length}` : ""}</h2>
        {open.length === 0 && done.length === 0 && (
          <p className="text-[0.85rem] text-muted-foreground">Metni seçip «Not al»a bas ya da başlığın yanındaki düğmeyi kullan.</p>
        )}
        <div className="space-y-2">
          {open.map((note) => (
            <NoteRow key={note.id} note={note} />
          ))}
        </div>
        {done.length > 0 && (
          <details className="mt-3 text-[0.85rem]">
            <summary className="cursor-pointer text-muted-foreground">{done.length} çözülmüş not</summary>
            <div className="mt-2 space-y-2">
              {done.map((note) => (
                <NoteRow key={note.id} note={note} />
              ))}
            </div>
          </details>
        )}
      </section>
    </div>
  );
}
