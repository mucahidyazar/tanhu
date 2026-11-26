# `structures.md` değişiklikleri: Zaman ve Takvim (K20)

> **Yerini aldı, işlenmez (2026-11-03, K26).** `structures.md` yalnız `d2/structures-delta.md` ile işlenir; bu dosyanın maddeleri (S1–S7) oraya indirildi. Dosya iz için kalır. S2'nin 22:00 durağı K21'e aykırıdır: inşaat ışıkta gece de sürer (`d2/core.md` §2.5).

Kaynak: `d2/time.md` §8.3, §10.1. Faz 7 bitince işlenir. Bu dosya yalnız **saat yüzünü** bağlar: ustaların saatleri, iş penceresi, atlamada ilerleme, `slice` kipinin kalkması. Emek miktarı, ekip eğrisi (`eff`), adım süreleri ve 590 sn çizelgesinin yerine gelen sayılar K21'in (emek alanı) kendi delta dosyasındadır; iki dosya aynı satıra dokunursa K21'in sayısı, bu dosyanın saati geçerlidir. Her madde bölüm başlığı, birebir bulunacak metin ve yeni metinle verilir.

## S1. §2.2 Veri biçimi

**Bul:**
```
  constructor(def, place, world, { mode: 'timed' | 'slice', preset, startFull })
```
**Yerine:**
```
  constructor(def, place, world, { mode: 'timed', preset, startFull })   // K20: 'slice' kipi kalktı; Kışlak da dünya saatiyle
```

**Bul:**
```
  advance(dtWork);                    // zaman modu
  sliceTick();                        // Kışlak dilim modu (§14)
```
**Yerine:**
```
  advance(dtWork);                    // iş: ekip × oyun dakikası (K21 iş dakikası); atlamada pencere içi toplu çağrı
```

## S2. §10.2 Durum makinesi

**Bul:** `**Yol.** A* kullanılmaz (kapıdan arkaya 64,8 ms ölçüldü).` ile başlayan paragrafın sonu (`…yalnız yürüme ızgarası.`)
**Sonrasına ekle:**
```
**Ustaların günü (K20, d2/time.md §8.3).** Ustalar dünya saatiyle çalışır. Ana kampta 06:00'da kuzey yamaçtaki usta girişinden (−4,5; −31) gelir, iş penceresi 06:00–22:00'dir (16 oyun saati, `econ-model.json` `prodHoursPerDay`); 12:00 ve 18:30 öğünlerinde sırayla 30'ar dakika ateş başına oturur, iş biri çalışırken sürer. Batıştan (18:38) sonra iş ocak ve meşale ışığında sürer, gece verimi K21'in `law.night`'ıdır. 22:00'de kuzeye çıkarlar; pencere dışında yardım yuvası açılmaz. Kışlak'ta pencere 07:00–23:00'dir. Bekleme ve uykuda (`clock:skip`) ekip yalnız pencere içindeki dakikalar kadar ilerler, ustalar programdaki yerine konur (karartma altında). Yapı bitince Erka Otacı Yurdu'nun programına geçer, Oktar üç günde bir akşam aşına gelir.
```

## S3. §10.3 İş oranı

**Bul:** `Kışlak'ta `slice` kipi: zaman yok, usta `schedule` süsüdür.`
**Yerine:** `Kışlak'ta da `timed` kip: dünya saati, ustalar `act1.md` §5 saat programında ve iş penceresinde (07:00–23:00); aşamayı malzeme ve ana adımlar kapılar (K21).`

## S4. §11.6 Zaman ve oyuncunun yardımı

**Bul:** `Yalnız `state === 'freeroam'` iken ilerler; hızlı yolculukta, menüde ve haritada durur. Yürüyen iş kadraj dışında da işler.`
**Yerine:** `Dünya saatiyle ilerler (`d2/time.md`): yalnız `freeroam`'da ve ustaların iş penceresinde (06:00–22:00); menüde, haritada ve duraklatmada saat durduğu için durur. Bekle ve uyku atlamasında pencere içindeki dakikalar toplu işlenir. Yürüyen iş kadraj dışında da işler. Kalan süre HUD'da oyun saatiyle yazılır: «Yeni Yurt · Kerege 3/6 · ≈3 saat» / «New Yurt · Lattice Walls 3/6 · ≈3 hours».`

**Bul:** `**Normal hız: 590 sn = 9 dk 50 sn.** İlk Serbest Gez girişinden 20 sn sonra ustalar gelir, `y_site` başlar.`
**Yerine:** `**Süre K21'indir** (emek alanının delta dosyası). İlk Serbest Gez girişinde saat iş penceresindeyse ustalar 20 sn (8 oyun dk) sonra gelir, `y_site` başlar; pencere dışındaysa ertesi 06:00'da.`

## S5. §14 Act 1 bağları

**Bul:** `| `mq_first_tally`: ped, aşama 0 | `structures.spawn('yurt', { id: 'new_yurt', preset: 'winter', mode: 'slice', pad })`, `deliver('stone', 6, 'player')` |`
**Yerine:** `| `mq_first_tally`: ped, aşama 0 | `structures.spawn('yurt', { id: 'new_yurt', preset: 'winter', mode: 'timed', pad })`, `deliver('stone', 6, 'player')` |`

**Bul:** `| Yeni Yurt takvimi | `sliceTick()`: NPC 2 dilimde 1 aşama, malzeme gelirse dilim başına 1; aşama içi adımlar 1,5 sn'de birlikte; Gün IV akşamı `ensureStage(7)` |`
**Yerine:** `| Yeni Yurt takvimi | Dünya saati: Nanay ve işçiler iş penceresinde (07:00–23:00) `advance`; aşamayı malzeme ve ana adımlar kapılar (K21); Gün IV `b_feast` vaktinde `ensureStage(7)` |`

**Bul:** `| `army.md` salvo, `cmd_camp` | `hit({ type: 'pierce', sdmg: 2 * n, … }, point, dir)`; Onluk çadırı `tent`, `mode: 'slice'` |`
**Yerine:** `| `army.md` salvo, `cmd_camp` | `hit({ type: 'pierce', sdmg: 2 * n, … }, point, dir)`; Onluk çadırı `tent`, `mode: 'timed'`, ordugâh iş penceresi (d2/time.md §10.4) |`

## S6. §15 Sonraki perde kancaları

**Bul:** `` `CampPlan = [{ kind, x, z, rot, preset }]`: tümen konaklaması `closed` LOD + 1–3 tam yapı, `sliceTick` ``
**Yerine:** `` `CampPlan = [{ kind, x, z, rot, preset }]`: tümen konaklaması `closed` LOD + 1–3 tam yapı, iş penceresinde `advance`; gece vardiyası emirle (`night: true`, bedeli K21/K23) ``

## S7. §16 İstek ve ilke çatışmaları

**Bul:** `| 2 | 11: gerçekçi süre | Gerçek kurulum saat | 1:8, 9 dk 50 sn, sıra gerçek | Tempo; süre oyuncuya bırakılır, yardım hızlandırır |`
**Yerine (yalnız «Uygulanan» hücresi, sayı K21'in):** `| 2 | 11: gerçekçi süre | Gerçek kurulum saat | K21: yurt 1 iş günü (tek işçi 60 dk), dünya saatinde; ustalar iş penceresinde | Tempo; süre oyuncuya bırakılır, yardım hızlandırır |`
