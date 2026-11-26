// Belge sürümleri: bütün belgelerin damgalanmış hâlleri, son sürümden beri değişenler, değişiklik günlüğü.
import type { Metadata } from "next";
import Link from "next/link";
import { Kusak } from "@/components/brand";
import { ReleaseDialog } from "@/components/doc/release-dialog";
import { activity, syncAll } from "@/lib/history";
import { changedBetween, listReleases, nextVersion } from "@/lib/store";
import { formatLong, formatShort } from "@/lib/text";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "Sürümler" };

export default function ReleasesPage() {
  syncAll();
  const releases = listReleases();
  const last = releases.at(-1) ?? null;
  const changed = changedBetween(last?.snapshot ?? null);
  const log = activity(60);
  const compareHref = (id: string, from: number, to: number) => (from > 0 ? `/history/${id}?rev=${to}&vs=${from}` : `/history/${id}?rev=${to}`);
  return (
    <main className="mx-auto w-full max-w-3xl px-5 py-10 lg:px-10">
      <div className="flex items-end gap-4">
        <h1 className="flex-1 font-display text-3xl font-medium tracking-wide">Sürümler</h1>
        <ReleaseDialog suggested={nextVersion()} changed={changed.length} />
      </div>
      <Kusak className="mt-3" />
      <p className="mt-4 font-serif text-lg text-muted-foreground">Her belgenin kendi sürüm geçmişi var; her kayıt yeni sürüm açar. Burada ise bütün belgeler birlikte damgalanır: «v0.2 şu hâliydi» diyebilmek için.</p>

      <section className="mt-8">
        <h2 className="text-lg font-bold">{last ? `${last.version} sürümünden beri değişenler` : "Henüz damgalanmış sürüm yok"}</h2>
        {changed.length === 0 ? (
          <p className="mt-2 rounded-md border bg-card p-4 text-muted-foreground">Değişen belge yok.</p>
        ) : (
          <ul className="mt-2 divide-y border-y text-sm">
            {changed.map((row) => (
              <li key={row.id} className="flex items-baseline gap-2 py-1.5">
                <Link href={compareHref(row.id, row.from, row.to)} prefetch={false} className="min-w-0 flex-1 truncate hover:underline">{row.title}</Link>
                <span className="shrink-0 font-mono text-xs text-muted-foreground">{row.from > 0 ? `${row.from} → ${row.to}` : "yeni"}</span>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="mt-10">
        <h2 className="text-lg font-bold">Damgalanan sürümler</h2>
        {releases.length === 0 && <p className="mt-2 text-muted-foreground">İlk sürümü yukarıdan oluştur.</p>}
        <ol className="mt-2 space-y-3">
          {[...releases].reverse().map((release, i, list) => {
            const previous = list[i + 1];
            const diff = changedBetween(previous?.snapshot ?? null, release.snapshot);
            return (
              <li key={release.version} className="rounded-md border bg-card p-4">
                <div className="flex flex-wrap items-baseline gap-2">
                  <span className="font-display text-lg font-medium">{release.version}</span>
                  {release.title ? <span className="font-medium">{release.title}</span> : null}
                  <span className="ml-auto text-xs text-muted-foreground">{formatLong(release.at)}</span>
                </div>
                {release.note ? <p className="mt-1 whitespace-pre-wrap font-serif text-muted-foreground">{release.note}</p> : null}
                {previous ? (
                  <details className="mt-2 text-sm">
                    <summary className="cursor-pointer text-muted-foreground">{previous.version} sürümünden {diff.length} belge değişti</summary>
                    <ul className="mt-1 space-y-0.5">
                      {diff.map((row) => (
                        <li key={row.id}>
                          <Link href={compareHref(row.id, row.from, row.to)} prefetch={false} className="hover:underline">{row.title}</Link>
                          <span className="ml-2 font-mono text-xs text-muted-foreground">{row.from > 0 ? `${row.from} → ${row.to}` : "yeni"}</span>
                        </li>
                      ))}
                    </ul>
                  </details>
                ) : (
                  <p className="mt-2 text-sm text-muted-foreground">{Object.keys(release.snapshot).length} belgenin başlangıç hâli.</p>
                )}
              </li>
            );
          })}
        </ol>
      </section>

      <section className="mt-10">
        <h2 className="text-lg font-bold">Değişiklik günlüğü</h2>
        {log.length === 0 ? (
          <p className="mt-2 text-muted-foreground">Henüz düzenleme yok.</p>
        ) : (
          <ol className="mt-2 divide-y border-y text-sm">
            {log.map((row) => (
              <li key={`${row.docId}:${row.n}`} className="flex items-baseline gap-2 py-1.5">
                <span className="w-28 shrink-0 text-xs text-muted-foreground">{formatShort(row.at)}</span>
                <Link href={`/history/${row.docId}?rev=${row.n}`} prefetch={false} className="min-w-0 flex-1 truncate hover:underline">
                  <span className="font-medium">{row.title}</span>
                  <span className="text-muted-foreground"> · {row.message}</span>
                </Link>
                <span className="shrink-0 font-mono text-xs">
                  <span className="text-[#3f7a3a] dark:text-[#8fc77f]">+{row.added}</span> <span className="text-kusak">−{row.removed}</span>
                </span>
              </li>
            ))}
          </ol>
        )}
      </section>
    </main>
  );
}
