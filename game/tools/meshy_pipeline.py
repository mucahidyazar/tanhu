#!/usr/bin/env python3
"""
Tanhu Meshy üretim hattı: konsept görselini (assets/_concepts/<id>.png) Meshy'de 3B modele çevirir,
karakterleri iskeletler (rig) ve animasyon ekler; dosyaları assets/_meshy_raw/<id>/ altına indirir.

Ayarlar ve maliyetler tools/asset_plan.json dosyasından okunur. Her satırın route'u (üretim yolu), credit_class'ı
(K66 kredi sınıfı) ve texture_class'ı (oyun dokusu, glb_prepare.py) vardır; run yalnız route'u "meshy" olan satırı
üretir. Girdi görseli satırın input_image'ıdır; yoksa kişide art'tan türeyen T-poz görseli
(docs/assets/encyclopedia/<id>/pose.png, pose_mode "t-pose"; K85), ötekilerde assets/_concepts/<id>.png.

Güvenlik ve bütçe:
  - API anahtarı yalnızca MESHY_API_KEY ortam değişkeninden (ya da --env-file ile verilen .env dosyasındaki
    MESHY_API_KEY satırından) okunur; hiçbir zaman yazdırılmaz, kaydedilmez. Tek ağ adresi https://api.meshy.ai.
  - Her görev oluşturulmadan önce canlı bakiye denetlenir, yetmiyorsa durur. Toplam harcama sınırı yoktur (K94: kullanıcı
    kaldırdı); kredi harcayan her iş önce kullanıcıya adet, sınıf ve toplamla sorulur (K66).
  - Bir görev bir kez oluşturulduysa (kimliği <id>/meshy.json'da) yeniden oluşturulmaz; kaldığı yerden izlenir.
    Oluşturma isteği zaman aşımına uğrarsa görev "belirsiz" işaretlenir ve elle kontrol istenir (çift ücret olmasın).
  - K90: bir hareket yalnız bir kez satın alınır. Planın animations listesinde başka bir varlığın aldığı hareket varsa
    (herhangi bir hesapta; meshy.json'lardaki anim_<n> görevleri ve action_ids taşıyan anim_batch_* görevleri) plan denetimi
    hata verir, run ve kuru koşu durur; hareket ClipRetarget ile aktarılır (scripts/character/clip_retarget.gd).

Kullanım:
  python3 tools/meshy_pipeline.py [--env-file F] balance
  python3 tools/meshy_pipeline.py [--env-file F] run <id>        # model (+ karakterse rig ve animasyon)
  python3 tools/meshy_pipeline.py run <id> --dry-run              # kuru koşu: Meshy'yi çağırmaz, anahtar istemez
  python3 tools/meshy_pipeline.py [--env-file F] status [<id>]
  python3 tools/meshy_pipeline.py plan                            # satırlar, alan denetimi, planlanan toplam kredi
"""
import base64
import json
import os
import shutil
import struct
import sys
import time
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAN_PATH = os.path.join(ROOT, "tools", "asset_plan.json")
RAW_DIR = os.path.join(ROOT, "assets", "_meshy_raw")
API = "https://api.meshy.ai"
TERMINAL = ("SUCCEEDED", "FAILED", "CANCELED")
## Bu aracın ürettiği kredi sınıfları (meshy-7.1 görselden 3B; kişide rig ve klipler). small_t25 (meshy-t2.5) ve
## variant (Retexture) başka uç noktalardır, burada üretilmez.
RUN_CLASSES = ("static", "human", "animal")
## Kişinin Meshy girdisi (K85); asset_plan.json'da character_input.image yoksa bu kullanılır.
DEFAULT_POSE_IMAGE = "../docs/assets/encyclopedia/{encyclopedia_id}/pose.png"


# --- Anahtar ve HTTP -------------------------------------------------------------------

def load_key(env_file):
    key = os.environ.get("MESHY_API_KEY", "").strip()
    if not key and env_file:
        with open(env_file, encoding="utf-8") as fh:
            for line in fh:
                if line.startswith("MESHY_API_KEY="):
                    key = line.split("=", 1)[1].strip().strip('"').strip("'")
                    break
    if not key:
        sys.exit("MESHY_API_KEY bulunamadı (ortam değişkeni ya da --env-file).")
    return key


def http(key, method, path, payload=None, timeout=60):
    """GET istekleri geçici ağ hatalarında birkaç kez yeniden denenir; POST (görev oluşturma) asla
    otomatik tekrarlanmaz (çift ücret olmasın)."""
    attempts = 4 if method == "GET" else 1
    for attempt in range(attempts):
        try:
            return _http_once(key, method, path, payload, timeout)
        except (urllib.error.URLError, ConnectionError, TimeoutError, OSError) as err:
            if isinstance(err, urllib.error.HTTPError) or attempt == attempts - 1:
                raise
            print("[ağ] %s %s geçici hata (%s), yeniden deneniyor..." % (method, path, type(err).__name__), flush=True)
            time.sleep(5 * (attempt + 1))


def _http_once(key, method, path, payload, timeout):
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    req = urllib.request.Request(API + path, data=data, method=method)
    req.add_header("Authorization", "Bearer " + key)
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as err:
        body = err.read().decode("utf-8", "replace")[:500]
        raise RuntimeError("HTTP %d %s: %s" % (err.code, path, body)) from None


def file_complete(path):
    """Dosya eksiksiz mi? GLB: başlıktaki toplam uzunluk = dosya boyutu; PNG: IEND ile biter; JPEG: FFD9 ile biter."""
    if not os.path.exists(path) or os.path.getsize(path) < 16:
        return False
    size = os.path.getsize(path)
    with open(path, "rb") as fh:
        head = fh.read(12)
        fh.seek(max(0, size - 12))
        tail = fh.read()
    if head[:4] == b"glTF":
        return struct.unpack_from("<I", head, 8)[0] == size
    if head[:8] == b"\x89PNG\r\n\x1a\n":
        return tail.endswith(b"IEND\xaeB`\x82")
    if head[:3] == b"\xff\xd8\xff":
        return tail.endswith(b"\xff\xd9")
    return True


def download(url, out_path):
    """Dosyayı indirir ve eksiksiz olduğunu doğrular. Bağlantı yarıda kesilirse kaldığı yerden (HTTP Range)
    devam eder; dosya eksik görünürse baştan indirir."""
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    tmp = out_path + ".part"
    for attempt in range(8):
        try:
            have = os.path.getsize(tmp) if os.path.exists(tmp) else 0
            req = urllib.request.Request(url)
            if have:
                req.add_header("Range", "bytes=%d-" % have)
            with urllib.request.urlopen(req, timeout=600) as resp:
                total = None
                if resp.status == 206:
                    cr = resp.headers.get("Content-Range", "")
                    total = int(cr.split("/")[-1]) if "/" in cr and cr.split("/")[-1].isdigit() else None
                    mode = "ab"
                else:
                    have = 0
                    cl = resp.headers.get("Content-Length")
                    total = int(cl) if cl and cl.isdigit() else None
                    mode = "wb"
                with open(tmp, mode) as fh:
                    shutil.copyfileobj(resp, fh, 1 << 20)
            got = os.path.getsize(tmp)
            if total is not None and got < total:
                raise ConnectionError("eksik indirme %d/%d bayt" % (got, total))
            if not file_complete(tmp):
                raise ConnectionError("dosya bütünlük denetimi başarısız")
            os.replace(tmp, out_path)
            return got
        except urllib.error.HTTPError as err:
            if err.code == 416 and os.path.exists(tmp):
                os.remove(tmp)  # Geçersiz aralık: baştan indir.
                continue
            if attempt == 7:
                raise
            time.sleep(5 * (attempt + 1))
        except (urllib.error.URLError, ConnectionError, TimeoutError, OSError) as err:
            if attempt == 7:
                raise
            print("[ağ] indirme kesildi (%s), devam ediliyor..." % err, flush=True)
            if os.path.exists(tmp) and not os.path.getsize(tmp):
                os.remove(tmp)
            time.sleep(5 * (attempt + 1))


def ensure_file(url, path):
    """Dosya yoksa ya da eksikse (yarım indirme) indirir."""
    if file_complete(path):
        return False
    if os.path.exists(path):
        print("[onar] eksik dosya yeniden indiriliyor: %s" % os.path.basename(path), flush=True)
        os.remove(path)
    size = download(url, path)
    print("[indir] %s (%.1f MB)" % (path, size / 1e6), flush=True)
    return True


# --- Plan ve durum -------------------------------------------------------------------

def load_plan():
    with open(PLAN_PATH, encoding="utf-8") as fh:
        return json.load(fh)


def asset_by_id(plan, asset_id):
    for a in plan["assets"]:
        if a["id"] == asset_id:
            return a
    sys.exit("Planda böyle bir varlık yok: " + asset_id)


def state_path(asset_id):
    return os.path.join(RAW_DIR, asset_id, "meshy.json")


def load_state(asset_id):
    p = state_path(asset_id)
    if os.path.exists(p):
        with open(p, encoding="utf-8") as fh:
            return json.load(fh)
    return {"id": asset_id, "tasks": {}}


def save_state(state):
    p = state_path(state["id"])
    os.makedirs(os.path.dirname(p), exist_ok=True)
    tmp = p + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(state, fh, ensure_ascii=False, indent=2)
    os.replace(tmp, p)


def spent_total():
    """Tüm varlıklar için oluşturulmuş görevlerin kredisi (biliniyorsa gerçek, yoksa planlanan)."""
    total = 0
    if not os.path.isdir(RAW_DIR):
        return 0
    for name in os.listdir(RAW_DIR):
        p = os.path.join(RAW_DIR, name, "meshy.json")
        if not os.path.exists(p):
            continue
        with open(p, encoding="utf-8") as fh:
            st = json.load(fh)
        for t in st.get("tasks", {}).values():
            if t.get("status") in ("FAILED", "CANCELED"):
                continue  # Başarısız görevlerin kredisi iade edilir.
            total += int(t.get("consumed_credits") or t.get("planned_credits") or 0)
    return total


def planned_cost(plan, asset):
    """Satırın planlanan kredisi: credit_class (K66) ve kişide ek klipler (clip × animations). credit_class'ı
    olmayan eski satırda credit_costs'tan (model, rig, hareket) hesaplanır."""
    classes = plan.get("credit_classes", {})
    credit = asset.get("credit_class")
    if credit in classes:
        cost = int(classes[credit])
        if credit == "human":
            cost += int(classes.get("clip", 0)) * len(asset.get("animations", []))
        return cost
    c = plan["credit_costs"]
    cost = c["model"]
    if asset["kind"] == "character":
        cost += c["rig"] + c["animation_per_action"] * len(asset.get("animations", []))
    return cost


def row_errors(plan, asset):
    """Satırın route, credit_class ve texture_class alanlarındaki hatalar (ileti listesi; boşsa geçerli)."""
    aid = asset.get("id", "?")
    routes = plan.get("routes", {})
    classes = plan.get("credit_classes", {})
    textures = plan.get("texture_classes", {})
    errors = []
    route = asset.get("route")
    credit = asset.get("credit_class")
    texture = asset.get("texture_class")
    if route not in routes:
        errors.append("%s: route %r tanımsız (%s)" % (aid, route, ", ".join(routes)))
    if credit not in classes:
        errors.append("%s: credit_class %r tanımsız (%s)" % (aid, credit, ", ".join(classes)))
    if route == "meshy" and credit == "none":
        errors.append("%s: meshy yolunun kredi sınıfı none olamaz" % aid)
    if route == "meshy" and texture is None:
        errors.append("%s: meshy yolunda texture_class gerekli" % aid)
    if texture is not None and texture not in textures:
        errors.append("%s: texture_class %r tanımsız (%s)" % (aid, texture, ", ".join(textures)))
    return errors


def purchased_actions():
    """Satın alınmış hareketler: {hareket numarası: [onu alan varlıklar]} (K90). Bütün meshy.json'lardaki anim_<n> görevleri ve
    action_ids taşıyan anim_* görevleri (toplu alım) sayılır; başarısız ya da iptal edilmiş görev alım değildir (kredisi iade
    edilir). Varlık, klasörünün adıdır; görevi sürenler ve sonucu belirsizler de alınmış sayılır (çift ücret olmasın)."""
    owners = {}
    if not os.path.isdir(RAW_DIR):
        return owners
    for name in sorted(os.listdir(RAW_DIR)):
        path = os.path.join(RAW_DIR, name, "meshy.json")
        if not os.path.exists(path):
            continue
        with open(path, encoding="utf-8") as fh:
            state = json.load(fh)
        for stage, task in state.get("tasks", {}).items():
            if not stage.startswith("anim_") or not isinstance(task, dict) or task.get("status") in ("FAILED", "CANCELED"):
                continue
            actions = task.get("action_ids")
            if not isinstance(actions, list):
                suffix = stage[len("anim_"):]
                actions = [int(suffix)] if suffix.isdigit() else []
            for action in actions:
                who = owners.setdefault(int(action), [])
                if name not in who:
                    who.append(name)
    return owners


def k90_errors(asset, owners):
    """K90 ihlalleri: satırın animations listesinde, başkasının aldığı ve bu satır için henüz alınmamış hareket (ileti listesi;
    boşsa geçerli). Satırın kendi aldığı hareket hata sayılmaz: ilk turun eski satırları (ör. beş kişinin 363'ü) böyle kalır."""
    errors = []
    aid = asset.get("id", "?")
    for action in asset.get("animations", []):
        who = owners.get(int(action), [])
        if who and aid not in who:
            errors.append("%s: K90: hareket %d zaten %s'de alındı; ClipRetarget ile aktar" % (aid, int(action), ", ".join(who)))
    return errors


def validate_plan(plan, owners=None):
    """Bütün satırların alan denetimi, tekil kimlik ve K90 (owners: purchased_actions biçimi; verilmezse kayıtlardan okunur);
    hata iletilerini döndürür."""
    if owners is None:
        owners = purchased_actions()
    errors = []
    seen = set()
    for a in plan["assets"]:
        if a.get("id") in seen:
            errors.append("%s: kimlik iki kez geçiyor" % a.get("id"))
        seen.add(a.get("id"))
        errors += row_errors(plan, a)
        errors += k90_errors(a, owners)
    return errors


def encyclopedia_id(asset):
    """Kişinin ansiklopedi kimliği: satırın encyclopedia_id'si, yoksa id'deki alt çizgiler tireye çevrilir."""
    return asset.get("encyclopedia_id") or asset["id"].replace("_", "-")


def input_image(plan, asset):
    """Meshy girdisinin mutlak yolu: satırın input_image'ı; yoksa kişide T-poz görseli (K85), ötekilerde konsept."""
    rel = asset.get("input_image")
    if not rel:
        if asset["kind"] == "character":
            template = plan.get("character_input", {}).get("image", DEFAULT_POSE_IMAGE)
            rel = template.replace("{encyclopedia_id}", encyclopedia_id(asset))
        else:
            rel = "assets/_concepts/%s.png" % asset["id"]
    return os.path.normpath(os.path.join(ROOT, rel))


def needs_create(state, stage):
    """Bu aşamanın görevi oluşturulacak mı? (Yok ya da başarısız; ensure_task'ın koşuluyla aynı.)"""
    t = state["tasks"].get(stage)
    return not t or t.get("status") in ("FAILED", "CANCELED")


def check_runnable(plan, asset):
    """run yalnız alanları geçerli, meshy yolundaki ve bu aracın ürettiği kredi sınıfındaki satırı üretir."""
    errors = row_errors(plan, asset) + k90_errors(asset, purchased_actions())
    if errors:
        sys.exit("PLAN: " + "; ".join(errors))
    if asset["route"] != "meshy":
        sys.exit("%s: route=%s; bu satır Meshy ile üretilmez." % (asset["id"], asset["route"]))
    if asset["credit_class"] not in RUN_CLASSES:
        sys.exit("%s: credit_class=%s bu araçla üretilmez (yalnız %s)." % (asset["id"], asset["credit_class"], ", ".join(RUN_CLASSES)))


def balance_check(key, cost, label):
    spent = spent_total()
    balance = int(http(key, "GET", "/openapi/v1/balance").get("balance", 0))
    if balance < cost:
        sys.exit("BAKİYE: %s için %d kredi gerekiyor, bakiye %d. Durdu." % (label, cost, balance))
    print("[kredi] %s: %d kredi (harcanan %d, bakiye %d)" % (label, cost, spent, balance), flush=True)


# --- Görevler ------------------------------------------------------------------------

def find_urls(obj, suffix):
    """Görev nesnesinde adı suffix ile biten tüm URL alanlarını (iç içe) bulur."""
    found = {}
    if isinstance(obj, dict):
        for k, v in obj.items():
            if isinstance(v, str) and v.startswith("http") and k.endswith(suffix):
                found[k] = v
            elif isinstance(v, (dict, list)):
                for kk, vv in find_urls(v, suffix).items():
                    found.setdefault(kk, vv)
    elif isinstance(obj, list):
        for item in obj:
            for kk, vv in find_urls(item, suffix).items():
                found.setdefault(kk, vv)
    return found


def ensure_task(plan, key, state, stage, endpoint, payload, cost):
    """Görev yoksa oluşturur (bütçe kontrolüyle), varsa kaldığı yerden izler; bitmiş görev nesnesini döndürür."""
    tasks = state["tasks"]
    t = tasks.get(stage)
    if t and t.get("status") == "CREATE_UNKNOWN":
        sys.exit("%s/%s: önceki oluşturma isteğinin sonucu belirsiz; Meshy görev listesini kontrol edin." % (state["id"], stage))
    if not t or t.get("status") in ("FAILED", "CANCELED"):
        if t and t.get("retries", 0) >= 1:
            sys.exit("%s/%s: görev yine başarısız oldu; elle kontrol gerekiyor." % (state["id"], stage))
        if payload is None:
            sys.exit("%s/%s: görev gövdesi yok (iç hata)." % (state["id"], stage))
        balance_check(key, cost, "%s/%s" % (state["id"], stage))
        retries = (t or {}).get("retries", -1) + 1
        tasks[stage] = {"status": "CREATE_UNKNOWN", "endpoint": endpoint, "planned_credits": cost, "retries": retries}
        save_state(state)
        task_id = None
        for wait in range(12):
            try:
                task_id = http(key, "POST", endpoint, payload, timeout=180)["result"]
                break
            except RuntimeError as err:
                if "HTTP 429" in str(err):
                    # Çok fazla eşzamanlı görev: görev oluşmadı, ücret alınmadı; bekleyip yeniden dene.
                    print("[sıra] %s/%s Meshy meşgul (429), 60 sn bekleniyor..." % (state["id"], stage), flush=True)
                    time.sleep(60)
                    continue
                # Sunucu isteği reddetti (4xx/5xx): görev oluşmadı, ücret alınmadı.
                tasks[stage] = {"status": "FAILED", "endpoint": endpoint, "error": str(err), "retries": retries}
                save_state(state)
                raise
        if task_id is None:
            tasks[stage] = {"status": "FAILED", "endpoint": endpoint, "error": "429 bekleme süresi doldu", "retries": retries}
            save_state(state)
            sys.exit("%s/%s: Meshy uzun süre meşgul kaldı." % (state["id"], stage))
        tasks[stage] = {"id": task_id, "status": "PENDING", "endpoint": endpoint, "planned_credits": cost, "retries": retries}
        save_state(state)
        print("[görev] %s/%s oluşturuldu: %s" % (state["id"], stage, task_id), flush=True)
    t = tasks[stage]
    last = -1
    while True:
        task = http(key, "GET", "%s/%s" % (t["endpoint"], t["id"]))
        status = task.get("status")
        progress = int(task.get("progress") or 0)
        if progress != last:
            print("[izle] %s/%s %s %d%%" % (state["id"], stage, status, progress), flush=True)
            last = progress
        if status in TERMINAL:
            t["status"] = status
            if task.get("consumed_credits") is not None:
                t["consumed_credits"] = task.get("consumed_credits")
            if status != "SUCCEEDED":
                t["error"] = json.dumps(task.get("task_error") or {}, ensure_ascii=False)[:500]
            save_state(state)
            with open(os.path.join(RAW_DIR, state["id"], "task_%s.json" % stage), "w", encoding="utf-8") as fh:
                json.dump(task, fh, ensure_ascii=False, indent=2)
            if status != "SUCCEEDED":
                sys.exit("%s/%s başarısız: %s" % (state["id"], stage, t.get("error")))
            return task
        time.sleep(10)


def image_data_uri(path):
    if not os.path.exists(path):
        sys.exit("Girdi görseli yok: " + path)
    with open(path, "rb") as fh:
        data = fh.read()
    # Görselin gerçek biçimi içerikten anlaşılır (üretici .png adıyla JPEG/WebP de yazabilir).
    if data[:3] == b"\xff\xd8\xff":
        mime = "image/jpeg"
    elif data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        mime = "image/webp"
    else:
        mime = "image/png"
    return "data:%s;base64,%s" % (mime, base64.b64encode(data).decode("ascii"))


def model_payload(plan, asset, preview=False):
    """image-to-3d görevinin gövdesi. preview'da görsel verisi yerine yolu ve boyu yazılır (kuru koşu)."""
    payload = dict(plan["meshy_defaults"])
    image = input_image(plan, asset)
    if preview:
        size = os.path.getsize(image) if os.path.exists(image) else 0
        payload["image_url"] = "<data URI: %s, %d KB>" % (os.path.relpath(image, ROOT), size // 1024)
    else:
        payload["image_url"] = image_data_uri(image)
    payload["target_polycount"] = int(asset.get("polycount", 30000))
    if asset["kind"] == "character":
        payload["pose_mode"] = plan.get("character_input", {}).get("pose_mode", "t-pose")
    return payload


def run_stages(plan, asset):
    """run'ın aşamaları sırayla: (aşama, uç nokta, kredi)."""
    costs = plan["credit_costs"]
    stages = [("model", "/openapi/v1/image-to-3d", costs["model"])]
    if asset["kind"] == "character":
        stages.append(("rig", "/openapi/v1/rigging", costs["rig"]))
        for action in asset.get("animations", []):
            stages.append(("anim_%d" % action, "/openapi/v1/animations", costs["animation_per_action"]))
    return stages


def dry_run(plan, asset_id):
    """Meshy'yi çağırmadan run'ın yapacağını yazar: alan denetimi, yol, girdi görseli, aşamalar, kredi ve bütçe.
    Ağa çıkmaz, anahtar istemez. Dönüş: run'ın çalışabileceği durumda 0, duracağı durumda 1."""
    asset = asset_by_id(plan, asset_id)
    state = load_state(asset_id)
    ok = True
    print("[kuru] %s (%s): route=%s credit_class=%s texture_class=%s planlanan %d kredi" % (
        asset_id, asset["kind"], asset.get("route"), asset.get("credit_class"), asset.get("texture_class"),
        planned_cost(plan, asset)))
    for err in row_errors(plan, asset) + k90_errors(asset, purchased_actions()):
        print("[kuru] HATA: " + err)
        ok = False
    if ok and asset["route"] != "meshy":
        print("[kuru] route=%s: bu satır Meshy ile üretilmez, run durur." % asset["route"])
        ok = False
    if ok and asset["credit_class"] not in RUN_CLASSES:
        print("[kuru] credit_class=%s bu araçla üretilmez (yalnız %s), run durur." % (asset["credit_class"], ", ".join(RUN_CLASSES)))
        ok = False
    if not ok:
        return 1
    image = input_image(plan, asset)
    model_new = needs_create(state, "model")
    print("[kuru] girdi görseli: %s (%s%s)" % (os.path.relpath(image, ROOT), "var" if os.path.exists(image) else "YOK",
                                               "" if model_new else "; model görevi var, okunmaz"))
    if model_new and not os.path.exists(image):
        print("[kuru] HATA: girdi görseli yok, run durur.")
        ok = False
    new_cost = 0
    for stage, endpoint, cost in run_stages(plan, asset):
        if needs_create(state, stage):
            new_cost += cost
            print("[kuru]   %-9s %-26s oluşturulur, %d kredi" % (stage, endpoint, cost))
        else:
            print("[kuru]   %-9s %-26s var (%s), yeniden oluşturulmaz" % (stage, endpoint, state["tasks"][stage].get("status")))
    if model_new:
        print("[kuru] model gövdesi: " + json.dumps(model_payload(plan, asset, preview=True), ensure_ascii=False))
    spent = spent_total()
    print("[kuru] kredi: harcanan %d + yeni %d = %d" % (spent, new_cost, spent + new_cost))
    print("[kuru] bakiye denetlenmedi: kuru koşu ağa çıkmaz.")
    return 0 if ok else 1


def print_plan(plan):
    """Satır tablosu (yol, kredi ve doku sınıfı, kredi, girdi görseli), alan denetimi ve planlanan toplam."""
    textures = plan.get("texture_classes", {})
    print("%-12s %-11s %-9s %-19s %5s  %s" % ("varlık", "yol", "sınıf", "doku", "kredi", "girdi görseli"))
    by_route = {}
    by_class = {}
    total = 0
    for a in plan["assets"]:
        cost = planned_cost(plan, a)
        total += cost
        route = a.get("route", "?")
        credit = a.get("credit_class", "?")
        by_route[route] = by_route.get(route, 0) + 1
        count, credits = by_class.get(credit, (0, 0))
        by_class[credit] = (count + 1, credits + cost)
        tex = textures.get(a.get("texture_class"), {})
        tex_text = "%s %s %s" % (a.get("texture_class", "-"), tex.get("size", ""), str(tex.get("format", "")).upper())
        image = input_image(plan, a)
        print("%-12s %-11s %-9s %-19s %5d  %s%s" % (a["id"], route, credit, tex_text.strip(), cost,
                                                   os.path.relpath(image, ROOT), "" if os.path.exists(image) else " (yok)"))
    print("Yola göre: " + ", ".join("%s %d" % kv for kv in sorted(by_route.items())))
    print("Kredi sınıfına göre: " + ", ".join("%s %d (%d kredi)" % (k, v[0], v[1]) for k, v in sorted(by_class.items())))
    errors = validate_plan(plan)
    print("Alan denetimi: " + ("hata yok" if not errors else "%d hata" % len(errors)))
    for err in errors:
        print("  - " + err)
    print("Planlanan toplam: %d kredi" % total)
    return 1 if errors else 0


def run_asset(plan, key, asset_id):
    asset = asset_by_id(plan, asset_id)
    check_runnable(plan, asset)
    state = load_state(asset_id)
    out_dir = os.path.join(RAW_DIR, asset_id)
    os.makedirs(out_dir, exist_ok=True)
    costs = plan["credit_costs"]

    # 1) Görselden 3B model. Girdi görseli yalnız görev oluşturulacaksa okunur (var olan görev yeniden açılmaz).
    payload = model_payload(plan, asset) if needs_create(state, "model") else None
    task = ensure_task(plan, key, state, "model", "/openapi/v1/image-to-3d", payload, costs["model"])
    glb = os.path.join(out_dir, asset_id + ".glb")
    ensure_file(task["model_urls"]["glb"], glb)
    for name, url in find_urls(task, "thumbnail_url").items():
        target = os.path.join(out_dir, "thumb_%s.png" % name.replace("_thumbnail_url", "").replace("thumbnail_url", "main"))
        ensure_file(url, target)
    # Çok yönlü önizlemeler: {"front": url, "back": url, ...} sözlüğü (eski sürümlerde liste) olarak gelir.
    views = task.get("thumbnail_urls") or {}
    items = views.items() if isinstance(views, dict) else enumerate(views)
    for name, url in items:
        target = os.path.join(out_dir, "view_%s.png" % name)
        if isinstance(url, str) and url.startswith("http"):
            ensure_file(url, target)

    if asset["kind"] != "character":
        print("[tamam] %s" % asset_id, flush=True)
        return

    # 2) İskelet (yürüme + koşma hediye).
    rig = ensure_task(plan, key, state, "rig", "/openapi/v1/rigging",
                      {"input_task_id": state["tasks"]["model"]["id"], "height_meters": float(asset.get("height_m", 1.7))}, costs["rig"])
    for name, url in find_urls(rig, "_glb_url").items():
        target = os.path.join(out_dir, "%s_%s.glb" % (asset_id, name.replace("_glb_url", "")))
        ensure_file(url, target)

    # 3) Ek animasyonlar (her biri ayrı görev).
    for action in asset.get("animations", []):
        stage = "anim_%d" % action
        anim = ensure_task(plan, key, state, stage, "/openapi/v1/animations",
                           {"rig_task_id": state["tasks"]["rig"]["id"], "action_id": int(action)}, costs["animation_per_action"])
        for name, url in find_urls(anim, "_glb_url").items():
            target = os.path.join(out_dir, "%s_%s_%d.glb" % (asset_id, name.replace("_glb_url", ""), action))
            ensure_file(url, target)
    print("[tamam] %s" % asset_id, flush=True)


def main():
    args = sys.argv[1:]
    env_file = None
    if args and args[0] == "--env-file":
        env_file, args = args[1], args[2:]
    dry = "--dry-run" in args
    args = [a for a in args if a != "--dry-run"]
    if not args:
        sys.exit(__doc__)
    plan = load_plan()
    cmd = args[0]
    if cmd == "plan":
        sys.exit(print_plan(plan))
    if cmd == "run" and dry:
        if len(args) < 2:
            sys.exit(__doc__)
        sys.exit(dry_run(plan, args[1]))
    if cmd == "status":
        ids = args[1:] or [a["id"] for a in plan["assets"]]
        for i in ids:
            st = load_state(i)
            print(i, {k: v.get("status") for k, v in st["tasks"].items()})
        print("harcanan (kayıtlara göre):", spent_total())
        return
    key = load_key(env_file)
    if cmd == "balance":
        print(http(key, "GET", "/openapi/v1/balance"))
    elif cmd == "run":
        os.makedirs(RAW_DIR, exist_ok=True)
        gd = os.path.join(RAW_DIR, ".gdignore")
        if not os.path.exists(gd):
            open(gd, "w").close()
        run_asset(plan, key, args[1])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
