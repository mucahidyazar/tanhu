#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# ElevenLabs aracı: seslendirme (tts), şarkı (music), ses efekti (sfx), yazıya çevirme (stt) ve kota.
# Kurallar: decisions.md K61 ve K28, audio.md §5, godot.md §3.3. Satırlar data/vo_lines.json'dadır (VoLines).
#
# Anahtar ELEVENLABS_API_KEY ortam değişkeninden, yoksa .env dosyasından okunur (--env-file=<yol> ya da
# ELEVENLABS_ENV_FILE; varsayılan /Users/mucahidyazar/Code/tests/tanhu-programatic-test/.env). Anahtar
# yazdırılmaz, dosyaya yazılmaz ve komut satırına girmez: curl başlığı standart girdiden okur.
#
# Kullanım (oyun klasöründen):
#   tools/elevenlabs_audio.sh [tts] --lines=act0.myth.3,act0.birth.12    satırları üretir (kimlik ya da kalıp)
#   tools/elevenlabs_audio.sh --lines='act0.myth.*' --cost               bekleyenlerin bedeli (ağsız)
#   tools/elevenlabs_audio.sh --lines='act0.myth.*' --dry-run            istek gövdesi ve defter satırı (ağsız)
#   tools/elevenlabs_audio.sh --lines=act0.myth.4 --force --take=2       beğenilmeyen okuma başka tohumla
#   tools/elevenlabs_audio.sh --lines=<kimlik> --response=<yanıt>        saklanan yanıtı yeniden çağırmadan işler
#   tools/elevenlabs_audio.sh --lines='act0.myth.*' --block              satırları tek çağrıda okur, sessizliklerden keser
#   tools/elevenlabs_audio.sh music --plan=<plan.json> --out=<şarkı.mp3> [--id=<kimlik>] [--seed=N] [--take=N]
#   tools/elevenlabs_audio.sh sfx <çıktı.mp3> <süre_sn> <loop:true|false> "<istem>" [--id=<kimlik>] [--wav]
#   tools/elevenlabs_audio.sh stt --lines=<kimlikler> [--write-timing]   Scribe v2 ile metin denetimi
#   tools/elevenlabs_audio.sh quota                                       kalan kredi
#
# tts: eleven_v3, with-timestamps ucu, çıktı mp3_44100_64 → <perde klasörü>/<id>.mp3 ve sözcük zamanı
#   <id>.json; satırın file, timing, seconds (gerçek süre), take ve take_hash alanları yazılır. Tohum satırın
#   karmasından ve çekimden gelir. Kilitsiz ya da kilidi tutmayan perdenin A/B satırı üretilmez (çıkış 4).
#   Dosyası güncel satıra kredi harcanmaz (--force yeniden üretir). Sesi seçilmemiş satır atlanır;
#   voice_pending satırı geçici sesle okunur. --no-timestamps düz ucu kullanır (sözcük zamanı yazılmaz).
#   --block: seçilen satırlar (aynı ses, model, ayar) tek çağrıda mp3_44100_128 okunur, ton satır aralarında kopmaz; satırlar
#   sözcük zamanı ve zarftan sessizliğin ortasında kesilir, her biri mp3_44100_64 kodlanır. Satırın dosyası, sözcük zamanı ve
#   alanları tek satır okumasıyla aynıdır; deftere blok tek satır yazılır. Ham yanıt ve bloğun sesi --keep=<klasör>'de kalır
#   (varsayılan ../docs/media/review/audio/blocks); --block --response=<yanıt> onu yeniden çağırmadan keser. ffmpeg ister.
# music: music_v2_5, composition_plan --plan'dan (çekim dosyası da olur), çıktı mp3_44100_128 ve <çıktı>.json.
# sfx: eleven_text_to_sound_v2; --wav ile ffmpeg 22,05 kHz mono WAV yazar.
# Ortak: --dry-run ve --cost ağsızdır; --over kota kapısını geçer; --remaining=N kalanı elle verir;
#   --ledger=<defter> (varsayılan tools/vo_ledger.jsonl); --data=<veri> (varsayılan data/vo_lines.json).
# Defter: her API çağrısı bir JSON satırı: {at, product, id, take, credits, chars, voice, model}; kredi
#   konuşmada character-cost başlığından, müzik, efekt ve stt'de aboneliğin farkından okunur.
# Kota kapısı: çağrıdan önce kalan okunur; plan kalandan büyükse araç durur (çıkış 3) ve --over ister.
# Çıkış: 0 tamam, 1 kullanım ya da veri hatası, 2 API ya da işleme hatası, 3 kota, 4 metin kilidi.
# ---------------------------------------------------------------------------
set -euo pipefail

GAME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "${1:-}" in
	"" | help | -h | --help)
		awk 'NR > 2 && /^# -----/ { exit } NR > 2 { sub(/^# ?/, ""); print }' "${BASH_SOURCE[0]}"
		if [[ -n "${1:-}" ]]; then exit 0; else exit 1; fi
		;;
esac

for tool in python3 curl; do
	if ! command -v "$tool" >/dev/null 2>&1; then
		echo "HATA: $tool bulunamadı." >&2
		exit 1
	fi
done

# Asıl iş Python'dadır (JSON, karma, base64, sözcük zamanı); -I: kullanıcı ve çalışma klasörü modülleri yüklenmez.
exec python3 -I - "$GAME_ROOT" "$PWD" "$@" <<'PY'
import array
import base64
import binascii
import datetime
import fnmatch
import hashlib
import json
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.parse
import wave

GAME_ROOT, CALLER_PWD = sys.argv[1], sys.argv[2]
ARGS = sys.argv[3:]
# Türkçe iletiler, yerel ayar ne olursa olsun UTF-8 yazılır.
sys.stdout.reconfigure(encoding="utf-8")
sys.stderr.reconfigure(encoding="utf-8")

API_DEFAULT = "https://api.elevenlabs.io"
# Konuşma satırı: MP3 44,1 kHz 64 kb/sn (K61; Godot MP3'ü olduğu gibi içe aktarır, satır ≈8 KB/sn).
TTS_FORMAT = "mp3_44100_64"
TTS_MODELS = ("eleven_v3",)
# Blok okuma: 128 kb/sn okunur, kesilen satır TTS_FORMAT'ın biçiminde kodlanır (bir kuşak kayıp az kalsın diye).
BLOCK_FORMAT = "mp3_44100_128"
BLOCK_BITRATE = "64k"
BLOCK_SEPARATOR = "\n\n"
# Zarf adımı, sessizlik eşikleri (gevşeyerek denenir) ve en kısa sessizlik (sn, dBFS).
BLOCK_HOP = 0.005
BLOCK_QUIET_DB = (-50.0, -44.0, -38.0)
BLOCK_MIN_QUIET = 0.12
# Sınırın, sözcük zamanlarının gösterdiği yere en çok bu kadar uzak olabilir (sn).
BLOCK_QUIET_REACH = 1.5
# Kesimin payları: sessizlik başladıktan sonra doğal sönüş, sonraki sözden önce nefes, uçlardaki yumuşatma (sn).
BLOCK_TAIL = 0.16
BLOCK_HEAD = 0.05
BLOCK_FADE_IN = 0.005
BLOCK_FADE_OUT = 0.03
BLOCK_FADE_LONG = 0.08
# Konuşma −18 LUFS (K78): bütün satırlara bloğun tek kazancı uygulanır, satırların birbirine göre düzeyi değişmez.
BLOCK_LUFS = -18.0
# Kesimin hemen önündeki düzey bundan yüksekse söz kesilmiş olabilir (dBFS).
BLOCK_CUT_WARN_DB = -40.0
DEFAULT_BLOCK_DIR = os.path.join(GAME_ROOT, "..", "docs", "media", "review", "audio", "blocks")
# eleven_v3 kararlılığı yalnız bu üç değeri alır (K17).
STABILITY_STEPS = (0, 0.5, 1)
# Şarkı: Eleven Music music_v2_5 (eski müzik modeli 31 Ocak 2027'de kalkar), 128 kb/sn.
MUSIC_MODEL = "music_v2_5"
MUSIC_FORMAT = "mp3_44100_128"
SFX_MODEL = "eleven_text_to_sound_v2"
SFX_FORMAT = "mp3_44100_128"
STT_MODEL = "scribe_v2"
# Metin kilidi olmadan üretilmeyen dilimler (K61).
LOCKED_TIERS = ("A", "B")
# Çekim karması prototipin tools/voices.mjs karmasıyla aynıdır: sha1 [kaynak, ses, model, ayar, metin].
TAKE_SOURCE = "elevenlabs"
SETTING_KEYS = ("stability", "similarity_boost")
SEED_STEP = 7919
# Kapının tahminleri; gerçek kredi deftere başlıktan ya da aboneliğin farkından yazılır.
MUSIC_CREDITS_PER_MINUTE = 900
SFX_CREDITS_PER_SECOND = 40
STT_CREDITS_PER_MINUTE = 330
DEFAULT_DATA = os.path.join(GAME_ROOT, "data", "vo_lines.json")
DEFAULT_LEDGER = os.path.join(GAME_ROOT, "tools", "vo_ledger.jsonl")
DEFAULT_ENV_FILE = "/Users/mucahidyazar/Code/tests/tanhu-programatic-test/.env"
RETRIES = 3

COMMON_VALUES = {"ledger", "remaining", "env-file"}
COMMON_FLAGS = {"dry-run", "cost", "over"}


class Fail(Exception):
	def __init__(self, code, message):
		super().__init__(message)
		self.code = code
		self.message = message


def die(code, message):
	raise Fail(code, message)


# --- Seçenekler ve yollar -------------------------------------------------------------

def options(rest, values=(), flags=(), positional=0):
	"""--ad=değer ve --bayrak; bilinmeyen seçenek hatadır (ör. yanlış yazılmış --dry-run gerçek çağrıya dönmesin)."""
	values = set(values) | COMMON_VALUES
	flags = set(flags) | COMMON_FLAGS
	opts, pos = {}, []
	for arg in rest:
		if arg.startswith("--"):
			name, eq, value = arg[2:].partition("=")
			if eq and name in values:
				opts[name] = value
			elif not eq and name in flags:
				opts[name] = True
			elif name in values:
				die(1, f"--{name}=<değer> biçiminde verilmeli")
			elif name in flags:
				die(1, f"--{name} değer almaz")
			else:
				die(1, f"bilinmeyen seçenek: {arg.split('=')[0]}")
		else:
			pos.append(arg)
	if len(pos) != positional:
		die(1, f"{positional} konum bağımsız değişkeni bekleniyordu, {len(pos)} geldi: {' '.join(pos)}")
	if opts.get("dry-run") and opts.get("cost"):
		die(1, "--dry-run ile --cost birlikte verilmez")
	return opts, pos


def need(opts, name):
	value = opts.get(name)
	if not isinstance(value, str) or not value:
		die(1, f"--{name}=<değer> gerekli")
	return value


def as_int(value, name, low=0):
	try:
		number = int(str(value))
	except ValueError:
		die(1, f"{name} tam sayı olmalı: {value}")
	if number < low:
		die(1, f"{name} en az {low} olmalı: {value}")
	return number


def from_caller(path):
	return os.path.normpath(path if os.path.isabs(path) else os.path.join(CALLER_PWD, path))


def res_to_fs(path):
	if path.startswith("res://"):
		return os.path.join(GAME_ROOT, path[len("res://"):])
	return from_caller(path)


def fs_to_res(path):
	rel = os.path.relpath(path, GAME_ROOT)
	return path if rel.startswith("..") else "res://" + rel.replace(os.sep, "/")


def is_num(value):
	return isinstance(value, (int, float)) and not isinstance(value, bool)


def json_number(value):
	"""JSON sayısı JavaScript'in yazdığı gibi: tam değer ondalıksız."""
	return int(value) if float(value).is_integer() else value


def now():
	return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load_json(path, what="dosya"):
	try:
		with open(path, encoding="utf-8") as f:
			return json.load(f)
	except FileNotFoundError:
		die(1, f"{what} yok: {path}")
	except json.JSONDecodeError as e:
		die(1, f"{what} bozuk: {path}: {e}")


def write_bytes(path, data):
	os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
	tmp = path + ".part"
	with open(tmp, "wb") as f:
		f.write(data)
	os.replace(tmp, path)


def write_text(path, text):
	write_bytes(path, text.encode("utf-8"))


def save_data(path, data):
	write_text(path, json.dumps(data, ensure_ascii=False, indent="\t") + "\n")


def dump_timing(timing):
	"""Sözcük zamanı dosyası: her sözcük bir satır (şarkının dosyasıyla aynı biçim)."""
	items = list(timing.items())
	out = ["{"]
	for i, (key, value) in enumerate(items):
		comma = "," if i < len(items) - 1 else ""
		if key in ("words", "lines") and isinstance(value, list):
			out.append(f"\t{json.dumps(key)}: [")
			for j, item in enumerate(value):
				out.append("\t\t" + json.dumps(item, ensure_ascii=False) + ("," if j < len(value) - 1 else ""))
			out.append("\t]" + comma)
		else:
			out.append(f"\t{json.dumps(key)}: {json.dumps(value, ensure_ascii=False)}{comma}")
	out.append("}")
	return "\n".join(out) + "\n"


# --- Satır verisi: kilit, karma, seçim ------------------------------------------------

def lock_text(data, act):
	"""Perdenin kilitlenen metni: A ve B satırları, kimliğe göre sıralı «kimlik<TAB>EN» (VoLines.lock_text)."""
	rows = sorted(
		(line.get("id", ""), line.get("text", {}).get("en", ""))
		for line in data.get("lines", [])
		if is_num(line.get("act")) and int(line["act"]) == act and line.get("tier") in LOCKED_TIERS)
	return "\n".join(f"{i}\t{en}" for i, en in rows)


def lock_hash(data, act):
	return hashlib.sha1(lock_text(data, act).encode("utf-8")).hexdigest()


def lock_problem(data, act):
	lock = data.get("locks", {}).get(str(act))
	if not isinstance(lock, dict) or not isinstance(lock.get("hash"), str):
		return f"perde {act} metni kilitli değil (locks['{act}'] yok)"
	if lock["hash"] != lock_hash(data, act):
		return f"perde {act} metni kilitten sonra değişti (kilit {lock['hash'][:8]}, metin {lock_hash(data, act)[:8]})"
	return None


def settings_of(line):
	return {key: json_number(line[key]) for key in SETTING_KEYS if is_num(line.get(key))}


def take_hash(line):
	"""Okuma satırının çekim karması (VoLines.take_hash): ilk 12 onaltılık hane."""
	text = json.dumps([TAKE_SOURCE, line.get("voice"), line.get("model"), settings_of(line), line["text"]["en"]],
		ensure_ascii=False, separators=(",", ":"))
	return hashlib.sha1(text.encode("utf-8")).hexdigest()[:12]


def seed_of(digest, take):
	return (int(digest[:8], 16) + take * SEED_STEP) % 4294967296


def select(data, spec):
	"""Kimlik ya da kalıp listesi (virgüllü; act0.myth.* gibi) → satırlar, dosyadaki sırayla."""
	patterns = [p.strip() for p in spec.split(",") if p.strip()]
	if not patterns:
		die(1, "--lines boş")
	lines = data.get("lines", [])
	chosen = {}
	for pattern in patterns:
		hits = [line for line in lines if fnmatch.fnmatchcase(str(line.get("id", "")), pattern)]
		if not hits:
			die(1, f"--lines: «{pattern}» hiçbir satırı tutmuyor")
		for line in hits:
			chosen[line["id"]] = line
	return [line for line in lines if line.get("id") in chosen]


def tts_unready(line):
	"""Satır okunamıyorsa nedeni (yoksa None)."""
	if line.get("kind") != "line":
		return "şarkı ya da şarkının altyazı dizesi; ayrıca okunmaz"
	if line.get("tier") == "D":
		return "D dilimi yazıdır, ses almaz"
	if not isinstance(line.get("voice"), str) or not line["voice"]:
		return "ses seçilmedi; satır altyazıyla akar"
	if line.get("model") not in TTS_MODELS:
		return f"model {line.get('model')} bir okuma modeli değil"
	if line.get("stability") not in STABILITY_STEPS:
		return "eleven_v3 kararlılığı yalnız 0, 0,5 ya da 1 olabilir (K17)"
	if not str(line.get("text", {}).get("en", "")).strip():
		return "EN metin boş"
	return None


def tts_state(line, digest, take, force):
	"""Satırın üretilmesi gerekiyorsa nedeni; dosyası güncelse None (kredi harcanmaz)."""
	if force:
		return "--force"
	path = line.get("file")
	if not isinstance(path, str):
		return "dosyası yok"
	if not os.path.exists(res_to_fs(path)):
		return "dosyası diskte yok"
	if line.get("take_hash") != digest:
		return "metin, ses ya da ayar dosyadan sonra değişti"
	if int(line.get("take") or 0) != take:
		return f"başka çekim ({take})"
	return None


def target_paths(data, line, out_dir):
	if out_dir:
		base = out_dir
	else:
		folder = data.get("dirs", {}).get(str(int(line["act"])))
		if not isinstance(folder, str):
			die(1, f"{line['id']}: perde {int(line['act'])} için dirs klasörü yok")
		base = res_to_fs(folder)
	return os.path.join(base, line["id"] + ".mp3"), os.path.join(base, line["id"] + ".json")


# --- Ağ ------------------------------------------------------------------------------

_secret = None


def read_key(opts):
	"""Anahtar: ortam değişkeni, yoksa .env. Hiçbir yere yazılmaz."""
	global _secret
	if _secret:
		return _secret
	value = os.environ.get("ELEVENLABS_API_KEY", "").strip()
	if not value:
		env_file = from_caller(opts.get("env-file") or os.environ.get("ELEVENLABS_ENV_FILE") or DEFAULT_ENV_FILE)
		try:
			with open(env_file, encoding="utf-8") as f:
				for row in f:
					m = re.match(r"^\s*(?:export\s+)?ELEVENLABS_API_KEY\s*=\s*(.*?)\s*$", row)
					if m:
						value = m.group(1).strip().strip("'\"")
						break
		except OSError:
			pass
	if not value or "\n" in value or "\r" in value:
		die(1, "ELEVENLABS_API_KEY bulunamadı: ortam değişkeni ya da .env satırı gerekli (--env-file=, ELEVENLABS_ENV_FILE)")
	_secret = value
	return _secret


def api_base():
	"""API kökü; ELEVENLABS_API_BASE yalnız yerel sınama sunucusunu gösterebilir (anahtar dışarı gitmesin)."""
	base = os.environ.get("ELEVENLABS_API_BASE", "").strip().rstrip("/") or API_DEFAULT
	if base != API_DEFAULT and not re.fullmatch(r"http://(127\.0\.0\.1|localhost)(:\d+)?", base):
		die(1, "ELEVENLABS_API_BASE yalnız yerel sınama sunucusu olabilir (http://127.0.0.1:<port>)")
	return base


def read_headers(path):
	"""curl -D dosyasının son başlık bloğu → {küçük harfli ad: değer}."""
	try:
		with open(path, encoding="latin-1") as f:
			blocks = [b for b in re.split(r"\r?\n\r?\n", f.read()) if b.strip()]
	except OSError:
		return {}
	headers = {}
	for row in (blocks[-1].splitlines()[1:] if blocks else []):
		name, sep, value = row.partition(":")
		if sep:
			headers[name.strip().lower()] = value.strip()
	return headers


def request(method, path, opts, out_path, body=None, form=None, accept=None):
	"""curl ile istek; anahtar başlığı standart girdiden gider. 429 ve 5xx'te kısa beklemeyle yeniden dener.
	→ (durum, başlıklar). Başarısızlıkta Fail(2); hata iletisi anahtarı içermez."""
	key = read_key(opts)
	work = tempfile.mkdtemp(prefix="tanhu_eleven_req_")
	head_path = os.path.join(work, "headers.txt")
	command = ["curl", "-sS", "--max-time", "600", "-X", method, api_base() + path, "-H", "@-",
		"-D", head_path, "-o", out_path, "-w", "%{http_code}"]
	if body is not None:
		body_path = os.path.join(work, "body.json")
		with open(body_path, "w", encoding="utf-8") as f:
			json.dump(body, f, ensure_ascii=False)
		command += ["-H", "Content-Type: application/json", "--data-binary", "@" + body_path]
	for name, value in form or []:
		command += ["-F", f"{name}={value}"]
	if accept:
		command += ["-H", "Accept: " + accept]
	try:
		for attempt in range(RETRIES + 1):
			done = subprocess.run(command, input=f"xi-api-key: {key}\n", capture_output=True, text=True)
			if done.returncode != 0:
				die(2, f"{method} {path.split('?')[0]}: curl {done.returncode}: {done.stderr.strip()[:300]}")
			status = int(done.stdout.strip()) if done.stdout.strip().isdigit() else 0
			if (status == 429 or status >= 500) and attempt < RETRIES:
				time.sleep(2 * (attempt + 1))
				continue
			break
		headers = read_headers(head_path)
	finally:
		shutil.rmtree(work, ignore_errors=True)
	if not 200 <= status < 300:
		detail = ""
		try:
			with open(out_path, "rb") as f:
				detail = f.read(600).decode("utf-8", "replace")
		except OSError:
			pass
		die(2, f"{method} {path.split('?')[0]} → {status}: {detail}")
	return status, headers


def subscription(opts):
	work = tempfile.mkdtemp(prefix="tanhu_eleven_sub_")
	try:
		out = os.path.join(work, "subscription.json")
		request("GET", "/v1/user/subscription", opts, out)
		info = load_json(out, "abonelik yanıtı")
	finally:
		shutil.rmtree(work, ignore_errors=True)
	used = int(info.get("character_count", 0))
	limit = int(info.get("character_limit", 0))
	return {"tier": info.get("tier"), "used": used, "limit": limit, "remaining": limit - used}


def gate(cost, opts, offline):
	"""Kota kapısı: plan kalandan büyükse durur, --over geçer. → kapıda okunan abonelik ya da None."""
	sub = None
	if "remaining" in opts:
		remaining, source = as_int(opts["remaining"], "--remaining", low=-10**12), "elle verilen"
	elif offline:
		print(f"Kota: ağsız koşu, kalan okunmadı; bu iş ≈{cost} kredi.")
		return None
	else:
		sub = subscription(opts)
		remaining, source = sub["remaining"], f"plan {sub['tier']}"
	print(f"Kota: kalan {remaining} kredi ({source}); bu iş ≈{cost} kredi.")
	if cost > remaining:
		if not opts.get("over"):
			die(3, f"plan (≈{cost} kredi) kalandan ({remaining}) büyük: durduruldu. Onaylıysa --over ile yeniden çalıştırın.")
		print("Uyarı: --over ile kalanın üstüne çıkılıyor.")
	return sub


def ledger_path(opts):
	return from_caller(opts["ledger"]) if "ledger" in opts else DEFAULT_LEDGER


def ledger_entry(product, item_id, take, credits, chars, voice, model):
	return {"at": now(), "product": product, "id": item_id, "take": take, "credits": credits, "chars": chars,
		"voice": voice, "model": model}


def append_ledger(path, entry):
	os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
	with open(path, "a", encoding="utf-8") as f:
		f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def show_request(method, path, body):
	print(f"istek: {method} {api_base()}{path}")
	if body is not None:
		print("gövde: " + json.dumps(body, ensure_ascii=False))


def show_ledger(entry):
	print("defter: " + json.dumps({**entry, "dry_run": True}, ensure_ascii=False))


# --- Ses dosyası ----------------------------------------------------------------------

def looks_like_mp3(data):
	return len(data) > 256 and (data[:3] == b"ID3" or (data[0] == 0xFF and (data[1] & 0xE0) == 0xE0))


def probe_seconds(path):
	if not shutil.which("ffprobe"):
		raise ValueError("ffprobe bulunamadı (süre ölçülemedi)")
	done = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
		"-of", "default=noprint_wrappers=1:nokey=1", path], capture_output=True, text=True)
	try:
		return float(done.stdout.strip())
	except ValueError:
		raise ValueError(f"ffprobe süreyi okuyamadı: {path}: {done.stderr.strip()[:200]}")


def tokens(text):
	return [t for t in re.split(r"\s+", text.strip()) if t]


def norm(word):
	return re.sub(r"[\W_]+", "", word.lower())


def words_from_alignment(alignment):
	"""Karakter zamanları → sözcükler [{w, t0, t1}] (boşlukla bölünür; sözcük metnin yazımıyla kalır)."""
	if not isinstance(alignment, dict):
		return []
	chars = alignment.get("characters") or []
	starts = alignment.get("character_start_times_seconds") or []
	ends = alignment.get("character_end_times_seconds") or []
	if not chars or len(chars) != len(starts) or len(chars) != len(ends):
		return []
	words, word, t0, t1 = [], "", 0.0, 0.0
	for char, start, end in zip(chars, starts, ends):
		if char.isspace():
			if word:
				words.append({"w": word, "t0": round(t0, 3), "t1": round(t1, 3)})
				word = ""
			continue
		if not word:
			t0 = float(start)
		word += char
		t1 = float(end)
	if word:
		words.append({"w": word, "t0": round(t0, 3), "t1": round(t1, 3)})
	return words


# --- tts ------------------------------------------------------------------------------

def tts_path(line, timestamps):
	voice = urllib.parse.quote(line["voice"], safe="")
	suffix = "/with-timestamps" if timestamps else ""
	return f"/v1/text-to-speech/{voice}{suffix}?output_format={TTS_FORMAT}"


def tts_body(line, seed):
	return {"text": line["text"]["en"], "model_id": line["model"], "voice_settings": settings_of(line), "seed": seed}


def tts_process(job, raw_path, mp3_path, timing_path, work):
	"""Yanıt (with-timestamps JSON'u ya da düz MP3) → ses, sözcük zamanı ve satırın alanları. Ses önce geçici
	dosyaya yazılır ve ölçülür; eski çekim ancak yenisi bütünüyle işlenince yerini bırakır."""
	line = job["line"]
	with open(raw_path, "rb") as f:
		raw = f.read()
	alignment = None
	if raw[:1] == b"{":
		response = json.loads(raw.decode("utf-8"))
		audio = base64.b64decode(response["audio_base64"])
		alignment = response.get("alignment") or response.get("normalized_alignment")
	else:
		audio = raw
	if not looks_like_mp3(audio):
		raise ValueError("yanıtta MP3 yok")
	staged = os.path.join(work, line["id"] + ".mp3")
	write_bytes(staged, audio)
	seconds = round(probe_seconds(staged), 3)
	words = words_from_alignment(alignment)
	write_bytes(mp3_path, audio)
	if words:
		if [norm(w["w"]) for w in words] != [norm(t) for t in tokens(line["text"]["en"])]:
			print(f"Uyarı: {line['id']}: sözcük zamanlarının sözcükleri metinle aynı sırada değil; dosyayı dinleyin.")
		write_text(timing_path, dump_timing({"id": line["id"], "take": job["take"], "seed": job["seed"],
			"hash": job["hash"], "model": line["model"], "voice": line["voice"], "seconds": seconds, "words": words}))
		line["timing"] = fs_to_res(timing_path)
	else:
		if os.path.exists(timing_path):
			os.remove(timing_path)
		line["timing"] = None
		print(f"Uyarı: {line['id']}: yanıtta sözcük zamanı yok; altyazı satır boyunca akar (stt --write-timing ekler).")
	line["file"] = fs_to_res(mp3_path)
	line["seconds"] = seconds
	line["take"] = job["take"]
	line["take_hash"] = job["hash"]
	return seconds, len(words)


# --- tts: blok okuma ------------------------------------------------------------------

def block_text(lines):
	"""Satırların ortak metni ve her satırın metindeki yeri: (metin, [(başlangıç, bitiş), ...])."""
	text, spans = "", []
	for index, line in enumerate(lines):
		if index:
			text += BLOCK_SEPARATOR
		begin = len(text)
		text += line["text"]["en"]
		spans.append((begin, len(text)))
	return text, spans


def block_id(lines):
	return f"block:{lines[0]['id']}..{lines[-1]['id']}"


def block_hash(line, text):
	"""Bloğun karması (tohum için): take_hash'in biçimi, metni bloğun metni."""
	payload = json.dumps([TAKE_SOURCE, line.get("voice"), line.get("model"), settings_of(line), text],
		ensure_ascii=False, separators=(",", ":"))
	return hashlib.sha1(payload.encode("utf-8")).hexdigest()[:12]


def align_spans(alignment, text, spans):
	"""Satırların yeri zaman dizilerinde: [(başlangıç, bitiş), ...]; boşluk dışındaki karakterler tutmazsa None."""
	if not isinstance(alignment, dict):
		return None
	chars = alignment.get("characters") or []
	starts = alignment.get("character_start_times_seconds") or []
	ends = alignment.get("character_end_times_seconds") or []
	if not chars or len(chars) != len(starts) or len(chars) != len(ends):
		return None
	solid = [i for i, char in enumerate(chars) if not char.isspace()]
	if [chars[i] for i in solid] != [char for char in text if not char.isspace()]:
		return None
	out, seen = [], 0
	for begin, end in spans:
		count = sum(1 for char in text[begin:end] if not char.isspace())
		out.append((solid[seen], solid[seen + count - 1] + 1))
		seen += count
	return out


def read_levels(wav_path):
	"""16 bit mono WAV → (zarf, adım): yaklaşık BLOCK_HOP'ta bir düzey (dBFS) ve adımın gerçek süresi (sn)."""
	with wave.open(wav_path, "rb") as w:
		rate = w.getframerate()
		raw = w.readframes(w.getnframes())
	samples = array.array("h")
	samples.frombytes(raw)
	if sys.byteorder == "big":
		samples.byteswap()
	hop = max(1, round(rate * BLOCK_HOP))
	levels = []
	for at in range(0, len(samples), hop):
		part = samples[at:at + hop]
		power = sum(s * s for s in part) / max(1, len(part))
		levels.append(10.0 * math.log10(power / 1073741824.0) if power > 0 else -120.0)
	return levels, hop / rate


def quiet_runs(levels, step, limit):
	"""Eşiğin altındaki, BLOCK_MIN_QUIET'ten uzun sessizlikler: [(başlangıç, bitiş), ...] sn (kapanma sesleri elenir)."""
	runs, begin = [], None
	for i in range(len(levels) + 1):
		quiet = i < len(levels) and levels[i] < limit
		if quiet and begin is None:
			begin = i
		elif not quiet and begin is not None:
			if (i - begin) * step >= BLOCK_MIN_QUIET:
				runs.append((begin * step, i * step))
			begin = None
	return runs


def nearest_quiet(levels, step, at):
	"""at anına en yakın sessizlik (sn); eşik gevşeyerek denenir, BLOCK_QUIET_REACH'te yoksa None."""
	for limit in BLOCK_QUIET_DB:
		best, gap = None, BLOCK_QUIET_REACH
		for run in quiet_runs(levels, step, limit):
			distance = 0.0 if run[0] <= at <= run[1] else min(abs(run[0] - at), abs(run[1] - at))
			if distance <= gap:
				best, gap = run, distance
		if best:
			return best
	return None


def block_cuts(lines, spans, alignment, levels, step):
	"""Satırların kesim aralıkları: [(t0, t1, önceki sessizlik, sesin bittiği an), ...]. Sınır, sözcük zamanlarının gösterdiği yere (satırın sonu
	ile sonraki satırın başının ortası) en yakın sessizliktir: modelin zamanları duraklamayı sonraki sözcüğe yazabilir, bu
	yüzden zaman yalnız yeri gösterir, kesimi zarf verir. Sessizlik bulunamayan sınırda hata."""
	starts = alignment["character_start_times_seconds"]
	ends = alignment["character_end_times_seconds"]
	duration = len(levels) * step
	loud = [i for i, level in enumerate(levels) if level >= BLOCK_QUIET_DB[0]]
	if not loud:
		raise ValueError("blokta ses yok")
	cuts, begin, pause = [], max(0.0, loud[0] * step - BLOCK_HEAD), 0.0
	for index, line in enumerate(lines):
		if index == len(lines) - 1:
			last = (loud[-1] + 1) * step
			cuts.append((begin, min(duration, last + BLOCK_TAIL), pause, last))
			break
		at = 0.5 * (float(ends[spans[index][1] - 1]) + float(starts[spans[index + 1][0]]))
		quiet = nearest_quiet(levels, step, at)
		if quiet is None or quiet[0] <= begin + BLOCK_HEAD:
			raise ValueError(f"{line['id']} ile sonraki satır arasında sessizlik bulunamadı")
		end = min(quiet[0] + BLOCK_TAIL, quiet[1])
		cuts.append((begin, end, pause, quiet[0]))
		begin = max(quiet[1] - BLOCK_HEAD, end)
		pause = quiet[1] - quiet[0]
	return cuts


def block_words(alignment, span, runs, t0, speech_end, seconds):
	"""Satırın sözcükleri, kesimin başından sayılır. Modelin zamanları duraklamayı sözcüğe yazabilir: sessizliğe düşen başlangıç
	sessizliğin sonuna, bitiş başına çekilir; sözcük sonrakinin başını aşmaz, son sözcük sesin bittiği yerde biter."""
	low, high = span
	part = {key: alignment[key][low:high] for key in
		("characters", "character_start_times_seconds", "character_end_times_seconds")}
	words = words_from_alignment(part)
	for word in words:
		for a, b in runs:
			if a <= word["t0"] < b:
				word["t0"] = b
			if a < word["t1"] <= b:
				word["t1"] = a
	for index, word in enumerate(words):
		if index == len(words) - 1:
			word["t1"] = max(speech_end, word["t0"])
		else:
			following = words[index + 1]["t0"]
			word["t0"] = min(word["t0"], following)
			if word["t1"] <= word["t0"] or word["t1"] > following:
				word["t1"] = following
	for word in words:
		word["t0"] = round(min(max(word["t0"] - t0, 0.0), seconds), 3)
		word["t1"] = round(min(max(word["t1"] - t0, 0.0), seconds), 3)
	return words


def measure_gain(wav_path):
	"""Bloğu BLOCK_LUFS'a getiren kazanç (dB); ölçülemezse 0."""
	done = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", wav_path, "-filter_complex", "ebur128", "-f", "null", "-"],
		capture_output=True, text=True)
	values = re.findall(r"I:\s+(-?\d+(?:\.\d+)?) LUFS", done.stderr)
	return round(BLOCK_LUFS - float(values[-1]), 2) if values else 0.0


def encode_part(wav_path, t0, t1, fade_out, gain, out_path):
	length = t1 - t0
	shape = (f"atrim=start={t0:.3f}:end={t1:.3f},asetpts=PTS-STARTPTS,afade=t=in:st=0:d={BLOCK_FADE_IN},"
		f"afade=t=out:st={max(0.0, length - fade_out):.3f}:d={fade_out},volume={gain}dB")
	done = subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav_path, "-af", shape, "-ac", "1", "-ar", "44100",
		"-c:a", "libmp3lame", "-b:a", BLOCK_BITRATE, out_path], capture_output=True, text=True)
	if done.returncode != 0:
		raise ValueError(f"ffmpeg kesemedi: {done.stderr.strip()[:300]}")


def block_process(lines, text, spans, raw_path, data, out_dir, keep, take, seed, work):
	"""Bloğun yanıtı → satırların sesi, sözcük zamanı ve alanları. Hepsi önce geçici klasörde üretilir: bir sınır kesilemezse
	eski çekimler yerinde kalır."""
	with open(raw_path, encoding="utf-8") as f:
		response = json.load(f)
	audio = base64.b64decode(response["audio_base64"])
	if not looks_like_mp3(audio):
		raise ValueError("yanıtta MP3 yok")
	alignment = response.get("alignment")
	where = align_spans(alignment, text, spans)
	if where is None:
		alignment = response.get("normalized_alignment")
		where = align_spans(alignment, text, spans)
	if where is None:
		raise ValueError("yanıtın sözcük zamanları metinle aynı değil")
	staged = os.path.join(work, "block.mp3")
	write_bytes(staged, audio)
	wav_path = os.path.join(work, "block.wav")
	done = subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", staged, "-ac", "1", "-ar", "44100", "-c:a", "pcm_s16le",
		wav_path], capture_output=True, text=True)
	if done.returncode != 0:
		raise ValueError(f"ffmpeg açamadı: {done.stderr.strip()[:300]}")
	gain = measure_gain(wav_path)
	print(f"Blok kazancı: {gain:+.2f} dB ({BLOCK_LUFS} LUFS).")
	levels, step = read_levels(wav_path)
	cuts = block_cuts(lines, where, alignment, levels, step)
	runs = quiet_runs(levels, step, BLOCK_QUIET_DB[0])
	parts = []
	for line, span, (t0, t1, pause, speech_end) in zip(lines, where, cuts):
		part_path = os.path.join(work, line["id"] + ".mp3")
		before_cut = levels[min(len(levels) - 1, max(0, int(t1 / step) - 1))]
		# Model sözün sönüşünü kesmişse (blok bitmiştir) kesik duyulmasın: yumuşatma uzar, araç söyler.
		fade_out = BLOCK_FADE_OUT if before_cut <= BLOCK_CUT_WARN_DB else BLOCK_FADE_LONG
		encode_part(wav_path, t0, t1, fade_out, gain, part_path)
		seconds = round(probe_seconds(part_path), 3)
		words = block_words(alignment, span, runs, t0, speech_end, seconds)
		if [norm(w["w"]) for w in words] != [norm(t) for t in tokens(line["text"]["en"])]:
			raise ValueError(f"{line['id']}: sözcük zamanlarının sözcükleri metinle aynı değil")
		parts.append((line, part_path, words, seconds, t0, t1, pause, before_cut))
	whole = os.path.join(keep, f"{lines[0]['id']}..{lines[-1]['id']}.take{take}.mp3")
	write_bytes(whole, audio)
	for line, part_path, words, seconds, t0, t1, pause, before_cut in parts:
		mp3_path, timing_path = target_paths(data, line, out_dir)
		with open(part_path, "rb") as f:
			write_bytes(mp3_path, f.read())
		digest = take_hash(line)
		write_text(timing_path, dump_timing({"id": line["id"], "take": take, "seed": seed, "hash": digest,
			"model": line["model"], "voice": line["voice"], "seconds": seconds,
			"block": {"id": block_id(lines), "t0": round(t0, 3), "t1": round(t1, 3)}, "words": words}))
		line["file"] = fs_to_res(mp3_path)
		line["timing"] = fs_to_res(timing_path)
		line["seconds"] = seconds
		line["take"] = take
		line["take_hash"] = digest
		note = (f"; UYARI: kesimden önce {before_cut:.0f} dB, sönüş {BLOCK_FADE_LONG} sn'de yumuşatıldı, dinleyin"
			if before_cut > BLOCK_CUT_WARN_DB else "")
		print(f"{line['id']}: {t0:.3f}–{t1:.3f} sn, {seconds:.3f} sn, önceki sessizlik {pause:.2f} sn{note}")
	return sum(part[3] for part in parts)


def tts_block(o, data, data_path, lines, blocked, take_override, out_dir, response):
	if not lines:
		die(1, "--block: okunacak satır yok")
	first = lines[0]
	for line in lines[1:]:
		if (line.get("voice"), line.get("model"), settings_of(line)) != (first.get("voice"), first.get("model"), settings_of(first)):
			die(1, f"--block: {line['id']} başka ses, model ya da ayarda; bir blokta hepsi aynı olmalı")
	take = take_override if take_override is not None else int(first.get("take") or 0)
	text, spans = block_text(lines)
	seed = seed_of(block_hash(first, text), take)
	item = block_id(lines)
	if not response and not o.get("force") and not any(tts_state(line, take_hash(line), take, False) for line in lines):
		print(f"güncel: {item} (dosyalar bu metinden ve sesten; kredi harcanmaz)")
		return 0
	print(f"Blok: {item}: {len(lines)} satır, {len(text)} karakter, ses {first['voice']}, çekim {take}, tohum {seed}.")
	print(f"Toplam: 1 çağrı, {len(text)} karakter (≈{len(text)} kredi; eleven_v3 karakter başına 1).")
	if o.get("cost"):
		return 0
	if blocked:
		die(4, "metin kilidi tutmuyor: " + ", ".join(line["id"] for line in blocked))
	voice = urllib.parse.quote(first["voice"], safe="")
	path = f"/v1/text-to-speech/{voice}/with-timestamps?output_format={BLOCK_FORMAT}"
	body = {"text": text, "model_id": first["model"], "voice_settings": settings_of(first), "seed": seed}
	ledger = ledger_path(o)
	if o.get("dry-run"):
		gate(len(text), o, offline=True)
		show_request("POST", path, body)
		show_ledger(ledger_entry("tts", item, take, len(text), len(text), first["voice"], first["model"]))
		return 0
	for tool in ("ffmpeg", "ffprobe"):
		if not shutil.which(tool):
			die(1, f"{tool} bulunamadı: blok kesilemez, çağrı yapılmadı")
	keep = from_caller(o["keep"]) if "keep" in o else os.path.normpath(DEFAULT_BLOCK_DIR)
	os.makedirs(keep, exist_ok=True)
	raw_path = response or os.path.join(keep, f"{first['id']}..{lines[-1]['id']}.take{take}.json")
	credits = 0
	if not response:
		gate(len(text), o, offline=False)
		_, headers = request("POST", path, o, raw_path, body=body, accept="application/json")
		cost = headers.get("character-cost", "")
		credits, source = (int(cost), "header") if cost.isdigit() else (len(text), "chars")
		entry = ledger_entry("tts", item, take, credits, len(text), first["voice"], first["model"])
		entry["credits_from"] = source
		append_ledger(ledger, entry)
	work = tempfile.mkdtemp(prefix="tanhu_eleven_block_")
	try:
		total = block_process(lines, text, spans, raw_path, data, out_dir, keep, take, seed, work)
	except (ValueError, KeyError, OSError, binascii.Error, json.JSONDecodeError) as e:
		die(2, f"{item}: blok işlenemedi: {e}. Ham yanıt saklandı: {raw_path}. Yeniden çağırmadan işlemek için: "
			f"tools/elevenlabs_audio.sh --lines=<aynı satırlar> --block --response={raw_path}")
	finally:
		shutil.rmtree(work, ignore_errors=True)
	save_data(data_path, data)
	print(f"Bitti: {len(lines)} satır, satırların toplamı {total:.1f} sn, {credits} kredi; defter {ledger}; ham yanıt {raw_path}.")
	print("Godot'un yeni sesleri içe aktarması için: tools/run_tests.sh (önce --import çalışır).")
	return 0


def cmd_tts(rest):
	o, _ = options(rest, values={"lines", "only", "data", "out-dir", "take", "response", "keep"},
		flags={"force", "no-timestamps", "block"})
	spec = o.get("lines") or o.get("only")
	data_path = DEFAULT_DATA
	if isinstance(o.get("lines"), str) and o["lines"].endswith(".json"):
		# Planın yazımı: --lines=data/vo_lines.json --only='act0.myth.*'
		data_path, spec = from_caller(o["lines"]), o.get("only")
	if "data" in o:
		data_path = from_caller(o["data"])
	if not isinstance(spec, str) or not spec:
		die(1, "--lines=<kimlik ya da kalıp,...> gerekli")
	data = load_json(data_path, "satır verisi")
	chosen = select(data, spec)
	out_dir = from_caller(o["out-dir"]) if "out-dir" in o else None
	response = from_caller(o["response"]) if "response" in o else None
	take_override = as_int(o["take"], "--take") if "take" in o else None
	timestamps = not o.get("no-timestamps")

	ready = []
	for line in chosen:
		reason = tts_unready(line)
		if reason:
			print(f"atlandı: {line['id']} ({reason})")
		else:
			ready.append(line)
	acts = sorted({int(line["act"]) for line in ready if line.get("tier") in LOCKED_TIERS})
	locks = {act: lock_problem(data, act) for act in acts}
	blocked = [line for line in ready if line.get("tier") in LOCKED_TIERS and locks[int(line["act"])]]
	if o.get("block"):
		return tts_block(o, data, data_path, ready, blocked, take_override, out_dir, response)
	if take_override is not None and len(ready) > 1:
		print(f"Uyarı: --take={take_override} seçilen {len(ready)} satırın hepsine uygulanır.")

	jobs = []
	for line in ready:
		take = take_override if take_override is not None else int(line.get("take") or 0)
		digest = take_hash(line)
		reason = "--response" if response else tts_state(line, digest, take, o.get("force"))
		if reason is None:
			print(f"güncel: {line['id']} (dosyası bu metinden ve sesten; kredi harcanmaz)")
			continue
		jobs.append({"line": line, "take": take, "hash": digest, "seed": seed_of(digest, take), "reason": reason})

	chars = sum(len(job["line"]["text"]["en"]) for job in jobs)
	by_speaker = {}
	for job in jobs:
		who = job["line"].get("speaker", "?")
		by_speaker[who] = by_speaker.get(who, 0) + len(job["line"]["text"]["en"])
	for job in jobs:
		line = job["line"]
		pending_note = "; ses seçimi bekliyor, geçici ses" if line.get("voice_pending") else ""
		print(f"satır: {line['id']} ({len(line['text']['en'])} karakter, {line.get('speaker')}, ses {line['voice']}"
			f"{pending_note}, çekim {job['take']}, tohum {job['seed']}; neden: {job['reason']})")
	if by_speaker:
		print("Konuşmacı başına: " + ", ".join(f"{who} {n}" for who, n in by_speaker.items()))
	print(f"Toplam: {len(jobs)} satır, {chars} karakter (≈{chars} kredi; eleven_v3 karakter başına 1).")
	for act, problem in locks.items():
		if problem:
			print(f"Kilit: {problem}: A/B satırı üretilmez (K61); kilidi ana oturum kullanıcının onayıyla yazar.")
	if o.get("cost"):
		return 0
	if blocked:
		die(4, "metin kilidi tutmuyor: " + ", ".join(line["id"] for line in blocked))
	if not jobs:
		print("Üretilecek satır yok.")
		return 0
	if response and len(jobs) != 1:
		die(1, "--response tek satırla verilir (--lines=<kimlik>)")

	ledger = ledger_path(o)
	if o.get("dry-run"):
		gate(chars, o, offline=True)
		for job in jobs:
			line = job["line"]
			print(f"--- {line['id']}")
			show_request("POST", tts_path(line, timestamps), tts_body(line, job["seed"]))
			show_ledger(ledger_entry("tts", line["id"], job["take"], len(line["text"]["en"]), len(line["text"]["en"]),
				line["voice"], line["model"]))
		return 0

	if not shutil.which("ffprobe"):
		die(1, "ffprobe bulunamadı: süre ölçülemez, çağrı yapılmadı")
	if not response:
		gate(chars, o, offline=False)
	work = tempfile.mkdtemp(prefix="tanhu_eleven_")
	spent = 0
	for index, job in enumerate(jobs, 1):
		line = job["line"]
		mp3_path, timing_path = target_paths(data, line, out_dir)
		if response:
			raw_path = response
		else:
			raw_path = os.path.join(work, f"{line['id']}.response")
			_, headers = request("POST", tts_path(line, timestamps), o, raw_path, body=tts_body(line, job["seed"]),
				accept="application/json" if timestamps else "audio/mpeg")
			cost = headers.get("character-cost", "")
			credits, source = (int(cost), "header") if cost.isdigit() else (len(line["text"]["en"]), "chars")
			entry = ledger_entry("tts", line["id"], job["take"], credits, len(line["text"]["en"]), line["voice"], line["model"])
			entry["credits_from"] = source
			append_ledger(ledger, entry)
			spent += credits
		try:
			seconds, count = tts_process(job, raw_path, mp3_path, timing_path, work)
		except (ValueError, KeyError, OSError, binascii.Error, json.JSONDecodeError) as e:
			die(2, f"{line['id']}: yanıt işlenemedi: {e}. Ham yanıt saklandı: {raw_path}. Yeniden çağırmadan işlemek için: "
				f"tools/elevenlabs_audio.sh --lines={line['id']} --response={raw_path}")
		save_data(data_path, data)
		print(f"[{index}/{len(jobs)}] {line['id']}: {seconds:.3f} sn, {count} sözcük → {line['file']}")
	shutil.rmtree(work, ignore_errors=True)
	print(f"Bitti: {len(jobs)} satır, {spent} kredi; defter {ledger}.")
	print("Godot'un yeni sesleri içe aktarması için: tools/run_tests.sh (önce --import çalışır).")
	return 0


# --- music ----------------------------------------------------------------------------

def split_music(raw, content_type):
	"""/v1/music/detailed yanıtı (multipart/mixed: JSON ve ses) → (ses, üstveri)."""
	if "multipart" not in content_type.lower():
		if looks_like_mp3(raw):
			return raw, {}
		raise ValueError("yanıt ne multipart ne MP3")
	match = re.search(r'boundary=("?)([^";]+)\1', content_type)
	if not match:
		raise ValueError("multipart sınırı yok")
	sep = b"--" + match.group(2).encode("latin-1")
	parts = []
	at = raw.find(sep)
	while at >= 0:
		nxt = raw.find(sep, at + len(sep))
		if nxt < 0:
			break
		part = raw[at + len(sep):nxt]
		split = part.find(b"\r\n\r\n")
		if split >= 0:
			body = part[split + 4:]
			if body.endswith(b"\r\n"):
				body = body[:-2]
			parts.append((part[:split].decode("utf-8", "replace"), body))
		at = nxt
	meta = next((b for h, b in parts if re.search(r"application/json", h, re.I)), None)
	audio = next((b for h, b in parts if re.search(r"audio/", h, re.I)), None)
	if meta is None or audio is None:
		raise ValueError("multipart yanıtında JSON ya da ses parçası yok")
	return audio, json.loads(meta.decode("utf-8"))


def cmd_music(rest):
	o, _ = options(rest, values={"plan", "out", "id", "seed", "take"})
	plan_file = from_caller(need(o, "plan"))
	out = from_caller(need(o, "out"))
	raw = load_json(plan_file, "plan")
	plan = raw.get("composition_plan", raw) if isinstance(raw, dict) else None
	if not isinstance(plan, dict) or not isinstance(plan.get("chunks"), list) or not plan["chunks"]:
		die(1, "plan composition_plan biçiminde değil (chunks listesi gerekli)")
	if "seed" in o:
		seed = as_int(o["seed"], "--seed")
	else:
		seed = raw.get("seed") if isinstance(raw.get("seed"), int) else None
	take = as_int(o["take"], "--take") if "take" in o else (seed if seed is not None else 0)
	item_id = o.get("id") or os.path.splitext(os.path.basename(out))[0]
	ms = sum(int(chunk.get("duration_ms", 0)) for chunk in plan["chunks"])
	cost = math.ceil(ms / 60000 * MUSIC_CREDITS_PER_MINUTE)
	body = {"composition_plan": plan, "model_id": MUSIC_MODEL, "with_timestamps": True}
	if seed is not None:
		body["seed"] = seed
	path = f"/v1/music/detailed?output_format={MUSIC_FORMAT}"
	print(f"Şarkı: {item_id}, plan {ms / 1000:.1f} sn, ≈{cost} kredi ({MUSIC_MODEL}, {MUSIC_FORMAT}, tohum {seed}).")
	if o.get("cost"):
		return 0
	entry = ledger_entry("music", item_id, take, cost, 0, None, MUSIC_MODEL)
	if o.get("dry-run"):
		gate(cost, o, offline=True)
		show_request("POST", path, body)
		show_ledger(entry)
		return 0
	if not shutil.which("ffprobe"):
		die(1, "ffprobe bulunamadı: süre ölçülemez, çağrı yapılmadı")
	before = gate(cost, o, offline=False) or subscription(o)
	work = tempfile.mkdtemp(prefix="tanhu_eleven_")
	raw_path = os.path.join(work, "music.response")
	_, headers = request("POST", path, o, raw_path, body=body)
	after = subscription(o)
	entry["credits"] = max(0, after["used"] - before["used"])
	entry["credits_from"] = "subscription"
	append_ledger(ledger_path(o), entry)
	try:
		with open(raw_path, "rb") as f:
			audio, meta = split_music(f.read(), headers.get("content-type", ""))
		write_bytes(out, audio)
		record = {"id": item_id, "take": take, "seed": seed, "model": MUSIC_MODEL, "song_id": headers.get("song-id"),
			"seconds": round(probe_seconds(out), 3), **meta, "composition_plan": plan}
	except (ValueError, OSError, json.JSONDecodeError) as e:
		die(2, f"şarkı yanıtı işlenemedi: {e}; ham yanıt saklandı: {raw_path}")
	write_text(os.path.splitext(out)[0] + ".json", json.dumps(record, ensure_ascii=False, indent=1) + "\n")
	shutil.rmtree(work, ignore_errors=True)
	print(f"Kaydedildi: {out} ({record['seconds']:.2f} sn, {entry['credits']} kredi) ve sözcük zamanı "
		f"{os.path.splitext(out)[0]}.json")
	return 0


# --- sfx ------------------------------------------------------------------------------

def cmd_sfx(rest):
	o, pos = options(rest, values={"id"}, flags={"wav"}, positional=4)
	out_arg, seconds_arg, loop_arg, prompt = pos
	try:
		seconds = float(seconds_arg)
	except ValueError:
		die(1, f"süre saniye olmalı: {seconds_arg}")
	if not 0.5 <= seconds <= 30:
		die(1, "süre 0,5–30 sn olmalı")
	if loop_arg not in ("true", "false"):
		die(1, "loop true ya da false olmalı")
	out = from_caller(out_arg)
	if o.get("wav"):
		out = os.path.splitext(out)[0] + ".wav"
	item_id = o.get("id") or os.path.splitext(os.path.basename(out))[0]
	body = {"text": prompt, "duration_seconds": seconds, "prompt_influence": 0.45, "loop": loop_arg == "true",
		"model_id": SFX_MODEL}
	path = f"/v1/sound-generation?output_format={SFX_FORMAT}"
	cost = math.ceil(seconds * SFX_CREDITS_PER_SECOND)
	print(f"Efekt: {item_id}, {seconds:g} sn, ≈{cost} kredi ({SFX_MODEL}).")
	if o.get("cost"):
		return 0
	entry = ledger_entry("sfx", item_id, 0, cost, len(prompt), None, SFX_MODEL)
	if o.get("dry-run"):
		gate(cost, o, offline=True)
		show_request("POST", path, body)
		show_ledger(entry)
		return 0
	if o.get("wav") and not shutil.which("ffmpeg"):
		die(1, "ffmpeg bulunamadı: --wav çevrilemez, çağrı yapılmadı")
	before = gate(cost, o, offline=False) or subscription(o)
	work = tempfile.mkdtemp(prefix="tanhu_eleven_")
	raw_path = os.path.join(work, "sfx.mp3")
	request("POST", path, o, raw_path, body=body, accept="audio/mpeg")
	after = subscription(o)
	entry["credits"] = max(0, after["used"] - before["used"])
	entry["credits_from"] = "subscription"
	append_ledger(ledger_path(o), entry)
	if o.get("wav"):
		os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
		done = subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", raw_path, "-ac", "1", "-ar", "22050",
			"-c:a", "pcm_s16le", out], capture_output=True, text=True)
		if done.returncode != 0:
			die(2, f"ffmpeg WAV'a çeviremedi: {done.stderr.strip()[:300]}; MP3 saklandı: {raw_path}")
	else:
		with open(raw_path, "rb") as f:
			write_bytes(out, f.read())
	shutil.rmtree(work, ignore_errors=True)
	print(f"Kaydedildi: {out} ({os.path.getsize(out)} bayt, {entry['credits']} kredi)")
	return 0


# --- stt ------------------------------------------------------------------------------

def cmd_stt(rest):
	o, _ = options(rest, values={"lines", "data"}, flags={"write-timing"})
	data_path = from_caller(o["data"]) if "data" in o else DEFAULT_DATA
	data = load_json(data_path, "satır verisi")
	todo = []
	for line in select(data, need(o, "lines")):
		path = line.get("file")
		if line.get("kind") == "sub" or not isinstance(path, str) or not os.path.exists(res_to_fs(path)):
			print(f"atlandı: {line['id']} (ses dosyası yok)")
		else:
			todo.append(line)
	seconds = sum(float(line.get("seconds") or 0) for line in todo)
	cost = math.ceil(seconds / 60 * STT_CREDITS_PER_MINUTE)
	print(f"Yazıya çevirme ({STT_MODEL}): {len(todo)} dosya, {seconds:.1f} sn, ≈{cost} kredi (tahmin).")
	if o.get("cost") or not todo:
		return 0
	if o.get("dry-run"):
		gate(cost, o, offline=True)
		for line in todo:
			print(f"--- {line['id']}")
			print(f"istek: POST {api_base()}/v1/speech-to-text (multipart: file={line['file']}, model_id={STT_MODEL}, "
				"language_code=en, timestamps_granularity=word)")
			show_ledger(ledger_entry("stt", line["id"], int(line.get("take") or 0),
				math.ceil(float(line.get("seconds") or 0) / 60 * STT_CREDITS_PER_MINUTE), 0, None, STT_MODEL))
		return 0
	before = gate(cost, o, offline=False) or subscription(o)
	ledger = ledger_path(o)
	work = tempfile.mkdtemp(prefix="tanhu_eleven_")
	mismatches = 0
	for line in todo:
		out = os.path.join(work, line["id"] + ".stt.json")
		request("POST", "/v1/speech-to-text", o, out, form=[("file", "@" + res_to_fs(line["file"])),
			("model_id", STT_MODEL), ("language_code", "en"), ("timestamps_granularity", "word"),
			("tag_audio_events", "false")])
		after = subscription(o)
		entry = ledger_entry("stt", line["id"], int(line.get("take") or 0), max(0, after["used"] - before["used"]),
			0, None, STT_MODEL)
		entry["credits_from"] = "subscription"
		append_ledger(ledger, entry)
		before = after
		result = load_json(out, "stt yanıtı")
		heard = [w for w in result.get("words", []) if w.get("type", "word") == "word"]
		expect = [norm(t) for t in tokens(line["text"]["en"])]
		got = [norm(str(w.get("text", ""))) for w in heard]
		same = sum(1 for a, b in zip(expect, got) if a == b)
		if got == expect:
			print(f"{line['id']}: metinle aynı ({len(got)} sözcük)")
		else:
			mismatches += 1
			print(f"{line['id']}: FARK ({same}/{len(expect)} sözcük aynı yerde): duyulan «{result.get('text', '')}»")
		# Sözcük zamanı yalnız duyulan metin satırın metniyle birebir aynıysa yazılır (eski kayda yeni metin oturmaz).
		if o.get("write-timing") and not isinstance(line.get("timing"), str) and got == expect:
			words = [{"w": t, "t0": round(float(w.get("start", 0)), 3), "t1": round(float(w.get("end", 0)), 3)}
				for t, w in zip(tokens(line["text"]["en"]), heard)]
			timing_path = os.path.splitext(res_to_fs(line["file"]))[0] + ".json"
			write_text(timing_path, dump_timing({"id": line["id"], "take": int(line.get("take") or 0),
				"hash": line.get("take_hash"), "model": line.get("model"), "voice": line.get("voice"),
				"seconds": line.get("seconds"), "source": STT_MODEL, "words": words}))
			line["timing"] = fs_to_res(timing_path)
			save_data(data_path, data)
			print(f"{line['id']}: sözcük zamanı Scribe'dan yazıldı → {line['timing']}")
	shutil.rmtree(work, ignore_errors=True)
	print(f"Bitti: {len(todo)} dosya, {mismatches} farklı.")
	return 1 if mismatches else 0


# --- quota ----------------------------------------------------------------------------

def cmd_quota(rest):
	o, _ = options(rest)
	sub = subscription(o)
	print(f"Plan {sub['tier']}: {sub['used']} / {sub['limit']} kredi kullanıldı, kalan {sub['remaining']}.")
	return 0


def main():
	command, rest = ("tts", ARGS) if ARGS[0].startswith("--") else (ARGS[0], ARGS[1:])
	handlers = {"tts": cmd_tts, "music": cmd_music, "sfx": cmd_sfx, "stt": cmd_stt, "quota": cmd_quota}
	if command not in handlers:
		die(1, f"bilinmeyen komut: {command} (tts, music, sfx, stt, quota)")
	return handlers[command](rest)


try:
	sys.exit(main())
except Fail as failure:
	sys.stdout.flush()
	print(f"HATA: {failure.message}", file=sys.stderr)
	sys.exit(failure.code)
PY
