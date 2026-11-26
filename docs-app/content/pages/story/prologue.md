---
title: 'Önsöz: Kopuz Söyler'
order: 20
status: tasarim
summary: 'Yeni Oyun''da kamera kamptan 1,52 kat geri çekilir, ozan kopuzla iki dize söyler; sessizlikten sonra karada sözü sürer: kişi yükselmek istedi, ölüm oldu, doymadı, insan ocağı yaktı, sayım sürüyor. Parşömen videosunun ardından ayrı bir sahne Mete''nin 27 Eylül MÖ 234 şafağındaki doğumunu gösterir. Tamamen sinemadır, 4 dk 18 sn; çekimler uzak ve yüksektir; Esc her an atlar, ikinci oyunda varsayılan atlanır, sonra Çocukluk başlar.'
sources:
  - docs/design/story.md
  - docs/design/act0-text.md
  - docs/design/decisions.md
  - docs/design/audio.md
  - docs/design/godot.md
  - docs/design/act1.md
  - docs/research/mitoloji.md
  - docs/research/kopuz.md
  - docs/design/d3/register.md
  - docs/design/d3/oyun-durumu.md
---

## Özet

Önsöz «Kopuz Söyler / The Kopuz Sings» oyunun ilk bölümüdür ve tamamen sinemadır: oyuncunun denetimi yoktur, Esc her an atlar, ikinci oyunda varsayılan atlanır (ayar oyunun ayarlarında durur, kayıtta değil). Üç sahnedir: **kamp ve şarkı**, **mit sineması**, **doğum**; son 10 sn Çocukluk'a geçiştir. Süre 4 dk 18 sn, hedef 4 dk 19 sn ± 15 sn ([K36](/docs/source/design/decisions#k36), [K68](/docs/source/design/decisions#k68)). Önsöz bitince Yeni Oyun Çocukluk'la sürer ([K99](/docs/source/design/decisions#k99)). Oyun içi çekimler uzaktan ve yukarıdandır, Diablo gibi; yakın plan yoktur ([K98](/docs/source/design/decisions#k98)).

Çerçeve 10 Nisan MÖ 209 gecesidir: Göl Obası'nın ateşi, yani ana kamp ([K37](/docs/source/design/decisions#k37), [K106](/docs/source/design/decisions#k106)). Kampta herkes rehinenin Yüeçilerde öldüğünü duymuştur; ozan ölü sanılan bir oğlun doğumunu söyler. Ertesi gün o oğul Tanhu Kampı'na döner: I. Perde'nin son görevi Ev, 11 Nisan; obaya gelmez. Önsöz saat okumaz; kampın ışığı Godot menüsünün gece ışığıdır, gökte ilk yıldızlar vardır, ay yoktur: gece yarısından sonra doğar, %43 ([K67](/docs/source/design/decisions#k67), [K76](/docs/source/design/decisions#k76)).

> [!NOT]
> «Ilk basta Ozan sazını çaldığında mitolojik bir hikaye anlatacak burası tamamen sinematik olacak, erlik ve diğer tanrılar hakkında ve sonra Metenin doğumuna gelecek anlatı»

> [!NOT]
> «Bebekliğinden başlayacak hikayeleştirmeye»

> [!NOT]
> «ve sunuda unutma gorev cekımlerı etc yakın cekım olmayacak uzak cekım olacak dıablo gıbı ornek resım ekledım sahnelerı buna gore duzenle ana menudeki sahnede dahil sinematografik oyun içi sahneler de dahil»

> [!NOT]
> «yeni oyun dedigimizde kamera ozana zoom yapmayacak hafif uzaklasacak belki 2-3 kat ve kamp gokyuzu daglar ayni akrede gozukecek ve o zaman ozanimizin kopuz sesi duyulacak ve soyleyeceklerini soyleyecek sonra biraz sessizlik olup ekran kararacak ve mitolojik sinematografik sahne acilacak ve anlatici ses mitolojik bir hikayeyi anlatacak ve sonra sinda baska bir sahneye metenin dogumuna baglanacak»

Bu notlar birlikte geçerlidir (K68, K98): Önsöz üç sahnedir, hikâye bebeklikten başlar, ardından Çocukluk gelir; sıra yukarıdaki sıradır. Menü karesi ve doğum da uzak ve yüksek kadrajdan çekilir; ufku isteyen geniş kare ve ay karesi bunun istisnasıdır, uzaklığı en az 40 m'dir. Parşömen videosu bu kuralın dışındadır. Mitin sözü ozanındır, tarihi anlatıcı okur ([K35](/docs/source/design/decisions#k35), [K96](/docs/source/design/decisions#k96)): ozan şarkıyı söyler, karada sözü sürdürür; doğumun tarih satırında anlatıcı devralır.

## Açılışın sırası

Saniyeler Yeni Oyun'a basıştan sayılır ([act0-text.md, Açılış sırası](/docs/source/design/act0-text#acilis-sirasi-k68)).

| # | Sahne | Saniye | Ne olur | Ses |
|---|---|---|---|---|
| 1 | Geri çekilme | 0:00,0–0:06,0 | Menü yazıları 0,5 sn'de söner. Kamera ozana yaklaşmaz, menü kadrajından geri çekilir; kamp, gök ve dağlar aynı karede görünür. 0:04,2'de ozan kopuzu kaldırır | Menü müziği 2 sn'de ozanın dronuna iner; ateş, rüzgâr |
| 2 | Şarkı | 0:06,0–0:32,9 | Kamera durur, hafifçe nefes alır (0,06 m). Ateş başında Ozan, Ana, Baba, Ağabey ve Çocuk; Çocuk ozana döner. Ozan kopuzla iki dizeyi söyler | Şarkı, çekim 3104, 26,85 sn; son vuruşu avuç susturur |
| 3 | Sessizlik ve kararma | 0:32,9–0:38,9 | Ozan avucunu tellerde tutar, kimse kıpırdamaz, duman yükselir (3 sn); ekran 2 sn'de kararır, 1 sn kara kalır | Müzik yok, rüzgâr −40 dB, ateş; rüzgâr kara ekranda da sürer |
| 4 | Mit sineması | 0:38,9–3:22,4 | Ozanın ilk sözü karada; perde 0:41,8'de açılır (parşömen videosu; dosya yoksa keçe panolar): su ve iki kara kaz, düşüş ve taş, boğazdaki toprak, adın alınışı ve Erlik, dokuz dallı ağaç ve dokuz kişi, sözsüz gök çadırı ve Demirkazık, ilk ölü ve sekiz, ırmak, ilk ateş, taşta duran Erlik, doğum yurdu | Ozan, satır 3–25; kopuz satır aralarında ≥1,5 sn cevap verir, en önemli sekiz boşlukta vermez; tek koro gök panosundadır |
| 5 | Doğum | 3:22,4–4:07,9 | Ayrı sahne: videonun közü gerçek köze döner. Ordos, 27 Eylül MÖ 234 şafağı, 3B. Teoman doğan güne eğilir; ilk ağlama; Hereka: «Bir eklendi.»; kart «27 Eylül MÖ 234 · Ordos» | Anlatıcı, doğumun satırı: tarih burada ozandan anlatıcıya geçer; Önsöz'ün tek kara sessizliği (2,5 sn); motifin bütünü ilk kez kopuzla |
| 6 | Geçiş | 4:07,9–4:17,9 | Beşiğin yayı parşömene döner, koyuna binen çocuk belirir; Çocukluk başlar | Çocukluk müziği: majör pentatonik, kopuz hızlanır |

![Godot'da menü karesinin referansı (K98, 2026-11-07): geri çekilme bu uzak ve yüksek kadrajdan başlar. Ateş başında Ana, Çocuk, Baba, Ağabey ve elinde kopuzuyla ozan oturur (K37, K60)](/media/game/tests/refs/menu.png)

## Kamera planı

Ölçü menü kamerasıdır, çünkü Yeni Oyun'da ekrandaki kamera odur: eğimi ve görüş açısı takip kamerasınınkiyle aynıdır (38°, 36°; [K98](/docs/source/design/decisions#k98)), ateşe uzaklığı 26,4 m'dir. Kamera 6 sn'de, yumuşak giriş ve çıkışla geri çekilir; yön kuzey kalır, görüş açısı 36°'den geniş karenin 41,76°'sine açılır ([godot.md §3.6](/docs/source/design/godot#3-6-onsoz-sinemasi-k68)).

| An | Ateşe | Eğim | Karede |
|---|---|---|---|
| Menü kadrajı, 0 sn | 26,4 m | 38° | Ufuk yok; ateş yukarıdan %60'ta, soldan %58'de |
| Yolun ortası, 3 sn | 32,7 m | 23,5° | Ufuk henüz yok (4 sn'de %10'da); ateş %66'da |
| Geniş kare, 6 sn | 40,0 m (1,52 kat) | 9° | Zirveler yukarıdan %10'a dek, ufuk %29'da, vadi ve göl ortada, ateş %80'de |

- 40 m takip kamerasının en uzak yakınlaştırmasıdır (varsayılanı 28 m). Dağ halkasının zirveleri ufkun ≈8° üstüne çıkar, üstte gök kalır.
- Geniş kare K98'in ufuk istisnasıdır: onayladığın gibi kaldı ([K95](/docs/source/design/decisions#k95)). Menü kadrajı K98 ile uzaklaştığı için geri çekilme 2,47 kattan 1,52 kata indi; kamera yine ozana hiç yaklaşmaz.
- Gök kubbesi ilk kez görünür: yıldız katmanı 4,0–6,0 sn arasında %35'e açılır, ay çizilmez. Dağlar sisle seçilmezse sis yalnız bu sahnede azalır.
- Yüz yakın planı yoktur (K68; K98 bunu bütün oyun içi çekimlere genişletti): yakın plan Meshy yüzünü konuşturmak zorundaydı. Şarkı geniş planda söylenir, ağız eşlemesi yoktur.

![Uzak ve yüksek menü karesi (K98, 2026-11-07)](/media/docs/media/review/uzak_menu.jpg)

Geniş kare kamp bütçesini tutar (2026-11-07: 14,67 ms, hedef 16,7, sınır 33), kamera yolu çam tacına ve kayaya ≥1,6 m pay bırakır; kareyi onayladın ([Yol Haritası](/roadmap#item-prologue-pullback)).

## Ozanın şarkısı

**Çalgı.** Ozanın çalgısı kopuzdur: üç telli, perdesiz, parmakla çalınan, gövdesinin bir bölümü deri, bağırsak telli uzun saplı lavta ([K60](/docs/source/design/decisions#k60)). Kural: Batı akoru yok, üçlü basılmaz; tırnakla aşağı, parmak ucuyla yukarı vuruş, sıyırma ve tek tele fiske serbesttir; mızrap ve akor tıngırtısı yoktur; ezgi bir telde, öteki teller açık dron, aynı anda en çok üç tel. Görüntüde üç tel ve deri göğüs görünür, ozanın kolu kaydın vuruş ızgarasına uyar (1,25 tur/sn, söylerken yavaşlamaz). Dombra, komuz, topşur ve saz oyunda geçmez; yaylı çalgı kıl kobuzdur ([K34](/docs/source/design/decisions#k34)).

**Şarkı.** ElevenLabs Eleven Music söyler ve çalar: yaşlı ozan sesi ve kopuz tek dosyadır. 6/8, noktalı dörtlük 52, D Dorian (doğal F ve C), her sekizlikte vuruş, gırtlaktan hece başına bir nota. Plan 27,7 sn'dir: 2 ölçü kopuz girişi, her dize 4 ölçü ve ardından kopuzun cevabı, 2 ölçü çıkış; A G F D motifi iki dizenin son üç ölçüsündedir. Çekim 3104 26,85 sn'dir. Şarkı 2B'dir, ozanın yönüne en çok %10 kaydırılır; altyazı sözcük zamanlarından çıkar, kol kaydın vuruş ızgarasına uyar. Şarkı iki dizedir, dörtlük değildir: Destan Kitabı'nın ve perde kartının dörtlüğü okunan metindir.

![Ozanın kopuzlu şarkısı, çekim 3104, 26,85 sn](/media/docs/media/audio/vo/en/act0.bard.song.mp3)

| Dize | EN (söylenen) | TR (altyazı) | Saniye |
|---|---|---|---|
| 1 | One more was counted the dawn that the full moon fell, | Dolunay batarken sayıma bir eklendi, | 0:09,9–0:14,7 |
| 2 | and the steppe learned his name from the sound of a bell. | bozkır adını çanın sesinden öğrendi. | 0:19,5–0:24,3 |

1. dize 2026-11-04'te değişti: eski «foal» (kulun) imgesi Tanhu 1'in ninnisine yakındı.

**Ölçütler ([K75](/docs/source/design/decisions#k75)).** Batı akoru yasağı ölçülebildiği yerde ölçülür. Sınır (uymayan çekim seçilmez): 23 sözcük sırayla, ses girişi 3–6 sn, dize arası ≤6 sn, boy 22–32 sn ve sözsüz bölümlerde eş zamanlı perde ≤3. Sayılan ölçüler: vuruş/sn ≥2,0, 1,28 kHz üstü enerji ≥%8, 2–6 kHz sönümü ≥4 dB / 100 ms, söz ile çalgı düzey farkı ≤12 dB. Bilgi: iki dizenin son üç ölçüsünde A→G→F→D; söz kipi (F / (F + F♯) ≥0,7) denetimi geçene dek bilgidir. Sözlü bölüm önce yerelde, kredisiz bir ses ayırma modeliyle (ör. Demucs) ses izine ayrılır, perde orada ölçülür. Çekim 3104'ün ölçüleri: saniyede 2,12 vuruş, 1,28 kHz üstü %9,7, sönüm 7,8 dB / 0,1 sn, düzey farkı 6,2 dB, eş zamanlı perde 2,39; kip ölçülemedi, motif bulunamadı. Vuruş ızgarası 0,399 sn'dir, vuruşların %73'ü oturur; kol ona uyar.

K75'in ölçüsü ve denetimi (kipi bilinen 3101 ve 3103 kodla kopuzla karıştırılır) dört çekimde, 3104–3107'de kredisiz koşuldu: dördü de eş zamanlı perde sınırını geçti ([Yol Haritası](/roadmap#item-song-measure)). Son onay kulaktadır: kullanıcı dinleyip çekim 3104'ü seçti ([K95](/docs/source/design/decisions#k95)).

```varlik
kopuz, elder
music_bard_song, music_camp_bard
```

## Sessizlik ve kararma

Şarkının son vuruşunu ozanın avucu susturur. 0:32,9–0:35,9 arasında kampta kimse kıpırdamaz, duman yükselir; müzik yoktur, rüzgâr −40 dB'e iner, ateş çıtırdar. 0:35,9–0:38,9 arasında ekran 2 sn'de kararır, 1 sn kara kalır. Rüzgâr kara ekranda da sürer: bu bir kara sessizlik değildir. Kara ekranda kamp dünyası bırakılır; doğumun dünyası mit sineması sürerken arka planda yüklenir.

## Mit sineması

Görüntü karadan açılan parşömen videosudur ([K93](/docs/source/design/decisions#k93)): `motion-studio`'da işlenen koyu sepya çizim, oyuna sessiz Ogg Theora girer, sinema saatini izler; boyalı süzgecin üstünde oynar, altyazı alttaki koyu bantta durur. Dosya yoksa kodla keçe panolar yedektir (boyalı süzgeç açık). Ateş dumanından çıkış kalktı (K68). 3–25. satırları ozan okur (David, `eleven_v3`, kararlılık 0,5; tek okumadan kesildi, [K96](/docs/source/design/decisions#k96)). 3. satır karadadır, altında ateşin çıtırtısı vardır; perde ondan sonra açılır. Kopuz müzik olarak satır aralarında en az 1,5 sn cevap verir; 3, 10, 11, 17, 18, 20, 23 ve 25'ten sonra vermez. Sinemanın tek korosu gök panosundadır. Ozanın sesine ses zinciri uygulanmaz: «Erlik.» sözünü rüzgârın kesilmesi ve sessizlik taşır.

| Pano | Süre | Görüntü | Satır | Kaynak ve rozet | Ses |
|---|---|---|---|---|---|
| 1 | 0:38,9–0:58,2 | Söz karada, perde 0:41,8'de açılır; boş deri, «water»da su, «two black geese»te iki kara kaz | 3, 4, 5 | Radloff, Holmberg «Ozan der»; 3. satır «Bizim» | Dron, seyrek tel; su; uzakta kaz |
| 2 | 0:58,2–1:08,0 | Kişi öteki kazın üstüne çıkar, düşer; sudan taş çıkar, üstüne konar | 6 | Radloff «Ozan der»; taş Holmberg s. 317 | Tek kısık tel |
| 3 | 1:08,0–2:00,5 | Dalış, iki avuç; boğaz yakın planı, arkada yer büyür, boğaz şişer, tükürür; bataklık, açık gagalı kaz; adı alınır, yüzü olmayan karanlık biçim ışıktan iner, yüzsüz başa yaklaşılır; dokuz dallı ağaç, dokuz kişi | 7–13 | Radloff, Holmberg, Anohin «Ozan der»; Kül Tigin «Taştan»; 8, 10, 12, 13'te «Bizim» | Tel susar, «Erlik.» sözüyle rüzgâr kesilir; sonra Erlik müziği: kargıra, E Frigyen |
| 4 | 2:00,5–2:14,2 | Sözsüz: gök çadır gibi gerilir; tündükte dönmeyen nokta, çevresinde Kök Boz At ve Ak Boz At; Yedi Karakçı; altta yer, arada dokuz kişi | 14, 15 | Kül Tigin «Taştan»; görüntü Kaşgarlı ve iki at «Ozan der»; 15 «Bizim» | Tengri müziği: tek koro |
| 5 | 2:14,2–2:53,0 | Yer kesiti: otun altından el uzanır, biri toprağa çekilir; sabah sekiz kişi, sekiz çentik; ırmak ve at kılından köprü; boş deri; ak taş kara taşa çarpar, kıvılcım, üç ocak taşı | 16–21 | Radloff, Anohin, Holmberg «Ozan der»; 17, 18 «Bizim» | Sekiz çentik, 3 sn sessizlik; kıvılcımdan önce 1,5 sn alçak sessizlik |
| 6 | 2:53,0–3:22,4 | Gece, ocak, sekiz kişi; yüzsüz biçim taşta durur, ışığın dışına oturur, sekiz çizik; doğum yurdu, eşikten giren gölge ocak taşında durur; son 1,5 sn'de çizili köz gerçek köze döner | 22–25 | Holmberg, Polat (motif Al Karısı'ndan aktarıldı); SJ 110 «Yıllıktan»; 23, 25 «Bizim» | Uzak çentikler, nefes, köz; ninni yok |

Rozetler çağ etiketleridir: «Yıllıktan» Hun çağı Çin yıllıkları, «Taştan» Göktürk ve Uygur tanıkları, «Ozan der» geç derlemeler, «Bizim» oyunun seçimi. Rozet ekrana yazılmaz, Destan Kitabı'ndadır. Satır satır kaynak ve «Bizim» işaretleri [act0-text.md](/docs/source/design/act0-text#mit-sinemasi-ve-dogum)'dedir. Söylenen adlar iki tanedir: Kişi ve [Erlik](/encyclopedia/erlik). [Kayra Han](/encyclopedia/kayra-han) «Gök» diye anılır; Toybodım'ın adı anlamıyla söylenir; [Al Karısı](/encyclopedia/al-karisi), [Umay](/encyclopedia/umay) ve [Yer-Sub](/encyclopedia/yer-sub) söylenmez, Destan Kitabı'nda kalır.

```varlik
fx_panel_water_geese, fx_panel_stone, fx_panel_erlik_tree
fx_panel_sky_tent, fx_panel_first_dead, fx_panel_birth_yurt
music_myth, music_erlik, music_tengri
```

## Doğum

Ayrı sahnedir, 3:22,4–4:07,9 (45,5 sn). Mit parşömende, tarih dünyadadır: videonun közü 1,5 sn'lik çakışmayla Lan Hatun'un ocağındaki gerçek köze döner, sahne Çocukluk'un dünyasında 3B oynar. Yer aynıdır: Ordos, Sarı Irmak kıvrımının içinde Teoman'ın güz otlağı, Dailin'in toplandığı yer; bu yüzden yeni dünya kurulmaz, Çocukluk'a geçişte yükleme yoktur. Lan Hatun'un yurdunun kapısı doğuya bakar. Çekimler uzak ve yukarıdandır ([K98](/docs/source/design/decisions#k98)): kamera kişiye en az 12 m'dir, ay karesi dışında eğim en az 30°'dir, yurdun içinde çatı kalkar. Işık saatten değil sabit örnekten gelir: içeride 05:50, dışarıda 06:03 (39°K); 8. ayın dolunayı o gece 02:24'tedir, şafakta güneş doğuda, dolunay batıda ufuktadır.

Kim var: [Lan Hatun](/encyclopedia/lan-hatun) (≈18), ebe [Hereka](/encyclopedia/hereka) (39; yıllar sonra Yüeçilere tutsak düşer, I. Perde'de Çukur'un ebesidir), Lan soyundan iki kadın. [Teoman](/encyclopedia/teoman) (≈28) dışarıdadır. Sayım hattında [sayıcı](/encyclopedia/counter) ve boyların atlıları vardır.

| # | Süre | Görüntü | Ses |
|---|---|---|---|
| 7a | 3:22,4–3:32,4 | Yurdun içi, çatısız, diorama gibi yukarıdan (16 m'den 18,5 m'ye tek yavaş çekim): köz ışığı, Lan Hatun döşekte, kolu keregede; Hereka ve iki kadın. Parşömende söylenen burada olur: kapıdan giren gölge tabanda okunur, ucu ocak taşında durur | Köz, keçe, nefes; dron alçak |
| 7b | 3:32,4–3:46,8 | Dışarıda şafak, uzak kare: Teoman otağından çıkar, doğan güne eğilir, uzun gölgesi batıya düşer. Satırın ikinci yarısında ay karesi: Teoman'ın ≈44 m doğusundan, alçaktan batıdaki dolunaya bakılır. Doğumun satırı | Satırın ardından tek uzun nota, 5 sn'de söner |
| 7c | 3:46,8–3:49,3 | Lan yurdu ve sayım hattı aynı uzak karede (≈40 m); kımıltı yok, kamera durur | Önsöz'ün tek kara sessizliği: 2,5 sn, −60 dB rüzgâr kuyruğu |
| 7d | 3:49,3–3:59,9 | Aynı kare, kamera yavaşça kayar. İlk ağlama. Hereka kapıdan sayım hattına seslenir: «Bir eklendi.» Sayıcı çubuğa çentik atar. Kart: «27 Eylül MÖ 234 · Ordos» | Ağlama; çentik; uzakta turnalar; motifin bütünü kopuzla |
| 7e | 3:59,9–4:07,9 | Hereka eşi yurdun yanında toprağa gömer (25 m); kesmeyle beşiğin başında diz çöküp küçük ok-yayı asar (26 m); turnaların V'si kadrajın içinden güneye geçer | Keçe, rüzgâr, uzak turna |

![Doğumun uzak ve yüksek kareleri (K98, 2026-11-07): 7a'nın çatısız yurdu, 7b'nin güneş ve ay kareleri, 7c–7d'nin sayım hattı, 7e'nin gömü ve beşik kareleri, Çocukluk'a geçiş](/media/docs/media/review/uzak_dogum_v2.jpg)

- **İşaret.** Gök iki ışığını birden tutar: doğuda doğan gün, batıda batmayan dolunay. Tanhu sabah güne, akşam aya eğilir (SJ 110 單于朝出營，拜日之始生，夕拜月); bu şafak ikisi aynı göktedir. Dailin'in günüdür: at semizdir, insan ve hayvan sayılır.
- **Ad konmaz.** Ad ilk kez anlatıcının köprüsünde, N2'de («When Mete was eighteen») duyulur. Umay görünmez ve konuşmaz; kurt, görü, ayna, ip, aynı gece doğan tay, ninni, kehanet ve ad koyma yoktur.
- **Kayıt.** Önsöz bayrak yazmaz, seçim sunmaz. Destan Kitabı «Doğum» girdisini açar (rozet «Yıllıktan» ve «Bizim»).

Doğrulanacak: doğum ağlaması önce kodla basılır ve kulakla sınanır; inandırıcı olmazsa ElevenLabs'in efekt ucundan tek çekim alınır, kredisi önce sorulur ([Yol Haritası](/roadmap#item-birth-scene)).

```varlik
cradle, cradle_bow, swaddled_baby, fx_al_karisi_shadow
hereka_young, lan_hatun, teoman, counter, vo_hereka_birth
```

## Geçiş

4:07,9–4:17,9: kamera beşiğin uzak karesinde durur, yakınlaşmaz; beşiğin yayı parşömene döner (dosya yoksa keçe pano), koyuna binen çocuk belirir ve oyuncu beş yaşındaki Mete'yle denetimi alır: [Çocukluk: Koyun Sırtında](/docs/story/childhood). Dünya aynıdır, yükleme yoktur. Çocukluk 20 Eylül MÖ 228 sabahı Lan Hatun'un yurdunda «Çobanlık»la açılır, sayım günü üçüncü gündür ([K110](/docs/source/design/decisions#k110)); geçişin son 10 sn'si bugünküdür. Anlatıcının yedi köprü satırı (N1–N7) Çocukluk'tan ve Yola Çıkış'tan sonra gelir; ikisi de o sayfadadır. Yeni Oyun'dan I. Perde'ye ilk oyunda ≈12 dk geçer, oluşturucu hariç.

## Satırlar

Söylenen dil İngilizcedir, Türkçe altyazıdır ([K61](/docs/source/design/decisions#k61)). 1–2 ozanın şarkısıdır. 3–25 mit sinemasında ozanın sözüdür (David), doğumun satırı (D) anlatıcınındır (Eldrin): mit ozanın, tarih anlatıcının ağzındadır ([K96](/docs/source/design/decisions#k96)). Başlama anları şarkıda çekimin sözcük zamanı, öbürlerinde okunan dosyanın gerçek süresidir; zaman çizelgesi satırın süresine bağlıdır, satır uzarsa sonraki işaretler aynı payla kayar.

| # | Kim | Başlar | TR (altyazı) | EN (söylenen) |
|---|---|---|---|---|
| 1 | Ozan | 0:09,9 | Dolunay batarken sayıma bir eklendi, | One more was counted the dawn that the full moon fell, |
| 2 | Ozan | 0:19,5 | bozkır adını çanın sesinden öğrendi. | and the steppe learned his name from the sound of a bell. |
| 3 | Ozan | 0:39,4 | Bizi kimin saydığını hiç sormadın. | You never asked who counts us. |
| 4 | Ozan | 0:43,3 | Sayılacak kimse yokken su vardı, bir de iki kara kaz. | Before there was anyone to count, there was water, and two black geese. |
| 5 | Ozan | 0:50,6 | Biri Gök'tü. Ötekini kendi yapmış, adını Kişi koymuştu. | One was the Sky. The other he had made, and named him Kishi. |
| 6 | Ozan | 0:58,8 | Kişi Gök'ten daha yükseğe uçmak istedi, düştü, Gök ona acıdı. | Kishi wanted to fly higher than the Sky, and he fell, and the Sky had mercy. |
| 7 | Ozan | 1:08,4 | Gök onu dipten toprak getirmeye yolladı. Bir avucunu verdi, bir avucunu ağzında sakladı. Kendine bir toprak istedi. | The Sky sent him for earth. One handful he gave. One he hid in his mouth. He wanted a land of his own. |
| 8 | Ozan | 1:18,5 | Dünya büyüdükçe ağzındaki toprak da büyüdü. «Tükür», dedi Gök. O gün bugündür doymadı. | The world grew, and the earth in his mouth grew with it. "Spit," said the Sky. He has not been full since. |
| 9 | Ozan | 1:30,3 | Gök adını aldı, onu ışıktan sürdü. Artık başka bir adı var. | The Sky took his name and drove him from the light. He has another now. |
| 10 | Ozan | 1:36,4 | Ateş başında o adı söylemeyiz. Bir kez söyleyeceğim. | We do not say it by the fire. I will say it once. |
| 11 | Ozan | 1:41,9 | Erlik. | Erlik. |
| 12 | Ozan | 1:46,1 | Sonra Gök başkalarını yarattı: bir ağacın altında dokuz insan. Onlara bir ad gerekti, boşta bir ad vardı. | Then the Sky made others, nine, under a tree, and they needed a name, and one was lying empty. |
| 13 | Ozan | 1:54,2 | Kişi. Sen de kişisin, ben de. | Kishi. You are kishi. I am kishi. |
| 14 | Ozan | 2:01,5 | Üstte gök, altta yer; ikisinin arasında kişi oğlu. | Sky above, earth below, and between them, the children of Kishi. |
| 15 | Ozan | 2:09,5 | Onları kimse saymazdı. Gerek yoktu. | Nobody counted them. Nobody needed to. |
| 16 | Ozan | 2:14,8 | Onları istedi. Onun adını taşıyorlardı. Gök vermedi. O da birini aldı. | He wanted them. They wore his name. The Sky said no. So he took one. |
| 17 | Ozan | 2:24,2 | Sabah biri saydı. | In the morning, somebody counted. |
| 18 | Ozan | 2:28,3 | Sekiz. | Eight. |
| 19 | Ozan | 2:31,9 | Irmağı otun altından akar, gözyaşımızla akar. Adı Doymadım. | Below the grass his river runs with our tears. Its name is: I am not full. |
| 20 | Ozan | 2:40,2 | Gök onları kendi başlarına bıraktı. | The Sky left them to themselves. |
| 21 | Ozan | 2:45,4 | Ak taş kara taşa vurdu, bir kıvılcım düştü; sekizi çevresine üç taş dizdi. | White stone struck black stone, and a spark fell, and the eight of them set three stones around it. |
| 22 | Ozan | 2:54,4 | Taşlara kadar geldi, orada durdu. | He came as far as the stones, and there he stopped. |
| 23 | Ozan | 2:59,3 | Gitmedi. Işığın dışına oturdu, bizi saymaya başladı. | He did not go away. He sat down outside the light, and began to count us. |
| 24 | Ozan | 3:06,8 | Biz de sayarız. Her doğumda bir kadın kapıya çıkıp sayıyı söyler. | So we count too. At every birth, a woman calls the count from the door. |
| 25 | Ozan | 3:14,1 | Irmak duyar. Adını değiştirmedi. | The river hears. It has not changed its name. |
| D | Anlatıcı | 3:33,4 | Şafakta Tanhu çadırından çıktı, doğan güne eğildi; batıda dolunay daha batmamıştı. | At dawn the Tanhu stepped out of his tent and bowed to the rising sun; in the west the full moon had not yet set. |
| H | Hereka | 3:51,0 | Bir eklendi. | One more. |

Mit satırları 2026-11-07'de tek okumadan kesildi ([K96](/docs/source/design/decisions#k96)), doğumun satırı ve Hereka'nın sözü daha önce okundu (2026-11-05); Hereka'nın sözü 39 yaşının sesiyle yenilendi (Heather Faith, 2026-11-07; [K95](/docs/source/design/decisions#k95)).

## Ses ve müzik

- **Kısma ([K78](/docs/source/design/decisions#k78)).** Anlatı ve sinema satırında müzik ve ortam −3 / −3 dB iner; iniş 0,3 sn sürer ve satırdan 0,15 sn önce başlar, dönüş 1,0 sn'dir; konuşma boyunca müziğin 2 kHz bandı −3 dB olur. Konuşma −18 LUFS'tır. Doğrulanacak: kısmanın son ayarı kulakla, önce Önsöz'ün satırlarıyla yapılır ([Yol Haritası](/roadmap#item-voice-bus)).
- **2B ses.** Şarkı, ozanın sözü ve anlatıcı 2B'dir, çünkü kamera ozandan 40 m uzaktadır ve konumlu ses kısılırdı; söz ortadadır, yankısı azdır. Ozanın sesine ses zinciri uygulanmaz: «Erlik.» sözünü sessizlik taşır.
- **Motif.** Yükseliş D↗A, düşüş A G F D. Doğumda bir kez bütün çalar; perdelerde parçalanır (I'de A G F, II'de yalnız yükseliş), oyunda ilk kez III'te bütünlenir.
- **Sessizlik.** İki alçak sessizlik vardır: şarkıdan sonra ≈9 sn (rüzgâr −40 dB; içinde ozanın ilk sözü karada) ve kıvılcımdan önce 1,5 sn. Tek kara sessizlik doğumdadır: 2,5 sn, her şey susar, rüzgâr kuyruğu −60 dB'te kalır ([K59](/docs/source/design/decisions#k59)). Ninni yoktur.
- **Uygulama.** Godot'da Önsöz üç sinema sahnesidir (kamp, mit, doğum) ve bir çalıştırıcı onları sırayla oynatır; ayrıntı [godot.md §3.6](/docs/source/design/godot#3-6-onsoz-sinemasi-k68)'dadır.

## Bedel ve onaylar

Konuşma karakter başına 1 kredi, şarkı dakikası 900 kredidir; tavan yoktur, harcama sayaçla izlenir (K61). Mit satırları 2026-11-07'de okundu: 1.352 karakter, üç çağrı, 715 kredi ([K96](/docs/source/design/decisions#k96)). Doğum satırı (113), köprünün üç yeni satırı (359) ve Hereka'nın sözü (9) daha önce okundu.

Kullanıcının seçimini ya da onayını bekleyenler [Karar Bekleyenler](/docs/general/pending-decisions)'dedir:

- Ozanın mit satırlarının (2026-11-07, 715 kredi), anlatıcının ve köprünün okunan satırlarının kulak onayı. Önerilen: önce Önsöz'ün içinde dinle.
- Önsöz'ün kişilerinin, kopuzun, beşiğin ve oturuşların göz onayı; modeller oyunda ([K89](/docs/source/design/decisions#k89), [K91](/docs/source/design/decisions#k91)).
- Uzak kadrajın göz onayı: menü karesi ve doğumun yeni çekimleri ([K98](/docs/source/design/decisions#k98)). Geniş kareyi ve mit videosunu onayladın ([K95](/docs/source/design/decisions#k95), [K96](/docs/source/design/decisions#k96)).
- Geniş kare K98'in istisnası olarak kaldı; yüksek açıya alınıp alınmayacağı senin seçimindir (önerim: kalsın).

## Göl Obası'nda üç gün: Süt ve Tipi

Yeni Oyun artık sinemayla değil, Göl Obası'nda oynanan üç günle açılır: 8–10 Nisan MÖ 209 ([K110](/docs/source/design/decisions#k110)). Oyuncu ozanın dinleyicisi Çocuk'tur. Her gün kara perdede kartla («8 Nisan MÖ 209 · Göl Obası») ve kayıt noktasıyla başlar: Devam Et o günün başından açar. Görevler arasında perde kararır, saat atlar; gün yatağa E ile ya da gecenin kararmasıyla biter. Esc basılı tutmak Önsöz'ün tamamını (günler ve sinema) atlar ([K100](/docs/source/design/decisions#k100)).

Kayın Obası Göl Obası'nın ≈320 m güneybatısındadır, vadi ormanının doğal açıklığında, çimenli bir düzlükte, menü kadrajının arkasında: üç yurt, sabanın ahşap çatısı ve deri saba, kurut sergisi, at bağı, güreş halkası; Künay'ın yurdunda beşik ve beşiğe asılı küçük yay. Yol obanın güney kıyısından beş kollu bir yokuşla iner (yamaç 30–45° diktir; yolun kolları ≈12°, dönemeçleri ≈25°), ormanın içinden batıya, açık vadiden derenin sığ geçidine ve obaya gider. Yolun yanında on iki keçe bayraklı kazık vardır; on ikincisi geçidin önündedir. Menü karesi değişmez: oba, yol ve kazıklar yalnız Önsöz'de kurulur.

- **Süt** (8 Nisan sabahı, vadide sis): Ana Çocuk'u uyandırır; Künay'ın vakti yakındır, kımız ona güç verir, Saruk'un sabası aç kalmıştır. İki tulum kısrak sütü omuz sırığındadır. Koşunca süt çalkalanır ve damlar; geçitte taştan taşa yavaş basılmazsa da damlar. Yolda Kayın Obası'ndan çıkan bir adam «Sırık senden büyük» der, obaya varınca kurut seren kadın Saruk'a seslenir. Dökülen pay Saruk'un sözünü seçer («Tek damla dökmemişsin.» ya da «Yarısı yolda kalmış. Olsun, yine kımız olur.»). Süt sabaya dökülür, saba yirmi kez çalkalanır: sopa inerken E, halka dolunca basılır; kaçan vuruş sayılmaz, ceza yoktur. Börü kızdan pehlivan olmayacağını söyler, Saruk toyu anar; Künay kapıda soluklandırır. Eve dönüş kararmayla kısalır: «Ellerin süt kokuyor.»
- **Tipi** (8 Nisan gecesi): rüzgâr döner, kızıllık griye çalar, tipi bastırır; Baba ile Ağabey atlara gider, ozan kapıyı bağlar. Börü yoldan koşarak gelir: ocakları sönmüş, Künay doğuruyor. Ana köz kabını verir; köz kabı Çocuk'un çevresine sıcak, küçük bir ışık verir ve sönmez ([K1](/docs/source/design/decisions#k1)). Görüş ≈25 m'dir, kazıklar tek tek belirir, amaç satırı sayar («Kazık 4/12»). Açıkta rüzgâr yana iter, kayaların ve ormanın ardı korur, karda iz kalır. Börü ardından gelir, yolda konuşur, yoldan 15 m uzaklaşınca «Kazığı göremiyorum!» der; uzakta bir kez kurt uluması duyulur, kurt görünmez ([K3](/docs/source/design/decisions#k3)). Künay'ın kara yurdunda köz ocağa konur, tezek ve çalı eklenir, ışık yurdu doldurur; yurdun içi çatısız, yukarıdandır. Ateş tutunca tipi yavaşça hafifler. Saruk ikisini kapıya çıkarır; içeriden ağlama gelir, Saruk kapıdan sayar: «Bir eklendi.» Tonga atlarla döner. Kar örtüsü kalır, 9 Nisan sabahı karlıdır.

![«Süt»: 8 Nisan sabahı aile yurdunda uyanış; yurt çatısız, Ana yatağın başında (E21, 2026-11-09)](/media/docs/media/review/e21_milk_wake.jpg)

![«Süt»: Kayın Obası'nda saba çalkalanır («5/20»); kurut sergisi, yurt, at bağı (E21, 2026-11-09)](/media/docs/media/review/e21_milk_churn.jpg)

![«Tipi»: Künay'ın kara yurdunda ocak yeniden yanar; Saruk: «Işık döndü.» (E21, 2026-11-09)](/media/docs/media/review/e21_storm_lit.jpg)

Kişiler var olan modellerin yeniden boyanmış yer tutucularıdır: Saruk Ebe yaşlı ebenin, Börü Luhun'un, Künay ve Kayın Obalı kadın Hun kadınının, Tonga Hun atlısının ağıyla. Göl Obası'nda herkes işindedir: Ana kısrakları sağar, Baba keçe onarır, Ağabey atların başındadır, ozan kapısında kopuzunu kurar; Oktar, Erka ve Dengiz obadadır (camp3 Önsöz'de kurulmaz).

## Kuzular, Şilde Gecesi, Güreş, Ocak

Göl Obası'ndaki üç günün son dört görevi 9 ve 10 Nisan MÖ 209'dur ([K110](/docs/source/design/decisions#k110)). Her istemin bir nedeni vardır ve kişiler söyler: kuzular tipide doğdu, yaşamaları ocağa bağlı; şildede ocak sönmez, gülüşme eksik olmaz; ateşi ozanın gecesi için Çocuk kurar.

- **Kuzular** (9 Nisan sabahı, kar örtüsü, yurtlardan buhar): dört kuzu obanın güney yamacında, her biri anasının yanında. Meleme ≈30 m'den duyulur, kardaki iz yurdun kapısından anaya gider. Kuzu kucağa alınır (E; kucakta koşulmaz), anası ardından gelir; kapıda Ana sayar. Dördüncüsü dere tarafındadır ve donmuştur: yurdun ocağının yanına konur, ağzına üç damla ilk süt damlatılır.
- **Şilde Gecesi** (9 Nisan gecesi, ay yok): dereden davul ve ağız kopuzu duyulur. Ana keçe kundağı verir, aile Çocuk'la Kayın Obası'na yürür. Büyük ateşin başında çalgıcılar, el çırpan kadınlar, oturan yaşlılar, kovalanan çocuklar. Saruk kımızı sunmadan önce göğe, yere ve ocağa serper; Çocuk kâseyi iki eliyle alır (E basılı). Kundak Künay'a verilir, Tonga beşiğin küçük yayını anlatır.
- **Güreş** (aynı gece): halka açılır, kalabalık izler. Kuşak güreşinde Börü iter ya da çeker, yönü gövdesinin eğilişiyle ≈0,4 sn önceden belli olur; karşı yöne basılır, denge çubuğu ortada tutulur; Börü fazla yüklenince ≈0,5 sn'lik pencerede E atar. Düşen Çocuk'a Börü «Bir daha!» der; G basılı kuşağı bırakmaktır. Kazanan kartal gibi kollarını açar.
- **Ocak** (10 Nisan ikindiden akşama): orman kıyısında iki kuru kütük baltayla üçer vuruşta kırılır, altı parça toplanır; derede büyük taş kırılır, üç taş tek tek Ağabey'in heybesine taşınır, dönüş kısa bir kararmayla kısalır. Üç taş üçgen dizilir, odun konur, ak taş kara taşa vurulur, kav 3–5 sn'de tutuşur; ateş odunla beslendikçe ışığın yarıçapı ≈2, 4, 7, 10 m olur, aile ışığa girdikçe menüdeki yerine oturur. Ateş harlanınca ozan kopuzu kaldırır, Çocuk Ana'nın yanına oturur, ateş menünün ateşine oturur ve sinema başlar.

Ceza yoktur: geç bulunan kuzu, kaybedilen ya da bırakılan güreş yalnız sözü değiştirir. Çekimler uzak ve yüksektir ([K98](/docs/source/design/decisions#k98)); güreşte kamera halkayı yandan gösterir.

## Tanhu 1'den fark

Tanhu 1'in önsözü yaz gecesinde oynanan hamile ananın yürüyüşüdür: Umay'ın altın kuşu, görü taşları, iki kurt uluması, kamın kehaneti, çatlayan ayna, aynı gece doğan tay, doğum ipi, ana duası seçimi, küçük ad. Bu önsöz oynanmaz; ozanın şarkısından sonra mit sudan başlar, güz şafağında biter. İşaret gökte zaten olandır, bir de sayım ([K32](/docs/source/design/decisions#k32)).

> [!DURUM]
> Godot'da bugün: Önsöz'ün bütünü oyunda. Yeni Oyun onu oynatır (ilk yeni oyunda; Ayarlar'da «Her yeni oyunda» seçilebilir; «görüldü» işareti içerik sürümüne bağlıdır, yeni mit bir kez daha oynar), basılı Esc atlar, ardından Çocukluk başlar; sıra Çocukluk → Köprü 1 → oluşturucu → Köprü 2 → «I. Perde: Çan, yapım aşamasında» kartı → açılış ekranıdır, kayıt yazılmaz, oluşturulan Mete kampa inmez ([K99](/docs/source/design/decisions#k99)). Kamera K98'in uzak kadrajındadır: menü karesi ateşe 26,4 m, 38°; doğumun çekimleri uzak ve yukarıdan, 7a çatısız. Akış gerçek sürelerle 4:17,9'dur: geri çekilme ve ozanın kopuzlu şarkısı (çekim 3104), mit sineması (parşömen videosu; dosyası yoksa kodla keçe panolar) ve ozanın 3–25. satırları, Ordos'ta doğum sahnesi, anlatıcının doğum satırı ve Hereka'nın sözü (39 yaşının sesi Heather Faith). Ateş başında Ana, Çocuk, Baba, Ağabey ve elinde üç telli Meshy kopuzu olan ozan oturur; doğumun kişileri kendi modelleriyle oynar, yer tutucu yalnız iki Lan kadınındadır. Keçe yedeği kodla çizilmiş şekillerdir. Kalan: kulak ve göz onayların ([Karar Bekleyenler](/docs/general/pending-decisions)). Prototipte denendi: eski ≈95 sn'lik giriş sineması (yüz yakın planı, dombra, yedi anlatıcı satırı). Sesler sitede de dinlenir: [Kadro, Sesler](/docs/story/cast#sesler).

```ilerleme
prologue
```

## Kaynaklar

- [story.md §3](/docs/source/design/story#3-onsoz-kopuz-soyler), [§4](/docs/source/design/story#4-dogum)
- [act0-text.md](/docs/source/design/act0-text): [Açılış sırası](/docs/source/design/act0-text#acilis-sirasi-k68), [Mit sineması ve doğum](/docs/source/design/act0-text#mit-sinemasi-ve-dogum), [Bedel](/docs/source/design/act0-text#bedel-k61)
- [decisions.md](/docs/source/design/decisions): [K17](/docs/source/design/decisions#k17), [K32](/docs/source/design/decisions#k32), [K34](/docs/source/design/decisions#k34), [K35](/docs/source/design/decisions#k35), [K36](/docs/source/design/decisions#k36), [K37](/docs/source/design/decisions#k37), [K59](/docs/source/design/decisions#k59), [K60](/docs/source/design/decisions#k60), [K61](/docs/source/design/decisions#k61), [K67](/docs/source/design/decisions#k67), [K68](/docs/source/design/decisions#k68), [K75](/docs/source/design/decisions#k75), [K76](/docs/source/design/decisions#k76), [K78](/docs/source/design/decisions#k78), [K96](/docs/source/design/decisions#k96)
- [audio.md §3](/docs/source/design/audio#3-muzik-durumlari), [§5](/docs/source/design/audio#5-seslendirme-elevenlabs)
- [godot.md §3.6](/docs/source/design/godot#3-6-onsoz-sinemasi-k68), [§9.3](/docs/source/design/godot#9-3-onsoz-kopuz-soyler-prologue)
- [act1.md §1](/docs/source/design/act1#1-oncul-sure-ton)
- [mitoloji.md](/docs/source/research/mythology), [kopuz.md](/docs/source/research/kopuz)
- [d3/register.md](/docs/source/design/d3/register): E4.2

İlgili sayfalar: [Çocukluk: Koyun Sırtında](/docs/story/childhood), [Mitoloji](/docs/story/mythology), [Kadro](/docs/story/cast), [Seslendirme](/docs/presentation/voice-over), [Ses ve Müzik](/docs/presentation/sound-music), [Karar Bekleyenler](/docs/general/pending-decisions).
