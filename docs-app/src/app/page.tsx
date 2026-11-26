// Başlangıç: kaldığın yer. Karar bekleyen çelişkiler, açık notlar, son değişiklikler, kategoriler.
import { CircleAlert } from "lucide-react";
import Link from "next/link";
import { GameIcon, Kusak } from "@/components/brand";
import { StatusGlyph } from "@/components/shell/status-mark";
import { allDocs, CATEGORIES, STATUSES, type Status } from "@/lib/catalog";
import { activity } from "@/lib/history";
import { buildNav } from "@/lib/nav";
import { listNotes } from "@/lib/store";
import { formatShort } from "@/lib/text";
import { itemsOfAct, readProgress, tally } from "@/lib/progress";

export const dynamic = "force-dynamic";

export default function HomePage() {
  const nav = buildNav();
  const docs = allDocs().filter((d) => d.kind === "sayfa");
  const conflicted = docs.filter((d) => d.conflicts + d.questions > 0).sort((a, b) => b.conflicts + b.questions - (a.conflicts + a.questions));
  const notes = listNotes().filter((n) => !n.done);
  const log = activity(6);
  const percent = nav.total ? Math.round((nav.reviewed / nav.total) * 100) : 0;
  const progress = readProgress();
  const acts = progress.acts.map((a) => ({ id: a.id, title: a.title, percent: tally(itemsOfAct(progress, a.id)).percent }));
  return (
    <main className="mx-auto w-full max-w-5xl px-5 py-10 lg:px-10">
      <header className="flex items-center gap-5">
        <GameIcon large className="size-16" />
        <div>
          <h1 className="font-display text-4xl font-medium tracking-[0.08em]">Tanhu</h1>
          <p className="mt-1 font-serif text-xl italic text-muted-foreground">Oyunun belgeleri: oku, not al, düzelt.</p>
        </div>
      </header>
      <Kusak className="mt-5" />

      <section className="mt-8 grid gap-6 md:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]">
        <div>
          <h2 className="flex items-baseline gap-2 text-lg font-bold">
            <Link href="/docs/general/pending-decisions" className="hover:underline">Karar bekleyenler</Link>
            <span className="text-sm font-normal text-muted-foreground">{nav.pending} madde, {conflicted.length} sayfada</span>
          </h2>
          <p className="mt-1 text-sm text-muted-foreground">Cevap bekleyen açık sorular, çelişkiler ve kararlar tek sayfada: <Link href="/docs/general/pending-decisions" className="underline underline-offset-2">Karar Bekleyenler</Link>.</p>
          {conflicted.length === 0 ? <p className="mt-3 rounded-md border bg-card p-3 text-sm text-muted-foreground">Cevap bekleyen madde yok.</p> : null}
          <ul className="mt-3 divide-y border-y empty:hidden">
            {conflicted.slice(0, 8).map((d) => (
              <li key={d.id}>
                <Link href={`/docs/${d.id}`} prefetch={false} className="flex items-baseline gap-2 py-2 hover:bg-accent/50">
                  <CircleAlert className="size-3.5 shrink-0 translate-y-0.5 text-kusak" />
                  <span className="min-w-0 flex-1">
                    <span className="font-medium">{d.title}</span>
                    <span className="ml-2 text-sm text-muted-foreground">{[d.conflicts ? `${d.conflicts} çelişki` : "", d.questions ? `${d.questions} açık soru` : ""].filter(Boolean).join(", ")}</span>
                  </span>
                </Link>
              </li>
            ))}
          </ul>

        </div>
        <div className="space-y-6">
          <div>
            <h2 className="text-lg font-bold">
              <Link href="/roadmap" className="hover:underline">Yol Haritası</Link>
            </h2>
            <p className="mt-1 text-sm text-muted-foreground">{nav.progress.bitti} / {nav.progress.total} madde bitti, {nav.progress.suruyor} sürüyor.</p>
            <div className="mt-2 flex h-2 overflow-hidden rounded-sm bg-muted" role="img" aria-label={`Yüzde ${nav.progress.percent}`}>
              <div className="h-full bg-primary" style={{ width: `${nav.progress.total ? (nav.progress.bitti / nav.progress.total) * 100 : 0}%` }} />
              <div className="h-full bg-bronze/60" style={{ width: `${nav.progress.total ? (nav.progress.suruyor / nav.progress.total) * 100 : 0}%` }} />
            </div>
            <ul className="mt-2 grid grid-cols-2 gap-x-4 gap-y-0.5 text-sm">
              {acts.map((a) => (
                <li key={a.id} className="flex justify-between gap-2">
                  <Link href={`/roadmap#${a.id}`} prefetch={false} className="truncate hover:underline">{a.title.split(":")[0]}</Link>
                  <span className="tabular-nums text-muted-foreground">%{a.percent}</span>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h2 className="text-lg font-bold">Gözden geçirme</h2>
            <p className="mt-1 text-sm text-muted-foreground">{nav.total} sayfanın {nav.reviewed} tanesine baktın.</p>
            <div className="mt-2 h-2 overflow-hidden rounded-sm bg-muted" role="img" aria-label={`Yüzde ${percent}`}>
              <div className="h-full bg-bronze" style={{ width: `${percent}%` }} />
            </div>
          </div>
          <div>
            <h2 className="text-lg font-bold">
              <Link href="/notes" className="hover:underline">Açık notlar</Link>
              <span className="ml-2 text-sm font-normal text-muted-foreground">{notes.length}</span>
            </h2>
            {notes.length === 0 ? (
              <p className="mt-1 text-sm text-muted-foreground">Bir sayfada metni seçip «Not al»a bas; not buraya düşer.</p>
            ) : (
              <ul className="mt-1 space-y-1 text-sm">
                {notes.slice(-5).reverse().map((n) => (
                  <li key={n.id} className="truncate">
                    <Link href={`/docs/${n.docId}${n.anchor ? `#${n.anchor}` : ""}`} prefetch={false} className="hover:underline">{n.text}</Link>
                  </li>
                ))}
              </ul>
            )}
          </div>
          <div>
            <h2 className="text-lg font-bold">
              <Link href="/releases" className="hover:underline">Son değişiklikler</Link>
              {nav.release ? <span className="ml-2 text-sm font-normal text-muted-foreground">{nav.release}</span> : null}
            </h2>
            {log.length === 0 ? (
              <p className="mt-1 text-sm text-muted-foreground">Henüz düzenleme yok.</p>
            ) : (
              <ul className="mt-1 space-y-1 text-sm">
                {log.map((row) => (
                  <li key={`${row.docId}:${row.n}`} className="flex gap-2">
                    <span className="shrink-0 text-xs leading-5 text-muted-foreground">{formatShort(row.at)}</span>
                    <Link href={`/history/${row.docId}?rev=${row.n}`} prefetch={false} className="min-w-0 truncate hover:underline">{row.title}</Link>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
      </section>

      <section className="mt-10">
        <h2 className="text-lg font-bold">Bölümler</h2>
        <div className="mt-3 grid gap-x-8 gap-y-6 sm:grid-cols-2 lg:grid-cols-3">
          {CATEGORIES.map((c) => {
            const items = docs.filter((d) => d.group === c.id).sort((a, b) => a.order - b.order);
            if (items.length === 0) return null;
            return (
              <div key={c.id}>
                <h3 className="border-b pb-1 font-display text-sm font-medium uppercase tracking-[0.12em]">
                  <Link href={`/docs/${c.id}`} prefetch={false} className="hover:underline">{c.title}</Link>
                </h3>
                <p className="mt-1 text-sm text-muted-foreground">{c.blurb}</p>
                <ul className="mt-2 space-y-0.5 text-[0.95rem]">
                  {items.map((d) => (
                    <li key={d.id}>
                      <Link href={`/docs/${d.id}`} prefetch={false} className="flex items-center gap-2 hover:underline">
                        <StatusGlyph status={d.status} className="text-bronze" />
                        <span className="min-w-0 truncate">{d.title}</span>
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            );
          })}
        </div>
        <ul className="mt-6 flex flex-wrap gap-x-5 gap-y-1 border-t pt-3 text-xs text-muted-foreground">
          {(Object.keys(STATUSES) as Status[]).map((status) => (
            <li key={status} className="inline-flex items-center gap-1.5">
              <StatusGlyph status={status} className="text-bronze" /> {STATUSES[status]}
            </li>
          ))}
          <li>
            <Link href="/docs/source" prefetch={false} className="underline underline-offset-2 hover:text-foreground">Kaynak belgeler</Link>: bağlayıcı tasarım belgeleri ve araştırmalar, tam metin.
          </li>
        </ul>
      </section>
    </main>
  );
}
