#!/usr/bin/env python3
"""
E21 sözlerini günün dosyasına eşitler (K110; docs/design/d3/e21-lines.json metnin kaynağıdır, metne elle dokunulmaz).

Günün sahne dosyasının (ChildhoodScene biçimi) "vo_prefix"i ile başlayan bütün satırlar e21-lines.json'dan okunur ve dosyanın
"lines" bölümüne anahtar = kimlik − önek olarak yazılır ({speaker, tr, en}); konuşanların görünen adları "speakers"a eklenir.
Dosyada olup e21-lines.json'da olmayan satır anahtarı (bark.* dışında) uyarı olarak yazılır ve silinir; bark.* satırları kalır.

Kullanım:
  python3 tools/sync_e21_lines.py data/story/childhood_days/day1_flock.json [--lines=../docs/design/d3/e21-lines.json] [--check]

  --check   yazmaz; fark varsa 1 ile çıkar.
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_LINES = os.path.join(os.path.dirname(ROOT), "docs", "design", "d3", "e21-lines.json")


def main(argv):
    paths = [a for a in argv if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in argv if a.startswith("--"))
    if not paths:
        print(__doc__)
        return 2
    lines_path = opts.get("lines", DEFAULT_LINES)
    src = json.load(open(lines_path, encoding="utf-8"))
    by_id = {l["id"]: l for l in src.get("lines", [])}
    speakers_src = src.get("speakers", {})
    changed = False
    for path in paths:
        full = path if os.path.isabs(path) else os.path.join(ROOT, path)
        text = open(full, encoding="utf-8").read()
        day = json.loads(text)
        prefix = day.get("vo_prefix", "")
        if not prefix:
            print(f"{path}: vo_prefix yok")
            return 2
        lines = {}
        for lid, l in by_id.items():
            if lid.startswith(prefix):
                lines[lid[len(prefix):]] = {"speaker": l["speaker"], "tr": l["tr"], "en": l["en"]}
        old = day.get("lines", {})
        for key, val in old.items():
            if key.startswith("bark."):
                lines[key] = val
            elif key not in lines:
                print(f"{path}: e21-lines.json'da yok, düştü: {prefix}{key}")
        speakers = dict(day.get("speakers", {}))
        for l in lines.values():
            sp = l["speaker"]
            if sp not in speakers and sp in speakers_src:
                speakers[sp] = speakers_src[sp]
        if lines != old or speakers != day.get("speakers", {}):
            changed = True
            day["lines"] = lines
            day["speakers"] = speakers
            if "check" not in opts:
                with open(full, "w", encoding="utf-8") as f:
                    json.dump(day, f, ensure_ascii=False, indent="\t")
                    f.write("\n")
                print(f"{path}: {len(lines)} satır eşitlendi")
        else:
            print(f"{path}: eşit ({len(lines)} satır)")
    return 1 if (changed and "check" in opts) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
