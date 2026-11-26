// Varlıklar: oyunun bütün varlıkları, türe göre. Her türün kendi tablosu /assets/<tür> sayfasındadır.
import type { Metadata } from "next";
import Link from "next/link";
import { Kusak } from "@/components/brand";
import { readCatalog, readFreeAssets, tallyAssets } from "@/lib/assets";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "Varlıklar" };

const fmt = (n: number) => n.toLocaleString("tr-TR");

export default function AssetsPage() {
  const catalog = readCatalog();
  const all = tallyAssets(catalog.assets);
  const free = readFreeAssets();
  const KIND: Record<string, string> = { texture: "Doku", model: "Model", hdri: "Gökyüzü", sound: "Ses" };
  return (
    <main className="mx-auto w-full max-w-4xl px-5 py-10 lg:px-10">
      <h1 className="font-display text-3xl font-medium tracking-wide">Varlıklar</h1>
      <Kusak className="mt-3" />
      <p className="mt-4 font-serif text-lg text-muted-foreground">
        Oyunun modelleri, simgeleri ve resimleri, türe göre. Her satırda görsel, 3B gereği, 3B durumu, en mantıklı üretim yolu ve Meshy'nin en kaliteli en son modeliyle üretim kredisi var. Görseller gpt-image-2 ile üretildi; aynı görsel Meshy'ye girdi olabilir.
      </p>

      <section className="mt-6 grid gap-3 sm:grid-cols-4">
        {[
          [fmt(all.count), "varlık"],
          [fmt(all.need), "3B gerekli"],
          [fmt(all.have), "3B modeli var"],
          [fmt(all.creditsNeeded), "kredi: eksik 3B'ler"],
        ].map(([n, label]) => (
          <div key={label} className="rounded-md border bg-card p-3">
            <p className="font-display text-2xl">{n}</p>
            <p className="text-sm text-muted-foreground">{label}</p>
          </div>
        ))}
      </section>
      <p className="mt-2 text-sm text-muted-foreground">
        Hepsi Meshy ile üretilse {fmt(all.creditsAll)} kredi. {catalog.meshy.model ? `Fiyat: ${catalog.meshy.model}, ${catalog.meshy.settings}; model ${catalog.meshy.static}, rig ${catalog.meshy.rig}, ek hareket ${catalog.meshy.action}, yeniden boyama ${catalog.meshy.retexture} kredi.` : ""} {catalog.meshy.note}
      </p>

      <h2 className="mt-10 text-lg font-bold">Türler</h2>
      <div className="mt-3 overflow-x-auto rounded-md border">
        <table className="w-full text-left text-sm">
          <thead className="bg-muted/60 text-xs uppercase tracking-wide text-muted-foreground">
            <tr>
              <th className="px-3 py-2">Tür</th>
              <th className="px-3 py-2 text-right">Varlık</th>
              <th className="px-3 py-2 text-right">3B gerekli</th>
              <th className="px-3 py-2 text-right">3B var</th>
              <th className="px-3 py-2 text-right">Görsel</th>
              <th className="px-3 py-2 text-right">Eksik 3B kredisi</th>
              <th className="px-3 py-2 text-right">Hepsi Meshy</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {catalog.groups.map((g) => {
              const t = tallyAssets(catalog.assets.filter((a) => a.group === g.id));
              return (
                <tr key={g.id} className="hover:bg-accent/40">
                  <td className="px-3 py-2">
                    <Link href={`/assets/${g.id}`} prefetch={false} className="font-medium hover:underline">{g.title}</Link>
                    <p className="text-xs text-muted-foreground">{g.summary}</p>
                  </td>
                  <td className="px-3 py-2 text-right tabular-nums">{fmt(t.count)}</td>
                  <td className="px-3 py-2 text-right tabular-nums">{fmt(t.need)}</td>
                  <td className="px-3 py-2 text-right tabular-nums">{fmt(t.have)}</td>
                  <td className="px-3 py-2 text-right tabular-nums">{fmt(t.images)}</td>
                  <td className="px-3 py-2 text-right tabular-nums">{fmt(t.creditsNeeded)}</td>
                  <td className="px-3 py-2 text-right tabular-nums">{fmt(t.creditsAll)}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <h2 className="mt-10 text-lg font-bold">Üretim yolları</h2>
      <dl className="mt-3 grid gap-3 sm:grid-cols-2">
        {catalog.paths.map((p) => (
          <div key={p.id} className="rounded-md border bg-card p-3">
            <dt className="font-medium">{p.title}</dt>
            <dd className="mt-1 text-sm text-muted-foreground">{p.summary}</dd>
          </div>
        ))}
      </dl>
      {catalog.meshy.source ? <p className="mt-4 text-xs text-muted-foreground">Kaynak: {catalog.meshy.source}</p> : null}

      {free.assets.length ? (
        <section className="mt-10" aria-labelledby="ucretsiz">
          <h2 id="ucretsiz" className="text-lg font-bold">
            Ücretsiz varlıklar (geçici) <span className="text-sm font-normal text-muted-foreground">· {free.assets.length}</span>
          </h2>
          <p className="mt-1 text-sm text-muted-foreground">
            Ücretsiz kanallardan geçici olarak alındı ve işaretli (E7.5, <Link href="/docs/source/design/decisions#k89" prefetch={false} className="underline underline-offset-2">K89</Link>): duruma göre sonra Meshy ile, ses için ElevenLabs ya da kodla yeniden üretilir. Kayıt <code>game/assets/_free/FREE_ASSETS.json</code>, lisanslar <code>LICENSES.md</code>.
          </p>
          <div className="doc-table mt-3">
            <table>
              <thead>
                <tr>
                  <th>Varlık</th>
                  <th>Tür</th>
                  <th>Kaynak ve lisans</th>
                  <th>Oyunda</th>
                  <th>Sonra</th>
                </tr>
              </thead>
              <tbody>
                {free.assets.map((a) => (
                  <tr key={a.id}>
                    <td>
                      <a href={a.url} target="_blank" rel="noreferrer" className="font-medium hover:underline">{a.name}</a>
                      <p className="max-w-xs text-xs text-muted-foreground">{a.plannedUse}</p>
                    </td>
                    <td>{KIND[a.kind] ?? a.kind}</td>
                    <td className="text-xs">{a.source} · {a.license}</td>
                    <td className="text-xs">{a.usedIn.length ? a.usedIn.join(", ") : <span className="text-muted-foreground">{a.replacedBy ? `Meshy modeli geldi: ${[a.replacedBy].flat().join(", ")}; yedek kaldı` : "henüz değil"}</span>}</td>
                    <td className="text-xs">{a.regenWith}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      ) : null}
      {catalog.assets.length === 0 ? <p className="mt-8 rounded-md border bg-card p-5 text-muted-foreground">Katalog boş. Veri <code>docs/assets/catalog.json</code> dosyasındadır.</p> : null}
    </main>
  );
}
