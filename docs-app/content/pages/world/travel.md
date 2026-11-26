---
title: Yolculuk
order: 30
status: tasarim
summary: 'İç haritada Menzil ağı ve araba, iç haritalar arasında Uzak Yol vardır; ışınlanma yoktur, bedel maldır, hikâye yolu kilitler, Tanhu Kampı sahnesiz bir konaktır.'
sources:
  - docs/design/decisions.md
  - docs/design/travel.md
  - docs/design/act1.md
  - docs/design/settlement.md
  - docs/design/weather.md
  - docs/design/fauna.md
  - docs/design/companions.md
  - docs/design/d2/core.md
  - docs/design/d3/oyun-durumu.md
---

## Özet

Yolculuk iki kademedir. İç harita içinde Menzil'e yürürsün, direğe vurursun, araba gelir, binersin. İç haritalar arasında atlas açılır, iğne yolda yürür, saat günleri atlar: Uzak Yol budur. Işınlanma yoktur. En hızlı yol Yolu Kısalt'tır (3 sn). Haritaya tıklayıp uçmak yoktur; tek istisna bedeli ağır Erlik'in Yolu'dur. Her yolculuk takvimi ileri yürütür, takvim geri gitmez ([K67](/docs/source/design/decisions#k67)).

| Kademe | Nerede | Gerçek süre | Oyun saati | Bedel |
|---|---|---|---|---|
| Menzil ağı, araba | İç harita içinde | 27–229 sn; Yol Akışı ile ≤66 sn; Yolu Kısalt ≈6 sn | Doğal süre × 0,4 oyun dk | I. Perde 1 Aş ya da 1 odun; sonra mesafeyle Aş ya da kabuk |
| Uzak Yol | İç haritalar arasında | 10–30 sn | Yol günleri kadar atlar | Gün başına erzak ve yem |

**Neden iki kademe.** Vadi içinde mesele hız değil yüktür: uçtan uca yürüyüş 5 dk'dır, ama Yük başta 21, araba 40'tır. Kesim Yeri → Menzil 372 m, 10 kütük: yürüyerek 326 sn, arabayla 58 sn, Yolu Kısalt ile 3 sn. Atlasta ise başka yol yoktur: iki iç harita arasında zemin yoktur.

| Hareket | m/sn | Vadi 1.400 m | Hexi → Tanhu 53,5 km | Harita eni 356,5 km |
|---|---|---|---|---|
| Çocuk yürüyüşü | 3,2 | 7,3 dk | 4,6 sa | 31 sa |
| Yürüyüş | 4,4 | 5,3 dk | 3,4 sa | 22,5 sa |
| Araba, yol | 6,4 | 3,6 dk | 2,3 sa | 15,5 sa |
| Dörtnal, sürekli ortalama | 8,58 | 2,7 dk | 1,7 sa | 11,5 sa |

Tanhu Kampı'nın yeni iğnesiyle (105,2; 46,5) Hexi → Tanhu kuş uçuşu 52,8 km'dir; süreler ≈%1,3 kısalır, sütun olduğu gibi kalır ([K106](/docs/source/design/decisions#k106)).

**II'den binekler ([K65](/docs/source/design/decisions#k65)).** Hun Atı (dörtnal 11, tırıs 6,2 m/sn; yokuş cezası ×0,5), Binek Deve (8,5 / 4,2; kum ve tuz cezası yok; 20 m içinde düşman atı ürker), Binek Katır (V; 8 / 4,6; eğim cezası yok), Cüti (VI; 11,5 / 6). Üzengi yoktur. Atlas günleri binek türüyle değişmez. Ayrıntı: [Hayvanlar](/docs/world/animals).

## Menzil ağı (I. Perde)

| Menzil | Yer (x,z) | Bölge | Açılır | Bağlı direk |
|---|---|---|---|---|
| Kışlak Menzili | (58,22) | Kışlak | Kantu'nun çetelesi | Yok |
| Çoban Durağı | (210,−250) | Ak Otlak | Rütbe 1 | RB04 |
| Kesim Yeri | (430,10) | Kara Yamaç | Rütbe 2 | Yok |
| Demir Diş | (−270,−90) | Demir Diş | Rütbe 3 | Yok |
| Sazlık İskelesi | (345,−192) | Sazlık | Rütbe 2 | RB12 |
| Büyük Kurgan | (450,−300) | Eski Kurganlar | Rütbe 3 | RB14 |
| Yukarı Ağıllar | (440,−475) | Yukarı Ağıllar | Rütbe 4 | RB08 |
| Tuz Kabuğu | (−180,−510) | Ayna Göl | Rütbe 4 | Yok |

| Durum | Nasıl | Haritada |
|---|---|---|
| Duyuldu | Bölge açıldı, Bakış Noktası, Kantu adını anar, yolcu haberi, ozan dörtlüğü | Sönük iğne |
| Bulundu | Bölge açık ve yolcu değilken 15 m'ye gelmişsin (at sırtı sayılır) | Dolu iğne; direği kırıksa kart: «Bulundu, direği kırık» |
| Bağlı | Bulundu ve varsa bağlı Yol Kemiği onarıldı | Dolu simge, +10 XP |

Ağ Gün II'de Kantu'nun çetelesiyle çalışır; önce bulunan duraklar bekler. Ulak becerisiyle onarılmış her Yol Kemiği de durak olur. **Menzilin işleri:** yolculuk, Yük Bindir, Menzil Ambarı, dinlenme (1 Aş, bütün yaralar kapanır).

**Süreler.** En kısa: Büyük Kurgan ↔ Yukarı Ağıllar 175 m, 27 sn. En uzun: Kesim Yeri ↔ Tuz Kabuğu 1.145 m, 229 sn (539 m'si kar). Kışlak Menzili'nden: Çoban Durağı 55 sn, Kesim Yeri 58, Demir Diş 55, Sazlık İskelesi 73, Büyük Kurgan 99, Yukarı Ağıllar 105, Tuz Kabuğu 171. Bütün tablo: [travel.md §4.4](/docs/source/design/travel#4-4-durak-arasi-metre-dogal-saniye). Esir Yolu, Keçi Yolu ve Av Sekisi arabaya kapalıdır.

```varlik
road_bone
```

## Araba ve sefer

Keçe çatılı iki tekerli araba: [Kantu](/encyclopedia/kantu) sürer, [Yakve](/encyclopedia/yakwe) çeker. Sefer şöyle işler:

1. **Direğe vur** (`E`, 2,1 m'den). Kilit varsa satırını gösterir.
2. **Araba gelir:** kadraj dışından, çoğu çağrı 8–15 sn, en çok 20 sn. 40 sn bekler; 60 m'den uzaklaşırsan ya da süre biterse gider. Yeni çağrı 30 sn sonra.
3. **Bin:** kuyruğa 2,6 m'den `E`. Yol Kartı açılır, kart açıkken saat durur.
4. **Seç, kalk:** otomatik kayıt, ücret.
5. **Var:** yavaşlama, iniş, yük teslimi, otomatik kayıt. Yolda inmek için `Esc` ya da kısa `E`: 1,5 sn'de durur, ücret dönmez.

| Yol Kartı seçeneği | Ne yapar |
|---|---|
| Yolu İzle | Gerçek yolculuk, yolcu kamerası, Kantu'nun sohbeti. Uzun yolda Yol Akışı araba, saat ve güneşi en çok 4 kat hızlandırır: 229 sn'lik yol 66 sn'ye iner |
| Yolu Kısalt | `E` basılı ya da karttan: 3 sn kararma, toplam ≈6 sn. 2,4 sn'den önce bırakırsan iptal. Kül Sabahı ve Yolcular görevinde kapalı |
| Yük Bindir | Heybeden 40 Yük'e dek: 10 kütük, 8 taş, 10 cevher ya da 13 tulum. Kışlak Menzili Ambar durağıdır, inişte kendiliğinden teslim |
| Kendin Sür | Arabacı becerisiyle. W, S, A, D; yol yardımı kapatılabilir |

**Saat ve beden.** Sefer saati doğal süre × 0,4 oyun dk ilerletir: 55 sn → 22 dk, 229 sn → 1 sa 32 dk. Yol Akışı gerçek süreyi kısaltır, oyun saati aynıdır. Yolu Kısalt kalanı atlar. Tokluk doğal süreyle düşer: 229 sn'lik sefer −7,6. Kısaltmak bedavadır, karnı kandırmaz. Yolcu keçe çatı altında kurudur, sürücü açıktadır ([Hava](/docs/world/weather)).

**Sarsıntı ve yolcular.** Kendin Sür'de güvenli hızı aşınca sarsıntı birikir, 60'ı geçince yolcu şikâyet eder. Yolcular görevi bunu öğretir (Gün III, Kantu'nun dizi tutar): her biri 35 XP, üçü bitince Arabacı. Sazlık Ebesi: Sazlık İskelesi → Kışlak Menzili, 465 m, 100 sn sınırı. Gelinin Anası: Çoban Durağı → Kışlak Menzili, 352 m, çömlek: ≤4 m/sn, sarsıntı 60'ı geçerse kırılır. [Nandu](/encyclopedia/nandu): Sazlık → Ulu Ocak pazarı, 399 m; Geçit'te Sak durdurur; bildirirsen Palak bağı +1, susarsan yedek at.

**Hasar.** Araba iki aşamalıdır: Kırık, Yürür. Sıradan onarım 1 odun, 1 ip. Kırık Tekerlek (96,−127) 2 tomruk, 1 demir pim, 1 ip ister. Kışlak'ta arabaya vurmak uyarı, sonra Güven −3.

| Araç | Çeken | Yolcu | Yük | Yol / kar m/sn | Perde |
|---|---|---|---|---|---|
| Kantu'nun Arabası | 1 at | 4 + sürücü | 40 | 6,4 / 4,0 | I |
| Keçe Araba | 1 at | 4 + sürücü | 60 | 6,8 / 4,4 | II; Plan Kipi'nde Oba |
| Yüksek Teker | 2 at | 6 + sürücü | 80 | 7,0 / 5,0 | III; Boy Yurdu |
| Ordu Arabası | 4 at | 8 + sürücü | 140 | 6,0 / 4,0 | IV; Toy Yeri |
| Keçe Göç Arabası | 4 öküz | 6 | 120 | 3,0 / 2,0 | Çevrede II'den; oyuncuya V, Göçer Avlu |
| Tenteli Araba | 1–2 at | 2 | 0 | 8,0 / 5,0 | V, armağan |

Arabacı becerisi +1 m/sn verir. Çamurda yol hızı 4,8 m/sn'ye iner ([weather.md §8.10](/docs/source/design/weather#8-10-yol-araba-hizli-yolculuk)). Plan Kipi'nde Atölye kategorisinde tek kart **Araba** vardır, tür ◂ ▸ ile seçilir; yeri Ağaç Atölyesi'ne ≤30 m, 6 × 12 m'lik Araba Yeri'dir ([K57](/docs/source/design/decisions#k57), [Plan Kipi](/docs/settlement/plan-mode)). Çevrede yalnız görünenler: Tomruk Kızağı, Öküz Arabası, Yük Devesi. Hun göç arabası için doğrudan kanıt yoktur: Keçe Göç Arabası Pazyryk ve İskit verisinden kurulur, tasarım tercihidir.

**Yük hayvanları (K65).** Yük Atı 30 (II), Yük Devesi 60 (I'de çevrede, II'den oyuncuya; yol dışı gider, çamuru okumaz, fırtına kilidinde yarı hızla yürür), Yük Eşeği 20 (IV), Yük Katırı 35 (V; eğim cezası yok). Deve yük atının iki katını taşır. Yurt Yükü (59) bir keçe arabaya, bir yük devesine ya da iki yük atına sığar; Küçük Yurt Yükü (38) bir yük devesine ya da iki yük atına; Otağ Yükü (109) iki yük devesi ve bir yük atına ya da bir Ordu Arabası'na. Çeken hayvan sürüden ayrılır, kesilmez.

```varlik
cart_kantu, cart_felt, cart_high, cart_war, wagon_felt, chariot_yao
cart_ox, sled_log, pack_saddle_horse, pack_saddle_camel, pack_saddle_donkey
```

**Çevre arabaları.** I. Perde'de 8 şerit kızak, öküz arabası, deve ve Kantu'yu yürütür. Kayda girmez, oyuncuyu ezmez, yana iter. Ağır havada (ağırlık ≥3) uçta bekler. Gece ve Tipide şerit yoktur.

**Serbest Gez arabası ([K9](/docs/source/design/decisions#k9)).** Kampta güney patikasında duran bir araba vardır, menüde görünmez; Ev bu kampta geçmez (K106). Sürücü takvimin mevsimine göre konuşur: baharda «Geçitler daha karla kapalı; yaz gelsin.», yaz ve güzde «Yol açık, ama baban izin vermeden bu araba kalkmaz.», kışın «Geçitleri kar kapadı; bahar gelsin.» Hızlı yolculuk yoktur: Serbest Gez tek iç haritadır, haritada başka yere tık «Serbest Gez'de yol kapalı.» yazar. Yeri Godot kampının güney patikasında yeniden seçilir: araba patikayı kesmez, eğim ≤7°, menü karesi değişmez.

## Sürücüler

| Kişi | Perde | Hat | Koşul |
|---|---|---|---|
| Kantu | I | Menzil ağı | Kantu'nun çetelesi. Altyazı; yalnız büyük sahne sesli |
| Mete | I+ | Aynı araba | Arabacı; Yolcular ve Kül Sabahı'nda zorunlu |
| Balamir | II+ | Islık Alanı hatları, Kuzey Kapısı ([K41](/docs/source/design/decisions#k41)) | II. Perde. Göç kolu başı |
| Nandu | II+ | Batı deve hattı | Sustuysan ücret ×0,5, yoksa ×2 |
| [Mene](/encyclopedia/mene) | IV | Kışlak, Yaz | Kantu'nun ve çanın kaderine bağlı. Sohbet yok, gidilecek yer el diliyle seçilir |
| Han arabacısı | V–VI | Tören yolu | Barış |

**Kantu'nun takvimi.** Gün I yalnız giriş seferi. Gün II teker onarılınca 11:00–17:00. Gün III 08:00–10:30 ve 13:30–17:00, öğle Yolcular. Gün IV 08:00–16:00, baskında teker kırılır. Gün V 07:30–10:00 yalnız yaralı seferi, sonra hat kapanır. Son Gece ve Gün VI kapalı. 21:00–07:30 uyur. Çevrim 2.438 m, 2 sa 53 dk oyun saati.

**Yol sohbeti.** Yolu İzle'nin nedeni budur. 18 sn'de en çok bir satır, altyazı; 12 satır görev ipucu, işaret ve bayrak verir. Yolu Kısalt satırı yakmaz, sonraki sefere kalır. Her 5 yeni satırda Kantu bağı +1 (en çok +2). Örnek: «Çanını tut da bin. Yakve o sesten bıktı, ben de.» Bütün satırlar: [travel.md §5.4](/docs/source/design/travel#5-4-yol-sohbeti).

## Uzak Yol

**Gün hesabı.** Dünya 75.000 km²'dir ([K40](/docs/source/design/decisions#k40)); Uzak Yol'un km'si, günü, bedeli ve gerçek süresi bu ölçeğin gösterim km'siyle hesaplanır ([Harita ve Ölçek](/docs/world/map)). Gün = km ÷ (hız × arazi), yarım güne yuvarlanır, en az yarım gün. Hız km/gün: at 40, yedek atla 60, araba 25, deve 30, öküz 16. Kış ×0,7. Arazi: bozkır 1, karışık 0,9, çöl ve Gobi 0,85, dağ ve orman 0,7–0,8. Gerçek uzaklık yalnız Destan Kitabı'ndadır: «Gerçekte ≈990 km; bir atlı için haftalarca.»

**Süre ve saat.** Gerçek süre 8 sn + km × 0,25 sn, 10 ile 30 sn arası; çok bacaklı yol toplam 30 sn'yi geçmez. Varışta saat yol günü kadar atlar, atlanan günler takvime işlenir; 24 saati aşan bacak tek uzun atlamadır. Güneş ufkun altındaysa varış ertesi doğuş + 30 dk'ya kayar ([Zaman ve Takvim](/docs/world/time-calendar)).

| Yol | Üzerinden | km | Gün at / araba / öküz | Yiyecek, ücret | Gerçek sn | Açılış |
|---|---|---|---|---|---|---|
| Hexi ↔ Tanhu Kampı | Hey Irmağı, Alaşan, Gobi | 63,6 | 2 / 3 / 4,5 | 3, 6 | 24 | Duyulur: Av. Bilinir: Ev. II–III Hexi yönü kapalı; IV'te uç Kışlak, Yaz |
| Tanhu Kampı ↔ Lung-çeng | | 4,3 | 0,5 / 0,5 / 0,5 | 1, 1 | 10 | IV |
| Tanhu Kampı ↔ Hangay | Lung-çeng | 13,7 | 0,5 / 0,5 / 1 | 1, 1 | 11 | VI |
| Tanhu Kampı ↔ Islık Alanı | Gobi | 36,2 | 1 / 1,5 / 2,5 | 2, 3 | 17 | II |
| Islık Alanı ↔ Tanhu Ordusu | Gobi | 30,0 | 1 / 1 / 2 | 1, 2 | 16 | II |
| Tanhu Kampı ↔ Tunghu Yurdu | Tula, Kerulen | 73,1 | 2 / 3 / 4,5 | 3, 6 | 26 | III |
| Tanhu Ordusu ↔ Ordos | Yin Dağları | 36,4 | 1 / 1,5 / 2,5 | 2, 3 | 17 | IV |
| Ordos ↔ Kışlak, Yaz | Helan, Alaşan | 48,0 | 1,5 / 2,5 / 3,5 | 3, 5 | 20 | IV |
| Tanhu Ordusu ↔ Mayi | Yin Dağları, Yunzhong | 25,9 | 0,5 / 1 / 2 | 1, 2 | 14 | V |
| Mayi ↔ Baideng | Pingçeng | 8,3 | 0,5 / 0,5 / 0,5 | 1, 1 | 10 | V |
| Tanhu Kampı ↔ Dingling Yurdu | Selenga, Hövsgöl | 42,3 | 1,5 / 2,5 / 4 | 3, 5 | 19 | Seçmeli |
| Kışlak, Yaz ↔ Loulan | Dunhuang | 44,7 | 1,5 / 2,5 / 4; deve 2 | 3, 5 | 19 | Seçmeli |

Yiyecek ve ücret araba ve tek yolcu içindir; açılış sütunu taslaktır. Tablo 12 yoldur, yol eklemek yeni bir karar ister (K41, [K84](/docs/source/design/decisions#k84)). Tanhu Ordusu'ndan Tunghu Yurdu'na ayrı yol yoktur: III'te yol Islık Alanı ve konak üstünden zincirlenir (30 + 36,2 + 73,1 km; atla 1 + 1 + 2 = 4 gün; 30 sn). Tanhu Kampı konaktır: iki bacak «Tanhu Kampı üstünden» altyazısıyla tek satır olur; III'ten konağın adı «Eski Avlu»dur (K41).

**Tanhu Kampı konağı (K41).** Tanhu Kampı II–VI'da Mete için sahnesiz bir atlas konağıdır: orada inilmez, sahne yüklenmez, yalnız varılan iç harita yüklenir. Altı yol orada zincirlenir: Hexi, Lung-çeng, Hangay, Islık Alanı, Tunghu ve Dingling. Yol Kartı varışı yazar, konağı değil. Bedel, yiyecek ve gün iki bacağın toplamıdır, yolculuk en çok 30 sn sürer. Örnek: Islık Alanı → Lung-çeng 36,2 + 4,3 km; atla 1 + 0,5 = 1,5 gün; arabayla 2 gün, yiyecek 3, hat ücreti 4; 17 + 10 = 27 sn. Konakta perde başına en çok 1 olay kartı gelir (eski avludan haber, kalan hane, söylenti); konak varış sayılmaz, XP vermez. Neden: darbe av alanındadır, [Teoman](/encyclopedia/teoman)'ın avlusu II'de yalnız sinemadır, uzak kare. Tanhu Kampı menünün kampı değildir; menü dünyası Göl Obası'dır, hikâyeye girmez ([K6](/docs/source/design/decisions#k6), [K106](/docs/source/design/decisions#k106)). Oynanır bir avlu gerekirse ayrı küçük bir dünya kurulur; Ev'in dünyası böyledir.

| Yol durumu | Nasıl | Haritada | Binek |
|---|---|---|---|
| Duyulan Yol | İki ucun adı açıldı, Bakış Noktası ya da satır | Kesik gri dikiş | Gidilmez; Keşfe Çık varsa bir kez |
| Bilinen Yol | İlk geçiş: hikâye ya da Keşfe Çık | Düz bronz | Kendi atın |
| Hat | İki uçta sürücü, varış durağı bağlı | Çift dikiş, altın | At, araba, yolcu, yük |

**Keşfe Çık.** Duyulan yolda, perde kapısı açıksa: bedel ×2, bir yol olayı kesin, hızlı atlanmaz. Varınca yol bilinir olur. Harita böyle büyür.

**Yolculuk nasıl görünür.** Araba ya da at kapıdan kadrajdan çıkar (4–6 sn), kısa kararma, atlas açılır. Şerit çizilir, iğne konaktan konağa yürür, gün sayacı «Gün 2 / 3» döner, her oyun günü bir pozlama nabzı atar. Yeni dünya arkada kurulur: ağır adım yalnız iğne konakta dururken çalışır, takılmayı konak gizler. Varışta son 30 m yürünür (4–6 sn). Yolda inme yoktur, çünkü arada dünya kurulmaz; olaylar kart olarak gelir. `E` basılı tutmak süreyi ×4 hızlandırır; ilk seferde hikâye yolu atlanmaz. Müzik yolculuğun ezgisidir: D Dorian, seyrek ve parmakla çalınan kopuz, dron, rüzgâr; motif konak başına bir kez gelir, biçimi perdenindir; atlasta müziğe hava katmanı girmez.

```varlik
ui_road_card, music_road_leg
```

**Anlatıcının yol cümlesi (K84).** II'den başlayarak her Uzak Yol'un ilk geçişinde anlatıcı tek cümle söyler: yolun geçtiği yerler ve o yerin Mete'nin hayatındaki yeri. Satır A dilimidir: İngilizce, ≤80 karakter, Türkçe altyazılı, ses Eldrin. Şerit çizilmeye başlayınca 1 sn sonra girer, en çok ≈6,7 sn sürer ve en kısa yolculuğa (10 sn) sığar; çalarken atlama kapalıdır. Sonraki geçişler sessizdir. Konak zincirinde her bacağın ilk geçişi kendi cümlesini alır, ikincisi 0,8 sn sessizlikten sonra gelir. Cümle sürerken müzik −6 dB, ortam −3 dB iner ([K78](/docs/source/design/decisions#k78)). I. Perde'nin eve dönüş bacağı ağ seferi değildir, cümle almaz. Satırlar taslaktır, II. Perde'nin metin kilidinde kesinleşir. 12 satırın İngilizcesi 829 karakterdir (≈829 kredi; K84'ün üst kestirimi ≈960 karakter, ≈1.000 kredi). Üretim II'nin metni kilitlenince sana sorulur; o güne dek cümle altyazıyla akar.

| Yol | İlk geçiş | Türkçe altyazı | EN karakter |
|---|---|---|---|
| Tanhu Kampı → Islık Alanı | II | Gobi'nin çakılını aşıp güneye, Islık Alanı'nın beş pınarına. | 72 |
| Islık Alanı → Tanhu Ordusu | II | Gobi'nin kıyısınca doğuya, Mete'nin payı olan otlağa. | 67 |
| Tanhu Kampı → Tunghu Yurdu | III | Tula ve Kerulen boyunca doğuya, Tunghu'nun otlağına. | 63 |
| Tanhu Kampı → Lung-çeng | IV | Lung-çeng'e: Hun beşinci ayda orada toplanır, atalarını anar. | 80 |
| Tanhu Ordusu → Ordos | IV | Yin Dağları'nı aşıp Ordos'a, Mete'nin doğduğu otlağa. | 76 |
| Ordos → Kışlak, Yaz | IV | Helan'ı ve Alaşan kumunu geçip batıya, Kışlak'a dönüş. | 73 |
| Kışlak ↔ Tanhu Kampı | IV | Hey Irmağı boyunca kuzeye, Alaşan ve Gobi'yi aşarak: bir zaman kaçıp döndüğü yol. | 77 |
| Tanhu Ordusu → Mayi | V | Yin geçitlerinden güneye, Han sınırının kenti Mayi'ye. | 63 |
| Mayi → Baideng | V | Mayi'den Pingçeng'e, Baideng denen tepeye. | 55 |
| Tanhu Kampı → Hangay | VI | Lung-çeng'i geçip Hangay'a, Orhun'un doğduğu yaylaya. | 63 |
| Tanhu Kampı → Dingling Yurdu | Seçmeli | Selenga ve Hövsgöl boyunca kuzeye, Dingling'in ormanlarına. | 73 |
| Kışlak, Yaz → Loulan | Seçmeli | Dunhuang'ı geçip batıya, Lop tuzlasının kıyısındaki Loulan'a. | 67 |

**Binme yeri.** Her iç haritada bir Uzak Durak vardır. Kışlak'ta Kemik Boğazı Kapısı'dır; I. Perde'den sonra yalnız IV'ün Kışlak, Yaz'ında. Islık Alanı'nda Kuzey Kapısı vardır, Yol Kartı orada konak üstünden Lung-çeng, Hangay, Tunghu, Dingling ve Hexi yollarına çatallanır; doğu kapısı Tanhu Ordusu'na açılır. Tanhu Kampı'nda kapı yoktur (K41). Herhangi bir bağlı duraktan zincirlenir: yakın ayak kararmada atlanır, ücretsizdir.

Doğrulanacak: haritadan çıkış yönü ilk yol bacağından en çok ±30° sapar. Kuzey Kapısı iç haritanın batı kenarındadır (yönü 270°), konağa kuş uçuşu ≈335° (K106): fark ≈65°. Kural Islık Alanı kurulurken gerçek ilk bacakla sınanır; tutmazsa kapı kuzeybatı kenarına kayar, adı «Kuzey Kapısı» kalır ([Yol Haritası](/roadmap#item-interior-maps)).

**Parti atlasta ([K70](/docs/source/design/decisions#k70), [K73](/docs/source/design/decisions#k73)).** Parti tek iğnedir: yoldaşlar Mete'nin iğnesinin çevresinde 10 küçük baklava olarak yürür. Hız en yavaş üyenin hızıdır, bedel onluğun bedelidir: 10 kişilik parti her yolda +2 Aş öder. Partide olmayan yoldaş bulunduğu konakta portre iğnesidir; Ordugâh'a Gönder ve Çağır atlas günü kadar sürer ([Yoldaşlar](/docs/gameplay/companions)).

**Yol olayları (II. Perde ve sonrası).** Sefer başına en çok 1, yol ≥1 gün ise %25, her biri perdede bir kez; konağın olay kartı da bu sayıya girer. İç haritadaki Taş Yığını'na `E` 2 sn ile 1 taş ya da 1 kıl bırakanın o haritadan sonraki seferinde olasılık %20'ye iner ([K35](/docs/source/design/decisions#k35)); konuk elçi Xi Huqian partideyken de %20'dir ([K74](/docs/source/design/decisions#k74)), ikisi birikmez.

| Olay | Seçim | Sonuç |
|---|---|---|
| Benekli Atlı | Selam Ver · Geç | O seferde Topal At ve Kuru Kuyu çıkmaz, [Yol Tengrisi](/encyclopedia/yol-tengrisi)'nin Destan girdisine satır · yok |
| Topal At | Bekle · Bırak | +0,5 gün, 1 yiyecek · yedek at gider |
| Kuru Kuyu | Yem ver · Zorla | −1 Yem Bağı · varışta binek −%30 |
| Kervan | Takas · Geç | Mal takası, açılmamış bir ad atlasa · yok |
| Kaçkınlar | Paylaş · Geç | −2 yiyecek, Kut +1 · Korku yok, satır |
| Kurt Sürüsü | Ateş · Sür | −1 odun · −1 yiyecek |
| Elçi | Dinle · Geç | Bir yol duyulur · yok |
| Fırtınaya Yakalanma | Sığın · Sür | +0,5 gün (Gecelik Çadır varsa bedelsiz) · −1 yiyecek, yedek at %25 topallar |
| Toz Duvarı | Yere Yat · Yön Bul | +0,5 gün · %50 yol kaybı: +1 gün, −1 Yem |
| Sel | Bekle · Geç | +0,5 gün · arabadan −4 Yük, can kaybı yok |
| Karda Kalış | Kazın · Yürüyün | +1 gün, −2 yiyecek (Gecelik Çadır varsa −1) · −1 Yem, yorgunluk +20 |

Son dördü havadandır, ağırlığı uç dünyaların ikliminden gelir, «perdede bir kez» kuralı onlara uygulanmaz. Kartta partideki bir yoldaşın tek satırı gelebilir; seçim Mete'nindir.

**Erlik'in Yolu.** Korku ≥18'de açılır. Tek ışınlanma: bedava, anlık, bilinen yol ya da hat üstünde, 3 sn kara buz damarı. Her kullanım Korku +1, bir ocak söner, son kartta görünür. Saat ilerlemez: takvim ne ileri ne geri gider, [Erlik](/encyclopedia/erlik)'in yolu zamanın dışındadır (K67).

**İkmal kervanı ([K23](/docs/source/design/decisions#k23)).** Yerleşimle ana ordugâh arasında, Islık Alanı ↔ Tanhu Ordusu yolunda (30 km) gider. Kervan Oba'yla (kademe 2) açılır; Ocak'ta kervan yoktur, onluktan bir Azıkçı iki günde bir Tan'da 2 öğün alıp terkisiyle götürür ([K54](/docs/source/design/decisions#k54)). Buyrukla iki günde bir Tan'da kalkar, dönüş ertesi Tan'dır; araç başına bir sürücü; gidişte kuru erzak, keçe, ok; dönüşte ganimet payı, deri, at. Bir keçe araba yerine bir deve konabilir: aynı 60 Yük, yolsuz gider, Gobi yolunun doğal seçimidir. Fırtına kilidinde kalkış en çok 6 oyun saati bekler. III'ten Akın olayı gelir (olaylar içinde payı III %30, IV %20, V %35): onluk koruma %60, Yüzlük %90 püskürtür, korumasız kervan yükün yarısını yitirir. Mete katılırsa olaylar ona sorulur, yoksa Yol Töresi kendi çözer. Akan Kronik yoldaki kervanı varmış sayar ([travel.md §9.9](/docs/source/design/travel#9-9-ikmal-kervani-supply-caravan-k23)).

## Bedeller

| I. Perde | Bedel | Not |
|---|---|---|
| Sefer | 1 Aş ya da 1 odun | Mesafeden bağımsız |
| Kantu bağı ≥5 | 0 | |
| Ağda ilk sefer | 0 | Tanıtım |
| Kazık dönüşü | 0, Güven −2 | Kızıl Kazık'ı aşınca Kantu geri getirir |
| Ambar'a yük | Ücret yükten: 1 odun, yoksa 1 Aş | Ardokşa öder |

Karar gerçektir: 1 Aş +35 Tokluk, rehinenin günlük tayını 2 Aş. Kısa yol yürünür, ağır yük için ödenir. Hikâye zorluğunda bedava, Zor'da ×1,5. I. Perde'de para yoktur, Terazi takası sürer.

| II. Perde ve sonrası | Bedel |
|---|---|
| İç harita seferi | Her başlayan 400 m için 1 Aş ya da kabuk |
| Uzak Yol, kendi atın | Her başlayan gün için 1 Aş ya da kabuk; yem: gün ve binek başına 1 Yem Bağı, yalnız kışın ya da Alaşan, Gobi bacağında (yazın at otlar) |
| Uzak Yol, hat | Yukarısı + gün başına 2 değer |
| Birlik | Her 5 üyeye +1 Aş; gezen birlik günde iki öğün erzak öder, 07:00 ve 18:00 |

**Mal değeri (Aş = kabuk, [K48](/docs/source/design/decisions#k48)).** Aş, Kak, odun, Yem Bağı, Tunç Kabuk 1. Kurut, balık, yün 0,5. Deri, tuz 2. Demir 4. Gümüş Parça 8. Yurt Yükü 60. 1 kabuk = 4 Kıymet = 1 Aş; yol bedelinde kabuk her sürücüde 1:1 sayılır, pazarın yabancı satıcı kuralı (0,6) yola uygulanmaz.

**Erzak yetmezse** yol kapanmaz, beden öder: varışta Tokluk ≤25, binek staminası 5 dk −%30. Ölüm yok.

**Beceriler.** Arabacı: Kendin Sür, +1 m/sn, sarsıntı yarı. Yol Dostu: +2 yolcu, yolcu ödülü ×1,5, durak haberi. Ulak: ücret 0, varışta binek dinç, direkler durak olur. Ordu Ambarcısı: ücret ×0,5, erzak ×0,75. Ulu Ambar: bütün ambarlar tek. Yedek At: Uzak Yol'da 60 km/gün. At Çağrısı: duran atı 300 m'den çağırır. Tümen Çağrısı: tümen seçili Menzil'e 6 oyun saatinde gelir.

## Hikâye kilitleri

İlk tutan kilit satırını gösterir.

| Sıra | Ne zaman | Satır |
|---|---|---|
| 1 | Kara Boran, Kemik Boğazı, ileride takip | «Peşindeler. Durak yok.» |
| 2 | Hüküm, Göz Yolu, hapis | «Bağlısın.» |
| 3 | Düğüm'den Adak Aygırı'na | «Bu gece kimse seni taşımaz.» |
| 4 | Sazlık Yanıyor | «Yol yanıyor.» |
| 5 | Kül Sabahı bitti | «Hat kapandı. Araba yalnız yaralı taşır.» |
| 6 | Kadrajda düşman | «Önce şunları savuştur.» |
| 7 | Araba kalkmaz hava: gök gürültülü ve kuru fırtına, dolu, fırtına, tipi, toz, Kara Boran | «Fırtına dinmeden araba kalkmaz (≈{n} saat).» |
| 8 | Hat arabası Kırık | «Araba kırık.» |
| 9 | Kantu'nun çetelesi yok | «Teker kırık. Kantu bir yere gitmiyor.» |
| 10 | Kantu 21:00–07:30 uyur | «Kantu uyuyor. Sabah gel.» |
| 11 | Gün IV akşam | «Bu akşam herkes kâsede.» |
| 12 | Rütbe yetmez | «Bu durak sana kapalı. Gereken: {kefil}.» |
| 13 | Uzak yol, I. Perde bitmedi | «Rehine vadiden çıkmaz.» |
| 14 | Uzak yol kapısı kapalı | «Bu yol henüz açılmadı.» |
| 15 | Yük 40'ı aşıyor | «Bu yükü Yakve çekmez.» |
| 16 | Mal yok | «Ücret: 1 Aş ya da 1 odun.» |

**Son Gece.** Hat kapalıdır, araba başka işe döner. Kantu'yu bağışlarsan fenerli araba güneye gider, takipçi −1 grup. Zorlarsan heybeni ve eyeri Geçit'e kaçırır. Çeteleyi bırakmazsan Kantu arabayı yitirir, IV'ün Kışlak, Yaz'ında araba görünmez.

**Ev sahnesi** ağ seferi değildir: kıştan bahara atlama hikâyeyle ayarlanır («Kış bitti, o hâlâ yoldaydı.»). Ağ bu sahneden sonra açılır.

## Oyunda şu an

> [!DURUM]
> **Godot'da var (act-1-p2, 2026-11-09):** Kışlak'ın Menzil ağı (geliştirme girişi; I. Perde'nin akışı henüz bağlanmadı). Ağ arazinin yol dosyasından kurulur: 23 kenar, 8 Menzil, 14 Yol Kemiği. Menzil bölge açıkken yaya 15 m'ye gelince bulunur, varsa bağlı Yol Kemiği onarılınca bağlanır (+10 XP). Yol Kemiği'ni `E` basılı 20 sn'de, 1 kemik ve 1 iple ya da 4 taşla onarırsın; onarılan direk 120 m'den uğuldar. Menzil Direği'ne `E` vurur (tahta tokmağın tok-tok sesi kodla basıldı), `E` basılı Menzil Ambarı'nı açar. Kantu'nun arabası Meshy'nin keçe araba gövdesidir, tekerlekleri koddur; Yakve çeker, Kantu önde bağdaş oturur. Çağrılınca yoldan sürerek gelir, durakta 40 sn bekler. Arabanın ardında `E` ile binersin: Mete arka ağızda geriye bakarak oturur, bacakları sarkar, örtü üstünde kesilir; kamera 40°, 32 m. Yol Kartı'nda bağlı duraklar metre, süre ve ücretle yazar, kart açıkken saat durur: `1` Yolu İzle (araba yolu gerçekten sürer), `2` Yolu Kısalt (basılı 3 sn kararma; araba hedefe 18 m kalaya taşınır, saat kalan süre kadar atlar), `3` Yük Bindir (40 Yük; Kışlak Menzili'nde Ambar'a teslim). Araba oyuncunun koşusunu aşmaz: yolda 4,6, karda 4,0 m/sn ([K105](/docs/source/design/decisions#k105)); Kışlak Menzili → Çoban Durağı ≈77 sn, ≈31 oyun dk. Ücret 1 Aş ya da 1 odun; ilk sefer ve Kantu bağı ≥5 parasız. Kantu 21:00–07:30 uyur; rütbe, bölge, baskın, Son Gece ve kovalamaca kilitleri bayrakla okunur. Kalkış ve iniş otomatik kayıt yazar. Deneme haritasında üç durak, iki Yol Kemiği ve araba vardır. Kareler: [araba Menzil'de](/media/docs/media/review/kislak_menzil_araba.jpg), [yolculuk](/media/docs/media/review/kislak_menzil_yolcu.jpg) ve [kırpımı](/media/docs/media/review/kislak_menzil_yolcu_kirpim.jpg), [Yol Kartı](/media/docs/media/review/kislak_menzil_yol_karti.jpg), [onarılmış Yol Kemiği](/media/docs/media/review/kislak_menzil_kemik_onarilmis.jpg), [kırık Yol Kemiği](/media/docs/media/review/kislak_menzil_kemik_kirik.jpg). **Yok:** Yol Akışı, Kendin Sür ve sarsıntı, Kantu'nun sohbeti ve takvimi, Yolda seslenme, Menzil'de dinlenme, çevre arabaları, Uzak Yol, atlas şeridi, yol olayları, kervan, Serbest Gez arabası. Ayrıntı ve sapmalar: [travel.md §4.5](/docs/source/design/travel#4-5-godot-da-act-1-p2-2026-11-09). Prototipte denendi: araba betikle ölçüldü (4.404 üçgen, 2 çizim); envanterde Menzil Ambarı ve araba kapları, beceri metinleri, saatin yolculuk atlaması yazıldı.

## Yol haritası

Kışlak'ın yol ağı, Menzil durakları ve araba I. Perde'nin Kışlak fazındadır; atlas, Uzak Yol ve iç haritalar II. Perde'nin ilk fazındadır; kervan ve yük hayvanları [act-2-p2](/roadmap#act-2-p2) fazındadır.

```ilerleme
act-1-p2, act-2-p1
```

## Kaynaklar

- [decisions.md: K6, K9, K20, K22, K23, K35, K40, K41, K48, K54, K57, K65, K67, K70, K73, K74, K78, K84](/docs/source/design/decisions#k41)
- [travel.md: bütün yolculuk tasarımı](/docs/source/design/travel)
- [travel.md §8: hikâye kilitleri](/docs/source/design/travel#8-hikaye-kilitleri)
- [travel.md §9: Uzak Yollar, konak, yol cümlesi](/docs/source/design/travel#9-uzak-yollar-atlas)
- [travel.md §10.3: Serbest Gez arabası](/docs/source/design/travel#10-3-serbest-gez-arabasi)
- [act1.md §9.4: araba](/docs/source/design/act1#9-4-araba-yolcu-hizli-yolculuk)
- [weather.md §8.10: yol, araba, hızlı yolculukta hava](/docs/source/design/weather#8-10-yol-araba-hizli-yolculuk)
- [settlement.md §3: yerler ve kapılar](/docs/source/design/settlement#3-yerler)
- [fauna.md §2: binek ve yük](/docs/source/design/fauna#2-binek-ve-yuk)
- [d3/game-state: Godot'daki oyunun bugünkü hâli](/docs/source/design/d3/game-state)
