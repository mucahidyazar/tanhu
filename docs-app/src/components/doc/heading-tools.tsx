"use client";

// Başlığın yanındaki küçük araçlar: bu bölüme not al, bu bölümü düzenle; bölümün açık not sayısı.
import { MessageSquareText, Pencil, StickyNote } from "lucide-react";
import Link from "next/link";
import { useNoteComposer } from "@/components/doc/note-composer";

export function HeadingTools({ docId, anchor, title, line, notes }: { docId: string; anchor: string; title: string; line: number; notes: number }) {
  const open = useNoteComposer();
  return (
    <span className="ml-2 inline-flex translate-y-[-0.1em] items-center gap-0.5 align-middle font-sans text-sm font-normal">
      {notes > 0 && (
        <a href="#notlar" className="inline-flex items-center gap-1 rounded-sm px-1 text-xs text-bronze no-underline" title={`${notes} açık not`}>
          <MessageSquareText className="size-3.5" /> {notes}
        </a>
      )}
      <span className="inline-flex items-center gap-0.5 opacity-0 transition-opacity focus-within:opacity-100 group-hover/heading:opacity-100">
        <button
          type="button"
          title="Bu bölüme not al"
          aria-label={`«${title}» bölümüne not al`}
          onClick={() => open({ anchor, anchorTitle: title })}
          className="rounded-sm p-1 text-muted-foreground hover:bg-accent hover:text-foreground"
        >
          <StickyNote className="size-3.5" />
        </button>
        <Link
          href={`/edit/${docId}?line=${line}`}
          prefetch={false}
          title="Bu bölümü düzenle"
          aria-label={`«${title}» bölümünü düzenle`}
          className="rounded-sm p-1 text-muted-foreground hover:bg-accent hover:text-foreground"
        >
          <Pencil className="size-3.5" />
        </Link>
      </span>
    </span>
  );
}
