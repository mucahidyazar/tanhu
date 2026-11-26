# `structures.md` için hava deltası (K22)

> **Yerini aldı, işlenmez (2026-11-03, K26).** `structures.md` yalnız `d2/structures-delta.md` birleşik defteriyle işlenir; bu dosyanın maddeleri oraya, sayıları `d2/core.md`'ye göre düzeltilerek indirildi. Dosya iz için kalır; `L` onu ikinci kez işlemez (çapalar ikinci geçişte tutmaz).

Kaynak: `docs/design/d2/weather.md` (§8.6, §8.7, §8.11, §9.8). Faz 7 bitince uygulanır; Faz 7 sırasında `structures.md` düzenlenmez. K21 yeniden işleme deltası (emek alanı) aynı bölümlere (§3.1, §10, §11.6) dokunursa bu deltanın satırları onun yanına eklenir, sayıları emek alanınındır. Her madde: bölüm ve başlık, yer (bulunacak metin), yapılacak iş, yeni metnin tamamı.

## 1. §6.2 Yayılma

**1a.** Şu maddeyi:

```
- Rüzgâr hızı 3 m/sn (Kara Boran 8), yönü `U.uWindDir`.
```

şununla değiştir:

```
- Rüzgâr hızı ve yönü havadan gelir (`d2/weather.md` §8.6): `StructureManager.wind = clamp(rüzgâr + 0,5 × bora; 0; 24)`, `windDir` havanın akış yönü. Havasız dünyada (sınama, menü) 3 m/sn ve `U.uWindDir` yönü kalır. Kara Boran 8 m/sn (act1 §10 ile aynı sayı); I. Perde baskın kilidi 3 m/sn, kuzeydoğudan.
```

**1b.** Şu maddeyi:

```
- `ıslak`: Kışlak'ta karlı keçe 0,5; taze karlı keçe 0,2; aksi 1.
```

şununla değiştir:

```
- `ıslak` (`spreadEntry.wet`, hava her kare yazar): keçe ve saz `min(1 − 0,8 × keçeIslaklığı, karÇarpanı)`; ahşap `1 − 0,4 × keçeIslaklığı`; taş ve metal 1. `karÇarpanı`: Kışlak'ta taze kar (son yağışın örtüsü >0,5) 0,2, aksi 0,5 (eski sayılar korunur); karın tutmadığı iklimde 1. `keçeIslaklığı` 0..1 yağmurla ıslanır, güneş ve rüzgârla kurur (`d2/weather.md` §5.9).
```

## 2. §6.3 Söndürme

Tablonun sonuna (şu satırdan sonra):

```
| Çatıyı Kesme / Cut the Roof | Üst havuzu düşürür, `burnT` 0 | `grain` hedefi, `act1.md` §8.3 |
```

ekle:

```
| Yağış / Rainfall | Barınaksız yanan yapıda `burnT` sn başına: çisenti −0,25, yağmur −1, gök gürültülü fırtına ve dolu −1,5, sağanak −2,5, sulu kar ve tipi −0,5, yoğun kar −0,3; hafif kar 0 | Hava (`d2/weather.md` §8.6), `douse(oran × dt)` |
```

Tablonun altına yeni paragraf ekle:

```
**Yağmurda yanık (hesap).** `tickBurn` ile yağış birlikte işler. Keçe henüz kuruyken ateşli ok (`burnT` 30) yağmurda 15 sn yanar (7→6; 6→5 için 30 sn gerekir), sağanakta 8,6 sn; meşale (70) yağmurda 35 sn (7→5), sağanakta 20 sn (7→6). Islak keçede (§6.1 tutuşma çarpanı) ateşli ok yağmurda 7,5 sn yanar. Hafif kar söndürmez: Son Gece oyalaması §6.1 kalibrasyonunda kalır (≈70 sn'de 7→3).
```

## 3. §6.1 Yanma

`Tutuşturan` tablosunun «Ateşli ok» satırının «Not» hücresinin sonuna ekle:

```
; tutuşturma gücü `× (1 − 0,5 × keçeIslaklığı)` (`d2/weather.md` §8.6: ıslak keçe zor tutuşur; kuru havada değişmez)
```

## 4. Yeni §6.5 Hava ve yıldırım

§6.4 «Görünüm ve etki» bölümünden sonra, §7 «Onarım»dan önce ekle:

```
### 6.5 Hava ve yıldırım

Kurallar `d2/weather.md` §8.6, §8.7; sayılar buraya özet olarak geçer.

**Dolu.** İri dolu (dolu sağanaklarının %30'u): `reed` birimi −0,5 Can/sn, `tent` örtüsü −0,2 Can/sn; küçük dolu `reed` −0,1 Can/sn. Keçe, ahşap, kafes dolu almaz. Dolu bir yapıyı aşama 1'in altına indirmez ve bir sağanakta en çok bir aşama düşürür.

**Fırtına (rüzgâr ≥16 m/sn).** Bağlanmamış `tent` örtüsü −0,2 Can/sn, `rack` −0,1 Can/sn ve içindekinin %20'si yere düşer. **Bağla / Tie Down** (`E` basılı 3 sn; `tent`, `rack`): o hava bölümünün sonuna dek bağışık. Yurt (kolan) ve ahır (kiriş) rüzgâr almaz. Taban aynı: aşama 1'in altı yok.

**Yıldırım.** Hedefi hava seçer (en uzun ve en yalnız aday, §8.7 skoru). Yurt ve ahır: tepe birimine `blunt` 25 (`STRUCT.blunt.wood` 1) ve `addScorch`; keçe ıslaklığı <0,3 ise (kuru fırtına) `ignite({ power: 30 })`, ≥0,5 ise tutuşmaz. Kule ve direk: tepe birimine `blunt` 40. Kurulmakta olan yapı hedef olmaz; vurulan yapı 1 oyun günü bekler; bir yerleşimde fırtına başına en çok bir yapı. **Tuğ Direği / Standard Pole** (K23 önerisi, 12 m): yurttan (`bounds.top` 8,6 m) uzundur; ≈22 m yarıçapındaki yapıların yerine yıldırımı o alır, 10 sn tüter, −10 Can (ahşap 30). Aday yüksekliği yapının `bounds.top` değeridir.

**Islak keçe görünümü.** `struct_tex` dış yüzü `U.uWet.y` ile koyulaşır ve dikey akıntı izi alır (`FELT_WET` kancası); iç duvar kuru kalır (dışa bakan normal sınaması ya da yapı başına merkez uniform'u). Kar çatısı Kışlak'ın kar kancasıdır (K2).

**Görünüm bütçesi.** Hava yapıya çizim ya da program eklemez: kanca metni değişir, anahtar ve program sayısı aynıdır.
```

## 5. §4.5 Kısa liste

**5a.** `tent` satırının «Kullanım» hücresinin sonuna ekle: `; fırtınada bağlanmazsa örtü yıpranır, Bağla / Tie Down (§6.5)`.

**5b.** `rack` satırının «Kullanım» hücresinin sonuna ekle: `; kurutma ilerlemesi havanın kurutma çarpanıyla, dolu içindekini bozar, fırtınada bağlanmazsa içindeki düşer (§6.5, d2/weather.md §8.5)`.

## 6. §10.2 Durum makinesi

Durum tablosunda şu satırdan sonra:

```
| `FLEE` | Yangın ≤4 m ya da düşüş: 6 m uzağa 3 m/sn, `wave` | Söner |
```

ekle:

```
| `SHELTER` | Hava adımı bekletince (emek tablosunun `hold` alanı: `felt`, `tall`, `all`; `d2/labour-model.json` `weather`): en yakın yurt kapısına ya da ahır çatısının altına 1,9 m/sn; çizelge bekler | `sev` 0,25 sa (37 sn) <3 kalınca önceki işe |
```

Tablonun altındaki «**Yol.**» paragrafından önce ekle:

```
**Hava.** Hız çarpanı ve bekleme emek alanının tablosudur; usta beklerken HUD satırı «Ustalar fırtınanın dinmesini bekliyor.» / «The builders are waiting out the storm.» (`lock.weather_build`). İş miktarı değişmez, takvim uzar.
```

## 7. §16 İstek ve ilke çatışmaları

Tablonun sonuna ekle:

```
| 14 | K22: hava yapıları etkiler | Yağmur yangını, yıldırım ve dolu oyuncunun emeğini zarla yok edebilir | Yağış söndürür ve ıslak keçe zor tutuşur; yıldırım uzun olanı seçer, kurulan yapıyı seçmez, bir gün bekler, ıslak keçeyi yakmaz; dolu ve fırtına aşama 1'in altına indirmez; Tuğ Direği korur; Bağla hazırlığı | Hava okunur ve hazırlanılır olmalı; kalıcı kayıp sürpriz olmamalı |
```

## 8. §17 Uygulama sırası ve kabul

«**Kabul testleri.**» listesinin sonuna ekle:

```
11. Hava: keçe kuruyken yağmurda ateşli ok 7→6'da durur (15 sn ±2), meşale 7→5'te (35 sn ±2); `a1_last_night` kilidinde meşale 7→3 70 sn ±2 (değişmez); `a1_feast_raid` kilidinde `spreadEntry.wet` 0,5, rüzgâr 3.
12. Yıldırım: kurulmakta olan yapı ve 1 gün içinde vurulan yapı hedef olmaz; ıslak keçe (≥0,5) tutuşmaz; 12 m Tuğ Direği ≈22 m yarıçapındaki yurtların yerine vurulur (`d2/weather.md` §15 W9).
13. Dolu ve fırtına bir yapıyı aşama 1'in altına indirmez; Bağla edilen çadır fırtınada Can kaybetmez.
14. `FELT_WET` ile program sayısı değişmez; `menuDiff` 0.
```
