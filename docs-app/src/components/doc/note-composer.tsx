"use client";

// Not alma: başlıktaki düğme, seçili metnin üstündeki düğme ve sayfa düğmesi aynı pencereyi açar.
import { StickyNote } from "lucide-react";
import { createContext, type ReactNode, useCallback, useContext, useEffect, useRef, useState, useTransition } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { addNoteAction } from "@/lib/actions";
import { NOTE_KINDS } from "@/lib/statuses";

export interface NoteDraft {
  anchor: string;
  anchorTitle: string;
  quote: string;
}

const EMPTY: NoteDraft = { anchor: "", anchorTitle: "", quote: "" };
const KIND_ITEMS = Object.entries(NOTE_KINDS).map(([value, label]) => ({ value, label }));
const KIND_PROMPT: Record<string, string> = { duzelt: "Ne düzeltilmeli?", karar: "Kararın ne?", soru: "Sorun ne?", fikir: "Fikrin ne?" };

const ComposerContext = createContext<(draft?: Partial<NoteDraft>) => void>(() => {});
export const useNoteComposer = () => useContext(ComposerContext);

export function NoteComposerProvider({ docId, children }: { docId: string; children: ReactNode }) {
  const [draft, setDraft] = useState<NoteDraft | null>(null);
  const [text, setText] = useState("");
  const [kind, setKind] = useState<string>("duzelt");
  const [pending, startTransition] = useTransition();

  const open = useCallback((next?: Partial<NoteDraft>) => {
    setDraft({ ...EMPTY, ...next });
    setText("");
  }, []);

  const save = () => {
    if (!draft || !text.trim() || pending) return;
    startTransition(async () => {
      try {
        await addNoteAction({ docId, kind, text, ...draft });
        toast.success("Not eklendi");
        setDraft(null);
      } catch (error) {
        toast.error(error instanceof Error ? error.message : "Not kaydedilemedi");
      }
    });
  };

  return (
    <ComposerContext.Provider value={open}>
      {children}
      <Dialog open={draft !== null} onOpenChange={(v) => !v && setDraft(null)}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>Not al</DialogTitle>
            <DialogDescription>{draft?.anchorTitle ? `Bölüm: ${draft.anchorTitle}` : "Bütün sayfa için"}</DialogDescription>
          </DialogHeader>
          {draft?.quote ? (
            <blockquote className="max-h-28 overflow-y-auto border-l-2 border-bronze pl-3 font-serif text-sm italic text-muted-foreground">{draft.quote}</blockquote>
          ) : null}
          <div className="grid gap-1.5">
            <Label htmlFor="note-text">{KIND_PROMPT[kind]}</Label>
            <Textarea
              id="note-text"
              autoFocus
              rows={4}
              value={text}
              onChange={(e) => setText(e.target.value)}
              onKeyDown={(e) => {
                if ((e.metaKey || e.ctrlKey) && e.key === "Enter") save();
              }}
            />
          </div>
          <div className="grid gap-1.5">
            <Label>Tür</Label>
            <Select items={KIND_ITEMS} value={kind} onValueChange={(v) => setKind(String(v))}>
              <SelectTrigger className="w-44">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {KIND_ITEMS.map((k) => (
                  <SelectItem key={k.value} value={k.value}>{k.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <DialogFooter>
            <Button onClick={save} disabled={!text.trim() || pending}>Notu kaydet</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </ComposerContext.Provider>
  );
}

export function NoteButton({ label = "Not al" }: { label?: string }) {
  const open = useNoteComposer();
  return (
    <Button variant="outline" size="sm" onClick={() => open()}>
      <StickyNote /> {label}
    </Button>
  );
}

// Seçili metnin üstünde beliren düğme: seçimi alıntı, üstteki başlığı bölüm yapar.
export function SelectionNote({ children }: { children: ReactNode }) {
  const open = useNoteComposer();
  const root = useRef<HTMLDivElement>(null);
  const [spot, setSpot] = useState<{ x: number; y: number } | null>(null);

  useEffect(() => {
    const update = () => {
      const sel = window.getSelection();
      if (!sel || sel.isCollapsed || sel.rangeCount === 0 || !root.current) return setSpot(null);
      const range = sel.getRangeAt(0);
      if (!root.current.contains(range.commonAncestorContainer) || sel.toString().trim().length < 3) return setSpot(null);
      const rect = range.getBoundingClientRect();
      setSpot({ x: rect.left + rect.width / 2, y: rect.top });
    };
    const hide = () => setSpot(null);
    document.addEventListener("selectionchange", update);
    window.addEventListener("scroll", hide, { passive: true });
    return () => {
      document.removeEventListener("selectionchange", update);
      window.removeEventListener("scroll", hide);
    };
  }, []);

  const take = () => {
    const sel = window.getSelection();
    if (!sel || sel.rangeCount === 0 || !root.current) return;
    const start = sel.getRangeAt(0).startContainer;
    const headings = [...root.current.querySelectorAll<HTMLElement>("h2[id],h3[id],h4[id]")];
    const above = headings.filter((h) => h.compareDocumentPosition(start) & Node.DOCUMENT_POSITION_FOLLOWING).at(-1);
    open({ anchor: above?.id ?? "", anchorTitle: above?.dataset.title ?? "", quote: sel.toString().trim() });
    setSpot(null);
  };

  return (
    <div ref={root}>
      {children}
      {spot && (
        <Button
          size="sm"
          className="fixed z-40 -translate-x-1/2 -translate-y-full shadow-md"
          style={{ left: spot.x, top: spot.y - 6 }}
          onMouseDown={(e) => e.preventDefault()}
          onClick={take}
        >
          <StickyNote /> Not al
        </Button>
      )}
    </div>
  );
}
