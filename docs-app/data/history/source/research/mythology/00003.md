# Türk mitolojisi ve Hun dönemi inançları

Bu belge cevap #8'in ("yalnız bu tanrılara bağlı kalma, araştır ve geliştir") ve giriş sineması isteğinin araştırma tabanıdır: ozan kopuzla mitolojik bir hikâye anlatır, anlatı Mete'nin doğumuna varır. Her öge hangi çağda belgelendiğiyle yazılır, çünkü oyun MÖ 3. yüzyılda geçer ama Türk mitolojisi dediğimiz malzemenin çoğu MS 8. ile 20. yüzyıllar arasında yazıya geçmiştir. Etiketler: **[kaynak]** kaynağı olan bilgi, **[çıkarım]** kaynaktan benim çıkarımım, **[kurgu]** oyun için önerilen uydurma. Cevap numaraları `docs/design/d3/register.md`'den, K numaraları `docs/design/decisions.md`'dendir. Kod yazılmadı; öneriler sahibi belgelere işlenecektir.

## Özet

1. Hun çağından elimizde bir tek tanrı adı var: Gök, 撐犁 (Hanshu 94A). Yanında Tanhu'nun güne ve aya eğilmesi, yılda üç toplantıda atalara, göğe, yere ve ruhlara sunu, kam (胡巫) ve lanet, altın insan, kılıç tanrısı ve kurt ile karganın beslediği bebek vardır. Panteon yoktur.
2. Umay, Yer-Sub ve kut sözcüğü 8. yüzyıl yazıtlarındadır. Erlik adının kökü Orhun'da Gök'ün sıfatıdır (`erklig`), Uygur Budist metinlerinde Yama'nın adı olur.
3. Kayra Han, Ülgen, Kızagan, Gün Ana, Ay Ata, Yayık 19. yüzyıl Altay derlemelerindedir. Radloff aynı anlatıda Musa ve Buda izleri bulunduğunu kendisi yazar. Bayanay, Abası ve Ürüng Ayıı Toyon Sakha derlemeleridir.
4. Oyun hepsini kullanır, ama ozan ağzından. Destan Kitabı her girdiye çağ etiketi koyar. K13 değişmez: mitoloji kurgu listesine girmez.
5. Giriş sineması 9 sahne, ≈3 dk 35 sn: sudan başlar, Mete'nin doğumuna varır, son sahne oynanan Çocukluk'a (Koyun Sırtında) geçiştir. Mitten tarihe köprü bir Shiji satırıdır: Tanhu şafakta çıkar, doğan güne eğilir.
6. Altay'daki Erlik, oyunun pazarlık eden Erlik'ini destekler: adı anılmaz, korkulur, kandırılır, kurbanı vadeli verilir. «Tüccar» benzetmesi kaynakta yoktur, Tanhu 1'in ses tarifinden («merchant of souls») gelir; oyun metninde kullanılmaz. K4'ün Kül Borcu biçimi kalır. Yeni malzeme: Kara Nama, Toybodım, Kıl Köprü.
7. Demirkazık'ın Eski Türkçe biçimi ikincil kaynakla doğrulandı (Kaşgarlı: `tämür qazuq`, Jiang 2026'nın Divan alıntısı; Li 2014). MÖ 209'da kutupta parlak yıldız yoktur: en yakınları sönük 4 UMi (3,9°) ve 5 UMi (5,6°), parlakların en yakını Kochab (7,7°). Kazık dönmeyen bir noktadır, çevresinde iki at döner. `iron_stake` metni ve gök kubbesi buna göre düzelir.
8. Geyik taşları MÖ 1200–600 arasıdır ve Hexi'de değil kuzeydedir; balbal Göktürk çağınındır. Hun'un kendi izi taş sırası ve yakılmış kemiktir; tarihli örnekleri MÖ 1. yy sonu – MS 1. yy'dır, Mete'den ≈150–250 yıl sonra. Bu ayrım Destan Kitabı'nda yazılır.
9. Sistemlere bağlı 25 öneri vardır: Umay ve Düşüş, Erlik ve Kül Ödemesi, Bayanay ve Av Payı, Od Ana ve Küle Yatırma, Yer-Sub ve Taş Yığını, kam rolleri, Beşinci Ay sunusu, Dailin'in Üç Turu, ıduk, yerel inanç notları.
10. İlk turda web arama bütçesi bitti. 2026-11-04 doğrulama turu Radloff, Anohin ve Holmberg'in tam metinlerinde, şerhli Shiji'de ve Godot belgelerinde sınama yaptı; düzeltmeler belgeye işlendi, liste sondaki Doğrulama bölümündedir. Uygulama önerilerinin Godot 4.7 karşılığı «Godot için» bölümündedir.

## 1. Tanıklık katmanları

| Katman | Çağ | Ne | Oyun için anlamı |
|---|---|---|---|
| Hun çağı | MÖ 2. yy – MS 5. yy Çin metinleri (Shiji MÖ 91 dolayı, Hanshu MS 111 dolayı, Hou Hanshu 5. yy), Hun mezarları | Dıştan yazılmış kısa notlar; ad yok, uygulama var. Usun Kunmo anlatısı (Shiji 123, Hanshu 61) bu katmandadır | Oyunun "gerçek" olanı. Kişiler bunu yaşar |
| Göktürk ve Uygur | 6.–11. yy yazıtlar, Wei Shu (554) ve Zhou Shu (636), Bizans ve Ermeni tanıklar, Irk Bitig, Kaşgarlı | Türklerin kendi sözü, ilk tanrı adları | Mete'den 800–1300 yıl sonra. Ozan dili |
| Orta çağ destanları | 13.–17. yy Oğuz-name, Reşidüddin, Dede Korkut, Ebulgazi | Yazıya geçmiş soy ve kahraman anlatıları | Ozan dili, serbest yankı |
| Etnografya derlemeleri | 19.–20. yy Radloff, Verbitski, Anohin (1910–1912 derlemesi, 1924 baskısı), Seroşevski, Holmberg; Manas'ın ilk kayıtları (Valihanov, Radloff) | Altay, Sakha, Kırgız sözlü inancı; en zengin katman | En çok ayrıntı buradan gelir. Geç, karışık |
| Popüler derleme | Çağdaş sözlükler, Vikipedi, ağ siteleri | Hepsini tek panteonda toplar, çağ ayırmaz | Yalnız ipucu. Kaynak sayılmaz |

**Şerhler ayrı katmandır.** Shiji ve Hanshu'nun şerhleri Hun çağı tanıklığı değildir: Zhang Hua (3. yy) ve 漢書音義 Jijie'de (5. yy), Cui Hao (5. yy) Suoyin'de alıntılanır; Yan Shigu'nun Hanshu şerhi 641'de, Suoyin ve Zhengyi (736) 8. yy'da yazıldı; Zhengyi'nin alıntıladığı Kuodizhi 642'dir. §2.1'de bu satırlar ayrıca işaretlidir. **[kaynak]** Wei Shu 103 ve Zhou Shu 50 Hun'u ansa da 6.–7. yy metinleridir.

Radloff'un kendi uyarısı: Altay anlatılarında Musa'nın yaratılış öyküsünün ve Budizmin açık izleri vardır; biri Müslümanlar ve Hıristiyanlar eliyle gelmiştir, Mandışire ve Maytere adları Budist etkidir ([Radloff, Aus Sibirien II](https://archive.org/details/aussibirienloseb02radl), s. 5–6). **[kaynak]** Holmberg de Altay tufanını bilinen eski tufan anlatılarının Kitab-ı Mukaddes'e en yakını sayar ([Holmberg 1927](https://archive.org/details/in.ernet.dli.2015.283531), s. 364). **[kaynak]** Bu yüzden "Türklerin eski inancı" diye tek bir sistem anlatmak yanlıştır. **[çıkarım]**

## 2. Hun çağı tanıklıkları

### 2.1 Metinler

Çince satırlar Wikisource baskılarından yeniden okundu; Türkçeler bu belgenindir. **[kaynak]** Bu tablo #7 denetimine de yarar. Baskı farkları vardır: Shiji 數千百人, Hanshu 數十百人; Shiji 北鄉, Hanshu 北向.

| # | Metin | Özgün satır | Türkçesi |
|---|---|---|---|
| H1 | [Hanshu 94A](https://zh.wikisource.org/wiki/漢書/卷094上) | 匈奴謂天為「撐犁」,謂子為「孤塗」 | Hun göğe 撐犁, oğula 孤塗 der. Tanhu'nun unvanı 撐犁孤塗單于: Göğün Oğlu Tanhu |
| H2 | [Shiji 110](https://zh.wikisource.org/wiki/史記/卷110), MÖ 176 mektubu | 天所立匈奴大單于 · 以天之福 | Mete kendisi yazar: "Göğün diktiği büyük Tanhu", "Göğün lütfuyla" |
| H3 | Shiji 110 | 單于朝出營,拜日之始生,夕拜月 | Tanhu sabah konaktan çıkar, güneşin doğuşuna eğilir, akşam aya |
| H4 | Shiji 110 | 歲正月…祠。五月,大會蘢城,祭其先、天地、鬼神。秋,馬肥,大會蹛林 | Yıl başı sunu; 5. ay Lung-çeng'de atalara, göğe, yere, ruhlara sunu; güz, at semizken Dailin |
| H5 | [Shiji Zhengyi (736), Yan Shigu'dan (7. yy)](https://zh.wikisource.org/wiki/史記三家註/卷110) | 蹛者,遶林木而祭也…秋祭無林木者,尚豎柳枝,眾騎馳遶三周乃止 | Dailin ağaç çevresinde dönerek yapılan sunudur. Xianbei'de ağaç yoksa söğüt dalı dikilir, atlılar üç tur atar. Tang çağı şerhidir, Xianbei töresini anlatır; Hun'a yansıtması **[çıkarım]** |
| H6 | Suoyin'de Cui Hao (5. yy); [Hou Hanshu 89](https://zh.wikisource.org/wiki/後漢書/卷89) (5. yy) | 西方胡皆事龍神 · 歲有三龍祠…正月、五月、九月戊日祭天神 · 走馬及駱駝為樂 | Cui Hao toplantı adını "ejder" ile açıklar. Üç sunu, göğün tanrısına. Güney Hunlarında at ve deve yarışı (MS 50 sonrası) |
| H7 | Shiji 110; 逗落 notu Jijie'de Zhang Hua'dan (3. yy) | 舉事而候星月 · 其送死,有棺槨金銀衣裘,而無封樹喪服 · 匈奴名冢曰逗落 | İşe yıldızı ve ayı gözleyerek girer. Tabut, altın, kürk var; höyük ağacı ve yas giysisi yok. Mezara 逗落 denir |
| H8 | Shiji 110; Jijie ve Suoyin'de 漢書音義, Zhengyi'de Kuodizhi (642) | 破得休屠王祭天金人 · 象祭天人也 · 徑路神祠…本匈奴祭天處,秦奪其地 | Xiutu Kralı'nın göğe sunudaki altın insanı. 漢書音義: göğe sunan kişinin suretidir. Kuodizhi: kılıç tanrısı tapınağı Yunyang'da, Qin'in aldığı eski Hun sunu yeri. Suoyin bu rivayete 事恐不然 (doğru olmayabilir) der |
| H9 | [Hanshu 94B](https://zh.wikisource.org/wiki/漢書/卷094下), MÖ 1. yy | 刑白馬,單于以徑路刀金留犁撓酒…共飲血盟 | Ant: beyaz at kesilir, Tanhu kılıç ve altın kaşıkla içkiyi karıştırır, Yüeçi kralının kafatasından içilir |
| H10 | Hanshu 94A, MÖ 89–88 | 律飭胡巫言先單于怒…遂屠貳師以祠。會連雨雪數月…為貳師立祠室 | Wei Lü kama "ölü Tanhu kızgın" dedirtir, Han generali kurban edilir. Aylarca kar yağar, sürü ölür, korkan Tanhu ona türbe yaptırır |
| H11 | [Luntai fermanı](https://zh.wikisource.org/wiki/輪臺詔), Hanshu 96B | 匈奴使巫埋羊牛所出諸道及水上以詛軍 · 縛馬者,詛軍事也 | Hun kamları Han ordusunun yollarına ve sularına koyun ve sığır gömer, lanet eder. Bağlanmış at da lanettir |
| H12 | [Shiji 123](https://zh.wikisource.org/wiki/史記/卷123); [Hanshu 61](https://zh.wikisource.org/wiki/漢書/卷061) | 昆莫生棄於野。烏嗛肉蜚其上,狼往乳之。單于怪以為神 | Usun bebeği Kunmo kıra bırakılır. Karga et getirir, kurt emzirir. Tanhu kutsal sayar, büyütür |
| H13 | [Wei Shu 103](https://zh.wikisource.org/wiki/魏書/卷103), 554 | 匈奴單于生二女…將以與天…老狼…故其人好引聲長歌,又似狼嘷 | Bir Tanhu iki kızını göğe vermek ister. Küçük kız yaşlı kurdun eşi olur. Gaoçe soyu buradan gelir; bu yüzden uzun çekerek şarkı söylerler, sesleri kurt ulumasına benzer. Hun çağı tanıklığı değil, 6. yy'da yazılmış Gaoçe söylencesidir |
| H14 | Suoyin (8. yy), Xihe jiushi'den; Zhengyi'de Kuodizhi üzerinden Xihe gushi | 亡我祁連山,使我六畜不蕃息;失我焉支山,使我婦女無顏色 · 祁連一名天山,亦曰白山 | Bilinen tek Hun şarkısı sayılır. Olay MÖ 121 sonrasıdır, ama ilk tanığı tarihi belirsiz Xihe jiushi'dir ve metin yalnız Tang şerhlerinde korunur **[kaynak; tanıklık geç]**. Suoyin: Qilian'ın öbür adı Gök Dağı (天山), Ak Dağ (白山) da denir. «Ak Dağ» Tanhu 1'in V. Perde adıdır, oyunda ad olmaz |
| H15 | [Hanshu 68](https://zh.wikisource.org/wiki/漢書/卷068) | 虜獲休屠王祭天金人 | Altın insan, Xiutu'nun oğlu Jin Midi'nin biyografisinde de geçer |

Şerhler altın insan için anlaşmaz. Wei Zhao "göğe sununun odağı" der, Cui Hao ve Zhengyi Buda heykeli sayar, Suoyin bir yorumu "olmayabilir" diye geçer ([şerhli Shiji 110](https://zh.wikisource.org/wiki/史記三家註/卷110)). **[kaynak]** MÖ 121'de Hexi'de Budist heykel beklemem. **[çıkarım]**

徑路 sözcüğü ayrı bir tartışmadır: bir kılıç türü ve bir Hun tanrısı olarak kayıtlıdır ([Wiktionary](https://en.wiktionary.org/wiki/%E5%BE%91%E8%B7%AF), [Language Log](https://languagelog.ldc.upenn.edu/nll/?p=24595)). **[kaynak]** Oyundaki `qingrak` bunu kullanır (`progression.md` §17.2). Herodot'ta İskitler demir kılıcı çalı yığınının üstüne dikip Ares diye kurban sunar ([Hdt. 4.62](https://www.perseus.tufts.edu/hopper/text?doc=Perseus:text:1999.01.0126:book=4:chapter=62)). **[kaynak]** Hun kılıç kültü bu bozkır geleneğiyle akrabadır. **[çıkarım]**

### 2.2 Arkeoloji

- **Güneş ve ay çifti.** Takhiltyn Khotgor'da altın daire ve altın hilal tabut kapağında bulundu. Kazıcılar bunu başka Hun mezarlarındaki çiftlerle ve H3 satırıyla bağlar ([Miller vd. 2009](https://edspace.american.edu/silkroadjournal/wp-content/uploads/sites/984/2017/09/Xiongnu-Elite-Tomb-Complexes.pdf)). **[kaynak]** Noyon Uul'da tabut altınının bir kısmı Çinli ustaların işidir ([Polosmak vd.](https://journal.archaeology.nsc.ru/jour/article/view/562)), yani motif Han zevkini de taşıyabilir. **[çıkarım]**
- **Taş sırası.** Büyük Hun mezarlarının kuzeyinde doğu-batı çift taş sıraları; aralarında kül, kömür, yanmış koyun-keçi ve sığır kemiği. Mezarla çağdaş; tarihli örnekler MÖ 1. yy sonu – MS 1. yy, yani Mete'den ≈150–250 yıl sonra ([Miller vd. 2018](https://www.cambridge.org/core/journals/antiquity/article/stone-lines-and-burnt-bones-ritual-elaborations-in-xiongnu-mortuary-arenas-of-inner-asia/1A4636F94C9A10D2599280A59E2E7163)). **[kaynak]** Oyunda Mete çağına konması geriye yansıtmadır **[çıkarım]**. Balbal değildir, makale böyle bir bağ kurmaz.
- **Bronz çağ mirası.** Aynı kazı raporu, hayvan kemiğini mezarın dışında yakıp taş çiftlerinin arasına koyma âdetini Bronz Çağı hirigsurlarındaki yakılmış kemik yığınlarıyla birebir koşut sayar ([Miller vd. 2009](https://edspace.american.edu/silkroadjournal/wp-content/uploads/sites/984/2017/09/Xiongnu-Elite-Tomb-Complexes.pdf)). **[kaynak]**
- **Kartal tacı.** Aluchaideng altın tacı: tepede turkuaz kartal, altta koyun boğan kurtlar ([China Daily](https://govt.chinadaily.com.cn/s/202304/06/WS642e6fcc498ea274927b5b56/eagle-shaped-gold-crown-from-more-than-2-000-years-ago.html)). **[kaynak]** Hun'a atfı ve MÖ 4–3. yy tarihi tartışmalıdır.
- **Yüeçi izi Hun mezarında.** Noin-Ula'daki nakışlı örtülerde bir sunak ve alev başında duran figürler Yüeçi olarak okunur, parça Baktriya işi sayılır ([Noin-Ula](https://en.wikipedia.org/wiki/Noin-Ula_burial_site)). **[kaynak, tartışmalı]**

### 2.3 Hun çağında olmayanlar

Hun çağı metinlerinde şu adlar geçmez: Erlik, Umay, Yer-Sub, kut, Kayra, Ülgen, Ak Ana, Bayanay, Od Ana, Demirkazık, Hayat Ağacı, Tülpar, Bozkurt, Asena. Hun dili de tartışmalıdır; Vovin, Hun yönetici katmanının bir Yenisey dili konuştuğunu önerir (Central Asiatic Journal 44/1, 2000, s. 87–104; [ikinci bölümü](https://www.altaist.org/home/confessions/a-vovin/did-the-xiongnu-speak-a-yeniseian-language-part-2-reexamining-the-lexical-evidence/)), "gök" sözü için Yenisey kökeni de önerilmiştir ([Tengri](https://en.wikipedia.org/wiki/Tengri)). **[kaynak, tartışmalı]** "Hunlar bunlara inanıyordu" denemez; "sonraki bozkır halkları böyle anlatmıştır, köklerinin bir kısmı eski olabilir" denir. **[çıkarım]**

## 3. Göktürk ve Uygur çağı

- **Orhun, gök ve yer.** `Üze kök tengri asra yağız yir kılındukda ikin ara kişi oğlı kılınmış` (Kül Tigin, doğu 1). Oyundaki en eski kozmoloji cümlesi budur ([Orhun Abideleri](https://archive.org/details/orhun_abideleri)). **[kaynak]**
- **Orhun, ölüm.** `Öd tengri yaşar. Kişi oğlı kop ölgeli törümiş` (Kül Tigin, kuzey 10): zamanı Gök buyurur, insan oğlu ölmek için doğmuştur. **[kaynak]** Fiilin okunuşu tartışmalıdır: yaşar, yasar ya da aysar; çeviri «Gök yaşar», «Gök düzenler» ya da «Gök buyurur» olur ([Ayaz 2020](https://dergipark.org.tr/en/download/article-file/979004)).
- **Orhun, Umay ve Yer-Sub.** `Tengri Umay ıduk yir sub basa birti erinç` (Tonyukuk): savaşın ortasında Gök, Umay ve kutsal Yer-Sub düşmanı bastırdı. Umay burada ebe değil, savaş yardımcısıdır. **[kaynak]** Kül Tigin'de (doğu 31) anne Umay'a benzetilir: `Umay teg ögüm katun kutıña` ([Umay](https://en.wikipedia.org/wiki/Umay), [Orhun çalışması](https://dergipark.org.tr/tr/download/article-file/4806051)). **[kaynak]**
- **Orhun, kut.** `Tengri yarlıkadukın üçün özüm kutum bar üçün kağan olurtum` (Kül Tigin, güney 9); Bilge Kağan'da `kutum ülügüm bar üçün`. Kut ve ülüş Gök'ten gelir. **[kaynak]** H2'nin 以天之福 satırı aynı fikrin 900 yıl önceki Çince kaydı olabilir. **[çıkarım]**
- **Orhun, iye.** `Eçümüz apamız tutmış yir sub idisiz bolmazun` (Kül Tigin, doğu 19): atalarımızın yeri ve suyu sahipsiz kalmasın. `İdi` sonraki `iye` ile aynı kökten bir "sahip" sözüdür. **[kaynak, köken çıkarım]**
- **Orhun, erklig.** `Üze tengri erklig` (Bilge Kağan, metin kırık; edisyon "üstte Tanrı kudretli" der). Sözcük burada Gök'ün sıfatıdır. **[kaynak; doğrulama turunda satır yeniden bulunamadı]** Erlik'in önce göksel olduğu görüşü ([Sagaster](https://www.encyclopedia.com/environment/encyclopedias-almanacs-transcripts-and-maps/erlik)) bununla uyuşur. **[çıkarım]**
- **Orhun, yas.** `Yoğçı sığıtçı` (yas tutan ve ağlayan elçiler; Kül Tigin, doğu 4). `Balbal`: Kül Tigin, doğu 16 ve 25; düşman kağanı mezar taşı olarak dikilir. **[kaynak]**
- **Zhou Shu 50, kurt ve ateş.** Aşina soyu kurttan iner; ikinci rivayette kurttan doğan ata rüzgâr ve yağmur çağırır, Yaz Tanrısı ve Kış Tanrısı'nın kızlarını alır, soyuna ateş bularak başa geçer ([Zhou Shu 50](https://zh.wikisource.org/wiki/周書/卷50)). **[kaynak]**
- **Zhou Shu 50, tören.** Kağan otağı doğuya açılır (牙帳東開,蓋敬日之所出也). Her yıl atalar mağarasına sunu; 5. ay ortasında Taren ırmağında (他人水) göğe sunu; ağaçsız yüksek dağa Yer Tanrısı denir (勃登凝黎,夏言地神也). **[kaynak]**
- **Theophylact, 7. yy.** Türkler ateşe aşırı saygı duyar, havayı ve suyu sayar, yere ilahi söyler, tanrı olarak yalnız göğün ve yerin yaratıcısına tapar; at, sığır, koyun keser; geleceği söyleyen din adamları vardır ([Hist. 7.8.11–15](https://mmp.acdh-dev.oeaw.ac.at/archiv/stelle/detail/5051), [çözümleme](https://books.openedition.org/editionscnrs/25263)). **[kaynak]**
- **Bizans elçileri.** İmparatorun elçileri İrtiş kaynağındaki Türk kağanına varmadan iki ateşin arasından geçirilir ([Holmberg 1927](https://archive.org/details/in.ernet.dli.2015.283531), s. 451). **[kaynak, ikinci el]** Olay Menandros'un anlattığı Zemarkhos elçiliğidir: elçiler Soğd ülkesine varınca arındırılır, Zemarkhos iki ateşin arasından geçirilir; elçilik 568 ya da 569'da yola çıkar ([Zemarchus](https://en.wikipedia.org/wiki/Zemarchus), Menandros'tan; Blockley 1985). **[kaynak, ikinci el]**
- **Movses Dasxuranci, olay 681–682, derleme 10. yy.** Kafkas Hunları: ağaç kültü; yıldırım çarpan kişi ve nesne tanrıya adanmış sayılır; dev bir varlığa T'angri Xan der, at yakarlar; ölü üstünde davul, ıslık, yanak kesme, mezarda çıplak kılıç dövüşü, at yarışı; ateşe, suya, yol tanrılarına, aya sunu ([Movses II.40](https://www.attalus.org/armenian/md13.htm)). **[kaynak]**
- **Bugut, 584.** Taspar Kağan'ın stelinin tepesinde dişi kurt ve figür ([Bugut](https://en.wikipedia.org/wiki/Bugut_inscription)). Kurt atası inancının ilk görsel kaydı. **[kaynak]**
- **Irk Bitig, Dunhuang, büyük olasılıkla 9. yy (Bazin: 930 ya da 942).** Yol Tengrisi iki kez konuşur: benekli atlı, sabah akşam gezen, korkan insana kut veren (2. fal); yaşlı, kırılanı onaran, yırtılanı diken (48. fal). Altın kanatlı kartal (3), göğe dua eden kuzgun (54) ([Tekin 1993](https://altaica.ru/LIBRARY/Tekin%20Talat/Tekin_Irk%20Bitig%20-%20The%20Book%20of%20Omens%201993.pdf)). **[kaynak]**
- **Uygur Budist metinleri.** `Erklig han`: güçlü han; Yama'nın adı. Bugünkü `Erlik` biçimi Moğolca bozulmadır, Sibirya Türkleri sonradan almıştır ([Anohin 1924, yayıncı notu](https://archive.org/details/sbornikmuzejaantropologiiietnografiit419), I.A). **[kaynak]** Yenisey mezar yazıtında "bizi Erklig ayırdı" geçer ([Atcı 2025](https://dergipark.org.tr/tr/download/article-file/4276930), Kormuşin'den). **[kaynak, ikinci el]**
- **Kaşgarlı, 1070'ler.** `Umay`: son, eş; atasözü `Umayga ogul bolur`. `Iduk`: ruhlara adanmış, sağılmayan, kırkılmayan, yük vurulmayan hayvan ([Bayat 2007](https://turkoloji.cu.edu.tr/ESKI%20TURK%20DILI/fuzuli_bayat_kasgarli_mahmut_divanu_lugatit_turk_mitolojik_dunya_modeli_kavramlar.pdf)). `Tämür qazuq`: Demirkazık, gök onun çevresinde döner ([Jiang 2026](https://bilig.yesevi.edu.tr/yonetim/icerik/makaleler/8108-published.pdf)). `Tengri`: dev görünen her şey ([Roux](https://www.encyclopedia.com/environment/encyclopedias-almanacs-transcripts-and-maps/tengri)). **[kaynak]**

## 4. Kozmoloji

### 4.1 Üç dünya

- Hun: gök, yer, atalar, ruhlar (H4). Üç kat sözü yoktur. **[kaynak]**
- Göktürk: üstte gök, altta yer, arada insan. Alt dünya sözü yazıtlarda yoktur. **[kaynak]**
- Altay: ruhlar üç küredir. Yer altı `körmös`, yer `yer-su` ya da `altay`, gök `kudai` ([Anohin 1924](https://archive.org/details/sbornikmuzejaantropologiiietnografiit419), giriş). **[kaynak]** Radloff'ta yukarıda 17, aşağıda 7 ya da 9 kat; insan ikisinin ortasındadır, iki alemin etkisi altında yaşar ([Radloff II](https://archive.org/details/aussibirienloseb02radl), s. 3). **[kaynak]**
- Gök bir çadırdır. Yıldızlar çadır örtüsünün delikleri, Ülker en kötü delik, soğuk buradan girer. Tanrılar örtüyü aralayınca göğün kapısı açılır ([Holmberg 1927](https://archive.org/details/in.ernet.dli.2015.283531), s. 336). **[kaynak]** Yurt bu yüzden küçük bir evrendir: tündük kapı, ocak yerin göbeği. **[çıkarım]** K4'ün Gök Açılır'ı ve sistemlerdeki yurt ağırlığı buna oturur.

### 4.2 Gök katları (Radloff, 19. yy)

| Kat | Kim | Not |
|---|---|---|
| 17 | Tengere Kaira Kan | Her şeyin başı, Altay'ın en yüksek adı |
| 16 | Bay Ülgen | Altın dağda altın taht; Kayra'dan çıkar |
| 9 | Kysagan Tengere | "Kudretli". Radloff savaş demez |
| 7 | Mergen Tengere, Kün Änä (Gün Ana) | "Her şeyi bilen"; güneş burada |
| 6 | Ai Ada (Ay Ata) | Radloff: "Ana" ve "Ata" adları ses uyumundandır, mitolojik anlamları yoktur |
| 5 | Kudai Yayuçı | Yaratan |
| 3 | Yayık, Mai-tärä, Süt Köl, Sürö Dağı, Yedi Kudai, cennet | Atalar burada yaşar, insanla tanrı arasında aracıdır |

Kaynak: [Radloff II](https://archive.org/details/aussibirienloseb02radl), s. 6–7. **[kaynak]** Sayılar yere göre değişir: Roux genelde yedi kat der ([Roux](https://www.encyclopedia.com/environment/encyclopedias-almanacs-transcripts-and-maps/tengri)), Anohin'de Ülgen'e yedi ya da dokuz geçit vardır, kam beşincide, Altın Kazık'ta durur, oradan kazlarla döner (Anohin I.B). **[kaynak]**

### 4.3 Demirkazık

- **Söz.** Kaşgarlı `tämür qazuq`; Uygur ve Altay `altun qazuq`; Kırgız, Başkurt `demir`; Hakas `tigir ortazı timir örgen` ([Li 2014](https://tdk.gov.tr/wp-content/uploads/2016/12/Yong-S%C5%8Fng%20LI%20-%20Some%20Star%20Names%20%C4%B1n%20the%20Modern%20Turk%C4%B1c%20Languages-I.pdf), [Jiang 2026](https://bilig.yesevi.edu.tr/yonetim/icerik/makaleler/8108-published.pdf)). **[kaynak]** `progression.md` §17.2'deki "Eski Türkçe biçim doğrulanmadı" notu kapanır.
- **Mit.** Kazak: Kazığa iki at bağlıdır, γ UMi Ak Boz At, β UMi Kök Boz At; Yedi Karakçı (Büyük Ayı) onları çalmak ister (Jiang). Eşleme çelişkilidir: Kazakça bir öğrenci derlemesi Ақбозат'ı Kochab'a (β) bağlar ([stud.kz](https://stud.kz/referat/show/82711)); Holmberg yalnız «biri ak, öteki kök boz» der, yıldız ayırmaz. Oyun Jiang'ı izler **[kaynak, çelişkili]**. Kırgız: Küçük Ayı'nın kutba yakın üç yıldızı bir «ip»tir, iki at ona bağlıdır; yedi yıldız atları kurttan korur; kurt atları öldürünce dünya biter (Holmberg s. 425). Altay: Ülker Yedi Han'ı kovalar (s. 427). **[kaynak]** Moğol Altan Gadas ve Mançu biçimleri aynı anlatıdır (Jiang). İp ve bağ görüntüsü oyunda gösterilmez, çünkü Tanhu 1'in kıl ipine yakındır; atlar yalnız döner.
- **Takvim.** Büyük Ayı'nın kuyruğu doğuya bakınca bahar, güneye yaz, batıya güz, kuzeye kış (Holmberg s. 416–417). **[kaynak]** Holmberg bunu «Orta ve Doğu Asya» der, kaynak vermez; söz Çince Heguanzi'nin 環流 bölümündeki 斗柄東指，天下皆春 cümlesidir ([Heguanzi](https://www.ctext.org/he-guan-zi)), Shiji 27 de Büyük Ayı için 建四時 der ([Shiji 27](https://zh.wikisource.org/wiki/史記/卷027)). **[kaynak]** Mete çağının Han bilgisidir; oyunda Han kişisinin ya da kâtibin ağzına yakışır, Hun ozanının değil **[çıkarım]**.
- **Gerçek gök.** MÖ 209'da kutupta parlak yıldız yoktu. Presesyon hesabı (Lieske 1977 açıları, özdevinim dahil; denetim: Polaris 2100'de 0,46°, Kochab'ın kutba en yakın geçişi MÖ 1050 dolayı 6,5°) kutba uzaklığı şöyle verir: 4 UMi 3,9° (4,8 kadir), 5 UMi 5,6° (4,3 kadir), Kochab 7,7° (2,1 kadir), Pherkad 10,9°, Polaris 12,9°. **[çıkarım]** İlk turdaki «kutupta çıplak gözle görülür yıldız yoktu, en yakını Kochab'dı» cümlesi yanlıştı: iki sönük yıldız daha yakındı. Polaris değeri Magli'nin MÖ 200 için verdiği ≈13° ile uyuşur ([Magli](https://arxiv.org/pdf/1612.05985)). Han gökbilimi 天極星'in parlak olanını Taiyi'nin evi sayar (中宮天極星，其一明者，太一常居也, [Shiji 27](https://zh.wikisource.org/wiki/史記/卷027)); o çağda bu yıldız Kochab'dır (帝, β UMi; Jiang). **[kaynak, ikinci el]** Yani Mete'nin göğünde Kazık parlak bir yıldız değil, iki atın döndüğü dönmeyen bir noktadır; Han kâtibi ise Kochab'ı kutup yıldızı sayar. Büyük Ayı bugünkünden kutba yakındı (18–29°): Hexi'de de ana kampta da hiç batmaz.
- Yakın tarihli bir makale Çince 勾陳'nin bu Türkçe sözden alındığını öne sürer (Jiang). Doğrulanmış sayılamaz. **[kaynak, tek makale]**

### 4.4 Hayat Ağacı ve Bay Terek

- **Hun çağı izi.** Dailin ağaç çevresinde dönmektir (H5). Ağaç kutsaldır, adı yoktur. **[kaynak]**
- **Altay.** Yerin göbeğinde en yüksek ağaç, dev bir köknar, Ülgen'in evine erişir; Jö Kan'ın işaretidir ([Radloff II](https://archive.org/details/aussibirienloseb02radl), s. 7). Radloff'un yaratılışında dokuz dallı ağaç, her dalın altında bir insan (s. 4). **[kaynak]**
- **Abakan ve Minusinsk.** Yerin ortasında demir dağ, üstünde yedi dallı ak huş; on iki göğü delen huş, altın yaprak, dibinde yaşam suyu teknesi. **[kaynak]** Sakha: yerin göbeğinde sekiz dallı ağaç; gövdesinden çıkan kadın ilk insana soyun atası olacağını söyler; büyük ana Kubay Hatun ağaçta oturur ([Holmberg 1927](https://archive.org/details/in.ernet.dli.2015.283531), s. 349–351, 414). **[kaynak]**
- **Tören.** Altay kamı yeni yurda dibi içeride, tepesi dumanlıktan çıkan genç huş diker, gövdesine dokuz çentik (`tapty`) açar. Yurdun kapısı doğudadır. Atı kam seçer, sırtına konan tahta kâsenin düşüşüyle sınar. Dördüncü basamakta dolunaya varır ([Radloff II](https://archive.org/details/aussibirienloseb02radl), s. 20–45). **[kaynak]** Anohin'de kurban açık renkli üç yaşında kısrak, üç, altı, dokuz ya da on iki yılda bir (I.B). **[kaynak]**
- **Bay Terek** adı için bu turda birincil kaynak açılamadı. Kaynak bulunamadı. Oğuz-name'de ikinci eş ağaç kovuğunda bulunur ([Oghuz Khagan](https://en.wikipedia.org/wiki/Oghuz_Khagan)). **[kaynak, kaynaksız bölüm]**

### 4.5 Dağ, su ve Yer-Sub

- Qilian "Gök Dağı"dır (H14), Hexi'nin dağıdır, önce Yüeçi'nin, sonra Hun'un yurdudur (始月氏居敦煌、祁連閒, [Shiji 123](https://zh.wikisource.org/wiki/史記/卷123)). **[kaynak]**
- Göktürk: kutsal Ötüken ormanı (`ıduk Ötüken yış`), kutsal Yer-Sub, ağaçsız dağ Yer Tanrısı (Zhou Shu). **[kaynak]**
- Altay: dağ ruhları ne Ülgen'e ne Erlik'e bağlıdır. Sürüyü çoğaltır, kötü ruhu kovar, saygısızlığı hastalıkla cezalandırır. Adları yerin adıdır. Hepsine `yer-su` ya da `ee` (sahip) denir ([Anohin 1924](https://archive.org/details/sbornikmuzejaantropologiiietnografiit419), I.B). Radloff: Yer-Su, kaynak başlarında oturan 17 handır; insan bunlara doğrudan sunu verir, yüksek tanrılara atası aracılığıyla ulaşır (s. 7–8). **[kaynak]**
- Dağ iznini dinlemeyen rüzgârla cezalanır; kam çocuk kutunu dağdan ister ([Polat 2020](https://dergipark.org.tr/en/download/article-file/1383030), Radloff ve Anohin'den). **[kaynak]**
- Geçitte taş yığına taş eklenir; kumaş, yün, at kılı bırakılır. Kaza olursa "yerin sahibi" yapmıştır. Sakha yol dilinde gizli sözler kullanır. Yüksek dağ yanında yüksek sesle konuşulmaz, rüzgâr gelir (Holmberg s. 457, 470–471). **[kaynak]**
- Toprağı kazmak, otu kökünden çekmek günahtır; tarla bozulunca "yerin kutu gitti" denir (Holmberg s. 459, 463). **[kaynak]**

### 4.6 Ateş ve Od Ana

- Theophylact ateşi ilk sayar; Bizans elçileri iki ateş arasından geçer; Movses ateşe sunuyu yazar. **[kaynak]** Hun çağı metninde ateş sunusu yoktur; arkeolojide ise mezar başında yakılmış hayvan kemiği vardır (§2.2, MÖ 1. yy sonu). Ateşe saygının en eski açık yazılı tanığı 6.–7. yy'dır. **[çıkarım]**
- Altay kamı ateşe "otuz başlı ana, kırk başlı kız" der. Moğol duası "Ana Ut" der, sözcük Türkçe `ot`tur. Her ocağın sahibi vardır: sunu veren evde semiz, cimri evde sıskadır. Yasak: tükürmek, suyla söndürmek, üstünden atlamak, ateşe bıçak sokmak, yanında odun yarmak. İlk lokma ve ilk kâse ateşe gider (Holmberg s. 452–454). **[kaynak]**
- Ateş gökten iner: Altay'da Ülgen ak ve kara iki taşı vurur, kıvılcım yere düşer; Yenisey'de yıldırım ağacı yakar, ilk kam insana öğretir (Holmberg s. 449–450). Anohin'in duasında Ülgen "üç ocak taşını" diker. **[kaynak]**
- Çuvaş gelin baba ocağının külünü yeni evine taşır (Holmberg s. 452). **[kaynak]** Köz Kabı (`settlement.md` §2.1) ile aynı düşüncedir. **[çıkarım]**
- `Od Ana` adı bu yazımla çağdaş derlemelerdedir; birincil tanıklık "ana ateş" ve "otuz başlı ana" biçimindedir. **[çıkarım]**

### 4.7 Kut ve ruh

- Altay `kut`: insanın ve doğanın canı. Yer kutunu yitirirse kıraçlaşır, yurt kutunu yitirirse ev olmaz (Holmberg s. 463). Anohin'in duasında kut, başın ceninidir: Ülgen `baştın kudun` yaratır. **[kaynak]**
- `Sür`: güç, görünüş, can. "Ordu sürünü yitirirse düşmanı yenemez" (Holmberg s. 463). **[kaynak]** `morale` için hazır bir sözdür. **[çıkarım]**
- `Tın`: Altay'da ipten can; Erlik'in lakabı Kayrakan burada "kesen" anlamındadır (Anohin I.A). **[kaynak]** Radloff ve Holmberg aynı sözü "merhametli" diye verir; Anohin bu çeviriye itiraz eder. **[kaynak]**
- Oyundaki Kut, Roux'nun tarifine uyar, ama dağıtan hükümdardır: Roux'da imparator herkese, insana ve hayvana, kut ve ülüg dağıtır ([Roux](https://www.encyclopedia.com/environment/encyclopedias-almanacs-transcripts-and-maps/tengri)). **[kaynak]** Hükümdarın kendi kutu Gök'ün lütfundandır (Kül Tigin, güney 9, §3). İlk turdaki «Gök hükümdara kut dağıtır» okuması düzeltildi. K4 ve `progression.md` §5 uyumludur.

## 5. Yaratılış anlatıları

### 5.1 Altay, Radloff

> Not (2026-11-07): Holmberg s. 317 taşı açıkça «stone» diye yazar; Radloff'un (`Aus Sibirien` II) OCR'ı «Stern» okur, basılı sayfa görülmedi. Radloff Kişi'yi «Mensch (Kishi)» diye yazar ve Erlik adını alanın bu «Mensch» olduğunu söyler. Oyunun yeni mit metninde (K96) taş söylenmez, yalnız görünür.

1. Her şey sudur. Tengere Kaira Kan kendine benzer bir varlık yaratır, adı Kişi. İkisi suyun üstünde iki kara kaz gibi uçar.
2. Kişi daha yükseğe çıkmak ister, gücünü yitirir, dibe düşer, yardım diler. Kaira onu çıkarır, sudan bir taş yükseltir, üstüne oturtur.
3. Kaira, Kişi'yi dibe daldırır, toprak getirtir, suya serper. Kişi bir parça toprağı kendine yer yapmak için ağzında saklar. Toprak şişer, boğulacak olur, tükürür. Düz yer bataklıkla bozulur.
4. Kaira ona Erlik adını verir, ışık aleminden sürer. Dokuz dallı ağaç bitirir, altında dokuz insan yaratır.
5. Erlik insanları ister, verilmez, baştan çıkarır. Kaira insanı kendi haline bırakır, Maytere'yi koruyucu olarak koyar, 17 kat göğü kurar.
6. Erlik izinle kendi göğünü kurar. Mandışire mızrakla parçalar, enkaz yere düşer, dağlar ve vadiler olur. Erlik en dibe sürülür.

Kaynak: [Radloff II](https://archive.org/details/aussibirienloseb02radl), s. 3–5. **[kaynak]** Kişi düşerken Kayra'yı «gütigen Himmel» (merhametli gök) diye çağırır. Adım 2'deki «taş» için archive.org OCR'ı «Stern» (yıldız) okur; basılı sayfada «Stein» (taş) olabilir, denetlenecek. Radloff ayrıca dünyayı taşıyan üç balık varyantını ve günah öyküsünü Musa etkisi diye ayırır. Kök biçim için Radloff 1866 ([Sagaster](https://www.encyclopedia.com/environment/encyclopedias-almanacs-transcripts-and-maps/erlik)'in kaynakçası) okunmadı.

### 5.2 Ötekiler

- **Verbitski.** Ülgen denizde insana benzer çamur görür, "kişi olsun" der, adını Erlik koyar ([Aça](https://dergipark.org.tr/tr/download/article-file/441175), İnan'dan; [Holmberg](https://archive.org/details/in.ernet.dli.2015.283531)). Erlik önce dost ve kardeştir. **[kaynak]**
- **Ak Ana.** Sularda yaşayan dişil ruh, yaratana "yarat" der. Türkçe aktarımlar anlatıyı Radloff'a, bazıları Verbitski'ye bağlar; aktarımlarda yaratanın adı Kara Han'dır ([Yaratılış Destanı](https://tr.wikipedia.org/wiki/Yarat%C4%B1l%C4%B1%C5%9F_Destan%C4%B1_(Altay)), [Küre](https://kureansiklopedi.com/tr/detay/turk-yaratilis-destani-radloff-derlemesi-82297)). Aus Sibirien II, Anohin 1924 ve Holmberg 1927'nin tam metinlerinde Ak Ana yoktur (metin araması, 2026-11-04). Birincil yeri bulunamadı; bakılacak yer Radloff'un 1866 Proben cildidir. Holmberg'in Süt Gölü Anası ayrı bir ögedir ve İran kökenli sayılır (s. 413–414). **[kaynak, ikinci el; birincil yer bulunamadı]**
- **Köpek.** Kudai ruh almaya gider, bedenleri köpeğe emanet eder. Erlik köpeğe altın tüy sözü verir, köpek bırakır (Holmberg s. 373). **[kaynak]**
- **Kuzgun.** Ülgen bedenleri yapar, kuzgunu ruh için Kudai'ye yollar; yolda leşe inmemeye çalışır (Anohin). **[kaynak]**
- **Sakha.** Tanrı küçük düz yeri yaratır, şeytan tekmeler, tanrı "büyü" der, dağ ve göl olur (Holmberg s. 319). Ürüng Ayıı Toyon süt beyazı tahtta oturur, ateşin babasıdır (Holmberg s. 449). **[kaynak]**
- **Tufan.** Altay'da Nama, Ülgen'in buyruğuyla gemi yapar, üç oğlu vardır, kuzgun ve güvercin yollar; adı ve sırası Kitab-ı Mukaddes'e çok yakındır (Holmberg s. 364; Aça). Kezer Çingis Kaira Han sal üstünde kurtulur. **[kaynak]** Oyunda kullanmam: en açık geç katman budur ve Mete'nin dünyasında işlevi yoktur. **[çıkarım]**
- **Erken ikilik.** Holmberg, ilk insanın düşüp ölülerin başı olmasını İran Yima anlatısına, Erlik ile tanrı kavgasını Bogomil benzerlikleriyle yan yana koyar (s. 316). Sagaster de Yima'yı anar. **[kaynak]** İyi ve kötü iki tanrı bozkırın çok eski kökü değildir. **[çıkarım]**

## 6. Tanrı ve ruh kadrosu

### 6.1 Gök

| Ad | Ne | En eski tanıklık | Oyunda |
|---|---|---|---|
| Tengri | Gök | Hanshu 94A 撐犁 (MS 1. yy, MÖ 2.–1. yy olayları) | Hun ağzındaki tek tanrı adı. Görünmez, tek sözcük (`act1.md` §3) |
| Kayra Han | En yüksek, "merhametli" | Radloff, 19. yy | Sinema: Tengri Kayra Han |
| Ülgen | Yaratan, gök gürültüsü ve yağmur | Radloff, Anohin | Altay kökenli kam sözü, Destan |
| Kızagan | "Kudretli" (Radloff) | Radloff; Moğol Kisagan Tengri savaş tanrısıdır, orduyu korur, zafer verir (Holmberg s. 406) | Savaş tanrısı oluşu Moğol tanıklığıdır, Altay'ın değil. V'te savaş kamının andığı ad olabilir **[çıkarım]** |
| Gün Ana, Ay Ata | Güneş kat 7, ay kat 6 | Radloff, adlara o da mitolojik anlam vermez | Hun çağında güneş ve ay vardır, cinsiyet ve ad yoktur |
| Yayık | Ülgen'in payı, aracı; kırmızı bulut kenarlı, gökkuşağı yularlı, şimşek kamçılı. Radloff'ta öteki adı Mai-änä; Umay'ın May-Ene adıyla bağı açık değil | Anohin, Radloff | Kam eşlikçisi. Bahar ilk sağımda ona süt ve talkan serpilir |
| Suyla | At gözlü bekçi, kam gözünde kartal; otuz günlük yol görür | Anohin | Kam eşlikçisi |
| Karakuş | Ülgen'in beşinci oğlu, kartal | Anohin; Radloff'ta kam törende Karakuş gibi davranır | Kartal simgesi |
| Karşıt, Pura, Burça | Ülgen'in oğulları, soy koruyucuları | Anohin | Soy adlarında yankı |
| Umay | Son ve doğum; savaşta yardım | Tonyukuk, 8. yy | Düşüş, beşik |
| Ak Ana | Sudaki ses | Türkçe aktarımlarda Radloff'a ya da Verbitski'ye atfen; birincil yer bulunamadı (§5.2) | Sinemada kalırsa «Ozan der» rozetiyle; kaynak satırında Radloff yazmaz |
| Ak Ayas | Ayrı tanrı değil, Ülgen'in lakabı: `ak Ayas` (ak aydınlık), `Ayas Kan` | Anohin | Ozan söz öbeği. Yazım `Ayas`: «Ayaz» Tanhu 1'de atın adıdır |

Kaynak: [Radloff II](https://archive.org/details/aussibirienloseb02radl), [Anohin 1924](https://archive.org/details/sbornikmuzejaantropologiiietnografiit419). **[kaynak]**

### 6.2 Yer ve iyeler

| Ad | Ne | Tanıklık | Oyunda |
|---|---|---|---|
| Yer-Sub | Yer ve su bütünü | Orhun, 8. yy; H4 地 kökü | Keşif, toprak |
| Altay Kan, Jö Kan, Talay Kan | 17 Yer-Su hanından üçü; Talay, deniz ve ölüler | Radloff | Yer adlarında |
| Yol Tengrisi | Benekli atlı, onaran | Irk Bitig, 9. yy; Movses "yol tanrıları" | Yol Kemikleri, Menzil |
| Bayanay | Sakha'da orman ve av sahibi; Bay Bayanay | Holmberg s. 466–467 | Av Payı |
| Payana, Bay-Ene | Altay-Sayan koruyucuları; Kaşgarlı'da Argu ile anılır, Umay ile de karışır | Bayat, Kayabaşı | Bayanay'ın eski yankısı olabilir, **[çıkarım]** |
| Od Ana | Ocak ateşi | Holmberg s. 452–455 | Ateş |
| Su iyesi, su boğası | Her suyun sahibi; fırtına öncesi böğüren, buzu kıran boğa | Holmberg s. 469–470 | Hava işareti |
| Dağ iyesi | Rüzgârı tutar; Moğolda fırtına "koşan günler" | Holmberg s. 457 | Hava işareti |
| Bozkır iyesi | Geceleyin yalancı ışık yakar, yoldan çıkarır (Moğol Albin) | Holmberg s. 468 | Saz Tüneli, gece |
| Çalgı iyesi | Buryat Huri Ecin: üç yol ağzında at kafatası üstünde çalana hüner verir | Holmberg s. 465 | Ozanın öyküsü |
| Demirci iyesi | Körükte baş iye; Boşintoy'un dokuz oğlu | Holmberg s. 464 | Demir Diş, Demirci Ocağı |
| Yel Ana | Rüzgâr anası | Kaynak bulunamadı; yalnız soru-cevap ve forum sayfaları | Kullanma; dağ iyesi ve boz boğa nefesi (Holmberg s. 457) yeter |

### 6.3 Alt dünya

| Ad | Ne | Tanıklık | Oyunda |
|---|---|---|---|
| Erlik | Bkz. §6.4 | Sözcük 8. yy; figür Uygur ve 19. yy | K4 |
| Oğulları | 7 ya da 9: Bay Mattır (taş bilekli), Karaş (yılanlı), Kerey Kan (bakır bilekli), Uçar Kan, Yabaş, Kömür Kan, Temir Kan, Şıngay, Padış | Anohin I.A; Atcı | Bkz. öneri 3 |
| Kızları | 2 (Sekiz Gözlü Kiştey, Erke Solton) ya da 9 "kara kız". Kamı yoldan çıkarır, kapılan kam ölür | Anohin I.A | Kam öyküsü, sahnede cinsellik yok |
| Körmös, Etkär, Yaman Üsüt | Alt dünya kalabalığı | Radloff s. 10 | Ozan dili |
| Yek, Aza | Yeryüzüne saçılmış kötü ruhlar; obur olanlar | Anohin I.A, I.B | Hun hastalık sözü |
| Abası, Arsan Duolay | Sakha ruhları ve ölüler hükümdarı; ağzı alnında | Holmberg s. 486 | Kuzey Dingling'de yankı |
| Al Karısı, Albastı | Doğum yapanı boğan kadın. Kırgız-Kazak'ta kara ve sarı; kara olan yalnız ocaklıdan korkar | Holmberg s. 468; [Polat 2020](https://dergipark.org.tr/en/download/article-file/1383030), İnan'dan | Umay'ın karşıtı, geç ve halk inancı |

`Yek` sözünün Sanskrit `yakşa`dan Budist yolla geldiğini biliyorum ama bu turda kaynak açamadım; kaynak bulunamadı. Al Karısı'nın kökeni de açık değildir: İnan "al"ı ateşle bağlar, Umay'dan bozulmuş olabileceğini söyleyenler vardır, boncuk ikisinin ortak ögesidir ([Kayabaşı](https://dergipark.org.tr/en/download/article-file/3173462), [Park 2024](https://dergipark.org.tr/en/download/article-file/4169511)). **[kaynak, tartışmalı]**

### 6.4 Erlik, ayrıntı

Bu bilgiler [Anohin 1924](https://archive.org/details/sbornikmuzejaantropologiiietnografiit419), I.A'dan ve 20. yy başı Altay'ındandır. **[kaynak]**

- **Korku.** Adı söylenmez. Yerine `Kara Nama` (kara nesne) denir.
- **Hile.** Korkulsa da kandırılır. Duanın özeti: sunu verilsin, başım sağ kalsın; üç yıl rahat yaşarsam yine sunu gelir.
- **Kurban.** Zayıf, hatta hasta hayvan. Post alınır, direğe asılmaz. Sunak eğri eski sopadan, kuzey yanda, çit dibinde, çöp atılan yerde. Yabani gül, alıç ya da yalancı iğde yanına kurulur, çünkü onlardan korkar.
- **Evdeki yeri.** Yurtta kapının solu, bulaşık suyu köşesi. Karaş'a siyah bez üstünde dokuz şerit asılır.
- **Boy.** Kara kaş, dizine dek çatal sakal, dişe benzer bıyık. Kara kayıkla, kara yorgayla ya da alnı akıtmalı boğayla gezer. Kırmızı yiyecek yer.
- **Yer.** Kara çamurdan ya da kara demirden saray, dokuz nehrin birleştiği yer. Nehir `Toybodım` ("doymadım"), insan gözyaşıyla akar. Üstünde at kılından köprü. Kaçan kopar, nehir onu geri getirir.
- **İş.** Kişiyi öldürür, canını alır, yargılar, kendine çalıştırır. Öteki Radloff'ta: yine de "Baba Erlik" denir, çünkü hepimiz ona varırız.

`act1.md` §3'teki oturan, aşık oynayan, sabırlı Erlik bu anlatıya uyar: kaynak korkuyu, kandırmayı ve vadeli sunuyu verir. «Tüccar» benzetmesi kaynakta yoktur; Tanhu 1'in Erlik ses tarifindeki «merchant of souls» sözüne denk düşer, bu yüzden oyun metninde ve ses tarifinde kullanılmaz **[çıkarım]**. Yüzü Teoman'ın yüzüdür; bu **[kurgu]**. Yama'nın aynası ve taşları ise hem geçtir hem Tanhu 1 aynasına yakındır; alınmaz. Anohin'in metni doğrulama turunda yeniden okundu: Kara Nama, Toybodım, kıl köprü ve görünüş (boynuzları ağaç kökü gibi) birebir oradadır; Sagaster de alt dünyada gözyaşı gölünü ve tek kıldan köprüyü anar ([Sagaster](https://www.encyclopedia.com/environment/encyclopedias-almanacs-transcripts-and-maps/erlik)). **[kaynak]**

### 6.5 Kam

- **Hun.** 胡巫 vardır, hükümdarın yanındadır, ölü Tanhu adına konuşur, kurban ister (H10). Savaşta yolları lanetler (H11). Davul tanıklığı yoktur. **[kaynak]**
- **Sözcük.** Holmberg: Altay `kam`, Sakha `oyun`, Moğol `bo`, Tunguz `şaman`; ad Rus etnografyasıyla yayılmıştır (s. 496). `Şaman` sözcüğü oyunda kullanılmaz. **[kaynak; karar çıkarım]**
- **Sınır.** Roux: kam Gök'e hükümdardan yakın olduğunu iddia ederse yok edilir. **[kaynak]** Bu Türk-Moğol geneli bir kuraldır; Roux'nun andığı örnek Moğol çağıdır (Teb Tenggeri), Hun tanıklığı değildir. H10 bunun tersini de gösterir: kam siyasetin aracıdır. **[çıkarım]**
- **Kapı.** Ülgen yolu yalnız erkek kama açıktır; kadın kamlar vardır, soyları sayılır (Anohin I.B ve kam soyları). Ülgen sunusuna yalnız erkekler girer; yemeğe kızlar yerinde, kadınlar uzakta katılır (Radloff s. 11 dolayı). **[kaynak]**

## 7. Hayvan simgeleri

| Hayvan | Ne | Çağ | Oyunda |
|---|---|---|---|
| Kurt | Usun bebeğini emzirir (H12), Gaoçe atası (H13), Aşina atası (Zhou Shu), Bugut, Oğuz'un gök kurdu | MÖ 2. yy, 6. yy, 14. yy | Bebek öyküsü VI. Perde; doğumda kurt yok (Tanhu 1) |
| Karga, kuzgun | Bebeğe et getirir (H12); ruh taşır (Anohin); göğe dua eder (Irk Bitig 54) | MÖ 2. yy, 9. yy, 20. yy | `crow`, ozan satırı |
| Kartal | Aluchaideng tacı; Irk Bitig 3; Karakuş; Suyla; Oğuz ongonları | MÖ 4.–3. yy, 9. yy, sonra | Avlu'nun tören tacı, `eagle_shooter`. Teoman'ın başlığına konmaz: Tanhu 1'de Tuman'ın kürk başlığında altın kartal vardı |
| Toğrul | Oğuz ongon listesinde çıkmadı ([Oghuz Turks](https://en.wikipedia.org/wiki/Oghuz_Turks); tablonun ongon sütunu kaynaksızdır) | Kaynak bulunamadı | Kullanma, Sungur ve Bürgüt var |
| Geyik | Geyik taşları MÖ 1200–600; Ostyak'ta Büyük Ayı geyiktir (Holmberg s. 417) | Hun öncesi | Eski anıtlar; Bugu Ana için kaynak bulunamadı |
| At | Ülgen'e sunulur; 千里馬; Ak Boz, Kök Boz | Hepsi | Bkz. öneri 21 |
| Tülpar | Kanatlı at; Kazak ve Kırgız; en eski tanıklık yok, kaynak zayıf ([Tulpar](https://en.wikipedia.org/wiki/Tulpar)) | Geç | Ozan, Tunghu'nun istediği bin li'lik ata (千里馬) söyler **[kurgu]**. «Bin Li At» Tanhu 1'in III. Perde adıdır, özel ad olarak yazılmaz |
| Boğa | Erlik'in binek ve kurbanı; su boğası; boz boğa rüzgârı | 20. yy | Kurban ve hava |
| Köpek | Erlik'e kanar (Holmberg); ölünün ruhunu Kızıl Dağ'a götürür ([Hou Hanshu 90](https://zh.wikisource.org/wiki/後漢書/卷90)) | MS 2. yy | Ku, III. Perde |
| Deve | Hun çağı toplantısında yarış (H6) | MS 1. yy | Ek istek |
| Iduk | Ruhlara adanmış, dokunulmaz hayvan (Kaşgarlı) | 11. yy | Adak Aygırı |

Oğuz boylarının ongon kuşları: Kayı sungur, Bayat puhu, Salur bürgüt, Bayındır laçın vb. Tablo Reşidüddin'e burada bağlanmaz ([Oghuz Turks](https://en.wikipedia.org/wiki/Oghuz_Turks)). **[kaynak, ikinci el]**

## 8. Türeyiş ve göç destanları

- **Oğuz Kağan.** Uygur yazılı nüsha 13.–15. yy ([Jiang 2026](https://bilig.yesevi.edu.tr/yonetim/icerik/makaleler/8108-published.pdf)). Gökten inen ışıkta bir eş, ağaçta bir eş; Gün, Ay, Yıldız ve Gök, Dağ, Deniz oğulları; gök kurt ordunun önünde ([Oghuz Khagan](https://en.wikipedia.org/wiki/Oghuz_Khagan)). **[kaynak, Vikipedi bu bölümü kaynaksız işaretler]**
- **Mete ile Oğuz.** Özdeşliği Bichurin önermiştir: baba katli ve fetih sırası benzer (aynı sayfa). Karşı görüş yalnız baba katline dayandığını söyler, Saka'ya bağlar ([Şengül 2026](https://dergipark.org.tr/en/download/article-file/5198629)). **[kaynak]** Oyun Mete'ye "Oğuz" demez, ozan bir kez benzetebilir. Tanhu 1'in "Oğuz sonu" alınmaz. **[çıkarım]**
- **Ergenekon.** En eski yazılı biçim Reşidüddin, 14. yy, Moğol ataları Nüküz ve Kıyan ([Zoriktuev](https://www.sciencedirect.com/science/article/abs/pii/S1563011015001555), [Ergenekon çalışması](https://www.academia.edu/176458926/A_Name_Without_an_Organization_Ergenekon_from_Rash%C4%ABd_al_D%C4%ABns_Valley_to_the_Silivri_Courtroom_c_1307_2019)). Kurdun yol göstermesi Ziya Gökalp'in 1913 şiirindendir diyen çalışma vardır, öteki siteler karşı çıkar. **[kaynak, tartışmalı]** Eski öz ayrıdır: Zhou Shu'da Aşina kurdu dağ içi ovaya sığınır, torunlar Rouran'ın demircisi olur (為茹茹鐵工). **[kaynak]**
- **Alp Er Tunga.** Kaşgarlı'nın ağıtı ve İran Afrasiyab'ı; bu turda metin açılamadı. Kaynak bulunamadı, bilgi bellekten.
- **Dede Korkut.** Dresden ve Vatikan nüshaları 16. yy, Günbed üçüncü nüsha; yazıya geçiş 14.–15. yy; Tepegöz 14. yy başında bilinir ([Book of Dede Korkut](https://en.wikipedia.org/wiki/Book_of_Dede_Korkut)). **[kaynak]** Deli Dumrul: birisi yerine ölmeyi kabul ederse Dumrul yaşar. `erlik_choice=name` ile aynı düğüm. **[çıkarım]**
- **Manas.** En eski yazılı anış 1792 tarihli Farsça yazmadır (Majmu at-tavarikh; Tagirdzhanov 1960); Hatto bu anışı büyük olasılıkla 18. yy sonu eklemesi sayar; ilk derlemeler Valihanov ve Radloff, 19. yy ([Epic of Manas](https://en.wikipedia.org/wiki/Epic_of_Manas)). **[kaynak, ikinci el]** Kırk yoldaş iyi motiftir. Doğduğu gün doğan tay kullanılmaz: Tanhu 1'de Motun'la aynı gece doğan tay (Kaşka) vardır. Er Töştük ve Alp Kara Kuş için kaynak bulunamadı.
- **Altay destanları.** Maaday Kara, Alıp Manaş; alt dünya yolculuğu ortak. Doğrudan metin okunmadı ([Atcı 2025](https://dergipark.org.tr/tr/download/article-file/4276930) kaynakçası).
- **Sakha olonho.** Kaynak açılamadı. Ad kullanılmaz.

## 9. Cenaze, yas, kurban ve saçı

**Hun çağı.** Tabut, altın, kürk; höyük ağacı ve yas giysisi yok; yakınlar ölüyle gider, sayı Shiji'de binlerce, Hanshu'da onlarca-yüzlerce (數十百人). Mezar sözü 逗落. Kazı: kare ve halka mezar, taş sırası, yanmış kemik, güneş ve ay çifti. Düşeni getiren malını alır (戰而扶輿死者,盡得死者家財). **[kaynak]** `carry_fallen` buna dayanır.

**Göktürk.** Çadır önüne at ve koyun dizilir; yedi kez çadır çevresinde at sürülür; yüz kesilir; beden yakılır; ot sararınca ya da çiçek açınca gömülür; mezara ölünün öldürdüğü kadar taş dikilir; kurban başları direğe asılır ([Zhou Shu 50](https://zh.wikisource.org/wiki/周書/卷50)). Yazıtta `yoğ`, `sığıt`, `balbal`. **[kaynak]**

**Tung-hu kolu.** Vuhuan savaşta ölmeyi yüceltir, gömerken şarkı söyler, atı ve eşyayı yakar, süslü köpek ruhu Kızıl Dağ'a götürür. Gök, yer, ay, yıldız, dağ ve ırmak sunusu; sunu yakılır ([Hou Hanshu 90](https://zh.wikisource.org/wiki/後漢書/卷90)). **[kaynak]**

**Geyik taşı ve kurgan.** Geyik taşları MÖ 1200–600, hirigsurlarla birlikte, Moğolistan ve komşuları ([UNESCO](https://whc.unesco.org/en/list/1621/), [Smithsonian çalışması](https://repository.si.edu/bitstreams/62c880a2-ca22-40b9-be96-43aa35d2a606/download)). **[kaynak]** Hexi için kayıt görmedim. **[çıkarım]** Kurgan yapan Saka'dır: Issyk, MÖ 4.–3. yy ([Issyk](https://en.wikipedia.org/wiki/Issyk_kurgan)). **[kaynak]**

**Kurban.** Hun: 祠, beyaz at, gömülü koyun ve sığır, hatta insan (H9–H11). Gaoçe: büyük göğe sunuda at koşusu ve kesim, çevrede dönerek şarkı (大會,走馬殺牲,遊遶歌吟, [Wei Shu 103](https://zh.wikisource.org/wiki/魏書/卷103)). Altay: üç yaşında kısrak, uzun tören. Sakha: bahar şöleninde kımız ateşe dökülür, Yedi Tanrı içindir (Holmberg s. 402). Moğol: Marco Polo'da süt ve kımız saçısı (Holmberg s. 460). **[kaynak]** Süt içkisi Hun çağında vardır (湩酪, Shiji 110), saçı tanıklığı yoktur. **[çıkarım]**

**Saçı.** Altay'da baharda ilk kısrak sağımında Yayık'a süt ve talkan serpilir; Suyla'ya içki; Karlık'a tündükten kaşıkla su (Anohin I.B). **[kaynak]**

## 10. Yerel inanç farkları

- **Yüeçi.** Shiji: Hun'la aynı töre (行國,隨畜移徙,與匈奴同俗). Kendi inançlarından yazılı bir şey yok. Sanjiaocheng'de sunu çukurları (`groups-research.md` §5). Kuşan tanrıları Nana, Athşo, Ardokşo, Miiro, Mao 1.–3. yy Baktriya'sınındır, Avesta adlarıyla Yunan biçimlerinin karışımıdır ([Yale](https://macmillan.yale.edu/southasia/pantheon-rediscovered-south-asian-studies-yale-university-0)). **[kaynak]** Kışlak'ın ateş bekçisi ve Adak Aygırı bu yüzden tasarımdır. Erlik'i bilmezler. **[çıkarım]**
- **Saka.** Massagetler yalnız güneşe tapar, en hızlısına en hızlısını diye at sunar ([Hdt. 1.216](https://www.perseus.tufts.edu/hopper/text?doc=Perseus:text:1999.01.0126:book=1:chapter=216)). İskitlerde kılıç sunağı ([Hdt. 4.62](https://www.perseus.tufts.edu/hopper/text?doc=Perseus:text:1999.01.0126:book=4:chapter=62)). Issyk'te kaplan, geyik, at, kanatlı leopar. **[kaynak]** K8'e göre I. Perde'de Saka yok; sonda ve `akinakes`te yankı.
- **Çiang.** Atası Wuyi Yuanjian: Qin kölesi, kaçar, mağaraya saklanır; Qin ateşe verir, kaplana benzer bir gölge onu korur, yanmaz, halk onu başa geçirir, tarım ve sürü öğretir ([Hou Hanshu 87](https://zh.wikisource.org/wiki/後漢書/卷87)). Savaşta ölmek kutlu, hastalıkta ölmek uğursuz. Tutsaklar bağlanmaktan değil yakılmamaktan korkar ([Xunzi](https://zh.wikisource.org/wiki/荀子/大略篇)). Beyaz taş ve Mubyasei 20. yy tanıklığıdır ([Qiang folk religion](https://en.wikipedia.org/wiki/Qiang_folk_religion)). **[kaynak]**
- **Han ve Qin.** Hükümdar Göğün Oğlu. Qin'de Yong'da dört sunak; Liu Bang MÖ 205'te beşinciyi, Kara İmparator'u ekler. Sarayda Liang, Jin, Qin, Jing kamları ve 九天巫 ([Shiji 28](https://zh.wikisource.org/wiki/史記/卷028)). Han generali MÖ 119'da Hun dağı Langjuxu'da kendi sunusunu yapar ([Shiji 111](https://zh.wikisource.org/wiki/史記/卷111)). Irk Bitig'in ilk falı `Ten-si`dir. **[kaynak]**
- **Tung-hu ve Xianbei.** §9. Söğüt halkası H5. **[kaynak]**
- **Dingling, Gaoçe.** Kurt soyu (H13); deve ve at; tekerlekli yüksek araba. **[kaynak]**

## Oyuna öneriler

Hepsi önerilidir; sahibi belgeler işler. Kişi ve yer adları `story.md`'nindir. Yeni beceri yoktur (93 beceri korunur), yeni ışık ve program yoktur (K22). Öneriler önce Three.js prototipinin yollarıyla yazıldı (`src/...`); oyun Godot 4.7'dedir (`d3/brief.md`), karşılıkları bu bölümün sonundaki «Godot için» alt bölümündedir.

**K4 ve K13 uyumu.** K4'ün Adak Aygırı, Gök Açılır, Kül Borcu biçimi ve Keçe Avlusu eyeri değişmez. K13: Tengri, Erlik, Umay ve öteki mitoloji kurgu listesine girmez; önerilen yeni kişiler (kamlar) girer; Kara Yol ve Kıl Köprü gibi tasarım araçları girmez, `tasarım tercihi` diye işaretlenir.

**1. Çağ etiketi (#8, #9).** Destan Kitabı'na yeni bölüm (Godot: `scripts/ui/destan_kitabi.gd` ve `data/mitler.json`; prototipte `src/data/destan.js` `CHAPTERS`): gruplar Gök, Yer, Alt, Hayvan, Destan; en çok 24 girdi, alan `age: hun | turk | late | game`. Rozet: «Yıllıktan», «Taştan», «Ozan der», «Bizim». K13 değişmez: bu liste kurgu listesi değildir. Ana kampta oyuncu ateş başında ozanı 5 sn dinleyince bir girdi açılır (saat gelince günde 1). Aynı işte Destan Kitabı'nın bütün `dombra`, `dombıra` sözleri kopuza döner (#55). Tek yazım: Tengri, Kayra Han, Ülgen, Erlik, Kara Nama, Umay, Yer-Sub, Od Ana, Bayanay, kam, Demirkazık. Hun ağzında "Tanrı" değil "Tengri". "Şaman" yok.

**2. Giriş sineması, sahne sırası (#8, #1, #55, Karar 5 ve 6).** Tamamen sinematik, Esc her an atlar, ikinci oyunda varsayılan atlanır. Metin yazılmaz, sıra verilir. Mit görüntüleri keçe aplike panodur (Noin-Ula, Pazyryk keçesi havasında), ateş dumanından çıkar. Kodla çizilir, boyalı süzgeç keçeyi sever. **[kurgu]**

| # | Süre | Ne olur | Çağ ve kaynak | Ses (`audio.md`) |
|---|---|---|---|---|
| 0 | 30 sn | Ana kamp, gece. Ozanın yüzü (K19), Çocuk ateş başında. "Kimi böyle der" çerçevesi | Oyun | Yalnız kopuz |
| 1 | 20 sn | Duman su olur. Yalnız su, iki kara kaz: Tengri Kayra Han ve Kişi | Radloff | Kopuz, dron |
| 2 | 15 sn | Kişi yükselmek ister, düşer, Kayra'ya yardım diye seslenir. Sudan taş çıkar. İsteğe bağlı: sudan bir kadın sesi, Ak Ana | Radloff; Ak Ana Türkçe aktarımdandır, birincil yeri bulunamadı (§5.2) | Tek kısık ses |
| 3 | 30 sn | Dalış, toprak, ağızda saklama, şişme, tükürme, bataklık. Adı Erlik. Yüzü yok | Radloff | `erlik`, E Frigyen |
| 4 | 30 sn | Yer yayılır. Dokuz dallı ağaç, dokuz insan. Gök çadır gibi gerilir, tündük Demirkazık'a bakar, iki at onun çevresinde döner (ip görünmez). Üstte gök, altta yer, arada insan | Radloff, Holmberg s. 336 ve 425, Kaşgarlı, Orhun | `tengri`, açık beşli |
| 5 | 25 sn | Erlik insanı ister. İlk ölüm. Toybodım ve kıl köprü bir kare. Ak ve kara taş, ilk kıvılcım, üç ocak taşı | Radloff, Anohin, Holmberg s. 449–450 | `erlik`, sonra kopuz |
| 6 | 25 sn | Doğum yurdu. Umay görünmez ve konuşmaz: yalnız eşin (son) gömülüşü ve beşiğe asılı küçük ok-yay. Görü, kapı, kuş yok. Dışarıda Al Karısı'nın gölgesi, ocak taşında durur | Orhun, Kaşgarlı, halk inancı | Ninni yok, nefes ve kopuz |
| 7 | 30 sn | MÖ 234 (#1). Tanhu Teoman şafakta çıkar, doğan güne eğilir. O şafak yurtta oğlu doğar. Anlatı ozandan kâtibe geçer | Shiji 110, Hanshu 94A | Tek uzun nota |
| 8 | 10 sn | Geçiş: keçe panoda koyuna binen çocuk belirir, pano açılır, oyuncu Çocukluk'ta (Koyun Sırtında) denetimi alır. Koyun, oyuncak yay, kuş ve fare oynanır, sinemada gösterilmez (兒能騎羊,引弓射鳥鼠) | Shiji 110; `d3/brief.md` | Kopuz, hız artar |

Toplam ≈215 sn. Brife göre Önsöz tamamen sinemadır, Çocukluk oynanır; ilk turdaki 25 sn'lik koyun sahnesi bu yüzden 10 sn'lik geçişe döndü. `act0-text.md`'nin anlatıcı bölümü (Qin, Tung-hu, Yüeçi, rehine) Çocukluk'tan sonra, I. Perde'den önce gelir; bu kısmı `story.md` yeniden yazar. Mete keçe panoda görünür, ana kampta değil (K6). **Sinemada kullanılmaz (Tanhu 1):** doğumda kurt ulumaları, görü taşları, Umay'ın görüsü, altın kapısı ve kuşu, ayna ve çatlaması, ip, aynı gece doğan tay, duvar-ateş sözü, ana duası seçimi, yaz gecesi doğumu. Tanhu 1'in önsözü bir yaz gecesinde kurt ulumasıyla ve Umay'ın görüsüyle geçer; bu sinema sudan başlar, şafakta biter, kurt ve görü içermez. Babanın ihaneti söylenmez. Kül Borcu ve Kara Yol söylenmez.

**3. Erlik'in adı (#8, K4).** Hun kişileri (Hereka, Uldın, Berik, sonra hane) `Erlik` demez, `Kara Nama` / `the Black Thing` der. Adı yalnız ozan, kam ve Erlik'in kendisi söyler. Yüeçi kişiler bilmez. Çukur'un kuzey çitinde, çöplük yanında bir dikenli çalı, siyah bez, dokuz şerit (1 çizim, süs). Korku ≥18 Erlik'in Yolu kartında (`progression.md` §5.2) her kullanımda dokuz oğuldan biri anılır: yalnız metin. Kara Nama'ya sunu verecek kişi zayıf hayvan verir, satır olarak geçer. Kaynaklar: §6.4.

**4. Kül Ödemesi (#8, #20, K4, K23).** K4'ün borcu "söndürülen ocak kadar kül"dür ama ödeme yolu yoktur. Altay duasındaki vade fikri ve K23 hanesiyle birleşir: `debt_erlik=ash` iken yerleşimde yanan her 5 yeni hane ocağı `hearths_out` −1, perde başına en çok 2, tabanı 0. En yüksek Can cezası (`−min(15, 5 + hearths_out)`, `act1.md` §8.5) yeniden okunur. Erlik'in Yolu yine +1 yazar. Ozan söz öbeği: üç yıl vade **[kurgu]**. K4 ile çelişmez, onu tamamlar. Sahibi `progression.md` §5.3 ve `settlement.md` §5.

**5. VI. Perde'de terazi yerine Kıl Köprü (#20, #5).** `act1.md` §16'da `debt_erlik` VI. Perde'de "terazi"ye gider; Tanhu 1'in "antların terazisi", Tamag ve Yer Beyi'ne fazla yakındır, register kural 1'e aykırıdır. Yerine: Toybodım üstünde at kılından köprü, boy 24 m, en `max(0,4; 2,0 − 0,1 × hearths_out)` m. Düşen ölmez, nehir geri getirir (Düşüş sayılmaz). Dövüş yok. `act1.md` §16 satırı ve `story.md` VI. Perde değişir. **[kurgu, Anohin motifi; Sagaster de tek kıldan köprüyü anar]** Tanhu 1'e yapısal yakınlık kalır: onun VI. Perdesi de alt dünyada geçer (Umay ülkesi, Tamag). Bu yüzden köprü tek sahnelik bir geçiştir, alt dünya bölümü olmaz; köprüde ip, bağ ya da ip kesme görüntüsü yoktur (Tanhu 1'in kıl ipi).

**6. Umay ve Düşüş (#8).** Tonyukuk Umay'ı savaşta anar, bu yüzden Umay Eşiği yalnız ana ruhu değildir: kaynağa yakındır. `progression.md` §8.5 sayıları değişmez. Görsel: uyanınca başucunda küçük ok ve yay (kız kişide ak bez ve boncuk; [Kayabaşı](https://dergipark.org.tr/en/download/article-file/3173462)). İlk Düşüş kartı: tek söz, Umay. 2 çizim, süs. Altın ışık kalır; kapı ve kuş yok. Hereka ebedir, `sq_fever`de "eş gömülür" bilgisini verir ([Bilgiç](https://dergipark.org.tr/en/download/article-file/2997890)).

**7. Al Karısı (#38, #21).** Yalnız yerleşimde, perde başına en çok 1 olay: «Loğusa boğuluyor». Seçenek: ocak taşı başına getir (Kut yok, hane Gönül +3, o hane 1 gün yarım iş), Otacı'yı çağır (IV+, Gönül +5, iş kaybı yok), geç (Gönül −5). Canavar görünmez, gölge ve nefes. **[kurgu]** Hane sistemi: `settlement.md` §5.

**8. Bayanay ve Av Payı (#8, ek istek, `survival.md` §4).** Sakha'nın avcısı ilk ganimetten pay verir (Holmberg s. 467). Yüzdükten sonra `E` basılı 2 sn «Pay Bırak»: 1 `meat_small` ya da 1 `fat`, bölge başına günde 1. Etki: o bölgede o gün hayvan algısı ×0,9, sonraki şafak geri gelme %30 → %35. Bir günde stoğun %30'undan fazlası vurulursa (`economy.md` sürdürülebilir av) «Yer küstü»: 2 şafak %15; Mene, Atşo ya da kam uyarır. Yavrulu sürü Korku +1 kuralı aynı. Kut vermez (`progression.md` §5.1). Ayının adı anılmaz (Holmberg s. 469); kişiler "Yaşlı" der **[kurgu]**. `tools/econ-sim.mjs` ile sınanır.

**9. Od Ana ve ateş (#23, #25, #46, `survival.md` §2).** (a) `F` su ya da kar: 1 sn, söner, buhar görünür, `cold_pit` ertesi şafak kaybolur (bugünkü kural). (b) Yeni: Kor evresinde `F` basılı 2 sn «Küle Yatır»: ışık 0, duman yok, `cold_pit.banked=true`; ertesi şafağa dek 1 odunla kavsız yanar. Ana'nın kitaptaki tarifi budur (prototipte `destan.js`; Godot'un `data/kisiler.json` `ana` kaydında bu satır yoktur, eklenir). (c) Ocağa Pay: tarif çemberinde seçenek, Tokluk −%10, o ateşin o günkü yakıt tüketimi ×0,9. (d) Hun kişisi ateşe tükürene, üstünden atlayana bir satır söyler, ceza yok. (e) «Üç Ocak Yeri» adı Anohin'in üç ocak taşına dayanır. (f) Köz Kabı satırı: «Ateş başka ateşten doğar» kalır.

**10. Yer-Sub ve Taş Yığını (#8, #14, `travel.md` §9.3, §9.6).** 75.000 km²'de keşif durağı türü: `cairn` «Taş Yığını / Cairn», harita başına 2–4, geçitte ve su başında (`travel.md` 3–8 keşif durağının içinden). `E` 2 sn: 1 `stone` ya da 1 `hair`. Etki: o seferde yol olayı %25 → %20, yığın başına bir kez. Ceza yok, ozan satırı var. İlk varış XP bugünkü `atlas_node` kuralıyla. `land_root` metnine `yir sub idisiz` yankısı. Tarlada ve aşırı otlakta «yerin kutu gitti» satırı (#41).

**11. Yol Tengrisi (#8, `act1.md` §4, `travel.md` §9.6).** Yol Kemikleri Yüeçi işidir, sayılar aynı. Ama direk onarınca Hun kişisi (Hereka, Uldın) bir kez yaşlı yol tanrısının kırılanı onardığını söyler. Destan girdisi `road_god`, `road_sung` ile açılır, rozet `turk`. II. Perde'den yol olayı `ev_road_god` «Benekli Atlı / The Dappled Rider», perdede bir kez, atlas kartı, sahne yok: Selam Ver (o seferde `ev_lame` ve `ev_well` çıkmaz) ya da Geç. **[kurgu]** Ana kampa at eklenmez (K3).

**12. Demirkazık ve gece yön bulma (#8, #12, `time.md` §5.6, `weather.md` §7.5).** (a) `iron_stake` metni: "yerinden oynamayan yıldızı" yerine "gökte dönmeyen noktayı" (`northMark` aynı). (b) Gök kubbesi (Godot: `shaders/sky.gdshader`; prototipte `src/world/sky.js`): adlı dokuz yıldız (Ak Boz At, Kök Boz At, Yedi Karakçı) gölgelendirici dizisi, yıldız açısıyla göğün kutbu çevresinde döner. Kutba uzaklık Kök Boz At 7,7°, Ak Boz At 10,9°, Yedi Karakçı 18–29°. Bir tur bir yıldız günüdür (23 sa 56 dk oyun saati, ≈60 gerçek dk). Yeni gölgelendirici yok; menü karesi değişmez. (c) Kazık çizilmez. Görülen şey iki atın döndüğü dönmeyen noktadır; sönük 4 UMi ve 5 UMi çizilmeyebilir, metin «yıldızsız» demez. K4'ün yıldız halkası yasağı bozulmaz. (d) Gök görmek için yeni tuş yok. İlk turdaki «Dinlen'de eğim 14°'ye kalkar» çözümü göğü göstermez: 14° aşağı bakan, 41,76° dikey görüşlü kamera ufkun ancak 7° üstünü görür, kutup ise enlem kadar yüksektedir (Hexi'de ≈39°, ana kampta 47°). Yerine gece ateş başı Dinlen'in ilk kullanımında 6 sn'lik «Göğe Bak» çekimi: kamera kuzeye döner, 40° yukarı bakar, sonra seçilen açıya döner (K27 açısı bekler). Bakış Noktası aynı çekimi kullanır. (e) Kut ≥6 Tipi `gap`'i (`act1.md` §10) iki atı aynı çekimle gösterir: ev kuzeydedir. (f) Kuyruk yönü mevsimi söyler: Defter'e satır, sayaç değil (#19). Söz Han kaynaklıdır (Heguanzi, Shiji 27); Han kişisi ya da kâtip söyler. Kaynak §4.3.

**13. İye inançları ve hava (#8, #16, `weather.md` §7.3, §7.6).** Altı kişi satırı, durum etkisi yok, Hun ve Altay ağzı: buz çatlarken su boğası (Buz Kolu, R2); fırtınadan 1 sa önce göl boğası; "dağ iyesi koşuyor" (fırtına); Ülker'in deliği (kar, soğuk yok K1); geçitte alçak ses; saz tünelinde yalancı ışık (bozkır iyesi, R4). Bir yeni efekt: `lake_bull`, göllü dünyada `far_rain` kanalına eklenir, K12 sınırı içinde. Yıldırım: Gök Direği alameti (`settlement.md` §12.4) Movses ile desteklenir; kural değişmez.

**14. Kam (#38, #21, `settlement.md` §12.3).** Üç rol, kişi adları `story.md`'de, kurgu listesine girer (K13). `kam_court`: II–III, Teoman'ın kamı, "ölü Tanhu kızgın" der (H10), Mete bu dili sonra kendi kullanır ya da susturur. Tanhu 1'in Kam Bögü'sünden ayrılır: doğumda kehanet söylemez; baykuş tüyü başlık, gök boyalı tüngür ve demir çıngırak taşımaz. `kam_field`: V, `a5_yada` (`weather.md` §6.4) ve yol laneti: Han yolunda kuyu başına gömülü koyun, Han moral −5, 1 gün, Korku yok (H11). `kam_hearth`: IV–VI, `cr_healer` ustası kadın kam. Kural: Divan'da «Kamın Alameti» perde başına 1, Dinle (1 koyun, Gönül +2) ya da Sustur (Korku +1). Kam, Gök'e Tanhu'dan yakın konuşamaz (Roux'nun Türk-Moğol kuralı, Hun tanıklığı değil): Kut ≥10 iken seçenek metni değişir. Kıyafet: çan, tüy, güneş ve ay pulu. Davul Hun çağında tanıksızdır: kam çan ve yaylı kıl kobuz kullanır, telli kopuz ozanındır (`kopuz.md`: baksının çalgısı yaylıdır, 19.–20. yy tanıklığı); davulu yalnız V'te savaş kamına veririz **[kurgu]**.

**15. Kurban ve Gök Direği (#8, `settlement.md` §12.4, §12.2, `army.md` §1.3).** Şafak Selamı aynı kalır. (a) Beşinci Ay Sunusu: `lunarMonth == 5`, `sky_pole` başında, perde başına 1: 1 `horse` (sürüden), 2 `kumis`. Et Toy'a gider (K24 at verimi). Avlu Gönül +3, birlik moral +5 bir gün, Kut +1 (`axisOnce`). Yalnız IV ve VI'da olur (kademe). (b) Saçı: yılın ilk `rc_kumis_batch`'inde sunu taşına 1 `kumis`, avlu Gönül +1. (c) Üç Tur: `dailin_count` başında Toy Alanı'nda (r 18) 12 söğüt dalı (örnekli, 1 çizim), atla üç tur = 339 m ≈ 28 sn. Oynanır ya da izlenir, ceza yok, sayım morali +2. (d) Direk üstünde 9 çentik (`tapty`), biçim yine `tasarım tercihi` (`settlement.md` §1.3). (e) Otağ, flama, Teoman ve Mete tabutunda altın daire ve hilal. (f) Akşam Teoman aya eğilir, oyuncuya eylem açılmaz; §12.4 kuralı kalır.

**16. Altın İnsan ve kılıç (#20, #8).** Qin'in aldığı Yunyang sunu yerinin kaybı (H8) Mete'nin toprak davasına eklenir: Ordos geri alınır, Yunyang geri alınamaz, altın insan batıya, sonradan Xiutu'nun payına gider. **[kaynak ve kurgu]** Rivayet 漢書音義 ve Kuodizhi'nindir, Suoyin «doğru olmayabilir» der; oyunda kişi ağzında söylenti olarak geçer. IV. Perde'de konuşulur. V. kademede avlunun sunu taşına ikinci altın insan dökülür **[kurgu]**: Hazine'den 300 Kıymet, Şafak Selamı morali +2 → +3. Kıngrak (`qingrak`) tarifinde "Kılıç Tanrısı" satırı. Eski Kurganlar `akinakes`i bu bağla okunur (`sq_dead_gold`). Altın insan Han'a MÖ 121'de geçer; Destan bunu yazar.

**17. Beyaz At Antı ve kafatası (#20, `progression.md` §5).** `brother_oath` ve Han ile barış sahnesi (V) 刑白馬 kalıbıyla yapılır: beyaz at, kılıç, altın kaşık. Kafatası kâsesi Mete'den sonradır (Laoshang), oyunda yoktur. Kışlak'ın Kardeş Kâsesi Herodot kalıbıdır, kalır. Kırık ant satırı: Hanshu 94B'de Han bakanları bu antı kınarken «Tanhu Göğe kötü söz iletebilir» der (令單于得以惡言上告于天); bu söz Kut −1'in metni olur.

**18. At ve deve yarışı (#8, ek istek, `settlement.md` §12.2).** Toy Alanı'nda IV'ten Lung-çeng benzeri toplantıda at ve deve yarışı (H6): 1 tur, `horse` ve `camel`, bahis yok, kazanan binicinin hanesi Gönül +2. Deve Hexi ve Gobi'den. `fauna.md`'ye kaynak.

**19. Ses ve söz biçimi (#57, #58, #59).** İki kaynak `audio.md` ve K19 yenilemesi için doğrudan delildir: Gaoçe 好引聲長歌 (uzun çekilen, kurt ulumasına benzeyen ezgi) ve 亡我祁連山 şarkısı (iki beyit, koşut dize). Öneri: kopuz üstünde uzun çekilen serbest ses, dörtlük zorunlu değil, iki beyit yeter (K6 sözü düzelir). Akor yok. MÖ 121 şarkısı kendisi oyunda söylenmez, biçim olarak alınır; sonsözde bir kez. Çalgı iyesi öyküsü ozanın kitap girdisi olur.

**20. Otağ içi (#32, #31).** Kültür × boy × iç düzen sisteminin inanç satırları: Hun: kapı doğu, ortada ocak, üç ocak taşı, oturuş yaşlı solda kuzeye bakarak (長左而北鄉, Shiji 110), kapının solu "kötü köşe" (Anohin, süs). Doğuya açılan kapının tanığı Göktürk kağan otağıdır (Zhou Shu 50, 636) ve Radloff'un Altay sunu yurdudur; Hun için tanık yoktur, `settlement.md` S4'te tasarım tercihi diye işaretlenir. Yüeçi: ateş sunağı, kutlu köz kabı, sayım çubukları. Han elçi çadırı: masa ve sunu kabı, Göğün Oğlu mührü. Çiang: taş ocak, tepede ak taş (geç). Tung-hu: kızıl boyalı bez, köpek yeri. Her kültür 1 prop grubu, ≤4 çizim, üç boyda aynı.

**21. Hayvan simgeleri (#8, ek istek, `fauna.md`).** Adak Aygırı, Hun ağzında `ıduk`tur: «sağılmaz, yük vurulmaz» (K4 değişmez, Hereka ve Uldın kullanır). Tunghu'nun istediği bin li'lik at (千里馬) ozanın ağzında Tülpar olur; «Bin Li At» Tanhu 1'in perde adı olduğundan özel ad yapılmaz. Karga avı `toy_bow` işidir; Hun kişisi bir kez "karga bebek besledi" der (H12). Kartallı taç (Aluchaideng, Hun'a atfı tartışmalı) Avlu'nun tören nesnesidir; Teoman'ın başlığına konmaz, çünkü Tanhu 1'de Tuman'ın kürk başlığında altın kartal vardı. Köpek III'te ruh götürür; Ku ile bağ: Mene'nin köpeği Erlik'e kanmaz **[kurgu]**. Geyik öldürmek eski taşların yanında bir satır. Kurt ateşten çekinir (kural aynı), Hun öldürse suç saymaz: ataya saygı Göktürk'tür, Hun değil.

**22. Tanhu ve Kut (#35, #8).** Oyuncuya "Tanhu" (#35). Kitapta bir kez 撐犁孤塗: Göğün Oğlu. MÖ 176 mektubu VI. Perde'de Mete'nin sözüdür: 天所立, 以天之福; Kut kartı «Göğün rızası» aynı kalır. Kut ≥10'da Divan'da "Göğün diktiği" unvanı **[kurgu]**. Morale için halk ağzı `sür`: «Bu ordunun süründe bir şey var» satırı, sayı yok.

**23. Cenaze ve yas (#20, `army.md` §3.5).** Teoman'ın gömülmesi (II) ve Mete'nin (VI): tabut, altın daire ve hilal, kürk, höyüksüz; yakınların ölümü sahne dışı (`act1.md` §1: kan görünmez). Yeni yapı değil, sahne. Yerleşimde büyük kayıptan sonra Divan'da «Yoğ Aşı»: 1 Toy maliyeti, moral +5, Gönül +2, perde başına 1. Toy Alanı'nda taş sırası: mezar başına 2 çift, içinde kül (süs, 1 çizim); tarihli örnekler Mete'den ≈150–250 yıl sonradır, kullanım geriye yansıtmadır **[çıkarım]**. `balbal` sözcüğü oyunda yalnız ozanın geleceğe dönük dizesinde geçer. Yüz kesme gösterilmez, satır olur.

**24. Doğruluk etiketi: Geyik Taşları (#8).** K4 Geyik Taşları'nı Adak Ağılı'nda tutar. Destan girdisi: «Bu taşlar Yüeçilerden binlerce kış eskidir; kuzeyden mi getirildi, bilen yok» **[kurgu]**, rozet `game`. `act1.md` §4 ve `deer_amulet` aynı. `sq_road_bones` RB14 cezası aynı. Kurganlar Saka ya da daha eskidir diye yazılır.

**25. Yerel inanç notları (#20, #38, K8).** Her halka bir gök sözü, bir ölüm kuralı, bir yasak; kişi satırları buradan yazılır, kaynak §10.
- **Yüeçi (I, IV):** Ateş ve sayı dili. Erlik'i bilmez; Donuk Kamp'ta Mene'nin onu duymaması bununla da uyuşur (`act1.md` §8.5) **[çıkarım]**. Atşo'nun kutlu ateşi söndürülmez. At sunusu Hun'la ortaktır. Hun töresiyle aynı derler (Shiji 123), kışlakta ayrım incedir.
- **Saka (son):** K8 gereği I. Perde'de yok. Güneşe at, kılıca sunu; `akinakes` ve kurganda yankı. VI ve sonsözde adı geçer.
- **Çiang (I, IV):** Yuan, Demir Diş'te Yanmayan Köle'yi anlatır (Yuanjian): Qin'den kaçan köle, ateş yakmaz. Mete'nin kaçışının ön yankısıdır **[kurgu]**. Yuan'ın isteği: ölürsem yakılayım (Xunzi). Beyaz taş kullanılmaz, geç tanıklıktır.
- **Han (II, V):** Göğün Oğlu; Liu Bang'ın beşinci sunağı (MÖ 205) ve saray kamları V'te elçi diline girer. Han için Tengri "Tian"dır, Hun mektubu (H2) bu yüzden küstah okunur. Kam sözünü küçümser, kendi kamlarını sayar.
- **Tung-hu (III):** Köpek ruhu Kızıl Dağ'a götürür; söğüt halkası; gök, ay, yıldız sunusu yakılır. Yenilenlerin seçiminde (`settlement.md` §5.7) bir satır: "köpeğim benimle gelsin".

### Perde perde açılma

| Perde | Yeni ögeler | Sistem |
|---|---|---|
| I | Hun ağzında Tengri; Kara Nama; Umay; Yüeçi ateşi; Yol Tengrisi; su boğası; iki at (`gap`); Çiang'ın Yanmayan Kölesi (Yuan anlatır); Geyik Taşları etiketi | Düşüş, Donuk Kamp, Tipi, Yol Kemikleri |
| II | Şafak Selamı (Teoman yapar); güneş ve ay çifti; `kam_court`; Av Payı; Köz Kabı ve Od Ana; Taş Yığını; `iron_stake`; Teoman'ın gömülmesi | Ocak, Oba, atlas |
| III | Vuhuan'ın köpeği ve Kızıl Dağ; söğüt halkası; `yir sub idisiz`; ayı adı; bozkır iyesi | Tung-hu seferi, Kut |
| IV | Beşinci Ay; Lung-çeng sunusu; at ve deve yarışı; Qilian Gök Dağı; altın insan; `kam_hearth`; Yüeçi sunağı | Toy Yeri, Gök Direği, `hexi_ash` |
| V | Han sunakları ve Göğün Oğlu; yol laneti; `a5_yada`; beyaz at antı; Yıldırım | Baideng, Avlu Toplantısı |
| VI | Gaoçe'nin kurt atası; Usun'un kurt ve karga bebeği; 天所立 mektubu; Üç Tur; Kıl Köprü; Mete'nin yoğu; ozanın son beyti | Dailin, Kurultay, Son |

Usun bebeği için tarih: Yüeçi'nin Nandoumi'yi öldürmesi Qilian-Dunhuang'da, MÖ 176 yenilgisinden önce, Kunmo o gün yeni doğmuş, Hun'a sığınır (Hanshu 61; Shiji 123 katili Hun yazar, iki metin ayrılır). Mete MÖ 174'e dek yaşar. Bebek Mete'nin avlusuna gelmiş olabilir. **[çıkarım]** VI. Perde bunu oynar.

### Godot için (Godot 4.7, `game/`)

Bugünkü Godot oyununda gece kampı, Serbest Gez, Destan Kitabı, kayıt, ayarlar, takip kamerası ve boyalı görünüm vardır; saat, takvim, hava, toplama, zanaat, ekonomi, yerleşim, ordu, atlas, dövüş ve gizlilik yoktur (`d3/oyun-durumu.md`). Bu yüzden öneri 4, 5, 7, 8, 10, 11, 14–18, 22 ve 23 o sistemler Godot'a gelince uygulanır; kuralları bu belgede kalır, uygulama biçimi `godot.md`'ye yazılır. Hemen uygulanabilenler: 1, 2, 9'un görünüşü, 12'nin gök katmanı ve «Göğe Bak» çekimi, 13'ün sesi, 21, 24. Yollar `game/` altındadır; Godot API'si 4.7 belgesinden denetlendi ([gök gölgelendiricisi](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/sky_shader.html), [gölgelendirme dili](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html), [MultiMesh](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html)).

| Öneri | Godot'da nasıl | Not |
|---|---|---|
| 1 | `scripts/ui/destan_kitabi.gd`: `CHAPTERS`'a `"mitler"`, `CHAPTER_TITLES`'a «Gök ve Yer», `DATA_PATHS`'a `res://data/mitler.json`, `ENTRY_KEYS`'e `"myths"`, `entries()`'e yeni `match` kolu; sayfa düzeni `destan_kitabi_page.gd`. Girdi alanları `id, name, group, age, unlock, text`; rozet `sub` alanında görünür. Koşul `JourneyFlags.holds` biçimindedir (`"mit_tengri"`). Oyuncu ateşin `FIRESIDE_RADIUS` (3 m) içinde 5 sn durunca `Journey.set_flag("mit_<id>")`; var olan «Destan Kitabı'na yazıldı» bildirimi çıkar | Saat yokken «günde 1» yerine ateşe her yeni varışta 1. Kopuz düzeltmesinin yerleri: `data/destan.json` (`ocak_basinda`), `data/kisiler.json` (`cocuk`, `ozan`), `scenes/world/camp_npcs.tscn` (`Elder/Dombra`, `model_id = "dombra"`), `tools/asset_plan.json` (`dombra` istemi), `README.md` |
| 2 | Yeni `scenes/cinematics/prologue.tscn`: `AnimationPlayer` kamerayı ve keçe panoları sürer; panolar `MeshInstance3D` dörtgendir, malzemesi `shaders/felt.gdshader` ya da `shyrdak.gdshader`; `painterly_overlay` açık kalır. Atlama `scripts/ui/epigraph.gd`'nin `is_skip_event` kalıbı ve `pause` eylemiyle (Esc). «İkinci oyunda atlanır» bilgisi `GameSettings`'te (`user://settings.cfg`) durur, kayıtta değil | Akış: Yeni Oyun, Önsöz, Çocukluk. Karakter oluşturucunun yeri ve ana kamptaki Mete (`camp_npcs.tscn`'de `Warrior` = `mete`, K6 ile çelişir) `godot.md` ve `story.md`'de çözülür. Ses K19 ve K28 hattıyla ElevenLabs'ten; kredi önce sorulur |
| 3 | Kara Nama çalısı tek `MeshInstance3D`, tek malzeme (1 çizim): kodla (`scripts/world/mesh_kit.gd`) ya da Meshy (`tools/meshy_pipeline.py`, model 40 kredi) | Meshy kredisi önce kullanıcıya sorulur |
| 6 | Başucundaki küçük ok-yay için var olan `assets/props/bow` modeli küçültülür; yeni üretim yok | |
| 8, 10 | Godot'da E bugün `camera_right` ve `accept`'tir (`scripts/core/input_setup.gd`, `KEY_ACTIONS`). «Pay Bırak» ve «Taş Ekle» için ayrı `interact` eylemi gerekir; basılı tutma süresi `_process` içinde `Input.is_action_pressed` ile sayılır | K27'deki gibi kamera `,` ve `.` tuşlarına geçerse E `interact` olur; karar `godot.md`'nindir |
| 9 | `scripts/camp/campfire.gd`: «Küle Yatır» durumu `OmniLight3D` enerjisini 0 yapar, alevi ve kıvılcımı gizler, dumanı keser, kor dokusunu söndürür; durum kayda yazılır. F bugün boştur: `fire_tend` eylemi | Ana'nın tarifi `data/kisiler.json` `ana` kaydına eklenir |
| 12 (b) | `shaders/sky.gdshader`'a `uniform vec3 named_stars[9]` (x = α, y = δ, z = parlaklık; uniform dizisine varsayılan değer verilemez), `uniform float sidereal_angle`, `uniform float latitude_deg` (Hexi ≈39, ana kamp 47,35), `uniform float named_star_strength` (menüde 0). Yön: H = sidereal_angle − α; doğu = −cos δ · sin H; yukarı = sin φ · sin δ + cos φ · cos δ · cos H; kuzey = cos φ · sin δ − sin φ · cos δ · cos H; Godot yönü `vec3(doğu, yukarı, -kuzey)` (kuzey −Z, `World.direction_from_angles` ile aynı). Adlı yıldızlar yalnız tam çözünürlük geçişinde çizilir, `AT_CUBEMAP_PASS`'ta değil; rastgele yıldızlar kutbun 3° çevresinde maskelenir | Godot belgesine göre her uniform değişimi radyans küp haritasını yeniden çizdirir: açı oyun dakikasında bir (2,5 sn) yazılır. Saat gelene dek açı sabittir |
| 12 (d) | «Göğe Bak»: `FollowCamera.set_active(false)`, `create_tween()` ile kamera kuzeye ve 40° yukarı, 6 sn bekleme, sonra `set_active(true)`; dönüş `activation_blend` (1,6 sn) ile yumuşar | `pitch_deg` aralığı 10–85° aşağıdır, yukarı bakışı karşılamaz |
| 13 | `lake_bull`: gölün (`Water` düğümü) yanında `AudioStreamPlayer3D`, `Ambience` veri yolu, 22 kHz mono (K12); dosya `tools/elevenlabs_audio.sh sfx` ile üretilir | Kredi önce sorulur; hava gelene dek tetik yok |
| 15 (c) | 12 söğüt dalı tek `MultiMeshInstance3D`'dir (tek çizim). Godot belgesine göre örnekler tek tek kırpılmaz, hepsi birlikte görünür ya da gizlenir; Toy Alanı küçük olduğu için sorun değildir | |
| 20 | Kültür başına prop grubu tek `MultiMeshInstance3D` ya da birleştirilmiş tek mesh; yurt içi `scripts/camp/yurt.gd` ile | |
| 21 | Godot'daki `data/kisiler.json` `ak_at` kaydı («ay ışığında gümüş yele», «Mete'den başkasını sırtına zor alır») K4'ün kaldırdığı Tanhu 1 ay atına yakındır; Adak Aygırı ve `ıduk` dili bu kaydın yerini alır | Sahibi `fauna.md` ve `story.md` |
| 24 | Geyik Taşları girdisi `data/taslar.json`'a `group: "Eski Taşlar"` ile girer; açılış koşulu bugün `kaya_kumesi`, ileride Adak Ağılı | |

**Adlı yıldızlar, MÖ 209.** Tarih ekvatoru koordinatları; Lieske 1977 açıları, özdevinim dahil **[çıkarım, kendi hesabım]**. Yedi Karakçı'nın en güneydeki yıldızı Alkaid bile 38°K'de ufkun 9° üstünde kalır.

| Yıldız | Oyun adı | Kadir | α (°) | δ (°) | Kutba (°) |
|---|---|---|---|---|---|
| β UMi, Kochab | Kök Boz At | 2,1 | 242,7 | 82,3 | 7,7 |
| γ UMi, Pherkad | Ak Boz At | 3,0 | 242,1 | 79,1 | 10,9 |
| α UMa, Dubhe | Yedi Karakçı | 1,8 | 120,8 | 71,7 | 18,3 |
| β UMa, Merak | Yedi Karakçı | 2,4 | 124,1 | 66,4 | 23,6 |
| γ UMa, Phecda | Yedi Karakçı | 2,4 | 143,3 | 65,3 | 24,7 |
| δ UMa, Megrez | Yedi Karakçı | 3,3 | 150,0 | 68,9 | 21,1 |
| ε UMa, Alioth | Yedi Karakçı | 1,8 | 164,8 | 68,2 | 21,8 |
| ζ UMa, Mizar | Yedi Karakçı | 2,2 | 175,8 | 67,0 | 23,0 |
| η UMa, Alkaid | Yedi Karakçı | 1,9 | 183,4 | 61,1 | 28,9 |

## Belirsizlikler

- **Kaynak bulunamadı.** İlk turda web arama sınırına ulaşıldı. 2026-11-04 doğrulama turunda da şunlar için özgün kaynak bulunamadı: Bay Terek adı, Bugu Ana, Toğrul (Vikipedi'nin ongon tablosunda yok, tablo kaynaksız), Er Töştük, Alp Kara Kuş, Alp Er Tunga metni, Yel Ana, `yek < yakşa`, Sakha olonho, Dede Korkut'ta kopuz, Verbitski ve Radloff 1866'nın kendisi, Kaşgarlı'nın kendi metni (Bayat, Jiang üzerinden), Ak Ana'nın birincil yeri, Irk Bitig fal numaraları (Tekin PDF'i taranmış görüntüdür, metin aranamadı), Bilge Kağan'daki `üze tengri erklig` satırı.
- **Hun dili.** 撐犁'nin Tengri olduğu çoğunlukla kabul edilir ama kanıtlanmış değildir; Vovin'in Yenisey önerisi vardır (§2.3). Hun ile Türk sürekliliği Zhou Shu'nun 匈奴之別種 sözüne dayanır, kanıt değildir.
- **Hou Hanshu 89.** Wikisource kopyası 三歲祠 yazar, Suoyin'in alıntısı 三龍祠 (doğrulama turunda iki metin yeniden okundu). Yanındaki 五月龍祠 ikincisini destekler.
- **Yan Shigu ve Qilian.** Yan Shigu'nun şerhi Vikisözlük'te alıntılanır: 祁連山即天山也，匈奴呼天為祁連 ([祁連](https://en.wiktionary.org/wiki/祁連)); Schuessler 2014 bu Hun kökenine karşı çıkar. Şerhin Hanshu'daki bölümü bu turda açılamadı. Suoyin'in notu: 祁連一名天山，亦曰白山.
- **Kül Tigin'de Umay.** Satır Kül Tigin doğu 31'dedir (`Umay teg ögüm katun kutıña`); doğrulama turunda Türkçe yayınlardan bulundu. archive.org kopyasında OCR yüzünden görülmemişti.
- **Bayat'ın PDF metni** kırıktır; `Payana` ve `ıduk` özetleri eksik metinden çıkarıldı.
- **Theophylact.** Çevrimiçi kayıt bot duvarı nedeniyle açılmadı; özet arama sonucundaki kayıttandır. Whitby 1986 s. 188–193 okunmadı.
- **Menandros.** Zemarkhos elçiliği ve iki ateş arasından geçiş ikincil kaynakla doğrulandı (§3); Menandros'un metni (Blockley 1985) açılmadı, yıl 568 ya da 569 diye geçer.
- **Sayfa numaraları** Holmberg ve Radloff için OCR'dan alınmıştır. Doğrulama turunda tam metin aramasıyla denetlendi; Holmberg'de bir sayfa kayabilir (ör. tufan 362–364, Kızagan 405–406). Anohin'in OCR'ı sayfa vermediği için bölüm numarasıyla anıldı: I.A kara ruhlar, I.B ak ruhlar.
- **Radloff'un taşı.** Yaratılışın 2. adımında OCR «Stern» (yıldız) okur; «Stein» (taş) dizgisi basılı sayfada denetlenecek.
- **Presesyon** kendi hesabımdır (Lieske 1977 açıları, özdevinim dahil), Magli ile uyumludur, iki denetim noktası tutar (§4.3). Godot gök kubbesi için yeterlidir, gökbilim iddiası değildir.
- **Kazak yıldız adları** Jiang'ın Çince ikincil kaynağından gelir; bir Kazakça öğrenci derlemesi eşlemeyi ters verir, Holmberg yıldız ayırmaz. Oyun Jiang'ı ve Kazak adlarını seçer.
- **Geyik taşı Hexi'de yok** hükmü okuduğum kaynakların sessizliğidir. UNESCO sayfası doğrudan açılmadı (403), tarih arama özetindendir.
- **Ergenekon ve kurt.** Akademik özet ile popüler siteler çelişir.
- **Noin-Ula** mantar ve sunak yorumu tartışmalıdır (Polosmak, Yatsenko).
- **Kızagan = savaş tanrısı** Holmberg'de (s. 406) Moğol Kisagan Tengri için yazılır; Altay için Radloff yalnız «kudretli» der. Holmberg'in kaynağı (Banzarov olabilir) açılmadı.
- **Tasarım sınırı.** Öneri 5 `act1.md` §16'yı, öneri 4 `progression.md` §5.3'ü, öneri 12 `progression.md` §4.6 ve `time.md` §5.6'yı değiştirir. Öneri 8'in sayıları ekonomi benzetimine girmeden kesinleşmez. Atşo'nun `hat.kind:'kam'` kimliği kalır ama o bir Yüeçi ateş bekçisidir, kam değildir.

## Kaynaklar

**Birincil metinler**
- [Shiji 110](https://zh.wikisource.org/wiki/史記/卷110), [üç şerhli Shiji 110](https://zh.wikisource.org/wiki/史記三家註/卷110)
- [Shiji 27](https://zh.wikisource.org/wiki/史記/卷027), [Shiji 28](https://zh.wikisource.org/wiki/史記/卷028), [Shiji 111](https://zh.wikisource.org/wiki/史記/卷111), [Shiji 123](https://zh.wikisource.org/wiki/史記/卷123)
- [Heguanzi, 環流](https://www.ctext.org/he-guan-zi)
- [Hanshu 61](https://zh.wikisource.org/wiki/漢書/卷061), [Hanshu 68](https://zh.wikisource.org/wiki/漢書/卷068), [Hanshu 94A](https://zh.wikisource.org/wiki/漢書/卷094上), [Hanshu 94B](https://zh.wikisource.org/wiki/漢書/卷094下), [Luntai fermanı](https://zh.wikisource.org/wiki/輪臺詔)
- [Hou Hanshu 87](https://zh.wikisource.org/wiki/後漢書/卷87), [89](https://zh.wikisource.org/wiki/後漢書/卷89), [90](https://zh.wikisource.org/wiki/後漢書/卷90)
- [Wei Shu 103](https://zh.wikisource.org/wiki/魏書/卷103), [Zhou Shu 50](https://zh.wikisource.org/wiki/周書/卷50), [Xunzi, Dalue](https://zh.wikisource.org/wiki/荀子/大略篇)
- [Herodot 1.216](https://www.perseus.tufts.edu/hopper/text?doc=Perseus:text:1999.01.0126:book=1:chapter=216), [Herodot 4.62](https://www.perseus.tufts.edu/hopper/text?doc=Perseus:text:1999.01.0126:book=4:chapter=62)
- [Orhun Abideleri: Kül Tigin, Bilge Kağan, Tonyukuk](https://archive.org/details/orhun_abideleri)
- [Irk Bitig, Tekin 1993](https://altaica.ru/LIBRARY/Tekin%20Talat/Tekin_Irk%20Bitig%20-%20The%20Book%20of%20Omens%201993.pdf)
- [Movses Dasxuranci, II.40](https://www.attalus.org/armenian/md13.htm)
- [Theophylact Simocatta, 7.8.11–15, kayıt](https://mmp.acdh-dev.oeaw.ac.at/archiv/stelle/detail/5051)

**Derlemeler**
- [W. Radloff, Aus Sibirien II](https://archive.org/details/aussibirienloseb02radl)
- [A. V. Anohin, Materialy po şamanstvu u altaytsev, 1924](https://archive.org/details/sbornikmuzejaantropologiiietnografiit419)
- [U. Holmberg, Finno-Ugric, Siberian, 1927](https://archive.org/details/in.ernet.dli.2015.283531)

**Arkeoloji**
- [Miller vd. 2018, Stone lines and burnt bones, Antiquity](https://www.cambridge.org/core/journals/antiquity/article/stone-lines-and-burnt-bones-ritual-elaborations-in-xiongnu-mortuary-arenas-of-inner-asia/1A4636F94C9A10D2599280A59E2E7163)
- [Miller vd. 2009, Xiongnu Elite Tomb Complexes, The Silk Road](https://edspace.american.edu/silkroadjournal/wp-content/uploads/sites/984/2017/09/Xiongnu-Elite-Tomb-Complexes.pdf)
- [Polosmak vd., The Xiongnu Gold from Noin-Ula](https://journal.archaeology.nsc.ru/jour/article/view/562)
- [UNESCO, Deer Stone Monuments](https://whc.unesco.org/en/list/1621/), [Mongolian Deer Stone-Khirigsuur Complex, Smithsonian deposu](https://repository.si.edu/bitstreams/62c880a2-ca22-40b9-be96-43aa35d2a606/download)
- [Aluchaideng tacı, China Daily](https://govt.chinadaily.com.cn/s/202304/06/WS642e6fcc498ea274927b5b56/eagle-shaped-gold-crown-from-more-than-2-000-years-ago.html)

**Çalışmalar**
- [J.-P. Roux, Tengri, Encyclopedia of Religion](https://www.encyclopedia.com/environment/encyclopedias-almanacs-transcripts-and-maps/tengri)
- [K. Sagaster, Erlik, Encyclopedia of Religion](https://www.encyclopedia.com/environment/encyclopedias-almanacs-transcripts-and-maps/erlik)
- [Z. Jiang 2026, Influence of Turkic North Pole Star Tradition, bilig](https://bilig.yesevi.edu.tr/yonetim/icerik/makaleler/8108-published.pdf)
- [Y.-S. Li 2014, Some Star Names, TDK Belleten](https://tdk.gov.tr/wp-content/uploads/2016/12/Yong-S%C5%8Fng%20LI%20-%20Some%20Star%20Names%20%C4%B1n%20the%20Modern%20Turk%C4%B1c%20Languages-I.pdf)
- [G. Magli, Royal mausoleums of the Western Han and Song](https://arxiv.org/pdf/1612.05985)
- [E. Atcı 2025, Nergal ve Erlik](https://dergipark.org.tr/tr/download/article-file/4276930)
- [M. Aça, Mitten Destana Beden](https://dergipark.org.tr/tr/download/article-file/441175)
- [F. Bayat 2007, Divanü Lügati't-Türk'te mitolojik dünya modeli](https://turkoloji.cu.edu.tr/ESKI%20TURK%20DILI/fuzuli_bayat_kasgarli_mahmut_divanu_lugatit_turk_mitolojik_dunya_modeli_kavramlar.pdf)
- [O. A. Kayabaşı, Türk Mitolojisinin Kutsal Dişisi: Umay](https://dergipark.org.tr/en/download/article-file/3173462)
- [H. Park 2024, Mago Halmi ve Umay Ana](https://dergipark.org.tr/en/download/article-file/4169511)
- [İ. Polat 2020, Türk Kültüründe Dağ Kültü](https://dergipark.org.tr/en/download/article-file/1383030)
- [Bilgiç ve Karaahmet, Türk Miti Tasavvurunda Anne Arketipi](https://dergipark.org.tr/en/download/article-file/2997890)
- [F. Şengül 2026, Oğuz Kağan'ın Kimliği](https://dergipark.org.tr/en/download/article-file/5198629)
- [Zoriktuev 2015, Turkic Version of the Ergene-Kun Legend](https://www.sciencedirect.com/science/article/abs/pii/S1563011015001555), [A Name Without an Organization: Ergenekon](https://www.academia.edu/176458926/A_Name_Without_an_Organization_Ergenekon_from_Rash%C4%ABd_al_D%C4%ABns_Valley_to_the_Silivri_Courtroom_c_1307_2019)
- [Orhun Yazıtlarında +Ka, +Da çalışması](https://dergipark.org.tr/tr/download/article-file/4806051)
- [Theophylact's Turkish Exkurs revisited](https://books.openedition.org/editionscnrs/25263)
- [The Pantheon Rediscovered, Yale](https://macmillan.yale.edu/southasia/pantheon-rediscovered-south-asian-studies-yale-university-0)
- [Language Log, Of precious swords](https://languagelog.ldc.upenn.edu/nll/?p=24595), [徑路, Wiktionary](https://en.wiktionary.org/wiki/%E5%BE%91%E8%B7%AF), [祁連, Wiktionary](https://en.wiktionary.org/wiki/祁連)
- [A. Vovin, Did the Xiongnu Speak a Yeniseian Language? (2000; ikinci bölüm)](https://www.altaist.org/home/confessions/a-vovin/did-the-xiongnu-speak-a-yeniseian-language-part-2-reexamining-the-lexical-evidence/)
- [E. S. Ayaz 2020, Kül Tigin kuzey 10 üzerine](https://dergipark.org.tr/en/download/article-file/979004)
- [Kazak yıldız adları, öğrenci derlemesi (zayıf kaynak)](https://stud.kz/referat/show/82711)
- [Türk Yaratılış Destanı, Küre (ikincil)](https://kureansiklopedi.com/tr/detay/turk-yaratilis-destani-radloff-derlemesi-82297)

**Godot belgeleri (4.7)**
- [Sky shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/sky_shader.html), [Shading language](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html), [Using MultiMesh](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html)

**Başlangıç noktası (Vikipedi, kanıt sayılmaz)**
- [Zemarchus](https://en.wikipedia.org/wiki/Zemarchus), [Umay](https://en.wikipedia.org/wiki/Umay), [Ülgen](https://en.wikipedia.org/wiki/%C3%9Clgen), [Tengri](https://en.wikipedia.org/wiki/Tengri), [Oghuz Khagan](https://en.wikipedia.org/wiki/Oghuz_Khagan), [Oghuz Turks](https://en.wikipedia.org/wiki/Oghuz_Turks), [Book of Dede Korkut](https://en.wikipedia.org/wiki/Book_of_Dede_Korkut), [Epic of Manas](https://en.wikipedia.org/wiki/Epic_of_Manas), [Tulpar](https://en.wikipedia.org/wiki/Tulpar), [Bugut inscription](https://en.wikipedia.org/wiki/Bugut_inscription), [Issyk kurgan](https://en.wikipedia.org/wiki/Issyk_kurgan), [Noin-Ula](https://en.wikipedia.org/wiki/Noin-Ula_burial_site), [Qiang folk religion](https://en.wikipedia.org/wiki/Qiang_folk_religion), [Yaratılış Destanı (Altay)](https://tr.wikipedia.org/wiki/Yarat%C4%B1l%C4%B1%C5%9F_Destan%C4%B1_(Altay))

## Doğrulama

Tarih: 2026-11-04. Şüpheci doğrulama turu; önceki araştırmacının kaynaklarına güvenilmedi, her iddia bağımsız metinle sınandı. Kaynak: şerhli Shiji 110 ve Hanshu 61, 94A, 94B, Hou Hanshu 89, Shiji 27 (Wikisource); Radloff Aus Sibirien II, Anohin 1924 ve Holmberg 1927'nin archive.org tam metinlerinde arama; Jiang 2026'nın PDF metni; Miller 2009 ve 2018; Roux ve Sagaster maddeleri; Godot 4.7 belgeleri ve `game/` betikleri. Presesyon kendi hesabımdır.

**Sınanan iddia: 43.** Çin metinleri 12 (H1, H5, H6, H7, H8, H10, H12 ile Hanshu 61, H13, H14, Yan Shigu'nun 祁連 şerhi, Hanshu 94B antı, Shiji 27), Orhun ve Göktürk çağı 8 (Kül Tigin kuzey 10 ve doğu 31, Zhou Shu'nun doğu kapısı, Menandros, Movses, Theophylact, Bugut, Irk Bitig), derlemeler 12 (Radloff'un yaratılışı, gök katları ve Kün Ana notu, Musa ve Budizm uyarısı, Yer-Su, Ülgen sunu yurdu; Anohin'in Erlik'i, Ülgen'in oğulları, Suyla, Ak Ayas; Holmberg'in dokuz sayfa atfı, Kırgız atları, Kızagan, Büyük Ayı takvimi; Ak Ana), çalışmalar 5 (Roux'nun kut ve kam cümleleri, Sagaster, Jiang'ın yıldız eşlemesi, Vovin), arkeoloji 2, destan 3 (Manas, Bichurin, Toğrul), gökbilim 1.

**Düzeltmeler**
- Katman tablosuna eserlerin yazım yılları, ayrı şerh katmanı ve Manas'ın ilk kayıtları eklendi.
- H5, H6, H7, H8, H13, H14'te tanıklığın yazıldığı çağ ve şerhçi düzeltildi: söğüt halkası 7.–8. yy Tang şerhidir ve Xianbei töresidir; Wei Shu 554'tür; Qilian şarkısının ilk tanığı Tang şerhlerindeki Xihe jiushi'dir.
- «Kutupta çıplak gözle görülür yıldız yoktu, en yakını Kochab'dı» yanlıştı: 4 UMi (3,9°) ve 5 UMi (5,6°) daha yakındı. Han'ın kutup yıldızı Kochab'dır (Shiji 27).
- Büyük Ayı'nın mevsim söylediği söz Türk değil Han bilgisidir (Heguanzi, Shiji 27).
- Kazak yıldız atlarının eşlemesi çelişkili diye işaretlendi; Kırgız anlatısındaki «ip» ayrıntısı ve Tanhu 1 notu eklendi.
- Roux'da kut ve ülügü Gök değil hükümdar dağıtır.
- Kızagan'ın savaş tanrısı oluşu popüler sitelerden değil, Holmberg'deki Moğol tanıklığından gelir.
- Ak Ana üç tam metinde yoktur; birincil yeri bulunamadı, sinemada isteğe bağlı kaldı.
- Taş sırası ve güneş-ay çiftinin Mete'den ≈150–250 yıl sonra olduğu yazıldı; hirigsur cümlesi düzeltildi.
- Kül Tigin doğu 31'deki Umay satırı ve Zemarkhos'un iki ateşi doğrulandı, ilgili belirsizlikler kapandı. Movses'in derleme çağı, Irk Bitig'in tarih aralığı ve `Öd tengri` okumasının tartışması eklendi.
- Tanhu 1 yakınlıkları ayrıldı: «tüccar» Erlik, Bin Li At, Ak Dağ, Ayaz, aynı gece doğan tay, Tuman'ın kartallı başlığı, Kam Bögü'nün görünüşü, kıl ip, VI. Perde'nin alt dünyası.
- Giriş sineması brifle uzlaştı: koyun sahnesi oynanan Çocukluk'a geçiş oldu (toplam ≈215 sn), Umay görünmez, kaynak sütunu düzeltildi, Tanhu 1 önsözünden farkı yazıldı.
- Öneri 12 (d): 14° eğim göğü göstermez; yerine «Göğe Bak» çekimi. Öneri 20: doğu kapının tanığı Göktürk'tür. Öneri 14'te kamın çalgısı yaylı kıl kobuz oldu, telli kopuz ozanda kaldı (`kopuz.md`). Öneri 5, 16, 17, 23'e bağlam notu eklendi.
- Küçükler: Zhou Shu'nun 他人水'su su değil ırmak adıdır; Bilge Kağan'daki `erklig` satırı yeniden bulunamadı diye işaretlendi; Tonyukuk satırının çevirisi «çöktü» yerine «bastırdı» oldu.
- «Godot için» bölümü eklendi: 13 önerinin Godot 4.7 karşılığı ve MÖ 209 için adlı yıldız koordinatları.

Doğru bulunan iddialar değiştirilmedi: Hanshu 94A'nın 撐犁 satırı, Hou Hanshu 89'un 三歲祠 farkı, Radloff'un gök katları ve Kün Ana notu, Anohin'in Erlik anlatısı, Holmberg'in sayfa atıflarının çoğu, Miller 2018'in taş sırası tarifi, Hanshu 61'in Kunmo anlatısı.
