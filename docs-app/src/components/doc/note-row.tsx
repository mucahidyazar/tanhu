"use client";

// Tek not: tür, metin, alıntı, bölüme bağlantı; çözüldü işareti ve silme.
import { Check, RotateCcw, Trash2 } from "lucide-react";
import Link from "next/link";
import { useState, useTransition } from "react";
import { toast } from "sonner";
import { deleteNoteAction, updateNoteAction } from "@/lib/actions";
import { NOTE_KINDS } from "@/lib/statuses";
import type { Note } from "@/lib/store";
import { formatShort } from "@/lib/text";
import { cn } from "@/lib/utils";

export function NoteRow({ note, showDoc, docTitle }: { note: Note; showDoc?: boolean; docTitle?: string }) {
  const [pending, startTransition] = useTransition();
  const [confirming, setConfirming] = useState(false);
  const run = (work: () => Promise<unknown>) =>
    startTransition(async () => {
      try {
        await work();
      } catch (error) {
        toast.error(error instanceof Error ? error.message : "İşlem yapılamadı");
      }
    });
  const href = `/docs/${note.docId}${note.anchor ? `#${note.anchor}` : ""}`;
  return (
    <article className={cn("rounded-md border bg-card p-2.5 text-[0.88rem] leading-snug", note.done && "opacity-70", pending && "opacity-50")}>
      <div className="mb-1 flex items-center gap-2 text-xs text-muted-foreground">
        <span className={cn("font-medium", note.kind === "duzelt" && "text-kusak", note.kind === "karar" && "text-primary", note.kind === "soru" && "text-bronze")}>{NOTE_KINDS[note.kind] ?? note.kind}</span>
        <span className="flex-1">{formatShort(note.at)}</span>
        <button
          type="button"
          title={note.done ? "Yeniden aç" : "Çözüldü"}
          aria-label={note.done ? "Notu yeniden aç" : "Not çözüldü"}
          className="rounded-sm p-1 hover:bg-accent hover:text-foreground"
          onClick={() => run(() => updateNoteAction(note.id, { done: !note.done }))}
        >
          {note.done ? <RotateCcw className="size-3.5" /> : <Check className="size-3.5" />}
        </button>
        {confirming ? (
          // Tarayıcının onay penceresi uygulama panelinde çıkmıyor, soru satırın içinde sorulur.
          <span className="flex items-center gap-1">
            Silinsin mi?
            <button type="button" className="rounded-sm px-1.5 py-0.5 font-medium text-destructive hover:bg-accent" onClick={() => run(() => deleteNoteAction(note.id))}>Sil</button>
            <button type="button" className="rounded-sm px-1.5 py-0.5 hover:bg-accent hover:text-foreground" onClick={() => setConfirming(false)}>Vazgeç</button>
          </span>
        ) : (
          <button type="button" title="Sil" aria-label="Notu sil" className="rounded-sm p-1 hover:bg-accent hover:text-destructive" onClick={() => setConfirming(true)}>
            <Trash2 className="size-3.5" />
          </button>
        )}
      </div>
      <p className={cn("whitespace-pre-wrap", note.done && "line-through decoration-muted-foreground/50")}>{note.text}</p>
      {note.quote ? <blockquote className="mt-1.5 line-clamp-3 border-l-2 border-bronze/60 pl-2 font-serif text-[0.85rem] italic text-muted-foreground">{note.quote}</blockquote> : null}
      {(showDoc || note.anchorTitle) && (
        <Link href={href} prefetch={false} className="mt-1.5 block truncate text-xs text-muted-foreground underline decoration-border underline-offset-2 hover:text-foreground">
          {showDoc ? docTitle : ""}
          {showDoc && note.anchorTitle ? " › " : ""}
          {note.anchorTitle || ""}
        </Link>
      )}
    </article>
  );
}
