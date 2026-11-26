"use client";

// Karakter seçici: gruplu liste kutusu (oynanabilir, kişiler, kalabalık). Kartın görseli varlığın küçük görselidir.
// Klavye: ↑ ↓ ← → kartlar arasında gezer, Home / End ilk ve son kart, Enter ya da Boşluk seçer. Seçim odakla değişmez:
// her seçim bir GLB yükler, oklarla gezerken boşuna yükleme olmasın. Kuyruktaki (henüz modeli olmayan) kişiler soluk
// ve seçilemez, ok tuşları onları atlar. Kartta gerekçenin kısa etiketi görünür (tamamı ekran okuyucuya); tam gerekçeler
// listenin altındaki açılır listede herkese (dokunmatik, klavye) açıktır.
import { type KeyboardEvent, useId, useRef, useState } from "react";
import type { AnimCharacter, AnimGroup, AnimPending } from "@/lib/animations";
import { cn } from "@/lib/utils";

const GROUPS: { id: AnimGroup; label: string }[] = [
  { id: "player", label: "Oynanabilir" },
  { id: "named", label: "Kişiler" },
  { id: "crowd", label: "Kalabalık" },
];

const height = (m: number | null) => (m ? `${m.toLocaleString("tr-TR", { maximumFractionDigits: 2 })} m` : null);

interface Card {
  id: string;
  name: string;
  image: string | null;
  meta: string;
  ready: boolean;
  label: string | null;
  reason: string | null;
}

function Poster({ url, name }: { url: string | null; name: string }) {
  return url ? (
    // Yerel küçük görsel (320 piksel): next/image gerekmez.
    <img src={url} alt="" loading="lazy" decoding="async" className="anim-card-img" />
  ) : (
    <span className="anim-card-img is-empty" aria-hidden="true">
      {name.slice(0, 1)}
    </span>
  );
}

export function CharacterPicker({
  characters,
  pending,
  selectedId,
  onSelect,
}: {
  characters: AnimCharacter[];
  pending: AnimPending[];
  selectedId: string;
  onSelect: (id: string) => void;
}) {
  const hintId = useId();
  const groupId = useId();
  const nodes = useRef(new Map<string, HTMLDivElement>());
  // Sekmeyle girilen kart: seçili olan; oklarla gezilince odaktaki.
  const [focusId, setFocusId] = useState(selectedId);
  // Seçim dışarıdan değişirse (adres, geri tuşu) sekme durağı yeni seçime geçer.
  const [seenSelected, setSeenSelected] = useState(selectedId);
  if (seenSelected !== selectedId) {
    setSeenSelected(selectedId);
    setFocusId(selectedId);
  }

  const groups = GROUPS.map((g) => ({
    ...g,
    cards: [
      ...characters
        .filter((c) => c.group === g.id)
        .map<Card>((c) => ({
          id: c.id,
          name: c.name,
          image: c.image,
          meta: [c.bodyLabel, height(c.heightM)].filter(Boolean).join(" · "),
          ready: c.ready,
          label: c.ready ? null : (c.statusLabel ?? "Hazır değil"),
          reason: c.ready ? null : (c.statusLabel ?? "Hazır değil"),
        })),
      ...pending
        .filter((p) => p.group === g.id)
        .map<Card>((p) => ({ id: p.id, name: p.name, image: p.image, meta: "", ready: false, label: p.tag, reason: p.reason })),
    ],
  })).filter((g) => g.cards.length > 0);

  const order = groups.flatMap((g) => g.cards.filter((c) => c.ready).map((c) => c.id));
  const tabStop = order.includes(focusId) ? focusId : order.includes(selectedId) ? selectedId : order[0];

  // Hazır olmayanların tam gerekçesi, kartlardaki sırayla; aynı gerekçeyi taşıyanlar tek satırda.
  const waiting = groups.flatMap((g) => g.cards).filter((c) => !c.ready);
  const reasons = new Map<string, string[]>();
  for (const c of waiting) {
    const reason = c.reason ?? c.label ?? "Hazır değil";
    reasons.set(reason, [...(reasons.get(reason) ?? []), c.name]);
  }

  const focusCard = (id: string | undefined) => {
    if (!id) return;
    setFocusId(id);
    nodes.current.get(id)?.focus();
  };

  const onKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    const current = (event.target as HTMLElement).closest<HTMLElement>("[data-card]")?.dataset.card;
    const at = current ? order.indexOf(current) : -1;
    switch (event.key) {
      case "ArrowDown":
      case "ArrowRight":
        focusCard(order[Math.min(order.length - 1, at + 1)]);
        break;
      case "ArrowUp":
      case "ArrowLeft":
        focusCard(order[Math.max(0, at - 1)]);
        break;
      case "Home":
        focusCard(order[0]);
        break;
      case "End":
        focusCard(order[order.length - 1]);
        break;
      case "Enter":
      case " ":
        if (current && order.includes(current)) onSelect(current);
        break;
      default:
        return;
    }
    event.preventDefault();
  };

  return (
    <div className="anim-picker">
      <p id={hintId} className="sr-only">
        Ok tuşlarıyla karakterler arasında gez, Enter ya da Boşluk ile seç.
      </p>
      <div role="listbox" aria-label="Karakter" aria-describedby={hintId} onKeyDown={onKeyDown} className="anim-picker-list">
        {groups.map((g) => (
          <div key={g.id} role="group" aria-labelledby={`${groupId}-${g.id}`} className="anim-group">
            <div role="presentation" id={`${groupId}-${g.id}`} className="anim-group-label">
              {g.label}
            </div>
            {g.cards.map((c) => {
              const selected = c.ready && c.id === selectedId;
              // Etiket gerekçenin kısaltmasıysa ekran okuyucu etiket yerine gerekçenin tamamını okur. Fare ipucu (title)
              // gizli etikettedir: kartın kendisinde olsaydı açıklama olarak okunur, gerekçe iki kez duyulurdu.
              const fullReason = c.reason && c.reason !== c.label ? c.reason : null;
              return (
                <div
                  key={c.id}
                  ref={(el) => {
                    if (el) nodes.current.set(c.id, el);
                    else nodes.current.delete(c.id);
                  }}
                  role="option"
                  data-card={c.id}
                  aria-selected={selected}
                  aria-disabled={c.ready ? undefined : true}
                  tabIndex={c.ready && c.id === tabStop ? 0 : -1}
                  onClick={() => {
                    if (!c.ready) return;
                    setFocusId(c.id);
                    onSelect(c.id);
                  }}
                  className={cn("anim-card", selected && "is-selected", !c.ready && "is-pending")}
                >
                  <Poster url={c.image} name={c.name} />
                  <span className="anim-card-name">{c.name}</span>
                  {c.label ? (
                    <span className="anim-card-tag" aria-hidden={fullReason ? true : undefined} title={fullReason ?? undefined}>
                      {c.label}
                    </span>
                  ) : c.meta ? (
                    <span className="anim-card-meta">{c.meta}</span>
                  ) : null}
                  {fullReason ? <span className="sr-only">: {fullReason}</span> : null}
                </div>
              );
            })}
          </div>
        ))}
      </div>
      {reasons.size ? (
        <details className="anim-waiting">
          <summary>Hazır olmayan {waiting.length} karakterin durumu</summary>
          <ul>
            {[...reasons].map(([reason, names]) => (
              <li key={reason}>
                <b>{names.join(", ")}</b>: {/[.!?…]$/.test(reason) ? reason : `${reason}.`}
              </li>
            ))}
          </ul>
        </details>
      ) : null}
    </div>
  );
}
