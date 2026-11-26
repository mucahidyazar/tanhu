// Animasyon kütüphanesi: docs/assets/animations/manifest.json (Godot aracı game/tools/clip_library_export.gd yazar, elle
// düzenlenmez; K90). Her karakterin bütün klipleri kendi GLB'sinde, adları klip anahtarıdır. Bir Meshy hareketi bir kez satın
// alınır; öteki karakterler o klibi ClipRetarget ile 0 krediyle alır. Klipler öbeklere ayrılır (groups), her kişinin varsayılan
// çeşitleri characters[].assigned'da (ClipVariety; oyuncu karakterinde boş, K91), sahnenin ona oynattığı klipler
// characters[].scene_picks'tedir. Dosya yoksa ya da okunamıyorsa sayfa boş durumu gösterir; eski sürüm bir dosyada yeni alanlar yoksa
// sayfa yine açılır (klipler «Öteki» öbeğinde). Yollar depo köküne göredir; tarayıcı /media/<yol>'dan alır.
import fs from "node:fs";
import path from "node:path";
import { REPO_ROOT } from "./catalog";

export const ANIMATION_MANIFEST = "docs/assets/animations/manifest.json";
const MANIFEST_FILE = path.join(REPO_ROOT, ANIMATION_MANIFEST);
// Medya yolu yalnız bu köklerin altından verilir (src/app/media/[...path]/route.ts).
const MEDIA_ROOTS = ["docs/", "game/"];
const DECISIONS_HREF = "/docs/source/design/decisions";
// Öbeği yazılı olmayan klibin öbeği.
const OTHER_GROUP = "other";

// ---------- Sayfanın gördüğü biçim (istemciye de gider; alanlar sözleşmedeki adlardan okunur) ----------

export type AnimGroup = "player" | "named" | "crowd";
export type AnimBody = "male" | "female" | "child";
export type AnimSeat = "ground" | "chair";
// purchase: kredili hareket (Meshy hareketi ya da metinden); rig: iskelet görevinin ücretsiz klibi; derived: başka klipten türetilmiş.
export type AnimClipKind = "purchase" | "rig" | "derived";
// native: karakterin oyunda kullanılan kendi klibi; native_raw: kendisi için satın alınmış ama oyunda kullanılmayan
// klibi; retarget: bağışçının ya da taşıyıcının klibinden ClipRetarget ile aktarılmış.
export type AnimClipSource = "native" | "native_raw" | "retarget";

export interface AnimCredits {
  spent_on_actions: number;
  purchases: number;
  distinct_actions: number;
  duplicate_credits: number;
  motions: { count: number; credits: number };
  total: number;
}

export interface AnimClipTags {
  body: string[];
  age: string[];
  style: string[];
}

// Klip öbeği: anahtar, görünen ad, klip sayısı ve kredisi. live: bugün sahnede rolü var (bekle, yürü, koş, otur; K91).
export interface AnimClipGroup {
  key: string;
  tr: string;
  count: number;
  credits: number;
  live: boolean;
}

// Klibin bütün karakterlerde aynı olan bilgisi (istemciye gider).
export interface AnimClip {
  key: string;
  tr: string;
  en: string;
  group: string;
  seat: AnimSeat | null;
  tags: AnimClipTags;
  meshyAction: number | null;
  kind: AnimClipKind;
  // Metinden hareketin istemi (öteki kliplerde null).
  prompt: string | null;
  // Türetilmiş klibin kaynağı (öteki kliplerde null).
  derived: { from: string; fromTr: string; trimStart: number } | null;
  loop: boolean;
  // Bir kez oynayan oturuş oturma rolünde döngüye kapatılıyor mu (true) ya da son pozunda mı duruyor (false); öteki kliplerde null.
  seatLoop: boolean | null;
  // Bir kez oynayan klibin kökünün yatay yer değiştirmesi (metre).
  travelM: number;
  purchases: { character: string; name: string; credits: number }[];
}

// Kütüphane tablosunun ayrıca gördüğü (sunucuda kalır).
export interface AnimClipInfo extends AnimClip {
  role: string;
  note: string;
  credits: number;
  // Klibi taşıyan karakter sayısı, klibi modelin kendi rol klibi olarak taşıyanların ve kişiye atanmış olanların sayısı.
  usedBy: number;
  ownBy: number;
  assignedTo: number;
}

export interface AnimCharacterClip {
  key: string;
  source: AnimClipSource;
  donor: string | null;
  duration: number | null;
  frames: number | null;
  loop: boolean;
  gameRole: boolean;
}

// Kişinin varsayılan çeşitleri (ClipVariety), sahnesiz: {öbek: klip anahtarı}, ara hareketler liste. Oyuncu karakterinde boş.
export type AnimAssigned = Record<string, string | string[]>;
// Sahnenin kişiye bugün oynattığı klipler: {sahne: {öbek: klip anahtarı}}.
export type AnimScenePicks = Record<string, Record<string, string>>;

export interface AnimCharacter {
  id: string;
  name: string;
  group: AnimGroup;
  bodyLabel: string | null;
  heightM: number | null;
  glbPath: string;
  glbUrl: string | null;
  glbExists: boolean;
  bytes: number | null;
  image: string | null;
  ready: boolean;
  statusLabel: string | null;
  clips: AnimCharacterClip[];
  assigned: AnimAssigned;
  scenePicks: AnimScenePicks;
  defaultClip: string | null;
}

export interface AnimPending {
  id: string;
  name: string;
  group: AnimGroup;
  // Tam gerekçe (manifestteki reason_tr; yoksa «Henüz hazır değil; …»).
  reason: string;
  // Kartın kısa etiketi: gerekçenin ilk virgül ya da noktalı virgül öncesi parçası («Meshy kuyruğunda», «Meshy modeli
  // hazır»); uzunsa sözcük sınırında kısaltılır, sonuna «…» gelir (pendingTag).
  tag: string;
  image: string | null;
}

export type AnimationsView =
  | { state: "missing"; file: string }
  | { state: "invalid"; file: string; error: string }
  | {
      state: "ok";
      file: string;
      updated: string | null;
      rule: string;
      ruleHref: string;
      credits: AnimCredits;
      groups: AnimClipGroup[];
      // Taşıyıcı iskeletlerin adları: {kimlik: görünen ad}.
      carriers: Record<string, string>;
      clips: AnimClipInfo[];
      characters: AnimCharacter[];
      pending: AnimPending[];
    };

const BODY_LABEL: Record<AnimBody, string> = { male: "Erkek", female: "Kadın", child: "Çocuk" };
const STATUS_LABEL: Record<string, string> = { missing: "GLB yok", error: "Dışa aktarılamadı", pending: "Meshy kuyruğunda" };

// ---------- Yardımcılar ----------

type Json = Record<string, unknown>;
const isObj = (v: unknown): v is Json => typeof v === "object" && v !== null && !Array.isArray(v);
const str = (v: unknown, fallback = "") => (typeof v === "string" ? v : fallback);
const num = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? v : null);
const arr = (v: unknown): unknown[] => (Array.isArray(v) ? v : []);
const strings = (v: unknown): string[] => arr(v).filter((x): x is string => typeof x === "string" && x !== "");

// Depo köküne göre yol; dışına çıkan ya da medya köklerinin dışında kalan yol verilmez.
function mediaPath(rel: string | null | undefined): string | null {
  if (!rel) return null;
  const clean = rel.replace(/\\/g, "/").replace(/^\/+/, "");
  const inside = path.relative(REPO_ROOT, path.resolve(REPO_ROOT, clean)).replace(/\\/g, "/");
  if (inside.startsWith("..") || !MEDIA_ROOTS.some((root) => inside.startsWith(root))) return null;
  return inside;
}

const exists = (rel: string | null) => !!rel && fs.existsSync(path.join(REPO_ROOT, rel));
const mediaUrl = (rel: string) => `/media/${rel.split("/").map(encodeURIComponent).join("/")}`;

// Kart görseli: varlıkların 320 piksellik küçük görseli (docs/assets/thumbs/<id>.webp) hafiftir; yoksa posterin .webp
// kardeşi, o da yoksa posterin kendisi; kuyruktakiler için ansiklopedi portresi.
function imageOf(id: string, poster: string | null): string | null {
  const thumb = `docs/assets/thumbs/${id}.webp`;
  if (exists(thumb)) return mediaUrl(thumb);
  const safePoster = mediaPath(poster);
  if (safePoster) {
    const webp = safePoster.replace(/\.png$/i, ".webp");
    if (webp !== safePoster && exists(webp)) return mediaUrl(webp);
    if (exists(safePoster)) return mediaUrl(safePoster);
  }
  for (const encId of [id, id.replace(/_/g, "-")]) {
    for (const file of ["portrait.webp", "portrait.png"]) {
      const rel = `docs/assets/encyclopedia/${encId}/${file}`;
      if (exists(rel)) return mediaUrl(rel);
    }
  }
  return null;
}

const normalGroup = (value: unknown, id: string): AnimGroup => {
  if (value === "player" || value === "named" || value === "crowd") return value;
  if (id === "mete" || id === "hero_f") return "player";
  return id.startsWith("crowd_") ? "crowd" : "named";
};

interface RawClip {
  key: string;
  tr: string;
  en: string;
  role: string;
  group: string;
  seat: AnimSeat | null;
  tags: AnimClipTags;
  meshyAction: number | null;
  kind: AnimClipKind;
  prompt: string | null;
  derived: { from: string; trimStart: number } | null;
  purchases: { character: string; credits: number }[];
  loop: boolean;
  seatLoop: boolean | null;
  travelM: number;
  note: string;
}

function readClip(raw: unknown): RawClip | null {
  if (!isObj(raw) || typeof raw.key !== "string" || !raw.key) return null;
  const tags = isObj(raw.tags) ? raw.tags : {};
  const derived = isObj(raw.derived) && str(raw.derived.from) ? { from: str(raw.derived.from), trimStart: num(raw.derived.trim_start) ?? 0 } : null;
  return {
    key: raw.key,
    tr: str(raw.tr, raw.key),
    en: str(raw.en),
    role: str(raw.role),
    group: str(raw.group, OTHER_GROUP) || OTHER_GROUP,
    seat: raw.seat === "ground" || raw.seat === "chair" ? raw.seat : null,
    tags: { body: strings(tags.body), age: strings(tags.age), style: strings(tags.style) },
    meshyAction: num(raw.meshy_action),
    kind: raw.kind === "rig" || raw.kind === "derived" ? raw.kind : "purchase",
    prompt: str(raw.prompt) || null,
    derived,
    purchases: arr(raw.purchases)
      .filter(isObj)
      .map((p) => ({ character: str(p.character), credits: num(p.credits) ?? 0 }))
      .filter((p) => p.character),
    loop: raw.loop !== false,
    seatLoop: typeof raw.seat_loop === "boolean" ? raw.seat_loop : null,
    travelM: num(raw.travel_m) ?? 0,
    note: str(raw.note_tr),
  };
}

function readCharacterClip(key: string, raw: unknown, fallbackLoop: boolean | undefined): AnimCharacterClip | null {
  if (!isObj(raw)) return null;
  return {
    key,
    source: raw.source === "retarget" || raw.source === "native_raw" ? raw.source : "native",
    donor: typeof raw.donor === "string" && raw.donor ? raw.donor : null,
    duration: num(raw.duration),
    frames: num(raw.frames),
    loop: typeof raw.loop === "boolean" ? raw.loop : (fallbackLoop ?? true),
    gameRole: raw.game_role === true,
  };
}

// Atama yalnız kütüphanede olan kliplerden: {öbek: anahtar}, ara hareketler liste.
function readAssigned(raw: unknown, known: Map<string, RawClip>): AnimAssigned {
  const out: AnimAssigned = {};
  if (!isObj(raw)) return out;
  for (const [group, value] of Object.entries(raw)) {
    if (typeof value === "string") {
      if (known.has(value)) out[group] = value;
    } else {
      const keys = strings(value).filter((k) => known.has(k));
      if (keys.length) out[group] = keys;
    }
  }
  return out;
}

// Sahne seçimi yalnız kütüphanede olan kliplerden: {sahne: {öbek: anahtar}}.
function readScenePicks(raw: unknown, known: Map<string, RawClip>): AnimScenePicks {
  const out: AnimScenePicks = {};
  if (!isObj(raw)) return out;
  for (const [scene, row] of Object.entries(raw)) {
    if (!isObj(row)) continue;
    const picks = Object.entries(row).filter((entry): entry is [string, string] => typeof entry[1] === "string" && known.has(entry[1]));
    if (picks.length) out[scene] = Object.fromEntries(picks);
  }
  return out;
}

const isAssigned = (assigned: AnimAssigned, key: string) => Object.values(assigned).some((v) => (Array.isArray(v) ? v.includes(key) : v === key));

// Öbekler sözleşmenin sırasıyla; sayı ve kredi kliplerden sayılır. Yazılı olmayan öbeğin klibi sona eklenir.
function readGroups(raw: unknown, library: RawClip[]): AnimClipGroup[] {
  const rows = arr(raw).filter(isObj).filter((g) => typeof g.key === "string" && g.key);
  const names = new Map(rows.map((g) => [String(g.key), str(g.tr, String(g.key))]));
  const live = new Set(rows.filter((g) => g.live === true).map((g) => String(g.key)));
  const order = [...names.keys()];
  for (const c of library) if (!order.includes(c.group)) order.push(c.group);
  return order.flatMap((key) => {
    const clips = library.filter((c) => c.group === key);
    if (!clips.length) return [];
    return [{
      key,
      tr: names.get(key) ?? (key === OTHER_GROUP ? "Öteki" : key),
      count: clips.length,
      credits: clips.reduce((sum, c) => sum + c.purchases.reduce((s, p) => s + p.credits, 0), 0),
      live: live.has(key),
    }];
  });
}

function readCredits(raw: unknown): AnimCredits {
  const credits = isObj(raw) ? raw : {};
  const motions = isObj(credits.motions) ? credits.motions : {};
  const spent = num(credits.spent_on_actions) ?? 0;
  const motionCredits = num(motions.credits) ?? 0;
  return {
    spent_on_actions: spent,
    purchases: num(credits.purchases) ?? 0,
    distinct_actions: num(credits.distinct_actions) ?? 0,
    duplicate_credits: num(credits.duplicate_credits) ?? 0,
    motions: { count: num(motions.count) ?? 0, credits: motionCredits },
    total: num(credits.total) ?? spent + motionCredits,
  };
}

// Kuyruktaki kartın kısa etiketi. Gerekçenin ilk virgül ya da noktalı virgül öncesi parçası alınır (ayraç içindeki
// virgül bölmez): «Meshy modeli hazır, iskelet (rig) görevi sürüyor; …» → «Meshy modeli hazır». Parça TAG_MAX
// karakterden uzunsa son sığan sözcükte kesilir ve «…» eklenir. Tam gerekçe kartta ekran okuyucuya, seçicinin altındaki
// listede herkese verilir.
const TAG_MAX = 28;
export function pendingTag(reason: string): string {
  let depth = 0;
  let end = reason.length;
  for (let i = 0; i < reason.length; i += 1) {
    const ch = reason[i];
    if (ch === "(") depth += 1;
    else if (ch === ")") depth = Math.max(0, depth - 1);
    else if (depth === 0 && (ch === "," || ch === ";")) {
      end = i;
      break;
    }
  }
  const head = reason.slice(0, end).trim().replace(/[.:]+$/, "");
  if (head.length <= TAG_MAX) return head;
  const space = head.lastIndexOf(" ", TAG_MAX);
  const cut = space > 0 ? head.slice(0, space) : head.slice(0, TAG_MAX);
  return `${cut.replace(/[\s,;:(]+$/, "")}…`;
}

// Karakterin açılış klibi: oyunda kullandığı bekleme klibi, yoksa oyunda kullandığı ilk klip, yoksa ilk klip.
function defaultClipOf(clips: AnimCharacterClip[], library: Map<string, RawClip>): string | null {
  const inGame = clips.filter((c) => c.gameRole);
  return (inGame.find((c) => library.get(c.key)?.role === "idle") ?? inGame[0] ?? clips[0])?.key ?? null;
}

// Tablonun notu: E9 paketinin her klipte yinelenen alım cümlesi atılır, alımı tablonun kendi sütunları söyler. Cümle bu biçimde
// değilse not olduğu gibi kalır.
function tableNote(note: string): string {
  return note
    .replace(/\s*E9 paketinde taşıyıcı iskelet için bir kez alındı \(toplu alım anim_batch_\d+\)(?:\.|; (\S))?/, (_, next: string | undefined) => (next ? ` ${next.toLocaleUpperCase("tr")}` : ""))
    .trim();
}

// ---------- Okuma ----------

// file: okunacak manifest (varsayılan sözleşmedeki yol); görünümdeki yol depo köküne göre yazılır.
export function readAnimations(file: string = MANIFEST_FILE): AnimationsView {
  const shown = path.relative(REPO_ROOT, file).replace(/\\/g, "/");
  if (!fs.existsSync(file)) return { state: "missing", file: shown };
  let data: unknown;
  try {
    data = JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (e) {
    return { state: "invalid", file: shown, error: e instanceof Error ? e.message : String(e) };
  }
  if (!isObj(data)) return { state: "invalid", file: shown, error: "Kök bir nesne değil." };

  const library = arr(data.clips).map(readClip).filter((c): c is RawClip => c !== null);
  const libraryByKey = new Map(library.map((c) => [c.key, c]));
  const rawCharacters = arr(data.characters).filter(isObj).filter((c) => typeof c.id === "string" && c.id);
  const rawPending = arr(data.pending).filter(isObj).filter((p) => typeof p.id === "string" && p.id);

  // Taşıyıcı iskeletin ham kimliği hiçbir yerde görünmez: yazılı değilse de genel adıyla anılır.
  const carriers: Record<string, string> = {};
  if (isObj(data.carriers)) {
    for (const [id, value] of Object.entries(data.carriers)) carriers[id] = (isObj(value) && str(value.tr)) || "Taşıyıcı iskelet";
  }
  const names = new Map<string, string>(Object.entries(carriers));
  for (const c of [...rawPending, ...rawCharacters]) names.set(String(c.id), str(c.tr, String(c.id)));
  const nameOf = (id: string) => names.get(id) ?? (id.startsWith("_") ? "Taşıyıcı iskelet" : id);

  // Kütüphanede olmayan ama bir karakterin taşıdığı klip (elle düzeltilmiş ya da eski dosya) görünür kalsın.
  for (const raw of rawCharacters) {
    if (!isObj(raw.clips)) continue;
    for (const key of Object.keys(raw.clips)) {
      if (libraryByKey.has(key)) continue;
      const stray = readClip({ key, purchases: [] });
      if (stray) {
        library.push(stray);
        libraryByKey.set(key, stray);
      }
    }
  }

  // Aynı kayıt (klibin taşıyıcıdan aktarımı her karakterde aynıdır) tek nesnedir: React istemciye giden veride yinelenen nesneyi
  // başvuruyla yazar, 15 karakter × 120 klip sayfayı 200 KB büyütmez.
  const sharedEntries = new Map<string, AnimCharacterClip>();
  const shared = (clip: AnimCharacterClip) => {
    const key = JSON.stringify(clip);
    const known = sharedEntries.get(key);
    if (known) return known;
    sharedEntries.set(key, clip);
    return clip;
  };

  const characters: AnimCharacter[] = rawCharacters.map((raw) => {
    const id = String(raw.id);
    const clipMap = isObj(raw.clips) ? raw.clips : {};
    const clips = library.flatMap((lib): AnimCharacterClip[] => {
      const clip = lib.key in clipMap ? readCharacterClip(lib.key, clipMap[lib.key], lib.loop) : null;
      return clip ? [shared(clip)] : [];
    });
    const glbPath = str(raw.glb);
    const safeGlb = mediaPath(glbPath);
    const status = str(raw.status, "ready");
    const body = raw.body === "male" || raw.body === "female" || raw.body === "child" ? raw.body : null;
    const poster = typeof raw.poster === "string" ? raw.poster : null;
    return {
      id,
      name: nameOf(id),
      group: normalGroup(raw.group, id),
      bodyLabel: body ? BODY_LABEL[body] : null,
      heightM: num(raw.height_m),
      glbPath,
      glbUrl: safeGlb ? mediaUrl(safeGlb) : null,
      glbExists: exists(safeGlb),
      bytes: num(raw.bytes),
      image: imageOf(id, poster),
      ready: status === "ready" && clips.length > 0,
      statusLabel: status === "ready" ? (clips.length ? null : "Klip yok") : (STATUS_LABEL[status] ?? status),
      clips,
      assigned: readAssigned(raw.assigned, libraryByKey),
      scenePicks: readScenePicks(raw.scene_picks, libraryByKey),
      defaultClip: defaultClipOf(clips, libraryByKey),
    };
  });

  const known = new Set(characters.map((c) => c.id));
  const pending: AnimPending[] = rawPending
    .filter((p) => !known.has(String(p.id)))
    .map((p) => {
      const id = String(p.id);
      // Gerekçe yazılmamışsa her zaman doğru olan söylenir; kuyruğun hangi adımı olduğu bilinmez.
      const reason = str(p.reason_tr).trim() || "Henüz hazır değil; gelince klipleriyle burada";
      return { id, name: nameOf(id), group: normalGroup(p.group, id), reason, tag: pendingTag(reason) || "Hazır değil", image: imageOf(id, null) };
    });

  const clips: AnimClipInfo[] = library.map((c) => {
    const holders = characters.filter((ch) => ch.clips.some((x) => x.key === c.key));
    return {
      key: c.key,
      tr: c.tr,
      en: c.en,
      group: c.group,
      seat: c.seat,
      tags: c.tags,
      meshyAction: c.meshyAction,
      kind: c.kind,
      prompt: c.prompt,
      derived: c.derived ? { ...c.derived, fromTr: libraryByKey.get(c.derived.from)?.tr ?? c.derived.from } : null,
      loop: c.loop,
      seatLoop: c.seatLoop,
      travelM: c.travelM,
      purchases: c.purchases.map((p) => ({ ...p, name: nameOf(p.character) })),
      role: c.role,
      note: tableNote(c.note),
      credits: c.purchases.reduce((sum, p) => sum + p.credits, 0),
      usedBy: holders.length,
      ownBy: holders.filter((ch) => ch.clips.some((x) => x.key === c.key && x.gameRole)).length,
      assignedTo: holders.filter((ch) => isAssigned(ch.assigned, c.key)).length,
    };
  });

  const rule = /^K\d{1,3}$/.test(str(data.rule)) ? str(data.rule) : "K90";
  return {
    state: "ok",
    file: shown,
    updated: str(data.updated) || null,
    rule,
    ruleHref: `${DECISIONS_HREF}#${rule.toLowerCase()}`,
    credits: readCredits(data.credits),
    groups: readGroups(data.groups, library),
    carriers,
    clips,
    characters,
    pending,
  };
}
