# Mete ve Hun Tarihi: Kaynak Denetimi ve Takvim

Bu belge yeni senaryonun tarih temelidir. Çince alıntıları birincil metinle karşılaştırır (cevap #7), Mete'nin hayatını kesin tarihli bir takvime oturtur (#1), açılışın takvim sorununu çözer (#3), Dailin Sayımı'nın gününü verir (#44), tek yazım tablosu önerir (#9) ve perdelere gerçek olay malzemesi çıkarır. Etiketler: [kaynak] kaynağı olan bilgi, [çıkarım] kaynaktan benim çıkarımım, [kurgu] oyun için önerilen uydurma. Tanhu 1'den ne kadro ne nesne ne perde adı alındı. Belge şüpheci turdan geçti (2026-11-04): düzeltmeler satır içindedir, kalan kuşkular «Belirsizlikler»dedir. Aynı gün ikinci, bağımsız bir sınama yapıldı; sonucu ve düzeltme listesi en sondaki «Doğrulama»dadır. Oyun Godot 4.7'dedir (`game/`): Three.js prototipine yazılmış öneriler «Godot için» bölümünde Godot karşılığıyla tamamlandı.

## Özet

1. 346 satırda 324 ayrı Çince parça tarandı, 56 bölümle ve 4 yorumlu bölümle karşılaştırıldı. Shiji ve Hanshu'ya dayanan bütün alıntılar metinle eşleşiyor; ikinci turda 299 parça yeniden sınandı, sonuç değişmedi (§1.1). Düzeltilen: bir karakter (毋 → 毌, okuma tercihi), iki yazım varyantı, bir noktalama, dört çeviri (§1.3).
2. Mete'nin tahta çıkış yılının en eski açık tanıklığı Shiji 110'un yorumundadır: Xu Guang (352–425) «秦二世元年壬辰歲立» der, yani MÖ 209 [kaynak]. Sima Qian'ın metninde yıl yoktur. Bu geç bir nottur; modern yazın yine 209'u kabul eder.
3. Dailin için tanıklıklar yorumdur, Mete'den en az üç yüzyıl sonradır. Fu Qian «秋社八月中» der: 8. ayda güz kurbanı [kaynak]. Yan Shigu (581–645) «遶林木而祭» der, dikili dalı ve üç turu Xianbei âdeti olarak anlatır, «此其遺法» diye Hun'a bağlar. Üç tur Hun için [çıkarım]dır (§4).
4. #3 çözümü: elçi Dailin Sayımı'ndan sonraki dolunayda yola çıkar, gerçek 1.173 km'yi 50 günde alır, kapıda 5 gün bekler. MÖ 210'da gösteri 2 Aralık sabahıdır. Atlas aynı yolu 2–4,5 günde gösterir: 50 gün yalnız hikâye hesabıdır (§3.5). «Her güz» ve «Elçi güzde gelir» sözleri kalkar (§3.6).
5. #44 çözümü: Dailin 8. ayın dolunayıdır. İki kez oynanır: III. Perde'de 16 Eylül MÖ 208, VI. Perde'de 9 Eylül MÖ 174 (§4).
6. Kesin tarihler: doğum 27 Eylül MÖ 234, darbe 14 Haziran MÖ 209, Baideng 25 Kasım–1 Aralık MÖ 201, ölüm 9 Eylül MÖ 174, 59 yaşında (§2).
7. Takvim ay olaylarıyla uyuyor: III. Perde 8. ayın yeni ayında açılır, Baideng dolunayın çevresindedir, kuşatma ay eksilirken kalkar (§2.3). Uyumun çoğu seçimdir, kanıt değildir. Han ayıyla verilen olaylar yeniden kurulmuş Ç'in-Han takvimiyle sınandı: beşinin günü ve Birinci İmparator'un ölüm günü kaynağın ayına düşmüyordu, düzeltildi (§2.1, §2.2).
8. Yazım: Hun, Mete, Teoman, Yüeçi, Tunghu, Ç'in, Han, Usun, Dingling, Loufan, Baiyang, Çiang, Lung-çeng, Dailin. İngilizcede atlas ve kitap Xiongnu, konuşan bozkırlı Hun der (§5).
9. Shiji 110 Hunların yazısı olmadığını söyler (毋文書) [kaynak]. Çentik yalnız Tunghu kökenli Wuhuan için kayıtlıdır (HHS 90), Hun'a taşınması [çıkarım]dır. Mektupları Han'dan gelen kâtipler yazmış olmalıdır [çıkarım]. Bu, Defter ve Kefil sistemlerine dayanak verir (§6.2).
10. Kazılan Hun yerlerinin çoğu Mete'den bir buçuk iki yüzyıl sonradır: Noin-Ula, Gol Mod, Ivolga, Khustyn Bulag MÖ 1. yy–MS 1. yy. Görünüş için ödünç alınır, olay için kanıt sayılmaz (§6.3).

## 1. Kaynak denetimi (#7)

### 1.1 Yöntem

- Tarama: `docs/design`, `docs/research`, `docs-app/content`, ayrıca `src`, `test`, `tools`. Node ile CJK karakter aralığı tarandı. Kodda tek Çince satır `src/map/geography.js:304`'tedir. `src`, `test`, `tools` Three.js prototipinindir (`~/Code/tests/tanhu-programatic-test`). Godot projesi `game/` (betik, veri, sahne, araç) 2026-11-04'te ayrıca tarandı: Çince satır yoktur.
- Karşılaştırma metni: zh.wikisource ham metni. Shiji 6–10, 16–18, 22, 28, 55–57, 81, 87, 88, 93, 95, 99, 110, 111, 113–116, 123, 129; Hanshu 1–4, 6, 28, 33, 40, 43, 48, 49, 52, 54, 55, 61, 94A, 94B, 96A, 96B; Hou Hanshu 87, 89, 90; Sanguozhi 30; Suishu 83; Zizhi Tongjian 7, 11–14. Yorumlu baskı: 史記三家註 56, 99, 110, 123.
- ctext.org denendi; istek güvenlik sınamasına takıldı, sınama aşılmadı. ctext'in 毋 yazdığı bilgisi yalnız arama özetindendir.
- Her parça önce birebir, sonra varyant eşlemesiyle (爲/為, 歳/歲, 彊/強, 閒/間) arandı. Sonra her satırın adını verdiği bölüm ve Türkçesi elle okundu.
- İkinci tur (şüpheci): 299 ayrı parça Vikikaynak'la yeniden tarandı. 294'ü eşleşti, 5'i 45–47. satırların kaynak dışı parçasıdır. Bağımsız tanık için [Kanripo TLS Shiji](https://github.com/kanripo/KR2a0001) ve [Wenyuange Hanshu 94](https://github.com/kanripo/KR2a0007) denendi: Shiji ve Hanshu 94 etiketli 211 parçanın 189'u orada da bulundu, kalan 22'si başka bölüm, yorum ya da yazım varyantıdır. Tek aykırı sonuç 毌'dir (§1.3).

### 1.2 Sonuç tablosu

Kısaltmalar: `arm` army.md, `set` settlement.md (d2 eşiyle), `wea` weather.md (d2 eşiyle), `tim` time.md, `pro` design/progression.md, `rpr` research/progression.md, `grp` groups-research.md, `tk` site Tarih ve Kaynaklar, `ord` site Ordu.

| # | Alıntı | Nerede | Kaynak | Sonuç |
|---|---|---|---|---|
| 1 | 東胡彊而月氏盛 | act0-text:3, tk:28, grp:77 | SJ 110 | Doğru; tk çevirisi düzeltildi |
| 2 | 頭曼以爲壯,令將萬騎 · 作爲鳴鏑,習勒其騎射 · 鳴鏑所射而不悉射者,斬之 | arm:28–30, tk:29–31, ord:66–68 | SJ 110 | Doğru |
| 3 | 行獵鳥獸 → 自射其善馬 → 自射其愛妻 → 射單于善馬 → 射頭曼 | arm:31, 554–560, tk:32, ord:69, 134–140 | SJ 110 | Doğru |
| 4 | 左右或不敢射者 · 左右或頗恐 · 左右皆射之 · 皆可用 · 皆隨鳴鏑 | arm:32, 565–568, set:29 | SJ 110 | Doğru |
| 5 | 大者萬騎,小者數千,凡二十四長,立號曰「萬騎」 | arm:33 | SJ 110 | Doğru; HS 94A 大者萬餘騎 |
| 6 | 諸二十四長亦各自置千長、百長、什長 · 諸大臣皆世官 · 呼衍氏,蘭氏,其後有須卜氏 | arm:34–35, ord:70, grp:55–57 | SJ 110 | Doğru |
| 7 | 諸左方王將居東方 · 右方王將居西方 · 單于之庭直代、雲中 | arm:36, set:14, 45 | SJ 110 | Doğru |
| 8 | 歳正月 · 五月,大會蘢城 · 秋,馬肥,大會蹛林,課校人畜計 | arm:37, set:27, 46, wea:51, tk:37 | SJ 110 | Doğru; set:27 noktalaması düzeltildi |
| 9 | 舉事而候星月,月盛壯則攻戰,月虧則退兵 | arm:38, tim:65, wea:50, tk:36 | SJ 110 | Doğru; arm çevirisine «yıldız» eklendi |
| 10 | 斬首虜賜一卮酒,而所得鹵獲因以予之 · 人人自爲趣利,善爲誘兵以冒敵 · 如鳥之集 · 瓦解雲散 · 戰而扶輿死者,盡得死者家財 | arm:39–42, ord:71, pro:1328 | SJ 110 | Doğru |
| 11 | 士力能毌弓,盡爲甲騎 | arm:43, set:48, tk:39, pro:122 | SJ 110 | **Düzeltildi**, okuma tercihi (§1.3) |
| 12 | 士力能彎弓，盡為甲騎 | rpr:43 | HS 94A | Doğru |
| 13 | 其長兵則弓矢,短兵則刀鋋 · 利則進,不利則退,不羞遁走 · 令國中有後者斬 | arm:44–45, ord:72, set:369, pro:1328 | SJ 110 | Doğru |
| 14 | 控弦之士三十餘萬 · 精兵四十萬騎 · 西方盡白馬,東方盡青駹馬,北方盡烏驪馬,南方盡騂馬 | arm:46–47, grp:47 | SJ 110 | Doğru; HS 94A 三十餘萬騎 |
| 15 | 其約束輕,易行也 · 匈奴人眾不能當漢之一郡 | arm:48–49, ord:73, tk:42 | SJ 110 | Doğru; Zhonghang Yue sözleridir, Mete'den sonra |
| 16 | 諸引弓之民,并爲一家 · 然至冒頓而匈奴最彊大…其世傳國官號乃可得而記云 | arm:50, 53, tk:43 | SJ 110 | Doğru |
| 17 | 單于, 賢王, 屠耆, 谷蠡王, 大將, 大都尉, 大當戶, 骨都侯, 輔政, 什, 百, 千 | arm:63–80, ord:55–58 | SJ 110 | Doğru |
| 18 | 逐水草遷徙，毋城郭常處耕田之業，然亦各有分地 | set:15, 44, 231 | SJ 110 | Doğru; buradaki 毋 doğrudur |
| 19 | 單于朝出營，拜日之始生，夕拜月 · 兒能騎羊，引弓射鳥鼠；少長則射狐兔：用爲食 | set:28, 47, 49, pro:125, tk:38, 40 | SJ 110 | Doğru |
| 20 | 與匈奴閒，中有棄地，莫居，千餘里，各居其邊爲甌脫 · 冒頓自立爲單于 | set:50, 53, 490, tk:33–34, geography.js:304 | SJ 110 | Doğru |
| 21 | 大破滅東胡王，而虜其民人及畜產 | set:51, tk:35, grp:74, economy:576 | SJ 110 | Doğru |
| 22 | 其法，拔刃尺者死，坐盜者沒入其家 | set:52, pro:1328 | SJ 110 | Doğru; çeviri düzeltildi |
| 23 | 衛律為單于謀「穿井築城，治樓以藏穀…」 · 北至窴顏山趙信城而還 · 匈奴父子同穹廬臥 | set:54–56, 231, 462, d2/labour:429, structures:55, yurtlar:59 | HS 94A | Doğru |
| 24 | 會冬大寒雨雪，卒之墮指者十二三 | wea:48, 539, tk:41 | SJ 110 | Doğru; çeviri düzeltildi |
| 25 | 風雨罷勞，飢渴不困，中國之人弗與也 | wea:31, 49, 884 | HS 49 | Doğru |
| 26 | 東胡初輕冒頓，不爲備 | wea:537 | SJ 110 | **Düzeltildi** (為 → 爲) |
| 27 | 地者，國之本也，柰何予之 · 引弓之國 · 天所立匈奴大單于 | rpr:495, grp:43 | SJ 110 | Doğru |
| 28 | 徑路 · 東去單于庭七千里 | pro:1329, grp:242 | HS 94B | Doğru |
| 29 | 單于姓攣鞮氏 · 虛連題 · 常與單于婚姻 · 呼衍氏為左 · 主斷獄聽訟 · 丘林氏 | grp:54–60 | HS 94A, HHS 89 | Doğru |
| 30 | 東胡盧王 · 滿亡命，聚黨千餘人 · 真番、臨屯皆來服屬 · 真番旁眾國 | grp:75, 105, 125 | SJ 93, SJ 115 | Doğru |
| 31 | 餘類保烏桓山 · 歲輸牛馬羊皮 · 東夷薉君南閭 · 東接穢貉、朝鮮 | grp:83, 87, 90 | HHS 90, HS 6, SJ 110 | Doğru |
| 32 | 二千餘里 · 否死，其子准立 · 辰韓者，古之辰國也 · 匈奴北有渾窳國… · 北海之南 | grp:97, 125, 230, 241 | SGZ 30 | Doğru |
| 33 | 夷滅月氏，盡斬殺降下之 · 定樓蘭、烏孫、呼揭及其旁二十六國，皆以爲匈奴 · 月氏盛 · 急擊月氏 · 西擊走月氏 | grp:138–141, 170 | SJ 110 | Doğru |
| 34 | 月氏王爲匈奴冒頓所殺 · 走月氏，威震百蠻，臣服諸羌 · 舊在张掖、酒泉地 | grp:142, 196, 400 | HHS 87 | Doğru |
| 35 | 行國 · 月氏王 · 控弦者可一二十萬 · 匈奴西邊小國 · 匈奴攻殺其父 · 邑有城郭，臨鹽澤 · 始月氏居敦煌、祁連閒 | grp:131–161, 399, tk:51 | SJ 123 | Doğru |
| 36 | 小國 · 祁連、焞煌閒 · 大月氏攻殺難兜靡 | grp:148–150 | HS 61 | Doğru |
| 37 | 本三十六國 · 僮僕都尉 · vaha adları (且末…車師) | grp:174, 181–188, 326 | HS 96A, 96B, SJ 123 | Doğru |
| 38 | 皆氐類也 · 以其眾王滇 · 接月氏、氐、羌 · 接氐、羌 | grp:200–204, 290–296 | SJ 116, SJ 110, HS 94A | Doğru |
| 39 | 北破林胡、樓煩 · 南并樓煩、白羊河南王 · 後北服渾庾、屈射、丁零、鬲昆、薪犁之國 · 是時漢兵與項羽相距 · 冠帶之室 · 朝那 · 膚施 | grp:214–230, 258–263, tk:86–88 | SJ 110 | Doğru |
| 40 | 去長安近者七百里，輕騎一日一夜可以至秦中 | grp:224 | SJ 99 | Doğru |
| 41 | 龍新赚 | grp:230 | HS 94A | Doğru; Vikikaynak baskısı burada bozuktur, oyunda SJ biçimi kullanılır |
| 42 | 丁令盜武牛羊 | grp:241 | HS 54 | Doğru |
| 43 | 秦已破滅 · 閩越、西甌、駱，役屬焉 · 漢五年，復立無諸為閩越王 · 孝惠三年 · 東冶 | grp:272–286 | SJ 113, SJ 114 | Doğru |
| 44 | 舊居祁連山北昭武城 · 踰居延，遂過小月氏，攻祁連山 · 焉支山 · 焉耆山 | grp:401–402, 413 | Suishu 83, SJ 111, HS 94A | Doğru |
| 45 | 東胡餘類 | grp:79, tk:81 | Yok | Alıntı değil, etiket; metin 餘類 der |
| 46 | 呼偈，小國名，在匈奴北 | grp:154–155 | Kaynak bulunamadı | 三家註'de yok; zh-Vikipedi aktarması; oyunda kullanılmaz |
| 47 | 冬季則選擇… · 冬春場… · 夏放高山… · 王帐 · 失我焉支山 | grp:405, 406, 453, 472 | Modern yayın | Birincil değil; belge zaten öyle işaretler |

### 1.3 Yapılan düzeltmeler

| Dosya | Eski | Yeni | Neden |
|---|---|---|---|
| army.md, settlement.md, d2/settlement.md, site tarih-kaynaklar.md | 士力能毋弓 | 士力能毌弓 | 毋 «yapma» demektir, cümle anlam vermez. Hanshu 94A açıkça 彎弓 yazar. Shiji 110 notunda Sima Zhen (679–732) «上音彎，如字亦通也» der: 彎 okunur, harfin kendi okunuşu da geçerlidir. Bu ikinci söz 毋'ye değil 毌'ye (貫) uyar [çıkarım]. Aynı kitapta tam karşılığı vardır: Shiji 66 «伍胥貫弓», 集解 «貫，烏還反», 索隱 «劉氏音貫爲彎，又音古患反。貫謂滿張弓» [kaynak]; 貫 (毌'nin bugünkü biçimi) 彎 okunur, kendi okunuşu da verilir. Siku baskısı 史記正義 metni harfi 彎 yapar [kaynak]. Dijital metinler bölünür: Vikikaynak, Kanripo TLS ve ctext özeti 毋, tek arama özeti 毌. Basılı Zhonghua görülmedi: 毌 okuma tercihidir |
| progression.md:122 | 盡為甲騎 | 盡爲甲騎 | Öteki satırlarla aynı biçim |
| weather.md, d2/weather.md | 不為備 | 不爲備 | Satır Shiji 110 der; 為 Hanshu biçimidir |
| settlement.md, d2/settlement.md (Y15) | 五月大會蘢城 · 秋馬肥大會蹛林 | 五月，大會蘢城 · 秋，馬肥，大會蹛林 | Noktalama |
| tarih-kaynaklar.md:28 | Yüeçi zenginleşmiş | Yüeçi serpilmişti | 盛 zenginlik değil güç ve serpilmedir. SJ 123 de 故時彊 der |
| weather.md, d2/weather.md, tarih-kaynaklar.md:41 | kış ortası, Han askeri ağır kayıp verdi | askerin onda ikisi üçü parmağını yitirdi | Metin kaybı sayıyla verir. K1 oyunu etkilemez: oynanan yine yalnız kardır |
| settlement.md, d2/settlement.md (S9) | hırsızın evi alınır | hırsızın hanesine (malına ve ailesine) el konur | 家 burada haneyi anlatır |
| army.md (#11) | ayı gözleyerek | yıldızı ve ayı gözleyerek | 候星月 |

`act0-text.md` anlatıcısının «Yüeçi zenginleşiyordu / grew rich» satırına dokunulmadı: kayıtlı ses satırıdır ve alıntı değil uyarlamadır.

**İşlenme sınaması (2026-11-04).** Tablodaki sekiz düzeltme `army.md`, `settlement.md`, `d2/settlement.md`, `weather.md`, `d2/weather.md`, `progression.md` ve site `hikaye/tarih-kaynaklar.md`'de yerindedir. Tek eksik site `yerlesim/hanlik-merkezi.md`:52'dir: hâlâ «hırsızın evi alınır» der. Satır Çince değildir, bu sınamada değiştirilmedi. Site sayfalarındaki 37 ayrı Çince parçanın hepsi Vikikaynak ya da Kanripo metninde bulundu; tek istisna zaten etiket olan 東胡餘類'dır. Site sayfalarında Çince karakter düzeltmesi gerekmedi.

## 2. Kronoloji (#1)

### 2.1 Takvim kuralları

- Oyun takvimi `time.md` §2'dir: `yearBC = 212 − floor((dayN + 24) / 365)`, dolunay `1.044,75 + 29,530588·k`, 1. ay kış gündönümünden sonraki ikinci yeni ayda başlar. Tablo bu formülle betikle hesaplandı; K20 ve K25 tarihleri aynen tutar.
- Han yılı Wu Di'ye dek 10. ayda başlar [kaynak: yıl başlıkları HS 1]. Gaozu'nun yedinci yılının kışı (10.–12. ay) 7 Kasım 201 – 3 Şubat 200'dür; 10. ay 7 Kasım–6 Aralık 201'dir [kaynak: ytliu0 takvimi, aşağıda]. ZZTJ 11 başlığı aynı yılı 公元前二〇〇 yazar [kaynak]; bu yüzden Baideng geleneksel olarak «MÖ 200» yazılır, ama kuşatma oyunda Kasım 201'dedir, 10. ayın içindedir [çıkarım]. Üst sınırı HS 1 verir: 十二月，上還過趙 (12. ay 5 Ocak 200'de başlar).
- **Han ayının batı karşılığı.** Kaynak bir olayı Han ayıyla veriyorsa oyun günü o ayın Jülyen aralığına düşer. Aralık [Yuk Tung Liu'nun Çin takvimi çeviricisinden](https://ytliu0.github.io/ChineseCalendar/) alınır; site Ç'in ve erken Han takvimini Zhang Peiyu ve ötekilerinin *Zhongguo gudai lifa* (2008) kitabı üzerine yeniden kurar [kaynak]. Bağımsız sınama: HS 1'in günlü kayıtları (5. yıl 二月甲午 ve 六月壬辰; 6. yıl 甲申 (12. ay), 正月丙午, 五月丙午; 9. yıl 六月乙未晦，日有食之; 12. yıl 四月甲辰) gökbilimsel yeni aylarla aynı ay başlarını verir [çıkarım]. Oyunun kendi ay sayımı (kış gündönümünden sonraki ikinci yeni ay) bazı yıllarda Han ayından bir ay öndedir: 201'de oyunun 9. ayı 15 Eylül'de, Han'ın 9. ayı 9 Ekim'de başlar. Dolunay kuralı yine işler, ama Han ayının aralığı içinde.
- Kural: kaynakta olay varsa ve günü yoksa, gün en yakın anlamlı ay olayına bağlanır (dolunay, 5. ay, 8. ay). Hunların işe ayla girdiği [kaynak: SJ 110 舉事而候星月] için bu seçim keyfi değildir. Yine de gün [kurgu]dur.
- #1 gereği oyuncu metninde «dolayı», «c.» ve «MÖ 206–203» gibi aralıklar kalkar. Ayrım yalnız bu belgededir.

### 2.2 Tablo

Kesinlik: **K** kaynakta yıl ya da ay var; **S** kaynakta sıra var, yıl çıkarım; **Y** kaynakta tarih ve çoğu zaman olay yok, tamamı kurgu.

| Olay | Kaynak | K | Oyun tarihi (MÖ) | dayN | Yaş |
|---|---|---|---|---|---|
| Doğum, Dailin gecesi | Yok. «c. 234» dipnotsuz modern tahmin | Y | 27 Eylül 234 | −7.785 | 0 |
| Koyuna biner, kuş ve fare vurur | SJ 110 兒能騎羊，引弓射鳥鼠 | Y | 22 Eylül 228 | −5.600 | 5 |
| Tilki ve tavşan vurur | SJ 110 少長則射狐兔 | Y | 17 Eylül 222 | −3.415 | 11 |
| Yay gerer, zırhlı atlı sayılır | SJ 110 士力能毌弓 | Y | 4 Eylül 218 | −1.968 | 15 |
| Sevdiği eşle evlenir | SJ 110 愛妻; evlilik yok | Y | 12 Eylül 216 | −1.230 | 17 |
| Meng Tian Ordos'u alır | SJ 6 三十二年; SJ 110 悉收河南地 | K | 3 Ağustos 215 | −905 | 18 |
| Teoman'ın küçük oğlu doğar | SJ 110 生少子 | Y | 24 Haziran 214 | −580 | 19 |
| Hun kuzeye göçer; Orhun ve ilk sayım [kurgu] | SJ 110 頭曼不勝秦，北徙; SJ 6 三十三年 | K | 21 Eylül 214 | −491 | 19 |
| Teoman Mete'yi rehin vermeye karar verir | SJ 110 欲廢冒頓而立少子 | Y | 10 Eylül 213 | −137 | 20 |
| Mete yola çıkar | SJ 110 使冒頓質於月氏 | Y | 15 Aralık 213 | −41 | 21 |
| Rehineliğin 1. günü | Oyun takvimi (`time.md` Z16) | Y | 26 Ocak 212 | 1 | 21 |
| Birinci gösteri | Yok | Y | 21 Kasım 212 | 300 | 22 |
| İkinci gösteri | Yok | Y | 18 Aralık 211 | 692 | 23 |
| Birinci İmparator ölür | SJ 6 七月丙寅; 7. ayda 丙寅 yok, 6. ayın 丙寅'si alındı (tablo sonu) | K | 12 Temmuz 210 | 898 | 23 |
| Dailin Sayımı, Teoman'ın son sayımı | SJ 110 | Y | 8 Eylül 210 | 956 | 23 |
| Elçi yola çıkar | Yok | Y | 7 Ekim 210 | 985 | 24 |
| Meng Tian ölür | SJ 88 tarih vermez; SJ 110 十餘年而蒙恬死; yıl yalnız ZZTJ 7 (11. yy) | S | 6 Kasım 210 | 1.015 | 24 |
| Üçüncü gösteri, Gün I | K20 | Y | 2 Aralık 210 | 1.041 | 24 |
| Elçi Kışlak'a girer, Gün III | Yok | Y | 4 Aralık 210 | 1.043 | 24 |
| Teoman saldırır, Gün IV, 18:00 dolunay | SJ 110 頭曼急擊月氏 | Y | 5 Aralık 210 | 1.044 | 24 |
| Yüeçi ölüm kararı, Gün V | SJ 110 月氏欲殺冒頓 | Y | 6 Aralık 210 | 1.045 | 24 |
| Kaçış ve İlk Islıklı Ok, Gün VI | SJ 110 盜其善馬，騎之亡歸 | Y | 7 Aralık 210 | 1.046 | 24 |
| Eve döner | K7; SJ 110 頭曼以爲壯 | Y | 11 Nisan 209 | 1.171 | 24 |
| On bin atlı, II. Perde (dolunay ertesi) | K25; SJ 110 令將萬騎 | Y | 1 Haziran 209 | 1.222 | 24 |
| Islık yasası | SJ 110 令曰 | Y | 4 Haziran 209 | 1.225 | 24 |
| İlk av | SJ 110 行獵鳥獸 | Y | 6 Haziran 209 | 1.227 | 24 |
| Kendi atı | SJ 110 自射其善馬 | Y | 8 Haziran 209 | 1.229 | 24 |
| Sevdiği eş | SJ 110 自射其愛妻 | Y | 10 Haziran 209 | 1.231 | 24 |
| Tanhu'nun atı | SJ 110 射單于善馬 | Y | 13 Haziran 209 | 1.234 | 24 |
| Teoman ölür (ay %2) | SJ 110 射頭曼 | K yıl | 14 Haziran 209 | 1.235 | 24 |
| Tanhu olur; üvey ana, kardeş, karşı beyler ölür | SJ 110; yıl 徐廣 秦二世元年壬辰歲立 | K yıl | 15 Haziran 209 | 1.236 | 24 |
| İlk Lung-çeng, Kronik | SJ 110 五月 | Y | 30 Haziran 209 | 1.251 | 24 |
| III. Perde açılır (8. ayın yeni ayı) | K25 | Y | 1 Eylül 208 | 1.679 | 25 |
| Tunghu at ister | SJ 110 欲得頭曼時有千里馬 | S | 3 Eylül 208 | 1.681 | 25 |
| Tunghu hatun ister | SJ 110 欲得單于一閼氏 | S | 9 Eylül 208 | 1.687 | 25 |
| Dailin; toprak istenir; «Toprak devletin temelidir» | SJ 110 | S | 16 Eylül 208 | 1.694 | 25 |
| Tunghu baskını, şafak (ay %23) | SJ 110 東襲擊東胡 | S | 26 Eylül 208 | 1.704 | 25 |
| IV. Perde açılır | K25 | Y | 1 Haziran 205 | 2.682 | 28 |
| Loufan ve Baiyang bağlanır | SJ 110 南并樓煩、白羊河南王 | S | 8 Haziran 205 | 2.689 | 28 |
| Lung-çeng, 5. ay dolunayı | SJ 110 五月，大會蘢城 | K ay | 17 Haziran 205 | 2.698 | 28 |
| Meng Tian'ın aldığı topraklar döner | SJ 110 悉復收…至朝那、膚施 | S | 14 Eylül 205 | 2.787 | 28 |
| Yan ve Dai'ye akın | SJ 110 遂侵燕、代 | S | 3 Eylül 204 | 3.141 | 29 |
| Yüeçi batıya sürülür (dolunay) | SJ 110 西擊走月氏, yılsız; «203» yalnız Vikipedi, Di Cosmo görülmedi; Benjamin 176 der | S | 25 Haziran 203 | 3.436 | 30 |
| Han kurulur | SJ 8 甲午，乃即皇帝位 | K | 28 Şubat 202 | 3.684 | 31 |
| Kuzeyin beş ülkesi | SJ 110 後北服渾庾… | S | 15 Haziran 202 | 3.791 | 31 |
| Han Xin Mayi'de teslim olur | SJ 93; HS 1, 6. yıl, 秋九月 (Han 9. ayı 9 Ekim–6 Kasım 201) | K | 30 Ekim 201 | 4.293 | 33 |
| Han Xin Hun avlusuna sığınır, V. Perde | HS 1 七年冬十月…信亡走匈奴; K25 | K | 20 Kasım 201 | 4.314 | 33 |
| On Han elçisi, sürü gizlenir; Liu Jing görür, zincire vurulur | SJ 99 使者十輩 | K yıl | 22–23 Kasım 201 | 4.316 | 33 |
| Mete yalandan kaçar | SJ 110 詳敗走 | K yıl | 24 Kasım 201 | 4.318 | 33 |
| Baideng kuşatması başlar | SJ 110 圍高帝於白登，七日 | K yıl | 25 Kasım 201 | 4.319 | 33 |
| Dört renk at (dolunay); Chen Ping'in armağanı 30 Kasım | SJ 110, SJ 56 | K yıl | 28 Kasım 201 | 4.322 | 33 |
| Bir köşe açılır | SJ 110 解圍之一角 | K yıl | 1 Aralık 201 | 4.325 | 33 |
| Liu Jing ve heqin | SJ 99, SJ 110 yılsız; yıl yalnız ZZTJ 12 高帝九年 冬 (11. yy; kış 16 Kasım 199 – 11 Şubat 198) | K mevsim | 6 Aralık 199 | 5.060 | 35 |
| VI. Perde açılır; ertesi gün Lung-çeng | K25 | Y | 1 Haziran 198 | 5.237 | 35 |
| Han Xin ölür | HS 1 十一年…春正月 (Han 1. ayı 19 Şubat–20 Mart 196); SJ 93 | K ay | 13 Mart 196 | 5.887 | 37 |
| Liu Bang ölür | HS 1 夏四月甲辰 | K | 1 Haziran 195 | 6.332 | 38 |
| Lu Wan sığınır, «Tunghu Lu Kralı» | SJ 93; HS 1 | K yıl | 29 Haziran 195 | 6.360 | 38 |
| İmparatoriçe Lü'ye mektup (yazılış; 28 Şubat Chang'an'da) | HS 94A 孝惠、高后時, yılsız; yıl ZZTJ 12 惠帝三年 (11. yy); HS 2 三年春 yalnız prensesi tarihler | K mevsim | 13 Şubat 192 | 7.319 | 41 |
| Sağ Bilge Kral Ordos'a girer | SJ 110 其三年五月 (Han 5. ayı 17 Haziran–16 Temmuz 177) | K ay | 14 Temmuz 177 | 12.945 | 56 |
| Sağ Bilge Kral Yüeçi'ye gönderilir | SJ 110 使之西求月氏擊之 | K yıl | 11 Ekim 177 | 13.034 | 57 |
| Mektup yazılır (K yıl); Kunmo Mete'ye getirilir (Y) | SJ 110 其明年; SJ 123 yılsız, Benjamin 173 der | K / Y | 4 Haziran 176 | 13.270 | 57 |
| Mektup sınıra varır, 6. ayın ortası, gün [kurgu] | SJ 110 以六月中來至薪望之地 (Han 6. ayı 6 Temmuz–4 Ağustos 176) | K ay | 20 Temmuz 176 | 13.316 | 57 |
| Wen'in cevabı ve armağanları | SJ 110 孝文皇帝前六年 | K yıl | 14 Şubat 174 | 13.890 | 59 |
| Mete ölür, son Dailin | SJ 110 後頃之，冒頓死 | K yıl | 9 Eylül 174 | 14.097 | 59 |
| Jiyu (Laoshang) Tanhu olur | SJ 110 子稽粥立; 索隱 稽音雞，粥音育 | K yıl | 8 Ekim 174 | 14.126 | |

Ölüm yaşı: altmışına 18 gün kala. Üç batı günü Jülyen takvimiyle gün döngüsüne karşı sınandı ve tutuyor: 28 Şubat 202 甲午, 1 Haziran 195 甲辰, 10 Eylül 210 丙寅. Oyun yılında artık gün yoktur, bu günler oyun takvimine etiket olarak iner [çıkarım]. 七月丙寅 kuşkuludur: ZZTJ 7'nin Vikikaynak notu «此年七月丙子朔，無丙寅，或為丙申之誤» der [kaynak]. Yeniden kurulmuş takvimde 210'un 7. ayı 22 Temmuz'da (丙子) başlar, 8. ayı 21 Ağustos'ta: 10 Eylül 丙寅'dir ama 8. aydadır, yani yalnız mekanik çeviridir. Seçenekler: 7. ayın 丙申'si 11 Ağustos (ZZTJ notu), 6. ayın 丙寅'si 12 Temmuz. en.wikipedia 12 Temmuz 210'u yazar ve 8. yy *Kaiyuan Zhanjing* 90'ın «六月乙丑» (11 Temmuz) kaydını gösterir [kaynak: Vikipedi dipnotu, metin görülmedi]. Oyun 12 Temmuz'u alır: ay ile gün döngüsünü birlikte kurtaran tek okuma budur [çıkarım]. Gün oyuna etki etmez, haber kervanla I. Perde'de gelir. `act1.md` §1 ve site `hikaye/perde-1.md` «Birinci İmparator'un ölüm haberi (Eylül 210)» der: «(Temmuz 210)» olmalıdır. Eski «10 Eylül» Vikipedi'nin eski bilgi kutusundan zincirleme gelmiş olabilir [çıkarım].

Han ayıyla verilen öteki olaylar da yeniden kurulmuş takvimle sınandı (§2.1). Beş satırın günü kaynağın ayına düşmüyordu ve düzeltildi: Han Xin'in teslimi 30 Eylül'den 30 Ekim 201'e, heqin 7 Kasım'dan 6 Aralık 199'a, Han Xin'in ölümü 12 Şubat'tan 13 Mart 196'ya, Sağ Bilge Kral'ın akını 15 Haziran'dan 14 Temmuz 177'ye, mektubun varışı 3 Temmuz'dan 20 Temmuz 176'ya. Yeni günlerin dördü yine oyunun dolunayıdır; mektubun varışı «六月中»ın iki okumasına da uysun diye Han ayının 15. günüdür. Tutanlar: Han Xin'in kaçışı 20 Kasım 201 (10. ay 7 Kasım–6 Aralık), Baideng 25 Kasım–1 Aralık 201 (10. ay), Lü'ye mektup 13 Şubat 192 (bahar 5 Şubat'ta başlar), Wen'in cevabı 14 Şubat 174, Liu Bang'ın ölümü 1 Haziran 195. Lu Wan'ın kaçışı 29 Haziran 195'tir: SJ 93 «四月，高祖崩，盧綰遂將其眾亡入匈奴» der, 四月 ölümün ayıdır; kaçış haberden sonradır ve Han'ın 5. ayına (7 Haziran–5 Temmuz) düşer [çıkarım]. Yaş tablosu `omurga.md`'yi düzeltir: II 24, III 25, IV 28–30, V 33, VI 35–59.

### 2.3 Ay ile örtüşenler

| Tarih | Ay | Anlam |
|---|---|---|
| 1 Haziran 209 | Dolunay ertesi | Mete on bin atlıyı alır |
| 14 Haziran 209 | %2, ertesi gün yeni ay | Darbe: Hun kuralı ay eksilince geri çekilir. Mete ayı dinlemez [kurgu] |
| 1 ve 16 Eylül 208 | 8. ayın yeni ayı ve dolunayı | III. Perde'nin K25 günü zaten yeni aydır; dolunay Dailin |
| 26 Eylül 208 | %23 | Tunghu Hunun eksilen ayda gelmeyeceğini bilir: 不爲備 [kurgu] |
| 28 Kasım, 1 Aralık 201 | Dolunay, eksilme başı | Baideng: 月盛壯則攻戰; kuşatma kalkar: 月虧則退兵 [çıkarım] |
| 2 Haziran 198 | 5. ay dolunayı | VI'nın 2. günü Lung-çeng |

Y ve S satırlarının günü §2.1 kuralıyla dolunaya bağlandı: bu uyum seçimdir, kanıt değildir. K25 günlerinin ay evresi rastlantıdır.

## 3. Açılışın tarihi (#3)

**Sorun.** `act1.md` §1: «Her güz rehine Kemik Boğazı'nda Hun elçisine canlı gösterilir; perde o gösteriden dönen arabada açılır.» Gün I 2 Aralık'tır, takvimde kış 16 Kasım'da başlar. Palak §8.2'de «Elçi güzde gelir. Bu kış ikinci kez geldi.» der.

### 3.1 Rehine uygulaması

- 質 Shiji 110'un sözcüğüdür: 乃使冒頓質於月氏 [kaynak].
- En yakın örnek yine Shiji 110'dadır. Yan'ın Qin Kai'si Hulara rehin gider, güvenlerini kazanır, döner, Tunghu'yu bin li geri sürer: 爲質於胡，胡甚信之。歸而襲破走東胡 [kaynak]. I. Perde'nin Güven eksenine tarihsel öncüldür.
- Bozkırda rehine bir küçük ülkenin iki büyük arasında yaşama yoludur. Loulan bir oğlunu Hunlara, birini Han'a verir: 遣一子質匈奴，一子質漢. Kralı «小國在大國間，不兩屬無以自安» der [kaynak: HS 96A, Mete'den sonra].
- Rehine ölürse Hun Yüeçi'ye saldırır, ama Teoman tam bunu ister: oğlunu ölüme göndermiştir (SJ 110) [çıkarım].
- Yang Lien-sheng'in 1952 tarihli makalesi konunun temel çalışmasıdır, künyesi ikincil kaynaktan görüldü, metni okunmadı.
- Rehinenin yılda bir elçiye gösterildiğine dair kaynak bulunamadı. Gösteri [kurgu]dur, gerekçesi [çıkarım]: rehine yaşamıyorsa rehin hükümsüzdür.

### 3.2 Elçi trafiği

- Hun elçisi saygı görür: Tanhu'dan bir tek belge taşıyanı ülkeler yol boyu besler, geciktirmez. 匈奴使持單于一信，則國國傳送食，不敢留苦 [kaynak: SJ 123, sonraki dönem]. Eskam'ın Altın Levhası bu 信'in oyundaki karşılığıdır [kurgu].
- Mete'nin 176 elçisi Xi Huqian (SJ 110 係雩淺, HS 94A 係虖淺; 雩, 虖 yorumlarda «hu» okunur) mektubu «六月中» sınıra getirir: yolculuk aya göre söylenir [kaynak: SJ 110]. 月中 «ayın içinde» de demektir; «ayın ortası» okuması [çıkarım]dır.
- Eskam'ın makamı (Gudu, Huyan soyundan) kaynağa uyar: Gudu «異姓大臣»dir [kaynak: SJ 110 notu].

### 3.3 Hun takvimi

| Zaman | Olay | Kaynak | MÖ 210'da oyunda |
|---|---|---|---|
| 1. ay | Küçük toplantı, avluda kurban | SJ 110 歳正月，諸長小會單于庭，祠 | 29 Ocak |
| 5. ay | Lung-çeng, atalara, göğe, yere, ruhlara | SJ 110 五月，大會蘢城 | 27 Mayıs–26 Haziran; dolunay 11 Haziran |
| 8. ay, dolunay [kurgu] | Dailin, at semizken, sayım | SJ 110 秋，馬肥; 集解 秋社八月中 | 8 Eylül |
| 1., 5., 9. ay | Üç tören, 戊 günleri | HHS 89, Güney Hunları, MS 1. yy | Türk yazınındaki «9. ay» buradan gelir [çıkarım] |

### 3.4 Hexi iklimi

- Hanshu'da Wang Mang'ın komutanı Yan You (嚴尤) seferi kötülerken Hun ülkesini şöyle anlatır: 胡地秋冬甚寒，春夏甚風 [kaynak: HS 94B]. Söz MS 11 dolaylarındandır, Mete'den iki yüzyıldan çok sonradır; iklim için yine kullanılır, çağı için değil.
- Zhangye (1.461 m): soğuk çöl iklimi, ocak ortalaması −9,3 °C, yılda 131,8 mm yağış, yağışın çoğu yazın, 20,9 karlı gün [kaynak: Vikipedi tablosu, 1991–2020]. Aynı sayfanın metni −9,1 °C ve 132,6 mm yazar, karı da çok seyrek sayar; tablo esas alındı. Bugünkü iklimdir.
- Kışlağın yeri Çilyan eteğindedir, ≈2.300 m [kurgu; başka belgede dayanağı yok]. Bugünkü Yugur çobanları kış ve bahar otlağını 2.000–3.000 m'de tutar (`groups-research.md` §5).
- Hey Irmağı'nın donma tarihi ve Çilyan'ın ilk karı için kaynak bulunamadı. Oyunun kışı 16 Kasım'da başlar (`time.md` §2, `d2/core.md`), Gün I'de karlıdır (K22 `hexi`).

### 3.5 Yol ve hesap

Tanhu Kampı (Orhun) ile Kışlak arası kuş uçuşu 987 km, `r_hexi_tanhu` yol katsayısıyla ≈1.173 km'dir [çıkarım: `travel.md` 63,6 / 53,5]. Yol Hey Irmağı, Alaşan, Gobi'dir (`travel.md` §9.2). SJ 111 踰居延，遂過小月氏，攻祁連山 Juyan'dan Çilyan'a inişi verir; Huo Qubing'in MÖ 121 seferidir, bu yön için dolaylı dayanaktır [çıkarım].

| Binek (`travel.md`) | km/gün | Gün | Kış ×0,7 ile |
|---|---|---|---|
| Hafif atlı, SJ 99 輕騎一日一夜 (≈291 km) | 291 | 4 | Retorik üst sınır |
| `remount` | 60 | 20 | 28 |
| `ride` | 40 | 29 | 42 |
| `camel` | 30 | 39 | 56 |
| `cart` | 25 | 47 | 67 |
| `ox` | 16 | 73 | 105 |

**Birim uyarısı.** `travel.md` §9.1 bu hızları gösterim km'si için verir: harita 1:18,5 sıkıştırılmıştır, atlas `r_hexi_tanhu`'yu at 2, araba 3, öküz 4,5 günde gösterir. Bu tablo aynı hızları gerçek km'ye uygular, yani gerçek yol süresi varsayımıdır [çıkarım]. Oyuncu metninde «50 gün» geçmez; yeri Destan Kitabı'nın «Gerçekte ≈990 km» satırıdır.

Elçi armağan arabasıyla gider, `cart` hızındadır. Takvim [kurgu]:

1. Dailin Sayımı: 8 Eylül 210. Sayım batı boylarından çetelelerin gelmesiyle kapanır.
2. Yola çıkış: sayımı izleyen dolunay, 7 Ekim. Dayanak: 舉事而候星月.
3. 7 Ekim–16 Kasım: 40 gün × 25 km = 1.000 km.
4. 16 Kasım'dan sonra kış çarpanı: kalan 173 km / 17,5 km = 10 gün. Varış 26 Kasım.
5. Yüeçi elçiyi Kapı dışında 5 gün bekletir: bu bekletiş Amaga'nın gücüdür.
6. Gösteri 2 Aralık sabahı. Araba 10:40'ta Kışlak'a girer (`act1.md` §5). Gün III'te elçi bu kez kampın içindedir.

Aynı kural öteki yıllarda 21 Kasım 212 (47 gün yol) ve 18 Aralık 211 (55 gün yol) verir: üç gösteri de kışın ilk beş haftasındadır, «üç kış» sözü (`act1.md` §1) tutar. Bu açıklama K20 ve K25'in hiçbir tarihini değiştirmez.

### 3.6 Düzeltilecek cümleler

**`act1.md` §1 ve site `hikaye/perde-1.md`, «Her güz…» cümlesinin yerine:**

> Her yıl Dailin Sayımı'ndan sonraki dolunayda Hun elçisi yola çıkar, kışın ilk haftalarında Kemik Boğazı'na varır; rehine ona canlı gösterilir, Hun sayımının son satırı odur. Perde o gösteriden dönen arabada, 2 Aralık MÖ 210 sabahı açılır.

**`act1.md` §8.2, Palak:**

> «Elçi yılda bir gelir. Bu kış iki kez geldi.» / «The envoy comes once a year. This winter he came twice.»

Satır «Yüeçiler sayıyla konuşur» kuralına da daha iyi oturur. Site `perde-1.md` sonundaki `[!ACIK]` kutusu kalkar.

## 4. Dailin Sayımı (#44)

**Anlamı.** Yalnız ilk satır Sima Qian'ındır; öteki yorumlar Mete'den 350–900 yıl sonradır, §6.3'teki kazılar gibi görünüş için alınır.
- SJ 110: 秋，馬肥，大會蹛林，課校人畜計. Güzün at semizken büyük toplantı, insan ve hayvan sayılır [kaynak].
- Fu Qian (Doğu Han) ve Hanshu Yinyi: 匈奴秋社八月中皆會祭處. Hunların güz kurbanı, 8. ayda herkesin toplandığı yer [kaynak]. 中 «ortası» değil «içinde» de olabilir [çıkarım].
- Zheng: yer adıdır. Jin Zhuo, Li Ling'in Su Wu'ya mektubundaki 相競趨蹛林 sözünü gösterir; «則服虔說是也» (öyleyse Fu Qian haklıdır) sonucu alıntının dışındadır, Sima Zhen'indir. Yao: 林 ile 襤 ses yakındır, belki SJ 81'deki 襜襤 halkıdır (索隱) [kaynak].
- Yan Shigu (581–645; HS 94A notu, 正義 aktarır): 蹛者，遶林木而祭也。鮮卑之俗，自古相傳，秋祭無林木者，尚豎柳枝，眾騎馳遶三周乃止，此其遺法也. Ağaç yoksa söğüt dalı dikilir, atlılar üç tur atar: bu Xianbei âdetidir [kaynak]. Hun'a bağlaması Yan'ın kendi çıkarımıdır, oyun için [çıkarım]dır.
- Türk yazınında (Ögel'e dayanarak Seyitdanlıoğlu) Tai-lin savaş ve sayım toplantısıdır: atlar güçlüdür, Çin'de harman vaktidir. Zhonghang Yue'nin «候秋孰，以騎馳蹂而稼穡» sözü aynı mevsim mantığını destekler [çıkarım].

`groups-research.md` «蹛 tören okuması doğrulanamadı» diyordu; artık yorum düzeyinde desteklendi, kesinleşmedi. `settlement.md` §1.3'teki «yeri bilinmez» tercihi geçerlidir: kaynaklar yerde de törende de birleşmez.

**Kural önerisi.** `time.md` §2 «doy 234–318 içindeki ilk dolunay» yerine **8. ayın dolunayı**. Sonuç 212–174 arasındaki 39 yılın 30'unda aynıdır; 209, 206, 203, 195, 192, 189, 184, 181 ve 178'de ilk kural 22–28 Ağustos'a, yani oyunun 7. ayına düşüyordu, yeni kural bir ay sonrasını verir. Yeni kural da 212, 198 ve 187'de 29–30 Ağustos'u verir: gerekçe ağustostan kaçmak değil, Fu Qian'ın «八月中»ına bağlı kalmaktır [çıkarım; betikle `time.md` §2 formülünden hesaplandı].

| Yıl | 8. ay başı | Dailin | dayN | Not |
|---|---|---|---|---|
| 212 | 16 Ağustos | 30 Ağustos | 217 | Birinci gösteri yılı |
| 210 | 24 Ağustos | 8 Eylül | 956 | Elçinin çıkış yılı |
| 209 | 12 Eylül | 27 Eylül | 1.340 | Kronik: Mete'nin Tanhu olarak ilk sayımı |
| **208** | **1 Eylül** | **16 Eylül** | **1.694** | **III. Perde, oynanır** |
| **174** | **25 Ağustos** | **9 Eylül** | **14.097** | **VI. Perde, oynanır** |

**Hangi perde, hangi gün.**
- **III. Perde, 16 Eylül MÖ 208.** Perde 1 Eylül'de açılır, Dailin takvimin 16. günüdür. K25'in 12 gün ±%30 ölçüsünü 0,4 gün aşar; cevap #19 bu ölçüyü yalnız tasarım ölçüsü yaptığı için kural bozulmaz. Bu sayım perdenin doruğudur: bütün atlılar toplanmıştır, Tunghu elçisi üçüncü isteği getirir, Mete «地者，國之本也» der, toprağı vermek isteyenler ölür, 令國中有後者斬 aynı gün çıkar. Toplantı seferberliğe döner. Tarih Tunghu'nun hazırlıksız yakalandığını söyler (不爲備); baskın 26 Eylül şafağıdır.
- **VI. Perde, 9 Eylül MÖ 174.** Son sayım. Sayan Mete'dir, sayım sürerken ölür. VI'nın 198'den 174'e yıl sıçraması bu güze iner. Site `yerlesim/hanlik-merkezi.md`'deki `[!ACIK]` ve «III'te sayım olmasın» önerisi kalkar: III'te de oynanır.
- Öteki yıllar Kronik satırıdır.

## 5. Yazım birliği (#9)

### 5.1 Okunan kaynaklardaki biçimler

| Kaynak | Hun | Mete | Teoman | Yuezhi | Donghu | Öteki |
|---|---|---|---|---|---|---|
| Eberhard, *Çin Tarihi*, 1947 | Hsiung-nu | Mao-tun (Mete) | T'ou-man (okunuşu Tov-man) | Yüeh-chih (okunuşu Yüe-cı) | | Ch'in, Wu-sun, Ting-ling, Ch'iang, Shan-yü, Pai-teng (okunuşu Bay-dınğ) |
| Taşağıl, *Tarih Dergisi* 2023; İng. makalesi | Hsiung-nu (Hun) | Mo-tu, Mo-tun | T'ou-man | Yüe-chih | Tung-hu, Tunghu | Wu-sun |
| Ögel, *Büyük Hun İmp. Tarihi*; 1948 makalesi | Hun, Hiung-nu | Mete | Tuman | Yüeçi | Tunghu | Makale adı Wu-sun; kitap biçimleri yalnız kitapçı dökümü özetinden, metin okunmadı |
| Çerçi, Hunlar'da Sosyal… | Hiung-Nu, Hun | Mete | Teoman, Tuman | Yüe-çi | Tung-hu | Tanhu, Şan-yü, Wu-sun, Lao-shang, Ki-ok |
| Pamir, ÇÜHAD 2022 | Hiung-nu | Mete (Mo-tun) | Teoman (Tümen, Tuman) | Yüeh-chi | Tung-hu | Tan-hu |
| Seyitdanlıoğlu, Toy makalesi | Hsiung-nu | Mao-tun | | | | Shan-yü (Tan-hu), Lung-ch'eng, Tai-lin |
| tr.wikipedia, Usunlar | Hiung-nu | | | Yüeçi | | Usun, Wusun, Vusun, Kun-mo |

Kafesoğlu'nun metnine erişilemedi: kaynak bulunamadı. Lou-fan ve Pai-yang okunan metinlerin hiçbirinde geçmiyor.

### 5.2 Kural

Türk tarihçiliğinde yerleşik Türkçe biçim varsa o alınır. Yoksa Türkçe okunabilen pinyin alınır. Kişi adları pinyin kalır (K16 Mete ve Teoman dışında). Tire yalnız yerleşikse durur.

**Sınama (2026-11-04).** Bu kural tabloyu açıklamıyordu. Türk yazınındaki Wade-Giles biçimleri (Ting-ling, Lung-ch'eng, Tai-lin, Pai-teng) «yerleşik» sayılırsa Dailin ve Baideng kurala aykırıdır; sayılmazsa Ting-ling ve Lung-çeng aykırıdır. Tablo ikisini birden yapıyordu. Seyitdanlıoğlu'nun metni Lung-ch'eng ve Tai-lin yazar, Lung-çeng yazmaz [kaynak]. Kural şöyle düzeltildi:

1. Türkçe biçimi olan ad o biçimle yazılır: Hun, Tanhu, Mete, Teoman, Yüeçi, Tunghu, Usun.
2. Öteki adlar Türkçe okunabilen pinyin'dir, tiresiz: Dingling, Dailin, Baideng, Loufan, Baiyang, Çiang, Kunmo, Hunyü, Çüşe, Şinli. Pinyin q Türkçede ç, x ş olur (Xinjiang: Şincan).
3. İki proje içi istisna kalır: Ç'in (Çin'le karışmasın) ve Lung-çeng (belgelerde ve sitede 83 kez geçer; Lung-ch'eng'in Türkçe okunuşudur) [çıkarım].
4. Wade-Giles biçimleri yalnız Destan notunda «Türk tarih yazınında Ting-ling, Tai-lin, Pai-teng» diye geçer.

Bu düzeltmeyle Ting-ling Dingling'e döner. Proje de çoğunlukla Dingling yazar: belgelerde 36, sitede 12 kez; Ting-ling 6 kez.

### 5.3 Tablo

| TR | EN | Çince | Nerede kullanılır | Değişen |
|---|---|---|---|---|
| Hun, Hunlar | Hun, Huns (konuşma); Xiongnu (yazı) | 匈奴 | §5.4 | |
| Hun Tanhuluğu | Xiongnu | 匈奴 | Atlas (K8) | |
| Tanhu | Tanhu | 單于 | Her yer (#35); kaynak notunda «Çin yazımı chanyu» | «Kağan», «hanlık» oyuncu metninden kalkar |
| Mete | Mete | 冒頓 | Her yer (K16); Destan notunda Modu, Mo-tun | |
| Teoman | Teoman | 頭曼 | Her yer | Tuman yalnız araştırmada |
| Yüeçi | Yuezhi | 月氏 | Her yer | |
| Tunghu | Donghu | 東胡 | Her yer | `geo.js` Tung-hu ×9, `geography.js` ×1, `act0/narrator.js` ×1 (yalnız TR altyazı) |
| Ç'in | Qin | 秦 | Hanedan ve ülke | «Çin» modern ülke anlamında kalır. Ç'in proje içi biçimdir (`geo.js`, `act1.md`): okunan kaynaklar Ch'in yazar; §5.2 madde 3'ün istisnasıdır, Çin'le karışmasın diye kalır [çıkarım] |
| Han | Han | 漢 | Her yer | |
| Usun | Wusun | 烏孫 | Her yer | `geo.js` Vusun ×4, `geography.js` ×1; site ve belgeler |
| Kunmo | Kunmo | 昆莫 | VI. Perde | Yeni |
| Dingling | Dingling | 丁零 | Atlas, Destan | `geo.js` TR Dingling kalır, `sub` kalkar; Destan notu «Türk yazınında Ting-ling» (§5.2 madde 2) |
| Loufan, Baiyang | Loufan, Baiyang | 樓煩, 白羊 | IV. Perde | |
| Çiang | Qiang | 羌 | Atlas | |
| Lung-çeng | Longcheng | 蘢城 | Toplantı, iç harita | Hanshu 龍城 yazar. Proje içi istisna (§5.2 madde 3); Türk yazınında Lung-ch'eng |
| Dailin | Dailin | 蹛林 | Toplantı | Pinyin (§5.2 madde 2); Türk yazınında Tai-lin, yalnız Destan notunda |
| Baideng | Baideng | 白登 | V. Perde | Pinyin; Eberhard Pai-teng yazar |
| Hunyü, Çüşe, Gekun, Şinli | Hunyu, Qushe, Gekun, Xinli | 渾庾, 屈射, 鬲昆, 薪犁 | Atlas | «Hun-yü» ve «Sinli» düzeltildi: tire yerleşik değil, x Türkçede ş olur |
| Laoshang (Jiyu) | Laoshang (Jiyu) | 老上, 稽粥 | Sonsöz | 索隱 «稽音雞。粥音育»: okunuş Jiyu'dur, en.wikipedia de Jiyu yazar. Benjamin ve proje belgeleri Jizhu yazar (粥'nin öteki okunuşu); Çerçi Ki-ok der |

`Değişen` sütunundaki `geo.js`, `geography.js` ve `act0/narrator.js` Three.js prototipinin dosyalarıdır. Godot projesinde tablodaki adlardan yalnız «Mete» ve «Hun» geçer (`game/data/kisiler.json`), ikisi de tabloya uyar; değişen adların hiçbiri Godot'da henüz yazılı değildir. Godot'daki yeri «Godot için» madde 5'tedir.

### 5.4 İngilizcede Xiongnu ve Hun

**Karar: kim konuşuyorsa onun sözü.** Atlas, Destan Kitabı, kronik kartı ve Han ağzı **Xiongnu**; anlatıcı, ozan, Hun ve Yüeçi ağzı **Hun**. Atlas açıklaması ilk açılışta bir kez köprü kurar: bugünkü `geo.js` metni zaten «The Chinese sources call them Xiongnu» der, sonuna «the steppe says Hun» eklenir.

Gerekçe:
- K8 atlası Xiongnu yapar, kaydedilmiş `act0.narr.2` ise «the Huns» der. İkisi de kalır, yeniden kayıt gerekmez.
- Bilimsel İngilizcede Xiongnu kurumsal addır. Atwood adı önce hanedan adı sayar [kaynak: Vikipedi üzerinden].
- Hun sözünü tek başına kullanmak İngiliz oyuncuda Attila'yı çağırır; yalnız Xiongnu kullanmak da «This is closed to you, Hun.» gibi kısa satırları öldürür.
- Bağ savunulabilir: de la Vaissière Soğd mektuplarında iki ad için tek sözcük (xwn) görür; Maróti ve ötekiler Avrupa Hunlarının bir kesiminde Xiongnu kökenli soy bulur. Ama uzlaşı yoktur [kaynak: Vikipedi üzerinden; Iranica maddesi 403 verdi, Maróti'nin özeti görüldü].

## 6. Senaryo malzemesi

### 6.1 Olaylar ve perdeler

Tarih §2.2'dedir. Perdeler K25'e göredir; adları `story.md`'nindir.

| Olay | Kaynak ve kısa satır | Etiket | Önerilen yer |
|---|---|---|---|
| Hun 215'e dek Ordos'tadır | SJ 110 悉收河南地 · 頭曼不勝秦，北徙 | [kaynak]; doğum yeri [çıkarım] | Giriş sineması: doğum ve çocukluk Ordos'ta, ana kampta değil. K6 bozulmaz |
| Gözde hatun, küçük oğul | SJ 110 後有所愛閼氏，生少子 | [kaynak]; adlar [kurgu] | Sinema; II'de sahne |
| Rehinelik | SJ 110 乃使冒頓質於月氏 | [kaynak] | Sinema, I |
| Yüeçi saldırısı | SJ 110 頭曼急擊月氏 | [kaynak] | I, Gün IV |
| Kaçış | SJ 110 盜其善馬，騎之亡歸 | [kaynak] | I, Gün VI. Metin at çalındı der; Adak Aygırı uyar |
| Islıklı ok sınavları | SJ 110; beş basamak | [kaynak] | II. `army.md` §6.3 |
| Darbe; üvey ana, kardeş, beyler | SJ 110 從其父單于頭曼獵 · 遂盡誅其後母與弟及大臣不聽從者 | [kaynak] | II sonu: av sırasında; ölümler ekran dışı, çocuk görünmez |
| Babanın hatunları | SJ 99 冒頓殺父代立，妻群母 | [kaynak] | III açılış, yalnız söz |
| Tunghu'nun üç isteği | SJ 110 柰何與人鄰國而愛一馬乎 | [kaynak] | III. At, sonra hatun, sonra toprak |
| Tunghu seferi ve artığı | SJ 110 令國中有後者斬，遂東襲擊東胡; HHS 90 餘類保烏桓山 | [kaynak] | III, `donghu_land`; sonda atlas |
| Yüeçi'nin sürülmesi | SJ 110 西擊走月氏; SJ 123 故時彊，輕匈奴，及冒頓立，攻破月氏 | [kaynak] | IV, `hexi_ash`. SJ sırası Yüeçi önce der; oyun dramatik sırayla sona alır [kurgu]. Bu sıra Tanhu 1'in IV'üne benzer, bkz. «Belirsizlikler» |
| Loufan ve Baiyang | SJ 110; SJ 99 去長安近者七百里 | [kaynak] | IV, `ordos`. 127'ye dek yerindedirler |
| Meng Tian'ın toprakları | SJ 110 至朝那、膚施 | [kaynak] | IV, Kronik; atlas sınırı |
| Çu ve Han savaşı | SJ 110 是時漢兵與項羽相距 | [kaynak] | IV, atlas: Mete boşluğu kullanır |
| Hunyu, Qushe, Dingling, Gekun, Xinli | SJ 110 後北服 | [kaynak]; üçünün yeri bilinmez | IV ile V arası Kronik; `dingling_north` seçmeli |
| Han Xin'in teslimi | SJ 93 信恐誅…以馬邑降胡 | [kaynak] | V açılış kartı; Xin kuşkuyla iter |
| On elçi, gizlenen sürü, Liu Jing | SJ 99 匈奴匿其壯士肥牛馬，但見老弱及羸畜 · 此必欲見短，伏奇兵以爭利 | [kaynak] | V görevi; öneri 11 |
| Baideng, dört renk at | SJ 110 | [kaynak] | V doruk; `four_winds` |
| Chen Ping ve hatun | SJ 56 其計祕，世莫得聞; Huan Tan'a göre Han güzeli korkusu | [kaynak]; ayrıntı yorum | V: hatun sahnesi; hatunun sözü SJ 110 兩主不相困 |
| Köşe açılır | SJ 110 乃解圍之一角 | [kaynak] | V sonu. Wang Huang ve Zhao Li'nin gelmeyişi de nedendir |
| Liu Jing ve heqin | SJ 99 取家人子名為長公主; SJ 110 宗室女公主 | [kaynak]; kaynaklar çelişir, yıl da | V ile VI arası; prenses VI'da |
| Tuidang ve Han beyleri | SJ 93 及至穨當城，生子 | [kaynak] | VI: Hun ülkesinde doğan Han kâtibi yalnız 176 için olur, Tuidang 192'de en çok 9 yaşındadır [kurgu] |
| 192 mektubu, Lü'nün cevabı | HS 94A 孤僨之君，生於沮澤之中，長於平野牛馬之域 · 年老氣衰，髮齒墮落 · 噲可斬也 | [kaynak] | VI, yıl sıçraması; Mete özür diler, at yollar |
| Kunmo | SJ 123 烏嗛肉蜚其上，狼往乳之。單于怪以爲神，而收長之; HS 61 見狼乳之 | [kaynak]; hangi Tanhu: «Belirsizlikler» | VI, 4 Haziran 176 |
| Sağ Bilge Kral | SJ 110 其三年五月…侵盜上郡葆塞蠻夷 | [kaynak] | VI: Han'la barışı bozan bey; ceza olarak batıya gider |
| 176 mektubu ve armağanı | SJ 110 天所立匈奴大單于 · 諸引弓之民，并爲一家 · 獻橐他一匹，騎馬二匹，駕二駟 | [kaynak] | VI doruk; `fauna.md` |
| Ölüm | SJ 110 後頃之，冒頓死，子稽粥立 | [kaynak] | VI sonu |
| Sonsöz | HS 96A 以其頭為飲器; SJ 110 疏記，以計課其人眾畜物; SJ 123 單于死，昆莫乃率其眾遠徙 | [kaynak] | Oğlun yaptığı; sayım yazıya geçer; Kunmo yıllar sonra ayrılır: bu 單于 Mete olamaz, oyunda bebek 174'te 2 yaşındadır [çıkarım] |

**Kaynakta adı olan kişiler.** Teoman (頭曼), Mete (冒頓), Jiyu (稽粥; 索隱 粥音育, «Jizhu» bu okunuşa uymaz), Han Xin (韓王信), Wang Huang (王黃), Zhao Li (趙利), Manqiu Chen (曼丘臣), Liu Bang, Liu Jing (劉敬), Chen Ping (陳平), Fan Kuai (樊噲), Ji Bu (季布), İmparatoriçe Lü, Zhang Ze (張澤; ZZTJ 12 張釋 yazar), Lu Wan (盧綰), Guan Ying (灌嬰), Xi Huqian (係雩淺), Zhang Sheng (張勝, Yan elçisi, 習胡事, SJ 93), Zang Yan (臧衍, Hun ülkesinde sürgün Yan beyi, SJ 93), Nandoumi (難兜靡), Bujiu Xihou (布就翖侯; Vikikaynak 翎 basar, Kanripo Wenyuange metni 翖 yazar ve Yan Shigu «翖與翕同» der), Kunmo (昆莫), Zhonghang Yue (中行說), Tuidang (穨當), Ying (嬰), Meng Tian (蒙恬), Qin Kai (秦開). **Adı olmayanlar** [kurgu listesine ad yazılabilir]: gözde hatun, küçük oğul, Mete'nin anası, sevdiği eş, Tunghu'ya verilen hatun, Tunghu Kralı, Baideng hatunu, Yüeçi Kralı, Sağ Bilge Kral.

### 6.2 Hun devlet düzeni

**Unvanlar [kaynak: SJ 110, HS 94A].**
- Tanhu'nun tam unvanı: 撐犁孤塗單于. Hunca 撐犁 gök, 孤塗 oğul, 單于 «geniş» demektir: «Göğün oğlu Tanhu». 撐犁 sözcüğü genelde Tengri ile eşlenir [çıkarım]; K13 Tengri'yi mitoloji sayar, bu yüzden kurgu listesine girmez.
- 176 mektubunda Mete kendini 天所立匈奴大單于 diye yazar.
- Soy: 攣鞮氏 (Luandi). Büyük soylar 呼衍, 蘭, sonra 須卜. Makamlar soydan geçer.
- Sol doğu, sağ batıdır. Sol Bilge Kral veliahttır (左屠耆王). Hunca 屠耆 «bilge».
- Hatun karşılığı 閼氏: Su Lin «焉支» okur, «Han imparatoriçesi gibi» der. Xi Zaochi, kızıl boya 烟肢'den gelir, «onun kadar sevimli» demektir der [kaynak: SJ 110, SJ 56 notları]. Hexi'nin Yanzhi dağıyla ses bağı oyun için kullanılabilir [kurgu]. «Hatun» sözü dönem sonrasıdır, oyun dilinin tercihidir.

**24 komutan ve onluk [kaynak].** Altı çift makam (12): Bilge Kral, Luli Kral, Büyük Komutan, Büyük Buyrukçu, Büyük Danghu, Gudu. 大者萬騎，小者數千，凡二十四長. Her biri kendi 千長、百長、什長, ayrıca 裨小王、相、都尉、當戶、且渠 atar. `army.md` §1 doğru özetler.

**Hukuk [kaynak: SJ 110].** Bir karış bıçak çeken ölür (拔刃尺者死). Hırsızın hanesine el konur (坐盜者沒入其家). Küçük suç 軋: yüz kesme (Fu Qian) ya da ayak bileği ezme (Yan Shigu), ekran dışı. Büyük suç ölüm. Dava en çok on gün sürer (獄久者不過十日). Bütün ülkede birkaç mahkûm olur (一國之囚不過數人): zindan yok.

**Söz ve yazı [kaynak: SJ 110].** 毋文書，以言語爲約束: yazı yok, söz bağlar. 其俗有名不諱，而無姓字: ad söylemek yasak değil, soyadı yok. Tunghu'nun torunlarında çağrı çentikli ağaçla yapılır: 大人有所召呼，則刻木為信 [kaynak: HHS 90]. Hun için [çıkarım]. Yazı Mete'den sonra gelir: Zhonghang Yue 疏記. Mektupları Han'dan gelenler yazmıştır [çıkarım]; Eberhard da Çinli kaçakların Mete'ye memurluk ettiğini sanır [kaynak]. 毋文書 bir Han tanıklığıdır: Noin-Ula'da 20'den çok oyma işaret bulunduğu, kimilerinin bunu yazı saydığı Vikipedi üzerinden görüldü (Ishjamts 1996, metni okunmadı; çağı Mete'den sonra). Vikipedi 刻木 ve «Hu yazısı»nı SJ 110'a atfeder, SJ 110'da ikisi de yoktur; 刻木 HHS 90 ve SGZ 30'da, 胡書 SGZ 30 ve Suishu 83'tedir. Bu zincir kullanılmaz.

**Cenaze [kaynak: SJ 110].** 其送死，有棺槨金銀衣裘，而無封樹喪服: tabut, altın, gümüş, kürk var; höyük, ağaç, yas giysisi yok. 近幸臣妾從死者，多至數千百人 (HS 94A: 數十百人; Yan Shigu «kimi onlarca, kimi yüz»). Mezara Hunca 逗落 denir [kaynak: Zhang Hua, SJ 110 notu].

**Evlilik [kaynak: SJ 110].** 父死，妻其後母；兄弟死，皆取其妻妻之. Zhonghang Yue'nin savunması: 惡種姓之失也, soy kaybolmasın diye.

**Çocuk ve er [kaynak: SJ 110].** 兒能騎羊，引弓射鳥鼠；少長則射狐兔：用爲食。士力能毌弓，盡爲甲騎. Silah: 弓矢, 刀鋋. 壯者食肥美，老者食其餘: en iyi lokma gence, yaşlıya artan.

**Mevsim [kaynak].** 寬則隨畜…急則人習戰攻 (SJ 110). Güz: at semiz, Han harmanı akın vaktidir (SJ 110 Zhonghang Yue). Kış: HS 94B 甚寒 (Yan You'nun MS 11 dolaylarındaki sözü). K24'ün dört mevsimiyle çelişmez.

**Oturma ve kapı [kaynak].** 其坐，長左而北鄉: oturak kuzeye bakar, sol üstündür (SJ 110 ve 正義). 單于朝出營，拜日之始生. Tunghu kökenli Wuhuan'da 以穹廬為舍，東開向日: kapı doğuya (HHS 90, 5. yy derlemesi). Hun kapısı için metin yoktur. #32 Otağ içi için oturak doğrudan, kapı dolaylı dayanaktır [çıkarım].

**Hayvan [kaynak: SJ 110].** 其畜之所多則馬、牛、羊; seyrek 橐駞、驢、驘、駃騠、騊駼、驒騱 (deve, eşek, katır, üç nadir at benzeri; 驒 düz Vikikaynak metninde 騨 diye basılır, 三家註 ve Siku 正義 驒 yazar). Av: 鳥, 鼠, 狐, 兔. `fauna.md` bu listeyi taban alır.

**Kuşkulu sayılar.** 四十萬騎 (SJ 110), 三十餘萬騎 (HS 94A), 控弦四十萬騎 (HS 43), 控弦三十萬 (SJ 99). Meng Tian 十萬 (SJ 110), 三十萬 (SJ 6, SJ 88). İlçe: 四十四縣 (SJ 110), 三十四縣 (SJ 6). 十餘年而蒙恬死 tarih hesabıyla 5–6 yıldır. Defter'in «söylenen ve beslenen» ayrımı doğrudur.

### 6.3 Arkeoloji

Çoğu Mete'den sonradır. Görünüş için kullanılır.

| Yer | Bilgi | Tarih | Perde ve kullanım |
|---|---|---|---|
| **Noin-Ula** (Noyon Uul, Töv ili, Batsümber) | Vikipedi 200'den çok höyük, Eregzen 2024 ≈300 mezar ve ≈78 kare rampalı mezar der; ahşap odalar. Kozlov 1924–25 sekiz höyük kazdı, 2006'dan Polos'mak. İşlemeli halılar (figürlerin Yüeçi olması Yatsenko'nun önerisi), Baktriya işi kumaş, Çin lake kapları, saç örgüleri | MÖ 1. yy sonu–MS 1. yy. 6. höyüğün Wuzhuliu (ö. MS 13) olması Bernştam'ın 1951 önerisidir, Eregzen 2024 zayıf sayar | VI ve sonsöz görünüşü: Tanhu Otağı halısı (#32) |
| **Gol Mod** (Arhangay, Hanuy) | Gol Mod 2'nin 1. mezarı en büyüğüdür (Waugh): 46×46 m (UNESCO, yalnız arama özeti). Çukur 22 m, bilinen en derin (Eregzen 2024). 48×42 m ve 37,5 m rampa Eregzen 2024'te yok: kaynak bulunamadı. 27 uydu mezar; Gol Mod 1'de Çin arabası (Waugh) | Geç Hun: MS 1. yy ortası–sonu (Eregzen 2024 önerisi) | Sonsöz: oğlunun çağı; Mete'nin 無封樹'sine karşıt |
| **Ivolga** (Ulan-Ude) | Davydova kazısı. 348×194–216 m, dört sıra sur, üç hendek, 57 konut, demir, darı. Halk karışık | Kuruluş MÖ 3. yy (en.wikipedia, taslak) ya da 2.–1. yy (ru.wikipedia); C14 MÖ 1. yy–MS 1. yy ortası (ru.wikipedia) | V, Surlu Avlu (`settlement.md` §1.2) |
| **Khustyn Bulag** (Töv ili, Herlen kolu; 48°01′K, 108°26′D) | Beş ocak, cüruf çukuru, ocak başına birden çok küçük kil üfleç, kavrulmuş manyetit, doğrudan çelik. Yalnız izabe: arıtma, döküm, dövme kanıtı yok. Teknik Güney Sibirya'dan, Çin'den değil. Sasada ve Amartuvshin bunu Moğolistan'ın ilk izabe kanıtı sayar | MÖ 1. yy–MS 1. yy (C14, yazarların özeti; kalibre aralıkların ucu MÖ 179) | II, Demirci Ocağı [kurgu]: kanıt II'den ≈150 yıl sonradır. `economy.md` §2.4 «çok körüklü» ve «Terelj yakını» der; makale üfleç der, Terelj'i anmaz |
| **Tamir** (Tamiryn Ulaan Khoshuu, Arhangay) | ≈22 ha mezarlık, Purcell ve Spurr 2005, Turbat ve Crubézy 2017'den. Wushu sikke, lake, tunç ayna parçası (Waugh). Yanında Tamir 2: üç surlu alan, işlevi belirsiz (bu turda doğrulanamadı) | Hun çağı, geniş aralık | III–IV, sıradan Hun mezarı: halkın görünüşü. Ayna yalnız mezar eşyasıdır, oyun nesnesi olmaz (register kural 1) |
| **Lung-çeng adayı** (Arhangay, 48,10°K, 102,56°D) | 2017'de bulundu, 2020'de kazıldı. Çatı kiremidinde «Göğün oğlu Tanhu» yazısı. Miller mevsimlik toplantı yeri sayar. Vikipedi'de 18 Temmuz 2020 kazı gününe «failed verification» etiketi konmuştur; koordinat Vikipedi'yle aynıdır (48,1030; 102,5606) | Tartışmalı | IV, VI: iç harita görünüşü; `geography.js` «tartışmalıdır» notu kalır |

Yine arkeolojiden: büyük kare rampalı mezarlar MÖ 1. yy sonunda yayılır. Eregzen 2024 üç aşama önerir: MÖ 1. yy ortasından önce yuvarlak taş halkalı mezar (Chikhertiin Zoo), MÖ 1. yy sonu–MS 1. yy başı Noin-Ula, MS 1. yy ortası–sonu Duurlig Nars ve Gol Mod. Erken evrede de yüzeyde taş halka vardır, en büyüğü 50 m çapındadır. Bu yüzden 無封樹 arkeolojiyle tam örtüşmez; oyun metni izler [kurgu]. Hun halkı genetik olarak karışıktır [kaynak: Science News 2023, Jeong 2020 üzerinden]; 諸引弓之民，并爲一家 ile `army.md` `origin` çeşitliliğini destekler [çıkarım].

## Oyuna öneriler

1. **#1 Tarih kartı.** Her perde ve büyük olay kartı §2.2 tarihini tam yazar: «27 Eylül MÖ 234» (geç kalan oyuncu için öneri 23). Oyuncu metninde «dolayı» ve «c.» yok; `geo.js` «Around 206–203», «MÖ 208», «MÖ 205», «MÖ 203» satırları §2.2'ye iner. Yeni veri `time.md` §2'ye tek tablo olarak girer; kod satırları `contract-requests.md`'ye yazılır (register genel kural 6).
2. **#3 Elçi kuralı.** `act1.md` §1, §8.2 ve site `perde-1.md` §3.6'daki cümlelerle değişir. Kod değişmez. Palak ayrıca `mq_count` sonrası bir kez «Üç gösteri. Bin kırk bir gün.» diyebilir.
3. **#44 Kural.** `time.md` §2, `army.md` §1.3 ve `settlement.md` §12.2: `dailin_count` 8. ayın dolunayıdır. Oynanan iki gün: `dayN` 1.694 ve 14.097. Yeni hava kilidi `a3_dailin` `clear` (`weather.md`'de yoktur, eklenir); `a6_dailin` zaten vardır.
4. **#44 Söğüt Turu.** Sayımın başında `dailin_ground`'a söğüt dalı dikilir. Atlılar üç tur atar (眾騎馳遶三周, Xianbei kaydı, Hun için [çıkarım]): çevre ≈170 m, yarıçap ≈27 m, üç tur ≈510 m, `travel.md` §2 dörtnal ortalaması 8,58 m/sn ile ≈60 sn; çizim bütçesi `army.md` T1 kümesi (prototipin `instanceMatrix` katmanı; Godot karşılığı «Godot için» madde 6). Bitiren her baş `loyalty` +1. Çapraz koşu yok, kazanan yok. `sky_pole`'a dokunmaz.
5. **#20 Lung-çeng günü.** `time.md`: 5. ayın dolunayı. Oynananlar: 17 Haziran 205 (IV, `dayN` 2.698, takvimin 17. günü, K25 sınırı içinde) ve 2 Haziran 198 (VI'nın 2. günü). Kronik 30 Haziran 209 ilk Lung-çeng'i yazar.
6. **#20 II. Perde takvimi.** §2.2: 1, 4, 6, 8, 10, 13, 14, 15 Haziran 209. 15 gün, K25'in 12 ±%30'u içindedir. `居頃之` iki kez geçer: aralar en az iki gün kalır. `taboo` merdiveni aynı.
7. **#20 III. Perde takvimi.** 3, 9, 16, 26 Eylül; yenilenlerin seçimi ve perde sonu 1 Ekim 208. Oynanan ≈12 gündür. `tanhu_ordu`'dan `donghu_land`'a gerçekte kuş uçuşu ≈394 km, yol ≈470 km: `remount` 60 km ile ≈8 gün, 2 gün toplanma. Atlas öneri yolu `r_ordu_donghu` (≈22 km) bunu 0,5 günde gösterir; bu yüzden 16–26 Eylül arası `mq_home` gibi hikâyeyle atlanır (`travel.md` §9.1 İstisna). Elçi sınırdaki Gözcü Konağı'nda bekler, haberci ≈1,5 günde gider (SJ 99 hızı, ≈291 km/gün).
8. **#20 Ay kuralını bozan sefer.** 26 Eylül'de ay %23'tür: `army.md` §3.5 `moonPenalty` −6 çalışır, oyuncu bunu görür. Karşılığında baskın görevinde Tunghu nöbeti seyrek başlar (#22 görev tablosu); `army.md`'de «uyanıklık» sayısı yoktur, yenisi açılmaz. `a3_donghu_dawn` sis kilidi kalır. Satır: «Hun eksilen ayda gelmez. Onlar da bilir.» / «Huns do not ride under a waning moon. They know it too.» [kurgu]
9. **#2 Qin Kai.** I. Perde'de Palak ya da Uldın bir kez Yan'ın rehinesini anar: 胡甚信之. Güven ekseninin ne olduğunu söyler. Destan Kitabı'na tek satır; K13 kurgu listesine girmez, gerçek kişidir.
10. **#43 Küçük akın ay ile gelir.** Yerleşim ve ordugâha küçük akın yalnız `moon` ≥0,97 günlerinde olur: ayda ≈3 gün. Bu kural `settlement.md` §15.4'ün sıklığının (III 8 günde 1, IV 14, V 12) yerine geçer; II ve VI'da akın yine yoktur, R (III 6, IV 10, V 16) kalır. Oynanan takvimde perde başına tek pencere düşer: III 15–17 Eylül, IV 16–18 Haziran, V 27–29 Kasım. Dailin günü akın yazılmaz; V'in penceresi kuşatmaya düştüğü için V'te akın yazılmaz. Ay hattı `time.md`'de zaten var, oyuncu takvimden okur.
11. **#20 On elçi görevi (V).** 22–23 Kasım 201. Yer `mayi` çevresindeki sefer ordugâhı `field_camp` ve otlaktır (`oyun-seviye-tasarimi.md` de oraya koyar): `whistle_field` 16 Kasım'dan beri dağılmıştır (K23, `army.md` §3.7), orada yalnız %10 kış bekçisi vardır. Oyuncu besili atı ve yiğitleri gizler, yalnız 老弱及羸畜 gösterir. Eskam'ın Gün III gezisinin aynasıdır: `eskam_saw[]` satırı burada okunur. On elçi geçer, Liu Jing görür. Süre ≈6 dk, bayrak `shown_weak`.
12. **#20 Baideng takvimi (V).** 25 Kasım–1 Aralık 201, kuşatma 7 gün, `a5_baideng` kar kilidi. K25'in «20 Kasım–≈6 Aralık» aralığı değişmez. Atlas etiketi «Baideng, Kasım MÖ 201»; geleneksel «MÖ 200» Destan notunda.
13. **#21 Divan yasası.** `settlement.md` §12.3 Yargı'nın üç hırsızlık seçeneği («Malını al», «Bağışla», «Sür») kalır. 沒入其家 yalnız mal olarak işlenir, aile esir olmaz (K23). Küçük suçta ekran dışı ceza. 獄久者不過十日 kuralı Yargı'nın 15 günlük aralığına kendiliğinden sığmaz: dava Yargı'dan hemen sonra doğarsa 15 gün bekler. Bu yüzden dava olayı bir sonraki Yargı'ya en çok 10 gün kala doğar; oyuncu Yargı'yı ertelerse ve dava 10 günü aşarsa o hane Gönül −1. Aynı anda en çok 3 mahkûm. Zindan yapısı yoktur.
14. **#61 Defter ve çentik.** Arayüz adı Defter kalır. Hikâye içinde sayım çentikle yürür: `settlement.md` «Sayım Defteri» sinema metninde «Sayım Çetelesi» olur. Mete: «Hun yazmaz, çentikler.» Kefil çetelesiyle aynı dildir. Zhonghang Yue sonsözde kalemi getirir.
15. **#20 Mektuplar (VI).** 13 Şubat 192 ve 4 Haziran 176 sahnelerinde Mete söyler, Han kâtibi yazar [kurgu]. 192 kâtibi Lu Wan ya da Han Xin'le gelenlerdendir, adlı aday Zhang Sheng'dir; 176 kâtibi Tuidang kuşağındandır. Oyuncu üç cümleden birini seçer; metnin kalanı HS 94A ve SJ 110'dan özetlenir. Her iki metin de Elçi Yurdu'nda biter.
16. **#8 ve #20 Kunmo.** VI, 4 Haziran 176, Lung-çeng. Oyuncu bir bebeğin getirilişini görür: kurt emzirmiş, karga et getirmiştir. Sonuç: Mete'nin babasının yaptığının tersi. Kut +1, seçim yok. Yıl ve Tanhu [kurgu]dur: SJ 123 yılsız, Benjamin 173 der. Sonsözde «yıllar sonra» kartı: 單于死，昆莫乃率其眾遠徙; Mete'nin ölümüne bağlanmaz. Mitoloji belgesi kurt ve karga motifini buradan bağlar.
17. **#20 Son.** 9 Eylül 174. 無封樹: üstüne höyük ve ağaç yapılmaz, son kare ottur [kurgu; arkeoloji tam örtüşmez, §6.3]. 從死 son kartta Kut ve Korku ile okunur: Kor Yolu'nda gelenek yürür, Gök Yolu'nda Mete «Ardımdan kimse gelmesin» der. Kan görünmez.
18. **Karar 6 Çocukluk.** 22 Eylül 228, Ordos, koyun sırtında küçük yay, üç hedef (kuş, kuş, fare). Oynanan ≈60 sn ya da sinema. Ana kampa dokunmaz: Hun 215'e dek Ordos'tadır, doğum yeri [çıkarım]; K6 ve K7 bozulmaz. Doğum Dailin gecesidir: ozan anlatısı sayımla biter («Sayıma bir eklendi.»). Bu, `omurga.md`'deki `[!CELISKI]` kutusunun bir yarısını çözer.
19. **#32 Otağ içi.** Hun Tanhu Otağı: oturak kuzeye bakar, sol üst [kaynak: SJ 110]. Kapı doğu [çıkarım: Wuhuan kaydı; `structures.md` Tanhu Otağı satırıyla aynı]. Han sarayının tersi [çıkarım]. Çin armağanı Tanhu Otağı'nda yalnız heqin'den sonra görünür. Noin-Ula halısı V sonrası.
20. **#9 Yazım işi.** §5.3 `decisions.md`'ye K kararı olarak girer. Kod bu turda değişmez, `contract-requests.md`'ye yazılır: `src/i18n/strings/geo.js`, `src/map/geography.js`, `src/story/act0/narrator.js` (TR altyazı). Bunlar prototip dosyalarıdır; Godot'da adlar tek çeviri tablosuna girer («Godot için» madde 5). Ses dosyası değişmez. Site sayfaları aynı turda.
21. **Ek 1 Hayvan.** `fauna.md`: ana sürü at, sığır, koyun; seyrek deve, eşek, katır; av kuş, fare, tilki, tavşan (SJ 110). VI'da mektup armağanı: 1 deve, 2 binek, 8 koşum atı. `fauna.md` III'te «bin li at» için yeni tür yazmaz, aygır kullanılır.
22. **#38 Kişiler.** §6.1 listesi `story.md`'nin tabanıdır. Adsızlara ad verilirse K13 kurgu listesine girer. `act1.md` §3'ün Hun adları 5. yy Avrupa Hunlarındandır: Mundzuk Attila'nın babası, Eskam kayınbabası, Uldin ve Berichus aynı çağ [kaynak: Vikipedi]. K21'in ana kamp ailesi de öyledir: Oktar Attila'nın amcası (Octar), Erka eşi (Kreka, Hereka), Dengiz oğlu (Dengizich) [kaynak: Vikipedi]. Hepsi dönem dışıdır ve Tanhu 1'den gelmez (`research/progression.md`'de yoktur): kurgu listesinde kalır, Destan Kitabı'nda işaretlenir ya da değişir.
23. **#1, #19 Tarih kapısı.** `oyun-seviye-tasarimi.md` öneri 16'nın kuralı alınır: kollar erken biterse son görev kapısı saati §2.2 gününe atlatır (`clock:skip`; Godot'da sinyal, «Godot için» madde 2); oyuncu o günü geçtiyse sahne gün söylemez, yıl ve mevsim söyler; kesin tarih Destan ve Kronik metninde kalır. Saat durdurulmaz, K20 değişmez.

### Godot için

Oyun Godot 4.7'dedir (`game/`). Bugün saat, takvim, ay, hava, atlas, diyalog ve yerleşim yoktur, gece sabittir (`d3/oyun-durumu.md`). Yukarıdaki öneriler prototipin sözleşmelerine göre yazılmıştı (`src/...`, olay yolu, `instanceMatrix`). Godot karşılıkları aşağıdadır; sınıf ve yöntem adları resmî Godot 4.7 belgesinden doğrulandı (Kaynaklar). Kod bu turda yazılmaz.

1. **Takvim çekirdeği.** `game/scripts/time/game_calendar.gd`: `class_name GameCalendar extends RefCounted`, yalnız `static func`, yan etkisiz. `time.md` §2'nin formülleri: `year_bc(day_n)`, `doy(day_n)`, `day_n_of(day, month, year_bc)`, `format_tr(day_n)` («27 Eylül MÖ 234»), `moon_age(t)`, `moon_illum(t)`, `month_start(year_bc, n)` (doy 354'ten sonraki ikinci yeni ay 1. aydır), `dailin_day(year_bc)` (8. ayın dolunayı), `longcheng_day(year_bc)` (5. ayın dolunayı). Sabitler `SYNODIC := 29.530588`, `MOON_EPOCH := 1044.75`. Godot'nun `Time` tekili kullanılmaz: proleptik Gregoryen takvimle çalışır; oyun yılı artık günsüz 365 gündür, tarih tablosu Jülyen'dir.
2. **Saat.** `GameClock` autoload'u (`extends Node`), `project.godot` `[autoload]` bölümünde `AudioManager` ve `GameSettings`'in yanına girer. Taşıdığı: `day_n: int`, `minute: float`; sinyaller `day_changed(day_n: int)` ve `skipped(reason: StringName, long: bool)`. Prototipin `clock:skip { reason, long }` olayı bu sinyaldir; öneri 23'ün kapısı `GameClock.skip_to(day_n, minute, &"gate")` çağırır. Kayıt: `Journey`'ye `day_n` ve `minute` eklenir, `SaveSystem`'in JSON kaydına `flags` ve `play_time` gibi yazılır.
3. **Olay verisi.** §2.2 `game/data/chronicle.json`'a girer: satır başına `id`, `day_n`, `k` (K, S, Y), `src`, `title`, `text`. Okuma `destan_kitabi.gd`'nin bugünkü yoluyla aynıdır: `JSON.new().parse(FileAccess.get_file_as_string(path))`. Destan Kitabı tarihi `GameCalendar.format_tr(day_n)` ile yazar; «Gerçekte ≈990 km» gibi notlar aynı kayıtta durur.
4. **Sınama.** `game/tests/unit/test_game_calendar.gd` (`extends TestCase`) bu belgenin sayılarını kilitler: `format_tr(1041) == "2 Aralık MÖ 210"`, `day_n_of(27, 9, 234) == -7785`, `dailin_day(210) == 956`, `dailin_day(208) == 1694`, `dailin_day(174) == 14097`, `longcheng_day(205) == 2698`, `longcheng_day(198) == 5238`, `moon_illum(1044.75) > 0.999`, `moon_illum(1235.5) < 0.03`, `moon_illum(1704.5)` ≈ 0,23. Koşu: `tools/run_tests.sh --filter=calendar`.
5. **Adlar (#9).** Arayüz bugün yalnız Türkçedir. §5.3 tek çeviri tablosuna girer: `game/locale/names.csv` (`keys,tr,en`; örnek `NAME_DONGHU,Tunghu,Donghu`). CSV içe aktarıcısı onu `Translation` kaynağına çevirir; Proje Ayarları > Localization > Translations'a eklenir, metin `tr("NAME_DONGHU")` ile okunur. §5.4'ün «kim konuşuyorsa» kuralı çeviri bağlamıdır: `tr("NAME_XIONGNU", &"speech")` «Hun», bağlamsız `tr("NAME_XIONGNU")` «Xiongnu» döner (`Object.tr(message, context)`). Dil `TranslationServer.set_locale()` ile değişir. Prototipin `geo.js`, `geography.js`, `narrator.js` satırları Godot'a taşınmaz, bu tablodan üretilir.
6. **Söğüt Turu (öneri 4).** `Path3D` altında r = 27 m'lik kapalı bir `Curve3D`: 16 nokta, teğet kollarıyla (`add_point(position, in, out)`). Her baş bir `PathFollow3D` çocuğudur, `loop = true`. Her karede `progress += 8.58 * delta`; `progress >= 3.0 * curve.get_baked_length()` (≈510 m, ≈60 sn) olunca tur biter ve `loyalty` +1 yazılır. Kalabalık tek `MultiMeshInstance3D`'dir: `MultiMesh.instance_count`, her karede `set_instance_transform(i, curve.sample_baked_with_rotation(offset))`. Geçiş görünürlük aralığıyla yapılır: yakın baş modellerinde `visibility_range_end`, kalabalık `MultiMeshInstance3D`'de aynı uzaklıkta `visibility_range_begin`. Bu, prototipteki `army.md` T1 `instanceMatrix` katmanının Godot karşılığıdır. Atlar Meshy'nin `horse_brown` ve `horse_white` modelleridir; dörtnal için rig (5 kredi) ve hareket başına 3 kredi gerekir, üretimden önce kullanıcıya sorulur.
7. **Küçük akın ayı (öneri 10).** Yerleşim kodu yazıldığında akın kapısı `GameCalendar.moon_illum(day_n + 0.5) >= 0.97`'dir; Dailin günü ve V. Perde dışarıda kalır. Pencereler veri olarak durur (örnek `game/data/raids.json`), koda gömülmez; `R` ve `D` `settlement.md` §15.4'ten okunur.
8. **Tarih kartı (öneri 1, 23).** `game/scenes/ui/date_card.tscn`: `CanvasLayer` altında bir `Control`, biçim `ui_kit.gd` ve `menu_style.gd`'den gelir. `GameClock.skipped` sinyalini dinler; oyuncu §2.2 gününü geçtiyse gün yerine yıl ve mevsim yazar (`format_season_tr`).
9. **Hava kilitleri (öneri 3).** Godot'da hava yoktur. `a3_dailin` ve `a6_dailin` `weather.md` taşınırken veri satırı olur; günü `GameCalendar.dailin_day()` verir.

## Belirsizlikler

- **毌 ve 毋.** Vikikaynak ve Kanripo TLS 毋 basar, ctext de öyle (yalnız arama özetinden). Bir dijital metinde 毌 görüldü (arama özeti). Sima Zhen'in tam notu (上音彎，如字亦通也) ve Hanshu 彎弓 okumayı destekler, kesinleştirmez; Zhonghua baskısı görülmedi. İkinci sınamada güçlü bir iç tanık bulundu: Shiji 66'da 貫弓 aynı biçimde 彎 okunur ve «如字» okunuşu da verilir (§1.3). Kesinleşmesi için yine basılı metin gerekir. Alan belgelerindeki 毌 okuma tercihidir.
- **Erişim.** ctext güvenlik sınamasında kaldı, aşılmadı. Oturum boyunca paylaşılan WebSearch hakkı bu görevin sonunda bitti; son iki arama çalışmadı (Hey Irmağı donması, Xiongnu genetik makalesi). Şüpheci turda da hak bitti: Di Cosmo'nun 203'ü, UNESCO ölçüsü, Tamir 2 ve 毌'nin basılı metni yeniden aranamadı. Kullanıcı isterse devam edilebilir. Science.org, UNESCO, Taylor & Francis sayfaları 403 verdi: UNESCO ölçüsü arama özetindendir. İkinci sınamada Vikikaynak ham metni, Kanripo, ytliu0 takvimi, J-STAGE, Studia Archaeologica ve Transoxiana açıldı; Gol Mod ölçüsü, Tamir 2 ve Di Cosmo'nun sayfası yine görülmedi.
- **Türk yazını.** Ögel'in *Büyük Hun İmparatorluğu Tarihi* ve Kafesoğlu'nun *Türk Millî Kültürü* metni okunamadı. Ögel biçimleri kitapçı dökümü özetindendir. Lou-fan ve Pai-yang için kaynak bulunamadı.
- **Doğum ve tahta çıkış.** MÖ 234'ün birincil dayanağı yok (cevap #1 kesin der, işaretlenmez). 徐廣 notu 5. yüzyıldandır, Sima Qian'ın kendi sözü değildir; modern yazın (Di Cosmo, Barfield, Vikipedi üzerinden) 209'u kabul eder.
- **Çelişki K25.** III. Perde'nin takvim aralığı 1 Eylül–1 Ekim'dir, K25 metni «12 gün» der. Oynanan gün 12 kaldığı için çelişki yoktur; #19'dan sonra yalnız ölçüdür. `time.md` Dailin kuralı değişir (öneri 3).
- **Tarih ile serbest oyun.** #1 kesin tarih, #19 ve karar 8 sayaçsız perde ister. Oyuncu III'te 16 Eylül'ü geçebilir: §2.2 oyun içinde her zaman tutmaz. Öneri 23 bunu kartta çözer, takvimde çözmez. Dolunaya bağlı günler (Dailin, Lung-çeng) geç kalanda ay evresiyle de tutmaz.
- **Dailin.** 8. ay (Fu Qian) ile 9. ay (HHS 89, Güney Hunları) çelişir, oyun 8. ayı alır. Yer adı mı tören mi çözülmedi, oyun ikisini de kullanır. Seyitdanlıoğlu'nun «beşinci ay ilkbahar» sözü Çin takvimine uymaz: 5. ay yazdır. Aynı makale 戊 gününü ayın beşinci günü sayar; 戊 on günlük döngünün beşincisidir, ayın değil [çıkarım]. Dolunay seçimi [kurgu]dur.
- **Sıra.** SJ 110 Yüeçi'yi Loufan'dan önce yazar ve «既歸» der, yıl vermez. «203»ün birincil dayanağı yok: Modu sayfası onu paragraf sonu dipnotuyla Di Cosmo'ya bağlar, Yuezhi sayfası «Mete'nin 7. yılı» der ve dipnot vermez, Xiongnu sayfası 176 der. Benjamin ilk akını 176'ya koyar, 203'ü Torday'ın kanıtsız Kangju savaşı olarak anar. Oyun Loufan 205, Yüeçi 203 alır [kurgu].
- **Tanhu 1 yankısı.** IV'ün sırası (Lung-çeng, batı, esaret kampına dönüş) Tanhu 1'in IV'üyle aynıdır (`research/progression.md`). Olay tarihtir, sıra değildir. Register kural 1 gereği `story.md` SJ sırasını, yani Yüeçi'yi perde başına almayı tartmalıdır; 203 buna engel değildir.
- **Kunmo.** SJ 123: babayı Hun öldürür. HS 61: Yüeçi öldürür, bebek Hunlara kaçırılır. Benjamin HS'yi izler, 173 der; o tarihte Tanhu Mete değildir. Oyun SJ'yi izler ve 176'da Mete'ye bağlar [kurgu]. Hangi Tanhu olduğu kaynakta yoktur. SJ 123'ün 單于死'si yetişkin Kunmo'yu anlatır, Mete'nin ölümü olamaz.
- **176'daki yenilgi.** SJ 110 mektubu «yok ettim» der, ama Yüeçi kralını Laoshang öldürür (SJ 123, HS 96A). HHS 87 tek başına Mete der. Abartı sayılır.
- **Heqin.** Prenses: SJ 99 halktan kız, SJ 110 soydan kız, HS 94A 翁主 der. Yıl: SJ 110 ve HS 94A anlatıyı Chen Xi'den (197) sonraya koyar, ZZTJ 12 ise 高帝九年 yazar. Oyun ZZTJ'yi alır [çıkarım].
- **Han ayı dönüşümü.** Artık hesaplıdır (§2.1): Gaozu'nun 7. yılında 10. ay 7 Kasım–6 Aralık 201, 11. ay 7 Aralık–4 Ocak, 12. ay 5 Ocak–3 Şubat 200'dür. Kuşatma 10. ya da 11. ayda olabilir; oyunun 25 Kasım'ı 10. aydadır ve Han Xin'in kaçışı, on elçi ve Liu Jing'in gidip gelişi bu yüzden beş güne sıkışır [kurgu]. 12. aydan sonra olamaz (HS 1). Yeniden kurulan takvimin ay başları ±1 gün oynayabilir: Han takvimi ortalama aya göre hesaplanırdı [çıkarım].
- **Arkeoloji.** Gol Mod ölçüsü tek kaynaklı, Ivolga tarihi kaynaklarda farklı, Lung-çeng kimliği tartışmalı. `economy.md`'nin Terelj bağı makalede yoktur: Khustyn Bulag Töv ilinin Mongonmorit sumundadır, Kerülen'in kolu Zuun Baidlag üstündedir [kaynak: Sasada ve Amartuvshin 2014].
- **Kut ve Korku.** Öneri 16 ve 17 Kut ve Korku'ya bağlanır. Bu iki sayaç Tanhu 1'de de vardır (`research/progression.md` §1); yeni tasarım onları `design/progression.md`'de kendi yollarıyla (Gök Yolu, Kor Yolu) tutar. Bu belge yeni ad ya da eşik eklemez.
- **Çeviri.** Hun Türkçeleri bu belgenindir; akademik çeviriyle karşılaştırılmadı (Watson okunmadı).

## Kaynaklar

**Birincil (zh.wikisource).**
- [Shiji 110](https://zh.wikisource.org/wiki/史記/卷110), [Shiji 110 üç yorumla (三家註)](https://zh.wikisource.org/wiki/史記三家註/卷110), [Shiji 56 üç yorumla](https://zh.wikisource.org/wiki/史記三家註/卷056), [Shiji 123](https://zh.wikisource.org/wiki/史記/卷123), [Shiji 123 üç yorumla](https://zh.wikisource.org/wiki/史記三家註/卷123)
- [Shiji 6](https://zh.wikisource.org/wiki/史記/卷006), [Shiji 8](https://zh.wikisource.org/wiki/史記/卷008), [Shiji 88](https://zh.wikisource.org/wiki/史記/卷088), [Shiji 93](https://zh.wikisource.org/wiki/史記/卷093), [Shiji 99](https://zh.wikisource.org/wiki/史記/卷099), [Shiji 111](https://zh.wikisource.org/wiki/史記/卷111)
- [Hanshu 1](https://zh.wikisource.org/wiki/漢書/卷001), [Hanshu 2](https://zh.wikisource.org/wiki/漢書/卷002), [Hanshu 6](https://zh.wikisource.org/wiki/漢書/卷006), [Hanshu 54](https://zh.wikisource.org/wiki/漢書/卷054), [Hanshu 40](https://zh.wikisource.org/wiki/漢書/卷040), [Hanshu 43](https://zh.wikisource.org/wiki/漢書/卷043), [Hanshu 49](https://zh.wikisource.org/wiki/漢書/卷049), [Hanshu 61](https://zh.wikisource.org/wiki/漢書/卷061), [Hanshu 94A](https://zh.wikisource.org/wiki/漢書/卷094上), [Hanshu 94B](https://zh.wikisource.org/wiki/漢書/卷094下), [Hanshu 96A](https://zh.wikisource.org/wiki/漢書/卷096上)
- [Hou Hanshu 87](https://zh.wikisource.org/wiki/後漢書/卷87), [Hou Hanshu 89](https://zh.wikisource.org/wiki/後漢書/卷89), [Hou Hanshu 90](https://zh.wikisource.org/wiki/後漢書/卷90), [Sanguozhi 30](https://zh.wikisource.org/wiki/三國志/卷30), [Suishu 83](https://zh.wikisource.org/wiki/隋書/卷83), [Zizhi Tongjian 7](https://zh.wikisource.org/wiki/資治通鑑/卷007), [Zizhi Tongjian 11](https://zh.wikisource.org/wiki/資治通鑑/卷011), [Zizhi Tongjian 12](https://zh.wikisource.org/wiki/資治通鑑/卷012), [Zizhi Tongjian 14](https://zh.wikisource.org/wiki/資治通鑑/卷014)
- İkinci tanık: [Kanripo KR2a0001, TLS Shiji](https://github.com/kanripo/KR2a0001), [Kanripo KR2a0007, Wenyuange Hanshu, yorumlarıyla](https://github.com/kanripo/KR2a0007) (61: 布就翖侯; 94: Fu Qian ve Yan Shigu'nun 蹛林 notları)
- İkinci sınamada eklenen: [Shiji 66 üç yorumla](https://zh.wikisource.org/wiki/史記三家註/卷066) (伍胥貫弓), [史記正義, Siku baskısı, 卷110](https://zh.wikisource.org/wiki/史記正義_(四庫全書本)/卷110) (士力能彎弓), [Hanshu 4](https://zh.wikisource.org/wiki/漢書/卷004) (文帝三年 günlü kayıtları)

**Takvim çevirisi.**
- [Yuk Tung Liu, Conversion between Western and Chinese Calendar (722 BCE – 2200 CE)](https://ytliu0.github.io/ChineseCalendar/): Ç'in ve erken Han ay başları; Zhang Peiyu, Chen Meidong, Bo Shuren, Hu Tiezhu, *Zhongguo gudai lifa* (2008) üzerine kurulur. Sonuçlar HS 1'in günlü kayıtlarıyla ve Meeus yeni ay hesabıyla sınandı.

**Türk tarihçiliği.**
- [Eberhard, Çin Tarihi (1947), archive.org](https://archive.org/download/KokTengri/Wolfram%20Eberhard.%20%C3%87in%20Tarihi%20%281947%29.pdf)
- Taşağıl: [Hun, Gök Türk, Uygur Araştırmalarının Tarihi Gelişimi, Tarih Dergisi 81 (2023)](https://dergipark.org.tr/en/download/article-file/3635575); [Turkish-Mongolian Relations in the Early Period](https://dergipark.org.tr/en/download/article-file/844440)
- [Faris Çerçi, Hunlar'da Sosyal, Siyâsî Hayat ve Devlet-Halk İlişkileri](https://dergipark.org.tr/en/download/article-file/67105); [Aybars Pamir, Mete Han ve Eski Türk Orta-Asya Kamu Hukukundaki Yeri, ÇÜHAD 2022](https://dergipark.org.tr/en/download/article-file/2274599)
- [Seyitdanlıoğlu, Eski Türklerde Devlet Meclisi «Toy» Üzerine Düşünceler](https://dergipark.org.tr/en/download/article-file/782085)
- [Ögel, Büyük Hun İmparatorluğu Tarihi, kitapçı kaydı](https://www.amazon.com.tr/B%C3%BCy%C3%BCk-%C4%B0mparatorlu%C4%9Fu-Tarihi-I-II-Tak%C4%B1m/dp/9751631548) (metin okunmadı)
- [Usunlar, Türkçe Vikipedi](https://tr.wikipedia.org/wiki/Usunlar)

**Modern çalışmalar.**
- [Benjamin, The Yuezhi Migration and Sogdia, Transoxiana 2003](http://www.transoxiana.org/Eran/Articles/benjamin.html)
- [Sasada ve Amartuvshin, Iron Smelting in the Nomadic Empire of Xiongnu in Ancient Mongolia, ISIJ International 2014](https://www.jstage.jst.go.jp/article/isijinternational/54/5/54_1017/_article)
- Waugh: [Xiongnu Archaeology Enters a New Century, University of Washington](https://depts.washington.edu/silkroad/archaeology/mongolia/xiongnu/xiongnuarchhist/xiongnuarchhist.html); [The Challenges of Preserving Evidence of Chinese Lacquerware in Xiongnu Graves, The Silk Road (Tamir kazısı eki)](https://edspace.american.edu/silkroadjournal/wp-content/uploads/sites/984/2017/09/The-Challenges-of-Preserving-Evidence.pdf)
- [Eregzen Gelegdorj, Chronological and evolutionary challenges associated with the Xiongnu aristocratic tombs, Studia Archaeologica 44, 2024](https://mongoliajol.info/index.php/SA/article/view/3522) (Moğolca metin okundu)
- [Éveha, Tamir Ulaan Khoshuu](https://eveha-international.com/?p=5330)
- [Bower, How Asia's first nomadic empire broke the rules of imperial expansion, Science News 2023](https://www.sciencenews.org/article/asia-xiongnu-nomadic-empire-expansion)
- [Battulga, История исследования производственных комплексов хунну, 2017](https://vst.susu.ru/humanities/article/view/6812): yalnız özet; sayfada ilgisiz kumar bağlantıları var, künye dergiden doğrulanmalı
- Metni okunmayanlar: [Maróti ve ötekiler, Current Biology 2022](https://doi.org/10.1016/j.cub.2022.04.093) (özeti görüldü); [Yang Lien-sheng](https://en.wikipedia.org/wiki/Yang_Lien-sheng), *Hostages in Chinese History*, HJAS 15 (1952); [de la Vaissière, Xiongnu, Encyclopaedia Iranica](http://www.iranicaonline.org/articles/xiongnu) (403)

**Başlangıç noktası (Vikipedi).**
- [Xiongnu](https://en.wikipedia.org/wiki/Xiongnu), [Modu Chanyu](https://en.wikipedia.org/wiki/Modu_Chanyu), [Yuezhi](https://en.wikipedia.org/wiki/Yuezhi), [Wusun](https://en.wikipedia.org/wiki/Wusun), [Longcheng, Mongolia](https://en.wikipedia.org/wiki/Longcheng,_Mongolia), [Noin-Ula burial site](https://en.wikipedia.org/wiki/Noin-Ula_burial_site), [Battle of Baideng](https://en.wikipedia.org/wiki/Battle_of_Baideng), [Zhangye](https://en.wikipedia.org/wiki/Zhangye), [Ivolga archaeological site](https://en.wikipedia.org/wiki/Ivolga_archaeological_site), [Иволгинское городище](https://ru.wikipedia.org/wiki/Иволгинское_городище), [Mundzuk](https://en.wikipedia.org/wiki/Mundzuk), [Eskam](https://en.wikipedia.org/wiki/Eskam), [Uldin](https://en.wikipedia.org/wiki/Uldin), [Berichus](https://en.wikipedia.org/wiki/Berichus), [Yan Shigu](https://en.wikipedia.org/wiki/Yan_Shigu), [Sima Zhen](https://en.wikipedia.org/wiki/Sima_Zhen), [徐廣](https://zh.wikipedia.org/wiki/徐廣), [服虔](https://zh.wikipedia.org/wiki/服虔), [Qin Shi Huang](https://en.wikipedia.org/wiki/Qin_Shi_Huang) (ölüm günü dipnotu), [Laoshang](https://en.wikipedia.org/wiki/Laoshang), [Octar](https://en.wikipedia.org/wiki/Octar), [Kreka](https://en.wikipedia.org/wiki/Kreka), [Dengizich](https://en.wikipedia.org/wiki/Dengizich)

**Godot 4.7 belgesi (docs.godotengine.org).**
- [PathFollow3D](https://docs.godotengine.org/en/4.7/classes/class_pathfollow3d.html), [Path3D](https://docs.godotengine.org/en/4.7/classes/class_path3d.html), [Curve3D](https://docs.godotengine.org/en/4.7/classes/class_curve3d.html), [MultiMesh](https://docs.godotengine.org/en/stable/classes/class_multimesh.html), [MultiMeshInstance3D](https://docs.godotengine.org/en/stable/classes/class_multimeshinstance3d.html), [GeometryInstance3D (görünürlük aralığı)](https://docs.godotengine.org/en/stable/classes/class_geometryinstance3d.html)
- [Singletons (Autoload)](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html), [GDScript reference (static)](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_basics.html), [JSON](https://docs.godotengine.org/en/stable/classes/class_json.html), [Time](https://docs.godotengine.org/en/4.7/classes/class_time.html) (proleptik Gregoryen)
- [Importing translations](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_translations.html), [Internationalizing games](https://docs.godotengine.org/en/stable/tutorials/i18n/internationalizing_games.html), [Object.tr](https://docs.godotengine.org/en/4.7/classes/class_object.html), [TranslationServer](https://docs.godotengine.org/en/stable/classes/class_translationserver.html)

**İç belgeler.** `docs/design/d3/register.md`, `d3/brief.md`, `d3/oyun-durumu.md`, `decisions.md`, `time.md` §2, §6.3, `army.md` §1, §3.5, §3.7, `settlement.md` §1, §12.3, §15.4, `act1.md` §1, §3, §5, §8.2, `travel.md` §2, §9, `economy.md` §2.4, `structures.md`, `groups-research.md`, `design/progression.md` §5, `research/progression.md`. Godot: `game/project.godot`, `game/scripts/save/journey.gd`, `game/scripts/ui/destan_kitabi.gd`, `game/data/kisiler.json`, `game/tools/run_tests.sh`.

## Doğrulama

**Tarih:** 2026-11-04. **Sınanan iddia: 40.** Yöntem: belge baştan sona okundu, yazarın kaynaklarına güvenilmeden her iddia yeniden açıldı. Çince metin Vikikaynak ham metninden (Shiji 6, 8, 56, 66, 81, 88, 93, 99, 110 ve 三家註, 111, 113–116, 123; Hanshu 1, 2, 4, 6, 43, 49, 54, 55, 61, 94A, 94B, 96A, 96B; Hou Hanshu 87, 89, 90; Sanguozhi 30; Suishu 83; ZZTJ 7, 11, 12) ve Kanripo Wenyuange Hanshu'dan (61, 94) okundu. Han ayları ytliu0 takvimiyle, HS 1'in günlü kayıtları ve gökbilimsel yeni aylarla sınandı. Oyun günleri `time.md` §2 formülüyle betikle yeniden hesaplandı. Godot adları 4.7 belgesinden doğrulandı.

**Doğru çıkanlar.** Xu Guang notu ve 352–425; 209'un 壬辰 oluşu; Fu Qian, Zheng, Jin Zhuo, Yao ve Yan Shigu'nun 蹛林 notları; 異姓大臣, 逗落, Su Lin, Xi Zaochi ve Huan Tan notları; HS 94A'nın on iki alıntısı; HS 96A, SJ 123, SJ 93 ve HS 6 alıntıları; ZZTJ 7'nin 丙寅 notu, Meng Tian'ın 37. yılda ölümü, ZZTJ 11–12 başlıkları; üç gün döngüsü sınaması; Benjamin'in 176, 173 ve Torday'ın 203'ü; Vikipedi'nin Modu (203, c. 234), Yuezhi (7. yıl) ve Xiongnu (176, Atwood, xwn) sayfaları; Zhangye iklim sayıları; Lung-çeng koordinatı; Ivolga ölçüleri ve 57 konut; Noin-Ula; Sasada ve Amartuvshin 2014 (yer, üfleç, C14, yalnız izabe, Güney Sibirya); Eregzen 2024'ün varlığı; Mundzuk, Eskam, Uldin, Berichus; Seyitdanlıoğlu'nun biçimleri ve «beşinci ay ilkbahar» sözü; §2.2, §2.3 ve §4 tablolarındaki bütün `dayN` değerleri ve ay evreleri; #3'ün yol hesabı (986 km, 1.172 km; 47, 55 ve 50 gün); öneri 7'nin 394 ve 469 km'si; öneri 10'un pencereleri ve `settlement.md` §15.4 sayıları; öneri 4'ün sayıları; #7'nin sekiz düzeltmesinden yedisinin bütün dosyalarda işlenmiş olması.

**Yapılan düzeltmeler.**
1. Birinci İmparator'un ölümü 10 Eylül → 12 Temmuz 210 (`dayN` 898): 10 Eylül o yılın 8. ayındadır; en.wikipedia de 12 Temmuz yazar. Eski gün Vikipedi kökenli zincirleme bir hata olabilir.
2. Han ayına düşmeyen beş gün düzeltildi: Han Xin'in teslimi 30 Ekim 201, heqin 6 Aralık 199, Han Xin'in ölümü 13 Mart 196, Sağ Bilge Kral'ın akını 14 Temmuz 177, mektubun varışı 20 Temmuz 176.
3. «Yedinci yıl kışı 201 sonudur» yerine 7 Kasım 201 – 3 Şubat 200; Han ayını batı takvimine çevirme kuralı yazıldı (§2.1).
4. 稽粥: Jizhu → Jiyu (索隱 粥音育).
5. 布就翎侯 → 布就翖侯 (Vikikaynak 翎 basar; Kanripo ve Yan Shigu 翖). Aynı türden: 騨騱 → 驒騱 (§6.2; 三家註 ve Siku 正義).
6. 蹛林 notunda «則服虔說是也» Sima Zhen'in sonucudur, Jin Zhuo'nun değil.
7. 毌 okumasına Shiji 66'nın 貫弓 iç tanığı ve Siku 正義'nın 彎弓'u eklendi; etiket «okuma tercihi» kaldı.
8. Yazım kuralı tabloyla çelişiyordu: kural düzeltildi; Ting-ling → Dingling, Hun-yü → Hunyü, Sinli → Şinli.
9. Dailin kural önerisinin gerekçesi düzeltildi: 39 yılın 9'unda fark var; yeni kural da üç yılda ağustos sonunu verir.
10. Öneri 13'teki «Yargı 15 günde birdir, sığar» mantık hatası düzeltildi.
11. Öneri 22'ye K21'in Oktar, Erka, Dengiz adlarının da Attila ailesinden geldiği eklendi.
12. Öneri 3: `a3_dailin` yeni kilittir, `weather.md`'de yoktur.
13. Lung-çeng satırı: Vikipedi'nin «failed verification» etiketi kimliği değil kazı gününü işaretler.
14. «Yer devletin temelidir» → «Toprak devletin temelidir» (`d3/brief.md` ile aynı).
15. HS 94B'nin 胡地秋冬甚寒 sözü «Hanshu'nun özeti» değil, Yan You'nun MS 11 dolaylarındaki sözüdür; geç tanıklık olarak işaretlendi (§3.4, §6.2).
16. «Godot için» bölümü eklendi; prototip yolları (`src/...`, `clock:skip`, T1 `instanceMatrix`, `geo.js`) Godot 4.7 karşılığına bağlandı. Godot projesinde Çince satır yoktur.

**Bu dosyanın dışında kalanlar** (başka ajanın dosyaları, bu sınamada değiştirilmedi): `act1.md` §1 ve site `hikaye/perde-1.md` «(Eylül 210)» → «(Temmuz 210)»; site `yerlesim/hanlik-merkezi.md`:52 «hırsızın evi alınır» → «hırsızın hanesine el konur»; Jizhu → Jiyu (`groups-research.md`:380, `code-audit.md`:355, site `hikaye/kadro.md`:127 ve `hikaye/omurga.md`:60); `hayvanlar.md`:27, 51, 465 騨騱 → 驒騱; `weather.md`:48 «Baideng, MÖ 200» oyun takviminde Kasım 201'dir.
