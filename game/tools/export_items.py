#!/usr/bin/env python3
"""Ekonomi modelinin eşya satırlarını data/economy/items.json'a yazar (godot.md §3 «Envanter ve ekonomi», K49).

Modelin (docs/design/d2/econ-model.json) sahip olduğu alanlar: name (tr, en), tier, w10, per, stack, worth, tags, act, fuel,
ration, bundle, source, note. Bunlar modelden yenilenir; Godot'nun alanları (slot, gear, tool, food, perish, icon, text, game,
yield, fine) ve modelde olmayan satırlar (yemek, araç, görevlik eşya, giyim, Çocukluk'un avı) olduğu gibi kalır. Modele yeni
giren kimlik dosyanın modele ait bölümünün sonuna eklenir.

Kullanım:
  python3 tools/export_items.py           # yazar
  python3 tools/export_items.py --check   # yalnız denetler: dosya modelle aynı değilse 1 döner (yazmaz)
"""
import json
import sys
from collections import OrderedDict
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent
MODEL = GAME.parent / "docs" / "design" / "d2" / "econ-model.json"
ITEMS = GAME / "data" / "economy" / "items.json"
MODEL_FIELDS = ["tier", "w10", "per", "stack", "worth", "tags", "act", "fuel", "ration", "bundle", "source", "note"]


def one(v):
    return json.dumps(v, ensure_ascii=False, separators=(", ", ": "))


def dump(o):
    """Üst düzey sekmeli; eşya, takım ve ad satırları tek satırda (kurucunun biçimi)."""
    lines = ["{"]
    keys = list(o.keys())
    for i, k in enumerate(keys):
        v = o[k]
        end = "," if i < len(keys) - 1 else ""
        if k in ("items", "kits"):
            lines.append("\t%s: {" % one(k))
            sub = list(v.keys())
            for j, sk in enumerate(sub):
                lines.append("\t\t%s: %s%s" % (one(sk), one(v[sk]), "," if j < len(sub) - 1 else ""))
            lines.append("\t}" + end)
        elif k == "labels":
            lines.append("\t%s: {" % one(k))
            groups = list(v.keys())
            for j, g in enumerate(groups):
                lines.append("\t\t%s: {" % one(g))
                ent = list(v[g].keys())
                for m, e in enumerate(ent):
                    lines.append("\t\t\t%s: %s%s" % (one(e), one(v[g][e]), "," if m < len(ent) - 1 else ""))
                lines.append("\t\t}" + ("," if j < len(groups) - 1 else ""))
            lines.append("\t}" + end)
        else:
            lines.append("\t%s: %s%s" % (one(k), one(v), end))
    lines.append("}")
    return "\n".join(lines) + "\n"


def merge(model_items, data):
    items = data["items"]
    out = OrderedDict()
    changed = []
    for item_id, row in items.items():
        if item_id in model_items:
            out[item_id] = refresh(item_id, row, model_items[item_id], changed)
        else:
            out[item_id] = row
    for item_id, m in model_items.items():
        if item_id not in out:
            changed.append("%s: yeni" % item_id)
            out[item_id] = refresh(item_id, OrderedDict(), m, [])
    data["items"] = out
    return changed


def refresh(item_id, row, m, changed):
    new = OrderedDict()
    new["name"] = OrderedDict([("tr", m["tr"]), ("en", m["en"])])
    for f in MODEL_FIELDS:
        if f in m:
            new[f] = m[f]
    for k, v in row.items():
        if k != "name" and k not in MODEL_FIELDS:
            new[k] = v
    old_model = {k: row.get(k) for k in ["name"] + MODEL_FIELDS}
    new_model = {k: new.get(k) for k in ["name"] + MODEL_FIELDS}
    if old_model != new_model:
        changed.append("%s: %s" % (item_id, ", ".join(k for k in new_model if old_model[k] != new_model[k])))
    return new


def main():
    check = "--check" in sys.argv[1:]
    model_items = json.loads(MODEL.read_text(encoding="utf-8"), object_pairs_hook=OrderedDict)["items"]
    data = json.loads(ITEMS.read_text(encoding="utf-8"), object_pairs_hook=OrderedDict)
    changed = merge(model_items, data)
    text = dump(data)
    same = text == ITEMS.read_text(encoding="utf-8")
    for line in changed:
        print("  " + line)
    if check:
        print("items.json modelle aynı" if same else "items.json modelden geri: tools/export_items.py koşulmalı")
        return 0 if same else 1
    if not same:
        ITEMS.write_text(text, encoding="utf-8")
    print("yazıldı: %s (%d eşya, %d değişiklik)" % (ITEMS.relative_to(GAME), len(data["items"]), len(changed)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
