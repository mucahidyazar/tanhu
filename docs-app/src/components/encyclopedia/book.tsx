"use client";

// Ansiklopedi kitabı (kullanıcının örnek tasarımı, 2026-11-04): açık parşömen; üstte simgeli bölüm sekmeleri (Q / E), solda
// portreli dizin (↑ / ↓), ortada kişinin görselleri (PROFİL, ART, 3B ya da T-POZ; ← / → görsel değiştirir, Enter büyütür),
// sağda numaralı bölümler, bilgi satırı, soy bağları ve kaynak notu. Başlığın yanındaki hoparlör kişinin kendini iki
// cümleyle tanıttığı sesi çalar. Her kaydın kendi adresi vardır: /encyclopedia/<kimlik>.
import { Box, Castle, ChevronDown, ChevronLeft, ChevronRight, Flame, Search, Sparkles, Sun, Swords, Tent, Users, Volume2, VolumeX } from "lucide-react";
import Link from "next/link";
import { type ComponentType, createElement, type ReactNode, useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useModelViewerStatus } from "@/components/media/use-model-viewer";
import type { EncyclopediaChapter, EncyclopediaRelation, EncyclopediaSection, EncyclopediaView } from "@/lib/encyclopedia";
import { fold } from "@/lib/text";
import { cn } from "@/lib/utils";

const ERA_LABEL = { mit: "Mit", tarih: "Tarih", kurgu: "Kurgu" } as const;
const ICONS: Record<NonNullable<EncyclopediaChapter["icon"]>, ComponentType<{ className?: string; strokeWidth?: number }>> = {
  sun: Sun,
  bow: Swords,
  yurt: Tent,
  horse: Flame,
  tower: Castle,
  people: Users,
  star: Sparkles,
};
// 3B görünüm: Google model-viewer, yalnız 3B sekmesi açılınca yüklenir (sabit sürüm; components/media/use-model-viewer.ts).

interface BookProps {
  book: { title: string; intro?: string; updated: string; chapters: EncyclopediaChapter[] };
  entries: EncyclopediaView[];
  initialId: string | null;
  backdrop?: string;
}

type Slot = { key: "profile" | "art" | "pose" | "model"; label: string; url: string | null; poster?: string | null };

const isTyping = (el: EventTarget | null) => el instanceof HTMLElement && (el.isContentEditable || ["INPUT", "TEXTAREA", "SELECT"].includes(el.tagName));
// ↑ / ↓ okunan metnin içindeyken sayfayı kaydırır; başka her yerde kişi seçer.
const inReading = (el: EventTarget | null) => el instanceof HTMLElement && !!el.closest(".ency2-content");

const slotsOf = (e: EncyclopediaView): Slot[] => [
  { key: "profile", label: "Profil", url: e.portraitUrl },
  { key: "art", label: "Art", url: e.artUrl },
  e.modelUrl ? { key: "model", label: "3B", url: e.modelUrl, poster: e.artUrl ?? e.poseUrl } : { key: "pose", label: "T-poz", url: e.poseUrl },
];
// Açılışta tam boy resim gösterilir; yoksa ilk var olan görsel.
const defaultSlot = (e: EncyclopediaView) => {
  const s = slotsOf(e);
  return s[1].url ? 1 : Math.max(0, s.findIndex((x) => x.url));
};

// Eski biçimli kayıt (summary, body, quote) numaralı bölümlere çevrilir.
function sectionsOf(e: EncyclopediaView): EncyclopediaSection[] {
  if (e.sections?.length) return e.sections;
  const out: EncyclopediaSection[] = [];
  if (e.summary) out.push({ title: "Kimliği", text: e.summary });
  if (e.body?.length) out.push({ title: "Anlatı", text: e.body.join("\n\n") });
  if (e.quote) out.push({ title: "Söz", text: `«${e.quote.text}» (${e.quote.source})` });
  return out;
}

function Knot({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 48 24" className={className} aria-hidden="true" fill="none" stroke="currentColor" strokeWidth={2} strokeLinejoin="round">
      <path d="M12 4 20 12 12 20 4 12Z" />
      <path d="M24 4 32 12 24 20 16 12Z" />
      <path d="M36 4 44 12 36 20 28 12Z" />
      <path d="M12 9 15 12 12 15 9 12Z M36 9 39 12 36 15 33 12Z" strokeWidth={1.4} />
    </svg>
  );
}

function Gem({ className }: { className?: string }) {
  return <span aria-hidden="true" className={cn("ency2-gem", className)} />;
}

function Rule({ className, children }: { className?: string; children?: ReactNode }) {
  return (
    <div className={cn("ency2-rule", className)} aria-hidden={children ? undefined : true}>
      <span />
      {children ? (
        <>
          <Gem />
          {children}
          <Gem />
        </>
      ) : (
        <Gem />
      )}
      <span />
    </div>
  );
}

export function EncyclopediaBook({ book, entries, initialId }: BookProps) {
  const byId = useMemo(() => new Map(entries.map((e) => [e.id, e])), [entries]);
  const initial = initialId ? byId.get(initialId) ?? null : null;
  const [chapterId, setChapterId] = useState<string>(initial?.chapter ?? book.chapters[0]?.id ?? "");
  const [selectedId, setSelectedId] = useState<string | null>(initial?.id ?? null);
  const [query, setQuery] = useState("");
  const [slot, setSlot] = useState(() => (initial ? defaultSlot(initial) : 1));
  const [zoom, setZoom] = useState(false);
  const [indexOpen, setIndexOpen] = useState(true);
  const contentRef = useRef<HTMLElement>(null);

  const chapterIndex = book.chapters.findIndex((c) => c.id === chapterId);
  const chapter = book.chapters[chapterIndex] ?? null;
  const q = fold(query.trim());
  const matches = (e: EncyclopediaView) => !q || [e.name, e.epithet ?? "", ...(e.altNames ?? [])].some((s) => fold(s).includes(q));
  const listed = entries.filter((e) => (q ? matches(e) : e.chapter === chapterId));
  const selected = selectedId ? byId.get(selectedId) ?? null : null;
  const slots = selected ? slotsOf(selected) : [];

  const open = useCallback(
    (id: string | null) => {
      setSelectedId(id);
      setZoom(false);
      const e = id ? byId.get(id) : null;
      if (e) {
        setChapterId(e.chapter);
        setSlot(defaultSlot(e));
      }
      // Adres sayfayı yeniden yüklemeden güncellenir: kitap yerinde kalır, kayıt adresi paylaşılabilir.
      window.history.replaceState(null, "", id ? `/encyclopedia/${id}` : "/encyclopedia");
      document.title = e ? `${e.name} · Ansiklopedi · Tanhu Belgeleri` : "Ansiklopedi · Tanhu Belgeleri";
      contentRef.current?.scrollTo({ top: 0 });
    },
    [byId],
  );

  const goChapter = useCallback(
    (index: number) => {
      const next = book.chapters[(index + book.chapters.length) % book.chapters.length];
      if (!next) return;
      setQuery("");
      setChapterId(next.id);
      const firstEntry = entries.find((e) => e.chapter === next.id);
      open(firstEntry?.id ?? null);
    },
    [book.chapters, entries, open],
  );

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (event.metaKey || event.ctrlKey || event.altKey || isTyping(event.target)) return;
      const list = q ? listed : entries.filter((e) => e.chapter === chapterId);
      const pos = selected ? list.findIndex((e) => e.id === selected.id) : -1;
      const key = event.key.toLocaleLowerCase("tr");
      if (zoom && event.key === "Escape") setZoom(false);
      else if (key === "q") goChapter(chapterIndex - 1);
      else if (key === "e") goChapter(chapterIndex + 1);
      else if (event.key === "ArrowDown" && list.length && !inReading(event.target)) open(list[Math.min(list.length - 1, pos + 1)].id);
      else if (event.key === "ArrowUp" && list.length && !inReading(event.target)) open(list[Math.max(0, pos - 1)].id);
      else if (event.key === "ArrowRight" && selected) setSlot((s) => (s + 1) % 3);
      else if (event.key === "ArrowLeft" && selected) setSlot((s) => (s + 2) % 3);
      else if (event.key === "Enter" && selected && !(event.target instanceof HTMLButtonElement) && !(event.target instanceof HTMLAnchorElement)) setZoom(!zoom);
      else if (event.key === "Escape") open(null);
      else return;
      event.preventDefault();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [chapterId, chapterIndex, entries, goChapter, listed, open, q, selected, zoom]);

  return (
    <main className="ency2">
      <Corner className="is-bl" />
      <Corner className="is-br" />
      <nav className="ency2-tabs" aria-label="Ansiklopedinin bölümleri">
        <kbd className="ency2-key" aria-hidden="true">Q</kbd>
        <div className="ency2-tablist">
          {book.chapters.map((c, i) => {
            const Icon = ICONS[c.icon ?? "star"] ?? Sparkles;
            const active = c.id === chapterId && !q;
            return (
              <button key={c.id} type="button" aria-current={active ? "true" : undefined} className={cn("ency2-tab", active && "is-active")} onClick={() => goChapter(i)}>
                <Icon className="ency2-tab-icon" strokeWidth={1.5} />
                <span>{c.title}</span>
              </button>
            );
          })}
        </div>
        <kbd className="ency2-key" aria-hidden="true">E</kbd>
      </nav>

      <div className="ency2-body">
        <aside className="ency2-index" aria-label="Dizin">
          <button type="button" className="ency2-index-head" aria-expanded={indexOpen} onClick={() => setIndexOpen((v) => !v)}>
            <span>{book.title}</span>
            <ChevronDown className={cn("size-4 transition-transform", !indexOpen && "-rotate-90")} />
          </button>
          <p className="ency2-count">{q ? `Arama · ${listed.length} kayıt` : `${chapter?.title ?? ""} · ${listed.length} kayıt`}</p>
          <label className="ency2-search">
            <Search className="size-4" aria-hidden="true" />
            <span className="sr-only">Ansiklopedide ara</span>
            <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Ad veya unvan ara" />
          </label>
          {indexOpen ? (
            <ul className="ency2-list">
              {listed.map((e) => (
                <li key={e.id}>
                  <Link
                    href={`/encyclopedia/${e.id}`}
                    prefetch={false}
                    scroll={false}
                    aria-current={selected?.id === e.id ? "page" : undefined}
                    className={cn("ency2-item", selected?.id === e.id && "is-selected")}
                    onClick={(ev) => {
                      // Yeni sekmede açma (Cmd, Ctrl, Shift, orta tuş) tarayıcıya kalır.
                      if (ev.metaKey || ev.ctrlKey || ev.shiftKey || ev.altKey || ev.button !== 0) return;
                      ev.preventDefault();
                      open(e.id);
                    }}
                  >
                    <Thumb url={e.portraitUrl ?? e.artUrl} name={e.name} />
                    <span className="ency2-item-name">{e.name}</span>
                  </Link>
                </li>
              ))}
              {listed.length === 0 ? <li className="ency2-empty">Bu sayfalar henüz boş.</li> : null}
            </ul>
          ) : null}
        </aside>

        {selected ? (
          <Viewer key={`viewer-${selected.id}`} entry={selected} slots={slots} slot={slot} setSlot={setSlot} zoom={zoom} setZoom={setZoom} />
        ) : (
          <section className="ency2-viewer is-cover" aria-label="Kitabın kapağı">
            <div className="ency2-cover">
              <Knot className="ency2-cover-knot" />
              <p className="ency2-cover-title">{book.title}</p>
              <p className="ency2-cover-sub">Göğün, yerin ve Mete'nin çağının kişileri</p>
            </div>
          </section>
        )}

        <article ref={contentRef} key={`content-${selected?.id ?? `toc-${chapterId}`}`} className="ency2-content">
          {selected ? <EntryContent entry={selected} byId={byId} onOpen={open} /> : <Contents book={book} entries={entries} onOpen={open} />}
        </article>
      </div>

      <footer className="ency2-hints" aria-label="Tuşlar">
        <span>
          <kbd>Q</kbd> <kbd>E</kbd> Kategori değiştir
        </span>
        <span>
          <kbd>↑</kbd> <kbd>↓</kbd> Karakter seç
        </span>
        <span>
          <kbd>←</kbd> <kbd>→</kbd> Görsel değiştir
        </span>
        <span>
          <kbd>Enter</kbd> Görseli büyüt
        </span>
        <span>
          <kbd>Esc</kbd> Geri
        </span>
      </footer>
    </main>
  );
}

function Corner({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 64 64" className={cn("ency2-corner", className)} aria-hidden="true" fill="none" stroke="currentColor" strokeWidth={2}>
      <path d="M4 60V36h12v12h12v12H4Z M4 28V4h24v12H16v12H4Z M36 60V48h12V36h12v24H36Z" />
    </svg>
  );
}

function Thumb({ url, name, className }: { url: string | null; name: string; className?: string }) {
  return url ? (
    // Yerel küçük görsel: next/image gerekmez.
    <img src={url} alt="" loading="lazy" className={cn("ency2-thumb", className)} />
  ) : (
    <span className={cn("ency2-thumb is-empty", className)} aria-hidden="true">
      {name.slice(0, 1)}
    </span>
  );
}

function Viewer({
  entry,
  slots,
  slot,
  setSlot,
  zoom,
  setZoom,
}: {
  entry: EncyclopediaView;
  slots: Slot[];
  slot: number;
  setSlot: (n: number | ((n: number) => number)) => void;
  zoom: boolean;
  setZoom: (v: boolean) => void;
}) {
  const current = slots[slot] ?? slots[0];
  const viewer = useModelViewerStatus(current.key === "model" && !!current.url);
  const stage = (big: boolean) => {
    if (!current.url) {
      return (
        <div className="ency2-stage-empty">
          <span>{entry.name.slice(0, 1)}</span>
          <p>{current.key === "pose" ? "T-poz görseli henüz üretilmedi. 3B model sonra bundan üretilecek." : current.key === "profile" ? "Profil görseli henüz üretilmedi." : "Art görseli henüz üretilmedi."}</p>
        </div>
      );
    }
    if (current.key === "model") {
      if (viewer.status === "error") {
        return (
          <div className="ency2-stage-empty" role="alert">
            <p>3B görüntüleyici yüklenemedi: model-viewer betiği (cdn.jsdelivr.net) alınamadı.</p>
            <button
              type="button"
              onClick={viewer.retry}
              className="rounded-md border border-(color:--k-gold) bg-(color:--k-paper) px-3 py-1 text-sm not-italic text-(color:--k-ink) hover:bg-(color:--k-gold-soft) focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-(color:--k-green)"
            >
              Yeniden dene
            </button>
          </div>
        );
      }
      if (viewer.status !== "ready") {
        return (
          <div className="ency2-stage-empty">
            <p>3B model yükleniyor…</p>
          </div>
        );
      }
      return createElement("model-viewer", {
        src: current.url,
        poster: current.poster ?? undefined,
        alt: `${entry.name}: 3B model`,
        "camera-controls": "",
        "auto-rotate": "",
        "shadow-intensity": "0.7",
        exposure: "1.05",
        "interaction-prompt": "none",
        class: big ? "ency2-model is-big" : "ency2-model",
      });
    }
    return (
      // Yerel görsel: next/image gerekmez.
      <img src={current.url} alt={`${entry.name}: ${current.label}`} className={cn("ency2-stage-img", current.key === "profile" && "is-profile")} />
    );
  };
  return (
    <section className="ency2-viewer" aria-label={`${entry.name} görselleri`}>
      {current.key === "model" && current.url ? (
        <div className="ency2-stage">{stage(false)}</div>
      ) : (
        <button type="button" className="ency2-stage" onClick={() => current.url && setZoom(true)} aria-label="Görseli büyüt" disabled={!current.url}>
          {stage(false)}
        </button>
      )}
      <div className="ency2-strip">
        <button type="button" className="ency2-arrow" aria-label="Önceki görsel" onClick={() => setSlot((s) => (s + 2) % 3)}>
          <ChevronLeft className="size-5" />
        </button>
        {slots.map((s, i) => (
          <button key={s.key} type="button" className={cn("ency2-slot", i === slot && "is-active")} onClick={() => setSlot(i)} aria-pressed={i === slot}>
            <span className="ency2-slot-img">
              {s.key === "model" ? (
                <>
                  {s.poster ? <img src={s.poster} alt="" loading="lazy" /> : null}
                  <Box className="ency2-slot-badge" strokeWidth={1.6} />
                </>
              ) : s.url ? (
                <img src={s.url} alt="" loading="lazy" />
              ) : (
                <span className="ency2-slot-none">yok</span>
              )}
            </span>
            <span className="ency2-slot-label">{s.label}</span>
          </button>
        ))}
        <button type="button" className="ency2-arrow" aria-label="Sonraki görsel" onClick={() => setSlot((s) => (s + 1) % 3)}>
          <ChevronRight className="size-5" />
        </button>
      </div>
      <p className="ency2-pager" aria-live="polite">
        <Gem /> <span>{slot + 1} / 3</span> <Gem />
      </p>
      {zoom && current.url ? (
        <div className="ency2-lightbox" role="dialog" aria-modal="true" aria-label={`${entry.name}: ${current.label}`} onClick={() => setZoom(false)}>
          <div className="ency2-lightbox-inner" onClick={(e) => e.stopPropagation()}>
            {stage(true)}
            <button type="button" className="ency2-lightbox-close" onClick={() => setZoom(false)}>
              Kapat <kbd>Esc</kbd>
            </button>
          </div>
        </div>
      ) : null}
    </section>
  );
}

function VoiceButton({ entry }: { entry: EncyclopediaView }) {
  const audio = useRef<HTMLAudioElement | null>(null);
  const [playing, setPlaying] = useState(false);
  // Sesi olmayan tanıtımın yazısı hoparlöre basınca açılır.
  const [shown, setShown] = useState(false);
  useEffect(() => {
    setShown(false);
    return () => {
      audio.current?.pause();
      audio.current = null;
    };
  }, [entry.id]);
  if (!entry.intro) return null;
  const caption = (
    <>
      <span lang="tr">{entry.intro.tr}</span>
      <span lang="en">{entry.intro.en}</span>
    </>
  );
  // Oyunda konuşmayan kişi sesle tanıtılmaz: hoparlör yok, iki cümle başlığın altında yazıdır (K86).
  if (entry.speaks === false) return null;
  const available = !!entry.audioUrl;
  const label = available
    ? `${entry.name} kendini tanıtsın`
    : entry.voicePending
      ? `${entry.name}: tanıtımı oku (sesi seçimini bekliyor)`
      : `${entry.name}: tanıtımı oku (ses henüz üretilmedi)`;
  const toggle = () => {
    if (!entry.audioUrl) {
      setShown((v) => !v);
      return;
    }
    if (!audio.current) {
      audio.current = new Audio(entry.audioUrl);
      audio.current.addEventListener("ended", () => setPlaying(false));
    }
    if (playing) {
      audio.current.pause();
      audio.current.currentTime = 0;
      setPlaying(false);
    } else {
      void audio.current.play();
      setPlaying(true);
    }
  };
  const open = playing || shown;
  return (
    <div className="ency2-voice">
      <button
        type="button"
        className={cn("ency2-voice-btn", playing && "is-playing", !available && "is-silent")}
        onClick={toggle}
        aria-pressed={open}
        aria-label={label}
        title={available && entry.voice?.name ? `${label} (ses: ${entry.voice.name})` : label}
      >
        {available ? <Volume2 className="size-5" strokeWidth={1.6} /> : <VolumeX className="size-5" strokeWidth={1.6} />}
      </button>
      {open ? <p className="ency2-voice-caption">{caption}</p> : null}
    </div>
  );
}

function LineageCard({ rel, byId, onOpen }: { rel: EncyclopediaRelation; byId: Map<string, EncyclopediaView>; onOpen: (id: string) => void }) {
  const other = byId.get(rel.id);
  if (!other) {
    return (
      <span className="ency2-kin is-missing">
        <span className="ency2-thumb is-empty">?</span>
        <span>
          <b>{rel.id}</b>
          <em>{rel.label}</em>
        </span>
      </span>
    );
  }
  return (
    <button type="button" className="ency2-kin" onClick={() => onOpen(other.id)}>
      <Thumb url={other.portraitUrl ?? other.artUrl} name={other.name} />
      <span>
        <b>{other.name}</b>
        <em>{rel.label}</em>
      </span>
    </button>
  );
}

function EntryContent({ entry, byId, onOpen }: { entry: EncyclopediaView; byId: Map<string, EncyclopediaView>; onOpen: (id: string) => void }) {
  const sections = sectionsOf(entry);
  const lineage = entry.lineage ?? (entry.relations?.length ? { side: entry.relations } : undefined);
  const groups = lineage
    ? ([
        ["Üst soy", lineage.up],
        ["Alt soy", lineage.down],
        [lineage.up?.length || lineage.down?.length ? "Yan bağlar" : "Bağlar", lineage.side],
      ] as const).filter(([, rows]) => rows && rows.length)
    : [];
  return (
    <div className="ency2-entry">
      <header className="ency2-head">
        <span className="ency2-vtab" aria-hidden="true">Ansiklopedi</span>
        <div className="ency2-head-text">
          <div className="ency2-title-row">
            <h1 className="ency2-title">{entry.name}</h1>
            <Knot className="ency2-knot" />
            <VoiceButton entry={entry} />
          </div>
          {entry.epithet ? <p className="ency2-epithet">{entry.epithet}</p> : null}
          <p className={cn("ency2-era", `is-${entry.era}`)}>
            <Gem /> {ERA_LABEL[entry.era]}
            {entry.altNames?.length ? <span className="ency2-alt"> · {entry.altNames.join(" · ")}</span> : null}
          </p>
          {entry.speaks === false && entry.intro ? (
            <p className="ency2-intro-static">
              <span lang="tr">{entry.intro.tr}</span>
              <span lang="en">{entry.intro.en}</span>
            </p>
          ) : null}
        </div>
      </header>
      <Rule />

      {sections.map((s, i) => (
        <section key={s.title} className="ency2-section">
          <span className="ency2-num" aria-hidden="true">
            <span>{String(i + 1).padStart(2, "0")}</span>
          </span>
          <div>
            <h2>{s.title}</h2>
            {s.text.split(/\n\n+/).map((para) => (
              <p key={para.slice(0, 40)}>{para}</p>
            ))}
          </div>
        </section>
      ))}

      {entry.facts?.length || entry.acts?.length ? (
        <>
          <dl className="ency2-facts">
            {(entry.facts ?? []).map((f) => (
              <div key={f.label}>
                <dt>{f.label}:</dt>
                <dd>{f.value}</dd>
              </div>
            ))}
            {entry.acts?.length ? (
              <div>
                <dt>Perdeler:</dt>
                <dd>{entry.acts.join(", ")}</dd>
              </div>
            ) : null}
          </dl>
          <Rule className="ency2-rule-thin" />
        </>
      ) : null}

      {groups.length ? (
        <section className="ency2-lineage" aria-labelledby={`soy-${entry.id}`}>
          <Rule className="ency2-rule-title">
            <h2 id={`soy-${entry.id}`}>Soy bağları</h2>
          </Rule>
          <div className="ency2-lineage-groups">
            {groups.map(([title, rows]) => (
              <div key={title} className="ency2-lineage-group">
                <p className="ency2-pill">{title}</p>
                <div className="ency2-kins">
                  {rows!.map((r) => (
                    <LineageCard key={`${r.id}-${r.label}`} rel={r} byId={byId} onOpen={onOpen} />
                  ))}
                </div>
              </div>
            ))}
          </div>
          {lineage?.note ? <p className="ency2-lineage-note">{lineage.note}</p> : null}
        </section>
      ) : null}

      {entry.sourceNote || entry.eraNote || entry.sources?.length ? (
        <aside className="ency2-source">
          {entry.sourceNote ? <p>{entry.sourceNote}</p> : null}
          {entry.eraNote ? <p>Çağı: {entry.eraNote}</p> : null}
          {entry.sources?.length ? (
            <p className="ency2-source-links">
              {entry.sources.map((s, i) => (
                <span key={s.href}>
                  {i > 0 ? " · " : null}
                  <Link href={s.href} prefetch={false}>
                    {s.label}
                  </Link>
                </span>
              ))}
            </p>
          ) : null}
        </aside>
      ) : null}
    </div>
  );
}

function Contents({ book, entries, onOpen }: { book: BookProps["book"]; entries: EncyclopediaView[]; onOpen: (id: string) => void }) {
  return (
    <div className="ency2-entry">
      <header className="ency2-head">
        <span className="ency2-vtab" aria-hidden="true">Ansiklopedi</span>
        <div className="ency2-head-text">
          <div className="ency2-title-row">
            <h1 className="ency2-title">İçindekiler</h1>
            <Knot className="ency2-knot" />
          </div>
          {book.intro ? <p className="ency2-epithet is-plain">{book.intro}</p> : null}
        </div>
      </header>
      <Rule />
      {book.chapters.map((c, i) => {
        const rows = entries.filter((e) => e.chapter === c.id);
        return (
          <section key={c.id} className="ency2-section">
            <span className="ency2-num" aria-hidden="true">
              <span>{String(i + 1).padStart(2, "0")}</span>
            </span>
            <div>
              <h2>
                {c.title} <small>{rows.length}</small>
              </h2>
              {c.summary ? <p className="ency2-muted">{c.summary}</p> : null}
              <p className="ency2-toc-names">
                {rows.map((e, k) => (
                  <span key={e.id}>
                    {k > 0 ? " · " : null}
                    <button type="button" onClick={() => onOpen(e.id)}>
                      {e.name}
                    </button>
                  </span>
                ))}
              </p>
            </div>
          </section>
        );
      })}
      {entries.length === 0 ? <p className="ency2-muted">Bu sayfalar henüz boş. Kayıtlar content/encyclopedia.json dosyasına yazılınca burada görünür.</p> : null}
    </div>
  );
}
