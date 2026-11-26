#!/usr/bin/env python3
"""Ekonomi modelinin tarif, tezgâh ve zanaatçı satırlarını data/economy/recipes.json ile stations.json'a yazar (economy.md §6, K24, K49).

Modelin (docs/design/d2/econ-model.json) sahip olduğu alanlar: tarifte out, in, hold, wh, cure, station, who, role, act, a1, skill, seasons,
note; tezgâhta tr, en, crewMax, slots, act, structure, open, note; zanaatçıda tier, craft, via, path, act. Bunlar modelden yenilenir.
Godot'nun alanları ve modelde olmayan satırlar olduğu gibi kalır: I. Perde'nin el tarifleri (economy.md §6.2: rc_sling, rc_snare, rc_felt_plug,
rc_shears, rc_sled, rc_halter, rc_firestriker, rc_bandage; «source»: «a1»), teçhizatın İnce İş eki («fine»: economy.md §2.10; model
yazmaz), tezgâhın «dry»ı (açık hava beklemesi kurur, yağmurda durur;
§6.7 kural 4), zanaatçının adı, tezgâhı ve hızı (§6.8), oyuncu metinleri. Modele yeni giren kimlik bölümünün sonuna eklenir.

Kullanım:
  python3 tools/export_recipes.py           # yazar
  python3 tools/export_recipes.py --check   # yalnız denetler: dosyalar modelle aynı değilse 1 döner (yazmaz)
"""
import json
import sys
from collections import OrderedDict
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent
MODEL = GAME.parent / "docs" / "design" / "d2" / "econ-model.json"
RECIPES = GAME / "data" / "economy" / "recipes.json"
STATIONS = GAME / "data" / "economy" / "stations.json"
RECIPE_FIELDS = ["station", "who", "role", "in", "out", "hold", "wh", "cure", "act", "a1", "skill", "seasons", "note"]
STATION_FIELDS = ["crewMax", "slots", "act", "structure", "open", "note"]
ROLE_FIELDS = ["tier", "craft", "via", "path", "act"]


def one(v):
    return json.dumps(v, ensure_ascii=False, separators=(", ", ": "))


def dump(o, tables):
    """Üst düzey sekmeli; tablo satırları tek satırda."""
    lines = ["{"]
    keys = list(o.keys())
    for i, k in enumerate(keys):
        v = o[k]
        end = "," if i < len(keys) - 1 else ""
        if k in tables and isinstance(v, dict):
            lines.append("\t%s: {" % one(k))
            sub = list(v.keys())
            for j, sk in enumerate(sub):
                lines.append("\t\t%s: %s%s" % (one(sk), one(v[sk]), "," if j < len(sub) - 1 else ""))
            lines.append("\t}" + end)
        else:
            lines.append("\t%s: %s%s" % (one(k), one(v), end))
    lines.append("}")
    return "\n".join(lines) + "\n"


def refresh(row, m, fields, name=False):
    new = OrderedDict()
    if name:
        new["name"] = OrderedDict([("tr", m["tr"]), ("en", m["en"])])
    for f in fields:
        if f in m:
            new[f] = m[f]
    for k, v in row.items():
        if k not in fields and not (name and k == "name"):
            new[k] = v
    return new


def merge(model_rows, rows, fields, name=False):
    out = OrderedDict()
    changed = []
    model_rows = OrderedDict((k, v) for k, v in model_rows.items() if not k.startswith("_"))
    for rid, row in rows.items():
        if rid in model_rows:
            new = refresh(row, model_rows[rid], fields, name)
            if new != row:
                changed.append(rid)
            out[rid] = new
        else:
            out[rid] = row
    for rid, m in model_rows.items():
        if rid not in out:
            changed.append("%s: yeni" % rid)
            out[rid] = refresh(OrderedDict(), m, fields, name)
    return out, changed


def main():
    check = "--check" in sys.argv[1:]
    model = json.loads(MODEL.read_text(encoding="utf-8"), object_pairs_hook=OrderedDict)
    stale = []
    rec = json.loads(RECIPES.read_text(encoding="utf-8"), object_pairs_hook=OrderedDict)
    rec["recipes"], changed = merge(model["recipes"], rec["recipes"], RECIPE_FIELDS)
    text = dump(rec, ("recipes", "messages"))
    if text != RECIPES.read_text(encoding="utf-8"):
        stale.append("recipes.json (%s)" % ", ".join(changed[:6]) if changed else "recipes.json (biçim)")
        if not check:
            RECIPES.write_text(text, encoding="utf-8")
    st = json.loads(STATIONS.read_text(encoding="utf-8"), object_pairs_hook=OrderedDict)
    st["stations"], ch1 = merge(model["stations"], st["stations"], STATION_FIELDS, name=True)
    st["roles"], ch2 = merge(model["masters"], st["roles"], ROLE_FIELDS)
    text = dump(st, ("stations", "roles", "messages"))
    if text != STATIONS.read_text(encoding="utf-8"):
        stale.append("stations.json (%s)" % ", ".join((ch1 + ch2)[:6]) if ch1 + ch2 else "stations.json (biçim)")
        if not check:
            STATIONS.write_text(text, encoding="utf-8")
    if check:
        if stale:
            print("[export_recipes] ESKİ: %s (python3 tools/export_recipes.py)" % "; ".join(stale))
            return 1
        print("[export_recipes] güncel")
        return 0
    print("[export_recipes] %s" % ("; ".join(stale) if stale else "değişmedi"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
