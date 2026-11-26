// Animasyonlar sayfasının saf kurallarının sınaması, bugünkü manifest.json ile: klip araması (anahtar yazıldığı gibi, belgelerin
// sözcükleri), oyuncu karakterinin çeşit almaması, sahnenin seçimi ve klibin kişideki yeri, döngü etiketi, kameranın geri çekilmesi,
// adresteki öbeğin açtığı klip, kaynak satırının dili. Tarayıcı açmaz, sunucu istemez.
// Kullanım (docs-app içinden): npm run animations
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { registerHooks } from "node:module";

const APP = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

// «@/» takma adı, src'nin uzantısız göreli içe aktarmaları ve JSON içe aktarması (Next çözer) düğüm için çözülür.
registerHooks({
  resolve(spec, ctx, next) {
    if (spec.startsWith("@/")) return next(pathToFileURL(path.join(APP, "src", `${spec.slice(2)}.ts`)).href, ctx);
    if (spec.startsWith("./") && !path.extname(spec)) {
      try {
        return next(`${spec}.ts`, ctx);
      } catch {
        /* uzantısız kalsın */
      }
    }
    return next(spec, ctx);
  },
  load(url, ctx, next) {
    if (url.endsWith(".json")) return { format: "module", shortCircuit: true, source: `export default ${fs.readFileSync(fileURLToPath(url), "utf8")}` };
    return next(url, ctx);
  },
});

const { readAnimations } = await import(path.join(APP, "src/lib/animations.ts"));
const { clipSourceParts, clipUses, isWideClip, loopText, matchesTokens, queryTokens, searchText, sourcePartsText, tagChips } = await import(path.join(APP, "src/components/animations/clip-text.ts"));
const { resolveSelection } = await import(path.join(APP, "src/components/animations/selection.ts"));

const view = readAnimations();
if (view.state !== "ok") {
  console.log(`manifest okunamadı: ${view.state} (${view.file})`);
  process.exit(1);
}
const { clips, groups, characters, pending, carriers } = view;
const groupName = new Map(groups.map((g) => [g.key, g.tr]));
const clipByKey = new Map(clips.map((c) => [c.key, c]));
const person = (id) => {
  const found = characters.find((c) => c.id === id);
  assert.ok(found, `${id} manifest'te yok`);
  return found;
};
const clipName = (key) => clipByKey.get(key)?.tr ?? key;
const search = (query) => {
  const tokens = queryTokens(query);
  return clips.filter((c) => matchesTokens(searchText(c, groupName.get(c.group) ?? ""), tokens)).map((c) => c.key);
};
const uses = (id, key) => {
  const character = person(id);
  return clipUses(character, character.clips.find((c) => c.key === key), groups, clipName).map((u) => u.text);
};
const opens = (character, group) => resolveSelection({ characters, pending, clips, groups }, { character, clip: null, group }).clipKey;

const tests = {
  "Her klibin anahtarı yazıldığı gibi aranınca klibi bulur": () => {
    for (const c of clips) assert.ok(search(c.key).includes(c.key), c.key);
    for (const key of ["idle_6", "proud_strut", "ground_side_sit"]) assert.deepEqual(search(key), [key]);
    assert.deepEqual(search("rev_stand_up_1"), ["rev_stand_up_1", "rev_stand_up_10"], "Sözcük parçası da eşleşir");
    assert.deepEqual(search("idle 6"), ["idle_6"], "Boşlukla da");
    assert.deepEqual(search("  IDLE_6 "), ["idle_6"], "Büyük harf ve boşluk");
  },
  "Türkçe harfsiz ve çok sözcüklü arama": () => {
    assert.ok(search("yuruyus kadin").includes("walking_woman"));
    assert.ok(search("yürüyüş kadın").includes("walking_woman"));
    assert.deepEqual(search("zzzyok"), []);
  },
  "Belgelerin öbek sözcükleri ve çiplerin türü bulunur": () => {
    const inGroup = (group) => clips.filter((c) => c.group === group).map((c) => c.key).sort();
    assert.deepEqual(search("kıpırdanma").sort(), inGroup("idle_fidget"), "K91: kıpırdanma, sayfada Ara hareket");
    assert.deepEqual(search("kütük").sort(), inGroup("sit_chair"), "K91: kütük ve tabure oturuşu");
    assert.deepEqual(search("oturakta").sort(), inGroup("sit_chair"), "K91: oturakta");
    for (const key of inGroup("sit_chair")) assert.ok(search("oturak").includes(key), `«Oturak: tabure» çipi: ${key}`);
    for (const key of inGroup("work")) assert.ok(search("iş ve selam").includes(key), `Varlık Hattı: iş ve selam: ${key}`);
    const seated = clips.find((c) => c.seat === "chair");
    assert.ok(tagChips(seated).some((chip) => chip.kind === "Oturak" && chip.label === "tabure"));
  },
  "Oyuncu karakteri çeşit almaz, sahnede seçimi yok": () => {
    const players = characters.filter((c) => c.group === "player");
    assert.deepEqual(players.map((c) => c.id), ["mete", "hero_f"]);
    for (const c of players) {
      assert.deepEqual(c.assigned, {}, `${c.id}: atama yok`);
      assert.deepEqual(c.scenePicks, {}, `${c.id}: sahne seçimi yok`);
    }
    for (const c of characters.filter((x) => x.group !== "player")) assert.ok(Object.keys(c.assigned).length > 0, `${c.id}: çeşitleri var`);
  },
  "Oyuncu karakterinde klibin yeri": () => {
    const mete = person("mete");
    const own = mete.clips.find((c) => c.gameRole);
    assert.deepEqual(uses("mete", own.key), ["Oyunda bu klibi oynar"]);
    assert.deepEqual(uses("mete", "proud_strut"), ["Bu kişiye atanmamış"]);
  },
  "Öbek bugün rolü olanla sahnesi olmayanı ayırır": () => {
    assert.deepEqual(groups.filter((g) => g.live).map((g) => g.key), ["idle_loop", "walk", "run", "sit_ground"]);
  },
  "Ateş başının beş oturuşu kişinin sayfasında oynar der": () => {
    const seats = { mother: "ground_kneel_heels", child: "ground_hug_knees", father: "ground_warm_hands", older_brother: "ground_one_knee", elder: "sit" };
    for (const [id, key] of Object.entries(seats)) {
      assert.equal(person(id).scenePicks.camp.sit_ground, key, `${id}: manifest`);
      assert.ok(uses(id, key).includes("Ateş başında oynar"), `${id}/${key}: ${uses(id, key)}`);
      assert.equal(opens(id, "sit_ground"), key, `${id}: Yerde oturma öbeği oynadığı klibi açar`);
    }
  },
  "Sahnede oynamayan varsayılan bunu söyler": () => {
    const mother = person("mother");
    const fallback = mother.assigned.sit_ground;
    assert.notEqual(fallback, "ground_kneel_heels");
    assert.deepEqual(uses("mother", fallback).filter((t) => t.startsWith("Sahnesiz")), [`Sahnesiz varsayılanı: Yerde oturma (ateş başında ${clipName("ground_kneel_heels")} oynar)`]);
    assert.ok(!uses("mother", fallback).includes("Ateş başında oynar"));
    const later = mother.assigned.sleep;
    assert.ok(uses("mother", later).includes("Sahnesi gelince: Uyku"), "Sahnesi olmayan öbek ayrı");
  },
  "Doğum sahnesinin klipleri": () => {
    assert.ok(uses("hereka_young", "ground_kneel_heels").includes("Doğumda oynar"));
    assert.ok(uses("lan_hatun", "sit").includes("Doğumda oynar"), "Lan Hatun'un kendi oturuşu");
    assert.ok(uses("teoman", "proud_strut").includes("Doğumda oynar"));
    assert.equal(person("teoman").scenePicks.birth.sit_ground, undefined, "Teoman doğumda oturmaz");
  },
  "Adresteki öbek kişinin oynadığı klibi açar": () => {
    const own = person("mete").clips.find((c) => c.gameRole && clipByKey.get(c.key)?.group === "idle_loop");
    assert.equal(opens("mete", "idle_loop"), own.key, "Mete kendi beklemesini oynar, çeşit almaz");
    assert.equal(opens("teoman", "walk"), "proud_strut", "Sahnenin seçimi");
    assert.equal(opens("crowd_hun_man", "walk"), person("crowd_hun_man").assigned.walk, "Sahnesi yoksa çeşit");
  },
  "Döngü etiketi klibin kendisini söyler": () => {
    assert.equal(loopText(true, null), "Döngülü klip");
    assert.equal(loopText(false, null), "Bir kez oynayan klip");
    const text = (key) => loopText(clipByKey.get(key).loop, clipByKey.get(key).seatLoop);
    assert.equal(text("ground_side_sit"), "Bir kez oynayan klip; oturma rolünde döngüye kapatılır");
    assert.equal(text("chair_sit_idle_f"), "Bir kez oynayan klip; oturma rolünde döngüye kapatılır");
    assert.equal(text("sit_arms_crossed"), "Bir kez oynayan klip; oturma rolünde son pozunda durur");
    assert.equal(text("sit"), "Döngülü klip");
    assert.equal(text("stand_up_1"), "Bir kez oynayan klip");
  },
  "Kamera geçişlerde ve yerinden giden klipte geri çekilir, oturuşta çekilmez": () => {
    for (const c of clips.filter((x) => x.group === "sit_ground" || x.group === "sit_chair")) assert.equal(isWideClip(c), false, c.key);
    for (const c of clips.filter((x) => x.group === "sit_down" || x.group === "stand_up")) assert.equal(isWideClip(c), true, c.key);
    assert.equal(isWideClip(clipByKey.get("idle_3")), false, "Döngülü");
    assert.equal(isWideClip(clipByKey.get("discuss_while_moving")), true, "Yürüyerek gider");
    assert.equal(isWideClip(clipByKey.get("wave_one_hand")), false, "Yerinde el sallar");
    assert.equal(isWideClip(undefined), false);
  },
  "Metinden hareketin istemi kaynak satırında İngilizce işaretli": () => {
    const context = { nameOf: (id) => id, carriers: Object.fromEntries(Object.entries(carriers)) };
    const clip = clipByKey.get("ground_side_sit");
    const entry = person("mother").clips.find((c) => c.key === clip.key);
    const parts = clipSourceParts(entry, clip, "mother", context);
    assert.equal(parts.filter((p) => p.lang === "en").length, 1, "İstem tek parça");
    assert.ok(parts.find((p) => p.lang === "en").text.startsWith(clip.prompt.slice(0, 20)));
    assert.ok(sourcePartsText(parts).includes("Metinden üretildi (istem: «"));
    assert.ok(sourcePartsText(parts).endsWith("."), "Cümle biter");
    const store = clipByKey.get("idle_6");
    const plain = clipSourceParts(person("mother").clips.find((c) => c.key === store.key), store, "mother", context);
    assert.ok(plain.every((p) => !p.lang), "İstemsiz klipte dil işareti yok");
  },
};

let failed = 0;
for (const [name, run] of Object.entries(tests)) {
  try {
    run();
    console.log(`  ✓ ${name}`);
  } catch (error) {
    failed += 1;
    console.log(`  ✗ ${name}\n      ${error.message.split("\n").join("\n      ")}`);
  }
}
console.log(`${Object.keys(tests).length} sınama, ${failed} başarısız`);
process.exit(failed ? 1 : 0);
