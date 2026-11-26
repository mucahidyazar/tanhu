# Sayfa yazım kuralları

Bu klasördeki sayfalar oyunun sahibi için yazılır. O sayfaları okuyacak, yanlış ya da eksik gördüğünü not alacak ve düzeltecek. Sayfalar `docs/design` ve `docs/research`'teki uzun belgelerin okunur özetidir; onların yerine geçmez, onlara bağlanır.

## Dosya

`content/pages/<kategori>/<sayfa>.md`. Başında şu ön bilgi durur:

```yaml
---
title: Zaman ve Takvim
order: 40
status: kismen
summary: Bir oyun günü 60 gerçek dakikadır; takvim gerçek tarihle akar.
sources:
  - docs/design/time.md
  - docs/design/d2/core.md
---
```

- `title`: sayfanın adı, kısa. Sayfanın gövdesine ayrıca `# başlık` yazma; başlık uygulamadan gelir. Gövde `##` ile başlar.
- `order`: kategori içi sıra.
- `summary`: tek cümle; sayfa ne söylüyor.
- `sources`: yararlanılan belgeler.
- `status`: dört değerden biri:
  - `oyunda`: oynanabilir hâlde var.
  - `kismen`: bir kısmı oyunda ya da kodu yazıldı.
  - `tasarim`: tasarlandı, kodu yok.
  - `yeni`: kullanıcı istedi, henüz tasarımı yok.

## Sayfanın yapısı

Sabit şablon yok, konuya göre kur. Çoğu sayfada şu sıra iyi gider:

1. İki üç cümleyle konunun özü, sade sözlerle: oyuncu ne görür, ne yapar.
2. Kullanıcının bu konudaki kendi notu (aşağıdaki `[!NOT]`).
3. Kurallar ve sayılar: başlıklar ve tablolar.
4. Oyunda şu an ne var (`[!DURUM]`).
5. Çelişkiler, açık sorular, öneriler.
6. `## Kaynaklar`: belgelere bağlantı listesi.

Uzunluk: bir sayfa 60–250 satır. Her ayrıntıyı taşıma; oyunu anlamaya ve karar vermeye yarayanı seç, kalanı kaynağa bağla. Kod ayrıntısı (dosya adı, işlev, sistem sırası, üçgen sayısı) `gelistirme/` dışındaki sayfalara girmez; zorunluysa tek cümle.

## Kutular

Şu beş kutu özel görünür. Blok alıntının ilk satırına etiketi yaz:

```markdown
> [!NOT]
> «Hava durumları olacak»

> [!CELISKI]
> Notun 1.500 km² diyor, tasarım 75.000 km². ...

> [!ONERI]
> Boşluğu şöyle doldurabiliriz: ... Henüz karar değil.

> [!ACIK]
> Belgede karara bağlanmamış soru: ...

> [!DURUM]
> Oyunda: ... Kodda ama bağlı değil: ... Yok: ...
```

- `[!NOT]`: kullanıcının sözü, **yazıldığı gibi**, düzeltmeden. Başka hiçbir şey ekleme.
- `[!CELISKI]`: kullanıcının notu ile şu anki tasarım ayrışıyorsa: iki tarafı, kesin sayılarıyla yaz; not benimsenirse neyin değişeceğini söyle. Hangisinin doğru olduğuna karar verme; karar kullanıcınındır.
- `[!ONERI]`: tasarımda boşluk varsa somut öneri. Karar değildir, öyle görünmesin.
- `[!ACIK]`: belgelerin kendisinin açık bıraktığı, kullanıcının henüz cevaplamadığı soru.
- Çözülmemiş her `[!ACIK]` ve `[!CELISKI]` kutusu kendiliğinden «Karar Bekleyenler» sayfasında (`/docs/general/pending-decisions`) toplanır: ayrı bir açık sorular sayfası yoktur. Cevaplanan kutu sayfadan kalkar, karar metne ve K numarasına geçer.
- `[!DURUM]`: oyunda şu an ne olduğu.

## Dil

- Türkçe, tam diyakritikle (ı, ş, ğ, ç, ö, ü, İ). Ondalık virgülle: 33,75. Binlik noktayla: 75.000.
- Kısa, düz cümleler. Süs yok, övgü yok, «muhteşem», «güçlü», «derinlik katar» yok. Tire yerine nokta ya da iki nokta.
- Oyunun sözcükleri: Perde (Act), Yurt, Oba, Ozan, Kut, Korku, Kefil, Serbest Gez. Kısaltmayı ilk geçtiği yerde aç: İD (iş dakikası: bir işçinin bir oyun dakikası), İS (iş saati), İG (iş günü: 1.440 İD).
- Tasarım belgesindeki kimlikleri (`mq_sound`, `rc_meal`) gereksizce yazma; adını yaz. Gerekirse parantezde.
- Kararlara numarasıyla değin: K21, K27.

## Doğruluk

- Yalnız belgelerde yazanı yaz. Uydurma yok. Sayıları belgeden aynen al.
- Belgeler çelişirse sıra (K: belge üstünlüğü, #65): `docs/design/decisions.md` > `docs/design/d2/core.md` > alan belgeleri (`story`, `fauna`, `companions`, `act1`, `progression`, `economy`, `survival`, `structures`, `travel`, `army`, `audio`, `time`, `weather`, `settlement`) > `docs/design/godot.md` (Godot uygulaması). `architecture.md` yalnız Three.js prototipinindir. `d2/labour.md`, `d2/economy.md` ve `d2/*-delta*.md` yalnız izdir, kullanma. Çözemediğini `[!ACIK]` yap.
- Tanhu 1 yalnız ilhamdır: adları, kadrosu, perde adları kullanılmaz. Oyun artık Godot projesidir (`game/`, eski Tanhu 3); onun menü ve kamp metni kullanılabilir.

## Oyunda şu an

Oyun Godot 4.7 projesidir: `game/` (eski adı Tanhu 3). Bugünkü hâli `docs/design/d3/oyun-durumu.md`'dedir: menü ve canlı gece kampı, karakter oluşturucu, kayıt, ayarlar, Destan Kitabı, Serbest Gez, takip kamerası, boyalı görünüm, ses ve üretim hatları var; hikâye perdeleri, I. Perde'nin sistemleri ve açık dünya henüz yok. Three.js prototipinde (`~/Code/tests/tanhu-programatic-test`) denenenler yalnız «prototipte denendi» diye anılır, «oyunda» sayılmaz. Bir şeyi «oyunda» diye yazmadan önce `game/` içinde ara (`game/scripts`, `game/scenes`, `game/data`); emin değilsen «tasarımda, Godot'da henüz yok» de. Yapılan ve yapılacak işlerin listesi Yol Haritası'ndadır (`/roadmap`).

## Bağlantılar ve görseller

- Başka sayfa: `[Zaman ve Takvim](/docs/world/time-calendar)`.
- Kaynak belge: `[time.md](/docs/source/design/time)`, `[d2/core.md](/docs/source/design/d2/core)`, `[act1-script.md](/docs/source/research/act1-script)`.
- Türkçe adlı kaynak belgenin adresi İngilizce takma adıdır (dosya adı değişmedi): `bozkir-ekonomi.md` → `/docs/source/research/steppe-economy`, `cadir-otag.md` → `yurts-and-tents`, `hayvanlar.md` → `animals`, `mete-tarih.md` → `mete-history`, `mitoloji.md` → `mythology`, `oyun-seviye-tasarimi.md` → `game-and-level-design`, `sanat-animasyon.md` → `art-and-animation`, `ses-tasarimi.md` → `sound-design`, `varlik-hatti.md` → `asset-pipeline`, `yoldaslar.md` → `companions`, `d3/oyun-durumu.md` → `/docs/source/design/d3/game-state`. Bütün liste `docs-app/src/lib/legacy-ids.json`. Metinde `mete-tarih.md` gibi yazılan ad kendiliğinden doğru adrese bağlanır.
- Sitenin öbür sayfaları: Yol Haritası `/roadmap` (Perde > Faz > Madde; bölüm bağı perde ya da faz kimliğiyle: `/roadmap#act-1`), Varlıklar `/assets` ve `/assets/<tür>#<kimlik>`, Ansiklopedi `/encyclopedia`, Notlar `/notes` (elle yazılan notlar `/notes?view=written`), Sürümler `/releases`. Bütün adresler İngilizcedir; sayfa başlıkları Türkçe kalır.
- Kaynak belgenin bölümü: `[time.md §3](/docs/source/design/time#3-gun-isigi)`. Bölüm bağı başlıktan türer: küçük harf, Türkçe harfler Latin (`ı→i`, `ş→s`, `ğ→g`, `ç→c`, `ö→o`, `ü→u`), harf ve rakam dışı her şey tek tire. Yinelenen başlık `-1`, `-2` alır.
- Görsel, projedeki dosyadan: `![Açıklama](/media/docs/research/cam-shots/after-south-180-max.png)`, `![Mete](/media/docs/media/ui/portraits/mete.webp)`.
- Ses, projedeki dosyadan, aynı biçimde: `![Ozanın şarkısı](/media/docs/media/audio/vo/en/act0.bard.song.mp3)`. Oynatıcı olarak görünür.
- `/media/` yalnız `docs/` (tasarım belgeleri, araştırma, `docs/media`) ve `game/` (Godot projesi: `game/assets/_concepts`, `game/audio`) altındaki görsel ve ses dosyalarını verir. Dosyanın var olduğunu denetle.
- Varlık görselleri varlık kataloğundan (`docs/assets/catalog.json`) gelir: sayfaya kimlikleriyle bir `varlik` bloğu konur, site küçük görselleri adlarıyla gösterir ve her birini Varlıklar tablosundaki satırına bağlar. Görseli henüz üretilmemiş varlık boş kutuyla görünür; katalogda olmayan kimlik kırmızı işaretlenir.

  ````markdown
  ```varlik
  horse_brown, horse_white
  camel
  ```
  ````
- Kataloğun `design` alanı bir sayfanın adresiyse (`/docs/world/animals`) o varlık sayfanın sonunda «Bu sayfanın varlıkları» altında da görünür. Sayfaya aynı varlığı ikinci kez blokla koymak gerekmez; blok, metnin anlattığı yerde göstermek içindir.
- Yol haritası İlerleme'den (`content/progress.json`) canlı gösterilir: `ilerleme` bloğuna bir perdenin kimliği (`act-1`) o perdenin bütün fazlarını ve maddelerini, bir fazın kimliği (`act-1-p4`) yalnız o fazı durum işaretleriyle (✓ bitti, ◐ sürüyor, ○ yapılacak) basar. Madde listesini sayfaya elle yazma: İlerleme değişince sayfa da değişir.

  ````markdown
  ```ilerleme
  act-1
  ```
  ````
