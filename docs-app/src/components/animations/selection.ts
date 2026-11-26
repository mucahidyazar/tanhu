// Animasyonlar sayfasının seçimi adresten okunur: /animations?character=<id>&clip=<anahtar>&group=<öbek>&q=<arama>. Sunucu (sekme
// başlığı) ile istemci (AnimationStudio) aynı kuralı izler; ekran, adres ve başlık hep aynı seçimi gösterir. Adresteki karakter
// yoksa ya da hazır değilse açılış karakteri (önce oynanabilir), klip yoksa karakterin açılış klibi gösterilir; neden bir
// bildirimle söylenir. Klip yazılı değilse ve adres bir öbek seçiyorsa kişinin o öbekte oynadığı klip açılır. Bilinmeyen öbek
// süzgeç sayılmaz, o da bildirimle söylenir. Dosya sunucu modülü içe aktarmaz: iki tarafta da çalışır.
import { normalizeQuery } from "@/components/animations/clip-text";
import type { AnimCharacter, AnimClip, AnimClipGroup, AnimPending } from "@/lib/animations";

export interface AnimSelection {
  character: AnimCharacter;
  clipKey: string;
  // Adres hazır bir karakteri seçiyor mu: seçiyorsa sekme başlığı karakterin adını taşır.
  named: boolean;
  notice: string | null;
  // Geçerli öbek süzgeci (yoksa null) ve arama (yoksa boş).
  group: string | null;
  query: string;
}

export interface SelectionData {
  characters: AnimCharacter[];
  pending: AnimPending[];
  clips: Pick<AnimClip, "key" | "tr" | "group">[];
  groups: AnimClipGroup[];
}

export interface SelectionQuery {
  character: string | null;
  clip: string | null;
  group?: string | null;
  q?: string | null;
}

// Kök yerleşimin başlık kalıbı (src/app/layout.tsx, "%s · Tanhu Belgeleri"): istemci başlığı kendisi yazarken kullanılır.
const SITE_TITLE = "Tanhu Belgeleri";
// Adresten bildirime yansıyan değer bu uzunlukta kesilir: uzun, boşluksuz bir değer dar ekranda satırı taşırmasın.
const ECHO_MAX = 40;

export const firstParam = (v: string | string[] | null | undefined): string | null => (Array.isArray(v) ? v[0] : v) || null;

const echo = (value: string) => (value.length > ECHO_MAX ? `${value.slice(0, ECHO_MAX - 1)}…` : value);

// Kişinin bir öbekte oynadığı klip: sahnenin seçimi, yoksa atanmış çeşit (ara harekette listenin ilki), yoksa modelin o öbekteki kendi
// rol klibi (oyuncu karakteri bunları oynar), o da yoksa kişinin o öbekteki ilk klibi.
function groupClip(character: AnimCharacter, group: string, clips: SelectionData["clips"]): string | null {
  const holds = (key: string | undefined): key is string => Boolean(key) && character.clips.some((c) => c.key === key);
  const scene = Object.values(character.scenePicks).find((row) => holds(row[group]))?.[group];
  if (scene) return scene;
  const assigned = character.assigned[group];
  const own = Array.isArray(assigned) ? assigned[0] : assigned;
  if (holds(own)) return own;
  const inGroup = clips.filter((c) => c.group === group && holds(c.key));
  const role = inGroup.find((c) => character.clips.some((x) => x.key === c.key && x.gameRole));
  return (role ?? inGroup[0])?.key ?? null;
}

// Hazır karakter yoksa null: sayfa boş durumu gösterir.
export function resolveSelection(data: SelectionData, requested: SelectionQuery): AnimSelection | null {
  const { characters, pending, clips, groups } = data;
  const ready = characters.filter((c) => c.ready);
  if (!ready.length) return null;
  const fromQuery = requested.character ? ready.find((c) => c.id === requested.character) : undefined;
  const character = fromQuery ?? ready.find((c) => c.group === "player") ?? ready[0];
  const group = requested.group && groups.some((g) => g.key === requested.group) ? requested.group : null;
  const opening = (group ? groupClip(character, group, clips) : null) ?? character.defaultClip ?? character.clips[0].key;
  const clipKey = requested.clip && character.clips.some((c) => c.key === requested.clip) ? requested.clip : opening;

  const notices: string[] = [];
  if (requested.character && !fromQuery) {
    const known = characters.find((c) => c.id === requested.character) ?? pending.find((p) => p.id === requested.character);
    notices.push(known ? `${known.name} henüz hazır değil; ${character.name} gösteriliyor.` : `«${echo(requested.character)}» kütüphanede yok; ${character.name} gösteriliyor.`);
  } else if (requested.clip && requested.clip !== clipKey) {
    const shown = clips.find((c) => c.key === clipKey)?.tr ?? clipKey;
    notices.push(`${character.name} için «${echo(requested.clip)}» klibi yok; ${shown} gösteriliyor.`);
  }
  if (requested.group && !group) notices.push(`«${echo(requested.group)}» diye bir klip grubu yok; bütün gruplar gösteriliyor.`);
  return { character, clipKey, named: Boolean(fromQuery), notice: notices.length ? notices.join(" ") : null, group, query: normalizeQuery(requested.q) };
}

// Sayfanın başlığı, kalıpsız (üst bilgi için): adres bir karakter seçiyorsa onun adıyla.
export const selectionTitle = (selection: AnimSelection | null) => (selection?.named ? `${selection.character.name} · Animasyonlar` : "Animasyonlar");

// Sekmenin tam başlığı (istemci document.title'a yazar).
export const documentTitle = (selection: AnimSelection | null) => `${selectionTitle(selection)} · ${SITE_TITLE}`;
