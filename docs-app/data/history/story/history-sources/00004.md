---
title: Tarih ve Kaynaklar
order: 70
status: tasarim
summary: 'Oyunun tarih dayanağı Shiji 110''dur; bu sayfa kaynakları, Çince alıntıların denetimini, grupları, neyin tarih neyin kurgu olduğunu, gösterilmeyecek adları, tek yazım tablosunu ve ad kurallarını toplar.'
sources:
  - docs/research/mete-tarih.md
  - docs/research/groups-research.md
  - docs/research/mitoloji.md
  - docs/design/decisions.md
  - docs/design/story.md
  - docs/design/army.md
  - docs/design/settlement.md
  - docs/design/act1.md
  - docs/design/act0-text.md
  - docs/design/time.md
  - docs/design/d3/oyun-durumu.md
---

## Özet

Oyunun tarih omurgası Shiji'nin 110. bölümüdür. Tarih değişmez, her dalda korunur: oyuncu kaçışın biçimini seçer, kaçışın olup olmadığını seçmez. Tarih kesindir: kaynağın gün vermediği olaylar da oyuncuya tam tarihle söylenir, oyuncu metninde «c.», «dolayı» ya da aralık yoktur; kaynak etiketi (K kaynakta yıl ya da ay var, S kaynakta sıra var, Y oyunun seçimi) yalnız belgede kalır, Destan Kitabı oyunun tarihini kurgu diye işaretlemez ([K33](/docs/source/design/decisions#k33)). Uydurulan kişi ve kurumlar Destan Kitabı'nda «kurgu tercihi» diye işaretlenir; mitoloji kurgu listesine girmez ([K13](/docs/source/design/decisions#k13)). Yer ve grup adları dönemin adlarıdır: Mete'nin yaşadığı yıllarda olmayan ad gösterilmez.

> [!NOT]
> «Kesin tarih diye soyleyelim»

## Shiji 110 satırları

Karakterler zh.wikisource baskısındandır ve aşağıdaki denetimden geçti; Türkçeler tasarım belgelerinindir.

| Metin | Türkçesi | Oyundaki karşılığı |
|---|---|---|
| 東胡彊而月氏盛 | Tunghu güçlüydü, Yüeçi serpilmişti | Anlatıcının N3 satırı |
| 兒能騎羊，引弓射鳥鼠 | Çocuk koyuna biner, yayla kuş ve fare vurur | Çocukluk «Koyun Sırtında»; hanenin av payı çocuk ve gencin işidir |
| 頭曼以爲壯,令將萬騎 | Teoman onu yiğit bulup on bin atlının başına koydu | Ev sahnesi, II. Perde |
| 作爲鳴鏑,習勒其騎射 | Islıklı oku yaptı, atlılarını atlı okçulukta talim ettirdi | Talim, disiplin |
| 鳴鏑所射而不悉射者,斬之 | Islıklı okun vurduğuna topluca atmayanın başı kesilir | Islık buyruğu, ret kararı |
| 行獵鳥獸 → 自射其善馬 → 自射其愛妻 → 射單于善馬 → 射頭曼 | Av, kendi iyi atı, sevdiği eş, Tanhu'nun iyi atı, Teoman | II. Perde'nin ıslık sınamaları |
| 冒頓自立爲單于 | Mete kendini Tanhu ilan etti | II. Perde'nin sonu |
| 與匈奴閒，中有棄地，莫居，千餘里 | Aralarında kimsenin oturmadığı bin li'den geniş boş toprak | Issız Toprak, Gözcü Konakları |
| 地者，國之本也 | Toprak devletin temelidir | III. Perde'nin Dailin'i |
| 大破滅東胡王，而虜其民人及畜產 | Tunghu kralını ezdi, halkını ve hayvanlarını aldı | Hayvan ganimet olur; insan olmaz, yenilenler seçer (tasarım tercihi) |
| 舉事而候星月,月盛壯則攻戰,月虧則退兵 | İşe yıldızı ve ayı gözleyerek girer; ay doluyken saldırır, eksilirken çekilir | Gün IV dolunay; Baideng; ordu morali |
| 歳正月 · 五月，大會蘢城 · 秋，馬肥，大會蹛林 | Yıl başı küçük toplantı, 5. ay Lung-çeng, güzün Dailin'de sayım | Kış Toplantısı, Lung-çeng, Dailin Sayımı |
| 單于朝出營，拜日之始生，夕拜月 | Tanhu sabah doğan güneşe eğilir, akşam aya | Önsöz'ün doğumu; Gök Direği'nde Şafak Selamı |
| 士力能毌弓，盡爲甲騎 | Yay çekebilen her er zırhlı atlıdır | Piyade yok, seferberlik |
| 會冬大寒雨雪，卒之墮指者十二三 | Kış geldi, büyük soğuk ve kar; askerin onda ikisi üçü parmağını yitirdi | Baideng'in kar kilidi; soğuk oynanmaz (K1) |
| 匈奴人眾不能當漢之一郡 | Hun nüfusu Han'ın bir komutanlığı etmez | Sayılara kuşku: Defter söylenen ve beslenen sayıyı ayırır |
| 諸引弓之民,并爲一家 | Yay çeken bütün halklar tek aile oldu | VI. Perde, 176 mektubu |

Rehinelik ve kaçış Shiji 110'dandır. Tam liste: [army.md §1](/docs/source/design/army#1-tarih-shiji-110), [settlement.md §1](/docs/source/design/settlement#1-tarih-dayanagi), [story.md §2](/docs/source/design/story#2-zaman-cizelgesi-1).

## Çince alıntıların denetimi

Bütün Çince parçalar birincil metinle karşılaştırıldı ([K33](/docs/source/design/decisions#k33), [mete-tarih.md §1](/docs/source/research/mete-history#1-kaynak-denetimi-7)).

- **Tarama.** Belgelerde ve sitede 346 satırda 324 ayrı parça tarandı, zh.wikisource ham metniyle karşılaştırıldı (56 bölüm ve 4 şerhli bölüm). İkinci turda 299 parça yeniden sınandı, sonuç değişmedi. Shiji ve Hanshu'ya dayanan bütün alıntılar metinle eşleşir.
- **İkinci tanık.** Shiji ile Hanshu 61 ve 94'ün parçaları ayrıca Kanripo'nun metniyle sınandı ve eşleşti. Hanshu 96'nın alıntıları da eşleşir, ama yalnız «düzeltilmemiş» uyarısı taşıyan Vikikaynak sayfasıyla: ikinci tanıkları yoktur.
- **Site.** Site sayfalarındaki 37 ayrı Çince parçanın hepsi Vikikaynak ya da Kanripo metninde bulundu; Çince karakter düzeltmesi gerekmedi.
- **Kural.** Oyuna basılacak her yeni Çince satır ikinci bir tanıkla, Kanripo ya da basılı metinle sınanır. Godot'da bugün Çince satır yoktur.

Düzeltilen sekiz yer: bir okuma tercihi, iki yazım varyantı, bir noktalama ve dört çeviri.

| Eski | Yeni | Neden |
|---|---|---|
| 士力能毋弓 | 士力能毌弓 | 毋 «yapma» demektir, cümle anlam vermez; Hanshu 94A 彎弓 yazar, Shiji 66'nın iç tanığı 毌'yi destekler; okuma tercihidir |
| 盡為甲騎; 不為備 | 盡爲甲騎; 不爲備 | Satırlar Shiji'dir; 為 Hanshu biçimidir |
| 五月大會蘢城 · 秋馬肥大會蹛林 | 五月，大會蘢城 · 秋，馬肥，大會蹛林 | Noktalama |
| «Yüeçi zenginleşmiş» | «Yüeçi serpilmişti» | 盛 zenginlik değil güç ve serpilmedir |
| «kış ortası, Han askeri ağır kayıp verdi» | «askerin onda ikisi üçü parmağını yitirdi» | Metin kaybı sayıyla verir |
| «hırsızın evi alınır» | «hırsızın hanesine el konur» | 家 burada haneyi anlatır |
| «ayı gözleyerek» | «yıldızı ve ayı gözleyerek» | 候星月 |

Anlatıcının N3 satırı da bu yüzden yeniden yazıldı: «batıda Yüeçi serpiliyordu / the Yuezhi flourished» ([Çocukluk: Koyun Sırtında](/docs/story/childhood)).

## Öteki dayanaklar

| Kaynak | Ne için |
|---|---|
| Shiji 6, 8 | Meng Tian'ın Ordos'u alması (215), Birinci İmparator'un ölümü (Temmuz 210), Han'ın kuruluşu |
| Shiji 123, Hanshu 96A | Yüeçi: göçer ülke (行國), hükümdar Yüeçi Kralı (月氏王), sonraki yazgısı; Usun bebeği Kunmo |
| Shiji 93, 99 | Mayi, Baideng, heqin, Han kralı Xin; Zang Yan, Zhang Sheng, Tuidang, Wang Huang |
| Shiji 7 | Loufan okçusu: Xiang Yu'nun bakışından kaçan okçu |
| Shiji 81 | Mete'den önceki Tunghu seferleri |
| Hanshu 94A, 94B | Tengri (撐犁) ve «oğul» (孤塗); Tanhu soyu Luandi; Wei Lü'nün sur önerisi; Beyaz At Antı; kurgu adların kökleri |
| Hanshu 61 | Kunmo, Nandoumi, Bujiu |
| Hou Hanshu 87, 89, 90 | Çiang, soylar, Tunghu kalıntıları, Yüeçi'nin eski yeri |
| Sanguozhi 30 ve Weilüe | Kuzeyin beş ülkesi, Çoson; Tunghu adları (Kebi, Mijia) |
| Herodot 4.70 | Kâse andının kalıbı (kurgu tercihi) |
| Sanjiaocheng (Hexi, Shajing kültürü) | Kışlağın görünüşü: toprak sedde, keçe ev, arpa ve darı çukurları |
| Ivolga (Buryatya) | V. kademenin Surlu yolu |
| Terelj ve Khustyn Bulag demiri | Demirci Ocağı |
| Benjamin 2003 | Yüeçi'nin büyük göçü Mete'den sonradır: Benjamin'in tahminiyle 162'de başlar, Ili'de 132'ye dek sürer |

Yalnız künye ya da alıntı olarak görülenler: Watson, Di Cosmo, Yü, Barfield, Beckwith, Psarras, Hulsewé ([groups-research.md §0](/docs/source/research/groups-research#0-evidence-and-conventions)). [act1-script.md](/docs/source/research/act1-script) Tanhu 1'in dökümüdür, metni kullanılmaz. Mitolojinin tanıkları ayrı sayfadadır: [Mitoloji](/docs/story/mythology).

## Gruplar

Atlasın açılma sırası [K8](/docs/source/design/decisions#k8) ve [groups-research.md §4](/docs/source/research/groups-research#4-reveal-order)'tür. Ad sütunu atlasın TR ve EN biçimidir.

| Grup | Çince | Tür | Mete'nin hayatındaki yeri | Açılma |
|---|---|---|---|---|
| [Hun Tanhuluğu](/encyclopedia/xiongnu) / Xiongnu | 匈奴 | Yay çekenler ülkesi | Meng Tian 215'te kuzeye sürer; darbe | I |
| [Yüeçi](/encyclopedia/yuezhi) / Yuezhi | 月氏 | Göçer ülke | Rehinelik, batıya sürülüş, 176 | I |
| Ç'in İmparatorluğu / Qin Empire | 秦 | İmparatorluk | Meng Tian; III → IV Kroniği'nde yıkılır | I |
| [Usun](/encyclopedia/wusun) / Wusun | 烏孫 | Küçük göçer ülke | Nandu'nun söylentisi; Kunmo; 176 mektubu | I söylenti, VI |
| [Çiang](/encyclopedia/qiang) / Qiang | 羌 | Çoban soyları | Yuan üzerinden; Yüeçi sürülünce boyun eğer | I (Yuan), IV |
| [Tunghu](/encyclopedia/donghu) / Donghu | 東胡 | Hu krallığı | At, hatun, toprak; 26 Eylül 208 baskınıyla yıkılır | II söylenti, III |
| Issız Toprak / The Abandoned Land | 棄地 | Boş bant, iki ucunda gözcü konakları | Üçüncü istek | III |
| Tunghu kalıntıları | 東胡餘類 | Dağa çekilen kalıntı | Yalnız dağ adı: Wuhuan, Xianbei | III sonu |
| Huimo, Çoson / Joseon | 穢貉, 朝鮮 | Beylikler, krallık | Sol kanadın doğu komşusu | III sonu |
| [Luandi](/encyclopedia/luandi-clan), [Huyan](/encyclopedia/huyan-clan), [Lan](/encyclopedia/lan-clan), [Xubu](/encyclopedia/xubu-clan) | 攣鞮, 呼衍, 蘭, 須卜 | Soylar: haritaya konmaz | Tanhu soyu, hatun veren soylar, sonradan yükselen | II, Xubu IV |
| Çu ve Han savaşı | 項羽, 漢 | İç savaş, sınır çizilmez | 206–202 | IV |
| Han Hanedanı / Han Dynasty | 漢 | İmparatorluk | Mayi, Baideng, heqin | Ad IV, tam V |
| [Loufan](/encyclopedia/loufan), [Baiyang](/encyclopedia/baiyang) | 樓煩, 白羊 | Ordos'un Henan krallıkları | 25 Haziran 203'te Mete'ye bağlanır; 127'ye dek yerinde | IV |
| Di | 氐 | Beylikler | Yalnız komşu | IV |
| [Kuzeyin beş ülkesi](/encyclopedia/northern-peoples): Hunyü, Çüşe, [Dingling](/encyclopedia/dingling), Gekun, Şinli | 渾庾, 屈射, 丁零, 鬲昆, 薪犁 | Kuzey ülkeleri | 15 Haziran 202'de boyun eğer; üçünün yeri bilinmez | V açılışı |
| [Loulan](/encyclopedia/loulan), Hujie, Yirmi Altı Ülke | 樓蘭, 呼揭, 二十六國 | Surlu ve küçük ülkeler | 176 mektubu; 26'nın adı yok | VI |
| Nanyue, Minyue, Dong'ou, Viman Çoson, Zhenfan, Lintun | | Krallık, dış vasal, bağlı ülke | Dünya bağlamı | VI |
| Sakalar, Davan, Kangju, Greko-Baktriya, Soğdiana, Part; Dian, Yelang | | Dış halka; güney | Dış halkanın Mete'yle kayıtlı teması yok | Sonsöz |

## Gösterilmeyecek adlar

MÖ 234–174 arasında olmayan ya da o yıllara bağlanamayan adlar atlasta ve metinde kullanılmaz.

- **Sonraki halklar:** Türk, Göktürk, Kırgız (Gekun kullanılır), Tiele, Gaoche, Uygur, Oğuz, Rouran, Tuyuhun, Tibet.
- **Sonraki devlet biçimleri:** Xianbei ve Wuhuan devlet olarak, Yilou, Samhan, Goguryeo, Okjeo, Silla, Baekje, Wa, Yayoi.
- **Yüeçi'nin sonrası:** Büyük Yüeçi, Küçük Yüeçi, Kuşan. Hexi'nin Han komutanlıkları, Xiutu ve Hunye kralları, Shanshan, «36 ülke».
- **Mete'den önce bitenler:** Linhu, Danlan, Yiqu, Shanrong. Seleukoslar da pencerede kalıcı değildir.
- **Etiketler:** Ötüken; arkeolojik kültür adları (Shajing, Shanma, Pazırık, Tagar); Toharca bir halk adı olarak; genel sözler: kabile, klan.

## Tarih ile kurgu

| Sınıf | Neler | Kural |
|---|---|---|
| Tarih | Mete, Teoman, gözde hatun ve küçük oğul, rehinelik, at çalma, on bin atlı, ıslıklı ok, darbe, Tunghu, Yüeçi, Mayi, Baideng, heqin, 176 mektubu, Meng Tian; Kunmo, Han Xin, Zang Yan, Tuidang ve öteki adı kaynakta geçen kişiler | Her dalda korunur |
| Mitoloji | Tengri (Hun çağının tek tanrı adı, 撐犁), Kayra Han, Ülgen, Erlik (Hun ağzında Kara Nama), Umay, Yer-Sub, Od Ana, Bayanay, Al Karısı, Yol Tengrisi | Kurgu listesine girmez (K13). Her Destan girdisi çağ rozeti taşır: «Yıllıktan» (Hun çağı Çin yıllıkları), «Taştan» (Göktürk ve Uygur tanıkları), «Ozan der» (geç derlemeler), «Bizim» (oyunun seçimi) ([K35](/docs/source/design/decisions#k35)). Önsöz'ün panolarında rozet ekrana yazılmaz, Destan Kitabı'ndadır ([K68](/docs/source/design/decisions#k68)) |
| Kurgu | Amaga, Farnak, Mene ve öteki adlı kişiler; tarihî kişiliklere oyunun verdiği adlar (Lan Hatun, Huyan Hatun, Gutu, Yançi, Yimo); kamlar Şidu, Nangçi, Dangyu; kefil ve çetele düzeni; rehinenin çanı; Kâse andı | Destan Kitabı'nda «kurgu tercihi» |
| Tasarım aracı | Kara Yol, Kıl Köprü, Çığırtkan | Listeye girmez |
| Tasarım tercihi | Mete'nin payının yeri, babanın közüyle yanan ilk ocak, kademe adları, yenilenlerin seçimi, Gönül, Kâhya, Dailin'in yeri, Gök Direği'nin biçimi, Surlu Avlu, küçük yer adları (Karasu, Seki, Dirsek, Kuytu), yada taşı, doğum yurdunun doğuya bakan kapısı | Destan Kitabı'nda «tasarım tercihi», kurgu listesine girmez |
| Oyunun takvimi | Doğumun günü (27 Eylül MÖ 234), Çocukluk (22 Eylül 228), Yola Çıkış (15 Aralık 213), rehineliğin 26 Ocak MÖ 212'de başlaması, Gün I'in 2 Aralık 210 oluşu, perde başları ([K25](/docs/source/design/decisions#k25)) | Kaynak gün vermez; oyunda kesin söylenir, Destan işaretlemez (K33) |

**Kaynağın söylemedikleri.**

- Doğum: 27 Eylül MÖ 234 oyunun seçimidir (Y): yıl dipnotsuz modern bir tahmindir, gün 8. ayın dolunayıdır. Oyunda kesin söylenir, Destan işaretlemez (K33).
- Yıllar: Sima Qian'ın metninde Mete'nin tahta çıkış yılı yoktur; MÖ 209'un en eski açık tanığı Shiji 110'un şerhinde Xu Guang'dır (352–425). Baideng'in geleneksel yılı MÖ 200'dür; kuşatma Kasım 201'e düşer, oyun 201 der, Destan notu 200'ü yazar. «208'e dek» Di Cosmo'dan Vikipedi üzerinden gelir.
- Onlu düzen: Shiji onu Mete'nin icadı demez. 24 başın dökümü yoktur. «Tümen» Shiji'de geçmez, sözcük 萬騎'dir.
- Sayılar: 10.000, 300.000 ve 400.000 Han kaynağının sayılarıdır, Hun nüfusu satırıyla gerilimlidir. Oyun gösterimi sayıyı doğrulamaz.
- 176 mektubu: «yok ettim» abartıdır, Yüeçi Kralı'nı sonradan Laoshang öldürür. Asıl göç Mete'den sonradır.
- Kışlağın yeri: Yüeçi'ye kesin bağlanan yer yoktur. Önerilen ≈[99,62; 38,84] çıkarımdır, atlastaki iğne [99,4; 38,9] yaklaşık 20 km ötededir ([groups-research.md §5](/docs/source/research/groups-research#5-tanhu-act-1-location)).
- Lung-çeng ve Dailin: Arkhangai kazısının kimliği tartışmalıdır, Dailin'in yeri bilinmez.
- Yüeçi ve Toharca bağı tartışmalıdır: kurgu tercihidir.
- Tanrıların çağı: Hun çağı metninde tanrı adı yalnız Tengri'dir; Umay, Yer-Sub ve kut 8. yy Orhun yazıtlarındadır; Kayra Han, Ülgen, bugünkü Erlik figürü ve Bayanay geç derlemelerdir ([mitoloji.md §1–§3](/docs/source/research/mythology#1-taniklik-katmanlari)). Oyun hepsini kullanır: Önsöz'de miti anlatıcı okur, oyunun içinde mit ozanındır.

## Yazım tablosu

Tek tablo [mete-tarih.md §5.3](/docs/source/research/mete-history#5-3-tablo)'tür ([K34](/docs/source/design/decisions#k34)). İngilizcede kim konuşuyorsa onun sözü geçer: atlas, Destan, kronik kartı ve Han ağzı «Xiongnu»; anlatıcı, ozan, Hun ve Yüeçi ağzı «Hun».

| TR | EN | Çince | Not |
|---|---|---|---|
| Hun, Hunlar | Hun (konuşma); Xiongnu (yazı) | 匈奴 | Kim konuşuyorsa onun sözü |
| Hun Tanhuluğu | Xiongnu | 匈奴 | Atlas (K8) |
| Tanhu | Tanhu | 單于 | Her yer; «kağan» ve «hanlık» oyuncu metninde geçmez |
| Mete, Teoman | Mete, Teoman | 冒頓, 頭曼 | Her yer (K16); Modu, Mo-tun, Tuman yalnız Destan notunda ve araştırmada |
| Yüeçi | Yuezhi | 月氏 | |
| Tunghu | Donghu | 東胡 | «Tung-hu» kalktı |
| Ç'in | Qin | 秦 | Proje içi istisna: Çin'le karışmasın |
| Han | Han | 漢 | |
| Usun | Wusun | 烏孫 | «Vusun» kalktı |
| Kunmo | Kunmo | 昆莫 | VI. Perde |
| Dingling | Dingling | 丁零 | Destan notu: «Türk yazınında Ting-ling» |
| Loufan, Baiyang | Loufan, Baiyang | 樓煩, 白羊 | IV. Perde |
| Çiang | Qiang | 羌 | |
| Lung-çeng | Longcheng | 蘢城 | Proje içi istisna; Hanshu 龍城 yazar |
| Dailin | Dailin | 蹛林 | Türk yazınında Tai-lin, yalnız Destan notunda |
| Baideng | Baideng | 白登 | Eberhard Pai-teng yazar |
| Hunyü, Çüşe, Gekun, Şinli | Hunyu, Qushe, Gekun, Xinli | 渾庾, 屈射, 鬲昆, 薪犁 | «Hun-yü» ve «Sinli» kalktı: tire yerleşik değil, x Türkçede ş olur |
| Jiyu (Laoshang) | Jiyu (Laoshang) | 稽粥, 老上 | Okunuş Jiyu (索隱 粥音育); «Jizhu» kalktı |

## Ad kuralları

- **Yazım (K34).** Türkçe biçimi olan ad o biçimle yazılır: Hun, Tanhu, Mete, Teoman, Yüeçi, Tunghu, Usun. Öteki adlar Türkçe okunan pinyindir, tiresiz; q → ç, x → ş, kurgu adlarda zh de ç: Dingling, Dailin, Baideng, Loufan, Baiyang, Çiang, Kunmo, Hunyü, Çüşe, Gekun, Şinli, Jiyu. Proje içi iki istisna Ç'in ve Lung-çeng'dir. Wade-Giles biçimleri (Ting-ling, Tai-lin, Pai-teng) yalnız Destan notunda geçer. Godot'da adlar tek çeviri tablosundan okunur.
- **İngilizce.** Kim konuşuyorsa onun sözü: atlas, Destan, kronik kartı ve Han ağzı «Xiongnu»; anlatıcı, ozan, Hun ve Yüeçi ağzı «Hun». Atlas ilk açılışta bir kez köprü kurar: Çin kaynakları «Xiongnu», bozkır «Hun» der.
- **Mete ([K16](/docs/source/design/decisions#k16)).** Kahraman her yerde Mete'dir; baba Teoman'dır. Başka kaynaklardaki Motun, Tuman biçimleri kullanılmaz.
- **Unvan.** Oyuncuya «Tanhu»; ülke «Hun Tanhuluğu», merkez «Tanhu Avlusu»; Destan'da bir kez 撐犁孤塗 «Göğün Oğlu». Amaga «kışlak başı»dır, hükümdar «Yüeçi Kralı»dır; yabgu dönem dışıdır ([K15](/docs/source/design/decisions#k15)).
- **Usta.** «Dülger / Carpenter»; «Ağaç Ustası» kalktı.
- **Çalgı.** Telli «kopuz», yaylı «kıl kobuz», ağızla çalınan «ağız kopuzu»; dombra, dombıra, komuz, topşur ve saz oyunda geçmez ([K60](/docs/source/design/decisions#k60)).
- **Konut.** Çadır direk ve örtüdür, kerege ve kalıcı ocak yoktur; Yurt kerege, uuk, tündük ve ocaktır; Otağ yurdun en büyük boyudur; Düzen içteki eşya planıdır. Destan Kitabı ilk kullanımda «yurt»un Türkçede toprak ve kamp yeri olduğunu, konutun ev ya da öy olduğunu bir satırla yazar.
- **Tarih.** Oyuncu metninde tarih tam yazılır («27 Eylül MÖ 234»). Han ayıyla verilen günler yeniden kurulmuş Ç'in-Han takviminin Jülyen aralığına oturur (K33).
- **Mitoloji.** Tengri, Kayra Han, Ülgen (lakabı Ayas), Erlik, Kara Nama, Umay, Yer-Sub, Od Ana, Bayanay, kam, Demirkazık; Hun ağzında «Tanrı» değil «Tengri»; «şaman» yok (K35).
- **Dönem adları.** Vahalar dönem adıyla yazılır (Yutian, Qiuci, Shule), kaynağı sonraysa «adı sonradan biliniyor» etiketi alır. Araştırmada `*` taşıyan Türkçe biçimler öneridir.
- **Sözcük varlığı.** Kademe adları ve yurt terimleri Türkçedir, dönemin sözcüğü değil (kerege, tündük, Oba). Onbaşı ve yüzbaşı bugünkü rütbeleri çağrıştırır; Uldın'ın «eski onbaşı»lığı için korunur.
- **Dil.** Kimlikler İngilizce, oyun metinleri TR ve EN çifti. Söylenen dil İngilizce, altyazı Türkçedir ([K61](/docs/source/design/decisions#k61)).
- **Kişi adları.** Hun kurgu adlarının, Yüeçi ve Tunghu adlarının kaynakları [Kadro](/docs/story/cast#adlarin-kaynagi) sayfasındadır ([K37](/docs/source/design/decisions#k37)).

> [!DURUM]
> Godot'da bugün: atlas, gruplar, hayat çizgisi ve Destan'ın tarih notları yok; Godot'da Çince satır yoktur; adların tek çeviri tablosu henüz yazılmadı. Godot verisinde tablodaki adlardan yalnız «Mete» ve «Hun» geçer, ikisi de tabloya uyar ([d3/oyun-durumu.md](/docs/source/design/d3/game-state)). Prototipte denendi: atlas, grupları ve hayat çizgisi (dört dönem: 210, 209, 200, 174; araştırma altı önerir: 210, 209, 207, 204, 200, 176) ve çağ dışı adların atlastan çıkarılması. Atlas Godot'da II. Perde'nin harita fazındadır ([Yol Haritası](/roadmap#item-atlas)).

## Kaynaklar

- [mete-tarih.md §1](/docs/source/research/mete-history#1-kaynak-denetimi-7), [§2](/docs/source/research/mete-history#2-kronoloji-1), [§5](/docs/source/research/mete-history#5-yazim-birligi-9)
- [groups-research.md §1](/docs/source/research/groups-research#1-records), [§2](/docs/source/research/groups-research#2-must-not-be-shown-in-234-174-bc), [§3](/docs/source/research/groups-research#3-geography-js-errata), [§4](/docs/source/research/groups-research#4-reveal-order), [§5](/docs/source/research/groups-research#5-tanhu-act-1-location), [§6](/docs/source/research/groups-research#6-other-uncertain-points)
- [mitoloji.md §1](/docs/source/research/mythology#1-taniklik-katmanlari), [§2](/docs/source/research/mythology#2-hun-cagi-tanikliklari), [§3](/docs/source/research/mythology#3-gokturk-ve-uygur-cagi)
- [army.md §1](/docs/source/design/army#1-tarih-shiji-110), [settlement.md §1](/docs/source/design/settlement#1-tarih-dayanagi)
- [story.md §2](/docs/source/design/story#2-zaman-cizelgesi-1), [§8](/docs/source/design/story#8-kadro)
- [decisions.md](/docs/source/design/decisions): [K8](/docs/source/design/decisions#k8), [K13](/docs/source/design/decisions#k13), [K15](/docs/source/design/decisions#k15), [K16](/docs/source/design/decisions#k16), [K25](/docs/source/design/decisions#k25), [K33](/docs/source/design/decisions#k33), [K34](/docs/source/design/decisions#k34), [K35](/docs/source/design/decisions#k35), [K37](/docs/source/design/decisions#k37), [K60](/docs/source/design/decisions#k60), [K68](/docs/source/design/decisions#k68)
- [act1.md §1](/docs/source/design/act1#1-oncul-sure-ton), [act0-text.md](/docs/source/design/act0-text), [time.md §2](/docs/source/design/time#2-takvim)
- [Shiji 110, Vikikaynak](https://zh.wikisource.org/wiki/史記/卷110), [Hanshu 94A, Vikikaynak](https://zh.wikisource.org/wiki/漢書/卷094上)

İlgili sayfalar: [Hikâye Omurgası](/docs/story/spine), [Mitoloji](/docs/story/mythology), [Kadro](/docs/story/cast), [Harita ve Ölçek](/docs/world/map).
