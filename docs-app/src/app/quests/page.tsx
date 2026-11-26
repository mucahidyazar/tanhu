// Görevler: oyunun ana hikâye, yan ve yoldaş görevleri tek sayfada, perde perde. Veri tasarım belgelerinden okunur
// (getQuestData, src/lib/quests.ts); sayfa yalnız gösterir. Süzgeçler adreste durur ve paylaşılabilir:
// /quests?kind=main|side|companion&act=0|I…VI&family=<aile>&q=<arama>, bir görev /quests?kind=side#sq_crow_war.
// Belgeye giden bağlar düz <a>'dır: Next'in istemci içi geçişinde tarayıcı :target'ı güncellemez, satır vurgusu çıkmaz.
import type { Metadata } from "next";
import { Kusak } from "@/components/brand";
import { InlineText } from "@/components/progress/inline-text";
import { QuestBrowser } from "@/components/quests/quest-browser";
import { familyLabel } from "@/components/quests/quest-filter";
import "@/components/quests/quests.css";
import { getQuestData, toClientView } from "@/lib/quests";
import { formatShort } from "@/lib/text";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "Görevler" };

const WARNINGS_SHOWN = 6;

// Adresteki süzgeçleri istemci okur (useSearchParams) ve sunucuya gitmeden değiştirir; sayfa her istekte yeniden çizilir,
// belgeler değişince liste tazelenir.
export default function QuestsPage() {
  const data = getQuestData();
  // İstemciye yalnız kartların ve süzgeçlerin kullandığı veri gider (toClientView); belgedeki özgün satırı kart «Ayrıntı»
  // açılınca /quests/raw'dan ister, uyarılar ve okuma zamanı burada çizilir.
  const view = toClientView(data);
  // Aile adları belgedeki aile tablosundan; Yoldaş satırı yan görev ailesi değildir.
  const families = data.families.map((f) => familyLabel(f.name)).filter((name) => name && !/^yolda/i.test(name));
  const generated = data.generatedAt && !Number.isNaN(Date.parse(data.generatedAt)) ? formatShort(data.generatedAt) : null;
  const shownWarnings = data.warnings.slice(0, WARNINGS_SHOWN);
  const moreWarnings = data.warnings.slice(WARNINGS_SHOWN);

  return (
    <main className="qst-page mx-auto w-full min-w-0 max-w-4xl px-5 py-10 lg:px-10">
      <h1 className="font-display text-3xl font-medium tracking-wide">Görevler</h1>
      <Kusak className="mt-3" />
      <p className="mt-4 font-serif text-lg text-muted-foreground">
        Oyunun bütün görevleri, tasarım belgelerinden okunur: ana hikâye, yan görevler ve yoldaşların kişisel görevleri, perde perde. Bir görevin kartından
        belgedeki satırına gidilir.
      </p>
      <ul className="qst-intro">
        <li>
          <b>Ana zincir.</b> II–VI&apos;da her perde aynı kalıptadır: açılış, aynı anda açılan üç kol (sırası serbest, biri bitince ötekilerin satırı
          değişir), kapanış ve perdeyi kapatan son görev. İstisnalar (
          <a href="/docs/source/design/story#10-1-kalip">story.md §10.1</a>
          ): II&apos;nin ıslık sınamaları bir merdivendir, iki sınama arasında en az iki gün geçer; VI&apos;nın kolları yıl dilimlerine bağlıdır, sıra
          takvimindir, bu yüzden aynı kol birden çok kez gelir. I. Perde bu kalıba girmez: zinciri gün gün ilerler (altı gün ve Son Gece). Çocukluk iki
          bölümdür, ikisi de kendi son göreviyle biter.
        </li>
        <li>
          <b>Yan görevler.</b> Ailelere ayrılır{families.length ? `: ${families.join(", ")}` : ""}. I. Perde&apos;ninkiler aileye ayrılmaz, Kışlak&apos;a bağlıdır (
          <a href="/docs/source/design/act1#7-yan-gorevler">act1.md §7</a>).
        </li>
        <li>
          <b>Yoldaş görevleri.</b> Her yoldaşın üç adımlık kişisel görevi; adım <code className="qst-code">ties</code> eşiğiyle ya da takvimin gününde
          açılır. XP vermez, ödülü <code className="qst-code">ties</code> ve kamp sahnesidir.
        </li>
        <li>
          <b>Perde sonu</b> (
          <a href="/docs/source/design/decisions#k42">K42</a>
          ). Açık kalan yan görev sessizce düşmez: <code className="qst-code">carry</code> sonraki perdeye taşınır,{" "}
          <code className="qst-code">chronicle</code> Akan Kronik&apos;te sonuçlanır, <code className="qst-code">lost</code> kapanır.
        </li>
      </ul>

      <QuestBrowser data={view} />

      {data.warnings.length ? (
        <aside className="qst-warnings" aria-labelledby="doc-mismatches">
          <h2 id="doc-mismatches">Belge uyumsuzlukları · {data.warnings.length}</h2>
          <ul>
            {shownWarnings.map((w, i) => (
              <li key={i}>
                <InlineText text={w} />
              </li>
            ))}
          </ul>
          {moreWarnings.length ? (
            <details>
              <summary>{moreWarnings.length} uyarı daha</summary>
              <ul>
                {moreWarnings.map((w, i) => (
                  <li key={i}>
                    <InlineText text={w} />
                  </li>
                ))}
              </ul>
            </details>
          ) : null}
        </aside>
      ) : null}
      {generated ? <p className="qst-generated">Liste belgelerden okundu: {generated}. Belge değişince kendiliğinden yenilenir.</p> : null}
    </main>
  );
}
