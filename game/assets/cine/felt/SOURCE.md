# Mit sinemasının keçe pano görselleri

Bu klasör Önsöz'ün mit sinemasının (`scenes/cine/prologue_myth.tscn`) gpt-image-2 görselleri içindir (Yol Haritası `myth-panels`, E2: kredisiz, kullanıcının ChatGPT planıyla). gpt-image-2 kotası 2026-11-05'te doluydu: panolar bugün kodla çizilen şekillerle ve `shaders/felt_panel.gdshader` ile kuruludur.

- **İstemler:** her panonun istemi `data/cine/myth_panels.json`'da `panels[].prompt`'tadır.
- **Ad:** görsel Varlıklar kataloğunun kimliğiyle konur: `fx_panel_water_geese.png`, `fx_panel_stone.png`, `fx_panel_erlik_tree.png`, `fx_panel_sky_tent.png`, `fx_panel_first_dead.png`, `fx_panel_birth_yurt.png` (`panels[].catalog`). Pano 1'in eski konsepti (`assets/_concepts/fx_panel_water_geese.png`) kazları Kanada kazı gibi çizdiği için yeniden üretilir.
- **Oyuna alış:** görselin yolu `panels[].image`'a yazılır; `felt_panel.gdshader`'ın `use_albedo_texture` ve `albedo_rect`'i panonun katmanını o dokuyla çizer.
- **Keçe dokusu:** parçaların lifi ve normali ücretsiz Fabric034'ten gelir (ambientCG, CC0 1.0, Lennart Demes): `assets/_free/texture/fabric034/` (K89, E7.5; kaydı `assets/_free/FREE_ASSETS.json`, kullanımı `assets/_free/usage.jsonl`).
