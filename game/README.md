# Tanhu

Ay ışığında bir bozkır kampı: iki keçe yurt, çıtırdayan bir ateş ve başında beş kişi (Göl Obası'nın ocağı: Ana,
Çocuk, Baba, Ağabey ve kopuz çalan yaşlı ozan), ahırda iki at, aşağıda gölüyle ve dağlarıyla uzanan bir vadi.
Yeni Oyun, Hun Tanhusu Mete'nin doğumunu anlatan Önsöz'le başlar.

Tanhu, "After the Wind" ruhunda; Ghibli ile Ragnarok Online karışımı, yumuşak ışıklı, boyalı
(painterly) görünümlü ve sıcak bir 3B oyundur. Godot 4.7 ile, yalnızca GDScript kullanılarak yapıldı.

**Tasarım ve ilerleme:** Oyunun tasarımı `../docs/design` klasöründedir; Godot'da nasıl kurulacağı
`../docs/design/godot.md`'dedir. Belge sitesi `../docs-app` (`npm --prefix ../docs-app run dev`,
http://127.0.0.1:3100). Yapılanlar ve sıradaki işler sitenin Yol Haritası sayfasındadır (`/roadmap`, veri
`../docs-app/content/progress.json`): bir iş bitince orada da işaretlenir. Bütün varlıkların listesi, en mantıklı
üretim yolu ve Meshy kredisi Varlıklar sayfasındadır (`/assets`).

## Neler var?

- **Açılış sözü (Tanhu 1'deki gibi):** Oyun açılırken koyu ekranın ortasında Mete'nin sözü belirir:
  «Yer, devletin temelidir. Onu kimseye vermem.» (Mete, Hunların Tanhusu · MÖ 3. yüzyıl). Birkaç saniye kalır,
  bir tuşa, tıka ya da oyun kolu düğmesine basınca erken geçilir, sonra menünün girişi başlar.
- **Açılış ekranı (Tanhu 1'in menüsü):** Canlı gece kampının üstünde, sol üstte Tanhu 1'in altın TANHU
  logosu, süs çizgisi ve "BİR BOZKIR DESTANI"; altında düğüm butonları (koyu keçe plaka, ince altın kenar,
  iki yanda sonsuzluk düğümü): *YENİ OYUN*, *DEVAM ET*, *YÜKLE*, *DESTAN KİTABI*, *AYARLAR*, *ÇIKIŞ*. Okunurluk
  için soldan açılan koyu bir gölge, sağ altta kulaklık önerisi ve sürüm, onların üstünde *SERBEST GEZ*.
  Üzerine gelince buton ısınır: arkasında altın bir fırça darbesi ve parıltı belirir, yazı altına döner,
  buton hafifçe büyür. Butonlar arasında geniş boşluk vardır, parıltı komşu butona taşmaz. Oyun açılırken
  perde kalkar, logo ve butonlar sırayla gelir (bir tuşla atlanır).
  Menüler ve logo 1080 satırlık ekrandaki piksel boylarını korur: 2560×1440'ta (ya da Retina, 4K) ekranın
  daha azını kaplar, pencere boyu değişince (tam ekrana geçince de) hemen yeniden ölçeklenir.
  - *YENİ OYUN* yapımın geldiği yere kadar gerçek sırayı oynatır (K99): Önsöz → Çocukluk → Köprü 1 → oluşturucu
    «Yola Hazırlan» → Yola Çıkış → Köprü 2 → «I. Perde: Çan / Yapım aşamasında.» kartı → açılış ekranı. Akış kayıt
    yazmaz, oluşturulan Mete kampa inmez (K37); takvim yalnız ileri gider. *DEVAM ET* son kaydı açar; seçiliyken yanında son
    kaydın kartı (resmi, yeri, numarası, oynanan süre ve tarih) görünür. *YÜKLE* kayıt yuvalarını açar. Kayıt
    yoksa bu ikisi soluk ve seçilemez.
  - *DESTAN KİTABI*: Destan (ozanın gece kampı üstüne dizeleri), Gök ve Yer (tanrılar, ruhlar, töre ve «Doğum»;
    her girdinin çağ rozeti vardır), Kişiler (belge sitesinin ansiklopedisinden: Mete ve soyu, Hun ordası,
    komşular, Ç'in ve Han, yoldaşlar; ocak halkı ve iki at) ve Taşlar (ocak taşları, ahır, yosunlu kayalar,
    dikili kayalar, göl). Kayıtlar yaptıklarınla açılır (bkz. «Destan Kitabı»). Açılış ekranında son kaydın,
    oyunda süren yolculuğun açtıklarını gösterir.
  - *AYARLAR* Tanhu 1'in tam ekran kitabını açar: AYARLAR ve TUŞLAR sayfaları (bkz. aşağıda).
  - *SERBEST GEZ* süren yolculukla doğrudan kampa indirir.
- **Önsöz «Kopuz Söyler» (≈4 dk 18 sn, tamamen sinema):** üç sahne sırayla oynar. *Kamp ve şarkı:* kamera menü
  kadrajından 6 sn'de geniş plana çekilir, ozan kopuzunu kaldırır ve şarkısını söyler (ElevenLabs, çekim 3104), sonra
  3 sn sessizlik, 2 sn kararma, 1 sn kara. *Mit:* keçe aplike panolarda yaratılış, Erlik, gök çadırı, ilk ölü ve ateş,
  doğum yurdu; satırları anlatıcı okur (Eldrin), satır aralarında kopuz cevap verir. *Doğum:* 27 Eylül MÖ 234
  şafağı, Ordos (`childhood_ordos` dünyası, mit sürerken arka planda yüklenir): yurdun içi, Teoman'ın güne eğilişi,
  tek kara sessizlik, ilk ağlama, Hereka'nın «One more.» sözü, tarih kartı; son 10 sn Çocukluk'a geçiştir. Söz
  İngilizcedir, altyazı Türkçe. Esc'i (oyun kolunda B ya da Start) 0,6 sn basılı tutmak her an atlar (sağ altta
  halka dolar). Önsöz bitince ya da atlanınca Çocukluk başlar. Önsöz her Yeni Oyun'da oynar (K100); *AYARLAR → Oyun →
  Önsöz: İlk yeni oyunda* seçilirse yalnız bir kez. Sinemada yolculuğun süresi işlemez; Destan Kitabı'nda mitler ve
  «Doğum» açılır.
- **Çocukluk «Koyun Sırtında» (oynanır, ≈5–6 dk):** 22 Eylül MÖ 228, 08:40, Ordos. Beş yaşındaki Mete uyanır, ağıldan
  koyunları çıkarır, yaşlı koyuna biner, Luhun'la taşa yarışır, oyuncak yayla iki kuş ve bir fare vurur, sayım hattına
  koşar. Oyunun saati akar (2,5 sn = 1 oyun dakikası; söz sürerken durur); sayım 11:00'de olur, Dailin'in kalabalığı
  toplanır, Teoman atlılarıyla geçip çocuğa dört saniye bakar, «Beni gördü.» Ceza yoktur; 90 sn takılan oyuncuya
  Yançi hedefi gösterir. İkinci oyunda Esc'i basılı tutmak «Çocukluğu geç»tir (Köprü 1'e atlar).
- **Köprüler ve Yola Çıkış:** Köprü 1 (≈50 sn) ve Köprü 2 (≈18 sn) anlatıcılı parşömen videolarıdır. Yola Çıkış
  15 Aralık MÖ 213'te karlı şafak öncesinde oynanır: Mete yayını kardeşinin beşiğine asar, Eskam ve Huyan Hatun'la
  vedalaşır, Teoman'ın kapısı kapalı kalır, Lan Hatun dizgini uzatır («Kırk iki gün yol.»), Mete ata biner.
- **Oyun içi HUD:** sol üstte portre, can ve dayanıklılık; sağ üstte mini harita ve görev kartı, görevin yönünü
  gösteren işaret; alt ortada yuvalar (boşken de basılma efekti), XP çubuğu ve tuş ipuçları; sağ altta I, J, M.
  *M* kitabın HARİTA sayfasını açar (üst menünün altı kenardan kenara harita: yakınlaş, sürükle, Z / C ile döndür),
  *J* GÖREVLER'i, *I* envanteri (3B ve döndürülebilen karakter, kuşam yuvaları, heybe). HUD'un büyüklüğü
  *AYARLAR → Görüntü → Arayüz ölçeği*'ndedir (kaydırıcı %50–%150; menüler ve HUD birlikte, K104).
- **Ahır ve atlar (Serbest Gez):** üç yanı kapalı ahırdaki ata yanaşıp *E* ile binilir; koşu tuşu önce tırıs, basılı
  kalınca dörtnal; toz, iz ve toynak sesi. *Boşluk* yürürken zıplatır, atta atı sıçratır (havada inilmez).
- **Duraklatma (Esc):** Serbest gezintide Esc dünyayı durdurur ve yolculuğun kitabını açar: GENEL sayfasında
  *DEVAM ET*, *KAYDET*, *YÜKLE*, *AYARLAR*, *ANA MENÜ*, *MASAÜSTÜNE DÖN* ve yolculuğun kartı; ayrıca Destan
  Kitabı'nın dört bölümü, TUŞLAR ve AYARLAR. *ANA MENÜ* yolculuğu otomatik kayda yazar ve kamera yumuşakça
  menü manzarasına uçar; *MASAÜSTÜNE DÖN* önce sorar, otomatik kayda yazar ve oyunu kapatır.
- **Yola Hazırlan (karakter oluşturma):** Mete 20 yaşındadır. Parşömen panelde vücut tipi, ten, saç modeli ve rengi,
  göz rengi; ardından köken (Zırhlı Atlılar Arasında, Otağda Yetişen, Yılkı Beyi; K104), zorluk (Hikâye, Normal, Zor) ve pelerin
  boyası (Göl Mavisi, Gök, Çivit, Koyu Çivit, Menekşe; K101). Önizleme Kışlak Kaftanı'nı ve Kışlak Pelerini'ni giyer. Her seçim soldaki 3B karaktere anında uygulanır; karakteri fareyle sürükleyerek
  çevirebilir, tekerlekle (ya da Tab ile) yüzüne yakınlaşabilir, Esc ile adım adım geri alabilirsin.
- **Oyun kamerası (K98, uzak çekim):** her çekim uzak ve yüksek açılıdır (Diablo gibi): takip kamerası 38° eğim,
  36° görüş, 28 m (Çocukluk'ta 22 m), tekerlekle 14–40 m. Menü sahnesi, görev çekimleri ve oyun içi sinema da
  uzaktan çekilir; yurt içinde çatı kalkar, içerisi yukarıdan görünür. Kamerayla
  karakter arasına giren çam dalları ve kayalar noktalı saydamlaşır.
- **Boyalı görüntü:** Fırça darbesi efekti, yumuşak ışık, sis ve sıcak renk tonları her ekranda açıktır.
- **Sesler:** Menü müziği, gece çayırı ambiyansı, ateş çıtırtısı, at sesi ve arayüz sesleri.

## Godot'da açma

1. [Godot 4.7](https://godotengine.org/download)'yi indirip aç.
2. Proje Yöneticisi'nde **İçe Aktar (Import)** düğmesine bas ve bu klasördeki `project.godot` dosyasını seç.
3. Açılan pencerede içe aktarmayı onayla (**İçe Aktar ve Düzenle** / **Import & Edit**). İlk açılışta Godot
   tüm dosyaları içe aktarır; bu bir iki dakika sürebilir.

## Çalıştırma

Editörde **F5**'e bas (Mac'te **Cmd + B**) ya da sağ üstteki ▶ düğmesine tıkla. Oyun ana menüyle açılır.
Yalnızca o an açık olan sahneyi denemek için **F6** (Mac'te **Cmd + R**).

## Kontroller

| Nerede | Tuş | Ne yapar |
|---|---|---|
| Açılış ekranı | ↑ ↓ ya da fare | Butonlar arasında gezinir (başa sarar, soluk butonları atlar) |
| | → / ← | *SERBEST GEZ*'e geçer / sütuna döner |
| | Enter / Boşluk (oyun kolu: A) | Seçer |
| | Herhangi bir tuş | Açılış sözünü kısaltır, açılış girişini atlar |
| Önsöz | Esc'i basılı tut (oyun kolu: B ya da Start) | 0,6 sn'de Önsöz'ü atlar (sağ altta halka dolar); kısa basış atlamaz |
| Kitaplar (ayarlar, Destan Kitabı, duraklatma) | Q / E (oyun kolu: LB / RB) | Sayfa / bölüm çevirir |
| | Z / C | Ayarlarda bölüm, tuşlarda görünüm değiştirir |
| | Esc (oyun kolu: B) | Kapatır (duraklatmada oyuna döner) |
| | F5 / F9 | Oyundayken kaydetme / yükleme yuvalarını açar |
| Karakterini Oluştur | ↑ ↓ (W S) | Satır seçer |
| | ← → (A D) | Değeri değiştirir |
| | E / Enter | Onaylar |
| | Esc | Geri alır (geri alınacak bir şey kalmadıysa ekrandan çıkar) |
| | Fareyle sürükle | Karakteri döndürür (çift tıklama ilk açısına getirir) |
| | Fare tekerleği ya da Tab | Tam boy / yakın plan arasında geçer |
| Serbest gezinti | W A S D ya da oklar | Yürür (W her zaman ekranda "yukarı" gider) |
| | Shift | Koşar (atta: tırıs, basılı kalınca dörtnal, dörtnalda yeniden basmak mahmuzdur: +3 m/sn, at soluksuz kalınca kapanır; koyunda: dürter) |
| | Boşluk (oyun kolu: A) | Zıplar; atta atı sıçratır |
| | E | Ata ya da koyuna biner, iner; yerdekini alır |
| | Q / E | Kamerayı karakterin çevresinde döndürür (sağ tıkla sürüklemek de olur) |
| | Fare tekerleği ya da dokunmatik yüzeyde iki parmak | Yakınlaştırır / uzaklaştırır (iki parmakla kıstırma da; Alt'la eğer, yana kaydırma döndürür) |
| | Orta tuşla sürükle · Alt + tekerlek · `;` `'` | Kamerayı eğer (15–60°); sürüklemesiz orta tık kuzeye hizalar |
| | `/` | Kamerayı varsayılana döndürür (kuzey, 28 m; çocukta 22 m) |
| | I / J / M | Envanter / Görevler / Harita |
| | T | Bekle tekeri: Bekle, Uyu (döşekte), Dinlen (ateş başında), Çalış |
| | G (0,6 sn basılı) | Yükü Bırak: sırttakini yere yığın yapar |
| Envanter (I) | Tık · Shift · sağ tık · sürükle | Seçer, taşır; aktarma sekmesinde (yakında at varsa terki) tek tane ya da yığın |
| | Esc (oyun kolu: Start) | Duraklatma kitabını açar (dünya durur) |
| Çocukken (oyuncak yay) | Sağ tık (basılı tut) / sol tık | Nişan alır / oku bırakır; kamerayı orta tuşla sürüklersin |
| Çocukluk (ikinci oyunda) | Esc'i basılı tut | «Çocukluğu geç»: Köprü 1'e atlar (kısa basış kitabı açar) |
| Ateş başında (deneme haritası, yetişkin Mete) | E · E basılı (3 sn) · T | Tarif çemberi (pişir, ye, Ocağa Pay) · Dinlen (Bekle tekeri) · T de her yanan ateşte Dinlen açar |
| | Y · Y uzakta · F basılı | Ateşi besler ya da yakar · yer seçip ateş kurar · söndürür ya da küle yatırır |
| | E basılı (leşin yanında) | Avı yüzer |
| Harita (M) | Tekerlek ya da dokunmatik yüzeyde iki parmakla kıstırma ve kaydırma · sürükle · sağ tık ya da Shift'le sürükle · Z / C · çift tık | İmlecin altına yakınlaşır, kaydırır, döndürür, iki kat yakınlaşır; «Konumum» (Boşluk) oyuncuya döner |
| Her yerde | F11 | Tam ekran / pencere |

Tuşlar klavyedeki **yerlerine** göre çalışır: Türkçe Q ya da F klavyede de aynı konumdaki tuşlar kullanılır.
Bütün tuşlar oyunun içinde de görülebilir: *AYARLAR* → *TUŞLAR* (liste, klavye, oyun kolu ve atama görünümleri). *Atama*'da «Değiştir» sonraki tuşu ya da kol düğmesini dinler, tuş başka işe bağlıysa sorar; seçim `settings.cfg`'nin `[input]` bölümüne yazılır, «Varsayılana dön» siler.

## Ayarlar

*AYARLAR* sayfası Tanhu 1'deki gibi dört bölümdür; her değişiklik hemen uygulanır, sayfa kapanınca
`user://settings.cfg` dosyasına yazılır ve oyun her açılışta bu dosyayı okuyup uygular.

| Bölüm | Ayarlar |
|---|---|
| Oyun | Kamera dönüş hızı, fare hassasiyeti (sağ tıkla sürükleme), kamera takibi (yumuşak / normal / sıkı), görüş açısı (Geniş 40°), eğim payı (−3..+12°), oyunda eğim, ters sürükleme, tuş ipuçları, Önsöz (ilk yeni oyunda / her yeni oyunda) |
| Dil | Arayüz dili: Türkçe (Tanhu şimdilik yalnızca Türkçedir) |
| Görüntü | Pencere / tam ekran, çözünürlük ("Ekranı kapla" ya da 1280×720 … 3840×2160), dikey eşitleme, boyalı görünüm, arayüz ölçeği (kaydırıcı %50–%150, adım 5; menüleri, kitapları ve HUD'u birlikte ölçekler, HUD menülerin 0,8 katında çizilir; menüler ekrana sığdığı kadar büyür; 1080 satırdan yüksek ekranlarda arayüz ayrıca ekranın gerçek boyuna göre küçülür; K104) |
| Ses | Ana ses, müzik, seslendirme, efektler, ortam sesi (Master, Music, Voice, SFX ve Ambience veri yolları); seslendirme anlatıcıyı, ozanın şarkısını ve kişilerin sözünü (Destan Kitabı'nın tanıtımları da) ayarlar |

F11 her yerde tam ekran ile pencere arasında geçer ve seçimi kaydeder. Önsöz'ün görüldüğü de bu dosyaya yazılır
(`[game]` `prologue_seen`, içerik sürümüyle; kayıtta değil): yalnız *Önsöz: İlk yeni oyunda* seçilince ikinci Yeni
Oyun'da atlanır (K100; seçim `prologue_every` anahtarındadır). Çocukluk'un bir kez oynandığı da buradadır
(`childhood_done`): ikinci oyunda «Çocukluğu geç» sunulur. Geliştirme koşuları (argümanlı Godot) bu dosyaya yazmaz.

## Kayıtlar

Oyun 10 kayıt yuvası ve bir otomatik kayıt tutar (`user://tanhu3_save_N.json` ve küçük resmi
`user://tanhu3_thumb_N.png`). Bir kayıtta karakter (oluşturucudaki seçimler), oyuncunun kamptaki yeri ve
baktığı yön, oynanan süre, tarih, yolculuğun işaretleri (Destan Kitabı bunlarla açılır) ve Esc'ye basılan
anın 320×180'lik resmi vardır. Oyunda Esc → *KAYDET* (ya da F5) bir yuvaya yazar (dolu yuvada önce sorar),
*YÜKLE* (ya da F9) yüklemeden önce sorar. *ANA MENÜ* ve *MASAÜSTÜNE DÖN* otomatik kayda yazar. Açılış
ekranında *DEVAM ET* en son kaydı, *YÜKLE* seçilen yuvayı açar. Bozuk ya da yarım bir kayıt dosyası boş yuva
sayılır; oyun çökmez.

**Kayıt klasörü.** `user://` proje adından bağımsız, sabit bir klasördür (`project.godot`:
`application/config/use_custom_user_dir` ve `custom_user_dir_name="Tanhu Bozkir Destani"`). Kayıtlar, küçük
resimler ve `settings.cfg` buradadır:

| Sistem | Klasör |
|---|---|
| macOS | `~/Library/Application Support/Tanhu Bozkir Destani` |
| Windows | `%APPDATA%\Tanhu Bozkir Destani` |
| Linux | `~/.local/share/Tanhu Bozkir Destani` |

Proje adı bir daha değişse de kayıtlar öksüz kalmaz. Klasörün adı eski klasörlerden (`Godot/app_userdata` altındaki
`Tanhu`, `Tanhu 2D`, `Tanhu 2`, `Tanhu Ref`) ve proje adından ayrıdır: `~/Library/Application Support/Tanhu` başka bir
projenindir. Kayıt kimliği (`tanhu3`) ve dosya adları değişmedi.

**Eski klasörden taşıma.** Oyun önceden Godot'nun varsayılan klasörünü kullanıyordu (macOS'ta
`~/Library/Application Support/Godot/app_userdata/Tanhu`). Oyuncunun ilk açılışında oradan yalnız bu oyunun
dosyaları yeni klasöre bir kez **kopyalanır** (`scripts/save/user_dir_migration.gd`): kaydı olan yuvaların
`tanhu3_save_N.json`'u ve `tanhu3_thumb_N.png`'si ile bu oyunun anahtarlarını (`[game]` `camera_speed`,
`camera_follow`) taşıyan `settings.cfg`. Eski klasör olduğu gibi kalır; günlükler, gölgelendirici önbelleği ve
başka dosyalar alınmaz; `Tanhu 2D`, `Tanhu 2` ve `Tanhu Ref` klasörlerine hiç bakılmaz. Yeni klasörde aynı adlı
dosya varsa üstüne yazılmaz. Taşıma bitince yeni klasöre `legacy_migration.cfg` yazılır (nereden, hangi dosyalar,
ne zaman); bu dosya durdukça taşıma bir daha yapılmaz. Taşımayı ayarlar okunmadan önce `GameSettings` başlatır.

Geliştirme çalıştırmaları (komut satırında `--` sonrası bir argüman varsa, ör. `tools/capture.sh`) ve
testler oyuncunun kayıtlarına ve ayarlarına yazmaz, eski klasörden taşıma da yapmaz; ekran görüntüsü
denemelerinde `--save-dir=` ve `--settings-file=` ile başka bir klasör ve dosya verilebilir. `godot -s betik.gd`
ile koşan bir betik de, `--` argümanı olmasa ve pencere açsa da, geliştirme sayılır (`GameSettings.is_dev_run`):
ayara yazmaz, taşımaz. Godot her
çalıştırmada yeni klasörü kendisi kurar, günlüğünü (`logs/`) ve gölgelendirici önbelleğini oraya yazar; kayıt,
ayar ve taşıma dosyaları yalnız oyuncunun açılışında yazılır.

## Destan Kitabı

| Bölüm | Kayıt | Nasıl açılır |
|---|---|---|
| Destan | Ocak Başında | Baştan açık |
| | İlk Adım | İlk serbest gezinti |
| | Ateşin Sözü | Ateşin başına varmak |
| | Ahırda İki At | Ahırın önüne gitmek |
| | Taşların Dili | Büyük yosunlu bir kayaya ya da bir kaya kümesine varmak |
| | Göle Bakan Yamaç | Platonun kuzey kenarına, göle bakan yamaca varmak |
| | Gece Biterken | Ateş, ahır ve yamaç: üçü de |
| Gök ve Yer | Önsöz'ün tanrıları ve ruhları (Tengri, Umay, Erlik, Al Karısı …) ve «Doğum» | Önsöz'ü izlemek ya da atlamak (`onsoz`; oluşturucunun onayında yazılır) |
| | İyeler | Ateş başında ozanı 5 sn kesintisiz dinlemek (`ozan_dinledi`) |
| | Öteki tanrı ve ruh kayıtları | Henüz kapalı (sonraki perdeler açacak) |
| Kişiler | Ocak halkı: Ana, Baba, Ağabey, Çocuk, Yaşlı Ozan | Baştan bilinir |
| | Önsöz'ün kişileri (Teoman, Lan Hatun, Hereka, sayıcı …) | Önsöz'ü izlemek ya da atlamak |
| | Doru At, Ak At | Ahırın önüne gitmek |
| Taşlar | Ocak Taşları, Ahır, Yosunlu Kayalar, Dikili Kayalar, Göl | Yukarıdaki yerlere varmak |

Yeni bir kayıt açılınca sağ üstte "Destan Kitabı'na yazıldı: …" bildirimi çıkar. Metinler `data/destan.json`,
`data/mitler.json`, `data/kisiler.json` ve `data/taslar.json` dosyalarındadır; koşullar "a", "!a", "a || b",
"a && b" biçimindedir. «Gök ve Yer» ile Kişiler belge sitesinin ansiklopedisinden gelir ve onun düzeninde açılır
(bölüm sekmeleri, portreli dizin ve arama, görsel, bilgi satırı, soy bağları, kaynak notu; tanıtımı olan kişide
hoparlör): `python3 tools/import_encyclopedia.py` yazar (`--images` görselleri, `--voices` tanıtım seslerini
alır), Godot'ya özgü alanlara (`unlock`) dokunmaz.

## Proje yapısı

| Klasör | İçinde ne var |
|---|---|
| `scenes/` | Sahneler: `main.tscn` (oyunun başladığı sahne), `world/` (gece kampı ve vadi), `cine/` (Önsöz'ün üç sahnesi: kamp, keçe panolarda mit, doğum), `maps/` (`childhood_ordos`: doğumun ve Çocukluk'un Ordos'u), `ui/` (menü, karakter oluşturma, ipucu paneli, boyalı efekt), `player/` (oyuncu deneme sahnesi), `dev/` (geliştirme sahneleri; `cine_preview.tscn` bir sinema dosyasını ana sahne olmadan oynatır) |
| `scripts/world/` | Arazi, dağlar, göl, orman, çayır, kayalar, patikalar, ateş başındaki karakterler, renk tonu ve ortak malzemeler |
| `scripts/camp/` | Kamp nesneleri: yurt, kamp ateşi, ahır, atlar, sancaklar, halılar, eşyalar ve yedek chibi karakter |
| `scripts/character/` | Karakter seçenekleri, oyuncunun profili (kaydı) ve sahnedeki 3B karakter |
| `scripts/player/` | Oyuncunun hareketi ve takip kamerası |
| `scripts/camera/` | Ana menü kamerası (Önsöz'ün geri çekilmesi ve geniş planı da) |
| `scripts/cine/` | Sinema: zaman çizelgesi (`CineTimeline`; çapalı zaman, segment zinciri), çalıştırıcı (`CineRunner`), sahnedeki konak (`CineHost`: segment sahneleri, dünyaların arka planda yüklenmesi, perde, kart, altyazı, basılı Esc ile atlama), ses bağdaştırıcısı (`CineAudio`), Önsöz'ün sahneleri, keçe panolar (`FeltPanel`, `FeltShapes`), sinema kişileri (`CineActor`), turnalar ve eğilme |
| `scripts/maps/`, `scripts/systems/`, `scripts/sim/` | `childhood_ordos` dünyası (`OrdosWorld`, arazi, ocak közü), ışığın tek yazıcısı (`SkyRig`; sinemanın sabit ışık örneği) ve güneş ile ay hesabı (`Daylight`) |
| `scripts/ui/` | Açılış ekranı, Tanhu 1'in arayüz takımı (`UIKit`, düğüm butonu, süslü çerçeve), oyun kitabı (`GameMenu`: ayarlar, tuşlar, kayıt yuvaları, Destan Kitabı, duraklatma), karakter oluşturma ekranı, ipucu paneli ve boyalı ekran efekti |
| `scripts/save/` | Kayıt sistemi (`SaveSystem`, `SaveData`), süren yolculuk (`Journey`), yolculuk işaretleri (`JourneyFlags`) ve eski kayıt klasöründen tek seferlik taşıma (`UserDirMigration`) |
| `scripts/settings/` | Ayarlar (`GameSettings` autoload'u: `user://settings.cfg`) |
| `data/` | Destan Kitabı'nın metinleri (dizeler, mitler, kişiler, taşlar), seslendirme satırları (`vo_lines.json`: kimlik, konuşmacı, dilim, metin, tahmini ve gerçek süre), sinema çizelgeleri (`cine/`: Önsöz dizisi `prologue.json` ve segmentleri), müzik bankaları ve basma tarifleri (`audio/`), haritalar (`maps/`) |
| `assets/title/`, `assets/fonts/`, `assets/ui/` | Tanhu 1'in logosu, yazı tipleri (Alegreya, Cinzel; SIL Open Font License) ve arayüz sesleri; kitabın bulanık arka plan gölgelendiricisi |
| `scripts/audio/` | Müzik ve ses yöneticisi (`AudioManager`: menü müziği, müzik bankaları, ortam katmanları, söz ve kısma, sessizlikler), satır kataloğu (`VoLines`), müzik bankası (`MusicBank`), kısma tablosu (`DuckTable`), kodla ses sentezi (`synth/`: kopuz, dron, koro, kobuz …) ve ses yükleme yardımcıları |
| `scripts/core/` | Tuş atamaları (`InputSetup`) |
| `scripts/dev/` | Geliştirme araçları (ekran görüntüsü alma, karakter vitrini, stil laboratuvarı...) |
| `shaders/` | Görünümü veren gölgelendiriciler: yumuşak toon ışık, çimen, su, gökyüzü, boyalı efekt... |
| `audio/` | Müzik (`music/`), ortam sesleri (`ambience/`), efektler (`sfx/`), seslendirme (`vo/prologue/`: şarkı ve anlatıcı, sözcük zamanlarıyla; `vo/ency/`: kitabın tanıtımları), kodla basılanlar (`gen/`, `ambience/gen/`, `sfx/gen/`); `_source/` içinde üretilen özgün dosyalar |
| `assets/_free/` | Ücretsiz (CC0, kamu malı) dokular, HDRI'lar, küçük modeller ve sesler: `FREE_ASSETS.json` kaydı, kullanıldığı her düğüm `usage.jsonl`'da |
| `assets/characters/` | Meshy ile üretilen karakter modelleri (her klasörde bir `.glb`, klipleri ve `meta.json`) |
| `assets/structures/`, `animals/`, `props/`, `nature/` | Meshy ile üretilen yurt ve ahır, atlar, kamp eşyaları, kayalar ve çamlar (oyun boyunda dokularla) |
| `assets/_reference/`, `_concepts/` | Stil referansları ve her modelin gpt-image-2 ile üretilen konsept görseli |
| `assets/_meshy_raw/` | Meshy'nin ham çıktıları (8K dokulu kaynaklar; Godot içe aktarmaz) |
| `ui/` | Arayüz temaları (yazı tipi, renk, buton görünümü) |
| `tests/` | Birim testleri (`unit/`), küçük test altyapısı (`framework/`) ve test yardımcıları (`support/`) |
| `tools/` | Yardımcı komutlar: testler, ekran görüntüsü, ses üretimi, görsel ve model üretim hattı (aşağıya bak) |
| `docs/` | Ek belgeler (ör. [testler nasıl çalışır ve nasıl yazılır](docs/testler.md)) |

## Testleri çalıştırma

Terminalde proje klasörüne girip:

```bash
tools/run_tests.sh                     # tüm testler (boş makinede on iki dakika kadar)
tools/run_tests.sh --filter=terrain    # yalnızca dosya adında "terrain" geçenler
tools/run_tests.sh --filter=cine       # sinema: çalıştırıcı (test_cine.gd) ve Önsöz'ün bütünü (test_cine_prologue.gd)
node --test tools/song/song_measure.test.mjs   # şarkı ölçüsü aracının sınamaları (Node; GDScript koşusuna girmez)
node --test tools/proto_fixtures.test.mjs     # prototip fikstürlerinin çalıştırıcısı (Node)
```

Her test ✓ (geçti) ya da ✗ (başarısız) ile listelenir; ✗ olanların altında nedeni yazar. En altta
"N test, M başarısız" özeti çıkar. Testler pencere açmaz. Ayrıntılar: [docs/testler.md](docs/testler.md).

## Ekran görüntüsü alma

```bash
tools/capture.sh ~/Desktop/menu.png 360 --window=3200x1800
tools/capture.sh ~/Desktop/gezinti.png 480 --window=3200x1800 --state=play
tools/capture.sh ~/Desktop/karakter.png 360 --window=3200x1800 --state=creator
```

Oyunu açar, verilen kare sayısı kadar bekler (360 kare ≈ 6 saniye; dünya ilk açılışta birkaç saniyede
kurulur), görüntüyü kaydeder ve kapanır. `--window=3200x1800` pencereyi menünün tasarlandığı 16:9 orana
getirir, `--state=play` menüyü atlayıp doğrudan kampa iner, `--state=creator` karakter oluşturma ekranını
açar, `--hide-ui` menüyü gizler, `--pose=x,y,z,yaw,pitch` menü kamerasını belli bir yere koyar ve
`--scene=` başka bir sahneyi açar. Görüntünün yanına aynı adla bir `.log` dosyası (oyunun çıktısı) da
yazılır. Pencere açtığı için normal bir terminalden çalıştır.

Menü sayfaları ve kayıtlar için ek argümanlar (bkz. `scripts/main.gd`):

```bash
tools/capture.sh ~/Desktop/ayarlar.png 420 --window=3200x1800 --open=ayarlar:2     # Görüntü bölümü
tools/capture.sh ~/Desktop/tuslar.png 420 --window=3200x1800 --open=tuslar:1       # klavye görünümü
tools/capture.sh ~/Desktop/kitap.png 420 --window=3200x1800 --open=destan          # Destan Kitabı
tools/capture.sh ~/Desktop/kayit.png 480 --window=3200x1800 --state=play --save-dir=/tmp/kayitlar --dev-save=1
tools/capture.sh ~/Desktop/kart.png 420 --window=3200x1800 --save-dir=/tmp/kayitlar --open=kart
tools/capture.sh ~/Desktop/durak.png 480 --window=3200x1800 --state=play --pause    # duraklatma kitabı
```

`--open=` açılış ekranında bir sayfa açar (`ayarlar[:bölüm]`, `tuslar[:görünüm]`, `yukle`, `destan`,
`kisiler`, `taslar`, `onay`, `kart`); `--pause[=sayfa]` kampa inince duraklatma kitabını açar (`kaydet`,
`yukle` kayıt yuvalarını); `--dev-save=N` kampa inince N. yuvaya kaydeder; `--flags=a,b` yolculuğa işaret
koyar; `--at=x,z[,yön]` oyuncunun belireceği yer; `--save-dir=` ve `--settings-file=` kayıt klasörü ve ayar dosyası.

Önsöz ve sinema için:

```bash
tools/capture.sh ~/Desktop/onsoz_genis.png 420 --window=1920x1080 --state=prologue --cine-at=6.5 --hide-ui  # geniş plan
tools/capture.sh ~/Desktop/onsoz_gok.png 480 --window=1920x1080 --state=prologue --cine-at=103            # gök panosu
tools/capture.sh ~/Desktop/onsoz_safak.png 720 --window=1920x1080 --state=prologue --cine-at=186          # şafak (7b)
/Applications/Godot.app/Contents/MacOS/Godot --path . res://scenes/dev/cine_preview.tscn -- --cine=res://data/cine/prologue_myth.json
```

`--state=prologue` Yeni Oyun'un Önsöz'ünü (görülmüş olsa da) oynatır, bitince oluşturucu açılır; `--cine=<dosya>`
Önsöz yerine bir diziyi ya da tek segmenti (`data/cine/*.json`) oynatır; `--cine-at=SN` sinemayı o saniyeye sessizce
ileri sarar (geçilen olaylar sesi çalmadan durumu kurar; doğuma sarınca `childhood_ordos` önce yüklenir); `--cine-speed=K`
sinemayı K kat hızlı akıtır. Saniyeler Yeni Oyun'a basıştandır ve satırların gerçek süresine bağlıdır: satır
uzayınca sonraki her işaret aynı payla kayar (toplamı `tools/run_tests.sh --filter=cine_prologue` yazar; bugün
tahminle 3:46,9, gerçek sürelerle 3:49,6). `scenes/dev/cine_preview.tscn`
bir dosyayı ana sahne olmadan oynatır (`--cine-at`, `--cine-speed`, `--no-world`, `--quit`; bitince R yeniden
oynatır, Q kapatır).

Çocukluk, Yola Çıkış, HUD ve pelerin için:

```bash
tools/capture.sh ~/Desktop/cocukluk.png 480 --window=1920x1080 --state=newgame --step=count                 # Çocukluk, sayım adımı
tools/capture.sh ~/Desktop/yola.png 480 --window=1920x1080 --state=newgame --stage=depart --step=horse       # Yola Çıkış, at adımı
tools/capture.sh ~/Desktop/akis.png 600 --window=1920x1080 --state=newgame --autoplay --accept-creator       # akış tuşsuz akar
tools/capture.sh ~/Desktop/harita.png 420 --window=1920x1080 --state=play --hud-screen=map                   # M haritası
tools/capture.sh ~/Desktop/pelerin.png 150 --window=1920x1080 --freeze-time=12 --scene=res://scenes/dev/cape_lineup.tscn --stop=dawn --dye=0
```

`--state=newgame` Yeni Oyun'un akışını Önsöz'süz açar; `--stage=` aşamayı (`childhood`, `bridge_1`, `creator`, `depart`,
`bridge_2`, `end_card`), `--step=` adımı seçer (Çocukluk `wake|ride|hunt|count`, Yola Çıkış `yurt|yard|horse`);
`--autoplay[=mouse]` sahneleri botla oynatır, `--accept-creator` oluşturucuyu onaylar, `--skip-offer` «Çocukluğu geç»
sorusunu sunar. `--state=prologue --skip-prologue` Önsöz'ü basılı Esc'le atlar (akışın pencerede kaydı);
`--state=childhood` Ordos'ta sahnesiz kum havuzudur. HUD kareleri için `--hud-screen=bag|map|journal`, `--hud-press=1,3,8`
(yuvalara basar), `--inv-demo`, `--inv-select=`, `--inv-turn=` (envanter) ve `--map-view=yer,genişlik,dönüş` (harita);
Arayüz ölçeği `--settings-file=` ile verilen ayar dosyasının `[display] ui_scale` satırındadır (0,5–1,5). Pelerinin okunurluk
kareleri `scenes/dev/cape_lineup.tscn`'dir (`--stop=`, `--mode=crowd|dyes`, `--distance=`, `--key`, `--cape_hex=`
aday boya); ölçüm `python3 tools/palette_compare.py --cape` (P1) ve `--blob kare.png anahtar.png` (P4), ışık
durakları `data/character/cape_light_stops.json` (K101). Bütçe: `--probe=camp|myth|birth|childhood|depart`.

I. Perde'nin çekirdeği için:

```bash
tools/capture.sh ~/Desktop/deneme.png 360 --window=1920x1080 --state=testmap                       # deneme haritası, oluşturulan Mete
tools/capture.sh ~/Desktop/ogle.png 360 --window=1920x1080 --state=play --light=noon --no-fade      # Serbest Gez, öğle durağı
tools/capture.sh ~/Desktop/tipi.png 360 --window=1600x900 --state=play --weather=blizzard --weather-instant --hide-ui
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tools/bake_map.gd -- --map=camp   # kampı yeniden pişirir
node tools/proto_fixtures.mjs --check                                                                 # prototip fikstürleri güncel mi
```

`--state=testmap` deneme haritasını açar (`--spawn`, `--at`, `--dye=N`, `--drive`; `--swap-probe[=N]` kamp ile harita arasındaki geçişi ölçer); haritada kayıt yazılmaz. Serbest Gez'in saati ve ışığı: `--light=<durak>` (night, dawn, morning, noon, golden, dusk), `--clock=SS:DD`, `--day=N` (1.171 = 11 Nisan MÖ 209), `--no-fade`, `--freeze-clock`, `--cam-distance=M`. Hava: `--weather=<tür>`, `--weather-instant`, `--weather-strike=SN`, `--weather-strike-age=SN`. Pişmiş parçalar imzalıdır: kampın düzeni ya da üretim kodu değişince `tools/bake_map.gd --map=camp` yeniden koşulur (`test_map_bake.gd` düşer). Prototip fikstürleri `tools/proto_fixtures/<alan>.mjs` ile yazılır, `tests/fixtures/` altına; yazma kipini yalnız kendi alanınla koş (`--only=<alan>`). Eşya verisi modelden `python3 tools/export_items.py` ile yenilenir (`--check`); hava ayarı `tools/weather_calibrate.gd`, keçe araba gövdesi `tools/cart_body.py`.

## Sesler nasıl yapıldı?

Menü müziği, ses efektleri, ozanın şarkısı ve anlatıcının satırları ElevenLabs ile `tools/elevenlabs_audio.sh`
komutuyla üretildi (`tools/elevenlabs_audio.sh help` bütün seçenekleri yazar). API anahtarı dosyaya yazılmaz ve
yazdırılmaz; `ELEVENLABS_API_KEY` ortam değişkeninden, yoksa `--env-file=` ile verilen `.env` dosyasından okunur:

```bash
tools/elevenlabs_audio.sh --lines='act0.myth.*' --cost             # bekleyen satırların bedeli (ağsız, kredi harcamaz)
tools/elevenlabs_audio.sh --lines=act0.myth.3,act0.birth.12         # satırları üretir (eleven_v3, sözcük zamanıyla)
tools/elevenlabs_audio.sh --lines=act0.myth.4 --force --take=2      # beğenilmeyen okumayı başka tohumla yeniden
tools/elevenlabs_audio.sh music --plan=<plan.json> --out=<şarkı.mp3>  # şarkı (music_v2_5)
tools/elevenlabs_audio.sh sfx <çıktı.mp3> 20 true "Crackling campfire, close-mic"
tools/elevenlabs_audio.sh quota                                     # kalan kredi
```

Çocukluk, Yola Çıkış ve Serbest Gez'in kampındaki sözler de seslidir (K105: `act0.child.*`, `act0.depart.*`, `act0.camp.*`); sahneler sesi `scripts/story/scene_voice.gd` ve `camp_voice.gd` ile çalar, altyazı sesin süresi kadar durur, sözler üst üste binmez, sıraya girer. Satırlar `data/vo_lines.json`'dadır; araç her satırın dosyasını (`audio/vo/prologue/<kimlik>.mp3`), sözcük
zamanını (`<kimlik>.json`) ve gerçek süresini (`seconds`) yazar, her API çağrısını `tools/vo_ledger.jsonl` defterine
bir satır olarak ekler. Perdenin metni kilitli değilse ya da kilit tutmuyorsa üretmez; kalan krediden büyük bir iş
için durur (`--over` ister). Dosyası olmayan satır yer tutucudur: oyunda altyazısıyla, tahmini süresince akar.

Kampın ve mitin müziği, ortam döngüleri ve efektlerin çoğu kodla basılır, kredi harcamaz: `tools/bake_music.sh`
(`data/audio/bake/*.json` tarifleri, `scripts/audio/synth/` çalgıları; `--only=`, `--list`) müziği `audio/gen/`'e
(Ogg), ortam döngülerini `audio/ambience/gen/`'e, efektleri `audio/sfx/gen/`'e (22,05 kHz mono QOA) yazar.
Şarkı çekimlerinin K75 ölçüsü `node tools/song/song_measure.mjs` ile kredisiz alınır (sonuç
`tools/song/k75_measure.json`). Ücretsiz (CC0, kamu malı) kayıtlar `assets/_free/sound/` altındadır.

**Dikkat:** API anahtarlarını asla bir dosyaya yazıp depoya ekleme. `.env` dosyaları `.gitignore`
içindedir. Üretilen özgün dosyalar `audio/_source/` klasöründe durur; oyun `audio/music`, `audio/ambience`
ve `audio/sfx` içindeki kopyaları kullanır (kesintisiz döngü için çoğu WAV'a çevrildi).
Bir ses dosyası eksik olsa bile oyun sessizce çalışmaya devam eder.

## Modeller nasıl yapıldı? (gpt-image-2 + Meshy)

Bütün karakterler ve kamp/doğa modelleri aynı iki stil referansından üretildi:
`assets/_reference/style_mete.png` (Mete karakteri) ve `assets/_reference/menu_camp.png` (gece kampı; ana
menünün hedef görüntüsü). Üretim üç adımdır:

1. **Konsept görsel (gpt-image-2):** `tools/imagegen/gen.sh` Codex CLI'nin görsel üretimini kullanır
   (Codex'e ChatGPT hesabınla giriş yapmış olman yeter). Her model için referans stilde, düz arka planlı
   bir konsept üretilir: `assets/_concepts/<ad>.png`. Onaylanan konseptin yanında `<ad>.ok` dosyası durur.

   ```bash
   tools/imagegen/gen.sh --prompt "..." --out assets/_concepts/barrel.png --ref assets/_reference/style_mete.png
   ```

2. **3B model (Meshy):** `tools/meshy_pipeline.py` konsepti Meshy'nin görselden 3B servisine gönderir
   (meshy-7.1, 8K doku, Ultra geometri). Karakterlere iskelet (rig), yürüme/koşma ve planlı animasyonları
   (bekleme ya da yere bağdaş kurup oturma) ekler. Ham çıktılar `assets/_meshy_raw/<ad>/` içine iner;
   Godot bu klasörü içe aktarmaz. Hangi modelin hangi boyda, kaç poligonla ve kaç krediyle üretileceği
   `tools/asset_plan.json` içindedir. Araç bütçeyi aşacak ya da bakiyeyi tüketecek bir görevi başlatmaz,
   oluşturulmuş bir görevi de asla ikinci kez oluşturmaz (yarıda kalırsa kaldığı yerden devam eder).

   ```bash
   python3 tools/meshy_pipeline.py plan                          # planlanan toplam kredi
   python3 tools/meshy_pipeline.py --env-file ~/.../.env balance  # kalan kredi
   python3 tools/meshy_pipeline.py --env-file ~/.../.env run barrel
   python3 tools/meshy_pipeline.py status                        # her modelin durumu
   ```

   `tools/meshy_dispatch.py` onaylanan (`.ok`) konseptleri kendiliğinden, aynı anda en fazla 8 tane olacak
   şekilde Meshy'ye gönderir.

3. **Oyuna hazırlama:** `tools/glb_prepare.py` dokuları varlığın doku sınıfındaki oyun boyuna küçültür ve
   `.import`'unu VRAM sıkıştırmasına çevirir (`asset_plan.json` → `texture_class`: Mete, Lan Hatun ve Ağabey 2048² BC7,
   öteki adlı kişiler ve at 1024² BC7, yapı 2048² BC1, eşya 1024² ya da 512² BC1; 8K kaynak `_meshy_raw`'da kalır; `--textures <id|all>`
   var olan varlığın dokusunu yeniden yazar, `--classes` durumu gösterir);
   `tools/prepare_character.py <ad>` karakterin modelini, kliplerini (`<ad>_walk.res`, `<ad>_run.res`,
   `<ad>_sit.res`...) ve `meta.json` dosyasını `assets/characters/<ad>/` içine yazar. Yapılar
   `assets/structures/`, atlar `assets/animals/`, kamp eşyaları `assets/props/`, kayalar ve çamlar
   `assets/nature/` altındadır.

**API anahtarı:** `MESHY_API_KEY` ortam değişkeninden ya da `--env-file` ile verilen dosyadaki yalnızca
`MESHY_API_KEY=` satırından okunur; araç anahtarı hiçbir zaman yazdırmaz ve hiçbir yere kaydetmez.

Bir model dosyası eksik olsa bile oyun açılır: karakterler kodla çizilen chibi karaktere, kamp eşyaları
ve yapılar kodla çizilen sade sürümlerine geri döner.

## Sahneyi editörde değiştirme

Kamp nesneleri kodla üretilir ama editörden kolayca ayarlanır:

1. `scenes/world/world.tscn` sahnesini aç.
2. Sahne ağacında `Camp` altındaki bir düğümü seç: ör. `YurtLeft` (yurt), `Campfire` (ateş) ya da
   `Stable` (ahır).
3. Sağdaki **Denetçi (Inspector)** panelinde değerleri değiştir: yurdun yarıçapı, kapısının en az yüksekliği
   (`min_door_height`, varsayılan 2,05 m: 1,82 m'lik Mete eğilmeden girsin diye model dikeyde uzatılır) ve
   keçe rengi; ateşin ışık rengi ve alev boyu (`flame_scale`); ahırın genişliği... Yurdu büyütürsen çevresindeki
   çitleri ve eşyaları da biraz dışarı al (duvar yarıçapın ~0,93'ü, kapı basamakları ~1,25 katı kadar uzanır).
4. Çoğu değişiklik anında görünür. Görünmezse Denetçi'deki **Yeniden oluştur** düğmesine bas.
5. Nesneyi taşımak için sahnede sürükle. Kampın ortası (ateşten yaklaşık 10 m'ye kadar) ve ahırın altı
   tamamen düzdür; daha uzakta, özellikle vadiye bakan önde (-Z) zemin alçalır. Nesneler zemine
   kendiliğinden oturmaz; eğimli bir yere taşırsan `test_world_scene` testi "zemine oturmayan kamp
   nesneleri" diye uyarır. Ahırı taşırsan altındaki düz alanı da taşı: `scripts/world/terrain_shape.gd`
   içindeki `FLAT_PADS` (merkez, düz yarıçap, geçiş genişliği).
   Ateşi taşırsan onunla birlikte gidenleri de güncelle: başındaki karakterler (`CampNpcs` düğümü),
   `Meadow` düğümündeki `trample_center` (ezik çimenin merkezi) ve `World` düğümündeki ilk toprak lekesi
   (`dirt_spots`). `test_world_scene` bunları da denetler.
6. **Ctrl + S** (Mac'te **Cmd + S**) ile kaydet.

Ateş başındaki beş karakter (Meshy modelleri, gerçek boylarıyla) `scenes/world/camp_npcs.tscn`
sahnesindedir: `Mother` (`mother`), `Child` (`child`), `Father` (`father`), `OlderBrother` (`older_brother`) ve kopuz
çalan `Elder` (`elder`). Bir karakteri seçip Denetçi'de `model_override` ile modelini, `start_pose` ile
pozunu (`idle` ya da `sit`) değiştirebilir, karakteri sahnede sürükleyebilirsin; karakterler kendiliğinden
ateşe döner. Kopuz ve yay, sahiplerinin alt düğümleridir (`Kopuz`, `Bow`); onlarla birlikte döner ve
gizlenirler. Serbest gezintide oyuncunun kendi modeli (ör. Mete) ateş başında gizlenir, menüye dönünce
yeniden oturur.

Mete'nin bekleme ("Idle 4", Meshy 244) ve bağdaş kurup oturma (363) klipleri Meshy'de kendi iskeletine
üretilmiştir; kadın kahramanın oturması anneninkinden aktarılır. Meshy karakterleri T-pozunda iskeletlendiği için
köprücük kemikleri kollar inikken de yukarı bakar ve omuzlar kalkık görünür: `ShoulderRelax`
(`scripts/character/shoulder_relax.gd`) animasyondan sonra köprücükleri ölçülen açı kadar indirir (açı her
karakterin `<ad>_fit.json` dosyasındaki `shoulder_drop` değeridir).

Bir karakter modeli yeniden üretilirse oturma yüksekliği, adım hızları ve omuz açısı yeniden ölçülmeli (eksik
oturma klipleri başka karakterlerden aktarılır; yeniden aktarmak için `--retarget` eklenir), oyuncu
karakterlerinin renk maskeleri de yeniden çıkarılmalıdır:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://scripts/character/character_fit_tool.gd -- mete hero_f mother child father elder
python3 tools/bake_regions.py assets/characters/mete/mete.glb assets/characters/hero_f/hero_f.glb
```

Meshy iskeleti oyuna düzeltilerek girer (K92): `tools/prepare_character.py` modeli hazırlarken `tools/rig_fix.py` ile diz, omurga ve ayna farkı büyük omuz eklemlerini doğru yere taşır, uzun giysinin ağırlık alanını (`tools/garment_weights.py`, kişi başına `data/garment_weights.json`) ve parmak kemiklerini (`tools/hand_rig.py`; poz `scripts/character/hand_grip.gd`) aynı sırayla yazar, iskeletin sabit farkını ve bilek farkını `data/rig_calibration.json`'a yazar; düzeltilemeyen eklem hatasında durur, kişi kadroya girmez, başarıda sıradaki komutları yazar. Sıra sabittir ve hep hamdan hesaplanır: eklemler, ham ağırlık, omuz geçişi, etek alanı, parmaklar. Elle: `python3 tools/rig_fix.py --report` (yalnız ölçer), `--apply <id>`, `--calibrate`; ölçü için `tools/hand_rig.py --report`, `tools/garment_weights.py --report` ve `--suggest <id>`. Sonra içe aktarma, `--retarget <id>`, `tools/anim_library_import.gd -- --measure <id>` ve `tools/clip_library_export.gd` yeniden koşar.

Çayır, orman ve kayaların (`Meadow`, `Forest`, `RockField`) da kendi ayarları ve **Yeniden oluştur**
düğmeleri vardır. Tohum (seed) değerini değiştirmek aynı kurallarla bambaşka bir dağılım üretir.
