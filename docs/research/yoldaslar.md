# Yoldaşlar: araştırma

Bu belge yoldaş isteğinin araştırma tabanıdır. Tür örneklerinden mekanik dersleri, kadraj dışındaki yoldaşın yuvarlak kartını, on yoldaşla başarımı, Mete'nin çevresindeki tarihî yoldaş adaylarını ve yoldaşın bozkırdaki işlerini toplar. Etiketler `mete-tarih.md` ile aynıdır: [kaynak] kaynağı olan bilgi, [çıkarım] kaynaktan benim çıkarımım, [kurgu] oyun için öneri. «Arama özeti» yazan bilgi, sayfa açılamadığı için arama aracının özetinden gelir ve zayıf sayılır. Örnek oyunlardan ad, kişi ve arayüz görünüşü alınmadı; yalnız mekanik ders alındı. Tanhu 1'in kadrosu (`research/progression.md`) kopyalamamak için okundu, ondan ad ve kişi alınmadı. Belge 2026-11-04'te yazıldı ve aynı gün sınandı (sondaki «Doğrulama»).

## Soru

Kullanıcının isteği, olduğu gibi:

> Ek olarak baldurs gate deki gibi companionlarımızda olabılecek haritada serbest dolaşıyorken yanımıza alabileceğimiz (10 companiona kadar alabiliriz ve her companionun kendi profil resminden mini dairesel kartı olacak eğer haritada gözükmüyorlarsa bu mini çeber profil resimleri gözükecek ne tarafta olduklarını belli edecek şekilde)

Araştırma soruları:

1. Yoldaşlı RPG'ler parti boyu, işe alma, bağ, kamp, kişisel görev, ayrılık, ölüm, buyruk, düzen ve takip için ne öğretir? On kişilik parti neyi zorlaştırır?
2. Kadraj dışındaki yoldaş ekran kenarında nasıl gösterilir: yer, boy, kümelenme, güvenli alan, renk körlüğü, ayar? Godot 4.7'de nasıl yapılır?
3. On yoldaş ve atları Godot'da hangi yol bulma, kaçınma, kademe ve canlandırma bütçesiyle yürür?
4. Mete'nin hayatında yoldaş olabilecek tarihî kişi ve gruplar kimlerdir? Kaynakları, yılları, güvenleri nedir? Adı bilinmeyene hangi ad verilebilir?
5. Bir yoldaş MÖ 3. yy bozkırında hangi işi yapabilir, dayanağı nedir?

## Yöntem

- **İç belgeler.** `mete-tarih.md` §2.2, §5, §6; `oyun-seviye-tasarimi.md` §6; `army.md` §1–§6; `progression.md` §3, §5, §11, §12; `act1.md` §2, §3, §9.7; `godot.md` §4.5–§4.7, §5.4, §7.2; `hayvanlar.md` §4; `kopuz.md` özeti. Kod: `follow_camera.gd`, `ui_kit.gd`, `game_hud.gd`, `game_settings.gd`, `creator_baked_rect.gd`.
- **Birincil metin.** zh.wikisource ham metni: Shiji 7 (三家註 ile), 93, 110 (三家註 ile), 123; Hanshu 31, 33, 34, 54, 61, 94A, 96A, 96B.
- **Oyun tasarımı.** bg3.wiki, Fextralife, Wikipedia, geliştirici söyleşileri (Game Informer, GameBanshee), Game Developer yazıları. Fandom vikileri 402, bazı forumlar 403 verdi; o bilgiler arama özetidir.
- **Arayüz.** Xbox Erişilebilirlik Yönergeleri (XAG 101, 103), Game Accessibility Guidelines, Microsoft'un TV güvenli alan belgesi, CHI makaleleri (Halo, Wedge).
- **Godot.** Sınıf başvurusu (`stable`) ve navigasyon öğreticisi.
- **Kamera hesabı.** `follow_camera.gd` sabitleriyle betikle: eğim 23,35°, dikey görüş 41,76°, uzaklık 27 m (6–40 m), uzaklığa göre eğim ±6°, bakış noktası ayaktan 0,7 m yukarıda, düz zemin. Ölçüm değil hesaptır [çıkarım].
- Kredi harcayan araç kullanılmadı. Bu dosyadan başka dosyaya dokunulmadı.

## Bulgular

### 1. Yoldaşlı RPG'lerden mekanik dersler

| Oyun | Parti | Mekanik ders | Kaynak |
|---|---|---|---|
| Baldur's Gate 3 | 4, oyuncu dahil | Onay 100'de durur; −20 ve −40'ta uyarı, −50'de kalıcı ayrılık. Olay anında uzakta olanın onayı değişmez; kampta bekleyen onay ne kazanır ne yitirir | bg3.wiki, Fextralife [kaynak]; parti sınırı The Loadout [arama özeti] |
| Dragon Age: Origins | Etkin parti, kalan kampta | Hediye onayı artırır, kişiye özel hediye sahne ya da görev açar. Yüksek onay savaş artısı verir, düşük onay ayrılık ya da düşmanlık getirir. Düşen yoldaş kalıcı yara alır, sargı takımıyla kapanır | Wikipedia [kaynak]; yara GameBanshee, Prima [arama özeti] |
| Dragon Age: Inquisition | 4 | Görev söyleşisi belli anlarda, gezi söyleşisi rastgele gelir; bölgede ve kadroda tükenir, kişisel görevle yenilenir. Topluluk ≈15 dk'lık sayaç ölçer; yükleme sayacı sıfırlar, binekte söyleşi başlamaz | BioWare blogu, Fextralife rehberi [arama özeti] |
| Pillars of Eternity II | 5 (6'dan indi) | Yeteneklerin izlenmesi kolaylaşsın, savaş daha taktiksel ve izlenir olsun diye | Game Informer 2018, GameBanshee [kaynak] |
| Mass Effect 2 | Oyuncu + 2 | Sadakat görevi kişisel görevdir: bir güç açar, son görevde sağ kalmayı gemi ve görev dağılımıyla birlikte belirler | Wikipedia [kaynak] |
| Mount & Blade: Warband | Ordu | Her yoldaşın bir sevdiği, iki sevmediği vardır; sevmediğiyle kalanın morali düşer, sonunda ayrılır | Topluluk rehberi [arama özeti] |
| Mount & Blade II: Bannerlord | Tavan 4, boy kademesiyle 9 | Dört parti görevi: levazımcı, gözcü, cerrah, mühendis. Yoldaş vali ve kervan başı da olur | GamerGuides, GameBanshee [kaynak] |
| Kenshi | 30 kişi, takımda 20 | Büyük kadronun başarım bedeli uyarılır; modla 256'ya çıkar | Kenshi vikisi, Nexus [arama özeti] |
| Divinity: Original Sin 2 | 4 | Zincirli üyeler önderi izler; zinciri çözülen ayrı yürür | Steam topluluğu [arama özeti] |
| The Last of Us | 1 yoldaş | Ellie yakında kalır, oyuncuyu ele vermez; gizlilikte düşman onu fark etmez. Kural eğlence için bükülür | Killscreen, Game Developer [kaynak] |
| DOOM (2016) | Düşman | Her saldırı türünde sınırlı jeton vardır; jetonu olmayan saldırmaz, zorluk jeton sayısını değiştirir | Game Developer [kaynak] |

**1.1 Parti boyu.**
- Taktik RPG partisi 3–6 kişidir. Gerekçe savaşın izlenmesi ve yönetimidir: PoE II altı kişiden beşe indi, çünkü altı kişilik gelenek yeteneği az sınıflı eski oyunlardan kalmıştı [kaynak]. BG3'ün dört kişilik sınırının dengeden geldiği söylenir; Larian'ın açıklaması bulunamadı [arama özeti].
- Büyük kadrolu oyunlar yoldaşı role ve birliğe çevirir. Bannerlord yoldaşa parti görevi verir [kaynak]; Kenshi kadroyu takımlara böler [arama özeti].
- [çıkarım] Tanhu'da on kişi taktik parti değil, ordunun en küçük birimidir. Doğru örnek BG3'ün dörtlü kavgası değil, Bannerlord'un rol yoldaşı ve `army.md`'nin onluğudur. Yük buyrukla değil, rol ve düzenle taşınır.

**1.2 İşe alma, bağ, güven.**
- Üç yol öne çıkar: hikâye (BG3, DAO), ücret ya da han (Warband, Bannerlord), kurtarma (Kenshi) [çıkarım: tür bilgisi, bu turda ayrıca sınanmadı].
- Bağ çoğu oyunda tek eksendir; PoE II onu küçük davranışa da bağlar: hayvan seven yoldaş hayvana kötülükten kırılır [kaynak: RPGSite 2017].
- BG3'ün yakınlık kuralı önemlidir: olayı duymayanın onayı değişmez [kaynak]. Bu, on kişide her seçimin on tepki üretmesini önler [çıkarım].
- [çıkarım] Tanhu'nun ekseni zaten vardır: `ties.<id>` 0–10, Defter'de 0–3 düğüm (`act1.md` §2); Kut ve Korku sayısızdır (`progression.md` §5.1). Yeni bir onay ölçeği gerekmez.

**1.3 Kamp söyleşisi ve kişisel görev.**
- DAI söyleşiyi iki katmana ayırır: göreve bağlı ve geziye bağlı. Gezi söyleşisi tükenir, kişisel görev ilerledikçe yenilenir [arama özeti].
- ME2'de kişisel görev sonun bedelini değiştirir [kaynak]. Böylece yoldaş görevi yan iş olmaktan çıkar [çıkarım].
- [çıkarım] Binekte susan yoldaş bu oyunda yanlıştır: yolun çoğu at üstündedir. Kamp söyleşisinin yeri ateş başıdır (`survival.md` `fire_rest`).

**1.4 Ayrılık, ölüm, yara.**
- BG3'te ayrılık bağın dibinde gelir ve önce iki uyarı verilir; DAO'da düşük onay ayrılık ya da düşmanlık getirir [kaynak].
- DAO'da düşmek ölmek değildir, kalıcı yaradır [arama özeti].
- Tanhu'da Düşüş'te adı bilinen üyenin ölüm şansı Normal %30, Zor %50'dir; `lead_carry` ×0,3 (`progression.md` §11, §12). [çıkarım] El yazımı içeriği olan yoldaş için bu şans ağırdır: yazılmış görev yarıda kalır.

**1.5 Buyruk, düzen, takip.**
- Pottinger (Age of Empires): grup en yavaş üyenin hızıyla yürür, öndeki geridekini bekler. Yuva düzenin yönüne göre ofsettir, içten dışa doldurulur. Engelde düzen dağılır, öbür yanda yeniden kurulur; yeniden kurma uzaksa yeni yol alınır [kaynak].
- DOS2'nin zinciri bir dersi verir: oyuncu kimin izleyeceğini kendisi seçer [arama özeti].
- The Last of Us: yoldaş yakında kalır ve oyuncunun gizliliğini bozmaz [kaynak].
- DOOM'un jetonu düşman içindir. [çıkarım] Aynı kalıp yoldaşların tek hedefe yığılmasını önler.

**1.6 On kişilik partinin zorlukları.**

| Zorluk | Büyüklük | Çözüm [çıkarım] |
|---|---|---|
| Söyleşi yükü | 10 kişide 45 ikili, 4 kişide 6 | 12 ikiliye el yazımı söyleşi; kalan ikililer köken, huy ve olay etiketli kısa sözle |
| Okunurluk | 11 atlı; kama 9,6 × 16,8 m (`army.md` §4.1); 27 m'de kişi ≈86 px | Her yoldaşa tek siluet işareti (şapka, kaftan rengi); yer halkası ve ad yalnız savaşta ya da tuşla |
| Dövüş kalabalığı | 11 kişi bir hedefe yığılır | Yakın dövüş jetonu: hedef başına 3, toplam 6; jetonsuz yoldaş ok atar (`army.md` §6.2: önce ok) |
| Buyruk yükü | 10 kişiye tek tek buyruk | Dört grup buyruğu (`army.md` §6.1) ve tek kişi çağrısı; rol işi kendiliğinden |
| Ses yükü | 10 kişinin bütün sözleri | Sahne sesi yalnız çekirdek yoldaşa; ötekine altyazı ve sözsüz ses |
| Çizim yükü | 11 atlı, 22 iskelet | §3.2 |

### 2. Ekran dışı gösterge

**2.1 Örnekler.**
- Don't Starve Together: kadraj dışındaki oyuncu ekran kenarında karakterinin baş resmiyle görünür; görünürlüğün uzaklıkla sınırlı olduğu sanılır; resmin eskimesi hata kaydına girmiştir [arama özeti: Klei hata kayıtları].
- Oxide: ekip arkadaşları için kenarda yön simgesi, ayarla açılır [arama özeti].
- Diablo IV: her ekip üyesinin rengi parti çerçevesinde ve harita işaretinde aynıdır [kaynak: Icy Veins].
- PlayMaker'ın kenar bileşeni işareti dikdörtgen ya da elips sınırın en yakın noktasına koyar ve hedefe döndürür [arama özeti; sayfa 403].
- Halo (Baudisch ve Rosenholtz, CHI 2003) yönü ve uzaklığı ekrana taşan halka yayıyla verir, ama halkalar üst üste biner. Wedge (Gustafson ve ötekiler, CHI 2008) her hedefe dar bir kama koyar; kamalar çakışmayana dek birbirini iter ve döner; üç görevde Halo'dan anlamlı ölçüde daha doğrudur [kaynak: Manitoba yayın sayfası, dblp; arama özeti].
- Proje: `ThreatEdge` tehdidi %92'lik elipste en çok üç okla gösterir, fazlası sayı olur; biçim durumu söyler, renk ektir (`godot.md` §5.4).

**2.2 Erişilebilirlik ve güvenli alan.**
- XAG 101: varsayılan metin 1080p'de PC için en az 18 px, konsol için 26 px; 4K'da 36 ve 52 px. Simge içindeki yazı da bu sınıra uyar; simge yazıyla birlikte %200'e dek büyür [kaynak].
- XAG 103: kritik görsel ipucu ikinci kanalla desteklenir, renk tek başına kullanılmaz [kaynak: `oyun-seviye-tasarimi.md` §6.3].
- GAG: bilgi yalnız sabit renkle verilmez, simge, desen ya da biçim eklenir (temel düzey). Arayüz boyu ayarlanır (orta düzey) [kaynak].
- TV güvenli alanı: yanlardan 48, üstten ve alttan 27 etkin piksel. Etkin alan 960 × 540 olduğu için 1080p'de 96 ve 54 px, yani %5'tir. Odaklanan her öğe bu alanda kalır [kaynak: Microsoft Learn, Windows blogu 2016].

**2.3 Bu kamerada yoldaş ne zaman kadraj dışındadır.** Mete ekranın ortasındadır, ileri pay yoktur (`godot.md` §5.7). 16:9, düz zemin [çıkarım].

| Uzaklık | Eğim | Arkada görünen | Önde görünen | Yanda, Mete hizasında | 1,8 m kişi |
|---|---|---|---|---|---|
| 6 m | 17,35° | 2,6 m | Ufka dek | ±4,2 m | 392 px |
| 10 m | 18,49° | 4,8 m | Ufka dek | ±6,9 m | 236 px |
| 15 m | 19,92° | 7,4 m | Ufka dek | ±10,3 m | 157 px |
| 27 m | 23,35° | 13,1 m | 240 m | ±18,5 m | 86 px |
| 40 m | 29,35° | 18,0 m | 102 m | ±27,4 m | 55 px |

- 16:10'da yan görüş 6, 27, 40 m'de ±3,8, ±16,6, ±24,6 m'dir; 21:9'da ±5,5, ±24,3, ±35,9 m.
- Kama düzeninin 10 yuvasından kadrajda kalan (yaya ölçeği 0,55 / atlı 1 / dörtnalda açılmış 1,25): 6 m'de kamera arkadayken 7/5/3, kamera öndeyken 9/7/5; 15 m'de 8–10; 27 m ve 40 m'de 10/10/10. Gerçek atlı yuvanın gerisinde kalır: bozkırda dörtnalda %92,8'i yuvasına 6 m içindedir (`army.md` §5.6).
- [çıkarım] Varsayılan kadrajda kart, 13 m'den çok geride kalan, 18 m'den çok yana açılan, işe gönderilen ya da kaybolan yoldaş içindir. Yakın kadrajda yoldaşların yarısı karttadır: kart istisna değil, olağan görünüştür.

**2.4 Godot 4.7'de yapım.**
- `Camera3D.unproject_position(world_point)` görüntü alanındaki 2B noktayı, `is_position_behind` noktanın kameranın arkasında olup olmadığını, `is_position_in_frustum` görüş kesiğinde olup olmadığını verir. Belge arkadaki noktayı `is_position_behind` ile ayırmayı söyler [kaynak]. Godot forumu arkadaki noktanın izdüşümünün işe yaramadığını yazar [arama özeti].
- **Matematik.** Önde olan noktada yön, ekran merkezinden izdüşüme doğrudur. Arkadaki noktada izdüşüm kullanılmaz; yön zemin düzleminde kameranın sağına ve ileri yönüne göre kurulur: ileri ekranda yukarı, geri aşağıdır. Böylece arkadaki hedef ters çevrilmiş olur. Yön ışını iç dikdörtgende durur [çıkarım]:

```gdscript
## Kadraj dışı yoldaşın kart merkezi. area: görüntü alanı, inset: kart merkezinin kenara uzaklığı.
static func edge_point(cam: Camera3D, p: Vector3, area: Rect2, inset: Vector2) -> Vector2:
	var c := area.get_center()
	var dir: Vector2
	if cam.is_position_behind(p):
		var d := p - cam.global_position
		var fwd := Vector3(-cam.global_basis.z.x, 0.0, -cam.global_basis.z.z).normalized()
		dir = Vector2(d.dot(cam.global_basis.x), -d.dot(fwd))
	else:
		dir = cam.unproject_position(p) - c
	if dir.length_squared() < 0.0001:
		dir = Vector2.DOWN
	dir = dir.normalized()
	var half := area.size * 0.5 - inset
	var t := minf(half.x / maxf(absf(dir.x), 0.0001), half.y / maxf(absf(dir.y), 0.0001))
	return c + dir * t


## Kadrajda mı: arkada değil ve izdüşümü kenardan margin × yükseklik içeride.
static func is_on_screen(cam: Camera3D, p: Vector3, area: Rect2, margin: float) -> bool:
	return not cam.is_position_behind(p) and area.grow(-area.size.y * margin).has_point(cam.unproject_position(p))
```

- Köşe yuvarlatılır: nokta köşe karesine düşerse yay merkezine göre yarıçapa itilir [çıkarım].
- **Maske, yol 1.** `Panel` + `StyleBoxFlat` (köşe yarıçapı kartın yarısı) ve `clip_children = CLIP_CHILDREN_ONLY`: düğüm maske olur, çizilmez; çocuk `TextureRect` onun alanına kırpılır, yarı saydam kenar karışır. İç içe kırpma ve `CanvasGroup` içinde kullanım desteklenmez [kaynak].
- **Maske, yol 2.** `TextureRect` + `canvas_item` gölgelendiricisi [çıkarım]:

```glsl
shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float d = distance(UV, vec2(0.5));
	c.a *= 1.0 - smoothstep(0.5 - fwidth(d), 0.5, d);
	COLOR = c;
}
```

- **Portre.** `SubViewport` kendi 3B dünyasıyla (`own_world_3d`) ve `render_target_update_mode = UPDATE_ONCE` ile bir kez çizer, sonra kapanır [kaynak]. Proje bu deseni `creator_baked_rect.gd`'de zaten kullanır.
- **Güvenli alan.** `DisplayServer.get_display_safe_area()` engelsiz alanı `Rect2i` olarak verir; gerçek değer yalnız Android ve iOS'tadır, öteki platformlar ana pencerenin ekranındaki kullanılabilir alanı döner [arama özeti: sınıf başvurusu yansısı].
- **Katman.** `GameHud` boyalı ekran efektinin (`PainterlyOverlay`, katman 1) üstündeki `CanvasLayer`'dadır (`game_hud.gd`). Kart katmanı oraya girer; ölçek `UIKit.ui_k()`'dir.

### 3. Kalabalık yoldaşla başarım ve davranış

**3.1 Yol ve kaçınma.**
- `NavigationAgent3D` dinamik engeli RVO ile aşar. `avoidance_enabled` ajanı sunucuda kaydeder; belge çok ajanda bedelin büyük olduğunu, yalnız gerekince açılmasını söyler. `neighbor_distance` küçüldükçe bedel düşer; `max_neighbors` çok düşükse ajan kaçınmayı yok sayar; zaman ufukları olabildiğince kısa tutulur. Yüksek `avoidance_priority`'li ajan düşüğü yok sayar. Katman ve maske fizik katmanı gibidir. Sonuç `velocity_computed(safe_velocity)` ile gelir, hareketi betik uygular. Sıçramadan sonra aynı karede `set_velocity_forced()` çağrılır. `path_max_distance` aşılınca yeni yol istenir; her kare yol yenilemek salınım yapar. Kaçınma yol bulmayı değiştirmez ve varsayılan olarak düzlemdedir [kaynak: sınıf başvurusu, öğretici].
- RVO'da her ajan ötekinin de kaçınacağını varsayar; yöntem salınımı gidermek için çıkmıştır (van den Berg, Lin, Manocha, ICRA 2008) [kaynak].
- Proje: `Follower` yuvayı izler, görüş kapanınca liderin kırıntısını izler, A* son çaredir, sıçrama yalnız kadraj dışındadır (`army.md` §5.4). Ölçüm: bozkırda dörtnalda ortalama hata 1,70 m, kampta 3,26 m (`army.md` §5.6). Godot'da kişiler (T0, ≤16) `NavigationAgent3D` ile yürür; oyuncu navmesh'e bağlı değildir (`godot.md` §4.7).

**3.2 Çizim ve canlandırma.**
- `godot.md` §7.2 kalabalık sütunu: T0 ≤16 kişi ve ≤4 atlı. Mete ve on atlı yoldaş 11 atlıdır, 22 iskelet eder. Bu, bugünkü tavanla çelişir [çıkarım].
- `AnimationMixer.callback_mode_process = ANIMATION_CALLBACK_MODE_PROCESS_MANUAL` canlandırmayı durdurur, `advance(delta)` elle ilerletir [kaynak]. Topluluk örneği: en yakın 8 karakter tam hız, sonraki 32 yarı, kalanı çeyrek; görünmeyende canlandırıcı kapatılınca 200'den çok birim [arama özeti: Godot forumu, r/godot].
- `VisibleOnScreenEnabler3D` kutusu görünmeyince hedefin `process_mode`'unu kapatır; sezgiseldir, örtme ayıklaması yoksa duvarı saymaz [kaynak].
- `army.md` S0: 10 tam atlı 0,25 ms (prototip, tarayıcı). Godot'da ölçülmüş sayı yoktur (`godot.md` §7.2).

**3.3 Düzen yuvaları.**
- `army.md` §4.1: kama, saf, hilal; 10 yuva ve `L` önder yeri; ilk atama `ties` sırasıyla, değişimde açgözlü en yakın. Yaya ölçeği `FOOT_K = 0,55`. Dar yerde kama kola döner, «istenen de budur» (`army.md` §5.6).
- [çıkarım] 10 × 10 atama Macar yöntemiyle ≈1.000 işlemdir; düzen değişiminde yolların kesişmesini önler. Açgözlü yöntem dönüşte (`flip`) kalır.

**3.4 Yaya ve atlı.**
- Atlı yan aralık 3,2 m, sıra aralığı 4,2 m; yaya bunun 0,55'i (`army.md` §4).
- Grup en yavaş üyenin hızıyla yürür [kaynak: Pottinger]. [çıkarım] Oyuncunun hızı kısılmaz; geride kalan yetişir ya da kadraj dışında sıçrar.

### 4. Tarih

**4.1 Onluk düzeni.**
- 諸二十四長亦各自置千長、百長、什長 [kaynak: SJ 110]. Hanshu listeyi uzatır: 千長、百長、什長、裨小王、相、都尉、當戶、且渠之屬 [kaynak: HS 94A]. Yirmi dört başın büyüğü on bin, küçüğü birkaç bin atlı sürer, unvanları 萬騎'dır [kaynak: SJ 110, `army.md` §1].
- «Tümen» Shiji'de geçmez. 統萬'ın (Tongwancheng) tümenle bağlanması öneridir [kaynak zayıf: Wikipedia, Hun dili].
- Onbaşı, yüzbaşı, binbaşı bugünkü rütbe sözleridir (`army.md` §1).
- [çıkarım] Hun onluğu on kişidir ve başı içindedir. Oyun onluğu 10 yuva ve önder yeri diye kurar (`army.md` §4). Mete ve on yoldaş bu yüzden on bir kişidir; Destan notunda söylenir.

**4.2 Mete'nin çevresi.**
- 左右: ıslıklı okun vurduğuna atmayan kesilir; kimi atamaz, sonunda hepsi atar [kaynak: SJ 110]. Yakın çevrenin adı yoktur.
- 群臣: toprak için danışılan beylerden «verilsin» diyenler kesilir: 諸言予之者，皆斬之 [kaynak: SJ 110].
- 近幸臣妾從死者: yakın beyler ve cariyeler ölen efendinin ardından ölür (SJ 110; HS 94A 數十百人) [kaynak: `mete-tarih.md` §6.2].
- Beckwith, Mete'nin öyküsünü kendini kanıtlayıp güvenilir yoldaşlar toplayan kahraman masallarına benzetir [kaynak: Wikipedia, Modu Chanyu; Beckwith 2009, 1. bölüm].
- Soylu soylar: 呼衍氏，蘭氏，其後有須卜氏，此三姓，其貴種也 [kaynak: HS 94A]. Huyan sol, Lan ve Xubu sağdır, yargıyı yürütür; bu kayıt MS 1. yy Güney Hunlarınındır (HHS 89) [kaynak: `mete-tarih.md` §1.2].
- Hatunlar: sevdiği eş, Tunghu'ya verilen hatun, Baideng hatunu. Adları yoktur [kaynak: SJ 110].

**4.3 Halklar.**
- Tunghu: 大破滅東胡王，而虜其民人及畜產. Halk ve sürü Hun'a geçer [kaynak: SJ 110].
- Loufan ve Baiyang: 南并樓煩、白羊河南王 [kaynak: SJ 110]. Han ordusunda Loufan adlı bir atlı okçu Chu'nun üç yiğidini vurur, Xiang Yu'nun bakışı karşısında okunu atamaz, sura kaçar: 樓煩目不敢視，手不敢發 [kaynak: SJ 7; HS 31]. 應劭: 樓煩胡也，今樓煩縣 [kaynak: SJ 7 集解]. Olay Guangwu karşılaşmasıdır, MÖ 203 [çıkarım].
- Dingling: 後北服渾庾、屈射、丁零、鬲昆、薪犁之國 [kaynak: SJ 110]. Bir yüzyıl sonra 丁令盜武牛羊: Dingling Su Wu'nun sürüsünü çalar [kaynak: HS 54].
- Usun: SJ 123'te babayı Hun öldürür; bebeğe karga et getirir, kurt emzirir; tanhu onu kutlu sayıp büyütür, yetişince babasının halkını verir [kaynak]. HS 61'de babayı (難兜靡) Büyük Yüeçi öldürür; lala 布就翖侯 (Vikikaynak 翎 basar) bebeği otların arasına saklar, kurdu ve kargayı görünce Hunlara götürür, tanhu sever ve büyütür [kaynak]. Kunmo'nun adı 獵驕靡'dır: 昆莫，王號也 [kaynak: HS 96B]. Hangi tanhu olduğu yazmaz.
- Yüeçi: Mete'nin rehinelik yılları; I. Perde kadrosu (`act1.md` §3).

**4.4 Han'dan Hunlara geçenler.**
- Han Xin (韓王信): 201'de Mayi'yi verir, Mete'yle Han'a saldırmayı tasarlar; 196 baharında 柴將軍 onu Canhe'de öldürür [kaynak: SJ 93].
- Wang Huang (王黃) ve Manqiu Chen (曼丘臣): 白土人, Zhao soyundan 趙利'yı kral yapar; ikisi de 故賈人, yani eski tüccardır. Chen Xi ayaklanınca (197–196) Wang Huang'ı Hun'dan yardım istemeye gönderir: 陳豨使王黃求救匈奴. Wang Huang'ın sonu metinde çelişir: bir yerde Quni'de kesilir, başka yerde adamları onu ödül için diri teslim eder [kaynak: SJ 93].
- Chen Xi (陳豨): Zhao'dan geçerken ardında 1.000'den çok arabalık konuk maiyeti vardır; Gaozu'nun 12. yılının kışında Lingqiu'da kesilir. Kendisi Hun'a geçmez [kaynak: SJ 93].
- Eski Yan kralı Zang Tu'nun oğlu Yan (衍): Hun ülkesinde sürgündür. Zhang Sheng'e «Yan'da değerin Hu işlerini bilmendendir» der: 以習胡事也 [kaynak: SJ 93; Vikikaynak 臧茶 basar].
- Lu Wan (盧綰): 195'te halkıyla Hun'a geçer, 東胡盧王 olur, bir yıl sonra ölür; karısı ve çocukları İmparatoriçe Lü döneminde Han'a döner [kaynak: SJ 93; HS 34].
- Tuidang (穨當) ve Ying (嬰): Han Xin'in oğlu ve torunu, Hun ülkesinde doğar; 孝文十四年 (166) halklarıyla Han'a geçer, marki olurlar [kaynak: SJ 93; HS 33 yıl vermez, 頹當 yazar].
- Dönem dışı ama en temiz kalıp: Ganfu (甘父, 堂邑父). Zhang Qian'ın yol arkadaşı, Hun kökenli köle; iyi okçudur, erzak bitince av vurup karın doyurur; Zhang Qian'ın Hun karısıyla birlikte kaçarlar (138–126) [kaynak: SJ 123; HS 61].

**4.5 Ad örnekleri.** Hun dili sınıflanamamıştır; adlar Çince çevriyazıdır, gerçek söylenişi bilinmez [kaynak: Wikipedia, Hun dili]. Kişi adı pinyin kalır (`mete-tarih.md` §5.2).

| Halk | Kayıtlı ad ya da söz | Çağ | Kullanım [çıkarım] |
|---|---|---|---|
| Hun, Mete çağı | 頭曼, 冒頓, 稽粥 Jiyu, 係雩淺 Xi Huqian | MÖ 3.–2. yy | Ünlü kişilerin; yeniden kullanılmaz, hece kalıbı için |
| Hun, sonraki tanhular | 軍臣 Junchen, 伊稚斜 Yizhixie, 烏維 Wuwei, 呴犁湖 Xulihu, 且鞮侯 Qiedihou, 狐鹿姑 Hulugu, 壺衍鞮 Huyandi | 161–68 | Adlı erlere hece kalıbı; aynen alınmaz |
| Hun, unvan ve söz | 撐犁 gök, 孤塗 oğul, 屠耆 bilge, 閼氏, 居次, 且渠, 當戶, 骨都 | Han kaynağı | Lakap ve makam; 𢴤黎孤塗 SJ 110 索隱'de |
| Usun | 難兜靡 Nandoumi, 獵驕靡 Liejiaomi, 軍須靡 Junxumi, 翁歸靡 Wengguimi, 泥靡 Nimi; unvan 昆莫, 岑陬, 翖侯 | MÖ 2.–1. yy | «-mi» sonu tekrarlanır; Usun yoldaşa bu kalıp |
| Yüeçi | Mete çağında kişi adı yok | | `act1.md` Saka-İran ve Toharca sözlerden kurar [kurgu] |
| Tunghu, Loufan, Baiyang, Dingling | Kişi adı yok | | İş, yer ya da hayvan lakabı [kurgu] |
| Han | Gerçek adlar bol (§4.4) | | Yalnız tarihî kişiye |

### 5. Bozkırda yoldaşın işi

| İş | Dayanak | Çağı | Güven |
|---|---|---|---|
| Okçu | 控弦之士; 士力能毌弓，盡爲甲騎 (SJ 110); Loufan okçusu (SJ 7) | Mete çağı | Yüksek |
| Mızrakçı | 短兵則刀鋋 (SJ 110); 韋昭: 鋋形似矛，鐵柄 (SJ 110 集解) | Mete çağı | Yüksek silah; ayrı uzmanlık [çıkarım] |
| Avcı | 兒能騎羊，引弓射鳥鼠；少長則射狐兔 (SJ 110); Ganfu av vurur (SJ 123) | Mete çağı; 138 | Yüksek |
| İz sürücü, gözcü | 甌脫: 服虔 作土室以伺漢人; 正義 境上斥候之室 (SJ 110 三家註) | Mete çağı | Orta |
| At terbiyecisi | Sürü ve at türleri (SJ 110); Pazırık koşum, maske, eyer örtüsü, MÖ 6.–3. yy | Mete çağı ve önce | Yüksek atçılık; unvan [çıkarım] |
| Kam | 匈奴使巫埋羊牛所出諸道及水上以詛軍 (HS 96B); 胡巫 Li Guangli'yi kurban ettirir (HS 94A) | MÖ 90–89 | Orta: ≈120 yıl sonra |
| Otacı | Hun hekimi (毉) çukurda köz yakar, Su Wu'yu üstüne yatırır, sırtına basıp kanı akıtır (HS 54) | MÖ 100 dolayı | Orta |
| Demirci | Khustyn Bulag izabesi, Ivolga (`mete-tarih.md` §6.3) | MÖ 1. yy–MS 1. yy | Orta: ≈150 yıl sonra |
| Dilmaç | 為發導繹 (SJ 123); 譯長二人 (HS 96A); 以習胡事也 (SJ 93) | 196; MÖ 2. yy | Yüksek, Han tarafı |
| Tüccar, pazarlıkçı | 王黃、曼丘臣，皆故賈人 (SJ 93) | 201–196 | Yüksek |
| Doğancı | Hun kuşçuluğuna doğrudan buluntu yok; atlı kuşçuluk MÖ 1. binyıla önerilir (`hayvanlar.md` §4; İran kaya resmi çalışması) | Belirsiz | Düşük |
| Güreşçi | Güreşçili kemer levhası, Ordos, Batı Han, MÖ 2.–1. yy (OAM Berlin). Kexingzhuang levhasının Hun'a bağlanması tartışmalı | MÖ 2.–1. yy | Orta |
| Kopuzcu ozan | Mete çağı telli lavta tanığı yok (`kopuz.md`); Hun ağıdı 西河舊事'nde (SJ 110 索隱, 正義), MÖ 121 sonrası | Geç | Düşük çalgı, orta şarkı |
| Soylu kadın, sınır yöneticisi | Takhiltyn Khotgor ve Shombuuzyn Belchir'de en zengin mezarlar kadınların; altın güneş ve ay, koşum, araba (Science Advances 2023) | Hun çağı, batı sınırı | Orta |

## Tarihî kişiler tablosu

Güven: kişinin kaynakta varlığı ve yıl için. Yoldaş olarak kullanım her satırda [kurgu]dur.

| Ad | Halkı | Kaynak | Yıl (MÖ) | Yoldaş olarak kullanım önerisi | Güven |
|---|---|---|---|---|---|
| Islıklı okla eğitilen atlılar (其騎, 左右) | Hun | SJ 110 | 209 | II: adlı erlerin çekirdeği; ıslık sınavlarında yanında olanlar | Yüksek grup; adlar [kurgu] |
| İlk firariler (`first_ten`) | Hun | `act1.md` | 210 | I: ilk yoldaşlar; Uldın (eski onbaşı, güreşçi), Berik (iz, gizlilik) | [kurgu] |
| Sevdiği eş (愛妻) | Hun | SJ 110 | 209 | Yoldaş olmaz: kamp kişisidir, `kin` sınavının konusu | Yüksek olay |
| Tunghu tutsakları (虜其民人) | Tunghu | SJ 110 | 208 | III–IV: iz sürücü, avcı | Yüksek grup |
| Loufan okçusu (樓煩) | Loufan | SJ 7; HS 31 | 203 | IV: Han'da okçuyken Xiang Yu'dan kaçan adam; utanç görevi | Orta: olay [kaynak], Hun'a geçişi [kurgu] |
| Loufan ve Baiyang halkı | Loufan, Baiyang | SJ 110 | ≈205 (S) | IV: at yetiştirici, Ordos kılavuzu | Yüksek grup |
| Dingling avcıları | Dingling | SJ 110; HS 54 | ≈202 (S) | IV–V: kuzey ormanının avcısı, doğancı adayı | Orta |
| Han Xin (韓王信) | Han | SJ 93; HS 1, 33 | 201–196 | V: konuk yoldaş, müttefik komutan; 196'da ölür | Yüksek |
| Wang Huang (王黃) | Han, Baitu | SJ 93 | 201–196 | V: tüccar komutan, pazarlıkçı; konuk yoldaş | Yüksek kişi; sonu çelişik |
| Manqiu Chen (曼丘臣) | Han, Baitu | SJ 93 | 201–196 | V: Wang Huang'ın ortağı; ikili söyleşi | Yüksek kişi |
| Yan (衍), Zang Tu'nun oğlu | Yan | SJ 93 | ≈202–195 | V–VI: sürgün bey, Han işlerinde danışman | Yüksek kişi; yıl [çıkarım] |
| Zhang Sheng (張勝) | Yan | SJ 93 | 196–195 | VI: «Hu işlerini bilen» elçi, dilmaç | Yüksek |
| Lu Wan (盧綰) | Yan | SJ 93; HS 34 | 195–194 | VI: Tunghu Lu Kralı; bir yıl yoldaş, ölümü sahnedir | Yüksek |
| Tuidang (穨當) | Han-Hun | SJ 93; HS 33 | 201 sonrası doğar; 166 | VI: iki dilli genç, dilmaç; Han'a dönüşü sonsözde | Yüksek kişi; yaş [çıkarım] |
| Ying (嬰) | Han-Hun | SJ 93; HS 33 | Aynı | VI: Tuidang'ın yeğeni; ikili söyleşi | Yüksek kişi |
| Xi Huqian (係雩淺) | Hun | SJ 110 | 176 | VI: mektubu götüren elçi; yol ve dilmaç | Yüksek ad; kişilik [kurgu] |
| Jiyu (稽粥, Laoshang) | Hun | SJ 110 | 174'te tanhu | VI: veliaht oğul, son perde yoldaşı | Yüksek |
| Bujiu (布就翖侯) | Usun | HS 61 | ≈176 (oyun); 173 (Benjamin) | VI: bebek Kunmo'yu taşıyan lala; koruyucu | Orta: kişi [kaynak], Mete'ye bağlanış [kurgu] |
| Kunmo (昆莫, 獵驕靡) | Usun | SJ 123; HS 61, 96B | Bebek | VI: yoldaş değil, korunan çocuk | Yüksek kişi; tanhu tartışmalı |
| Huyan, Lan, Xubu soyundan bir bey | Hun | SJ 110; HS 94A | Mete çağı; Xubu belki sonra | III–VI: soylu danışman, yargıç | Orta |
| Sınırı yöneten soylu kadın | Hun | Science Advances 2023 | Hun çağı | V–VI: batı sınırında müttefik, konuk yoldaş | Orta grup; kişi [kurgu] |
| Ganfu (甘父) | Hun kökenli | SJ 123; HS 61 | 138–126 | Oyunda yok: avcı okçu yoldaşın kalıbı | Yüksek; dönem dışı |
| Zhonghang Yue (中行說) | Han | SJ 110 | 174 sonrası | Kullanılmaz: Laoshang'ın adamı | Yüksek; dönem dışı |

## Oyuna öneriler

1. **Sınır.** Yanında en çok 10 adlı yoldaş gezer (`party.max = 10`), Mete'yle on bir kişi. Sayı `army.md` S0'ın «≤10 adlı» kademesine ve onluğun 10 yuvasına (`s0`–`s9`) oturur. Oyuncu metni «Yoldaşlar / Companions», ordu dili «Mete'nin onluğu». On birinci katılımda «Kim kalsın?» kartı açılır; ayrılan Ordugâh'a (`own_camp`) gider, kaybolmaz. Ordugâhta bekleyenin `ties`'i düşmez [kurgu].
2. **İki kademe.** `core` (çekirdek yoldaş): oyun boyunca en çok 12 kişi; el yazımı kişisel görev, kamp sahnesi, 6–10 ikili söyleşi, sahne sesi. `named` (adlı er): üretilmiş portre, `army.md` `trait`'i ve bir rol, 12–20 kısa söz, görev yok. İki kademe aynı kartı kullanır. Konuk yoldaş (`guest`): hikâyeye bağlı, yer tutar, gönderilemez, betikle ayrılır (Han Xin 196, Lu Wan 194) [kurgu].
3. **Katılma.** Dört yol: hikâye; ateş başında ant (`ties` ≥3 ve boş yer); kurtarma (tutsak ya da firari); armağanla tutulan yabancı usta (Usun at tüccarı gibi, perde başına mal). Söz ≥9'da yeni üyenin `ties`'i +2 başlar (`progression.md` §2.1) [kurgu].
4. **Bağ.** Yeni onay ölçeği yok: `ties.<id>` 0–10 ve birimin `loyalty`'si (`army.md` §3.4). Defter düğümü gösterir, sayı göstermez. Bağ değişimini yalnız olayı duyan alır: Mete'ye 40 m içindeki yoldaş (BG3 yakınlık kuralı; 40 m `ThreatEdge`'in tehdit yarıçapıyla aynı) [çıkarım].
5. **Ayrılık.** Koşul: `ties` ≤1 ve yoldaşın kırmızı çizgisi (her çekirdek yoldaşa bir değer: esire ok, ant bozmak, yağma). Önce iki uyarı: `ties` 3'te düğüm gevşer ve bir söz, 2'de ateş başında yüzleşme. Ayrılan halkına ya da Ordugâh'a gider; perde başına bir kez kişisel bir bedelle geri kazanılır. Çekirdek yoldaş sessiz gitmez, her ayrılık bir sahnedir. `korku` ≥14 ve `kut` <4 iken `pious` huylu adlı er ertesi şafak ayrılır (`army.md` §3.4 firar eşiğinin kişi yüzü) [kurgu].
6. **Ölüm ve yara.** Adlı er `progression.md` §12 kuralına uyar (Normal %30, Zor %50, `lead_carry` ×0,3) ve Ad İpi'ne geçer. Çekirdek yoldaş Düşüş zarı atmaz: düşerse taşınır, Yara +2 alır, bir oyun günü Otacı Yurdu'nda yatar; ölümü yalnız tarihin sahnesindedir. Yara sargıyla ya da otacıyla kapanır (DAO dersi). Bu, `progression.md` §11'deki «üye ölümü Düşüşte» kuralına sapmadır; gerekçe yazılmış görevin yarıda kalmamasıdır [kurgu].
7. **Söyleşi.** Binekte de söyleşi olur. Kural: savaşta, gizlilikte ve başka ses varken yok; aynı ikili için en az 6 gerçek dakika, genel olarak 4 dakikada bir; ateş başında gecede bir sahne, aynı yoldaşın kendi sahnesi iki oyun gününde bir. Sıra: kişisel görev adımı, son olaya tepki, ikili söyleşi. 45 ikilinin 12'si el yazımıdır, kalanı etiketli sözdür (`origin` × `trait` × olay) [kurgu].
8. **Kişisel görev.** Her çekirdek yoldaşın en az iki perdeye yayılan üç adımlı görevi olur. Ödül `ties` +2 ve bir beceri öğretmeni (`progression.md` kural 3: her beceriyi bir insan öğretir). Görev tarihe bağlanır: Loufan okçusunun 203 utancı, Bujiu'nun Kunmo'yu koruyuşu, Tuidang'ın Han'daki baba yurdu [kurgu].
9. **Rol.** Her yoldaşın bir rolü vardır; parti etkisi verir, aynı rol üst üste binmez, en iyisi sayılır. Öneri sayıları: avcı (`hunter`) av izi 80 m'den görünür; at terbiyecisi (`horse_master`) yoldaş atlarının yorgunluk kazancı ×0,9; kam (`shaman`) `skyRead` 6 saat; otacı (`healer`) Otacı Yurdu iyileşmesi %15 → %20; demirci (`smith`) kampta onarım ve günde +2 ok; iz sürücü (`tracker`) 60 m içindeki iz haritaya düşer; dilmaç (`interpreter`) Han ve Yüeçi ağzında ek seçenek; tüccar (`broker`) takas −%5; doğancı (`falconer`, IV'ten) 10 dakikada bir 300 m keşif; güreşçi (`wrestler`) toyda moral +4; ozan (`bard`) ateş başında moral +1/dk ek; okçu ve mızrakçı savaş rolüdür. Anahtarlar `progression.md` §4.11 diline yazılır [kurgu].
10. **Buyruk.** Grup buyrukları `army.md` §6.1'dir (Z izle, X kal, V akın, R ıslık, B düzen). Tek kişi: karta sol tık o yoldaşı çağırır (`to_sound` Mete'ye), sağ tık rol işini ya da «Kal»ı açar. Oyun kolunda Buyruk Halkası'na kişi sekmesi eklenir. Gizlilik bölgesinde en çok 3 yoldaş izler, kalanı bölge kenarında `hold`'a geçer; izleyenler saldırmadıkça nöbet algısına girmez (The Last of Us dersi) [kurgu].
11. **Düzen.** Atta `army.md` kaması varsayılandır. Yerleşimde yeni gevşek düzen (`loose`): Mete'nin ardında iki yay, 2,4 m'de 4 yuva ve 4,2 m'de 6 yuva, 150° açı, ±0,4 m titreme; durunca 4 sn'de bir yeniden örneklenir, yoldaş Mete'ye ya da yakındaki ilgi noktasına bakar. 6 m'den dar yolda kol (`column`): yaya 1,8 m, atlı 4,2 m aralık. Düzen değişiminde Macar ataması, dönüşte açgözlü atama [kurgu].
12. **Takip ve yetişme.** `army.md` §5.4 merdiveni aynen. Ek: yuvaya 25 m'den uzaksa hız ×1,25 (`vMax` sınırında); 60 m'den uzak ve 2 sn kadraj dışındaysa `nearestFree(yuva)`'ya sıçrar, aynı karede `set_velocity_forced()`; kadrajda asla sıçramaz. 300 m'den uzak ya da başka iç haritadaysa «geride kaldı» olur, `travelNet`'in sonraki durağında katılır. Mete binince yoldaşlar yuva sırasıyla 0,3–1,2 sn arayla biner, inişte de aynı [kurgu].
13. **Kaçınma.** İç haritada (kamp, yerleşim) `NavigationAgent3D` kaçınması açık: yarıçap yaya 0,45 m, atlı 1,1 m; `neighbor_distance` yaya 6 m, atlı 12 m; `max_neighbors` 6; `time_horizon_agents` 0,8 sn, `time_horizon_obstacles` 0,4 sn; `avoidance_priority` Mete 1,0, yoldaş ve NPC 0,5. Mete kaçınmaya yalnız kaçınan ajan olarak kaydedilir, yoldaş ondan kaçar. Hedef 4 Hz'de yenilenir; `path_max_distance` yaya 2 m, atlı 4 m. Açık bozkırda kaçınma kapalı, `army.md` itmesi (`SEP_R` 2,2 / 1,2 m) yeter [kurgu].
14. **Çizim bütçesi.** Yoldaş partisi için T0 atlı tavanı 4'ten 11'e çıkar (Mete + 10); yaya yoldaş 16 kişilik T0 tavanına sayılır. Canlandırma kademesi: kadrajda ve ≤30 m tam hız; kadrajda 30–60 m 30 Hz (birikmiş `delta` ile `advance`); kadraj dışında 10 Hz; kadraj dışında ve 60 m ötede T1 `MultiMesh` ya da yalnız kinematik. Kabul: iç haritada GDScript ≤4 ms (`godot.md` §7.2), `g0` taban ölçümünde sınanır; tutmazsa 30 m ötesi T1 olur [kurgu].
15. **Kart.** Yoldaş Kartı / Companion Card: 1080p'de 56 px çaplı daire (`UIKit.ui_k()` ile ölçeklenir); ayar Küçük 44, Orta 56, Büyük 72 px. İçte 50 px portre, 3 px halka. Halka `GOLD_DIM` (#7d6236) olağan, `GOLD` (#d9b56c) konuşurken ya da seçiliyken. Kartın sağ altında (saat 4 yönü) 16 px durum rozeti, biçimi durumu söyler, renk ektir: çapraz kılıç savaşta (`EMBER` #ff8a3d), damla yaralı, kırık halka kayıp, kare bekliyor, üç nokta konuşmak istiyor, yatık sancak düştü (`CRIMSON` #d0343f). Yazı en az 18 px (XAG 101, PC), Alegreya, `PARCHMENT` üstünde gölge [kurgu].
16. **Ne zaman çıkar.** Kart, yoldaşın göğüs noktası (yerden 1,2 m) kenardan %4 içeride çizilen dikdörtgenin dışına 0,25 sn kalınca çıkar; %8 içeri girince kaybolur (gecikme ve histerezis titremeyi keser). Kadrajda olup görüşü 1 sn kapalı kalan yoldaşa kenar kartı değil, başının üstünde 36 px'lik yerinde işaret konur; görüş sınaması projenin görüş hattı yardımcısıyla 5 Hz'dedir (`godot.md` §1) [kurgu].
17. **Yer.** Kart merkezi yuvarlatılmış iç dikdörtgende durur: 1080p'de yanlardan 64 px, üstten ve alttan 60 px (kart kenarı ekrandan 36 ve 32 px), köşe yarıçapı 96 px. Bu pay, `DisplayServer.get_display_safe_area()` ve ayardaki TV payı (%0–5; %5'te 96 ve 54 px + yarıçap) ile büyür, hiç küçülmez. Yön çapası ekran merkezidir (Mete orada). HUD'un ayrılmış dikdörtgenleri (sol alt ipucu paneli, beceri çubuğu) yasak bölgedir; kart kenar boyunca bölgenin dışına kayar [kurgu].
18. **Yön ve uzaklık.** Halkanın dışında 10 px'lik üçgen çentik kartın çevresinde döner, yoldaşı gösterir. Boy ve saydamlık uzaklıkla azalır: 30 m'de 56 px ve %100, 150 m'de 44 px ve %75, arası doğrusal. Sayısal uzaklık yalnız 60 m ötede, kayıpta ya da tuş basılıyken yazar, 10 m'ye yuvarlanır («120 m»). Kameranın arkasındaki hedef §2.4'teki zemin yönüyle ters çevrilir [kurgu].
19. **Kümelenme.** İki kartın merkezleri kenar boyunca 64 px'ten yakınsa (çapın 1,15 katı) kümelenir, 80 px'te ayrılır. Kümede en yakın yoldaş üstte, en çok üç portre 14 px kaydırmayla yelpaze olur; dördüncüden sonra tek küme kartı: üstteki portre ve «+N». Tehdit okları kartı her zaman yener: tehdit okuna 64 px'ten yakın kart kenar boyunca en çok 80 px kaçar, kaçamazsa %50 saydamlaşır [kurgu].
20. **Geçiş süreleri.** Çıkış: 0,20 sn solma ve izdüşüm noktasından kenara 0,15 sn kayma (yavaşlayarak). Kayboluş: 0,20 sn. Kenar boyunca hareket üstel yumuşatmayla, keskinlik 12/sn (zaman sabiti ≈0,08 sn), açısal hız en çok 540°/sn. Kümeleşme ve ayrılma 0,18 sn. Kayıp ve düşmüş kart 1 Hz'de nabız atar; 3 Hz'den hızlı yanıp sönme yok [kurgu].
21. **Godot yapısı.** `CompanionEdge` (`Control`), `GameHud`'ın `CanvasLayer`'ında, `ThreatEdge`'in yanında. Konum her kare, kadraj sınaması 30 Hz. Kart `Panel` + `StyleBoxFlat` (yarıçap 28) + `clip_children = CLIP_CHILDREN_ONLY` + `TextureRect`; gölgelendirici yedek yoldur. `edge_point` ve `is_on_screen` saf durağan işlevdir, `follow_camera.gd` gibi birim testlidir: `tests/unit/test_companion_edge.gd` arkadaki hedefi alta, soldakini sola koyar; 63 px'te kümeler, 81 px'te ayırır [kurgu].
22. **Portre.** `PortraitBaker`: `SubViewport` (`own_world_3d`, saydam arka plan, `UPDATE_ONCE`), yoldaşın `CharacterAvatar`'ını göğüsten yukarı çizer, 256 × 256 doku önbelleğe girer (10 portre ≈2,5 MiB). Görünüş değişince (yara bezi, şapka, perde kılığı) yeniden çizilir. El boyası portre gelirse aynı yuvayı kullanır; çekirdek yoldaşa boyalı, adlı ere çizilmiş portre [kurgu].
23. **Ayarlar ve harita.** `[game]` bölümüne: `companion_edge` (`on`, `combat`, `off`; varsayılan `on`), `companion_card_size` (44, 56, 72), `companion_distance_text` (`far`, `always`, `off`), `hud_safe_margin` (%0–5), `companion_banter` (`few`, `normal`, `many`). Harita'da yoldaş 32 px portre iğnesidir. Defter'e «Yoldaşlar / Companions» sekmesi girer: on kart, düğüm, rol, yara, görev adımı. Köpek ve kuş yer tutmaz, kartları 40 px ve simgelidir [kurgu].
24. **Tarihî kadro.** I: `first_ten`'den 2–3 çekirdek (Uldın, Berik). II: ıslık talimindeki adlı erler. III: Tunghu tutsağı iz sürücü. IV: Loufan okçusu, Baiyang atçısı, Dingling avcısı. V: Wang Huang ve Han Xin konuk, Zang Tu'nun oğlu Yan danışman. VI: Lu Wan (bir yıl), Zhang Sheng, Tuidang ve Ying, Xi Huqian, Bujiu ve bebek Kunmo, veliaht Jiyu. Sevdiği eş yoldaş olmaz: oyuncunun yoldaşını kendi okuna hedef yapmak hile gibi okunur; sahne kişisi kalır [kurgu].

## Belirsizlikler

- **Kunmo.** SJ 123'te babayı Hun, HS 61'de Büyük Yüeçi öldürür. Hangi tanhunun büyüttüğü yazmaz; oyun 176'yı ve Mete'yi alır (`mete-tarih.md`) [kurgu]. Bujiu'nun Mete'yi görüp görmediği bilinmez.
- **Loufan okçusu.** SJ 7'deki «樓煩» bir kişinin halk adı mı, okçu lakabı mı, belli değildir. 應劭 yalnız «樓煩胡也» der. Hun'a geçtiğine dair kaynak yoktur.
- **Wang Huang.** SJ 93 iki ayrı son yazar. Hangisinin oynanacağı senaryonun seçimidir.
- **Tuidang'ın yaşı.** 201 sonrası doğar; 192'de en çok 9 yaşındadır (`mete-tarih.md` §6.1). VI'nın yıl sıçramasında genç yetişkin olur [çıkarım].
- **Xubu.** 其後有須卜氏: soy Mete'den sonra yükselmiş olabilir.
- **İşlerin çağı.** Kam, otacı, demirci ve dilmaç tanıkları Mete'den 100–150 yıl sonradır; Pazırık önce gelir ve Hun değildir. Görünüş ve iş için ödünç alınır, olay için kanıt sayılmaz.
- **Doğancı ve ozan.** Kuşçuluk ve telli lavta için dönem kanıtı yoktur.
- **Kadın mezarları.** Bulgu batı sınırının iki mezarlığından ve küçük örneklemdendir (19 kişinin 17'si). Mezarların tam tarihi bu turda görülmedi.
- **Oyun örnekleri.** Fandom 402, birkaç forum 403 verdi. DOS2, Warband, Kenshi ve DAI sayacı topluluk kaynaklıdır. BG3 eşikleri yamalarla değişebilir.
- **Kenar matematiği ve sayılar.** Arkadaki hedefin zemin yönü, kart boyu, paylar ve süreler denenmedi. Kamera ön ayarları (atlı, Bakış) Godot'da henüz yoktur (`godot.md` §5.7); gelince §2.3 yeniden hesaplanır.
- **Bütçe.** T0 atlı tavanının 11'e çıkması `godot.md` §7.2 ile çelişir; ölçümden önce karar verilemez.
- **Serbest Gez.** Çocuk kipinde yoldaş yoktur; istenirse çocuk oyun arkadaşı ayrı tasarlanır.
- **Erişim.** DST, PlayMaker, Oxide, Wedge ve Kexingzhuang bilgisi arama özetidir.

## Kaynaklar

**Birincil (zh.wikisource).**
- [Shiji 7](https://zh.wikisource.org/wiki/史記/卷007), [Shiji 7 üç yorumla](https://zh.wikisource.org/wiki/史記三家註/卷007), [Shiji 93](https://zh.wikisource.org/wiki/史記/卷093), [Shiji 110](https://zh.wikisource.org/wiki/史記/卷110), [Shiji 110 üç yorumla](https://zh.wikisource.org/wiki/史記三家註/卷110), [Shiji 123](https://zh.wikisource.org/wiki/史記/卷123)
- [Hanshu 31](https://zh.wikisource.org/wiki/漢書/卷031), [Hanshu 33](https://zh.wikisource.org/wiki/漢書/卷033), [Hanshu 34](https://zh.wikisource.org/wiki/漢書/卷034), [Hanshu 54](https://zh.wikisource.org/wiki/漢書/卷054), [Hanshu 61](https://zh.wikisource.org/wiki/漢書/卷061), [Hanshu 94A](https://zh.wikisource.org/wiki/漢書/卷094上), [Hanshu 96A](https://zh.wikisource.org/wiki/漢書/卷096上), [Hanshu 96B](https://zh.wikisource.org/wiki/漢書/卷096下)

**Oyun tasarımı.**
- [bg3.wiki, Approval](https://bg3.wiki/wiki/Approval); [Fextralife, Companion Approval](https://baldursgate3.wiki.fextralife.com/Companion+Approval); [The Loadout, BG3 party size](https://www.theloadout.com/baldurs-gate-3/party-size) (arama özeti)
- [Wikipedia, Dragon Age: Origins](https://en.wikipedia.org/wiki/Dragon_Age:_Origins); [GameBanshee, DAO injuries](https://gamebanshee.com/dragonageorigins/injuries.php) (arama özeti); [BioWare blogu, banter ve müzik](https://blog.bioware.com/?p=10350) (arama özeti); [Fextralife, DAI Party Banter Guide](https://dragonage3.wiki.fextralife.com/Party+Banter+Guide) (arama özeti)
- [Game Informer 2018, Sawyer](https://gameinformer.com/b/news/archive/2018/05/07/pillars-of-eternity-ii-director-on-fan-feedback-publishers-and-genre-evolution.aspx); [GameBanshee, Deadfire önizleme](http://www.gamebanshee.com/k4whp); [RPGSite 2017, Deadfire ilişkileri](https://www.rpgsite.net/news/5303-obsidian-sheds-light-on-how-companion-relationships-will-work-in-pillars-of-eternity-ii-deadfire)
- [Wikipedia, Mass Effect 2](https://en.wikipedia.org/wiki/Mass_Effect_2)
- [GamerGuides, Bannerlord yoldaşları](https://gamerguides.com/mount-and-blade-ii-bannerlord/guide/introduction/character-development/companions); [GameBanshee, Bannerlord boy ünü](https://www.gamebanshee.com/kccy3); [Raider King, Warband yoldaşları](https://raiderking.com/mount-and-blade-warband-companions-guide/) (arama özeti)
- [Nexus, Kenshi mod 368](https://www.nexusmods.com/kenshi/mods/368) (arama özeti); [Steam, DOS2 zincir](https://steamcommunity.com/app/435150/discussions/0/1630790506928670517) (arama özeti)
- [Killscreen, Ellie](https://www.killscreen.com/how-ellies-pathfinding-made-you-love-her/); [Game Developer, Ellie GDC 2014](https://gamedeveloper.com/design/video-ellie-s-buddy-ai-in-i-the-last-of-us-i-); [GDC Vault](https://gdcvault.com/play/1020364/Ellie-Buddy-AI-in-The)
- [Game Developer, The AI of DOOM (2016)](https://www.gamedeveloper.com/design/cyber-demons-the-ai-of-doom-2016-); [Pottinger, Implementing Coordinated Movement](https://www.gamedeveloper.com/programming/implementing-coordinated-movement)

**Arayüz ve erişilebilirlik.**
- [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101); [XAG 101, devdocs](https://devdocs.xbox.com/gaming/accessibility/xbox-accessibility-guidelines/101) (arama özeti)
- [GAG, renk](https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-colour-alone/); [GAG, arayüz boyu](https://gameaccessibilityguidelines.com/allow-interfaces-to-be-resized/)
- [Microsoft Learn, Xbox ve TV için tasarım](https://learn.microsoft.com/zh-cn/windows/uwp/design/devices/designing-for-tv) (arama özeti); [Windows blogu 2016](https://blogs.windows.com/windowsdeveloper/2016/09/09/tailoring-your-app-for-xbox-and-the-tv-app-dev-on-xbox-series/)
- [Wedge, Manitoba](https://hci.cs.umanitoba.ca/Publications/details/wedge-clutter-free-visualization-of-off-screen-locations); [dblp](https://dblp.org/rec/conf/chi/GustafsonBGI08) (arama özeti)
- [Klei, DST oyuncu göstergesi](https://forums.kleientertainment.com/klei-bug-tracker/dont-starve-together/player-indicators-use-outdated-images-r28677/) (arama özeti); [Oxide, Off-Screen Marker](https://hyperhug.theymes.com/hc/en/oxide/articles/what-is-the-off-screen-marker-and-how-do-i-track-clanmates-on-screen-111) (arama özeti); [Icy Veins, Diablo IV](https://wp-prod.icy-veins.com/this-change-in-diablo-4-could-fix-one-of-co-ops-most-annoying-moments/); [PlayMaker, Offscreen Indicator](https://docs.hutonggames.com/guides/ui-widgets/target-managers/offscreen-indicator/) (arama özeti)

**Godot.**
- [Camera3D](https://docs.godotengine.org/en/stable/classes/class_camera3d.html), [CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html), [SubViewport](https://docs.godotengine.org/en/stable/classes/class_subviewport.html), [NavigationAgent3D](https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html), [Using NavigationAgents](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html), [AnimationMixer](https://docs.godotengine.org/en/stable/classes/class_animationmixer.html), [VisibleOnScreenEnabler3D](https://docs.godotengine.org/en/stable/classes/class_visibleonscreenenabler3d.html)
- [DisplayServer.xml yansısı](https://remotebranch.eu/Stowage/godot/raw/commit/c6297f46fe236abbd6c6b06bb9b6bfaa239b49a5/doc/classes/DisplayServer.xml) (arama özeti); [Godot forumu, kenar göstergesi](https://forum.godotengine.org/t/putting-an-indicator-on-the-edge-of-the-screen-for-an-off-screen-target/29020) (arama özeti); [Godot forumu, kalabalık](https://forum.godotengine.org/t/performance-of-crowds-of-animated-rigged-characters-in-3d/130409) (arama özeti); [r/godot, AnimationTree](https://lr.sudovanilla.org/r/godot/comments/1fivfwd/animation_tree_killing_fps) (arama özeti)
- [RVO, GAMMA](https://gamma.cs.unc.edu/RVO); [ICRA 2008 PDF](https://www.cs.unc.edu/~geom/RVO/icra2008.pdf)

**Arkeoloji ve modern çalışma.**
- [Wikipedia, Pazyryk culture](https://en.wikipedia.org/wiki/Pazyryk_culture); [OAM Berlin, erken göçerler](https://depts.washington.edu/silkroad/museums/oam/nomads.html); [Christopoulos, Kexingzhuang](https://mongolschinaandthesilkroad.blogspot.com/2016/04/sino-platonic-papers-number-260.html) (arama özeti)
- [Harvard Gazette 2023](https://news.harvard.edu/gazette/story/2023/04/dna-shows-poorly-understood-empire-was-multiethnic-with-strong-female-leadership/); [Max Planck 2023](https://www.mpg.de/20098860/0403-evan-mongolia-s-first-nomadic-empire-150495-x)
- [İran kuşçuluk kaya resimleri](https://www.falconryheritage.org/uploads/itemUploads/11853/Falconry_petroglyphs_in_Iran.pdf) (arama özeti)
- [Wikipedia, Modu Chanyu](https://en.wikipedia.org/wiki/Modu_Chanyu) (Beckwith 2009); [Wikipedia, Chanyu](https://en.wikipedia.org/wiki/Chanyu); [Wikipedia, Xiongnu language](https://en.wikipedia.org/wiki/Xiongnu_language)

**İç belgeler.** `docs/research/mete-tarih.md`, `oyun-seviye-tasarimi.md`, `hayvanlar.md`, `kopuz.md`, `research/progression.md`; `docs/design/army.md`, `progression.md`, `act1.md`, `godot.md`, `d3/register.md`. Kod: `game/scripts/player/follow_camera.gd`, `game/scripts/ui/ui_kit.gd`, `game_hud.gd`, `creator_baked_rect.gd`, `game/scripts/settings/game_settings.gd`.

## Doğrulama

**Tarih:** 2026-11-04. **Sınanan iddia: 12.** Yöntem: belgenin en çok yük taşıyan on iki iddiası ilk kaynaktan bağımsız ikinci bir kaynakla açıldı. Çince iddialarda ikinci kaynak ayrı bir kitaptır (Hanshu ya da başka bölüm); Hanshu bu dönemi büyük ölçüde Shiji'den aktardığı için bu, metnin ikinci tanığıdır, olayın bağımsız tanığı değildir. Oyun ve arayüz iddialarında ikinci kaynak ayrı bir sitedir.

| # | İddia | Birinci | İkinci | Sonuç |
|---|---|---|---|---|
| 1 | Yirmi dört baş kendi binbaşı, yüzbaşı, onbaşısını atar | SJ 110 | HS 94A | Doğru; HS listeyi uzatır |
| 2 | Usun bebeği Kunmo'yu tanhu büyüttü | SJ 123 | HS 61 | Doğru; babanın katili ayrışır, lala yalnız HS'de |
| 3 | Lu Wan 東胡盧王 oldu, bir yıl sonra öldü | SJ 93 | HS 34 | Doğru |
| 4 | Tuidang ve Ying Hun ülkesinde doğdu, Wen döneminde Han'a geçti | SJ 93 | HS 33 | Doğru; 166 yılı yalnız SJ 93'te |
| 5 | Ganfu Hun kökenli okçuydu, av vurup erzak sağladı | SJ 123 | HS 61 | Doğru |
| 6 | Han ordusunda Loufan adlı atlı okçu Xiang Yu'dan kaçtı | SJ 7 | HS 31 | Doğru; lakap açıklaması düzeltildi |
| 7 | Hun kamları (巫) lanet töreni yaptı | HS 96B | HS 94A | Doğru; iki ayrı olay, MÖ 90–89 |
| 8 | Batı sınırı mezarlıklarında en zengin mezarlar kadınların | Harvard Gazette | Max Planck | Doğru; biri «araba», öteki «yarım savaş arabası» der |
| 9 | PoE II partiyi yönetim ve savaş için beşe indirdi | Game Informer | GameBanshee | Doğru |
| 10 | BG3'te −50'de ayrılık; uzaktaki ve kamptaki onay almaz | bg3.wiki | Fextralife | Doğru; −50 sayısı yalnız bg3.wiki'de |
| 11 | XAG 101: 1080p'de PC 18 px, konsol 26 px | Microsoft Learn | devdocs (arama özeti) | Doğru |
| 12 | Godot kaçınması RVO'dur; çok ajanda bedeli büyüktür | Sınıf başvurusu | Navigasyon öğreticisi | Doğru; öğretici bedeli komşu sayısına bağlar |

**Yapılan düzeltmeler.**
1. «Han ordusunda okçulara Loufan denirdi» cümlesi kalktı: 集解'de yalnız 應劭'nun «樓煩胡也» notu vardır. Lakap okuması [çıkarım] oldu.
2. Tuidang ve Ying'in Han'a geçiş yılı (166) yalnız SJ 93'tendir; HS 33 «至孝文時» der ve adı 頹當 yazar.
3. Wang Huang'ın sonu SJ 93 içinde çelişir; tablo iki okumayı da not eder.
4. 胡巫 sözü HS 96B'de yoktur; orada 巫 geçer. 胡巫 HS 94A'dadır.
5. 撐犁 ve 孤塗 Wikipedia'nın Hun dili sayfasında yoktur; dayanak SJ 110 索隱'nin Hanshu aktarmasıdır (Vikikaynak 𢴤黎 basar).
6. Vikikaynak SJ 93 臧荼'yu 臧茶 basar; oğlunun adı metinde yalnız 衍'dır. `mete-tarih.md`'deki «臧衍» proje içi biçimdir.
7. HS 61'in Vikikaynak metni 翎侯 basar; `mete-tarih.md` gereği 翖侯 yazıldı.
8. Kexingzhuang güreşçi levhasının Hun'a bağlanması tartışmalı bulundu; güreşçi dayanağı OAM Berlin'in Ordos levhasına indi.
9. TV güvenli alanında blog «piksel», Learn «etkin piksel» der; 1080p karşılığı 96 ve 54 px yazıldı.
10. BG3 uyarı eşikleri: bir arama özeti −25 dedi; bg3.wiki'nin −20 ve −40'ı esas alındı.
11. Örnek olarak düşünülen iki iddia doğrulanamadı ve belgeye girmedi: Skyrim'de uzaktaki yoldaşın ışınlanması (UESP'de görülmedi) ve RDR2'de binicinin hızına uyma düğmesi.

**Bu dosyanın dışında kalanlar** (değiştirilmedi): `godot.md` §7.2 T0 atlı tavanı 4 (öneri 14 ile 11); `progression.md` §11 ve §12 Düşüş'te üye ölümü (öneri 6 ile çekirdek yoldaş muaf); `army.md` §4'e `loose` ve `column` düzeni; `godot.md` §5.4'e `CompanionEdge`.
