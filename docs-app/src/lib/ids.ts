// Eski Türkçe kimlik ve adresleri İngilizceye çevirir (legacy-ids.json): yönlendirme, veri taşıma ve kaynak belgelerin
// takma adları. Dosya adları değişmedi; kaynak belgenin adresi takma addır (bozkir-ekonomi.md → steppe-economy).
import legacy from "./legacy-ids.json";

const SOURCE_NAMES: Record<string, string> = legacy.sourceNames;
const SOURCE_FILES: Record<string, string> = Object.fromEntries(Object.entries(SOURCE_NAMES).map(([file, alias]) => [alias, file]));
const PAGES: Record<string, string> = legacy.pages;
const CATEGORIES: Record<string, string> = legacy.categories;
// Uzun önek önce: JSON'daki sıra korunur (kaynak/design/d2, kaynak/design/d3, kaynak/design …).
const SOURCE_GROUPS = Object.entries(legacy.sourceGroups as Record<string, string>);

// Kaynak belgenin dosya adından adresteki adı ve tersi.
export const sourceAlias = (fileBase: string) => SOURCE_NAMES[fileBase] ?? fileBase;
export const sourceFileBase = (alias: string) => SOURCE_FILES[alias] ?? alias;

// Eski kimlik → yeni kimlik (sayfa, kategori, kaynak grubu ya da kaynak belge). Bilinmeyen kimlik olduğu gibi döner.
export function newDocId(old: string): string {
  if (PAGES[old]) return PAGES[old];
  if (CATEGORIES[old]) return CATEGORIES[old];
  for (const [from, to] of SOURCE_GROUPS) {
    if (old === from) return to;
    if (!old.startsWith(`${from}/`)) continue;
    const rest = old.slice(from.length + 1);
    if (rest.includes("/")) continue;
    return `${to}/${sourceAlias(rest)}`;
  }
  return old;
}

// Yeni kimlikten eski Türkçe kimliğe (sayfa ve kaynak belge): tarayıcıda eski adla kalmış taslağı bulmak için.
const OLD_PAGE: Record<string, string> = Object.fromEntries(Object.entries(PAGES).filter(([from]) => from !== "hikaye/sonraki-perdeler").map(([from, to]) => [to, from]));
const OLD_GROUP = SOURCE_GROUPS.map(([from, to]) => [to, from] as const).sort((a, b) => b[0].length - a[0].length);
export function legacyDocId(id: string): string | null {
  if (OLD_PAGE[id]) return OLD_PAGE[id];
  for (const [to, from] of OLD_GROUP) {
    if (!id.startsWith(`${to}/`)) continue;
    const rest = id.slice(to.length + 1);
    if (rest.includes("/")) continue;
    // Türkçe dosya adlı takma adlar yalnız araştırma, d3 ve oyun belgelerindedir: tasarımın companions.md'si kendi adıdır.
    return `${from}/${to === "source/design" ? rest : sourceFileBase(rest)}`;
  }
  return null;
}
