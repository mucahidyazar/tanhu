// Okuma ekranı: sayfa ya da kaynak belge; kategori adresinde kategorinin içindekiler listesi.
import { CircleAlert, FolderOpen, History, Pencil } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Kusak } from "@/components/brand";
import { AssetStrip } from "@/components/doc/asset-strip";
import { DocRail } from "@/components/doc/doc-rail";
import { PendingList } from "@/components/doc/pending-list";
import { HeadingTools } from "@/components/doc/heading-tools";
import { MarkdownView } from "@/components/doc/markdown-view";
import { NoteButton, NoteComposerProvider, SelectionNote } from "@/components/doc/note-composer";
import { ReviewButton } from "@/components/doc/review-button";
import { StatusBadge, StatusGlyph } from "@/components/shell/status-mark";
import { buttonVariants } from "@/components/ui/button";
import { assetCards, assetsOfPage, readCatalog } from "@/lib/assets";
import { allDocs, bodyOf, CATEGORIES, getDoc, groupTitle, readDocText, SOURCE_GROUPS } from "@/lib/catalog";
import { syncDoc } from "@/lib/history";
import { extractHeadings } from "@/lib/markdown";
import { progressView } from "@/lib/progress";
import { listNotes, readReview } from "@/lib/store";
import { formatShort } from "@/lib/text";

export const dynamic = "force-dynamic";

// Karar Bekleyenler: elle yazılan bekleyen kararların altında sayfalardaki açık soru ve çelişkiler toplanır.
const PENDING_PAGE = "general/pending-decisions";

type Props = { params: Promise<{ id: string[] }> };

const docIdOf = (parts: string[]) => parts.map(decodeURIComponent).join("/");

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const id = docIdOf((await params).id);
  return { title: getDoc(id)?.title ?? (id === "source" ? "Kaynak belgeler" : groupTitle(id)) };
}

function GroupIndex({ id }: { id: string }) {
  const category = CATEGORIES.find((c) => c.id === id);
  const sources = id === "source" ? SOURCE_GROUPS : SOURCE_GROUPS.filter((g) => g.id === id);
  if (!category && sources.length === 0) notFound();
  const docs = allDocs();
  if (category) {
    const items = docs.filter((d) => d.kind === "sayfa" && d.group === id).sort((a, b) => a.order - b.order);
    return (
      <main className="mx-auto w-full max-w-3xl px-5 py-10 lg:px-10">
        <h1 className="font-display text-3xl font-medium tracking-wide">{category.title}</h1>
        <Kusak className="mt-3" />
        <p className="mt-4 font-serif text-lg text-muted-foreground">{category.blurb}</p>
        <ul className="mt-6 divide-y border-y">
          {items.map((d) => (
            <li key={d.id}>
              <Link href={`/docs/${d.id}`} prefetch={false} className="flex items-baseline gap-3 py-3 hover:bg-accent/50">
                <StatusGlyph status={d.status} className="translate-y-px text-bronze" />
                <span className="min-w-0 flex-1">
                  <span className="block font-medium">{d.title}</span>
                  <span className="block text-sm text-muted-foreground">{d.summary}</span>
                </span>
                {d.conflicts > 0 && (
                  <span className="inline-flex items-center gap-1 text-xs text-kusak">
                    <CircleAlert className="size-3.5" /> {d.conflicts}
                  </span>
                )}
              </Link>
            </li>
          ))}
        </ul>
      </main>
    );
  }
  return (
    <main className="mx-auto w-full max-w-3xl px-5 py-10 lg:px-10">
      <h1 className="font-display text-3xl font-medium tracking-wide">Kaynak belgeler</h1>
      <Kusak className="mt-3" />
      <p className="mt-4 font-serif text-lg text-muted-foreground">Oyunun bağlayıcı tasarım belgeleri ve araştırmalar, olduğu gibi. Burada yapılan düzenleme doğrudan dosyaya yazılır.</p>
      {sources.map((g) => (
        <section key={g.id} className="mt-8">
          <h2 className="text-lg font-bold">{g.title}</h2>
          <ul className="mt-2 divide-y border-y">
            {docs.filter((d) => d.group === g.id).map((d) => (
              <li key={d.id}>
                <Link href={`/docs/${d.id}`} prefetch={false} className="block py-2 hover:bg-accent/50">
                  <span className="block font-medium">{d.title}</span>
                  <span className="block font-mono text-xs text-muted-foreground">{d.relPath}</span>
                </Link>
              </li>
            ))}
          </ul>
        </section>
      ))}
    </main>
  );
}

export default async function DocPage({ params }: Props) {
  const id = docIdOf((await params).id);
  const doc = getDoc(id);
  if (!doc) return <GroupIndex id={id} />;

  const revision = syncDoc(doc);
  const text = readDocText(doc);
  const body = bodyOf(doc, text);
  const headings = extractHeadings(body);
  const notes = listNotes().filter((n) => n.docId === doc.id);
  const review = readReview()[doc.id];
  const reviewState = review ? (revision.n > review.rev ? "degisti" : "tamam") : null;
  // Düzenleyici kaynak belgede bütün dosyayı, sayfada yalnız gövdeyi açar: başlık satırı buna göre kayar.
  const lineOffset = doc.kind === "kaynak" ? text.slice(0, text.length - body.length).split("\n").length - 1 : 0;
  const catalog = readCatalog();
  const assets = assetCards(catalog);
  const pageAssets = doc.kind === "sayfa" ? assetsOfPage(doc.id, catalog) : [];
  const PAGE_ASSETS_SHOWN = 24;
  const openByAnchor = new Map<string, number>();
  for (const note of notes) if (!note.done && note.anchor) openByAnchor.set(note.anchor, (openByAnchor.get(note.anchor) ?? 0) + 1);

  return (
    <NoteComposerProvider docId={doc.id}>
      <div className="mx-auto flex w-full max-w-[86rem] flex-1 flex-col gap-8 px-5 py-8 lg:px-10 xl:flex-row">
        <main className="min-w-0 flex-1 xl:max-w-[50rem]">
          <header>
            <Link href={`/docs/${doc.group}`} prefetch={false} className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground">
              <FolderOpen className="size-3.5" /> {groupTitle(doc.group)}
            </Link>
            <h1 className="mt-1 font-display text-[2rem] font-medium leading-tight tracking-wide">{doc.title}</h1>
            <Kusak className="mt-3" />
            {doc.kind === "sayfa" && doc.summary ? <p className="mt-3 font-serif text-[1.2rem] italic leading-snug text-muted-foreground">{doc.summary}</p> : null}
            {doc.kind === "kaynak" ? <p className="mt-3 font-mono text-xs text-muted-foreground">{doc.relPath}</p> : null}
            <div className="mt-4 flex flex-wrap items-center gap-2">
              <StatusBadge status={doc.status} />
              {doc.conflicts > 0 && (
                <span className="inline-flex items-center gap-1 rounded-sm border border-kusak/40 px-1.5 py-0.5 text-xs text-kusak">
                  <CircleAlert className="size-3" /> {doc.conflicts} çelişki
                </span>
              )}
              <Link href={`/history/${doc.id}`} prefetch={false} className="inline-flex items-center gap-1 rounded-sm border px-1.5 py-0.5 text-xs text-muted-foreground hover:text-foreground">
                <History className="size-3" /> Sürüm {revision.n} · {formatShort(revision.at)}
              </Link>
              <span className="flex-1" />
              <ReviewButton docId={doc.id} state={reviewState} />
              <NoteButton />
              <Link href={`/edit/${doc.id}`} prefetch={false} className={buttonVariants({ size: "sm" })}>
                <Pencil /> Düzenle
              </Link>
            </div>
          </header>
          <SelectionNote>
            <article className="doc mt-8">
              <MarkdownView
                source={body}
                assets={assets}
                progress={progressView()}
                headingExtra={(h) => <HeadingTools docId={doc.id} anchor={h.id} title={h.text} line={h.line + lineOffset} notes={openByAnchor.get(h.id) ?? 0} />}
              />
            </article>
          </SelectionNote>
          {doc.id === PENDING_PAGE ? <PendingList /> : null}
          {pageAssets.length > 0 && (
            <section className="mt-12 border-t pt-6" aria-labelledby="sayfanin-varliklari">
              <h2 id="sayfanin-varliklari" className="font-display text-xl font-medium tracking-wide">Bu sayfanın varlıkları</h2>
              <p className="mt-1 text-sm text-muted-foreground">
                Varlık kataloğunda bu sayfaya bağlı {pageAssets.length} varlık.{" "}
                <Link href="/assets" prefetch={false} className="underline underline-offset-2">Bütün varlıklar</Link>
              </p>
              <AssetStrip cards={pageAssets.slice(0, PAGE_ASSETS_SHOWN)} />
              {pageAssets.length > PAGE_ASSETS_SHOWN && (
                <p className="text-sm text-muted-foreground">Ve {pageAssets.length - PAGE_ASSETS_SHOWN} varlık daha; tamamı Varlıklar sayfasının tablolarında.</p>
              )}
            </section>
          )}
        </main>
        <aside className="w-full shrink-0 xl:sticky xl:top-0 xl:h-dvh xl:w-72 xl:overflow-y-auto xl:py-1">
          <DocRail headings={headings} notes={notes} />
        </aside>
      </div>
    </NoteComposerProvider>
  );
}
