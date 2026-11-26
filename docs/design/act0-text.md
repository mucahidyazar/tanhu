# Yeni Oyun metni: ozan, anlatıcı ve sahnelerin sözleri

Bu belgedeki kod yolları (`src/…`, `tools/*.mjs`) Three.js prototipinindir; Godot karşılıkları `godot.md`'dedir (§3.3, §3.6).

Kaynak: `decisions.md` K17, K33, K35, K36, K60, K61, K68, K75, K78, K96, K105. Sahne sahne zaman çizelgesinin sahibi `story.md` §3'tür; bu belge satırları ve açılışın sırasını tutar. Satır kimlikleri `act0.*`; prototipte paket 5.5 bu metni kullanır, Godot'da satırlar `game/data/vo_lines.json`'a girer (K61). Tanhu 1 satırı yoktur. Söylenen dil İngilizce, altyazı Türkçedir (K61). Tarih: Shiji 110 (東胡彊而月氏盛; Meng Tian'ın sürgünü; Teoman'ın gözde hatunu ve küçük oğlu; Mete'nin rehin verilişi); doğum 27 Eylül MÖ 234 şafağıdır (K33). Babanın ihaneti burada söylenmez: I. Perde'de öğrenilir. Oyunun bütün satırları `game/audio/vo/prologue/` altındadır; sitenin kopyaları `docs/media/audio/vo/en/`'dedir (oradaki N2, N3 ve N6 eski metinlidir); şarkının çekimleri `docs/research/bard-takes/`'tedir.

## Açılış sırası (K68)

Kullanıcının sırası (E4.2): Yeni Oyun'a basınca kamera ozana yaklaşmaz, geri çekilir; kamp, gök ve dağlar aynı karede görünür. Ozanın kopuzu duyulur, ozan sözlerini söyler. Kısa bir sessizlik olur, ekran kararır. Mitolojik sinematik sahne açılır, anlatıcı mitolojik hikâyeyi anlatır. Ardından ayrı bir sahne Mete'nin doğumuna bağlanır. Saniyeler Yeni Oyun'a basıştan sayılır; Önsöz saat okumaz (K20, K67).

| # | Sahne | Saniye | Ne olur | Ses |
|---|---|---|---|---|
| 1 | Geri çekilme | 0:00,0–0:06,0 | Menü yazıları 0,5 sn'de söner. Kamera ozana yaklaşmaz, menü kadrajından geri çekilir: ateşe 26,4 m'den 40 m'ye (1,52 kat), eğim 38°'den 9°'ye, görüş 36°'den 41,76°'ye; yön (kuzey) kalır; yumuşak giriş ve çıkış (K98; geniş kare onaylı ufuk istisnasıdır). Son karede gök ve dağlar üstte (zirveler yukarıdan %10'a dek, ufuk %29'da), vadi ve göl ortada, kamp alt üçte birde (ateş %80'de). Gökte ilk yıldızlar vardır, ay yoktur. 0:04,2'de ozan kopuzu kaldırır | Menü müziği 2 sn'de `camp_bard` dronuna iner; ateş, rüzgâr |
| 2 | Şarkı | 0:06,0–0:32,9 | Kamera durur, menünün salınımıyla nefes alır (0,06 m). Ateş başında Ozan, Ana, Baba, Ağabey ve Çocuk; Çocuk ozana döner. Ozan kopuzla iki dizeyi söyler. Plan geniştir: yüz yakın planı ve ağız eşlemesi yoktur, ozanın kolu kaydın vuruşuna uyar (0:08,3–0:28,6) | `act0.bard.song`, çekim 3104, 26,85 sn: kopuz 0:06,0'dan yükselerek girer; ses 0:09,9–0:14,7 ve 0:19,5–0:24,3; son vuruşu avuç susturur (0:28,6) |
| 3 | Sessizlik ve kararma | 0:32,9–0:38,9 | Ozan avucunu tellerde tutar, kimse kıpırdamaz, duman yükselir (3 sn); ekran 2 sn'de kararır, 1 sn kara kalır | Alçak sessizlik: müzik yok, rüzgâr −40 dB, ateş. Rüzgâr kara ekranda da sürer: bu kara sessizlik değildir |
| 4 | Mit sineması | 0:38,9–3:22,4 | Ozanın ilk sözü karada; perde sonra açılır, parşömen videosu (K93; dosya yoksa keçe panolar). Sıra: su ve iki kara kaz, düşüş ve taş, boğazdaki toprak, adın alınışı ve Erlik, dokuz dallı ağaç ve dokuz kişi, sözsüz gök çadırı ve Demirkazık, ilk ölü ve sekiz, ırmak «Doymadım», ilk ateş, taşta duran Erlik, doğum yurdu. Her satırın kaynağı aşağıdadır, ekrana yazılmaz | Ozan (David), satır 3–25; kopuz satır aralarında ≥1,5 sn cevap verir, 3, 10, 11, 17, 18, 20, 23 ve 25'ten sonra vermez; sinemanın tek korosu gök panosundadır |
| 5 | Doğum | 3:22,4–4:07,9 | Ayrı sahne: mit videosunun közü (K93; yedeği keçe köz) 1,5 sn'lik çakışmayla Lan Hatun'un ocağının gerçek közüne döner. Ordos, 27 Eylül MÖ 234 şafağı, `childhood_ordos` dünyasında 3B: mit parşömende, tarih dünyada. Çekimler uzak ve yukarıdandır (K98): yurdun içi çatısız diorama; Teoman otağından çıkar, doğan güne eğilir; batıda dolunay ufukta (ay karesi ufuk istisnası). İlk ağlama; Hereka sayım hattına seslenir, sayıcı çubuğa çentik atar; kart «27 Eylül MÖ 234 · Ordos». Hereka eşi toprağa gömer, beşiğe küçük ok-yay asar. Ad konmaz | Anlatıcı (Eldrin), satır 12: tarih burada ozandan anlatıcıya geçer; Hereka'nın sözü; Önsöz'ün tek kara sessizliği (2,5 sn, −60 dB rüzgâr kuyruğu, K59); motifin bütünü ilk kez kopuzla |
| 6 | Geçiş | 4:07,9–4:17,9 | Kamera beşiğin uzak karesinde durur; beşiğin yayı parşömene döner (`childhood.ogv`, yedeği keçe pano), koyuna binen çocuk belirir; Çocukluk başlar | `childhood`: majör pentatonik, kopuz hızlanır |

Toplam 4 dk 18 sn (satırların gerçek süresiyle); hedef 4 dk 19 sn ± 15 sn (K96: K68'in 3 dk 45 sn'si bu mit için kalktı). Esc her an atlar; ikinci oyunda varsayılan atlanır (`GameSettings`, kayıtta değil). Süreler okunan dosyalarındır (`seconds`); zaman çizelgesi satırın gerçek süresine bağlıdır, satır uzarsa sonraki işaretler aynı payla kayar.

**Önsöz'den sonra (K36).** Çocukluk «Koyun Sırtında» (`mq0_sheep`, 22 Eylül MÖ 228, oynanır, ≈6 dk) → Köprü 1 (N1–N5, ≈50 sn) → oluşturucu «Yola Hazırlan» → Yola Çıkış (`mq0_depart`, 15 Aralık MÖ 213, ≈90 sn) → Köprü 2 (N6–N7, ≈18 sn) → I. Perde'nin kara ekranı ve çanı. İlk oyunda ≈12 dk, oluşturucu hariç (`story.md` §5, §6; `act1.md` §1, §12). Bugün Yeni Oyun bu sırayı oynatır, yapılmamış Yola Çıkış ve I. Perde atlanır, sonda «I. Perde: Çan / Yapım aşamasında.» kartı ve açılış ekranı gelir (K99; `data/story/new_game.json`).

(K68 ile değişti: K19'un yüz yakın planı, «ilk vuruşla geri çekilme»si ve Önsöz'de David'in konuşma sesi kalktı. Anlatıcı bölümündeki «Kamera geri çekilip kampı ve göğü gösterirken» notu da kalktı: köprü satırları artık Çocukluk'tan ve Yola Çıkış'tan sonra keçe panolarda okunur.) (2026-11-07: köprüler de keçe değil parşömen videosudur; aşağıda «Köprüler».)

## Ozan (`speaker: bard`, ses David `BNgbHR0DNeZixGQVzloa`)

Önsöz'de ozan şarkıyı söyler, ardından mitin sözünü verir (K35, K96; K68'in «ozan konuşmaz» maddesi kalktı): sesi David'dir, ateş başında ve Kopuz Gecesi'nde de odur. Satırlar aşağıda, «Mit sineması ve doğum» tablosundadır.

**Çalgı (K60).** Kopuz: üç telli, perdesiz, parmakla çalınan, gövdesinin bir bölümü deri, bağırsak telli uzun saplı lavta. Dombra, komuz, topşur ve saz oyunda geçmez; yaylı çalgı «kıl kobuz»dur ve Mete'nin çağında elde görünmez. Kural: «Batı akoru yok, üçlü basılmaz. Kopuz parmakla çalınır: tırnakla aşağı, parmak ucuyla yukarı vuruş, tellere sıyırma ve tek tele fiske serbesttir; mızrap ve akor tıngırtısı yoktur. Ezgi bir telde, öteki teller açık dron; aynı anda en çok üç tel.» Görüntüde üç tel ve deri göğüs görünür; ozanın kolu kaydın vuruşuna uyar (K95; çekim 3104'ün ızgarasında 1,2534 tur/sn, söylerken yavaşlamaz). Godot'da ateş başındaki düğüm `Elder/Kopuz`'dur (Yol Haritası `camp-cast`, `kopuz-model`): üç telli Meshy kopuzu oyunda (2026-11-06; yeni konsept, E7.7, 40 kredi), model yokken kodla çizilir; göz onayı Karar Bekleyenler'dedir.

**Şarkı (K60, #59).** Şarkı iki dizedir, dörtlük değildir. Destan Kitabı'nın dörtlük sayfası ve I. Perde'nin perde kartındaki dörtlük okunan metindir, şarkı değildir. ElevenLabs Eleven Music (`music_v2_5`) yaşlı ozan sesiyle ve kopuzla söyler; kampın kipi ve hızı: D Dorian (doğal F ve C), 6/8, noktalı dörtlük 52, her sekizlikte vuruş, gırtlaktan hece başına bir nota. Ses ve kopuz tek dosyadır, `act0.bard.song`, 26,85 sn: 2 ölçü kopuz girişi (plan 4.616 ms; ses 3,92 sn'de girer), her dize 4 ölçü ve ardından kopuzun cevabı, 2 ölçü kopuzla kapanış (plan 27,7 sn). A G F D motifi iki dizenin son üç ölçüsündedir. Çekim 3104'tür (2026-11-04, tarifin ilk kolu; kullanıcı dinleyip seçti, K95). Modele giden tarif çalgıyı komuz diye fiziksel olarak anlatır (`kopuz.md` öneri 1–3); oyunda ad kopuzdur.

Çekim 3104'ün ölçüleri: saniyede 2,12 vuruş, 1,28 kHz üstü %9,7, sönüm 7,8 dB / 0,1 sn, söz ile çalgı düzey farkı 6,2 dB, eş zamanlı perde 2,39; kip ölçülemedi, motif bulunamadı. Vuruş ızgarası (bilgi) 0,399 sn'dir, vuruşların %73'ü oturur; kol ona uyar. 2,12 ise giriş ve çıkışın ortalamasıdır, paydasında sessiz baş ve kuyruk da vardır (`audio.md` §2 «Görüntü ve sinema»).

**Ölçütler (K75).** K60'ın kuralı aynen kalır (Batı akoru yok, ezgi bir telde, öteki teller açık dron, aynı anda en çok üç tel); değişen, aracın onu nasıl ölçtüğüdür. Ölçütler üç sınıftır.
- **Sınır** (uymayan çekim seçilmez): 23 sözcük sırayla, ses girişi 3–6 sn, dize arası ≤6 sn, boy 22–32 sn ve eş zamanlı perde ≤3. Eş zamanlı perde yalnız sözsüz çalgı bölümlerinde (giriş, dize arası cevap, çıkış) ölçülür: her karede art arda harmonik çıkarmayla sayılan perdelerin ortalamasıdır (`kopuz.md` §7). O bölümleri sözcük zamanları bulur; orada ses olmadığı için karışık dosya çalgının kendisidir. Aynı ölçü denetim sinyallerinde Batı tıngırtısına 4,33, `dombra.js`'e 1,84, prototipin kopuz sentezine 2,57 verdi.
- **Sayılan ölçüler** (çekimlerin sırası): vuruş/sn ≥2,0, 1,28 kHz üstü enerji ≥%8, 2–6 kHz sönümü ≥4 dB / 100 ms (K60'ın 300 ms'de 12 dB'i), söz ile çalgı düzey farkı ≤12 dB.
- **Bilgi** (araç yazar, sırayı değiştirmez): iki dizenin son üç ölçüsünde A→G→F→D; söz kipi F / (F + F♯) ≥0,7 de denetimi geçene dek bilgidir; vuruş ızgarası (dönem, ilk vuruş, oturan vuruş oranı): ozanın kolu seçili çekimin ızgarasına uyar (K95).
- **Sözlü bölüm.** Kip ve motif sözlü bölümdedir. Orada sözcük zamanları sesi çalgıdan ayırmaz: kopuz ezgiyi sesle aynı anda bir telde çalar, dronun harmonikleri sesin bandındadır (D'nin 5. harmoniği F♯). Araç bu bölümü önce yerelde, kredisiz, açık kaynaklı bir kaynak ayırma modeliyle (ör. Demucs) ses izine ayırır, perdeyi ses izinde pYIN ile çıkarır; 30 kareden az perde yakalanırsa «ölçülemedi» yazar.
- **Denetim.** Kipi bilinen eski çekimler 3101 (D majör, F♯ baskın) ve 3103 (D Dorian) kodla kopuzla, 3106'nın 5 dB düzey farkında karıştırılır. Araç ikisinin kipini doğru bulursa söz kipi sayılan ölçü olur, bulamazsa bilgi kalır.
- **Koşu.** Ölçü ve denetim bir sonraki çekim turundan önce araca yazılır ve dört çekimde (3104–3107) kredisiz koşulur (Yol Haritası `song-measure`). Seçilecek çekim eş zamanlı perde sınırını geçmezse bu, kullanıcı dinlemeden önce söylenir (2026-11-06 koşusunda dördü de geçti, 3104 2,39).

(K75 ile değişti: eski liste eş zamanlı perdeyi, söz kipini ve motifi aynı eşik listesinde sayıyordu; dört çekimin dördünde kip ve motif, ses çalgıdan ayrılmadan ölçüldüğü için ölçülemedi.) Son onay kulaktadır (K60): kullanıcı çekimleri dinledi ve 3104'ü seçti (K95). Çekim yeniden açılırsa yeni tur 4 çekimdir (≈1.620 kredi); o da geçmezse deri gövdeli ikinci kol 4 çekim alır; ikisi de geçmezse B planı: a cappella ses ve kodla kopuz, yine tek dosya (kopuz söz altında −9 dB, yalnızken −3 dB; mono, −18 LUFS). Her çekim önce kullanıcıya sorulur. Plan `src/story/act0/bard-song-plan.js`'te, sözcük zamanları `bard-song-take.js`'tedir; dosyayı `node tools/bard-song.mjs` kurar, ölçüleri `tools/song-measure.mjs` alır (prototip; çekim 3104'ün oyundaki dosyası aynı adımlarla `game/audio/vo/prologue/`'a yazıldı, ölçü `game/tools/song/k75_measure.json`). Şarkı 2B'dir, ozanın yönüne en çok %10 kaydırılır; altyazı sözcük zamanlarından çıkar, kol kaydın vuruş ızgarasına uyar (K95).

1. dize 2026-11-04'te değişti: «kulun» imgesi Tanhu 1'in ninnisine yakındı (`story.md` §3). Aşağıdaki iki satır şarkının altyazısıdır, söylendikleri saniyede ayrı açılır; ayrıca okunmaz.

| id | Saniye | EN (söylenen) | TR (altyazı) |
|---|---|---|---|
| `act0.bard.1` | 0:09,9–0:14,7 | One more was counted the dawn that the full moon fell, | Dolunay batarken sayıma bir eklendi, |
| `act0.bard.2` | 0:19,5–0:24,3 | and the steppe learned his name from the sound of a bell. | bozkır adını çanın sesinden öğrendi. |

## Anlatıcı (`speaker: narrator`, ses Eldrin, `eleven_v3`, kararlılık 0,5)

Anlatıcı görünmez; hep 2B'dir, ortadadır, yankısı azdır; konuşma −18 LUFS. Satır boyunca müzik ve ortam −3 / −3 dB kısılır (K78'in anlatı ve sinema satırı: `myth`, `camp_bard`, `narration`); iniş 0,3 sn sürer ve satırdan 0,15 sn önce başlar, dönüş 1,0 sn'dir. Son ayar kulakla yapılır (Yol Haritası `voice-bus`). Önsöz'de yalnız doğumun tarih satırını okur (12): mit ozanın, tarih anlatıcının ağzındadır (K35, K96). İki satır kümesi vardır: doğum (12) ve iki köprü (N1–N7).

### Mit sineması ve doğum

Tek omurga vardır: kişi yükselmek istedi, ölüm oldu, doymadı, insan ocağı yaktı, sayım sürüyor. Yeni düşman yok, bir kişi baştan sona. Satır numaraları `story.md` §3'ünkilerdir; 1 ve 2 ozanın şarkısıdır. 3–25 ozanın sözüdür (David, K35, K96), 12 ve Hereka'nın sözü doğumdadır. Ozanın sesine ses zinciri uygulanmaz: anı sessizlik taşır. Kopuz satırların ardından en az 1,5 sn cevap verir; 3, 10, 11, 17, 18, 20, 23 ve 25'ten sonra vermez. Çağ rozetleri (`mitoloji.md` öneri 1): «Yıllıktan» Hun çağı Çin yıllıkları, «Taştan» Göktürk ve Uygur çağının Türkçe tanıkları, «Ozan der» geç derlemeler, «Bizim» oyunun seçimi.

| id | Başlar, süre | EN (söylenen) | TR (altyazı) | Pano | Kaynak, rozet |
|---|---|---|---|---|---|
| `act0.myth.3` | 0:39,4; 2,2 sn | You never asked who counts us. | Bizi kimin saydığını hiç sormadın. | Kara ekran; perde bu satırdan sonra 2 sn'de açılır | «Bizim» |
| `act0.myth.4` | 0:43,3; 5,5 sn | Before there was anyone to count, there was water, and two black geese. | Sayılacak kimse yokken su vardı, bir de iki kara kaz. | Boş deri; «water»da su, «two black geese»te kazlar | Radloff s. 3–4, Holmberg s. 317 «Ozan der» |
| `act0.myth.5` | 0:50,6; 5,9 sn | One was the Sky. The other he had made, and named him Kishi. | Biri Gök'tü. Ötekini kendi yapmış, adını Kişi koymuştu. | Üstteki kaz «Sky», alttaki «Kishi» sözünde kanat çırpar | Radloff s. 3–4 «Ozan der» |
| `act0.myth.6` | 0:58,8; 5,9 sn | Kishi wanted to fly higher than the Sky, and he fell, and the Sky had mercy. | Kişi Gök'ten daha yükseğe uçmak istedi, düştü, Gök ona acıdı. | Kişi öteki kazın üstüne çıkar, düşer; «mercy»de sudan taş, kaz üstüne konar | Radloff s. 4 «Ozan der» |
| `act0.myth.7` | 1:08,4; 8,6 sn | The Sky sent him for earth. One handful he gave. One he hid in his mouth. He wanted a land of his own. | Gök onu dipten toprak getirmeye yolladı. Bir avucunu verdi, bir avucunu ağzında sakladı. Kendine bir toprak istedi. | Dalış, dip, iki avuç, biri suya saçılır; kesme: boğaz yakın planı, gaga kapalı | Holmberg s. 317, Radloff s. 4 «Ozan der» |
| `act0.myth.8` | 1:18,5; 9,8 sn | The world grew, and the earth in his mouth grew with it. "Spit," said the Sky. He has not been full since. | Dünya büyüdükçe ağzındaki toprak da büyüdü. «Tükür», dedi Gök. O gün bugündür doymadı. | Arkada yer büyür, boğaz şişer; «Spit»te Gök ışır, toprak saçılır, bataklık; kesme: geniş plan, açık gagalı kaz | Holmberg s. 317–318, Radloff s. 4 «Ozan der»; son cümle «Bizim» |
| `act0.myth.9` | 1:30,3; 4,6 sn | The Sky took his name and drove him from the light. He has another now. | Gök adını aldı, onu ışıktan sürdü. Artık başka bir adı var. | Kaz ışığa çağrılır, «name»de yüzsüz biçime döner, sürülür, bataklığa iner | Radloff s. 4 «Ozan der» |
| `act0.myth.10` | 1:36,4; 3,8 sn | We do not say it by the fire. I will say it once. | Ateş başında o adı söylemeyiz. Bir kez söyleyeceğim. | Kamera yüzü olmayan başa gider | Anohin I.A, `mitoloji.md` öneri 3 «Ozan der»; söyleyiş «Bizim» |
| `act0.myth.11` | 1:41,9; 0,8 sn | Erlik. | Erlik. | Başın yakın planı; söz neredeyse sessizlikte, rüzgâr kesilir | Radloff s. 4 «Ozan der» |
| `act0.myth.12` | 1:46,1; 6,6 sn | Then the Sky made others, nine, under a tree, and they needed a name, and one was lying empty. | Sonra Gök başkalarını yarattı: bir ağacın altında dokuz insan. Onlara bir ad gerekti, boşta bir ad vardı. | Kesme: ağaç büyür, dalların altında dokuz kişi tek tek belirir | Radloff s. 4 «Ozan der»; adın geçişi «Bizim» |
| `act0.myth.13` | 1:54,2; 5,1 sn | Kishi. You are kishi. I am kishi. | Kişi. Sen de kişisin, ben de. | Kişilere yaklaşılır | Kül Tigin doğu 1, `kişi oğlı` «Taştan»; seslenme «Bizim» |
| `act0.myth.14` | 2:01,5; 5,2 sn | Sky above, earth below, and between them, the children of Kishi. | Üstte gök, altta yer; ikisinin arasında kişi oğlu. | Sözsüz gök çadırı, kazık, Kök Boz At ve Ak Boz At, Yedi Karakçı; altta yer, arada dokuz kişi | Kül Tigin doğu 1 «Taştan» |
| `act0.myth.15` | 2:09,5; 3,2 sn | Nobody counted them. Nobody needed to. | Onları kimse saymazdı. Gerek yoktu. | Aynı kare, gök döner | «Bizim» |
| `act0.myth.16` | 2:14,8; 7,2 sn | He wanted them. They wore his name. The Sky said no. So he took one. | Onları istedi. Onun adını taşıyorlardı. Gök vermedi. O da birini aldı. | Yer kesiti: üstte ağaç ve dokuz kişi, otun altında yüzsüz biçim elini kaldırır; «no»da ışık iner; «took»ta en sağdaki kişi toprağa çekilir, gece | Radloff s. 4, Anohin I.A, Holmberg s. 316 «Ozan der»; «adını taşıyorlardı» «Bizim» |
| `act0.myth.17` | 2:24,2; 2,0 sn | In the morning, somebody counted. | Sabah biri saydı. | Kesme: sabah, ağaç, sekiz kişi, boş bir yer, çetele çubuğu; ardından sekiz çentik | «Bizim»; sayım SJ 110 «Yıllıktan» |
| `act0.myth.18` | 2:28,3; 0,6 sn | Eight. | Sekiz. | Çentikler biter; söz; kamera boş yere gider | «Bizim» |
| `act0.myth.19` | 2:31,9; 6,6 sn | Below the grass his river runs with our tears. Its name is: I am not full. | Irmağı otun altından akar, gözyaşımızla akar. Adı Doymadım. | Irmak, at kılından köprü; alınan kişi köprüden geçer, biçim köprünün başında; «I am not full»da köprüye yakın plan, akış hızlanır | Anohin I.A «Ozan der»; «otun altında» «Bizim» |
| `act0.myth.20` | 2:40,2; 2,1 sn | The Sky left them to themselves. | Gök onları kendi başlarına bıraktı. | Mürekkep deriye çekilir; boş deri kararır, çakmak taşları belirir | Radloff s. 4–5 «Ozan der» |
| `act0.myth.21` | 2:45,4; 6,4 sn | White stone struck black stone, and a spark fell, and the eight of them set three stones around it. | Ak taş kara taşa vurdu, bir kıvılcım düştü; sekizi çevresine üç taş dizdi. | `fire_catch` karesi; iki çarpma, kıvılcım, üç ocak taşı, alev | Holmberg s. 449–450, Anohin «Ozan der»; taşları dizenin sekizi olması ozanın söyleyişi |
| `act0.myth.22` | 2:54,4; 3,3 sn | He came as far as the stones, and there he stopped. | Taşlara kadar geldi, orada durdu. | Gece, ocak, sağda sekiz kişi; yüzsüz biçim soldan gelir, taşta durur | Holmberg s. 468, Polat 2020; motif Al Karısı'ndan aktarıldı, «Ozan der» ve «Bizim» |
| `act0.myth.23` | 2:59,3; 5,2 sn | He did not go away. He sat down outside the light, and began to count us. | Gitmedi. Işığın dışına oturdu, bizi saymaya başladı. | Işığın dışına çekilip oturur; yerde sekiz çizik | «Bizim» (K32, `act1.md` oturan Erlik, `story.md` §12) |
| `act0.myth.24` | 3:06,8; 5,5 sn | So we count too. At every birth, a woman calls the count from the door. | Biz de sayarız. Her doğumda bir kadın kapıya çıkıp sayıyı söyler. | Kesme: doğum yurdu; gölge eşikten girer, ocak taşında durur | SJ 110 «Yıllıktan»; kapıdan seslenme K36 «Bizim» |
| `act0.myth.25` | 3:14,1; 4,1 sn | The river hears. It has not changed its name. | Irmak duyar. Adını değiştirmedi. | Gölge gitmez; köze yaklaşılır; son 1,5 sn köz | «Bizim» |
| `act0.birth.12` | 3:33,4; 8,4 sn | At dawn the Tanhu stepped out of his tent and bowed to the rising sun; in the west the full moon had not yet set. | Şafakta Tanhu çadırından çıktı, doğan güne eğildi; batıda dolunay daha batmamıştı. | 3B doğum sahnesi: Teoman doğan güne eğilir, batıda dolunay | SJ 110 單于朝出營，拜日之始生，夕拜月; «Yıllıktan» |
| `act0.birth.hereka` (`speaker: hereka`, ses Heather Faith) | 3:51,0; 0,64 sn | One more. | Bir eklendi. | İlk ağlamadan sonra Hereka kapıdan sayım hattına seslenir; sayıcı çentik atar | Dailin: SJ 110 秋，馬肥，大會蹛林 «Yıllıktan»; söz oyunun, «Bizim» |

**Kaynak notu (K96).** Ham metin okundu: Radloff, `Aus Sibirien` II, s. 3–5; Holmberg 1927, s. 316–318, 449–450, 468. Radloff Kişi'yi açıkça «Mensch (Kishi)» diye yazar, Erlik adını alan da bu «Mensch»tir; sonra Kaira Kan'ın «andere Menschen» yarattığını söyler: «kişi insan demektir» okuması kaynağın kendisindedir. Holmberg s. 316 ilk insanın ilk ölen ve ölülerin başı olduğunu yazar; s. 317–318 iki avucu ve dünyayla büyüyen toprağı anlatır, s. 317 açıkça «stone» der: `mitoloji.md` §5.1'in «taş» sorusu ikinci tanıkla kapanır. Radloff'un OCR'ı «Stern» okumayı sürdürür, basılı sayfası görülmedi; bu taş metinde söylenmez, görüntüdedir. Radloff s. 4–5'in «sich selbst zu überlassen» sözünün son sözcüğü OCR'da bozuktur, bağlamdan okundu.

**«Bizim» işaretleri.** 6 satır tümüyle (3, 15, 17, 18, 23, 25), 8 satır kısmen (8, 10, 12, 13, 16, 19, 22, 24) «Bizim»dir. Yeni varlık yoktur; «ilk sayım» ve «oturup sayma» ozanın yorumudur; adın insanlara geçişi de öyledir, kaynakta dayanağı var ama devir sözü yok. 22'de ocak taşı motifi Al Karısı'ndan adsız Erlik'e aktarıldı (kullanıcı onayı, K96): 3B doğumdaki gölge bu sözle okunur, belgede Al Karısı kalır.

**Söylenmeyen adlar.** Kayra Han, Tengri («the Sky», «Gök» denir), Toybodım (adının anlamı söylenir: «I am not full», «Doymadım»), Al Karısı, Umay, Yer-Sub, Demirkazık. Gök çadırı, kazık ve iki at görüntüdedir. Hepsi Destan Kitabı'nda kalır.

**Okuma (K96).** David, `eleven_v3`, kararlılık 0,5. Satırlar tek çağrıda okundu (`tools/elevenlabs_audio.sh --block`), sessizliklerin ortasından kesildi, −18 LUFS'a getirildi: ton satır aralarında kopmaz, tek sözcüklük «Erlik.» ve «Eight.» cümlenin sürdürdüğü bağlamda söylenir. Bloğun ham sesi `docs/media/review/audio/blocks/`'tadır. 3 ve 25 aynı yolla, bağlamlarıyla yeniden okundu: yerel yazıya çevirme 3'ün ilk okumasında «counts» yerine «comes» duydu; bloğun sonu 25'in son sözcüğünü −36 dB'te kesmişti.

Doğumda konuşan tek kişi Hereka'dır; Umay görünmez ve konuşmaz; kurt, görü, ayna, ip, aynı gece doğan tay, ninni, kehanet ve doğumda ad koyma yoktur (K36). Anlatılmayanlar: Ak Ana, tufan, Kızagan, Gün Ana, Ay Ata, Bay Terek, Yel Ana; kurt VI'nın Kunmo'suna saklıdır (K35).

### Köprüler (`act0.narr.1`–`act0.narr.7`)

Eldrin'in yedi satırı uyarlandı ve yerinde kalır; mit satırları bunlara eklenir, yerlerini almaz (K36). N1–N5 Çocukluk'tan sonra (Köprü 1, ≈50 sn), N6–N7 Yola Çıkış'tan sonra (Köprü 2, ≈18 sn) parşömen videosunda okunur (`assets/cine/video/bridge_1.ogv`, `bridge_2.ogv`; `motion-studio`, mit videosunun çizgisiyle; yoksa kara ekran ve altyazı); satırlar arası 0,9–1,0 sn, dron ve seyrek tel altında (`data/cine/bridge_1.json`, `bridge_2.json`). Köprü 1'in çekimleri: tilki ve tavşan (222, 11 yaş), gerilen yay (218, 15), Dailin'de evlilik (216), Ç'in'in suru ve Ordos'tan çekiliş (215), doğuda Tunghu, batıda Yüeçi ve arada sayan Teoman, diz çökmeyen veliaht, kuzeye göç ile Huyan Hatun ve beşikteki Gutu (214), Dailin'de Teoman ve mühür, Lung-çeng'de Jiyu'nun beşiği (213). Köprü 2'nin çekimleri: kar yolu, Kemik Boğazı'nda kapı, bileğe bağlanan çan, sayıcı ve sığırların arasında rehine, yürüyen ayak ve çan; sonra kararma (`story.md` §6). Köprüler adı konmuş atlamadır: takvim 22 Eylül 228'den Yola Çıkış'a, oradan 2 Aralık 210'a ileri gider (K67). Yazım K34'tür: Türkçede Tunghu, İngilizcede Donghu; anlatıcının İngilizcesinde «Hun».

N2, N3 ve N6 yeniden yazıldı ve 2026-11-05'te yeni metinle okundu (359 karakter, 158 kredi; `tools/vo_ledger.jsonl`). N1, N4, N5, N7 değişmez, kayıtları kalır (K36; K61: değişmeyen satıra kredi harcanmaz). Mete'nin adı ilk kez N2'de duyulur.

| id | Köprü | EN | TR | Kayıt |
|---|---|---|---|---|
| `act0.narr.1` | 1 | Before there were empires of grass, there was only the wind, and those who could outlast it. | Otun imparatorlukları yokken yalnız rüzgâr vardı, bir de ona dayanabilenler. | Var, değişmez |
| `act0.narr.2` | 1 | When Mete was eighteen, the Qin raised a wall against the sky and drove the Huns out of the Ordos. | Mete on sekizindeyken Ç'in göğe karşı bir sur yükseltti, Hunları Ordos'tan sürdü. | Yeni çekim (2026-11-05) |
| `act0.narr.3` | 1 | To the east, the Donghu grew strong. To the west, the Yuezhi flourished. And between them, Teoman the Tanhu counted his horses and his years. | Doğuda Tunghu güçleniyor, batıda Yüeçi serpiliyordu. Arada Tanhu Teoman atlarını ve yıllarını sayıyordu. | Yeni çekim (2026-11-05): yazım (#9), 盛 çevirisi (`mete-tarih.md` §1.3) |
| `act0.narr.4` | 1 | He had an heir called Mete, quick with a bow and slow to kneel. And he had a young wife, with a younger son. | Mete adında bir veliahdı vardı; yayda çevik, diz çökmekte ağırdı. Bir de genç bir hatunu, ondan küçük bir oğlu. | Var, değişmez |
| `act0.narr.5` | 1 | So the Tanhu made peace with the Yuezhi, and sealed it the old way: with a son. | Tanhu, Yüeçilerle barış yaptı ve onu eski usulle mühürledi: bir oğulla. | Var, değişmez |
| `act0.narr.6` | 2 | Mete rode west with no army and no bow. At the gate they tied a bell to his ankle and counted him like a head of cattle. | Mete batıya ordusuz ve yaysız gitti. Kapıda ayağına bir çan bağladılar, onu bir baş hayvan gibi saydılar. | Yeni çekim (2026-11-05) |
| `act0.narr.7` | 2 | History remembers the Tanhu he became. This is the hostage he was. | Tarih, sonradan olduğu Tanhu'yu yazar. Bu, önce olduğu rehinenin hikâyesi. | Var, değişmez |

Köprülerin İngilizcesi 704 karakterdir (Köprü 1: 518, Köprü 2: 186); eski yedi satır ≈680 karakterdi.

## Sahnelerin sözleri (K105)

Kullanıcının isteğiyle (E20/7, «konusmalar felan yoksa ekle varsa seslerini ekle») Çocukluk, Yola Çıkış ve Serbest Gez'in kampındaki sözler seslidir: K61'in «iş ve ara sözler altyazı» kuralı ve Çocukluk'un «çocukken altyazı» notu bu üç sahne için kalktı ([K105](decisions.md)). Söylenen dil İngilizce, altyazı Türkçedir. Satırlar `game/data/vo_lines.json`'dadır (`act0.child.*`, `act0.depart.*`, `act0.camp.*`; `scene`, `node`, `gain_db`); sahneler sesi `scripts/story/scene_voice.gd` ve `camp_voice.gd` ile çalar: altyazı sesin süresi kadar durur, söz sırası sesin bitişini bekler, sözler üst üste binmez, sıraya girer. Tepki sözleri (ıska, vuruş, kalkan kuş, otlayan yaşlı koyun) üçer çeşittir; aynı çocuk aynı olayda ≥45 sn arayla konuşur, biri konuşuyorsa söz düşer. Ses düzeyi satır başına oyun içi kazançla eşitlenir (hedef −18 LUFS, K78). Çocukluk'ta hiçbir sözde «Mete» adı geçmez (ad ilk kez N2'de duyulur); büyük Mete'nin oyunda duyulan ilk sözü «Sayarım.»dır.

68 söz, İngilizcesi 1.764 karakter; 2026-11-08'de okundu, defterde 68 çağrı ve 777 kredi (`tools/vo_ledger.jsonl`). Eskam'ın atlı sözünün ilk metni («Arabanın yanından ayrılma, evladım.») yeni sürüşle çelişiyordu; kullanıcının onayıyla «Sen sür evladım, araba ardından yetişir.» okundu (18 kredi). Dinleme notları Karar Bekleyenler'dedir.

| Kim | Ses (ElevenLabs kütüphanesi) | Söz |
|---|---|---|
| Lan Hatun (`lan_hatun`) | Poppy - Calm & Kind Teacher/Mother | 4 |
| Luhun (`luhun_child`) | Austin - Timid and Casual | 25 |
| Yançi (`yanchi_child`) | Emmaline - young British girl | 19 |
| Mete (`mete_child`) | Ryan Quin | 6 |
| Sayıcı (`counter`) | Alden - Tired Old Man | 3 |
| Yançi (`yanchi`) | Emilia Bennett - Young British Narrator | 2 |
| Huyan Hatun (`huyan_hatun`) | Jessica - Playful, Bright, Warm | 2 |
| Eskam (`eskam`) | Roland Lescalde - Epic Narrator | 3 |
| Mete (`mete`) | King Chuku the Great (eski adı Arthur, Deep and Powerful King) | 1 |
| Ana (`mother`) | Kathleen Julie (eski adı Sharon - Motherly, Soothing, and Warm) | 1 |
| Ozan (`bard`) | David, Deep and Engaging Storyteller | 1 |
| Baba (`father`) | Michael Sweets (eski adı Michael - Deep, Warm and Gentle) | 1 |

### Çocukluk «Koyun Sırtında» (`mq0_sheep`)

| id | Kim | EN | TR | sn |
|---|---|---|---|---|
| `act0.child.wake` | Lan Hatun | Up. It's the count today, and you're letting the sheep out. | Kalk, bugün sayım var. Koyunları ağıldan sen çıkaracaksın. | 3,8 |
| `act0.child.wake_count` | Lan Hatun | Forty head. Get every one of them out. | Kırk baş. Hepsini çıkar. | 2,7 |
| `act0.child.gate_call` | Luhun | Hurry! You have to open the gate. | Çabuk! Kapıyı sen açacaksın. | 2,6 |
| `act0.child.herd_tip` | Luhun | Walk behind them. They run from you. | Arkalarından yürü, senden kaçarlar. | 3,2 |
| `act0.child.herd_last` | Luhun | There's still one inside. | İçeride bir tane kaldı. | 1,6 |
| `act0.child.race_dare` | Luhun | Race you to the stone? | Taşa kadar yarışalım mı? | 1,3 |
| `act0.child.race` | Luhun | The old one's yours. The fast one's mine. | Yaşlısı senin, hızlısı benim. | 3,0 |
| `act0.child.race_first` | Luhun | I'm first! | Birinci benim! | 0,9 |
| `act0.child.race_late` | Luhun | The old one made it anyway. | Yaşlısı yine de geldi. | 1,6 |
| `act0.child.race_won` | Luhun | How did the old one run like that? | Yaşlısı nasıl koştu öyle? | 1,8 |
| `act0.child.dismount_call` | Yançi | Get down and come! The larks are over here! | İnin de gelin! Tarla kuşları burada! | 2,4 |
| `act0.child.hunt_dare` | Yançi | Let's see who hits the first bird. | Bakalım ilk kuşu kim vuracak. | 1,9 |
| `act0.child.yanchi_bird` | Yançi | That one's mine. Don't forget it at the count. | O benim. Sayarken unutma. | 3,0 |
| `act0.child.luhun_mouse` | Luhun | She has young. | Yavrusu var. | 1,0 |
| `act0.child.mouse_shot` | Luhun | But she had young. | Ama yavrusu vardı. | 1,9 |
| `act0.child.point` | Yançi | There! In the short grass. | Şurada! Kısa otun içinde. | 2,0 |
| `act0.child.pick_1` | Mete | One. | Bir. | 0,5 |
| `act0.child.pick_2` | Mete | Two. | İki. | 1,0 |
| `act0.child.pick_mouse` | Mete | One mouse. | Bir fare. | 1,0 |
| `act0.child.bark.graze.luhun_child.1` | Luhun | She's eating again! | Yine otluyor! | 1,4 |
| `act0.child.bark.graze.luhun_child.2` | Luhun | The old one's hungry. | Yaşlısı acıktı. | 1,4 |
| `act0.child.bark.graze.luhun_child.3` | Luhun | Prod her, go on! | Dürt onu, dürt! | 1,8 |
| `act0.child.bark.graze.yanchi_child.1` | Yançi | She can eat later! | Otu sonra yesin! | 1,1 |
| `act0.child.bark.graze.yanchi_child.2` | Yançi | Did your sheep fall asleep? | Koyunun uyudu mu? | 1,5 |
| `act0.child.bark.graze.yanchi_child.3` | Yançi | At this rate you'll get there by nightfall! | Böyle akşama varırsın! | 2,4 |
| `act0.child.bark.miss.yanchi_child.1` | Yançi | Too high! | Çok yüksek! | 1,0 |
| `act0.child.bark.miss.yanchi_child.2` | Yançi | The bird's laughing at you. | Kuş sana gülüyor. | 1,5 |
| `act0.child.bark.miss.yanchi_child.3` | Yançi | Again! | Bir daha! | 1,4 |
| `act0.child.bark.miss.luhun_child.1` | Luhun | Slowly. Breathe. | Yavaş. Nefes al. | 3,8 |
| `act0.child.bark.miss.luhun_child.2` | Luhun | A little lower. | Biraz aşağıdan. | 1,2 |
| `act0.child.bark.miss.luhun_child.3` | Luhun | Get closer, then let go. | Biraz yaklaş, öyle bırak. | 2,7 |
| `act0.child.bark.hit.luhun_child.1` | Luhun | It's down! | Düştü! | 1,0 |
| `act0.child.bark.hit.luhun_child.2` | Luhun | Good shot. | İyi attın. | 0,9 |
| `act0.child.bark.hit.luhun_child.3` | Luhun | Go and pick it up. | Git al onu. | 1,1 |
| `act0.child.bark.hit.yanchi_child.1` | Yançi | Not bad. | Fena değil. | 1,2 |
| `act0.child.bark.hit.yanchi_child.2` | Yançi | Mine fell first, though. | Benimki önce düştü ama. | 1,4 |
| `act0.child.bark.hit.yanchi_child.3` | Yançi | Now the second one! | Şimdi ikincisi! | 1,0 |
| `act0.child.bark.flush.luhun_child.1` | Luhun | Slowly. It can hear your feet. | Yavaş, ayak sesini duyuyor. | 3,1 |
| `act0.child.bark.flush.luhun_child.2` | Luhun | Keep low, keep low. | Eğil, eğil. | 1,4 |
| `act0.child.bark.flush.luhun_child.3` | Luhun | Quiet, quiet. | Sessiz ol, sessiz. | 1,2 |
| `act0.child.bark.flush.yanchi_child.1` | Yançi | It's off! It landed in the other grass. | Kaçtı! Öbür ota kondu. | 2,9 |
| `act0.child.bark.flush.yanchi_child.2` | Yançi | You scared it! | Ürküttün onu! | 1,1 |
| `act0.child.bark.flush.yanchi_child.3` | Yançi | I'd go slower, if I were you. | Ben olsam yavaş giderdim. | 1,8 |
| `act0.child.count_call` | Yançi | The count! Last one there gets counted with the sheep! | Sayım! Son gelen koyunlarla sayılır! | 3,4 |
| `act0.child.wait_me` | Luhun | Wait for me! | Bekleyin beni! | 0,9 |
| `act0.child.sheep_first` | Sayıcı | Sheep first. Children after. | Önce koyunlar. Çocuklar sonra. | 4,0 |
| `act0.child.stand_still` | Yançi | Stand still. If you wiggle, he counts you twice. | Kıpırdama. Kıpırdarsan iki kez sayar. | 3,7 |
| `act0.child.mouse_spared` | Luhun | You let the mouse go. | Fareyi bıraktın. | 1,2 |
| `act0.child.look_down` | Luhun | When the Tanhu rides by, look at the ground. Everyone does. | Tanhu geçerken yere bak. Herkes bakar. | 4,6 |
| `act0.child.my_bird` | Yançi | Count my bird too! | Kuşumu da say! | 1,4 |
| `act0.child.count_child` | Sayıcı | One child. | Bir çocuk. | 1,7 |
| `act0.child.mete_catch` | Mete | Two birds, one mouse. | İki kuş, bir fare. | 2,2 |
| `act0.child.mete_catch_spared` | Mete | Two birds. | İki kuş. | 1,0 |
| `act0.child.count_answer` | Sayıcı | I'll count those too. What is eaten is counted. | Onları da sayarım. Yenen de sayılır. | 5,0 |
| `act0.child.saw_me` | Mete | He saw me. | Beni gördü. | 1,1 |

### Yola Çıkış (`mq0_depart`)

| id | Kim | EN | TR | sn |
|---|---|---|---|---|
| `act0.depart.yanchi_hush` | Yançi | Shh. He just fell asleep. | Şşş. Yeni uyudu. | 2,6 |
| `act0.depart.yanchi_bow` | Yançi | The bow stays here; I'll keep it strung. Go on, go and be counted. | Yay burada kalır, ben gererim. Sen git, sayılmaya. | 5,2 |
| `act0.depart.huyan_road` | Huyan Hatun | May your road be clear, Mete. | Yolun açık olsun, Mete. | 1,7 |
| `act0.depart.huyan_wave` | Huyan Hatun | Wave to your brother, Gutu. | Gutu, ağabeyine el salla. | 1,5 |
| `act0.depart.eskam_road` | Eskam | My boy, the road is long. I will come every winter. | Evladım, yol uzun. Ben her kış gelirim. | 3,8 |
| `act0.depart.eskam_come` | Eskam | Come, my boy. The road is waiting for us. | Gel evladım, yol bizi bekler. | 2,6 |
| `act0.depart.lan_days` | Lan Hatun | Forty-two days of road. | Kırk iki gün yol. | 2,2 |
| `act0.depart.mete_count` | Mete | I'll count them. | Sayarım. | 0,9 |
| `act0.depart.lan_home` | Lan Hatun | Count the road home too. | Dönüş yolunu da say. | 1,8 |
| `act0.depart.eskam_ride` | Eskam | Ride on, my boy. The cart will catch up. | Sen sür evladım, araba ardından yetişir. | 2,3 |

### Serbest Gez, Göl Obası

| id | Kim | EN | TR | sn |
|---|---|---|---|---|
| `act0.camp.rise` | Ana | Don't go far, my girl. | Uzağa gitme, kızım. | 1,4 |
| `act0.camp.bard` | Ozan | Sit. Let the kopuz speak first. | Otur. Önce kopuz söylesin. | 2,8 |
| `act0.camp.stable` | Baba | Don't walk behind Doru. He kicks. | Doru'nun arkasından geçme. Teper. | 2,6 |

### Önsöz: Göl Obası'nda üç gün (E21, K110)

Önsöz'ün sinemadan önceki oynanan üç günü (`story.md` §3, «Göl Obası'nda üç gün»). Çocuk sözsüzdür. Kullanıcının yönüyle («istekler anlamli seyler olsun, atmosfere ozellikle dikkat et») her istem nedenini söyler, yolda konuşulur, kişiler oyuncunun yaptığına karşılık verir. 90 söz, İngilizcesi 4.166 karakter. ElevenLabs'ın onayı E21'dedir («elevenlabs kullanabilirsin»); okuma sahneler bitip metin kilitlenince yapılır. Yeni sesler kütüphaneden seçilir: Saruk Ebe yaşlı, kısık ve şakacı bir kadın; Börü sekiz yaşında, hızlı konuşan bir oğlan; Künay genç, yorgun ve sıcak bir kadın; Tonga genç, kısa sözlü bir adam; Ağabey genç ve hızlı (`story.md` §8.3); obanın halkı iki ses. Ana, Baba ve Ozan bugünkü sesleriyledir. Metnin makinece okunan kopyası `d3/e21-lines.json`'dur; tabloda sözler görev görev, sahnedeki sırasıyla değil kimliğiyle dizilidir.

| id | Kim | EN | TR |
|---|---|---|---|
| `act0.milk.wake` | Ana | Up, my girl. Saruk Ebe's churn has gone hungry. | Kalk kızım. Saruk Ebe'nin sabası aç kaldı. |
| `act0.milk.task` | Ana | Two skins of mare's milk. You're taking them to Birch Camp. Go slowly over the stream. | İki tulum kısrak sütü. Kayın Obası'na sen götüreceksin. Dereyi yavaş geç. |
| `act0.milk.arrive` | Saruk Ebe | Ah, my milk is here. Pour it into the churn, then. | Hah, sütüm geldi. Dök bakalım sabaya. |
| `act0.milk.full` | Saruk Ebe | Not a single drop spilled. | Tek damla dökmemişsin. |
| `act0.milk.spilt` | Saruk Ebe | Half of it stayed on the road. Never mind. It'll still be kumis. | Yarısı yolda kalmış. Olsun, yine kımız olur. |
| `act0.milk.churn` | Saruk Ebe | Kumis is churned a thousand times. You churn twenty. I'll count the rest. | Kımız bin kez çalkalanır. Sen yirmisini çalkala, gerisini ben sayarım. |
| `act0.milk.churn_done` | Saruk Ebe | Twenty. You've a strong arm. | Yirmi. Kolun sağlam. |
| `act0.milk.boru` | Börü | Girls don't make wrestlers. | Kızdan pehlivan olmaz. |
| `act0.milk.saruk_reply` | Saruk Ebe | When the baby comes, there'll be a feast. We'll see then. | Bebek gelince toy olur. Orada görürüz. |
| `act0.milk.home` | Ana | Your hands smell of milk. Good. | Ellerin süt kokuyor. Güzel. |
| `act0.milk.why` | Ana | Kunay's time is near. Kumis gives her strength, and Saruk is waiting. | Künay'ın vakti yakın. Kımız ona güç verir; Saruk bekliyor. |
| `act0.milk.ana_call` | Ana | Give Saruk my greetings. And take my love to Kunay. | Saruk'a selam söyle. Künay'a da sevgimi götür. |
| `act0.milk.road_man` | Kayın Obalı | That yoke's bigger than you, girl. Go slowly. | Sırık senden büyük, kızım. Yavaş git. |
| `act0.milk.greet` | Kayın Obalı | The girl from Lake Camp is here! Saruk, your milk is here! | Göl Obası'nın kızı geldi! Saruk, sütün geldi! |
| `act0.milk.kunay_door` | Künay | Come, catch your breath. That yoke is heavy. | Gel, soluklan. O sırık ağırdır. |
| `act0.milk.kunay_kick` | Künay | He kicked all morning. Soon, Saruk says. | Bu sabah çok tekmeledi. Yakında, diyor Saruk. |
| `act0.milk.saruk_kunay` | Saruk Ebe | This will be ready in time for the watch-night. It'll bring Kunay's strength back. | Bu kımız şildeye yetişir. Künay'ın gücü bununla döner. |
| `act0.storm.baba` | Baba | A blizzard's coming. Your brother and I are going to the horses. | Tipi geliyor. Ağabeyinle atlara gidiyoruz. |
| `act0.storm.boru` | Börü | Our fire's gone out! My sister's having the baby, and Grandma needs embers! | Ocağımız söndü! Ablam doğuruyor, ebem köz istiyor! |
| `act0.storm.ana` | Ana | Take the ember pot. Count the stakes. At the twelfth, you go down to the stream. | Köz kabını al. Kazıkları say: on ikincide dereye inersin. |
| `act0.storm.ana_hand` | Ana | Keep Boru by your side. | Börü'yü yanından ayırma. |
| `act0.storm.lost` | Börü | I can't see the stake! | Kazığı göremiyorum! |
| `act0.storm.wolf` | Börü | Is that a wolf? It won't come near the fire, will it? | Kurt mu o? Ateşin yanına gelmez, değil mi? |
| `act0.storm.arrive` | Saruk Ebe | Embers! Bring them here, quick. | Köz! Getir buraya, çabuk. |
| `act0.storm.lit` | Saruk Ebe | The light's back. Now out, both of you. Wait by the door. | Işık döndü. Şimdi çıkın, kapıda bekleyin. |
| `act0.storm.count` | Saruk Ebe | One more. | Bir eklendi. |
| `act0.storm.boru_ask` | Börü | Is it a boy or a girl? | Oğlan mı, kız mı? |
| `act0.storm.saruk_answer` | Saruk Ebe | A life. The rest can wait till morning. | Can. Gerisi sabaha. |
| `act0.storm.tonga` | Tonga | Who brought the fire? | Ateşi kim getirdi? |
| `act0.storm.saruk_tonga` | Saruk Ebe | The girl from Lake Camp. | Göl Obası'nın kızı. |
| `act0.storm.dusk` | Ana | The wind's turned. There'll be a blizzard tonight. | Rüzgâr döndü. Bu gece tipi var. |
| `act0.storm.bard_door` | Ozan | Tie the door tight. A blizzard knows where the door is. | Kapıyı sıkı bağla. Tipi kapının yerini bilir. |
| `act0.storm.boru_stakes` | Börü | Grandma says in a blizzard only the stakes know the road. | Ebem der ki tipide yolu yalnız kazıklar bilir. |
| `act0.storm.boru_six` | Börü | Six. We're halfway. | Altı. Yarısı geçti. |
| `act0.storm.boru_scared` | Börü | My sister was crying out. I'm scared. | Ablam bağırıyordu. Korkuyorum. |
| `act0.storm.boru_silent` | Börü | You never talk, do you? That's all right. | Sen hiç konuşmuyorsun, değil mi? Olsun. |
| `act0.storm.boru_twelve` | Börü | Twelve! The stream's right there! | On iki! Dere şurada! |
| `act0.storm.door_1` | Börü | Grandma says if the light goes out on a birth night, someone waits at the door. | Ebem der ki doğum gecesi ışık sönerse kapıda biri bekler. |
| `act0.storm.door_2` | Börü | But the light's on now. You lit it. | Ama ışık yandı. Sen yaktın. |
| `act0.lambs.ana` | Ana | The ewes lambed out in the open last night. Find the lambs and bring them inside. Follow their voices. | Koyunlar gece açıkta doğurdu. Kuzuları bul, yurda getir. Sesinden bulursun. |
| `act0.lambs.one` | Ana | One. | Bir. |
| `act0.lambs.two` | Ana | Two. | İki. |
| `act0.lambs.three` | Ana | Three. | Üç. |
| `act0.lambs.four` | Ana | Four. All of them alive. | Dört. Hepsi sağ. |
| `act0.lambs.weak` | Ana | This one's frozen through. Set it by the fire and drip the first milk into its mouth. | Bu donmuş. Ocağın yanına koy, ağzına ilk sütü damlat. |
| `act0.lambs.bard` | Ozan | What's born on a blizzard night lives well. May Kunay's son do the same. | Tipi gecesi doğan iyi yaşar. Künay'ın oğlu da öyle olsun. |
| `act0.lambs.morning` | Ana | Up. It snowed. The blizzard's gone, and the lambs have come. | Kalk, kar yağmış. Tipi gitti, kuzular geldi. |
| `act0.lambs.brother` | Ağabey | The horses are all here. And the grey mare's foaled. | Atlar tamam. Kır kısrak da taylamış. |
| `act0.lambs.carry` | Ana | Pick it up. Its mother will follow. | Kucağına al, anası ardından gelir. |
| `act0.lambs.last` | Ana | There's one more bleating, down by the stream. | Biri daha meliyor. Dere tarafında. |
| `act0.lambs.kopuz` | Ozan | The kopuz strings are cold too. They'll be warm by evening. | Kopuzun teli de üşüdü. Akşama ısınır. |
| `act0.feast.ana` | Ana | There's a watch-night at Birch Camp. In a newborn's first nights the fire never dies, and the laughing never stops. | Kayın Obası'nda şilde var. Yeni doğanın ilk gecelerinde ocak sönmez, gülüşme eksik olmaz. |
| `act0.feast.baba` | Baba | Let's go. The one who sits outside the light can't stand noise. | Gidelim. Işığın dışında oturan gürültüyü sevmez. |
| `act0.feast.saruk` | Saruk Ebe | Come here, girl. This kumis is from the milk you brought. Take it with both hands. | Gel kız. Bu kımız senin getirdiğin sütten. İki elinle al. |
| `act0.feast.sour` | Saruk Ebe | Sour? The first kumis always is. | Ekşi mi? İlk kımız ekşi olur. |
| `act0.feast.kunay` | Künay | You brought the fire. Let my son know you. | Ateşi sen getirdin. Oğlum seni bilsin. |
| `act0.feast.tonga_bow` | Tonga | The little bow stays on the cradle. When he's grown, he'll string it himself. | Küçük yay beşikte durur. Büyüyünce kendisi gerer. |
| `act0.feast.bark_1` | Kayın Obalı | Laugh! A watch-night is never quiet. | Gülün! Şilde gecesi sessiz olmaz. |
| `act0.feast.bark_2` | Kayın Obalı | Another branch on the fire! | Ocağa bir dal daha! |
| `act0.feast.gift` | Ana | Here. You give this felt swaddle to Kunay. | Al, bu keçe kundağı Künay'a sen ver. |
| `act0.feast.walk` | Ana | Nobody goes to a watch-night empty-handed. | Şildeye giden eli boş gitmez. |
| `act0.feast.libation` | Saruk Ebe | First to the Sky, then to the Earth, then to the hearth. | Önce Gök'e, sonra Yer'e, sonra ocağa. |
| `act0.feast.kunay_gift` | Künay | From your mother's hands? It's still warm. | Ananın elinden mi? Daha ılık. |
| `act0.feast.old_man` | Kayın Obalı | Nobody sleeps tonight. Whoever sleeps misses the watch-night. | Bu gece kimse uyumaz. Uyuyan şildeyi kaçırır. |
| `act0.feast.song` | Kayın Obalı | Come on, another song! The baby's listening. | Hadi, bir türkü daha! Bebek dinliyor. |
| `act0.feast.baba_tonga` | Baba | Tonga, long life to your son. | Tonga, oğlun uzun yaşasın. |
| `act0.feast.tonga_thanks` | Tonga | You were the one who brought the fire. There's a place for you at this hearth. | Ateşi getiren sendin. Bu ocakta yerin var. |
| `act0.wrestle.dare` | Börü | I said girls don't make wrestlers. Come and show me. | Kızdan pehlivan olmaz dedim. Gel de göster. |
| `act0.wrestle.rules` | Tonga | Nobody lets go of the belt. Whoever's back touches the ground loses. | Kuşak bırakılmaz. Sırtı yere değen yenilir. |
| `act0.wrestle.start` | Tonga | Grip! | Tutun! |
| `act0.wrestle.again` | Börü | Again! | Bir daha! |
| `act0.wrestle.win` | Börü | Grandma was right. | Ebem haklıymış. |
| `act0.wrestle.saruk` | Saruk Ebe | Who falls gets up. Who gets up, laughs. | Düşen kalkar, kalkan güler. |
| `act0.wrestle.home` | Ana | Tomorrow you build the fire. The bard means to sing a long one. | Yarın ocağı sen kur. Ozan uzun söyleyecek. |
| `act0.wrestle.ring` | Kayın Obalı | Make a ring! The girl from Lake Camp against Boru! | Halka açılsın! Göl Obası'nın kızı Börü'ye karşı! |
| `act0.wrestle.tip` | Tonga | Keep your weight in your feet. When he pushes, give way. | Ağırlığını ayağına ver. İttiğinde çekil. |
| `act0.wrestle.eagle` | Tonga | The winner spreads her arms like an eagle. Go on. | Kazanan kartal gibi açar kollarını. Hadi. |
| `act0.wrestle.boru_after` | Börü | Let's wrestle again tomorrow. | Yarın yine güreşelim. |
| `act0.hearth.bard` | Ozan | Tonight I'll sing something long. You build the fire. The blizzard cracked the hearthstones. | Bu gece uzun bir şey söyleyeceğim. Ateşi sen kur; tipi ocak taşlarını çatlattı. |
| `act0.hearth.wood` | Baba | There's dry wood at the edge of the forest. Green wood only smokes. | Kuru dal orman kıyısında. Yaş odun yalnız duman eder. |
| `act0.hearth.stone` | Ağabey | The stream's full of stones. Break a big one and bring three. | Derede taş çok. Büyüğünü kır, üçünü getir. |
| `act0.hearth.three` | Ozan | Three stones. Always three. | Üç taş. Hep üç. |
| `act0.hearth.strike` | Ozan | Here. Strike the white stone on the black. | Al. Ak taşı kara taşa vur. |
| `act0.hearth.lit` | Ana | It's caught. Feed it. | Tuttu. Besle onu. |
| `act0.hearth.grow` | Baba | The light's reached us. | Işık bize de yetişti. |
| `act0.hearth.full` | Ozan | Now it's ready. | Şimdi oldu. |
| `act0.hearth.ana` | Ana | Tonight is the bard's night. Everyone will be at the fire. | Bu gece ozanın gecesi. Herkes ateşin başında olacak. |
| `act0.hearth.why_three` | Ozan | Do you know why three? I'll tell it tonight. | Neden üç, biliyor musun? Bu gece anlatacağım. |
| `act0.hearth.wood_done` | Ağabey | With this much wood it'll burn till morning. | Bu kadar odunla sabaha dek yanar. |
| `act0.hearth.sit` | Ana | Come, sit by me. | Gel, yanıma otur. |

### Çocukluk'un iki yeni günü (E21, K110)

20 ve 21 Eylül MÖ 228'in sözleri (`story.md` §5, «İki yeni gün») ve sayım gününe eklenen tek söz (`act0.child.count_stick`). 75 söz, İngilizcesi 3.002 karakter. Çocukların, Lan Hatun'un ve sayıcının sesleri bugünküdür; Hereka Önsöz'ün 39 yaşının sesiyle konuşur (Heather Faith, K95); Ebe Obası'nın halkı iki yeni ses.

| id | Kim | EN | TR |
|---|---|---|---|
| `act0.flock.wake` | Lan Hatun | Up. Today the three of you are taking the flock to Reed Lake. Luhun knows the way. | Kalk. Bugün sürüyü Kamışlı Göl'e üçünüz götüreceksiniz. Luhun yolu bilir. |
| `act0.flock.back` | Lan Hatun | Be back before the sun goes down behind the hill. | Güneş tepeye inmeden dönün. |
| `act0.flock.go` | Luhun | The lake's that way, past the tamarisks. Follow me. | Göl ötede, ılgınların ardında. Ardımdan gelin. |
| `act0.flock.stray_1` | Yançi | One's getting away! Head it off! | Biri kaçıyor! Önüne geç! |
| `act0.flock.stray_2` | Luhun | The ones on the right are scattering! | Sağdakiler dağılıyor! |
| `act0.flock.lake` | Yançi | The lake! The lambs can smell the water. | Göl! Kuzular suyun kokusunu aldı. |
| `act0.flock.swim_dare` | Luhun | Who's swimming? Last one in is a frog! | Kim yüzer? Son giren kurbağa! |
| `act0.flock.swim_deep` | Yançi | It's deep out there, come back! | Orası derin, geri gel! |
| `act0.flock.stone_dare` | Luhun | There's a white stone at the bottom, by the reeds. Whoever brings it up is a lord. | Sazlığın dibinde ak bir taş var. Çıkaran bey olur. |
| `act0.flock.stone_got` | Yançi | He got it! The white stone's his! | Çıkardı! Ak taş onun! |
| `act0.flock.noon_1` | Luhun | That cloud looks like a horse. | Şu bulut at gibi. |
| `act0.flock.noon_2` | Yançi | The Tanhu's horse. A white one. | Tanhu'nun atı. Ak. |
| `act0.flock.noon_3` | Mete | My father's. | Babamın. |
| `act0.flock.noon_4` | Luhun | You'll see him at the count. | Sayımda görürsün onu. |
| `act0.flock.count_gate` | Yançi | Let's count them. Drive them between the two stones. | Sayalım. İki taşın arasından geçirin. |
| `act0.flock.count_38` | Yançi | Thirty-eight. | Otuz sekiz. |
| `act0.flock.count_39` | Yançi | Thirty-nine. | Otuz dokuz. |
| `act0.flock.missing` | Luhun | One's missing! | Bir eksik! |
| `act0.flock.lamb_found` | Yançi | In the reeds! It's stuck in the mud! | Sazlıkta! Balçığa saplanmış! |
| `act0.flock.fox` | Luhun | A fox! It's waiting for the lamb! | Tilki! Kuzuyu bekliyor! |
| `act0.flock.fox_gone` | Luhun | It ran off! | Kaçtı! |
| `act0.flock.forty` | Mete | Forty. | Kırk. |
| `act0.flock.home_call` | Yançi | The sun's touching the hill. Let's go back! | Güneş tepeye değdi, dönelim! |
| `act0.flock.home_count` | Lan Hatun | Forty went out, forty came back. | Kırk çıktı, kırk döndü. |
| `act0.flock.bow` | Yançi | Did you bring your bow? There are ducks at the lake. | Yayını aldın mı? Gölde ördek olur. |
| `act0.flock.walk_1` | Luhun | My father says the Yellow River used to run through here. The lake is what it left behind. | Babam der ki Sarı Irmak eskiden buradan akarmış. Göl ondan kalmış. |
| `act0.flock.walk_2` | Yançi | The river left and forgot the lake. | Irmak gitmiş de gölü unutmuş. |
| `act0.flock.walk_3` | Mete | It didn't forget. It's waiting. | Unutmamış. Bekliyor. |
| `act0.flock.cranes` | Luhun | Cranes! They're going south. | Turnalar! Güneye gidiyorlar. |
| `act0.flock.cranes_2` | Yançi | One day we'll go too. | Biz de bir gün gideriz. |
| `act0.flock.dailin` | Yançi | Look, the smoke from the Dailin. Everyone's coming to the count. | Bak, Dailin'in dumanları. Sayıma herkes geliyor. |
| `act0.flock.water_cold` | Yançi | The water's freezing! | Su buz gibi! |
| `act0.flock.fish` | Luhun | A fish touched my foot! | Ayağıma balık değdi! |
| `act0.flock.stone_mine` | Mete | I'll give this to my mother. | Bunu anama vereceğim. |
| `act0.flock.noon_5` | Yançi | Will the counter count us too? | Sayıcı bizi de sayacak mı? |
| `act0.flock.noon_6` | Luhun | He counts everyone. If he doesn't count you, you're not there. | Herkesi sayar. Saymazsa yoksun. |
| `act0.flock.dusk` | Luhun | Let's have them in the pen before the moon's up. It's the wolves' hour. | Ay doğmadan ağılda olalım. Kurt saatidir. |
| `act0.flock.lan_stone` | Lan Hatun | A white stone… You keep it. A white stone knows the way. | Ak taş… Sende kalsın. Ak taş yolu bilir. |
| `act0.bone.call` | Yançi | The moon's coming up! Let's play white bone! | Ay doğuyor! Ak kemik oynayalım! |
| `act0.bone.rules` | Luhun | I'll throw it. Whoever finds it runs for the post, and the others try to catch them. | Ben atarım. Bulan direğe koşar, ötekiler yakalar. |
| `act0.bone.throw` | Luhun | White bone, lie in the moonlight! | Ak kemik, ay ışığında yat! |
| `act0.bone.mete_has` | Yançi | He's got it! Catch him! | Onda! Yakala! |
| `act0.bone.yanchi_has` | Yançi | I've got it! I've got it! | Bende! Bende! |
| `act0.bone.luhun_has` | Luhun | It's mine! | Benim! |
| `act0.bone.tagged` | Luhun | You got me! Take it, run! | Tuttun! Al, koş! |
| `act0.bone.mete_won` | Yançi | He made the post! | Direğe vardı! |
| `act0.bone.other_won` | Luhun | I made it! | Ben vardım! |
| `act0.bone.end` | Lan Hatun | The moon's high. Bed now. Tomorrow someone is going to Hereka. | Ay yükseldi. Yatın artık; yarın biri Hereka'ya gidecek. |
| `act0.bone.lan_watch` | Lan Hatun | Don't wander off. Moonlight shows the bone, and it shows the wolf too. | Uzaklaşmayın. Ay ışığı kemiği gösterir, kurdu da. |
| `act0.bone.breath` | Yançi | Wait… I can't breathe… | Dur… soluğum kesildi… |
| `act0.bone.tease` | Luhun | You're slower than the old sheep! | Yaşlı koyundan da yavaşsın! |
| `act0.bone.again` | Yançi | Another round! I'm throwing this time. | Bir el daha! Bu kez ben atarım. |
| `act0.bone.moon` | Mete | My father's bowing to the moon now. | Babam şimdi aya eğiliyor. |
| `act0.bone.yanchi_won` | Yançi | I got there first! Me! | İlk ben vardım! Ben! |
| `act0.tally.errand` | Lan Hatun | The count is the day after tomorrow. Take this dried curd to Hereka, and bring back her tally stick. | Öbür gün sayım var. Bu kurutu Hereka Ebe'ye götür, çetelesini al gel. |
| `act0.tally.news_task` | Lan Hatun | And tell her camp about the count. Everyone must hear. | Sayımı obasına da söyle. Herkes duysun. |
| `act0.tally.dogs` | Mete | Hold your dog! | Köpeğinizi tutun! |
| `act0.tally.dogs_held` | Hereka | I've got him. Come. Whose boy are you? | Tuttum, gel. Kimin oğlusun sen? |
| `act0.tally.name` | Mete | Lan Hatun's. | Lan Hatun'un. |
| `act0.tally.counted` | Hereka | I know. Six autumns ago, at the door, I was the one who counted you. | Bilirim. Altı güz önce kapıda seni ben saydım. |
| `act0.tally.stick` | Hereka | Here. Seven notches, this year's births. Give it to the counter, so he doesn't write us short. | Al. Yedi çentik, bu yıl doğanlar. Sayıcıya ver, eksik yazmasın. |
| `act0.tally.news` | Mete | The count's the day after tomorrow! | Sayım öbür gün! |
| `act0.tally.reply_1` | Ebe Obalı | We heard, we heard. | Duyduk, duyduk. |
| `act0.tally.reply_2` | Ebe Obalı | The horses are fat. We'll come and be counted. | Atlar semiz. Gelir sayılırız. |
| `act0.tally.bye` | Hereka | Tell your mother her curd turned out well. | Anana söyle: kurudu güzel olmuş. |
| `act0.tally.home` | Lan Hatun | Did you bring it? Seven. The counter will be pleased. | Getirdin mi? Yedi. Sayıcı sevinir. |
| `act0.tally.why` | Lan Hatun | Hereka keeps count of the newborns. Without her stick, the counter will write us short. | Hereka yeni doğanları sayar. Çetelesi olmazsa sayıcı bizi eksik yazar. |
| `act0.tally.inside` | Hereka | Come in. Don't touch the herbs. Each one is for a birth. | Gir. Otlara dokunma; her biri bir doğum için. |
| `act0.tally.moon` | Hereka | The dawn you were born, the full moon was setting and the sun was rising. Your father bowed to them both. | Doğduğun şafak dolunay batıyordu, güneş doğuyordu. Baban ikisine de eğildi. |
| `act0.tally.reply_3` | Ebe Obalı | Tell the counter our foal should be counted too. | Sayıcıya söyle, bizim tay da sayılsın. |
| `act0.tally.lan_ask` | Lan Hatun | What did Hereka say? | Hereka ne dedi? |
| `act0.tally.mete_answer` | Mete | She counted me. | Beni o saymış. |
| `act0.tally.lan_answer` | Lan Hatun | That's right. It was her voice at the door. | Öyle. Kapıda onun sesi vardı. |
| `act0.tally.give` | Mete | My mother sent it. To say thank you. | Anam gönderdi. Teşekkür için. |
| `act0.child.count_stick` | Sayıcı | Hereka's notches. Seven. | Hereka'nın çentikleri. Yedi. |

## Bedel (K61)

- Konuşma karakter başına 1 kredidir (`eleven_v3`); şarkı dakikası 900 kredidir (27 sn'lik çekim ≈405 kredi, `music_v2_5`); Creator planı ayda 121.000 kredi verir. Tavan yoktur (#56): harcama sayaç ve defterle izlenir; `tools/vo_ledger.jsonl` her API çağrısına bir satır yazar (tarih, ürün, id, çekim, kredi); plan kalandan büyükse araç `--over` ister.
- Bu belgenin çekimleri: mit satırları 3–25 1.352 karakterdir (blokla 1.396), doğum satırı 113, Hereka'nın sözü 9, köprünün üç yeni satırı 359 (N2 98, N3 141, N6 120; 2026-11-05, 158 kredi). Mit 2026-11-07'de okundu (K96): blok 614 kredi, satır 3'ün bağlamlı okuması 45, satır 25'inki 56; toplam 715 kredi (`tools/vo_ledger.jsonl`), karakter başına ≈0,44. Doğum satırı, Hereka'nın sözü ve köprüler daha önce okundu; değişmeyen satıra kredi harcanmaz. Kulak onayı Karar Bekleyenler'dedir. Şarkı çekim 3104'tür (K95); yeni tur istenirse 4 çekim, ≈1.620 kredidir.
- Bu belgenin bütün satırları A dilimindedir (anlatıcı ve sinema). Metin kilidi olmadan üretilmez; her ElevenLabs işi önce kullanıcıya sorulur (K61). Godot'da satır verisi `game/data/vo_lines.json`'dadır (`id`, `act`, `speaker`, `tier`, `text`, `seconds`); araç `tools/elevenlabs_audio.sh tts`, çıktı `mp3_44100_64`. Godot'da Önsöz'ün ve köprülerin bütün satırları oyundadır (`game/audio/vo/prologue/`).
- (K61 ile değişti: belgenin eski sonu şarkı için «≈110 kredi» yazıyor ve eski kaynak klasörünü anıyordu. Bedeller yukarıdadır; kayıtların yeri girişte yazılıdır.)

**Hereka'nın sesi (K95).** Kullanıcı seçimi öneriye bıraktı («hereka secimini sana birakiyorum onerdigini sec»): Önsöz'ün 39 yaşı Heather Faith (`49d0YOOn2K0LVSBCkZ0q`), I. ve IV. Perde Lea, Mature (`V4hbKpM9VBIJ9lKaWBjM`). Satır 9 karakterdir; Heather Faith'le 2026-11-07'de okundu (çekim 2, 0,64 sn; iki okuma, 8 kredi: çekim 1'in sonu −22 dB'de kesiliyordu). Lea'nın geçici okuması (1,04 sn) `docs/media/review/audio/hereka/`'dadır. **Model karara bağlandı (K89, E7.9):** temel model I. ve IV. Perde'nin yaşlı Hereka'sıdır; Önsöz'ün ≈45 sn'lik doğum sahnesi konseptten ayrı modelle çekilir (`hereka_young`), çünkü iki Retexture'da yüz soluk çıktı. Modeller oyunda (Yol Haritası `hereka-model`).
