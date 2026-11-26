---
title: 'Perde Arası: Akan Kronik'
order: 58
status: tasarim
summary: 'Perde son görevle biter, sayaç yoktur; sonra Serbest Dolaşım açık kalır, oyuncu dilediğinde aradaki yıllar 30–90 sn''lik Akan Kronik''te ay ay akar ve yeni perde açılır.'
sources:
  - docs/design/decisions.md
  - docs/design/story.md
  - docs/design/time.md
  - docs/design/settlement.md
  - docs/design/progression.md
  - docs/design/companions.md
  - docs/design/act1.md
  - docs/design/d3/oyun-durumu.md
---

## Özet

Perdeler arasında yıllar geçer, ama takvim durmaz, sıfırlanmaz, geri gitmez. Perde son ana görevle biter; sayaç yoktur ([K42](/docs/source/design/decisions#k42)). Son görevden sonra dünya açık kalır: Serbest Dolaşım. Oyuncu dilediğinde «Kronik'e bırak» der; aradaki aylar ve yıllar Akan Kronik'te 30–90 saniyede ay ay akar, sonra yeni perdenin kartı gelir. I. Perde'nin sonu tek istisnadır: Ev'den sonra Mete oynanmaz, 11 Nisan–1 Haziran 209 doğrudan Kronik'tir. Perdelerin kendi içeriği kendi sayfalarındadır (en sonda).

> [!NOT]
> «Hikaye gerçek tarih zamanı içinde gerçek zamanlı akacak, tarih sürekli akacak»

Kullanıcı 4 Kasım'da bu notun «1 gün 60dk olacak» notuyla çelişmediğini yazdı (E4.1):

> [!NOT]
> «bu ikisi celiski degil 1 gun 60dk olacak ve gercek tarih dedigim takvim bu kural ile akacak ve gunduz gece buna gore calsiacak»

Tasarım bu iki sözü birlikte uygular ([K67](/docs/source/design/decisions#k67)). 1 oyun günü 24 oyun saati, 60 gerçek dakikadır; hız ayarı yoktur. Oyunun tek saati gerçek tarihli takvimdir: sayım günü ve gün dakikası, oyuncuya «27 Eylül MÖ 234» gibi yazılır. Gündüz, gece, ay evresi ve mevsim aynı saatten okunur. Hızlı geçişler adı konmuş atlamadır ve takvimi aynı yönde yürütür: Bekle, Uyu, Dinlen, Çalış, atlas yolculuğu, anlatıcının köprüleri ve Akan Kronik. Atlanan her gün takvime işlenir, Kronik onu ay ay gösterir: tarihte boşluk yoktur, «sürekli akan tarih» budur.

## Perde sonu: son görev

> [!NOT]
> «onerdigi ngibi olsun sayac olmasin perde son gorev ile bitsin»

- **Sayaç yok.** Perde son ana görevle biter. K25'in gün bütçesi (II 12, III 12, IV 14, V 12, VI 16 oyun günü; perde ≈420 gerçek dk, ±%30) yalnız tasarım ölçüsüdür, oyunda okunmaz; ana görev zamanla kapanmaz (K42).
- **Son görev kollardan sonra açılır.** Her perde açılış, aynı anda açılan üç kol, kapanış ve son görevdir ([K43](/docs/source/design/decisions#k43)). Son görev yalnız kollar bitince açılır.
- **Son Görev Kapısı.** Kart: «Bu yol perdeyi kapatır. Sonra {y} yıl geçer.» / «This road closes the act. Then {y} years will pass.» `{y}` sonraki perdenin başına kalan yıldır. Açık yan görevler sonucuyla listelenir; düğmeler `Yola Çık` ve `Daha Değil`; kartta saat durur.
- **Açık yan görevin sonucu** görev verisinde yazılıdır, sessiz düşüş yoktur: sonraki perdede sürer (`carry`), Kronik'te bir sonuç satırı olur (`chronicle`) ya da listede «Kapanır» diye yazılır (`lost`).
- **Oyalanana bedel yok, söz var.** Son görev açıldıktan sonra 3., 6. ve 9. günde kişiler üç kademede sabırsızlanır.
- **Tarih kapısı** ([K33](/docs/source/design/decisions#k33)). Kollar erken biterse son görevin kapısı saati tablodaki güne atlatır; oyuncu o günü geçtiyse sahne günü değil yılı ve mevsimi söyler; saat durmaz. Takvim olaylarının vakit çağrısı karartmayla götürmez: kaçırılan Dailin ya da toplantı Kronik'te «sensiz yapıldı» satırı olur (K43).

| Perde | Başlar (sayım günü) | Son görev (tablo günü) | Sonra |
|---|---|---|---|
| [I. Çan](/docs/story/act-1) | 2 Aralık MÖ 210 (1.041) | Ev, 11 Nisan 209 (1.171) | Doğrudan Kronik; II yazılana dek «II. Perde yakında» kartı |
| [II. Ok Neyi Gösterirse](/docs/story/act-2) | 1 Haziran 209 (1.222) | Av: ok Teoman'ı gösterir, 14 Haziran 209 (1.235) | Serbest Dolaşım, Kronik |
| [III. Boş Toprak](/docs/story/act-3) | 1 Eylül 208 (1.679) | Yenilenlerin seçimi, 1 Ekim 208 (1.709) | Serbest Dolaşım, Kronik |
| [IV. Borç](/docs/story/act-4) | 1 Haziran 205 (2.682) | Ordos'ta Dailin, 22 Eylül 203 (3.525) | Serbest Dolaşım, Kronik |
| [V. Dört Renk](/docs/story/act-5) | 20 Kasım 201 (4.314) | Bir köşe açılır, 1 Aralık 201 (4.325) | Serbest Dolaşım, Kronik |
| [VI. Sayım](/docs/story/act-6) | 1 Haziran 198 (5.237) | Son Dailin, 9 Eylül 174 (14.097): Mete sayım sürerken ölür | [Sonsöz «Kopuz Susar»](/docs/story/epilogue) |

I'de yan görevler Kışlak'a bağlıdır: Gün V'te Göz Yolu başlayınca açık kalanlar «Kapanır» olur ([act1.md §7](/docs/source/design/act1#7-yan-gorevler)). Son Görev Kapısı ve tarih kapısı II'nin ana zinciriyle kurulur ([Yol Haritası](/roadmap#item-final-quest-gate)).

## Serbest Dolaşım

II. Perde'den başlayarak her perdede son görev bitince kapanış sahnesi ve perde kartı gelir, dünya açık kalır ([story.md §10.7](/docs/source/design/story#10-7-serbest-dolasim-ve-akan-kronik)).

- **Açık kalanlar.** İç haritalar, Plan Kipi, Defter, sürüp giden yan görevler, av ve inşa. Yeni ana görev açılmaz.
- **Takvim akar.** 1 oyun günü 60 gerçek dk; mevsim kendi işini yapar: kışın ordugâh dağılır, akın ay penceresiyle gelir ([K55](/docs/source/design/decisions#k55)). Kâhya, kervan, av ve inşa sürer; akın penceresi ve hanelerin Çekimi bitmiş perdenin tavanlarıyla işler.
- **XP.** Seviye tavanı ve XP ölçeği eski perdenindir: av, inşa ve süren yan görevler XP verir, tavanı aşan saklanır ve yeni perdenin başında seviye verir ([progression.md §15](/docs/source/design/progression#15-perde-gecisi)).
- **Kronik'e bırak / Leave it to the Chronicle.** Düğme perde kartında, duraklatma kitabında ve Mete'nin her ocağında durur. Onay kartı hedef tarihi, geçecek yılı ve açık yan görevlerin sonucunu yazar; kartta saat durur. Hedef `max(sonraki perdenin başı, bugün + 30 gün)`'dür; ikinci terim bir güvencedir: perdeler arası aralar yüzlerce gündür, hedef pratikte hep sonraki perdenin başıdır ([Yol Haritası](/roadmap#item-leave-to-chronicle)).
- **Tan'da tarih.** Oyun içinde her Tan'da 2 sn tarih yazar: «8 Haziran MÖ 209 · 1.229. gün».
- **I'de yok.** Ev'den sonra serbest dolaşım yoktur: Mete'nin denetimi II'de atlas bacağında başlar ([K7](/docs/source/design/decisions#k7)).
- **Serbest Gez başka şeydir.** Menünün Serbest Gez'i Çocuğun oyunudur: aynı takvim akar ama perde, Kronik ve takvim olayı yoktur, Tan kartı yalnız tarihi yazar ([K67](/docs/source/design/decisions#k67)).

## Akan Kronik

Akan Kronik yerleşimin kapalı hesabını oyuncuya gösterir ([K42](/docs/source/design/decisions#k42), [settlement.md §16.2](/docs/source/design/settlement#16-2-perde-gecisi-kronik-k25)). Sırası:

1. Perde kartı.
2. Atlas yeni perdenin dönemine geçer.
3. Tarih ve sayım günü ay ay akar.
4. Mevsim nabzı: kapalı hesap akış boyunca mevsim mevsim işlenir.
5. 2–5 anlatıcı ya da ozan satırı. Satırları anlatıcı okur (İngilizce, Türkçe altyazı); ozan satırı kopuzla gelir.
6. Hane ve sürü sayıları.
7. Yeni perdenin kartı.

- **Süre.** `T = clamp(mevsim sayısı × 5 sn, 30, 90)`; mevsim 91,25 gün sayılır. Kısa ara 30 sn'nin altına inmez, en uzun ara 90 sn'yi geçmez. Süre oyuncunun Kronik'e bıraktığı günden sayılır; aşağıdaki tablo son görev gününden hesaplandı ([story.md §13](/docs/source/design/story#13-perde-arasi-akan-kronik)). K42'nin örnekleri (II→III 30, III→IV 54, IV→V 89, V→VI 50 sn) perde başından perde başına sayılmıştı; IV'ün iç Kroniği ayrı koştuğu için IV'ten V'e iki koşu ≈83 sn eder. Formül esastır.
- **Atlama.** Atlanabilir: `E` basılı tutulursa ×4 hızlanır, Esc atlar.
- **Kronik Kararı.** En çok iki: tek kart, iki seçenek; 10 sn'de seçilmezse Kâhya seçer, akış durmaz.
- **Toplantılar.** Kış Toplantısı oynanan günde sahne açmaz; Kronik'in sonraki koşusunda toplu işlenir (K42). Aradaki Dailin'ler ve Lung-çeng'ler satır olur.
- **Yoldaşlar.** Kronik'te parti donar: yoldaki, görevdeki ve subay olan yerinde kalır; tarihli kişisel görev adımı Kronik'te sonuç satırı olur (`chronicle`), son adım +2 yerine +1 verir ([companions.md §2.4](/docs/source/design/companions#2-4-partisiz-kipler)).
- **Dokunmadıkları.** Kronik kabuğa dokunmaz ([K48](/docs/source/design/decisions#k48)), akın işlemez (K55).
- **Godot.** Atlamayı oyunun saati yapar (`GameClock.skip_to`), satırlar `data/chronicle.json`'dadır; ilk Kronik I → II'dir ([Yol Haritası](/roadmap#item-chronicle)).

![Prototipte denendi: atlasta yeni açılan bölge ≈3 sn'de mürekkeple belirir, dört kare](/media/docs/research/atlas-shots/reveal_ink_2x2.jpg)

```varlik
ui_act_card, ui_chronicle_card, ui_atlas
```

### Kronik (K25)

Kapalı hesap K25'indir; K42 onu görünür kıldı. Hesap mevsim başına ≤150 ms sürer ve akışa dağılır ([settlement.md §16.2](/docs/source/design/settlement#16-2-perde-gecisi-kronik-k25)):

1. Tarih hedefe atlar; atlanan her gün takvime işlenir.
2. Aradaki her yıl kapalı biçimde işlenir: sürünün doğumu, soğumu ve kaybı (otlak kapasitesiyle sınırlı), bozulanın silinmesi, saklananın bir kış ve ambar kapasitesiyle sınırı, bakımın ödenmesi. III'ten Tunghu haracı yılda 20 deridir.
3. Tarla: Surlu yolda ve en az bir tarla varsa yıl başına hasat işlenir; ambara yalnız son hasat yazılır, `min(500 × tarla, boş tahıl yeri)` ([K54](/docs/source/design/decisions#k54)).
4. Hane perdenin açılış tabanına çıkar (III 10, IV 22, V 45, VI 80); üstündeyse düşmez. Yeni haneler yükleriyle gelir, Kâhya parsel verir.
5. Kışla açılan perdede (V) kış stoğu kademe hedefinin %75–115 bandının ortasına dek, ambar ve sundurma kapasitesiyle doldurulur: kap kurmak kışı korur.
6. Yoldaki kervan varmış sayılır; şantiyeler emek yeterse biter, yoksa bırakılmış kalır.
7. Perde kartı özeti: «{y} yıl geçti. {h} hane, {s} baş sürü; ambar kışa {p}.» Surlu yolda ek satır: «Tarlalar {n} darı verdi.»

Yeni perdenin başında sıra şudur: kayıt alınır, seviye tavanı artar, biriken XP seviye verir, Ozan'a Anlattır hakkı +2 olur, yeni perdenin XP ölçeği gelir. Yerleşim ve ordugâh aynen sürer. IV'ün ve VI'nın iç Kronikleri aynı akışla işler ama yeni perde açmaz.

## Geçişler

Tarihler ve satırlar [story.md §13](/docs/source/design/story#13-perde-arasi-akan-kronik)'tendir; süre son görev gününden hesaplandı. Yeni satırlar (Göl Obası'nın ozanının ölümü, Dulongçi'nin ölümü, Huyan ve Tunghu kararları, Lan Hatun'un dileği) kurgudur.

| Geçiş | Takvim, süre | Ne olur | Anlatıcının satırı | Kronik Kararı | Yol Haritası |
|---|---|---|---|---|---|
| I → II | 11 Nisan → 1 Haziran 209; 51 gün, 30 sn | Bahar; Tanhu'nun sürüleri yaz otlağına çıkar; Mete'nin döndüğü obadan obaya yayılır. Mete oynanmaz | «Bahar geçti, Tanhu'nun sürüleri yaz otlağına çıktı.» | Yok | [madde](/roadmap#item-chronicle) |
| II → III | 15 Haziran 209 → 1 Eylül 208; 443 gün, 30 sn | Teoman höyüksüz gömülür, yeri yeşerir. 30 Haziran 209 ilk [Lung-çeng](/encyclopedia/longcheng): Mete babasının hatunlarını alır, [Yimo](/encyclopedia/yimo) onun hatunu olur. 27 Eylül 209 Mete'nin Tanhu olarak ilk [Dailin](/encyclopedia/dailin)'i: «Sayımın bin üç yüz kırkıncı günü.» 6 Şubat 208 Kış Toplantısı; 19 Haziran 208 Lung-çeng; avlu göçü başlar | «Mete babasının yerinde oturdu. Doğuda Tunghu bunu korku sandı.» | Huyan'ın makamı: «Geri ver» (Huyan haneleri Gönül +5, soy soylu kalır) ya da «Askıda tut» (Korku +1) | [madde](/roadmap#item-chronicle-2-3) |
| III → IV | 1 Ekim 208 → 1 Haziran 205; 973 gün, ≈53 sn | Vuhuan her yıl haraç verir; Ç'in yıkılır, Ziying teslim olur; Çu ile Han savaşı başlar; üç Kış Toplantısı, üç Dailin. Göl Obası'nın ozanı ölür, kopuzu ocağın Çocuğuna kalır: IV'ten Mete'nin ocağının ozanı Çocuktur ([K79](/docs/source/design/decisions#k79)) | «Ç'in düştü, Han ile Çu birbirini yiyordu. Bozkır üç güz sayıldı.» | Tunghu'dan gelenlerin başı: «Kendi beyleri» (o haneler Gönül +5) ya da «Bir Hun beyi» (Korku +1) | [madde](/roadmap#item-chronicle-3-4) |
| IV içi | 18 Haziran 205 → 24 Haziran 203; 738 gün, ≈40 sn | 14 Eylül 205 Yimo'dan [Yitu](/encyclopedia/yitu) doğar (Dailin günü); Dailin 205 ve 204; 6 Haziran 204 Lung-çeng; Çu ile Han savaşı sürer; Lan Hatun yaşlanır | «Yüeçi batıda yol aldı. Yimo bir oğul doğurdu, adını Yitu koydular.» | Yok | [madde](/roadmap#item-inner-chronicle) |
| IV → V | 22 Eylül 203 → 20 Kasım 201; 789 gün, ≈43 sn | 21 Ekim 203 Yan ve Dai'ye akın; 16 Kasım 203 [Lan Hatun](/encyclopedia/lan-hatun) ölür, Yimo Kâhya olur; 28 Şubat 202 Han kurulur; 15 Haziran 202 kuzeyin beş halkı boyun eğer (Hunyü, Çüşe, Dingling, Gekun, Şinli); 30 Ekim 201 [Han Xin](/encyclopedia/han-xin) Mayi'de teslim olur | «Lan Hatun kışın ilk günü öldü. Han tahtındaki Liu Bang kuzeye baktı.» | Lan Hatun'un yoğu: «Yoğ Aşı» (bir Toy bedeli, Gönül +2) ya da dileğince «Sade gömü»: «Sayın beni, ağlamayın.» (Kut +1) | [madde](/roadmap#item-chronicle-4-5) |
| V → VI | 1 Aralık 201 → 1 Haziran 198; 912 gün, 50 sn | [Liu Jing](/encyclopedia/liu-jing) zincirden çözülür, «vurulur» diyen on elçi kesilir; Han'da Pingcheng türküsü; Han Xin'in komutanları sözü bozup Dai ve Yunzhong'a akar; 6 Aralık 199 heqin: [prenses](/encyclopedia/han-princess), her yıl ipek, kumaş, şarap ve tahıl, iki hükümdar kardeş sayılır; barış kartı Beyaz At kalıbıyladır ([K35](/docs/source/design/decisions#k35)); [Dulongçi](/encyclopedia/dulongchi) ölür | «Han bir prenses, ipek, şarap ve tahıl gönderdi. İki hükümdar kardeş sayıldı.» | Han Xin'in komutanlarının akın payı: «Al» (Hazine artar, Korku +1) ya da «Alma» (Kut +1); akın her dalda olur | [madde](/roadmap#item-chronicle-5-6) |
| VI-a → VI-b | 4 Haziran 198 → 12 Şubat 192; ≈2.080 gün, 90 sn | 197 güzü [Chen Xi](/encyclopedia/chen-xi) ayaklanır; 13 Mart 196 Han Xin ölür; 196'da [Wang Huang](/encyclopedia/wang-huang)'ı kendi adamları ödül için diri teslim eder; 196'da Hun ülkesindeki [Zang Yan](/encyclopedia/zang-yan), Lu Wan'ın elçisi [Zhang Sheng](/encyclopedia/zhang-sheng)'e Hun yanını tutmasını söyler; 1 Haziran 195 [Liu Bang](/encyclopedia/liu-bang) ölür; 29 Haziran 195 [Lu Wan](/encyclopedia/lu-wan) binlerce adamıyla sığınır | «Liu Bang öldü. Lu Wan binlerce adamıyla sınırı geçti.» | Yok | [madde](/roadmap#item-year-slices) |
| VI-b → VI-c | 14 Şubat 192 → 14 Temmuz 177; ≈5.265 gün, 90 sn | [Lü](/encyclopedia/empress-lu)'nün cevabı, iki araba ve iki takım at; Mete'nin özrü ve at armağanı; 186 kışı [Dangyu](/encyclopedia/dangyu) ölür, ocağını ardılı [Liuli](/encyclopedia/liuli) yakar (Dangyu yoldaş olduysa); 180 yazı Lü ölür, [Wen](/encyclopedia/emperor-wen) tahta çıkar, heqin yenilenir; Jiyu ve Yitu büyür | «Lü öfkelendi, sonra yumuşak yazdı. Han'da yeni bir imparator barışı yeniledi.» | Yok | [madde](/roadmap#item-year-slices) |
| VI-c içi | 15 Temmuz → 11 Ekim 177; 88 gün, 30 sn | Han atlıları Gaonu'ya gelir; Wen Taiyuan'a gider, Jibei ayaklanınca döner | «Han'ın atlıları geldi, Sağ Bilge Kral sınırın ötesine çekildi.» | Yok | [madde](/roadmap#item-year-slices) |
| VI-c → VI-d | 11 Ekim 177 → 3 Haziran 176; 235 gün, 30 sn | Sağ kanat batıdadır; Yüeçi yenilir; Loulan, Usun, Hujie | «Sağ kanat batıya yürüdü. Yüeçi yenildi, yirmi altı ülke Hun sayıldı.» | Yok | [madde](/roadmap#item-year-slices) |
| VI-d → VI-e | 5 Haziran 176 → 14 Şubat 174; 619 gün, 34 sn | 20 Temmuz 176 mektup Xinwang'a varır; Han tartışır, barışı seçer; [Kunmo](/encyclopedia/kunmo) büyür | «Mektup sınıra vardı. Han barışı seçti.» | Yok | [madde](/roadmap#item-year-slices) |
| VI-e içi | 15 Şubat → 8 Eylül 174; 206 gün, 30 sn | Son yaz; atlar semizler; Surlu yolda darı sararır | «Son yaz uzun sürdü. Atlar semizledi.» | Yok | [madde](/roadmap#item-year-slices) |
| VI → Sonsöz | 9 Eylül → 8 Ekim 174 ve «yıllar sonra»; Kronik yok | Son görevden sonra Sonsöz sineması gelir (≈2 dk 55 sn): gömü, Yoğ Aşı, 8 Ekim'de Jiyu Tanhu olur, «yıllar sonra» kartları, Son Sayım | | Yok | [Sonsöz](/roadmap#epilogue) |

```varlik
chen_xi, fan_kuai, ji_bu, guan_ying
```

Kronik'in Han yüzleri: Chen Xi 197 güzünde ayaklanan Han beyidir. Lü'nün avlusunda Fan Kuai savaş ister, Ji Bu karşı çıkar; Lü'nün öfkesi ve yumuşak cevabı VI-b → VI-c Kroniği'nde gelir. Guan Ying 177'de 85.000 araba ve atlıyla yollanan Han komutanıdır (VI-c).

## Perde başında ne değişir

Her perde yeni bir yaşta, yeni bir yerleşim kademesinde ve yeni bir seviye tavanıyla açılır. Sayılar [settlement.md §2.2](/docs/source/design/settlement#2-2-perde-perde) ve K43'tendir.

| Perde | Mete | Seviye tavanı | Yerleşim | Hane | Ordugâh |
|---|---|---|---|---|---|
| II | 24 | 6–8 | Ocak → Oba | 3 → 10 | Onluk Ateşi → Yüzlük Kampı (100 atlı yerleşik) |
| III | 25–26 | 9–11 | Boy Yurdu | 10 → 22 | Binlik Ordugâhı (200 yerleşik, Dailin'de 1.000) |
| IV | 28–30 | 12–14 | Toy Yeri | 22 → 45 | Binlik (400 yerleşik) |
| V | 33 | 15–17 | Tanhu Avlusu (Surlu ya da Göçer seçimi) | 45 → 80 | Tümen Ordugâhı (600 yerleşik, toplantıda 3.000–10.000) |
| VI | 35–59 | 18–20 | Tanhu Avlusu tam | 80 → en çok 90 | Tümen |

## Açılıştaki köprüler

I. Perde'den önceki yıllar Akan Kronik değildir: anlatıcının iki köprüsü adı konmuş atlamadır, parşömen videoları aradaki yılları gösterir ([K36](/docs/source/design/decisions#k36), K67, [K68](/docs/source/design/decisions#k68)).

| Atlama | Takvim | Süre | Ne gösterir |
|---|---|---|---|
| [Önsöz](/docs/story/prologue) → [Çocukluk](/docs/story/childhood) | Önsöz saat okumaz: çerçevesi 10 Nisan 209 gecesi, doğum 27 Eylül 234 şafağı; oynanan takvim 22 Eylül 228, 08:40'ta başlar | Önsöz 4 dk 18 sn | Ozanın kopuzlu şarkısı, parşömen videosunda mit, doğum |
| Köprü 1 | 22 Eylül 228 → 15 Aralık 213 | ≈50 sn | Tilki ve tavşan (222), gerilen yay (218), Dailin'de evlilik (216), Ç'in'in suru ve Ordos'tan çekiliş (215), doğuda Tunghu, batıda Yüeçi ve arada sayan Teoman, diz çökmeyen veliaht, kuzeye göç ile Huyan Hatun ve beşikteki Gutu (214), Dailin'de Teoman ve mühür, Lung-çeng'de Jiyu'nun beşiği (213); anlatıcının N1–N5 satırları; ardından oluşturucu ve Yola Çıkış |
| Köprü 2 | 15 Aralık 213 → 2 Aralık 210 | ≈18 sn | N6 ve N7: kar yolu, Kemik Boğazı'nda kapı, bileğe bağlanan çan, sayılan rehine, yürüyen ayak ve çan; kara ekran ve I. Perde'nin çanı |

## Perdelerin sayfaları

- [Önsöz: Kopuz Söyler](/docs/story/prologue): sinema, kamp, mit ve doğum.
- [Çocukluk: Koyun Sırtında](/docs/story/childhood): 22 Eylül MÖ 228, köprüler ve Yola Çıkış.
- [I. Perde: Çan](/docs/story/act-1) ve [I. Perde: Gün Gün](/docs/story/act-1-days): 2–7 Aralık MÖ 210, Ev 11 Nisan 209.
- [II. Perde: Ok Neyi Gösterirse](/docs/story/act-2): 1–15 Haziran 209.
- [III. Perde: Boş Toprak](/docs/story/act-3): 1 Eylül–1 Ekim 208.
- [IV. Perde: Borç](/docs/story/act-4): 1 Haziran 205–22 Eylül 203.
- [V. Perde: Dört Renk](/docs/story/act-5): 20 Kasım–1 Aralık 201.
- [VI. Perde: Sayım](/docs/story/act-6): 1 Haziran 198–9 Eylül 174.
- [Sonsöz: Kopuz Susar](/docs/story/epilogue): 9 Eylül–8 Ekim 174 ve «yıllar sonra».

Bütün hayatın çizgisi [Hikâye Omurgası](/docs/story/spine), saatin kuralı [Zaman ve Takvim](/docs/world/time-calendar) sayfasındadır.

## Oyunda şu an

> [!DURUM]
> Oyunda: yok. Godot'da saat ve takvim yok, kampın gecesi sabittir; perde, perde kartı, Son Görev Kapısı, Serbest Dolaşım ve Akan Kronik yok. Menünün Serbest Gez'i var: ana kampın Çocuğu gece kampında yürür, takvim akmaz. Yeni Oyun'un akışı takvim gününü yolculuğa yazar (Çocukluk −5.600, Köprü 1'den sonra −41, Köprü 2'den sonra 1.041; [K99](/docs/source/design/decisions#k99)), saat yoktur. Prototipte denendi: takvimdeki perde başları, Kronik'in yıl adımı (saf hesap) ve atlasta mürekkeple açılış; Godot'a taşınmadı ([oyun-durumu.md](/docs/source/design/d3/game-state)).

## Yol Haritası

Kronik'in altyapısı I. Perde'nin son fazında kurulur; her perdenin Kroniği o perdenin son fazındadır, IV'ün iç Kroniği IV'ün harita fazında, VI'nın iç Kronikleri VI'nın yıl dilimleri fazındadır.

```ilerleme
act-1-p6
act-2-p5
act-3-p4
act-4-p2
act-4-p4
act-5-p4
act-6-p1
```

## Kaynaklar

- [decisions.md](/docs/source/design/decisions): K7, K25, K33, K35, K36, K42, K43, K48, K54, K55, K67, K68, K71, K79
- [story.md §10.6](/docs/source/design/story#10-6-perde-sonu-19), [§10.7](/docs/source/design/story#10-7-serbest-dolasim-ve-akan-kronik), [§12](/docs/source/design/story#12-sonsoz-kopuz-susar-the-kopuz-falls-silent), [§13](/docs/source/design/story#13-perde-arasi-akan-kronik)
- [time.md §2](/docs/source/design/time#2-takvim), [§7.4](/docs/source/design/time#7-4-atlamada-sistemler); [settlement.md §2.2](/docs/source/design/settlement#2-2-perde-perde), [§16.2](/docs/source/design/settlement#16-2-perde-gecisi-kronik-k25)
- [progression.md §15](/docs/source/design/progression#15-perde-gecisi), [companions.md §2.4](/docs/source/design/companions#2-4-partisiz-kipler), [act1.md §8.11](/docs/source/design/act1#8-11-esik-ve-ev-the-threshold-and-home)

İlgili sayfalar: [Hikâye Omurgası](/docs/story/spine), [Zaman ve Takvim](/docs/world/time-calendar), [Obadan Hanlığa](/docs/settlement/encampment), [Açık Dünya ve Görevler](/docs/gameplay/open-world-quests), [Yoldaşlar](/docs/gameplay/companions).
