# Tanhu Belgeleri

Oyunun belgeleri: oku, not al, düzelt, sürümle. Yerelde çalışır, veriler bu klasördeki dosyalardadır.

```bash
npm install
npm run dev
```

Adres: http://127.0.0.1:3100. Proje kökünden: `npm --prefix docs-app run dev`.

## Ne nerede

| Yol | Ne |
|---|---|
| `content/pages/<kategori>/*.md` | Derlenmiş sayfalar; yazım kuralları `content/YAZIM.md` |
| `content/progress.json` | Yol Haritası: perdeler, fazlar, maddeler, durumları, kanıt yolları ve işaret geçmişi (yazmadan önce `progress.json.bak` kopyası alınır) |
| `content/encyclopedia.json` | Ansiklopedi: bölümler ve kayıtlar |
| `src/lib/legacy-ids.json` | Eski Türkçe adreslerin İngilizce karşılıkları; yönlendirmeler buradan üretilir |
| `../docs/design`, `../docs/research` | Kaynak belgeler; site onları olduğu gibi gösterir, düzenleme doğrudan o dosyaya yazılır |
| `../game`, `../game/docs` | Godot projesinin belgeleri; «Kaynak belgeler» altında görünür |
| `../docs/assets/catalog.json` | Varlık kataloğu: her varlığın türü, 3B gereği, en mantıklı üretim yolu, Meshy kredisi, görseli |
| `../docs/assets/thumbs/<id>.webp` | Varlıkların 320 piksellik küçük görselleri (`npm run concepts` yazar) |
| `../game/assets/_concepts/<id>.png` | Konsept görselleri; Godot'nun Meshy hattı da buradan okur, yanında `<id>.ok` onaylı demektir |
| `data/history/<belge>/` | Her belgenin bütün sürümleri, tam metin; `revisions.json` dizin |
| `data/notes.json` | Notlar: belge, bölüm, alıntı, metin, durum |
| `data/pins.json` | Kenar çubuğunda Ara'nın altına sabitlenen sayfalar, sırasıyla |
| `data/releases.json` | Damgalanmış belge sürümleri (v0.1, v0.2): her belgenin o anki sürüm numarası |
| `data/review.json` | Gözden geçirme işaretleri |

## Sürümleme

- Her kayıt yeni sürüm açar; hiçbir sürüm silinmez, eski sürüme dönmek de yeni sürümdür.
- Dosya uygulama dışından değişirse (elle ya da başka bir araçla) belge açılınca «Uygulama dışından» diye yeni sürüm olarak yakalanır.
- **Sürümler** sayfası bütün belgeleri birlikte damgalar.

## Listeler

- **Yol Haritası** (`/roadmap`): oyunun yapım sırası ve Godot'da yapılanlar tek sayfada: Perde > Faz > Madde. Perdenin hedefi, fazın önkoşulu ve çıkış ölçütü burada. Her madde Yapılacak, Sürüyor ya da Bitti diye işaretlenir; not eklenebilir, her işaret geçmişe yazılır. Maddenin kanıt yolları `game/` altında varsa yeşil görünür. Plan `content/progress.json` dosyasıdır (`acts`, `phases`, `items`; madde `phase` alanıyla faza, faz `act` alanıyla perdeye bağlanır); Godot'da bir madde bitince orada da işaretlenir. Sayfalar `ilerleme` bloğuyla bir perdenin ya da fazın canlı listesini gösterebilir.
- **Varlıklar** (`/assets`): oyunun bütün varlıkları, türlerine göre ayrı tablolarda: görsel, 3B gerekli mi, 3B modeli var mı, en mantıklı üretim yolu ve Meshy'nin en kaliteli en son modeliyle kredisi. Bir sayfa `varlik` bloğuyla varlık görseli gösterebilir; kataloğun `design` alanı bir sayfayı gösteriyorsa varlık o sayfanın sonunda da görünür (biçim `content/YAZIM.md`).
- **Karar Bekleyenler** (`/docs/general/pending-decisions`): kullanıcı kararı bekleyen her şey tek sayfada; sayfalardaki çözülmemiş `[!ACIK]` ve `[!CELISKI]` kutuları sayfanın altında kendiliğinden listelenir. Ayrı açık sorular sayfası yoktur.
- **Ansiklopedi** (`/encyclopedia`): mitoloji ve önemli kişiler, açık parşömen bir kitap: solda portreli dizin ve arama, ortada görsel (Profil, Art, 3B modeli varsa döndürülebilir model, yoksa T-poz), sağda numaralı bölümler, bilgi satırı, soy bağları ve kaynak notu. Başlığın yanındaki hoparlör kişinin kendini iki cümleyle tanıttığı sesi çalar (İngilizce, Türkçesi altyazı). Veri `content/encyclopedia.json` (biçim `src/lib/encyclopedia.ts`); görselleri `npm run concepts -- --encyclopedia` üretir (önce art, profil ve T-poz art'tan), sesleri `node scripts/intro-voices.mjs cast | cost | gen`. Tuşlar: Q / E bölüm, ↑ / ↓ kişi, ← / → görsel, Enter görseli büyüt, Esc geri.
- **Notlar** (`/notes`): senin notların tek sayfada. «Açık» ve «Çözülen» sayfalara düştüğün notlardır (türleri Düzeltilecek, Karar, Soru, Fikir); «Yazdığın notlar» (`/notes?view=written`) elle yazdığın tasarım notlarının ham metni ve her maddesinin hangi sayfaya gittiği (dosyası `content/pages/general/my-notes.md`, eski Notlarım sayfası).
- **Animasyonlar** (`/animations`): bir karakter seçilir, kütüphanenin 120 klibi o karakterde oynar (K90). Klip listesinin en üstünde «Sahnede oynar» (kişinin bugün sahnede oynadığı klipler) ve «Bu kişinin çeşitleri» (sahnesiz varsayılan; bugün rolü olan öbekler ve sahnesi olmayanlar ayrı) durur, altında öbek öbek bütün klipler; oyuncu karakteri çeşit almaz (K91). Arama ad, etiket, anahtar (yazıldığı gibi) ve belgelerin öbek sözcükleriyle süzer. Veri `../docs/assets/animations/manifest.json` ve karakter başına GLB'dir (`game/tools/clip_library_export.gd` yazar, elle düzenlenmez; okuyucu `src/lib/animations.ts`). Adres paylaşılabilir: `?character=<id>&clip=<anahtar>&group=<öbek>&q=<arama>`.
- **Kenar çubuğu**: her satırın sağındaki raptiye o sayfayı Ara'nın altına sabitler; sabitlenenlerin sırası sürükle bırakla (dokunmatik ekranda soldaki tutamaçtan) ya da tutamaç odaktayken Alt + ↑ / ↓ ile değişir. Altta «Oyun» (Yol Haritası, Ansiklopedi, Görevler, Animasyonlar, Varlıklar) ve «Çalışma» (Notlar, Karar Bekleyenler, Sürümler) başlıkları durur.

## Araçlar

```bash
npm run check
```

Sayfa denetimi: ön bilgi, kırık bağ, eksik bölüm, eksik medya, katalogda olmayan varlık, kalan açık kutular.

```bash
npm run animations
```

Animasyonlar sayfasının saf kuralları, bugünkü manifest'le: klip araması, oyuncu karakterinin çeşit almaması, sahnenin seçimi ve klibin kişideki yeri, döngü etiketi, kameranın geri çekilmesi, adresteki öbeğin açtığı klip, kaynak satırının dili. Tarayıcı açmaz.

```bash
npm run progress -- --baseline=eski-progress.json
```

İlerleme dosyasının denetimi: düzen, tekil kimlikler, durumlar, tasarım bağları. `--baseline` ile eski dosyada bitmiş ya da süren her maddenin durumunu ve geçmişini koruduğunu sınar.

```bash
npm run concepts -- --jobs=3
```

Katalogda görseli olmayan ve önceliği 1 olan varlıkların konseptini gpt-image-2 ile üretir (Codex CLI, ChatGPT hesabı; kredi harcamaz, kota sınırlıdır), küçük görselleri yazar. Yarıda kalırsa kaldığı yerden sürer. `--all` önceliği 2 olanları da katar, `--only=id1,id2` yalnız onları, `--thumbs` yalnız küçük görselleri yeniden yazar. 3B üretimi bu araçta yoktur: Meshy kredi harcar, onaydan sonra Godot'nun `game/tools/meshy_dispatch.py` aracıyla yapılır.

## Notları tasarıma işlemek

Bu sitedeki sayfalar `docs/design` belgelerinin özetidir, oyunun geliştirilmesinde bağlayıcı olan onlardır. Sayfada yapılan düzeltme ya da alınan not kendiliğinden tasarım belgelerine geçmez. Bir oturumda «kararları ve notları işle» denince `data/notes.json` ve Sürümler sayfasındaki değişiklikler okunup belgelere ve koda işlenir.

Kaynak belgeyi (`/docs/source/...`) düzenlemek ise doğrudan `docs/` altındaki dosyayı değiştirir.
