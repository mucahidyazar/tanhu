#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sitenin ansiklopedisini Destan Kitabı'na aktarır (godot.md §3.8; K35, K85, K86).

Kaynak `docs-app/content/encyclopedia.json`'dır (sitenin /encyclopedia sayfası). Araç kayıtları kimliğiyle
Godot verisine yazar: «Tanrılar ve Ruhlar» bölümü (`gods`) `data/mitler.json`'a («Gök ve Yer»), öteki beş
bölüm `data/kisiler.json`'a («Kişiler»). Kimlik kebab'dan alt çizgiye döner (`lan-hatun` → `lan_hatun`).

Godot'ya özgü alanlar (`unlock`, `game_group`) ve sitede olmayan kayıtlar (Doru, Akbulut, «Doğum») korunur;
araç onlara dokunmaz. Yeni kayıtta açılma kuralı: kamp halkı (`*`), `acts`'ında «Önsöz» geçen kayıt
(`onsoz`), ozanı dinlemenin girdisi iyeler (`ozan_dinledi`), öteki boş (kapalı). Eski Türkçe kimlikler
(`ana`, `baba`, `cocuk`, `ozan`, `ak_at`, ateş başındaki `mete`) bir kez göçer (godot.md §3.4).

Tanrıların çağ rozetleri `eraNote`'tan ayrıştırılır: «Yıllıktan», «Taştan», «Ozan der», «Bizim»; geçiş
sırasıyla, birden çok olabilir. Rozetsiz tanrı kaydı site biçiminin değiştiğini gösterir: araç durur.

Görseller (--images): `docs/assets/encyclopedia/<kimlik>/{art,portrait,pose}.png` küçültülerek
`assets/ui/encyclopedia/<alt_çizgili>/`'ye yazılır: art ve T-poz 1024 boyunda (683 × 1024), profil
512 × 512, küçük resim 128 × 128 (profilden ortadan kesim). Asıl PNG docs'ta kalır; `_portrait-ref.png` ve
WebP kopyalanmaz. Yanlarına yalnız `importer` ve `[params]` taşıyan `.import` yazılır (VRAM sıkıştırma,
BC7, mipmap, boy sınırı); uid'i ve dest_files'ı Godot doldurur. Küçültme önce macOS `sips` ile denenir,
kum havuzunda (geçici klasöre yazamazsa) `ffmpeg`'e düşer. BC7 sıkıştırması yavaştır (görsel başına
≈1 sn): görseller kişi kişi dilimlerle, `tools/_godot_lock.sh`'ın kilidi tutularak yazılır ve her dilimden
sonra Godot içe aktarır; başka bir koşu kilidi en çok bir dilim bekler.

Tanıtım sesleri (--voices): `docs/media/audio/vo/en/ency.<kimlik>.mp3` yeniden kodlanmadan
`audio/vo/ency/<alt_çizgili>.mp3`'ye kopyalanır (K61); konuşmayan kişinin (`speaks: false`) sesi alınmaz.

Kullanım (game/ klasöründen):
  python3 tools/import_encyclopedia.py              # yalnız veri
  python3 tools/import_encyclopedia.py --all        # görseller, sesler ve veri
  python3 tools/import_encyclopedia.py --images     # görseller (ve veri)
  python3 tools/import_encyclopedia.py --voices     # sesler (ve veri)
  python3 tools/import_encyclopedia.py --check      # hiçbir şey yazmaz; değişiklik varsa çıkış kodu 1
  python3 tools/import_encyclopedia.py --all --no-data   # yalnız görseller ve sesler
Görseller ve sesler üretildikçe araç yeniden koşulur; değişmeyen dosyaya dokunmaz.
"""

from __future__ import annotations

import argparse
import contextlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent
REPO = GAME.parent
SITE_JSON = REPO / "docs-app" / "content" / "encyclopedia.json"
IMAGE_SRC = REPO / "docs" / "assets" / "encyclopedia"
VOICE_SRC = REPO / "docs" / "media" / "audio" / "vo" / "en"

PEOPLE_FILE = GAME / "data" / "kisiler.json"
MYTHS_FILE = GAME / "data" / "mitler.json"
IMAGE_DIR = GAME / "assets" / "ui" / "encyclopedia"
VOICE_DIR = GAME / "audio" / "vo" / "ency"
RES = "res://"

# Veri dosyalarının biçimi: 2 = ansiklopedi kayıtları (1 = Tanhu 2'nin kısa kayıtları, eski Türkçe kimlikler).
FORMAT = 2
GODS = "gods"
BADGES = ("Yıllıktan", "Taştan", "Ozan der", "Bizim")
BADGE_RE = re.compile("«(" + "|".join(re.escape(b) for b in BADGES) + ")»")
# Açılma işaretleri (JourneyFlags.PROLOGUE ve BARD_LISTEN ile aynı).
PROLOGUE_FLAG = "onsoz"
BARD_FLAG = "ozan_dinledi"
PROLOGUE_ACT = "Önsöz"
# Ozanı ateş başında 5 sn dinlemenin açtığı girdi: yer ruhları, ozanın ezgisinin konusu (tasarım boşluğu).
BARD_ENTRY = "iyeler"
# Ateş başındaki ocak halkı (K37): baştan açıktır.
CAMP_FOLK = ("mother", "father", "child", "bard", "older_brother")
# data/kisiler.json'un eski kimlikleri (godot.md §3.4, camp-cast).
LEGACY_IDS = {"ana": "mother", "baba": "father", "cocuk": "child", "ozan": "bard", "ak_at": "akbulut", "mete": "older_brother"}
# Araç bu alanlara dokunmaz: Godot verisinde kalır.
GODOT_KEYS = ("unlock", "game_group")
# Oyunun kendi grupları (eski Kişiler sayfası; game_group).
GAME_GROUPS = [{"id": "ocak", "name": "Ocak Halkı"}, {"id": "atlar", "name": "Atlar"}]
MYTH_GROUPS = ["Gök", "Yer", "Alt", "Hayvan", "Töre ve sunu", "Destan"]

# Oyuncunun okuduğu metin (2026-11-07). Site ekibin belgesidir, Destan Kitabı oyunun parçası: sitede bağ olan K numaraları ve
# «story.md §3» gibi atıflar oyuncuya bir şey söylemez, «Oyundaki yeri» bölümü oyunun nasıl yapıldığını anlatır. Kaynak site olduğu için
# ayıklama aktarımdadır, site metni değişmez.
SITE_ONLY_SECTIONS = ("Oyundaki yeri",)
_DOC_REF = r"(?:K\d{1,3}|[A-Za-z0-9_/-]+\.md(?:\s*§[\d.]+(?:,\s*§[\d.]+)*)?|§[\d.]+|Godot\b)"
_REF_PAREN = re.compile(rf"\s*\(\s*{_DOC_REF}(?:\s*[,;]\s*(?:ve\s+)?{_DOC_REF})*\s*\)")
_REF_ANY = re.compile(rf"(?<![\w.]){_DOC_REF}")
_SENTENCE = re.compile(r"(?<=[.!?»])\s+(?=[A-ZÇĞİÖŞÜ«])")

# Görseller: tür → (kaynak dosya, boy sınırı). Küçük resim profilden kesilir.
IMAGE_KINDS = ("art", "portrait", "pose", "thumb")
IMAGE_LIMITS = {"art": 1024, "pose": 1024, "portrait": 512, "thumb": 128}
IMAGE_SOURCES = {"art": "art.png", "pose": "pose.png", "portrait": "portrait.png", "thumb": "portrait.png"}
# Yazılmakta olan kaynak alınmaz: dosya en az bu kadar eski olmalı (sn) ve PNG'nin son parçası IEND olmalı.
SETTLE_SECONDS = 5.0
PNG_TAIL = b"\x00\x00\x00\x00IEND\xaeB`\x82"
# Kişi başına ≈3 sn BC7: 12 kişilik dilim ≈40 sn sürer, kilidin 180 sn'lik bekçisinin altında kalır.
CHUNK_PEOPLE = 12
GODOT = os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot")
LOCK_DIR = Path(os.environ.get("TMPDIR") or "/tmp") / "tanhu3_import.lock"
LOCK_STALE = 180

TEXTURE_PARAMS = ("compress/mode", "compress/high_quality", "mipmaps/generate", "process/size_limit")
MP3_PARAMS = {"loop": "false", "loop_offset": "0", "bpm": "0", "beat_count": "0", "bar_beats": "4"}

# Sitede olmayan, Godot'nun kendi kayıtları. Dosyada varsa korunur; yoksa bu hâlleriyle yazılır.
# Akbulut'un eski Mete cümlesi ve ay atı dili kalktı (K37); Doru'nun metninde Ak At Akbulut oldu.
GODOT_ONLY_PEOPLE = [
	{
		"id": "doru",
		"name": "Doru",
		"alt_names": ["Doru At"],
		"epithet": "Kampın sabırlı yük atı",
		"section": "huns",
		"group": "Ocak ve anlatı",
		"kind": "animal",
		"era": "kurgu",
		"era_note": "Kurgu. Ana kampın iki atından biri; adını donundan alır.",
		"acts": [],
		"sections": [
			{"title": "Kimliği", "text": "Kızıl kahve donlu, alnı akıtmalı. Yurdun keçelerini, kazanı, odunları o taşır. Sabırlıdır; Akbulut'un yanında durunca gölgesi gibi görünür. Saman uzatana başını eğer, karşılığında burnunu omzuna dayar."},
			{"title": "Oyundaki yeri", "text": "Göl Obası'nın ahırında Akbulut'la birlikte durur; ikisi Çocuğun bineğidir. Gece yarısından şafağa dek başını eğip dinlenir. Ahırın önüne varınca Destan Kitabı'na yazılır."},
		],
		"facts": [
			{"label": "Halkı", "value": "Hun, Göl Obası"},
			{"label": "Donu", "value": "Doru, alnı akıtmalı"},
			{"label": "Rolü", "value": "Yük atı"},
		],
		"lineage": {"side": [{"id": "akbulut", "label": "Ahır arkadaşı"}, {"id": "child", "label": "Binicisi"}]},
		"source_note": "Kaynak: oyunun hikâye ve zaman belgeleri. Godot'nun kendi kaydıdır, sitenin ansiklopedisinde yoktur.",
		"unlock": "ahir_ziyaret",
		"game_group": "atlar",
	},
	{
		"id": "akbulut",
		"name": "Akbulut",
		"alt_names": ["Ak At"],
		"epithet": "Çocuğun ak bineği",
		"section": "huns",
		"group": "Ocak ve anlatı",
		"kind": "animal",
		"era": "kurgu",
		"era_note": "Kurgu. Ana kampın iki atından biri.",
		"acts": [],
		"sections": [
			{"title": "Kimliği", "text": "Ak donlu, uzun yeleli, ürkek bir at. Yabancıya kulak yatırır, ayağını yere vurur; ama Çocuk elma uzatınca bütün huysuzluğu geçer. Doru'yla aynı ahırda durur, onun sabrına yaslanır."},
			{"title": "Oyundaki yeri", "text": "Göl Obası'nın ahırında Doru'yla birlikte durur; ikisi Çocuğun bineğidir. Gece yarısından şafağa dek başını eğip dinlenir. Ahırın önüne varınca Destan Kitabı'na yazılır."},
		],
		"facts": [
			{"label": "Halkı", "value": "Hun, Göl Obası"},
			{"label": "Donu", "value": "Ak"},
			{"label": "Rolü", "value": "Çocuğun bineği"},
		],
		"lineage": {"side": [{"id": "doru", "label": "Ahır arkadaşı"}, {"id": "child", "label": "Binicisi"}]},
		"source_note": "Kaynak: oyunun hikâye ve zaman belgeleri. Godot'nun kendi kaydıdır, sitenin ansiklopedisinde yoktur.",
		"unlock": "ahir_ziyaret",
		"game_group": "atlar",
	},
]
# «Doğum» (story.md §4): Destan grubu, rozet «Yıllıktan» ve «Bizim», Önsöz'le açılır.
GODOT_ONLY_MYTHS = [
	{
		"id": "birth",
		"name": "Doğum",
		"alt_names": ["Mete'nin doğumu", "Dailin şafağı"],
		"epithet": "27 Eylül MÖ 234 şafağı, Ordos",
		"section": GODS,
		"group": "Destan",
		"kind": "event",
		"era": "tarih",
		"era_note": "«Yıllıktan»: Shiji 110 (單于朝出營，拜日之始生，夕拜月 ve 秋，馬肥，大會蹛林，課校人畜計). Gün, yer, ebe, gölge ve beşik yayı oyunun seçimidir, «Bizim».",
		"acts": [PROLOGUE_ACT],
		"sections": [
			{"title": "Kimliği", "text": "Mete 27 Eylül MÖ 234 şafağında Ordos'ta, Sarı Irmak kıvrımının içinde Teoman'ın güz otlağında doğar. Dailin'in günüdür: at semizdir, insan ve hayvan sayılır. Gök iki ışığını birden tutar, doğuda doğan gün, batıda batmayan dolunay; Tanhu sabah güne, akşam aya eğilir, o şafak ikisi aynı göktedir."},
			{"title": "Anlatı notu", "text": "Doğum Lan Hatun'un yurdundadır, kapısı doğuya bakar. Ebe Hereka'dır, yanında Lan soyundan iki kadın. Al Karısı'nın gölgesi eşikten girer, ocak taşında durur, öteye geçemez. Hereka kapıdan sayım hattına seslenir: «Bir eklendi.» Sayıcı çubuğa bir çentik atar. Eş yurdun yanında toprağa gömülür, beşiğe küçük bir ok-yay asılır; uzakta turnalar güneye geçer. Ad konmaz."},
			{"title": "Oyundaki yeri", "text": "Önsöz'ün son sahnesidir: mit sinemasının keçe közü Lan Hatun'un ocağındaki gerçek köze döner, Teoman çadırından çıkıp doğan güne eğilir. Önsöz oynanınca ya da atlanınca bu girdi açılır."},
		],
		"facts": [
			{"label": "Gelenek", "value": "Shiji 110: Dailin sayımı, Tanhu'nun güne ve aya eğilişi"},
			{"label": "Alanı", "value": "Ordos, Lan Hatun'un yurdu"},
			{"label": "Motifler", "value": "Doğan gün ve batmayan dolunay · Ocak taşında duran gölge · Beşikte ok-yay"},
		],
		"lineage": {"side": [
			{"id": "mete", "label": "Doğan"},
			{"id": "lan_hatun", "label": "Anası"},
			{"id": "teoman", "label": "Babası, güne eğilen"},
			{"id": "hereka", "label": "Ebesi"},
			{"id": "counter", "label": "Çentiği atan"},
			{"id": "al_karisi", "label": "Eşikteki gölge"},
			{"id": "umay", "label": "Payı gömülen"},
			{"id": "dailin", "label": "Günün sayımı"},
		]},
		"source_note": "Kaynak: Shiji 110; oyunun hikâye belgesi §4. Beşik yayı ve eş gömme töresi Kaşgarlı (Umay) ve Kayabaşı'ndadır. Doğum yeri çıkarımdır: Hun MÖ 215'e dek Ordos'tadır (悉收河南地).",
		"unlock": PROLOGUE_FLAG,
	},
]


def snake(site_id: str) -> str:
	return site_id.replace("-", "_")


def log(msg: str) -> None:
	print(msg, flush=True)


# --- Kayıtlar -------------------------------------------------------------------------------------

def parse_badges(era_note: str) -> list[str]:
	"""Çağ rozetleri, eraNote'taki geçiş sırasıyla ve tekrarsız."""
	out: list[str] = []
	for m in BADGE_RE.finditer(era_note or ""):
		if m.group(1) not in out:
			out.append(m.group(1))
	return out


def model_id(site_model: str | None) -> str:
	"""Sitenin model yolu (game/assets/characters/elder/elder.glb) → Godot model kimliği (elder); dosya yoksa boş."""
	if not site_model:
		return ""
	name = Path(site_model).stem
	return name if (GAME / "assets" / "characters" / name / f"{name}.glb").exists() else ""


def lineage_of(raw: dict | None) -> dict:
	out: dict = {}
	raw = raw or {}
	for key in ("up", "down", "side"):
		rows = [{"id": snake(str(r["id"])), "label": str(r.get("label", ""))} for r in raw.get(key, []) or [] if isinstance(r, dict) and r.get("id")]
		if rows:
			out[key] = rows
	if raw.get("note"):
		out["note"] = str(raw["note"])
	return out


def default_unlock(rec: dict, myths: bool) -> str:
	if myths:
		if rec["id"] == BARD_ENTRY:
			return BARD_FLAG
		return PROLOGUE_FLAG if PROLOGUE_ACT in rec.get("acts", []) else ""
	if rec["id"] in CAMP_FOLK:
		return "*"
	return PROLOGUE_FLAG if PROLOGUE_ACT in rec.get("acts", []) else ""


def image_paths(gid: str) -> dict:
	"""Oyun kopyası olan görsellerin res:// yolu; olmayanınki boş."""
	out = {}
	for kind in IMAGE_KINDS:
		f = IMAGE_DIR / gid / f"{kind}.png"
		out[kind] = RES + f.relative_to(GAME).as_posix() if f.is_file() else ""
	return out


def intro_audio_path(gid: str, speaks: bool) -> str:
	f = VOICE_DIR / f"{gid}.mp3"
	return RES + f.relative_to(GAME).as_posix() if speaks and f.is_file() else ""


def site_record(e: dict) -> dict:
	gid = snake(e["id"])
	intro = e.get("intro") or {}
	speaks = e.get("speaks") is not False
	rec = {
		"id": gid,
		"site_id": e["id"],
		"section": e.get("chapter", ""),
		"group": e.get("group", ""),
		"kind": e.get("kind", ""),
		"name": e["name"],
		"alt_names": [str(a) for a in e.get("altNames", []) or []],
		"epithet": e.get("epithet", "") or "",
		"era": e.get("era", "") or "",
		"era_note": player_text(e.get("eraNote", "") or ""),
		"acts": [str(a) for a in e.get("acts", []) or []],
		"sections": player_sections([s for s in e.get("sections", []) or [] if s.get("title") and s.get("text")]),
		"facts": [{"label": str(f["label"]), "value": player_text(str(f["value"]))} for f in e.get("facts", []) or [] if f.get("label") and f.get("value")],
		"lineage": lineage_of(e.get("lineage")),
		"source_note": player_text(e.get("sourceNote", "") or ""),
		"intro": {"en": str(intro.get("en", "")), "tr": str(intro.get("tr", ""))} if intro.get("en") else {},
		"speaks": speaks,
		"voice_pending": e.get("voicePending") is True,
		"model": model_id(e.get("model")),
	}
	if e.get("chapter") == GODS:
		rec["badges"] = parse_badges(rec["era_note"])
	return rec


def player_text(text: str) -> str:
	"""Metinden tasarım belgesi atıflarını çıkarır: yalnız atıf taşıyan parantez, atıflı bölüm (;) ve bölümü kalmayan cümle gider."""
	text = _REF_PAREN.sub("", text)
	if not _REF_ANY.search(text):
		return text
	kept = []
	for sentence in _SENTENCE.split(text):
		if not _REF_ANY.search(sentence):
			kept.append(sentence)
			continue
		end = sentence[-1] if sentence[-1] in ".!?" else "."
		clauses = [c.strip() for c in sentence.rstrip(".!?").split(";") if not _REF_ANY.search(c)]
		if clauses:
			joined = "; ".join(clauses)
			kept.append(joined[0].upper() + joined[1:] + end)
	return " ".join(kept)


def player_sections(sections: list) -> list:
	"""Oyuncunun kitabındaki bölümler: yalnız sitenin bölümleri çıkar, metinler ayıklanır, boşalan bölüm kalmaz."""
	out = []
	for sec in sections:
		text = player_text(str(sec["text"]))
		if str(sec["title"]) not in SITE_ONLY_SECTIONS and text:
			out.append({"title": str(sec["title"]), "text": text})
	return out


def godot_only(defn: dict, myths: bool) -> dict:
	rec = {"id": defn["id"], "site_id": "", "godot_only": True}
	for key in ("section", "group", "kind", "name", "alt_names", "epithet", "era", "era_note", "acts", "sections", "facts", "lineage", "source_note"):
		rec[key] = defn.get(key, [] if key in ("alt_names", "acts", "sections", "facts") else ({} if key == "lineage" else ""))
	rec["era_note"] = player_text(str(rec["era_note"]))
	rec["source_note"] = player_text(str(rec["source_note"]))
	rec["sections"] = player_sections(rec["sections"])
	rec["intro"] = {}
	rec["speaks"] = False
	rec["voice_pending"] = False
	rec["model"] = ""
	if myths:
		rec["badges"] = parse_badges(rec["era_note"])
	rec["unlock"] = defn.get("unlock", "")
	rec["game_group"] = defn.get("game_group", "")
	return rec


def read_existing(path: Path, list_key: str) -> tuple[dict, list]:
	"""Var olan dosyanın kayıtları (kimlik → kayıt) ve sitede olmayanları (sırasıyla). Eski biçim göçer."""
	if not path.exists():
		return {}, []
	data = json.loads(path.read_text(encoding="utf-8"))
	rows = data.get(list_key, [])
	legacy = int(data.get("format", 1)) < FORMAT
	by_id: dict = {}
	for row in rows:
		if not isinstance(row, dict) or not row.get("id"):
			continue
		rid = LEGACY_IDS.get(row["id"], row["id"]) if legacy else row["id"]
		if legacy:
			# Tanhu 2'nin kısa kaydı: yalnız açılma koşulu ve oyun grubu taşınır.
			by_id[rid] = {"id": rid, "unlock": row.get("unlock", ""), "game_group": row.get("group", ""), "legacy": True}
		else:
			by_id[rid] = row
	extras = [r for r in by_id.values() if r.get("godot_only")]
	for extra in extras:
		extra["era_note"] = player_text(str(extra.get("era_note", "")))
		extra["source_note"] = player_text(str(extra.get("source_note", "")))
		extra["sections"] = player_sections(extra.get("sections", []) or [])
	return by_id, extras


def build_file(site: dict, myths: bool) -> dict:
	path, list_key = (MYTHS_FILE, "myths") if myths else (PEOPLE_FILE, "people")
	existing, extras = read_existing(path, list_key)
	records: list[dict] = []
	for e in site["entries"]:
		if (e.get("chapter") == GODS) != myths or not e.get("id") or not e.get("name"):
			continue
		rec = site_record(e)
		old = existing.get(rec["id"])
		for key in GODOT_KEYS:
			if old is not None and key in old:
				rec[key] = old[key]
			elif key == "unlock":
				rec[key] = default_unlock(rec, myths)
			else:
				rec[key] = ""
		records.append(rec)
	# Sitede olmayan kayıtlar: dosyadakiler korunur, yoksa aracın tanımıyla yazılır (eski kimliğin açılması taşınır).
	defs = GODOT_ONLY_MYTHS if myths else GODOT_ONLY_PEOPLE
	known = {r["id"] for r in extras}
	for d in defs:
		if d["id"] not in known:
			rec = godot_only(d, myths)
			old = existing.get(d["id"])
			if old is not None:
				for key in GODOT_KEYS:
					if old.get(key):
						rec[key] = old[key]
			extras.append(rec)
	site_ids = {r["id"] for r in records}
	for rec in extras:
		if rec["id"] in site_ids:
			continue  # site aynı kimliği aldı: sitenin kaydı geçer, Godot alanları yukarıda taşındı
		_insert_after_group(records, rec)
	for rec in records:
		rec["images"] = image_paths(rec["id"])
		rec["intro_audio"] = intro_audio_path(rec["id"], bool(rec.get("speaks", True)) and bool(rec.get("intro")))
	chapters = [
		{"id": c["id"], "title": c.get("title", c["id"]), "icon": c.get("icon", "star"), "summary": c.get("summary", "")}
		for c in site.get("chapters", []) if (c.get("id") == GODS) == myths
	]
	out = {
		"format": FORMAT,
		"source": "docs-app/content/encyclopedia.json",
		"site_updated": site.get("updated", ""),
		"note": "tools/import_encyclopedia.py yazar; unlock, game_group ve godot_only kayıtlar Godot'nundur, elle değişir.",
		"chapters": chapters,
	}
	if myths:
		out["groups"] = MYTH_GROUPS
	else:
		out["groups"] = GAME_GROUPS
	out[list_key] = records
	return out


def _insert_after_group(records: list[dict], rec: dict) -> None:
	"""Kaydı aynı bölüm ve gruptaki son kaydın ardına (yoksa bölümün sonuna, o da yoksa en sona) koyar."""
	same_group = [i for i, r in enumerate(records) if r.get("section") == rec.get("section") and r.get("group") == rec.get("group")]
	same_section = [i for i, r in enumerate(records) if r.get("section") == rec.get("section")]
	at = same_group[-1] if same_group else (same_section[-1] if same_section else len(records) - 1)
	records.insert(at + 1, rec)


def validate(people: dict, myths: dict) -> list[str]:
	"""Site biçimi değişirse araç düşer: rozetsiz tanrı, çözülmeyen soy bağı, çakışan kimlik."""
	problems: list[str] = []
	ids_p = [r["id"] for r in people["people"]]
	ids_m = [r["id"] for r in myths["myths"]]
	all_ids = set(ids_p) | set(ids_m)
	if len(all_ids) != len(ids_p) + len(ids_m):
		problems.append("kişiler ve mitler arasında çakışan ya da tekrarlanan kimlik var")
	for r in myths["myths"]:
		if not r.get("badges"):
			problems.append(f"{r['id']}: çağ rozeti ayrıştırılamadı (eraNote «…» ile başlamalı)")
		elif any(b not in BADGES for b in r["badges"]):
			problems.append(f"{r['id']}: bilinmeyen rozet {r['badges']}")
	for r in people["people"] + myths["myths"]:
		for key in ("up", "down", "side"):
			for rel in r.get("lineage", {}).get(key, []):
				if rel["id"] not in all_ids:
					problems.append(f"{r['id']}: soy bağı çözülmüyor: {rel['id']}")
	return problems


def dump(data: dict) -> str:
	return json.dumps(data, ensure_ascii=False, indent="\t") + "\n"


# --- Kilit ve Godot içe aktarması ---------------------------------------------------------------

@contextlib.contextmanager
def import_lock():
	"""tools/_godot_lock.sh ile aynı kilit (mkdir atomiktir). 180 sn'den eski kilit takılı sayılır."""
	waited = 0
	while True:
		try:
			LOCK_DIR.mkdir()
			break
		except FileExistsError:
			time.sleep(1)
			waited += 1
			if waited > LOCK_STALE:
				shutil.rmtree(LOCK_DIR, ignore_errors=True)
	try:
		yield
	finally:
		shutil.rmtree(LOCK_DIR, ignore_errors=True)


def godot_import(enabled: bool) -> None:
	if not enabled:
		return
	if not Path(GODOT).exists():
		log(f"  ! Godot bulunamadı ({GODOT}); içe aktarma sonraki tools/run_tests.sh'a kalır")
		return
	started = time.time()
	try:
		subprocess.run([GODOT, "--headless", "--path", str(GAME), "--import"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=LOCK_STALE - 10, check=False)
	except subprocess.TimeoutExpired:
		log("  ! Godot içe aktarması süreyi aştı; kalan iş sonraki koşuda sürer")
	log(f"  Godot içe aktardı ({time.time() - started:.0f} sn)")


def read_import_params(path: Path) -> dict:
	params: dict = {}
	section = ""
	if not path.exists():
		return params
	for line in path.read_text(encoding="utf-8").splitlines():
		line = line.strip()
		if line.startswith("[") and line.endswith("]"):
			section = line[1:-1]
		elif section == "params" and "=" in line:
			k, v = line.split("=", 1)
			params[k.strip()] = v.strip()
	return params


def import_text(importer: str, params: dict) -> str:
	body = "\n".join(f"{k}={v}" for k, v in params.items())
	return f'[remap]\n\nimporter="{importer}"\n\n[params]\n\n{body}\n'


def texture_params(limit: int) -> dict:
	return {"compress/mode": "2", "compress/high_quality": "true", "mipmaps/generate": "true", "process/size_limit": str(limit)}


def ensure_import(path: Path, importer: str, params: dict, write: bool) -> bool:
	"""Elle yazılan .import (yalnız importer ve [params]). Godot'nun doldurduğu dosya ayarı tutuyorsa kalır."""
	imp = path.with_name(path.name + ".import")
	have = read_import_params(imp)
	if imp.exists() and all(have.get(k) == v for k, v in params.items()):
		return False
	if write:
		imp.write_text(import_text(importer, params), encoding="utf-8")
	return True


# --- Görseller -----------------------------------------------------------------------------------

def usable_png(path: Path) -> bool:
	"""Kaynak tamamlanmış bir PNG mi? (üretim sürerken yarım dosya alınmaz)"""
	try:
		st = path.stat()
	except FileNotFoundError:
		return False
	if st.st_size < 64 or time.time() - st.st_mtime < SETTLE_SECONDS:
		return False
	with path.open("rb") as f:
		head = f.read(8)
		f.seek(-12, os.SEEK_END)
		tail = f.read(12)
	return head == b"\x89PNG\r\n\x1a\n" and tail == PNG_TAIL


def png_size(path: Path) -> tuple[int, int]:
	with path.open("rb") as f:
		head = f.read(24)
	return int.from_bytes(head[16:20], "big"), int.from_bytes(head[20:24], "big")


class Resizer:
	"""PNG küçültücü: önce sips (macOS), olmazsa ffmpeg. sips kum havuzunda geçici klasörüne yazamayabilir."""

	def __init__(self) -> None:
		self.backend = ""
		self.tmp = Path(tempfile.mkdtemp(prefix="ency_img_"))

	def close(self) -> None:
		shutil.rmtree(self.tmp, ignore_errors=True)

	def resize(self, src: Path, dst: Path, kind: str) -> None:
		w, h = png_size(src)
		limit = IMAGE_LIMITS[kind]
		if kind == "thumb":
			side = min(w, h)
			box = (limit, limit, side)
		else:
			k = min(1.0, limit / max(w, h))
			box = (max(1, round(w * k)), max(1, round(h * k)), 0)
		tmp_out = self.tmp / f"out_{os.getpid()}.png"
		for backend in ([self.backend] if self.backend else ["sips", "ffmpeg"]):
			if self._run(backend, src, tmp_out, box):
				self.backend = backend
				dst.parent.mkdir(parents=True, exist_ok=True)
				shutil.move(str(tmp_out), str(dst))
				return
		raise RuntimeError(f"{src} küçültülemedi (sips ve ffmpeg başarısız)")

	def _run(self, backend: str, src: Path, out: Path, box: tuple[int, int, int]) -> bool:
		out.unlink(missing_ok=True)
		w, h, crop = box
		env = dict(os.environ, TMPDIR=str(self.tmp))
		try:
			if backend == "sips":
				source = src
				if crop:
					cropped = self.tmp / "crop.png"
					cropped.unlink(missing_ok=True)
					r = subprocess.run(["sips", "-c", str(crop), str(crop), str(src), "--out", str(cropped)], capture_output=True, env=env, timeout=120)
					if r.returncode != 0 or not cropped.exists():
						return False
					source = cropped
				r = subprocess.run(["sips", "-s", "format", "png", "-z", str(h), str(w), str(source), "--out", str(out)], capture_output=True, env=env, timeout=120)
			else:
				vf = f"scale={w}:{h}:flags=lanczos"
				if crop:
					vf = f"crop={crop}:{crop}:(iw-{crop})/2:(ih-{crop})/2," + vf
				r = subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", str(src), "-vf", vf, "-compression_level", "9", "-pred", "mixed", "-frames:v", "1", str(out)], capture_output=True, env=env, timeout=120)
		except (FileNotFoundError, subprocess.TimeoutExpired):
			return False
		return r.returncode == 0 and out.exists() and out.stat().st_size > 0 and png_size(out) == (w, h)


def image_jobs(site: dict) -> dict:
	"""Kişi → [(tür, kaynak, hedef)]: kaynağı tamamlanmış ve oyun kopyası eksik ya da eski olanlar."""
	jobs: dict = {}
	for e in site["entries"]:
		if not e.get("id"):
			continue
		gid = snake(e["id"])
		for kind in IMAGE_KINDS:
			src = IMAGE_SRC / e["id"] / IMAGE_SOURCES[kind]
			dst = IMAGE_DIR / gid / f"{kind}.png"
			if not usable_png(src):
				continue
			fresh = dst.exists() and dst.stat().st_mtime >= src.stat().st_mtime
			params_ok = not ensure_import(dst, "texture", texture_params(IMAGE_LIMITS[kind]), write=False)
			if fresh and params_ok:
				continue
			jobs.setdefault(gid, []).append((kind, src, dst, fresh))
	return jobs


def import_images(site: dict, write: bool, run_godot: bool) -> int:
	jobs = image_jobs(site)
	count = sum(len(v) for v in jobs.values())
	log(f"Görseller: {len(jobs)} kişide {count} dosya yazılacak")
	if not write or not jobs:
		return count
	resizer = Resizer()
	people = sorted(jobs)
	try:
		for i in range(0, len(people), CHUNK_PEOPLE):
			chunk = people[i:i + CHUNK_PEOPLE]
			# Dosyalar kilit tutulurken yazılır: başka bir koşunun içe aktarması yarım dosya görmez.
			with import_lock():
				for gid in chunk:
					for kind, src, dst, fresh in jobs[gid]:
						if not fresh:
							resizer.resize(src, dst, kind)
						ensure_import(dst, "texture", texture_params(IMAGE_LIMITS[kind]), write=True)
				log(f"  {i + len(chunk)}/{len(people)} kişi yazıldı ({resizer.backend or 'yeniden küçültme yok'})")
				godot_import(run_godot)
	finally:
		resizer.close()
	return count


def image_orphans(site: dict) -> list[str]:
	known = {snake(e["id"]) for e in site["entries"] if e.get("id")}
	if not IMAGE_DIR.exists():
		return []
	return sorted(d.name for d in IMAGE_DIR.iterdir() if d.is_dir() and d.name not in known)


# --- Tanıtım sesleri --------------------------------------------------------------------------------

def voice_jobs(site: dict) -> list[tuple[Path, Path]]:
	jobs = []
	for e in site["entries"]:
		if not e.get("id") or e.get("speaks") is False or not (e.get("intro") or {}).get("en"):
			continue
		src = VOICE_SRC / f"ency.{e['id']}.mp3"
		if not src.is_file() or src.stat().st_size == 0 or time.time() - src.stat().st_mtime < SETTLE_SECONDS:
			continue
		dst = VOICE_DIR / f"{snake(e['id'])}.mp3"
		same = dst.is_file() and dst.stat().st_size == src.stat().st_size and dst.read_bytes() == src.read_bytes()
		if same and not ensure_import(dst, "mp3", MP3_PARAMS, write=False):
			continue
		jobs.append((src, dst))
	return jobs


def import_voices(site: dict, write: bool, run_godot: bool) -> int:
	jobs = voice_jobs(site)
	log(f"Tanıtım sesleri: {len(jobs)} dosya kopyalanacak")
	if not write or not jobs:
		return len(jobs)
	with import_lock():
		VOICE_DIR.mkdir(parents=True, exist_ok=True)
		for src, dst in jobs:
			# Olduğu gibi: yeniden kodlamak kayıp ekler (K61).
			shutil.copyfile(src, dst)
			ensure_import(dst, "mp3", MP3_PARAMS, write=True)
		godot_import(run_godot)
	return len(jobs)


# --- Ana akış ---------------------------------------------------------------------------------------

def main() -> int:
	ap = argparse.ArgumentParser(description="Sitenin ansiklopedisini Destan Kitabı'na aktarır.")
	ap.add_argument("--images", action="store_true", help="görselleri küçültüp kopyala")
	ap.add_argument("--voices", action="store_true", help="tanıtım seslerini kopyala")
	ap.add_argument("--all", action="store_true", help="görseller, sesler ve veri")
	ap.add_argument("--check", action="store_true", help="yazmadan değişiklik raporu (değişiklik varsa çıkış 1)")
	ap.add_argument("--no-godot", action="store_true", help="Godot içe aktarmasını çalıştırma")
	ap.add_argument("--no-data", action="store_true", help="yalnız görseller ve sesler; veri dosyaları yazılmaz")
	args = ap.parse_args()
	write = not args.check
	site = json.loads(SITE_JSON.read_text(encoding="utf-8"))
	changes = 0
	if args.images or args.all or args.check:
		changes += import_images(site, write, not args.no_godot)
		orphans = image_orphans(site)
		if orphans:
			log(f"  Sitede kaydı olmayan görsel klasörleri (elle silinir): {', '.join(orphans)}")
	if args.voices or args.all or args.check:
		changes += import_voices(site, write, not args.no_godot)
	if args.no_data:
		return 1 if args.check and changes else 0
	people = build_file(site, myths=False)
	myths = build_file(site, myths=True)
	problems = validate(people, myths)
	if problems:
		for p in problems:
			log(f"  ! {p}")
		log("Site biçimi beklenenden farklı: veri yazılmadı.")
		return 2
	for path, data, key in ((PEOPLE_FILE, people, "people"), (MYTHS_FILE, myths, "myths")):
		text = dump(data)
		old = path.read_text(encoding="utf-8") if path.exists() else ""
		rows = data[key]
		with_img = sum(1 for r in rows if r["images"]["art"] or r["images"]["portrait"])
		with_voice = sum(1 for r in rows if r["intro_audio"])
		state = "değişmedi" if text == old else ("değişecek" if args.check else "yazıldı")
		log(f"{path.relative_to(GAME)}: {len(rows)} kayıt, {with_img} görselli, {with_voice} sesli ({state})")
		if text != old:
			changes += 1
			if write:
				path.write_text(text, encoding="utf-8")
	return 1 if args.check and changes else 0


if __name__ == "__main__":
	sys.exit(main())
