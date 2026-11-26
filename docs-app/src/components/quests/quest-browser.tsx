"use client";

// Görevler sayfasının etkileşimli gövdesi: perde başına sayılar, süzgeçler (perde, arama), sekmeler (ana hikâye, yan
// görevler, yoldaş görevleri), perde perde katlanabilir bölümler ve kartlar. Süzgeçler adreste durur (?kind, ?act,
// ?family, ?q) ve sunucuya gitmeden history.replaceState ile yazılır. #kimlik bağı kartı görünür kılar (gerekirse sekmeyi
// değiştirip süzgeci gevşetir), ona kayar ve vurgular; Geri / ileri ile ya da yeniden yüklemeyle dönülünce okuma yeri
// korunur.
import { ChevronDown, Search } from "lucide-react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { type KeyboardEvent, type MouseEvent, memo, type ReactNode, useCallback, useDeferredValue, useEffect, useMemo, useRef, useState } from "react";
import { fold } from "@/lib/text";
import type { ActId, ClientAct, ClientQuest, QuestKind, QuestStatus, QuestView } from "@/lib/quests";
import { QuestCard } from "./quest-card";
import {
  ACT_KEYS,
  ACT_ORDER,
  type ActKey,
  type ActLookup,
  actHeading,
  actKeyOf,
  actLookup,
  capitalizeTr,
  familyKey,
  familyLabel,
  filterHref,
  formatNumber,
  inAct,
  KINDS,
  matchesQuery,
  parseFilter,
  type QuestFilter,
  questActKeys,
  STATUS,
  searchText,
} from "./quest-filter";
import { type QuestNav, QuestNavContext, RichText } from "./rich-text";

type Pending = { id: string; kind: QuestKind; instant: boolean };
type Section = { id: ActId; info: ClientAct | undefined; quests: ClientQuest[] };
// Süzgecin öbeği; inTable: story.md §10.3'ün aile tablosunda satırı var (I. Perde'nin Kışlak öbeğinde yok).
type FamilyRow = { key: string; label: string; total: number; inTable: boolean };

const KIND_NOUN: Record<QuestKind, string> = { main: "ana görev", side: "yan görev", companion: "yoldaş görevi" };
const KIND_GEN: Record<QuestKind, string> = { main: "ana görevin", side: "yan görevin", companion: "yoldaş görevinin" };

// Katlanan perde bölümünün anahtarı: «tür:perde».
const sectionKey = (kind: QuestKind, act: ActId) => `${kind}:${act}`;
const escapeRe = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const actFilterText = (key: ActKey) => (key === "0" ? "Önsöz ve Çocukluk" : `${key}. Perde`);

function currentFilter(): QuestFilter {
  const p = new URLSearchParams(window.location.search);
  return parseFilter((k) => p.get(k));
}

// Adres sunucuya gitmeden yazılır; Next bunu useSearchParams'a yansıtır. Süzgeç değişince eski kart bağı (#) düşer.
function writeUrl(next: QuestFilter, opts: { hash?: string; push?: boolean } = {}) {
  const href = filterHref(next) + (opts.hash ? `#${encodeURIComponent(opts.hash)}` : "");
  if (opts.push) window.history.pushState(null, "", href);
  else window.history.replaceState(null, "", href);
}

const reducedMotion = () => window.matchMedia("(prefers-reduced-motion: reduce)").matches;

// Adresteki #kimlik (çözülmüş); bozuk kodlanmışsa olduğu gibi.
function hashId(): string {
  const raw = window.location.hash.slice(1);
  try {
    return decodeURIComponent(raw);
  } catch {
    return raw;
  }
}

// #kimlik adresten düşer, süzgeç ve arama kalır (Next'in sardığı replaceState; yeni girdi açılmaz).
const dropHash = () => window.history.replaceState(null, "", window.location.pathname + window.location.search);

const inView = (el: HTMLElement) => {
  const r = el.getBoundingClientRect();
  return !el.closest("[hidden]") && r.bottom > 0 && r.top < window.innerHeight;
};

// Bağ yeni sekmede ya da pencerede açılmak isteniyorsa tarayıcıya bırakılır.
const plainClick = (e: MouseEvent) => !e.defaultPrevented && e.button === 0 && !e.metaKey && !e.ctrlKey && !e.shiftKey && !e.altKey;

// Geri / ileri ile dönüş. Sayfa takılı değilken (başka bir sayfadan Geri ile dönülürken) gelen popstate'in adresi
// burada kalır ve sayfa takılınca okunur; sayfa takılıyken gelen popstate'i bileşenin kendi dinleyicisi işler ve siler.
// Modül düzeyindedir: bileşen yokken de dinlemesi gerekir. Dinleyici bileşeninkinden önce eklenir, önce çalışır.
let poppedHref: string | null = null;
if (typeof window !== "undefined") {
  window.addEventListener("popstate", () => {
    poppedHref = window.location.href;
  });
}
let firstMount = true;

// Sayfaya geçmişten mi dönüldü: istemci içi Geri / ileri, belgenin Geri / ileri ile yeniden yüklenmesi ya da yenileme.
// Öyleyse kaydırmayı tarayıcı ve Next geri yükler; adreste kalan #kimlik okuma yerini, odağı ve vurguyu ezmesin diye
// karta kayılmaz. Belgenin yükleniş türü yalnız bu belgedeki ilk açılışta ve adres belgenin adresiyse sayılır.
function cameFromHistory(): boolean {
  const href = window.location.href;
  const popped = poppedHref === href;
  poppedHref = null;
  if (popped) return true;
  if (!firstMount) return false;
  firstMount = false;
  const nav = performance.getEntriesByType("navigation")[0] as PerformanceNavigationTiming | undefined;
  return Boolean(nav && (nav.type === "back_forward" || nav.type === "reload") && nav.name.split("#")[0] === href.split("#")[0]);
}

export function QuestBrowser({ data }: { data: QuestView }) {
  const params = useSearchParams();
  const filter = useMemo(() => parseFilter((k) => params.get(k)), [params]);

  // Arama kutusu yereldir: her harfte adres değişmez, 300 ms sonra yazılır. Adres dışarıdan değişirse (bağ, geri tuşu)
  // kutu ona uyar; lastQ adrese en son yazılan ya da adresten okunan aramadır.
  const [text, setText] = useState(filter.q);
  const lastQ = useRef(filter.q);
  const textRef = useRef(text);
  useEffect(() => {
    textRef.current = text;
  }, [text]);
  useEffect(() => {
    if (filter.q === lastQ.current) return;
    lastQ.current = filter.q;
    setText(filter.q);
  }, [filter.q]);
  useEffect(() => {
    const q = text.trim();
    if (q === lastQ.current) return;
    const timer = window.setTimeout(() => {
      // Bu arada bir bağ ya da süzgeç aramayı adrese yazdıysa yinelenmez: yeni girdinin #kimliği düşmesin.
      if (q === lastQ.current) return;
      lastQ.current = q;
      writeUrl({ ...currentFilter(), q });
    }, 300);
    return () => window.clearTimeout(timer);
  }, [text]);

  const update = useCallback((patch: Partial<QuestFilter>) => {
    const q = patch.q ?? textRef.current.trim();
    lastQ.current = q;
    writeUrl({ ...currentFilter(), ...patch, q });
  }, []);

  const byId = useMemo(() => new Map(data.quests.map((q) => [q.id, q])), [data.quests]);
  const lookup = useMemo(() => actLookup(data.quests), [data.quests]);
  const haystack = useMemo(() => new Map(data.quests.map((q) => [q.id, searchText(q)])), [data.quests]);
  const acts = useMemo(() => new Map(data.acts.map((a) => [a.id, a])), [data.acts]);
  const actIds = useMemo(() => ACT_ORDER.filter((id) => acts.has(id) || data.quests.some((q) => q.act === id)), [acts, data.quests]);
  const actIndex = useMemo(() => new Map(actIds.map((id, i) => [id, i])), [actIds]);

  // Öbekler: önce görevlerde geçip aile tablosunda olmayanlar (perde sırasıyla I'in Kışlak'ı gelir), sonra belgedeki aile
  // tablosunun sırası. Görevi olmayan aile çıkmaz; çiplerin toplamı «Hepsi» ile tutar.
  const families = useMemo(() => {
    const table = new Map<string, FamilyRow>();
    const others = new Map<string, FamilyRow>();
    for (const f of data.families) {
      const key = familyKey(f.name);
      if (key && !table.has(key)) table.set(key, { key, label: familyLabel(f.name), total: 0, inTable: true });
    }
    for (const q of data.quests) {
      if (q.kind !== "side" || !q.family) continue;
      const key = familyKey(q.family);
      const row = table.get(key) ?? others.get(key) ?? { key, label: familyLabel(q.family), total: 0, inTable: false };
      row.total += 1;
      if (!row.inTable) others.set(key, row);
    }
    return [...others.values(), ...table.values()].filter((f) => f.total > 0);
  }, [data.families, data.quests]);
  const familyOrder = useMemo(() => new Map(families.map((f, i) => [f.key, i])), [families]);
  const family = filter.kind === "side" && filter.family && familyOrder.has(filter.family) ? filter.family : null;

  const query = useDeferredValue(text);
  const folded = fold(query.trim());
  const matching = useMemo(
    () => data.quests.filter((q) => inAct(q, filter.act, lookup) && matchesQuery(haystack.get(q.id) ?? "", folded)),
    [data.quests, haystack, filter.act, folded, lookup],
  );
  // Arama hiçbir görevde (perde, sekme ve aile gözetmeden) geçiyor mu: boş sonuç metni buna göre konuşur.
  const anywhere = useMemo(() => !folded || data.quests.some((q) => matchesQuery(haystack.get(q.id) ?? "", folded)), [data.quests, haystack, folded]);
  const counts = useMemo(() => {
    const c: Record<QuestKind, number> = { main: 0, side: 0, companion: 0 };
    for (const q of matching) c[q.kind] += 1;
    return c;
  }, [matching]);
  const familyCounts = useMemo(() => {
    const m = new Map<string, number>();
    for (const q of matching) if (q.kind === "side") m.set(familyKey(q.family), (m.get(familyKey(q.family)) ?? 0) + 1);
    return m;
  }, [matching]);
  const shown = useMemo(
    () => matching.filter((q) => q.kind === filter.kind && (!family || familyKey(q.family) === family)),
    [matching, filter.kind, family],
  );
  const sections = useMemo<Section[]>(() => {
    const byAct = new Map<ActId, ClientQuest[]>();
    for (const q of shown) {
      const list = byAct.get(q.act);
      if (list) list.push(q);
      else byAct.set(q.act, [q]);
    }
    return actIds.filter((id) => byAct.has(id)).map((id) => ({ id, info: acts.get(id), quests: byAct.get(id)! }));
  }, [shown, actIds, acts]);

  const [collapsed, setCollapsed] = useState<ReadonlySet<string>>(() => new Set());
  const toggleSection = (key: string) =>
    setCollapsed((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  const allCollapsed = sections.length > 0 && sections.every((s) => collapsed.has(sectionKey(filter.kind, s.id)));
  const toggleAll = () =>
    setCollapsed((prev) => {
      const next = new Set(prev);
      for (const s of sections) {
        const key = sectionKey(filter.kind, s.id);
        if (allCollapsed) next.delete(key);
        else next.add(key);
      }
      return next;
    });

  // Bağla gelinen kart: görünür kılınır (sekme, perde, aile, arama ve katlanmış bölüm), sonra ona kayılır.
  const [target, setTarget] = useState<{ id: string; n: number } | null>(null);
  const pending = useRef<Pending | null>(null);
  // Karta kayılacağını ve vurgulanacağını işaretler; katlanmış bölümü açar. Adrese dokunmaz.
  const mark = useCallback((quest: ClientQuest, instant: boolean) => {
    setCollapsed((prev) => {
      const key = sectionKey(quest.kind, quest.act);
      if (!prev.has(key)) return prev;
      const copy = new Set(prev);
      copy.delete(key);
      return copy;
    });
    pending.current = { id: quest.id, kind: quest.kind, instant };
    setTarget((prev) => ({ id: quest.id, n: (prev?.n ?? 0) + 1 }));
  }, []);
  const reveal = useCallback(
    (id: string, opts: { push?: boolean; instant?: boolean } = {}) => {
      const quest = byId.get(id);
      if (!quest) return false;
      const cur = currentFilter();
      const typed = textRef.current.trim();
      const keepQuery = !typed || matchesQuery(searchText(quest), fold(typed));
      if (!keepQuery) setText("");
      const next: QuestFilter = {
        kind: quest.kind,
        act: inAct(quest, cur.act, lookup) ? cur.act : null,
        family: cur.family && quest.kind === "side" && familyKey(quest.family) === cur.family ? cur.family : null,
        q: keepQuery ? typed : "",
      };
      lastQ.current = next.q;
      mark(quest, Boolean(opts.instant));
      writeUrl(next, { hash: id, push: opts.push });
      return true;
    },
    [byId, lookup, mark],
  );
  const go = useCallback(
    (id: string, event?: MouseEvent<HTMLAnchorElement>) => {
      if (event && !plainClick(event)) return;
      if (!byId.has(id)) return;
      // Geri tuşu okunan karta dönsün: bağın bulunduğu kart şimdiki girdinin #'ine yazılır (adreste eski bir #kimlik
      // kalmış olabilir), hedef kart yeni girdi olur.
      const from = event?.currentTarget.closest<HTMLElement>(".qst-card")?.id;
      if (from && from !== id && byId.has(from)) writeUrl({ ...currentFilter(), q: textRef.current.trim() }, { hash: from });
      if (reveal(id, { push: true })) event?.preventDefault();
    },
    [byId, reveal],
  );
  const nav = useMemo<QuestNav>(() => ({ byId, go }), [byId, go]);

  // Görünüm oturunca (sekme ve arama yerinde, kart çizilmiş) karta kayılır; hareket azaltılmışsa kaydırma animasyonsuzdur.
  useEffect(() => {
    const p = pending.current;
    if (!p || filter.kind !== p.kind || query !== text) return;
    const el = document.getElementById(p.id);
    if (!el || el.closest("[hidden]")) return;
    pending.current = null;
    el.scrollIntoView({ behavior: p.instant || reducedMotion() ? "auto" : "smooth", block: "start" });
    el.querySelector<HTMLElement>("[data-quest-heading]")?.focus({ preventScroll: true });
  });

  // Adresteki #kimliğin kartı bir kez görünüp sonra görünümden çıkınca (okuyan başka yere kaydırdı, bölümü kapattı) #
  // adresten düşer. Eski bir # adreste kalırsa Geri ile ya da yenilemeyle dönülünce tarayıcı okuma yerini değil o kartı
  // açabilir; #'siz girdide kaydırmayı olduğu gibi geri yükler. Kartın çerçevesi kalır.
  const unwatch = useRef<() => void>(() => {});
  const watch = useCallback((id: string) => {
    unwatch.current();
    unwatch.current = () => {};
    const el = document.getElementById(id);
    if (!el || typeof IntersectionObserver === "undefined") return;
    let seen = false;
    const io = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        seen = true;
        return;
      }
      if (!seen) return;
      io.disconnect();
      if (hashId() === id) dropHash();
    });
    io.observe(el);
    unwatch.current = () => io.disconnect();
  }, []);
  // Sekme değişince kart yeniden çizilir (ya da ilk kez çizilir): gözlem yenilenir.
  useEffect(() => {
    if (target) watch(target.id);
  }, [target, filter.kind, watch]);
  useEffect(() => () => unwatch.current(), []);

  // Adresteki #kimlik. Sayfaya yeni gelinince (bağ, adres çubuğu) ve # elle değişince kart görünür kılınır. Geri /
  // ileri ile ya da yeniden yüklemeyle dönülünce kayılmaz (cameFromHistory): okuma yerini tarayıcı ve Next geri yükler;
  // kart görünmüyorsa eski # düşer, görünüyorsa gözlenir. Açılışta bir tur beklenir: Next history.replaceState'i üst
  // bileşenin etkisinde sarar, alt bileşenin etkisi ondan önce çalışır; sarılmamış çağrı Next'in geçmiş kaydını siler,
  // geri tuşu o girdiyi tanımaz. Açılış yalnız bir kez işlenir (opened); React'in geliştirme kipindeki çift etkisi
  // zamanlayıcıyı siler, karar zamanlayıcı çalışınca verilir.
  const opened = useRef(false);
  useEffect(() => {
    const hashQuest = () => byId.get(hashId()) ?? null;
    // Geçmişten dönüş: kaydırma geri yüklenmiştir. #'in kartı görünüyorsa gözlenir, görünmüyorsa eski # düşer.
    const returned = () => {
      const quest = hashQuest();
      if (!quest) return;
      const el = document.getElementById(quest.id);
      if (el && inView(el)) watch(quest.id);
      else dropHash();
    };
    // Sayfa içinde Geri / ileri: süzgeci Next adresten geri yükler, burada yalnız girdinin kartına kayılır. # da
    // değiştiyse ardından hashchange gelir; o elle değiştirilmiş # değildir, yok sayılır (süzgeç ve arama yeniden
    // yazılmaz). Next'in girdisinde state doludur; elle # değişiminde (yeni girdi) boştur.
    let traversed: string | null = null;
    const onPop = (e: PopStateEvent) => {
      poppedHref = null;
      traversed = e.state ? window.location.href : null;
      const quest = hashQuest();
      if (quest) mark(quest, true);
    };
    const onHash = () => {
      if (traversed === window.location.href) {
        traversed = null;
        return;
      }
      const quest = hashQuest();
      if (quest) reveal(quest.id, { instant: true });
    };
    const timer = opened.current
      ? 0
      : window.setTimeout(() => {
          opened.current = true;
          if (cameFromHistory()) returned();
          else onHash();
        }, 0);
    window.addEventListener("hashchange", onHash);
    window.addEventListener("popstate", onPop);
    return () => {
      window.clearTimeout(timer);
      window.removeEventListener("hashchange", onHash);
      window.removeEventListener("popstate", onPop);
    };
  }, [byId, reveal, mark, watch]);

  const tabRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const searchRef = useRef<HTMLInputElement>(null);
  // Temizleme düğmeleri basılınca kalkar (süzgeç kalmaz ya da sonuç gelir): odak kalıcı bir yere, seçili sekmeye geçer.
  const focusTab = () => tabRefs.current[KINDS.findIndex((k) => k.id === filter.kind)]?.focus();
  const selectKind = (kind: QuestKind) => {
    if (kind !== filter.kind) update({ kind, family: null });
  };
  const onTabKeyDown = (e: KeyboardEvent<HTMLButtonElement>, index: number) => {
    const last = KINDS.length - 1;
    const next = e.key === "ArrowRight" ? (index + 1) % KINDS.length : e.key === "ArrowLeft" ? (index + last) % KINDS.length : e.key === "Home" ? 0 : e.key === "End" ? last : -1;
    if (next < 0) return;
    e.preventDefault();
    tabRefs.current[next]?.focus();
    selectKind(KINDS[next].id);
  };

  // Sayılar tablosundan: o perdenin o türdeki görevleri, aramasız; liste başına kayılır.
  const pick = useCallback(
    (kind: QuestKind, act: ActKey, e: MouseEvent<HTMLAnchorElement>) => {
      if (!plainClick(e)) return;
      e.preventDefault();
      setText("");
      update({ kind, act, family: null, q: "" });
      document.getElementById("quest-tabs")?.scrollIntoView({ behavior: reducedMotion() ? "auto" : "smooth", block: "start" });
      tabRefs.current[KINDS.findIndex((k) => k.id === kind)]?.focus({ preventScroll: true });
    },
    [update],
  );

  const clearAll = () => {
    setText("");
    update({ act: null, family: null, q: "" });
    focusTab();
  };

  if (data.quests.length === 0) {
    return (
      <section className="qst-empty" aria-labelledby="no-quests">
        <h2 id="no-quests">Görev okunamadı</h2>
        <p>Tasarım belgelerinden hiç görev çıkmadı. Belgedeki görev tabloları değiştiyse sayfanın altındaki uyarılara bak.</p>
      </section>
    );
  }

  const typed = text.trim();
  const active = Boolean(filter.act || typed || family);
  const actText = filter.act ? actFilterText(filter.act) : null;
  const familyRow = family ? families.find((f) => f.key === family) : undefined;
  const summary = [
    `${formatNumber(shown.length)} ${KIND_NOUN[filter.kind]}`,
    actText,
    familyRow ? (familyRow.inTable ? `${familyRow.label} ailesi` : familyRow.label) : null,
    typed ? `«${typed}» araması` : null,
  ]
    .filter(Boolean)
    .join(" · ");
  // Başlık düzeyi: perde h2; kol ya da aile başlığının altındaki kart h4, başlıksız gruptaki kart h3.
  const card = (q: ClientQuest, lvl: 3 | 4) => (
    <QuestCard
      key={q.id}
      quest={q}
      level={lvl}
      act={q.kind === "companion" ? filter.act : null}
      target={target?.id === q.id}
      flash={target?.id === q.id ? (target.n % 2 ? "a" : "b") : null}
    />
  );

  return (
    <QuestNavContext.Provider value={nav}>
      <Overview data={data} actIds={actIds} acts={acts} lookup={lookup} onPick={pick} />

      <div className="qst-filters" role="search" aria-label="Görev süzgeçleri">
        <div className="qst-filter-row">
          <span id="act-filter" className="qst-filter-label">
            Perde
          </span>
          <div role="radiogroup" aria-labelledby="act-filter" className="qst-chips">
            <Chip name="act" checked={!filter.act} onSelect={() => update({ act: null })}>
              Hepsi
            </Chip>
            {ACT_KEYS.filter((a) => a.acts.some((id) => actIndex.has(id))).map((a) => (
              <Chip key={a.key} name="act" checked={filter.act === a.key} onSelect={() => update({ act: a.key })} title={a.acts.map((id) => actHeading(acts.get(id) ?? { id, tr: "" })).join(", ")}>
                {a.label}
              </Chip>
            ))}
          </div>
        </div>
        <label className="qst-search">
          <Search aria-hidden="true" />
          <span className="sr-only">Görev ara (kimlik ya da ad)</span>
          <input
            ref={searchRef}
            type="search"
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="Kimlik ya da ad: mq2_hunt, Karga…"
            autoComplete="off"
            spellCheck={false}
            enterKeyHint="search"
          />
        </label>
      </div>

      <div id="quest-tabs" role="tablist" aria-label="Görev türü" className="qst-tablist">
        {KINDS.map((k, i) => {
          const selected = filter.kind === k.id;
          return (
            <button
              key={k.id}
              ref={(el) => {
                tabRefs.current[i] = el;
              }}
              type="button"
              role="tab"
              id={`tab-${k.id}`}
              aria-selected={selected}
              aria-controls="quest-panel"
              tabIndex={selected ? 0 : -1}
              className="qst-tab"
              onClick={() => selectKind(k.id)}
              onKeyDown={(e) => onTabKeyDown(e, i)}
            >
              {k.label}{" "}
              <span className="qst-tab-count">{formatNumber(counts[k.id])}</span>
            </button>
          );
        })}
      </div>

      <div role="tabpanel" id="quest-panel" aria-labelledby={`tab-${filter.kind}`} className="qst-panel">
        {filter.kind === "side" ? (
          <SideTools data={data} families={families} familyCounts={familyCounts} family={family} onFamily={(key) => update({ family: key })} />
        ) : null}
        {filter.kind === "companion" ? (
          <p className="qst-panel-note">
            Her yoldaşın üç adımlık kişisel görevi. Adım <code className="qst-code">ties</code> eşiğiyle (3, 6, 9) ya da takvimin gününde açılır; görev XP vermez.
            Perde süzgeci, adımı o perdede olan görevleri de gösterir.
          </p>
        ) : null}
        {filter.kind === "main" ? (
          <p className="qst-panel-note">
            I. Perde&apos;de her görevin XP&apos;si belgededir, başlık toplamını yazar (<a href="/docs/source/design/act1#6-ana-gorevler">act1.md §6</a>). II–VI&apos;da
            görev başına taban oyun verisinde yazılır; başlık perdenin ana görev bütçesini ve ortalama tabanı yazar: taban × görev ×{" "}
            <code className="qst-code">xpScale</code> (<a href="/docs/source/design/story#10-2-perde-basina-sayilar">story.md §10.2</a>).
          </p>
        ) : null}

        <div className="qst-result-bar">
          <p role="status" aria-live="polite" aria-atomic="true">
            {summary}
          </p>
          <div className="qst-result-actions">
            {active ? (
              <button type="button" className="qst-text-button" onClick={clearAll}>
                Süzgeçleri temizle
              </button>
            ) : null}
            {filter.kind !== "companion" && sections.length > 1 ? (
              <button type="button" className="qst-text-button" onClick={toggleAll}>
                {allCollapsed ? "Bölümlerin hepsini aç" : "Bölümlerin hepsini kapat"}
              </button>
            ) : null}
          </div>
        </div>

        {shown.length === 0 ? (
          <Empty
            kind={filter.kind}
            typed={typed}
            nowhere={Boolean(typed) && !anywhere}
            act={actText}
            family={family ? (familyRow?.label ?? family) : null}
            counts={counts}
            onClearQuery={() => {
              setText("");
              update({ q: "" });
              searchRef.current?.focus();
            }}
            onClearAct={() => {
              update({ act: null });
              focusTab();
            }}
            onClearFamily={() => {
              update({ family: null });
              focusTab();
            }}
            onKind={(kind) => {
              selectKind(kind);
              tabRefs.current[KINDS.findIndex((k) => k.id === kind)]?.focus();
            }}
          />
        ) : filter.kind === "companion" ? (
          <section aria-labelledby="companion-list">
            <h2 id="companion-list" className="sr-only">
              Yoldaş görevleri
            </h2>
            <div className="qst-grid">
              {[...shown].sort((a, b) => (actIndex.get(a.act) ?? 99) - (actIndex.get(b.act) ?? 99)).map((q) => card(q, 3))}
            </div>
          </section>
        ) : (
          sections.map((s) => {
            const key = sectionKey(filter.kind, s.id);
            // XP belgede görev görev yazılıysa (I) gösterilen görevlerin toplamı, en çok değerle; değilse (II–VI) belgenin
            // perde bütçesi ve tabanı. Okunamayan sayı yazılmaz.
            const xp = s.quests.reduce((sum, q) => sum + (q.xpMax ?? q.xp ?? 0), 0);
            const main = filter.kind === "main";
            const meta = [
              `${formatNumber(s.quests.length)} görev`,
              xp ? `${main ? "" : "en çok "}${formatNumber(xp)} XP` : null,
              main && s.info?.xpBudget ? `ana görev bütçesi ${formatNumber(s.info.xpBudget)} XP` : null,
              main && s.info?.baseXp ? `taban ${formatNumber(s.info.baseXp)} XP` : null,
            ]
              .filter(Boolean)
              .join(" · ");
            return (
              <ActSection
                key={key}
                id={`${filter.kind}-${s.id}`}
                info={s.info}
                act={s.id}
                meta={meta}
                full={filter.kind === "main"}
                open={!collapsed.has(key)}
                onToggle={() => toggleSection(key)}
              >
                {filter.kind === "main" ? <MainChain quests={s.quests} render={card} /> : <SideGroups quests={s.quests} order={familyOrder} render={card} />}
              </ActSection>
            );
          })
        )}
      </div>
    </QuestNavContext.Provider>
  );
}

function Chip({ name, checked, onSelect, title, children }: { name: string; checked: boolean; onSelect: () => void; title?: string; children: ReactNode }) {
  return (
    <label className="qst-chip" title={title}>
      <input type="radio" name={name} checked={checked} onChange={onSelect} />
      <span>{children}</span>
    </label>
  );
}

// Perde başına sayılar: süzgeçten bağımsızdır, yalnız veri değişince yeniden çizilir.
const Overview = memo(function Overview({
  data,
  actIds,
  acts,
  lookup,
  onPick,
}: {
  data: QuestView;
  actIds: ActId[];
  acts: ReadonlyMap<ActId, ClientAct>;
  lookup: ActLookup;
  onPick: (kind: QuestKind, act: ActKey, e: MouseEvent<HTMLAnchorElement>) => void;
}) {
  const total: Record<QuestKind, number> = { main: 0, side: 0, companion: 0 };
  const status: Record<QuestStatus, number> = { playable: 0, "in-progress": 0, design: 0 };
  for (const q of data.quests) {
    total[q.kind] += 1;
    status[q.status] = (status[q.status] ?? 0) + 1;
  }
  // Ana ve yan görev kendi perdesinde, yoldaş görevi geçtiği her perdede sayılır (perde süzgeci de böyle süzer).
  const rows = actIds.map((id) => {
    const key = actKeyOf(id);
    const of = (kind: QuestKind) =>
      data.quests.filter((q) => q.kind === kind && (q.act === id || (kind === "companion" && key !== "0" && questActKeys(q, lookup).includes(key)))).length;
    return { id, key, info: acts.get(id), main: of("main"), side: of("side"), companion: of("companion") };
  });
  const cell = (kind: QuestKind, n: number, key: ActKey, label: string) =>
    n ? (
      <a href={filterHref({ kind, act: key })} className="qst-count-link" onClick={(e) => onPick(kind, key, e)} aria-label={`${label}: ${formatNumber(n)} ${KIND_NOUN[kind]}`}>
        {formatNumber(n)}
      </a>
    ) : (
      <span className="qst-zero">
        <span aria-hidden="true">—</span>
        <span className="sr-only">yok</span>
      </span>
    );
  return (
    <section className="qst-overview" aria-labelledby="quest-counts">
      <h2 id="quest-counts" className="sr-only">
        Görev sayıları
      </h2>
      <div className="qst-totals">
        <p>
          <b>{formatNumber(total.main)}</b> ana
        </p>
        <p>
          <b>{formatNumber(total.side)}</b> yan
        </p>
        <p>
          <b>{formatNumber(total.companion)}</b> yoldaş görevi
        </p>
        <p className="qst-status-tally">
          {(Object.keys(STATUS) as QuestStatus[]).map((s, i) => (
            <span key={s}>
              {i ? " · " : null}
              <span aria-hidden="true">{STATUS[s].glyph}</span> {formatNumber(status[s])} {STATUS[s].label.toLocaleLowerCase("tr-TR")}
            </span>
          ))}
        </p>
      </div>
      <table className="qst-counts">
        <caption className="sr-only">Perde başına görev sayıları; sayıya basınca o perdenin görevleri açılır.</caption>
        <thead>
          <tr>
            <th scope="col">Perde</th>
            <th scope="col">Ana</th>
            <th scope="col">Yan</th>
            <th scope="col">Yoldaş</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => {
            const label = actHeading(r.info ?? { id: r.id, tr: "" });
            return (
              <tr key={r.id}>
                <th scope="row">{label}</th>
                <td>{cell("main", r.main, r.key, label)}</td>
                <td>{cell("side", r.side, r.key, label)}</td>
                <td>{cell("companion", r.companion, r.key, label)}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
      <p className="qst-counts-note">Sayıya basınca o perdenin görevleri açılır. Yoldaş görevi, adımı olan her perdede sayılır.</p>
      <p className="qst-counts-note">
        Durum yaklaşıktır: görevin bağlı olduğu{" "}
        <Link href="/roadmap" prefetch={false}>
          Yol Haritası
        </Link>{" "}
        maddesinin başlığından türetilir, madde görevin bütün işini kapsamayabilir.
      </p>
    </section>
  );
});

function ActSection({
  id,
  act,
  info,
  meta,
  full,
  open,
  onToggle,
  children,
}: {
  id: string;
  act: ActId;
  info: ClientAct | undefined;
  meta: string;
  // Ana hikâyede perdenin sorusu, notu, seviyesi ve zincir kalıbı da yazar; öteki sekmelerde yalnız ad ve tarih.
  full: boolean;
  open: boolean;
  onToggle: () => void;
  children: ReactNode;
}) {
  const bodyId = `${id}-list`;
  // Notun sonundaki seviye etiketsizdir («Talim, ıslık buyruğu; Ocak → Oba; 6–8», story.md §1'in «Oyuncu» sütunu):
  // kırpılır ve «seviye 6–8» diye yazılır. Not seviyeyi kendisi adıyla yazıyorsa («…; seviye 1–5») yinelenmez.
  const note = info?.note && info.level ? info.note.replace(new RegExp(`\\s*;\\s*${escapeRe(info.level)}\\s*$`), "") : (info?.note ?? null);
  const level = info?.level && !/\bseviye\b/i.test(note ?? "") ? `seviye ${info.level}` : null;
  // Bütçenin hesabı (story.md §10.2): üç sayı da belgeden okunduysa yazılır.
  const budget = info?.baseXp && info.xpScale && info.xpBudget ? `bütçe ${formatNumber(info.baseXp)} × ${formatNumber(info.mainCount)} × \`xpScale\` ${formatNumber(info.xpScale)}` : null;
  const facts = full ? [note, level, info?.structure ? `ana zincir ${info.structure}` : null, budget].filter(Boolean) : [];
  return (
    <section className="qst-act" aria-labelledby={`${id}-title`}>
      <h2 id={`${id}-title`} className="qst-act-head">
        <button type="button" className="qst-act-toggle" aria-expanded={open} aria-controls={bodyId} onClick={onToggle}>
          <ChevronDown className="qst-act-chevron" aria-hidden="true" />
          <span className="qst-act-title">{actHeading(info ?? { id: act, tr: "" })}</span>{" "}
          <span className="qst-act-meta">{meta}</span>
        </button>
      </h2>
      {info?.en || info?.years ? (
        <p className="qst-act-sub">
          {info.en ? <span lang="en">{info.en}</span> : null}
          {info.en && info.years ? " · " : null}
          {info.years ?? null}
        </p>
      ) : null}
      {full && info?.question ? <p className="qst-act-question">{info.question}</p> : null}
      {facts.length ? (
        <p className="qst-act-sub">
          <RichText text={facts.join(" · ")} />
        </p>
      ) : null}
      <div id={bodyId} hidden={!open} className="qst-act-body">
        {children}
      </div>
    </section>
  );
}

const isFinale = (branch: string | null | undefined) => /^son görev$/i.test(branch?.trim() ?? "");

// Grubun yılları gün sütunundan («12 Şubat 192», «3–4 Haziran 198»): «MÖ 192» ya da «MÖ 176–174».
function yearSpan(quests: ClientQuest[]): string | null {
  const years = quests.flatMap((q) => [...(q.when ?? "").matchAll(/(?:^|\D)(\d{3})(?!\d)/g)].map((m) => m[1]));
  if (!years.length) return null;
  const first = years[0];
  const last = years[years.length - 1];
  return first === last ? `MÖ ${first}` : `MÖ ${first}–${last}`;
}

// Ana zincir: belge sırasıyla dikey; ardışık aynı kol bir bölüm başlığı altında toplanır (açılış, kol, kapanış, son
// görev). I. Perde kol değil gün gün ilerler: başlık günün adıdır (act1.md §1; Gün I · Gösteri … Son Gece, Gün VI · Ses).
// İki durum ayrıca: perdede birden çok son görev varsa (Çocukluk iki bölümdür, ikisi de kendi son göreviyle biter) her biri
// kendi bölümünün adıyla başlık alır (story.md §1); kollar iç içe geçiyorsa (VI'nın kolları yıl dilimlerine bağlıdır, sıra
// takvimindir, aynı kol birden çok kez gelir) başlık grubun yılını da yazar.
function MainChain({ quests, render }: { quests: ClientQuest[]; render: (q: ClientQuest, level: 3 | 4) => ReactNode }) {
  const finales = quests.filter((q) => isFinale(q.branch)).length;
  const groups: { key: string; label: string | null; quests: ClientQuest[] }[] = [];
  for (const q of quests) {
    const own = finales > 1 && isFinale(q.branch);
    const key = own ? `son:${q.id}` : (q.day ?? q.branch ?? "");
    const last = groups.at(-1);
    if (!own && last && last.key === key) {
      last.quests.push(q);
      continue;
    }
    const plain = q.day ? (isFinale(q.branch) ? `${q.day} · son görev` : q.day) : (q.branch ?? null);
    groups.push({ key, label: own ? `${q.chapter || "Bölüm"} · son görev` : plain, quests: [q] });
  }
  const labelled = groups.filter((g) => g.label).map((g) => g.key);
  const interleaved = new Set(labelled).size < labelled.length;
  return (
    <div>
      {interleaved ? (
        <p className="qst-chain-note">Kollar bu perdede iç içe geçer: zincir belgedeki sırayla ilerler, aynı kol birden çok kez gelir; başlık yılı da yazar.</p>
      ) : null}
      {groups.map((g, i) => {
        const years = interleaved && g.label ? yearSpan(g.quests) : null;
        return (
          <div key={`${g.key || "-"}-${i}`} className="qst-branch">
            {g.label ? (
              <h3 className="qst-branch-title">
                {capitalizeTr(g.label)}
                {years ? ` · ${years}` : null}
              </h3>
            ) : null}
            <ol className="qst-chain-list">
              {g.quests.map((q) => (
                <li key={q.id} className="qst-chain-item" data-status={q.status}>
                  {render(q, g.label ? 4 : 3)}
                </li>
              ))}
            </ol>
          </div>
        );
      })}
    </div>
  );
}

// Yan görevler aileye göre; ailesi yazılmamış olanlar (act1.md §7'nin öbek cümlesi okunamazsa I'in görevleri) en sonda.
function SideGroups({ quests, order, render }: { quests: ClientQuest[]; order: ReadonlyMap<string, number>; render: (q: ClientQuest, level: 3 | 4) => ReactNode }) {
  const groups = new Map<string, { label: string; quests: ClientQuest[] }>();
  for (const q of quests) {
    const key = familyKey(q.family);
    const g = groups.get(key) ?? { label: q.family ? familyLabel(q.family) : "", quests: [] };
    g.quests.push(q);
    groups.set(key, g);
  }
  const sorted = [...groups.entries()].sort(([a], [b]) => (a ? (order.get(a) ?? 98) : 99) - (b ? (order.get(b) ?? 98) : 99));
  const titled = sorted.some(([key]) => key);
  return (
    <>
      {sorted.map(([key, g]) => (
        <div key={key || "-"} className="qst-family">
          {key ? (
            <h3 className="qst-family-title">
              {g.label} <span>· {formatNumber(g.quests.length)}</span>
            </h3>
          ) : titled ? (
            <h3 className="qst-family-title">
              Ailesi yazılmamış <span>· {formatNumber(g.quests.length)}</span>
            </h3>
          ) : null}
          <div className="qst-grid">{g.quests.map((q) => render(q, key || titled ? 4 : 3))}</div>
        </div>
      ))}
    </>
  );
}

function SideTools({
  data,
  families,
  familyCounts,
  family,
  onFamily,
}: {
  data: QuestView;
  families: { key: string; label: string }[];
  familyCounts: ReadonlyMap<string, number>;
  family: string | null;
  onFamily: (key: string | null) => void;
}) {
  const all = [...familyCounts.values()].reduce((a, b) => a + b, 0);
  // I. Perde'nin öbeği aile değildir, bağlı oldukları yerdir (act1.md §7).
  const actOne = data.quests.filter((q) => q.kind === "side" && q.act === "I" && q.family);
  return (
    <div className="qst-side-tools">
      {families.length ? (
        <div className="qst-filter-row">
          <span id="family-filter" className="qst-filter-label">
            Aile
          </span>
          <div role="radiogroup" aria-labelledby="family-filter" className="qst-chips">
            <Chip name="family" checked={!family} onSelect={() => onFamily(null)}>
              Hepsi <span className="qst-chip-count">{formatNumber(all)}</span>
            </Chip>
            {families.map((f) => (
              <Chip key={f.key} name="family" checked={family === f.key} onSelect={() => onFamily(f.key)}>
                {f.label} <span className="qst-chip-count">{formatNumber(familyCounts.get(f.key) ?? 0)}</span>
              </Chip>
            ))}
          </div>
        </div>
      ) : null}
      {actOne.length ? (
        <p className="qst-side-note">
          «{familyLabel(actOne[0].family ?? "")}» bir aile değil, yerdir: I. Perde&apos;nin {formatNumber(actOne.length)} yan görevi aileye ayrılmaz, hepsi bu yere bağlıdır; Göz
          Yolu başlayınca (Gün V) açık kalanlar kapanır (K42; <a href="/docs/source/design/act1#7-yan-gorevler">act1.md §7</a>). Aileler II. Perde&apos;de başlar.
        </p>
      ) : null}
      {data.families.length ? (
        <details className="qst-families">
          <summary>
            Yan görev aileleri <span className="qst-chip-count">· {formatNumber(data.families.length)}</span>
          </summary>
          <table>
            <thead>
              <tr>
                <th scope="col">Aile</th>
                <th scope="col">Sistem</th>
                <th scope="col">Tetik</th>
                <th scope="col">Ödül</th>
                <th scope="col">Etkin perdeler</th>
              </tr>
            </thead>
            <tbody>
              {data.families.map((f) => (
                <tr key={f.name}>
                  <th scope="row">
                    {f.name}
                    {f.en ? (
                      <span lang="en" className="qst-family-en">
                        {" "}
                        {f.en}
                      </span>
                    ) : null}
                  </th>
                  <td data-label="Sistem">{f.system ? <RichText text={f.system} /> : "—"}</td>
                  <td data-label="Tetik">{f.trigger ? <RichText text={f.trigger} /> : "—"}</td>
                  <td data-label="Ödül">{f.reward ? <RichText text={f.reward} xp /> : "—"}</td>
                  <td data-label="Etkin perdeler">{f.acts ?? "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </details>
      ) : null}
    </div>
  );
}

// Boş sonuç: metin yalnız doğru olanı söyler. Arama başka sekmede ya da perdede geçiyorsa «bu süzgeçlerle» der;
// hiçbir görevde geçmiyorsa onu söyler ve süzgeç gevşetmeyi önermez. «Öteki sekmelere bak» yalnız oralarda sonuç
// varken, «süzgeci gevşet» yalnız perde ya da aile süzgeci açıkken çıkar.
function Empty({
  kind,
  typed,
  nowhere,
  act,
  family,
  counts,
  onClearQuery,
  onClearAct,
  onClearFamily,
  onKind,
}: {
  kind: QuestKind;
  typed: string;
  // Arama hiçbir görevin kimliğinde ya da adında geçmiyor (perde, sekme ve aile gözetmeden).
  nowhere: boolean;
  act: string | null;
  family: string | null;
  counts: Record<QuestKind, number>;
  onClearQuery: () => void;
  onClearAct: () => void;
  onClearFamily: () => void;
  onKind: (kind: QuestKind) => void;
}) {
  const narrowed = Boolean(act || family);
  const filtered = Boolean(typed) || narrowed;
  const elsewhere = KINDS.filter((k) => k.id !== kind && counts[k.id] > 0);
  const relax = narrowed && !nowhere;
  const advice =
    relax && elsewhere.length ? "Süzgeci gevşet ya da öteki sekmelere bak." : relax ? "Süzgeci gevşet." : elsewhere.length ? "Öteki sekmelerde sonuç var." : null;
  return (
    <section className="qst-empty" aria-labelledby="empty-result">
      <h2 id="empty-result">{filtered ? `Bu süzgeçte ${KIND_NOUN[kind]} yok` : `Bu sekmede henüz ${KIND_NOUN[kind]} yok`}</h2>
      {filtered ? (
        <p>
          {typed && nowhere ? (
            <>
              «{typed}» hiçbir görevin kimliğinde ya da adında geçmiyor; arama yalnız ikisine bakar (ör. <code className="qst-code">mq2_hunt</code>, Karga).{" "}
            </>
          ) : typed ? (
            <>
              {narrowed ? "Bu süzgeçlerle" : "Bu sekmede"} «{typed}» hiçbir {KIND_GEN[kind]} kimliğinde ya da adında geçmiyor.{" "}
            </>
          ) : null}
          {act ? <>Perde süzgeci açık: {act}. </> : null}
          {family ? <>Aile süzgeci açık: {family}. </> : null}
          {advice}
        </p>
      ) : (
        <p>Görevler tasarım belgelerinden okunur; bu türde satır bulunamadı. Sayfanın altındaki uyarılar nedenini söyleyebilir.</p>
      )}
      <div className="qst-empty-actions">
        {typed ? (
          <button type="button" className="qst-action-button" onClick={onClearQuery}>
            Aramayı temizle
          </button>
        ) : null}
        {act && relax ? (
          <button type="button" className="qst-action-button" onClick={onClearAct}>
            Bütün perdeler
          </button>
        ) : null}
        {family && relax ? (
          <button type="button" className="qst-action-button" onClick={onClearFamily}>
            Bütün aileler
          </button>
        ) : null}
        {elsewhere.map((k) => (
          <button key={k.id} type="button" className="qst-action-button" onClick={() => onKind(k.id)}>
            {k.label}: {formatNumber(counts[k.id])} sonuç
          </button>
        ))}
      </div>
    </section>
  );
}
