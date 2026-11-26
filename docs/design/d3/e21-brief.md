# E21 ajanlarının ortak kuralları (2026-11-09)

Bu dosya E21'in dört uygulama ajanının ortak kurallarıdır. Tasarım: `docs/design/decisions.md` K110; `docs/design/story.md` §3 «Göl Obası'nda üç gün» ve §5 «İki yeni gün»; `docs/design/act0-text.md` «Önsöz: Göl Obası'nda üç gün» ve «Çocukluk'un iki yeni günü»; sözlerin makinece okunan kopyası `docs/design/d3/e21-lines.json`.

## Ajanlar ve sahiplik

| Ajan | Sahip olduğu | Görevler |
|---|---|---|
| Ö1 | Önsöz'ün koşucusu ve akışı (`scripts/story/prologue_days.gd`, `data/story/prologue_days.json` sırası, `data/story/prologue_days/day1_*.json`), yeni oyun akışında `prologue` aşamasının başı, uyku ve günün kartı, «Önsözü geç», gün başı kayıt noktası, sinemaya geçiş API'si; kamp dünyasında Kayın Obası, yol, geçit, on iki kazık, yürünür alanın genişlemesi; tipi gecesi, köz kabı ışığı, eşlikçi Börü, kara yurdun ocağı, omuz sırığı ve dökülme, saba çalkalama | «Süt», «Tipi» |
| Ö2 | `data/story/prologue_days/day2_*.json`, `day3_*.json`; `scripts/story/steps/` altında `lambs_*`, `feast_*`, `wrestle_*`, `hearth_*` dosyaları; kuşak güreşi oyunu; menü ateşinin kurulması ve harlanması (ışığın evreyle büyümesi); balta ve taş kırma; kuzular; şilde gecesi | «Kuzular», «Şilde Gecesi», «Güreş», «Ocak» |
| Ç1 | Ordos dünyasının genişlemesi (`ordos_world.gd`, `childhood_ground.gd`, `childhood_scatter.gd`, `childhood_site.gd`, `data/maps/childhood_ordos/*`): Kamışlı Göl, Ebe Obası'nın yeri ve yurtları, yollar, kamera sınırı; çocukta yüzme; sürünün uzağa sürülmesi; Çocukluk'un günleri (`data/story/childhood_days.json` sırası, `data/story/childhood_days/day1_flock.json`), uyku ve günün kartı, «Çocukluğu geç» | «Çobanlık» |
| Ç2 | `data/story/childhood_days/day1_bone.json`, `day2_tally.json`; `scripts/story/steps/` altında `bone_*`, `tally_*` dosyaları; çocukların kovalamaca yapay zekâsı; ak kemik; Ebe Obası'nın kişileri ve köpekleri; çetele; sayım gününe tek söz (`data/story/childhood/scene.json`'da yalnız `count_stick`'in eklenmesi) | «Ak Kemik», «Ebenin Çetelesi» |

Ö1 ve Ç1 ilk yarım saatte koşucunun genişleme noktasını (adım türü kaydı: tür adı → ayrı betik) ve yerleri (Kayın Obası'nın, Kamışlı Göl'ün, Ebe Obası'nın noktaları, işaretleri) kurar ve şu dosyalara yazar: Ö1 `docs/design/d3/e21-prologue-api.md`, Ç1 `docs/design/d3/e21-childhood-api.md`. Ö2 ve Ç2 o dosya gelene dek kendi düzeneklerini ayrı ve birim sınamalı kurar, sonra bağlar. Dosya yoksa birkaç dakikada bir bakılır.

## Kurallar
- Türkçe yaz; kod yorumları Türkçe, tanımlayıcılar İngilizce; belgelerde tam Türkçe harfler.
- Sözlerin metnini değiştirme: metin `e21-lines.json`'daki gibidir, okunması kredi harcar. Değişmesi gereken söz varsa raporuna yaz, metni ana oturum değiştirir. Söz kimlikleri dosyadakilerdir (`act0.<görev>.<anahtar>`).
- Kredi harcayan çağrı yok (Meshy, ElevenLabs). Ses dosyası yoksa söz altyazıyla, metnin uzunluğundan süreyle oynar (bugünkü `SceneVoice` yolu). `data/vo_lines.json`'a dokunma.
- Klip kütüphanesinde olan klipleri kullan (`data/clip_library.json`): Stand_and_Drink, Sit_and_Drink, Sleep_Normally, Wake_Up_and_Look_Up, Collect_Object, Male_Bend_Over_Pick_Up, Female_Crouch_Pick_Up_Place_Side, Pull_Radish, Stand_To_Side_Lying, Sitting_Clap, Cheer_with_Both_Hands_Up, Stand_Clap_and_Sit_Down, Sit_Cross_Legged_on_Floor, Big_Wave_Hello ve öbürleri. Kütüphanede olmayan hareket (yüzme, balta, güreşte itme ve atma) kodla yer tutucu pozdur; gerçek klipler onayla gelir (Swim_Idle 568, Swim_Forward 569, Charged_Axe_Chop 237, Push_and_Walk_Forward 261, Grip_and_Throw_Down 389, falling_down 366): yer tutucu, kimliğiyle değiştirilebilir yazılır.
- Yeni kişilerin modeli var olandan gelir: kalabalık ağları ve `Folk` (`scripts/character/folk.gd`; çocuk ve yaşlının kalabalık modeli yok), yeniden boyama (`cloth_color`, bölge maskeleri). Börü için `luhun_child`, Saruk Ebe için uygun kadın ağı yeniden boyanır; Hereka (45) `hereka_young`'dır. Yeni Meshy modeli yok.
- `docs/design/decisions.md` ve `docs-app/content/progress.json`'a dokunma; ana oturum işler.
- Ortak dosyalarda yalnız küçük Edit blokları: `scripts/main.gd`, `scripts/core/session.gd`, `scripts/player/player_controller.gd`, `scripts/story/new_game_flow.gd`, `scripts/story/childhood_scene.gd`, `data/clip_library.json`.
- Aynı anda Kışlak'ın birleştirme ajanı çalışıyor: Kışlak'ın dosyalarına (data/maps/kislak, folk, fauna, travel, stable katmanları, grass_field, map_world'ün Kışlak kısmı) dokunma.
- Menü karesi değişmez (`test_main_menu`, `tests/refs/menu.png`). Kamp bütçesi dardır (B'nin ölçümü: görünür 3,41M üçgen, sınır 3,5M): Kayın Obası kodla kurulan yurdun uzaklık kademesini (B'nin `yurt_field`'i) ve kalabalık kademelerini kullanır, ölçülür.
- K1: soğuk yoktur (tipide görüş ve rüzgârın itişi var). K3: kurt yalnız sesiyle. K98: her çekim uzak ve yüksektir (oynanışta takip kamerası 22–28 m, 38°; yurdun içi çatısız diorama gibi yukarıdan). K105: hiçbir kişi oyuncunun en yüksek koşusunu aşmaz (çocukta 3,6 m/sn). Ceza yok: dökülen süt, kaybedilen güreş, geç bulunan kuzu sözü değiştirir, görevi bitirmez. Boşluğu tasarımla doldur, sorma (K87); kararını raporuna yaz.
- Oyuncunun gerçek kaydına ve ayarlarına dokunma (`~/Library/Application Support/Tanhu Bozkir Destani/`); argümanlı geliştirme koşuları yazmaz. API anahtarlarına dokunma.
- Sınamalar: `tools/run_tests.sh --filter=<ad>`; tam koşu yok (ana oturum koşar). İçe aktarma: `source tools/_godot_lock.sh; godot_import_locked`. Kare: `tools/capture.sh <png> <kare> --window=1920x1080 --freeze-time=12` (kum havuzu kapalı); kareler `docs/media/review/e21_<görev>_*.jpg`. Bütçe: `--scene=res://scenes/dev/budget_probe.tscn --probe=camp|childhood|birth` ve gerekirse yeni nokta; `tools/check_budget.py <json> --baseline=data/budget_baseline.json`; kum havuzu kapalıyken mutlak `/tmp/claude-501/...` yolu.
- Belgeler: kendi kısmının oyundaki hâlini `docs/design/godot.md`'ye ve docs-app'in `story/prologue`, `story/childhood` sayfalarına kısa yaz; `npm --prefix docs-app run check` temiz kalsın.

## Rapor
Kısa, şu başlıklarla: Ne yapıldı / Ölçüt tablosu / Dosyalar (ortak dosyalardaki bloklar ayrı) / Sınamalar / Kareler / Bütçe / Tasarım boşluğu kararları / Ana oturumun bilmesi gerekenler / Doğrulanamayanlar.
