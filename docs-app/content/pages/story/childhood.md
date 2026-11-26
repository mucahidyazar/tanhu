---
title: 'Çocukluk: Koyun Sırtında'
order: 25
status: kismen
summary: 'Oyuncunun ilk denetimi: 22 Eylül MÖ 228''de Ordos''ta beş yaşındaki Mete koyuna biner, oyuncak yayla iki tarla kuşu ve bir fare vurur, sayıma girer (≈6 dk); ardından anlatıcının iki köprüsü, oluşturucu ve Yola Çıkış onu I. Perde''ye götürür. Bugün dört adım oynanır, köprüler ve oluşturucu Yeni Oyun''un akışına bağlıdır.'
sources:
  - docs/design/story.md
  - docs/design/act0-text.md
  - docs/design/decisions.md
  - docs/design/act1.md
  - docs/design/time.md
  - docs/design/godot.md
  - docs/design/fauna.md
  - docs/research/mete-tarih.md
  - docs/design/d3/register.md
  - docs/design/d3/oyun-durumu.md
  - game/data/story/new_game.json
  - game/data/story/childhood/scene.json
  - game/data/cine/bridge_1.json
  - game/data/cine/bridge_2.json
---

## Özet

Çocukluk «Koyun Sırtında / On a Sheep's Back» oyunun ikinci bölümü ve oyuncunun ilk denetimidir ([K36](/docs/source/design/decisions#k36)). 22 Eylül MÖ 228'de, Dailin'in günü, Mete doğduğu otlakta, Ordos'ta beş yaşındadır; beş gün sonra altı olur. Sahne ≈6 dk sürer (5–7): uyanış, koyuna binme, oyuncak yayla iki tarla kuşu ve bir fare, sayım. Ceza yoktur. Adı Shiji 110'dan gelir: Hun çocuğu koyuna biner, yayla kuş ve fare vurur (兒能騎羊，引弓射鳥鼠).

Bölümün öteki parçaları sırayla gelir: Köprü 1 (N1–N5, ≈50 sn), oluşturucu «Yola Hazırlan», Yola Çıkış (15 Aralık MÖ 213, ≈90 sn) ve Köprü 2 (N6–N7, ≈18 sn); sonra I. Perde'nin kara ekranı ve çanı. Yeni Oyun'dan I. Perde'ye ilk oyunda ≈12 dk geçer, oluşturucu hariç.

> [!NOT]
> «Bebekliğinden başlayacak hikayeleştirmeye»

Hikâye bebeklikten başlar: Önsöz doğumla biter, Çocukluk beş yaşı oynatır, köprüler aradaki yılları parşömen videosunda gösterir ([K68](/docs/source/design/decisions#k68)). Oynanan takvim burada başlar ([K67](/docs/source/design/decisions#k67)).

## Yeni Oyun'un akışı

> [!NOT]
> «suana kadar yaptıgın herseyir bir bağla yeni oyun diyince karakter oluşturma ekranına attı ve ana menüdeki sahnede mete kontrolüne geçti»

Karar [K99](/docs/source/design/decisions#k99): Yeni Oyun yapımın geldiği yere kadar gerçek sırayı oynatır. Sıra: Önsöz → Çocukluk → Köprü 1 → oluşturucu «Yola Hazırlan» → Yola Çıkış → Köprü 2 → I. Perde. Yapılmamış parça sessizce atlanır, sıra değişmez: bugün I. Perde yoktur, Köprü 2'den sonra kara ekranda «I. Perde: Çan» ve «Yapım aşamasında.» kartı çıkar, ardından açılış ekranı gelir ([K102](/docs/source/design/decisions#k102)). Oluşturulan Mete ana kampa (Göl Obası) inmez ([K37](/docs/source/design/decisions#k37)). Akış kayıt yazmaz: Çocukluk'ta duraklatma kitabının KAYDET'i kapalıdır, Ana Menü kayıt yazmadan açılış ekranına döner; oluşturucuda Geri Al da açılış ekranına döner. Takvim her parçadan sonra ileri gider: Çocukluk'ta 22 Eylül MÖ 228, Köprü 1'den sonra 15 Aralık MÖ 213, Köprü 2'den sonra 2 Aralık MÖ 210.

Önsöz'ün «görüldü» işareti içerik sürümüne bağlıdır: Önsöz büyük ölçüde değişince oyuncu yenisini bir kez daha görür (bugün mitin yeni metni, [K96](/docs/source/design/decisions#k96)).

![Akış: uyanış ve binme](/media/docs/media/review/akis_1_uyanis_binme.jpg)

![Akış: Köprü 1, oluşturucu, Köprü 2, son kart ve açılış ekranı](/media/docs/media/review/akis_4_kopru_kart.jpg)

## Gün, yer, kişiler

- **Gün.** 22 Eylül MÖ 228 (oyunun gün sayacında −5.600; sayaç rehineliğin ilk gününde 1'dir). Sahne 08:40'ta açılır, saat tek kuralla akar (2,5 sn = 1 oyun dk): ≈6 dk'lık sahne en çok ≈2 sa 24 dk oyun saati eder, bloklayan söz saati durdurur, sayım ≈11:00'de biter. Hava açık, rüzgâr 2 m/sn, ot sarı. Godot'da oyunun saati henüz yoktur: bugün sahnenin kendi saati güneşi ve göğü 08:40'tan 11:00'e sürer, ekranda saat yoktur.
- **Yer.** Ayrı küçük dünya, ≈220 × 160 m: Lan Hatun'un yurdu ve ağılı, güz çayırı, 40 m'lik yarış yolu ve taşı, sayım hattı, ufukta Sarı Irmak. Önsöz'ün doğum sahnesi de burada oynar; bu yüzden doğumdan Çocukluk'a geçişte yükleme yoktur. Bozkırın kendisi (yükselti, kaya, çalı) iki sahnede aynıdır; ağıl, sürü, av ve izler yalnız Çocukluk'ta görünür.
- **Kişiler.** [Mete](/encyclopedia/mete) (5); Lan soyunun çobanlarından [Yançi](/encyclopedia/yanchi) (5) ve [Luhun](/encyclopedia/luhun) (6); anası [Lan Hatun](/encyclopedia/lan-hatun); [sayıcı](/encyclopedia/counter); geçerken [Teoman](/encyclopedia/teoman) ve beyleri. Yançi sonra Mete'nin sevdiği eşi ve Jiyu'nun anası olur; Luhun II. Perde'de okçusu ve yoldaşıdır ([Kadro](/docs/story/cast)).

```varlik
mete_child, yanchi_child, luhun_child
sheep, toy_bow, fx_panel_sheep_child
```

## Ak Kemik ve Ebenin Çetelesi

Çocukluk üç gündür ([K110](/docs/source/design/decisions#k110)): «Çobanlık»ın akşamı «Ak Kemik», ertesi gün «Ebenin Çetelesi», sonra sayım günü. Sözler seslidir, metni [act0-text.md](/docs/source/design/act0-text) «Çocukluk'un iki yeni günü»ndedir; görevler bir oyunu ve bir ziyareti oynatır, istemlerin nedeni söylenir.

- **Çobanlık (20 Eylül, 07:20'den gün batımına, ≈7 dk).** Mete Lan Hatun'un yurdunda uyanır; Lan Hatun sürüyü göle götürmesini, akşam kırkı da geri getirmesini söyler. Kapıyı açar, kırk koyun çıkar, Yançi ve Luhun kanatlardadır; sürü ağılın ≈350 m doğusundaki Kamışlı Göl'e sürülür (Sarı Irmak'ın eski yatağı: kumlu sığ kıyı, sazlık, sazın dibinde balçık, derin orta). Yolda iki koyun sapar, önlerine geçilince sürüye döner; turnalar güneye geçer, ufukta Dailin'in dumanları görünür. Yaşlı koyuna binilebilir. Kıyıda sürü içer; Luhun «Kim yüzer? Son giren kurbağa!» der: sığda yavaş yürünür, belden derinde yüzülür, en derin yerde akıntı geri iter (Yançi seslenir). Sazlığın dibindeki ak taş dalışla (E) alınır, heybeye girer. Öğle dinlencesinde çocuklar sırtüstü uzanır, bulutlar konuşulur; bu arada saat ikindiye akar, en küçük kuzu sazlığa gider. İkindi sayımında sürü iki taşın arasından geçirilir (Yançi sayar: otuz sekiz, otuz dokuz; Luhun «Bir eksik!»). Kuzu sazın dibinde balçığa saplanmıştır, az ötede tilki bekler: yanına atılan ok ya da üstüne koşmak onu kaçırır (vurulmaz), kuzu E basılı tutularak çekilir. Güneş batı tepesine değince Yançi «Dönelim!» der; dönüşte uzaktan kurt sesi gelir, doğuda dolunay doğar, Lan Hatun kapıda koyunları sayar: «Kırk çıktı, kırk döndü.» Ak taş ona gösterilir. Aynı akşam Ak Kemik oynanır. Ceza yoktur; sürü dağılsa da gün biter.
- **Ak Kemik (20 Eylül akşamı, ≈2–2,5 dk).** Sürü ağıla girmiş: ağılda bir kadın diz çökmüş sağıyor, Lan Hatun kapısının yanında bakıyor, yurt kapılarından ocak ışığı sızıyor, ovada Dailin'e gelen boyların ateşleri yanıyor. Müzik susar; cırcır böcekleri, uzak köpek ve çocukların gülüşmesi kalır. Yançi çağırır, Mete aya bakar («Babam şimdi aya eğiliyor.»), Lan Hatun kurdu hatırlatır, Luhun bağlama direğinin önünde kuralı söyler. Üç el oynanır. Atan kemiği karanlık çayıra fırlatır: 25–45 m öteye, her elde başka yere. Kemik ay ışığında yalnız yakından ışıldar. Bulan direğe koşar, ötekiler kovalar; 1 m'ye yaklaşan kemiği kapar, yakalanan 2 sn soluklanır. Direğe varan eli kazanır ve sonraki eli o atar (Yançi kazanınca «İlk ben vardım! Ben!»): Mete kazanırsa direğin yanında `E`'yi basılı tutar, atış tuttukça uzar, kemiğin düşeceği yerde bir halka görünür. Çocuklar Mete'nin koşusunu aşmaz ([K105](/docs/source/design/decisions#k105)); kovalanan çocuk iki saniyede bir kısa duraksar, Mete onu yakalayabilir. Ceza yoktur: hep yenilse de oyun üç elde biter. Sonunda ay yükselir, Lan Hatun çağırır, yurtta yatağa `E`.
- **Ebenin Çetelesi (21 Eylül, 08:30'dan öğleye, ≈4 dk).** Lan Hatun bir torba kurut verir ve nedenini söyler: sayım öbür gün, Hereka yeni doğanları sayar, çetelesi olmazsa sayıcı obayı eksik yazar; sayım Hereka'nın obasına da duyurulmalıdır. Kuruyan dere boyunca kuzeye ≈300 m yürünür. Obaya yaklaşınca iki köpek havlar ve yolun önüne geçer: ısırmaz, değmez, ama seslenmeden obaya girilmez. Bozkırın görgüsü budur: gelen durur, `E` ile seslenir («Köpeğinizi tutun!»), ev sahibi çıkıp köpeği tutar. Mete kurutu verir: «Anam gönderdi. Teşekkür için.» Hereka onu altı güz önce kapıda kendisinin saydığını, doğduğu şafak dolunayın battığını anlatır, yurduna çağırır (kapının önünde kuruyan otlar; içerisi çatısız diorama) ve yedi çentikli çeteleyi verir. Obanın üç kişisi işindedir: kurut seren kadın, at bağlayan adam, tayının yanındaki adam. Her birine `E` ile sayım haber edilir, her biri kendi cevabını verir. Dönüşte yol kısa bir kararmayla kısalır; Lan Hatun çeteleyi görür, Hereka'yı sorar. Öğleden akşama kararmayla geçilir, uyku.
- **Sayım günü.** Mete sayıcıya varınca, «Bir çocuk.»tan önce, çetele heybedeyse sayıcı «Hereka'nın çentikleri. Yedi.» der ve çeteleyi alır. Bugünkü sıra ve sözler değişmez.

![Çobanlık: sürü göle giden yolda](/media/docs/media/review/e21_flock_path.jpg)

![Çobanlık: Kamışlı Göl'de yüzme](/media/docs/media/review/e21_flock_lake.jpg)

![Çobanlık: ak taş](/media/docs/media/review/e21_flock_stone.jpg)

![Çobanlık: öğle dinlencesi, bulutlar](/media/docs/media/review/e21_flock_noon.jpg)

![Çobanlık: balçıktaki kuzu ve tilki](/media/docs/media/review/e21_flock_lamb.jpg)

![Çobanlık: akşam dönüşü, doğuda dolunay](/media/docs/media/review/e21_flock_home.jpg)

![Ak Kemik: ay ışığında arama](/media/docs/media/review/e21_bone_search.jpg)

![Ak Kemik: direğe varış](/media/docs/media/review/e21_bone_post.jpg)

![Ebenin Çetelesi: köpekler yolu kesti, Mete seslendi, Hereka köpekleri tutmaya geliyor](/media/docs/media/review/e21_tally_keeper.jpg)

![Ebenin Çetelesi: Hereka'nın kapısı, kuruyan otlar, kurut sergisi, obanın kişileri](/media/docs/media/review/e21_tally_door.jpg)

![Ebenin Çetelesi: Hereka'nın yurdu içeriden (çatısız), yedi çentikli çetele](/media/docs/media/review/e21_tally_stick.jpg)

![Ebenin Çetelesi: sayımın haberi](/media/docs/media/review/e21_tally_news.jpg)

## Dört adım

| Adım | Süre | Ne olur | Öğrettiği | Satır (sesli; bütün sözler [act0-text.md](/docs/source/design/act0-text)) |
|---|---|---|---|---|
| 1 Uyanış | 0:00–1:00 | Lan Hatun'un yurdu. Ana çocuğu ağıla yollar; 40 m yürüyüş | Yürü, koş; kamerayı döndür ve yakınlaştır (tek ipucu) | Lan Hatun: «Kalk, bugün sayım var. Koyunları ağıldan sen çıkaracaksın.» / «Up. It's the count today, and you're letting the sheep out.» |
| 2 Binme | 1:00–2:30 | Ağılda yaşlı koyun: bin (`E`), sür, in. Koyun on saniyede bir otlamak için durur, dürtünce yürür. Luhun'la taşa dek 40 m yarış | Binme, dürtme (koşu tuşu), inme | Luhun: «Yaşlısı senin, hızlısı benim.» / «The old one's yours. The fast one's mine.» |
| 3 Nişan | 2:30–4:30 | Çayırda iki tarla kuşu ve bir fare. Koyun sırtından ya da yerden nişan al, bırak. Ok küttür, kan yoktur; vurulan düşer, çocuk alır. Yançi ilk kuşu önce vurur; Luhun fareye yayını indirir | Nişan, bırakma, toplama | Yançi: «O benim. Sayarken unutma.» / «That one's mine. Don't forget it at the count.» Luhun: «Yavrusu var.» / «She has young.» |
| 4 Sayım | 4:30–6:00 | Çocuklar sayım hattına koşar. Sayıcı koyunları geçirir, sonra çocukları sayar. Teoman atlılarıyla geçer, çocuğa dört saniye bakar, durmaz | Görev teslimi | Sayıcı: «Bir çocuk.» Mete: «İki kuş, bir fare.» Sayıcı: «Onları da sayarım. Yenen de sayılır.» Mete: «Beni gördü.» / «One child.» «Two birds, one mouse.» «I'll count those too. What is eaten is counted.» «He saw me.» |

Ceza yoktur: ıska bedavadır, 90 sn sonra Yançi hedefi gösterir. İkinci oyunda «Çocukluğu geç» sunulur. Müzik çocukluk durumudur: majör pentatonik, kopuz hızlanır; gündelik durumda konuşma sırasında müzik −6, ortam −3 dB iner ([K78](/docs/source/design/decisions#k78)).

**Kamera ([K98](/docs/source/design/decisions#k98)).** Takip kamerası çocuğu 22 m'den, 38°'lik uzak ve yüksek kareden izler; tekerlek 14–40 m arasında yakınlaştırır, yakınlaşınca eğim düşmez. Çocuk karenin ≈60–80 pikselidir; yakın plan yoktur. Sözler seslidir, Türkçesi altyazıdır ([K105](/docs/source/design/decisions#k105)). Teoman'ın dört saniyelik bakışı da uzak karedir: odak çocukla Teoman'ın ortasına kayar, kamera 26 m'ye açılır. Nişan almak kamerayı yaklaştırmaz.

![Çocukluk'un 40 m'lik kadrajı: yurt, ağıl ve sürü, yarış yolu ve taşı, sayım hattı aynı karede](/media/docs/media/review/cocukluk_kadraj_40m.jpg)

![Akış: nişan](/media/docs/media/review/akis_2_nisan.jpg)

![Akış: sayım](/media/docs/media/review/akis_3_sayim.jpg)

## Küçük seçim ve bitiş

- **Fare.** Fareyi vurmamak serbesttir: Mete sayımda «İki kuş.» der, oyun bunu bayrak olarak yazar; II. Perde'de Luhun bunu bir satırla okur. Fare kum faresidir, kuşlar tarla kuşudur ([Hayvanlar](/docs/world/animals), [fauna.md](/docs/source/design/fauna)).
- **Bitiş.** «Beni gördü.» sözüyle görüntü durur ve kararır; Köprü 1 karadan açılır. Sahne kayıt yazmaz, bitince yolculuğa işaretini yazar.
- **Teoman'ın bakışı.** Dört saniyelik bakış üç kez gelir: burada atlıyken, Yola Çıkış'ta kapalı kapı olarak, I. Perde'nin Gün IV'ünde höyükten. «Beni gördü.» birincide ve üçüncüde söylenir. Üçü de uzak kareyle oynanır (K98).

## Serbest Gez ile ilişki

İki ayrı çocuk, iki ayrı dünya vardır ([K37](/docs/source/design/decisions#k37)). Çocukluk'un çocuğu küçük Mete'dir (228, Ordos). Serbest Gez'in Çocuğu ana kampın çocuğudur: ozanın dinleyicisi, yedi yaşında bir Hun kızı (209 baharı); Mete değildir. İkisi aynı çocuk denetleyicisini, oyuncak yayı ve binme kodunu kullanır; Serbest Gez'de oluşturulan yetişkin değil Çocuk yürür, ateş başındaki yerinden ilk harekette kalkar. Fark: binek koyundur, dünya Ordos'tur. Ana kampın en çok 40 koyunu binilmez, iskeletsiz bir sürüdür; binilen iki iskeletli koyun yalnız Çocukluk'un dünyasındadır ([K65](/docs/source/design/decisions#k65)). Çocukluk'ta öğrenilen ipuçları Serbest Gez'de yinelenmez; I. Perde'nin öğretim satırları kısa ipucuyla geçer.

## Köprü 1

≈50 sn. Çocukluk karada biter, Köprü 1 karadan açılır: mit videosunun çizgisinde, önceden işlenmiş sessiz parşömen videosudur ([K93](/docs/source/design/decisions#k93)); dosya yoksa kara ekranda altyazı akar. Anlatıcı N1–N5'i okur (Eldrin, kararlılık 0,5; [K17](/docs/source/design/decisions#k17)). Satırlar arası 0,9–1 sn'dir, altta dron ve seyrek tel çalar. Takvim 22 Eylül 228'den ileri gider (K67). Babanın ihaneti gösterilmez ve söylenmez: I. Perde'de öğrenilir. Mete'nin adı ilk kez N2'de duyulur.

Çekimler: tilki ve tavşan (222, 11 yaş), gerilen yay (218, 15 yaş), Dailin'de evlilik (216), Ç'in'in suru ve Ordos'tan çekiliş (215), doğuda Tunghu, batıda Yüeçi ve arada sayan Teoman, diz çökmeyen veliaht, kuzeye göç ile Huyan Hatun ve beşikteki Gutu (214), Dailin'de Teoman ve mühür, Lung-çeng'de Jiyu'nun beşiği (213; «with a son» beşikte biter). Rehin kararı 10 Eylül 213 Dailin'inde alınır; sahnesi yoktur, N5 söyler.

![Köprü 1, izleme kopyası](/media/docs/media/review/kopru_1.mp4)

```varlik
fx_panel_bridge1_fox_hare, fx_panel_bridge1_bow, fx_panel_bridge1_wedding
fx_panel_bridge1_wall, fx_panel_bridge1_cradle, fx_panel_bridge1_jiyu
```

| # | TR (altyazı) | EN (söylenen) | Kayıt | Dinle |
|---|---|---|---|---|
| N1 | Otun imparatorlukları yokken yalnız rüzgâr vardı, bir de ona dayanabilenler. | Before there were empires of grass, there was only the wind, and those who could outlast it. | Var, değişmez | ![N1](/media/docs/media/audio/vo/en/act0.narr.1.mp3) |
| N2 | Mete on sekizindeyken Ç'in göğe karşı bir sur yükseltti, Hunları Ordos'tan sürdü. | When Mete was eighteen, the Qin raised a wall against the sky and drove the Huns out of the Ordos. | Yeni çekim (2026-11-05) | ![N2](/media/game/audio/vo/prologue/act0.narr.2.mp3) |
| N3 | Doğuda Tunghu güçleniyor, batıda Yüeçi serpiliyordu. Arada Tanhu Teoman atlarını ve yıllarını sayıyordu. | To the east, the Donghu grew strong. To the west, the Yuezhi flourished. And between them, Teoman the Tanhu counted his horses and his years. | Yeni çekim (2026-11-05) | ![N3](/media/game/audio/vo/prologue/act0.narr.3.mp3) |
| N4 | Mete adında bir veliahdı vardı; yayda çevik, diz çökmekte ağırdı. Bir de genç bir hatunu, ondan küçük bir oğlu. | He had an heir called Mete, quick with a bow and slow to kneel. And he had a young wife, with a younger son. | Var, değişmez | ![N4](/media/docs/media/audio/vo/en/act0.narr.4.mp3) |
| N5 | Tanhu, Yüeçilerle barış yaptı ve onu eski usulle mühürledi: bir oğulla. | So the Tanhu made peace with the Yuezhi, and sealed it the old way: with a son. | Var, değişmez | ![N5](/media/docs/media/audio/vo/en/act0.narr.5.mp3) |

N2, N3 ve N6 yeniden yazıldı ve 2026-11-05'te yeni metinle okundu: N2 Mete'nin yaşını ve Ordos'u söyler; N3'te yazım K34'e uydu ve 盛 «serpilmek» diye çevrildi; N6 çanı ekler. Oyundaki dosyalar yeni metinlidir; `docs/media`'daki eski kopyalar eski metni taşır: N2 «To the south, the Qin had raised a wall against the sky and driven the Huns from their pastures.», N3 «… the Yuezhi grew rich …», N6 «Mete rode west with no army and no bow, and at the gate they counted him like a head of cattle.». Yazım: Türkçede Tunghu, İngilizcede Donghu; anlatıcının İngilizcesinde «Hun» ([K34](/docs/source/design/decisions#k34)).

## Oluşturucu «Yola Hazırlan»

Köprü 1'den sonra kara perdeden açılır; panoların son yılında Mete 20 yaşındadır. Oyuncu görünüşü, kökeni, zorluğu ve pelerin boyasını seçer; önizleme rehine kılığını gösterir: Kışlak Kaftanı ve Kışlak Pelerini. Oluşturucu saat okumaz. Onay karakteri yolculuğa yazar, kayıt yazmaz, akış Köprü 2'ye geçer; Geri Al açılış ekranına döner. Bugünkü oluşturucuda vücut, ten, saç, sakal, bıyık ve göz satırları vardır; köken, zorluk ve boya satırı ve Kışlak kılığı yoktur.

**Pelerin ([K58](/docs/source/design/decisions#k58)).** Renk tek yerden gelir: eşya ve seçilen boya. Kaftan pelerini boyamaz, rehine kılığının kendi pelerin rengi kalkar. Varsayılan Göl Mavisi `#216e94`'tür ([K101](/docs/source/design/decisions#k101)); eski `#3e5f6b` en kötü ışıkta kalabalıktan yalnız ΔE 0,034 ayrılıyordu (ölçüt ≥0,05). Beş boya: Göl Mavisi `#216e94`, Gök `#3a78a8`, Çivit `#34508a`, Koyu Çivit `#2b3f66`, Menekşe `#5f4a96`; Turkuaz tanda ve akşamda kalabalıktan ayrılmadığı için çıktı. Soğuk renk bandı kalabalık giysisinde yasak, adlı kişide serbesttir; boyanmayan pelerin kendi rengindedir, savaş pelerini `#a8321f`. Giysilerin adı «Rehine Kaftanı» değil «Kışlak Kaftanı / Winter Camp Coat», «Kışlak Pelerini / Winter Camp Cape»dir: eski ad Tanhu 1'in giysisine denk düşüyordu. Hikâyede pelerin evden gelir; Kışlak onu değersiz sayıp almaz.

Doğrulanacak: altı ışık durağının en kötüsünde Göl Mavisi pelerin kalabalıktan ΔE ≥0,05, 1/8'e indirilen karede çevresinden ΔE ≥0,06 ayrılır (P1–P5); oluşturucu ile oyun aynı rengi verir ([Yol Haritası](/roadmap#item-cape-dye)).

```varlik
ui_creator, hostage_coat, cape_hostage
```

## Yola Çıkış

15 Aralık MÖ 213, şafaktan önce, ≈90 sn; Mete 21 yaşındadır. Kuzeydeki Tanhu Kampı, kış. Ayrı küçük sahnedir: Yançi'nin yurdu ve önündeki karlı avlu; ana kampa dokunmaz ([K6](/docs/source/design/decisions#k6)). Henüz yapılmadı: Yeni Oyun'un akışı bu parçayı bugün atlar.

| Adım | Ne olur | Satır |
|---|---|---|
| 1 Yurt | Jiyu (6 aylık) beşikte uyur; beşiğin üstünde Mete'nin doğumundan kalan küçük ok-yay asılıdır. Oyuncu beşiğe yürür, `E` ile kendi yayını küçüğün yanına asar: Yüeçi rehineyi silahsız ister | Yançi: «Yay burada kalır, ben gererim. Sen git, sayılmaya.» / «The bow stays here; I'll keep it strung. Go on, go and be counted.» |
| 2 Avlu | Eskam ve armağan arabası bekler. Huyan Hatun kapısında, kucağında Gutu el sallar. Teoman'ın kapısı kapalı kalır; kamera uzak karede kapıda dört saniye durur | Eskam: «Evladım, yol uzun. Ben her kış gelirim.» / «My boy, the road is long. I will come every winter.» |
| 3 At | Lan Hatun dizginleri verir. Oyuncu ata biner, sahne kararır | Lan Hatun: «Kırk iki gün yol.» / «Forty-two days of road.» |

Tanhu Kampı'ndan Kışlak'a 1.173 km'dir; kış yolu atla 28 km/gün, 42 gün tutar. Söz yankılanır: Ev'de Lan Hatun «Kırk iki gün dedim. Bin iki yüz on iki oldu.» der; I. Perde'nin elçisi yine [Eskam](/encyclopedia/eskam)'dır; II. Perde'de Yançi yayı gergin getirir: «Dört yıl gergin kaldı.»

```varlik
cradle, cradle_bow, yanchi, huyan_hatun, gutu, eskam, lan_hatun
```

## Köprü 2

≈18 sn. Parşömen videosunda N6 ve N7 okunur: kar yolu, Kemik Boğazı'nda kapı, bileğe bağlanan çan, sayıcı ve sığırların arasında rehine, yürüyen ayak ve çan. Rehineliğin 1. günü (26 Ocak MÖ 212) bu atlamanın içindedir; takvim 2 Aralık MÖ 210'a, I. Perde'nin Gün I'ine ileri gider. Kararmadan sonra I. Perde'nin kara ekranı ve çanı gelir; anlatıcı: «Üç kıştır bir sözdü. Yürüdükçe çalıyordu.» / «For three winters he had been a promise. It rang when it walked.» Kışlak bu çekimler sürerken yüklenir. Devamı: [I. Perde: Çan](/docs/story/act-1). Bugün I. Perde yoktur: Köprü 2'den sonra kara ekranda «I. Perde: Çan» ve «Yapım aşamasında.» kartı çıkar, çan bir kez çalar, açılış ekranı gelir.

![Köprü 2, izleme kopyası](/media/docs/media/review/kopru_2.mp4)

![İki köprünün kareleri](/media/docs/media/review/kopru_kareleri.jpg)

| # | TR (altyazı) | EN (söylenen) | Kayıt | Dinle |
|---|---|---|---|---|
| N6 | Mete batıya ordusuz ve yaysız gitti. Kapıda ayağına bir çan bağladılar, onu bir baş hayvan gibi saydılar. | Mete rode west with no army and no bow. At the gate they tied a bell to his ankle and counted him like a head of cattle. | Yeni çekim (2026-11-05) | ![N6](/media/game/audio/vo/prologue/act0.narr.6.mp3) |
| N7 | Tarih, sonradan olduğu Tanhu'yu yazar. Bu, önce olduğu rehinenin hikâyesi. | History remembers the Tanhu he became. This is the hostage he was. | Var, değişmez | ![N7](/media/docs/media/audio/vo/en/act0.narr.7.mp3) |

```varlik
fx_panel_bridge2_road, fx_panel_bridge2_gate, fx_panel_bridge2_bell
```

Köprülerin İngilizcesi 704 karakterdir (Köprü 1: 518, Köprü 2: 186). Yeniden çekilen üç satır 359 karakterdir (N2 98, N3 141, N6 120) ve 2026-11-05'te 158 kredi tuttu; değişmeyen dört satır yeniden çekilmez ([K61](/docs/source/design/decisions#k61)).

## Takvim

Köprüler adı konmuş atlamadır (K67): takvim 22 Eylül 228'den Yola Çıkış'a, oradan I. Perde'ye ileri gider, geri gitmez.

| Parça | Tarih (MÖ) | Gerçek süre | Oynanır mı |
|---|---|---|---|
| Çocukluk | 22 Eylül 228, 08:40–≈11:00 | ≈6 dk (sesli sözlerle otomatik oynatmada 189,9 sn, insan hızındaki botta 216,1 sn; [K102](/docs/source/design/decisions#k102), [K105](/docs/source/design/decisions#k105)) | Evet |
| Köprü 1 | 222–213 çekimleri | ≈50 sn | Hayır |
| Oluşturucu | Saat okumaz | Oyuncuya bağlı | Seçim |
| Yola Çıkış | 15 Aralık 213, şafaktan önce | ≈90 sn (otomatik oynatmada 72,0 sn, sürüş 85 m; [K105](/docs/source/design/decisions#k105)) | Evet |
| Köprü 2 | 26 Ocak 212 ve 2 Aralık 210'a dek | ≈18 sn | Hayır |

## Üretim ve onaylar

- **Dünya.** Çocukluk'un küçük dünyası: yurt, ağıl, çayır, yarış yolu ve taşı, sayım hattı, kaya öbekleri, pelin ve karagan, ufukta Sarı Irmak. 40 koyun tek çizimdir; ağıldan tek tek çıkar, çayırda otlar, sayımda hattan tek sıra geçer. Binilen iki koyun iskeletlidir. Tarla kuşu, keklik, karga, tarbagan ve kum faresi kodla çizilir; yaklaşınca kaçar, vurulunca düşer. Uzaktaki sayım kalabalığı kart kademesinde olacaktır, bugün yoktur.
- **Çocuklar.** Küçük Mete, çocuk Yançi ve Luhun kendi Meshy modelleridir: insan sınıfı 45'er kredi, yürüme ve koşu iskeletle gelir. Yançi ve Luhun'a ayrı model yapıldı, çünkü katalogdaki Retexture yolu Hereka'da iki kez soluk yüz vermişti. Üçünün yüzü kredisiz boyandı ve oyun dokusu 1024²'den 2048²'ye çıktı ([Varlık Hattı](/docs/development/asset-pipeline)). Görünüşleri oluşturucudan gelmez.
- **Yay ve biniş.** Yay nişanı kütüphaneye bir kez alındı (3 kredi); bırakma kodladır. Koyuna biniş kütüphanede yoktur, oturuştan kodla türer.
- **Koyun.** Ağı Meshy'dendir (40 kredi); iskeleti, dört klibi (bekle, otla, yürü, tırıs) ve uzak sürü ağı Blender betiğiyle yapıldı, kredisizdir.
- **Bedel.** Hepsi 178 kredi tuttu, senin «Yançi ve Luhun da, 178» onayınla (E14). Göz onayı bekleyenler (Çocukluk'un akışı, çocukların yüzleri, koyun, köprü videoları) [Karar Bekleyenler](/docs/general/pending-decisions)'dedir.

![Çocukların yüzleri: önce, sonra ve konsept](/media/docs/media/review/cocuk_yuzleri.jpg)

![Koyun: duruş, yürüyüş, otlama, tırıs ve 1.300 üçgenlik uzak sürü ağı](/media/docs/media/review/cocukluk_koyun.jpg)

> [!DURUM]
> Godot'da bugün (2026-11-08): Çocukluk'un üç fazı bitti ([K102](/docs/source/design/decisions#k102)). Yeni Oyun Önsöz'ü oynatır, sonra Çocukluk başlar: 22 Eylül MÖ 228, 08:40, Ordos. Oyunun saati akar (2,5 sn = 1 oyun dakikası; bloklayan söz saati durdurur, ekranda saat yok, ışık saati izler). Küçük Mete yürür, koşar, zıplar, yaşlı koyuna `E` ile biner, Shift'le dürter, iner; oyuncak yayla sağ tuşla nişan alır, sol tuşla bırakır, düşeni `E` ile alır. Ağılda inatçı koyunlar kımıldar; Luhun hızlı koyunla taşa yarışır, Yançi ilk kuşu önce vurur, fareye yaklaşınca Luhun «Yavrusu var.» der, 90 sn'de Yançi bir kuşu gösterir. Sayım 11:00'den önce başlamaz: sayıcı sürüyü hattan geçirir ve çocukları sayar, Dailin'in kalabalığı toplanır, Teoman ve üç bey atlı geçer, Teoman uzaktan dört saniye bakar, «Beni gördü.» sözünün son karesi Köprü 1'in keçe panosuna karışır. Ardından Köprü 1, oluşturucu «Yola Hazırlan» (köken, zorluk, beş pelerin boyası, Kışlak kılığı), Yola Çıkış (karlı şafak öncesi, üç adım, «Kırk iki gün yol.»), Köprü 2 ve «I. Perde: Çan» kartı gelir, açılış ekranına dönülür; kayıt yazılmaz, oluşturulan Mete kampa inmez. İkinci oyunda Esc basılı tutulunca «Çocukluğu geç» Köprü 1'e atlar. HUD çocukta da görünür: portre, mini harita, görev kartı ve yön işareti, yuvalar, I J M. Kamera 22 m'de, 38°'lik uzak karededir. Sözler seslidir: 55 söz, çocukların birbirine sözleri ve tepki sözleri de içinde (küçük Mete Ryan Quin, çocuk Yançi Emmaline, Luhun Austin; [K105](/docs/source/design/decisions#k105)). Otomatik oynatmada sahne 189,9 sn sürer; ilk oyunda ≈5–6 dk beklenir, gerçek oyuncuyla ölçülmedi. Görev ve diyalog sistemine taşınma, Kışlak'ın Köprü 2'de yüklenmesi ve I. Perde'nin açılışı I. Perde'nin maddeleridir. Serbest Gez'de oluşturulan karakter değil Çocuk yürür.

```ilerleme
childhood
```

## Kaynaklar

- [story.md §5](/docs/source/design/story#5-cocukluk-koyun-sirtinda), [§6](/docs/source/design/story#6-genclik-ve-rehinelige-gidis), [§7.4](/docs/source/design/story#7-4-pelerin-6-tek-renk-kurali), [§7.8](/docs/source/design/story#7-8-baglar-ve-kucuk-duzeltmeler)
- [act0-text.md, Köprüler](/docs/source/design/act0-text#kopruler-act0-narr-1-act0-narr-7), [Bedel](/docs/source/design/act0-text#bedel-k61)
- [decisions.md](/docs/source/design/decisions): [K6](/docs/source/design/decisions#k6), [K17](/docs/source/design/decisions#k17), [K34](/docs/source/design/decisions#k34), [K36](/docs/source/design/decisions#k36), [K37](/docs/source/design/decisions#k37), [K58](/docs/source/design/decisions#k58), [K61](/docs/source/design/decisions#k61), [K65](/docs/source/design/decisions#k65), [K67](/docs/source/design/decisions#k67), [K68](/docs/source/design/decisions#k68), [K78](/docs/source/design/decisions#k78), [K85](/docs/source/design/decisions#k85), [K93](/docs/source/design/decisions#k93), [K98](/docs/source/design/decisions#k98), [K99](/docs/source/design/decisions#k99)
- [act1.md §12](/docs/source/design/act1#12-ogretim-ve-ilk-15-dakika), [§8.11](/docs/source/design/act1#8-11-esik-ve-ev-the-threshold-and-home)
- [godot.md §9.4](/docs/source/design/godot#9-4-cocukluk-koyun-sirtinda-childhood), [§3.6](/docs/source/design/godot#3-6-onsoz-sinemasi-k68)
- [mete-tarih.md §3.5](/docs/source/research/mete-history#3-5-yol-ve-hesap)
- [d3/register.md](/docs/source/design/d3/register): E14 ve E15

İlgili sayfalar: [Önsöz: Kopuz Söyler](/docs/story/prologue), [I. Perde: Çan](/docs/story/act-1), [Hikâye Omurgası](/docs/story/spine), [Kadro](/docs/story/cast), [Hayvanlar](/docs/world/animals), [Kamera ve Kontroller](/docs/gameplay/camera-controls), [Karar Bekleyenler](/docs/general/pending-decisions).
