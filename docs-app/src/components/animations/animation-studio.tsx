"use client";

// Animasyonlar sayfasının etkileşimli bölümü: karakter seçici, klip oynatıcı ve klip listesi. Geniş ekranda üçü yan yana, orta
// genişlikte seçici üstte, telefonda alt alta (görünüm yapışkan kalır, klip seçilince hareket hemen görünür).
// Seçim ve süzgeç adresten okunur (useSearchParams): /animations?character=<id>&clip=<anahtar>&group=<öbek>&q=<arama>. Kart ya
// da klip seçilince adres sunucuya gitmeden history.replaceState ile yazılır, Next bunu useSearchParams'a yansıtır; kenar
// çubuğundaki bağ, geri tuşu ve elle yazılan adres de ekrana aynı yoldan gelir, ekran hep adresi gösterir. Hız ve döngü
// karakter değişince de korunur.
import { useSearchParams } from "next/navigation";
import { useCallback, useEffect, useMemo, useState, useSyncExternalStore } from "react";
import { CharacterPicker } from "@/components/animations/character-picker";
import { ClipBrowser } from "@/components/animations/clip-browser";
import { ClipPlayer, SourceText } from "@/components/animations/clip-player";
import { clipSourceParts, clipUses } from "@/components/animations/clip-text";
import { documentTitle, firstParam, resolveSelection } from "@/components/animations/selection";
import type { AnimCharacter, AnimClip, AnimClipGroup, AnimPending } from "@/lib/animations";

const REDUCED_MOTION = "(prefers-reduced-motion: reduce)";

function subscribeMotion(onChange: () => void) {
  const query = window.matchMedia(REDUCED_MOTION);
  query.addEventListener("change", onChange);
  return () => query.removeEventListener("change", onChange);
}

// Sunucuda tercih bilinmez: hareket azaltılmamış sayılır, istemci ilk çizimden sonra gerçeğini okur.
function usePrefersReducedMotion() {
  return useSyncExternalStore(
    subscribeMotion,
    () => window.matchMedia(REDUCED_MOTION).matches,
    () => false,
  );
}

const height = (m: number | null) => (m ? `${m.toLocaleString("tr-TR", { maximumFractionDigits: 2 })} m` : null);

// Adresin parametrelerini değiştirir (null: siler); adres zaten buysa dokunulmaz.
function writeParams(change: Record<string, string | null>) {
  const params = new URLSearchParams(window.location.search);
  for (const [name, value] of Object.entries(change)) {
    if (value) params.set(name, value);
    else params.delete(name);
  }
  const search = params.size ? `?${params.toString()}` : "";
  if (search !== window.location.search) window.history.replaceState(null, "", `${window.location.pathname}${search}`);
}

export function AnimationStudio({
  characters,
  pending,
  clips,
  groups,
  carriers,
}: {
  characters: AnimCharacter[];
  pending: AnimPending[];
  clips: AnimClip[];
  groups: AnimClipGroup[];
  carriers: Record<string, string>;
}) {
  const reducedMotion = usePrefersReducedMotion();
  const params = useSearchParams();
  const [rate, setRate] = useState(1);
  const [loop, setLoop] = useState(true);

  const selection = resolveSelection(
    { characters, pending, clips, groups },
    { character: firstParam(params.get("character")), clip: firstParam(params.get("clip")), group: firstParam(params.get("group")), q: firstParam(params.get("q")) },
  );
  const title = documentTitle(selection);
  const clipsByKey = useMemo(() => new Map(clips.map((c) => [c.key, c])), [clips]);
  const nameOf = useMemo(() => {
    const names = new Map([...pending, ...characters].map((c) => [c.id, c.name]));
    return (id: string) => names.get(id) ?? id;
  }, [characters, pending]);

  // Sekme başlığı da adresten yazılır: Next aynı sayfada yalnız arama değişince başlığa dokunmaz, önbellekten dönülen
  // sayfada da eski adresin başlığı kalırdı.
  useEffect(() => {
    document.title = title;
  }, [title]);

  const onGroup = useCallback((group: string | null) => writeParams({ group }), []);
  const onQuery = useCallback((q: string) => writeParams({ q: q || null }), []);

  // Sunucu hazır karakter yoksa bu bileşeni çizmez; yine de seçim yoksa boş kalır.
  if (!selection) return null;
  const { character, notice } = selection;
  const clip = character.clips.find((c) => c.key === selection.clipKey) ?? character.clips[0];
  const info = clipsByKey.get(clip.key);
  const ready = characters.filter((c) => c.ready);
  const sourceParts = clipSourceParts(clip, info, character.id, { nameOf, carriers });
  const uses = clipUses(character, clip, groups, (key) => clipsByKey.get(key)?.tr ?? key);

  const selectCharacter = (id: string) => {
    const next = ready.find((c) => c.id === id);
    if (!next) return;
    // Aynı klip yeni karakterde de varsa kalır (karşılaştırmak için); yoksa karakterin açılış klibi.
    const key = next.clips.some((c) => c.key === clip.key) ? clip.key : (next.defaultClip ?? next.clips[0].key);
    writeParams({ character: next.id, clip: key });
  };

  const selectClip = (key: string) => writeParams({ character: character.id, clip: key });

  return (
    <div className="anim-studio">
      <div className="anim-layout">
        <section className="anim-side" aria-labelledby="anim-picker-title">
          <h2 id="anim-picker-title" className="anim-side-title">
            Karakterler <span>· {ready.length} hazır{pending.length ? `, ${pending.length} kuyrukta` : ""}</span>
          </h2>
          <CharacterPicker characters={characters} pending={pending} selectedId={character.id} onSelect={selectCharacter} />
        </section>

        <section className="anim-main" aria-labelledby="anim-viewer-title">
          <header className="anim-head">
            <h2 id="anim-viewer-title" className="anim-title">
              {character.name}
            </h2>
            <p className="anim-sub">{[character.bodyLabel, height(character.heightM), `${character.clips.length} klip`].filter(Boolean).join(" · ")}</p>
          </header>
          {notice ? (
            <p className="anim-notice" role="status">
              {notice}
            </p>
          ) : null}
          {reducedMotion ? <p className="anim-notice is-quiet">Hareket azaltma tercihin açık: klipler kendiliğinden oynamaz, Oynat ile başlar.</p> : null}
          <div className="anim-viewer">
            <ClipPlayer
              key={character.id}
              character={character}
              clip={clip}
              info={info}
              sourceParts={sourceParts}
              uses={uses}
              rate={rate}
              onRate={setRate}
              loop={loop}
              onLoop={setLoop}
              reducedMotion={reducedMotion}
            />
            <ClipBrowser
              character={character}
              clips={clips}
              groups={groups}
              clipKey={clip.key}
              group={selection.group}
              query={selection.query}
              onClip={selectClip}
              onGroup={onGroup}
              onQuery={onQuery}
            />
          </div>
          {/* Duyuru oynatıcının dışında: oynatıcı karakter başına yeniden kurulur, içindeki canlı bölge her seferinde yeni
              doğar ve ekran okuyucu yeni bölgenin ilk metnini okumaz. Bu öğe kalır; karakter de klip de değişince okunur. */}
          <p className="sr-only" aria-live="polite">
            {`${character.name}, ${info?.tr ?? clip.key}: `}
            <SourceText parts={sourceParts} />
          </p>
        </section>
      </div>
    </div>
  );
}
