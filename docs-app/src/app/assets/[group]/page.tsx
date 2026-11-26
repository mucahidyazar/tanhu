// Bir varlık türünün tablosu: görsel, ad, perde, 3B gereği, 3B durumu, en mantıklı yol, Meshy kredisi, not.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Kusak } from "@/components/brand";
import { imageOf, NEED3D, readCatalog, STATUS3D, status3dOf, tallyAssets, thumbOf } from "@/lib/assets";
import { cn } from "@/lib/utils";

export const dynamic = "force-dynamic";

type Props = { params: Promise<{ group: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { group: groupId } = await params;
  return { title: readCatalog().groups.find((g) => g.id === groupId)?.title ?? "Varlıklar" };
}

const fmt = (n: number) => n.toLocaleString("tr-TR");

export default async function AssetGroupPage({ params }: Props) {
  const { group: groupId } = await params;
  const catalog = readCatalog();
  const group = catalog.groups.find((g) => g.id === groupId);
  if (!group) notFound();
  const rows = catalog.assets.filter((a) => a.group === groupId);
  const t = tallyAssets(rows);
  const pathTitle = (id: string) => catalog.paths.find((p) => p.id === id)?.title ?? id;
  return (
    <main className="mx-auto w-full max-w-6xl px-5 py-10 lg:px-10">
      <p className="text-sm text-muted-foreground">
        <Link href="/assets" prefetch={false} className="hover:underline">Varlıklar</Link>
      </p>
      <h1 className="mt-1 font-display text-3xl font-medium tracking-wide">{group.title}</h1>
      <Kusak className="mt-3" />
      <p className="mt-4 max-w-3xl font-serif text-lg text-muted-foreground">{group.summary}</p>
      <p className="mt-2 text-sm text-muted-foreground">
        {fmt(t.count)} varlık · {fmt(t.need)} tanesine 3B gerekli · {fmt(t.have)} tanesinin modeli var · eksik 3B'ler {fmt(t.creditsNeeded)} kredi · hepsi Meshy ile {fmt(t.creditsAll)} kredi
      </p>

      <div className="mt-6 overflow-x-auto rounded-md border">
        <table className="w-full min-w-[56rem] text-left text-sm">
          <thead className="bg-muted/60 text-xs uppercase tracking-wide text-muted-foreground">
            <tr>
              <th className="w-24 px-3 py-2">Görsel</th>
              <th className="px-3 py-2">Varlık</th>
              <th className="px-3 py-2">Perde</th>
              <th className="px-3 py-2">3B gerekli mi</th>
              <th className="px-3 py-2">3B durumu</th>
              <th className="px-3 py-2">En mantıklı yol</th>
              <th className="px-3 py-2 text-right">Meshy kredisi</th>
            </tr>
          </thead>
          <tbody className="divide-y align-top">
            {rows.map((row) => {
              const thumb = thumbOf(row);
              const full = imageOf(row);
              const s3 = status3dOf(row);
              return (
                <tr key={row.id} id={row.id} className="scroll-mt-6 hover:bg-accent/30">
                  <td className="px-3 py-2">
                    {thumb ? (
                      <a href={full ?? thumb} target="_blank" rel="noreferrer" className="block size-20 overflow-hidden rounded-sm border bg-muted">
                        {/* Yerel küçük görsel: next/image gerekmez. */}
                        <img src={thumb} alt={row.tr} loading="lazy" className="size-full object-contain" />
                      </a>
                    ) : (
                      <span className="flex size-20 items-center justify-center rounded-sm border border-dashed text-center text-[0.7rem] text-muted-foreground">Görsel yok</span>
                    )}
                  </td>
                  <td className="px-3 py-2">
                    <p className="font-medium">{row.tr}</p>
                    <p className="text-xs text-muted-foreground">{row.en ? `${row.en} · ` : ""}<code>{row.id}</code></p>
                    {row.note ? <p className="mt-1 max-w-md text-xs text-muted-foreground">{row.note}</p> : null}
                    {row.design ? (
                      <Link href={row.design} prefetch={false} className="mt-1 inline-block text-xs underline underline-offset-2">Tasarım</Link>
                    ) : null}
                  </td>
                  <td className="px-3 py-2 text-xs">{row.act ?? ""}</td>
                  <td className="px-3 py-2">
                    <span className={cn("rounded-sm px-1.5 py-0.5 text-xs", row.need3d === "evet" ? "bg-primary/10 text-primary" : row.need3d === "kismen" ? "bg-bronze/20" : "bg-muted text-muted-foreground")}>
                      {NEED3D[row.need3d]}
                    </span>
                  </td>
                  <td className="px-3 py-2">
                    <span className={cn("rounded-sm px-1.5 py-0.5 text-xs", s3 === "var" ? "bg-primary/10 text-primary" : s3 === "kismen" ? "bg-bronze/20" : row.need3d === "hayir" ? "bg-muted text-muted-foreground" : "bg-kusak/10 text-kusak")}>
                      {row.need3d === "hayir" && s3 === "yok" ? "Gerekmez" : STATUS3D[s3]}
                    </span>
                    {row.model && s3 === "var" ? <p className="mt-1 font-mono text-[0.7rem] text-muted-foreground">{row.model.replace(/^game\//, "")}</p> : null}
                  </td>
                  <td className="px-3 py-2">
                    <p className="text-xs font-medium">{pathTitle(row.path)}</p>
                    {row.free?.length ? (
                      <p className="mt-1 inline-block rounded-sm bg-bronze/20 px-1.5 py-0.5 text-[0.7rem]" title="Ücretsiz kanaldan geçici; duruma göre sonra Meshy ile üretilir (E7.5)">
                        Bugün ücretsiz, geçici: {row.free.join(", ")}
                      </p>
                    ) : null}
                    {row.pathNote ? <p className="mt-0.5 max-w-xs text-xs text-muted-foreground">{row.pathNote}</p> : null}
                  </td>
                  <td className="px-3 py-2 text-right">
                    <p className="tabular-nums">{row.meshy.credits === null ? "—" : fmt(row.meshy.credits)}</p>
                    <p className="text-[0.7rem] text-muted-foreground">{row.meshy.detail}</p>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </main>
  );
}
