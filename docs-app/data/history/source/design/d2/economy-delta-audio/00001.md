# `audio.md` değişiklikleri: Ekonomi (K24)

> **Yerini aldı, işlenmez (2026-11-03, K26).** `audio.md` yalnız `d2/audio-delta.md` birleşik defteriyle işlenir; bu dosyanın maddeleri oraya, sayıları `d2/core.md`'ye göre düzeltilerek indirildi. Dosya iz için kalır; `L` onu ikinci kez işlemez (çapalar ikinci geçişte tutmaz).

Kaynak: `d2/economy.md` §4, §5, §15. Faz 7 bitince birleşir. Hepsi kodla sentezdir (Vibi yalnız konuşma), 22 kHz mono, sahne başına dilimli ön üretim; hazır ses bütçesi (≤40 MB) içinde ≈0,6 MB. Aynı anda en çok 2 tezgâh döngüsü; uzaklıkla 3B (`audio/spatial.js`).

---

## A1. §4 Ortam ve efekt reçeteleri: «Komşu belgelerin ekleri» maddesi

**İşlem:** maddeyi değiştir.

**Eski metin:**

```
- **Komşu belgelerin ekleri:** `clean_strike`, `load_thud`, `notch`, `cook_sizzle`, `balance_tick` (`economy.md` §3.7); `post_knock`, `wheel_snow` (`travel.md` §14); `bone_clack`, `sling_whirl` (`progression.md` §14.2); `whoosh`, `page_turn` (`menu-spec.md`).
```

**Yeni metin:**

```
- **Komşu belgelerin ekleri:** `clean_strike`, `load_thud`, `notch`, `cook_sizzle`, `balance_tick` (`economy.md` §3.7); `post_knock`, `wheel_snow` (`travel.md` §14); `bone_clack`, `sling_whirl` (`progression.md` §14.2); `whoosh`, `page_turn` (`menu-spec.md`); `felt_roll`, `bellows`, `anvil`, `adze`, `tan_scrape`, `shear_snip`, `milk_pail`, `store_open`, `cart_unload`, `loot_search`, `craft_done` (`d2/economy.md` §4.2, §5; reçeteler aşağıda).
```

## A2. §4: ekonomi reçeteleri

**İşlem:** tablo ekle. **Yer:** A1 maddesinden sonra, «## 5. Seslendirme (Vibi)» başlığından önce.

**Yeni metin:**

```
**Ekonomi reçeteleri** (`src/audio/sfx/economy.js`). Döngüler tezgâhta iş sürerken çalar; ekip yoksa susar. Gece atölye döngüsü −4 dB (`d2/labour-delta-audio.md` gece kuralı).

| id | Olay | Sentez | Kazanç |
|---|---|---|---|
| `felt_roll` | Keçe Avlusu, döngü | Yumuşak tok vuruşlar 1,2 Hz (alçak geçiren 400 Hz gürültü, 60 ms) + hasır hışırtısı (bant 2–4 kHz, %30), her 8 vuruşta kadın sesi yok, yalnız nefes (gürültü 300–800 Hz, 0,4 sn) | −20 dB |
| `bellows` | Demirci Ocağı, döngü | Nefes gibi kabaran gürültü 0,8 Hz (bant 300–900 Hz, zarf 0,5 sn yükselme, 0,7 sn iniş) + kor çıtırtısı (8 Hz rastgele tık) | −18 dB |
| `anvil` | Demirci vuruşu, 2–3 sn'de bir | FM: taşıyıcı 1,2 kHz, oran 2,76, indis 4, 600 ms sönüm + 180 Hz tok 40 ms | −14 dB |
| `adze` | Ağaç Atölyesi, keser | Bant 1,1 kHz gürültü 25 ms + sinüs 140→100 Hz 60 ms; 1,6 sn'de bir, ±%8 perde | −16 dB |
| `tan_scrape` | Sepi Yeri, kazıma | Bant 1,5–3 kHz gürültü vuruşları 2 Hz, 180 ms, ıslak alçak geçiren son | −22 dB |
| `shear_snip` | Kırkım | İki tık 4 kHz (8 ms arayla) + yapağı hışırtısı (alçak geçiren 1,2 kHz, 250 ms) | −20 dB |
| `milk_pail` | Sağım | Sıvı fışkırma (bant 2–4 kHz, 70 ms) kova rezonansına (bant 700 Hz, Q 6) | −22 dB |
| `store_open` | Kap açılır (ambar, sandık, terki) | Keçe kapak hışırtısı (alçak geçiren 600 Hz, 200 ms) + tahta kapak tok (120 Hz, 50 ms) | −16 dB |
| `cart_unload` | Araba ya da kervan boşalır | `load_thud` üç kez, 0,25 sn arayla, perde her birinde −%6 | −14 dB |
| `loot_search` | Ara / Search | Kumaş hışırtısı (bant 1–3 kHz, 400 ms) + 2 metal şıngırtı (FM 2,4 kHz, 90 ms) | −18 dB |
| `craft_done` | Tarif ya da sipariş bitti (arayüz) | Dombra çekişi D4 (gündüz D Dorian) + ince tahta tık (`ui_hover` ×0,7) | −16 dB |
```

## A3. §4 «Bellek» paragrafı

**İşlem:** cümle ekle. **Yer:** paragrafın sonuna (`… kare başına ≤4 ms.` sözcüklerinden sonra).

**Yeni metin:**

```
Ekonomi döngüleri (`felt_roll`, `bellows`, `tan_scrape`) yalnız yerleşim ve ordugâh dünyalarında ön üretilir; Kışlak'ta yalnız `anvil` ve `bellows` (Kujul'un körüğü).
```
