# Varlık hattı araştırması

Bu belge, sitedeki Varlıklar sayfalarının (kullanıcının ek isteği, [register.md](../design/d3/register.md)) hangi üretim yolunu ve hangi krediyi yazacağını belirler. **Hedef Godot 4.7'dir:** oyun `game/` klasöründedir (eski Tanhu 3, adı artık «Tanhu»; [brief.md](../design/d3/brief.md)). Belge önce Three.js prototipi için yazıldı. Prototipe özgü satırlar (`src/...`, `Folk`, `InstancedMesh`, `KitField`, `paintMaterial`, KTX2) yalnız ölçüm kaynağıdır; Godot karşılıkları §4.1, §5.8 ve §8'dedir. Bütün web erişimleri **2026-11-04** tarihlidir. Bu turda Meshy ve Blender çağrılmadı, kredi harcanmadı; Godot projesinin 26 Meshy iş kaydı (`game/assets/_meshy_raw/*/meshy.json`, `task_*.json`) okundu. Kural brief'tedir: Godot'da varlık üretimi serbesttir, Meshy hattı kuruludur (`game/tools/meshy_pipeline.py`), prototipin «Blender ve Meshy çağrılmaz» kuralı (`gorsel-dil.md`, [K14](../design/decisions.md)) Godot'a geçmez; kredi harcayan her üretim önce kullanıcıya sorulur. Etiketler: [kaynak] bağlantılı ya da dosyadan okunmuş bilgi, [çıkarım] hesap ya da sonuç, [kurgu] önerilen değer.

## Özet

1. **En son ve en kaliteli model `meshy-7.1`.** `latest` buna gider. Tek görselde `geometry_resolution: "4k"`, `texture_resolution: "8k"` **40 kredi** tutar (8K doku 35 + Ultra geometri 5). Çoklu görselde 4K geometri yoktur; `2k` ile yine 40 kredi. Godot'daki 26 model işi bu ayarla 40'ar kredi yazdı (`consumed_credits`). [kaynak]
2. **Fiyat notu doğrulandı.** 2026-10-12 tablosu API fiyat sayfasıyla aynı. Yeni olan yalnız `texture_model` parametresi ve `meshy-n1` dokusu (2–3 Kasım).
3. **Formül (API).** Statik 40. Oyun ağına indirme üretim içinde yapılırsa (`should_remesh: true`, `topology: "triangle"`, `target_polycount`) ek kredi yoktur: Godot hattı 26 işte bunu 4K geometriyle 40'a yaptı. Ayrı Remesh çağrısı (5) yalnız sonradan yeniden indirmede gerekir. İnsan rig +5 (yürüme ve koşu içinde), her ek hareket +3, doku varyantı 15 (8K) ya da 10. **İnsan 45 kredi.** Web uygulamasında remesh, rig ve kütüphane hareketi 0 kredidir.
4. **Tüm oyun.** 449 3B adayı en kaliteli ayarla ≈18.210 kredi, $228–364 eder. Bunun 5.120'si yalnız 2B olması gereken eşya ve yiyecektir. Godot için önerilen karma ≈9.710 kredi, beğenmeme payıyla ≈12.630: beş ay Premium ya da iki ay Ultra ($200) eder [kurgu, §7.2].
5. **Godot'da insanlar zaten Meshy çıktısıdır.** Altı kişi (`mete`, `hero_f`, `mother`, `father`, `child`, `elder`) Meshy 7.1 ile üretildi ve riglendi; klipler `AnimationPlayer`'da oynar (`character_avatar.gd`). Yürüme ve koşu rigle gelir. `ClipRetarget` (`clip_retarget.gd`) bir Meshy iskeletinin klibini ötekine kredisiz aktarır: `hero_f`'in oturması annenindir. Mete 54, öteki beşi 48 kredi tuttu; 26 varlığın toplamı 1.094'tür. 24 kemik Godot'daki ham dosyada da aynıdır. [kaynak: dosya]
6. **Meshy'nin otomatik ağırlığı uzun giysiyi bacağa bağlar** (Mete'de %94,8; Godot'daki ham ağda benzer süzgeçle %92,8). Bozkır kıyafeti uzun olduğu için her yapay zekâ insanında ağırlık düzeltme adımı vardır. Godot'da `Folk` yoktur: ağırlık kalçaya taşınır (Blender ya da Godot araç betiği) ya da pelerine kemik eklenip `SpringBoneSimulator3D` ile sallanır [çıkarım].
7. **Hayvanda Meshy API'si yok.** Rig yalnız insansı alır. Web'de «Quadruped Dog» bir yürüyüş verir. Tripo `quadruped` ve `avian` dahil rigler (25 kredi), ama dört ayaklıda tek hazır hareket `walk`, kuşta hiç yok. Godot'daki iki at Meshy statik ağıdır, canlılığı gölgelendirici verir (`horse.gd`). En mantıklı yol: Meshy ağı (40) ve başsız Blender betiğiyle bizim iskeletimiz, ağırlığımız ve yürüyüşlerimiz; Tanhu 1'in `tools/blender_horse.py` yöntemi yalnız teknik olarak alınır [çıkarım].
8. **Durum taşıyan yapı kodla kurulur, görünüş Meshy'den gelir.** Godot'da yurt ve ahır Meshy ağıdır, kodla çizilen yurt yedektir (`yurt.gd`). Yapay zekâ ağı grup taşımaz: aşamalı kurulum, söküm, hasar, kültür ve boy (#32) parametrik `Yurt` koduyla yürür; menü, sinema ve uzak NPC kampı Meshy kabuğunu kullanır [çıkarım].
9. **Oyuna giriş.** 8K yalnız ana kopyadır. Godot hattı dokuyu `glb_prepare.py` ile küçültür: insan, at ve yapı 4096², eşya ve doğa 2048². Bugün 26 dokunun hepsi `Lossless` içe aktarılmış (`compress/mode=0`, `vram_texture: false`): hepsi yüklenince bellekte ≈0,94 GB tutar; `VRAM Compressed` ile ≈0,16 GB (S3TC) ya da ≈0,31 GB (BPTC) olur [hesap]. Küçük doğa nesnesi zaten köşe rengine pişirilip `MultiMesh`'e girer (`TreeKit`).
10. **Referans görsel.** Godot'un konsept ekleri (`asset_plan.json`, `style_suffix`, `character_suffix`) düz ışık ve gri zemin ister; ama «4th century steppe» der, oyun MÖ 3. yüzyıldır. Ortak `STYLE_3D` ve sınıf şablonları bölüm 6'dadır. Godot'da 26 konsept ve iki yeniden deneme ≈37 dakikada çıktı. [kaynak: dosya saatleri]

## 1. Meshy

### 1.1 Modeller

| Kimlik | Durum | Ne için | Tarih |
|---|---|---|---|
| `meshy-7.1` (`latest`) | Etkin, en son, en kaliteli | Tam ayrıntı, Ultra geometri | 2026-09-18 |
| `meshy-7` | Ağ modeli olarak eskidi, çalışır | Ağ için yerine 7.1. Doku modeli olarak en kalitelisi: PBR, 8K, çoklu görüş | 2026-08-12 |
| `meshy-6`, `meshy-6-lite` | Etkin | `meshy-6`: `remove_lighting` çalışan tek doku; Lite: ucuz, 2K | |
| `meshy-t2`, `meshy-t2.5` | Etkin | Smart Topology: doğrudan düşük üçgen. T2.5 oyun varlığı için, yalnız üçgen, 100–30.000 | 2026-07-13, 2026-10-15 |
| `meshy-n1` | Etkin, yalnız doku | 2K temel renk, yalnız referans görselden; PBR ve metin yok | 2026-11-02 ve 03 |
| `meshy-5`, `meshy-t1` | Kalktı, kalkıyor | Kullanılmaz | 2026-10-10, 2026-11-30 |

Kaynak: [değişiklik günlüğü](https://docs.meshy.ai/en/api/changelog), [eskime sayfası](https://docs.meshy.ai/en/api/deprecations), erişim 2026-11-04.

### 1.2 En yüksek kalite parametreleri

| Parametre | Tek görsel | Çoklu görsel | Not |
|---|---|---|---|
| `ai_model` | `meshy-7.1` | `meshy-7.1` | `latest` de aynı; sabit yazılır, sonuç sonradan kaymaz [çıkarım] |
| `geometry_resolution` | `4k` | `2k` | Çoklu görselde `4k` 400 döner; ikisi de +5 kredi |
| `texture_model` | `meshy-7` | `meshy-7` | 8K'ya çıkar, PBR verir; seçim krediyi değiştirmez. Godot işleri bu parametre yokken (25 Ekim) 8K taban renk aldı |
| `texture_resolution` | `8k` | `8k` | 8K 35, 2K ve 4K 30 kredi; 8K'da emisyon haritası yok (API). PBR haritalarının 4K kaldığını yalnız Meshy MCP açıklaması yazar, API sayfası boyut vermez |
| `enable_pbr` | `true` | `true` | Kredi eklemez. Oyun yalnız taban rengi okur (Godot: `atw_textured`, `enable_pbr: false`), bkz. §5.8 |
| `should_remesh` | `false` (ana kopya) | `false` | Belge en yüksek kalite için `false` der. Godot hattı oyun ağı için `true` gönderir: ek kredi yok, 26 işin 22'si üçgen hedefinin ±%5'inde kaldı; `pine_a` 20.000 isteyip 5.769 verdi |
| `topology`, `target_polycount` | Ana kopyada kullanılmaz | Kullanılmaz | `should_remesh` açıkken: `triangle` ya da `quad`, 100–300.000, varsayılan 30.000. Godot: `triangle`, varlık başına `polycount` |
| `image_enhancement` | `false` | `false` | API varsayılanı `true`. `false` boyalı görseli olduğu gibi tutar; açıkken ayrıntı kayabilir |
| `pose_mode` | `t-pose` (insan) | `t-pose` (insan) | İnsansı olmayanda poz görselden gelir |
| `target_formats` | `["glb"]` | `["glb"]` | Az biçim daha hızlıdır |
| `multi_view_thumbnails` | `true` | `true` | Dört yön önizleme, ≈5 sn |

```json
{ "image_url": "<data URI>", "ai_model": "meshy-7.1", "geometry_resolution": "4k",
  "should_texture": true, "texture_model": "meshy-7", "texture_resolution": "8k", "enable_pbr": true,
  "should_remesh": false, "image_enhancement": false, "target_formats": ["glb"], "multi_view_thumbnails": true }
```

Girdi: JPG, PNG, WebP, ≤20 MB, kenar ≥32 px (web önerisi ≥512). Çoklu görselde 1–4 görsel, ilki önden sayılır. Topoloji için `model_type: "smart-topology"` ve `meshy-t2.5` ayrı bir yoldur, çoklu görsel almaz.

Kaynak: [Image to 3D](https://docs.meshy.ai/en/api/image-to-3d), [Multi-Image to 3D](https://docs.meshy.ai/en/api/multi-image-to-3d), [web kılavuzu](https://docs.meshy.ai/en/webapp/image-to-3d), erişim 2026-11-04.

### 1.3 Kredi tablosu, doğrulanmış

Sunucunun 2026-10-12 notu bugünkü sayfayla aynıdır. Web sütunu ayrı bir sayfadadır ve belirgin fark taşır.

| İş | API kredisi | Web kredisi |
|---|---|---|
| `meshy-7.1`, `meshy-6`: yalnız ağ | 20 | 20 |
| + 2K ya da 4K doku | 30 | 30 |
| + 8K doku | 35 | 35 [çıkarım] |
| Ultra geometri (`2k`, `4k`, yalnız 7.1) | +5 | 25 fiyatında |
| **En kaliteli statik** | **40** | **40** [çıkarım] |
| `meshy-6-lite`: ağ, 2K | 5, 15 | 10, +10 |
| `meshy-t2`, `meshy-t2.5` (tek görsel): ağ, 2K/4K, 8K | 5, 15, 20 | T2: 5, +10 |
| `meshy-7.1` + `meshy-n1` dokusu | 30 | sayfada yok |
| Retexture | 10; 8K 15 | 10; 8K 15 |
| Remesh | 5 | **0** |
| UV Unwrap | 5 | sayfada yok |
| Rigging (yürüme ve koşu içinde) | 5 | **0** |
| Animation | Eylem başına 3, çağrıda ≤10 | **0** (kütüphane, ücretli plan) |
| Text to Motion | `prime` 10, `swift` 3 | Kredili, sayı yok |
| Convert, Resize | 1 | sayfada yok |
| Meshy içinden `gpt-image-2` | Metinle 9, görselle 12 | sayfada yok |

Başarısız iş 0 kredidir. Bekleyen iş silinince kredi döner; işleyen silinemez (409), biten silinince dönmez. Beğenilmeyen sonuç ücretlidir [çıkarım]. API dosyaları Enterprise dışında 3 gün durur: sonuç hemen indirilir.

**Godot'daki iş kayıtları (2026-10-25).** 26 model işi 40'ar (20 statik varlık, 6 insan), altı rig işi 5, sekiz hareket işi 3 kredi yazdı; toplam 1.094, plan sınırı (`budget_cap`) 1.100. Her işte `expires_at` bitişten tam 3 gün sonradır. Model işi 124–559 sn sürdü (ortanca 326); dağıtıcı en çok 8 işi birlikte yürüttü. İlk insan takımı (yedi kişi: dört chibi avcı, üç NPC; Meshy içinden `gpt-image-2` konseptiyle, 2K doku) stil değişince bırakıldı; kaydı olan dördü 50–59, toplam 224 kredi tuttu (`assets/_unused/characters_v1/*/meta.json`). [kaynak: dosya]

Kaynak: [API fiyatı](https://docs.meshy.ai/en/api/pricing), [web fiyatı](https://docs.meshy.ai/en/webapp/pricing), [hızlı başlangıç](https://docs.meshy.ai/en/api/quick-start), [varlık saklama](https://docs.meshy.ai/en/api/asset-retention), [Rigging API](https://docs.meshy.ai/en/api/rigging-and-animation), erişim 2026-11-04.

### 1.4 Planlar ve kredi başına dolar

| Plan | Fiyat | Kredi/ay | Kredi başına | API | Eşzamanlı iş |
|---|---|---|---|---|---|
| Free | $0 | 100 | | Yok, iş açılmaz | 1 |
| Starter | ₺440 (yalnız bazı ülkeler) | 250 | ₺1,76 | Yok | 5 |
| Pro | $20, ₺879 | 1.000 | $0,0200, ₺0,88 | Var | 10 |
| Premium | $40, ₺1.758 | 3.000 | $0,0133, ₺0,59 | Var | 30 |
| Ultra | $100 | 8.000 | $0,0125 | Var | 100 |
| Studio (1×) | $70, ₺3.080 | 5.500 havuz | $0,0127, ₺0,56 | Var | 60 |
| Studio (3×, 5×) | $210, $350 | 16.800, 28.000 | $0,0125 | Var | 60 |
| Enterprise | Özel | Özel | | Var | 100+ |

- En kaliteli statik varlık (40 kredi): Pro $0,80, Premium $0,53, Ultra $0,50. [çıkarım]
- Aylık kredi devretmez, satın alınan kredi süresizdir. Paket fiyatı yayımlı değildir; Starter, Pro ve Premium'a %20 indirim yazar.
- Yıllık fiyat çelişkili: SSS %20 der, sayfadaki sayılar aylıkla aynıdır.
- `meshy.ai/pricing` bu erişimde lira gösterdi. Dolar sayıları yardım sayfasındandır (2026-08-27). Ultra için Costbench 10.000 kredi yazar; satın almadan bakılmalı.

Kaynak: [fiyat sayfası](https://www.meshy.ai/pricing), [yardım: planlar](https://help.meshy.ai/en/articles/12062933-meshy-pricing-plans-free-pro-studio-enterprise), [hız sınırları](https://docs.meshy.ai/en/api/rate-limits), [Costbench](https://costbench.com/software/ai-3d-generation/meshy/), erişim 2026-11-04.

### 1.5 Ticari kullanım

- Ücretli planda çıktı müşterinindir, ticari kullanım açıktır. Ücretsiz planda çıktı Meshy'nindir, CC BY 4.0 ile atıf ister. Sahiplik başkasının hakkını çiğnememe koşuluna bağlıdır.
- Çıktının benzersizliği ve korunabilirliği garanti edilmez.
- Meshy'nin eklediği yapay zekâ işareti ve üst verisi silinemez. Hazırlama aracı bunu korumalıdır. Godot'daki ham dosyalarda görünür işaret bulunmadı; `glb_prepare.py` glTF JSON'u olduğu gibi yazar (§5.8, Belirsizlikler).
- Enterprise dışında girdi ve çıktı Meshy'nin eğitiminde kullanılabilir; `support@meshy.ai`'ye e-postayla çıkılır. Topluluk sayfasına konan CC0 olur.
- Kullanım politikası oyunları anmaz; kimliği belli kişiye şiddet ve kişilik hakkı yasağı vardır. Mete tarihî kişidir, sorun beklenmez [çıkarım].
- Steam'e çıkılırsa: Ocak 2026 güncellemesi (16–17 Ocak) bildirimi oyuncunun gördüğü ve duyduğu üretken içerikle sınırlar, arka plandaki verim araçlarını dışarıda bırakır. Godot'da buna Meshy modelleri ve ElevenLabs sesleri girer; yalnız Meshy'ye girdi olan konsept görseli oyuncuya görünmez [çıkarım].

Kaynak: [Meshy koşulları, 2026-09-19](https://www.meshy.ai/terms-of-use), [kullanım politikası](https://meshy.ai/acceptable-use-policy), [yardım: Image to 3D](https://help.meshy.ai/en/articles/9996860-how-to-use-the-image-to-3d-feature), [PC Gamer](https://www.pcgamer.com/software/ai/steam-updates-ai-disclosure-form-to-specify-that-its-focused-on-ai-generated-content-that-is-consumed-by-players-not-efficiency-tools-used-behind-the-scenes/), erişim 2026-11-04.

### 1.6 Rig, animasyon, hareket

| Yol | Kapsam | Çıktı | Kredi |
|---|---|---|---|
| API Rigging | Yalnız dokulu insansı. Belge ≤380.000 üçgen, MCP aracı ≤300.000 yüz der; +Z yönü; `height_meters` | Rigli FBX, GLB; `walking`, `running` (GLB, FBX, yalnız iskelet GLB) | 5 |
| Web, Humanoid | İşaretçiyle; indirmede iskelet şablonu, varsayılan Mixamo | FBX, GLB | 0 |
| Web, Quadruped Dog | Dört ayaklı, model sola bakar | Bir yürüyüş | 0 |
| Web, Smart Rig (Beta) | Yaratık, makine, nesne | Yalnız GLB, kütüphane yok | 0 |
| Animation | `rig_task_id` şart: dış rig giremez. `action_ids` ≤10, tek GLB'de ayrı klip; `change_fps` 24, 25, 30, 60 | GLB, FBX | 3 / eylem |
| Kütüphane | 600'den çok klip (sayfada en yüksek kimlik 696). Hepsi `/biped/`; at binme yok. `Archery_Shot` 224, `Sit_Cross_Legged` 362; Godot `Idle_3` 243, `Idle_4` 244 ve yerde bağdaş `Sit_Cross_Legged_on_Floor` 363'ü kullanır | | Liste ücretsiz |
| Text to Motion | Metin ≤400 harf, 2–10 sn; biped rig; dosya 3 gün | `prime` FBX, `swift` BVH | 10, 3 |

API sayfası dört ayaklıyı hiç anmaz, insansı olmayanı kapsam dışı sayar. Yüz kemiği ve kuyruk fiziği de yoktur. [çıkarım: API ile hayvan riglenmez]

**İskelet belgede yok, ama ölçülmüş.** İki bağımsız proje Meshy çıktısında 24 kemik bulmuş (biri 2026-10-18 tarihli deneme grubu); üç GitHub sayfası da bu turda açıldı, yazılanı doğruluyor. `mete.glb` ve Godot'daki ham rig dosyası (`_meshy_raw/mete/mete_rigged_character.glb`) bu turda okundu. Ham dosyada `Armature` düğümü 0,01 ölçeklidir ve üreteç `Khronos glTF Blender I/O v4.5.51`'dir: Meshy rig çıktısını kendisi Blender ile yazar. Adlar ikisinde de aynıdır:

```
Hips Spine02 Spine01 Spine neck Head head_end headfront
LeftShoulder LeftArm LeftForeArm LeftHand RightShoulder RightArm RightForeArm RightHand
LeftUpLeg LeftLeg LeftFoot LeftToeBase RightUpLeg RightLeg RightFoot RightToeBase
```

Parmak yok, omurga kalçadan yukarı `Spine02`, `Spine01`, `Spine`. `mixamorig:` öneki de görülmüş; web şablonuna göre ad değişebilir.

Kaynak: [Rigging API](https://docs.meshy.ai/en/api/rigging-and-animation), [web rig](https://docs.meshy.ai/webapp/guides/3d-model/rigging), [özellik sayfası](https://www.meshy.ai/features/ai-auto-rigging), [Animation API](https://docs.meshy.ai/en/api/animation), [kütüphane](https://docs.meshy.ai/en/api/animation-library), [Text to Motion](https://docs.meshy.ai/en/api/text-to-motion), [prime-game-art PR 216](https://github.com/xperiaroco2/prime-game-art/pull/216), [eldritch-tactics #158](https://github.com/klhall1987/eldritch-tactics/issues/158), [washed-ashore #96](https://github.com/chz160/washed-ashore/issues/96), erişim 2026-11-04.

### 1.7 Varyant, bütçeye indirme, biçim

- **Retexture ile varyant.** Aynı ağ, yeni doku: 10 kredi, 8K'da 15. `enable_original_uv: true` yazılır (belge varsayılanı `false`, MCP aracı `input_task_id`'de `true` der). Stil girdisi metin, tek görsel ya da 1–4 görüş. Burada `latest` Meshy 7'dir, 7.1 yok. `meshy-n1` 2K, 10 kredi. Kültür ve rütbe varyantı için en ucuz yoldur.
- **Remesh.** 5 kredi, 100–300.000, `triangle` ya da `quad`, `decimation_mode` 1–4. Çıktı: `glb, fbx, obj, usdz, blend, stl, 3mf`. **Dokunun taşınması belgede yazmıyor.** Yanıt `texture_urls` döner, web kılavuzu ise daha iyi sonuç için yeniden dokulamayı önerir. Bu yüzden +10 kredi ihtimali vardır, ölçülecek. T2 ağı remesh almaz. Delik varsa kaynak ağ bozuktur.
- **Üretim içinde indirme.** `should_remesh: true`, `save_pre_remeshed_model: true` hem oyun ağını hem ana kopyayı verir, fiyat tablosunda ek ücret görünmez. Godot'daki 26 iş `should_remesh: true` ve 4K geometriyle 40 kredi yazdı ve dokulu oyun ağı verdi: ayrı Remesh'in 5 kredisi gerekmez. [kaynak: dosya] `save_pre_remeshed_model` Godot'da denenmedi; ana kopyanın dokulu gelip gelmediğini belge yazmaz.
- **UV Unwrap.** 5 kredi, ≤40.000 yüz; çıktı dokusuz, gri malzemeli ağdır. Yalnız yeniden dokulanacak ağda.
- **Biçim.** Üretimde GLB, FBX, OBJ, USDZ, STL; 3MF istekle. Oyuna GLB girer: Godot'da glTF 2.0 önerilen biçimdir; sahne içe aktarıcısı `.glb.import` ayarlarıyla (`generate_lods`, `create_shadow_meshes`, dokular dışarı çıkarılır) kendi biçimine çevirir. Prototipte `GLTFLoader`.

Kaynak: [Retexture](https://docs.meshy.ai/en/api/retexture), [Remesh API](https://docs.meshy.ai/en/api/remesh), [web Remesh](https://docs.meshy.ai/webapp/guides/3d-model/remesh), [UV Unwrap](https://docs.meshy.ai/en/api/uv-unwrap), erişim 2026-11-04.

## 2. Tripo ve ötekiler

### 2.1 Tripo modelleri ve kredi

| Model | Kimlik | Yüz sınırı | Kredi: dokusuz, standart, ayrıntılı, 8K |
|---|---|---|---|
| H3.1 (varsayılan, en iyi geometri) | `v3.1-20260211` | 1,5M; Ultra 2M; quad ≤150k; Smart Low-poly 500–20.000 | 20, 30, 40, 50 (görsel, çoklu görüş); metin 10, 20, 30, 40 |
| P2.0 (oyun için, quad) | `P2-20260801` | 48–50.000 üçgen; 48–25.000 quad | 100, 110, 120, 130 |
| P1 (düşük üçgen) | `P1-20260311` | 50–20.000 | Sayfada ayrı sayı yok |

Ek: ayrıntılı geometri +20, quad +5, Smart Low-poly +10, parçalı üretim +20. **H3.1 en kaliteli: 50 + 20 = 70 kredi, $0,70.** P2 en kaliteli: 130 kredi, $1,30.

İşlem: doku 10, 10, 20, 30; retopoloji 10, 30, 35, 40; Smart UV 20; segmentasyon 40; biçim 5, 10. Görselden çoklu görüş 10, görüş düzeltme 5.

API: `https://openapi.tripo3d.ai/v3`, Bearer anahtar, görev kimliğiyle sorgu ya da webhook. Başarısız ve iptal iş ücretsiz.

Para: API'de 1 kredi = $0,01, en az $1 yükleme. Çin sitesi 2026-12-01'den ¥0,07 gösterir. Studio planları API'den ayrıdır; resmî sayfa 403 döndü, üçüncü taraf Pro ≈$20 ve 3.000, Max $90 ve 25.000, Team $110/koltuk yazar.

Ticari: yardım sayfasının arama özetine göre ücretli kullanıcı modellerin sahibidir ve eğitime girmez; ücretsizde çıktı Tripo'da kalır. Sayfa doğrudan açılmadı (403), koşul metni okunmadı.

Kaynak: [Tripo API fiyatı](https://developers.tripo3d.ai/en/pricing), [H3.1](https://developers.tripo3d.ai/en/models/v3-1), [P2.0](https://developers.tripo3d.ai/en/models/p2), [faturalama](https://developers.tripo3d.com/en/docs/billing), [Costbench](https://costbench.com/software/ai-3d-generation/tripo-ai/), [yardım: ticari kullanım](https://www.tripo3d.ai/help/privacy-policy/how-to-use-tripo-models-commercially), erişim 2026-11-04.

### 2.2 Tripo rig ve animasyon

- **Rig 25 kredi, denetim ücretsiz.** `rig_type`: `biped, quadruped, hexapod, octopod, avian, serpentine, aquatic, others`. `spec` (`tripo, mixamo, actorcore, unity, unreal, vrm`) yalnız biped içindir. Model: `v1.0-20240301` (yalnız biped, varsayılan), `v2.5-20260210` (yaratık), `v3.0-20260909` (hepsi; elle seçilir). Dış GLB alır, ≤150 MB.
- **Retarget 10 kredi / hareket, çağrıda ≤5.** Biped: v1.0 rigde 101, v2.5 ve v3.0 rigde 11 hazır hareket. Dört ayaklı yalnız `preset:quadruped:walk`. Kuş için hazır hareket listelenmiyor.
- **Bir dört ayaklı yürüyüşlü: 25 + 10 = 35 kredi, $0,35.** Dur, otla, koş, saldır yoktur: bunlar elle ya da kodla yapılır. Kemik adları belgede yok. [çıkarım]

Kaynak: [Auto Rig](https://developers.tripo3d.ai/en/docs/animations-rig), [Retarget](https://developers.tripo3d.ai/en/docs/animations-retarget), [Rig Check](https://developers.tripo3d.ai/en/docs/animations-rig-check), erişim 2026-11-04.

### 2.3 Karşılaştırma

| Ölçüt | Meshy 7.1 | Tripo H3.1, P2.0 | Üstün |
|---|---|---|---|
| En kaliteli statik | 40 kredi, $0,50–0,80 | H3.1 70 kredi, $0,70; P2 $1,30 | Yakın |
| Düşük üçgen doğrudan | T2.5, 15 kredi (8K 20), 100–30.000, yalnız üçgen | P2 110 kredi, quad, Smart Low-poly almaz; H3.1'de Smart Low-poly +10 (500–20.000 yüz) | Meshy ucuz, Tripo quad |
| Çoklu görüş | 1–4, ilk önden, 2K geometri | 2–4, anahtarlı (`front, left, back, right`) | Tripo biraz |
| İnsan rig | 5, yürüme ve koşu dahil, 24 kemik, kodda hazır eşleme | 25, her hareket 10 | **Meshy** |
| Hareket kütüphanesi | 600+ biped, 3 kredi | 101 ya da 11 biped, 10 kredi | **Meshy** |
| Dört ayaklı, kuş rig | API yok; web Quadruped Dog, Smart Rig | API var, tek yürüyüş (`walk`), kuşta hazır hareket yok | **Tripo**; ama kredisiz üçüncü yol başsız Blender betiğidir (§3) |
| Gömülü ışık | Meshy 7 kendiliğinden, Meshy 6 `remove_lighting` | `delight`, doku `v3.5-20260815` ile | Sınanacak |
| Varyant | Retexture 10, 15 | Doku 10–30, `model_seed` sabit | Yakın |
| Hız sınırı, saklama | Pro 10 iş; 3 gün | Belgede bu turda görülmedi | Bilinmiyor |

**Kalite.** Elde tek karşılaştırmalı ölçüm var: Nisan–Mayıs 2026, kör oylamada geometride Tripo v3.1 birinci, Rodin Gen-2.5 ikinci, Meshy 6 üçüncü. Yazar Meshy çalışanı, örnek sayısı yok, **Meshy 7.1 ve P2 denenmemiş**. Bu sayı bugünkü kararı taşımaz. Karar kendi üç varlığımızla sınanarak verilir (öneri 2).

**Karar (Godot).** İnsan için Meshy: rig 5 kredi, Godot hattı ve klip aktarımı hazır. Dört ayaklı için Meshy ağı ve başsız Blender betiği; Tripo rig yalnız karşılaştırma ya da tek yürüyüşü yeten tekil yaratık içindir. Durum taşıyan ve çok tekrarlanan için kod. [çıkarım]

Kaynak: [HackerNoon denemesi](https://hackernoon.com/how-i-stress-tested-3-ai-3d-generators-on-the-same-inputs-what-the-numbers-actually-show), [H serisi çoklu görüş](https://developers.tripo3d.ai/en/docs/generation-multiview-to-model/standard), [P serisi görsel](https://developers.tripo3d.ai/en/docs/generation-image-to-model/p), erişim 2026-11-04.

### 2.4 Ötekiler, kısaca

| Araç | Bilinen | Bu proje için |
|---|---|---|
| Rodin (Hyper3D) | Creator $30, ≈60 model; Business $120, ≈416 model ve API; tek kredi $1,5 | Blender MCP'de hazır araç. Fiyatı Meshy'nin üstünde, insan rig avantajı yok |
| Hunyuan3D | Barındırılan 3.x, resmî fiyat bu turda görülmedi. Açık ağırlık 2.1 lisansı AB, Birleşik Krallık, Güney Kore'yi dışlar; ≥1M aylık kullanıcıda izin ister | Oyun AB'de satılacaksa açık ağırlık kullanılmaz [çıkarım] |
| TRELLIS.2 | Microsoft, PBR; ağda küçük delik olabilir; üçüncü taraf 24 GB NVIDIA GPU yazar. Lisans proje sayfasında yazmaz, sayfa malzemesini akademik ve araştırma amaçlı sayar; MIT yalnız model kartı kopyalarında görüldü [doğrulanamadı] | M1 Pro'da çalışmaz, öncelik değil [çıkarım] |

Kaynak: [Hyper3D fiyatı](https://hyper3d.ai/pricing), [Hunyuan3D 2.1 lisansı](https://raw.githubusercontent.com/Tencent-Hunyuan/Hunyuan3D-2.1/main/LICENSE), [WaveSpeed](https://wavespeed.ai/blog/posts/hunyuan-3d-api/), [TRELLIS.2](https://microsoft.github.io/TRELLIS.2), erişim 2026-11-04.

## 3. Blender MCP

**Nedir.** Topluluk köprüsü, MIT, resmî Blender işi değildir. Blender eklentisi yerel bir soket açar, MCP sunucusu komut gönderir. Depo adı `mcp-for-blender` oldu. Bugünkü araçlar `execute_blender_code, look, get_scene_info, generate_3d, search_assets, import_asset` ve ayarlar. Bu oturumdaki araç listesi daha eskidir (`get_viewport_screenshot`, ayrı Hyper3D ve Hunyuan araçları): kullanılacaksa önce güncellenir. [çıkarım]

| Yetenek | Ne verir | Tanhu'da |
|---|---|---|
| Betikle modelleme (`execute_blender_code`) | `bpy` ile model, değiştirici, boolean | Godot'da `MeshKit` ve `Procedural3D` (prototipte `core/geo.js`) aynı işi çalışma anında, dosyasız yapar. Yalnız oyma, kabartma gibi kod zorlananda |
| Poly Haven | ≈2.400 CC0 HDRI, doku, model (API'de 2.387), anahtarsız | Foto gerçekçi, stile uymaz. Fon referansı ve kaya başlangıcı olabilir |
| Sketchfab, Poly Pizza | Model kütüphanesi; lisans model başına, CC BY atıf ister | Dönem nesnesi az, lisans takibi bedel. Son çare |
| Retopoloji | Decimate Collapse, Voxel, QuadriFlow | Otomatik yeniden örgü iyi eğilmez diyor kılavuz. Bu kamerada kabul edilebilir [çıkarım]. Statikte Decimate |
| Bake | Cycles Selected to Active; Diffuse yalnız Color ile ışıksız renk, Normal teğet uzayda | **En değerli iş.** 8K ana kopyayı düşük ağa pişirir, Meshy remesh dokuyu bozarsa çıkış yolu |
| Rig | Armature; Automatic Weights (bone heat) ya da betikle ağırlık | **İkinci değerli iş.** AI hayvanını bizim iskeletimize bağlar, pelerin ağırlığını düzeltir. Meshy ağı UV dikişlerinde binlerce adaya bölünür; Tanhu 1'in at aracı bu yüzden bone heat kullanmaz, ağı konuma göre kaynaştırıp bölge maskesiyle ağırlık verir (§3.1) |
| `generate_3d` | Rodin, Hunyuan3D, Meshy, Tripo; kendi anahtarınla ya da Premium | Meshy zaten doğrudan var |

**Bedel ve risk.**

- Kredi yok, ama her adım model çağrısı ve görüntü demektir; karmaşık iş parçalanmak zorunda (README). Süre ve belirsizlik kodla üretimden yüksektir.
- `execute_blender_code` Blender içinde her Python'u çalıştırır. Güvenli kip (`BLENDER_MCP_SAFE_MODE=1`) varsayılan kapalı.
- Soket parolasız, şifresiz: `localhost:9876` dışına açılmaz.
- Temel kullanım verisi varsayılan toplanır, `DISABLE_TELEMETRY=true` kapatır. Bu oturumdaki `execute_blender_code` şeması kullanıcı istemini telemetri için ister.
- Poly Haven indirmesi Blender arayüzünü kilitler. İki sunucu birden çalıştırılmaz.
- `.blend` ikilidir, tekrar üretim yoktur. Her işlem betiği `tools/blender/` altında saklanır. [kurgu]

**Bu projede nerede mantıklı.** Üretici olarak değil, Meshy ile Godot arasında son işçi olarak: (1) dört ayaklı ve kuşun iskeleti, ağırlığı ve yürüyüş klipleri (§3.1), (2) uzun giysi ağırlığı ve pelerin maskesi, (3) gerekirse ana kopyadan düşük ağa bake, (4) adlı kişilerde model başına denetim karesi. Toplu eşya üretiminde yeri yok. Godot'da Blender çağırmak kural dışı değildir (brief) ve kredi harcamaz. Tekrar üretilebilir iş için MCP yerine başsız betik (`Blender -b --python tools/blender/<iş>.py`) yazılır; MCP yalnız tek seferlik bakış ve deneme içindir [çıkarım]. Godot `.blend`'i doğrudan da içe aktarır, ama Blender'ın kurulu olmasını ister; GLB dışa aktarımı daha taşınırdır.

### 3.1 Dört ayaklı rig: üç yol

| Yol | Ne verir | Kredi | Godot'a giriş | Sınama sonucu |
|---|---|---|---|---|
| Meshy API | Rig yalnız dokulu insansı; insansı olmayan «uygun değil» | Yok | | Hayvan riglenmez [kaynak] |
| Meshy web | «Quadruped Dog»: model sola bakar, yalnız yürüyüş; «Smart Rig (Beta)»: yaratık ve nesne, yalnız GLB, kütüphane yok | 0, elle | GLB | Yürüyüş dışında klip yok; iskelet adları yazmaz [kaynak] |
| Tripo API | `rig_type: "quadruped"` (ve `avian`, `hexapod` ...), `model: "v2.5-20260210"` ya da `"v3.0-20260909"` elle seçilir; dış GLB ≤150 MB alır | Rig 25, her hareket 10 ($0,35) | GLB ya da FBX | Dört ayaklıda tek hazır hareket `preset:quadruped:walk`, kuşta yok. Dur, otla, tırıs, dörtnal yine elle [kaynak] |
| Başsız Blender betiği | Bizim iskeletimiz, betikle ağırlık, kodla yürüyüş döngüleri, NLA eylemi olarak GLB | 0; bedel emek | GLB: `Skeleton3D` + `AnimationPlayer` klipleri | Tanhu 1 bu yolu Meshy atında çalıştırdı (aşağıda); çıktı sprite idi, Godot'a GLB dışa aktarımı denenmedi [çıkarım] |

**Tanhu 1'deki çalışan örnek (yalnız teknik).** Tanhu 1 projesinin `tools/blender_horse.py`, `horse_gaits.py` ve `horse_weights.py` dosyaları (2026-11-04'te `projects/tanhu-2d/tools/` altında) Meshy'nin statik at ağını şöyle canlandırır: [kaynak: dosya]

- **İskelet:** 33 kemik, 30'u deforme eder: kök, gövde ve eyer (üçü deforme etmez), sırt, göğüs, sağrı, üç boyun, baş, iki kulak, beş kuyruk ve her bacakta dört kemik (üst, alt, incik, toynak). Döngüler: bekleme, yürüyüş, koşu.
- **Ağırlık:** bone heat yerine bölge maskesi. Ağ konuma göre kaynaştırılır; bacak toynaktan yukarı jeodezik uzaklıkla, kuyruk ucundan sağrıya, boyun ve baş omuzdan geçen düzlemin önüyle ayrılır; eyer, örtü ve kolan sırta katı bağlanır; zincir içinde ağırlık kemik parçasına ters uzaklıkla (üs 6) dağılır.
- **Yürüyüş:** duruşta IK ile yere basan toynak, salınımda elle konmuş anahtarlar, gövde, boyun ve kuyrukta harmonikler; her döngü kendi üstüne kapanır, adım boyu hızı belirler (ayak kaymaz).

Godot için aynı yöntem bir iskelet ailesine genelleşir: toynaklılar (at, deve, sığır, koyun, keçi, geyik, ceylan), köpek ve kurt, kedi, kemirgen [kurgu]. Betik klipleri `idle`, `walk`, `trot`, `gallop`, `graze` adlarıyla GLB'ye yazar; Godot'da `AnimationTree` hızla karıştırır. Tanhu 1'in adları, kadrosu ve atları alınmaz; yalnız yöntem alınır.

Kaynak: [mcp-for-blender](https://github.com/ahujasid/blender-mcp), [README](https://raw.githubusercontent.com/ahujasid/mcp-for-blender/main/README.md), [Poly Haven lisansı](https://polyhaven.com/license), [Sketchfab blog](https://sketchfab.com/blogs/community/restricting-generative-ai-use-of-free-models), Blender kılavuzu: [bake](https://docs.blender.org/manual/en/latest/render/cycles/baking.html), [retopoloji](https://docs.blender.org/manual/en/latest/modeling/meshes/retopology.html), [Remesh](https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/remesh.html), [Decimate](https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/decimate.html), [armature bağlama](https://docs.blender.org/manual/en/latest/animation/armatures/skinning/parenting.html), erişim 2026-11-04.

## 4. Kodla üretim

Aşağıdaki tablo Three.js prototipinin reposudur (`~/Code/tests/tanhu-programatic-test`); Godot'da bu dosyalar yoktur, karşılıkları §4.1'dedir. Sayılar dosyadan ya da tasarım belgesindendir. [kaynak]

| Dosya (prototip) | Ne üretir | Bütçe | Yapay zekânın veremediği |
|---|---|---|---|
| `character/folk.js`, `head.js`, `rig.js`, `looks.js` | Tek iskeletli kişi: beden, baş, saç, kıyafet | 13,9–24,8k, 3 çizim + 3 gölge | `aCloth` etek ve pelerin (yürüyüş, koşu, `uRide`), boyanan yüz, ≈40 jest ve taşıma, veri satırıyla çeşit |
| `character/mete.js` | GLB + `retarget()` | 60.592 üçgen, 7,2 MB, 2048² | Bu zaten dış modeldir |
| `character/horse.js` | Binilen at | 9.216 üçgen, 11 kemik, köşe başına tek kemik | `MountLike` yüzü, yürüyüş fazı, `seat`, `sway`, `hit`, seçeneklerle don ve koşum |
| `game/mounted.js` | Binme mantığı | Ağ yok | `three` bile istemez |
| `game/builders.js` | Üçüncü yurdun ustaları | Taşınan prop ≤1,2k | Adı yanıltmasın: ağ üreticisi değil, davranıştır |
| `world/structure*.js`, `camp.js` | 14 yapı türü, aşamalar | Yurt `hero` 76–129k, `winter` ≤34k, `closed` ≈3k, uzak 96; küçük yapı ≤6k; `KitField` ≤400 | `G` grupları ve `aStage`: adım adım kurulum, hasarda geri düşme, yanık, ok saplanması, iç oda |
| `world/yurt-designs.js`, `props.js` | 46 + 9 eşya işlevi, köşe renkli, tek ağda | Otacı içi 26.496, tekil ≤300 | `merge`, `aoY`; malzeme eklemez |
| `data/node-kinds.js`, `world/nodes.js` | 49 düğüm türü, 29 görünüş | Tür başına 28–700 üçgen, satır ≤60k, ≤15 çizim | `InstancedMesh` havuzu, tükenme biçimi (`stump`, `shrink`), ağaç devrilişi |
| `world/flora.js` | Çam ve kaya | Çam 4.770, 1.690, 430, 42 | Tohum, hücre, LOD |
| `game/projectiles.js` | Ok, taş | 36, 20 | Örnekli, ≤64 saplı ok |

`core/geo.js` ortak dildir: `surf, tube, lathe, blob, rbox, beam, merge, mergeStaged, aoY, tintBy`. Doku yok, köşe rengi var, `paintMaterial` fırçası yüzeyi böler. İndirme 0 MB, kredi 0, tohumla aynı sonuç, test edilebilir.

**Kodun en mantıklı olduğu yer.** Durum taşıyan (yapı, düğüm), çok tekrarlanan (kalabalık, sürü, orman), kemiği kurala bağlı (at, hayvan, kuş), küçük görünen (silah, alet, kamp eşyası). 33 m'de 1 m ≈53 px, Kuwahara 13 cm altını siler ([sanat-animasyon.md §9](sanat-animasyon.md)): kılıç 50 px'lik bir çizgidir.

**Kodun zayıf olduğu yer.** Yakın planda organik silüet, kabartma, süslü tekil nesne. Bu sınıfta yapay zekâ emeği düşürür. Mete bunun kanıtıdır. [çıkarım]

**Bütçe.** Tavanlar [architecture.md §7](../design/architecture.md) ve [sanat-animasyon.md](sanat-animasyon.md) önerisidir: kamp ≤4,85M üçgen, ≤520 çizim; iç harita ≤3,10M, ≤360; VRAM ≤480 MB; program ≤92. Bunlar tarayıcı prototipinin sayılarıdır; Godot'un bütçesi henüz yazılmadı, `godot.md`'ye girer [çıkarım].

### 4.1 Godot için

Godot projesinde kodla üretim bugün çevre, yedek görünüş ve efekttir; insan, at, yapı ve eşyanın ana görünüşü Meshy'dir. [kaynak: `game/scripts`, `game/shaders`]

| Betik | Ne üretir | Not |
|---|---|---|
| `scripts/world/procedural_3d.gd` (`Procedural3D`), `mesh_kit.gd` (`MeshKit`) | Kodla ağ: torna (`lathe`), kapsül, silindir, kutu; düğüm her açılışta yeniden kurulur, sahneye kaydedilmez | Meshy modeli yoksa yedek görünüş bunlarla çizilir |
| `scripts/world/meshy_prop.gd` (`MeshyProp`) | Meshy GLB'yi gerçek boyuna ölçekler, tabanını oturtur, `atw_textured` malzemesini paylaşır, Otağ kesiti (`cutaway`) | Yurt, ahır, at, eşya ve kaya bununla girer |
| `scripts/camp/yurt.gd`, `stable.gd`, `camp_prop.gd`, `horse.gd`, `chibi_character.gd` | Meshy varsa model, yoksa kodla sade sürüm | Kodla at boyun, kuyruk ve kulak eklemiyle oynar; Meshy at kemiksizdir, gölgelendiriciyle başını indirir, kuyruğunu sallar, nefes alır |
| `scripts/world/tree_kit.gd`, `forest.gd`, `rock_field.gd` | Meshy çam ve kayayı konuma göre kaynaştırır, dokuyu köşe rengine işler, LOD zinciri kurar; küçük kayalar ≈900 üçgen, `MultiMesh` | Prototipin «köşe rengine pişirme» önerisinin çalışan Godot hâli |
| `meadow.gd`, `path_network.gd`, `mountains.gd`, `terrain.gd`, `water.gd`, `village_lights.gd` | Çayır, çakıl, dağ, arazi, su, uzak ışık; çoğu karelere bölünmüş `MultiMeshInstance3D` | Çok tekrarlanan, kodla kalır |
| `scripts/world/fx.gd`, `shaders/flame`, `smoke`, `sky`, `water` | Duman dörtgeni, kıvılcım ve ateş böceği parçacığı, gök, su | Doku dosyası yok |
| `shaders/felt`, `rug` (`yurt.gd`, `rug.gd` kullanır); `kerege`, `shyrdak` (Otağ içi için yazılmış, bugün hiçbir betik yüklemiyor) | Keçe, halı, kafes, taban keçesi deseni | Kodla yurt ve halı bunlarla boyanır |

**Godot'da kodun en mantıklı olduğu yer.** Durum taşıyan (kurulan ve sökülen yurt, tükenen düğüm), çok tekrarlanan (çayır, uzak orman, sürü ve kalabalığın uzak katı), kuralla oynayan (kuş kanadı, kuyruk, bayrak) ve efekt. Görünüşü Meshy kampıyla eşleşmesi gereken yakın nesnede kod yedek kalır.

## 5. Yapay zekâ modeli oyuna nasıl girer

§5.1–5.7 prototipin (Three.js) hattıdır ve ölçüm olarak kalır. Godot'daki çalışan hat ve Godot karşılıkları §5.8'dedir.

### 5.1 Hat (prototip)

1. **Görsel.** `tools/imagegen/gen.sh` ile `art_src/assets/<grup>/<id>.png`. Zemin `remove-bg` becerisiyle silinir.
2. **Ana kopya.** Meshy 40 kredi. `art_src/assets/<grup>/<id>/master.glb`; `public/` altına girmez. Dosya 3 gün durur, hemen indirilir.
3. **Üçgen.** Remesh ya da üretim içi indirme (§1.7). T2.5 yolunda bu adım yoktur.
4. **Doku.** Remesh dokuyu bozduysa Retexture (+10) ya da Blender bake.
5. **Gömülü ışık** denetimi (§5.3).
6. **`tools/prepare-asset.mjs`** [kurgu]. `prepare-mete.mjs` kalıbı: animasyon ve teğet atılır, PBR haritaları düşer, doku küçülür, gerekiyorsa köşe rengine pişer, meshopt ve KTX2 uygulanır, yapay zekâ işareti korunur.
7. **Oyunda.** `paintMaterial`, LOD, örnekleme.
8. **Sınama.** 33, 44, 16 m kareleri, `renderer.info`, gizli bölme `perf()`, kış ve altı ışık durağı.

### 5.2 Üçgen ve doku hedefleri (prototip)

| Sınıf | Oyun üçgeni | Doku | Malzeme uzayı | Dayanak |
|---|---|---|---|---|
| Mete | 60,6k (var) | 2048² | `bindSpace` | `mete.js`, oluşturucu yakın planı |
| Adlı kişi | ≤15k, LOD1 ≤3k [kurgu] | 1024² | `bindSpace` | `Folk` 13,9–24,8k'nın altında |
| Kalabalık tipi | ≤1,2k | Köşe rengi | `crowd_t1` | [army.md §7.1](../design/army.md) |
| T0 hayvan | ≤4k; küçük av ≤1,2k; kartal ≤600 | Köşe rengi | `bindSpace` | `sanat-animasyon.md` öneri 5 |
| Küçük yapı, araba | ≤6k; uzak ≤400; araba LOD1 160–240 | 512² ya da köşe | `objectSpace` | `structures.md`, `travel.md` |
| Tekil anıt | ≤6k [kurgu] | 1024² | `objectSpace` | `act1.md` küçük yapı sınırı |
| Elde silah, alet | ≤800 [kurgu]; taşınan ≤1,2k | Köşe rengi | Taşıyanla aynı | `structures.md` prop satırı |
| Düğüm, küçük eşya | 28–700 | Köşe rengi | Örnekli, dünya uzayı | `economy.md` §11.3 |

**Neden düşük.** Mete 109.337 köşe, 60.592 üçgen: üçgen başına 1,80 köşe. Yapay zekâ UV'si parçalıdır, her dikiş köşe çoğaltır, iskelet köşe başına hesaplanır. Bu oran izlenir, hedef ≤1,2. [kaynak: dosya; hedef kurgu]

**Çizim.** Adlı kişi tek ağda 1 + 1 gölge. 16 kişide `Folk` 96 çizim, AI 32. Üçgen ≈290k yerine ≤240k. Bedeli 16 × 1024² doku, BC7'de ≈22 MB. [çıkarım]

### 5.3 Doku, sıkıştırma, gömülü ışık (prototip; gömülü ışık ortak)

Mip dahil bellek hesabı. [çıkarım]

| Boyut | RGBA (JPEG, WebP açılınca) | BC7 (UASTC) | BC1 (ETC1S) |
|---|---|---|---|
| 8192² | 358 MB | 89 MB | 45 MB |
| 4096² | 89 MB | 22 MB | 11 MB |
| 2048² | 22 MB | 5,6 MB | 2,8 MB |
| 1024² | 5,6 MB | 1,4 MB | 0,7 MB |
| 512² | 1,4 MB | 0,35 MB | 0,17 MB |

Godot'da aynı sütunlar içe aktarma kiplerine denk gelir: ilk sütun `Lossless` ve `Lossy` (JPEG kaynakta RGB8, %25 az), BC7 `VRAM Compressed` + `high_quality` (BPTC), BC1 varsayılan `VRAM Compressed` (S3TC DXT1). [kaynak: Godot belgesi; hesap]

- **8K oyuna girmez.** Prototipin tavanı 480 MB. 8K'nın işi temiz küçültme kaynağıdır. Fiyat farkı 5 kredi olduğu için ana kopyada kalabilir.
- **Yeterlilik.** `eyes` 16 m'de 1 m ≈110 px. 1024² bir kişiye ≈550 texel/m verir, 5 katı yeter. 512² kalabalıkta yeter. Mete'nin 2048²'si oluşturucu içindir. [çıkarım]
- **KTX2.** GPU belleğini düşürür, JPEG ve WebP açılınca ham yer kaplar. Taban renkte ETC1S, normal haritada UASTC yaygın seçimdir. Fırça ve Kuwahara ETC1S bozulmasını örter [çıkarım]. Kodda bugün `KTX2Loader` ve meshopt yok; three 0.187 içinde `libs/basis/basis_transcoder.*` ve `meshopt_decoder.module.js` hazır. `GLTFLoader.setKTX2Loader`, `setMeshoptDecoder` ve `detectSupport(renderer)` gerekir.
- **WebP.** İndirmesi küçüktür, bellekte ham yer kaplar. Az modelde kabul edilir: `mete.glb` 2048² JPEG ile 22 MB VRAM tutuyor. Adlı kişi sayısı artınca KTX2 gerekir. [çıkarım]
- **Gömülü ışık neden zararlı.** Güneş saatle döner (K20), kamera döner (K27). Dokudaki gölge sabit kalır, yanlış yöne düşer.

| Sıra | Yol | Bedel |
|---|---|---|
| 1 | Referans düz ışıklı üretilir (§6) | 0 |
| 2 | Meshy 7 dokusu: web kılavuzu ışığı kendiliğinden sildiğini yazar. `remove_lighting` yalnız `meshy-6` dokusunda çalışır: Retexture'da Meshy 7 ile gönderilirse yok sayılır, Image to 3D'de `meshy-6` dışı dokuyla gönderilirse 400 döner (Godot işleri göndermedi) | 0, sınanır |
| 3 | `meshy-n1`: yalnız görselden boyar, boyalı görünüşü en az bozan aday [çıkarım]; ama görseldeki ışık kalır | 30 (üretimde), 10 (Retexture) |
| 4 | Retexture `ai_model: "meshy-6"`, `remove_lighting: true`, `enable_original_uv: true`, 4K | +10 |
| 5 | Araçta düşük frekanslı parlaklığı bölerek düzleştirme [kurgu] | Kod |

**Sınama.** Üst ve alt yüz parlaklık farkı ≤%10, sol ve sağ aynı. Üç ışık durağında kare. [kurgu]

Kaynak: [KTX2Loader](https://threejs.org/docs/pages/KTX2Loader.html), [Khronos KTX](https://www.khronos.org/ktx/), [glTF Transform](https://github.com/donmccurdy/glTF-Transform), [glTF Transform CLI](https://gltf-transform.dev/cli), [AI Texturing](https://docs.meshy.ai/en/webapp/guides/3d-model/ai-texturing), [Retexture](https://docs.meshy.ai/en/api/retexture), erişim 2026-11-04.

### 5.4 `paintMaterial` uyumu (prototip)

`mete.js` kalıbı hazırdır: GLB malzemesinin `map`'i alınır, `paintMaterial({ map, bindSpace: true, brush: 0.2, term: 0.26, scale: 8, rim: 0.28, rampLo: -0.28, rampHi: 0.6, key })` yazılır.

| Durum | Uzay | `brush` | Neden |
|---|---|---|---|
| İskeletli | `bindSpace` | 0,2 | Fırça bedene yapışır, yürürken yüzmez |
| Statik tek | `objectSpace` | 0,2–0,3 | Nesneyle birlikte döner |
| Örnekli | Varsayılan (dünya) | 0,3 | `USE_INSTANCING` kolu gölgelendiricide var |
| Köşe renkli | `vertexColors: true` | 0,3 (`Folk`, `props` gibi) | Mevcut malzemelerle aynı |

- **Malzeme Lambert'tır.** `metalnessMap` ve `roughnessMap` kullanılmaz: atılır. `normalMap` `MeshLambertMaterial`'da vardır ama bu kamerada karşılığı yok, yalnız yakın plan kişide düşünülür. [çıkarım]
- **Üç kat boya.** Dokudaki fırça, `uBrush`, Kuwahara üst üste biner. Referans ince kıl ve ince darbe istemez, büyük boya kütlesi ister; `brush` düşük tutulur. `_test/camel.png` iyi bir başlangıç ama kürkü ince: 3B'de gürültü olabilir.
- **Program sayısı.** Anahtar `paint|uzay|key|hook karması`. Varlık başına değil sınıf başına `key` (`ai_char`, `ai_prop`) kullanılır. Kışta `world.matKey`. Tavan ≤92 program.
- **Paylaşım.** Doku ve malzeme önbellekte, `markShared`; `World.dispose` silmez.
- **Çift yüz.** Mete `DoubleSide` kullanır. Kapalı ağda ön yüz yeter, doldurma düşer. Ağ delikliyse kalır.
- **Zemin teması.** Küçük eşyada `aoY` taban koyuluğu kod eşyalarıyla aynı görünüşü verir.

### 5.5 LOD, örnekleme, köşe rengi (prototip)

- **Köşe rengine pişirme asıl kapıdır.** [kurgu, ölçülecek] ≤6k üçgenlik ağda doku köşeye örneklenir, UV ve doku atılır, köşeler kaynaşır. Sonuç `position, normal, color`: kodun ürettiği düzenin aynısı. 33 m'de 10 cm köşe aralığı ≈5 px, Kuwahara yarıçapı 3,1 px: fark görünmez. Kazanç: VRAM 0, indirme küçük, `merge` ile aynı ağda, `instanceColor` ile renk çeşidi.
- **`KitField` için şart.** `BatchedMesh` tek malzeme ister, ilk ağın öznitelik düzeni bağlayıcıdır ([sanat-animasyon.md §2](sanat-animasyon.md)). Dokulu ağ buraya giremez.
- **İskeletli örneklenmez.** `SkinnedMesh` çoğaltılamaz, 100 `Rig` 500 çizimdir ([army.md](../design/army.md)). Kalabalıkta AI ağı ancak T1 biçimine inerse girer: `aPart` en güçlü kemikten çıkarılır, ≤1,2k. Bu ayrı bir araç işidir, öneri değildir. [kurgu]
- **LOD.** `gltf-transform weld` + `simplify` (meshoptimizer, `ratio`, `error`); belge iskeletli ağı anmaz, `JOINTS` ve `WEIGHTS` ile sınanır. Statikte Blender Decimate Collapse da olur.
- **Sıkıştırma.** `meshopt` geometriyi ve animasyonu küçültür; en son adım olur. Mete 7,2 MB'ın 0,77 MB'ı doku, gerisi köşe verisidir: en büyük kazanç burada. [kaynak: dosya]

Kaynak: [simplify](https://gltf-transform.dev/modules/functions/functions/simplify), [glTF Transform CLI](https://gltf-transform.dev/cli), erişim 2026-11-04.

### 5.6 İnsan iskeleti: çakışmalar (prototip)

Meshy'nin 24 kemiği `BONE_MAP` ile 18 `Rig` ekleminden sürülür. Kod bir kez yazıldı, çalışıyor. Genelleştirirken: [kaynak: `mete.js`, `rig.js`]

| Konu | Bugün | AI insanında | Çözüm |
|---|---|---|---|
| Hareket | `retarget()` her kare kemiği yazar, `AnimationMixer` yok | Meshy klibi oynamaz | Rig yeter. Klip gerekirse karışım eklemi yazılır |
| Kemik adı | `BONE_MAP` | Aynı adlar eşleşir | API çıktısı ölçülür; web şablonu Mixamo olabilir |
| Bağlama pozu | `REST_DIR`, `HAND_FROM`, `SHOULDER_DROP`, `SOCKET_AT` Mete'ye özel. Ölçüm: üst kol −24,7°, ön kol −1,9° | El ve yuva kayar | Model başına ölçülür, veri satırına taşınır |
| Birim | `UNIT = 100`, Armature 0,01. Bu ölçek ve `mete.glb`'deki Blender üreteci Meshy'nin kendi rig çıktısından gelir (Godot ham dosyası, §1.6) | Ham GLB aynı ölçektedir | Araç yine ölçer |
| Kumaş | `Folk`'ta `aCloth`, `uRide`; Mete'de yok | Pelerin ve etek bacakla açılır, sürüşte at gövdesine girer (`sanat-animasyon.md` §11: %41 köşe, 32 cm) | Ağırlık kalçaya, `_CAPE` özniteliği (aynı belge, öneri 12). Model başına iş |
| Eyer | `seatHeight`, `ADULT.ride` | Bacak boyu değişince diz gövdeye girer | M9, M10 sınaması |
| Yüz | `paintFace`; ozanda `VISEMES` (`npc.js`) | Yüz dokuya pişer, ağız oynamaz | Yakın planda portre ve altyazı |
| Renk | `mete_regions.png` + renk ailesi | Her model yeni maske | Adlı kişi sabit renktir, maske gerekmez |
| Yükleme | `Folk` kurulumda kodla | GLB indirilir | Zon başına tembel yükleme |
| Parmak | `Folk` el geometrisi, `armMode: 'bow'` | Kemik yok | Yay tutuşu Mete gibi el yuvasından |

**Karar (prototip).** Kılık uzunsa AI insanın asıl bedeli kredi değil, bu tablodaki model başına iştir; prototipte yan karakter varsayılanı bu yüzden `Folk` idi. **Godot'da** `Folk` yoktur, Meshy insan hattı çalışır: yan karakter varsayılanı Meshy'dir, model başına iş ölçüm (`character_fit_tool.gd`), omuz düzeltmesi (`ShoulderRelax`) ve uzun giysi ağırlığıdır (§5.8). [çıkarım]

### 5.7 Hayvan iskeleti: çakışmalar (prototip)

- `Horse` 11 kemik, köşe başına tek kemik, yürüyüş `update`'te. `MountLike` yüzünü (`root, heading, g, sway, place, update, seat, shape`) binme ve ordu kullanır. Menü karesi değişmemelidir.
- `buildQuad` planı: T0 16 kemik ≤4k; T1, T2 `aPart` ile analitik gölgelendirici; aynı kesitlerden ([sanat-animasyon.md §3](sanat-animasyon.md)). Kademe geçişinde silüet atlamaz.
- Meshy API rig yok. Web Quadruped Dog kemik adını yazmaz. Tripo `quadruped` de yazmaz, `spec` yalnız biped içindir.
- **Sonuç.** Satıcı iskeleti oyunun sözleşmesine uymaz. Yapay zekâ hayvanı istenirse ağ alınır, iskelet bizimdir: Blender'da betikle ağırlık (Tanhu 1 yöntemi, §3.1); Automatic Weights Meshy'nin UV adalarına bölünmüş ağında uymaz. Kredi 40'ta kalır, bedel emektir.
- Kuş: T2 ≤80 üçgen, kanat analitik. Yapay zekâ ağı burada anlamsız. Kartal T0 ≤600 bile kodla kolaydır.

### 5.8 Godot için

**Hat (çalışıyor).** [kaynak: `game/README.md`, `game/tools`]

1. **Konsept.** `tools/imagegen/gen.sh --ref assets/_reference/style_mete.png` (ya da `menu_camp.png`) ile `assets/_concepts/<id>.png`; istem `asset_plan.json` satırı, `style_suffix` ve insanda `character_suffix`. Onay `<id>.ok` dosyasıdır.
2. **Model.** `tools/meshy_dispatch.py` onaylı konsepti en çok 8 eşzamanlı işle `tools/meshy_pipeline.py run <id>`'ye verir: `meshy-7.1`, 4K geometri, 8K doku, `should_remesh: true`, `triangle`, satırdaki `polycount`; insanda `pose_mode: "t-pose"`, rig (`height_meters`) ve plandaki klipler. Bütçe sınırı ve canlı bakiye her işten önce denetlenir, kimliği yazılmış iş ikinci kez açılmaz. Ham dosya `assets/_meshy_raw/<id>/` altındadır (`.gdignore`, Godot içe aktarmaz).
3. **Küçültme.** `tools/glb_prepare.py` dokuyu ffmpeg ile küçültür (8K → 4K ya da 2K); ağa, iskelete ve klibe dokunmaz.
4. **İnsan.** `tools/prepare_character.py <id>`: ana model ilk klibin GLB'sinden, öteki klipler `<id>_<rol>.res`, `meta.json`. Sonra `character_fit_tool.gd` (`<id>_fit.json`: zemin kaydırması, klip hızı, omuz açısı) ve oyuncu karakterinde `tools/bake_regions.py` (renk maskesi).
5. **İçe aktarma.** `.glb.import`: `meshes/generate_lods=true`, `create_shadow_meshes=true`, `ensure_tangents=true`, dokular dışarı çıkarılır (`gltf/embedded_image_handling=1`).
6. **Sahnede.** `MeshyProp` (statik), `CharacterAvatar` (insan), `Horse` (at); model yoksa kodla yedek.

**Karşılıklar ve düzeltilecekler.** [kaynak: Godot 4.7 belgesi ve proje dosyaları; «çözüm» satırları çıkarım]

| Konu | Prototip | Godot karşılığı |
|---|---|---|
| Doku belleği | KTX2, meshopt | Godot kaynak biçime değil içe aktarma ayarına bakar. 26 dokunun hepsi `Lossless` (`compress/mode=0`, `vram_texture: false`). Belge: `Lossless` ve `Lossy` VRAM'i düşürmez, `VRAM Compressed` 3B'nin varsayılanıdır ve 4–6 kat küçültür. «Detect 3D» dokuyu 3B'de görünce sıkıştırır; dokular `ShaderMaterial` (`atw_textured`) ile çizildiği için sezilmemiş olabilir [çıkarım]. Çözüm: `.import`'ta `compress/mode=2`, 4K kişi ve yapıda `high_quality` (BPTC). Bugün ≈0,94 GB, S3TC ile ≈0,16 GB, BPTC ile ≈0,31 GB [hesap: RGB8, mip dahil, 26 doku birden] |
| Ölçüm | `renderer.info`, `perf()` | `Performance.RENDER_TEXTURE_MEM_USED`, `RENDER_VIDEO_MEM_USED`, `RENDER_TOTAL_DRAW_CALLS_IN_FRAME`, `RENDER_TOTAL_PRIMITIVES_IN_FRAME` |
| LOD | `gltf-transform simplify` | İçe aktarıcı LOD'u meshoptimizer ile kendisi üretir; seçim ekran uzayındadır (düğümde LOD Bias, görüntüde `mesh_lod_threshold`). Meshy ağı UV dikişlerinde çift köşeli olduğu için üretilen LOD az sadeleşir (`tree_kit.gd` notu). Statikte `TreeKit` kaynaştırması ve köşe rengi; dokulu ve iskeletli ağda ikinci düzey için Meshy Remesh (5) ya da Blender Decimate [çıkarım]. `MultiMesh`'te bütün örnekler aynı LOD'dadır: uzak sürü ve orman karelere bölünür |
| Örnekleme | `InstancedMesh`, `BatchedMesh`, `KitField` | `MultiMeshInstance3D`; örnek başına evre ve renk `INSTANCE_CUSTOM` ile. Örnek tek tek kırpılmaz, kareye bölünür (çayır ve orman böyle) |
| Malzeme | `paintMaterial` | `atw_textured` (statik), `character_toon` (insan). Fırça gürültüsü dünya uzayındadır: yürüyen kişide ve hayvanda desen yüzer; prototipin `bindSpace` dersi Godot'ta UV ya da bağlama pozu uzayındaki gürültüyle uygulanır [çıkarım] |
| İnsan iskeleti | `BONE_MAP`, `retarget()` | Meshy `Skeleton3D` doğrudan kullanılır, klipler `AnimationPlayer`'dadır. Klip aktarımı `ClipRetarget` ile iskelet uzayında yapılır: Godot'nun `BoneMap` ve «Overwrite Axis» yolu dinlenme pozunu yeniden yazar, belge bunun kötü sonuç verebileceğini söyler; Meshy kişiden kişiye yerel ekseni değiştirir. T-poz bağlaması köprücüğü kaldırır: `ShoulderRelax` (`SkeletonModifier3D`) 14,1–18,0° indirir |
| Kumaş, kuyruk, yele | `aCloth`, `uRide`, `_CAPE` | Kemik zinciri varsa `SpringBoneSimulator3D` (4.7'de var; saç, kumaş, kuyruk; dallı zincir almaz). Meshy iskeletinde pelerin kemiği yoktur: ya Blender'da zincir eklenir ya pelerin maskesi köşe rengine yazılıp köşe gölgelendiricisiyle sallanır [çıkarım] |
| Hayvan | `Horse`, `buildQuad`, `MountLike` | `Horse` bugün Meshy statik ağ ve gölgelendiricidir. Binme ve yürüyüş için §3.1'in GLB'si; `AnimationTree` hıza göre `idle`, `walk`, `trot`, `gallop` karıştırır [kurgu] |
| Sürü ve kalabalık | T1, T2 `aPart` | Godot belgesi: kemikler CPU'da hesaplanır, binlerce iskeletli nesne olmaz. Yakındaki birkaç hayvan ve kişi `Skeleton3D`; uzak kat `MultiMeshInstance3D` ve köşe gölgelendiricisiyle (balık sürüsü yöntemi) ya da klipten pişirilmiş köşe animasyonu dokusuyla [çıkarım] |
| Biçim | GLB | glTF 2.0 önerilen; `.blend` doğrudan alınır ama Blender kurulu olmalı; FBX `ufbx` ile |
| Yapay zekâ işareti | İnceleme önerisi | Godot'daki ham dosyalarda görünür işaret yok: glTF `extras` yok, JPEG'de yalnız JFIF. `glb_prepare.py` glTF JSON'u korur, ffmpeg bir yorum satırı ekler. Koşul işaret silmeyi yasaklar; ham dosya `_meshy_raw`'da saklanır |

**Godot'da bugün üçgen ve doku.** İnsan 40–62k üçgen, 4096²; at 47–51k, 4096²; yurt 51k, ahır 44k, 4096²; kamp eşyası 10–26k, kaya ve çam 6–15k, 2048². Köşe/üçgen oranı 0,98–2,30 (Mete 1,80). Kamp çamları köşe rengine pişirilmiş LOD zinciriyle, çayıra dağılan küçük kayalar pişirilmiş ≈900 üçgenlik tek düzeyle (`MultiMesh`) çizilir; kahraman kayalar dokulu `MeshyProp`'tur. [kaynak: dosya]

Kaynak: [Importing images](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html), [Mesh LOD](https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html), [Using MultiMesh](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html), [Animating thousands of fish](https://docs.godotengine.org/en/stable/tutorials/performance/vertex_animation/animating_thousands_of_fish.html), [Retargeting 3D skeletons](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html), [SpringBoneSimulator3D](https://docs.godotengine.org/en/stable/classes/class_springbonesimulator3d.html), [Available 3D formats](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html), [Performance](https://docs.godotengine.org/en/stable/classes/class_performance.html), hepsi Godot 4.7 belgesi, erişim 2026-11-04.

## 6. Referans görsel kuralları

### 6.1 Girdi kuralları

| Kural | Dayanak |
|---|---|
| Tek nesne, sade zemin; zemin önceden silinir | [Meshy web](https://docs.meshy.ai/en/webapp/image-to-3d), [yardım](https://help.meshy.ai/en/articles/9996860-how-to-use-the-image-to-3d-feature) |
| ≥512² (blog ≥1040²); `gen.sh` 1536×1024 veriyor | Aynı; `art_src/assets/_test/camel.png` |
| Tam silüet, kırpma yok; sert perspektif yok, tele ya da düz bakış | Meshy web |
| Düz ve eşit ışık; koyu gölge kara leke bırakır; tek yanlı gölge yok | Meshy web, [çoklu görüş kılavuzu](https://help.meshy.ai/en/articles/16102789-meshy-multi-view-best-practices-angles-and-images) |
| A-poz: kollar ≈45° aşağı; T-poz: kollar yatay. Kol, bacak, gövde arasında boşluk | [Yardım](https://help.meshy.ai/en/articles/9996860-how-to-use-the-image-to-3d-feature), [web rig](https://docs.meshy.ai/webapp/guides/3d-model/rigging) |
| Metinle T-poz güvenilmez: görsel + `pose_mode`. Her kişide tutmayabilir | [Poz kılavuzu](https://help.meshy.ai/en/articles/10255659-how-to-generate-3d-models-with-a-pose-t-pose-or-custom-poses) |
| Çoklu görüş: ön, sol, arka, sağ; 45–90° ayrı; aynı boy, poz, ışık, üslup; ≤4. İyi tek görsel çoğu kez daha temizdir | Çoklu görüş kılavuzu |
| İyi girdide `image_enhancement: false` | Meshy web |

**Poz kararı.** Görsel A-poz, Meshy `pose_mode: "t-pose"`. Uzun kolluk ve kaftan A-pozda daha az bozulur [çıkarım]. Godot bu yolu altı kişide kullandı (görselde kollar ≈40° aşağı); T-poz bağlaması köprücükleri kaldırdı, `ShoulderRelax` gerekti [kaynak: `game/README.md`]. Sıradaki kişide `pose_mode: "a-pose"` denenir, omuz açısı `character_fit_tool.gd` ile karşılaştırılır [çıkarım].

**Pelerin ve uzun etek.** Görselde bedenden ayrı durmaz, rigde bacağa yapışır. Adlı kişi üretilecekse pelerinsiz görsel denenir, pelerin ayrı ağ olur [kurgu].

**Şeffaf zemin.** OpenAI kılavuzu `background: transparent`'ı 2.5 modelleri için yazar; `gpt-image-2` sayfası anmaz, üçüncü taraf hata döndüğünü yazar. Düz zemin istenir, `remove-bg` silinir.

Kaynak: [OpenAI görsel kılavuzu](https://developers.openai.com/api/docs/guides/image-generation), [gpt-image-2](https://developers.openai.com/api/docs/models/gpt-image-2), [APIYI](https://docs.apiyi.com/en/api-capabilities/gpt-image-2/overview), erişim 2026-11-04.

### 6.2 Ortak stil

`tools/imagegen/portraits.mjs` içindeki `STYLE` ateş ışığı ve kenar ışığı ister, büst keser: 3B'ye girmez. Üslup sözcükleri korunur, ışık düzleşir.

```
STYLE_3D = Soft hand-painted gouache with the feel of a Studio Ghibli concept study, large simple paint masses with fine brush texture, restrained warm earthy palette of ochre, rust, felt cream and umber. Flat, even, soft ambient light from all sides: no cast shadow, no contact shadow, no highlights, no rim light, no dark occlusion. Plain uniform light warm grey background (#d8d3cb) with nothing else on it and no ground plane. One subject only, complete and uncropped with a clear margin, long telephoto lens with no perspective distortion. Steppe world of the 3rd century BC. No text, no logo, no watermark, no frame, no modern items.
```

- Konu açık renkliyse (keçe, kar, kemik) zemin `#6f6a63` olur: düşük karşıtlıkta nesne zeminden zor ayrılır.
- İstemde bulunmayacak sözcükler: `turnaround`, `sheet`, `collage`, `multiple views`, `cinematic`, `dramatic`, `sunset`, `firelight`, `depth of field`.
- Stüdyo adı projenin `STYLE` satırından gelir. Meshy sahipliği hak ihlali olmamasına bağlar. Ticari sürümde ad çıkarılır, üslup öteki sözcüklerle taşınır. [çıkarım]
- **Godot'un konsept eki.** `game/tools/asset_plan.json` `style_suffix` iki referans görselle (`style_mete.png`, `style_camp.png`) çalışır ve düz ışık, gri zemin, gölgesiz ister: `STYLE_3D` ile aynı yöndedir. İki farkı var: «Ghibli-like» der (yukarıdaki not) ve «4th century steppe» der; oyun MÖ 3. yüzyıldadır, yeni konseptte `3rd century BC` yazılır. [kaynak: dosya]

### 6.3 Sınıf şablonları

**İnsan karakter.** 1024×1536. Meshy: tek görsel, `pose_mode: "t-pose"`.

```
Full-body reference of one person: {DESC}. Standing in a calm A-pose: arms straight and angled 45 degrees down and away from the body, palms facing the thighs, fingers together, clear gaps between arms and torso and between the legs, feet shoulder width apart pointing forward, head level, mouth closed, eyes ahead. Strict front view at chest height, visible from the top of the headgear to the soles. Clothing hangs straight with no wind. Empty hands, no weapons, no bags, no cape. {STYLE_3D}
```

**Hayvan.** 1536×1024. Meshy: tek görsel, poz görselden gelir.

```
Full-body reference of one animal: {DESC}. Exact side profile facing left, standing square with all four legs straight and separated, every hoof fully visible, neck relaxed, head level, mouth closed, tail hanging free and clear of the legs. No rider, no saddle, no load, no harness. Coat shown as large painted masses, not individual hairs. {STYLE_3D}
```

Kuş için son cümleler: `Wings folded, legs visible, standing.` Uçan biçim üstten ayrı görsel ister.

**Yapı ve çadır.** 1536×1024. Tek görsel.

```
One {DESC}, complete and standing alone, three-quarter view from 30 degrees above, door facing the lower left, whole roof and base inside the frame. No terrain, no people, no animals, no smoke, no snow, no fence, no other structures. Felt panels, lattice, ropes and poles shown as clear readable shapes. {STYLE_3D}
```

**Taşıt.** 1536×1024. Çoklu görüşe uygun: yan + 3/4.

```
One {DESC}, horizontal exact side view from axle height, whole vehicle inside the frame, both wheels complete and clearly separate from the body, shafts level. No draft animal, no driver, no cargo unless stated. Wood, felt and rope as large painted shapes. {STYLE_3D}
```

**Silah ve araç.** 1536×1024. Tek görsel. T2.5 uygun.

```
One {DESC}, laid out perfectly horizontal with the {tip or head} pointing right, exact side view, flat to the camera, whole object inside the frame with margin on both ends. Not held by anyone, no stand, no pile, no sheath unless stated. Real craft of the 3rd century BC steppe: {MATERIALS}. {STYLE_3D}
```

**Eşya ve malzeme.** 1024×1024. Aynı görsel, zemin silinince heybe simgesi olur.

```
One {DESC} as a small object study, centered, three-quarter view from 35 degrees above, complete and uncropped, filling about 70 percent of the frame. One object or one neat bundle, nothing scattered. {STYLE_3D}
```

**Çevre, ağaç.** 1024×1536.

```
One {SPECIES} tree, whole from root flare to crown tip, exact side view at eye level, trunk centered, foliage grouped in large painted clumps with background visible between the boughs. No fallen leaves, no grass, no terrain. {STYLE_3D}
```

**Çevre, kaya.** 1024×1024.

```
One {DESC} boulder, three-quarter view from 20 degrees above, complete with a flat base, no pebbles around it, no terrain, no moss unless stated. {STYLE_3D}
```

**Beceri simgesi.** 1024×1024. 3B gerekmez, ışık kısıtı yoktur. Dal başına Ordos hayvan üslubu `gorsel-dil.md`'dendir.

```
Square skill icon: {DESC} as one bold emblem in the Ordos bronze animal style, strong silhouette readable at 48 pixels, at most three tones, soft hand-painted gouache with visible brush texture, bronze and felt colours. Plain dark muted teal background (#1c2b2d) with a faint vignette. No text, no letters, no frame, no border, no logo.
```

**Durum simgesi.** 1024×1024. 3B gerekmez.

```
Square status icon: {DESC} as a single simple symbol, very high contrast, readable at 28 pixels, no fine detail, one warm tone on the plain dark muted teal background (#1c2b2d). Hand-painted gouache edge. No text, no letters, no frame, no border, no logo.
```

### 6.4 Çoklu görüş ne zaman

Yalnız yanları farklı olan varlıkta: tek omuz süsü, yan sadak, araba. Simetrik eşyada gerekmez.

| Yol | Bedel | Not |
|---|---|---|
| `gen.sh --ref front.png`: `Same subject, same pose, same proportions, same colours and light, exact {left side or back or right side} view.` | Plan kullanımı | OpenAI tekrarlayan öznede tutarlılığın garanti olmadığını yazar |
| Meshy `text-to-image`, `generate_multi_view: true`, `ai_model: "gpt-image-2"` | 9 kredi | Çoğu kez 3 görüş; `input_task_id` ile çoklu görsele girer |
| Tripo görselden çoklu görüş | 10 Tripo kredisi | Yalnız Tripo yolunda |

Kaynak: [Meshy Text to Image](https://docs.meshy.ai/en/api/text-to-image), [Tripo fiyatı](https://developers.tripo3d.ai/en/pricing), erişim 2026-11-04.

### 6.5 Meshy'ye girmeden kabul

1. Tek nesne, zemin düz, silinince kenar temiz.
2. Silüet tam, kenardan pay var.
3. Gölge ve ışık yönü yok: üst ve alt yüz parlaklığı yakın.
4. Kol, bacak, gövde boşlukları görülür (insan, hayvan).
5. Dönem dışı nesne yok: üzengi ([sanat-animasyon.md §11](sanat-animasyon.md)), modern kumaş, modern araç.
6. İnce kıl, ince ip yok; ≥15 cm okunur ayrıntı.
7. Metin, damga, çerçeve yok.

Godot'da kabulün izi `assets/_concepts/<id>.ok` dosyasıdır; `meshy_dispatch.py` yalnız onaylı konsepti Meshy'ye gönderir. [kaynak: dosya]

**Deneme görseli (prototip).** `art_src/assets/_test/camel.png` 1–5 ve 7'yi geçer, 6'da takılır: kürk darbeleri ve ipler ince. Örtü ve ip hayvana yapışık: rig düşünülürse örtüsüz görsel gerekir.

## 7. Maliyet formülü

### 7.1 Varlık başına

Sayılar API'nin 2026-11-04 fiyatıdır ve Godot'daki iş kayıtlarıyla tutar. «Meshy en kaliteli» her zaman `meshy-7.1`, 4K geometri, 8K dokudur.

| Sınıf | Formül (API) | Meshy en kaliteli | Web | Not |
|---|---|---|---|---|
| Statik, oyun ağı | 35 (8K) + 5 (4K geometri); indirme üretim içinde 0 | **40** | 40 [çıkarım] | Godot'daki 20 statik iş 40'ar |
| İnsan, rigli | 40 + rig 5 | **45** | 40 | Yürüme ve koşu içinde. Godot NPC'leri bir klip ekiyle 48, Mete üç klip ekiyle 54 |
| Her ek klip | +3 (bir istekte ≤10) | +3 | 0 (ücretli plan) | Aynı klip başka Meshy insanına `ClipRetarget` ile 0 kredi |
| İnsan, 10 klipli | 45 + 10 × 3 | **75** | 40 | |
| Metinden hareket | `prime` 10 (`swift` 3) + uygulama 3 | +13 | Kredili | 2–10 sn, biped |
| Hayvan, ağ | 40 | **40** | 40 | API rig yok |
| Hayvan, Blender iskeleti | 40 + 0 | **40** | 40 | Bedel emek (§3.1) |
| Hayvan, Tripo rig ve yürüyüş | 40 + Tripo 25 + 10 | 40 + 35 Tripo ($0,35) | 40 (Quadruped Dog) | Öteki hareketler elle ya da kodla |
| Küçük eşya | 40 | **40** | 40 | Oyuna yeter yol: T2.5 8K **20**, 2K 15 |
| Varyant | Retexture | **15** (8K), 10 (2K, 4K) | Aynı | `enable_original_uv: true`; ağ ve rig yeniden ödenmez |
| Sonradan yeniden indirme | Remesh | 5 | 0 | İkinci LOD ya da yeni üçgen hedefi için |
| Yeniden dokuma | Retexture | +10, 8K +15 | Aynı | Yalnız ayrı Remesh dokuyu bozarsa |
| Referans görsel | `gen.sh` | 0 | 0 | Meshy içinden `gpt-image-2` 9, görselle 12 (Godot'un ilk insan takımı bu yolla 12 ödedi) |
| 3B gerekmeyen | | 0 | 0 | Yalnız 2B |

Dolar: 40 kredi Pro $0,80, Premium $0,53, Ultra $0,50. 45 kredi $0,90, $0,60, $0,56. [çıkarım]

**Beğenmeme payı.** Başarısız iş ücretsizdir, beğenilmeyen değil. Godot'daki ölçüm: ikinci turdaki 26 varlığın hepsi tuttu; ilk insan takımı (yedi kişi, kaydı olan dördü 224 kredi) stil değişince bırakıldı. Toplama ×1,3 eklenir [kurgu]; pay her toplu üretimden sonra kayıtlardan güncellenir.

### 7.2 Tüm oyun için kaba toplam

**Yöntem.** `Toplam = Σ (adet × sınıf kredisi) × beğenmeme payı`. Adetler veriden sayılır; yeni tür eklenince tablo kendiliğinden büyür. Sitede kredi sütunu sınıftan hesaplanır, elle yazılmaz.

Adetler tasarım belgelerinden ve prototip verisinden sayılır; Godot'da bu sistemlerin çoğu henüz yoktur. Hayvanlar `fauna.md` yazılana dek [hayvanlar.md](hayvanlar.md) öneri 1 ve 2'den sayılır.

| Tür | Adet | Adet kaynağı | Kredi | Toplam |
|---|---|---|---|---|
| Karakter (Mete) | 1 | Godot'da var (54 harcandı); yeniden üretim bedeli | 45 | 45 |
| Yan karakter | 25 | `kadro.md`: 14 + 8 + 3 tanrı | 45 | 1.125 |
| Kalabalık tipi | 24 | 6 kültür × 4 rol [kurgu] | 45 | 1.080 |
| Evcil hayvan | 10 | `hayvanlar.md` öneri 1 | 40 | 400 |
| Yaban hayvan | 24 | `hayvanlar.md` öneri 2, memeliler | 40 | 960 |
| Kuş | 9 | Aynı | 40 | 360 |
| Balık | 2 | Aynı | 40 | 80 |
| Yurt ve çadır | 10 | `settlement-model.json` | 40 | 400 |
| Kalıcı yapı | 30 | `settlement-model.json`, 44 − 10 − 4 araba | 40 | 1.200 |
| Taşıt | 8 | `travel.md` | 40 | 320 |
| Silah | 36 | 15 bıçak + 10 yay + 7 ok + 3 sadak + sapan | 40 | 1.440 |
| Zırh, giysi, binek takımı | 41 | `GEAR` yuvaları | 40 | 1.640 |
| Alet | 11 | `TOOLS` + meşale | 40 | 440 |
| Eşya ve malzeme | 104 | `ITEM_ROWS` 170 − yiyecek, teçhizat, ok, alet | 40 | 4.160 |
| Yiyecek | 24 | `food` etiketi | 40 | 960 |
| Çevre | 35 | 29 düğüm görünüşü + flora [kurgu] | 40 | 1.400 |
| Kamp eşyası | 55 | `props.js` 9 + `yurt-designs.js` 46 | 40 | 2.200 |
| **Toplam** | **449** | | | **18.210** |
| Beceri, durum, arayüz, portre, efekt | 93 + ≈30 + küçük setler | `SKILLS`; portre Godot'da yok | 0 | 0 |

**Senaryolar.** [çıkarım]

| Senaryo | Kredi | Pro | Premium | Ultra |
|---|---|---|---|---|
| Hepsi Meshy, en kaliteli | 18.210 | $364, ₺16.007 | $243, ₺10.671 | $228 |
| Aynısı, 50 insana 10 klip | 19.710 | $394 | $263 | $246 |
| Hepsi `meshy-t2.5` 2K, insan rigli | 6.985 | $140 | $93 | $87 |
| **Godot için önerilen karma** (aşağıda), payla | **12.628** | **$253** | **$168** | $158 |

Aylık kredi devretmez: 18.210 kredi 7 ay Premium ($280), 3 ay Ultra ($300) ya da bir ay Studio 5× ($350, 28.000) demektir; önerilen karma 5 ay Premium ya da 2 ay Ultra ($200). Aynı iş Tripo'da H3.1 en kaliteli + Smart Low-poly ve 50 insana rig ile ≈37.170 kredi, $372 (bu iki seçeneğin birlikte çalıştığı sınanmadı).

**Godot için önerilen karma.** Her satır §8'deki en mantıklı yoldan gelir; kod ve yalnız 2B satırları 0'dır. Adetler [kurgu]; liste sitede kullanıcı işaretler.

| Kalem | Adet | Kredi | Toplam |
|---|---|---|---|
| Adlı kişi (Meshy insan, rigli) | 25 | 45 | 1.125 |
| Yeni ortak klip türü (bir kez, sonra aktarım) | 8 | 3 | 24 |
| Kalabalık tabanı ve Retexture varyantı | 6 + 18 | 45, 15 | 540 |
| Evcil hayvan ağı (at hazır) ve yak çeşidi | 8 + 1 | 40, 15 | 335 |
| Yaban hayvan ağı ve üç görünüş çeşidi (`izubra`, `bharal`, `corsac`) | 23 + 3 | 40, 15 | 965 |
| Kartal ve doğan çeşidi (öteki kuşlar kodla) | 1 + 1 | 40, 15 | 55 |
| Öteki kültürlerin yurt ve çadır kabuğu (Hun hazır) | 6 | 40 | 240 |
| Kalıcı yapı kabuğu (ahır hazır) | 29 | 40 | 1.160 |
| Taşıt gövdesi (teker kodla) | 8 | 40 | 320 |
| Ünlü silah (7.1) ve öteki silah (T2.5 8K; yay hazır) | 8 + 27 | 40, 20 | 860 |
| Takılan teçhizat (başlık, sadak, kın) ve kılık varyantı | 15 + 26 | 40, 15 | 990 |
| Alet (T2.5 8K) | 11 | 20 | 220 |
| Dünyada ortak yığın | 10 | 40 | 400 |
| Çevre kahraman türü (iki çam, iki kaya hazır) | 31 | 40 | 1.240 |
| Kamp ve iç eşya (12 hazır; halı ve keçe kodla) | 30 | 40 | 1.200 |
| Kopuz (dombranın yerine, #55) | 1 | 40 | 40 |
| **Toplam** | 296 | | **9.714**; ×1,3 = **12.628** |

**Varyant kazancı.** 24 kalabalık tipi 6 ağ + 18 Retexture ile 540 kredidir, 1.080 değil. Silah ve kılık ailesinde aynı mantık. [çıkarım]

**Görsel maliyeti.** Her satıra görsel: ≈572 adet (449 + 93 + ≈30), kredi 0, plan kotası. Godot'da 26 konsept ve iki yeniden deneme ≈37 dakikada çıktı, ilk denemeden sonrası ≈26 dakikada (dosya saatleri): görsel başına ≈58–79 sn, ≈572 görsel ≈9–13 saat eder, kota sınırı ayrıca. Prototipte 24 portre 21 dakikada çıkmıştı (≈52 sn). [çıkarım]

## 8. Karar matrisi

Matris Godot içindir (2026-11-04). Kredi sütunu her satırda Meshy'nin en kaliteli en son modeliyle (`meshy-7.1`, 4K geometri, 8K doku, API) bedeldir, en mantıklı yol başka olsa bile: statik 40, rigli insan 45, klip başına 3, Retexture varyantı 15. Yol sütunundaki ilk ad varsayılandır. «Bugün» sütunu `game/`'in hâlidir ([oyun-durumu.md](../design/d3/oyun-durumu.md)). Prototip için yazılmış eski matris §4 ve §5.1–5.7'deki ölçümlere dayanıyordu; Godot'da `Folk`, `buildQuad`, `StagedStructure` ve `KitField` olmadığı için yol seçimi değişti. [çıkarım; kredi kaynak]

| Tür | Adet | 3B gerekli mi | Godot'da bugün | En mantıklı yol (Godot) | Neden | Meshy en kaliteli kredi |
|---|---|---|---|---|---|---|
| Karakter (Mete) | 1 | Evet | Var: Meshy 7.1, rig, üç klip (54 kredi harcandı); renk maskesi, `_fit.json` | Meshy (bitti); sürüş için pelerin ağırlığı Blender ya da Godot araç betiğiyle | Oluşturucu yakın planı, `AnimationPlayer` klipleri, `ShoulderRelax` hazır | Rigli 45; klip 3; metinden hareket 13 |
| Yan karakter | 25 | Evet | Kısmen: beş Meshy kişi (`hero_f`, ana, baba, çocuk, ozan); kodla insan yalnız chibi yedeği | Meshy (görselden, rigli) + ortak klip `ClipRetarget` ile | Godot'da `Folk` yok; hat, ölçüm aracı ve klip aktarımı hazır. Kişi başına iş: uzun giysi ağırlığı, omuz açısı | Rigli 45; klip 3; varyant 15 |
| Kalabalık tipi | 24 | Evet | Yok | Meshy taban insan (6) + Retexture (18); yakında `Skeleton3D`, uzakta `MultiMeshInstance3D` ve köşe gölgelendiricisiyle hareket | Godot belgesi: kemikler CPU'da, binlerce iskelet olmaz; varyant ağ ve rig ödemez | Rigli 45; varyant 15 |
| Evcil hayvan | 10 | Evet | Kısmen: iki at Meshy statik, gölgelendiriciyle bekleme (`horse.gd`); kodla at yedeği | Meshy ağı + başsız Blender betiğiyle iskelet, ağırlık, yürüyüş (§3.1) → GLB; uzak sürü `MultiMesh` | Meshy API hayvan riglemez; Tripo yalnız `walk` verir; Blender betiği kredisiz ve tekrar üretilir | Statik 40; varyant 15; Tripo yolu ayrıca 25 + 10 Tripo kredisi ($0,35) |
| Yaban hayvan | 24 | Evet | Yok | Aynı yol; iskelet ailesi ölçeklenir (toynaklı, köpek ve kurt, kedi, kemirgen) [kurgu] | Av, kaçış ve sürü davranışı yürüyüş ister | Statik 40; varyant 15 |
| Kuş | 9 | Evet, küçük | Yok | Programatik (GDScript ağı, köşe gölgelendiricisiyle kanat, `MultiMesh`); kartal yakın planda Meshy ağı + gölgelendirici | Gökte küçük; kemiksiz kanat çırpma GPU'da (balık sürüsü yöntemi); Tripo kuşa hareket vermez | Statik 40 |
| Balık | 2 | Hayır | Yok | Yalnız 2B (tutulan balık simgesi); suda gölge kodla | Buz ve ağ işi simgeyle okunur | Statik 40 (gerekirse) |
| Yurt ve çadır | 10 tür; 7 kültür, 3 boy (#32) | Evet | Var: Hun yurdu Meshy, kodla yurt yedeği (`yurt.gd`), Otağ kesiti gölgelendiricisi | Kurulan ve sökülen yurt kodla (parametrik `Yurt`: kültür, boy, aşama; `felt`, `kerege` gölgelendiricileri); menü, sinema ve uzak NPC kampında kültür başına Meshy kabuğu | Aşama, söküm, hasar, oda kesiti durum taşır; Meshy tek ağ verir. Üç boy ölçektir, ağa üçgen eklemez (`cadir-otag.md`) | Statik 40 kültür başına; varyant 15 |
| Kalıcı yapı | 30 | Evet | Kısmen: ahır Meshy | Meshy kabuk + kodla iskele ve aşama örtüsü [kurgu] | Görünüş Meshy kampıyla eşleşir; aşama kod işidir | Statik 40 |
| Taşıt | 8 | Evet | Yok | Meshy gövde + kodla teker ve oklar | Meshy tek ağ verir; teker ayrı dönmeli | Statik 40; teker de Meshy ise +40 |
| Silah | 36 | Evet, küçük | Kısmen: yay Meshy | Meshy T2.5 (doğrudan düşük üçgen); yakın plan ve ünlü silahta 7.1; elde `BoneAttachment3D` | 27 m'de küçük; oluşturucu 6 m'ye yaklaşır | Statik 40; T2.5 20 (8K) ya da 15 |
| Zırh, giysi, binek takımı | 41 | Kısmen | Yok: kılık modelin içindedir | Yalnız 2B simge; bedende kılık takımı Retexture, başlık, sadak ve kın Meshy ve `BoneAttachment3D` | Meshy insanı tek ağdır, giysi ayrı parça değildir | Statik 40; varyant 15 |
| Alet | 11 | Evet, küçük | Yok (balta odun yığınının içinde) | Meshy T2.5, elde `BoneAttachment3D` | Jestle eşli, elde görünür | Statik 40; T2.5 20 |
| Eşya ve malzeme | 104 | Çoğu hayır | Kısmen: sandık, çuval, heybe Meshy | Yalnız 2B simge; dünyada az sayıda ortak yığın Meshy | Heybede simge yeter; hepsi Meshy olsa 4.160 kredi boşa gider | Statik 40 (gerekirse) |
| Yiyecek | 24 | Hayır | Yok | Yalnız 2B; sofrada kazan ve kap Meshy | Ekranda çok küçük, tüketilir | Statik 40 (gerekirse) |
| Çevre | 35 | Evet | Var: Meshy çam ve kaya (köşe rengine pişirilmiş, LOD zinciri, `MultiMesh`); kodla vadi ladini, kaya, çayır, dağ, su | Meshy kahraman tür + `TreeKit` pişirmesi; uzak ve çok tekrarlanan kodla | Köşe rengi UV istemez, LOD sadeleşir; `MultiMesh` kare başına tek çizim | Statik 40 |
| Kamp eşyası | 55 | Evet | Var: 12 Meshy eşya (`camp_prop.gd`), kodla yedek | Meshy (7.1 ya da T2.5) + `MeshyProp`; halı ve keçe gölgelendiriciyle; `dombra` kopuzla değişir (#55) | Kamp görünüşü Meshy'dir | Statik 40; T2.5 20 |
| Beceri simgesi | 93 | Hayır | Gerekmez | Yalnız 2B (`gpt-image-2`) | Düz simge | 0 |
| Durum simgesi | ≈30 | Hayır | Gerekmez | Yalnız 2B | 28 px'te okunmalı | 0 |
| Arayüz | Küçük set | Hayır | Var: logo (`assets/title`), yazı tipleri, `UIKit`, kitap gölgelendiricisi; logo ve arayüz takımı Tanhu 1'den gelir | Yalnız 2B ve kod | Meshy gerekmez | 0 |
| Portre | 24 | Hayır | Yok (prototipte 24 `webp`) | Yalnız 2B (`gpt-image-2`) ya da Meshy modelinden `SubViewport` çekimi; oluşturucunun döner tablası (`creator_turntable.gd`) bu düğümü zaten kullanır [kurgu] | Kişiler sayfası ve diyalog | 0 |
| Efekt | Küçük set | Hayır | Var: alev, duman, gök, su gölgelendiricileri; kıvılcım ve ateş böceği (`fx.gd`) | Programatik (gölgelendirici, `GPUParticles3D`) | Ağ değil, zamanlı çizim | 0 |

## Oyuna öneriler

Öneriler Godot içindir. Kod işleri `godot.md`'ye yazılır; bu belge kodu değiştirmez.

1. **Kural (Godot).** Brief'in kuralı geçerlidir: Godot'da Meshy ve Blender serbesttir, kredi harcayan her toplu üretim önce kullanıcıya adet, sınıf ve toplam krediyle sorulur. Prototip için önerilen K14 eki Godot'da gereksizdir: Mete dışındaki her dış model zaten `asset_plan.json`'da bir satırdır. Varlıklar sayfasında işaretlenen satır plana girer. [kurgu]
2. **Açık kalan üç yolun denemesi.** Godot insanı, statik eşyayı, yapıyı ve doğayı 26 işle sınadı. Sınanmayan üç yol: (a) `camel`: Meshy statik 40 ve başsız Blender betiğiyle iskelet ve beş klip: bekleme, yürüyüş, tırıs, dörtnal, otlama (0 kredi); aynı ağ Tripo'da rig 25 ve `walk` 10 ile karşılaştırılır ($0,35). (b) `cart_felt`: Meshy gövde 40, teker kodla. (c) Uzun kaftanlı bir adlı kişi: 45 ve bir klip 3; at sırtında etek ve pelerin sınanır. Meshy 128 kredi, Tripo 35 kredi. Ölçüt: ayak kayması, 27 m ve 6 m'de boyalı görünüş, `RENDER_TEXTURE_MEM_USED`, at üstünde giysi. Toplu hayvan üretimi bu denemeden önce açılmaz. [kurgu]
3. **Site alanları.** Satır: `id, group, name, image, need3d, has3d, path, creditClass, count`. Kredi `creditClass`'tan hesaplanır: `static` 40, `human` 45, `clip` 3 (ek klip başına), `animal` 40 (Blender iskeleti 0; Tripo yolu ayrıca $0,35), `small_t25` 20 (8K) ya da 15, `variant` 15, `none` 0. Fiyat değişince tek yerden düzelir. Sayfa başında «2026-11-04 API fiyatı» yazılır. `has3d` Godot'daki `assets/<klasör>/<id>/<id>.glb`'den okunur.
4. **Görsel üretici.** Godot'da hazır: `game/tools/imagegen/gen.sh` ve `asset_plan.json`. Yeni varlık plana satır olarak girer (`id`, `kind`, `dir`, boy, `polycount`, `refs`, istem); `style_suffix`'teki «4th century steppe» «3rd century BC steppe» olur; onay `.ok` dosyasıdır. Önce 20 satır denenir, stil onaylanır. Sitedeki görseller aynı konseptlerdir.
5. **Hayvan aktörü.** `CharacterAvatar` kalıbıyla bir `AnimalAvatar` [kurgu]: `assets/animals/<id>/` altındaki rigli GLB'yi yükler, hıza ve duruma göre `AnimationTree` ile karıştırır, model yoksa `Horse` gibi kodla yedeğe düşer. İkinci rigli hayvan gelmeden yazılmaz.
6. **Doku içe aktarma ayarı.** Meshy dokuları `compress/mode=2` (VRAM Compressed) olur; 4K kişi ve yapıda `compress/high_quality=true` (BPTC). Küçültme `glb_prepare.py`'de kalır ya da Godot'nun `process/size_limit` ayarına geçer. Önce ve sonra `Performance.RENDER_TEXTURE_MEM_USED` ölçülür. Yalnız `.import` ayarıdır, oyun koduna dokunmaz.
7. **Köşe rengine pişirme.** Godot'da çam ve kayada çalışıyor (`TreeKit`). Aynı yol dağınık küçük nesneye (taş, odun, çalı) genişler; fıçı ve sandık gibi yakın eşya dokulu kalır. Sınama: 27 m ve 6 m'de dokulu sürümle yan yana. [kurgu]
8. **Hesap güvenliği.** Meshy anahtarı yalnız `MESHY_API_KEY` ortam değişkeninden ya da `--env-file` satırından okunur, yazdırılmaz (`meshy_pipeline.py`). Eğitimden çıkış e-postası kullanıcı kararıdır. Blender MCP kullanılırsa `BLENDER_MCP_SAFE_MODE=1`, `DISABLE_TELEMETRY=true`, yalnız `localhost`.
9. **Ham dosya saklama.** Godot'da var: `assets/_meshy_raw/<id>/` ana kopya (8K), `meshy.json` iş kimlikleri, `task_*.json`, önizlemeler, `.gdignore`. API dosyası 3 gün sonra gider; yeniden üretim yeniden ödemedir.
10. **Kopuz (#55).** Godot'daki `dombra` eşyası ve ozanın elindeki çalgı kopuzla değişir: `kopuz.md` tarifine göre yeni konsept, Meshy 40 kredi; ateş başındaki `Dombra` düğümü yeni modele bağlanır. Kod işi `godot.md`'ye girer.

## Belirsizlikler

- Ayrı Remesh çağrısının dokuyu nasıl taşıdığı belgede yok; o yolda +10 ihtimali açık. Üretim içi indirmede doku gelir (Godot'daki 26 iş).
- Meshy 7'nin ışığı kendiliğinden silmesi satıcı beyanıdır; boyalı referansta ölçülmedi. `meshy-n1` iki günlük, üçüncü taraf deneyimi yok.
- Meshy 7.1 ve Tripo P2 için bağımsız kalite ölçümü bulunamadı. Tek deneme Meshy çalışanınındır ve eski modellerle yapılmıştır.
- 24 kemik API belgesinde yazmıyor. İki dış proje, `mete.glb` ve Godot'daki altı ham rig dosyası aynı; `mixamorig:` öneki web şablonundan gelebilir. Yeni çıktıda yine ölçülür.
- Godot'daki ham dosyalarda görünür yapay zekâ işareti yok (glTF `extras` yok, JPEG'de yalnız JFIF). Dokuya gömülü görünmez bir filigran olup olmadığı bilinmiyor; koşul silmeyi yasakladığı için ham dosya saklanır.
- Godot'da dokuların neden `Lossless` kaldığı sınanmadı; «Detect 3D»nin `ShaderMaterial`'da tetiklenmediği çıkarımdır.
- Blender betiğinin Godot'a GLB ve klip olarak dışa aktarımı denenmedi; Tanhu 1 aynı yöntemle sprite üretti. Bölge maskesinin deve, koyun, kurt gibi öteki gövdelerde tutup tutmadığı bilinmiyor.
- Godot'nun içe aktarmada ürettiği LOD'un iskeletli Meshy ağında ne kadar sadeleştiği ölçülmedi. Fırça gürültüsünün yürüyen ağda yüzmesi gözle sınanmadı.
- Plan sayıları: Ultra 8.000 ve 10.000 çelişkisi; yıllık indirim çelişkisi; kredi paketi fiyatı yok; Starter'ın dolar fiyatı yok.
- Tripo resmî plan sayfası ve koşullar 403 döndü; plan sayıları üçüncü taraftan, ticari hak arama özetinden. P1 fiyatı ayrı görülmedi. H3.1'de ayrıntılı geometri ile Smart Low-poly'nin birlikte çalıştığı sınanmadı.
- Hunyuan3D 3.x resmî fiyat ve lisansı, Rodin kredi başına bedel bu turda birincil kaynaktan okunmadı. TRELLIS.2'nin lisansı resmî sayfada yazmıyor.
- `gen.sh` ChatGPT planındaki `imagegen` aracını sürer. Aracın bugün `gpt-image-2` mi 2.5 mi olduğu dışarıdan bilinemiyor (tek kaynak 2026-09-08'de 2.5'e geçtiğini yazıyor). Plan kotası da yayımlı değil.
- Kalabalık (24), çevre (35), durum simgesi (≈30) adetleri ve Godot önerilen karmasının adetleri kurgudur. `docs/design/fauna.md` hâlâ yok; hayvan adetleri `hayvanlar.md`'den sayıldı. II. Perde sonrası kadro sayılmadı.
- Texel hesabı ölçülmedi. Rigify sayfası bu turda açılamadı; hedef iskelet bizim olduğu için kullanılması beklenmiyor.
- Bu turda Meshy çağrılmadı: kredi sayıları belgeden ve Godot'daki 25 Ekim iş kayıtlarından okundu, yeni iş açılmadı.

## Kaynaklar

Bütün web kaynaklarına erişim tarihi 2026-11-04.

**Godot projesi (`game/`).** `README.md`; `tools/asset_plan.json`, `meshy_pipeline.py`, `meshy_dispatch.py`, `glb_prepare.py`, `prepare_character.py`, `bake_regions.py`, `imagegen/gen.sh`; `assets/_meshy_raw/*/meshy.json`, `task_*.json`, `dispatch.log`, ham GLB dosyaları; `assets/_unused/characters_v1/*/meta.json`; `assets/**/*.import`; `assets/_concepts/` (dosya saatleri); `scripts/world/meshy_prop.gd`, `tree_kit.gd`, `forest.gd`, `rock_field.gd`, `meadow.gd`, `procedural_3d.gd`, `mesh_kit.gd`, `fx.gd`; `scripts/camp/horse.gd`, `yurt.gd`, `camp_prop.gd`, `chibi_character.gd`; `scripts/character/character_avatar.gd`, `clip_retarget.gd`, `shoulder_relax.gd`, `character_fit_tool.gd`; `scripts/ui/creator_turntable.gd`; `shaders/include/atw_textured_body.gdshaderinc`, `shaders/character_toon.gdshader`; `assets/characters/*/*_fit.json`. Belgeler: [brief.md](../design/d3/brief.md), [oyun-durumu.md](../design/d3/oyun-durumu.md), [hayvanlar.md](hayvanlar.md), [cadir-otag.md](cadir-otag.md).

**Tanhu 1 (yalnız teknik).** `projects/tanhu-2d/tools/blender_horse.py`, `horse_gaits.py`, `horse_weights.py`, `art_src/chars/at/rig/*.blend` (2026-11-04'teki yol). Adlar, kadro ve atlar alınmadı.

**Godot belgesi (4.7).** [Importing images](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html), [Mesh level of detail](https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html), [Using MultiMesh](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html), [Animating thousands of fish](https://docs.godotengine.org/en/stable/tutorials/performance/vertex_animation/animating_thousands_of_fish.html), [Retargeting 3D skeletons](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html), [SpringBoneSimulator3D](https://docs.godotengine.org/en/stable/classes/class_springbonesimulator3d.html), [Available 3D formats](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html), [Performance](https://docs.godotengine.org/en/stable/classes/class_performance.html).

**Proje (prototip ve belgeler).** [decisions.md](../design/decisions.md) (K14, K20, K27); [register.md](../design/d3/register.md); [architecture.md §3.7, §7](../design/architecture.md); [army.md §5, §7](../design/army.md); [structures.md §3, §13](../design/structures.md); [settlement.md §13](../design/settlement.md); [economy.md §11.3](../design/economy.md); [travel.md §3](../design/travel.md); [survival.md §4](../design/survival.md); [sanat-animasyon.md](sanat-animasyon.md); [menu-spec.md §8](menu-spec.md); `docs/design/d2/settlement-model.json`; `docs-app/content/pages/sunum/gorsel-dil.md`, `hikaye/kadro.md`; `src/character/folk.js`, `head.js`, `rig.js`, `mete.js`, `horse.js`, `actor.js`, `looks.js`, `gestures/`; `src/game/mounted.js`, `builders.js`, `projectiles.js`; `src/core/paint-material.js`, `geo.js`; `src/world/structure.js`, `structure-defs.js`, `yurt-designs.js`, `props.js`, `nodes.js`, `flora.js`; `src/data/items.js`, `gear.js`, `weapons.js`, `skills.js`, `node-kinds.js`, `herd-kinds.js`, `stations.js`; `tools/prepare-mete.mjs`, `tools/imagegen/gen.sh`, `tools/imagegen/portraits.mjs`; `public/models/mete.glb` (bu turda okundu); `art_src/assets/_test/camel.png`; `node_modules/three` 0.187.

**Meshy, belge.**
- [API fiyatı](https://docs.meshy.ai/en/api/pricing), [Image to 3D](https://docs.meshy.ai/en/api/image-to-3d), [Multi-Image to 3D](https://docs.meshy.ai/en/api/multi-image-to-3d), [Rigging](https://docs.meshy.ai/en/api/rigging-and-animation), [Animation](https://docs.meshy.ai/en/api/animation), [Animation Library](https://docs.meshy.ai/en/api/animation-library), [Text to Motion](https://docs.meshy.ai/en/api/text-to-motion), [Remesh](https://docs.meshy.ai/en/api/remesh), [Retexture](https://docs.meshy.ai/en/api/retexture), [UV Unwrap](https://docs.meshy.ai/en/api/uv-unwrap), [Text to Image](https://docs.meshy.ai/en/api/text-to-image), [Changelog](https://docs.meshy.ai/en/api/changelog), [Deprecations](https://docs.meshy.ai/en/api/deprecations), [Quick Start](https://docs.meshy.ai/en/api/quick-start), [Rate Limits](https://docs.meshy.ai/en/api/rate-limits)
- Web: [Image to 3D](https://docs.meshy.ai/en/webapp/image-to-3d), [Pricing](https://docs.meshy.ai/en/webapp/pricing), [Rigging](https://docs.meshy.ai/webapp/guides/3d-model/rigging), [Remesh](https://docs.meshy.ai/webapp/guides/3d-model/remesh), [AI Texturing](https://docs.meshy.ai/en/webapp/guides/3d-model/ai-texturing), [AI Auto Rigging](https://www.meshy.ai/features/ai-auto-rigging)
- Yardım: [Planlar](https://help.meshy.ai/en/articles/12062933-meshy-pricing-plans-free-pro-studio-enterprise), [Image to 3D](https://help.meshy.ai/en/articles/9996860-how-to-use-the-image-to-3d-feature), [Çoklu görüş](https://help.meshy.ai/en/articles/16102789-meshy-multi-view-best-practices-angles-and-images), [Poz](https://help.meshy.ai/en/articles/10255659-how-to-generate-3d-models-with-a-pose-t-pose-or-custom-poses)
- Hukuk ve fiyat: [Pricing](https://www.meshy.ai/pricing), [Terms](https://www.meshy.ai/terms-of-use), [Acceptable Use](https://meshy.ai/acceptable-use-policy)
- Saklama: [Asset Retention](https://docs.meshy.ai/en/api/asset-retention)
- Bu oturumdaki Meshy MCP sunucusu: araç açıklamaları (`meshy_rig`, `meshy_image_to_3d`, `meshy_remesh`, `meshy_retexture`) okundu, çağrılmadı.

**Meshy, üçüncü taraf ölçüm.**
- [prime-game-art PR 216](https://github.com/xperiaroco2/prime-game-art/pull/216), [eldritch-tactics #158](https://github.com/klhall1987/eldritch-tactics/issues/158), [washed-ashore #96](https://github.com/chz160/washed-ashore/issues/96), [Costbench, Meshy](https://costbench.com/software/ai-3d-generation/meshy/)

**Tripo.**
- [API fiyatı](https://developers.tripo3d.ai/en/pricing), [H3.1](https://developers.tripo3d.ai/en/models/v3-1), [P2.0](https://developers.tripo3d.ai/en/models/p2), [Auto Rig](https://developers.tripo3d.ai/en/docs/animations-rig), [Retarget](https://developers.tripo3d.ai/en/docs/animations-retarget), [Rig Check](https://developers.tripo3d.ai/en/docs/animations-rig-check), [Multiview H](https://developers.tripo3d.ai/en/docs/generation-multiview-to-model/standard), [Image P](https://developers.tripo3d.ai/en/docs/generation-image-to-model/p), [Billing](https://developers.tripo3d.com/en/docs/billing), [ticari kullanım](https://www.tripo3d.ai/help/privacy-policy/how-to-use-tripo-models-commercially) (arama özeti), [Costbench, Tripo](https://costbench.com/software/ai-3d-generation/tripo-ai/)

**Karşılaştırma ve ötekiler.**
- [HackerNoon denemesi, 2026-06-03](https://hackernoon.com/how-i-stress-tested-3-ai-3d-generators-on-the-same-inputs-what-the-numbers-actually-show)
- [Hyper3D fiyatı](https://hyper3d.ai/pricing), [Hunyuan3D 2.1 lisansı](https://raw.githubusercontent.com/Tencent-Hunyuan/Hunyuan3D-2.1/main/LICENSE), [WaveSpeed, Hunyuan 3D](https://wavespeed.ai/blog/posts/hunyuan-3d-api/), [TRELLIS.2](https://microsoft.github.io/TRELLIS.2)

**Blender.**
- [mcp-for-blender](https://github.com/ahujasid/blender-mcp), [README](https://raw.githubusercontent.com/ahujasid/mcp-for-blender/main/README.md), [Poly Haven lisansı](https://polyhaven.com/license), [Poly Haven API](https://api.polyhaven.com/assets) (2.387 varlık: 997 HDRI, 869 doku, 521 model), [Sketchfab, üretken yapay zekâ kısıtı](https://sketchfab.com/blogs/community/restricting-generative-ai-use-of-free-models)
- Kılavuz: [Render Baking](https://docs.blender.org/manual/en/latest/render/cycles/baking.html), [Retopology](https://docs.blender.org/manual/en/latest/modeling/meshes/retopology.html), [Remesh](https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/remesh.html), [Decimate](https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/decimate.html), [Armature Parenting](https://docs.blender.org/manual/en/latest/animation/armatures/skinning/parenting.html)

**Görsel üretim.**
- [OpenAI görsel kılavuzu](https://developers.openai.com/api/docs/guides/image-generation), [gpt-image-2](https://developers.openai.com/api/docs/models/gpt-image-2), [APIYI, gpt-image-2](https://docs.apiyi.com/en/api-capabilities/gpt-image-2/overview), [moda.app, gpt-image-2](https://moda.app/resources/models/gpt-image-2)

**Teknik.**
- [Three.js KTX2Loader](https://threejs.org/docs/pages/KTX2Loader.html), [Khronos KTX](https://www.khronos.org/ktx/), [glTF Transform](https://github.com/donmccurdy/glTF-Transform), [CLI](https://gltf-transform.dev/cli), [simplify](https://gltf-transform.dev/modules/functions/functions/simplify)

**Yayın.**
- [PC Gamer, Steam yapay zekâ bildirimi](https://www.pcgamer.com/software/ai/steam-updates-ai-disclosure-form-to-specify-that-its-focused-on-ai-generated-content-that-is-consumed-by-players-not-efficiency-tools-used-behind-the-scenes/)

## Doğrulama

**Tarih:** 2026-11-04. Şüpheci okuma; yazarın kaynaklarına güvenilmedi, her iddia birincil sayfayla ya da Godot projesinin dosyasıyla yeniden açıldı. Meshy, Blender, Tripo ve görsel üretimi çağrılmadı; Godot koduna dokunulmadı.

**Sınanan iddia: 39;** 26'sı doğru çıktı, 13'ü düzeltildi ya da zayıflatıldı (aşağıda 1–12 ve 14). Doğru çıkanlar: `meshy-7.1` ve `latest` (2026-09-18); tek görselde 4K geometri ve 8K doku 40; çoklu görselde `4k` 400, `2k` 40; `texture_model` ve `meshy-n1` tarihleri; meshy-5 ve meshy-t1 eskimesi; Retexture 10 ve 15, Retexture'da `latest` Meshy 7; rig kapsamı (dokulu insansı, ≤380.000 üçgen, +Z, yürüme ve koşu); web Quadruped Dog ve Smart Rig; kütüphane (en yüksek kimlik 696, hepsi biped); Animation API (`rig_task_id`, ≤10 eylem, fps); UV Unwrap (≤40.000 yüz, dokusuz çıktı); planlar ve lira fiyatları, yıllık indirim çelişkisi; API dosyasının 3 gün durması; Meshy koşulları (2026-09-19); Steam bildirimi (Ocak 2026); Tripo kimlikleri, fiyatları, rig türleri ve tek `walk`; HackerNoon denemesi (Meshy çalışanı, örnek sayısı yok); Blender MCP'nin yeni adı, araçları, kapısı, telemetri ve güvenli kipi; Hunyuan3D 2.1 lisansı; Rodin fiyatı; Poly Haven sayısı (2.387); `gpt-image-2` şeffaf zemin notu; 24 kemik ve üç dış kaynak (üçü de var); Mete'nin 60.592 üçgeni ve 109.337 köşesi; pelerin ağırlığının uyluklara bağlanması (%94,8; Godot ham ağında yeniden ölçümde %92,8, sonuç aynı); 8K doku bellek hesabı.

**Düzeltmeler.**

1. Statik oyun ağının bedeli 45 değil 40: üretim içi indirme ek kredi istemez (Godot'daki 26 iş kaydı); §Özet 3, §1.2, §1.7, §7.1 düzeldi.
2. Rigli insan 50 değil 45, 10 klipli 80 değil 75; Godot'da gerçek bedel NPC başına 48, Mete 54, toplam 1.094.
3. Tüm oyun toplamı 19.645 değil 18.210 (449 aday); hayvan adetleri `hayvanlar.md`'den (10 evcil, 24 yaban memeli, 9 kuş, 2 balık) yeniden sayıldı; senaryolar ve Tripo karşılığı yeniden hesaplandı.
4. Öneri 2'deki Tripo hesabı (105 + 105 + 130) iş bölümüyle açıklanamıyordu; öneri Godot denemesi olarak yeniden yazıldı (Meshy 128, Tripo 35 kredi).
5. Belgenin «proje kuralı kodla üretimdir, Meshy ve Blender çağrılmaz» cümlesi brief'le çelişiyordu: Godot'da üretim serbesttir, kredi harcayan iş önce sorulur; giriş, §3 ve öneri 1 düzeldi.
6. Hayvan riginde «Blender Automatic Weights» önerisi zayıftı: Tanhu 1'in çalışan aracı bone heat'in Meshy'nin UV adalarında uymadığını yazar ve bölge maskesi kullanır; §3, §3.1, §5.7 düzeldi; 16 kemik yerine Tanhu 1'in 33 kemiklik iskeleti örnek verildi.
7. «`mete.glb` Blender'dan geçmiş, ham ölçek bilinmiyor» yanlıştı: Blender üreteci ve 0,01 ölçek Meshy'nin kendi rig çıktısındadır.
8. «Meshy 7'de `remove_lighting` yok sayılır» yalnız Retexture için doğru; Image to 3D'de 400 döner.
9. «PBR haritaları 4K kalır» yalnız MCP açıklamasıdır, API sayfasında yok; etiketlendi.
10. P2'nin Smart Low-poly aldığı izlenimi düzeldi: P2 bu seçeneği desteklemez.
11. TRELLIS.2'nin MIT lisansı resmî sayfada yok: [doğrulanamadı] yapıldı.
12. Metinden hareketin uygulama bedeli (3) çıkarım değil, değişiklik günlüğünde yazılı; etiket düzeldi.
13. Steam notu Godot'a uyarlandı: portre ve logo yerine Meshy modelleri ve ElevenLabs sesleri.
14. Yapay zekâ işareti belirsizliği daraldı: Godot ham dosyalarında görünür işaret yok.
15. Three.js uygulama önerileri Godot 4.7 karşılığıyla tamamlandı: §4.1 (Godot betikleri), §5.8 (çalışan hat, doku belleği, LOD, `MultiMesh`, iskelet, kumaş, sürü), §8 (karar matrisi Godot için yeniden yazıldı), öneriler 1–10.
16. Godot'da bulunan iki yeni sorun yazıldı: 26 doku `Lossless` içe aktarılmış (≈0,94 GB), `asset_plan.json` konsept eki «4th century» diyor; ayrıca `dombra` eşyası #55'e göre kopuzla değişmeli.

**Tanhu 1 denetimi.** Belgede Tanhu 1'in kadrosu, adları, nesneleri ve perde adları yok. `farnak` prototipin I. Perde kişisidir, Tanhu 1'de geçmez; yine de öneri 2'den çıkarıldı. Tanhu 1'den yalnız teknik yöntem (at riginin betiği) anıldı. Godot'daki logo ve arayüz takımının Tanhu 1'den geldiği §8'de not edildi.
