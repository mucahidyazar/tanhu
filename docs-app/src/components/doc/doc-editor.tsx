"use client";

// Düzenleyici: solda markdown, sağda canlı önizleme. Kaydetmek yeni sürüm açar; arada belge değiştiyse sorar.
// Yazılan metin tarayıcıda taslak olarak da durur: sayfa kapanırsa kaybolmaz.
import { markdown } from "@codemirror/lang-markdown";
import { HighlightStyle, syntaxHighlighting } from "@codemirror/language";
import { EditorSelection } from "@codemirror/state";
import { EditorView, type ViewUpdate } from "@codemirror/view";
import { tags } from "@lezer/highlight";
import CodeMirror, { type ReactCodeMirrorRef } from "@uiw/react-codemirror";
import { ArrowLeft, Columns2, Loader2, Save } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useDeferredValue, useEffect, useMemo, useRef, useState, useTransition } from "react";
import { toast } from "sonner";
import { MarkdownView } from "@/components/doc/markdown-view";
import type { AssetCard } from "@/lib/assets";
import { legacyDocId } from "@/lib/ids";
import type { ProgressView } from "@/lib/progress";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from "@/components/ui/alert-dialog";
import { Button, buttonVariants } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { saveDocAction } from "@/lib/actions";
import { extractHeadings } from "@/lib/markdown";
import { NO_STATUS, STATUSES } from "@/lib/statuses";
import { cn } from "@/lib/utils";

export interface EditorDoc {
  id: string;
  kind: "sayfa" | "kaynak";
  title: string;
  summary: string;
  status: string | null;
  relPath: string;
}

interface Draft {
  text: string;
  rev: number;
}

const STATUS_ITEMS = [{ value: NO_STATUS, label: "Durum yok" }, ...Object.entries(STATUSES).map(([value, label]) => ({ value, label }))];

const editorTheme = EditorView.theme({
  "&": { backgroundColor: "var(--card)", color: "var(--foreground)" },
  ".cm-content": { caretColor: "var(--foreground)", padding: "0.75rem 0" },
  ".cm-gutters": { backgroundColor: "var(--muted)", color: "var(--muted-foreground)", border: "none" },
  ".cm-activeLine": { backgroundColor: "color-mix(in oklab, var(--accent) 45%, transparent)" },
  ".cm-activeLineGutter": { backgroundColor: "var(--accent)" },
  ".cm-cursor": { borderLeftColor: "var(--foreground)" },
  "&.cm-focused .cm-selectionBackground, .cm-selectionBackground, ::selection": { backgroundColor: "color-mix(in oklab, var(--ring) 40%, transparent) !important" },
  ".cm-panels": { backgroundColor: "var(--muted)", color: "var(--foreground)" },
  ".cm-searchMatch": { backgroundColor: "color-mix(in oklab, var(--ring) 35%, transparent)" },
});

const editorHighlight = syntaxHighlighting(
  HighlightStyle.define([
    { tag: tags.heading, fontWeight: "700", color: "var(--primary)" },
    { tag: tags.strong, fontWeight: "700" },
    { tag: tags.emphasis, fontStyle: "italic" },
    { tag: [tags.link, tags.url], color: "var(--bronze)" },
    { tag: tags.monospace, color: "var(--kusak)" },
    { tag: tags.quote, color: "var(--muted-foreground)" },
    { tag: [tags.processingInstruction, tags.contentSeparator, tags.meta], color: "var(--muted-foreground)" },
  ]),
);

export function DocEditor({
  doc,
  initialText,
  baseRev,
  startLine,
  assets,
  progress,
}: {
  doc: EditorDoc;
  initialText: string;
  baseRev: number;
  startLine: number | null;
  assets?: Record<string, AssetCard>;
  progress?: ProgressView;
}) {
  const router = useRouter();
  const draftKey = `tanhu:taslak:${doc.id}`;
  // Açılıştaki hâl sabittir: sunucu yeni sürümle yeniden çizse de yazılan metin ve çakışma denetimi buna bağlı kalır.
  const [opened] = useState(() => ({ text: initialText, title: doc.title, summary: doc.summary, status: doc.status ?? NO_STATUS }));
  const [base, setBase] = useState(baseRev);
  const [text, setText] = useState(opened.text);
  const [title, setTitle] = useState(opened.title);
  const [summary, setSummary] = useState(opened.summary);
  const [status, setStatus] = useState<string>(opened.status);
  const [message, setMessage] = useState("");
  const [preview, setPreview] = useState(true);
  const [draft, setDraft] = useState<Draft | null>(null);
  const [conflict, setConflict] = useState<number | null>(null);
  const [pending, startTransition] = useTransition();
  const deferred = useDeferredValue(text);
  const editor = useRef<ReactCodeMirrorRef>(null);
  const previewPane = useRef<HTMLDivElement>(null);
  const saved = useRef(false);

  const dirty = text !== opened.text || title !== opened.title || summary !== opened.summary || status !== opened.status;
  const extensions = useMemo(() => [markdown(), EditorView.lineWrapping, editorTheme, editorHighlight], []);

  useEffect(() => {
    try {
      // Adresler İngilizceye geçmeden önce yazılmış taslak eski kimliğin anahtarındadır: bulunursa yeni anahtara taşınır.
      const legacy = legacyDocId(doc.id);
      const legacyKey = legacy ? `tanhu:taslak:${legacy}` : null;
      if (legacyKey && localStorage.getItem(draftKey) === null) {
        const old = localStorage.getItem(legacyKey);
        if (old !== null) localStorage.setItem(draftKey, old);
        localStorage.removeItem(legacyKey);
      }
      const stored = JSON.parse(localStorage.getItem(draftKey) ?? "null") as Draft | null;
      if (stored && stored.text !== opened.text) setDraft(stored);
    } catch {
      // Tarayıcı depolaması kapalıysa ya da kayıt bozuksa taslak tutulmaz.
    }
  }, [doc.id, draftKey, opened.text]);

  useEffect(() => {
    if (!dirty || saved.current) return;
    const timer = setTimeout(() => {
      try {
        localStorage.setItem(draftKey, JSON.stringify({ text, rev: base } satisfies Draft));
      } catch {
        // Taslak yalnız kolaylıktır.
      }
    }, 800);
    return () => clearTimeout(timer);
  }, [base, dirty, draftKey, text]);

  useEffect(() => {
    const warn = (e: BeforeUnloadEvent) => {
      if (dirty && !saved.current) e.preventDefault();
    };
    window.addEventListener("beforeunload", warn);
    return () => window.removeEventListener("beforeunload", warn);
  }, [dirty]);

  const clearDraft = useCallback(() => {
    try {
      localStorage.removeItem(draftKey);
    } catch {
      // Taslak yalnız kolaylıktır.
    }
    setDraft(null);
  }, [draftKey]);

  const save = useCallback(
    (force = false) => {
      startTransition(async () => {
        try {
          const result = await saveDocAction({ id: doc.id, body: text, message, baseRev: base, force, title, summary, status });
          if (!result.ok) {
            setConflict(result.latest.n);
            return;
          }
          saved.current = true;
          clearDraft();
          toast.success(result.unchanged ? "Değişiklik yok" : `Sürüm ${result.revision.n} kaydedildi`);
          router.push(`/docs/${doc.id}`);
        } catch (error) {
          toast.error(error instanceof Error ? error.message : "Kaydedilemedi");
        }
      });
    },
    [base, clearDraft, doc.id, message, router, status, summary, text, title],
  );

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "s") {
        e.preventDefault();
        if (dirty && !pending) save();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [dirty, pending, save]);

  // Önizleme, imlecin bulunduğu bölüme gider: uzun belgede düzenlenen yer görünür kalır.
  const headings = useMemo(() => extractHeadings(deferred), [deferred]);
  const lastHeading = useRef<string | null>(null);
  const followCursor = useCallback(
    (line: number) => {
      // Kaynak belgede metin ön başlık satırını da taşır; satır yine metnin kendi satırıdır.
      const current = headings.filter((h) => h.line <= line).at(-1);
      if (!current || current.id === lastHeading.current) return;
      lastHeading.current = current.id;
      previewPane.current?.querySelector(`[id="${current.id}"]`)?.scrollIntoView({ block: "start" });
    },
    [headings],
  );

  // ?line=N: düzenleyici o başlıkta açılır.
  const onCreate = useCallback(
    (view: EditorView) => {
      if (!startLine || startLine > view.state.doc.lines) return;
      const pos = view.state.doc.line(startLine).from;
      view.dispatch({ selection: EditorSelection.cursor(pos), effects: EditorView.scrollIntoView(pos, { y: "start", yMargin: 24 }) });
      view.focus();
    },
    [startLine],
  );
  const onUpdate = useCallback(
    (update: ViewUpdate) => {
      if (update.selectionSet || update.docChanged) followCursor(update.state.doc.lineAt(update.state.selection.main.head).number);
    },
    [followCursor],
  );

  return (
    <div className="flex h-dvh min-h-0 flex-col">
      <div className="flex flex-wrap items-center gap-2 border-b bg-card px-4 py-2">
        <Link href={`/docs/${doc.id}`} prefetch={false} className={buttonVariants({ variant: "ghost", size: "sm" })}>
          <ArrowLeft /> Geri
        </Link>
        <div className="min-w-0 flex-1 truncate font-medium">
          {doc.title} <span className="text-sm font-normal text-muted-foreground">· düzenleniyor, temel sürüm {base}</span>
        </div>
        <Button variant="ghost" size="sm" aria-pressed={preview} onClick={() => setPreview((v) => !v)}>
          <Columns2 /> {preview ? "Önizlemeyi kapat" : "Önizleme"}
        </Button>
        <Input value={message} onChange={(e) => setMessage(e.target.value)} placeholder="Ne değişti? (isteğe bağlı)" className="w-64" aria-label="Değişiklik notu" />
        <Button size="sm" disabled={!dirty || pending} onClick={() => save()}>
          {pending ? <Loader2 className="animate-spin" /> : <Save />} Kaydet
        </Button>
      </div>
      {doc.kind === "sayfa" && (
        <div className="grid gap-3 border-b bg-card px-4 py-2 sm:grid-cols-[minmax(0,1fr)_minmax(0,2fr)_auto]">
          <div className="grid gap-1">
            <Label htmlFor="doc-title" className="text-xs text-muted-foreground">Başlık</Label>
            <Input id="doc-title" value={title} onChange={(e) => setTitle(e.target.value)} />
          </div>
          <div className="grid gap-1">
            <Label htmlFor="doc-summary" className="text-xs text-muted-foreground">Özet</Label>
            <Input id="doc-summary" value={summary} onChange={(e) => setSummary(e.target.value)} />
          </div>
          <div className="grid gap-1">
            <Label className="text-xs text-muted-foreground">Durum</Label>
            <Select items={STATUS_ITEMS} value={status} onValueChange={(v) => setStatus(String(v))}>
              <SelectTrigger className="w-40">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {STATUS_ITEMS.map((s) => (
                  <SelectItem key={s.value} value={s.value}>{s.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>
      )}
      {doc.kind === "kaynak" && (
        <p className="border-b bg-card px-4 py-1.5 text-xs text-muted-foreground">
          Bu bir kaynak belge. Kaydedince <span className="font-mono">{doc.relPath}</span> dosyası değişir; oyunun geliştirilmesinde bağlayıcıdır.
        </p>
      )}
      {draft !== null && (
        <div className="flex flex-wrap items-center gap-2 border-b bg-accent px-4 py-2 text-sm">
          <span className="flex-1">
            Bu belge için kaydedilmemiş bir taslağın var{draft.rev !== base ? ` (${draft.rev}. sürümden başlamıştın, belge şimdi ${base}. sürümde)` : ""}.
          </span>
          {/* Taslak kendi sürümüyle açılır: arada değişiklik varsa kaydederken çakışma sorulur. */}
          <Button size="xs" onClick={() => { setText(draft.text); setBase(draft.rev); setDraft(null); }}>Taslağı aç</Button>
          <Button size="xs" variant="ghost" onClick={clearDraft}>Sil</Button>
        </div>
      )}
      <div className={cn("grid min-h-0 flex-1", preview ? "lg:grid-cols-2" : "grid-cols-1")}>
        <div className="min-h-0 overflow-hidden">
          <CodeMirror
            ref={editor}
            value={text}
            onChange={setText}
            onCreateEditor={onCreate}
            onUpdate={onUpdate}
            theme="none"
            height="100%"
            style={{ height: "100%" }}
            extensions={extensions}
            basicSetup={{ foldGutter: false, highlightActiveLineGutter: true }}
          />
        </div>
        {preview && (
          <div ref={previewPane} className="hidden min-h-0 overflow-y-auto border-l bg-background px-6 py-5 lg:block">
            <article className="doc mx-auto max-w-[46rem]">
              <MarkdownView source={deferred} assets={assets} progress={progress} />
            </article>
          </div>
        )}
      </div>
      <AlertDialog open={conflict !== null} onOpenChange={(v) => !v && setConflict(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Belge sen düzenlerken değişti</AlertDialogTitle>
            <AlertDialogDescription>
              Sen {base}. sürümden başladın, şu an {conflict}. sürüm var. Yine de kaydedersen arada gelen değişikliğin üstüne yazılır; o sürüm geçmişte durur, oradan geri alınabilir.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Vazgeç</AlertDialogCancel>
            <AlertDialogAction onClick={() => { setConflict(null); save(true); }}>Yine de kaydet</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
