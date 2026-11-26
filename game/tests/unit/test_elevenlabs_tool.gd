extends TestCase
## ElevenLabs aracının (tools/elevenlabs_audio.sh) sınamaları (K61, K28; audio.md §5): uçlar ve biçimler,
## ağsız bedel (--cost) ve kuru koşu (--dry-run), metin kilidi, kota kapısı, anahtarın yazdırılmaması ve
## yerel sahte sunucuyla uçtan uca üretim (tts, music, sfx, stt).
##
## Gerçek ElevenLabs'e hiçbir istek gitmez, kredi harcanmaz: her koşuda anahtar boştur ya da sahtedir,
## .env okunmaz (ELEVENLABS_ENV_FILE yok bir dosyadır) ve API kökü yerel bir adrestir (araç kökü yalnız
## 127.0.0.1'e çevirmeye izin verir). Veri, defter ve çıktılar geçici klasördedir; oyunun verisi ve defteri
## değişmez. Satırlar üretilmiş olsa da sınama aynı kalır: fikstür satırların dosyalarını siler.

const TempDir := preload("res://tests/support/temp_dir.gd")
const TOOL := "res://tools/elevenlabs_audio.sh"
const DATA := "res://data/vo_lines.json"
const LEDGER := "res://tools/vo_ledger.jsonl"
## Sahte anahtar: hiçbir çıktıda ve dosyada görünmemeli.
const FAKE_KEY := "sinama-anahtari-7f3a91"
## Varsayılan API kökü: kapalı yerel kapı; bir sınama yanlışlıkla ağa çıkmak isterse yerelde düşer.
const DEAD_BASE := "http://127.0.0.1:9"
## Sahte sunucunun döndürdüğü ses (yeniden kodlanmadan kopyalanmış bir köprü kaydı) ve süresi.
const SOURCE_MP3 := "res://audio/vo/prologue/act0.narr.7.mp3"
const SOURCE_SECONDS := 6.4
const ELDRIN := "LvmvHEBEmMJBJw9UuhwO"
## Ozanın konuşma sesi: mit satırlarını o okur (K35, K61).
const DAVID := "BNgbHR0DNeZixGQVzloa"
## Hereka'nın Önsöz satırının sesi (39 yaşı; K95): araç satırın voice'unu okur, speakers tablosunu değil.
const HEATHER := "49d0YOOn2K0LVSBCkZ0q"
const LEDGER_KEYS: Array[String] = ["at", "product", "id", "take", "credits", "chars", "voice", "model"]
const N1_TEXT := "Before there were empires of grass, there was only the wind, and those who could outlast it."

## Sahte ElevenLabs sunucusu: abonelik, with-timestamps ve düz tts, müzik (multipart), efekt ve stt uçları.
## Her isteği (yol, xi-api-key başlığı, gövde) günlüğe yazar; ücretli çağrı aboneliğin kullanımını artırır.
## Bağımsız değişkenler: kapı dosyası, günlük, MP3, kalan kredi, stt metni, MP3'ün süresi. 90 sn sonra kapanır.
const MOCK_SERVER := r"""
import base64, http.server, json, os, sys, threading, time

port_file, log_file, mp3_path, remaining, stt_text, seconds = sys.argv[1:7]
audio = open(mp3_path, "rb").read()
state = {"used": 1000}
LIMIT = 1000 + int(remaining)


class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *args):
        pass

    def _log(self, body):
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(json.dumps({"method": self.command, "path": self.path, "key": self.headers.get("xi-api-key"),
                "body": body}, ensure_ascii=False) + "\n")

    def _send(self, status, payload, content_type, extra=None):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(payload)))
        for name, value in (extra or {}).items():
            self.send_header(name, value)
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        self._log(None)
        if self.path == "/v1/user/subscription":
            info = {"tier": "sinama", "character_count": state["used"], "character_limit": LIMIT}
            self._send(200, json.dumps(info).encode(), "application/json")
        else:
            self._send(404, b'{"detail": "yok"}', "application/json")

    def do_POST(self):
        raw = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        kind = self.headers.get("Content-Type", "")
        body = json.loads(raw.decode("utf-8")) if "json" in kind else {"bytes": len(raw), "scribe": b"scribe_v2" in raw}
        self._log(body)
        path = self.path.split("?")[0]
        if self.headers.get("xi-api-key") is None:
            self._send(401, b'{"detail": "anahtar yok"}', "application/json")
        elif path.startswith("/v1/text-to-speech/"):
            if path.split("/")[3] == "HATA401":
                self._send(401, b'{"detail": {"status": "invalid_api_key"}}', "application/json")
                return
            text = body["text"]
            state["used"] += len(text)
            cost = {"character-cost": str(len(text))}
            if path.endswith("/with-timestamps"):
                step = float(seconds) / max(1, len(text))
                al = {"characters": list(text),
                    "character_start_times_seconds": [round(i * step, 3) for i in range(len(text))],
                    "character_end_times_seconds": [round((i + 1) * step, 3) for i in range(len(text))]}
                payload = {"audio_base64": base64.b64encode(audio).decode(), "alignment": al, "normalized_alignment": al}
                self._send(200, json.dumps(payload).encode(), "application/json", cost)
            else:
                self._send(200, audio, "audio/mpeg", cost)
        elif path == "/v1/music/detailed":
            state["used"] += 405
            sep = b"--sinirSINIR123"
            meta = json.dumps({"song_metadata": {"title": None},
                "words_timestamps": [{"word": "One", "start_ms": 4716, "end_ms": 5116}]}).encode()
            parts = (sep + b"\r\nContent-Type: application/json\r\n\r\n" + meta + b"\r\n"
                + sep + b"\r\nContent-Type: audio/mpeg\r\n\r\n" + audio + b"\r\n" + sep + b"--\r\n")
            self._send(200, parts, "multipart/mixed; boundary=sinirSINIR123", {"song-id": "sinamaSarki"})
        elif path == "/v1/sound-generation":
            state["used"] += 160
            self._send(200, audio, "audio/mpeg")
        elif path == "/v1/speech-to-text":
            state["used"] += 30
            words, t = [], 0.0
            for word in stt_text.split():
                words.append({"text": word, "type": "word", "start": round(t, 3), "end": round(t + 0.3, 3)})
                words.append({"text": " ", "type": "spacing", "start": round(t + 0.3, 3), "end": round(t + 0.35, 3)})
                t += 0.4
            self._send(200, json.dumps({"text": stt_text, "words": words}).encode(), "application/json")
        else:
            self._send(404, b'{"detail": "yok"}', "application/json")


server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
threading.Thread(target=lambda: (time.sleep(90), os._exit(0)), daemon=True).start()
with open(port_file + ".part", "w") as f:
    f.write(str(server.server_address[1]))
os.replace(port_file + ".part", port_file)
server.serve_forever()
"""

var _tmp := ""
var _server_pid := -1
var _port := 0


func before_each() -> void:
	_tmp = TempDir.fresh("eleven_tool")
	VoLines.clear_cache()


func after_each() -> void:
	_stop_server()
	TempDir.wipe(_tmp)
	VoLines.clear_cache()


# --- Betiğin metni -----------------------------------------------------------------------------

func test_script_names_the_new_endpoints_and_formats() -> void:
	var text := FileAccess.get_file_as_string(TOOL)
	for needle in ["mp3_44100_64", "with-timestamps", "eleven_v3", "music_v2_5", "/v1/music/detailed",
			"mp3_44100_128", "eleven_text_to_sound_v2", "scribe_v2", "/v1/user/subscription", "character-cost",
			"vo_ledger.jsonl", "--over", "--dry-run"]:
		assert_true(text.contains(needle), "Araç «%s» bilmeli" % needle)
	assert_false(text.contains("music_v1"), "Eski müzik modeli kalktı (K61: 31 Ocak 2027)")


func test_key_is_never_printed_or_put_on_the_command_line() -> void:
	# Anahtar yazdırılmaz (K28, K61): yazdıran hiçbir satır anahtarı ya da onu tutan değişkeni anmaz;
	# curl başlığı standart girdiden okur (-H @-), anahtar süreç listesinde görünmez.
	var text := FileAccess.get_file_as_string(TOOL)
	var number := 0
	for row in text.split("\n"):
		number += 1
		var line := row.strip_edges()
		if line.begins_with("#"):
			continue
		var prints := line.contains("echo") or line.contains("printf") or line.contains("print(") \
				or line.contains(".write(")
		if prints:
			for secret in ["$ELEVENLABS_API_KEY", "{ELEVENLABS_API_KEY}", "_secret", "{key}", "read_key("]:
				assert_false(line.contains(secret), "%d. satır anahtarı yazdırabilir: %s" % [number, line])
	assert_true(text.contains("\"-H\", \"@-\""), "Anahtar başlığı curl'e standart girdiden gitmeli")
	assert_false(text.contains("xi-api-key: ${"), "Anahtar komut satırına girmemeli")


# --- Ağsız: bedel, kuru koşu, kilit, kota --------------------------------------------------------

func test_cost_of_myth_and_birth_lines_is_1465() -> void:
	# act0-text.md «Bedel»: mit (3–25) ve doğum satırları 1.465 karakter; Hereka'yla 1.474.
	var data := _fixture()
	var run := _run(["--lines=act0.myth.*,act0.birth.12", "--cost", "--data=" + data])
	assert_eq(run["code"], 0, run["out"])
	assert_true(str(run["out"]).contains("Toplam: 24 satır, 1465 karakter"), run["out"])
	run = _run(["tts", "--lines=act0.myth.*,act0.birth.12,act0.birth.hereka", "--cost", "--data=" + data])
	assert_true(str(run["out"]).contains("Toplam: 25 satır, 1474 karakter"), "Mit, doğum ve Hereka. %s" % run["out"])
	assert_false(str(run["out"]).contains("ses seçimi bekliyor"), "Hereka'nın sesi seçildi (K95)")
	# Sesi seçilmemiş kişinin satırı geçici sesle okunur ve araç bunu söyler.
	var pending := _fixture(true, [], func(d: Dictionary) -> void: _line_of(d, "act0.birth.hereka")["voice_pending"] = true)
	run = _run(["--lines=act0.birth.hereka", "--cost", "--data=" + pending])
	assert_true(str(run["out"]).contains("ses seçimi bekliyor"), "Geçici ses söylenmeli. %s" % run["out"])
	# Planın yazımı: --lines=<veri> --only=<kalıp>.
	run = _run(["tts", "--lines=" + data, "--only=act0.myth.*,act0.birth.12", "--cost"])
	assert_true(str(run["out"]).contains("1465 karakter"), run["out"])
	# Önsöz'ün bütün bekleyen satırları (köprüler dahil): 1.833 karakter (act0-text.md). Oynanan sahnelerin satırları (E20/7) ayrı sayılır.
	run = _run(["--lines=act0.bard.*,act0.myth.*,act0.birth.*,act0.narr.*", "--cost",
		"--data=" + _fixture(true, ["act0.narr.1", "act0.narr.4", "act0.narr.5", "act0.narr.7"])])
	assert_true(str(run["out"]).contains("1833 karakter"), "Değişmeyen dört köprü yeniden çekilmez. %s" % run["out"])
	# Çocukluk, Yola Çıkış ve Serbest Gez'in sözleri (E20/7; Eskam'ın atlı sözüyle; E21'in sayım günü sözüyle): 69 satır, 1.788 karakter.
	run = _run(["--lines=act0.child.*,act0.depart.*,act0.camp.*", "--cost", "--data=" + _fixture(true)])
	assert_true(str(run["out"]).contains("Toplam: 69 satır, 1788 karakter"), "Oynanan sahnelerin sözleri. %s" % run["out"])
	# E21 (K110): Önsöz'ün üç günü ve Çocukluk'un iki yeni günü: 164 satır, 7.144 karakter.
	run = _run(["--lines=act0.milk.*,act0.storm.*,act0.lambs.*,act0.feast.*,act0.wrestle.*,act0.hearth.*,act0.flock.*,act0.bone.*,act0.tally.*",
		"--cost", "--data=" + _fixture(true)])
	assert_true(str(run["out"]).contains("Toplam: 164 satır, 7144 karakter"), "E21'in sözleri. %s" % run["out"])


func test_dry_run_prints_request_and_ledger_without_network() -> void:
	var data := _fixture()
	var ledger := _tmp.path_join("defter.jsonl")
	var real_ledger := FileAccess.get_file_as_string(LEDGER)
	var run := _run(["tts", "--dry-run", "--data=" + data, "--ledger=" + ledger, "--lines=act0.myth.9,act0.birth.hereka"])
	assert_eq(run["code"], 0, run["out"])
	var urls := _after(run["out"], "istek: ")
	assert_eq(urls.size(), 2, run["out"])
	if urls.size() == 2:
		assert_true(urls[0].ends_with("/v1/text-to-speech/%s/with-timestamps?output_format=mp3_44100_64" % DAVID), urls[0])
		assert_true(urls[1].ends_with("/v1/text-to-speech/%s/with-timestamps?output_format=mp3_44100_64" % HEATHER), urls[1])
	var bodies := _json_after(run["out"], "gövde: ")
	var ids := ["act0.myth.9", "act0.birth.hereka"]
	assert_eq(bodies.size(), 2, run["out"])
	for i in bodies.size():
		var body: Dictionary = bodies[i]
		assert_eq(str(body.get("model_id", "")), "eleven_v3")
		assert_almost(float(body["voice_settings"]["stability"]), 0.5, 0.0001, "Kararlılık 0,5 (K17)")
		assert_eq(str(body.get("text", "")), VoLines.subtitle(ids[i], "en"), "Söylenen metin vo_lines.json'dan")
		assert_eq(int(body.get("seed", -1)), _seed_of(ids[i]), "Tohum satırın karmasından")
	var entries := _json_after(run["out"], "defter: ")
	assert_eq(entries.size(), 2, run["out"])
	for i in entries.size():
		var entry: Dictionary = entries[i]
		for key in LEDGER_KEYS:
			assert_true(entry.has(key), "Defter satırında %s yok: %s" % [key, entry])
		assert_eq(str(entry.get("product", "")), "tts")
		assert_eq(str(entry.get("id", "")), ids[i])
		assert_eq(int(entry.get("chars", 0)), VoLines.chars(ids[i]))
		assert_eq(entry.get("dry_run"), true)
	assert_false(FileAccess.file_exists(ledger), "Kuru koşu deftere yazmaz")
	assert_eq(FileAccess.get_file_as_string(LEDGER), real_ledger, "Oyunun defteri değişmez")


func test_music_sfx_and_stt_dry_runs() -> void:
	var plan := _write_plan()
	var run := _run(["music", "--dry-run", "--plan=" + plan, "--out=" + _tmp.path_join("sarki.mp3"), "--seed=3106"])
	assert_eq(run["code"], 0, run["out"])
	var body: Dictionary = _first(_json_after(run["out"], "gövde: "))
	assert_eq(str(body.get("model_id", "")), "music_v2_5", "Müzik ucu music_v2_5 (K61)")
	assert_eq(body.get("with_timestamps"), true)
	assert_eq(int(body.get("seed", 0)), 3106)
	assert_true(body.get("composition_plan") is Dictionary)
	assert_true(_first_string(_after(run["out"], "istek: ")).ends_with("/v1/music/detailed?output_format=mp3_44100_128"), run["out"])
	assert_true(str(run["out"]).contains("≈416 kredi"), "27,7 sn × 900 kredi/dk. %s" % run["out"])
	var entry: Dictionary = _first(_json_after(run["out"], "defter: "))
	assert_eq(str(entry.get("product", "")), "music")
	run = _run(["sfx", _tmp.path_join("aglama.mp3"), "4", "false", "Newborn first cry", "--wav", "--dry-run"])
	assert_eq(run["code"], 0, run["out"])
	body = _first(_json_after(run["out"], "gövde: "))
	assert_eq(str(body.get("model_id", "")), "eleven_text_to_sound_v2")
	assert_almost(float(body.get("duration_seconds", 0.0)), 4.0, 0.0001)
	assert_eq(str((_first(_json_after(run["out"], "defter: ")) as Dictionary).get("product", "")), "sfx")
	run = _run(["stt", "--dry-run", "--lines=act0.narr.1"])
	assert_eq(run["code"], 0, run["out"])
	assert_true(str(run["out"]).contains("/v1/speech-to-text"), run["out"])
	assert_true(str(run["out"]).contains("scribe_v2"), run["out"])


func test_unlocked_or_changed_text_is_refused() -> void:
	# K61: metin kilidi olmadan A ve B üretilmez; kilitten sonra değişen metin de üretilmez.
	var unlocked := _fixture(true, [], func(d: Dictionary) -> void: (d["locks"] as Dictionary).erase("0"))
	var run := _run(["--dry-run", "--data=" + unlocked, "--lines=act0.myth.3"])
	assert_eq(run["code"], 4, "Kilitsiz metin: çıkış 4. %s" % run["out"])
	assert_true(str(run["out"]).contains("kilitli değil"), run["out"])
	var changed := _fixture(true, [], func(d: Dictionary) -> void: _line_of(d, "act0.myth.4")["text"]["en"] = "Kishi wanted to fly higher.")
	run = _run(["--dry-run", "--data=" + changed, "--lines=act0.myth.4"])
	assert_eq(run["code"], 4, "Kilidi tutmayan metin: çıkış 4. %s" % run["out"])
	assert_true(str(run["out"]).contains("kilitten sonra değişti"), run["out"])
	# Bedel kilitsiz metinde de okunur (kullanıcıya sormak için), ama kilidi söyler.
	run = _run(["--cost", "--data=" + changed, "--lines=act0.myth.4"])
	assert_eq(run["code"], 0, run["out"])
	assert_true(str(run["out"]).contains("Kilit:"), run["out"])


func test_quota_gate_stops_without_over() -> void:
	var data := _fixture()
	var run := _run(["--dry-run", "--remaining=100", "--data=" + data, "--lines=act0.myth.*"])
	assert_eq(run["code"], 3, "Plan (841) kalandan (100) büyük: çıkış 3. %s" % run["out"])
	assert_true(str(run["out"]).contains("--over"), "Araç --over istemeli. %s" % run["out"])
	run = _run(["--dry-run", "--remaining=100", "--over", "--data=" + data, "--lines=act0.myth.*"])
	assert_eq(run["code"], 0, "--over kapıyı geçer. %s" % run["out"])
	run = _run(["--dry-run", "--remaining=5000", "--data=" + data, "--lines=act0.myth.*"])
	assert_eq(run["code"], 0, run["out"])


func test_unknown_option_and_unmatched_line_are_refused() -> void:
	# Yanlış yazılmış bir --dry-run gerçek çağrıya dönmemeli.
	var run := _run(["--lines=act0.myth.3", "--dryrun"])
	assert_eq(run["code"], 1, run["out"])
	assert_true(str(run["out"]).contains("bilinmeyen seçenek"), run["out"])
	run = _run(["--lines=act0.yok", "--cost"])
	assert_eq(run["code"], 1, run["out"])
	assert_true(str(run["out"]).contains("hiçbir satırı tutmuyor"), run["out"])
	# API kökü yalnız yerel sınama sunucusuna çevrilebilir: anahtar başka bir adrese gitmez.
	run = _run(["--lines=act0.myth.3", "--data=" + _fixture(), "--ledger=" + _tmp.path_join("defter.jsonl"),
		"--out-dir=" + _tmp], {"ELEVENLABS_API_BASE": "https://ornek.example.com", "ELEVENLABS_API_KEY": FAKE_KEY})
	assert_eq(run["code"], 1, run["out"])
	assert_true(str(run["out"]).contains("yalnız yerel sınama sunucusu"), run["out"])
	assert_false(str(run["out"]).contains(FAKE_KEY))


# --- Yerel sahte sunucuyla uçtan uca ------------------------------------------------------------

func test_tts_end_to_end_with_local_server() -> void:
	if not _start_server(5000, "x"):
		return
	var data := _fixture()
	var ledger := _tmp.path_join("defter.jsonl")
	var env := {"ELEVENLABS_API_BASE": _base(), "ELEVENLABS_API_KEY": FAKE_KEY}
	var args := ["--lines=act0.myth.8,act0.birth.hereka", "--data=" + data, "--ledger=" + ledger, "--out-dir=" + _tmp]
	var run := _run(args, env)
	assert_eq(run["code"], 0, run["out"])
	assert_false(str(run["out"]).contains(FAKE_KEY), "Anahtar yazdırılmaz")
	# Sunucunun gördüğü: önce kota (abonelik), sonra iki with-timestamps çağrısı; anahtar başlıkta.
	var requests := _jsonl(_tmp.path_join("server_log.jsonl"))
	assert_eq(requests.size(), 3, "Bir abonelik ve iki satır isteği: %s" % str(requests))
	if requests.size() == 3:
		assert_eq(str(requests[0]["path"]), "/v1/user/subscription", "Kota kapısı çağrıdan önce kalanı okur")
		assert_eq(str(requests[1]["path"]), "/v1/text-to-speech/%s/with-timestamps?output_format=mp3_44100_64" % DAVID)
		assert_eq(str(requests[2]["path"]), "/v1/text-to-speech/%s/with-timestamps?output_format=mp3_44100_64" % HEATHER)
		for request: Dictionary in requests:
			assert_eq(str(request.get("key", "")), FAKE_KEY, "Anahtar xi-api-key başlığında gider")
		var body: Dictionary = requests[1]["body"]
		assert_eq(str(body.get("model_id", "")), "eleven_v3")
		assert_almost(float(body["voice_settings"]["stability"]), 0.5, 0.0001)
		assert_eq(str(body.get("text", "")), VoLines.subtitle("act0.myth.8", "en"))
	# Ses yeniden kodlanmadan yazılır; sözcük zamanı metinle aynı sırada; satırın alanları güncellenir.
	var source := FileAccess.get_file_as_bytes(SOURCE_MP3)
	var result := _read_json(data)
	for id in ["act0.myth.8", "act0.birth.hereka"]:
		var mp3 := _tmp.path_join(id + ".mp3")
		assert_eq(FileAccess.get_file_as_bytes(mp3), source, "%s: yanıttaki ses olduğu gibi yazılmalı" % id)
		var line := _line_of(result, id)
		assert_eq(str(line.get("file", "")), mp3, id)
		assert_eq(str(line.get("timing", "")), _tmp.path_join(id + ".json"), id)
		assert_almost(float(line.get("seconds", 0.0)), SOURCE_SECONDS, 0.05, "%s: seconds dosyanın gerçek süresi" % id)
		assert_eq(str(line.get("take_hash", "")), VoLines.take_hash(VoLines.line(id)), "%s: çekimin karması" % id)
		assert_almost(float(line.get("est", 0.0)), VoLines.est(id), 0.0001, "%s: tahmin değişmez" % id)
		var timing := _read_json(_tmp.path_join(id + ".json"))
		var words: Array = timing.get("words", [])
		assert_eq(words.size(), VoLines.subtitle(id, "en").split(" ", false).size(), "%s: sözcük sayısı" % id)
		if not words.is_empty():
			assert_eq(str(words[0]["w"]), VoLines.subtitle(id, "en").split(" ", false)[0])
		assert_eq(str(timing.get("hash", "")), str(line.get("take_hash", "")))
	# Defter: her API çağrısı bir satır; kredi character-cost başlığından.
	var entries := _jsonl(ledger)
	assert_eq(entries.size(), 2, "İki çağrı, iki defter satırı")
	for entry: Dictionary in entries:
		for key in LEDGER_KEYS:
			assert_true(entry.has(key), "Defter satırında %s yok" % key)
		assert_eq(str(entry.get("product", "")), "tts")
		assert_eq(int(entry.get("credits", 0)), VoLines.chars(str(entry["id"])), "Kredi başlıktan")
		assert_eq(str(entry.get("credits_from", "")), "header")
	for path in [data, ledger, _tmp.path_join("act0.myth.8.json")]:
		assert_false(FileAccess.get_file_as_string(path).contains(FAKE_KEY), "Anahtar dosyaya yazılmaz: %s" % path)
	# İkinci koşu: dosyalar güncel, istek ve kredi yok (K61: değişmeyen satıra kredi harcanmaz).
	run = _run(args, env)
	assert_eq(run["code"], 0, run["out"])
	assert_true(str(run["out"]).contains("güncel: act0.myth.8"), run["out"])
	assert_eq(_jsonl(_tmp.path_join("server_log.jsonl")).size(), 3, "Güncel satır için istek gitmez")
	assert_eq(_jsonl(ledger).size(), 2, "Güncel satır deftere yazılmaz")


func test_api_error_writes_nothing_and_lock_blocks_the_call() -> void:
	if not _start_server(5000, "x"):
		return
	var ledger := _tmp.path_join("defter.jsonl")
	var env := {"ELEVENLABS_API_BASE": _base(), "ELEVENLABS_API_KEY": FAKE_KEY}
	# 401: çıkış 2, defter satırı ve dosya yok, anahtar iletide yok.
	var broken := _fixture(true, [], func(d: Dictionary) -> void: _line_of(d, "act0.myth.9")["voice"] = "HATA401")
	var run := _run(["--lines=act0.myth.9", "--data=" + broken, "--ledger=" + ledger, "--out-dir=" + _tmp], env)
	assert_eq(run["code"], 2, run["out"])
	assert_true(str(run["out"]).contains("401"), run["out"])
	assert_false(str(run["out"]).contains(FAKE_KEY))
	assert_false(FileAccess.file_exists(ledger), "Başarısız çağrı deftere yazılmaz")
	assert_false(FileAccess.file_exists(_tmp.path_join("act0.myth.9.mp3")))
	# Kilitsiz metin: sunucuya hiç gidilmez.
	var before := _jsonl(_tmp.path_join("server_log.jsonl")).size()
	var unlocked := _fixture(true, [], func(d: Dictionary) -> void: (d["locks"] as Dictionary).erase("0"))
	run = _run(["--lines=act0.myth.3", "--data=" + unlocked, "--ledger=" + ledger, "--out-dir=" + _tmp], env)
	assert_eq(run["code"], 4, run["out"])
	assert_eq(_jsonl(_tmp.path_join("server_log.jsonl")).size(), before, "Kilitsiz metinde istek gitmez")
	# Kota: kalan 50, plan 61 → çıkış 3, ücretli istek yok.
	_stop_server()
	if not _start_server(50, "x"):
		return
	env["ELEVENLABS_API_BASE"] = _base()
	run = _run(["--lines=act0.myth.8", "--data=" + _fixture(), "--ledger=" + ledger, "--out-dir=" + _tmp], env)
	assert_eq(run["code"], 3, run["out"])
	for request: Dictionary in _jsonl(_tmp.path_join("server_log.jsonl")):
		assert_ne(str(request.get("method", "")), "POST", "Kota aşılınca ücretli istek gitmez")


func test_saved_response_is_processed_without_network() -> void:
	# Yanıt işlenemezse ham yanıt saklanır; --response onu yeniden çağırmadan işler (deftere yazmaz).
	var text := VoLines.subtitle("act0.myth.8", "en")
	var step := SOURCE_SECONDS / text.length()
	var starts := []
	var ends := []
	for i in text.length():
		starts.append(i * step)
		ends.append((i + 1) * step)
	var chars := []
	for i in text.length():
		chars.append(text[i])
	var response := {"audio_base64": Marshalls.raw_to_base64(FileAccess.get_file_as_bytes(SOURCE_MP3)),
		"alignment": {"characters": chars, "character_start_times_seconds": starts, "character_end_times_seconds": ends}}
	var response_path := _tmp.path_join("yanit.json")
	_write(response_path, JSON.stringify(response))
	var data := _fixture()
	var ledger := _tmp.path_join("defter.jsonl")
	var run := _run(["--lines=act0.myth.8", "--response=" + response_path, "--data=" + data, "--ledger=" + ledger,
		"--out-dir=" + _tmp])
	assert_eq(run["code"], 0, run["out"])
	var line := _line_of(_read_json(data), "act0.myth.8")
	assert_almost(float(line.get("seconds", 0.0)), SOURCE_SECONDS, 0.05)
	assert_eq(FileAccess.get_file_as_bytes(_tmp.path_join("act0.myth.8.mp3")), FileAccess.get_file_as_bytes(SOURCE_MP3))
	assert_eq((_read_json(_tmp.path_join("act0.myth.8.json")).get("words", []) as Array).size(), text.split(" ", false).size())
	assert_false(FileAccess.file_exists(ledger), "Saklanan yanıt yeni çağrı değildir, deftere yazılmaz")


func test_block_reading_cuts_lines_at_the_silences() -> void:
	# --block: satırlar tek çağrıda okunur, sözcük zamanı sınırın yerini gösterir, kesimi zarf verir (modelin zamanları duraklamayı
	# sonraki sözcüğe yazar: burada da öyle). Saklanan yanıtla ağsız sınanır; satırın dosyası, zamanı ve alanları tek okumadaki gibidir.
	var ids: Array[String] = ["act0.myth.17", "act0.myth.18", "act0.myth.20"]
	var mp3 := _tmp.path_join("blok.mp3")
	# Üç söz (1,8; 0,5; 1,6 sn), aralarında sessizlik: 0,9 ve 1,1 sn.
	var made := OS.execute("ffmpeg", ["-v", "error", "-y", "-f", "lavfi", "-i", "sine=frequency=220:duration=1.8", "-f", "lavfi", "-i",
		"anullsrc=r=44100:cl=mono:d=0.9", "-f", "lavfi", "-i", "sine=frequency=330:duration=0.5", "-f", "lavfi", "-i",
		"anullsrc=r=44100:cl=mono:d=1.1", "-f", "lavfi", "-i", "sine=frequency=440:duration=1.6", "-filter_complex",
		"[0:a]aformat=sample_rates=44100:channel_layouts=mono[a];[2:a]aformat=sample_rates=44100:channel_layouts=mono[c];[4:a]aformat=sample_rates=44100:channel_layouts=mono[e];[a][1:a][c][3:a][e]concat=n=5:v=0:a=1",
		"-c:a", "libmp3lame", "-b:a", "128k", ProjectSettings.globalize_path(mp3)])
	if made != 0:
		print("    ffmpeg yok: blok sınaması atlandı")
		return
	var chars := []
	var starts := []
	var ends := []
	# Zamanlar: «Eight.» sessizliğin başından, öteki satırlar sözcüklere eşit dağılır (gerçek okumadaki gibi kaba).
	var spans := [[0.0, 1.8], [1.82, 3.2], [4.3, 5.9]]
	for i in ids.size():
		var text := VoLines.subtitle(ids[i], "en")
		var step: float = (float(spans[i][1]) - float(spans[i][0])) / text.length()
		for k in text.length():
			chars.append(text[k])
			starts.append(float(spans[i][0]) + k * step)
			ends.append(float(spans[i][0]) + (k + 1) * step)
		if i < ids.size() - 1:
			for k in 2:
				chars.append("\n")
				starts.append(float(spans[i][1]))
				ends.append(float(spans[i][1]))
	var response := {"audio_base64": Marshalls.raw_to_base64(FileAccess.get_file_as_bytes(mp3)),
		"alignment": {"characters": chars, "character_start_times_seconds": starts, "character_end_times_seconds": ends}}
	var response_path := _tmp.path_join("blok.json")
	_write(response_path, JSON.stringify(response))
	var data := _fixture()
	var ledger := _tmp.path_join("defter.jsonl")
	var spec := "--lines=" + ",".join(ids)
	var run := _run([spec, "--block", "--response=" + response_path, "--data=" + data, "--ledger=" + ledger, "--out-dir=" + _tmp,
		"--keep=" + _tmp])
	assert_eq(run["code"], 0, run["out"])
	var result := _read_json(data)
	var want := [1.8, 0.5, 1.6]
	for i in ids.size():
		var line := _line_of(result, ids[i])
		var path := _tmp.path_join(ids[i] + ".mp3")
		assert_true(FileAccess.file_exists(path), "%s: satırın dosyası" % ids[i])
		assert_eq(str(line.get("file", "")), path)
		assert_eq(str(line.get("take_hash", "")), VoLines.take_hash(VoLines.line(ids[i])), "%s: çekimin karması" % ids[i])
		assert_almost(float(line.get("seconds", 0.0)), float(want[i]) + 0.2, 0.15, "%s: söz ve payları, %s" % [ids[i], line.get("seconds")])
		var timing := _read_json(_tmp.path_join(ids[i] + ".json"))
		var words: Array = timing.get("words", [])
		assert_eq(words.size(), VoLines.subtitle(ids[i], "en").split(" ", false).size(), "%s: sözcük sayısı" % ids[i])
		assert_true(float(words[0]["t0"]) < 0.2, "%s: ilk sözcük sessizlikte başlamaz, %s" % [ids[i], words[0]])
		assert_true(float(words[-1]["t1"]) <= float(line.get("seconds", 0.0)), "%s: son sözcük dosyanın içinde" % ids[i])
		assert_true(float(words[-1]["t1"]) > float(words[-1]["t0"]), "%s: son sözcüğün süresi var" % ids[i])
		assert_true((timing.get("block", {}) as Dictionary).has("t0"), "%s: bloktaki yeri yazılı" % ids[i])
	assert_false(FileAccess.file_exists(ledger), "Saklanan yanıt yeni çağrı değildir, deftere yazılmaz")
	assert_true(FileAccess.file_exists(_tmp.path_join("act0.myth.17..act0.myth.20.take0.mp3")), "Bloğun sesi saklanır")
	# Tek ses şartı: başka sesli satır bloğa giremez; kuru koşu tek çağrı ve 128 kb/sn yazar.
	run = _run(["--lines=act0.myth.17,act0.birth.12", "--block", "--dry-run", "--data=" + data])
	assert_eq(run["code"], 1, run["out"])
	assert_true(str(run["out"]).contains("hepsi aynı olmalı"), run["out"])
	run = _run(["--lines=act0.myth.3,act0.myth.4", "--block", "--dry-run", "--force", "--data=" + data, "--ledger=" + ledger])
	assert_eq(run["code"], 0, run["out"])
	assert_true(_after(run["out"], "istek: ").size() == 1 and _after(run["out"], "istek: ")[0].ends_with("/with-timestamps?output_format=mp3_44100_128"), run["out"])
	assert_false(FileAccess.file_exists(ledger), "Kuru koşu deftere yazmaz")


func test_music_sfx_and_stt_end_to_end_with_local_server() -> void:
	if not _start_server(5000, N1_TEXT):
		return
	var ledger := _tmp.path_join("defter.jsonl")
	var env := {"ELEVENLABS_API_BASE": _base(), "ELEVENLABS_API_KEY": FAKE_KEY}
	# Şarkı: music_v2_5, multipart yanıt → MP3 ve sözcük zamanı; kredi aboneliğin farkından.
	var song := _tmp.path_join("sarki.mp3")
	var run := _run(["music", "--plan=" + _write_plan(), "--out=" + song, "--id=act0.bard.song", "--seed=3106",
		"--ledger=" + ledger], env)
	assert_eq(run["code"], 0, run["out"])
	assert_eq(FileAccess.get_file_as_bytes(song), FileAccess.get_file_as_bytes(SOURCE_MP3), "Şarkının sesi multipart'tan")
	var meta := _read_json(_tmp.path_join("sarki.json"))
	assert_eq(str(meta.get("song_id", "")), "sinamaSarki")
	assert_eq(int(meta.get("seed", 0)), 3106)
	assert_eq((meta.get("words_timestamps", []) as Array).size(), 1)
	# Efekt: --wav ile 22,05 kHz mono WAV.
	run = _run(["sfx", _tmp.path_join("aglama.mp3"), "4", "false", "Newborn first cry", "--wav", "--id=newborn_cry",
		"--ledger=" + ledger], env)
	assert_eq(run["code"], 0, run["out"])
	var wav := AudioStreamWAV.load_from_file(_tmp.path_join("aglama.wav"))
	assert_not_null(wav, "WAV yazılmalı")
	if wav:
		assert_eq(wav.mix_rate, 22050)
		assert_false(wav.stereo, "Mono")
	# Yazıya çevirme: Scribe v2 metni satırın metniyle karşılaştırır.
	run = _run(["stt", "--lines=act0.narr.1", "--data=" + _fixture(false), "--ledger=" + ledger], env)
	assert_eq(run["code"], 0, run["out"])
	assert_true(str(run["out"]).contains("metinle aynı"), run["out"])
	var requests := _jsonl(_tmp.path_join("server_log.jsonl"))
	var posts := requests.filter(func(r: Dictionary) -> bool: return r["method"] == "POST")
	assert_eq(posts.size(), 3, str(posts))
	if posts.size() == 3:
		assert_eq(str(posts[0]["path"]), "/v1/music/detailed?output_format=mp3_44100_128")
		assert_eq(str(posts[0]["body"]["model_id"]), "music_v2_5")
		assert_eq(str(posts[1]["path"]), "/v1/sound-generation?output_format=mp3_44100_128")
		assert_eq(str(posts[1]["body"]["model_id"]), "eleven_text_to_sound_v2")
		assert_eq(str(posts[2]["path"]), "/v1/speech-to-text")
		assert_eq(posts[2]["body"]["scribe"], true, "Scribe v2 modeli formda")
	var entries := _jsonl(ledger)
	var products := entries.map(func(e: Dictionary) -> String: return str(e["product"]))
	assert_eq(products, ["music", "sfx", "stt"])
	var credits := entries.map(func(e: Dictionary) -> int: return int(e["credits"]))
	assert_eq(credits, [405, 160, 30], "Kredi aboneliğin farkından")
	for entry: Dictionary in entries:
		assert_eq(str(entry.get("credits_from", "")), "subscription")
	assert_false(str(run["out"]).contains(FAKE_KEY))


# --- Yardımcılar ---------------------------------------------------------------------------------

## Aracı ayrı süreçte koşar: {code, out} (standart çıktı ve hata birlikte). Anahtar boş, .env yok, API kökü
## kapalı yerel kapı; env bunları değiştirir.
func _run(args: Array, env: Dictionary = {}) -> Dictionary:
	var vars := {"ELEVENLABS_API_KEY": "", "ELEVENLABS_ENV_FILE": _tmp.path_join("yok.env"), "ELEVENLABS_API_BASE": DEAD_BASE}
	vars.merge(env, true)
	var argv := PackedStringArray()
	for key: String in vars:
		argv.append("%s=%s" % [key, vars[key]])
	argv.append("bash")
	argv.append(ProjectSettings.globalize_path(TOOL))
	for arg: Variant in args:
		argv.append(str(arg))
	var output := []
	var code := OS.execute("env", argv, output, true)
	return {"code": code, "out": "\n".join(PackedStringArray(output))}


## Oyunun verisinin geçici kopyası. clear: okuma satırlarının dosyaları silinir (üretilmemiş hâl; keep
## dışındakiler), böylece sınama satırlar üretildikten sonra da aynı kalır. mutate kopyayı bozar.
func _fixture(clear: bool = true, keep: Array = [], mutate: Callable = Callable()) -> String:
	var d: Dictionary = VoLines.data().duplicate(true)
	if clear:
		for item: Variant in d["lines"]:
			var line: Dictionary = item
			if str(line.get("kind", "")) == "line" and not keep.has(line.get("id")):
				line["file"] = null
				line["timing"] = null
				line["take_hash"] = null
				line["seconds"] = line.get("est")
	if mutate.is_valid():
		mutate.call(d)
	var path := _tmp.path_join("veri_%d.json" % Time.get_ticks_usec())
	_write(path, JSON.stringify(d, "\t", false))
	return path


func _line_of(d: Dictionary, id: String) -> Dictionary:
	for item: Variant in d.get("lines", []):
		if item is Dictionary and item.get("id") == id:
			return item
	fail("Veride %s yok" % id)
	return {}


func _seed_of(id: String) -> int:
	var digest := VoLines.take_hash(VoLines.line(id))
	return (("0x" + digest.substr(0, 8)).hex_to_int() + int(VoLines.line(id).get("take", 0)) * 7919) % 4294967296


func _write_plan() -> String:
	var plan := {"chunks": [
		{"text": "[Intro]\n{solo komuz}", "duration_ms": 4616, "positive_styles": ["solo komuz"], "negative_styles": ["guitar"]},
		{"text": "One more was counted the dawn that the full moon fell,", "duration_ms": 23084,
			"positive_styles": ["solo komuz", "old male bard"], "negative_styles": ["guitar"]}]}
	var path := _tmp.path_join("plan.json")
	_write(path, JSON.stringify(plan))
	return path


func _start_server(remaining: int, stt_text: String) -> bool:
	var script := _tmp.path_join("mock_eleven.py")
	_write(script, MOCK_SERVER)
	var port_file := _tmp.path_join("port.txt")
	for old in [port_file, _tmp.path_join("server_log.jsonl")]:
		if FileAccess.file_exists(old):
			DirAccess.remove_absolute(old)
	_server_pid = OS.create_process("python3", PackedStringArray(["-I", script, port_file, _tmp.path_join("server_log.jsonl"),
		ProjectSettings.globalize_path(SOURCE_MP3), str(remaining), stt_text, str(SOURCE_SECONDS)]))
	if _server_pid <= 0:
		fail("Sahte sunucu başlatılamadı (python3)")
		return false
	var waited := 0
	while not FileAccess.file_exists(port_file) and waited < 10000:
		OS.delay_msec(20)
		waited += 20
	_port = int(FileAccess.get_file_as_string(port_file)) if FileAccess.file_exists(port_file) else 0
	if _port <= 0:
		fail("Sahte sunucu kapısını yazmadı")
		return false
	return true


func _stop_server() -> void:
	if _server_pid > 0:
		OS.kill(_server_pid)
	_server_pid = -1
	_port = 0


func _base() -> String:
	return "http://127.0.0.1:%d" % _port


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	assert_true(parsed is Dictionary, "%s JSON sözlüğü olmalı" % path)
	return parsed if parsed is Dictionary else {}


func _jsonl(path: String) -> Array:
	var out := []
	if not FileAccess.file_exists(path):
		return out
	for row in FileAccess.get_file_as_string(path).split("\n", false):
		var parsed: Variant = JSON.parse_string(row)
		if parsed is Dictionary:
			out.append(parsed)
	return out


## Çıktının «önek» ile başlayan satırlarının geri kalanı.
func _after(text: String, prefix: String) -> PackedStringArray:
	var out := PackedStringArray()
	for row in text.split("\n"):
		if row.begins_with(prefix):
			out.append(row.substr(prefix.length()))
	return out


func _json_after(text: String, prefix: String) -> Array:
	var out := []
	for row in _after(text, prefix):
		var parsed: Variant = JSON.parse_string(row)
		assert_true(parsed is Dictionary, "%s JSON değil: %s" % [prefix, row])
		if parsed is Dictionary:
			out.append(parsed)
	return out


func _first(list: Array) -> Dictionary:
	if list.is_empty():
		fail("Beklenen satır çıktıda yok")
		return {}
	return list[0]


func _first_string(list: PackedStringArray) -> String:
	return list[0] if not list.is_empty() else ""
