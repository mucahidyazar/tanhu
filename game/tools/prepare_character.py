#!/usr/bin/env python3
"""
Meshy'den gelen bir karakteri (assets/_meshy_raw/<id>/) oyuna hazırlar:
  1. Ana model: ilk planlı animasyonun GLB'si (iskelet + o klip) → assets/characters/<id>/<id>.glb.
     Planda ücretli animasyon yoksa (animations: []) iskelet görevinin modeli (<id>_rigged_character.glb, bağlama
     pozu T) ana modeldir; bekleme ve oturma klipleri sonra character_fit_tool.gd ile bağışçı karakterlerden
     aktarılır (satırın clip_donors'ı meta.json'a yazılır; Önsöz'ün yeni kişileri, 2026-11-05).
     Dokular satırın doku sınıfındaki oyun boyuna küçültülür (glb_prepare.py; --max-size sınıfı ezer); 8K kaynak korunur.
  2. Diğer klipler: yürüme, koşma ve kalan planlı animasyonlar → <id>_<rol>.res (tools/extract_animation.gd).
  3. meta.json: rol sırası, ek klipler, boy, kaynak bilgisi. Klasörde meta.json varsa (ör. yer tutucunun öyküsü,
     yaşı, düğüm yolu) silinmez: yalnız bu alanlar güncellenir, durum "meshy" olur.
  4. İskelet düzeltmesi ve kalibrasyon (K92, tools/rig_fix.py): dizler, omurga ve ayna farkı büyük omuz doğru yere taşınır; etek alanı
     (data/garment_weights.json'daki kişide, tools/garment_weights.py) ve parmak kemikleri (tools/hand_rig.py) aynı sırada yazılır; iskeletin sabiti
     data/rig_calibration.json'a yazılır. Düzeltilemeyen eklem hatası varsa araç hatayla durur: ana model eski hâline döner (yoksa
     silinir), klip ve meta.json yazılmaz, kişi kadroya girmez.
  Sonraki adımları araç bitince sırayla yazar: içe aktarma, doku sınıfı, rol klipleri, 120 klibin ölçüsü, dışa aktarma.

Roller: animasyon 243 (Idle 3) ve 244 (Idle 4) → idle, 363 (yerde bağdaş kurup oturma) → sit; yürüme/koşma iskelet görevinden gelir.
Kullanım: python3 tools/prepare_character.py <id> [--max-size=N]
"""
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rig_fix  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot")
ROLE_OF_ACTION = {243: "idle", 244: "idle", 363: "sit", 307: "talk", 300: "cheer"}
NAMES_TR = {"mete": "Mete", "hero_f": "Kadın kahraman", "mother": "Anne", "child": "Çocuk", "father": "Baba", "elder": "Yaşlı ozan",
            "teoman": "Teoman", "lan_hatun": "Lan Hatun", "older_brother": "Ağabey", "hereka": "Hereka",
            "hereka_young": "Hereka (39 yaşında)", "counter": "Sayıcı", "crowd_hun_man": "Hun eri",
            "crowd_hun_woman": "Hun kadını", "crowd_hun_rider": "Hun atlısı"}


def extract(src, dst_res, name):
    out = subprocess.run([GODOT, "--headless", "--path", ROOT, "-s", "res://tools/extract_animation.gd", "--", src, dst_res, name],
                         capture_output=True, text=True)
    line = [l for l in out.stdout.splitlines() if l.startswith("[extract]")]
    if not line or not line[0].rstrip().endswith("hata=0") or not os.path.exists(os.path.join(ROOT, dst_res[len("res://"):])):
        sys.exit("Klip çıkarılamadı: %s\n%s" % (src, out.stdout[-800:]))
    print("  " + line[0])


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    if len(args) != 1:
        sys.exit(__doc__)
    cid = args[0]
    plan = json.load(open(os.path.join(ROOT, "tools", "asset_plan.json"), encoding="utf-8"))
    asset = next(a for a in plan["assets"] if a["id"] == cid)
    raw = os.path.join(ROOT, "assets", "_meshy_raw", cid)
    out_dir = os.path.join(ROOT, "assets", "characters", cid)
    os.makedirs(out_dir, exist_ok=True)
    actions = asset.get("animations", [])
    if actions:
        main_src = os.path.join(raw, "%s_animation_%d.glb" % (cid, actions[0]))
        clip_roles = [ROLE_OF_ACTION.get(actions[0], "idle")]
    else:
        # Ücretli animasyon yok: iskeletli model ana modeldir, klipleri bağışçılardan gelir (clip_donors).
        main_src = os.path.join(raw, "%s_rigged_character.glb" % cid)
        clip_roles = []
    if not os.path.exists(main_src):
        sys.exit("Ana model yok: %s" % os.path.relpath(main_src, ROOT))
    print("[ana model] %s" % os.path.basename(main_src))
    texture_class = plan.get("texture_classes", {}).get(asset.get("texture_class", ""), {})
    size_arg = ["--max-size=%s" % opts["max-size"]] if "max-size" in opts else []
    main_glb = os.path.join(out_dir, cid + ".glb")
    previous = main_glb + ".onceki"
    # Klipler önce geçici adla çıkarılır, kişi sağlam çıkınca yerine geçer. Öldürülmüş koşudan kalan .onceki son sağlam modeldir: korunur.
    fresh = {}
    if os.path.exists(previous):
        if os.path.exists(main_glb):
            os.remove(main_glb)
    elif os.path.exists(main_glb):
        os.replace(main_glb, previous)
    try:
        subprocess.run([sys.executable, os.path.join(ROOT, "tools", "glb_prepare.py"), main_src, main_glb] + size_arg, check=True)
        plan_fix, changed, patched = rig_fix.apply_fix(cid)
        print("[iskelet] %d kemik düzeltildi, %d konum izi; %s" % (len(changed), patched, " | ".join(plan_fix["notes"]) or "eklem hatası yok"))
        problems = rig_fix.report([cid])
        if problems:
            sys.exit("İskelet düzeltilemedi: %s. Model kadroya alınmadı; tools/rig_fix.py'yi bu iskelete göre genişletin." % problems)
        extra = {}
        for src_name, role, clip in [("walking", "walk", "Walk"), ("running", "run", "Run")]:
            src = os.path.join(raw, "%s_%s.glb" % (cid, src_name))
            if os.path.exists(src):
                extract(src, "res://assets/characters/%s/%s_%s.yeni.res" % (cid, cid, role), clip)
                fresh[role] = "%s_%s" % (cid, role)
                extra[role] = "%s_%s.res" % (cid, role)
        for action in actions[1:]:
            role = ROLE_OF_ACTION.get(action, "anim_%d" % action)
            src = os.path.join(raw, "%s_animation_%d.glb" % (cid, action))
            extract(src, "res://assets/characters/%s/%s_%s.yeni.res" % (cid, cid, role), role.capitalize())
            fresh[role] = "%s_%s" % (cid, role)
            extra[role] = "%s_%s.res" % (cid, role)
        meta_path = os.path.join(out_dir, "meta.json")
        meta = {}
        if os.path.exists(meta_path):
            with open(meta_path, encoding="utf-8") as fh:
                meta = json.load(fh)
        input_image = asset.get("input_image", "assets/_concepts/%s.png" % cid)
        meta.update({
            "id": cid,
            "name": meta.get("name") or NAMES_TR.get(cid, cid),
            "role": meta.get("role") or ("player" if cid in ("mete", "hero_f") else "npc"),
            "file": cid + ".glb",
            "status": "meshy",
            "concept_image": input_image,
            "style_reference": meta.get("style_reference", "assets/_reference/style_mete.png"),
            "source": "assets/_meshy_raw/%s (8K doku, Ultra geometri, meshy-7.1)" % cid,
            "game_texture_size": int(opts["max-size"]) if "max-size" in opts else int(texture_class.get("size", 4096)),
            "height_m": meta.get("height_m") or asset.get("height_m"),
            "clip_roles": clip_roles,
            "extra_clips": extra,
            "description": meta.get("description") or asset.get("prompt", ""),
        })
        if asset.get("clip_donors"):
            meta["clip_donors"] = asset["clip_donors"]
        meta.pop("replace_with", None)
        with open(meta_path, "w", encoding="utf-8") as fh:
            json.dump(meta, fh, ensure_ascii=False, indent=2)
            fh.write("\n")
        for stem in fresh.values():
            os.replace(os.path.join(out_dir, stem + ".yeni.res"), os.path.join(out_dir, stem + ".res"))
    except BaseException:
        # Kişi yarım kalmasın: ana model yoksa kadroda yoktur (StandIn.has_model), varsa eski hâlidir; klipler ve meta.json eskidir.
        if os.path.exists(main_glb):
            os.remove(main_glb)
        if os.path.exists(previous):
            os.replace(previous, main_glb)
        for stem in fresh.values():
            leftover = os.path.join(out_dir, stem + ".yeni.res")
            if os.path.exists(leftover):
                os.remove(leftover)
        raise
    if os.path.exists(previous):
        os.remove(previous)
    try:
        rig_fix.calibrate(rig_fix.all_ids())
    except SystemExit as error:
        sys.exit("%s hazırlandı ve kadroda, ama kalibrasyon yazılamadı: %s\nEksiği giderip tools/rig_fix.py --calibrate koşun." % (cid, error))
    print("[tamam] %s → assets/characters/%s/" % (cid, cid))
    print("Uzun giysili kişide etek alanı için bir satır gerekir (data/garment_weights.json): python3 tools/garment_weights.py --suggest %s, sonra tools/rig_fix.py --apply %s" % (cid, cid))
    print("Sıradaki adımlar (game/ klasöründe):")
    print("  source tools/_godot_lock.sh && godot_import_locked")
    print("  python3 tools/glb_prepare.py --textures %s && godot_import_locked" % cid)
    print("  $GODOT --headless --path . -s res://scripts/character/character_fit_tool.gd -- --retarget %s" % cid)
    print("  $GODOT --headless --path . -s res://tools/anim_library_import.gd -- --measure %s" % cid)
    print("  $GODOT --headless --path . -s res://tools/clip_library_export.gd")
    print("  tools/run_tests.sh --filter=rig_health")


if __name__ == "__main__":
    main()
