// Yol Haritası: oyunun yapım sırası ve Godot'da (game/) yapılanlar tek sayfada: Perde > Faz > Madde. Perdenin hedefi,
// fazın önkoşulu ve çıkış ölçütü burada yazar; bir madde bitince buradan işaretlenir. Veri content/progress.json'dadır,
// Godot'da çalışan bir oturum da aynı dosyayı günceller.
import { InlineText } from "@/components/progress/inline-text";
import type { Metadata } from "next";
import Link from "next/link";
import { Kusak } from "@/components/brand";
import { ProgressControl } from "@/components/progress/progress-control";
import { getDoc } from "@/lib/catalog";
import {
  type Act,
  evidenceOf,
  itemsOfAct,
  itemsOfPhase,
  orphanItems,
  type Phase,
  type ProgressItem,
  phasesOf,
  readProgress,
  type Tally,
  tally,
} from "@/lib/progress";
import { PROGRESS_STATES, type ProgressState } from "@/lib/statuses";
import { formatShort } from "@/lib/text";
import { cn } from "@/lib/utils";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "Yol Haritası" };

function Bar({ t, className }: { t: Tally; className?: string }) {
  const part = (n: number) => (t.total ? `${(n / t.total) * 100}%` : "0%");
  return (
    <div className={cn("flex h-2 overflow-hidden rounded-sm bg-muted", className)} role="img" aria-label={`${t.bitti} bitti, ${t.suruyor} sürüyor, ${t.yapilacak} yapılacak`}>
      <div className="h-full bg-primary" style={{ width: part(t.bitti) }} />
      <div className="h-full bg-bronze/60" style={{ width: part(t.suruyor) }} />
    </div>
  );
}

function designLink(href: string) {
  const id = href.replace(/^\/docs\//, "").split("#")[0];
  return { href, label: getDoc(id)?.title ?? id };
}

function Row({ item }: { item: ProgressItem }) {
  const evidence = evidenceOf(item);
  const last = item.history?.at(-1);
  return (
    <li id={`item-${item.id}`} className="grid scroll-mt-6 gap-2 py-3 sm:grid-cols-[minmax(0,1fr)_auto] sm:gap-4">
      <div className="min-w-0">
        <div className="flex flex-wrap items-baseline gap-x-2">
          <span className={cn("font-medium", item.status === "bitti" && "text-muted-foreground")}><InlineText text={item.title} /></span>
          {item.area ? <span className="text-xs text-muted-foreground">{item.area}</span> : null}
        </div>
        {item.note ? <p className="mt-0.5 text-sm text-muted-foreground"><InlineText text={item.note} /></p> : null}
        {(item.design?.length || evidence.length) ? (
          <div className="mt-1.5 flex flex-wrap gap-1.5 text-xs">
            {item.design?.map(designLink).map((d) => (
              <Link key={d.href} href={d.href} prefetch={false} className="rounded-sm border px-1.5 py-0.5 hover:bg-accent">
                {d.label}
              </Link>
            ))}
            {evidence.map((e) => (
              <span
                key={e.path}
                title={e.exists ? `game/${e.path} var; son değişiklik ${e.modified ? formatShort(e.modified) : "?"}` : `game/${e.path} yok`}
                className={cn("rounded-sm px-1.5 py-0.5 font-mono", e.exists ? "bg-primary/10 text-primary" : "bg-kusak/10 text-kusak")}
              >
                {e.exists ? "✓" : "✗"} {e.path}
              </span>
            ))}
          </div>
        ) : null}
      </div>
      <div className="flex flex-col items-start gap-1 sm:items-end">
        <ProgressControl id={item.id} title={item.title} status={item.status} note={item.note ?? ""} />
        {last ? <span className="text-xs text-muted-foreground">{formatShort(last.at)}{last.by ? ` · ${last.by}` : ""}</span> : null}
      </div>
    </li>
  );
}

function PhaseBlock({ phase, index, items, filter, titles }: { phase: Phase; index: number; items: ProgressItem[]; filter: ProgressState | null; titles: Map<string, string> }) {
  const shown = filter ? items.filter((i) => i.status === filter) : items;
  if (filter && shown.length === 0) return null;
  const t = tally(items);
  return (
    <section id={phase.id} className="mt-6 scroll-mt-6 border-l-2 border-border pl-4" aria-labelledby={`${phase.id}-baslik`}>
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <h3 id={`${phase.id}-baslik`} className="text-base font-bold">
          <span className="mr-2 font-normal text-muted-foreground">Faz {index}</span>
          {phase.title}
        </h3>
        <span className="text-sm text-muted-foreground tabular-nums">{t.bitti} / {t.total}</span>
      </div>
      {phase.summary ? <p className="mt-1 text-sm text-muted-foreground"><InlineText text={phase.summary} /></p> : null}
      {phase.requires?.length ? (
        <p className="mt-1 text-sm">
          <span className="font-medium">Önkoşul:</span>{" "}
          {phase.requires.map((id, i) => (
            <span key={id}>
              {i > 0 ? ", " : null}
              <a href={`#${id}`} className="underline underline-offset-2">{titles.get(id) ?? id}</a>
            </span>
          ))}
        </p>
      ) : null}
      {phase.exit ? (
        <p className="mt-1 text-sm">
          <span className="font-medium">Çıkış ölçütü:</span> <span className="text-muted-foreground"><InlineText text={phase.exit} /></span>
        </p>
      ) : null}
      <Bar t={t} className="mt-2" />
      {shown.length ? (
        <ul className="mt-1 divide-y">
          {shown.map((item) => (
            <Row key={item.id} item={item} />
          ))}
        </ul>
      ) : (
        <p className="mt-2 text-sm text-muted-foreground">Bu fazda henüz madde yok.</p>
      )}
    </section>
  );
}

function ActBlock({ act, phases, items, filter, data, titles }: { act: Act; phases: Phase[]; items: ProgressItem[]; filter: ProgressState | null; data: ReturnType<typeof readProgress>; titles: Map<string, string> }) {
  if (filter && !items.some((i) => i.status === filter)) return null;
  const t = tally(items);
  // Perdenin sayfası henüz yazılmadıysa bağ verilmez (404 olmasın).
  const page = act.page && getDoc(act.page.replace(/^\/docs\//, "").split("#")[0]) ? designLink(act.page) : null;
  return (
    <section id={act.id} className="mt-12 scroll-mt-6" aria-labelledby={`${act.id}-baslik`}>
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <h2 id={`${act.id}-baslik`} className="font-display text-2xl font-medium tracking-wide">{act.title}</h2>
        <span className="text-sm text-muted-foreground tabular-nums">
          {t.bitti} / {t.total} · %{t.percent}
        </span>
      </div>
      <p className="mt-1 text-[0.95rem] text-muted-foreground">
        {act.summary}
        {page ? (
          <>
            {" "}
            <Link href={page.href} prefetch={false} className="underline underline-offset-2">{page.label}</Link>
          </>
        ) : null}
      </p>
      {act.goal ? <p className="mt-2 font-serif text-[1.05rem] leading-relaxed"><InlineText text={act.goal} /></p> : null}
      {act.systems?.length ? (
        <div className="mt-2 flex flex-wrap gap-1.5 text-xs" aria-label="Perdenin getirdiği sistemler">
          {act.systems.map((name) => (
            <span key={name} className="rounded-sm border px-1.5 py-0.5 text-muted-foreground">{name}</span>
          ))}
        </div>
      ) : null}
      <Bar t={t} className="mt-3 h-2.5" />
      {phases.map((phase, i) => (
        <PhaseBlock key={phase.id} phase={phase} index={i + 1} items={itemsOfPhase(data, phase.id)} filter={filter} titles={titles} />
      ))}
    </section>
  );
}

export default async function ProgressPage({ searchParams }: { searchParams: Promise<{ status?: string; durum?: string }> }) {
  const { status: statusParam, durum } = await searchParams;
  const status = statusParam ?? durum;
  const data = readProgress();
  const all = tally(data.items);
  const filter = status && Object.hasOwn(PROGRESS_STATES, status) ? (status as ProgressState) : null;
  const tab = (active: boolean) => cn("rounded-sm px-2.5 py-1", active && "bg-accent font-medium");
  const orphans = orphanItems(data);
  // Önkoşul bağlarının adı: «I. Perde · Faz 4 Dikey dilim».
  const titles = new Map(
    data.phases.map((p) => {
      const act = data.acts.find((a) => a.id === p.act);
      const n = phasesOf(data, p.act).indexOf(p) + 1;
      return [p.id, `${act?.title.split(":")[0] ?? p.act} · Faz ${n} ${p.title}`];
    }),
  );
  return (
    <main className="mx-auto w-full max-w-4xl px-5 py-10 lg:px-10">
      <h1 className="font-display text-3xl font-medium tracking-wide">Yol Haritası</h1>
      <Kusak className="mt-3" />
      <p className="mt-4 font-serif text-lg text-muted-foreground">
        Oyunun yapım sırası ve Godot'da (<code>game/</code>) yapılanlar, tek sayfada: perde, faz, madde. Her perdenin hedefi, her fazın önkoşulu
        ve çıkış ölçütü burada. Bir madde bitince işaretle; tarih ve not maddenin geçmişinde kalır. Yeşil dosya adı oyunda var, kırmızısı henüz yok.
      </p>

      <section className="mt-6 rounded-md border bg-card p-4">
        <div className="flex flex-wrap items-baseline gap-x-6 gap-y-1">
          <p className="font-display text-2xl">
            {all.bitti} <span className="text-base text-muted-foreground">/ {all.total} madde bitti</span>
          </p>
          <p className="text-sm text-muted-foreground">{all.suruyor} sürüyor · {all.yapilacak} yapılacak · %{all.percent}</p>
          {data.updated ? <p className="text-sm text-muted-foreground">Son işaret: {formatShort(data.updated)}</p> : null}
        </div>
        <Bar t={all} className="mt-3" />
        {data.acts.length > 1 ? (
          <nav aria-label="Perdeler" className="mt-4 flex flex-wrap gap-1.5 text-sm">
            {data.acts.map((act) => {
              const t = tally(itemsOfAct(data, act.id));
              return (
                <a key={act.id} href={`#${act.id}`} className="rounded-sm border px-2 py-0.5 hover:bg-accent">
                  {act.title.split(":")[0]} <span className="text-muted-foreground tabular-nums">%{t.percent}</span>
                </a>
              );
            })}
          </nav>
        ) : null}
      </section>

      <div className="mt-5 inline-flex rounded-md border p-0.5 text-sm" role="group" aria-label="Süzgeç">
        <Link href="/roadmap" prefetch={false} className={tab(!filter)}>Hepsi · {all.total}</Link>
        {(Object.keys(PROGRESS_STATES) as ProgressState[]).map((s) => (
          <Link key={s} href={`/roadmap?status=${s}`} prefetch={false} className={tab(filter === s)}>
            {PROGRESS_STATES[s]} · {all[s]}
          </Link>
        ))}
      </div>

      {data.acts.map((act) => (
        <ActBlock key={act.id} act={act} phases={phasesOf(data, act.id)} items={itemsOfAct(data, act.id)} filter={filter} data={data} titles={titles} />
      ))}

      {orphans.length ? (
        <section className="mt-12" aria-labelledby="fazsiz">
          <h2 id="fazsiz" className="font-display text-xl font-medium tracking-wide">Fazı belirsiz maddeler</h2>
          <p className="mt-1 text-sm text-muted-foreground">Bu maddelerin fazı dosyada yok; <code>content/progress.json</code>'da bir faza bağlanmalı.</p>
          <ul className="mt-2 divide-y border-y">
            {(filter ? orphans.filter((i) => i.status === filter) : orphans).map((item) => (
              <Row key={item.id} item={item} />
            ))}
          </ul>
        </section>
      ) : null}

      {data.items.length === 0 ? (
        <p className="mt-8 rounded-md border bg-card p-5 text-muted-foreground">Henüz madde yok. Plan <code>docs-app/content/progress.json</code> dosyasındadır.</p>
      ) : null}
    </main>
  );
}
