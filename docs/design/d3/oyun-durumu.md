# Godot'daki oyunun bugünkü hâli (2026-11-04)

(2026-11-06: Bu liste 2026-11-04'ün kesitidir. Önsöz'ün bütünü, modeller, klip kütüphanesi ve çeşit ataması sonradan geldi; bugünkü durum Yol Haritası'ndadır, sayfaların «Oyunda şu an» kutuları o gün buna göre yazıldı.) (2026-11-07: kamera K98 ile uzak ve yüksek oldu, Çocukluk'un ilk fazı (`childhood-p1`) ve Yeni Oyun'un akışı (K99) geldi; Serbest Gez'de oluşturulan karakter değil Çocuk yürür.)

Bu liste sayfalardaki «Oyunda şu an» kutularının kaynağıdır. Kaynak: `game/README.md`, `game/scenes`, `game/scripts`, `game/tools/asset_plan.json`. Godot 4.7, Forward Plus, yalnız GDScript, 116 betik ve sahne, 516 birim testi.

## Oynanabilir

- **Açılış sözü:** Mete'nin sözü koyu ekranda, sonra menü (`scripts/ui/epigraph.gd`).
- **Ana menü:** gece kampının üstünde Tanhu 1'in logosu ve düğüm butonları: Yeni Oyun, Devam Et, Yükle, Destan Kitabı, Ayarlar, Çıkış, Serbest Gez (`scenes/ui/main_menu.tscn`).
- **Karakter oluşturma:** vücut, ten, saç, sakal, bıyık, göz; 3B önizleme döner ve yakınlaşır (`scenes/ui/character_creator.tscn`).
- **Kayıt:** 10 yuva, otomatik kayıt, küçük resim; bozuk kayıt boş sayılır (`scripts/save/`).
- **Ayarlar:** kamera dönüş hızı, fare hassasiyeti, kamera takibi, görüş açısı, ses veri yolları, çözünürlük, arayüz ölçeği; yalnız Türkçe (`scripts/ui/settings_panel.gd`).
- **Destan Kitabı:** Destan, Kişiler, Taşlar; kayıtlar kampta yapılanla açılır (`data/destan.json`).
- **Duraklatma kitabı:** Esc ile; kaydet, yükle, ayarlar, ana menü.
- **Gece kampı:** iki keçe yurt, ateş, ahır, iki at, ateş başında beş kişi (ana, çocuk, baba, Mete, elinde dombra olan yaşlı ozan), vadi, göl, dağlar, çam ormanı, çayır, patikalar (`scenes/world/world.tscn`).
- **Serbest Gez:** oluşturulan karakterle yürüme ve koşma; W her zaman ekranda yukarı (`scripts/player/player_controller.gd`).
- **Kamera:** menü açısıyla aynı (eğim 23,35°), başta 27 m; Q/E ve sağ tıkla döner, tekerlekle 6–40 m; araya giren dal ve kaya saydamlaşır. Eğim oyuncuya açık değil (`scripts/player/follow_camera.gd`). (K98 ile değişti, 2026-11-07: eğim 38°, görüş 36°, başta 28 m, Çocukluk'ta 22 m; tekerlek 14–40 m.)
- **Görünüm:** boyalı fırça efekti, yumuşak toon ışık, sis, sıcak renk tonu (`shaders/`, `scripts/ui/painterly_overlay.gd`).
- **Ses:** menü müziği, gece ambiyansı, ateş, at ve arayüz sesleri (ElevenLabs ile üretildi, `tools/elevenlabs_audio.sh`).

## Hazır araç ve varlık

- **Modeller:** Meshy ile 6 karakter (mete, mother, father, child, elder, hero_f), 2 at (horse_brown, horse_white), 2 yapı (yurt, stable), 12 kamp eşyası (barrel, bow, bucket, campfire, cauldron, crate, dombra, fence, firewood, saddlebags, stool, weapon_rack), 4 doğa nesnesi (pine_a, pine_b, boulder_a, boulder_b). Her birinin gpt-image-2 konsepti `assets/_concepts/` içinde. Model eksikse oyun kodla çizilen sade sürüme düşer.
- **Üretim hattı:** `tools/meshy_pipeline.py` konsepti Meshy'ye gönderir (meshy-7.1, 8K doku, 4K geometri, remesh, üçgen topoloji); karakterlere rig ve hareket ekler. Kredi: model 40, rig 5, hareket başına 3. Bütçe sınırı ve bakiye denetimi var, aynı görev iki kez açılmaz.
- **Testler:** `tools/run_tests.sh` (başsız), `docs/testler.md`.

## Yok

Mete'nin hikâyesi ve perdeler, görev ve diyalog, envanter, toplama, zanaat, ekonomi, saat ve takvim (gece sabittir), hava, emek ve aşamalı kurulum, hasar, dövüş, gizlilik, binicilik, hayvan davranışı, atlas haritası ve yolculuk, yerleşim, ordu, Kışlak dünyası, giriş sineması, seslendirme, İngilizce arayüz. Bunların bir kısmı Three.js prototipinde denendi (saat, hava, emek yasası, atlas, yapı aşamaları); Godot'a taşınmadı.
