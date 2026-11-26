# Referans kareler

Ekran görüntüsü karşılaştırmasının referansları (`../docs/design/godot.md` §8.5). Godot bu klasörü içe aktarmaz
(`.gdignore`). Nasıl karşılaştırıldığı `docs/testler.md`'nin «Menü karesi: referansla karşılaştırma» bölümündedir.

| Dosya | Komut (proje klasöründe, normal bir terminalden) | Alındığı |
|---|---|---|
| `menu.png` | `tools/capture.sh <çıktı.png> 360 --window=1920x1080 --freeze-time=12` | 2026-11-08: ahır üç yanı kapalı, önü açık (iki yan tahta duvar; ön bağlama korkuluğu oyun kopyasından kesildi) ve atlar iskeletli, beklerken klip oynar (ak at karede başını indirmiş, samandan yiyor); fark ahırdadır (eski referanstan %0,665). Önceki referans 2026-11-07'nin K98 karesiydi (menü kamerası uzak ve yüksek: ateşe 26,4 m, eğim 38°, görüş 36°); Apple M1 Pro, Metal, Godot 4.7.2 |

Karşılaştırma: `python3 tools/image_diff.py tests/refs/menu.png <çıktı.png>`; en az bir kanalı 8/255'ten çok değişen
piksel en çok %0,5 olabilir. Menü karesini bilerek değiştiren iş referansı aynı komutla yeniden alır.
