"use client";

// Kenar çubuğu. Üstte arama ve kullanıcının sabitledikleri (sırası sürükle bırakla ya da Alt + ↑ / ↓ ile değişir); altta
// kategoriler, «Oyun» (Yol Haritası, Ansiklopedi, Görevler, Animasyonlar, Varlıklar), «Çalışma» (Notlar, Karar Bekleyenler, Sürümler) ve kaynak
// belgeler. Her satırın sağındaki raptiye o sayfayı sabitler; sabitlenenler data/pins.json'da durur.
import { BookOpen, Boxes, Check, CircleAlert, FileClock, GripVertical, History, MessageSquareText, Moon, PersonStanding, Pin, PinOff, Route, Scale, ScrollText, Search, Sun } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useTheme } from "next-themes";
import { type KeyboardEvent, type PointerEvent as ReactPointerEvent, type ReactNode, useEffect, useMemo, useOptimistic, useRef, useState, useTransition } from "react";
import { toast } from "sonner";
import { GameIcon, Kusak } from "@/components/brand";
import { openSearch } from "@/components/shell/search-dialog";
import { StatusGlyph } from "@/components/shell/status-mark";
import { setPinsAction } from "@/lib/actions";
import type { NavData, NavGroup, NavItem } from "@/lib/nav";
import { cn } from "@/lib/utils";

// Kenar çubuğunun bir satırı: adres, ad, solda simge ya da durum işareti, sağda sayaçlar.
interface Entry {
  href: string;
  label: string;
  title?: string;
  lead: ReactNode;
  trail?: ReactNode;
  // Etkin sayılma kuralı: tam eşleşme ya da önek (ansiklopedi gibi alt adresli sayfalar).
  prefix?: boolean;
}

const rowClass = "group/row relative flex items-center rounded-sm text-[0.9rem] leading-snug text-sidebar-foreground/85 hover:bg-sidebar-accent hover:text-sidebar-accent-foreground";
const sectionTitle =
  "flex cursor-pointer list-none items-center gap-2 px-2 pb-1 pt-3 font-display text-[0.72rem] font-medium uppercase tracking-[0.16em] text-sidebar-foreground/60 hover:text-sidebar-foreground [&::-webkit-details-marker]:hidden";

function docTrail(item: NavItem) {
  return (
    <>
      {item.conflicts > 0 && (
        <span title={`${item.conflicts} çelişki`} className="inline-flex items-center gap-0.5 text-xs text-[#f0a48f]">
          <CircleAlert className="size-3" />
          {item.conflicts}
        </span>
      )}
      {item.notes > 0 && (
        <span title={`${item.notes} açık not`} className="inline-flex items-center gap-0.5 text-xs text-sidebar-primary">
          <MessageSquareText className="size-3" />
          {item.notes}
        </span>
      )}
      {item.review === "tamam" && <Check className="size-3.5 text-sidebar-primary" aria-label="Gözden geçirildi" />}
      {item.review === "degisti" && <FileClock className="size-3.5 text-[#f0a48f]" aria-label="Gözden geçirildikten sonra değişti" />}
    </>
  );
}

const docEntry = (item: NavItem): Entry => ({
  href: `/docs/${item.id}`,
  label: item.label,
  title: item.title,
  lead: item.status ? <StatusGlyph status={item.status} className="text-sidebar-primary/80" /> : <span className="size-2.5 shrink-0" />,
  trail: docTrail(item),
});

function toolEntries(nav: NavData) {
  const icon = (I: typeof Route) => <I className="size-3.5 shrink-0" />;
  const roadmap: Entry = { href: "/roadmap", label: "Yol Haritası", lead: icon(Route), trail: <span className="text-xs text-sidebar-foreground/60">%{nav.progress.percent}</span> };
  const encyclopedia: Entry = { href: "/encyclopedia", label: "Ansiklopedi", lead: icon(BookOpen), prefix: true };
  const quests: Entry = { href: "/quests", label: "Görevler", lead: icon(ScrollText), prefix: true };
  const animations: Entry = { href: "/animations", label: "Animasyonlar", lead: icon(PersonStanding) };
  const assets: Entry = { href: "/assets", label: "Varlıklar", lead: icon(Boxes) };
  const notes: Entry = { href: "/notes", label: "Notlar", lead: icon(MessageSquareText), trail: nav.openNotes > 0 ? <span className="text-xs text-sidebar-primary">{nav.openNotes}</span> : null };
  const pending: Entry = { href: "/docs/general/pending-decisions", label: "Karar Bekleyenler", lead: icon(Scale), trail: nav.pending > 0 ? <span className="text-xs text-sidebar-primary">{nav.pending}</span> : null };
  const releases: Entry = { href: "/releases", label: "Sürümler", lead: icon(History) };
  return { game: [roadmap, encyclopedia, quests, animations], assets, work: [notes, pending, releases] };
}

function PinButton({ pinned, label, onToggle }: { pinned: boolean; label: string; onToggle: () => void }) {
  return (
    <button
      type="button"
      onClick={onToggle}
      aria-pressed={pinned}
      aria-label={pinned ? `${label}: sabitlemeyi kaldır` : `${label}: sabitle`}
      title={pinned ? "Sabitlemeyi kaldır" : "Arama'nın altına sabitle"}
      className={cn(
        "mr-1 grid size-6 shrink-0 place-items-center rounded-sm text-sidebar-foreground/50 hover:bg-sidebar-border hover:text-sidebar-accent-foreground focus-visible:opacity-100",
        // Dokunmatik ekranda üstüne gelme yok: raptiye hep görünür.
        pinned ? "text-sidebar-primary" : "opacity-0 group-hover/row:opacity-100 [@media(hover:none)]:opacity-60",
      )}
    >
      {pinned ? <Pin className="size-3.5 fill-current" /> : <Pin className="size-3.5" />}
    </button>
  );
}

function Row({ entry, active, pinned, onToggle, onNavigate }: { entry: Entry; active: boolean; pinned: boolean; onToggle: () => void; onNavigate?: () => void }) {
  return (
    <div className={cn(rowClass, active && "bg-sidebar-accent font-medium text-sidebar-accent-foreground")}>
      <Link href={entry.href} prefetch={false} onClick={onNavigate} draggable={false} title={entry.title ?? entry.label} aria-current={active ? "page" : undefined} className="flex min-w-0 flex-1 items-center gap-2 px-2 py-1">
        {entry.lead}
        <span className="min-w-0 flex-1 truncate">{entry.label}</span>
        {entry.trail}
      </Link>
      <PinButton pinned={pinned} label={entry.label} onToggle={onToggle} />
    </div>
  );
}

// Sabitlenenler: sıra işaretçiyle değişir (fare satırın her yerinden, dokunmatik ekran tutamaçtan sürükler) ya da
// tutamaç odaktayken Alt + ↑ / ↓ ile. HTML5 sürükle bırak kullanılmaz: dokunmatik ekranda çalışmıyor.
function PinnedList({
  pins,
  byHref,
  isActive,
  onToggle,
  onMove,
  onNavigate,
}: {
  pins: string[];
  byHref: Map<string, Entry>;
  isActive: (e: Entry) => boolean;
  onToggle: (href: string) => void;
  onMove: (from: number, to: number) => void;
  onNavigate?: () => void;
}) {
  const rows = useRef<(HTMLLIElement | null)[]>([]);
  const drag = useRef<{ from: number; startY: number; active: boolean } | null>(null);
  const stopDrag = useRef<(() => void) | null>(null);
  const suppressClick = useRef(false);
  const [state, setState] = useState<{ from: number; slot: number } | null>(null);

  // Sürüklerken bileşen kalkarsa pencere dinleyicileri de kalksın.
  useEffect(() => () => stopDrag.current?.(), []);

  // İşaretçinin altındaki araya giriş yeri: 0 ilk satırın üstü, pins.length sonuncunun altı.
  const slotAt = (y: number) => {
    for (let i = 0; i < pins.length; i++) {
      const r = rows.current[i]?.getBoundingClientRect();
      if (r && y < r.top + r.height / 2) return i;
    }
    return pins.length;
  };

  const onPointerDown = (i: number) => (event: ReactPointerEvent<HTMLLIElement>) => {
    if (event.button !== 0) return;
    const target = event.target as HTMLElement;
    const onHandle = Boolean(target.closest("[data-handle]"));
    if (!onHandle && target.closest("button")) return;
    if (event.pointerType !== "mouse" && !onHandle) return;
    drag.current = { from: i, startY: event.clientY, active: false };
    const move = (ev: PointerEvent) => {
      const d = drag.current;
      if (!d) return;
      if (!d.active && Math.abs(ev.clientY - d.startY) < 5) return;
      d.active = true;
      ev.preventDefault();
      setState({ from: d.from, slot: slotAt(ev.clientY) });
    };
    const end = (ev: PointerEvent) => {
      stopDrag.current?.();
      const d = drag.current;
      drag.current = null;
      setState(null);
      if (!d?.active || ev.type === "pointercancel") return;
      // Bırakılan yer bir bağlantıysa tıklama sayılmasın; aynı görevde gelen tıklama yutulur, sonra bayrak iner.
      suppressClick.current = true;
      setTimeout(() => {
        suppressClick.current = false;
      }, 0);
      const slot = slotAt(ev.clientY);
      onMove(d.from, slot > d.from ? slot - 1 : slot);
    };
    stopDrag.current = () => {
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", end);
      window.removeEventListener("pointercancel", end);
      stopDrag.current = null;
    };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", end);
    window.addEventListener("pointercancel", end);
  };

  const onHandleKey = (i: number) => (event: KeyboardEvent) => {
    if (!event.altKey || (event.key !== "ArrowUp" && event.key !== "ArrowDown")) return;
    event.preventDefault();
    const to = event.key === "ArrowUp" ? i - 1 : i + 1;
    if (to < 0 || to >= pins.length) return;
    onMove(i, to);
    // Satır yeni yerine taşınınca odak tutamağında kalsın (DOM'da yer değiştiren düğüm odağı yitirebilir).
    requestAnimationFrame(() => rows.current[to]?.querySelector<HTMLElement>("[data-handle]")?.focus());
  };

  // Giriş çizgisi: taşıma bir şey değiştirmeyecekse (kendi yeri ya da hemen altı) görünmez.
  const lineAt = state && state.slot !== state.from && state.slot !== state.from + 1 ? state.slot : null;
  return (
    <ul
      aria-label="Sabitlenenler"
      onClickCapture={(event) => {
        if (!suppressClick.current) return;
        event.preventDefault();
        event.stopPropagation();
        suppressClick.current = false;
      }}
      className={cn("mt-1 space-y-px border-t border-sidebar-border/60 pt-1", state && "cursor-grabbing select-none")}
    >
      {pins.map((href, i) => {
        const entry = byHref.get(href);
        if (!entry) {
          return (
            <li
              key={href}
              ref={(el) => {
                rows.current[i] = el;
              }}
              className="flex items-center gap-2 px-2 py-1 text-xs text-sidebar-foreground/50"
            >
              <PinOff className="size-3.5" />
              <span className="min-w-0 flex-1 truncate">{href} artık yok</span>
              <button type="button" onClick={() => onToggle(href)} className="underline">
                kaldır
              </button>
            </li>
          );
        }
        return (
          <li
            key={href}
            ref={(el) => {
              rows.current[i] = el;
            }}
            onPointerDown={onPointerDown(i)}
            className={cn(
              "relative flex items-center",
              state?.from === i && "opacity-50",
              lineAt === i && "before:absolute before:inset-x-1 before:-top-px before:h-0.5 before:bg-sidebar-primary",
              lineAt === pins.length && i === pins.length - 1 && "after:absolute after:inset-x-1 after:-bottom-px after:h-0.5 after:bg-sidebar-primary",
            )}
          >
            <button
              type="button"
              data-handle
              onKeyDown={onHandleKey(i)}
              aria-label={`${entry.label}: sırasını değiştir (Alt + yukarı / aşağı ok)`}
              title="Sürükle ya da Alt + ↑ / ↓ ile taşı"
              className="grid w-4 shrink-0 cursor-grab touch-none place-items-center self-stretch text-sidebar-foreground/40 hover:text-sidebar-foreground active:cursor-grabbing"
            >
              <GripVertical className="size-3.5" />
            </button>
            <div className="min-w-0 flex-1">
              <Row entry={entry} active={isActive(entry)} pinned onToggle={() => onToggle(href)} onNavigate={onNavigate} />
            </div>
          </li>
        );
      })}
    </ul>
  );
}

function Section({ title, defaultOpen, children }: { title: string; defaultOpen: boolean; children: ReactNode }) {
  return (
    <details open={defaultOpen} className="group/section">
      <summary className={sectionTitle}>
        <span className="flex-1">{title}</span>
        <span className="transition-transform group-open/section:rotate-90" aria-hidden="true">›</span>
      </summary>
      <div className="space-y-px">{children}</div>
    </details>
  );
}

export function Sidebar({ nav, onNavigate }: { nav: NavData; onNavigate?: () => void }) {
  const pathname = usePathname();
  const { resolvedTheme, setTheme } = useTheme();
  // İyimser liste: kayıt sürerken yeni sıra görünür; kayıt bitince sunucunun listesi (nav.pins) geçerli olur,
  // kayıt başarısızsa kendiliğinden eskiye döner.
  const [pins, setOptimisticPins] = useOptimistic(nav.pins);
  const [, startTransition] = useTransition();
  const [announce, setAnnounce] = useState("");

  const tools = useMemo(() => toolEntries(nav), [nav]);
  // Sabitlenebilen her şeyin adresine göre dizini: sabitlenenin adı ve simgesi buradan çözülür.
  const byHref = useMemo(() => {
    const map = new Map<string, Entry>();
    for (const e of [...tools.game, tools.assets, ...tools.work]) map.set(e.href, e);
    for (const g of [...nav.categories, ...nav.sources]) for (const item of g.items) if (!map.has(`/docs/${item.id}`)) map.set(`/docs/${item.id}`, docEntry(item));
    for (const g of nav.assets) map.set(`/assets/${g.id}`, { href: `/assets/${g.id}`, label: g.title, lead: <Boxes className="size-3.5 shrink-0 opacity-70" />, trail: <span className="text-xs text-sidebar-foreground/60">{g.count}</span> });
    return map;
  }, [nav, tools]);

  const isActive = (e: Entry) => (e.prefix ? pathname === e.href || pathname.startsWith(`${e.href}/`) : pathname === e.href);
  const save = (next: string[], message: string) => {
    startTransition(async () => {
      setOptimisticPins(next);
      try {
        await setPinsAction(next);
        setAnnounce(message);
      } catch {
        toast.error("Sabitlenenler kaydedilemedi");
      }
    });
  };
  const labelOf = (href: string) => byHref.get(href)?.label ?? href;
  const toggle = (href: string) =>
    pins.includes(href) ? save(pins.filter((p) => p !== href), `${labelOf(href)} sabitlenenlerden çıktı`) : save([...pins, href], `${labelOf(href)} sabitlendi`);
  const move = (from: number, to: number) => {
    if (from === to || from < 0 || to < 0 || from >= pins.length || to >= pins.length) return;
    const next = [...pins];
    const [item] = next.splice(from, 1);
    next.splice(to, 0, item);
    save(next, `${labelOf(item)} ${to + 1}. sıraya taşındı`);
  };

  const assetsOpen = pathname.startsWith("/assets");
  return (
    <div className="flex h-full min-h-0 flex-col">
      <div className="px-4 pb-3 pt-4">
        <Link href="/" onClick={onNavigate} className="flex items-center gap-2.5">
          <GameIcon className="size-9" />
          <span>
            <span className="block font-display text-lg font-medium leading-none tracking-[0.14em] text-sidebar-accent-foreground">TANHU</span>
            <span className="mt-1 block text-xs text-sidebar-foreground/70">Oyun belgeleri{nav.release ? ` · ${nav.release}` : ""}</span>
          </span>
        </Link>
      </div>
      <Kusak className="opacity-70 [--kusak:var(--sidebar-primary)]" />
      <div className="border-b border-sidebar-border/60 px-2 pb-1.5 pt-2">
        <button type="button" onClick={openSearch} className={cn(rowClass, "w-full gap-2 px-2 py-1 text-left")}>
          <Search className="size-3.5" />
          <span className="flex-1">Ara</span>
          <kbd className="text-xs text-sidebar-foreground/60">⌘K</kbd>
        </button>
        {pins.length > 0 ? (
          <PinnedList pins={pins} byHref={byHref} isActive={isActive} onToggle={toggle} onMove={move} onNavigate={onNavigate} />
        ) : (
          <p className="px-2 pb-1 pt-1 text-[0.72rem] leading-snug text-sidebar-foreground/45">Bir satırın sağındaki raptiyeye basınca o sayfa buraya sabitlenir.</p>
        )}
      </div>
      <p className="sr-only" aria-live="polite">{announce}</p>
      <nav aria-label="Belgeler" className="min-h-0 flex-1 overflow-y-auto px-2 pb-4">
        {nav.categories.map((g: NavGroup) => (
          <Section key={g.id} title={g.title} defaultOpen>
            {g.items.map((item) => {
              const entry = docEntry(item);
              return <Row key={item.id} entry={entry} active={isActive(entry)} pinned={pins.includes(entry.href)} onToggle={() => toggle(entry.href)} onNavigate={onNavigate} />;
            })}
          </Section>
        ))}

        <Section title="Oyun" defaultOpen>
          {tools.game.map((entry) => (
            <Row key={entry.href} entry={entry} active={isActive(entry)} pinned={pins.includes(entry.href)} onToggle={() => toggle(entry.href)} onNavigate={onNavigate} />
          ))}
          <Row entry={tools.assets} active={isActive(tools.assets)} pinned={pins.includes(tools.assets.href)} onToggle={() => toggle(tools.assets.href)} onNavigate={onNavigate} />
          {nav.assets.length > 0 ? (
            <details open={assetsOpen} className="group/assets ml-3 border-l border-sidebar-border/60 pl-1">
              <summary className="flex cursor-pointer list-none items-center gap-2 px-2 py-0.5 text-[0.8rem] text-sidebar-foreground/60 hover:text-sidebar-foreground [&::-webkit-details-marker]:hidden">
                <span className="flex-1">Varlık türleri</span>
                <span className="transition-transform group-open/assets:rotate-90" aria-hidden="true">›</span>
              </summary>
              <div className="space-y-px">
                {nav.assets.map((g) => {
                  const entry = byHref.get(`/assets/${g.id}`)!;
                  return <Row key={g.id} entry={entry} active={isActive(entry)} pinned={pins.includes(entry.href)} onToggle={() => toggle(entry.href)} onNavigate={onNavigate} />;
                })}
              </div>
            </details>
          ) : null}
        </Section>

        <Section title="Çalışma" defaultOpen>
          {tools.work.map((entry) => (
            <Row key={entry.href} entry={entry} active={isActive(entry)} pinned={pins.includes(entry.href)} onToggle={() => toggle(entry.href)} onNavigate={onNavigate} />
          ))}
        </Section>

        <div className="mx-2 mt-4 border-t border-sidebar-border" />
        {nav.sources.map((g) => (
          <Section key={g.id} title={g.title} defaultOpen={g.items.some((i) => pathname === `/docs/${i.id}`)}>
            {g.items.map((item) => {
              const entry = docEntry(item);
              return <Row key={item.id} entry={entry} active={isActive(entry)} pinned={pins.includes(entry.href)} onToggle={() => toggle(entry.href)} onNavigate={onNavigate} />;
            })}
          </Section>
        ))}
      </nav>
      <div className="flex items-center justify-between border-t border-sidebar-border px-4 py-2 text-xs text-sidebar-foreground/70">
        <span>{nav.reviewed} / {nav.total} sayfa gözden geçirildi</span>
        <button
          type="button"
          aria-label="Temayı değiştir"
          onClick={() => setTheme(resolvedTheme === "dark" ? "light" : "dark")}
          className="rounded-sm p-1 hover:bg-sidebar-accent"
        >
          <Sun className="hidden size-4 dark:block" />
          <Moon className="block size-4 dark:hidden" />
        </button>
      </div>
    </div>
  );
}
