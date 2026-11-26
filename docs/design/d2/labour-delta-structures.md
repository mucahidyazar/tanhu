# `structures.md` değişiklikleri (K21 emek yasası)

> **Yerini aldı, işlenmez (2026-11-03, K26).** `structures.md` yalnız `d2/structures-delta.md` birleşik defteriyle işlenir; bu dosyanın maddeleri oraya, sayıları `d2/core.md`'ye göre düzeltilerek indirildi. Dosya iz için kalır; `L` onu ikinci kez işlemez (çapalar ikinci geçişte tutmaz).

Kaynak: `docs/design/d2/labour.md`. Faz 7 bitince baş mühendis birleştirir. Birleşmede `d2/labour.md` → `docs/design/labour.md` taşınır; aşağıdaki yeni metinler bu yolu yazar (`labour.md`). Her madde: bölüm, değiştirilecek metin (birebir), yeni metin. Sırayla uygulanır; bir madde tutmazsa (metin değişmişse) baş mühendis anlamı korur.

**Zaman taslağıyla aynı satırlar.** `d2/time-delta-structures.md` (K20) aynı satırlardan altısına dokunur. Bu dosyanın maddeleri iki taslağın birleşik metnini yazar; ikisi birlikte uygulanmaz:

| `time-delta-structures.md` | Bu dosya | Not |
|---|---|---|
| S1 (§2.2) | D6 | Kip `'timed' \| 'script'`; `advance(wm)` saat yüzünü de söyler |
| S2 (§10.2 «Ustaların günü») | D15b | K21 gereği 22:00'de bırakma yok; `Gece dinlenilsin` emri pencereye çeker (`labour.md` §9.5) |
| S3 (§10.3 Kışlak cümlesi) | D16 | Kışlak saatleri zaman taslağından |
| S4 (§11.6 iki cümle) | D20 | Yeni §11.6 iki cümleyi de içerir |
| S5 (§14 üç satır) | D23 | |
| S6 (§15 `CampPlan`) | D24 | |
| S7 (§16 satır 2) | D25 | |

---

## D1. §0 Karar özeti, ilk tablo, «Süre» satırı

**Değiştir:**
```
| Süre | 8 × 3 dk = 24 dk | 590 sn = 9 dk 50 sn; yardımla en az 4 dk 43 sn | İstenen aralık 8–12 dk |
```
**Yeni:**
```
| Süre | 8 × 3 dk = 24 dk | Emek: tek işçiyle 1 iş günü (1.440 iş dakikası = 60 gerçek dk); camp3 üç ustayla, öğün sırasıyla 23,4 dk (14:54 → 00:16), Çocuğun bütün yardımıyla 19,7 dk (§11.6) | K21 (2026-11-02): süre emekten çıkar, `labour.md` |
```

## D2. §0, ilk tablo, «Çocuğun yardımı» satırı

**Değiştir:**
```
| Çocuğun yardımı | Odun getirirse aşama −15 sn | Kütük −15 sn korunur (`help_log`); ek olarak adıma göre 2–8 sn, 8 yardım türü (§11.6) | 13 adımın 12'si yardıma açık, toplam alt sınır 283 sn |
```
**Yeni:**
```
| Çocuğun yardımı | Odun getirirse aşama −15 sn | Çocuk ekibe katılınca yarım el (0,5) ve bir baş sayılır; kütük, köz ve su ayak işidir (§11.6) | K21: «çocuk yarım işçi»; kredi ve 3 kat erime kalktı |
```

## D3. §0, ikinci tablo, `economy.md` §6.5 satırı

**Değiştir:**
```
| `economy.md` §6.5 | (−22,−20), 180 sn/aşama, aşamada 8 parça | §11.1, §11.6: adım başına 1 parça, toplam 4, parça −15 sn | Yer geçersiz; adımlar kısa |
```
**Yeni:**
```
| `economy.md` §6.5 | (−22,−20), 180 sn/aşama, aşamada 8 parça | §11.1, §11.6: yığın uuk için 4 kütük eksik başlar; Çocuk getirmezse Dengiz gider | Yer geçersiz; K21 emek yasası |
```

## D4. §1 Gerçek kurulum sırası ve sözcükler, ilk paragraf

**Değiştir:**
```
2–3 kişi bir boz yurdu gerçekte 60–90 dakikada kurar. Oyun bunu ≈1:8 sıkıştırır; sıra korunur.
```
**Yeni:**
```
2–3 kişi bir boz yurdu gerçekte 60–90 dakikada kurar. Oyun emeği K21 ile sabitler: yurt bir işçinin bir iş günüdür (1.440 iş dakikası, tek işçiyle 60 gerçek dakika), ekip büyüdükçe süre azalan verimle kısalır (`labour.md` §2, §4). Sıra korunur.
```

## D5. §2.1 Kavramlar, tabloya satır

**Yer:** `| Adım | `step` | Gerçek iş sırası; bir aşamada 1–4 adım |` satırının hemen altı.
**Ekle:**
```
| Emek | `work` | Adımın iki elle iş dakikası; tek el çarpanı `solo`, el sınırı `min`–`max` (`labour.md` §4) |
```

## D6. §2.2 Veri biçimi, kod bloğu

**Değiştir:**
```
  steps: [
    { id: 'y_kerege', stage: 2, name: { tr: 'Kerege', en: 'Lattice Walls' }, dur: 70, crew: 2,
```
**Yeni:**
```
  craft: 'home', crewMax: 8,                                         // labour.md §3, §2
  steps: [
    { id: 'y_kerege', stage: 2, name: { tr: 'Kerege', en: 'Lattice Walls' }, work: 136, solo: 1.25, min: 2, max: 6,
```

**Değiştir:**
```
  constructor(def, place, world, { mode: 'timed' | 'slice', preset, startFull })
  stage; step; stepT;                 // aşama, adım dizini, adım içi 0..1
  advance(dtWork);                    // zaman modu
  sliceTick();                        // Kışlak dilim modu (§14)
  deliver(item, n, who);              // malzeme; who 'player' | 'npc', contrib sayılır
  credit(seconds);                    // oyuncu yardımı
```
**Yeni:**
```
  constructor(def, place, world, { mode: 'timed' | 'script', preset, startFull })   // K20: 'slice' kalktı; Kışlak da dünya saatiyle
  stage; step; stepT; wm;             // aşama, adım dizini, adım içi 0..1, işlenen emek (iş dakikası)
  advance(wm);                        // emek kipi: wm = oran × oyun dakikası; oranı sürücü yazar, atlamada toplu (labour.md §6.8, §11)
  deliver(item, n, who);              // malzeme; who 'player' | 'npc', contrib sayılır
  credit(wm);                         // senaryo armağanı, çarpansız
  dismantle();                        // söküm: tersten, emeğin 0,35'i (labour.md §6.9)
```

**Değiştir:**
```
  repairStep(dtWork, who);            // §7
```
**Yeni:**
```
  repairStep(wm, who);                // §7, iş dakikası
```

## D7. §3.1 başlık, paragraf ve tablo

**Değiştir (başlık):** `### 3.1 Adımlar: süre, iş gücü, malzeme, can`
**Yeni:** `### 3.1 Adımlar: emek, el, malzeme, can`

**Değiştir (paragraf):**
```
Süreler `hero` hazır ayarı, 2 usta, oranı 1 (§10.3). Malzeme ve can toplamları aşama başına `act1.md` ile birebir aynıdır.
```
**Yeni:**
```
Emek iş dakikasıdır (İD, `labour.md` §1): «Tek el» bir işçinin, «Ekip» iki ve daha fazla elin harcadığı emek; «El» baş sayısıdır, en az ve en çok. Süre ekipten çıkar (`labour.md` §4.3). Malzeme ve can toplamları aşama başına `act1.md` ile birebir aynıdır.
```

**Değiştir:** başlık satırı `| Adım | TR / EN | Aşama | Süre sn | Bitiş | Usta | Malzeme | Can | Pay | Sınıf |` ile başlayıp `| **Toplam** | | | **590** | …` satırıyla biten tablonun tamamı.
**Yeni:**
```
| Adım | TR / EN | Aşama | Tek el İD | Ekip İD | El | Malzeme | Can | Pay | Sınıf |
|---|---|---|---|---|---|---|---|---|---|
| `y_site` | Zemin ve Ocak Halkası / Ground and Hearth Ring | 0 | 75 | 75 | 1–8 | 6 taş | Yıkılmaz | 0 | stone |
| `y_bosaga` | Bosağa / Door Frame | 1 | 75 | 75 | 1–4 | 3 odun, 1 demir | 40 | %9,5 | wood |
| `y_kerege` | Kerege / Lattice Walls | 2 | 170 | 136 | 2–6; tek el ×1,25 | 8 odun, 2 ip | 45 | %10,7 | lattice |
| `y_bag` | Kerege Bağı / Tension Band | 2 | 45 | 45 | 1–6 | 2 ip | 15 | %3,6 | bands |
| `y_tunduk` | Tündük / Crown | 3 | 160 | 100 | 2–6; tek el ×1,6 | 1 tündük (`yurt_crown`), 2 sırık (`pole`) | 50 | %11,9 | wood |
| `y_uuk` | Uuk / Roof Poles | 4 | 270 | 270 | 1–8 | 12 odun | 80 | %19,0 | wood |
| `y_liner` | İç Örtü ve Çiy / Inner Liner and Reed Screen | 5 | 105 | 105 | 1–6 | 6 saz | 40 | %9,5 | reed |
| `y_tuurduk` | Tuurduk / Felt Walls | 6 | 150 | 120 | 2–8; tek el ×1,25 | 4 keçe | 70 | %16,7 | felt |
| `y_uzuk` | Üzük / Felt Roof | 6 | 170 | 136 | 2–8; tek el ×1,25 | 2 keçe | 50 | %11,9 | felt |
| `y_kolan` | Kolan / Girth Ropes | 7 | 105 | 105 | 1–6 | 3 ip | 24 | %5,7 | bands |
| `y_esik` | Kapı Keçesi / Door Curtain | 7 | 20 | 20 | 1–2 | 1 ip (keçe artığı) | 6 | %1,4 | felt |
| `y_sirdak` | Şırdak / Floor Felts | 7 | 75 | 75 | 1–6 | Ambardan, sayılmaz | 0 | 0 | felt |
| `y_ocak` | Ocak Yakma / Hearth Lit | 7 | 20; köz yığındaysa 6 | 20 | 1–1 | 1 köz | 0 | 0 | yok |
| **Toplam** | | | **1.440** | **1.282** | En çok 8 | 6 taş, 23 odun, 1 demir, 8 ip, 1 tündük, 2 sırık, 6 saz, 6 keçe, 1 köz | **420** | | |

Ekip çizelgesi (yetişkin, usta var, gündüz, açık hava): 1 el 60,0; 2 el 28,5; 3 el 20,4; 4 el 16,3; 6 el 12,6; 8 el 11,6 gerçek dakika (`labour.md` §4.3). Dört iki ellik adımın tek el yöntemi `labour.md` §4.2.
```

## D8. §4.1 Ahır, tablo

**Değiştir:** `| Adım | TR / EN | Aşama | Süre | Usta | Malzeme | Can, sınıf, birim | Çarpışma | Oda | Görünen, üçgen |` başlıklı tablonun başlığı, beş adım satırı ve Toplam satırı.
**Yeni:**
```
| Adım | TR / EN | Aşama | Ekip İD | El | Malzeme | Can, sınıf, birim | Çarpışma | Oda | Görünen, üçgen |
|---|---|---|---|---|---|---|---|---|---|
| `st_site` | Zemin ve Oluk / Ground and Trough | 0 | 140 | 1–6 | 4 taş | Yıkılmaz | Yok | Yok | Saman izli zemin, 8 yuva, stok |
| `st_posts` | Direk / Posts | 1 | 340 | 1–4 | 6 odun | 60, wood, 4 sütun çifti × 15 | 8 `circle(0.13)` (`camp.js:527-532`) | Yok | 8 direk, 8 payanda; 1.200 |
| `st_walls` | Bölme ve Duvar / Stalls and Walls | 2 | 510 | 1–6 | 6 odun, 4 ip | 60: arka 30, yan 14 wood; `rails` 2 × 8 bands | 2 `rect` (`camp.js:525-526`), 2 `rect(top -1.1)` (`camp.js:534-535`) | Yemlik, eyer, fener; atlar bağlanır | 26 arka, 9 yan tahta 3.780; korkuluk 480; fener 330; iç eşya 9.440 |
| `st_beams` | Kiriş / Beams | 3 | 270; tek el ×1,5 | 2–4 | 6 odun | 30, wood, 4 × 7,5 | Değişmez | Yok | 2 saçak, mahya kirişi, 8 mertek, 4 bağ; 1.104 |
| `st_roof` | Çatı / Roof | 4 | 765 | 1–6 | Canlı kamp 14 odun; Kışlak 10 saz, 3 keçe | 20, canlı `wood`, Kışlak `reed`; 6 dilim | Değişmez | `room.enabled`: kesit açılır | 496 tahta sıra sıra saçaktan mahyaya, mahya tahtası; 6.252 |
| **Toplam** | | | **2.025; tek el 2.160 = 1,5 iş günü** | | | **170** | | | **12.816 + 9.770** |
```
**Tablonun altına ekle:** `Zanaat `wood`: ağaç ustası yoksa oran ×0,7 (`labour.md` §3). Dört elle 24,5, sekiz elle 20,0 gerçek dakika.`

## D9. §4.2 Çit, tablo

**Değiştir:**
```
| Adım | TR / EN | Aşama | Süre | Usta | Malzeme | Can, sınıf | Çarpışma | Görünen |
|---|---|---|---|---|---|---|---|---|
| `f_stakes` | Kazıklar / Stakes | 0 | 6 sn/m | 1 | 4 odun / 10 m | Yıkılmaz (kırık kütük) | Yok | Kazıklar sırayla çakılır; 48 üçgen/kazık |
| `f_rails` | Kuşaklar / Rails | 1 | 3 sn/m | 1 | 2 odun, 2 ip / 10 m | 20 / 2 m, wood | `capsule(r 0.1, top -0.95)`, üstünden atlanır | 2 kuşak kip 5 |
```
**Yeni:**
```
| Adım | TR / EN | Aşama | Ekip İD | El | Malzeme | Can, sınıf | Çarpışma | Görünen |
|---|---|---|---|---|---|---|---|---|
| `f_stakes` | Kazıklar / Stakes | 0 | 7,2 / m | 1; 2 m'lik parça başına bir el, en çok 8 | 4 odun / 10 m | Yıkılmaz (kırık kütük) | Yok | Kazıklar sırayla çakılır; 48 üçgen/kazık |
| `f_rails` | Kuşaklar / Rails | 1 | 3,6 / m | Aynı | 2 odun, 2 ip / 10 m | 20 / 2 m, wood | `capsule(r 0.1, top -0.95)`, üstünden atlanır | 2 kuşak kip 5 |
```

## D10. §4.3 Ağıl, tablo

**Değiştir:**
```
| `p_line` | Kazık Hattı / Stake Line | 0 | 12 sn / 10 m | 1 | 1 odun / 5 m | Yıkılmaz | Yok | Hayvan tutmaz | Köşe kazıkları, ip |
| `p_wattle` | Örgü Çit / Wattle Fence | 1 | 8 sn / pano | 2 | 1 odun / pano | 20 / pano, wood | `capsule(r 0.1, top -1.1)` pano başına | Kapalı döngü: yeniden etiket (§12.4) | 2,2 m pano 64 üçgen |
| `p_gate` | Kapı / Gate | 1 | 20 | 2 | 2 odun, 1 ip | 20, wood | `open` ise silinir | `gate.toggle()`; E ya da at | 3,2 m kanat |
```
**Yeni:**
```
| `p_line` | Kazık Hattı / Stake Line | 0 | 1,5 / m | 1; 5 m başına bir el, en çok 8 | 1 odun / 5 m | Yıkılmaz | Yok | Hayvan tutmaz | Köşe kazıkları, ip |
| `p_wattle` | Örgü Çit / Wattle Fence | 1 | 20 / pano | 1; pano başına bir el, en çok 8 | 1 odun / pano | 20 / pano, wood | `capsule(r 0.1, top -1.1)` pano başına | Kapalı döngü: yeniden etiket (§12.4) | 2,2 m pano 64 üçgen |
| `p_gate` | Kapı / Gate | 1 | 40; tek el ×1,25 | 2–2 | 2 odun, 1 ip | 20, wood | `open` ise silinir | `gate.toggle()`; E ya da at | 3,2 m kanat |
```
**Aynı tablonun başlığında:** `Süre` → `Ekip İD`, `Usta` → `El`.
**Tablonun altına ekle:** `Adak Ağılı (148 m, 66 pano, kapı): tek el 1.592 İD (1,1 iş günü); 6 elle 14,6 gerçek dakika.`

## D11. §4.4 Araba, tablo ve paragraf

**Değiştir:**
```
| Adım | TR / EN | Süre | Usta | Malzeme (`economy.md` §6.4 toplamı) | Birim can, sınıf | Çarpışma | Binek | Görünen, üçgen |
|---|---|---|---|---|---|---|---|---|
| `c_axle` | Dingil ve Teker / Axle and Wheels | 60 | 2 | 3 odun, 1 `iron_bar` | `c_wheels` 2 × 8, `c_axle` 8; wood | `circle(r 1.6)` | Yok | 2 teker (`InstancedMesh`), dingil; 1.112 + kasadan pay |
| `c_bed` | Kasa / Cart Bed | 45 | 2 | 2 odun | 12, wood | Değişmez | Yük 40 | Taban, yan tahta, sürücü sandığı, yük; 1.564 |
| `c_hoops` | Çember / Hoops | 30 | 1 | 1 odun | 4, lattice | Değişmez | Yok | 3 kaburga; çatının içinde |
| `c_tilt` | Keçe Çatı / Felt Tilt | 30 | 2 | 2 keçe | 6, felt | Değişmez | Yolcu korunur | Yarım silindir, 2 kapak; 568 |
| `c_yoke` | Koşum / Harness | 20 | 1 | 2 odun, 2 ip | 4, bands | Değişmez | **4 yolcu + sürücü, aşama 1** | Oklar, göğüs kayışı, kolan, dizgin; 416 at ağında |
| **Toplam** | | **185** | | 8 odun, 1 `iron_bar`, 2 keçe, 2 ip | **50** | | | |
```
**Yeni:**
```
| Adım | TR / EN | Ekip İD | El | Malzeme (`economy.md` §6.4 toplamı) | Birim can, sınıf | Çarpışma | Binek | Görünen, üçgen |
|---|---|---|---|---|---|---|---|---|
| `c_axle` | Dingil ve Teker / Axle and Wheels | 110; tek el ×1,5 | 2–4 | 3 odun, 1 `iron_bar` | `c_wheels` 2 × 8, `c_axle` 8; wood | `circle(r 1.6)` | Yok | 2 teker (`InstancedMesh`), dingil; 1.112 + kasadan pay |
| `c_bed` | Kasa / Cart Bed | 120 | 1–4 | 2 odun | 12, wood | Değişmez | Yük 40 | Taban, yan tahta, sürücü sandığı, yük; 1.564 |
| `c_hoops` | Çember / Hoops | 40 | 1–2 | 1 odun | 4, lattice | Değişmez | Yok | 3 kaburga; çatının içinde |
| `c_tilt` | Keçe Çatı / Felt Tilt | 60; tek el ×1,25 | 2–4 | 2 keçe | 6, felt | Değişmez | Yolcu korunur | Yarım silindir, 2 kapak; 568 |
| `c_yoke` | Koşum / Harness | 32 | 1–2 | 2 odun, 2 ip | 4, bands | Değişmez | **4 yolcu + sürücü, aşama 1** | Oklar, göğüs kayışı, kolan, dizgin; 416 at ağında |
| **Toplam** | | **362; tek el 432 = 0,3 iş günü** | | 8 odun, 1 `iron_bar`, 2 keçe, 2 ip | **50** | | | |
```

**Değiştir (paragraf «Yolculuk bağı» içinde):** `Sıradan onarım 1 odun, 1 ip, 25 sn;`
**Yeni:** `Sıradan onarım 1 odun, 1 ip; emek 29 İD (teker kaldırma, §7): Mete ve sürücüyle ≈39 sn, `repair` ile ≈19 sn;`

## D12. §4.5 Kısa liste, yeni sütun

**Değiştir (başlık):** `| `kind` | Aşama | Adımlar TR / EN | Can, sınıf | Kullanım |` ve ayırıcı satır.
**Yeni:** `| `kind` | Aşama | Adımlar TR / EN | Can, sınıf | Emek, tek el İD (iş günü) | Kullanım |` ve `|---|---|---|---|---|---|`.

**Her satırda «Can, sınıf» hücresinden sonra yeni hücre:**

| `kind` | Yeni hücre |
|---|---|
| `tent` | 216 (0,15): 36, 72 (2 el, ×1,2), 108 (2 el, ×1,2) |
| `hut` | 720 (0,5): 60, 220 (2 el, ×1,25), 240, 200 |
| `shed` | 864 (0,6): 60, 180, 198 (2 el, ×1,5), 200, 226 |
| `granary` | 1.152 (0,8): 80, 240, 264 (2 el, ×1,5), 266, 302 |
| `tower` | 2.160 (1,5): 300, 660 (2 el, ×1,5), 660 (2 el, ×1,25), 540 |
| `tower_gate` | 2.160, senaryo; yalnız onarım formülü |
| `bridge` | 2.880 (2): 360, 720 (2 el, ×1,5), 600 (2 el, ×1,5), 480, 300, 420 |
| `rack` | 3,2: basılı tutma 8 sn (`rc_rack`) |
| `road_bone` | 8: basılı tutma 20 sn (`rp_road_bone`) |

**Tablonun altına ekle:** `Adım emeği ve el sınırları `labour.md` §8.1 ve `labour-model.json`'dadır. Emeği ≤12 İD olan yerleştirilebilir şantiye açmaz: oyuncunun basılı tutması emeğin kendisidir.`

## D13. §7 Onarım, tablo satırları

**Değiştir:**
```
| Süre | **Yama / Patch**, canı eksik birim: `dur × (birim canı / adım canı) × (1 − can/max) × 0,6`. **Yeniden kaldırma / Re-raise**, düşmüş birim: `dur × pay × 0,8`, kurulum gösterimiyle |
```
**Yeni:**
```
| Emek | Birimin emeği `work × (birim canı / adım canı)` (iş dakikası). **Yama / Patch**, canı eksik birim: birim emeği × (1 − can/max) × 0,6. **Yeniden kaldırma / Re-raise**, düşmüş birim: birim emeği × 0,8, kurulum gösterimiyle; adımın el sınırı ve tek el çarpanı geçer. Birimsiz yeniden koşan adım (`y_sirdak`, `y_ocak`) ×0,8. Süre ekipten çıkar (`labour.md` §7) |
```

**Değiştir (aynı tablonun «Malzeme» satırında):** `` `y_tunduk` 3 kişi şartı kalır. Yanık birim +%25 ``
**Yeni:** `` `y_tunduk` iki el ister, tek başına bakanla ×1,6. Yanık birim emekte ve malzemede +%25 ``

**Değiştir:**
```
| Usta | Öncelik: yangın > düşmüş birim > can <%50. Elindeki iş biter, `REPAIR`'a geçer. Serbest Gez'de malzeme stoktan, sayılmaz |
```
**Yeni:**
```
| Usta | Öncelik: yangın > düşmüş birim > can <%50. Elindeki iş biter, `REPAIR`'a geçer. Serbest Gez'de malzeme stoktan, sayılmaz. A, B, ahır ve çitin yedek onarımı ana kampın iki adsız eli (oran 1,9 İD / oyun dk), vuruştan 30 gerçek sn sonra |
```

**Değiştir:**
```
| Oyuncu | ≤2,2 m, E basılı: «Onar / Repair». Mete `hammer` ya da `tie`. Çocuk yalnız çentik ve yırtık yamar: «Yama / Patch», 4 sn |
```
**Yeni:**
```
| Oyuncu | ≤2,2 m, E basılı: «Onar / Repair»: Mete ekibe 1 ağırlıkla girer, `repair` ile emek ×0,5. Mete `hammer` ya da `tie`. Çocuk yalnız yırtık diker: «Yama / Patch», yırtık başına 4 iş dakikası, yarım elle ≈20 gerçek sn, bırakınca ilerleme kalır; can onarımına «Ustalara Katıl» ile yarım el katılır |
```

## D14. §10.1 Kadro, son paragraf

**Değiştir:**
```
Adlar Hun ad kümesinden, `kurgu tercihi`. Dengiz yalnız `y_tunduk`'ta gelir, Çocuk sırığa geçerse gelmez. Bitince Oktar çıkar, Erka yurdun içinde oturur (`sitWant=1`).
```
**Yeni:**
```
Adlar Hun ad kümesinden, `kurgu tercihi`. Üçü birlikte gelir ve baştan sona çalışır: Oktar ve Erka usta (ağırlık 1), Dengiz çırak (0,75) (`labour.md` §9). Bitince Oktar ve Dengiz çıkar, Erka yurdun içinde oturur (`sitWant=1`).
```

## D15. §10.2 Durum makinesi, ilk cümle

**Değiştir:** `**Zaman çizelgesi asıldır:** `stepT` süreyi sayar, usta onu süsler.`
**Yeni:** `**Emek çizelgesi asıldır:** `stepT` adımın emeğini sayar (iş dakikası, `labour.md` §11), usta onu süsler.`

## D15b. §10.2 Durum makinesi, «Ustaların günü» paragrafı (zaman taslağının S2'sinin yerine)

**Yer:** `**Yol.** A* kullanılmaz (kapıdan arkaya 64,8 ms ölçüldü).` ile başlayan paragrafın sonu (`…yalnız yürüme ızgarası.`).
**Sonrasına ekle:**
```
**Ustaların günü (K20, K21).** Ustalar dünya saatiyle çalışır (`d2/time.md` §8.3, `labour.md` §9). Ana kampta ilk geliş yalnız 06:00–22:00 arasındadır: Serbest Gez 14:46'da açılır, ustalar 20 sn (8 oyun dk) sonra kuzey yamaçtaki usta girişinden (−4,5; −31) iner. 12:00 ve 18:30 öğünlerinde sırayla 30'ar dakika ateş başına oturur, iş öteki ikisiyle sürer. Batıştan (18:38) sonra iki meşale direği yanar, iş ışıkta ×1 sürer; K21 gereği ekip 22:00'de bırakmaz, yurt bitene dek çalışır (yardımsız ilk duman 00:16). Şantiyeye `Gece dinlenilsin` emri verilirse ekip 22:00'de kuzeye çıkar, 06:00'da döner. Hava durağında `SHELTER`: en yakın yurdun ya da ahır çatısının altı (`d2/weather.md` §8.11). Kışlak'ta senaryo ekibi hikâye programına uyar: iki el 07:00–23:00, Nanay 10:30–19:30. Bekleme ve uykuda (`clock:skip`) emek toplu işlenir, ustalar programdaki yerine konur (karartma altında). Yapı bitince Erka Otacı Yurdu'nun programına geçer, Oktar üç günde bir akşam aşına gelir.
```

## D16. §10.3 İş oranı, bölümün tamamı

**Değiştir:**
```
`oran = (usta < crew ? 0,6 : usta > crew ve crew ≥ 2 ? 1,25 : 1) × su çarpanı`. `crew` §3.1. `REPAIR`'daki usta sayılmaz; `help_heave` ile Çocuk 1 usta sayılır. II. Perde `quick_raise`: `buildTime` ×0,7, `helpers` +1. Kışlak'ta `slice` kipi: zaman yok, usta `schedule` süsüdür.
```
**Yeni:**
```
`oran = eff(W) × K_usta × K_beceri × K_gece × K_hava × K_tok × K_su × hız / solo`, iş dakikası / oyun dakikası (`labour.md` §2, §5). `eff(W) = min(W, 10 · (1 − 0,9^W))`; W, adımın el sınırına (§3.1 «El») dek en ağır üyelerin ağırlığı: usta ve el 1, çırak 0,75, Çocuk 0,5. `solo`: ekipte adımın en az el sayısından az baş varsa tek el çarpanı. `REPAIR`'daki usta o adımda sayılmaz. Katılan Çocuk 0,5 ağırlık ve bir baştır. `quick_raise`: Mete ekipteyken ×1/0,7, Mete'nin buyurduğu şantiyeye +1 el. Gece ışıkta ×1, dolunayda ×0,7, karanlıkta ×0,4; camp3'ün iki meşale direği gece yanar. Kışlak'ta dilim kipi kalkar: `timed` kip, dünya saati; Yeni Yurt ekibi `act1.md` §5 saat programındadır (Nanay 10:30–19:30, iki el 07:00–23:00), aşamayı malzeme ve ana adımlar kapılar (`labour.md` §10).
```

## D17. §10.4 İş tablosu

**Değiştir (ilk satır):** `Yüzde adım içi. Yuva yerel `(α°, r)`, kapı α=0, `(sin α·r, cos α·r)`.`
**Yeni:** `Yüzde adım içi; adımın gerçek süresi `stepSpanS = kalan İD / oran × 2,5` ile okunur (`dur` yok), uzun pencerede hareket döngüsü sürer (`loop`). Yuva yerel `(α°, r)`, kapı α=0, `(sin α·r, cos α·r)`. Dengiz her adımda çalışır, satırları `labour.md` §9.2; katılan Çocuğun satırları §11.6.`

**Değiştir:**
```
| | 40–90 | Üçü ya da Çocuk | 3 hamle: `uHoist.x` 6→4→2→0, her biri 0,9 sn | | `heave` | `uHoist.y` ±0,05 yalpa |
```
**Yeni:**
```
| | 40–90 | Üçü; Çocuk katıldıysa dördü | 3 hamle: `uHoist.x` 6→4→2→0, her biri 0,9 sn; tek el kaldığında 6 küçük hamle, yalpa ×1,5 | | `heave` | `uHoist.y` ±0,05 yalpa |
```

**Değiştir:**
```
| | 8–100 | İkisi | İç halkada, karşılıklı dilim. Sırık başı `reach_up` 0,9 + iniş 1,0 + `tie` 0,9 sn; iki ustayla 2,1 sn/sırık | `prop_pole` | `reach_up`, `tie` | `G_UUK*` |
```
**Yeni:**
```
| | 8–100 | İkisi; Dengiz yığından sırık getirir | İç halkada, karşılıklı dilim. Sırık başı `reach_up` 0,9 + iniş 1,0 + `tie` 0,9 sn hareket; adım emeği 270 İD, camp3 ekibiyle sırık başına ≈5,6 gerçek sn, arada `tie` döngüsü | `prop_pole` | `reach_up`, `tie` | `G_UUK*` |
```

## D18. §10.6 Ustaların sözleri, ek

**Yer:** son madde (`Bitişte, Oktar: …`) altı.
**Ekle:**
```
- Alacakaranlık, Erka: «Meşaleleri dikin. Gece işi bitirmez, ışık olsun yeter.» / «Plant the torches. Night won't stop the work, so long as there is light.»
- Gece, Oktar: «Karanlıkta düğüm parmakla görülür.» / «In the dark you see a knot with your fingers.»
- Yağmur, Oktar: «Keçeyi yağmura açmayız. Bekleyelim.» / «We don't open felt to the rain. We wait.»
- Çocuk katılınca, Oktar: «Gel. Yarım el de eldir.» / «Come. Half a hand is still a hand.»
- Kütük eksik, Dengiz: «Kütük eksik. Ben getiririm.» / «We're short of logs. I'll fetch them.»
- Su gelince, Dengiz: «Su mu? Sen olmasan kovaya ben koşacaktım.» / «Water? Without you I'd be running to the bucket.»
```

## D19. §11.5 Stok, uuk satırı

**Değiştir:** `| Uuk | (0.4, −1.2), görsel boy 3,6 m | 12 | `y_uuk` |`
**Yeni:** `| Uuk | (0.4, −1.2), görsel boy 3,6 m | 12; ilk 8'i dolu başlar, 4'ü kamp odunluğundan gelince dolar (§11.6) | `y_uuk` |`

## D20. §11.6, bölümün tamamı

**Değiştir:** `### 11.6 Zaman ve oyuncunun yardımı` başlığından `### 11.7 Tasarım seçimi` başlığına dek her şey.
**Yeni:**
```
### 11.6 Emek ve oyuncunun yardımı

**Ekip.** Dünya saatiyle ilerler (`d2/time.md`). İlk Serbest Gez girişinde saat 06:00–22:00 arasındaysa ustalar 20 sn (8 oyun dk) sonra gelir, `y_site` başlar; değilse ertesi 06:00'da. Oktar, Erka ve Dengiz baştan sona çalışır; öğün sırası ve gece §10.2. Emek yalnız Serbest Gez saati işlerken işler: menüde, haritada ve duraklatmada saat durduğu için durur; Bekle ve uyku atlamasında toplu işlenir. Yürüyen iş kadraj dışında da işler. Kalan süre HUD'da oyun saatiyle yazılır: «Ekip: 3 el · ≈3 saat» / «Crew: 3 hands · ≈3 hours».

| Durum (14:54 başlangıç, öğün sırası, gece meşalede) | İlk duman | Geçen oyun saati | Gerçek |
|---|---|---|---|
| Yardımsız (uuk başında Dengiz 4 kütüğe gider) | 00:16 | 9 sa 22 dk | 23,4 dk (1.405 sn) |
| Yalnız ayak işi: 4 kütük ve köz | 23:52 | 8 sa 58 dk | 22,4 dk |
| Yalnız katılma | 23:04 | 8 sa 10 dk | 20,4 dk |
| Katılma ve ayak işi | 22:46 | 7 sa 52 dk | 19,7 dk (1.181 sn) |
| Yardımsız, `Gece dinlenilsin` | Ertesi 08:16 | 17 sa 22 dk | 43,4 dk |

Saatsiz saf emek (öğünsüz): yardımsız 1.338 sn, bütün yardımla 1.125 sn. Adım adım süreler `labour.md` §9.1.

**Yardım: işçi katkısı.** Çocuk şantiyenin bir işini yaptığı sürece ekipte yarım el (0,5) ve bir baştır. Kredi, 3 kat erime ve adım başına sınırlar yoktur. Stokta ya da bir ustanın 4 m yakınında `E`: «Ustalara Katıl (yarım el)» / «Join the Builders (half a hand)»; Çocuk dördüncü işçi olur, `BuilderSystem` onu ustaların durum makinesiyle sürer, kamera izler; hareket girdisi çıkarır: «Ekipten ayrıldın» / «You left the crew». Yuva parlak halkadır (`Game.marker` gölgelendiricisi), istem `hud.setPrompt`. Ceza yok.

| id | TR / EN | Adım | Katılınca Çocuğun işi |
|---|---|---|---|
| `help_tamp` | Toprağı Çiğne / Tamp the Earth | `y_site` | Dairenin içinde çiğner |
| `help_carry` | Taşı / Carry | `y_bosaga`, `y_uuk`, `y_liner`, `y_sirdak` | Yığından yuvaya: 1 dikme, 2 sırık, 1 saz, 1 rulo |
| `help_hold` | Tut / Hold | `y_kerege`, `y_tuurduk` | Kanadı, panelin alt kenarını tutar |
| `help_tie` | Bağla / Tie | `y_bag`, `y_kolan` | Dış halkada düğüm tutar |
| `help_heave` | Çek / Heave | `y_tunduk` | Bakana omuz verir; çağrıda `E` (0,6 sn): tam hamlede yalpa yok, geçte yalpa ve gülüşme |
| `help_pull` | Halatı Çek / Haul the Rope | `y_uzuk` | Geri yürüyerek çeker |

**Ayak işleri** (katılmadan; Çocuk o sırada taşıyıcıdır, ekipte sayılmaz):

| id | TR / EN | Ne değişir |
|---|---|---|
| `help_log` | Kütük Getir / Bring a Log | Yığın uuk için 4 kütük eksik başlar (`node_camp_logs` (6.12,−5.75), stoğa 19,7 m, E 1,5 sn; Yük ve hız `progression.md` §2.5). Çocuk getirmezse uuk başında Dengiz dört kez gider: her sefer 26 gerçek sn ekipten çıkar |
| `help_ember` | Köz Getir / Bring an Ember | Ateşten (0,0) köz, 27 m. `y_ocak`'ın 20 İD'sinin 14'ü köz getirmektir: köz önceden yığına gelirse adım 6 İD'dir, Erka Çocuğa döner |
| `help_water` | Su Getir / Bring Water | Kova (−3.65, 0.2) yığına: bütün ekip 1 oyun saati (2,5 gerçek dk) ×1,1; en çok 4, arada 1 oyun saati |

`y_esik` iki kişilik, `y_ocak` tek kişiliktir: Çocuğa yuva açılmaz; ipucu «Kapı keçesi iki kişilik iş» / «The door felt is a two-person job».

**Bitiş.** İlk duman, `stage_done`, ustalar `CHEER`. Çocuk köz getirdiyse Erka ona döner, ateş başındaki dört kişi başlarını yurda çevirir (`lookAtPoint`, 4 sn). Kart: «Yeni yurt kuruldu / The new yurt stands». Ad `Otacı Yurdu / Healer's Yurt` olur. Yer adı inşaatta `hud.setPlace`: «Yeni Yurt · Kerege 3/6» / «New Yurt · Lattice Walls 3/6», r <10 m. İnşaat parçası ekibi ve bitişi yazar: «Ekip: 3 el · Akşam biter» / «Crew: 3 hands · Done at dusk»; Çocuk katılınca «Ekip: 3 el + sen» / «Crew: 3 hands + you» (`labour.md` §6.11).
```

## D21. §11.8 Hasar ve kayıt, şema ve açıklama

**Değiştir:** jsonc bloğunun tamamı (`{ "camp3": { "stage": 2, "hp": … "doneAt": null } }`).
**Yeni:**
```jsonc
{ "camp3": { "v": 2, "stage": 3, "hp": [0, 40, 60, 50, 0, 0, 0, 0], "wm": 514.7, "cut": 1, "burnT": 0, "stuck": 1,
    // bu belgenin eki
    "step": 5, "stepT": 0.31, "units": { "k0": 7.5, "door": 40 }, "fell": [],
    "tears": [[0.62, 0.72, 1.1, 0.4, 0]], "arrows": [[-14.1, 3.2, -17.9, 0.7, -0.2, -0.6, "w1"]],
    "contrib": { "player": 3, "npc": 19, "wm": { "player": 12.5, "npc": 502.2 } }, "helps": 12, "doneAt": null,
    // K21 eki (labour.md §14)
    "child": { "joined": false, "logs": 2, "ember": 0, "water": 1, "waterUntil": 1095.0, "waterNext": 1095.0 },
    "stock": { "short": { "tag:wood": 2 } }, "startMin": 1020.0 } }
```

**Değiştir:** `` `hp` havuz dizisidir, `t` işlenen saniye, `cut` yırtık sayısı, `stuck` saplı ok sayısı. ``
**Yeni:** `` `v` şema sürümü (1 → 2 göçü `labour.md` §14), `hp` havuz dizisidir, `wm` işlenen iş dakikası, `cut` yırtık sayısı, `stuck` saplı ok sayısı. ``

## D22. §13.3 Aşama, «Tavan» paragrafı

**Değiştir:** `` `?q=low`: usta en çok 2, yangın alevi ≤12. ``
**Yeni:** `` `?q=low`: Dengiz kukla ağıyla (≤1,2k üçgen) çizilir, ekipte sayılır (süre değişmez); yangın alevi ≤12. ``

**Yer:** «Tavan» paragrafının altı.
**Ekle:**
```
**K21.** Dengiz baştan sona çalışır: tablonun 2 ustalı her satırına +14k ana, +14k gölge, +3 / +3 çizim (`Folk` 14.078). Faz 6'nın ölçülen en kötü karesi +217k, +35 çizim → +245k, +41: tavan içinde. İki meşale direği `frame`'de ≈120 üçgen, çizim yok; alevler `fxFlames`, parıltı `fxGlow` havuzundan; ışık ve program eklenmez.
```

## D23. §14 Act 1 bağları, dört satır

**Değiştir:**
```
| `mq_first_tally`: ped, aşama 0 | `structures.spawn('yurt', { id: 'new_yurt', preset: 'winter', mode: 'slice', pad })`, `deliver('stone', 6, 'player')` |
| Yeni Yurt takvimi | `sliceTick()`: NPC 2 dilimde 1 aşama, malzeme gelirse dilim başına 1; aşama içi adımlar 1,5 sn'de birlikte; Gün IV akşamı `ensureStage(7)` |
```
**Yeni:**
```
| `mq_first_tally`: ped, aşama 0 | `sites.place('yurt', { id: 'new_yurt', preset: 'winter', mode: 'timed', pad, crew, schedule: 'kislak_new_yurt' })`, `deliver('stone', 6, 'player')` |
| Yeni Yurt takvimi | Dünya saati, ekip ve malzeme (`labour.md` §10.1): Nanay 10:30–19:30, iki el 07:00–23:00 pedde; Ambar her aşamanın malzemesini saatinde gönderir, oyuncu önceden getirirse o gönderim düşer; `y_tunduk` `mq_crown`'u (08:30), `y_ocak` `mq_feast` közünü bekler; Gün IV `b_feast` vaktinde eksik varsa `ensureStage(7)` |
```

**Değiştir:** `| `army.md` salvo, `cmd_camp` | `hit({ type: 'pierce', sdmg: 2 * n, … }, point, dir)`; Onluk çadırı `tent`, `mode: 'slice'` |`
**Yeni:** `| `army.md` salvo, `cmd_camp` | `hit({ type: 'pierce', sdmg: 2 * n, … }, point, dir)`; Onluk çadırı `tent`, `mode: 'timed'`, onluklar paralel kurar (`labour.md` §8.3); ordugâh günü `d2/time.md` §10.4 |`

**Değiştir:** `| `quick_raise`, `wagon_ring` | `buildTime`, `helpers`; `ringR` 14: 8 `fence` birimi, kuruluş 20 sn (`progression.md` §4.5) |`
**Yeni:** `| `quick_raise`, `wagon_ring` | `quick_raise`: Mete ekipteyken ×1/0,7, +1 el (`labour.md` §3); `wagon_ring` savaş düzenidir, emek yasası dışında: `ringR` 14, 8 `fence` birimi, kuruluş 20 sn (`progression.md` §4.5) |`

## D24. §15 Sonraki perde kancaları

**Değiştir:**
```
| Birlik, tümen (istek 13) | `crew` listesi `Squad.members` kabul eder; `oran` usta sayısıyla ölçeklenir (5–10 kişide ×2,2 tavan). `CampPlan = [{ kind, x, z, rot, preset }]`: tümen konaklaması `closed` LOD + 1–3 tam yapı, `sliceTick` |
```
**Yeni:**
```
| Birlik, tümen (istek 13) | `crew` listesi `Squad.members` kabul eder; oran `labour.md` §2 (`eff(W)`, yapı başına ≤8 el, fazlası taşır). `CampPlan = [{ kind, x, z, rot, preset }]`: tümen konaklaması `closed` LOD + 1–3 tam yapı; onluklar çadırlarını paralel kurar (≈2–3 gerçek dk); gece kesintisiz (K21), `Gece dinlenilsin` emriyle ordugâh penceresinde |
```

**Yer:** tablonun son satırı altı.
**Ekle:**
```
| Şantiye (K23) | `game/sites.js`: her `STRUCTURE_DEFS` türü için yerleşim, yığın ve taşıma, ekip atama, gece ve hava kesintisi, söküm, kayıt (`labour.md` §6) |
```

## D25. §16 İstek ve ilke çatışmaları, satır 2

**Değiştir:** `| 2 | 11: gerçekçi süre | Gerçek kurulum saat | 1:8, 9 dk 50 sn, sıra gerçek | Tempo; süre oyuncuya bırakılır, yardım hızlandırır |`
**Yeni:** `| 2 | 11: gerçekçi süre; K21 | Gerçek kurulum saat | Emek yasası, dünya saatinde: tek işçi 1 iş günü (60 dk), ekip azalan verimle; camp3 23,4 dk (14:54 → 00:16); sıra gerçek | K21; Çocuğun yardımı yarım el olarak hızlandırır |`

## D26. §17 Uygulama sırası ve kabul

**Değiştir:** `| 7 | Kışlak `winter`, `closed`, `slice`, Act 1 bağları | `world/winter-spec`, `game/quests` | 8, 9 |`
**Yeni:** `| 7 | Kışlak `winter`, `closed`, emek kipi, Act 1 bağları | `world/winter-spec`, `game/quests` | 8, 9 |`

**Yer:** uygulama tablosunun son satırı altı.
**Ekle:**
```
| 8 | Emek yasası ve Faz 6 yeniden çalışması (`labour.md` §12) | `game/labour.js`, `world/structure-defs.js`, `world/structure-logic.js`, `world/structure.js`, `game/builders.js`, `ui/hud/build-status.js` | K20 saati |
| 9 | Şantiye ve kum havuzu | `game/site-core.js`, `game/sites.js`, `world/site-pad.js` | 8 |
```

**Değiştir (panel):** `` `list()`, `get(id)`, `setStep(id, stepId, t)`, `hit(id, type, lx, y, lz)`, `ignite(id, lx, y, lz)`, `speed(k)`, `reset(id)`, `diff()` (no-op piksel farkı), `nav(on)` (katman üstü çizim). ``
**Yeni:** `` `list()`, `get(id)`, `setStep(id, stepId, t)`, `hit(id, type, lx, y, lz)`, `ignite(id, lx, y, lz)`, `speed(k)`, `reset(id)`, `diff()` (no-op piksel farkı), `nav(on)` (katman üstü çizim), `labour(id)` (ekip, oran, bitiş; `__tanhu.labour` `labour.md` §11.8). ``

**Değiştir (kabul 4):** `4. Yardımsız 590 sn ±5; bütün yardımlarla ≥283 sn.`
**Yeni:** `4. camp3 14:54 saatiyle ve öğünle yardımsız 1.405 sn ±15 (ilk duman 00:16), Çocuğun bütün yardımıyla 1.181 sn ±15; saatsiz saf emek 1.338 ve 1.125 sn ±10; tek işçi yurdu 60,0 dk ±0,1 (`labour.md` §15).`
