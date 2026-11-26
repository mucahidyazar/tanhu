// Sürüm geçmişi: solda sürümler, sağda seçili sürümün önceki sürüme (ya da seçilen sürüme) farkı ya da metni.
import { ArrowLeft } from "lucide-react";
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { DiffView } from "@/components/doc/diff-view";
import { MarkdownView } from "@/components/doc/markdown-view";
import { assetCards } from "@/lib/assets";
import { progressView } from "@/lib/progress";
import { RestoreButton } from "@/components/doc/restore-button";
import { buttonVariants } from "@/components/ui/button";
import { bodyOf, getDoc } from "@/lib/catalog";
import { diffDocs } from "@/lib/diff";
import { listRevisions, readRevision, type RevisionKind, syncDoc } from "@/lib/history";
import { formatLong, formatShort } from "@/lib/text";
import { cn } from "@/lib/utils";

export const dynamic = "force-dynamic";

type Props = {
  params: Promise<{ id: string[] }>;
  searchParams: Promise<{ rev?: string; vs?: string; view?: string; s?: string; karsi?: string; gor?: string }>;
};

const KIND_LABEL: Record<RevisionKind, string> = {
  ilk: "İlk kayıt",
  duzenleme: "Düzenleme",
  "geri-donus": "Geri dönüş",
  disaridan: "Uygulama dışından",
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const doc = getDoc((await params).id.map(decodeURIComponent).join("/"));
  return { title: doc ? `Geçmiş: ${doc.title}` : "Geçmiş" };
}

export default async function HistoryPage({ params, searchParams }: Props) {
  const doc = getDoc((await params).id.map(decodeURIComponent).join("/"));
  if (!doc) notFound();
  const query = await searchParams;
  syncDoc(doc);
  const revisions = listRevisions(doc.id);
  const latest = revisions.at(-1);
  if (!latest) notFound();

  const selected = revisions.find((r) => r.n === Number(query.rev ?? query.s)) ?? latest;
  const against = (query.vs ?? query.karsi) !== undefined ? revisions.find((r) => r.n === Number(query.vs ?? query.karsi)) ?? null : revisions.find((r) => r.n === selected.n - 1) ?? null;
  // Eski adresin sorgusu (s, karsi, gor=metin) da okunur.
  const view = query.view === "text" || query.gor === "metin" ? "metin" : "fark";
  const selectedText = readRevision(doc.id, selected.n) ?? "";
  const againstText = against ? readRevision(doc.id, against.n) ?? "" : "";
  const href = (next: { s?: number; karsi?: number | null; gor?: string }) => {
    const params = new URLSearchParams();
    params.set("rev", String(next.s ?? selected.n));
    if (next.karsi !== null && next.karsi !== undefined) params.set("vs", String(next.karsi));
    if ((next.gor ?? view) === "metin") params.set("view", "text");
    return `/history/${doc.id}?${params}`;
  };

  return (
    <div className="mx-auto flex w-full max-w-[86rem] flex-1 flex-col gap-6 px-5 py-8 lg:flex-row lg:px-10">
      <aside className="w-full shrink-0 lg:w-80">
        <Link href={`/docs/${doc.id}`} prefetch={false} className={cn(buttonVariants({ variant: "ghost", size: "sm" }), "-ml-2")}>
          <ArrowLeft /> Belgeye dön
        </Link>
        <h1 className="mt-2 font-display text-xl font-medium leading-tight tracking-wide">{doc.title}</h1>
        <p className="mt-1 text-sm text-muted-foreground">{revisions.length} sürüm</p>
        <ol className="mt-4 divide-y border-y">
          {[...revisions].reverse().map((r) => (
            <li key={r.n}>
              <Link
                href={href({ s: r.n, karsi: null })}
                prefetch={false}
                aria-current={r.n === selected.n ? "true" : undefined}
                className={cn("block px-2 py-2 text-sm hover:bg-accent/60", r.n === selected.n && "bg-accent")}
              >
                <span className="flex items-baseline gap-2">
                  <span className="font-medium">Sürüm {r.n}</span>
                  <span className="text-xs text-muted-foreground">{formatShort(r.at)}</span>
                  <span className="flex-1" />
                  <span className="font-mono text-xs">
                    <span className="text-[#3f7a3a] dark:text-[#8fc77f]">+{r.added}</span> <span className="text-kusak">−{r.removed}</span>
                  </span>
                </span>
                <span className="mt-0.5 block text-muted-foreground">{r.message || KIND_LABEL[r.kind]}</span>
                {r.message !== KIND_LABEL[r.kind] && <span className="block text-xs text-muted-foreground/80">{KIND_LABEL[r.kind]}</span>}
              </Link>
            </li>
          ))}
        </ol>
      </aside>
      <main className="min-w-0 flex-1">
        <div className="flex flex-wrap items-center gap-2">
          <div className="min-w-0 flex-1">
            <h2 className="text-lg font-bold">Sürüm {selected.n}</h2>
            <p className="text-sm text-muted-foreground">
              {formatLong(selected.at)}
              {against ? ` · ${against.n}. sürümle karşılaştırma` : ""}
              {selected.n === latest.n ? " · güncel sürüm" : ""}
            </p>
          </div>
          <div className="inline-flex rounded-md border p-0.5 text-sm" role="group" aria-label="Görünüm">
            <Link href={href({ karsi: against?.n ?? null, gor: "fark" })} prefetch={false} className={cn("rounded-sm px-2.5 py-1", view === "fark" && "bg-accent font-medium")}>Fark</Link>
            <Link href={href({ karsi: against?.n ?? null, gor: "metin" })} prefetch={false} className={cn("rounded-sm px-2.5 py-1", view === "metin" && "bg-accent font-medium")}>Metin</Link>
          </div>
          {selected.n !== latest.n && (
            <>
              <Link href={href({ s: latest.n, karsi: selected.n, gor: "fark" })} prefetch={false} className={buttonVariants({ variant: "outline", size: "sm" })}>Güncelle karşılaştır</Link>
              <RestoreButton docId={doc.id} n={selected.n} isSource={doc.kind === "kaynak"} />
            </>
          )}
        </div>
        <div className="mt-4">
          {view === "metin" ? (
            <article className="doc max-w-[50rem] rounded-md border bg-card p-6">
              <MarkdownView source={bodyOf(doc, selectedText)} assets={assetCards()} progress={progressView()} />
            </article>
          ) : against ? (
            <DiffView hunks={diffDocs(againstText, selectedText)} />
          ) : (
            <p className="rounded-md border bg-card p-4 text-muted-foreground">Bu belgenin ilk kaydı; karşılaştırılacak önceki sürüm yok. Metni görmek için «Metin»e geç.</p>
          )}
        </div>
      </main>
    </div>
  );
}
