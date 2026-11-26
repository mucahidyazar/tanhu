# Testler

Tanhu'nun birim testleri oyunu pencere açmadan (headless) çalıştırır ve kodun verdiği sözleri korur:
"kamp düzdür", "göl suyun altındadır", "çapraz yürüyüş düz yürüyüşten hızlı değildir", "ateş ışığı
çakmaz, yumuşakça titrer" gibi. Bir değişiklik bu sözlerden birini bozarsa test ✗ ile ve nedeniyle uyarır.

## Çalıştırma

```bash
tools/run_tests.sh                     # tüm testler
tools/run_tests.sh --filter=world      # yalnızca dosya adında "world" geçenler
tools/run_tests.sh --dir=res://tests/framework/selftest   # başka bir klasörün test_*.gd dosyaları
```

Komut önce Godot'un içe aktarmasını çalıştırır (sınıf adları için gerekir), sonra
`tests/run_tests.gd` koşucusu `tests/unit/test_*.gd` dosyalarını alfabetik sırayla açar ve her
dosyadaki `test_` ile başlayan her metodu ayrı bir test olarak çalıştırır. Çıkış kodu: 0 = hepsi
geçti, 1 = en az bir test başarısız. Bütün testler (2026-11-08 koşusunda 109 dosyada 1676) içe aktarmayla birlikte birkaç dakika
sürer; en uzunları gerçek ana sahneyi oynayan akış testleridir: `test_cine_prologue.gd` (~35 sn; Önsöz'ü beş kez
oynatır), `test_main_flow.gd` ve `test_new_game_flow.gd` (Yeni Oyun'un bütün akışı). Şarkı ölçüsü aracının Node sınamaları ayrıdır:
`node --test tools/song/song_measure.test.mjs`.

Koşucu iki durumda takılıp kalmaz:
- Sözdizimi hatalı bir test dosyası `✗ <dosya> yüklenemedi` diye başarısız sayılır (altında ayrıştırma
  hatası yazar), koşu sürer.
- 180 saniyeden uzun süren bir test (ör. hiç gelmeyen bir sinyali bekleyen) `takıldı` diye yazılır,
  altında o ana dek yazılan hatalar (çoğu zaman sinyalin neden gelmediğini söyler) listelenir ve koşu
  1 çıkış koduyla biter.

Bilinen yük yarışı (2026-11-08): makine başka süreçlerle ağır yüklüyken (1 dakikalık yük ≈35) tam koşuda bir kez
`test_childhood_scene.gd`'nin saat sınaması başsız çizicinin motor hatasıyla düştü («Parameter "t" is null»,
`texture_2d_initialize`, `servers/rendering/dummy`). Dosya tek başına ve ardından yinelenen tam koşuda geçti
(1.401 test, 0 başarısız). Büyük olasılıkla boş çizicinin doku kimliklerinde iş parçacığı yarışıdır: arka planda
yükleme sürerken ana iş parçacığında doku kurulur. Yinelerse sınama, Ordos'un yüklemesinin bitmesini bekleyerek
düzeltilir; kare süresine bağlı sınamalar (ör. `test_childhood_site.gd`'nin kurulum bütçesi) da yük altında
düşebilir, boş makinede yeniden koşulur.

### Konsola hata yazan test düşer

Koşucu, Godot'un günlükçülerine (`OS.add_logger`) `TestErrorLog`'u (`tests/framework/test_error_log.gd`)
ekler. Bir test sürerken (`before_each`, test, `after_each` ve testin içindeki her `await`) konsola yazılan
hata o testi düşürür; nedeni ✗ satırının altında, iletisi ve yeriyle yazılır (hata ekleme denemesinden:
menünün buton işleyicisine eklenen betik hatası):

```
    ✗ test_buttons_emit_their_signals
        - Betik hatası: Invalid call. Nonexistent function 'deliberate_button_error' in base 'Nil'. — _on_pressed (res://scripts/ui/main_menu.gd:604) ← test_buttons_emit_their_signals (res://tests/unit/test_main_menu.gd:231)
```

- **Sayılır:** `SCRIPT ERROR` (betik çalışırken çıkan hata: `null` üstünde metot, olmayan anahtar...),
  `push_error`, motorun `ERROR` satırları (açılamayan dosya, bulunamayan düğüm, aynı sinyale ikinci kez
  bağlanma...) ve `SHADER ERROR`. **Sayılmaz:** uyarılar (`WARNING`, `push_warning`) ve `printerr`.
- Yer "bozulan satır ← testin satırı" biçimindedir; hata testin kendi satırındaysa yalnız o yazılır, betik
  dışından gelen hatada (ör. çizim sunucusu) motorun C++ konumu yazılır.
- Hata nedenleri düşen denetimlerden önce gelir (çoğu zaman asıl neden odur). Aynı ileti bir kez, `(×n)`
  ile yazılır; en çok 5 farklı ileti gösterilir, kalanı tek satırda sayılır.
- Betik hatası test fonksiyonunu o satırda keser (sonraki denetimler çalışmaz); `after_each` yine çalışır.
- **Test bittikten sonra çalışan iş** (`call_deferred`, silinen düğümün `_exit_tree`'si, kare sonu):
  koşucu testler arasında kare beklemez. Beklemek her testin sildiği düğümleri ve onlarla giden modelleri
  bırakır, sonraki test onları diskten yeniden yükler (denendi: karakter oluşturucu testleri 3 sn'den
  30 sn'ye çıktı) ve testlerin hiç görmediği ara kareleri çizer. Böyle bir işin hatası bu yüzden bir kare
  bekleyen ilk sonraki teste ya da dosyanın kapanışına yazılır:
  `✗ test_x.gd: testlerin dışında hata yazıldı (...)`; yer satırı asıl kaynağı gösterir. Hatanın kendi
  testinde yakalanması isteniyorsa test `await wait_frames(1)` ile biter.
- Testlerin dışında (dosya kurulurken ya da kapanırken) yazılan hata da dosyanın ✗ satırına yazılır ve
  başarısızlık sayılır; özet ve çıkış kodu onu da sayar.

### Beklenen hata: `expect_errors`

Bilerek hata yazdıran bir yolu sınayan test (ör. bozuk dosyanın reddedildiği; motor ayrıştırma hatasını
her durumda konsola yazar) beklediği hatayı testin içinde bildirir:

```gdscript
func test_missing_and_corrupt_files_keep_values() -> void:
	...
	expect_errors(["ConfigFile parse error"])   # bozuk dosyayı motor konsola yazar; beklenen hata
	assert_false(settings.load_settings(), "Bozuk dosya okunmamalı")
```

- Her parça, test sürerken yazılan en az bir hatanın iletisinde geçmeli (yer satırı sayılmaz: dosya adı
  gibi bir parça o dosyadaki her hatayı susturmasın). Parçayı içeren hatalar testi düşürmez; içermeyen her
  hata ve hiç yazılmayan parça (`Beklenen hata yazılmadı: «…»`) düşürür: hata artık yazılmıyorsa eskiyen
  işaret de görünür. Boş parça kabul edilmez (her hatayı susturur). `before_each`'te bildirilen parça
  dosyanın her testi için bildirilmiş sayılır, yani her testte yazılmalıdır.
- Geçen testin satırı beklenen hatayı sayar: `✓ test_x  (beklenen hata: 1)`. Godot hatayı konsola yine
  yazar (günlükçü yalnız dinler), bu yüzden üstünde bir `ERROR` satırı görünür.
- Bugün işaretli olanlar: `test_game_settings.gd` → `test_missing_and_corrupt_files_keep_values` (bozuk
  `settings.cfg`); `test_music_bank.gd` → `test_choir_only_in_tengri_and_dawn` ve `test_music_choir.gd` →
  `test_bank_refuses_a_choir_outside_the_sky` (izin dışı klipteki koro katmanı kurulmaz, `MusicBank` «koro» hatası
  yazar; K59).

## Hangi dosya neyi korur?

Test sütunu 2026-11-08'deki tam koşunun sayısıdır (birden çok dosyalı satırda dosyaların sırasıyla; her dosyada
`func test_` ile başlayan satır sayısı); Node satırları dışındakilerin toplamı 1.834'tür (130 dosya).

| Dosya | Koruduğu davranış | Test |
|---|---|---|
| `test_terrain_shape.gd` | Aynı tohum aynı araziyi verir; kamp ateşinin çevresi ve ahırın altı (`FLAT_PADS`) düzdür, düz alanın geçişi yamacı fazla dikleştirmez; çayır kampın arkasında kamp düzleminde sürer (4. referanstaki kayalar ve çamlar orada), vadi çok aşağıdadır; menü kamerası (konumu `main.tscn`'den okunur) platonun üstünde, yüksekten bakar ve ateşi engelsiz görür; uzaktaki nehir ve göl suyun altında, adacıklar suyun üstündedir; nehir kaynağından göle doğru genişler; 6 km'lik ızgarada NaN yoktur; normaller birimdir, yukarı ve yokuş aşağı bakar; arazi meshi yukarıdan görünür, köşe renkleri ve normalleri vardır ve TerrainShape ile örtüşür. | 28 |
| `test_scatter.gd` | Engel daireleri, kenara uzaklık, kare (chunk) anahtarı (negatif koordinatlar dahil), ön plan ağırlığı, diskte düzgün rastgele nokta, MultiMesh üretimi ve çayırın çimen yoğunluğu kuralları (ezik çimenin `trample_center` ile ateşi izlemesi dahil). | 18 |
| `test_mesh_kit.gd` | İkosferin köşe/üçgen sayıları, tüm üçgenlerin dışa bakması ve yüzeyin kapalı olması; lathe (yurt duvarı, kapı açıklığı), disk, oyundaki her kayanın (ateş taşları, kahraman kayalar, çakıllar) zemine oturması, çimen, çiçek, kumaş ve çam meshleri (shader'ların kullandığı UV ve renk dizileri dahil); AtwKit tutamlarının (geliştirme sahneleri) yerde duran, ince, tekrarlanabilir kartlar olması. | 20 |
| `test_campfire.gd` | Ateş ışığının titremesi [0,72; 1,18] aralığında, belirlenimci ve kareden kareye yumuşaktır; sahnedeki ateş ışığı gerçekten titrer; ateş düğümü ışığını, kıvılcımlarını ve engel dairesini kurar; engel dairesi ateşin taşlarını ve alevlerini örter ama oyuncunun ateşe yaklaşmasını engellemez; "Yeniden oluştur" parçaları çoğaltmaz. | 10 |
| `test_capture_args.gd` | Ekran görüntüsü aracının `--anahtar=değer` argümanlarını (`--window=3200x1800`, `--state=play` dahil) doğru ayrıştırması; `--capture` yokken aracın kendini kaldırması. Kararlı kare: `--freeze-time` değerinin okunması (ondalık virgül dahil; değersiz ya da okunamayan değer 10 sn, eksi değer 0, argüman yoksa zaman akar); `world_time` genel tekdüzeninin `project.godot`'ta eksi varsayılanla (oyunda zaman akar) tanımlı olması; `shaders/` altında ham `TIME` okuyan gölgelendirici kalmaması (zamanı `tn_time()`'dan, `world_time.gdshaderinc`'i içererek okurlar); görüntüyü bekletme sayacı (`hold_capture`, `release_capture`). | 16 |
| `test_budget_probe.gd` | Bütçe ölçüm sahnesinin saf hesapları (godot.md §7.4): 5 nokta × 4 yön × 3 uzaklık (14, 28, 40 m; K98) × 3 eğim = 180 poz ve 28 m'deki 20 pozun çimensiz eşi, tekil kimlikler; Çocukluk takımının oynanış kadrajları (38°, 36°; 22 ve 40 m, ayrıca 14 m); varsayılan eğim takip kamerasınınki, bandın uçları 15° ve 60°; ölçümün sabitlerinin `FollowCamera`'nınkiyle aynı olması; göle bakan yamaç noktasının «Göle Bakan Yamaç» işaretinin konduğu yerde, kenar noktasının oyun alanının 2 m içinde olması; her pozda kameranın odağa bakması ve zemine gömülmemesi; %95'lik dilim (en yakın sıra), özet, çimenin payı, JSON yolu ve süzgeç; eksiye düşüp sarmış motor sayacının (≈1,8·10¹⁹ bayt) geçersiz sayılması; `data/budgets.json`'un godot.md §7.2 tablosuyla aynı olması; `data/budget_baseline.json`'un bütün pozlarla ve varsayılan ayarlarla alınmış olması ve her pozda doku belleğinin malzeme dokularından (1–4.096 MiB) gelmesi. | 17 |
| `test_budget_cuts.gd` | Kampın bütçe kesintileri (godot.md §7.5, K3: menü karesini değiştirmeyen, görünmeyen kesintiler): arazi ızgarası merkez diskine ve bant dilimlerine bölünür, dilimler her dörtgeni bir kez kapsar ve ızgaranın köşelerini kullanır (dikiş yok); seyrek merkez diski tam diskin üçgenlerinin %40'ından azıyla aynı alanı boşluksuz örter ve bantlara oturur; dağ halkasının dilimleri halkanın bütün üçgenleridir; uzak vadi ladininde gövde yoktur (dal katları aynı). Dünyada arazi, dağlar, çimen, çiçek ve küçük kayalar gölge düşürmez; kahraman kayaların ve kampa yakın çamların gölgesini daha az üçgenli, yalnız gölge düşüren bir kopya düşürür (kaya kopyası modelin yerinde ve boyunda, çam kopyası aynı malzemeyle sallanır); kahraman kayaların dokulu ağında ve küme taşlarında LOD zinciri vardır; uzaktaki çam yarı üçgenli düzeye geçer (geçiş payıyla), ama menü gözünden hiçbir çam geçmez (≥1 m pay; menü karesi değişmez); vadi kayaları karelere bölünür, kamptan 400 m ötesindekiler seyrek ağlıdır (80 üçgen); dünya temiz silinir. | 16 |
| `test_input_setup.gd` | Tüm eylemlerin fiziksel tuşlarla kaydı, tekrar çağrının kopya tuş eklememesi, eksik tuşun geri eklenip elle eklenen tuşların korunması, hareket vektörünün uzunluğunun hiçbir tuş birleşiminde 1'i aşmaması. | 19 |
| `test_audio_util.gd` | Eksik ses dosyasının sessizce (konsola hata yazmadan) `null` dönmesi, oyunun kullandığı her ses dosyasının gerçekten bulunması, WAV/MP3/OGG döngüsü, arayüz seslerinin tek sefer çalması, veri yollarının (Music, Ambience, SFX, Voice) varlığı ve Master'a geri düşme. | 15 |
| `test_audio_budget.gd` | Ses içe aktarma kuralı ve bütçesi (K59): ortam döngüleri (`audio/ambience/`) 22,05 kHz mono QOA içe aktarılır ve kuralın boyunu tutar (gece çayırı 1,07 MB → 0,27 MB); döngü içe aktarmada açıktır ve yeni hızda bütün dosyayı kapsar, süre değişmez (`edit/loop_mode` ileri, son -1); dünya başına ses havuzları içe aktarılan dosya boylarıyla tavanın altındadır (müzik 16, efekt ve ortam 8, seslendirme 2 MiB; toplam 26 MiB; bugün tek dünya kamptır ve projedeki her ses sayılır; Destan Kitabı'nın tanıtım sesleri, kitap aynı anda tek tanıtım yüklediği için, bir kez ve en büyüğüyle; anlatıcının köprüleri `act0.narr.*`, kendi sinemasında yüklenip bırakıldığı için Önsöz'le aynı havuza değil, ayrı sayılır); kodda adı geçen her ses bütçede sayılır. | 7 |
| `test_world_scene.gd` | `world.tscn` sahnesinin konsola hata yazmadan kurulması ve temel düğümleri; çimen, orman ve kayaların boş olmaması; serbest gezinti engelleri; kamp nesnelerinin zemine oturması; ateşin başında, ateşe dönük oturan beş karakter (Teoman'ın ocağı, K37: Mete yok, Ağabey kendi modeliyle, ozanın elinde kopuz), her oturağın ve yayın bir halının üstünde olması; Önsöz'ün geri çekilme yolunun (0–6 sn, 0,1 sn adımla) çam taçlarına, kayalara ve zemine ≥1,6 m pay bırakması; ezik çimenin ve küçük toprak lekesinin ateşin yerinde, patikanın başına bağlı olması; yurt kapı basamaklarının çıplak toprakta durması; ön plan kayalarının çevresinde kısa çimen ve çiçek; gece renk ayarı; ay ve ay ışığı yönü; ağaç ve köy ışığı yerleştirme kuralları. | 22 |
| `test_path_network.gd` | Patika geometrisi (uzaklık, yumuşatma, parça bütçesi, hızlı sorgu); patikaların engellerin ve halıların içinden geçmemesi; kaya kümelerinin menü kamerasından kampın önünü (ateş, ateş başı, yurtlar, ahır) kapatmaması (K98; eskiden kadraja hiç girmezlerdi) ve patikalardan, kamptan, çam gövdelerinden uzak durması; oyun kamerasının her patika noktasında karakteri görmesi; patikada çimen çıkmaması; kenarlara metre başına yeterli çakıl. | 22 |
| `test_meadow.gd` | Çayırın ince yapraklı tutamları (kart düzeni, ince yapraklar, küçük ve bölünmüş çim tutamları), ezik çimen ve kapı basamağı kuralları, engel ızgarasının tam taramayla aynı cevabı vermesi, çiçek kümeleri ve renk karışımı, halı örtüsü daireleri, kapı toprağı, durumsuz duman. | 13 |
| `test_forest.gd`, `test_rock_field.gd` | Meshy çamları ve kayaları: boyları, tabanları, engel daireleri, zemine oturmaları; göl görüşünü kapatmayan ağaç boyu sınırı (göl penceresinin gözü K98'den önceki menü kamerasının yerinde kalır, yeni kamera onun üstünden ve gerisinden bakar); arka çayırdaki genç çamlar; vadi ağaçlarının oyun alanında engel olması; referanstan ölçülen kaya boyları; modeller kapalıyken kodla çizilen yedekler. | 27 + 14 |
| `test_follow_camera.gd` | Takip kamerası: dönüşüm, yakınlaştırma sınırları (14–40 m), geçiş, zemine gömülmeme; K98'in uzak ve yüksek kadrajı (2026-11-07: 38°, 36°, 28 m; yakınlaşınca eğim düşmez, uzaklaşınca dikleşir, karenin üst kenarı ufkun en az 15° altında; yetişkin karenin %7–12'si, çocuk 22 m'de 1080p'de 60–80 piksel, en yakında bile yetişkin karenin beşte birini geçmez); başlangıç uzaklığı (çocukta 22 m) sınırlar içinde; nişan sağ sürüklemeyi alabilir, orta sürükleme her zaman döndürür; E'nin işi varken kamera dönmez; iç haritanın dönüşüm süzgeci son sözü söyler; menü kamerası gibi yaw 0'da +Z tarafında durur. | 47 |
| `test_meshy_prop.gd` | Meshy modellerinin gösterimi (gerçek boy, zemine oturma, malzeme, çift yüz, işleme katmanları), eksik modelin sessizce kodla çizilen yedeğe düşmesi; yurt, ahır, at, ateş ve her kamp eşyası türünün modelli ve modelsiz kurulması.; dikey uzatma (yalnızca boy büyür, taban yerinde kalır) ve yurt kapısının 1,82 m'lik Mete'nin eğilmeden geçeceği yükseklikte (min_door_height) olması. | 30 |
| `test_camp_npcs.gd`, `test_character_fit.gd`, `test_character_regions.gd` | Ateş başındaki beş karakter (Ana, Çocuk, Baba, Ağabey, Ozan; gerçek boy, ateşe dönük, çakışmasız, kopuz ve yay sahiplerinde; Ağabey kendi Meshy modeliyle), elle seçilmiş beş ayrı oturuş (K91, `CampNpcs.SEATS`; gerçek modellerde yere oturur, kalça boşluğu sınırın altındadır, model ikinci kez yüklenmez), diz çöken Ana'nın çocuğa, Baba'ya ve taş halkaya köşe köşe uzaklığı, Çocuk'un kütüğü, ayakların taş halkanın dışında ve yayın Ağabey'in bacaklarından uzakta kalması, öteki rollerde kişilerin ayrışması, serbest gezintide oyuncunun ikizinin gizlenmesi; oturma yüksekliği, adım hızları, yerinde oynatılan ve döngüye giren klipler, aktarılan oturma klipleri; renk değiştirme maskeleri.; T-pozu iskeletlerinde kalkık omuzları indiren ShoulderRelax (açı hesabı, her karakter için ölçülmüş açı, avatarın düzelticiyi kurması). | 25 + 17 + 3 |
| `test_clip_library.gd` | Klip kütüphanesi (K90; `ClipLibrary`, `data/clip_library.json`) ve dışa aktarması (`tools/clip_library_export.gd`): tanım (120 klip: çekirdek beş `idle_3`, `idle_4`, `sit`, `walk`, `run`; E9 paketinin 109'u; 6 ters klip), Meshy hareket numaraları ve erkek, kadın, çocuk bedeni için bağışçılar; kişinin bedeni ve öbeği (oyuncu, adlı, kalabalık); bağışçı seçimi (bedene göre; yoksa klibi kendinde olan biri; kişi kendine bağışçı olmaz); taşıyıcı klibi taşıyıcıdan gelir, karakter kendisi aldıysa kendi alımı önce; kaynak sırası oyunun klibi > ham alım > aktarma, `.res` kaydı eski bağışçı tablosunu yener; gerçek kadro oyundaki gibi çözülür (Mete'nin oturması kendi alımı, Kadın Kahraman'ınki Ana'dan; Baba'nın oturması Kadın Kahraman'a her kemiğin iziyle aktarılır; taşıyıcı klipleri her bedene ulaşır); çekirdek bekleme erkeklerde ham GLB açmaz, kişinin kendi hareketleri tanımdan okunur (`tools/` gerekmez, planla aynı tutulur); döngü ve yerinde oynatma `CharacterAvatar`'daki gibidir; toplu alım ve metinden hareket okunur, kredi özeti yinelenen alımları sayar; eksik dinlenme izleri tamamlanır; omuz düzeltmesi klibe pişirilir (omuzsuz iskelette yapılmaz, klip değişmez) ve oyundaki `ShoulderRelax` düğümüyle aynı kol pozunu verir; kök kaydırma (geçişte iki uca ayrı pay) ve her klipte aynı konum izleri; aracın sayfaya yazdığı satırlar (klipler ve oturma rolündeki döngüleri ile kök yolu, öbekler ve bugün rolü olanlar, taşıyıcılar, kredi, kişinin çeşitleri; oyuncu karakteri çeşit almaz) ve sahnelerin kişiye oynattığı klipler (ateş başı `SEATS`, doğum sahnesinin kullandığı roller); yazılmış `manifest.json` sözleşmeye, kütüphaneye, sahnelere ve GLB'lere uyar, dışa aktarılmış klipler temas kemikleriyle zemine oturur, yürüme oyunun kuralıyla (60 örnek, alttan dilim). | 36 |
| `test_rig_health.gd` | İskelet sağlığı (K92; `tools/rig_fix.py`, `data/rig_calibration.json`, `ClipRetarget`), eşikleri aracınkiyle aynı (`limits`): bütün kadroda omurga düz; diz bacak çizgisinde ve doğru yükseklikte, iki bacak aynı boyda; her iskelet kalibre (dönüş ve bilek farkı, ayak sabiti dinlenmede); taşıyıcının yürümesi kişiye aktarılınca gövde kişinin kendi Meshy yürümesinden en çok 3°, bilek en çok 4 cm ayrışır (ikiz sınaması; ham dosya yoksa atlanır); ayakta kliplerde belde kırık ve diz kilidi yok, bacak düzeltmesi ayağı indirirken de diz kilitlenmez, ağır yürüyüşte diz sıçramaz; oturuşta dizler kaynaktakinin en az %75'i kadar açık; bilekler aynı yükseklikte; rol kliplerinde her kemiğin izi var; kendi yürümesinden sonra uyluğun konumu dinlenmeye döner; her kişinin 120 klip ölçüsü var | 19 |
| `test_hand_grip.gd` | Parmak kavraması (K92; `HandGrip`, `tools/hand_rig.py`): parmak kemiği adları ötekilerle karışmaz; parmaksız iskelette ve chibi yedeğinde `attach` null döner, kullanan atlar; varsayılan doğal yarı gevşek eldir, kapanınca parmak ucu avuca yaklaşır, yumruk tamdır; yere dayanan el düz durur; süreli geçiş hedefe varır, kare başına iş kemik başına tek atamadır; aktarım (`ClipRetarget`) parmağa iz yazmaz; `bake_pose` site GLB'sine doğal eli sabit iz yazar; `KopuzPlay` kalkışta iki eli kapatır, `CineActor`'ın `reach_grips` ve `gesture_grips`'i eli sahnenin izinden kurar. Küçük bir iskelet kullanır; bütün kadronun kemikleri `test_rig_health.gd`, ozanın eli `test_kopuz.gd`'dedir. | 11 |
| `test_anim_library.gd` | Klip kütüphanesinin oyun kaynakları (K90, K91, E9; `tools/anim_library_import.gd`): 115 kaynak (`assets/animations/library`) ve taşıyıcı iskelet (`assets/animations/donor`; yalnız kemikler) ham GLB gerekmeden yüklenir, izleri geçerlidir; sık öbeklerde en az 10 çeşit (yürüme ve koşmada en az 10 döngü; her beden ve yaş birleşimi her sık öbekte en az 3 çeşit bulur, yaşlı koşmaz; çocuk bedeni ile yaşı çelişmez); her klipte etiket, temas kemiği ve bilinen öbek; ters klipler ana kliplerinin aynasıdır; `clip_for` her bedene NaN'sız ve oyunun kurallarıyla aktarır; döngü dikişi ve iskeleti düzeltilen uzun bacakta iki ayak aynı hizada basar; bacak düzeltmesi (`ClipLibrary.fit_legs`): kalça ve bilek istenen kadar iner, öteki bilek ve ayağın yönü yerinde kalır, geçişte ayakta uçta söner, kalça bacağı katlanma sınırına itmez (oran ve dizin beş karelik savrulması, `stand_up_9`'da diz kalçanın önünde), inen bilek zincirin sonuna yumuşak yaklaşır, düzeltilmeyen bilek yerinde kalır, ölçülen düzeltmeler bedeni ve ayakları zemine oturtur, `clip_for` düzeltmeyi işler; kalça inince yere dayanan el gömülmez (`ground_lean_back`, bütün kadro), `ShoulderRelax` eli gömmez (`ground_side_sit`), yatarken ayak zemine girmez, gövde ve baş zeminde kalır (11 yatma klibi, bütün kadro); ölçü dosyası (`data/clip_library_measure.json`) her klibi ve kadronun 15 kişisini kapsar, kök ilerleyen klipte doğal hız kökün hızıdır, zemin payı doğru kemikleri zemine oturtur, yürüme ve koşmada alttan dilimle alınır, oyunun ve dışa aktarmanın kuralı tektir (`PoseFit.floor_times`, `floor_offset`); `ground_side_sit`'in eli yatıktır, `catching_breath` dinlenme pozundan başlar; `tools/meshy_pipeline.py` bir hareketin ikinci alımını reddeder. | 36 |
| `test_clip_variety.gd` | Animasyon çeşitliliği (K91; `ClipVariety`, `CharacterAvatar`, `CineActor`): kişi profili (`meta.json`'un `variety`'si, yoksa kütüphane); uygun çeşitler (`scene_only` klip yalnız elle seçilir; beden, yaş, kişiye özgü stil; durum çeşidi yalnız istenince; eşya ve oturak sahnenin verdiğiyle; kalça boşluğu sınırı aşan oturuş yalnız elle seçilir; yürüme ve koşmanın doğal hızı; geçişlerin iki ucu, kadronun herkesi her duruştan kalkıp inebilir), kişi başına çeşit hedefleri tutar, ara hareketler kısadır; seçim belirlenimci, stil önde, ağırlık başlangıcı kaydırır; dağıtıcı aynı sahnede farklı klip verir, sırası sabit, elle seçimi ayırır; avatar atanan klibi ölçüsüyle oynatır (klip, zemin payı, hız), ölçülmemiş modelde taşıyıcının hızı kalça oranıyla ölçeklenir; kendi klibinde aktarım olmaz, `pinned_roles` korunur, kişisiz avatar ve chibi yedeği değişmez, aynı modeli gösteren iki kişi klip paylaşmaz; oturuş döngüsünün dikişi kapalı (`sit_arms_crossed` son pozunda durur), klipler kişiye bağlı evrede başlar; ısıtma bir kez kurar, kare içinde aktarım olmaz; ara hareketin saati kişiye bağlıdır, klip beklerken oynar ve döner, sinemada kapalıdır; sahnenin kişileri tek dağıtıcıyı sahne sırasıyla paylaşır, `reach_turns`'lü kişi oturuşunu korur; bekleme klibi olmayan kişi ilk karede ve Ansiklopedi'nin görünümünde T-pozda kalmaz, model değişiminden sonra poz sürer, ilk karedeki değişim ve silinme motor hatası yazmaz. Kamp ve doğumun atamaları kendi dosyalarındadır. | 46 |
| `test_character_profile.gd` | Karakter seçenekleri kataloğu ve oyuncu profilinin kaydı / yüklenmesi. | 10 |
| `test_character_creator.gd` | Karakter oluşturma ekranı: satırlar, renk örnekleri, değiştirme / geri alma / onaylama, klavye, fare, oyun kolu; Meshy modellerinde yüze çizili özelliklerin (sakal, bıyık, göz biçimi) kilitli satırları ve odağın bu satırları atlaması; kamera çerçevesinin her boydaki modele uyması. | 59 |
| `test_color_grade.gd` | Gece renk ayarının ateş renklerini ve parlak beyazları koruması, kremleri mora kaydırmaması, çimeni gece tonuna çekmesi. | 7 |
| `test_main_menu.gd` | Açılış ekranı (Tanhu 1'in menüsü): logo, süs çizgisi, "BİR BOZKIR DESTANI", kulaklık önerisi ve sürüm; altı düğüm butonu ve sırası; kayıt yokken DEVAM ET / YÜKLE'nin soluk ve odaksız olması; yukarı / aşağı başa saran ve pasifleri atlayan odak, sağ ile SERBEST GEZ, fare ve oyun kolu; DEVAM ET'in yanındaki son kayıt kartı; YENİ OYUN sorusu (kayıt varken); YÜKLE paneli; AYARLAR kitabı (yalnızca AYARLAR ve TUŞLAR); DESTAN KİTABI'nın son kaydın işaretlerini okuması; atlanabilir giriş ve görünürlük geçişleri; 16:9 / 16:10 / 21:9 yerleşimi; düğüm butonunun Tanhu 1 plakası ve Tanhu vurgusu (sıcak parıltı, fırça, altın yazı, ×1,06); eksik dosyada sessizce yedeğe düşme. | 38 |
| `test_save_system.gd` | Kayıt yuvaları: kaydedip okuma (karakter, yer, yön, süre, işaretler), yuvaların bağımsızlığı ve numaraları, en son kayıt, eksik / bozuk / başka oyunun dosyası (boş yuva), güvenli varsayılanlar, küçük resim (16:9 kırpma, 320×180), yazılamayan klasör, biçimler; `Journey`'nin kaydetmesi ve kayıttan geri kurulması. Kayıt klasörü (K30): `user://`'nin `use_custom_user_dir` ile sabit ve eski klasörlerden ayrı olması; eski `app_userdata/Tanhu`'dan tek seferlik taşıma (`UserDirMigration`) sahte klasörlerle: yalnız bu oyunun kayıtları, küçük resimleri ve ayarı alınır, `Tanhu 2D`, `Tanhu 2` ve `Tanhu Ref`'e dokunulmaz, eski klasör değişmez (bütün ağacın md5 ve tarih anlık görüntüsü), yeni klasördeki dosya ezilmez, yarım kalan kopya tamamlanır, ikinci açılışta yeniden taşınmaz. | 19 |
| `test_game_settings.gd` | Ayarların `settings.cfg`'ye yazılıp okunması, bozuk / eksik dosya, değerlerin sınırlanması, ses veri yollarına uygulanması (Seslendirme → Voice), Önsöz satırı (ilk yeni oyunda / her yeni oyunda; `prologue_seen` testte dosyaya yazılmaz), takip kamerasına yalnızca açık özellikleriyle uygulanması, arayüz ölçeği (pencerenin gerçek piksel boyuna göre küçülmesi; pencere büyüyünce ölçeğin yenilenmesi, yalnızca gerçekten değiştiyse); testlerde autoload'un dosyaya yazmaması ve taşımaması; geliştirme çalıştırmasının tanınması (`is_dev_run`: başsız, `--` argümanlı ya da `godot -s` betiğiyle kurulan ana döngü; `--` argümansız pencereli deneme betiği de); Ayarlar sayfasının Tanhu 1'in dört bölümü, yalnızca Türkçe dil satırı, değer değiştirip kapanınca kaydetmesi, Z / C; Önsöz'ün «görüldü» işaretinin içerik sürümüyle eskimesi (`PROLOGUE_VERSION`, K99: sürüm yazmayan eski dosya 1 sayılır, yeni Önsöz bir kez daha oynar). | 28 |
| `test_destan_kitabi.gd` | Destan Kitabı'nın dört bölümü (Destan, Gök ve Yer, Kişiler, Taşlar) ve verileri, kayıtların işaretlerle açılması (ilk dize ve ocak halkı baştan açık; mit girdileri ve «Doğum» Önsöz'le, `onsoz`; iyeler ozanı 5 sn dinleyince, `ozan_dinledi`), çağ rozetleri, gruplar, boş bölüm yazısı, bölüm sayfası (liste, seçilen kayıt), ansiklopedi sayfası (altı bölüm sekmesi, portreli dizin ve Türkçe katlamalı arama, görsel yuvaları, soy kartları, Voice yolunda tanıtım sesi), Q / E ve Esc; koşul dili; kampın yer işaretleri (ateş başı, ahır, kayalar, kaya kümeleri, göle bakan yamaç) ve oyuncunun belirdiği yerin hiçbir işareti kendiliğinden koymaması. | 34 |
| `test_pause_menu.gd` | Duraklatma: kitabın kiplere göre sayfaları, dünyanın durup sürmesi, GENEL sayfasının altı butonu ve durumları, ANA MENÜ / MASAÜSTÜNE DÖN (önce sorar), Esc / Q / E / F5 / F9, yuvaya kaydetme ve üstüne yazmadan önce sorma, oyunda yüklemeden önce sorma, soru penceresi (odak HAYIR'da, Esc = hayır). | 11 |
| `test_epigraph.gd` | Açılış sözü (Tanhu 1'deki gibi): Mete'nin sözü ve altındaki yazı, siyahtan açılma, ekranı kaplayan koyu arka plan, bekleme ve kendini silme, beklerken basışla kısalma (belirirken basılan sayılmaz), F11 / tekerlek / fare hareketinin sayılmaması, arayüz ölçeğiyle ortalanma. | 7 |
| `test_main_flow.gd` | Gerçek ana sahneyle (başsızken açılış sözü atlanır): açılış → serbest gezinti (işaretler ve bildirim) → Esc → KAYDET → devam → ANA MENÜ (otomatik kayıt, kamera menüye uçar) → DEVAM ET (kaydedildiği yerde) → YÜKLE → MASAÜSTÜNE DÖN; ve YENİ OYUN sorusu → karakter oluşturucu (vazgeç / onayla, yeni yolculuk) → ayarların sahneye uygulanması → ÇIKIŞ; ve YENİ OYUN → Önsöz (deneme çizelgesi; sinemada süre işlemez, altyazı görünür) → basılı Esc → kara perdeden oluşturucu → onayda `onsoz` işareti, görülen Önsöz ikinci Yeni Oyun'da atlanır (gerçek Önsöz dizisi `test_cine_prologue.gd`'de); Yeni Oyun'dan sonra Serbest Gez'de Çocuk yürür, yetişkine dönülebilir; `--state=childhood` Ordos'u küçük Mete'yle açar. Yeni Oyun'da oluşturucu onaylanınca kampa inilmez, açılış ekranı gelir (K99); bütün akış `test_new_game_flow.gd`'dedir. | 5 |
| `test_new_game_flow.gd` | Yeni Oyun'un akışı (K99; `data/story/new_game.json`, `NewGameFlow`): sıra K99'u izler (Önsöz → Çocukluk → Köprü 1 → oluşturucu → Köprü 2 → son kart), dosyası olmayan Yola Çıkış ve I. Perde atlanır, I. Perde hazır olunca son kart düşer, takvim atlamaları (−5.600, −41, 1.041); Çocukluk'un verisi eksiksizdir (dört adım, iki dilde ve tasarımdaki gibi satırlar, kişilerin modelleri, dünyanın işaretleri); altyazının video bandı 16:10'da videonun 16:9 dikdörtgenine göredir; denetimler çocuğun eylemlerini bilir; gerçek ana sahnede Yeni Oyun → Önsöz (atla) → Çocukluk (adımlar doğrudan sürülür: hedefe konma, E ile binme ve alma, kuş vurma) → Köprü 1 → oluşturucu → Köprü 2 → son kart → açılış ekranı, kampa inilmez, kayıt yazılmaz; doğumun başına ileri sarılan Önsöz oynamayı sürer; Çocukluk'ta duraklatma kitabının KAYDET'i kapalıdır, Ana Menü kayıt yazmadan akışı bırakır. | 9 |
| `test_cine.gd` | Sinema çalıştırıcısı (godot.md §3.6): `CineTimeline`'ın çapa çözümü (sayı, `_end`, ±ofset, adlı olay, satır ve çekim adı, `end`, segment zinciri), satır uzayınca sonraki olayların aynı payla kayması, `validate`'in eksik çapa ve döngü raporu; `CineRunner`'ın aynı anın sırası, 0,25 sn'lik adım kırpması, ileri sarmada sesin çalmaması; `CineHost`'un atlaması (0,5 sn kararma, `finished(true)`, sahnelerin `restore`'u), 0,6 sn'den kısa Esc'in atlamaması, altyazı pencereleri (sözcük zamanı ve `seconds` yedeği), deneme çizelgesinin baştan sona oynaması, sahnesiz segment, `release_camp` / `restore_camp`, her kare sorulan ön yükleme, şarkıya saat kilidi, overlay görünümü, dünyası hazır olmayan segmentin beklemesi; `cine_preview.tscn`. Ses sahte bir hedefe gider. | 23 |
| `test_cine_prologue.gd` | Önsöz'ün bütünü (`data/cine/prologue.json`; K68, story.md §3–§4): toplam 4 dk 19 sn ± 15 sn tahmini sürelerle, oyunun `seconds`'ıyla ve dosyaların gerçek süresiyle (2026-11-07, şarkı çekim 3104: 4:18,7 / 4:17,9 / 4:17,9; satırların hepsinin dosyası var); tahminle segment sınırları 0:38,9 / 3:22,2 / 4:08,7 / 4:18,7 (±0,1); şarkı kamera durunca 0:06,0'da; şarkıdan sonra 3 + 2 + 1 sn; konuşmacılar (1–2 ve mit satırları 3–25 ozan, `act0.birth.12` anlatıcı, Hereka); aynı sahnedeki iki satır arası ≥1,5 sn; tek kara sessizlik (doğumda 2,5 sn), tek koro (tengri), iki alçak sessizlik; `childhood_ordos` mit başında istenir, pano 6'nın başında örneklenir (tahminle 2:53,0; çakışma 3:20,7); kamp kara ekranda bırakılır; satırların gerçek süresiyle sonraki işaretlerin kayması. Gerçek ana sahne ve `AudioManager`'la akış (`Engine.time_scale` 2 × sinema hızı 30): Yeni Oyun → Önsöz sonuna dek (doğum dünyasını beklemeden açılır; pano 6'dan doğuma dek sinema gerçeğin 4 katı hızda akarken de) → oluşturucu (`prologue_seen` yazılır) → vazgeç → menü; ikinci Yeni Oyun varsayılanla atlar, «Her yeni oyunda» yeniden oynar ve her müzik bankası kendi düzeyinden başlar (önceki oynatmanın katman düzeyleri taşınmaz) → onayda `onsoz`; basılı Esc kampta, mitte ve doğumda ayrı ayrı atlar (dünya bırakılır, bekleyen yükleme bırakılır, kamp geri gelir). Her dönüşte menü karesinin başsız karşılığı Önsöz öncesiyle aynıdır: kamp dünyası, gök ve su tekdüzenleri, sis, menü kamerası, ateş başı (`CampNpcs`), çalan müzik ve ortam, ortam katmanları, yolların düzeyi. `tools/run_tests.sh --filter=cine` bu dosyayı `test_cine.gd` ile birlikte koşar. | 12 |
| `test_vo_budget.gd` | Seslendirme verisi (`data/vo_lines.json`, `VoLines`; K61): şema, kimlik tekilliği, dilim A–D, bilinen konuşmacı, dosya ve sözcük zamanı yolları, şarkının altyazı pencereleri, kilitli perdenin metin karması (bir sözcük değişince düşer), yapı kuralı; dosyası olan satırın süresi dosyanınki (±0,05 sn) ve sözcükleri metinle aynı sırada, dosyası olmayan satır yer tutucu (K89); şarkının çekimi ve karması (3104; K95); Hereka'nın Önsöz satırı Heather Faith, kişi tablosu Lea, Mature (K95); Önsöz'ün mit satırları ozanın sesiyle (David) ve zincirsiz (K96), Önsöz'ün sesleri 2 MiB havuzunda; perde, konuşmacı ve dilim başına karakter ve süre sayacı (yazdırılır, düşmez). | 17 |
| `test_elevenlabs_tool.gd` | `tools/elevenlabs_audio.sh` (K61, K28): uçlar ve biçimler (konuşma `eleven_v3`, sözcük zamanlı uç, `mp3_44100_64`; şarkı `music_v2_5`), ağsız bedel (`--cost`) ve kuru koşu (`--dry-run`), metin kilidi, kota kapısı, anahtarın yazdırılmaması, deftere satır; okuma satırın sesini kullanır (Hereka'nın Önsöz satırı, K95), sesi seçilmemiş satırda araç geçici sesi söyler; yerel sahte sunucuyla uçtan uca üretim (tts, music, sfx, stt); tek okuma (`--block`, K96): satırlar sessizliklerden kesilir, sözcük zamanları parçaya taşınır, tek bir kazanç uygulanır. Gerçek ElevenLabs'e istek gitmez, kredi harcanmaz. | 13 |
| `test_voice_bus.gd` | `Voice` veri yolu ve konuşmada kısma (K78): yol düzeni (`default_bus_layout.tres`), `DuckTable`'ın durumları ve zarfı, `play_line` / `play_song` / `stop_line`, ana sözde Amplify ve EQ, sistem sözünde yan zincirli kompresör, kara ve alçak sessizlik, satırların arka planda yüklenmesi. Başsızda ses sahtedir: değerler sınanır, son ayar kulaktadır. | 22 |
| `test_music_bank.gd`, `test_synth_kopuz.gd` | Müzik motoru (`MusicBank`, K59): kurulan `AudioStreamInteractive` (klipler, katmanlar, geçişler), koro kuralı, perde rengi (`MusicColor`), `AudioManager`'ın `set_music_bank` / `set_music_state` / `set_layer_db`'si ve `tools/bake_music.sh`'ın bastığı dosyalar; kodla kopuz (K60, K75: vuruş dizisi, Karplus-Strong teli, 1,28 kHz üstü enerji, 2–6 kHz sönümü, vuruş/sn). | 18 + 14 |
| `test_menu_camera.gd`, `test_kopuz.gd`, `test_stand_in.gd` | Menü kamerasının görüş açısı uyarlaması ve salınımı; menü kadrajının K98 kuralı (2026-11-07: eğim 38° ≥30°, ateşe 26,4 m ≥25 m, görüş 36°, ufuk yok, ayakta kişi karenin %6–15'i, yurtlar ve ahır karede, ateş sağ yarıda); Önsöz'ün geri çekilmesi (WIDE: ateşe 40 m, eğim 9°, 41,76°, menüden 1,52 kat; 0/3/6 sn pozları; uzaklık hiç azalmaz, ateş karede kalır ve sıçramaz; WIDE çevresinde kendi görüşüyle paralakssız salınım, `menu_transform` değişmez; yolun engellere payı); ozanın kopuzu (Meshy modeli gerçek boyunda ve tek çizim, model yokken kodla çizim) ve çalışı (`KopuzPlay`: kol seçili çekimin vuruş ızgarasına uyar, `STROKE_HZ` × 2 1 / dönem'in %2'si içinde, 3104'te 1,2534 tur/sn, aşağı vuruş ızgarada; kaldırma 1,1 sn, avuçla susturma); kişi modelleri (`StandIn`, K89: glb yokken `meta.json`'un kaydı, glb varken kişinin kendi kimliği; kendi modeli gelen dokuz kişi oynamaya hazır; renk çarpanı yalnız o avatara, ölçek). | 14 + 16 + 8 |
| `test_prologue_camp.gd` | Önsöz'ün kamp sahnesi (`prologue_camp.json`, `PrologueCamp`): çizelge (WIDE'a 6,0'da varış, şarkı, dizelerin pencereleri, dronun şarkının son 4,6 sn'sinde sönmesi, 3 + 2 + 1), kolun çekim 3104'ün zarfına ve ızgarasına bağlılığı (8,3'te başlar, 28,64'te avuç; ikisi de ölçünün ızgara noktası ve vuruşun sıfır geçişi; ileri sarmada da), sahne kablajı (kamera, yıldızlar %35, ay yok, kopuz 4,2–5,3, Çocuk ozana döner) ve bitince ya da atlanınca gök, su, sis, kamera, bakış ve kopuzun setup'taki hâline dönmesi; ana sahnede Yeni Oyun'dan 0:38,9'a; geri çekilmede ozana uzaklık hiç azalmaz, ozan karede kalır (K98). | 9 |
| `test_felt_panel.gd`, `test_prologue_myth.gd`, `test_music_choir.gd`, `test_synth_myth.gd` | Mit sineması: keçe şekiller ve panolar (`FeltShapes`, `FeltPanel`, `myth_panels.json`, `prologue_myth.tscn`); çizelge (tahminle 0:38,9–3:22,2; 3–25 ozanın, hiçbiri `fx` taşımaz; bütün satırlar arasında ≥1,5 sn; cevap katmanı +6 dB, 3, 10, 11, 17, 18, 20, 23 ve 25'ten sonra yok; myth → erlik → myth → tengri → erlik → myth; tek koro; kıvılcımdan önce 1,5 sn alçak sessizlik; «Erlik.»le rüzgâr kesilir; 17 ve 23'ten sonra sekiz çentik; satır uzayınca kayma) ve sahnesiyle oynatma; koronun yalnız `tengri` ve `dawn`'da çalması; kodla koro (yalnız D–A), kobuz (0,25 sn atak), kargıra (A↘D kayışı) ve su döngüsü, basılan dosyaların tariflerine uyması. | 16 + 11 + 6 + 7 |
| `test_cine_video.gd` | Mit videosu ve Çocukluk'a geçiş (K93; `CineVideo`, `PrologueMyth` ve `PrologueBirth`'ün video kipi; küçük fixture `tests/fixtures/t_silent.ogv`, başsız koşuda konum ve sinyaller çalışır, doku boştur): saati izler, sapma 0,12 sn'yi aşınca sarar (en az 0,5 sn arayla), küçük sapmayı hız alır, sarma sarma doğurmaz, takılmada saat ve video birliktedir, hız `CineHost.speed`'den, saat durunca duraklar, sonunda son karede kalır; dosya yok ya da bozuksa sessizce kapalı, `enabled` kapalıyken keçe yedeği; 16:9 ve bant; katman sırası (0 < süzgeç 1 < video 2 < perde 5 < altyazı 6); altyazı video oynarken koyu bantta (iki satır sığar), bitince eski yerinde; mit sahnesinde keçe kurulmaz, 3B çizilmez, dünya önceden çizilip kapanır, çekim ve olaylar sürer, ileri sarma, son 1,5 sn çakışma, köz sabit yerde ve 7a'nın ilk karesi oraya oturur; doğumun son 10 sn'si (0,4–1,9 sn belirir, opak olunca 3B kapanır, son 0,5 sn perde). Gerçek dosya varsa süresi: `\|myth.ogv − (mit segmenti + 1,0)\| ≤ 0,25`, yoksa atlanır ve yazar. | 35 |
| `test_bridges.gd` | Anlatıcının iki köprüsü (`data/cine/bridge_1.json`, `bridge_2.json`; K36, K67, K93): çizelgeler sorunsuz çözülür (overlay, kendi dünyası yok, sahnesi `bridge.tscn`); satırlar sırada (N1–N5, N6–N7), araları 0,6–1 sn; süre satırların gerçek süresinden gelir; çekimler hikâyenin sırasında; her efekt, ortam ve müzik katmanı vardır; perde başta açılır, sonda karadır; gerçek video çizelgeyi karşılar (\|video − (segment + 1,0)\| ≤ 0,25 sn, dosya yoksa atlanır ve yazar); dosya yoksa ya da bozuksa kara ekranda satırlar, altyazı ve olaylar konsola hata yazmadan akar; video sinema saatini izler ve süzgecin üstündedir; ileri sarma sessizdir, atlama ortam döngülerini susturur; altyazı koyu bantta iki satıra sığar; çan çalıp söner. | 14 |
| `test_ordos_world.gd`, `test_daylight.gd`, `test_sky_rig.gd` | Doğumun dünyası `childhood_ordos` (arka planda yükleme → örnekleme → iş parçacığı işleri ve kare bütçeli kurulum → `is_ready`; CineHost'un mit sürerken beklemeden yüklemesi; yurt kapıları doğuya, doğum yurdunun içi, ocak ve köz ışığı, sayım hattı, beşik ve gömü yeri zeminde, kamera noktaları, ücretsiz varlıklar; düğüm ve önbellek bırakmadan silinme); güneş ve ay hesabı (prototipin `daylight.js`'inden altın değerler; 27 Eylül MÖ 234, 39°K); `SkyRig`'in sabit ışık örneği (içeride 05:50, dışarıda 06:03; kampın gece göğü değişmez); doğum bozkırı görür ama Çocukluk'a özgü olanları (ağıl, sürü, av, yarış yolu, izler) görmez. | 21 + 18 + 14 |
| `test_childhood_site.gd` | Çocukluk'un oynanış yerleri (`ChildhoodSite`, `OrdosWorld`'ün Çocukluk yüzü; story.md §5): düzenin uzaklıkları hikâyeyle aynı, her şey yürünür alanda ve zeminde; bölgeler zemin gölgelendiricisine sığar, ot ağıldan ve lekelerden kaçar; yükselti doğumun yerlerini korur ve kademe yapar; K98 kadrajı yerleri tutar, kamera sınırı ve varsayılan kamera sınıra değmez; doğum Çocukluk'a özgü olanları hiç görmez, düğüm gizli kurulur ve kiple görünür, dünya hazır değilse kip bekler; kurulum kare bütçesini tutar; çit, kapı, yurtlar ve taş oyuncuyu durdurur; sürü ve av kiple çalışır; Çocukluk'un saati ışığı sürer; çizim üst sınırı (iç harita satırı) ve bırakınca bir şey kalmaz. | 21 |
| `test_herd_field.gd`, `test_sheep_asset.gd` | Sürü (`HerdSim`, `HerdField`, `FaunaMesh`; fauna.md §10, K65): koyunlar kapalı ağılda kalır, salınınca yalnız kapıdan çıkıp çayıra yayılır, çayırda diskinde otlar, gövdeler ağılda ve kapıda ayrı durur, sayımda ip boyunca her koyun bir kez sayılır, aynı tohum aynı sürü, oyuncuya yol verir; tek `MultiMeshInstance3D`, iskelet yok, örnek verisi zemini ve yürüyüşü izler, tıklar arası ara değer, olaylar sinyalle; Meshy ağı gelince kendiliğinden yerine geçer (uzak ağ `sheep_far`), indirilmiş ağ T1 bütçesine sığar. Koyun varlığı (`tools/blender/quadruped_rig.py`): iskelet ve kemikler, dört döngülü klip, boy, yön ve zemin, yürürken toynaklar zeminin üstünde, `MultiMesh` için uzak ağ, `sheep.json`'da eyer ve klip hızları; dosya yoksa atlanır. | 21 + 6 |
| `test_small_game.gd` | Küçük av (`SmallGame`, `SmallGameField`, `FaunaKind`, `FaunaMesh`; story.md §5, fauna.md §1, §10): katalog fauna.md ile aynı (tarla kuşu, keklik, karga, tarbagan, kum faresi), hikâyenin hedefleri düzende, kodla çizilen ağlar bütçede ve dışa bakar; hedef sözleşmesi (`targets` grubu, `hit`, düşme, `collect`; canlı hedef alınmaz), uçarken vurulan kuş yere düşer, ürken kuş başka lekeye konar, keklik ve karga birlikte havalanır, her tür kendi uzaklığında kaçar, kemirgen ine saklanıp çıkar, boştaki hayvan kare başına iş yapmaz, otlanma lekede ve zeminde kalır, inler bir kez çizilir. | 15 |
| `test_child_controller.gd`, `test_mount.gd`, `test_projectiles.gd` | Çocuk denetleyicisi (K37, story.md §5, godot.md §9.4): küçük Mete ve Serbest Gez'in Çocuğu kendi hızlarıyla yürür ve koşar, aynı denetleyici ikisini de gösterir, yetişkine dönülür; E yalnız erimde bindirir, binince tırıs, dürtünce dörtnal, koyun 10 sn'de bir otlamak için durur ve dürtmek yürütür, E yanına indirir, boş yanı seçer, binerken engel ve oyun alanı geçerlidir; model yokken koyun sürünün çizimiyle oturak taşır, gerçek modelde binici pozu oturuştan türer ve bacaklar gövdeyi sarar; yerden ve koyun sırtından nişan hedefi vurur, çocuk düşeni eğilip alır, kısa tıklama kısa düşer, nişan konisi ve yakın hedef kilidi, ıska yakındakileri ürkütür; gerçek yay pozunda eller yayda ve kirişte, yay sırtta durur; oturan çocuk ilk harekette kalkar; sağ tuş yalnız çocukta nişandır, E'nin işi varken kamera dönmez; çocuk kadrajı 22 m'den başlar, yetişkine varsayılan döner; nişan kamerayı yaklaştırmaz; ipucu yapılabileni izler; oyuncak yayın ağı beşiğin yayından kesilir, okun dibinde küt topuz vardır. `Mount` (saf; `data/fauna/mounts.json`): koyun satırı tasarım sayılarını, oturağı modelin ölçüsünü taşır; giriş yokken durur, varken tırıs, koşu tuşuyla dörtnal; otlama ve dürtme; atın satırı aynı biçimde, otlamasız; erim ve inilen yer (önce sol, sonra sağ, sonra arka). Oyuncak yayın hesabı (`Projectiles`, `BowDraw`, `Weapons`; progression.md §7.2): `toy_bow` satırı tasarım tablosudur; analitik yay hedefe iner, rüzgâr inişi kaydırır ve öngörü aynıdır; küt ok yerde yatıp erir, keskin ok saplanır; ok yolundaki ilk hedefe çarpar, küt ok seker; uzun karede ince hedef atlanmaz; havuz en eskiyi geri kullanır; germe, yayılma, kol yorulması, iptal. | 37 + 8 + 15 |
| `test_childhood_scene.gd`, `test_game_clock.gd` | Çocukluk'un saati, sayımı ve kalabalığı (childhood-p2; K67, K98, K102): sahne 08:40'ta açılır, sayımın vakti 11:00; atlı kolu (`RiderColumn`) geçiş noktasına adım hızına inerek varır, durmaz, Teoman dört saniye bakar, odak Mete'yi karede tutar; Dailin'in kalabalığı kart kademesindedir. Oyunun saati ve takvimi (`GameClock`, `GameCalendar`, saf): 2,5 sn = 1 oyun dk, kare başına en çok 0,25 sn, durma nedenleri sayılır (söz, sinema, duraklatma), saat başı ve gece yarısı olayları, atlama yalnız ileri. | 11 + 14 |
| `test_departure.gd` | Yola Çıkış (mq0_depart; K98, K99): üç adım (yay, avlu, at) ve iki dilde satırlar, beş kişi (Gutu Huyan Hatun'un kucağında); `depart_yurt` kampın ve Ordos'un yapı taşlarıyla kurulur (oyuncu içerideyken çatısı kalkan yurt, beşik ve küçük yay, Teoman'ın kapalı kapısı), ana kampa dokunmaz; adımlar sırayla akar, at batıya yürür, perde kararır. | 4 |
| `test_cape_dye.gd`, `test_creator_prepare.gd` | Pelerin boyası (K58, K101): beş boya tasarımın sırasıyla ve rengiyle, tek kaynak `CharacterOptions.cape_tint`, önizleme ile oyundaki Mete aynı rengi verir (M18), kaftan pelerini boyamaz, boyanmayan pelerin kendi rengindedir, soğuk bant kalabalık giysisinde yasaktır (kalabalık dokusunda pay ≈0), OKLab hesabı Python aracıyla aynıdır. Oluşturucu «Yola Hazırlan» (K36): başlık ve alt yazı, köken, zorluk ve boya satırları ve açıklamaları, kumaş örnekleri, Meshy modelinde gizlenen satırlar, profilin kayda (v1) ve yolculuğa girip geri gelmesi, eski kayıtta varsayılan. | 12 + 15 |
| `test_gameplay_hud.gd`, `test_vitals.gd` | Oyun içi HUD (E16, E18; `GameplayHud`): parçalar kurulur ve yalnız oynanırken görünür, görev kartı kaynağın yazılarını gösterir, mini haritanın dönüşü ve kırpması, kenardaki yön oku, I envanteri açar (oyun durur), M ve J kitabın HARİTA ve GÖREVLER sayfasını ister, HUD ölçeği bütün parçalara ve tuş ipuçlarına uyar (XP çubuğu ipucunun üstünde kalır), yuvaya basma efekti, Tuşlar sayfasında I, J, M, Boşluk ve atın tuşları; son test gerçek ana sahnede Serbest Gez'e iner. Can, takat, durum yuvaları, seviye ve deneyim (`Vitals`). | 25 + 7 |
| `test_horse_asset.gd`, `test_horse_riding.gd`, `test_horse_jump.gd`, `test_player_jump.gd` | Kampın iki atı (`quadruped_rig.py`, `quadruped_horse.json`: iskelet, klipler, boy, eyerin yeri, adım boyu; dosya yoksa atlar). Ata binme (`RideableHorse`, vault binişi): giriş adım, Shift tırıs sonra dörtnal, toynak tozu, izi ve sesi, iniş, ikinci at, ahırın duvarları ve ağzı. Atla sıçrama (hıza göre plan, koyun sıçramaz, binici attan kopmaz, düğüm ve kamera yerde kalır, havada inilmez, nişanla birlikte çalışır). Yerde zıplama (Meshy `regular_jump`): çömelme, havada kalış, yumuşak iniş; binerken, nişanda, otururken zıplanmaz; çocukta ve yetişkinde aynı. | 5 + 13 + 11 + 7 |
| `test_session.gd`, `test_data_catalog.gd`, `test_conditions.gd`, `test_save_v2.gd` | Çekirdek (act-1-p1; godot.md §3): Session'ın 12 adımlık sırası ve 11b kancası, yerleşim adımının yalnız saat başında koşması, saatin durma nedenleri (sahip sayısıyla), oto kayıt nedenleri, oturumun Serbest Gez'de ve Yükle'de kurulup menüde silinmesi; Catalog: `data/**/*.json` ilk çağrıda okunur, 14 tablo ve 25 kurallık kimlik ve başvuru şeması, TR ve EN anahtarları, d2 modelleri (bilinen üç ayrılık adıyla); Cond ve Effects: prototipin dili ve 30 etki, `JourneyFlags`'in eski sonuçlarıyla aynılık; kayıt v2: bloklar ve sürümleri, iki aşamalı yükleme, v1 göçü (oyuncunun kaydının biçimi `tests/fixtures/save_v1_roam.json`), bozuk blok boş yuva. | 17 + 12 + 15 + 12 |
| `test_proto_fixtures.gd`, `test_labour.gd`, `test_progression.gd`, `test_derive.gd` | Prototip fikstürleri (`tools/proto_fixtures.mjs`; bekçi değişen kuralı sokmaz) ve okuyucusu `ProtoFixture`; emek yasası (K50 eğrisi: Hane Yurdu 60 / 45 / 33,75 … dk, Küçük Yurt en çok 6 el, Otağ 12 el, söküm ×0,35 ve onarım, tezgâhta `eff`; 453 durumluk fikstür); ilerleme (seviye 20 ve I. Perde'de 1–5, beş stat, köken, beceriyi insan öğretir, insan öldürmek XP vermez, kayıt bloğunun doğrulaması); türetilen değerler (progression.md §2.3; 227 durum). | 5 + 15 + 16 + 4 |
| `test_item_catalog.gd`, `test_inventory.gd`, `test_inventory_proto.gd`, `test_hud_inventory.gd` | Envanter (economy.md §4): eşya kataloğu (modelin 135 satırı birebir, etiket eşleme, İnce İş), kaplar (onda bir Yük, 24 ortak yuva, kabul süzgeci, bozulma, aktarma, bohça), Yük (12 + 3×Bilek; hız 1 − 0,3 × doluluk; zıplama ≤%50, koşu ≤%75), kuşam, terki, yer yığını, el koyma, kayıt bloğu; prototip fikstürü (46 durum); ekran ve aktarma paneli. | 6 + 9 + 5 + 9 |
| `test_game_calendar.gd`, `test_light_stops.gd`, `test_roam_time.gd`, `test_roam_flow.gd` | Takvim (time.md §17'nin günleri, ay yaşı, Dailin, Lung-çeng, «1.229. gün»), altı ışık durağı ve pelerin durak dosyasının onları izlemesi (K101), Serbest Gez'in saati (kayıtsız 11 Nisan MÖ 209 14:46,2, eski günün göçü, menüye dönüşte değerlerin bit bit geri yazılması), menü akışı. | 7 + 10 + 6 + 1 |
| `test_weather_planner.gd`, `test_weather_snow.gd`, `test_weather_fx.gd`, `test_weather_view.gd` | Hava (weather.md): planlayıcı ve cepheler prototiple bit bit aynı (fikstür `weather_core.json`), W26 (150 kış: steppe_south derin kar 0,16 ve kabuk 0,62/kış), SnowPack, şimşek ve yıldırım, göl boğası sinyali, ≤1 KB kayıt bloğu ve Session'a bağlanması; görünüm menüde sabit, kampta saatle akar, menüye dönüşte kimliğine döner. | 10 + 10 + 9 + 13 |
| `test_world_swap.gd`, `test_map_world.gd`, `test_map_bake.gd` | Dünya değişimi (`WorldHost`): kamp → deneme haritası → kamp, sızıntı yok (düğüm, kaynak, nesne sayıları), kampa dönüş ≤2 sn, iç harita ≤6 sn; `MapWorld` ve deneme haritası (belirme, kapılar, iki at); pişmiş parçaların imzası: kampın üretim kodu değişirse düşer, `tools/bake_map.gd --map=camp` yeniden koşulur. | 6 + 9 + 4 |
| `test_controls_page.gd` | Tuşlar sayfasının dört görünümü (liste, klavye, oyun kolu, atama) ve atama: «Değiştir», çakışmada «Şuna da bağlı: {eylem}», «Varsayılana dön», `settings.cfg`'nin `[input]` bölümü. | 9 |
| `test_kislak_fauna.gd`, `test_cart_felt_asset.gd` | Kışlak'ın hayvanları (deve, köpek, maral, kurt, ceylan, sığır: iskelet, beş klip, uzak ağ, ölçüler; dosya yoksa atlar) ve keçe araba gövdesi (kod tekerleğine oturur: yarıçap 0,72, iz 0,92). | 6 + 3 |
| `tools/proto_fixtures.test.mjs` (Node) | Fikstür çalıştırıcısı ve alan modülleri: alanların toplanması, `--check`, kararlı yazım, bekçinin değişen kuralı reddetmesi. `node --test tools/proto_fixtures.test.mjs` ile koşar, GDScript koşusuna girmez. | 9 |
| `test_prologue_birth.gd`, `test_synth_birth.gd` | Doğum sahnesi (`prologue_birth.json`, `PrologueBirth`): çizelge (tahminle 3:22,2–4:18,7; `act0.birth.12`, Hereka'nın sözü, tek kara sessizlik 2,5 sn, ilk ağlama, çentik, motif, kart «27 Eylül MÖ 234 · Ordos»), çekimler, ışık örnekleri, kişiler (`CineActor`, kimlik ve düğüm yolu sabit; kendi modelleri, Önsöz'ün Hereka'sı genç model, iki Lan kadını yer tutucu; renk çarpanı yalnız o kişiye), atanan klipler (K91: iki kurulumda aynı, çekim içinde aktarım yok, hiç yürümeyen Sayıcı'nın yürüyüşü kurulmaz; ikinci Lan kadınının oturuşunu sahne seçer, Lan Hatun'a girmez, alt bedeni döşekte), eğilme (`CineBow`), beşik, ağdan kesilen yay ve kundak modelleri (model yokken kodla çizim), güneye geçen turnalar, eşikte duran gölge, pano 8, ücretsiz varlıkların işaretleri; kodla ağlama, turna, motif ve ortam döngüleri. Kadraj kuralı (K98, 2026-11-07): canlandırmanın her kamera anahtarı konusundan ≥12 m, ay karesi dışında eğim ≥30° ve ufuk yok, görüş 30–40°; 7a 16–20 m ve kesmesiz, 7b güneş 28–34 m, ay ≥40 m (ufuk ve dolunay karede), 7c–7d kapıya ve sayıcıya 36–44 m ve tek kare, 7e 24–28 m ve tek kesme, panel_8'de kamera durur ve beşik ortada; 7a'da yurdun dış kabuğu ve çatı astarı gizli, duvar astarının dış yüzü çizilmez, kapı maskesi görünür, 7b'den sonra ve restore'da hepsi geri gelir (eski «kamera astarın içinde» sınaması kalktı); turnaların V'si ve zemindeki gölge izleri beşiğin karesinde; bozkırın kayası ve çalısı kişilere ve kadrajlara girmez. | 41 + 9 |
| `test_encyclopedia_data.gd` | Ansiklopedi verisi ve görselleri (`tools/import_encyclopedia.py`; K85): `kisiler.json` ve `mitler.json` sitenin kaydıyla eşleşir, soy bağları çözülür, mitlerle kişiler çakışmaz, görsel ve ses yolları dosyadır ya da boştur; görsellerin içe aktarması (BC7, mipmap, türüne göre boy sınırı); kitabın metninde belge atfı ve «Oyundaki yeri» yoktur (K97). | 6 |
| `test_free_assets.gd` | Ücretsiz varlıkların işareti (E7.5, K89; `assets/_free`): her dosya `<kind>/<id>/` klasörüyle `FREE_ASSETS.json`'daki bir kayda bağlıdır (denetimin henüz birleştirmediği yeni indirme `usage.jsonl`'da «new»: true ile); kaydın alanları tam, lisansı CC0 ya da kamu malı ve URL'siyle `LICENSES.md`'de; kullanılan kaydın dosyası `_staging` dışında (`path`), taşınan her kayıt kullanılır; `usedIn` ve `usage.jsonl` «sahne:düğüm» yazar; kaydın `catalog`'u ile Varlıklar kataloğunun (`docs/assets/catalog.json`) `free` alanı aynı bağı yazar. `.tscn`'de ücretsiz varlığa başvuran düğüm (yükleme listeleri dışında) ve kurulan sahnelerde (ücretsiz varlığı kendisi ya da betiği anan her sahne: `childhood_ordos`, `prologue_myth`, `prologue_birth`) ücretsiz varlığı çizen ya da çalan her düğüm `free_asset` meta verisini taşır (glTF örneğinin içinde işaret örneğin kökündedir); `usedIn`'deki her düğüm kurulan sahnede o kimlikle durur; modeller kapalıyken yedek düğümler yerindedir; Meshy modeli gelen kayıt `replacedBy` ile modeli, `fallbackIn` ile yedek düğümleri yazar, yalnız o kayıtta `replaceLater` false olabilir. Denetleyiciler küçük örneklerle de sınanır. | 10 |
| `tools/song/song_measure.test.mjs` (Node) | Şarkı ölçüsü aracı (`tools/song/song_measure.mjs`, K75): eş zamanlı perde (sentetik Batı akoru 3'ü geçer, tek tel + dron ve oyunun kodla kopuzu geçmez), sözcükler ve sözsüz bölümler, söz kipi ve motif, sayılan ölçülerin prototipin 3106 sayılarını vermesi, vuruş ızgarası (dönem, ilk ve son vuruş, oturan vuruş oranı; 3104'te 0,399 sn), denetim karışımı, `k75_measure.json` (3104–3107); Demucs ayırması yalnız kuruluysa (hiçbir şey indirilmez). `node --test tools/song/song_measure.test.mjs` ile koşar, GDScript koşusuna girmez, ffmpeg ister. | 20 |
| `test_run_tests.gd` | Koşucunun kendisi: test sürerken yazılan betik hatası, `push_error` ve motor hatası o testi düşürür, nedeni yeriyle (bozulan satır ← testin satırı; `await`'ten dönen işlevin yığında kalan eski çerçeveleri karışmaz) ✗ satırının altına yazılır; `await`'ten sonra ve test beklerken çalışan ertelenmiş çağrıdaki hata kendi testinde, test bittikten sonra çalışanınki ve dosya kapanırken yazılan dosyanın ✗ satırında yakalanır; `expect_errors` ile bildirilen hata düşürmez, yazılmayan düşürür, boş parça reddedilir; uyarı düşürmez; hata denetimden önce, aynı ileti `(×n)` ile tek satır; `after_each` betik hatasından sonra da çalışır; özet ve çıkış kodu bunları sayar. Bilerek hata yazan `tests/framework/selftest/test_faults.gd` ayrı bir Godot sürecinde gerçek koşucuyla koşar (kasıtlı hatalar bu koşunun konsoluna düşmez; elle: `tools/run_tests.sh --dir=res://tests/framework/selftest`). | 21 |
| `test_player_controller.gd` | Oyuncu denetleyicisi: kameraya göre yön, hızın yaklaşımı, engelden itilme, oyun alanının sınırı ve sahnede adım adım yürüme (gerçek klavye olmadan, `step()` ile). | 27 |
| `test_ring_wall.gd` | Otağa girilebilmesinin çarpışma kuralları: kapılı dairesel duvar (`RingWall`) ve döndürülmüş kutu (`ObstacleBox`); duvardan geçilmez, kapıdan geçilir, duvara yaslanınca kayılır, tek adımda öbür yana atlanmaz; oyuncu denetleyicisiyle birlikte. | 10 |
| `test_game_hud.gd`, `test_painterly_overlay.gd` | Tuş ipuçları şeridi (`GameHud`: yazı, tuş kapakçıkları, gösterme, kendiliğinden solma, gizleme) ve boyalı süzgeç (`PainterlyOverlay`: katman, tam ekran süzgeç, gölgelendirici ayarları, açma ve kapama). | 10 + 7 |
| `test_session_hud.gd`, `test_save_roundtrip.gd` | Oturumun HUD'a ve oyuncuya bağları (seviye ve XP gerçek ilerlemeyi okur; Yük yürüyüşü yavaşlatır: çocukta tek kütük ×0,8, koşu açık, zıplama kapalı; yetişkinin portresi) ve kayıt → yükle turu: `map`, saat, ilerleme, envanter ve Serbest Gez'de hava blokları yazılıp yeni oturuma aynen okunur; gerçek ana sahnede oto kayıt ve Devam Et deneme haritasına, aynı yere ve yöne döner (save-v2, inventory, levels-skills). | 5 + 9 |
| `test_wait_sleep.gd` | Bekle, Uyu, Dinlen ve Çalış tekeri (`WaitWheel`, `WaitPlan`; K20, K45): satırlar ve sınırlar (≤12 sa, uyku ≤15 sa yalnız Akşam ve Gece'de, Tokluk <25'te Çalış kapalı), bağlamın kipi (döşek, şantiye, ateş başı; atta hep Bekle, at yürürken «Atı durdur.»), görünür akış ve uyku atlaması, oto kayıt; T oyuncunun yaktığı ateşte de Dinlen açar (K108). | 9 |
| `test_gathering.gd`, `test_crafting.gd`, `test_gather_layer.gd` | Toplama ve zanaat (gathering, crafting; economy.md §3, §6): düğüm türleri ve `NodeStore` prototiple bit bit aynı (I. Perde'nin 3.270 kaydı, altın karma), `Gather`'ın vuruş süresi, Tam Vuruş ve araç kademesi; tarif ve tezgâh tabloları modelle aynı, tarif çözümü ve tezgâhın saati (`Workshop.tick`); deneme haritasının katmanı gerçek ana sahnede: 36 düğüm, balta ve kazma vuruşu, taşma sırası (Heybe, terki, yer yığını), iki tezgâh ve zanaat ekranı (K108). | 15 + 8 + 4 |
| `test_survival_fire.gd`, `test_survival_cooking.gd`, `test_survival_hunt.gd`, `test_survival_needs.gd`, `test_survival_session.gd`, `test_survival_view.gd`, `test_survival_layer.gd` | Ateş, pişirme, av, Tokluk ve yara (fire-hunting, hunger-wounds; survival.md; K108): yakıt ve evreler, Y ile yakıt, hava, çukur ve zon sınırı; istasyonlar, Tam Vuruş, kalite ve bozulma; av verimi, yüzme, büyük avda bıçak; `Needs` prototiple altın değerlerde aynı, açlık öldürmez, yara ve Düşüş (Umay Eşiği'nin bedeli); oturumun 4. adımı ve «survival» bloğu, uyku ve dinlenme atlamaları; ateşin ve HUD'un görünüşü; deneme haritasının katmanı gerçek ana sahnede (deneme takımı yalnız yeni yolculukta, Eski Ocak, tarif çemberi, basılı E ile Dinlen, yerleşimin ocağı, yer yığını leş sayılmaz). | 16 + 9 + 5 + 9 + 5 + 6 + 1 |
| `test_pace_limit.gd` | Kişilerin hız sınırı (E20, K105; `PaceLimit`): sınır oyuncunun koşusudur (çocukta 3,6, yetişkinde 4,6 m/sn); ölçü yürüyüşü doğru ölçer, ışınlanmayı yakalar, gizleneni hız saymaz; Çocukluk'un ve Yola Çıkış'ın kişileri, atlıları ve kalabalığı sınırı aşmaz. | 7 |
| `test_scene_voice.gd`, `test_camp_voice.gd` | Oynanan sahnelerin sesli sözleri (E20/7, K105): söz hemen ya da sırayla başlar, altyazı sesin süresi kadar durur, sözler üst üste binmez, tepki sözü konuşulurken düşer ve aynı rol aynı olayda 45 sn konuşmaz (`SceneVoice`); Serbest Gez'in kamp sözleri gerçek ana sahnede Voice yolunda çalar: Ana, ozan ve Baba birer kez (`CampVoice`). | 4 + 1 |
| `test_riding.gd`, `test_horse_hooves.gd` | Binicilik ve toynaklar (riding, horse-rig): `Mount`'un koşulu (Bağ, eyer, gem, terki), at staminası ve mahmuz, Bağ'ın kaynakları ve günlük sınırları, kayıt v2'nin «mounts» bloğu; toynak IK'sı (`RideableHooves`, `TwoBoneIK3D`) yamaçta ve basamakta ≤1,5 cm, sıçramanın havasında kapalı, zemini verilmeyen ata (menü atları) dokunmaz. | 8 + 6 |
| `test_mete_model.gd`, `test_mete_riding.gd` | Mete'nin modeli (K58, mete-model-checks): M1 tek ağ ve üçgen bütçesi, M4 kılık maskeleri, pelerinin kalçaya bağlanması, M5 yürüyüşte pelerin bacak arasından ayrılmaz, M11 ayak kayması, M12 taban; sürüşte `RideCape`, M6 arka köşeler at gövdesine ≤%3 ve ≤2 cm, M7 binme ve inme sıçramasız, M8 titreme yok, M9 eyer noktası, M10 diz ve kaval. | 6 + 6 |
| `test_atlas.gd` | Atlas (E20, K106, K107; godot.md §4.8): prototipin 75.000 km²'lik haritasının verisi (`AtlasGeo`), üç ev (Göl Obası, Ordos, Tanhu Kampı ayrı yerde), açılma kuralları ve siyasi katman (`AtlasPolitical`), kitabın HARİTA sayfasının kamerası, düzeyleri ve kırıntıları; tekerlek, iki parmakla kıstırma ve kaydırma görünümden geçer, jestin ikinci kopyası yok sayılır. | 10 |
| Diğer: `test_player_controller.gd`, `test_ring_wall.gd`, `test_game_hud.gd`, `test_painterly_overlay.gd` | Her modül kendi testleriyle gelir: oyuncu denetleyicisi (kameraya göre yön, hız yaklaşımı, engelden itilme, oyun alanı sınırı, sahnede adım adım yürüme, beklerken ara hareket ve hareket edince hemen kesilmesi), otağın kapılı duvarı (`RingWall`: duvardan geçilmez, kapıdan girilir, duvara yaslanınca kayılır; döndürülmüş kutu `ObstacleBox`), ipucu paneli ve boyalı ekran efekti. Her dosyanın ilk satırları neyi koruduğunu anlatır. | 27 + 10 + 10 + 7 |

Testlerin gerçekten hata yakaladığı da denetlendi: projenin bir kopyasında dünya koduna bilerek 35 küçük
hata eklendi (ör. üçgen sırasını ters çevirmek, kamp düzlüğünü daraltmak, çapraz hareketi sınırsız
bırakmak). 34'ünü en az bir test yakaladı; kalan biri davranışı hiç değiştirmeyen bir değişiklikti
(Godot aynı tuşu zaten iki kez eklemiyor). İncelemede 17 hata daha denendi (ör. arazinin köşe
renklerini ya da çimenin UV'lerini düşürmek, ateş ışığını dondurmak, çayır kurulurken betik hatası).
İlk hâlinde 12'si gözden kaçıyordu; bunların 8'inde konsolda `SCRIPT ERROR` yazdığı hâlde koşucu
testi "geçti" saydı. Testler güçlendirildi; şimdi 17'sinin hepsi yakalanıyor.
İkinci incelemede (oyunun parçaları birleştirildikten sonra) bu hatalar yeniden denendi ve yeni testler
için 25 hata daha eklendi (ör. menü kamerasını vadiye taşımak, kamerayla ateş arasına tepe koymak,
ateşin taş halkasını engel dairesinden büyütmek, karakterleri ateşe dönük olmaktan çıkarmak, bir ses
dosyasının adını bozmak, çimen tutamını yan çevirmek). Toplam 77 hatanın 76'sı yakalandı; kalan yine o
zararsız değişiklikti.

Koşucunun hata yazan testi düşürmesi de hata ekleme denemesiyle gösterildi (2026-11-05). Projenin bir
kopyasında oyun koduna 8 hata eklendi: ana menünün `_ready`'sinin sonunda betik hatası, kayıt yazıldıktan
sonra `push_error`, aynı sinyale ikinci kez bağlanma (motor hatası), ertelenmiş bir çağrıda, buton
işleyicisinde ve ateşin her karesinde (`_process`) betik hatası, çayır kurulurken betik hatası ve bir test
dosyasına kendi içinde betik hatası olan geçici bir test. Eklenmeden önce ilgili 93 test iki koşucuyla da
geçiyordu. Eski koşucu 7 hatada konsolda hata yazdığı hâlde bütün testleri "geçti" saydı (çayırınkini
yalnız `test_world_scene.gd`'nin kendi günlükçüsü yakaladı); yenisi 8'ini de yakaladı ve nedeni bozulan
satırla yazdı (ör. ana menü hatasında menünün 37 testi de düştü, kayıt hatasında yazan 8 test). Koşucunun
kendi testi (`test_run_tests.gd`) de denendi: koşucuya eklenen 11 hatanın (betik hatasını saymamak,
hatayı teste işlememek, uyarıyı saymak, yığındaki eski çerçeveyi yer diye yazmak, dosyanın hatasını
yazmamak, boş parçayı kabul etmek, betik hatasından sonra `after_each`'i atlamak...) hepsini yakaladı.

## Menü karesi: referansla karşılaştırma

Menü karesi her işte referansla karşılaştırılır (godot.md §1 madde 11, §8.5). Karşılaştırma pencere açtığı için
koşucuda değil, araçla yapılır; proje klasöründe, normal bir terminalden (kum havuzu pencere açtırmaz):

```bash
tools/capture.sh $TMPDIR/menu.png 360 --window=1920x1080 --freeze-time=12
python3 tools/image_diff.py tests/refs/menu.png $TMPDIR/menu.png --diff=$TMPDIR/menu_fark.png
```

- **Kararlı kare (`--freeze-time=12`).** Gölgelendiriciler zamanı `TIME` yerine `tn_time()`'dan okur
  (`shaders/include/world_time.gdshaderinc`). `world_time` genel tekdüzeni (`project.godot` `[shader_globals]`) normalde
  -1'dir ve `TIME` kullanılır; yakalama aracı (`scripts/dev/capture.gd`) onu 12. saniyeye sabitler: çimen, çiçek, su,
  alev, duman, gök, sancak ve kor donar. `tools/capture.sh` bununla Godot'ya `--fixed-fps 60` da verir (her kare 1/60 sn
  sayılır: karakterlerin canlandırması, ateş ışığının titremesi ve menünün girişi kare sayısına bağlanır) ve oyuncunun
  kayıt ve ayar dosyaları yerine boş bir geçici klasör açar (kayıt olmadığı için DEVAM ET ve YÜKLE soluktur, YENİ OYUN
  odaktadır; boyalı görünüm açıktır). Menü kamerası salınmaz ve fareye bakmaz, pencere girdi almaz (fare bir butonu
  ısıtmaz). Parçacık sistemleri (kor, ateş böcekleri) görüntüden 30 kare önce sabit tohumlu, kendi sabit adımı kapalı
  yepyeni kopyalarıyla değiştirilir: erken başlayan sistemin çizim sunucusundaki durumu yeniden başlatmayla da
  gizlemekle de sıfırlanmıyor ve ne zaman başladığı gerçek zamanda süren gölgelendirici derlemesine bağlı.
- **Karşılaştırma.** `image_diff.py` en az bir renk kanalı 8/255'ten çok değişen piksellerin oranını yazar; oran %0,5'i
  aşmıyorsa kare aynıdır (çıkış 0), aşıyorsa farklıdır (çıkış 1); okunamayan dosya ya da farklı boy 2'dir. `--diff=`
  değişen pikselleri kırmızıyla gösteren görüntüyü yazar. Bağımlılığı yoktur (PNG standart kitaplıkla açılır; numpy
  varsa hızlanır).
- **İki koşu aynı kare.** 2026-11-05'te aynı argümanlarla alınan dört kare (referans dahil) birbirinden %0,030–0,064
  piksel ayrıldı; sınır %0,5'tir. Kalan farkın iki kaynağı var: odaktaki YENİ OYUN düğümünün nabız halkası
  (`scripts/ui/knot_button.gd`, `Time.get_ticks_msec()` ile gerçek saatle atar; 270–660 piksel) ve birkaç kor ile ateş
  böceği (280–400 piksel; GPU parçacıkları yepyeni ve sabit tohumlu olsa da bit bit aynı çıkmıyor). Aynı karede
  `--freeze-time=13` %1,43 verir (FARKLI): dondurulan zaman gerçekten gölgelendiricilere gider.
- **Referans.** `tests/refs/menu.png` (1920×1080) bu komutla alındı (2026-11-08: ahır üç yanı kapalı, önü açık, atlar iskeletli ve beklerken klip oynar; aynı komutla iki koşu %0,045 ayrıldı; eski referanstan %0,665, fark ahırda; önceki referans 2026-11-07'nin K98 karesiydi: menü kamerası uzak ve yüksek kadraja geçti, ateşe 26,4 m, eğim 38°, görüş 36°; Apple M1 Pro, Metal); klasörde
  `.gdignore` vardır, Godot referansları içe aktarmaz; komut `tests/refs/README.md`'de de yazılıdır. Menü karesini
  bilerek değiştiren iş (model, gölgelendirici, ışık, arayüz) referansı aynı komutla yeniden alır ve farkı fark
  görüntüsüyle gösterir; beklenmeyen fark hatadır.
- **Önsöz'den menüye dönüş.** Önsöz menü karesine dokunduğu her şeyi (kamp dünyası, gök ve su tekdüzenleri, sis,
  menü kamerası, ateş başı, ses) bitince ya da atlanınca geri yazar. Başsız karşılığı anlık görüntü karşılaştırmasıdır:
  `test_cine_prologue.gd` (Önsöz sonuna dek; Esc kampta, mitte, doğumda) ve `test_prologue_camp.gd` (kamp segmenti).
  Pencereli denetim yukarıdaki komuttur: Önsöz'e ya da kampa dokunan iş menü karesini referansla karşılaştırır.
  Önsöz'ün dört fazından sonra (2026-11-05 16:28) kare referanstan %0,040 ayrıldı (sınır %0,5): AYNI. Referansın göz
  onayı kullanıcınındır.
- Zamana bağlı yeni bir gölgelendirici zamanı `TIME`'dan değil `tn_time()`'dan okur; `test_capture_args.gd` ham `TIME`'ı
  yakalar.

## Bütçe ölçümü

Bütçe sahnesi (`scenes/dev/budget_probe.tscn`, betiği `scripts/dev/budget_probe.gd`; godot.md §7.4) kampı sabit pozlarda
ölçer ve sonucu JSON olarak yazar; `tools/check_budget.py` sonucu `data/budgets.json`'daki sınırlarla (godot.md §7.2'nin
makine kopyası) karşılaştırır. Pencere açar, normal bir terminalden koşulur (bütün pozlar ≈12 dk):

```bash
tools/capture.sh $TMPDIR/budget.png 1 --scene=res://scenes/dev/budget_probe.tscn --window=1920x1080 --probe=camp --timeout=1800
python3 tools/check_budget.py $TMPDIR/budget.json --baseline=data/budget_baseline.json
```

- **Pozlar.** Önce menü karesi (menü kamerası ve arayüzüyle), sonra menünün «Serbest Gez» isteğiyle kampa inilir
  (varsayılan karakter ateşin önündedir) ve takip kamerasının kadrajıyla (odak noktanın 0,7 m üstü, dikey görüş 36°, K98;
  zemine gömülmeden) 5 nokta (ateş, ahır, yurtların arası, göle bakan yamaç, oyun alanının güney kenarı) × 4 yön (0°, 90°,
  180°, 270°) × 3 uzaklık (14, 28, 40 m) ölçülür; her biri varsayılan eğimde ve bandın iki ucunda (15°, 60°): 180 poz.
  Çimenin payı için menü karesi ve 28 m'deki 20 poz çimen tutamları gizlenerek yinelenir (`grass_share`: çimenli −
  çimensiz); çimensiz eş çimenli pozun hemen ardından ölçülür. Eşler ayrı uçlarda ölçülünce (ilk denemede) uzun koşuda
  makinenin yükü ve ısısı kaydı, çimensiz kare 5 ms'ye dek yavaş çıktı.
- **Okunan.** Dikey eşitleme kapalı, boyalı görünüm açık; 240 kare ısınma, her pozda 30 kare oturma ve 180 kare ölçüm.
  Kare süresi (tik farkı; ortalama, %95'lik dilim, en çok); görünür ve gölge geçişinin çizim, üçgen ve nesne sayısı
  (`Viewport.get_render_info`); CPU çizim süresi; süreç adımı (karenin `process_frame` anından en son işlenen düğümün
  `_process`'ine dek: GDScript bütçesinin ölçüsü; `Performance.TIME_PROCESS` çizimi de içerdiği için kullanılmaz); doku
  belleği (sahnedeki 3B malzeme dokularının ekran kartındaki boyu, biçim ve mip düzeyiyle; `texture_mem_probe.gd`'nin
  hesabı), tampon ve video belleği; sahnede konumsal ışık, çalan ses oynatıcısı ve MultiMesh üçgeni. Aygıt, sürücü,
  pencere, 3B ölçek ve makinenin yükü (`uptime`) rapora yazılır.
- **Denetim.** Sınıra dek tamam, sınırın %3 üstüne dek uyarı, daha üstü hata (çıkış 1); kare süresinin hedefi
  (kampta 16,7 ms) yalnız uyarıdır, sınırı (33 ms) kuraldır. Çizim ve üçgende pozun en büyük değeri, kare süresinde
  ortalaması sınanır; çimensiz pozlar sınanmaz. `--all` her pozu, `--baseline=` tabana göre farkı yazar.
- **Taban ölçümü** `data/budget_baseline.json`'dadır (2026-11-07 15:00; K98'in uzak kadrajıyla, Önsöz'ün modelleriyle; Apple M1 Pro, Metal,
  1920×1080, bilinear 0,67, MSAA 2×). Kare ortalaması en kötü 15,0 ms (yurtların arası, 28 m, eğim 15°; sınır 33 ms; bütün
  pozlar 16,7 ms hedefinin altında), %95'lik dilim en kötü 15,96 ms; süreç adımının ortalaması ≤0,51 ms (sınır 3); görünür
  çizim ≤450 (800), gölge çizimi ≤108 (600); görünür üçgen en çok 3,25M (sınır 3,5M), gölge üçgeni en çok 1,81M (sınır 2,5M);
  doku belleği 66,0 MiB (256), video belleği ≤466 MiB (1.024); konumsal ışık 6, gölgelisi yok; çalan ses oynatıcısı 3.
  `check_budget.py`: GEÇTİ. Çimenin payı (21 eş): kare +0,39 ms (en çok +0,74), görünür çizim +34 (50), görünür üçgen
  +63 bin (96 bin), gölgede yok. K98'den önceki taban (2026-11-07 09:35, 23,35°'lik kamerayla) en kötü 16,16 ms, görünür
  üçgen 3,48M, gölge üçgeni 2,48M'di. Modellerden önceki taban (2026-11-05 11:16) en kötü 15,51 ms, görünür üçgen 3,37M,
  gölge üçgeni 2,28M'di.
  Kesintilerden önceki taban (09:08) üçgende aşıyordu: görünür üçgen en çok 4,14M, gölge üçgeni 3,63M; 89 hata,
  26 uyarı, KALDI.
- **Kısa deneme.** `--probe-only=parça` yalnız kimliğinde parçanın geçtiği pozları ölçer (ör. `--probe-only=/28m/`);
  `--probe-frames=`, `--probe-warmup=`, `--probe-settle=` sayıları değiştirir. Taban ölçümü varsayılanlarla ve süzgeçsiz
  alınır (`test_budget_probe.gd` sınar). Önsöz'ün geniş karesi (`menu/wide`: menü kamerası WIDE'da nefes alır, menü
  arayüzü gizli; K68) yalnız süzgeçle istenince ölçülür (`--probe-only=wide`), taban ölçümünün poz listesi değişmez.
  2026-11-07 15:00'te, K98 kadrajıyla: kare ortalaması 14,67 ms (%95'lik dilim 15,45), görünür çizim 421, gölge çizimi 94,
  görünür üçgen 3,25M, gölge üçgeni 1,39M, doku belleği 65,4 MiB; `check_budget.py`: GEÇTİ. Önsöz'ün sineması ve Çocukluk
  `interior` satırıyla ölçülür: mit (`--probe=myth`) en kötü 4,06 ms, video belleği ≤660 MiB; doğum (`--probe=birth`, K98
  çekimleri) en kötü 8,94 ms (7d), gölge üçgeni en çok 1,26M (7a); Çocukluk (`--probe=childhood`, 63 poz: 7 nokta × 4 yön ×
  22 ve 40 m, ayrıca 14 m; üç çocuk, Lan Hatun, sayıcı ve sürü yerinde) en kötü 8,66 ms (sayım hattı, 40 m), görünür üçgen
  1,10M, gölge üçgeni 1,26M, doku belleği 72,9 MiB. Hepsi GEÇTİ (15:00–15:06). Çocukluk'un kareleri
  `scenes/dev/childhood_lineup.tscn`'de aynı kadrajla bakılır.
- **Dikkat.** Metal sürücüsü GPU zamanını bildirmez (0 yazar; raporda `gpu_timing: false`); dikey eşitleme kapalıyken
  kare süresi GPU'ya bağlıdır. Motorun doku sayacı (`Performance.RENDER_TEXTURE_MEM_USED`) Godot 4.7.2 Metal'de
  güvenilmez: 2026-11-05'te pencere 1920×1080 açılınca −758 MiB'e, büyütülmüş pencere (3456×2104, 488 MiB okuyordu)
  1920×1080'e küçülünce −593 MiB'e düştü ve işaretsiz sayı olarak ≈1,8·10¹⁹ bayt okundu; `tools/capture.sh` ile aynı
  ayarlı koşular kimi zaman 134 MiB, kimi zaman bu sarmış değeri verdi. Bu yüzden bütçe malzeme dokularının boyuyla
  sınanır; sayaç raporda `texture_counter_mib` olarak yalnız bilgi için durur (sarmışsa boştur). Video belleği sayacı
  (`RENDER_VIDEO_MEM_USED`) tutarlıdır. macOS'ta Godot 4.7'nin `rendering/scaling_3d/mode.macos` ayarı (varsayılanı 0,
  Bilinear) projenin FSR 1.0 ayarını (`scaling_3d/mode=1`) ezer: ölçüm bilinear 0,67 ile alınır (raporun
  `scaling_3d_mode` alanı). Aynı anda koşan başka işler (sınama, içe aktarma) kare süresini bozar; rapordaki
  `load_before` ve `load_after` bunu gösterir.

## Yeni test yazmak

`tests/unit/` içine adı `test_` ile başlayan bir dosya ekle:

```gdscript
extends TestCase
## Kısa açıklama: bu dosya neyi korur?


func test_camp_is_flat() -> void:
	var shape := TerrainShape.new()
	assert_almost(shape.height_at(0.0, 0.0), 0.0, 0.01, "Kamp ateşinin altı düz olmalı")


func test_menu_builds() -> void:
	var menu := preload("res://scenes/ui/main_menu.tscn").instantiate()
	add_child(menu)
	await wait_frames(2)        # sahnenin _ready'si ve ertelenmiş işler için
	assert_not_null(menu.get_node_or_null(^"%StartButton"))
	menu.queue_free()
```

Kullanılabilen denetimler (`tests/framework/test_case.gd`): `assert_true`, `assert_false`, `assert_eq`,
`assert_ne`, `assert_almost`, `assert_vec_almost`, `assert_between`, `assert_not_null`, `assert_null`,
`fail`, `watch_signal(sinyal)` (yayıldı mı, kaç kez, hangi argümanla), `await wait_frames(n)` ve
`expect_errors([parça])` (testin bilerek yazdırdığı hata; bkz. yukarıda). Her testten önce `before_each()`,
sonra `after_each()` çağrılır.

İyi bir test hızlıdır, her çalıştırmada aynı sonucu verir ve başarısız olunca nedenini Türkçe söyler.
Hesap yapan kodu saf `static func` olarak yazmak (ör. `Campfire.flicker`, `TerrainShape.height_at`)
onu sahne kurmadan test etmeyi kolaylaştırır.

## Dikkat edilecek tuzaklar

- **Betik hatası testi yarıda keser.** Godot, hata veren (ör. `null` bir düğüme erişen) test fonksiyonunu
  o satırda bırakır; koşucu testi düşürür ama sonraki denetimler hiç çalışmaz ve neden yalnız betik
  hatasının iletisi olur. Bu yüzden önce `assert_not_null(...)` ile denetle, `null` ise `return` et; tür
  belirsiz bir değeri (ör. `get_shader_parameter`) tipli bir denetime vermeden önce türünü (`is Vector3`)
  kontrol et. Mesh dizileri de eksik olabilir: `test_mesh_kit.gd` içindeki
  `_arrays(mesh, ad, gereken_diziler)` okumadan önce UV, renk gibi dizilerin varlığını denetler.
- **"Hata yazmamalı" sözünü koşucu her test için denetler.** Hata veren bir fonksiyon çoğu zaman boş bir
  değer döndürür ve denetimler geçer; koşucu yine de testi düşürür (bkz. «Konsola hata yazan test düşer»).
  Sözü belli bir adıma bağlamak gerekirse (ör. birkaç testin paylaştığı dünyanın kurulması, ya da
  hatanın kare sonunda çıkıp başka teste yazılması) test kendi günlükçüsünü kurar: `TestErrorLog.new()`,
  `OS.add_logger(...)`, iş, `OS.remove_logger(...)`, `take()`. Eski testlerdeki `_ErrorLog` sınıfları
  (`test_world_scene.gd`, `test_audio_util.gd` → `_errors_during`) aynı işi yapar.
- **Dosya yazan testler** `user://` yerine geçici bir klasör kullanmalı: oyuncunun kayıtları ve ayarları
  `user://` altındadır, kum havuzunda da `user://` yazılamaz. Kayıt ve ayar testleri
  `tests/support/temp_dir.gd` yardımcısını kullanır (`TempDir.fresh("ad")` boş bir klasör verir, `wipe` siler);
  ana sahneyi kuran test `main.saves = SaveSystem.new(klasör)` ile kayıt klasörünü sahneye eklemeden önce verir.
  Başsız çalıştırmada `GameSettings` autoload'u ayar dosyası okumaz ve yazmaz; ayar testleri kendi örneğini
  geçici bir dosyayla kurar.
- **after_each beklenmez.** Koşucu `after_each()`'i `await` etmeden çağırır: orada `await` kullanılırsa
  geri kalanı bir sonraki testin ortasında çalışır (ör. onun kayıtlarını siler). Temizliği hemen yap.
- **Arayüz sesleri:** Menü testleri `MenuStyle.muted = true` ile arayüz seslerini susturur (çıkışta yarım
  kalan ses oynatıcısı sızıntı uyarısı vermesin). Ana sahneyi kuran test bitince AudioManager'ın müziğini
  durdurur (`_silence_audio`).
- **Dünyayı durduran testler** (`get_tree().paused = true`, ör. duraklatma kitabı) `after_each()` içinde
  `get_tree().paused = false` yapmalı; `wait_frames` ve zamanlayıcılar duraklatılmışken de çalışır.
- **Basılan tuşları bırak:** `Input.action_press` kullanan testler `after_each()` içinde
  `Input.action_release` çağırmalı; yoksa sonraki testler "basılı" tuşla başlar.
- **Ses çalan düğümler:** Silindikten sonra ses sunucusu oynatıcıyı kendi iş parçacığında bırakır.
  Test hemen biterse çıkışta "ObjectDB instances were leaked" uyarısı yazılır; düğümü sildikten sonra
  ~0,2 sn beklemek yeterlidir (bkz. `test_campfire.gd` → `_free_and_settle`).
- **Başsız modun sınırları:** Sahte çizim sunucusu MultiMesh örnek dönüşümlerini saklamaz (yalnızca
  sayıları sınanabilir); mesh normalleri sıkıştırılarak, köşe renkleri 8 bit olarak saklanır, bu yüzden
  küçük bir toleransla karşılaştır.
- **Ortak kaynaklar:** `load()` aynı dosya için hep aynı nesneyi döndürür. `AudioUtil.load_stream(yol, true)`
  o dosyayı kalıcı olarak döngüye sokar; bir testte değiştirilen kaynak sonraki testleri de etkiler.
- **Yavaş sahneler:** Dünya sahnesi ~3-4 sn'de kurulur; `test_world_scene.gd` onu bir kez kurup dosyadaki
  sahne testleriyle paylaşır ve son sahne testinde (`test_world_frees_cleanly`) siler. Dünyayı kullanan
  yeni bir test eklersen onu `test_world_frees_cleanly`'den ÖNCE yaz (testler dosyadaki sırayla çalışır).
- **Sahne ayarını kurmadan okumak:** Bir sahnedeki kayıtlı bir değeri (ör. menü kamerasının konumu)
  okumak için sahneyi örneklemek gerekmez: `(load(yol) as PackedScene).get_state()` düğüm adlarını ve
  özelliklerini verir (bkz. `test_terrain_shape.gd` → `_scene_node_origin`).
- **Saf olmayan yardımcılar:** Sahneye eklenmemiş bir düğümün bazı fonksiyonları `_ready`/`rebuild`
  sırasında kurulan şeylere ihtiyaç duyar (ör. `Meadow.grass_height` gürültüyü ister). Böyle bir çağrı
  betik hatası verir ve test sessizce yarıda kesilir; yalnızca gerçekten saf olanları (`grass_density`) çağır.
- **`Engine.time_scale` bekçiyi de hızlandırır.** Koşucunun 180 sn'lik bekçisi `create_timer`'la kurulur ve ölçekli
  zamanla akar: `time_scale` 8 iken bir test 22,5 gerçek saniyede «takıldı» sayılır. Hızlandırılmış akış sınamaları
  ölçekli süreyi 180 sn'nin altında tutar (ör. `test_cine_prologue.gd`: `time_scale` 2, sinemanın kendi hızı 30;
  sinema hızı yalnız sinema saatini hızlandırır, bekçiyi değil) ve `after_each`'te `time_scale`'i 1'e döndürür.
- **Sinema ve gerçek `AudioManager`.** `AudioManager` bütün testlerin paylaştığı autoload'dur: ana sahneyi oynatan
  test bitince `stop_all()` ve `reset_buses()` çağırır. Önsöz'ün sahneleri dokundukları ortam döngülerini dizi o
  segmentte bitince (Esc) kendileri susturur; müzik bankası her baştan başlayışta katmanlarını bankanın düzeyine
  döndürür (önceki oynatmanın `set_layer_db`'leri taşınmaz). `test_cine_prologue.gd` ikisini de menü karesinin
  ses anlık görüntüsüyle ve yeniden oynatmayla sınar.
- **İlk arka plan yüklemesi çıkışta sızıntı uyarısı bırakır.** Godot 4.7.2'de ağır bir sahneyi (`prologue_birth.tscn`,
  `childhood_ordos.tscn`) ilk kez `load_threaded_request` ile yükleyen istek yükleme belirteçlerini bırakmıyor;
  koşunun sonunda «ObjectDB instances were leaked at exit» yazılır (Önsöz oynatması başına ≈18 nesne; oyunda
  zararsız). Önbellekteki kaynağı isteyen yükleme bırakmaz: sinemayı ana sahnede oynatan sınama segment sahnelerini
  ve dünyayı önceden `load()` ile yükleyip test boyunca bir dizide tutar (`test_cine_prologue.gd` → `_new_main`).
  Sonucu atılan `load()` yetmez: kaynak hemen bırakılır ve önbellekten düşer.
