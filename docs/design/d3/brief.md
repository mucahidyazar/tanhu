# Üçüncü tur brifi: kararların yönü (2026-11-04)

`register.md` kullanıcının cevaplarını kelimesi kelimesine saklar. Bu dosya, kullanıcının bana bıraktığı yerlerde verdiğim tasarım kararlarını yazar. Bağlayıcı metin `decisions.md`'ye K29'dan başlayarak girer; bu dosya o metnin kaynağıdır.

## Hedef: Godot

- Oyun **Godot 4.7** ile `game/` klasöründe yapılır (eski Tanhu 3, artık adı «Tanhu»). Kullanıcı: «bunu tanhu-3 godot projesi için yapıyoruz unutma».
- Three.js prototipi (`~/Code/tests/tanhu-programatic-test`) yalnız tasarım ve ölçüm kaynağıdır. `architecture.md` ve `contract-requests.md` prototipin belgeleridir; Godot'un uygulama planı `godot.md`'dir.
- Godot'da varlık üretimi serbesttir: Meshy hattı (`game/tools/meshy_pipeline.py`) zaten kuruludur. Prototipin «Blender ve Meshy çağrılmaz» kuralı Godot'a geçmez. Kredi harcayan her üretim önce kullanıcıya sorulur.
- Oyunun bugünkü hâli: `d3/oyun-durumu.md`.

## Belge üstünlüğü (#65)

`decisions.md` > `d2/core.md` (alanlar arası ortak sayılar) > alan belgeleri (`act1.md`, `story.md`, `economy.md`, `structures.md`, `settlement.md`, `progression.md`, `travel.md`, `time.md`, `weather.md`, `army.md`, `survival.md`, `audio.md`, `fauna.md`) > `godot.md` (uygulama). Sayı ve oyun kuralı alan belgesinden, uygulama biçimi `godot.md`'den okunur. `architecture.md` yalnız prototip içindir. `d3/` ve `d2/` taslak ve deltaları izdir.

## Perde adları (#5)

Tanhu 1'in adları (Umay'ın Görüsü, Rehine, Islıklı Ok, Bin Li At, Batı Rüzgârı, Ak Dağ, Eksik Görü, Ozanın Sesi) kullanılmaz. Ortak olan yalnız perde perde yapı ve Mete'nin hayatıdır.

| Bölüm | Ad | EN | Neden bu ad |
|---|---|---|---|
| Önsöz | Kopuz Söyler | The Kopuz Sings | Ozan kopuzuyla mitolojiyi anlatır, anlatı Mete'nin doğumuna varır |
| Çocukluk | Koyun Sırtında | On a Sheep's Back | Shiji 110: Hun çocuğu koyuna biner, yayla kuş ve fare vurur |
| I | Çan | The Bell | Rehinenin ayağındaki çan; perde çanla açılır, ıslıkla kapanır |
| II | Ok Neyi Gösterirse | Where the Arrow Points | Islıklı okun emri: ok neyi gösterirse herkes ona atar |
| III | Boş Toprak | The Empty Land | Tunghu'nun üçüncü isteği; «Toprak devletin temelidir» |
| IV | Borç | The Debt | I. Perde'de güven borca dönmüştü; IV'te borçlar ödenir, Kışlak'a dönülür |
| V | Dört Renk | Four Colours | Baideng: Han ordusunu dört renk at çevirir (Shiji 110) |
| VI | Sayım | The Count | I. Perde'de Palak rehineyi sayar; VI'da Mete halkını sayar |
| Sonsöz | Kopuz Susar | The Kopuz Falls Silent | Ozanın anlatısı biter |

## Hikâye ilkeleri

- Hikâye doğumdan başlar (KB 6, bebeklik notu). Önsöz tamamen sinemadır; Çocukluk kısa, oynanan bir sahnedir; I. Perde rehineliktir.
- **Tarih kesindir (#1).** Kaynağı olmayan tarihler oyunda kesin tarih gibi söylenir, Destan Kitabı'nda işaretlenmez. Doğum MÖ 234; gün `story.md`'de seçilir. Bütün olaylar tek takvimde, `time.md` §2 sayacıyla.
- **Mitoloji geniştir (#8).** Yalnız Tengri, Erlik ve Umay değil: kaynak `docs/research/mitoloji.md`. Mit ozanın sesidir; geç tanıklıklar (Altay derlemeleri, Göktürk yazıtları) ozan anlatısı olarak kullanılır. Tanrılar az konuşur, görünmeyenler görünmez.
- **Perde son görevle biter (#19).** Sayaç yok. K25'in gün bütçesi yalnız tasarım ölçüsüdür.
- **Tarih akar (not 9).** Takvim tek sayaçtır. Perde bitince Serbest Dolaşım açık kalır, takvim akar; oyuncu dilediğinde «Kronik'e bırak» der, Akan Kronik (30–90 sn, atlanabilir) aradaki yılları ay ay gösterir. 1 oyun günü 60 gerçek dakika kalır.
- **Açık dünya (not 8).** I. Perde kısıtlıdır (vadi, kefil, Kızıl Kazık). II'den sonra özgürdür. Görevlere gidilir: ana zincir, yan görev aileleri, keşif durakları; görev verici ve harita iğnesi.
- **Unvan (#35).** Oyuncuya «Tanhu», ülke «Hun Tanhuluğu», merkez «Tanhu Avlusu». «Kağan» ve «hanlık» oyuncu metninde geçmez.

## Sistem kararları

- **Kamera (#12, #17, #18, not 7).** Varsayılan Diablo tarzıdır: Godot'daki takip kamerasının bugünkü açısı (eğim ≈23°, uzaklık 27 m; 2026-11-07, K98 ile 38°, görüş 36°, 28 m). Oyuncu kamerayı 360° döndürür, eğimi bir bantta değiştirir, 6–40 m arasında yakınlaştırır (K98: 14–40 m); tek tuş varsayılana döndürür. Dönüş hızı ve fare hassasiyeti ayardır, tuşlar yeniden atanır ve kaydedilir. I. Perde'nin kadraj sözleşmesi kameraya bağlı değildir: kadraj dışındaki tehdit ekran kenarında okla ve sesin yönüyle okunur; kovalamacada döndürme açıktır.
- **Yurt süresi (not 1, K21'in yerine).** `T(n) = taban × 0,75^(n−1)`, n en çok 8 el (8'in üstü 8 sayılır). Hane Yurdu tabanı 60 dk: 60 / 45 / 33,75 / 25,3 / 19,0 / 14,2 / 10,7 / 8,0. Eğri yalnız inşaat ve sökümde geçerlidir; tezgâhlar eski `eff` ile kalır. camp3 ve Kışlak Yeni Yurdu bu eğriyle yeniden hesaplanır.
- **Yurt boyları ve milletler (#31, #32, not 10).** Üç boy: Küçük Yurt ×0,7, Hane Yurdu ×1, Otağ ×1,4 (kaynak `docs/research/cadir-otag.md`). Dış görünüş millete göre değişir (Hun, Yüeçi, Saka, Usun, Tunghu, Çiang, Han), iç düzenler ayrı adlarla tutulur.
- **Para (not 2).** I. Perde'de para yoktur, Terazi ile takas sürer (Mete rehinedir). II. Perde'den görünür bir para birimi gelir; adı ve oranı `docs/research/bozkir-ekonomi.md`'den. Kıymet ölçeği değişmez.
- **Dünya (#14).** 75.000 km². 1.500 km² kalkar. Harita yürünmez, oynanan yerler iç haritalardır.
- **Haritadan oyuna (#10, not 4).** Yüklü iç haritada en yakın düzeyde harita kapanır, kamera oyun kamerasına karışır, oyun sürer; M gerekmez. Başka bir yere yakınlaşma 6 birimde durur, tıklayınca Yol Kartı açılır.
- **Tek gecelik kamp (not 11).** Gecelik Çadır ve döşek, II. Perde'den.
- **Savaştan malzeme (not 12).** I. Perde'den sonra savaş ganimeti; rastgele düşme yok.
- **Hayvanlar (ek istek).** At ve deve binek ve yük hayvanıdır; inek, koyun, keçi, geyik, köpek, kartal ve gereken bütün hayvanlar `fauna.md`'de.
- **Gelen haneler (#39).** İki tür: çadırını ve eşyasını at ya da deveye yükleyip gelen; çadır isteyen.
- **Ordugâh baskını (#43).** Ordugâh baskına uğrar, ama akın küçüktür, seyrektir ve kolay def edilir.
- **Araba (#48).** Araba Plan Kipi'nde ayrı bir kartla seçilir.
- **Ozanın çalgısı (#54, #55).** Kopuz: telli, mızrapsız, parmakla çalınan uzun saplı çalgı. Yaylı çalgı «kobuz» değil «ıklığ/kıl kobuz» diye ayrı yazılır (adı `docs/research/kopuz.md`'den). «Dombra» yalnız Kazak çalgısının adı olarak kalır, oyunda geçmez.
- **Şarkı (#57, #58).** Bugünkü çekim kopuza ve ozanlığa benzemiyor. Tarif `kopuz.md`'deki bulgularla yeniden yazılır, yeni çekim alınır.
- **Seslendirme tavanı yok (#56).** 45.000 tavanı kalkar; harcama sayaçla izlenir.
- **Hayvan ve varlık üretimi.** Her varlık için en mantıklı yol `docs/research/varlik-hatti.md`'den: Programatik, Meshy, Blender MCP, Tripo ya da yalnız 2B.

## Soru olmayanlar (#15, #16 ve benzerleri)

Ölçüm ve yapılacak iş soru olarak tutulmaz: ilgili belgeye kural ya da hedef olarak yazılır, iş İlerleme sayfasına girer.
