// «Karar Bekleyenler» sayfasının alt listesi: sayfalardaki çözülmemiş açık sorular ve çelişkiler, kategori ve sayfa
// sırasıyla. Cevaplanan kutu sayfasından kalkınca buradan da düşer.
import { ArrowUpRight } from "lucide-react";
import Link from "next/link";
import { MarkdownView } from "@/components/doc/markdown-view";
import { CATEGORIES } from "@/lib/catalog";
import { pendingItems } from "@/lib/questions";

const KIND_LABEL = { acik: "Açık soru", celiski: "Çelişki" } as const;

export function PendingList() {
  const items = pendingItems();
  const groups = CATEGORIES.map((category) => {
    const rows = items.filter((q) => q.group === category.id).sort((a, b) => a.order - b.order);
    const pages = [...new Set(rows.map((q) => q.docId))].map((docId) => ({
      docId,
      title: rows.find((q) => q.docId === docId)?.docTitle ?? docId,
      rows: rows.filter((q) => q.docId === docId),
    }));
    return { ...category, total: rows.length, pages };
  }).filter((g) => g.total > 0);
  // Numara sayfa sırasıyla verilir: madde kapanınca sonrakiler bir kayar.
  const numbers = new Map(groups.flatMap((g) => g.pages.flatMap((p) => p.rows)).map((q, i) => [q, i + 1]));
  const conflicts = items.filter((q) => q.kind === "celiski").length;
  return (
    <section className="mt-12 border-t pt-6" aria-labelledby="sayfalardaki-bekleyenler">
      <h2 id="sayfalardaki-bekleyenler" className="font-display text-xl font-medium tracking-wide">
        Sayfalarda cevap bekleyenler
        <span className="ml-2 font-sans text-sm font-normal tracking-normal text-muted-foreground">
          {items.length === 0 ? "yok" : `${items.length - conflicts} açık soru, ${conflicts} çelişki`}
        </span>
      </h2>
      <p className="mt-1 text-sm text-muted-foreground">
        Sayfalardaki «Açık soru» ve «Çelişki» kutuları burada toplanır. Cevaplamak için sayfasına git, Not al ile yaz ya da metni düzenle.
      </p>
      {items.length === 0 ? <p className="mt-4 rounded-md border bg-card p-4 text-sm text-muted-foreground">Sayfalarda cevap bekleyen soru ya da çelişki yok.</p> : null}
      {groups.map((group) => (
        <div key={group.id} className="mt-6">
          <h3 className="font-display text-lg font-medium tracking-wide">
            {group.title}
            <span className="ml-2 font-sans text-sm font-normal tracking-normal text-muted-foreground">{group.total}</span>
          </h3>
          {group.pages.map((page) => (
            <div key={page.docId} className="mt-3">
              <h4 className="font-bold">
                <Link href={`/docs/${page.docId}`} prefetch={false} className="hover:underline">{page.title}</Link>
              </h4>
              <ul className="mt-2 divide-y border-y">
                {page.rows.map((q) => (
                  <li key={`${q.kind}:${q.anchor}:${q.text.slice(0, 40)}`} className="flex gap-3 py-3">
                    <span className="w-7 shrink-0 pt-0.5 text-right font-display text-sm text-muted-foreground">{numbers.get(q)}</span>
                    <div className="min-w-0 flex-1">
                      <span className={q.kind === "celiski" ? "text-xs font-bold uppercase tracking-wide text-kusak" : "text-xs font-bold uppercase tracking-wide text-bronze"}>{KIND_LABEL[q.kind]}</span>
                      <div className="doc doc-compact mt-1">
                        <MarkdownView source={q.text} />
                      </div>
                      <Link href={`/docs/${q.docId}${q.anchor ? `#${q.anchor}` : ""}`} prefetch={false} className="mt-1 inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
                        {q.section || "Sayfaya git"} <ArrowUpRight className="size-3.5" />
                      </Link>
                    </div>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      ))}
    </section>
  );
}
