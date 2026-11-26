// Notlar: sayfalara düşülen notlar (açık / çözülen) ve kullanıcının elle yazdığı tasarım notları («Yazdığın notlar»,
// kaynağı content/pages/general/my-notes.md) tek sayfada. Sayfa notlarının dosyası data/notes.json: sonraki bir oturum
// notları oradan okuyup belgelere işleyebilir.
import { History, Pencil } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";
import { Kusak } from "@/components/brand";
import { MarkdownView } from "@/components/doc/markdown-view";
import { NoteRow } from "@/components/doc/note-row";
import { buttonVariants } from "@/components/ui/button";
import { assetCards, readCatalog } from "@/lib/assets";
import { allDocs, bodyOf, getDoc, groupTitle, readDocText } from "@/lib/catalog";
import { syncDoc } from "@/lib/history";
import { progressView } from "@/lib/progress";
import { listNotes } from "@/lib/store";
import { formatShort } from "@/lib/text";
import { cn } from "@/lib/utils";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "Notlar" };

// Elle yazılan notların sayfası: kenar çubuğunda ayrıca görünmez, /docs/general/my-notes buraya yönlenir.
const WRITTEN_NOTES_DOC = "general/my-notes";

type View = "open" | "resolved" | "written";

function viewOf(view?: string, gor?: string): View {
  if (view === "written") return "written";
  if (view === "resolved" || gor === "cozulen") return "resolved";
  return "open";
}

function WrittenNotes() {
  const doc = getDoc(WRITTEN_NOTES_DOC);
  if (!doc) return <p className="mt-8 rounded-md border bg-card p-5 text-muted-foreground">Yazdığın not sayfası bulunamadı ({WRITTEN_NOTES_DOC}).</p>;
  const revision = syncDoc(doc);
  const body = bodyOf(doc, readDocText(doc));
  return (
    <section className="mt-8" aria-labelledby="yazdigin-notlar">
      <div className="flex flex-wrap items-center gap-2">
        <h2 id="yazdigin-notlar" className="sr-only">Yazdığın notlar</h2>
        {doc.summary ? <p className="min-w-0 flex-1 font-serif text-[1.05rem] italic leading-snug text-muted-foreground">{doc.summary}</p> : <span className="flex-1" />}
        <Link href={`/history/${doc.id}`} prefetch={false} className="inline-flex items-center gap-1 rounded-sm border px-1.5 py-0.5 text-xs text-muted-foreground hover:text-foreground">
          <History className="size-3" /> Sürüm {revision.n} · {formatShort(revision.at)}
        </Link>
        <Link href={`/edit/${doc.id}`} prefetch={false} className={buttonVariants({ size: "sm" })}>
          <Pencil /> Düzenle
        </Link>
      </div>
      <article className="doc mt-6">
        <MarkdownView source={body} assets={assetCards(readCatalog())} progress={progressView()} />
      </article>
    </section>
  );
}

export default async function NotesPage({ searchParams }: { searchParams: Promise<{ view?: string; gor?: string }> }) {
  const { view: rawView, gor } = await searchParams;
  const view = viewOf(rawView, gor);
  const all = listNotes();
  const openCount = all.filter((n) => !n.done).length;
  const doneCount = all.length - openCount;
  const tab = (active: boolean) => cn("rounded-sm px-2.5 py-1", active && "bg-accent font-medium");
  const tabs = [
    { view: "open" as const, href: "/notes", label: `Açık · ${openCount}` },
    { view: "resolved" as const, href: "/notes?view=resolved", label: `Çözülen · ${doneCount}` },
    { view: "written" as const, href: "/notes?view=written", label: "Yazdığın notlar" },
  ];

  let pageNotes = null;
  if (view !== "written") {
    const showDone = view === "resolved";
    const notes = all.filter((n) => n.done === showDone);
    const byDoc = allDocs()
      .map((doc) => ({ doc, notes: notes.filter((n) => n.docId === doc.id) }))
      .filter((row) => row.notes.length > 0);
    pageNotes = (
      <>
        {byDoc.length === 0 && (
          <p className="mt-8 rounded-md border bg-card p-5 text-muted-foreground">
            {showDone ? "Henüz çözülen not yok." : "Açık not yok. Bir sayfada metni seçip «Not al»a bas."}
          </p>
        )}
        {byDoc.map(({ doc, notes: rows }) => (
          <section key={doc.id} className="mt-8">
            <h2 className="font-bold">
              <Link href={`/docs/${doc.id}`} prefetch={false} className="hover:underline">{doc.title}</Link>
              <span className="ml-2 text-sm font-normal text-muted-foreground">{groupTitle(doc.group)}</span>
            </h2>
            <div className="mt-2 grid gap-2">
              {rows.map((note) => (
                <NoteRow key={note.id} note={note} />
              ))}
            </div>
          </section>
        ))}
      </>
    );
  }

  return (
    <main className={cn("mx-auto w-full px-5 py-10 lg:px-10", view === "written" ? "max-w-[50rem]" : "max-w-3xl")}>
      <h1 className="font-display text-3xl font-medium tracking-wide">Notlar</h1>
      <Kusak className="mt-3" />
      <p className="mt-4 font-serif text-lg text-muted-foreground">
        Sayfalara düştüğün notlar ve elle yazdığın tasarım notları. Sayfa notunu çözünce buradan işaretle; yazdığın notların her maddesinin hangi sayfaya gittiği «Yazdığın notlar»da.
      </p>
      <div className="mt-5 inline-flex flex-wrap rounded-md border p-0.5 text-sm" role="group" aria-label="Görünüm">
        {tabs.map((t) => (
          <Link key={t.view} href={t.href} prefetch={false} aria-current={view === t.view ? "page" : undefined} className={tab(view === t.view)}>
            {t.label}
          </Link>
        ))}
      </div>
      {view === "written" ? <WrittenNotes /> : pageNotes}
    </main>
  );
}
