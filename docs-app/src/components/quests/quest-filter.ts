// Görevler sayfasının süzgeç kuralları: adresteki değerlerin okunması (?kind, ?act, ?family, ?q), perde grupları,
// arama eşleşmesi ve görev adresi. Saf işlevlerdir; sunucu da istemci de aynı kuralla okur. Veri modülünden
// (src/lib/quests.ts, node:fs kullanır) yalnız tip alınır: istemci paketine girmesin.
import type { ActId, ClientAct, ClientQuest, Quest, QuestKind, QuestStatus } from "@/lib/quests";
import { fold } from "@/lib/text";

export const KINDS: { id: QuestKind; label: string }[] = [
  { id: "main", label: "Ana hikâye" },
  { id: "side", label: "Yan görevler" },
  { id: "companion", label: "Yoldaş görevleri" },
];

export const KIND_LABEL: Record<QuestKind, string> = { main: "Ana hikâye", side: "Yan görev", companion: "Yoldaş görevi" };

// Perde süzgeci: Önsöz ile Çocukluk tek seçenektir («0»), ötekiler Roma rakamıyla.
export type ActKey = "0" | "I" | "II" | "III" | "IV" | "V" | "VI";
export const ACT_KEYS: { key: ActKey; label: string; acts: ActId[] }[] = [
  { key: "0", label: "Önsöz–Çocukluk", acts: ["prologue", "childhood"] },
  { key: "I", label: "I", acts: ["I"] },
  { key: "II", label: "II", acts: ["II"] },
  { key: "III", label: "III", acts: ["III"] },
  { key: "IV", label: "IV", acts: ["IV"] },
  { key: "V", label: "V", acts: ["V"] },
  { key: "VI", label: "VI", acts: ["VI"] },
];
export const ACT_ORDER: ActId[] = ["prologue", "childhood", "I", "II", "III", "IV", "V", "VI"];

export const STATUS: Record<QuestStatus, { label: string; glyph: string }> = {
  playable: { label: "Oyunda", glyph: "✓" },
  "in-progress": { label: "Yapılıyor", glyph: "◐" },
  design: { label: "Tasarımda", glyph: "○" },
};

export type QuestFilter = { kind: QuestKind; act: ActKey | null; family: string | null; q: string };

const ROMAN = ["I", "II", "III", "IV", "V", "VI"] as const;
// Map: adresten gelen değer nesnenin prototipine çarpmasın (?kind=constructor, ?kind=__proto__ varsayılana düşer).
const KIND_ALIASES = new Map<string, QuestKind>([
  ["main", "main"],
  ["ana", "main"],
  ["side", "side"],
  ["yan", "side"],
  ["companion", "companion"],
  ["yoldas", "companion"],
]);
const ZERO_ALIASES = new Set(["0", "prologue", "childhood", "onsoz", "cocukluk"]);

export function parseKind(value: string | null | undefined): QuestKind {
  return (value && KIND_ALIASES.get(fold(value.trim()))) || "main";
}

export function parseAct(value: string | null | undefined): ActKey | null {
  if (!value) return null;
  const v = fold(value.trim());
  if (ZERO_ALIASES.has(v)) return "0";
  const upper = v.toUpperCase();
  if ((ROMAN as readonly string[]).includes(upper)) return upper as ActKey;
  const n = Number(v);
  return Number.isInteger(n) && n >= 1 && n <= 6 ? ROMAN[n - 1] : null;
}

// Aile adı adreste katlanmış yazılır: «Töre / Custom» → «tore», «Kışlak (I. Perde)» → «kislak».
export function familyKey(name: string | null | undefined): string {
  return name ? fold(name.split("/")[0].replace(/\s*\([^)]*\)\s*$/, "").trim()) : "";
}

export function familyLabel(name: string): string {
  return name.split("/")[0].trim();
}

export function parseFilter(get: (key: string) => string | null | undefined): QuestFilter {
  const kind = parseKind(get("kind"));
  const family = kind === "side" ? familyKey(get("family")) || null : null;
  return { kind, act: parseAct(get("act")), family, q: (get("q") ?? "").trim() };
}

export function actKeyOf(act: ActId): ActKey {
  return act === "prologue" || act === "childhood" ? "0" : act;
}

// Görev kimliğinden perdesi (var olan görevler); adımda yalnız kimlik yazıyorsa adımın perdesi buradan okunur.
export type ActLookup = (id: string) => ActKey | null;

export function actLookup(quests: readonly Pick<Quest, "id" | "act">[]): ActLookup {
  const acts = new Map(quests.map((q) => [q.id, actKeyOf(q.act)]));
  return (id) => acts.get(id) ?? null;
}

const ACT_WORD = "(?:VI|IV|V|III|II|I)(?![A-Za-zÇĞİÖŞÜçğıöşü])";
const STEP_LEAD = new RegExp(`^${ACT_WORD}(?:-[a-eA-E])?(?:\\s+ya da\\s+${ACT_WORD}(?:-[a-eA-E])?)*`);
const QUEST_CODE = /`((?:mq|sq|cq)\d*_[a-z0-9_]+)`/g;

// Yoldaş adımının perdeleri: öndeki perde ya da seçenekleri («IV-A, `mq4_hollow`» → IV, «III ya da IV» → III ve IV,
// «V'in Serbest Dolaşım'ı» → V) ve metinde ters tırnakla anılan görevlerin perdeleri («`mq4_dailin_ordos`» → IV,
// «II, `mq2_own_hearth` (IV yolunda `mq4_torn_felt`)» → II ve IV). Kimliğin perdesi için lookup gerekir.
export function stepActKeys(when: string | null | undefined, lookup?: ActLookup): ActKey[] {
  const text = when?.trim() ?? "";
  const keys = new Set<ActKey>();
  for (const roman of text.match(STEP_LEAD)?.[0].match(/VI|IV|V|III|II|I/g) ?? []) keys.add(roman as ActKey);
  if (lookup) {
    for (const m of text.matchAll(QUEST_CODE)) {
      const key = lookup(m[1]);
      if (key) keys.add(key);
    }
  }
  return [...keys];
}

// Görevin geçtiği perdeler: görevin perdesi, verinin yazdığı perdeler (yoldaş görevi birden çok perdeye yayılır) ve
// yoldaş adımlarının perdeleri. Sayılar tablosu, perde süzgeci ve merdivenin «bu perdede» işareti aynı kuralı kullanır.
export function questActKeys(quest: ClientQuest, lookup?: ActLookup): ActKey[] {
  const keys = new Set<ActKey>([actKeyOf(quest.act)]);
  for (const a of quest.acts ?? []) keys.add(actKeyOf(a));
  if (quest.kind === "companion") {
    for (const s of quest.steps ?? []) for (const key of stepActKeys(s.when, lookup)) keys.add(key);
  }
  return [...keys];
}

export function inAct(quest: ClientQuest, act: ActKey | null, lookup?: ActLookup): boolean {
  return !act || questActKeys(quest, lookup).includes(act);
}

export function searchText(quest: ClientQuest): string {
  return fold([quest.id, quest.titleTr, quest.titleEn ?? ""].join(" "));
}

// Kimlikte alt çizgi ile boşluk aynı sayılır: «crow war» da «sq_crow_war»ı bulur.
export function matchesQuery(haystack: string, folded: string): boolean {
  if (!folded) return true;
  const plain = haystack.replace(/_/g, " ");
  return folded
    .split(/\s+/)
    .filter(Boolean)
    .every((word) => haystack.includes(word) || plain.includes(word.replace(/_/g, " ")));
}

// Görevin paylaşılabilir adresi: süzgeçsiz, yalnız sekmesiyle; sayfa açılınca karta kayar.
export function questHref(quest: Pick<Quest, "id" | "kind">): string {
  return `/quests${quest.kind === "main" ? "" : `?kind=${quest.kind}`}#${encodeURIComponent(quest.id)}`;
}

export function filterHref(f: Partial<QuestFilter>): string {
  const p = new URLSearchParams();
  if (f.kind && f.kind !== "main") p.set("kind", f.kind);
  if (f.act) p.set("act", f.act);
  if (f.kind === "side" && f.family) p.set("family", f.family);
  if (f.q) p.set("q", f.q);
  const s = p.toString();
  return `/quests${s ? `?${s}` : ""}`;
}

export function actName(id: ActId): string {
  if (id === "prologue") return "Önsöz";
  if (id === "childhood") return "Çocukluk";
  return `${id}. Perde`;
}

// Başlık: «I. Perde · Çan». Veri adı zaten «Önsöz …» diye başlıyorsa yinelenmez.
export function actHeading(info: Pick<ClientAct, "id" | "tr">): string {
  const name = actName(info.id);
  const tr = info.tr?.trim();
  if (!tr) return name;
  return fold(tr).startsWith(fold(name)) ? tr : `${name} · ${tr}`;
}

export function capitalizeTr(text: string): string {
  return text ? text.charAt(0).toLocaleUpperCase("tr-TR") + text.slice(1) : text;
}

export const formatNumber = (n: number) => n.toLocaleString("tr-TR");
