"use client";

// Klip listesi: arama, öbek süzgeci, en üstte kişiye özel kısa liste («Sahnede oynar», «Bu kişinin çeşitleri»; oyuncu karakterinde
// yok), altında öbek öbek bütün klipler. İkisi ayrı liste kutusudur: bir klip ikisinde de durabilir, her kutuda tek seçenek seçilidir,
// bütün klipler kutusunun sayısı klip sayısıdır. Süzgeç ve arama adrestedir (?group=…&q=…; AnimationStudio yazar): bağı paylaşan aynı
// listeyi görür, geri tuşu ve kenar çubuğundaki bağ da listeyi doğru kurar. Yazarken liste hemen süzülür, adres kısa bir bekleyişle
// yazılır (Safari saniyede çok replaceState'i reddeder).
// Klavye karakter seçicideki gibidir: Sekme listeye seçili klipten girer, ↑ ↓ ← → iki kutunun klipleri arasında gezer, Home / End ilk
// ve son klip, Enter ya da Boşluk seçer; 120 düğmede Sekme ile yürümek gerekmez. Yan yana düzende liste kendi içinde kayar; seçili klip
// görünmüyorsa (bağdan gelinmişse) görünür yere gelir.
import { Search, X } from "lucide-react";
import Link from "next/link";
import { Fragment, type KeyboardEvent, useEffect, useId, useMemo, useRef, useState } from "react";
import { matchesTokens, normalizeQuery, QUERY_MAX, queryTokens, sceneLabel, searchText } from "@/components/animations/clip-text";
import { CountBadge } from "@/components/animations/count-badge";
import type { AnimCharacter, AnimClip, AnimClipGroup } from "@/lib/animations";
import { cn } from "@/lib/utils";

// Yazmayı bitirince adres bu kadar sonra yazılır (milisaniye).
const WRITE_DELAY = 250;

const K91_HREF = "/docs/source/design/decisions#k91";

interface Row {
  // Listedeki yeri: aynı klip sahnede, çeşitlerde ve öbeğinde görünebilir.
  id: string;
  clip: AnimClip;
}

// Kısa listenin bir satır öbeği: başlığı (sahne ya da öbek adı) ve klipleri.
interface RowGroup {
  key: string;
  label: string;
  // Ekran okuyucunun satırın adına eklediği yer.
  place: string;
  rows: Row[];
}

export function ClipBrowser({
  character,
  clips,
  groups,
  clipKey,
  group,
  query,
  onClip,
  onGroup,
  onQuery,
}: {
  character: AnimCharacter;
  clips: AnimClip[];
  groups: AnimClipGroup[];
  clipKey: string;
  group: string | null;
  query: string;
  onClip: (key: string) => void;
  onGroup: (group: string | null) => void;
  onQuery: (query: string) => void;
}) {
  const titleId = useId();
  const hintId = useId();
  const labelId = useId();
  const list = useRef<HTMLDivElement>(null);
  const nodes = useRef(new Map<string, HTMLDivElement>());
  const input = useRef<HTMLInputElement>(null);
  const [draft, setDraft] = useState(query);
  const [announced, setAnnounced] = useState("");
  // Adrese en son bizim yazdığımız arama: adres başka bir yoldan değişirse (geri tuşu, kenar çubuğu) kutu ona uyar.
  const written = useRef(query);
  const [focusId, setFocusId] = useState<string | null>(null);

  useEffect(() => {
    if (query !== written.current) {
      written.current = query;
      setDraft(query);
    }
  }, [query]);

  // Arama metinleri bir kez kurulur: klip ve öbek listesi sayfa boyunca değişmez.
  const index = useMemo(() => {
    const groupName = new Map(groups.map((g) => [g.key, g.tr]));
    return new Map(clips.map((c) => [c.key, searchText(c, groupName.get(c.group) ?? "")]));
  }, [clips, groups]);

  const typed = normalizeQuery(draft);
  const tokens = useMemo(() => queryTokens(typed), [typed]);
  const held = useMemo(() => new Set(character.clips.map((c) => c.key)), [character.clips]);
  const matched = useMemo(() => clips.filter((c) => held.has(c.key) && matchesTokens(index.get(c.key) ?? "", tokens)), [clips, held, index, tokens]);
  const visible = useMemo(() => (group ? matched.filter((c) => c.group === group) : matched), [matched, group]);
  const visibleKeys = useMemo(() => new Set(visible.map((c) => c.key)), [visible]);
  const byKey = useMemo(() => new Map(clips.map((c) => [c.key, c])), [clips]);
  const searching = tokens.length > 0;

  const totals = new Map<string, number>();
  for (const c of matched) totals.set(c.group, (totals.get(c.group) ?? 0) + 1);

  // Sahnelerin bu kişiye oynattığı klipler, süzgece uyanlar.
  const scenes = Object.entries(character.scenePicks).flatMap(([scene, picks]): RowGroup[] => {
    const rows = groups.flatMap((g): Row[] => (visibleKeys.has(picks[g.key]) ? [{ id: `s:${scene}:${picks[g.key]}`, clip: byKey.get(picks[g.key]) as AnimClip }] : []));
    return rows.length ? [{ key: scene, label: sceneLabel(scene), place: sceneLabel(scene), rows }] : [];
  });
  // Kişinin sahnesiz çeşitleri: öbek sırasıyla, süzgece uyanlar. Ara hareketler aynı satırda birden çok klip olabilir. Bugün rolü olan
  // öbekler önce, sahnesi olmayanlar ayrı.
  const variants = (live: boolean) =>
    groups.flatMap((g): RowGroup[] => {
      if (g.live !== live) return [];
      const value = character.assigned[g.key];
      const keys = (Array.isArray(value) ? value : value ? [value] : []).filter((k) => visibleKeys.has(k));
      return keys.length ? [{ key: g.key, label: g.tr, place: g.tr, rows: keys.map((k): Row => ({ id: `v:${k}`, clip: byKey.get(k) as AnimClip })) }] : [];
    });
  const liveVariants = variants(true);
  const laterVariants = variants(false);
  const shortRows = [...scenes, ...liveVariants, ...laterVariants].flatMap((g) => g.rows);
  const sections = groups.flatMap((g) => {
    const rows = visible.filter((c) => c.group === g.key).map((c): Row => ({ id: `g:${c.key}`, clip: c }));
    return rows.length ? [{ group: g, rows }] : [];
  });
  const allRows = [...shortRows, ...sections.flatMap((s) => s.rows)];
  const order = allRows.map((r) => r.id);
  const keyOfRow = new Map(allRows.map((r) => [r.id, r.clip.key]));
  const selectedRow = order.find((id) => keyOfRow.get(id) === clipKey);
  const selectedRows = new Set([shortRows.find((r) => r.clip.key === clipKey)?.id, `g:${clipKey}`]);
  const tabStop = focusId && order.includes(focusId) ? focusId : (selectedRow ?? order[0]);
  const assignedKeys = useMemo(() => new Set(Object.values(character.assigned).flat()), [character.assigned]);
  const sceneKeys = useMemo(() => new Set(Object.values(character.scenePicks).flatMap((row) => Object.values(row))), [character.scenePicks]);
  const ownKeys = useMemo(() => new Set(character.clips.filter((c) => c.gameRole).map((c) => c.key)), [character.clips]);
  const isPlayer = character.group === "player";

  // Adres ve ekran okuyucu duyurusu yazma bitince güncellenir; süzgeç değişince de sonuç sayısı söylenir.
  const count = visible.length;
  useEffect(() => {
    const timer = window.setTimeout(() => {
      if (typed !== query) {
        written.current = typed;
        onQuery(typed);
      }
      const filtered = searching || group !== null;
      setAnnounced(filtered ? (count ? `${count.toLocaleString("tr-TR")} klip gösteriliyor` : "Bu süzgeçle klip yok") : "");
    }, WRITE_DELAY);
    return () => window.clearTimeout(timer);
  }, [typed, query, onQuery, count, searching, group]);

  // Süzgeç değişince liste başa döner (telefonda liste kaymaz, bunun etkisi olmaz).
  useEffect(() => {
    list.current?.scrollTo(0, 0);
  }, [group, typed]);

  // Yan yana düzende liste kendi içinde kayar: seçili klibin bir kopyası bile görünüyorsa dokunulmaz, görünmüyorsa görünür yere
  // gelir. Telefonda liste sayfayla birlikte kayar, burada bir şey yapılmaz. Seçim, kişi ya da süzgeç değişince bakılır.
  useEffect(() => {
    const box = list.current;
    if (!box || box.scrollHeight <= box.clientHeight + 1) return;
    const shown = box.getBoundingClientRect();
    const copies = order.filter((id) => keyOfRow.get(id) === clipKey).flatMap((id) => nodes.current.get(id) ?? []);
    if (!copies.length) return;
    const inView = copies.some((n) => {
      const r = n.getBoundingClientRect();
      return r.top >= shown.top && r.bottom <= shown.bottom;
    });
    if (inView) return;
    const r = copies[copies.length - 1].getBoundingClientRect();
    box.scrollTop += r.top - shown.top - (shown.height - r.height) / 2;
  }, [clipKey, group, character.id, typed]);

  const focusRow = (id: string | undefined) => {
    if (!id) return;
    setFocusId(id);
    nodes.current.get(id)?.focus();
  };

  const onKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    const current = (event.target as HTMLElement).closest<HTMLElement>("[data-row]")?.dataset.row;
    const at = current ? order.indexOf(current) : -1;
    switch (event.key) {
      case "ArrowDown":
      case "ArrowRight":
        focusRow(order[Math.min(order.length - 1, at + 1)]);
        break;
      case "ArrowUp":
      case "ArrowLeft":
        focusRow(order[Math.max(0, at - 1)]);
        break;
      case "Home":
        focusRow(order[0]);
        break;
      case "End":
        focusRow(order[order.length - 1]);
        break;
      case "Enter":
      case " ": {
        const key = current ? keyOfRow.get(current) : undefined;
        if (key) onClip(key);
        break;
      }
      default:
        return;
    }
    event.preventDefault();
  };

  const clear = () => {
    setDraft("");
    written.current = "";
    onQuery("");
    input.current?.focus();
  };

  const rowProps = (row: Row) => ({
    ref: (el: HTMLDivElement | null) => {
      if (el) nodes.current.set(row.id, el);
      else nodes.current.delete(row.id);
    },
    role: "option",
    "data-row": row.id,
    "aria-selected": selectedRows.has(row.id),
    tabIndex: row.id === tabStop ? 0 : -1,
    onClick: () => {
      setFocusId(row.id);
      onClip(row.clip.key);
    },
  });

  // Kısa listenin satırı. Aynı klibin öteki kopyaları da seçili görünür; her liste kutusunda yalnız ilk kopya seçili sayılır.
  const shortRow = (row: Row, place: string) => (
    <div key={row.id} {...rowProps(row)} className={cn("anim-option", row.clip.key === clipKey && "is-active")}>
      <span className="anim-option-name">{row.clip.tr}</span>
      <span className="sr-only">, {place}</span>
    </div>
  );

  return (
    <section className="anim-browser" aria-labelledby={titleId}>
      <div className="anim-browser-inner">
        <div className="anim-browser-head">
          <h3 id={titleId} className="anim-browser-title">
            Klipler{" "}
            <span>
              · {searching || group ? `${count.toLocaleString("tr-TR")} / ` : ""}
              {character.clips.length.toLocaleString("tr-TR")}
            </span>
          </h3>
          <div className="anim-search">
            <Search className="size-4 shrink-0" aria-hidden="true" />
            <input
              ref={input}
              type="text"
              role="searchbox"
              aria-label="Klip ara"
              inputMode="search"
              enterKeyHint="search"
              autoComplete="off"
              spellCheck={false}
              placeholder="Ara: ad, etiket, anahtar"
              maxLength={QUERY_MAX}
              value={draft}
              onChange={(e) => setDraft(e.currentTarget.value)}
              onKeyDown={(e) => {
                if (e.key === "Escape" && draft) {
                  e.preventDefault();
                  clear();
                } else if (e.key === "ArrowDown" && order.length) {
                  // Aşağı ok listeye iner: sonuçlara Sekme ile süzgeçlerin üstünden geçmeden varılır.
                  e.preventDefault();
                  focusRow(tabStop);
                }
              }}
            />
            {draft ? (
              <button type="button" className="anim-search-clear" onClick={clear} aria-label="Aramayı temizle">
                <X className="size-3.5" aria-hidden="true" />
              </button>
            ) : null}
          </div>
          <div className="anim-filters" role="group" aria-label="Klip grubu">
            <button type="button" aria-pressed={group === null} onClick={() => onGroup(null)} className={cn("anim-filter", group === null && "is-active")}>
              Hepsi <CountBadge count={matched.length} rich={false} word={searching ? "sonuç" : "klip"} />
            </button>
            {groups.map((g) => {
              const shown = searching ? (totals.get(g.key) ?? 0) : g.count;
              return (
                <button
                  key={g.key}
                  type="button"
                  aria-pressed={group === g.key}
                  onClick={() => onGroup(group === g.key ? null : g.key)}
                  className={cn("anim-filter", group === g.key && "is-active", searching && !shown && "is-empty")}
                >
                  {g.tr} <CountBadge count={shown} rich={searching ? false : undefined} word={searching ? "sonuç" : undefined} />
                </button>
              );
            })}
          </div>
          <p className="anim-legend">
            <span className="anim-count is-rich" aria-hidden="true">
              10+
            </span>{" "}
            on ve üzeri çeşit
            {sceneKeys.size ? (
              <>
                {" "}
                · <span className="anim-mark is-scene" aria-hidden="true" /> sahnede oynar
              </>
            ) : null}
            {assignedKeys.size ? (
              <>
                {" "}
                · <span className="anim-mark is-assigned" aria-hidden="true" /> bu kişiye atanmış
              </>
            ) : null}{" "}
            · <span className="anim-mark is-own" aria-hidden="true" /> {isPlayer ? "oyunda bunu oynar" : "modelin kendi rol klibi"}
          </p>
        </div>
        <p className="sr-only" role="status">
          {announced}
        </p>
        <p id={hintId} className="sr-only">
          Ok tuşlarıyla klipler arasında gez, Enter ya da Boşluk ile seç.
        </p>
        {order.length ? (
          <div ref={list} onKeyDown={onKeyDown} className="anim-browser-list">
            <p className="anim-list-note">
              {isPlayer ? (
                <>
                  Oyuncu karakteri çeşit almaz, kendi kliplerini oynar (
                  <Link href={K91_HREF} prefetch={false}>
                    K91
                  </Link>
                  ).
                </>
              ) : (
                <>
                  Önce sahnenin seçimi oynar; seçim yoksa kişinin varsayılan çeşidi (
                  <Link href={K91_HREF} prefetch={false}>
                    K91
                  </Link>
                  ).
                </>
              )}
            </p>
            {shortRows.length ? (
              <div role="listbox" aria-label={`${character.name}: sahnede oynayanlar ve çeşitler`} aria-describedby={hintId} className="anim-listbox">
                {scenes.length ? (
                  <div role="group" aria-labelledby={`${labelId}-scenes`} className="anim-list-group is-scene">
                    <div role="presentation" id={`${labelId}-scenes`} className="anim-list-label">
                      Sahnede oynar
                    </div>
                    {scenes.map((g) => (
                      <Fragment key={g.key}>
                        <div role="presentation" className="anim-variant-group">
                          {g.label}
                        </div>
                        {g.rows.map((row) => shortRow(row, g.place))}
                      </Fragment>
                    ))}
                  </div>
                ) : null}
                {liveVariants.length || laterVariants.length ? (
                  <div role="group" aria-labelledby={`${labelId}-assigned`} className="anim-list-group is-assigned">
                    <div role="presentation" id={`${labelId}-assigned`} className="anim-list-label">
                      Bu kişinin çeşitleri
                    </div>
                    <div role="presentation" className="anim-variant-hint">
                      Sahnesiz varsayılan atama; sahne kendi seçimini yazabilir.
                    </div>
                    {liveVariants.length ? (
                      <div role="presentation" className="anim-variant-tier">
                        Oyunda rolü olanlar
                      </div>
                    ) : null}
                    {liveVariants.map((g) => (
                      <Fragment key={g.key}>
                        <div role="presentation" className="anim-variant-group">
                          {g.label}
                        </div>
                        {g.rows.map((row) => shortRow(row, g.place))}
                      </Fragment>
                    ))}
                    {laterVariants.length ? (
                      <div role="presentation" className="anim-variant-later">
                        <div role="presentation" className="anim-variant-tier">
                          Henüz sahnesi yok
                        </div>
                        {laterVariants.map((g) => (
                          <Fragment key={g.key}>
                            <div role="presentation" className="anim-variant-group">
                              {g.label}
                            </div>
                            {g.rows.map((row) => shortRow(row, `${g.place}, sahnesi yok`))}
                          </Fragment>
                        ))}
                      </div>
                    ) : null}
                  </div>
                ) : null}
              </div>
            ) : null}
            <div role="listbox" aria-label="Bütün klipler" aria-describedby={hintId} className="anim-listbox">
              {sections.map((s) => (
                <div key={s.group.key} role="group" aria-labelledby={`${labelId}-${s.group.key}`} className="anim-list-group">
                  <div role="presentation" id={`${labelId}-${s.group.key}`} className="anim-list-label">
                    {s.group.tr} <CountBadge count={searching ? s.rows.length : s.group.count} rich={searching ? false : undefined} word={searching ? "sonuç" : undefined} />
                  </div>
                  {s.rows.map((row) => (
                    <div key={row.id} {...rowProps(row)} className={cn("anim-option", row.clip.key === clipKey && "is-active")}>
                      <span className="anim-option-name">{row.clip.tr}</span>
                      {sceneKeys.has(row.clip.key) ? (
                        <span className="anim-mark is-scene" title="Sahnede oynar">
                          <span className="sr-only">, sahnede oynar</span>
                        </span>
                      ) : null}
                      {assignedKeys.has(row.clip.key) ? (
                        <span className="anim-mark is-assigned" title="Bu kişiye atanmış">
                          <span className="sr-only">, bu kişiye atanmış</span>
                        </span>
                      ) : null}
                      {ownKeys.has(row.clip.key) ? (
                        <span className="anim-mark is-own" title={isPlayer ? "Oyunda bunu oynar" : "Modelin kendi rol klibi"}>
                          <span className="sr-only">, {isPlayer ? "oyunda bunu oynar" : "modelin kendi rol klibi"}</span>
                        </span>
                      ) : null}
                    </div>
                  ))}
                </div>
              ))}
            </div>
          </div>
        ) : (
          <div className="anim-browser-empty">
            <p>Bu süzgeçle klip yok.</p>
            <button
              type="button"
              className="anim-chip"
              onClick={() => {
                setDraft("");
                written.current = "";
                onQuery("");
                onGroup(null);
              }}
            >
              Süzgeci temizle
            </button>
          </div>
        )}
      </div>
    </section>
  );
}
