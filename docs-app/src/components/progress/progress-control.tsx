"use client";

// Bir işin durumu: üç düğme (Yapılacak, Sürüyor, Bitti) ve not penceresi. Her değişiklik işin geçmişine yazılır.
import { Check, CircleDashed, LoaderCircle, StickyNote } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { setProgressAction } from "@/lib/actions";
import { PROGRESS_STATES, type ProgressState } from "@/lib/statuses";
import { cn } from "@/lib/utils";

const ICONS: Record<ProgressState, typeof Check> = { yapilacak: CircleDashed, suruyor: LoaderCircle, bitti: Check };
const ORDER: ProgressState[] = ["yapilacak", "suruyor", "bitti"];

export function ProgressControl({ id, title, status, note }: { id: string; title: string; status: ProgressState; note: string }) {
  const [pending, startTransition] = useTransition();
  const [open, setOpen] = useState(false);
  const [draft, setDraft] = useState(note);
  const [noteStatus, setNoteStatus] = useState<ProgressState>(status);

  const save = (next: ProgressState, text?: string) =>
    startTransition(async () => {
      try {
        await setProgressAction({ id, status: next, note: text });
        toast.success(`${title}: ${PROGRESS_STATES[next]}`);
        setOpen(false);
      } catch (error) {
        toast.error(error instanceof Error ? error.message : "İşaretlenemedi");
      }
    });

  return (
    <div className="flex items-center gap-1.5">
      <div role="radiogroup" aria-label={`${title} durumu`} className={cn("inline-flex rounded-md border bg-card p-0.5", pending && "opacity-60")}>
        {ORDER.map((s) => {
          const Icon = ICONS[s];
          const active = s === status;
          return (
            <button
              key={s}
              type="button"
              role="radio"
              aria-checked={active}
              disabled={pending}
              onClick={() => !active && save(s)}
              title={PROGRESS_STATES[s]}
              className={cn(
                "inline-flex items-center gap-1 rounded-sm px-2 py-0.5 text-xs text-muted-foreground transition-colors hover:text-foreground",
                active && s === "bitti" && "bg-primary text-primary-foreground hover:text-primary-foreground",
                active && s === "suruyor" && "bg-bronze/25 text-foreground",
                active && s === "yapilacak" && "bg-muted text-foreground",
              )}
            >
              <Icon className="size-3" />
              <span className="hidden sm:inline">{PROGRESS_STATES[s]}</span>
            </button>
          );
        })}
      </div>
      <Button
        variant="ghost"
        size="icon-xs"
        aria-label={`${title}: not yaz`}
        title="Not yaz"
        onClick={() => {
          setDraft(note);
          setNoteStatus(status);
          setOpen(true);
        }}
      >
        <StickyNote />
      </Button>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>{title}</DialogTitle>
            <DialogDescription>Not ve durum işin geçmişine tarihiyle yazılır.</DialogDescription>
          </DialogHeader>
          <div className="grid gap-1.5">
            <Label htmlFor={`progress-note-${id}`}>Not</Label>
            <Textarea
              id={`progress-note-${id}`}
              rows={4}
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              placeholder="Ne yapıldı, ne kaldı?"
              onKeyDown={(e) => {
                if ((e.metaKey || e.ctrlKey) && e.key === "Enter") save(noteStatus, draft);
              }}
            />
          </div>
          <div className="grid gap-1.5">
            <Label>Durum</Label>
            <div className="inline-flex w-fit rounded-md border bg-card p-0.5">
              {ORDER.map((s) => (
                <button
                  key={s}
                  type="button"
                  onClick={() => setNoteStatus(s)}
                  aria-pressed={noteStatus === s}
                  className={cn("rounded-sm px-2.5 py-1 text-sm", noteStatus === s ? "bg-accent font-medium" : "text-muted-foreground")}
                >
                  {PROGRESS_STATES[s]}
                </button>
              ))}
            </div>
          </div>
          <DialogFooter>
            <Button disabled={pending} onClick={() => save(noteStatus, draft)}>
              Kaydet
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
