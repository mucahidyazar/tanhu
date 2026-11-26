// Animasyonlar sayfasının metinleri: etiket adları ve çipler, klip araması, klibin bu kişideki yeri, kaynak satırı. Saf modül:
// sunucuda (tablo) da istemcide (oynatıcı, klip listesi) çalışır, sunucu modülü içe aktarmaz. Sınaması scripts/animations-check.mjs.
import type { AnimCharacter, AnimCharacterClip, AnimClip, AnimClipGroup } from "@/lib/animations";
import { fold } from "@/lib/text";

// Bir öbekte bu kadar ya da daha çok çeşit varsa öbek «zengin» sayılır, sayısı belirgin görünür.
export const RICH_GROUP_MIN = 10;
// Aramanın en uzun hâli: adresten gelen değer de bu boya indirilir.
export const QUERY_MAX = 60;
const PROMPT_MAX = 72;

const BODY_TR: Record<string, string> = { male: "Erkek", female: "Kadın", child: "Çocuk" };
const AGE_TR: Record<string, string> = { adult: "Yetişkin", elder: "Yaşlı", child: "Çocuk" };
const SEAT_TR: Record<string, string> = { ground: "yer", chair: "tabure" };
// Sahnelerin adı (manifest scene_picks): «Ateş başında oynar». Burada olmayan sahne kimliğiyle görünür.
const SCENE_TR: Record<string, string> = { camp: "Ateş başında", birth: "Doğumda" };
// Kararların ve Varlık Hattı'nın öbek sözcükleri (K91): sayfanın adı başka olsa da arama bulsun.
const GROUP_WORDS: Record<string, string> = {
  idle_fidget: "kıpırdanma",
  sit_ground: "yerde oturuş",
  sit_chair: "oturakta oturuş kütük",
  talk: "konuşma ve jest",
  work: "iş ve selam",
};
// Geçişler kişiyi yerinden kaldırır ya da oturtur: kamera geri çekilir. Bu öbekler dışında yalnız kökü bu kadar giden klipte.
const TRANSITION_GROUPS: ReadonlySet<string> = new Set(["sit_down", "stand_up"]);
const WIDE_TRAVEL_M = 0.25;
// data/clip_library.json tags.style. Burada olmayan stil tanımdaki adıyla görünür.
const STYLE_TR: Record<string, string> = {
  angry: "öfkeli",
  calm: "sakin",
  ceremony: "tören",
  chore: "gündelik iş",
  confused: "şaşkın",
  drink: "içme",
  fast: "hızlı",
  festive: "şenlik",
  graceful: "zarif",
  greet: "selam",
  listen: "dinleme",
  look_around: "etrafa bakma",
  meal: "yemek",
  night: "gece",
  passion: "coşkulu",
  playful: "neşeli",
  proud: "gururlu",
  restless: "huzursuz",
  sick: "hasta",
  slow: "yavaş",
  stretch: "gerinme",
  talk: "konuşma",
  thoughtful: "düşünceli",
  tired: "yorgun",
  warrior: "savaşçı",
};

export interface TagChip {
  kind: "Beden" | "Yaş" | "Stil" | "Oturak";
  label: string;
}

const listLabel = (values: string[], names: Record<string, string>) => values.map((v) => names[v] ?? v).join(", ");

// Etiket çipleri: beden, yaş, stil (stil başına bir çip), oturak. Bütün bedenlere ya da yaşlara uyan klipte kısa yazılır,
// etiketi olmayan alan çip vermez.
export function tagChips(clip: Pick<AnimClip, "tags" | "seat">): TagChip[] {
  const { body, age, style } = clip.tags;
  const chips: TagChip[] = [];
  if (body.length) chips.push({ kind: "Beden", label: body.length >= Object.keys(BODY_TR).length ? "her beden" : listLabel(body, BODY_TR) });
  if (age.length) chips.push({ kind: "Yaş", label: age.length >= Object.keys(AGE_TR).length ? "her yaş" : listLabel(age, AGE_TR) });
  for (const s of style) chips.push({ kind: "Stil", label: STYLE_TR[s] ?? s });
  if (clip.seat) chips.push({ kind: "Oturak", label: SEAT_TR[clip.seat] ?? clip.seat });
  return chips;
}

// Tablonun tek satırlık etiket yazısı: «Kadın · Yetişkin · sakin, zarif · oturak: yer».
export function tagLine(clip: Pick<AnimClip, "tags" | "seat">): string {
  const chips = tagChips(clip);
  const of = (kind: TagChip["kind"]) => chips.filter((c) => c.kind === kind).map((c) => c.label);
  return [...of("Beden"), ...of("Yaş"), of("Stil").join(", "), ...of("Oturak").map((s) => `oturak: ${s}`)].filter(Boolean).join(" · ");
}

// Klibin arama metni: ad, İngilizce ad, anahtar, öbek, öbeğin belgelerdeki sözcükleri ve etiketler (türüyle: «Oturak tabure»),
// Türkçe harfler katlanmış. Alt çizgi boşluk olur; sorgu da aynı kuraldan geçer (queryTokens).
export function searchText(clip: AnimClip, groupName: string): string {
  const chips = tagChips(clip).map((c) => `${c.kind} ${c.label}`);
  return fold([clip.tr, clip.en, clip.key.replace(/_/g, " "), groupName, GROUP_WORDS[clip.group] ?? "", ...chips].join(" "));
}

export const normalizeQuery = (value: string | null | undefined) => (value ?? "").trim().slice(0, QUERY_MAX);

// Sözcüklerin hepsi metinde geçmeli: «yerde kadın» ikisini de taşıyan klipleri bulur. Anahtar yazıldığı gibi de aranır:
// «ground_side_sit» «ground side sit» gibi okunur.
export function queryTokens(query: string): string[] {
  return fold(query).replace(/_/g, " ").split(/\s+/).filter(Boolean);
}

export const matchesTokens = (text: string, tokens: string[]) => tokens.every((t) => text.includes(t));

// Türkçe ilgi eki, kesme işaretiyle: Mete'nin, Baba'nın, Teoman'ın, Çocuk'un, Lan Hatun'un. Ek son ünlüye uyar; ünlüyle
// biten adda araya «n» girer. Ad harfle bitmiyorsa (ör. «(1)») ek yerine «X adlı karakterin» yazılır.
export function genitive(name: string): string {
  const trimmed = name.trim();
  const lower = trimmed.toLocaleLowerCase("tr");
  const vowels = lower.match(/[aıoueiöü]/g);
  if (!vowels || !/[a-zçğıöşü]$/.test(lower)) return `${trimmed} adlı karakterin`;
  const last = vowels[vowels.length - 1];
  const suffix = "aı".includes(last) ? "ın" : "ei".includes(last) ? "in" : "ou".includes(last) ? "un" : "ün";
  return `${trimmed}'${/[aıoueiöü]$/.test(lower) ? "n" : ""}${suffix}`;
}

export const sceneLabel = (scene: string) => SCENE_TR[scene] ?? scene;

// Kamera geri çekilsin mi: geçişler ve kökü gerçekten yerinden giden bir kez oynayan klipler. Oturuşların kökü yerinde durur.
export function isWideClip(clip: Pick<AnimClip, "loop" | "group" | "travelM"> | undefined): boolean {
  if (!clip || clip.loop) return false;
  return TRANSITION_GROUPS.has(clip.group) || clip.travelM >= WIDE_TRAVEL_M;
}

// Klibin oynayış biçimi, klibin kendisine göre: oyunda bugün oynayıp oynamadığını söylemez (onu clipUses söyler).
export function loopText(loop: boolean, seatLoop: boolean | null | undefined): string {
  if (loop) return "Döngülü klip";
  if (seatLoop === true) return "Bir kez oynayan klip; oturma rolünde döngüye kapatılır";
  if (seatLoop === false) return "Bir kez oynayan klip; oturma rolünde son pozunda durur";
  return "Bir kez oynayan klip";
}

export interface ClipUse {
  text: string;
  // Bugün sahnede oynuyor: görsel olarak öne çıkar.
  live: boolean;
}

// Klibin bu kişideki yeri: sahnede oynuyor mu, sahnesiz varsayılanı mı (rolü olan öbekte ya da sahnesi henüz olmayan öbekte), modelin
// kendi rol klibi mi. Oyuncu karakteri çeşit almaz: kendi rol klibi oyunda oynadığı kliptir.
export function clipUses(character: Pick<AnimCharacter, "group" | "assigned" | "scenePicks">, clip: Pick<AnimCharacterClip, "key" | "gameRole">, groups: AnimClipGroup[], clipName: (key: string) => string): ClipUse[] {
  const uses: ClipUse[] = [];
  const picks = Object.entries(character.scenePicks);
  for (const [scene, row] of picks) {
    if (Object.values(row).includes(clip.key)) uses.push({ text: `${sceneLabel(scene)} oynar`, live: true });
  }
  if (character.group === "player" && clip.gameRole) uses.push({ text: "Oyunda bu klibi oynar", live: true });
  for (const group of groups) {
    const value = character.assigned[group.key];
    if (!(Array.isArray(value) ? value.includes(clip.key) : value === clip.key)) continue;
    if (!group.live) {
      uses.push({ text: `Sahnesi gelince: ${group.tr}`, live: false });
      continue;
    }
    // Sahne bu öbekte başka klip seçtiyse varsayılan orada oynamaz: hangisinin oynadığı yazılır.
    const elsewhere = picks.flatMap(([scene, row]) => (row[group.key] && row[group.key] !== clip.key ? [`${sceneLabel(scene).toLocaleLowerCase("tr")} ${clipName(row[group.key])} oynar`] : []));
    uses.push({ text: `Sahnesiz varsayılanı: ${group.tr}${elsewhere.length ? ` (${elsewhere.join(", ")})` : ""}`, live: false });
  }
  if (clip.gameRole && character.group !== "player") uses.push({ text: "Modelin kendi rol klibi", live: false });
  return uses.length ? uses : [{ text: "Bu kişiye atanmamış", live: false }];
}

// İstemin kısası: sözcük sınırında kesilir, tamamı kütüphane tablosunun notundadır.
export function shortPrompt(prompt: string): string {
  if (prompt.length <= PROMPT_MAX) return prompt;
  const space = prompt.lastIndexOf(" ", PROMPT_MAX);
  return `${(space > 0 ? prompt.slice(0, space) : prompt.slice(0, PROMPT_MAX)).replace(/[\s,;:]+$/, "")}…`;
}

const SECONDS = new Intl.NumberFormat("tr-TR", { maximumFractionDigits: 2 });

export interface SourceContext {
  // Karakterlerin adları (donor ya da alım sahibi).
  nameOf: (id: string) => string;
  // Taşıyıcı iskeletlerin adları: {kimlik: görünen ad}.
  carriers: Record<string, string>;
}

// Kaynak satırının parçası: metinden hareketin istemi İngilizcedir, ekran okuyucu onu İngilizce okusun (lang).
export interface SourcePart {
  text: string;
  lang?: "en";
}

export const sourcePartsText = (parts: SourcePart[]) => parts.map((p) => p.text).join("");

// Klibin bu karakterdeki kaynağı. Beş tür: kendi klibi; taşıyıcıdan ya da başka karakterden aktarıldı (0 kredi); metinden
// üretildi (kısa istemle); ters türetildi; iskeletin hediyesi. Taşıyıcının ham kimliği gösterilmez, adı yazılır.
export function clipSourceParts(entry: Pick<AnimCharacterClip, "source" | "donor">, clip: AnimClip | undefined, characterId: string, context: SourceContext): SourcePart[] {
  if (entry.source === "retarget") {
    const carrier = entry.donor ? context.carriers[entry.donor] : undefined;
    const transfer = carrier
      ? `taşıyıcıdan ClipRetarget ile aktarıldı (0 kredi): ${carrier}`
      : entry.donor
        ? `${genitive(context.nameOf(entry.donor))} klibinden ClipRetarget ile aktarıldı (0 kredi)`
        : "başka bir karakterin klibinden ClipRetarget ile aktarıldı (0 kredi)";
    const origin = clipOrigin(clip);
    return origin.length ? [...origin, { text: `; ${transfer}.` }] : [{ text: `${capitalize(transfer)}.` }];
  }
  if (clip?.kind === "rig") return [{ text: "İskeletin hediyesi: bu karakterin iskelet göreviyle geldi, ek kredi yok." }];
  const owner = entry.donor ?? characterId;
  const bought = clip?.purchases.filter((p) => p.character === owner) ?? [];
  const credits = bought.reduce((sum, p) => sum + p.credits, 0);
  const detail = [clip?.meshyAction != null ? `Meshy hareketi ${clip.meshyAction}` : "", bought.length ? `${credits} kredi` : ""].filter(Boolean).join(", ");
  const tail = detail ? ` (${detail})` : "";
  if (entry.source === "native_raw") return [{ text: `Bu karakterin kendi alımı; modelin rol klibi değil${tail}.` }];
  return [{ text: `Bu karakterin kendi klibi${tail}.` }];
}

// Aktarılan klibin kökeni: metinden üretildi, ters türetildi, iskelet hediyesi ya da Meshy hareketi.
function clipOrigin(clip: AnimClip | undefined): SourcePart[] {
  if (!clip) return [];
  if (clip.kind === "derived" && clip.derived) {
    const cut = clip.derived.trimStart > 0 ? `, ${SECONDS.format(clip.derived.trimStart)}. saniyede kesildi` : "";
    return [{ text: `Ters türetildi: «${clip.derived.fromTr}» klibinin tersi${cut}` }];
  }
  if (clip.prompt) return [{ text: "Metinden üretildi (istem: «" }, { text: shortPrompt(clip.prompt), lang: "en" }, { text: "»)" }];
  if (clip.kind === "rig") return [{ text: "İskeletin hediyesi" }];
  return clip.meshyAction != null ? [{ text: `Meshy hareketi ${clip.meshyAction}` }] : [];
}

const capitalize = (text: string) => text.charAt(0).toLocaleUpperCase("tr") + text.slice(1);
