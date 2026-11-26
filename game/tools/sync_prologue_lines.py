#!/usr/bin/env python3
"""Önsöz'ün günlerinin sözlerini eşitler (E21, K110; docs/design/d3/e21-prologue-api.md §2).

docs/design/d3/e21-lines.json metnin kaynağıdır (act0-text.md ile aynı); oyun res:// dışını okuyamaz. Bu araç Önsöz'ün görevlerinin
satırlarını (act0.milk, storm, lambs, feast, wrestle, hearth) ve andıkları konuşanları data/story/prologue_days/lines.json'a yazar.
Metne elle dokunulmaz: söz değişecekse kaynak dosya değişir, araç yeniden koşar. Sınama (test_prologue_days.gd) iki dosyanın aynı olduğunu
denetler.

  python3 tools/sync_prologue_lines.py          # yazar
  python3 tools/sync_prologue_lines.py --check  # yalnız denetler (fark varsa çıkış 1)
"""
import json
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent
SOURCE = GAME.parent / "docs" / "design" / "d3" / "e21-lines.json"
TARGET = GAME / "data" / "story" / "prologue_days" / "lines.json"
QUESTS = ("milk", "storm", "lambs", "feast", "wrestle", "hearth")


def build(src: dict) -> dict:
    lines = [l for l in src.get("lines", []) if any(str(l.get("id", "")).startswith("act0.%s." % q) for q in QUESTS)]
    used = sorted({str(l.get("speaker", "")) for l in lines})
    speakers = {k: v for k, v in src.get("speakers", {}).items() if k in used}
    return {
        "id": "prologue_days_lines",
        "doc": "Önsöz'ün oynanan günlerinin sözleri (E21, K110). Kaynak docs/design/d3/e21-lines.json; eşitleme python3 tools/sync_prologue_lines.py. Elle değiştirilmez.",
        "speakers": speakers,
        "lines": [{"id": l["id"], "speaker": l.get("speaker", ""), "tr": l.get("tr", ""), "en": l.get("en", "")} for l in lines],
    }


def main() -> int:
    src = json.loads(SOURCE.read_text(encoding="utf-8"))
    out = build(src)
    text = json.dumps(out, ensure_ascii=False, indent="\t") + "\n"
    if "--check" in sys.argv:
        current = TARGET.read_text(encoding="utf-8") if TARGET.exists() else ""
        if current != text:
            print("lines.json eşit değil: python3 tools/sync_prologue_lines.py")
            return 1
        print("eşit: %d söz" % len(out["lines"]))
        return 0
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text(text, encoding="utf-8")
    print("yazıldı: %s (%d söz, %d konuşan)" % (TARGET.relative_to(GAME), len(out["lines"]), len(out["speakers"])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
