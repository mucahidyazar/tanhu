# Tanhu

Hun Tanhusu Mete'nin hayatını perde perde anlatan, Godot 4.7 ile yapılan açık dünya rol yapma oyunu. Bu klasörde oyun, tasarım belgeleri ve belgeleri okuyup not almak için kurulan site birlikte durur.

| Klasör | İçinde ne var |
|---|---|
| [`game/`](game/README.md) | Godot projesi (`project.godot`, adı «Tanhu»). Sahneler, betikler, varlıklar, testler ve üretim araçları |
| `docs/design/` | Bağlayıcı tasarım belgeleri. Çelişkide `decisions.md` kazanır |
| `docs/research/` | Araştırmalar ve prototipin ekran görüntüleri |
| `docs/media/` | Sitenin gösterdiği portre ve ses kopyaları |
| [`docs-app/`](docs-app/README.md) | Belge sitesi: okuma, not, sürüm, İlerleme ve varlık sayfaları |

## Oyunu açma

Godot 4.7'nin Proje Yöneticisi'nde **Tanhu**'yu seç (listede yoksa **İçe Aktar** ile `game/project.godot`). Ayrıntılar ve tuşlar `game/README.md`'de. Testler:

```bash
game/tools/run_tests.sh
```

## Belge sitesi

```bash
npm --prefix docs-app run dev
```

Adres: http://127.0.0.1:3100. **İlerleme** sayfası Godot'da yapılanları izler; bir iş bitince oradan işaretlenir. Plan dosyası `docs-app/content/progress.json`.

## Depoda olmayanlar

- Oyunun sinema videoları (`game/assets/cine/video/*.ogv`) Git LFS ile durur: klonlamadan önce `git lfs install`.
- Ham Meshy indirmeleri (`game/assets/_meshy_raw`, ≈9 GB) depoda değildir; oyun bunları yüklemez (`.gdignore`). Depoda yalnız görev kayıtları (`meshy.json`) vardır.
- Godot'nun içe aktarma önbelleği (`game/.godot/`) ilk açılışta yeniden üretilir. Belge sitesinin bağımlılıkları `npm --prefix docs-app install` ile kurulur.
- 100 MB'ı aşan üç inceleme videosu (`docs/media/review/mit_sinemasi*.mp4`, `kopru_1.mp4`) ve yerel yedekler (`backups/`) dışarıdadır.

## Öteki Tanhu projeleri

- `../tanhu-2d/`: Tanhu 2D (belgelerde «Tanhu 1»), ilk oyun (Godot, 2B). Yalnız ilham kaynağıdır; kadrosu ve senaryosu kopyalanmaz.
- `~/Code/tests/tanhu-programatic-test/`: Three.js ile kodla üretim prototipi. Tasarım belgeleri ilk orada yazıldı; `docs/design` ve `docs/research` şimdi buraya bağlıdır.
