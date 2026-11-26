---
title: Arayüz ve Menüler
order: 40
status: kismen
summary: "Menü canlı gece kampının üstünde durur; Godot'da bugün açılış sözü, menü, oluşturucu, kayıt, ayarlar, tuşlar ve üç bölümlü Destan Kitabı var; kitabın kişi ve tanrı sayfaları ansiklopedi düzenine ve tanıtım sesine, HUD yoldaş kartlarına ve ekran kenarı göstergesine, Defter tek sekme listesine geçer."
sources:
  - docs/design/d3/oyun-durumu.md
  - docs/design/decisions.md
  - docs/design/godot.md
  - docs/design/companions.md
  - docs/design/progression.md
  - docs/design/economy.md
  - docs/design/settlement.md
  - docs/design/time.md
  - docs/design/weather.md
  - docs/design/story.md
  - docs/design/d3/register.md
  - docs/research/menu-spec.md
  - docs-app/content/encyclopedia.json
  - game/README.md
---

## Özü

Oyunu açan önce Mete'nin sözünü, sonra menüyü görür. Menü ayrı bir ekran değildir: düğmeler oyunun canlı gece kampının üstünde durur, ateş yanar, ozan ateş başındadır. Bütün tam ekran sayfalar tek kitap çerçevesidir: üstte simgeli sekmeler ve Q / E, ortada süslü çerçeve, altta tuş ipuçları. Arayüz bugün yalnız Türkçedir.

> [!NOT]
> «bizim canlı kamp»

Menünün altındaki kare oyunun kendi kampıdır ve korunur: menü, Yeni Oyun ve oluşturucu saat, hava ve yeni sistem okumaz; kare her işte referansla karşılaştırılır ([K20](/docs/source/design/decisions#k20), [K29](/docs/source/design/decisions#k29); [Yol Haritası](/roadmap#item-menu-reference)). Menünün kalıbı, logosu ve üç arayüz sesi (sayfa, ret, bildirim) Tanhu 1'den gelir ve kalır; değişirse sen karar verirsin ([K32](/docs/source/design/decisions#k32)).

| Adım | Süre | Ne olur |
|---|---|---|
| Mete'nin sözü | 1,6 sn açılır, 4,2 sn durur, 1,2 sn söner | Koyu ekranda «Yer, devletin temelidir. Onu kimseye vermem.» · Mete, Hunların Tanhusu · MÖ 3. yüzyıl. Basış bekleyişi kısaltır; belirirken basılan tuş sayılmaz |
| Menünün girişi | Perde 2,0 sn | Siyahtan kampa açılır; logo 1,1 sn'de, alt yazı 1,9 sn'de belirmeye başlar, düğmeler 2,3 sn'den 0,1 sn arayla soldan kayarak gelir; bir tuş girişi atlar |
| Serbest Gez'e iniş | Menü 0,5 sn'de söner | Kamera açıyı değiştirmeden kayarak karakteri ortalar; yükleme ekranı yok |
| Menüye dönüş | | Önce oto kayıt, sonra kamera yumuşakça menü manzarasına uçar |

![Godot'nun ana menüsü: DEVAM ET odakta, yanında Son Kayıt kartı; sağ altta SERBEST GEZ. Bu kare arayüz kodundan ölçüm için çizildi: arkadaki resim durağan referans resmidir, oyunda arkada canlı gece kampı durur.](/media/docs/research/menu-shots/menu_01_saves_continue_focus.jpg)

## Menü

Sol üstte altın TANHU logosu, süs çizgisi ve «BİR BOZKIR DESTANI»; altında düğüm düğmeleri: koyu keçe plaka, ince altın kenar, iki yanda sonsuzluk düğümü. Üzerine gelince düğme ısınır: arkasında altın bir fırça darbesi belirir, yazı altına döner. Sağ altta «Kulaklıkla oynaman önerilir», sürüm ve onların üstünde SERBEST GEZ. Yön tuşları, Enter ve oyun kolu sütunu gezer; soluk düğme odak almaz.

| Düğme | Bugün | Tasarımda |
|---|---|---|
| YENİ OYUN | Kayıt varsa sorar: «Yeni bir yolculuk başlayacak; otomatik kayıt yeni yolculuğa geçer. Emin misin?»; ilk yeni oyunda Önsöz oynar (Ayarlar'da «Her yeni oyunda» seçilebilir), ardından Çocukluk, Köprü 1, oluşturucu, Köprü 2 ve «I. Perde: Çan, yapım aşamasında» kartı gelir, açılış ekranına dönülür; kampa inilmez, akış kayıt yazmaz ([K99](/docs/source/design/decisions#k99)) | Önsöz «Kopuz Söyler» başlar; oluşturucu Çocukluk ve Köprü 1'den sonra «Yola Hazırlan» olarak gelir ([K36](/docs/source/design/decisions#k36), [K68](/docs/source/design/decisions#k68)) |
| DEVAM ET | Son kaydı açar; odaktayken Son Kayıt kartı: küçük resim, yer, kayıt numarası, oynanan süre, tarih. Kayıt yoksa soluk | Kayıt kartı tarih ve evre yazar: «8 Haziran MÖ 209, ikindi»; I. Perde'de «Gün II, ikindi» ([time.md §11](/docs/source/design/time#11-arayuz-ve-metinler)) |
| YÜKLE | Kayıt paneli: 1 otomatik ve 10 elle yuva, küçük resim; bozuk kayıt boş yuva sayılır | Kayıt bloklu yeni sürüme geçer, eski kayıt okunur |
| DESTAN KİTABI | Destan, Gök ve Yer, Kişiler, Taşlar; kişi ve tanrı sayfaları ansiklopedi düzeninde (aşağıda) | Aynı |
| AYARLAR | Ayarlar ve Tuşlar | Yeni satırlar aşağıda |
| ÇIKIŞ | Masaüstüne döner; web ve mobilde yok | Aynı |
| SERBEST GEZ | «Kampta dolaş»: süren yolculukla kampa iner, oluşturulan karakter yürür | Kayıtlı saat yoksa 11 Nisan MÖ 209'un 14:46,2'sinde açılır; oluşturulan yetişkin değil Çocuk yürür ([K37](/docs/source/design/decisions#k37), [K76](/docs/source/design/decisions#k76)) |

**Kayıt.** 0. yuva otomatik kayıttır: ana menüye ya da masaüstüne dönerken yazılır. Küçük resim yalnız duraklatmada ve menüye dönüşte çekilir. Kayıt ve ayar klasörü proje adından bağımsız sabitlenir, eski klasörden yalnız bu oyunun kayıtları ve ayarı bir kez taşınır ([K30](/docs/source/design/decisions#k30); [Yol Haritası](/roadmap#item-user-dir)).

**Geçiş ve yükleme.** Yükleme ekranı yerine karartma ve yolculuk vardır: kampa dönüş karartma altında ≤2 sn, iç harita yüklemesi ≤6 sn ve atlas yolculuğunun altında sürer; Kışlak, Köprü 2'nin panoları okunurken yüklenir ([K64](/docs/source/design/decisions#k64)).

Doğrulanacak: kamp dünyası bugün başsız testte 3–4 sn'de kurulur; kampa dönüşün ≤2 sn'yi ve iç haritanın ≤6 sn'yi tuttuğu sınanır ([Yol Haritası](/roadmap#item-world-swap)).

```varlik
ui_logo, ui_game_icon, ui_menu_buttons, ui_save_slot, ui_loading
```

## Kitap

Kitap bütün tam ekran sayfaların ortak çerçevesidir. Q ve E sekme çevirir, Esc geri döner ya da kapatır. Oyundayken açılınca dünya durur, arkada son kare bulanık kalır.

| Nereden açılır | Bugünkü sekmeler | Tasarımda |
|---|---|---|
| Menü › AYARLAR | Ayarlar, Tuşlar | Aynı |
| Menü › DESTAN KİTABI | Destan, Gök ve Yer, Kişiler, Taşlar | Aynı |
| Oyunda Esc (duraklatma) | Genel, Destan, Gök ve Yer, Kişiler, Taşlar, Tuşlar, Ayarlar | Aynı |

Genel sayfasında DEVAM ET, KAYDET, YÜKLE, AYARLAR, ANA MENÜ ve MASAÜSTÜNE DÖN düğmeleriyle yolculuğun kartı durur: yer, oynanan süre, Destan, Gök ve Yer, Kişiler ve Taşlar'ın kaçının açıldığı. F5 kaydeder, F9 yükler. ANA MENÜ yolculuğu otomatik kayda yazar; MASAÜSTÜNE DÖN önce sorar.

![Godot'nun duraklatma kitabı, Genel sayfası: solda altı düğme, sağda yolculuğun kartı (Ahırın Önü · Gece Kampı; Destan 4/7, Kişiler 7/7, Taşlar 2/5).](/media/docs/research/menu-shots/pause_general.jpg)

## Destan Kitabı ve ansiklopedi

> [!NOT]
> «ansiklopedi sayfasi ve karakterler su tarz olacak buna gore duzenle»

**Bugün.** Destan Kitabı dört bölümdür: Destan (ozanın gece kampı üstüne dizeleri), Gök ve Yer (tanrılar, ruhlar, töre ve «Doğum»), Kişiler (sitenin ansiklopedisinden) ve Taşlar (ocak taşları, ahır, yosunlu kayalar, dikili kayalar, göl). Destan ve Taşlar'ın kayıtları kampta yaptıklarınla açılır: ilk dize baştan açıktır; ilk gezinti, ateşin başı, ahır, kayalar ve göle bakan yamaç yenilerini açar. Düzeni solda kayıt listesi, sağda başlık ve metindir. Gök ve Yer ile Kişiler ansiklopedi düzenindedir: simgeli altı bölüm sekmesi, arama ve portreli dizin, görsel şeridi, numaralı bölümler, soy kartları, kaynak notu; konuşan 96 kişide hoparlör tanıtım sesini çalar. Önsöz'ün mit girdileri ve «Doğum» Önsöz'le açılır ([Yol Haritası](/roadmap#item-epic-book-encyclopedia)). Parşömen düzeninin göz onayı [Karar Bekleyenler](/docs/general/pending-decisions)'dedir.

![Godot'da Destan Kitabı'nın bugünkü Kişiler sayfası: solda Ocak Halkı ve Atlar, sağda seçilen kaydın metni.](/media/docs/research/menu-shots/book_kisiler.jpg)

**Tasarım ([K85](/docs/source/design/decisions#k85)).** Kişiler sayfası ve tanrıların «Gök ve Yer» bölümü sitenin [Ansiklopedi](/encyclopedia)'siyle aynı düzene geçer; düzenin kaynağı senin gönderdiğin örnek ekrandır (Erlik Han sayfası). Destan ve Taşlar bugünkü düzende kalır. Kitabın sırası Destan, Gök ve Yer, Kişiler, Taşlar olur ([godot.md §3.8](/docs/source/design/godot#3-8-destan-kitabi-ansiklopedi-duzeni-k85-k86)).

| Yer | İçerik |
|---|---|
| Üst | Açık parşömen; simgeli altı bölüm sekmesi: Tanrılar ve Ruhlar (güneş), Mete ve Soyu (yay), Hun Ordası (yurt), Komşu Halklar (at), Ç'in ve Han (kule), Yoldaşlar (kişiler). «Gök ve Yer» ilkini, Kişiler öteki beşini açar |
| Sol | Arama kutusu ve portreli dizin: yuvarlak portre, ad ve sanı; açılan kayıt sayısı «n / N açıldı» |
| Orta | Tam boy görsel ve altında üç küçük resim: PROFİL, ART, 3B ya da T-POZ. Kişinin modeli varsa üçüncüsü döndürülebilir 3B'dir, yoksa T-poz görselidir. Görseli üretilmemiş kayıtta «Görsel henüz üretilmedi.» yazar |
| Sağ | Ad ve sanı, yanında hoparlör; numaralı bölümler («01 Kimliği», «02 Gelenekteki Görünüşü», «03 Anlatı Notu»); bilgi satırı (Gelenek / Alanı / Motifler); Soy Bağları (üst soy, alt soy; portreli kartlar, basınca o kişiye gider); kaynak notu |
| Alt | Tuş satırı: Q E bölüm · ↑ ↓ kişi · ← → görsel · Enter büyüt · Esc geri |

- **Tuşlar.** Q / E bölüm değiştirir; bölüm sınırında (Q'da ilk, E'de son bölüm) kitabın komşu sayfasına geçer. ↑ / ↓ kişi seçer, ← / → görseli döngüyle değiştirir, Enter görseli tam ekran büyütür. Esc sırayla geri döner: önce büyütülmüş görseli kapatır, sonra aramadan çıkar, sonra kitabı kapatır. Arama kutusu odaktayken Q ve E harf yazar. Oyun kolunda LB / RB bölüm, yön tuşları kişi ve görsel, A büyüt, B geri; hoparlör Y, klavyede Boşluk.
- **Arama.** Ada, öteki adlara ve sana bakar; Türkçe büyük ve küçük harfi ayırmaz: İ / i ve I / ı ayrıca eşlenir, çünkü Godot'nun küçük harfe çevirmesi dile bakmaz.
- **Açılma.** Kayıt bugünkü gibi oyunda yaptığınla açılır; açılmamış kayıt dizinde görünmez. Soy bağında açılmamış kişi adsız keçe siluettir, basılmaz.
- **Görseller.** Önce tam boy art (1024 × 1536), sonra art'tan profil (1254 × 1254) ve T-poz (1024 × 1536); taç, giysi, renk ve zemin üçünde aynıdır. Görseller gpt-image-2 ile kredisiz, sorulmadan üretilir. Üçüncü küçük resim modeli olan kişide döndürülebilir 3B'dir (bugün on kişi: Mete, Ozan, Çocuk, Ana, Baba, Teoman, Lan Hatun, Ağabey, Sayıcı, Hereka), olmayanda T-poz; T-poz Meshy'nin girdisidir, yeni 3B önce sorulur. Ayrıntı [Görsel Dil](/docs/presentation/visual-language).
- **Bellek.** Sayfa yalnız seçili kişinin görsellerini yükler, komşu iki kişiyi önden ister, kapanınca bırakır; kişi başına ≈2,1 MiB, kamp satırının doku belleğine sayılır.

![Erlik Han'ın profili: art'tan türetildi, kitabın dizinindeki yuvarlak portre bundan kesilir.](/media/docs/assets/encyclopedia/erlik/portrait.webp)

**Tanıtım sesi ([K86](/docs/source/design/decisions#k86)).**

> [!NOT]
> «Ve burda bir yere bir icon ekle ve o ikona bastigimzida karakterin konusma sesi ile karakter kendisini tanitsin 2 cumle ile ben erlik ...»

Başlığın yanındaki hoparlöre basınca kişi kendini iki cümleyle tanıtır: söylenen İngilizce, Türkçesi tuş satırının üstünde iki satır altyazıdır. Ses kişinin oyundaki konuşma sesidir; anlatıcının ve ozanın sesleri başka kişilere verilmez. Yeniden basmak susturur; başka kişiye geçince ya da kitap kapanınca satır susar. Söz ana sözdür: çalarken müzik ve ortam kısılır. Kitap duraklatmada da açıldığı için ses duraklatmada da çalar. Dosyası olmayan kişide hoparlör görünmez, iki cümle yazıdır; oyunda konuşmayan kişide ([Umay](/encyclopedia/umay), [Mene](/encyclopedia/mene)) hoparlör hiç yoktur. Bugün yalnız [Erlik Han](/encyclopedia/erlik)'ın tanıtımı var ve başka bir sesledir; oyunun Erlik sesiyle yeniden okunur. Bedel kişi başına ≈110 kredidir, her tur önce toplamıyla sorulur ([Seslendirme](/docs/presentation/voice-over)).

![Erlik Han'ın tanıtımı: «I am Erlik, lord of the world below. Every breath that leaves the steppe comes down to my river in the end.» / «Ben Erlik'im, alt dünyanın beyi. Bozkırdan çıkan her nefes sonunda benim ırmağıma iner.»](/media/docs/media/audio/vo/en/ency.erlik.mp3)

```varlik
ui_destan_book
```

```ilerleme
prologue-p3
```

## Ayarlar

| Bölüm | Bugün | Tasarımda eklenecek |
|---|---|---|
| Oyun | Kamera dönüş hızı (60–160°/sn), Fare hassasiyeti (0,1–0,5°/px), Kamera takibi (Yumuşak, Normal, Sıkı), Görüş açısı (Dar, Normal, Geniş), Tuş ipuçları (Açık, Kapalı) | Kamera eğim payı (−8..+20°), oyunda eğim (açık), X ve Y ters çevirme (kapalı), tekerlek eşlemesi (açık) ([K39](/docs/source/design/decisions#k39)); Saat göstergesi (Evre ya da Evre ve saat); altyazılar; yoldaş ayarları (aşağıda) |
| Dil | Arayüz dili: yalnız Türkçe | English ([Yol Haritası](/roadmap#item-english-ui)) |
| Görüntü | Ekran (Pencere, Tam ekran), Çözünürlük, Dikey eşitleme, Boyalı görünüm (Açık, Kapalı), Arayüz ölçeği (%80, %90, %100) | Şimşek Parlaması (Tam, Yumuşak, Kapalı); Hareketi Azalt ve yüksek karşıtlık ([Yol Haritası](/roadmap#item-accessibility)) |
| Ses | Ana ses, Müzik, Efektler, Ortam sesi | Seslendirme ([Yol Haritası](/roadmap#item-voice-bus)) |

Zorluk ayar değildir: oluşturucuda seçilir, kayda yazılır, kitaptan değişir (Hikâye, Normal, Zor; [Yol Haritası](/roadmap#item-difficulty)). İkinci oyunda Önsöz varsayılan olarak atlanır; bu bir ayardır, kayıtta değildir.

**Tuşlar.** Bugün üç görünüm vardır: ne zaman işe yaradığına göre gruplanmış liste (yürürken, karakter oluşturmada, menüde), her tuşun üstüne işini yazan klavye ve oyun kolu; sayfa tuşları doğrudan tuş haritasından okur. Tasarımda her satıra «Değiştir» gelir: sonraki tuşu dinler, tuş aynı bağlamda başka eyleme bağlıysa «Şuna da bağlı: {eylem}» diye sorar, eski eylem boş kalmaz; «Varsayılana dön» bütün atamayı siler; atama ayar dosyasına kaydedilir ([Yol Haritası](/roadmap#item-key-rebinding)). Tuş adları klavye dizilişinden okunur: Türkçe Q'da kamera tuşları Ö, Ç ve nokta görünür ([K27](/docs/source/design/decisions#k27)). Q I. Perde'de Çığırtkan'dır, II'den hızlı silahtır ([K82](/docs/source/design/decisions#k82)). Tuşların tamamı [Kamera ve Kontroller](/docs/gameplay/camera-controls) sayfasındadır.

![Godot'nun Ayarlar sayfası, Oyun bölümü: kamera dönüş hızı, fare hassasiyeti, kamera takibi, görüş açısı ve tuş ipuçları.](/media/docs/research/menu-shots/book_settings_0.jpg)

## HUD

**Bugün.** Serbest Gez'de yalnız sol altta küçük bir ipucu paneli vardır: WASD Yürü · Shift Koş · Q/E Kamerayı döndür · Tekerlek Yakınlaş · Esc Menü. Serbest Gez'e inince belirir, 7 sn sonra söner; Ayarlar › Oyun › Tuş ipuçları kapatır.

![Godot'nun ipucu paneli, sol altta. Arkadaki kare durağan referans resmidir.](/media/docs/research/menu-shots/x_hud.jpg)

**Tasarım.** HUD'un yerleri sabittir; yoldaş kartları bu yerlerin dışında, kenar boyunca kayar (`companions.md` §7.3).

| Yer | Parça | Ne söyler |
|---|---|---|
| Sol üst | Can ve Stamina bloğu | Can ve Stamina |
| Sol kenar | Parti şeridi | Dikey on Yoldaş Kartı (F1–F10), altında hayvan kartları |
| Sağ üst | Harita düğmesi (M), Gök Kavisi, hava simgesi | Gök Kavisi yayda güneşi ve ayı yürütür, altında evrenin adı; dokununca Bekle tekeri; Son Gece'de Ay Saati; Tipide gizli. Hava simgesi on simgedir, cephe 1 saat içindeyse altında ok ([weather.md §11](/docs/source/design/weather#11-arayuz)) |
| Üst orta | Yer adı | «Tanhu Ordusu · Oba» gibi |
| Alt orta | 1–6 çubuğu (Çubuk); yerleşimde Plan Kipi çubuğu | Çubuk etkin beceri ve sarf eşyası alır (kuru et, kurut, sargı, meşale, tuzak); II'den 6. yuvada Çığırtkan. Plan Kipi'nin yedi kategorisi ([Plan Kipi](/docs/settlement/plan-mode)) |
| Sol alt | İpucu paneli | Bugünkü panel |
| Ekran kenarı | Tehdit okları ve yoldaş kartları | Ok biçimi durumu söyler: boş üçgen izliyor, dolu üçgen yanaşıyor, halka ateş edecek, kanca kement; en çok 3 ok, vuruştan en az 1,2 sn önce yanar ([K39](/docs/source/design/decisions#k39)) |

Kut ve Korku sayı göstermez: Kut altın güneş, Korku kızıl kordur, dört parlaklık kademesi vardır (0–3, 4–7, 8–13, 14+). I. Perde'de Güven Çentik Çubuğu'dur: 5 puana 1 çentik ([progression.md §5](/docs/source/design/progression#5-kut-ve-korku)). Tokluk ve Yük göstergeleri ekonomi sayfalarındadır ([Envanter ve Yük](/docs/economy/inventory-load)).

```varlik
ui_vitals, ui_hotbar, ui_interact_prompt, ui_sky_arc, ui_threat_edge
status_hp, status_stamina, status_load, status_fullness, status_wound
```

## Yoldaş kartı ve ekran kenarı

> [!NOT]
> «10 companiona kadar alabiliriz ve her companionun kendi profil resminden mini dairesel kartı olacak eğer haritada gözükmüyorlarsa bu mini çeber profil resimleri gözükecek ne tarafta olduklarını belli edecek şekilde»

**Yoldaş Kartı ([K70](/docs/source/design/decisions#k70)).** Her yoldaşın kendi portresinden yuvarlak kart; Destan Kitabı'nın dilindedir: koyu keçe, altın çift çizgi, baklava süs, gök mavisi vurgu. Boy 56 px (Küçük 44, Büyük 72), hayvan kartı 40 px.

| Parça | Yer | Ne söyler |
|---|---|---|
| Portre | 48 px daire | Kim; portre kişinin profil görselinden 256 × 256 kesilir |
| Can bandı | Altın çift çizginin arasında, saat 12'den saat yönünde | Can yay boyuyla; %35 altında kor rengi ve 1 Hz nabız |
| Baklava | Saat 12 | Kenar kartında çevrede döner, yoldaşın yönünü gösterir |
| Yara | Saat 6'da üç küçük baklava | Yara 0–3; dolu baklava kızıl |
| Durum rozeti | Saat 4 | Çapraz kılıç savaşta, damla yaralı, iki damla Ağır Yaralı, kırık halka kayıp ya da geride kaldı, kare bekliyor ya da Burayı Tut, üç nokta konuşmak istiyor, kapalı göz gizlenmiş, yatık sancak düştü |
| Konuk düğümü, baş işareti | Saat 8 ve saat 10 | Konuk; onluğun başı (küçük ıslıklı ok) |
| Seçili, konuşuyor | Bütün kart | Seçili kart ×1,08 ve gök mavisi hale; konuşan yoldaşta iç çizgi 0,3 sn parşömen rengine döner |

Biçim önce gelir, renk ektir: hiçbir bilgi yalnız renkle verilmez. Düşmüş kartta portre %70 solar.

**Parti şeridi.** Sol kenarda, Can ve Stamina bloğunun 24 px altından başlayan dikey on kart, aralık 66 px; sığmazsa Küçük boya, yine sığmazsa iki sütuna geçer; ayarla 1–6 çubuğunun soluna yatay 2 × 5 olur. Kartın altında tuşu yazar (F1); ad üstüne gelince görünür. Sol tık seçer, çift tık kamerayı yoldaşa çevirir, sağ tık bağlam menüsünü açar: Çağır, Dur, Burayı Tut, rol işi, Burada Bırak, Defter sayfası. Boş yuva ince çizgili keçe dairedir. Sinemada, kitapta ve Plan Kipi'nde şerit ve kenar kartları gizlenir.

**Ekran kenarı göstergesi ([K73](/docs/source/design/decisions#k73)).** Varsayılan 28 m kamerada ([K98](/docs/source/design/decisions#k98)) 10 m'den çok geride ya da 16 m'den çok yanda kalan yoldaş ekrandan çıkar; kart bu yüzden olağan görünüştür.
- **Ne zaman.** Göğüs noktası (yerden 1,2 m) ekranın %4 içeride çizilen dikdörtgeninin dışında 0,25 sn kalınca kart çıkar, %8 içeri girince kaybolur. Kadrajda ama 1 sn'den çok örtülü yoldaşın başının üstüne 36 px işaret konur.
- **Nerede.** Kart merkezi yuvarlatılmış iç dikdörtgendedir: yanlardan 64, üstten ve alttan 60 px, şerit soldayken sol 128 px, köşe yarıçapı 96 px. HUD'un ayrılmış yerleri yasaktır, kart kenar boyunca en yakın boş yere kayar. Yön ekranın ortasındaki Mete'dendir; kameranın arkasındaki yoldaşta yön zemin düzleminden okunur, geri ekranda aşağıdır.
- **Uzaklık.** 30 m'de 56 px ve %100, 150 m'de 44 px ve %75; uzaklık 60 m ötede, kayıpta ya da Tab basılıyken 10 m'ye yuvarlanıp yazılır («120 m»).
- **Kümelenme.** İki kart 64 px'ten yakınsa kümelenir, 80 px'te ayrılır; en çok üç portre yelpaze olur, dördüncüden sonra «+N».
- **Tehditten ayrım.** Tehdit okları her zaman öndedir ve portresizdir; oka 64 px'ten yakın kart kenar boyunca en çok 80 px kaçar, kaçamazsa %50 saydamlaşır. Yoldaş göstergesi üçgen kullanmaz.
- **Hareket.** Çıkış 0,20 sn solma ve 0,15 sn kayma; kenar boyunca yumuşak kayma, açısal hız ≤540°/sn: kamera dönerken kart sıçramaz. 3 Hz'den hızlı yanıp sönme yoktur; Hareketi Azalt'ta kayma anlıktır.
- **Tıklama.** Sol tık kamerayı 0,6 sn'de yoldaşa çevirir, gerekirse uzaklık 40 m'ye dek açılır; sağ tık çağırır; Shift ile sol tık seçer.

| Ayar | Değerler | Varsayılan |
|---|---|---|
| Kenar kartı | Hep, yalnız dövüşte ve kovalamacada, hiç | Hep |
| Kart boyu | 44, 56, 72 px | 56 |
| Uzaklık yazısı | Uzakta, hep, hiç | Uzakta |
| Şeritte ad | Üstüne gelince, hep | Üstüne gelince |
| Şeridin yeri | Sol, alt | Sol |
| Er ile doldur | Açık, kapalı | Açık |
| Gezi söyleşisi | Az, olağan, çok | Olağan |
| TV güvenli alanı | %0–5 | %0 |
| Yüksek karşıtlık | Açık, kapalı | Kapalı |

Doğrulanacak: kartın ve kenar göstergesinin sayıları ekranda denenir; ilk ayar Ku'nun kartıyla yapılır ([Yol Haritası](/roadmap#item-ku-card-edge)), on kartla 1080p ve 1440p'de, 14 ve 28 m kadrajda yinelenir; göz onayı senindir ([Yol Haritası](/roadmap#item-party-ledger-strip)).

Kartın görünüşü senin onayını bekler: gpt-image-2 taslağı şimdi, oyundaki ilk kart Godot'da çizilince oyun içi kare ([Karar Bekleyenler](/docs/general/pending-decisions)). Kuralın tamamı [Yoldaşlar](/docs/gameplay/companions) sayfasındadır.

```varlik
ui_companion_card, ui_offscreen_indicator, ui_party_strip, ui_animal_card, ui_empty_slot
```

## Heybe, Defter, Terazi

Hepsi kitabın çerçeve dilindedir; açıkken oyun durur.

**Defter / Ledger (L; [K62](/docs/source/design/decisions#k62), K70).** Tek sekme listesi, bu sırayla ([progression.md §14.1](/docs/source/design/progression#14-1-ekran)):

| Sekme | İçerik | Ne zaman |
|---|---|---|
| Künye / Record | Seviye, XP, statlar, Kut ve Korku parlaklığı | Hep |
| Beceriler / Skills | Beceri dalları; K doğrudan açar | Hep |
| Yoldaşlar / Companions | Tanınan yoldaşlar, durum, düğüm (0–3), Can ve Yara, kişisel görevin adımı, öğrenilen sevdikleri, atı ve terkisi; Al, Burada Bırak, Ordugâh'a Gönder, Görevlendir, Subay Yap, Baş Yap, Çağır; P doğrudan açar | Hep; I. Perde'de yalnız yanındakiler |
| Çeteleler / Tallies | Kefil çeteleleri | Hep |
| Adlar / Names | Bilinen adlar, Ad İpi | Hep |
| Kış Hesabı / Winter Ledger | Teslim edilen yiyecek, yakacak ve yem; ordugâhta ok. I. Perde'de İş Tahtası'nda da görünür: aynı veri, iki yüz | Hep |
| Zula / The Cache | Gizli erzak yuvaları; haritada yalnız bu sekmede görünür | Hep |
| Yerleşim / Hold | Üstte «Yurdun / Your Hold» · «Ordugâh / Encampment» seçici; yapı ve kervan sayfaları onun içinde | II'den |

Arayüz adı «Defter» kalır; hikâye içinde sayım çentikle yürür: sinemada «Sayım Çetelesi» denir, Mete: «Hun yazmaz, çentikler.» Görevler (J) ve Destan Kitabı ayrı kitaptır ([Yol Haritası](/roadmap#item-ledger)).

**Yerleşim sekmesi** ([settlement.md §14.2](/docs/source/design/settlement#14-2-yerlesim-defteri-hold-ledger)): Özet, Halk, İş, Ambar, Sürü, Yapılar, Kervan, Kademe. Kut ve Korku sayı göstermez; Gönül düğüm, Çekim dört kademedir; hane ve gün sayıdır.

**Heybe / Pack (I; [economy.md §4.2](/docs/source/design/economy#4-2-yuva-ve-sekmeler)).** Sekmeler: Sırt (Yük ≥3 olanlar), Erzak ve Zanaat (ortak 24 yuva), Araç, Hatıra (satılmaz, atılmaz), Yoldaş Terkileri (yoldaşın atı 15 m içindeyken). Yük sayılır; G basılı tutulunca Yükü Bırak. Aktarma panelinde iki sütun durur, heybe ve kap; «Eksikleri Al» şantiyenin eksiğini alır ([Envanter ve Yük](/docs/economy/inventory-load)).

**Görevler (J).** Vakitler saatle değil evreyle yazılır: «Öğle çanı · Öğle»; çağrıda «Seni çağırıyorlar.» II–VI'da takvim olayı tarihle yazılır: «Dailin · 16 Eylül».

**Terazi / Balance ([economy.md §9.2](/docs/source/design/economy#9-2-terazi-balance)).** Takas ekranıdır; iki kefe, mal sürüklenir ya da tıklanır. Kiriş verilen ve alınanın oranıyla en çok 18° eğilir; etiket «Denk», «Eksik» ya da «Fazla» der; istenen mal kefede hafifçe parlar. I. Perde'de sayı yoktur. II'den Kabuk görünür: her kefenin altında «Eder {n}», üstte «Kese {n}», «Fazla»da «Üstü {n} kabuk»; kese yetmezse «Kesem yetmez.» ([K48](/docs/source/design/decisions#k48); [Para ve Satıcılar](/docs/economy/money-traders)).

```varlik
ui_pack_panel, ui_ledger_book, ui_skill_tree, ui_quest_book, ui_winter_ledger
```

## Altyazı

- Söylenen İngilizcedir, altyazı Türkçedir; İngilizce arayüzde altyazı İngilizcedir ([K61](/docs/source/design/decisions#k61)). Konuşanın adı başta yazar; adı bilinmeyen firarinin sözü adsızdır.
- Şarkıda dizeler söylendiği saniyede açılır; altyazı sözcük zamanlarından çıkar ([Seslendirme](/docs/presentation/voice-over)).
- Ses dosyası eksikse satır altyazıyla, metnin uzunluğuna göre süreyle akar.
- Altyazı kare bütçesi için kesilmeyecekler listesindedir; altyazı ve yüksek karşıtlık ayardır ([godot.md §7.5](/docs/source/design/godot#7-5-once-ne-kesilir)).
- Diyalogda konuşanın portresi kutuda durur; bloklayan sözde saat durur ([Yol Haritası](/roadmap#item-dialogue)).

## TR ve EN

- Bugün arayüz yalnız Türkçedir ve çeviri tablosu yoktur; yeni kod her dizgeyi baştan anahtarla yazar, TR ve EN tek tabloda durur ([godot.md §1](/docs/source/design/godot#1-ilkeler)).
- Adlar tek çeviri tablosundadır. İngilizcede kim konuşuyorsa onun sözü: atlas, Destan, kronik kartı ve Han ağzı «Xiongnu»; anlatıcı, ozan, Hun ve Yüeçi ağzı «Hun» der ([K34](/docs/source/design/decisions#k34)). Oyuncuya unvan «Tanhu»dur; «kağan» ve «hanlık» oyuncu metninde geçmez.
- Tarih tam ve kesin yazılır: «27 Eylül MÖ 234» / «27 September 234 BC» ([K33](/docs/source/design/decisions#k33)).
- İngilizce arayüz ve dilin Ayarlar'dan değişmesi yayından önceki fazdadır ([Yol Haritası](/roadmap#item-english-ui)).

## Oluşturucu ve portre

**Bugün.** «Karakterini Oluştur»: solda karakterin döner 3B önizlemesi (sürükleyerek döner, tekerlek ya da Tab yakın plan), sağda parşömen. Satırlar: Vücut tipi (Tip 1 Mete, Tip 2 kadın kahraman), Ten (Doğal ve dokuz ton), Saç modeli, Saç rengi (Doğal ve on renk), Sakal, Bıyık, Gözler (Meshy modelinde «Modelde çizili»), Göz rengi (Doğal ve sekiz renk). Esc Geri Al, E Onayla; ↑ / ↓ satır, ← / → değer.

![Godot'nun bugünkü oluşturucusu: solda Mete'nin modeli, sağda parşömen üstünde satırlar.](/media/docs/research/menu-shots/creator_full.jpg)

**Tasarım: «Yola Hazırlan» ([K36](/docs/source/design/decisions#k36)).** Oluşturucu Köprü 1'den sonra açılır; Mete 20 yaşındadır, adı sabittir ([K16](/docs/source/design/decisions#k16)). Görünüş, köken, zorluk ve pelerin boyası seçilir; önizleme Kışlak Kaftanı'nı ve Kışlak Pelerini'ni gösterir ([Yol Haritası](/roadmap#item-creator-prepare)).
- **Köken** ([progression.md §2](/docs/source/design/progression#2-statlar)), değişmez: Zırhlı Atlılar Arasında (Bilek +1), Otağda Yetişen (Söz +1), Yılkı Beyi (Ayak +1, Bağ +10) ([K104](/docs/source/design/decisions#k104)).
- **Boya** ([K58](/docs/source/design/decisions#k58), [K101](/docs/source/design/decisions#k101)): Göl Mavisi `#216e94` (varsayılan), Gök `#3a78a8`, Çivit `#34508a`, Koyu Çivit `#2b3f66`, Menekşe `#5f4a96`; kumaş örnekleriyle seçilir.
- **Müzik.** Oluşturucunun altında yumuşak kaval ve kopuz çalar (52, D Dorian).

**Portre.** Kişinin portresi art'tan türeyen profilidir ([K85](/docs/source/design/decisions#k85)); kişinin eski portresi yalnız yüz referansıdır. Yoldaş Kartı'nın portresi profilden kesilir; adı bilinmeyen firari portresiz keçe siluettir.

![Mete'nin profili: art'tan türetildi.](/media/docs/assets/encyclopedia/mete/portrait.webp)

> [!DURUM]
> **Oyunda:** açılış sözü; ana menü (logo, düğüm düğmeleri, Son Kayıt kartı, Serbest Gez); Yeni Oyun'da Önsöz (altyazı, tarih kartı, atlama halkası); karakter oluşturucu (sekiz satır, döner 3B önizleme); kayıt (1 otomatik ve 10 elle yuva, küçük resim, bozuk kayıt boş sayılır); kitap: Ayarlar (Oyun, Dil, Görüntü, Ses), Tuşlar (liste, klavye, oyun kolu), Destan Kitabı (Destan, Gök ve Yer, Kişiler, Taşlar; ansiklopedi düzeni ve tanıtım sesi), duraklatmanın Genel sayfası; sol altta ipucu paneli. Arayüz yalnız Türkçe.
>
> **Yok:** «Yola Hazırlan» akışı, köken ve pelerin boyası, Heybe, Defter, Görevler, Terazi, aktarma paneli, diyalog, Can ve Stamina, 1–6 çubuğu, Gök Kavisi, hava simgesi, tehdit okları, parti şeridi ve Yoldaş Kartı, ekran kenarı göstergesi, tuş atama, İngilizce arayüz.
>
> **Prototipte denendi:** ilk açılışta dil seçimi, kitabın altı sekmesi TR ve EN, HUD'un ilk parçaları ve inşaat göstergesi. Godot'ya taşınmadı.

```ilerleme
act-1-p3
```

## Kaynaklar

- [d3/oyun-durumu.md](/docs/source/design/d3/game-state): Godot'daki oyunun bugünkü hâli; [game/README.md](/docs/source/game/readme): Godot'nun menüsü ve kitabı
- [godot.md §3.8](/docs/source/design/godot#3-8-destan-kitabi-ansiklopedi-duzeni-k85-k86): Destan Kitabı'nın ansiklopedi düzeni; [§5.4](/docs/source/design/godot#5-4-kadraj-disi-tehdit-ve-yoldas-gostergesi-17-k73): tehdit oku ve yoldaş göstergesi; [§5.6](/docs/source/design/godot#5-6-ayarlar-ve-tus-atamasinin-kaydi-18): ayarlar ve tuş ataması
- `companions.md` §7: Yoldaş Kartı, parti şeridi, ekran kenarı, ayarlar, Defter
- [progression.md §14.1](/docs/source/design/progression#14-1-ekran): Defter ve ekran metinleri
- [economy.md §4.2](/docs/source/design/economy#4-2-yuva-ve-sekmeler): Heybe; [§9.2](/docs/source/design/economy#9-2-terazi-balance): Terazi
- [settlement.md §14](/docs/source/design/settlement#14-arayuz): Plan Kipi, Yerleşim Defteri, HUD
- [time.md §11](/docs/source/design/time#11-arayuz-ve-metinler): Gök Kavisi, tarih ve kayıt kartı; [weather.md §11](/docs/source/design/weather#11-arayuz): hava simgesi
- [decisions.md](/docs/source/design/decisions): [K16](/docs/source/design/decisions#k16), [K20](/docs/source/design/decisions#k20), [K27](/docs/source/design/decisions#k27), [K32](/docs/source/design/decisions#k32), [K34](/docs/source/design/decisions#k34), [K36](/docs/source/design/decisions#k36), [K39](/docs/source/design/decisions#k39), [K58](/docs/source/design/decisions#k58), [K61](/docs/source/design/decisions#k61), [K62](/docs/source/design/decisions#k62), [K68](/docs/source/design/decisions#k68), [K70](/docs/source/design/decisions#k70), [K73](/docs/source/design/decisions#k73), [K82](/docs/source/design/decisions#k82), [K85](/docs/source/design/decisions#k85), [K86](/docs/source/design/decisions#k86)
- [menu-spec.md](/docs/source/research/menu-spec): Godot menüsünün ölçüleri
- İlgili: [Ansiklopedi](/encyclopedia), [Yoldaşlar](/docs/gameplay/companions), [Kamera ve Kontroller](/docs/gameplay/camera-controls), [Envanter ve Yük](/docs/economy/inventory-load), [Para ve Satıcılar](/docs/economy/money-traders), [Plan Kipi](/docs/settlement/plan-mode), [Görsel Dil](/docs/presentation/visual-language), [Seslendirme](/docs/presentation/voice-over)
