#!/usr/bin/env python3
"""
Bütçe denetimi (godot.md §7.4, K63): bütçe ölçümünün (scenes/dev/budget_probe.tscn) JSON sonucunu
data/budgets.json'daki sınırlarla karşılaştırır. Her pozun her ölçüsü sınanır: sınıra dek tamam, sınırın %3
üstüne dek uyarı, daha üstü hata. Kare süresi pozun 180 karesinin ortalamasıdır; hedefin (kampta 16,7 ms)
üstü yalnız uyarıdır, sınırın (33 ms) üstü kuraldır. Çizim ve üçgen pozdaki en büyük değerdir. Çimeni gizli
pozlar sınanmaz: yalnız çimenin payını verirler (ölçümün grass_share satırı).

Kullanım:
  python3 tools/check_budget.py <ölçüm.json> [--budgets=data/budgets.json] [--row=camp]
                                [--baseline=data/budget_baseline.json] [--all]

  --row=camp        Sınanacak satır (varsayılan: ölçümün kendi satırı).
  --baseline=yol    Taban ölçümüyle karşılaştır: her ölçünün en kötü değeri ve tabana göre farkı.
  --all             Her pozun satırını yaz (varsayılan: özet, uyarı ve hata satırları).

Çıkış kodu: 0 = hata yok (uyarı olabilir), 1 = en az bir hata, 2 = dosya okunamadı ya da biçim yanlış.
"""
import json
import os
import signal
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_BUDGETS = os.path.join(ROOT, "data", "budgets.json")

# Sınanan ölçüler: (ölçümdeki alan, istatistik ya da None, bütçedeki anahtar, ad, birim).
METRICS = [
    ("frame_ms", "mean", "frame_ms_limit", "Kare süresi, ortalama", "ms"),
    ("script_ms", "mean", "script_ms", "Süreç adımı (GDScript), ortalama", "ms"),
    ("draw_calls_visible", "max", "draw_calls_visible", "Görünür çizim", ""),
    ("draw_calls_shadow", "max", "draw_calls_shadow", "Gölge çizimi", ""),
    ("triangles_visible", "max", "triangles_visible", "Görünür üçgen", ""),
    ("triangles_shadow", "max", "triangles_shadow", "Gölge üçgeni", ""),
    ("texture_mib", None, "texture_mib", "Doku belleği (3B malzeme dokuları)", "MiB"),
    ("video_mib", None, "video_mib", "Video belleği", "MiB"),
]
# Yalnız bilgi için yazılanlar (sınırı yok).
INFO = [
    ("frame_ms", "p95", "Kare süresi, %95'lik dilim", "ms"),
    ("gpu_ms", "mean", "GPU çizim süresi, ortalama", "ms"),
    ("cpu_ms", "mean", "CPU çizim süresi, ortalama", "ms"),
    ("objects_visible", "max", "Görünür nesne", ""),
    ("objects_shadow", "max", "Gölge nesnesi", ""),
    ("texture_counter_mib", None, "Doku sayacı (RENDER_TEXTURE_MEM_USED)", "MiB"),
    ("buffer_mib", None, "Tampon belleği", "MiB"),
]
SCENE = [
    ("positional_lights", "Konumsal ışık"),
    ("positional_lights_shadowed", "Gölgeli konumsal ışık"),
    ("audio_players", "Çalan ses oynatıcısı"),
]
STATUS_ORDER = {"tamam": 0, "bilgi": 0, "uyarı": 1, "hata": 2}
# Viewport.MSAA sayıları.
MSAA_NAMES = {0: "kapalı", 1: "2x", 2: "4x", 3: "8x"}


class BudgetError(Exception):
    pass


def load_json(path, what):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError) as e:
        raise BudgetError(f"{what} okunamadı: {path}: {e}")


def judge(value, limit, tolerance):
    """Değerin sınıra göre durumu: tamam, uyarı (sınırın tolerance kadar üstüne dek) ya da hata."""
    if limit is None:
        return "bilgi"
    if value <= limit:
        return "tamam"
    if value <= limit * (1.0 + tolerance):
        return "uyarı"
    return "hata"


def pose_value(pose, field, stat):
    value = pose.get(field)
    if value is None:
        return None
    if stat is None:
        return float(value)
    if not isinstance(value, dict) or stat not in value:
        return None
    return float(value[stat])


def fmt(value, unit):
    if value is None:
        return "—"
    if unit == "ms":
        return f"{value:.2f} ms"
    if unit == "MiB":
        return f"{value:.1f} MiB"
    if value >= 100000:
        return f"{value / 1e6:.2f}M"
    return f"{value:.0f}"


def checked_poses(report):
    """Sınanan pozlar: çimenli olanlar (menü karesi dahil); çimensizler yalnız çimenin payıdır."""
    poses = report.get("poses")
    if not isinstance(poses, list) or not poses:
        raise BudgetError("ölçümde poz yok (poses)")
    return [p for p in poses if isinstance(p, dict) and p.get("grass", True)]


def evaluate(report, row, tolerance, scene_limits):
    """Her ölçünün en kötü değeri ve durumu; pozların uyarı ve hata satırları."""
    poses = checked_poses(report)
    summary = []
    findings = []
    for field, stat, key, label, unit in METRICS:
        limit = row.get(key)
        worst = None
        worst_pose = None
        for pose in poses:
            value = pose_value(pose, field, stat)
            if value is None:
                continue
            state = judge(value, limit, tolerance)
            if state in ("uyarı", "hata"):
                findings.append((state, label, pose.get("id"), value, limit, unit))
            if worst is None or value > worst:
                worst, worst_pose = value, pose.get("id")
        summary.append({"label": label, "value": worst, "pose": worst_pose, "limit": limit, "unit": unit,
                        "state": judge(worst, limit, tolerance) if worst is not None else "bilgi",
                        "field": field, "stat": stat})
        if field == "frame_ms" and worst is not None and row.get("frame_ms_target") is not None:
            target = row["frame_ms_target"]
            over = [p.get("id") for p in poses if (pose_value(p, field, stat) or 0.0) > target]
            summary.append({"label": "Kare süresi hedefi", "value": worst, "pose": worst_pose, "limit": target,
                            "unit": unit, "state": "uyarı" if over else "tamam", "field": field, "stat": stat,
                            "note": f"{len(over)} poz hedefin üstünde" if over else "bütün pozlar hedefin altında"})
    gpu_timing = report.get("device", {}).get("gpu_timing", True)
    for field, stat, label, unit in INFO:
        if field == "gpu_ms" and not gpu_timing:
            summary.append({"label": label, "value": None, "pose": "—", "limit": None, "unit": unit, "state": "bilgi",
                            "field": field, "stat": stat, "note": "sürücü GPU zamanını bildirmiyor"})
            continue
        values = [(pose_value(p, field, stat), p.get("id")) for p in poses]
        values = [v for v in values if v[0] is not None]
        if values:
            value, pose_id = max(values, key=lambda v: v[0])
            summary.append({"label": label, "value": value, "pose": pose_id, "limit": None, "unit": unit,
                            "state": "bilgi", "field": field, "stat": stat})
        elif field == "texture_counter_mib":
            summary.append({"label": label, "value": None, "pose": "—", "limit": None, "unit": unit, "state": "bilgi",
                            "field": field, "stat": stat, "note": "motor sayacı geçersiz: eksiye düşüp sardı"})
    scene = report.get("scene", {})
    for key, label in SCENE:
        if key in scene:
            limit = scene_limits.get(key)
            state = judge(float(scene[key]), limit, tolerance)
            summary.append({"label": label, "value": float(scene[key]), "pose": "sahne", "limit": limit, "unit": "",
                            "state": state, "field": key, "stat": None})
            if state in ("uyarı", "hata"):
                findings.append((state, label, "sahne", float(scene[key]), limit, ""))
    return summary, findings


def baseline_worst(baseline, field, stat):
    values = [pose_value(p, field, stat) for p in checked_poses(baseline)]
    values = [v for v in values if v is not None]
    return max(values) if values else None


def print_report(report, row_name, row, summary, findings, baseline, show_all):
    device = report.get("device", {})
    poses = report.get("poses", [])
    checked = checked_poses(report)
    print(f"Bütçe denetimi: {row_name} ({row.get('title', '')})")
    scale = device.get("scaling_3d_scale")
    scale_text = f"{float(scale):.2f}" if isinstance(scale, (int, float)) else "?"
    print(f"Ölçüm: {report.get('date', '?')}; {device.get('adapter', '?')}, {device.get('driver', '?')}, "
          f"{device.get('method', '?')}, {device.get('godot', '?')}; pencere {device.get('window', '?')}, "
          f"3B ölçek {device.get('scaling_3d_mode', '?')} {scale_text}, MSAA {MSAA_NAMES.get(device.get('msaa_3d'), '?')}, "
          f"dikey eşitleme {'açık' if device.get('vsync') else 'kapalı'}")
    for key, label in (("load_before", "başta"), ("load_after", "sonda")):
        if device.get(key):
            print(f"Makinenin yükü {label}: {device[key]}")
    settings = report.get("settings", {})
    print(f"Pozlar: {len(poses)} ({len(checked)} sınanır, {len(poses) - len(checked)} çimensiz eş); "
          f"ısınma {settings.get('warmup', '?')}, oturma {settings.get('settle', '?')}, ölçüm {settings.get('frames', '?')} kare"
          + (f"; süzgeç «{settings['only']}»" if settings.get("only") else ""))
    print()
    head = f"{'Ölçü':<36}{'En kötü':>13}{'Sınır':>13}  {'Durum':<7} Poz"
    if baseline is not None:
        head += "  (taban: en kötü, fark)"
    print(head)
    for item in summary:
        line = (f"{item['label']:<36}{fmt(item['value'], item['unit']):>13}{fmt(item['limit'], item['unit']):>13}"
                f"  {item['state']:<7} {item['pose']}")
        if item.get("note"):
            line += f" ({item['note']})"
        if baseline is not None and item["pose"] not in ("sahne", "—") and item["label"] != "Kare süresi hedefi":
            base = baseline_worst(baseline, item["field"], item["stat"])
            if base is not None and item["value"] is not None:
                delta = item["value"] - base
                pct = f" ({100.0 * delta / base:+.1f}%)" if base else ""
                line += f"  [taban {fmt(base, item['unit'])}, {'+' if delta >= 0 else ''}{fmt(delta, item['unit']) if abs(delta) >= 0.005 else '0'}{pct}]"
        print(line)
    share = report.get("grass_share")
    if isinstance(share, dict) and share.get("pairs"):
        print()
        print(f"Çimenin payı (çimenli − çimensiz, {share['pairs']} eş; ortalama / en çok):")
        for field, label, unit in [("frame_ms", "kare süresi", "ms"), ("gpu_ms", "GPU", "ms"), ("cpu_ms", "CPU çizim", "ms"),
                                   ("draw_calls_visible", "görünür çizim", ""), ("draw_calls_shadow", "gölge çizimi", ""),
                                   ("triangles_visible", "görünür üçgen", ""), ("triangles_shadow", "gölge üçgeni", "")]:
            item = share.get(field)
            if isinstance(item, dict):
                print(f"  {label:<16} {fmt(item.get('mean'), unit):>12} / {fmt(item.get('max'), unit)}")
    scene = report.get("scene", {})
    if "multimesh_triangles" in scene:
        print(f"Sahnedeki MultiMesh üçgeni (kırpmasız): {fmt(float(scene['multimesh_triangles']), '')}, "
              f"çimeninki {fmt(float(scene.get('grass_triangles', 0)), '')}")
    if show_all:
        print()
        print(f"{'Poz':<34}{'kare':>9}{'%95':>9}{'gpu':>9}{'çizim':>7}{'gölge':>7}{'üçgen':>9}{'g.üçgen':>9}")
        for pose in poses:
            print(f"{str(pose.get('id')):<34}"
                  f"{pose_value(pose, 'frame_ms', 'mean') or 0:>9.2f}{pose_value(pose, 'frame_ms', 'p95') or 0:>9.2f}"
                  f"{pose_value(pose, 'gpu_ms', 'mean') or 0:>9.2f}"
                  f"{pose_value(pose, 'draw_calls_visible', 'max') or 0:>7.0f}{pose_value(pose, 'draw_calls_shadow', 'max') or 0:>7.0f}"
                  f"{(pose_value(pose, 'triangles_visible', 'max') or 0) / 1e6:>8.2f}M{(pose_value(pose, 'triangles_shadow', 'max') or 0) / 1e6:>8.2f}M")
    if findings:
        print()
        print("Uyarı ve hatalar:")
        for state, label, pose_id, value, limit, unit in sorted(findings, key=lambda f: (-STATUS_ORDER[f[0]], f[1], str(f[2]))):
            print(f"  {state:<6} {label}: {fmt(value, unit)} > {fmt(limit, unit)}  ({pose_id})")


def parse_args(argv):
    opts = {"budgets": DEFAULT_BUDGETS, "row": None, "baseline": None, "all": False}
    files = []
    for arg in argv:
        if arg.startswith("--budgets="):
            opts["budgets"] = arg.split("=", 1)[1]
        elif arg.startswith("--row="):
            opts["row"] = arg.split("=", 1)[1]
        elif arg.startswith("--baseline="):
            opts["baseline"] = arg.split("=", 1)[1]
        elif arg == "--all":
            opts["all"] = True
        elif arg in ("-h", "--help"):
            return None, None
        elif arg.startswith("--"):
            raise BudgetError(f"bilinmeyen argüman: {arg}")
        else:
            files.append(arg)
    if len(files) != 1:
        raise BudgetError("bir ölçüm JSON'u gerekli")
    return files[0], opts


def main(argv):
    try:
        path, opts = parse_args(argv)
        if path is None:
            print(__doc__)
            return 0
        report = load_json(path, "ölçüm")
        budgets = load_json(opts["budgets"], "bütçe")
        rows = budgets.get("rows", {})
        row_name = opts["row"] or report.get("row") or "camp"
        if row_name not in rows:
            raise BudgetError(f"bütçede «{row_name}» satırı yok (var olanlar: {', '.join(rows)})")
        tolerance = float(budgets.get("tolerance", 0.03))
        baseline = load_json(opts["baseline"], "taban") if opts["baseline"] else None
        summary, findings = evaluate(report, rows[row_name], tolerance, budgets.get("scene", {}))
        print_report(report, row_name, rows[row_name], summary, findings, baseline, opts["all"])
    except BudgetError as e:
        print(f"check_budget: {e}", file=sys.stderr)
        return 2
    errors = sum(1 for f in findings if f[0] == "hata")
    warnings = sum(1 for f in findings if f[0] == "uyarı")
    target_note = [s for s in summary if s["label"] == "Kare süresi hedefi" and s["state"] == "uyarı"]
    print()
    verdict = "KALDI" if errors else "GEÇTİ"
    extra = " (kare süresi hedefin üstünde, sınırın altında)" if target_note and not errors else ""
    print(f"Sonuç: {errors} hata, {warnings} uyarı → {verdict}{extra}")
    return 1 if errors else 0


if __name__ == "__main__":
    # Çıktı kesilirse (ör. "| head") Unix araçları gibi sessizce dur; Python yığın dökümü yazmasın.
    if hasattr(signal, "SIGPIPE"):
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    sys.exit(main(sys.argv[1:]))
