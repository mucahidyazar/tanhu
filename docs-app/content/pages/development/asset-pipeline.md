---
title: Varlık Hattı
order: 30
status: kismen
summary: "Her varlık en mantıklı yoldan gelir: kod varsayılandır, adlı kişi ve tekil nesne Meshy'den, iskelet işi Blender betiğinden, tekil yaratık rigi Tripo'dan, simge ve kişi görseli yalnız 2B; gpt-image-2 kredisizdir, kredi harcayan her iş önce sorulur."
sources:
  - docs/research/varlik-hatti.md
  - docs/design/godot.md
  - docs/design/decisions.md
  - docs/design/companions.md
  - docs/design/fauna.md
  - docs/design/d3/register.md
  - docs/assets/catalog.json
  - game/tools/asset_plan.json
  - game/tools/meshy_pipeline.py
  - game/tools/rig_fix.py
  - game/tools/paint_face.py
  - game/tools/blender/quadruped_rig.py
  - game/tools/blender/quadruped_sheep.json
  - game/data/rig_calibration.json
  - game/data/clip_library.json
  - game/data/clip_library_measure.json
  - game/tools/anim_library_import.gd
  - game/scripts/character/clip_variety.gd
  - docs-app/scripts/concepts.mjs
  - docs-app/scripts/intro-voices.mjs
  - docs-app/content/encyclopedia.json
---

## Özü

Oyunun her görseli, modeli ve sesi bir varlıktır. Her varlık için önce 2B konsept çizilir (gpt-image-2), sonra beş yoldan biri seçilir: programatik, Meshy, Blender, Tripo ya da yalnız 2B. Kod varsayılandır; yapay zekâ modeli yalnız kodun zayıf kaldığı yerde, yakın planda görünen organik ve tekil nesnede kullanılır. gpt-image-2 kullanıcının ChatGPT planıyla çalışır, kredi harcamaz ve sorulmadan üretilir (E2, E5). Meshy, Tripo ve ElevenLabs kredi harcar: her toplu üretim önce adet, sınıf ve toplam krediyle kullanıcıya sorulur ([K66](/docs/source/design/decisions#k66)).

Bütün varlıklar türe göre ayrı tablolarda [Varlıklar](/assets) sayfasındadır: görsel, 3B gerekli mi, 3B'si var mı, en mantıklı yol ve Meshy'nin en kaliteli en son modeliyle bedel. Bu sayfa o tabloların arkasındaki kuralı anlatır. Kaynak [varlik-hatti.md](/docs/source/research/asset-pipeline) ve [godot.md §6](/docs/source/design/godot#6-varlik-hatti)'dır.

> [!NOT]
> ayrica asssetler icinde bir sayfa veya sayfalar koyup sidebarda goster web sitesinde, gpt-image-2 ile uret, asset icin urettigin resimleri kullanarak gerekirse meshy den assetleride uretebiliyor olabilelim.
>
> ve meshy ile en kaliteli sekilde uretiminde isteyecegi krediyi goster
>
> 3d asset uretimi icin en mantikli yol ney onuda belirt tabloda her asset icin, programatik veya blender mcp veya meshy veya tripo gibi
>
> ama hepsinin meshy en kaliteli en son model ile uretim maliyeti ne kadar onu soyle

## Beş yol

| Yol | Ne için | Godot'ya giriş | Bedel |
|---|---|---|---|
| Programatik | Durum taşıyan ve çok tekrarlanan her şey: kurulan yurt, aşamalı yapı, teker, çit, düğüm, kalabalığın uzak katı, kuş, küçük memeli, etki, kodla basılan müzik | `Procedural3D`, `MeshKit`, `TreeKit`, `MultiMesh`, parametrik `Yurt`; pişirme aracıyla `.res` | 0 |
| Meshy | Adlı kişi, kalabalık tabanı, tekil yapı kabuğu, ünlü silah, hikâye eşyası, kamp eşyası, hayvan ağı | `meshy_pipeline.py`, `glb_prepare.py`, `prepare_character.py` → `assets/<tür>/<id>/` | Statik 40, rigli insan 45, ek hareket 3, çeşit 15 |
| Blender | Son işçi: dört ayaklıya iskelet ve klip, uzun giysinin ağırlığı, 8K kopyadan oyun dokusuna pişirme, aşama kitini parçalara ayırma | Başsız betik `tools/blender/*.py` → GLB | Kredi yok; emek |
| Tripo | Tekil, insan olmayan yaratıkta API rigi (dört ayaklı, kuş) | GLB; iskelet Blender'da düzeltilir | Rig 25, hareket 10 Tripo kredisi |
| Yalnız 2B | Simge, beceri, durum, portre, kişinin art, profil ve T-pozu, keçe pano, Meshy'nin konsept girdisi | `assets/icons/`, `assets/ui/encyclopedia/`, `assets/_concepts/` | 0, plan kotası |

**Programatik.** Godot'da kodla üretim bugün çevre, yedek görünüş ve efekttir: çayır, çakıl, dağ, arazi, su (`meadow.gd`, `mountains.gd`, `terrain.gd`, `water.gd`), alev, duman, gök gölgelendiricileri, keçe ve halı deseni. Meshy modeli yoksa yurt, ahır, at ve eşya kodla çizilen sade sürüme düşer (`MeshyProp.has_model`). Kod şu dört yerde en mantıklıdır: durum taşıyan (kurulan ve sökülen yurt, tükenen düğüm), çok tekrarlanan (sürü, kalabalık, uzak orman), kuralla oynayan (kanat, kuyruk, bayrak) ve küçük görünen. Varsayılan 28 m'de 1080p ekranda 1 m ≈59 pikseldir ([K98](/docs/source/design/decisions#k98)): kılıç ≈57 piksellik bir çizgidir, boyalı süzgeç ince ayrıntıyı zaten siler. Yurdun 13 adımı tek ağdır: her parça köşesinde aşama numarasını taşır, gölgelendirici `stage`'in üstündekileri çökertir, yapı başına çizim eklemez. Üç boy kök ölçektir (×0,7, ×1, ×1,4), millet `YurtStyle`'dan gelir, yeni doku yoktur (K51).

**Blender.** Üretici değil, Meshy ile Godot arasında son işçidir. Tekrarlanacak iş başsız betik olarak yazılır (`Blender -b --python tools/blender/<iş>.py`); MCP yalnız tek seferlik bakış ve deneme içindir, çünkü `.blend` ikilidir ve tekrar üretilmez. MCP güvenli kipte (`BLENDER_MCP_SAFE_MODE=1`), telemetri kapalı (`DISABLE_TELEMETRY=true`) ve yalnız `localhost` üstünde çalışır. Tanhu 1'in at betiğinden yalnız yöntem alınır: ağ konuma göre kaynaştırılır, ağırlık bölge maskesiyle verilir. Automatic Weights kullanılmaz, çünkü Meshy'nin ağı UV dikişlerinde binlerce adaya bölünür ve orada tutmaz.

**Tripo.** H3.1'in en kaliteli statik ağı 70 kredidir ($0,70); bizde ağ için değil, rig için düşünülür. Rig 25 kredi, hazır hareket başına 10 kredidir (1 kredi $0,01). Dört ayaklıda tek hazır hareket yürüyüştür, kuşta hazır hareket yoktur: dur, otla, tırıs, dörtnal yine elle ya da kodla yapılır. Bu yüzden yalnız devenin karşılaştırma denemesinde ve tek yürüyüşün yettiği tekil yaratıkta kullanılır.

**Yalnız 2B.** `game/tools/imagegen/gen.sh` Codex CLI'nin görsel aracını kullanıcının ChatGPT oturumuyla sürer; referans görselle de çalışır. Kota yayımlı değildir, dolunca betik durur ve kaldığı yerden sürer. Godot'da 26 konsept ve iki yeniden deneme ≈37 dakikada çıktı (görsel başına ≈58–79 sn).

Örnekler, yola göre:

```varlik
mete, mother, elder, horse_brown, yurt, stable, campfire, pine_a
otag_hun, yurt_hun_small, wheel_pair, crow, marmot, fx_campfire_flame, meadow_grass
hun_pony, camel
skill_tree_bow, status_kut, portrait_mete, ui_logo
```

## Meshy'nin en kaliteli en son modeli

En son ve en kaliteli model `meshy-7.1`'dir (2026-09-18; `latest` buna gider). Kredi sütunu her satırda bu modelle bedeldir, en mantıklı yol başka olsa bile. Fiyat API'nin fiyat sayfasındandır, 2026-10-12 tablosu 2026-11-04'te aynı bulundu; ilk turun 26 iş kaydı aynı sayıları yazdı ([varlik-hatti.md §1.3](/docs/source/research/asset-pipeline#1-3-kredi-tablosu-dogrulanmis)).

**Ayar** (`asset_plan.json` `meshy_defaults`): görselden 3B, tek görsel, `ai_model: "meshy-7.1"`, `geometry_resolution: "4k"`, `texture_resolution: "8k"`, `should_remesh: true` ve `topology: "triangle"` (oyun ağına indirme üretimin içinde, ek kredi yok; satırın `polycount`'u hedeftir), `image_enhancement: false` (boyalı görsel olduğu gibi kalır), `enable_pbr: false`, çıktı GLB; insanda `pose_mode: "t-pose"`, rig ve plandaki klipler. Araştırma en kaliteli ayara `texture_model: "meshy-7"`'yi de ekler (8K ve PBR, kredi değişmez); ilk turun 26 işi bu parametre çıkmadan önce, 25 Ekim'de üretildi. Çoklu görselde 4K geometri yoktur, `2k` ile yine 40 kredidir.

| İş | API kredisi | Not |
|---|---|---|
| Görselden 3B, yalnız ağ | 20 | `meshy-7.1` ve `meshy-6` |
| + 2K ya da 4K doku | 30 | |
| + 8K doku | 35 | 8K'da emisyon haritası yok |
| Ultra geometri (`4k`) | +5 | Yalnız 7.1 |
| **En kaliteli statik varlık** | **40** | Godot'daki 23 statik iş 40'ar yazdı |
| Rig (yürüme ve koşu içinde) | 5 | Yalnız dokulu insansı; dört ayaklı API'de riglenmez |
| Ek hareket | 3 / eylem | Çağrıda ≤10; kütüphanede 600'den çok insan klibi, at binme yok |
| Retexture (çeşit) | 10; 8K 15 | `enable_original_uv: true`; ağ ve rig yeniden ödenmez |
| Ayrı Remesh, UV Unwrap | 5, 5 | Yalnız sonradan yeniden indirmede ya da dokusuz ağda |
| Metinden hareket | `prime` 10, `swift` 3 | 2–10 sn, yalnız insan |
| `meshy-t2.5` (doğrudan düşük üçgen) | Ağ 5; 2K/4K 15; 8K 20 | Küçük eşya ve sıradan silah için oyuna yeten yol |
| Biçim çevirme, boy değiştirme | 1 | |

**Sınıf başına bedel** (sitedeki kredi sütunu bundan hesaplanır, elle yazılmaz): statik 40; rigli insan 45; ek klip 3 (aynı klip başka Meshy insanına `ClipRetarget` ile 0); on klipli insan 75; hayvan ağı 40 (iskeleti Blender betiği 0, Tripo yolu ayrıca 25 + 10 Tripo kredisi, $0,35); küçük eşya T2.5 ile 20 (8K) ya da 15; çeşit 15; 3B gerekmeyen 0.

**Planlar ve dolar.** Pro $20 / ayda 1.000 kredi, Premium $40 / 3.000, Ultra $100 / 8.000, Studio $70 / 5.500 havuz. En kaliteli statik varlık (40 kredi) Pro'da $0,80, Premium'da $0,53, Ultra'da $0,50 eder. Aylık kredi devretmez, satın alınan kredi süresizdir. Başarısız iş 0 kredidir, beğenilmeyen sonuç ücretlidir: toplama ×1,3 beğenmeme payı eklenir. Ücretli planda çıktı müşterinindir; API dosyaları 3 gün durur, bu yüzden sonuç hemen indirilir ve ham kopya saklanır.

**Toplamlar.**

| Hesap | Kredi |
|---|---|
| İlk tur, 25–26 Ekim (26 model × 40, 6 rig × 5, 8 hareket × 3) | 1.094 |
| Önsöz'ün işleri, 2026-11-05 (12 model × 40, 9 rig × 5, 2 Retexture × 15) | 555 |
| Animasyon çeşitliliği paketi, 2026-11-05 (100 hareket × 3, 9 metinden hareket × 13, taşıyıcı iskelet 5) | 422 |
| `meshy-t2.5` denemesi, 2026-11-06 (Baba: model 15, rig 5; E11.4) | 20 |
| Çocukluk'un işleri, 2026-11-07 (küçük Mete, çocuk Yançi ve Luhun 3 × 45, koyun 40, yay nişanı 3; E14) | 178 |
| Zıplama klibi, 2026-11-07 (Regular Jump, 1 hareket × 3; E16) | 3 |
| Yola Çıkış'ın kişileri, 2026-11-07 (Yançi, Eskam, Huyan Hatun, Gutu 4 × 45; E17) | 180 |
| Kışlak'ın üretimi, 2026-11-08 (dokuz kişi 9 × 45, deve ve keçe araba 2 × 40, köpek, maral, kurt, ceylan, sığır 5 × 40, Atşo ve Kujul'un iskeletinin yenilenmesi 2 × 5; E19) | 695 |
| Meshy görevlerinin kaydı, toplam | 3.147; toplam sınırı yok (K94) |
| Araştırmanın 449 3B adayı, hepsi en kaliteli Meshy ile | ≈18.210 ($228–364) |
| Godot için önerilen karma (her satır en mantıklı yoldan) | ≈9.714; ×1,3 payla ≈12.628 ($158–253) |
| Varlıklar sayfası, 2026-11-05: 1.044 satırın hepsi Meshy ile | 22.809 |
| Aynı gün: 3B gereken 514 satırdan modeli olmayanlar | 16.825 |

Önerilen karma Premium'da beş ay ya da Ultra'da iki ay ($200) eder. Varlıklar sayfasının sayıları katalog büyüdükçe kendiliğinden değişir.

## Hangi tür hangi yolla

Karar matrisi Godot içindir ([varlik-hatti.md §8](/docs/source/research/asset-pipeline#8-karar-matrisi)); yol sütunundaki ilk ad varsayılandır.

| Tür | 3B gerekli mi | En mantıklı yol | Neden |
|---|---|---|---|
| Mete ve adlı kişi | Evet | Meshy (görselden, rigli); ortak klip `ClipRetarget` ile | Hat, ölçüm aracı ve klip aktarımı hazır; kişi başına iş uzun giysi ağırlığı ve omuz açısıdır |
| Kalabalık tipi | Evet | Meshy taban insanı + Retexture çeşidi; uzakta `MultiMesh` | Kemikler işlemcide hesaplanır, binlerce iskelet olmaz; çeşit ağ ve rig ödemez |
| Evcil ve yaban dört ayaklı | Evet | Meshy ağı + başsız Blender betiğiyle iskelet ve yürüyüş; uzak sürü `MultiMesh` | Meshy API hayvan riglemez, Tripo yalnız yürüyüş verir; betik kredisiz ve tekrar üretilir |
| Küçük memeli, kuş | Evet, küçük | Programatik; eldeki kartal Meshy ağı ve gölgelendirici | Gökte ve yerde küçük; kanat GPU'da çırpar |
| Kurulan yurt ve çadır | Evet | Programatik (kültür, boy, aşama); menü, sinema ve uzak kamp için millet başına Meshy kabuğu | Aşama, söküm, hasar ve oda kesiti durum taşır, Meshy tek ağ verir |
| Kalıcı yapı | Evet | Meshy kabuk + kodla iskele ve aşama örtüsü | Görünüş Meshy kampıyla eşleşir, aşama kod işidir |
| Araba | Evet | Meshy gövde + kodla teker ve oklar | Teker ayrı dönmeli |
| Silah, alet | Evet, küçük | Meshy T2.5; ünlü silahta 7.1; elde `BoneAttachment3D` | 28 m'de küçük; yakından yalnız oluşturucuda ve Destan Kitabı'nda görünür (K98) |
| Zırh ve giysi | Kısmen | Gövdede Retexture çeşidi; başlık, sadak, kın ayrı Meshy ağı; heybede simge | Meshy insanı tek ağdır, giysi ayrı parça değildir |
| Eşya, malzeme, yiyecek | Çoğu hayır | Yalnız 2B simge; dünyada az sayıda ortak yığın Meshy | Hepsi Meshy olsa eşyada 4.160 kredi boşa gider |
| Ağaç ve kaya | Evet | Kahraman tür Meshy + `TreeKit` pişirmesi; çok tekrarlanan kodla | Köşe rengi UV istemez, `MultiMesh` kare başına tek çizim |
| Beceri, durum, arayüz, portre | Hayır | Yalnız 2B; arayüz ögesi kodla çizilir | Düz simge 48 ve 28 pikselde okunur |
| Efekt, müzik, efekt sesi | Hayır | Programatik (gölgelendirici, `GPUParticles3D`, başsız ses aracı) | Ağ değil, zamanlı çizim ve kodla basılan ses; söz ve şarkı ElevenLabs'tendir |

Katalogda 2026-11-05'te 1.044 satır vardır: 325'i Meshy, 303'ü programatik, 415'i yalnız 2B, 1'i Blender yolundadır; 397'sine 3B gerekir, 117'sine kısmen, 530'una gerekmez. Türlerin tabloları: [Kişiler](/assets/characters), [Kalabalık](/assets/crowds), [Evcil hayvanlar](/assets/livestock), [Yaban hayvanları](/assets/wildlife), [Yurtlar](/assets/yurts), [Silahlar](/assets/weapons), [Doğa](/assets/nature), [Beceri simgeleri](/assets/skills), [Ses](/assets/audio).

## Onay ve .ok akışı

1. **Satır.** Varlık kataloğa girer (`docs/assets/catalog.json`: `id`, grup, ad, perde, 3B gereği, yol, kredi, istem, öncelik). 3B'si olacaksa `game/tools/asset_plan.json`'a da satır olur: `id`, `kind`, `dir`, `height_m`, `polycount`, `animations`, `refs`, `prompt`.
2. **Konsept.** `npm run concepts` eksik konseptleri üretir: önceliği 1 olan 200 satır, `--all` ile 792 öncelik 2 satırı da; `--only=a,b`, `--group=<grup>`, `--jobs=3`. İstem satırın kendisi, `style_suffix` ve insanda `character_suffix`'tir; referans `style_mete.png` ve `style_camp.png`. Çıktı `game/assets/_concepts/<id>.png` (`.gdignore`'lı, Godot içe aktarmaz); sitenin 320 piksellik küçük görseli `docs/assets/thumbs/<id>.webp`. `--thumbs` yalnız küçük görselleri yeniden yazar. Var olan konsepte dokunulmaz.
3. **Kabul** ([varlik-hatti.md §6.5](/docs/source/research/asset-pipeline#6-5-meshy-ye-girmeden-kabul)). Yedi kural: tek nesne ve düz zemin; tam silüet ve kenar payı; gölge ve ışık yönü yok; kol, bacak ve gövde arası boşluk görülür; dönem dışı nesne yok (üzengi, modern kumaş); ince kıl ve ip yok, ≥15 cm okunur ayrıntı; metin, damga, çerçeve yok.
4. **Onay.** Kullanıcı görseli [Varlıklar](/assets) sayfasında görür ve onaylar; onayın izi konseptin yanındaki `<id>.ok` dosyasıdır.
5. **Kredi sorusu.** Üretimden önce adet, sınıf ve toplam kredi sorulur. `meshy_pipeline.py` her işten önce yeni bedeli canlı bakiyeyle karşılaştırır, yetmiyorsa durur. Toplam harcama sınırı yoktur ([K94](/docs/source/design/decisions#k94)).
6. **Üretim.** `tools/meshy_dispatch.py` yalnız `.ok`'lu konsepti `meshy_pipeline.py run <id>`'ye verir, aynı anda en çok 8 iş. Görev kimliği `meshy.json`'a yazılır ve bir daha açılmaz; zaman aşımına uğrayan istek «belirsiz» işaretlenir ve elle denetlenir, çift ücret olmasın. Model işi 124–559 sn sürdü (ortanca 326).
7. **Ham kopya.** 8K ana kopya, iş kayıtları ve önizlemeler `assets/_meshy_raw/<id>/`'de kalır (`.gdignore`). Yeniden üretim yeniden ödemedir.
8. **Hazırlık.** `glb_prepare.py` dokuyu küçültür, ağa ve iskelete dokunmaz. Yüzü okunmayan kişide `paint_face.py` kaynak görselin yüzünü ağın önüne dik izdüşümle 8K dokuya boyar (kredisiz; ağ, UV, iskelet ve klipler aynı kalır, `--undo` geri alır), `glb_prepare.py` boya varsa hamın yerine onu küçültür. Ayar kişinin `assets/_meshy_raw/<id>/face_paint/paint.json`'udur: kaynak kutusu ve boyanan çokgen (yumuşatma `feather_px`), eşleme (göz çizgisinin ortası, piksel/metre), kaynaktan silinen izler (`source_cleanup`), ten eşitlemesinin bandı (`match_band`), renk çarpanı (`tints`), çizgi (`strokes`), iris, keskinleştirme (`sharpen`), koyu rengin tene açılması (`dark_lift`). 2026-11-07'de Çocukluk'un çocukları için üç ayar eklendi: `hair_guard` (bu çokgenlerde ham dokunun koyu pikseli boyanmaz, saç çizgisi hamdaki gibi kalır), `cleanup_min_luma` (dolgunun okuduğu tenin en düşük parlaklığı: saç gölgesi dolguya sızmaz) ve `warp_y` (ağın alt yüzü konseptten kısaysa düşey eşleme parça parça kurulur; Yançi'nin çenesi ≈18 mm kısaydı). Bugün boyalı yüzler: Ağabey, küçük Mete, çocuk Yançi, Luhun ([önce, sonra ve konsept](/media/docs/media/review/cocuk_yuzleri.jpg)), Gutu ve Huyan Hatun ([Yola Çıkış'ın yüzleri](/media/docs/media/review/yola_cikis_yuzleri.jpg)). 2026-11-08'de `self` kaynağı eklendi: kaynak ağın kendi 8K yüzüdür, yalnız lekenin çevresindeki tenle doldurur (Gutu'nun burun altı lekesi, Huyan Hatun'un çenesine inen açık şerit); konsept ağzı açık ya da dörtte üç bakan yüzlerde bu yol kullanılır. İnsanda `prepare_character.py` klipleri `<id>_<rol>.res` olarak ayırır; `character_fit_tool.gd` zemin kaydırmasını, adım hızını ve omuz açısını `<id>_fit.json`'a, oyuncu karakterinde `bake_regions.py` renk maskesini yazar.
9. **Sahne.** `MeshyProp` (statik), `CharacterAvatar` (insan), `Horse` (at); model yoksa kodla yedek.

**Bugün.** `asset_plan.json` 43 satırdır: 42'si Meshy yolunda, biri programatik. Hepsinin oyun dosyası vardır. İlk turun 26'sı kampın 6 kişisi, 2 atı, 2 yapısı, 12 eşyası ve 4 doğa nesnesidir. Önsöz'ün 12 modeli 2026-11-05'te üretildi (E7.6–E7.9) ve 2026-11-06'da oyuna takıldı: dokuz kişi ([Teoman](/encyclopedia/teoman), [Lan Hatun](/encyclopedia/lan-hatun), Ağabey, [Hereka](/encyclopedia/hereka), 39 yaşındaki Hereka, Sayıcı, Hun Erkeği, Hun Kadını, Hun Atlısı), kopuz, beşik ve kundak. Beşiğin kemerine kaynamış yay, sadak ve ipler ağdan kesildi, kendi satırı oldu (`cradle_bow`; programatik satır budur, kredisizdir, `tools/glb_split_region.py`). Kopuzun ağında dört tel izi vardı; oyun kopyası `tools/kopuz_three_strings.py` ile kredisiz üç tele indi, ham dosya değişmedi. Hun Yaşlısı II. Perde'ye kaldı.

**Çocukluk'un modelleri (2026-11-07, E14).** Kullanıcının «Yançi ve Luhun da, 178» onayıyla doğrudan API'den: küçük Mete (`mete_child`, 1,10 m), çocuk Yançi (`yanchi_child`, 1,08 m) ve Luhun (`luhun_child`, 1,15 m) insan sınıfıdır (model 40, iskelet 5; meshy-7.1, 8K doku, Ultra geometri; 41,4k–41,7k üçgen); koyun (`sheep`) hayvan ağıdır (40; 31,4k üçgen). Yançi ve Luhun kendi modelidir, çünkü katalogdaki Retexture yolu Hereka'da iki kez soluk yüz vermişti. Üç çocuk iskelet düzeltmesinden ve parmak betiğinden geçti (küçük Mete 20 parmak kemiği; Yançi ve Luhun 16, serçesiz), klipleri kütüphaneden alır (bağışçılar bekleme `hero_f`, oturma `mother`), yürüme ve koşu kendi iskeletlerindendir. Yayın nişanı kütüphaneye bir kez alındı (`bow_aim`, 3). Yüzleri kredisiz boyandı, oyun dokusu `hero` sınıfına geçti (aşağıda «Oyuna giriş kuralları»). Koyunun iskeleti ve klipleri Blender betiğindendir (aşağıda «Dört ayaklılar»).

```varlik
teoman, lan_hatun, older_brother, hereka, hereka_young, counter
crowd_hun_man, crowd_hun_woman, crowd_hun_rider, kopuz, cradle, swaddled_baby
```

Meshy görevlerinin kaydı 3.147 kredidir (2.091'e onaylardan sonra Çocukluk'un 178'i, zıplama klibinin 3'ü, Yola Çıkış'ın dört kişisinin 180'i ve Kışlak'ın 695'i eklendi): Önsöz'ün işleri, animasyon paketi, `meshy-t2.5` denemesi ve Çocukluk'un işleri kullanıcının onayıyla Meshy MCP'si ve doğrudan API ile açıldı, araçtan geçmedi. Toplam sınırı kullanıcı kaldırdı ([K94](/docs/source/design/decisions#k94)); her toplu üretim yine ayrıca sorulur. Onay bekleyen kredi işleri [Karar Bekleyenler](/docs/general/pending-decisions)'dedir: toplu üretimden önceki üç deneme (deve, keçe araba, uzun kaftanlı adlı kişi) Meshy 128 ve Tripo 35; ilk 12 hayvan türünün kalanı 240; yoldaşlar ≈840, boyalı donlarla ≈1.035.

```varlik
mete_child, yanchi_child, luhun_child, sheep
camel, cart_felt
```

**Yola Çıkış'ın modelleri (2026-11-07, E17).** Kullanıcının «Dördü de, 180» onayıyla doğrudan API'den: Yançi (`yanchi`, 1,60 m), Eskam (`eskam`, 1,66 m), Huyan Hatun (`huyan_hatun`, 1,62 m) ve Gutu (`gutu`, ≈1 yaşında, 0,80 m) insan sınıfıdır (model 40, iskelet 5; meshy-7.1, 8K doku, Ultra geometri). Dördü iskelet düzeltmesinden, etek alanından (`garment_weights.json`) ve parmak betiğinden geçti; Huyan Hatun'un yürüyüşü zincir oranı adımıyla düzeldi (aşağıda «İskelet düzeltmesi»). Yançi, Huyan Hatun ve Gutu `hero` (2048) doku sınıfındadır (kişi başına ≈4 MiB VRAM), Eskam `named` (1024). Bekleme klibi bağışçıdandır: Yançi ve Huyan Hatun `hero_f`, Eskam `mete`, Gutu `hero_f`; oturma Yançi ve Huyan Hatun'da `mother`, Eskam'da `elder`, Gutu'da `child`. Site oynatıcısına 2026-11-08'de girdiler (`clip_library_export.gd`, 22 karakter).

```varlik
yanchi, eskam, huyan_hatun, gutu
```

**Kışlak'ın modelleri (2026-11-08, E19).** Kullanıcının «Dokuzu da, 405» ve «Denemeler, sonra altısı: 320» onayıyla, dört hesaba dağılarak: Amaga, Farnak, Nanay, Ardokşa, Kantu, Mene, Palak, Atşo ve Kujul insan sınıfıdır (meshy-7.1, 8K doku, Ultra geometri, hedef 28k üçgen: 26,8k–29,1k, iç harita hedefinde, Decimate gerekmedi; `named` 1024 doku). Dokuzu iskelet düzeltmesinden (dokuzunda etek satırı), parmak betiğinden (çoğunda 20 kemik; Kujul 16, Amaga 12), klip aktarımından ve ölçümden geçti; site oynatıcısı 31 karakter. Klip profilleri: Amaga ve Kantu `elder`, Palak ve Farnak `warrior`, Atşo `ceremony`. Açık: Atşo'nun iskeleti Meshy'den başka bir biçimde geldi (kalibrasyon sapması 2,24°, ikizde bilek 8,5 cm), Kujul'un ağı kollar ≈30° aşağıda üretildi (bilek 4,4 cm, diz çökmede 0,58), Nanay'ın diz çökmesinde dizler dar (0,73, sınır 0,75): Atşo ve Kujul'un iskeleti onayla yenilendi (2 × 5) ama Meshy aynı model görevinden aynı iskeleti verdi; Nanay `rig_fix`'te uyluk payının alt sınırı 0,495 → 0,50 ile düzeldi (diz çökmede 0,73 → 0,79), Atşo ve Kujul için kredisiz `rig_fix` adımları sürüyor. Deve denemesi tuttu ve türün kendisi oldu (30 deforme kemik, beş klip, hörgüç 2,30 m, uzak ağ 1.599 üçgen); keçe araba gövdesi Yola Çıkış'ın kod tekerleğine oturur (`tools/cart_body.py`, 20,2k üçgen). Köpek, maral, kurt, ceylan ve sığır aynı yoldan (`tools/blender/quadruped_*.json`, uzak ağlar 999–1.500 üçgen). `quadruped_rig.py`'ye beş isteğe bağlı alan eklendi (mutlak omuz ve kalça eklemi, toynak tohumları, boynuz için ek baş elipsoidi, gövde burguları, ayağın yanı); atın ve koyunun çıktısı bayt bayt aynı. Tripo karşılaştırması onaylanmadı.

```varlik
amaga, farnak, nanay, ardoksha, kantu, mene, palak, atsho, kujul
camel, cart_felt
```

## Oyuna giriş kuralları

Dokular VRAM sıkıştırmalı ve oyun boyundadır ([godot.md §6.2–§6.5](/docs/source/design/godot#6-2-ice-aktarma-kurallari)). İlk turun 30 dokusunun 26'sı renk dokusudur ve aşağıdaki sınıflardadır; öteki dördü Mete'nin ve `hero_f`'in renk bölgesi maskesidir (2048², kişi başına iki), kayıpsız kalır. Önsöz'ün modelleri aynı sınıflarla girdi (`texture_class`: kişi 1024² BC7, Lan Hatun ve Ağabey 2048² BC7, eşya 1024² ya da 512² BC1). `hero` sınıfı (2048² BC7) bugün yedi kişidir: Mete, oyuncu kahramanı (`hero_f`), Lan Hatun, Ağabey, küçük Mete, çocuk Yançi ve Luhun. Lan Hatun ve Ağabey Önsöz'ün eski yakın planları için bu sınıfa alınmıştı; K98'den beri oyunda yakın plan yoktur, sınıf değişmedi. Üç çocuk yüzleri boyanınca 1024²'den bu sınıfa çıktı. Koyun binek sınıfındadır (`mount`, 1024² BC7):

| Sınıf | Oyun dokusu | Biçim | Bellek, mip dahil |
|---|---|---|---|
| `hero`: Mete, oyuncu kahramanı, Lan Hatun, Ağabey, Çocukluk'un üç çocuğu | 2048² | BC7 | 5,3 MiB |
| Adlı kişi; at ve koyun (`mount`) | 1024² | BC7 | 1,3 MiB |
| Yurt, ahır, tekil yapı | 2048² | BC1 | 2,7 MiB |
| Kamp eşyası, kaya, çam | 1024² ya da 512² | BC1 | 0,7 ya da 0,2 MiB |
| Renk bölgesi maskesi | 1024² ya da 2048², iki maske tek RGBA'da | Kayıpsız | 5,3 ya da 21,3 MiB |
| Sıkıştırmadan önce, karşılaştırma için | 4096² ya da 2048² | Kayıpsız RGBA8 | 85,3 ya da 21,3 MiB |

Kamptaki 3B malzeme dokuları 60 MiB'tır (hesap ≈45–77 MiB) ve kamp satırının ≤256 MiB'ına sığar ([Yol Haritası](/roadmap#item-texture-compression)). Motorun doku sayacı (`RENDER_TEXTURE_MEM_USED`) kampta 1920 × 1080'de 244,1 MiB, 2560 × 1440'ta 303,2 MiB okudu: pencereyle büyüyen çizim hedeflerini de sayar ve Metal'de güvenilmez, bu yüzden bütçe malzeme dokularını ayrıca sınar ([Mimari Özeti](/docs/development/architecture)). 28 m'de 1,8 m'lik kişi 38° eğimle ≈84 piksel boyundadır (K98): 1024² yeter; 2048² oyuncu karakteri, oluşturucu, Destan Kitabı ve boyalı yüz içindir.

| Sınıf | LOD0 hedefi | Bugün (GLB'den sayıldı) |
|---|---|---|
| Mete, oyuncu kahramanı | ≤65k | `mete` 60,6k, `hero_f` 62,1k |
| Adlı kişi | ≤30k | `mother` 51,6k, `father` 50,5k, `elder` 52,0k, `child` 40,2k; Önsöz'ün dokuz kişisi 47,4k–52,0k; Çocukluk'un üç çocuğu 41,4k–41,7k |
| Binilen at, büyük hayvan | ≤20k | `horse_brown` 47,4k, `horse_white` 51,1k; `sheep` 31,4k, uzak sürü ağı `sheep_far` 1.300 |
| Tekil yapı | ≤30k | `yurt` 50,8k, `stable` 43,6k |
| Kamp eşyası, kaya, çam | ≤8k | 5,8k–25,9k; Önsöz'ün eşyaları: `kopuz` 19,2k, `cradle` 27,0k, `cradle_bow` 3,9k, `swaddled_baby` 20,8k |
| Kalabalık T1, T2 | ≤1,2k, ≤360 | Yok; üç Hun tipinin modeli ≈51k'dır, T1 ve T2 kopyası henüz yok |

- Otomatik LOD uzağı zaten indirir; LOD0 hedefi en yakın uzaklık, iskelet maliyeti ve iç haritadaki çokluk içindir. Menü kampının modelleri menü karesi bozulmasın diye yeniden üretilmez; iç haritaya girecek kopyalar Meshy Remesh (5) ya da Blender Decimate ile iner.
- Gömülü ışık yoktur: güneş saatle, kamera oyuncuyla döner, dokudaki gölge yanlış yöne düşer. Konsept düz ışıklı üretilir.
- PBR haritaları atılır (`enable_pbr: false`); malzeme sınıf başına boyalı gölgelendiricidir (`atw_textured`, `character_toon`). Görünümü malzeme, gece renk ayarı ve boyalı süzgeç verir; yeni varlık bu üçüne uyar, doku ince kıl değil büyük boya kütlesi taşır.
- Köşe / üçgen oranı izlenir: Mete'de 1,80, hedef ≤1,2.

**İnsan klipleri.** Meshy iskeleti 24 kemiklidir, parmaksız gelir; K92'den beri `tools/hand_rig.py` parmak kemiği ekler (40–44 kemik; Sayıcı, Teoman, Hereka, çocuk Yançi ve Luhun'da serçe yok). Yürüme ve koşu rigle gelir, bekleme ve oturma kütüphanedendir. `ClipRetarget` klibi bir Meshy iskeletinden ötekine kredisiz aktarır; `ShoulderRelax` T bağlamanın kaldırdığı köprücüğü 14,1–18,0° indirir. Yoldaşların ayrı klibi yalnız beş jesttir (5 × 3 = 15 kredi). At binme kütüphanede yoktur: Blender'da yazılır ya da oturma pozuna kodla bacak düzeltmesi eklenir. Her hareket bir kez alınır: [Klip kütüphanesi](#klip-kutuphanesi-k90). Kişiye düşen çeşit: [Animasyon çeşitliliği](#animasyon-cesitliligi-k91).

**Dört ayaklılar (K65).** Ağ Meshy'den, iskelet ve klipler başsız Blender betiğinden gelir. Binek (at, deve) ≈30 deforme kemik taşır: bacak başına 4, boyun 3, kuyruk 5; öteki tam hayvan plan başına 16 kemiktir ve aynı plandan çıkan tür yeni iskelet istemez. Toynak yere `TwoBoneIK3D` ile basar. Klipler `idle`, `graze`, `walk`, `trot`, `gallop`, `flee`, `lie`, `shake`. İlk iskeletli dört ayaklı Çocukluk'un koyunudur (2026-11-07, 0 kredi): `tools/blender/quadruped_rig.py` türün JSON tarifiyle (`tools/blender/quadruped_sheep.json`) Meshy ağını normalize eder (gövde +z'ye, taban y = 0'a, boyun burgusu), 30 kemikli iskelet kurar (29 deforme: kalça, omurga, göğüs, karın, üç boyun, baş, iki kulak, üç kuyruk, bacak başına dört: üst, alt, incik, toynak), ağırlığı bölge maskesi ve ağ üstünde yumuşatmayla verir (UV dikişindeki kopyalar aynı ağırlığı alır), dört klibi analitik IK ile yazar (`idle`, `graze`, `walk`, `run`; adım boyu ve hız `data/fauna/kinds.json`'la aynı, yürüme fazları sol arka 0, sol ön 0,25, sağ arka 0,5, sağ ön 0,75, tırısta çapraz çift), Blender Decimate ile uzak sürü ağını çıkarır (`sheep_far.glb`, 1.300 üçgen) ve binek ölçülerini yazar (`sheep.json`: `saddle_y` 0,707, `saddle_z` 0,03). Betik Blender'ı başsız açar; Metal kum havuzunda açılmadığından kum havuzu dışında koşar. Ölçüm `quadruped_measure.gd`, kareler `quadruped_preview.py`, sınama `test_sheep_asset.gd`. At ve öteki dört ayaklılar aynı betiği kendi tarifiyle kullanır: sıradaki deneme var olan `horse_brown` ağına iskelet ve beş kliptir, 0 kredidir ve onaysız yapılır ([Yol Haritası](/roadmap#item-horse-rig)); sonra deve gelir ([Yol Haritası](/roadmap#item-asset-route-trials)). Yoldaşların 13 atı bu iskeletli kopyadır, don kodla boyanır. Ayrıntı [Hayvanlar](/docs/world/animals) sayfasındadır.

## Klip kütüphanesi (K90)

> [!NOT]
> meshyde aniamsyonlari tekrar tekrar uretmiyorsun degilmi? urettigin animasyonlari tum karakterler icin kullan, hatta urettigin animasyonlar icin web app de bir sayfa olustur ve animasyonlarida gorelim istedigimiz karakteri secerek

Karar [K90](/docs/source/design/decisions#k90)'dır. Bir Meshy hareketi bir kez, tek bir bağışçı karakterde alınır (3 kredi) ve `ClipRetarget` ile Meshy iskeletli bütün karakterlere kredisiz aktarılır. İlk turda (25–26 Ekim) böyle değildi: Meshy hareketi bir iskelet görevi için üretir, hat da her kişiye kendi hareketini aldı. 8 alım 24 kredi tuttu; bunun 15 kredisi aynı hareketin tekrarıydı. Kütüphane her klibi bedene göre bir bağışçıya bağlar (tablonun son sütunu); karakter klibi kendi bedeninin bağışçısından `ClipRetarget` ile alır, bağışçının modeli ya da klibi yoksa klibi kendinde olan başka bir karaktere düşülür. Aktarım iskelet uzayındadır: kol yönü kaynağa eşlenir, bacak iki kemikli çözümle kurulur, kök kemik kalça yüksekliği oranıyla ölçeklenir ([godot.md §6.6](/docs/source/design/godot#6-6-karakter-klipleri-ve-retarget)). İlk turun kopyaları böylece boşa gitmez; yeni hareketin ise tek bağışçısı olur ve üç beden de ondan alır, bugünkü Bekleme 4 gibi. Yürüme ve koşmayı her karakter kendi iskeletinden oynatır; bunların bağışçısı yalnız kendi klibi olmayan karakter içindir. Önsöz'ün sekiz yeni insanı ve Hereka'nın 39 yaşı hareket satın almadı: klipleri kütüphaneden gelir. Tablo çekirdek beş kliptir; bugün kütüphanede 120 klip vardır ve E9 paketinin bağışçısı taşıyıcı iskelettir ([Animasyon çeşitliliği](#animasyon-cesitliligi-k91)).

| Klip (anahtar) | Meshy hareketi | İlk turda alındığı kişi | Bağışçı: erkek / kadın / çocuk |
|---|---|---|---|
| Yürüme, koşma (`walk`, `run`) | Yok: iskelet görevinin hediyesi | Her karakter kendi | Kendi klibi; yoksa yedek Mete / Kadın Kahraman / Çocuk |
| Bekleme 3 (`idle_3`) | 243 `Idle_3` | Mete, Kadın Kahraman (2 × 3) | Mete / Kadın Kahraman / Kadın Kahraman |
| Bekleme 4 (`idle_4`) | 244 `Idle_4` | Mete (3) | Mete / Mete / Mete |
| Oturma, yerde bağdaş (`sit`) | 363 `Sit_Cross_Legged_on_Floor` | Mete, Ana, Baba, Ozan, Çocuk (5 × 3) | Baba / Ana / Çocuk |

**Uygulama ve sayfa.** Veri `game/data/clip_library.json`; çözüm ve klip kurma `scripts/character/clip_library.gd` (`ClipLibrary`). Oyunda bağış klibini bugün oyunun bağışçı tablosu kurar: `asset_plan.json` satırındaki `clip_donors` ({rol: bağışçı}; `prepare_character.py` `meta.json`'a yazar) ve `character_fit_tool.gd`'deki `DONORS`. `character_fit_tool.gd` eksik rolün klibini bağışçıdan aktarıp `<id>_<rol>.res` olarak yazar; `ClipLibrary` oyunun klibinin kaynağını bu tablodan okur. Tablo kütüphanenin bağışçısıyla aynı tutulur, yeni kişi eklenirken ikisi birlikte yazılır. İki eski ayrılık 2026-11-06'da kapandı: Sayıcı'nın oturma bağışçısı Baba'dır; `CineActor` bağışçıyı her bedende `ClipLibrary.donor_for`'dan alır. Dışa aktarma `game/` içinde, içe aktarmadan sonra koşar: `Godot --headless --path . -s res://tools/clip_library_export.gd`. Araç modeli olan her karakterin kütüphanedeki bütün kliplerini `docs/assets/animations/<id>.glb` olarak, listesini de `manifest.json` olarak yazar; ikisi de elle düzenlenmez. [Animasyonlar](/animations) sayfası onları okur: karakter seçilir, klipleri o karakterde oynar, her klibin kaynağı (beş tür: kendi klibi ya da alımı, `ClipRetarget` aktarımı, metinden üretim, ters türetme, iskeletin hediyesi) ve tekrar alımlara giden kredi yazar.

**Yeni hareket ekleme.** (1) Kütüphanede ara (`clip_library.json` ya da Animasyonlar sayfası); aynı işi gören klip varsa yeni alım yoktur. (2) Yoksa hareketi Meshy kütüphanesinden seç (600'den çok insan klibi, liste ücretsiz, at binme yok; [varlik-hatti.md §1.6](/docs/source/research/asset-pipeline#1-6-rig-animasyon-hareket)) ve kütüphaneye ekle: anahtar, ad, rol, hareket numarası ve tek bağışçı (üç beden için aynı karakter). (3) 3 krediyi kullanıcıya sor ([K66](/docs/source/design/decisions#k66)) ve hareketi yalnız bağışçı için al; hareket planda yalnız onun `animations` alanına yazılır, öteki kişiler rolü `clip_donors` ile alır. (4) Dışa aktarmayı koş: klip her karaktere aktarılır ve Animasyonlar sayfasında görünür. `meshy_pipeline.py` ikinci alımı kendisi de reddeder: planın `animations` listesinde başka bir varlığın aldığı hareket varsa plan denetimi hata verir, `run` ve kuru koşu durur. Bir pakete giren çeşit için adımlar aşağıdadır.

## Animasyon çeşitliliği (K91)

Kullanıcının sözü (E9, [d3/register.md](/docs/source/design/d3/register)):

> animasyon cesitliligini artir oyunda ayni animasyonlar olmasin tum karakterlerde, oturma kalkma yurume etc en sik kullanilan animasyonlarda en az 10 farkli cesit olsun meshy ile uret bunlari

Karar [K91](/docs/source/design/decisions#k91)'dir. Sık öbeklerde en az 10 çeşit vardır; bu sayı kütüphanenin toplamıdır, kişiye düşen uygun çeşit daha azdır (aşağıdaki tablo). Kişi öbek başına kendi çeşidini alır, aynı sahnede iki kişi uygun çeşit kaldıkça aynı klibi almaz. Her çeşit bir kez alındı ([K90](/docs/source/design/decisions#k90)) ve taşıyıcı iskeletten `ClipRetarget` ile her karaktere kredisiz aktarılır.

**Paket.** Kullanıcının onayı «Evet, hepsini üret (Önerilen)», MESHY3 hesabı. Taşıyıcı bir karakter değildir: Mete'nin T-poz ağı yeniden iskeletlendi, hareketler ona alındı. Ham dosyalar `game/assets/_meshy_raw/_anim_library/`'dedir (`plan.json`, `meshy.json`; `.gdignore`'lu, oyuna girmez).

| Kalem | Adet | Kredi | Dosya |
|---|---|---|---|
| Taşıyıcı iskelet | 1 | 5 | `donor_rigged_character.glb` |
| Mağaza hareketi, on toplu alım (hareket başına 3) | 100 | 300 | `anim_batch_01..10.glb` |
| Metinden yer oturuşu (üretim 10, iskelete uygulama 3) | 9 | 117 | `motion_anim_<anahtar>.glb` |
| Ters klip: kalkma klibinin tersi, oturmaya geçiş | 6 | 0 | Türetilir (`rev_*`, `kind: derived`) |
| **Toplam** | **115 klip** | **422** | |

**Öbekler.** Çekirdek beş klip öbeklere katılır, kütüphane 120 klip olur; Çocukluk'un yay nişanı (`bow_aim`, E14, 3 kredi; yalnız sahne seçer) ile 121. Yürümenin ikisi bir kez oynar (`discuss_while_moving`, `carry_water_bucket_walk`), role giremez: döngülü yürüyüş 12'dir.

| Öbek | Anahtar | Çeşit | Kişi başına uygun | Geldiği yer | Oyunda oynar mı |
|---|---|---|---|---|---|
| Bekleme | `idle_loop` | 10 | 7–8 | Çekirdek 2, paket 8 | Bekle rolü |
| Kıpırdanma (ara hareket) | `idle_fidget` | 5 | 3–4 | Paket | Bekleme arasında; oyuncu karakterinde açık |
| Yürüme | `walk` | 14 | 2–4 | Çekirdek 1, paket 13 | Yürü rolü |
| Koşma | `run` | 14 | 4–7; yaşlılarda 1 | Çekirdek 1, paket 13 | Koş rolü |
| Yerde oturuş | `sit_ground` | 10 | 4 | Çekirdek 1, metinden 9 | Otur rolü |
| Oturakta oturuş | `sit_chair` | 12 | 2–4 | Paket | Otur rolü, yalnız oturak varsa |
| Oturmaya geçiş | `sit_down` | 13 | 7–9 | Paket 7, ters 6 | Henüz değil |
| Kalkma | `stand_up` | 14 | 5–9 | Paket | Henüz değil |
| Konuşma ve jest | `talk` | 10 | 3–8 | Paket | Henüz değil |
| Uyku | `sleep` | 8 | 8 | Paket | Henüz değil |
| İş ve selam | `work` | 11 | 4–9; iki Hereka'da 1 | Paket 10; Çocukluk'un yay nişanı `bow_aim` | `bow_aim` Çocukluk'ta oynar; ötekiler henüz değil |

«Çeşit» kütüphanenin toplamıdır. «Kişi başına uygun» oyuncu karakteri dışındaki 13 kişide `ClipVariety`'nin süzgeçlerinden (beden, yaş, stil, doğal hız, oturuşta kalça boşluğu) geçen çeşit sayısıdır (2026-11-06); konuşma, uyku ve işte durum açıkça istenince sayılır. Atama da daralır: ara hareket 13 kişinin 11'inde aynı üç klip, sahnesiz yer oturuşu 6'sında bağdaştır. Sayının yetip yetmediği senin kararındır ([Karar Bekleyenler](/docs/general/pending-decisions)).

**Etiketler.** Her klibin `tags` alanı: `body` (male, female, child), `age` (adult, elder, child), `style`; `weight` öbekteki ağırlığıdır, göze batan çeşit daha az kişiye düşer. Kişinin profili `assets/characters/<id>/meta.json`'un `variety` alanıdır; yazılı değilse beden kütüphaneden gelir. Bugün stil taşıyan kişiler: Teoman `proud`, Lan Hatun ve ikinci Lan kadını `graceful`, Ağabey ve Hun Atlısı `warrior`, iki Hereka `ceremony`.

**Atama** (`ClipVariety`, `scripts/character/clip_variety.gd`).

- **Uygun çeşit.** Tanımda `scene_only` taşıyan klip varsayılan atamaya girmez, yalnız sahnenin elle seçimiyle gelir (2026-11-07: `ground_side_sit`, adı yana oturuştur ama dizler önde, iki ayak iki yandan çıkar, sol ayak havadadır; ham klip de böyledir, klip düzelene dek havuz dışı). Beden ve yaş kişiye uymalıdır. `proud` ve `warrior` taşıyan çeşit yalnız o stildeki kişiye gider. Durum stili (`chore`, `talk`, `festive`, `meal`, `sick` gibi) varsayılan atamaya girmez, sahne `situations` ile ister. Mızrakla yürüyüş `props` ile mızrak ister. Yürüme ve koşmada çeşidin doğal hızı, oynatma hızı sınırları içinde (yürüme ×0,6–1,8; koşma ×0,7–1,5) kişinin hızına yetişmelidir.
- **Oturak.** `sit_chair` yalnız sahne oturak verirse (`seat`: tür ve kalça yüksekliği, ±8 cm) gelir. Yerde oturuşta kalça boşluğu ölçülür (`seat_gap_m`): bu kişide bedeni 6 cm'den yukarıda tutan çeşit varsayılan atamaya girmez, sahne seçer ve altına oturak koyar. Bugün yalnız `ground_hug_knees` aşar (Ana'da kalça 41 cm, bağdaşta 17 cm).
- **Seçim.** Başlangıç `hash(kişi:öbek)`'tir, ağırlıklıdır; kişinin stilini taşıyan çeşitler öne alınır. Rastgele sayı ve nesne kimliği yoktur: aynı kişi her çalıştırmada aynı çeşitleri alır.
- **Sahne.** `ClipVariety.Allocator` sahne başına alınmış çeşitleri tutar, kişiler sabit sırayla kaydolur. Alınmış çeşit atlanır; hepsi alınmışsa kişinin kendi sırasındaki ilk çeşit kalır.
- **Önce gelenler.** Sahnenin elle seçimi `Allocator.assign`'dır. Ateş başının beş oturuşu böyle seçildi: Ana `ground_kneel_heels` (2026-11-07), Çocuk `ground_hug_knees` (kütükte), Baba `ground_warm_hands`, Ağabey `ground_one_knee`, Ozan `sit` (kopuz bu pozda kucağa oturur). Doğumda ikinci Lan kadını `ground_one_knee`'dir (`PrologueBirth.SEAT_PICKS`, `CineActor.seat_key`). `pinned_roles` rolü kişinin kendi klibinde tutar: keregeyi tutan Lan Hatun'un oturuşu. Oyuncu karakteri çeşit almaz, kendi klipleriyle oynar.
- **Ara hareket.** `auto_fidget` açıksa kişi beklerken 8–20 sn'de bir kıpırdanma oynar (kişiye bağlı tohum). Sinemada kapalıdır. Oyuncu karakterinde açıktır (2026-11-07, `PlayerController`): çeşit atanmaz, rolleri kendi kliplerindedir, hareket edince ara hareket hemen kesilir; ilk kurulum ≈50 ms, model yüklenirken. Sahne NPC'si açmaz: ateş başı oturur, doğum sahnesi sinemadır.
- **Kare bütçesi.** Bir klibin aktarımı 4–40 ms sürer ve model ve klip başına bir kezdir. Sahne bunu kurulumda yapar (`warm_variety`), kare içinde aktarım olmaz.

**Bacak düzeltmesi** (`ClipLibrary.fit_legs`; tanımın `leg_fit`'i, kişinin ölçüsü `clip_library_measure.json`). Metinden hareketlerde ve kimi bekleme klibinde beden havada kalır: klip kurulurken kalça ve havada kalan bilek kişinin ölçüsü kadar iner, diz iki kemikli çözümle kurulur. Kurallar (2026-11-07):

- **Katlanma sınırı.** Kalça, kalça-bilek uzaklığı zincirin %25'inin altına inecek kadar inmez (`LEG_FIT_MIN_FOLD`); klip orada zaten daha katlıysa o karede hiç inmez. Sınır eğrisi 0,2 sn'lik çevreyle yumuşatılır, yerdeki uçta düzeltme tamdır. `stand_up_3`'te oran Lan Hatun'da 0,16'dan 0,25'e, sol dizin beş karelik savrulması 34 cm'den 20 cm'ye indi (klibin kendisinde 17 cm); `stand_up_9`'da diz kalçanın önünün gerisine geçmez.
- **Yumuşak uzanım.** İnen bilekte bacak zincirin %99,9'una `ClipRetarget._soft_reach` ile yaklaşır, sert sınır yoktur: `idle_03`, `shrug`, `alert`, `idle_12`'de diz dümdüz kilitlenmez (22 kayıtta 0,8–1,3 cm idi, hepsi 1,5 cm'nin üstünde). Düzeltilmeyen bileğin yeri değişmez.
- **Yere dayanan el.** `leg_fit: hands` (`ground_lean_back`): omuz kalçayla iner, bilek yerinde kalır, dirsek bükülür, el zemine göre ölçülür. Kalçası inen 9 kişide el zeminin 0–2 cm üstündedir (Baba 6–10 cm gömülüydü). Kalçası zaten zeminde olan 6 kişide kol uzanıp ele yetişmez, el 3–11 cm havadadır; klibi seçen sahne yoktur.
- **Yatan bedenin ayağı.** `leg_fit: lie` (11 yatma klibi; oturaktan yatağa geçen `sleep` hariç: zemini yataktır): yatarken zemin payı gövde ve başa göredir, klipte bacak aşağı eğimlidir, ayak zemine giriyordu. Klip boyunca saniyede 6 örnekte (en az 24) ölçülür, zeminin altındaki bilek iki kemikli çözümle kalkar (`lift_left`, `lift_right`), gövde ve baş yerinde kalır. 15 kişide 165 kaydın 128'inde ayak 5 mm'den çok, en çok 18 cm gömülüydü; kaydın 22'sinde 5-8 mm kaldı.
- **Omuz.** Eli yere dayanan klipte zemin payı ve el ölçüsü `ShoulderRelax` işlenmiş pozdandır (`PoseFit.has_hand_contact`): oyunda ve sayfada aynı poz.
- **Zemin payı tek kuraldır** (`PoseFit.floor_times`, `floor_offset`): oyunun ölçümü ve dışa aktarma aynı yerden okur; yürüme ve koşmada 60 örnek ve kare başına en alt noktaların alttan dilimi (yürüme dörtte bir, koşma onda bir), son örnek süreden bir adım önce; öteki kliplerde 12 örnekte en alçak an.

**Aktarma aracı.** `tools/anim_library_import.gd` ham GLB'leri oyun kaynağına çevirir; kredi harcamaz, Meshy'yi çağırmaz. `game/` içinde, `Godot --headless --path . -s res://tools/anim_library_import.gd -- <adım>`:

| Adım | Ne yazar | Not |
|---|---|---|
| `--donor` | `assets/animations/donor/donor.glb` | Taşıyıcının yalnız iskeleti; ardından içe aktarma |
| `--clips` | `assets/animations/library/<key>.res` | 115 klip, ≈9,4 MB (2026-11-07'den beri `bow_aim` ile 116). Dinlenme pozu taşıyıcıdan ayrışan GLB reddedilir; ters klipler ana klipten kurulur, `pose_fix` işlenir |
| `--measure [id ...]` | `data/clip_library_measure.json` | Süre, döngüye uygunluk, doğal hız, kalça yüksekliği; karakter başına zemin payı. Karakter başına ≈30 sn; paralel koşu `--part=<yol>`, birleştirme `--merge` |

**Dışa aktarma ve sayfa.** `tools/clip_library_export.gd` modeli olan her karakterin 121 klibini `docs/assets/animations/<id>.glb`'ye, listeyi `manifest.json`'a yazar (karakter başına ≈40 sn; kredi harcamaz). Bugün 18 karakter dışa aktarılmıştır (≈260 MB; Çocukluk'un üç çocuğu dahil). Manifest kişinin sahnesiz varsayılan atamasını (`assigned`; oyuncu karakterinde boş) ve sahnelerin ona bugün oynattığı klipleri de taşır (`scene_picks`: ateş başının elle seçilmiş oturuşları, doğum sahnesinin kullandığı roller). Atama ya da sahne değişince GLB'ler değişmez: `--manifest-only` yalnız manifest'i yazar (≈2 sn). [Animasyonlar](/animations) sayfası ikisini okur: karakter seçilir, en üstte «Sahnede oynar» (kişinin bugün sahnede oynadığı klipler), altında «Bu kişinin çeşitleri» (sahnesiz varsayılan: bugün rolü olan dört öbek ve sahnesi olmayan yedi öbek ayrı), altında öbek öbek bütün klipler. Ateş başındaki kişide sahnenin oturuşu çoğu kez varsayılandan başkadır. Oyuncu karakterinde bu iki liste yoktur: çeşit almaz, kendi kliplerini oynar. Öbek ve aramayla süzülür (anahtar yazıldığı gibi de aranır); klip o karakterde oynar, kaynağı ve kredisi yazar.

**Yeni çeşit ekleme.**

1. Kütüphanede ara: aynı işi gören çeşit varsa alım yoktur.
2. Yoksa kaynağı seç: Meshy mağazası (hareket başına 3 kredi) ya da metinden hareket (10 + 3 kredi). Tersi işe yarayan klip varsa ters klip 0 kredidir: `kind: derived`, `derived: {from, op: reverse, trim_start}`.
3. `game/data/clip_library.json`'a satır yaz: `key`, `tr`, `en`, `role`, `group`, `kind`, `loop`, `meshy_action`, `meshy_name` (metinden harekette `motion`), `carrier: _anim_library`, `file`, `resource`, `seat`, `transition` (geçişse), `contact`, `tags`, `weight`, `note_tr`.
4. Krediyi kullanıcıya sor ([K66](/docs/source/design/decisions#k66)). Hareketi taşıyıcı iskelete al, GLB'yi `_meshy_raw/_anim_library/`'ye indir, görevi `meshy.json`'a yaz. Bir kişinin `animations` alanına yazma.
5. `--clips`, sonra `--measure`: oyun kaynağı ve ölçüler yazılır, kredi harcanmaz.
6. Sınamalar: `tools/run_tests.sh --filter=anim_library`, `--filter=clip_variety`, `--filter=clip_library`. Süzgeçlerden geçen çeşit kendiliğinden atama havuzuna girer ve kişilerin atamaları değişebilir; ateş başının elle seçilmiş oturuşları değişmez. İstenmeyen çeşit `weight` ile geri çekilir ya da sahne elle seçer.
7. Dışa aktarmayı koş, Animasyonlar sayfasında bak.

## İskelet düzeltmesi (K92)

> [!NOT]
> karakterlerin cogunun animasyonlari veya rigid noktalari sorunlu ben anlamiyorum sorun ne resimelre bak kodu etc incele ve sorun ne bana soyle

Karar [K92](/docs/source/design/decisions#k92)'dir. Meshy eklemleri uzun giysi ve zırh altında yanlış yere koyabilir, klibi de bu yanlış eklemlere göre yazar. Üç kusur çıktı:

| Kusur | Nerede | Görünen | Ölçü |
|---|---|---|---|
| Zikzak omurga ve sabit gövde açısı | Mete ve onun modelinden kurulan taşıyıcı; klipleriyle bütün kadro | Belde kırık: karın öne çıkmış, boyun gömük | Ayakta 53 klibin 44–47'si −20°'nin ötesinde, en kötü −48°; düzeltmeden sonra yalnız `idle_03`'te 5 kayıt (−25°'e kadar) |
| Diz eklemi bacak çizgisinin dışında | Baba, Ana, Ozan, Lan Hatun, Hereka 39 (sol), Hun Kadını; hafif Sayıcı, Teoman, Çocuk, Hun Erkeği | Baba çömelmiş; ötekilerde diz geriye bükülü | 10–18 cm sapma; düzeltmeden sonra boya göre 1,8–2,7 cm öne |
| Diz eklemi bacakta yüksek | Ana, Ozan, Sayıcı, Hun Kadını, Lan Hatun, Hereka, Hereka 39 | Bağışçı ya da hedef olunca oturuşta dizler kapanır | Uyluk/baldır 0,83–0,97 (sağlamda 1,04–1,21); düzeltmeden sonra 1,08 |

**Sabit fark.** Meshy klibi iskelete yazarken iskeletin şekline bağlı bir fark ekler: Δ_iskelet(t) = Δ_başvuru(t) · C. Her iskelette vardır, düz omurgada küçüktür ve o kişinin ağında zararsızdır. Klibi başka kişiye taşırken hareket sanılırsa kopyalanır. Bilekte de vardır: kalça eklemlerinin iskelete özgü kayması yüzünden taşıyıcıda sağ bilek 5 cm dışarıda durur (F).

**Araç.** `tools/rig_fix.py` kredi harcamaz. Düzeltme hep ham iskeletten hesaplanır; aynı girdiyle yeniden çalıştırmak aynı dosyayı verir. Eşikler `game/data/rig_calibration.json`'un `limits` alanındadır, sınama da oradan okur.

- `--report`: bugünkü iskeleti ölçer (omurga, diz yeri ve yüksekliği, iki bacak farkı, ayak sabiti, omuz ve dirsek ayna farkı, parmak kemiği sayısı), düzeltilmemiş sorun varsa çıkış kodu 1.
- `--apply`: diz bacak çizgisine ve doğru yüksekliğe, zikzak omurga Hips-neck çizgisine, ayna farkı büyük üst kol eklemi öteki yanın aynasına taşınır; kemiğin dinlenme yönü ve ters bağ matrisleri yeniden yazılır, etek alanı ve parmaklar eklenir (aşağıda). Ağ, UV, doku ve klip dönüşleri değişmez.
- `--calibrate`: her iskeletin kemik başına sabitini ve bilek farkını kendi bedava yürüme klibinden ölçer (başvuru Sayıcı). Aynı ağın doku çeşidi kendi iskeletini taşımaz, `meta.json`'a `variant_of` yazar.

**Aktarım.** `ClipRetarget` kaynağın sabitini çıkarır, hedefinkini ekler: Δ_hedef = Δ_kaynak · C_kaynak⁻¹ · C_hedef. Taşıyıcının yürümesi kişiye aktarılınca gövde ve el kişinin kendi Meshy yürümesini 0,1° içinde tutturur, kol en çok 3,8° ayrışır. Bacak iki kemikli çözümle kurulur: bilek, kalça eklemlerinin ortasına göre kaynaktaki yerine gider; kaynağın F'si çıkarılır, hedefinki eklenir. Bu yüzden taşıyıcının kalça eklemlerindeki fark ayağı havada bırakmaz, bir bacak düzleşip öteki bükülmez. Bacak zincirin %97'sinden sonra yumuşak uzar: diz ayakta dümdüz kilitlenmez, kilide girerken sıçramaz (8 kişi × 16 klipte sağ düz kare 13.114 → 73; Ana'nın ağır yürüyüşünde en büyük diz adımı 6,3 → 2,3 cm).

**Sonraki üretimler.** `prepare_character.py` yeni kişiyi bu adımdan geçirir. Düzeltilemeyen eklem hatasında durur: ana model eski hâline döner ya da silinir, klip ve `meta.json` yazılmaz, kişi kadroya girmez. Başarıda sıradaki adımları yazar: içe aktarma, `glb_prepare.py --textures <id>`, `character_fit_tool.gd --retarget <id>`, `anim_library_import.gd --measure <id>`, `clip_library_export.gd`. `tests/unit/test_rig_health.gd` bütün kadroda omurgayı, dizi, kalibrasyonu, aktarılan klibi kişinin kendi klibiyle (ikiz sınaması: gövde ve bilek), bel kırığını, diz kilidini, oturuşta diz açıklığını, ayak yüksekliğini, rol kliplerinin her kemiğe izini ve her kişinin 120 klip ölçüsünü sınar: hattan geçmeyen model testte düşer.

### Etek, parmak ve omuz (2026-11-07)

> [!NOT]
> bunlari onerdigin cozumlerle gelistir ve duzelt

Üç kusur daha betikle düzeldi, kredi harcanmadı. `rig_fix.py --apply` hepsini tek koşuda yapar, sıra sabittir: eklemler ve ters bağ matrisleri, ham ağırlıklar, omuz geçişi, etek alanı, parmaklar. Araç hep ham iskeletten başlar, ikinci koşu bayt bayt aynı dosyayı verir. Ağırlıkta «değişmez» kuralının üç istisnası bunlardır. Yeni kişide `prepare_character.py` aynı adımları çalıştırır; uzun giysili kişi için `python3 tools/garment_weights.py --suggest <id>` bir satır önerir, `data/garment_weights.json`'a yazılır.

**Etek.** `tools/garment_weights.py` kumaş köşelerinin ağırlığını dinlenme konumundan yumuşak bir alan olarak yazar: kalça payı yükseklikle artar, baldır payı bacak ekseninden uzaklaştıkça söner, sonra kaynaşık köşeler üstünde yumuşatılır. Uyluk baskın kalır: kalça baskın olunca `PoseFit` etek ucunu beden sanıp kişiyi 24 cm'ye kadar kaldırıyordu. Kısa giysili kişi (Mete, Kadın Kahraman, Çocuk, Ağabey, Hun Atlısı) dokunulmaz. Diz ve kalça kumaş içinde kalır, 120 klibin zemin payı ortalama en çok 0,21 cm değişti.

| Kişi | Davul dm² | Kapak cm | Yerde genişlik cm | >2 kat gerilme % |
|---|---|---|---|---|
| Baba | 33 → 15 | 45,9 → 41,6 | 60,3 → 59,8 | 2,4 → 1,5 |
| Ana | 82 → 0 | 39,8 → 30,9 | 58,4 → 59,5 | 8,5 → 4,9 |
| Sayıcı | 28 → 10 | 36,8 → 33,8 | 52,1 → 53,0 | 5,7 → 6,8 |
| Hereka | 24 → 7 | 40,4 → 35,8 | 51,8 → 51,4 | 4,8 → 5,4 |
| Ozan | 21 → 10 | 40,0 → 33,9 | 54,6 → 52,2 | 4,3 → 3,0 |
| Lan Hatun | 23 → 0 | 37,5 → 29,2 | 53,2 → 54,9 | 9,6 → 5,8 |
| Hereka 39 | 40 → 1 | 39,6 → 32,4 | 53,4 → 50,8 | 7,4 → 4,1 |
| Hun Kadını | 18 → 9 | 36,8 → 35,5 | 52,0 → 52,4 | 4,6 → 4,2 |
| Hun Eri | 15 → 8 | 38,2 → 35,1 | 50,3 → 50,1 | 4,2 → 4,0 |
| Teoman | 27 → 9 | 40,8 → 37,1 | 56,4 → 55,0 | 2,7 → 2,6 |

Davul, diz hizasının üstünde yukarı bakan etek yüzeyidir; kapak, etek köşelerinin %99,5 yüksekliği; yerde genişlik, zemin üstü 30 cm bandında kalçaya yatay uzaklığın %99'u. Davul ve kapak bağdaş, ateşe el ve tek dizin, genişlik dört yer oturuşunun ortalamasıdır. Yürürken Ana ve Lan Hatun'da etek ucu köşe farkı büyüktür (yürüme 20–23, koşma 33–41 cm): etek artık baldırla savrulmuyor.

**Parmak.** `tools/hand_rig.py` kemikleri ağdan ölçer: elin izdüşümünde parmak şeritlerini bulur, parmak başına iki boğum ve ayrı başparmak ekler, sol ve sağ boyları eşitler. 12 kişide 20 kemik; Sayıcı (üç parmak ve kütük), Teoman (kaynaşık) ve Hereka (eldiven gibi) 16 kemik, serçesizdir. Klip parmağa yazmaz. `HandGrip` doğal yarı gevşek eli kurar, kavrama sahnedendir (`KopuzPlay`, `CineActor` `reach_grips` ve `gesture_grips`), site GLB'sinde doğal el sabit izdir. Karşılaşılan sınır: başparmak karşıtlığı kısmidir, kopuzda başparmağın ucu sapın arkasına biraz gömülür. Doğum sahnesinde kapanan el astara 4,4 cm kısa kaldı, kol zaten uzanıktı: Lan Hatun 4 cm duvara yaklaştı (el astara 0,5 cm), etek de taştığından katlanmış keçe 0,25 × 1,3'ten 0,29 × 1,335 m'ye büyüdü.

**Omuz.** Üst kol ekleminin ayna farkı 1,7 m boyda 4 cm'yi aşarsa yan, öteki yanın aynasına taşınır, omuz geçişinin ağırlığı da aynadan alınır: yalnız eklem taşınınca omuz kabarıyordu. Mete 6,2 → 0 cm; `idle_9`'da sol el sağa göre −4,5 → +2,7 cm (taşıyıcı +2,5), kadroda en büyük fark 2,8 cm. Taşıyıcıda bu kusur yoktur (0,6 cm). Sol dirsek bütün kadroda 1,5–3,2 cm ayna farkı taşır, sınırın altındadır, dokunulmadı.

**Zincir oranı (6. adım, 2026-11-08).** Meshy'nin yürüme ve koşusu zincire göreli kurulur: bacağı zincirin %99,6'sına dek açar, kalçayı da kaldırır. Diz düzeltmesi zinciri kısaltınca kişinin kendi yürümesinin mutlak dönüşleri bileği eski boylara göre koyar. Bu sapma 4 cm'yi (ikiz sınamasının eşiği) aşarsa `rig_fix.py` bacağı yeniden çözer: ayak yolu kalça eklemine göre zincir oranıyla küçülür, kalça bilek yüksekliği çevresinde aynı oranla iner, diz `ClipRetarget`'in iki kemikli çözümüyle kurulur, ayağın dünya dönüşü korunur. Sonuç ham klasörde bir kopyadır (`_meshy_raw/<id>/rig_fix/`), kalibrasyon oyunun `.res`'ini oradan çıkarır. Kadroda yalnız Huyan Hatun eşiği aşar (ham diz kadronun en yükseği, uyluk payı 0,425): bilek sapması 4,8 → 2,9 cm, diz çökmede dizler arası 28,4 → 35,8 cm (kaynak 46,3; pay 0,61 → 0,77). Öteki 22 kişinin dosyaları bayt bayt aynı kaldı. Hereka 39'un yürümesinde sol diz 33 karenin 21'inde zincirin %99'unun üstündedir; eşiği aşmadığı için dokunulmadı.

**Sonraki adımlar.** Her uygulamadan sonra içe aktarma, `character_fit_tool.gd --retarget`, `anim_library_import.gd --measure` (ve `--merge`), `clip_library_export.gd`. `rig_fix` GLB'nin görselini olduğu gibi taşır: doku işi korunur.

**Çözülmeyenler.** Etek yerde hâlâ geniş: davul gitti, yerdeki genişlik giysinin dinlenme genişliğinden gelir, çözümü kumaş kemiğidir, ayrı iştir. Hereka'nın kucağında kutu gibi bir kütle kalır. Yatma kliplerinde sırtı ince kişide ayak zemine gömülür (bugün yatma sahnesi yok).

### `meshy-t2.5` denemesi (E11.4)

Baba'yı aynı konseptten `meshy-t2.5` (akıllı topoloji) ve `meshy-n1` dokuyla ürettik, Meshy iskeletledi: 15 + 5 = 20 kredi, ≈4 dakika. Dosyalar `assets/_meshy_raw/father_t25`'te, oyuna takılı değil. Aynı kliplerle aynı aktarım ve düzeltmeden geçti.

| Ölçü | `meshy-7.1` (bugünkü Baba) | `meshy-t2.5` |
|---|---|---|
| Köşe / üçgen | 96.784 / 50.495 | 22.552 / 28.954 |
| UV adası | 23.630 | 1.023 |
| Çok yüzlü kenar | 1.789 | 25 |
| Parça | 1 | 36 (giysi katmanları ayrı) |
| Ham diz sapması (sol / sağ) | −15 / −17,6 cm | +7,4 / +8 cm, yine düzeltildi |
| Yüzeyin 1,5 kattan çok gerilen payı, ortalama | %10,7 | %10,6 |
| Yüzeyin 2 kattan çok gerilen payı, ortalama | %3,7 | %4,8 |
| Yüzeyin 3 kattan çok gerilen payı, ortalama | %0,8 | %1,5 |

Sonuç: ağ belirgin temiz ve hafif: köşe 4,3 kat, üçgen 1,7 kat azalır. Hareket daha iyi değildir: uzun kaftan aynı yerde gerilir, aşırı uçta biraz fazla, çünkü kumaş yine uyluğa bağlıdır. Doku yumuşak, kürk geometrisi düz, saç ve yüz daha düzenli ama konseptin keskinliği azalır. Kadroyu yeniden üretmek için gerekçe yoktur; yeni ikincil kişide ucuz (45 yerine 20 kredi) ve hafif bir seçenektir, karar kullanıcınındır.

![Üst sıra bugünkü Baba, alt sıra t2.5: dinlenme, yüz ve etek, tel kafesle](/media/docs/research/rig-teshis/t25-ag-karsilastirma.jpg)

![Aynı kliplerde iki Baba: bekleme, yürüme, koşma, bağdaş, ateşe el, yana oturma](/media/docs/research/rig-teshis/t25-klipler-1.jpg)

## Kişi görsel zinciri ve T-poz

> [!NOT]
> her karakterin profil resimi ve art resmi tutarli olacak
>
> gereken assetleri gpt-image-2 ile uret
>
> ayrica 3b uretimi ilk basta yapmayacagimiz icin 3B yerine V veya T pose ekleyebiliriz 3d uretecegimzi zaman bunlari kullaniriz hangisi bizim icin en uygunsa v veya t pose onu uret, 3b modeli olmayanalr t pose a dussun, 3b modelleri daha sonra uretiriz suan varolanlari kullan sadece

Karar [K85](/docs/source/design/decisions#k85)'tir. Zincir tek yönlüdür:

1. **Art önce.** Tam boy art üretilir (1024 × 1536): tek figür, önden dörtte üç, baştan ayağa, ılık açık zemin.
2. **Profil ve T-poz art'tan türer.** Profil kare baş ve omuzdur (1254 × 1254), T-poz 1024 × 1536'dır; ikisi art'ı referans alır. Taç, giysi, renk ve zemin üçünde aynıdır.
3. **Eski portre yalnız yüz referansıdır.** Kişinin eski portresi varsa (bugün 24 kişi) art o yüze bakılarak çizilir; profil yine art'tan türer, eski portreden değil.

Neden: ayrı istemlerle üretilen görseller birbirinden kayar; yüzün, tacın ve rengin üç görselde tutmasının tek yolu ikisini art'tan türetmektir.

**T-poz.** Kollar omuz hizasında yana açık, avuçlar aşağı, önden, düz açık gri zemin, düz stüdyo ışığı, gölgesiz. Kullanıcı V ile T arasını «hangisi bizim için en uygunsa» diyerek tasarıma bıraktı; T seçildi. Meshy'nin otomatik iskeleti T ve A pozunu kabul eder; T-poz görselde görselin pozu bağlama pozuyla aynıdır. Var olan altı karakter A-poz görselden (kollar ≈40° aşağı) T bağlamayla üretildi; köprücükler kalktı, `ShoulderRelax` gerekti. T-pozda kollar gövdeden ayrıdır, giysi önden bütün görünür. Uzun kaftan A-pozda daha az bozulabilir: üç denemeden uzun kaftanlı kişi T-poz görselle yapılır, bozulursa o sınıfa A-poz görsel üretilir.

**3B ya da T-POZ.** Ansiklopedide ve Destan Kitabı'nda üçüncü küçük resim modeli olan kişide döndürülebilir 3B, olmayanda T-poz görselidir. Var olan altı model (Mete, Ana, Baba, Yaşlı Ozan, Çocuk, kadın kahraman) kalır; ansiklopedide modeli bağlı kayıt 2026-11-06'da ondur (Mete, Ozan, Çocuk, Ana, Baba, Teoman, Lan Hatun, Ağabey, Sayıcı, Hereka). Önsöz'ün öteki modellerinin ayrı kaydı yok: genç Hereka Hereka'nın kaydındadır, üç Hun tipi kalabalıktır. Sonraki 3B önce sorulur ([K66](/docs/source/design/decisions#k66)), T-poz görseli girdisi olabilir (`pose_mode: "t-pose"`).

[Erlik](/encyclopedia/erlik)'in zinciri: eski portre (yalnız yüz), art, profil, T-poz.

![Erlik'in eski portresi, yalnız yüz referansı](/media/docs/media/ui/portraits/erlik.webp) ![Erlik, art](/media/docs/assets/encyclopedia/erlik/art.webp) ![Erlik, profil](/media/docs/assets/encyclopedia/erlik/portrait.webp) ![Erlik, T-poz](/media/docs/assets/encyclopedia/erlik/pose.webp)

**Plandaki ekler ve alanlar.** `asset_plan.json`'ın `style_suffix`'i «3rd century BC steppe» der; `character_suffix` T-poz ister, A-poz eki ayrıdır (`character_suffix_a_pose`, kollar ≈40° aşağı). Yeni kişinin Meshy girdisi varsayılan olarak T-poz görselidir (`character_input`: `pose_mode: "t-pose"`, `docs/assets/encyclopedia/<id>/pose.png`); satırın `input_image`'ı varsa o kullanılır: ilk turun altı kişisi ve Önsöz'ün yedi kişisi kendi konseptiyle, Hereka ve Sayıcı T-poz görseliyle üretildi. 39 satırın hepsinde `route`, `credit_class` ve `texture_class` vardır; yol kimlikleri `programatik`, `meshy`, `blender`, `tripo`, `2d` ve `free`'dir, `free` K89'un ücretsiz kanalıdır ([Yol Haritası](/roadmap#item-asset-plan-fields)).

## Kodla kişi: Folk

Kendi modeli olmayan kişi ve kalabalık 0 krediyle, var olan modellerden kurulur ([folk-generator](/roadmap#item-folk-generator); [K89](/docs/source/design/decisions#k89)): `scripts/character/folk.gd`, veri `data/character/folk.json`. Tam kişide model üç kalabalık modelinden biridir (`crowd_hun_man`, `crowd_hun_woman`, `crowd_hun_rider`); üçüne 1024 piksellik bölge maskesi pişti (`tools/bake_regions.py --size 1024`: saç, ten, göz; dokuyla aynı boy, kayıpsız ≈4 MiB), giysinin ölçüsü `tools/bake_folk_cloth.py`'dendir (maskede saç, ten ve göz olmayan pikselin doğrusal ortalama parlaklığı ve boyanın bandı). Karakter gölgelendiricisinin yeni `cloth_color` boyası giysiyi kişinin rengine boyar, koyu deri ve çizme doğal kalır; ten ve saç halkın rengindedir. Maskesi olmayan modelde `StandIn`'in renk çarpanı kalıbı ılımlıdır. Kalabalığın kuklası ve kartı aynı paleti okur; kart atlası açılışta pişer, dosya değildir.

## Ansiklopedi levhaları

Ansiklopedinin ([/encyclopedia](/encyclopedia)) her kaydı görsellerini `docs/assets/encyclopedia/<id>/` altında taşır: `art.png`, `portrait.png`, `pose.png` asıldır, sitede WebP kopyalar gösterilir (art ve T-poz 1.100 piksel boy, profil 512 × 512). Eski portreden türeyen yüz referansı `_portrait-ref.png` yalnız üretimde kullanılır, oyuna girmez.

- **Komut.** `npm run concepts -- --encyclopedia [--jobs=3] [--only=a,b]`. Kaydın `artPrompt`'undan önce art çizilir, sonra profil ve (modeli yoksa) T-poz art'tan türer. Var olan görsele dokunulmaz; kota dolunca durur, sonra kaldığı yerden sürer. Tanrılarda üslup referansı yalnız kamp görselidir, kişilerde Mete ve kamp.
- **Kapsam.** `encyclopedia.json`'da 149 kayıt vardır: 99 kişi, 20 tanrı, 17 topluluk, 7 hayvan, 6 yer. Yerler figür taşımadığı için bu üretime girmez.
- **Bugün.** Üretim tamam (2026-11-06'da sayıldı): 143 kaydın 143 art'ı, 143 profili ve 138 T-pozu var; modeli olan on kişide T-poz yerine model gösterilir (ilk beşinin T-pozu hiç üretilmedi).
- **Godot'ya giriş.** Oyunun kopyasına belge atfı ve «Oyundaki yeri» geçmez ([K97](/docs/source/design/decisions#k97)). `tools/import_encyclopedia.py` görselleri `game/assets/ui/encyclopedia/<id>/`'ye kopyalar, profilden 128 × 128 küçük resim keser; doku VRAM sıkıştırmalı BC7'dir, mip açık, art ve T-poz 1024, profil 512 sınırında. Kişi başına ≈2,1 MiB, 80 küçük portre ≈1,7 MiB eder; sayfa yalnız seçili kişiyi ve iki komşusunu yükler, kamp satırının doku belleğinde kalır ([Yol Haritası](/roadmap#item-encyclopedia-images)). Kitabın düzeni [Arayüz ve Menüler](/docs/presentation/ui-menus) sayfasındadır.
- **Yoldaşlar.** On altı yoldaşın art, profil ve T-pozu (Jiyu'nun iki yaşıyla 54 görsel) aynı sırayla ve kredisiz üretilir; Yoldaş Kartı'nın portresi profilden 256 × 256 kesilir.

## Tanıtım sesleri

> [!NOT]
> Ve burda bir yere bir icon ekle ve o ikona bastigimzida karakterin konusma sesi ile karakter kendisini tanitsin 2 cumle ile ben erlik ...

Karar [K86](/docs/source/design/decisions#k86)'dır. Kişi sayfasında başlığın yanında hoparlör durur; basınca kişi kendini iki cümleyle tanıtır. Söylenen İngilizcedir, Türkçesi altyazıdır (K5, K61). Tanıtım sesi kişinin oyundaki konuşma sesidir: bir kişi sitede ve oyunda tek sesle konuşur. Anlatıcının sesi Eldrin ve ozanın sesi David başka kişilere verilmez. Oyunda konuşmayan kişi sesle tanıtılmaz ([Umay](/encyclopedia/umay), [Mene](/encyclopedia/mene)): hoparlör çıkmaz, iki cümle yazı olarak kalır.

| Komut | İş | Bedel |
|---|---|---|
| `node scripts/intro-voices.mjs cast [--force]` | Sesi olmayan kayda `voiceBrief`'e (cinsiyet, yaş, tını) göre ElevenLabs kütüphanesinden ses seçer | Arama kredisiz |
| `node scripts/intro-voices.mjs cost` | Üretilecek satırların karakter toplamını yazar | Kredisiz |
| `node scripts/intro-voices.mjs gen [--only=a,b] [--force]` | `eleven_v3`, kararlılık 0,5 ile okur; `docs/media/audio/vo/en/ency.<id>.mp3` | Karakter başına 1 kredi |

- Aynı ses ve aynı metin bir kez üretilir (`ency.manifest.json`); `--force` yeniden üretir. Anahtar araçta kalır, yazdırılmaz.
- Her `gen` turu önce `cost`'un toplamıyla kullanıcıya sorulur; tur kişinin metni ve sesi belli olunca açılır. Sesi kullanıcının seçimine kalan kişilerde (Hereka, [Ardokşa](/encyclopedia/ardoksha), [Kujul](/encyclopedia/kujul), [Atşo](/encyclopedia/atsho), [Çocuk](/encyclopedia/child) ve 16 yoldaş) tanıtım o seçimden sonra okunur (K87). Harcama sayaçla izlenir, tavan yoktur.
- **Bugün.** Konuşan 96 kişinin tanıtımı üretildi (2026-11-05, E7): 4.718 kredi (`ency.manifest.json`), tanıtım başına ≈49. Erlik oyundaki sesi Kall'la konuşur. Sesi kullanıcının seçimini bekleyen kişilerde önerilen ses geçicidir ([Karar Bekleyenler](/docs/general/pending-decisions)).
- **Godot.** Dosya `game/audio/vo/ency/<id>.mp3`'ye olduğu gibi kopyalanır, yeniden kodlanmaz; `Voice` yolunda ana söz olarak çalar ve müziği kısar ([Yol Haritası](/roadmap#item-intro-voices)).

![Erlik'in tanıtımı](/media/docs/media/audio/vo/en/ency.erlik.mp3)

> [!DURUM]
> **Oyunda (Godot, 2026-11-07):** konsept, Meshy, küçültme ve karakter hazırlama hattı çalışıyor (`imagegen/gen.sh`, `meshy_pipeline.py`, `meshy_dispatch.py`, `glb_prepare.py`, `prepare_character.py`, `bake_regions.py`). İlk turda (25–26 Ekim) 26 model üretildi: 6 kişi, 2 at, 2 yapı, 12 kamp eşyası, 4 doğa nesnesi; 1.094 kredi. Önsöz'ün 12 modeli (555 kredi; E7.6–E7.9) oyunda: dokuz kişi kendi modeliyle, ozanın elinde kopuz, doğumda beşik, kundak ve ağdan kesilen yay (`cradle_bow`). Önsöz'de yer tutucu yalnız iki Lan kadınındadır (Hun Kadını'nın ağı). Çocukluk'un dört modeli (E14, 178 kredi) oyunda: küçük Mete, çocuk Yançi ve Luhun kendi modelleriyle, yüzleri kredisiz boyalı (`paint_face.py`), `hero` doku sınıfında; koyun Meshy ağıyla, iskeleti, dört klibi ve uzak sürü ağı `tools/blender/quadruped_rig.py`'den. Klip kütüphanesi (K90) ve çeşit ataması (K91) çalışıyor: `ClipLibrary`, `ClipVariety`, `anim_library_import.gd`, `clip_library_export.gd`; 121 klip, 116 oyun kaynağı, 18 karakter dışa aktarıldı. Kampta ve doğum sahnesinde bekle, yürü, koş ve otur rolleri kişiye atanır; oyuncu karakteri kendi kliplerindedir. `meshy_pipeline.py` bir hareketin ikinci alımını reddeder. Dokular VRAM sıkıştırmalı ve oyun boyunda; kampta 3B malzeme dokuları 60 MiB (2026-11-05 ölçümü). `asset_plan.json`'ın 43 satırının hepsinde `route`, `credit_class` ve `texture_class` var, `character_suffix` T-poz ister. Ansiklopedinin görselleri (`assets/ui/encyclopedia/`, `import_encyclopedia.py`) ve tanıtım sesleri oyunda. Atlar iskeletsizdir, canlılığı gölgelendirici verir; ilk iskeletli dört ayaklı koyundur.
>
> **Kodda ama eksik:** Ara hareketi açan sahne yok; oturmaya geçiş, kalkma, konuşma, uyku ve iş kliplerini (Çocukluk'un yay nişanı dışında) oynatan sahne yok. Menü karesinin referansı ve bütçe tabanı 2026-11-07'de K98'in uzak kadrajıyla yeniden alındı ([Yol Haritası](/roadmap#item-menu-budget-retake)). Gerçek çizimde göz onayı [Karar Bekleyenler](/docs/general/pending-decisions)'dedir.
>
> **Yok:** Tripo kullanımı; atın ve öteki hayvanların iskeleti (dört ayaklı betiği bugün yalnız koyunda koştu).

Hattın Yol Haritası'ndaki temel fazı, canlı:

```ilerleme
foundation-p1
```

## Kaynaklar

- [varlik-hatti.md](/docs/source/research/asset-pipeline): [§1 Meshy](/docs/source/research/asset-pipeline#1-meshy), [§2 Tripo](/docs/source/research/asset-pipeline#2-tripo-ve-otekiler), [§3 Blender MCP](/docs/source/research/asset-pipeline#3-blender-mcp), [§6 referans görsel](/docs/source/research/asset-pipeline#6-referans-gorsel-kurallari), [§7 maliyet](/docs/source/research/asset-pipeline#7-maliyet-formulu), [§8 karar matrisi](/docs/source/research/asset-pipeline#8-karar-matrisi)
- [godot.md §6](/docs/source/design/godot#6-varlik-hatti): yollar, içe aktarma, doku, üçgen, malzeme, klip, dört ayaklı; [§3.8](/docs/source/design/godot#3-8-destan-kitabi-ansiklopedi-duzeni-k85-k86): ansiklopedi görsellerinin ve tanıtım sesinin Godot'ya girişi
- [decisions.md](/docs/source/design/decisions): [K65](/docs/source/design/decisions#k65), [K66](/docs/source/design/decisions#k66), [K85](/docs/source/design/decisions#k85), [K86](/docs/source/design/decisions#k86), [K87](/docs/source/design/decisions#k87), [K89](/docs/source/design/decisions#k89), [K90](/docs/source/design/decisions#k90), [K91](/docs/source/design/decisions#k91), [K92](/docs/source/design/decisions#k92)
- [d3/register.md](/docs/source/design/d3/register): E2, E5, E7.6–E7.9, E8, E9 ve E11, kullanıcının sözleri
- [fauna.md §10](/docs/source/design/fauna#10-godot-uygulamasi): hayvanların iskeleti, yürüyüşü ve varlık yolu; `companions.md` §9: yoldaşların görselleri, modelleri ve bedeli
- Araçlar: `game/tools/asset_plan.json`, `meshy_pipeline.py`, `meshy_dispatch.py`, `prepare_character.py`, `rig_fix.py`, `anim_library_import.gd`, `clip_library_export.gd`; `docs-app/scripts/concepts.mjs`, `intro-voices.mjs`; veri `docs/assets/catalog.json`, `docs-app/content/encyclopedia.json`, `game/data/clip_library.json`, `game/data/clip_library_measure.json`, `game/data/rig_calibration.json`
- İlgili: [Varlıklar](/assets), [Animasyonlar](/animations), [Ansiklopedi](/encyclopedia), [Mimari Özeti](/docs/development/architecture), [Karar Bekleyenler](/docs/general/pending-decisions), [Yol Haritası](/roadmap)
