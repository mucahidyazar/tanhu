#!/usr/bin/env python3
"""
Meshy'den gelen ham GLB'yi oyuna hazırlar: içindeki dokuları varlığın doku sınıfındaki oyun boyuna küçültür
(8K kaynak → 2048, 1024 ya da 512), diğer her şeyi (mesh, iskelet, animasyon) olduğu gibi korur. Godot'nun GLB'den
çıkardığı dokunun .import ayarını da sınıfın VRAM sıkıştırmasına çevirir (godot.md §6.2, §6.3).

Doku sınıfları tools/asset_plan.json'dadır (texture_classes; satırın texture_class alanı):
  hero       Mete, oyuncu kahramanı, yakın planı olan kişi (Lan Hatun, Ağabey)  2048²  BC7
  named      adlı kişi                   1024²  BC7
  mount      at ve binek                 1024²  BC7
  structure  yurt, ahır, tekil yapı      2048²  BC1
  prop       kamp eşyası, kaya, çam      1024²  BC1
  small      küçük kamp eşyası            512²  BC1
BC7: «VRAM Compressed» ve «High Quality» (masaüstünde BPTC); BC1: «VRAM Compressed» (masaüstünde S3TC, alfasız doku).
Mip açık; .import'taki process/size_limit sınıfın boyudur: GLB daha büyük doku taşısa da oyunda bu boy aşılmaz.
detect_3d kapanır: editör dokuyu kendiliğinden başka biçime çevirmez. Renk bölgesi maskesi (<id>_regions*.png) bu
aracın işi değildir, kayıpsız kalır.

Ham dosya (assets/_meshy_raw/<id>/...) değişmez, 8K kaynak orada kalır. Dokular ffmpeg ile (lanczos) küçültülür ve
aynı biçimde (JPEG/PNG) yeniden kodlanır. Kişinin yüzü boyandıysa (tools/paint_face.py, assets/_meshy_raw/<id>/face_paint/<id>_painted.jpg)
ham görselin yerine boyalı 8K okunur: yeniden hazırlık yüzü kaybetmez.

Kullanım:
  python3 tools/glb_prepare.py <girdi.glb> <çıktı.glb> [--class=prop] [--max-size=N] [--jpeg-quality=2]
      Oyun GLB'sini yazar. Sınıf verilmezse çıktı klasörünün asset_plan.json satırından okunur; --max-size sınıfın
      boyunu ezer (oyundaki boyu yine .import'un size_limit'i sınırlar). Çıkarılmış dokunun .import'u varsa sınıfa
      göre ayarlanır; yoksa (yeni varlık) Godot'nun ilk içe aktarmasından sonra --textures ile yeniden çalıştırın.
  python3 tools/glb_prepare.py --textures <id> [<id> ...]   |   --textures all
      Var olan varlık: GLB'ye dokunmadan, Godot'nun GLB'den çıkardığı dokuyu ham 8K kopyadan sınıfın boyunda yeniden
      yazar ve .import'unu ayarlar. Godot çıkardığı dokuyu GLB'deki görsel değişmedikçe yeniden yazmaz (.import'taki
      md5); GLB değişirse yeni görseli bu .import ayarıyla içe aktarır. Sonra: source tools/_godot_lock.sh; godot_import_locked
  python3 tools/glb_prepare.py --embed <id> [<id> ...]
      Var olan varlık: oyun GLB'sindeki görseli kaynağından sınıfın boyunda yeniden yazar, çıkarılmış dokuyu aynı baytlarla
      yazar ve .import'unu ayarlar. Ağ, iskelet ve klipler bayt bayt kalır, tools/rig_fix.py yeniden koşmaz. Sonra içe aktarma.
  python3 tools/glb_prepare.py --classes
      Varlıkların doku sınıfı, bugünkü dokuları ve .import ayarı; bekleyen varsa çıkış kodu 1 (hiçbir şeyi değiştirmez).
"""
import json
import os
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAN_PATH = os.path.join(ROOT, "tools", "asset_plan.json")
RAW_DIR = os.path.join(ROOT, "assets", "_meshy_raw")
GLB_MAGIC = 0x46546C67
CHUNK_JSON = 0x4E4F534A
CHUNK_BIN = 0x004E4942
# Sınıfın biçimi → Godot doku içe aktarıcısının «High Quality» seçeneği (masaüstünde true: BPTC/BC7, false: S3TC/BC1).
HIGH_QUALITY = {"bc7": True, "bc1": False}
# Sınıfı bilinmeyen çıktıda eski varsayılan.
DEFAULT_MAX_SIZE = 4096


def read_glb(path):
    with open(path, "rb") as fh:
        data = fh.read()
    magic, version, length = struct.unpack_from("<III", data, 0)
    if magic != GLB_MAGIC or version != 2:
        raise ValueError("GLB 2.0 değil: " + path)
    offset = 12
    doc, binary = None, b""
    while offset < length:
        chunk_len, chunk_type = struct.unpack_from("<II", data, offset)
        chunk = data[offset + 8: offset + 8 + chunk_len]
        if chunk_type == CHUNK_JSON:
            doc = json.loads(chunk.decode("utf-8"))
        elif chunk_type == CHUNK_BIN:
            binary = chunk
        offset += 8 + chunk_len
    return doc, binary


def write_glb(path, doc, binary):
    js = json.dumps(doc, separators=(",", ":")).encode("utf-8")
    js += b" " * ((4 - len(js) % 4) % 4)
    binary += b"\0" * ((4 - len(binary) % 4) % 4)
    total = 12 + 8 + len(js) + 8 + len(binary)
    with open(path, "wb") as fh:
        fh.write(struct.pack("<III", GLB_MAGIC, 2, total))
        fh.write(struct.pack("<II", len(js), CHUNK_JSON))
        fh.write(js)
        fh.write(struct.pack("<II", len(binary), CHUNK_BIN))
        fh.write(binary)


def glb_images(path):
    """GLB'nin gömülü görselleri: [(görsel sırası, mime türü, bayt)]."""
    doc, binary = read_glb(path)
    views = doc.get("bufferViews", [])
    out = []
    for index, img in enumerate(doc.get("images", [])):
        if "bufferView" not in img:
            continue
        view = views[img["bufferView"]]
        start = view.get("byteOffset", 0)
        out.append((index, img.get("mimeType", "image/png"), binary[start: start + view["byteLength"]]))
    return out


def image_size(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "stream=width,height", "-of", "csv=p=0", path],
                         capture_output=True, check=True).stdout.decode().strip().split(",")
    return int(out[0]), int(out[1])


def resize_image(blob, mime, max_size, jpeg_quality):
    """Dokuyu en büyük kenarı max_size olacak şekilde küçültür; zaten küçükse aynen döndürür."""
    ext = ".jpg" if "jpeg" in mime else ".png"
    with tempfile.TemporaryDirectory() as tmp:
        src = os.path.join(tmp, "src" + ext)
        dst = os.path.join(tmp, "dst" + ext)
        with open(src, "wb") as fh:
            fh.write(blob)
        w, h = image_size(src)
        if max(w, h) <= max_size:
            return blob, (w, h), (w, h)
        scale = max_size / float(max(w, h))
        nw, nh = int(round(w * scale)), int(round(h * scale))
        cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", src, "-vf", "scale=%d:%d:flags=lanczos" % (nw, nh)]
        if ext == ".jpg":
            cmd += ["-q:v", str(jpeg_quality)]
        cmd.append(dst)
        subprocess.run(cmd, check=True)
        with open(dst, "rb") as fh:
            return fh.read(), (w, h), (nw, nh)


# --- Plan ve doku sınıfı -------------------------------------------------------------

def load_plan():
    with open(PLAN_PATH, encoding="utf-8") as fh:
        return json.load(fh)


def asset_by_id(plan, asset_id):
    for a in plan["assets"]:
        if a["id"] == asset_id:
            return a
    sys.exit("Planda böyle bir varlık yok: " + asset_id)


def asset_for_glb(plan, glb_path):
    """Çıktı GLB'sinin klasörü planda hangi satırın dir'i ise o satır (yoksa None)."""
    folder = os.path.normpath(os.path.dirname(os.path.abspath(glb_path)))
    for a in plan["assets"]:
        if os.path.normpath(os.path.join(ROOT, a["dir"])) == folder:
            return a
    return None


def texture_class(plan, name):
    """Sınıfın (ad, boy, biçim) üçlüsü; tanımsız sınıfta durur."""
    classes = plan.get("texture_classes", {})
    if name not in classes:
        sys.exit("Doku sınıfı tanımsız: %r (%s)" % (name, ", ".join(classes)))
    spec = classes[name]
    fmt = str(spec["format"]).lower()
    if fmt not in HIGH_QUALITY:
        sys.exit("Doku sınıfı %s: biçim %r desteklenmiyor (%s)" % (name, fmt, ", ".join(HIGH_QUALITY)))
    return name, int(spec["size"]), fmt


def import_params(size, fmt):
    """Sınıfın Godot doku içe aktarma ayarları (.import [params]); değerler dosyadaki yazımıyla."""
    return [
        ("compress/mode", "2"),
        ("compress/high_quality", "true" if HIGH_QUALITY[fmt] else "false"),
        ("mipmaps/generate", "true"),
        ("process/size_limit", str(size)),
        ("detect_3d/compress_to", "0"),
    ]


def read_import_params(import_path):
    """.import dosyasının [params] bölümü: {anahtar: değer yazısı}."""
    params = {}
    section = ""
    with open(import_path, encoding="utf-8") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if line.startswith("["):
                section = line.strip()
            elif section == "[params]" and "=" in line:
                key, value = line.split("=", 1)
                params[key] = value
    return params


def _bracket_depth(text):
    """Satırın açtığı ve kapattığı parantezlerin farkı ({ ve [ açar, } ve ] kapatır; tırnak içindekiler sayılmaz)."""
    depth = 0
    quoted = False
    escaped = False
    for ch in text:
        if escaped:
            escaped = False
        elif ch == "\\":
            escaped = True
        elif ch == '"':
            quoted = not quoted
        elif not quoted:
            if ch in "{[":
                depth += 1
            elif ch in "}]":
                depth -= 1
    return depth


def patch_import(import_path, params):
    """.import'un [params] bölümünde verilen anahtarları ayarlar (eksikse bölümün sonuna ekler), öteki satırlara
    dokunmaz. Değişen anahtarların listesini döndürür (boşsa dosya yazılmaz).

    Godot içe aktarınca bazı değerleri çok satıra açar (ör. _subresources, JSON gibi). Böyle bir değer bütün okunur:
    açılan parantez kapanana dek satırlar o anahtarındır, iç satırlar anahtar ya da bölüm başı sayılmaz. Değişen
    çok satırlı değerin bütün bloğu tek satırla değişir (Godot sonraki içe aktarmada yine açar)."""
    with open(import_path, encoding="utf-8") as fh:
        text = fh.read()
    lines = text.split("\n")
    wanted = dict(params)
    changed = []
    found = set()
    out = []
    section = ""
    params_end = None
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("["):
            if section == "[params]" and params_end is None:
                params_end = len(out)
            section = line.strip()
        elif section == "[params]" and "=" in line:
            key, value = line.split("=", 1)
            end = i
            depth = _bracket_depth(value)
            while depth > 0 and end + 1 < len(lines):
                end += 1
                depth += _bracket_depth(lines[end])
            block = lines[i:end + 1]
            if key in wanted:
                found.add(key)
                if "\n".join([value] + block[1:]) != wanted[key]:
                    changed.append(key)
                    block = ["%s=%s" % (key, wanted[key])]
            out.extend(block)
            i = end + 1
            continue
        out.append(line)
        i += 1
    if section == "[params]" and params_end is None:
        params_end = len(out)
        while params_end > 0 and out[params_end - 1] == "":
            params_end -= 1
    missing = [k for k, _ in params if k not in found]
    if missing:
        if params_end is None:
            out += ["", "[params]", ""]
            params_end = len(out)
        for offset, key in enumerate(missing):
            out.insert(params_end + offset, "%s=%s" % (key, wanted[key]))
        changed += missing
    if changed:
        with open(import_path, "w", encoding="utf-8") as fh:
            fh.write("\n".join(out))
    return changed


def extracted_textures(glb_path):
    """Godot'nun GLB'den çıkardığı dokuların yolları: [(görsel sırası, yol)]. Ad <glb adı>_<görsel adı ya da sırası>,
    uzantı mime türünden (ör. mete_Image_0.jpg, yurt_0.jpg)."""
    doc, _ = read_glb(glb_path)
    folder = os.path.dirname(os.path.abspath(glb_path))
    stem = os.path.splitext(os.path.basename(glb_path))[0]
    out = []
    for index, img in enumerate(doc.get("images", [])):
        ext = ".jpg" if "jpeg" in img.get("mimeType", "") else ".png"
        out.append((index, os.path.join(folder, "%s_%s%s" % (stem, img.get("name") or index, ext))))
    return out


def raw_source(asset):
    """Varlığın 8K ham GLB'si: kişide ilk planlı klibin GLB'si (prepare_character.py gibi), ötekilerde <id>.glb."""
    aid = asset["id"]
    if asset["kind"] == "character" and asset.get("animations"):
        return os.path.join(RAW_DIR, aid, "%s_animation_%d.glb" % (aid, asset["animations"][0]))
    return os.path.join(RAW_DIR, aid, aid + ".glb")


def painted_source(asset_id):
    """Kişinin boyalı 8K dokusu (tools/paint_face.py); boya yoksa None. Varsa ham görselin yerine bu küçültülür."""
    path = os.path.join(RAW_DIR, asset_id, "face_paint", "%s_painted.jpg" % asset_id)
    return path if os.path.exists(path) else None


def source_images(asset):
    """Varlığın kaynak görselleri: {görsel sırası: (mime türü, bayt)}. Boya varsa ilk görsel boyalı 8K'dır."""
    raw = raw_source(asset)
    images = {i: (mime, blob) for i, mime, blob in glb_images(raw)} if os.path.exists(raw) else {}
    painted = painted_source(asset["id"])
    if painted:
        with open(painted, "rb") as fh:
            images[0] = ("image/jpeg", fh.read())
    return images


def pack_views(doc, blobs):
    """BIN bölümünü yeniden dizer: her bufferView 4 bayta hizalanır, ofsetler ve uzunluklar güncellenir. BIN baytlarını döndürür."""
    out = bytearray()
    for view, blob in zip(doc.get("bufferViews", []), blobs):
        out += b"\0" * ((4 - len(out) % 4) % 4)
        view["byteOffset"] = len(out)
        view["byteLength"] = len(blob)
        out += blob
    if doc.get("buffers"):
        doc["buffers"][0]["byteLength"] = len(out)
    return bytes(out)


def _rel(path):
    """Proje içindeki yol projeye göre, dışındaki mutlak yazılır."""
    path = os.path.abspath(path)
    return os.path.relpath(path, ROOT) if path.startswith(ROOT + os.sep) else path


def _apply_import(texture_path, size, fmt):
    """Çıkarılmış dokunun .import'unu sınıfa göre ayarlar; .import yoksa (Godot henüz içe aktarmadı) bildirir."""
    import_path = texture_path + ".import"
    if not os.path.exists(import_path):
        print("  %s: .import yok; Godot'nun ilk içe aktarmasından sonra --textures ile yeniden çalıştırın" % _rel(texture_path))
        return
    changed = patch_import(import_path, import_params(size, fmt))
    print("  %s: %s" % (_rel(import_path), ("ayarlandı (%s)" % ", ".join(changed)) if changed else "ayarlı"))


# --- İşler -------------------------------------------------------------------------

def drop_self_emission(doc):
    """Meshy'nin iskelet görevi kimi kişide renk dokusunu ışık dokusu olarak da bağlar (emissiveTexture aynı görsel, emissiveFactor 1,
    KHR_materials_specular 2; 2026-11-08, Atşo): model gece de kendi ışığıyla parlar. Oyun malzemeyi toon'a çevirir, ama Destan Kitabı
    ve sitenin oynatıcısı GLB'nin malzemesini okur. Işık dokusu renk dokusuyla aynı görselse bu üç alan atılır. Döner: atılan malzeme sayısı."""
    textures = doc.get("textures", [])
    dropped = 0
    for mat in doc.get("materials", []):
        emissive = mat.get("emissiveTexture")
        base = mat.get("pbrMetallicRoughness", {}).get("baseColorTexture")
        if not emissive or not base:
            continue
        if textures[emissive["index"]].get("source") != textures[base["index"]].get("source"):
            continue
        for key in ("emissiveTexture", "emissiveFactor"):
            mat.pop(key, None)
        ext = mat.get("extensions", {})
        for key in ("KHR_materials_specular", "KHR_materials_ior"):
            ext.pop(key, None)
        if not ext:
            mat.pop("extensions", None)
        dropped += 1
    return dropped


def prepare(src, dst, max_size, jpeg_quality, cls=None):
    doc, binary = read_glb(src)
    if drop_self_emission(doc):
        print("  malzeme: renk dokusunun ışık dokusu olarak bağı atıldı (Meshy iskelet çıktısı)")
    views = doc.get("bufferViews", [])
    blobs = [binary[v.get("byteOffset", 0): v.get("byteOffset", 0) + v["byteLength"]] for v in views]
    painted = painted_source(os.path.basename(os.path.dirname(os.path.abspath(dst))))
    for index, img in enumerate(doc.get("images", [])):
        if "bufferView" not in img:
            continue
        i = img["bufferView"]
        mime = img.get("mimeType", "image/png")
        if painted and index == 0:
            with open(painted, "rb") as fh:
                blobs[i] = fh.read()
            mime = img["mimeType"] = "image/jpeg"
            print("  doku %s: boyalı kaynak %s" % (img.get("name", i), _rel(painted)))
        new_blob, old_size, new_size = resize_image(blobs[i], mime, max_size, jpeg_quality)
        print("  doku %s: %dx%d → %dx%d" % (img.get("name", i), old_size[0], old_size[1], new_size[0], new_size[1]))
        blobs[i] = new_blob
    packed = pack_views(doc, blobs)
    os.makedirs(os.path.dirname(os.path.abspath(dst)), exist_ok=True)
    write_glb(dst, doc, packed)
    print("  %s (%.1f MB) → %s (%.1f MB)" % (os.path.basename(src), os.path.getsize(src) / 1e6, dst, os.path.getsize(dst) / 1e6))
    if cls is not None:
        _, size, fmt = cls
        for _, texture in extracted_textures(dst):
            _apply_import(texture, size, fmt)


def write_textures(plan, asset_id, jpeg_quality):
    """Var olan varlığın çıkarılmış dokusunu ham 8K kopyadan sınıfın boyunda yeniden yazar, .import'unu ayarlar.
    GLB'ye dokunmaz. Doku zaten sınıfın boyundaysa yeniden kodlanmaz (her koşu kaliteyi bir daha düşürmesin)."""
    asset = asset_by_id(plan, asset_id)
    if not asset.get("texture_class"):
        print("%s: texture_class yok, atlandı" % asset_id)
        return
    name, size, fmt = texture_class(plan, asset["texture_class"])
    game_glb = os.path.join(ROOT, asset["dir"], asset_id + ".glb")
    if not os.path.exists(game_glb):
        print("%s: oyun GLB'si yok (%s), atlandı" % (asset_id, _rel(game_glb)))
        return
    print("%s (%s, %d² %s):" % (asset_id, name, size, fmt.upper()))
    raw = raw_source(asset)
    raw_images = source_images(asset)
    for index, texture in extracted_textures(game_glb):
        if not os.path.exists(texture):
            print("  %s yok: Godot dokuyu henüz çıkarmamış; önce içe aktarın" % _rel(texture))
            continue
        current = image_size(texture)
        if max(current) != size:
            if index in raw_images:
                mime, blob = raw_images[index]
                source = _rel(painted_source(asset_id) if index == 0 and painted_source(asset_id) else raw)
            else:
                # Ham kopya yoksa bugünkü oyun dokusundan küçültülür (büyütülmez).
                mime = "image/jpeg" if texture.endswith(".jpg") else "image/png"
                with open(texture, "rb") as fh:
                    blob = fh.read()
                source = _rel(texture) + " (ham kopya yok)"
            new_blob, old_size, new_size = resize_image(blob, mime, size, jpeg_quality)
            if max(new_size) < max(current) or max(current) < size <= max(old_size):
                tmp = texture + ".yeni"
                with open(tmp, "wb") as fh:
                    fh.write(new_blob)
                os.replace(tmp, texture)
                print("  %s: %dx%d → %dx%d (kaynak %s)" % (_rel(texture), current[0], current[1], new_size[0], new_size[1], source))
            else:
                print("  %s: %dx%d, kaynak sınıfın boyundan küçük; değişmedi" % (_rel(texture), current[0], current[1]))
        else:
            print("  %s: %dx%d (sınıfın boyunda)" % (_rel(texture), current[0], current[1]))
        _apply_import(texture, size, fmt)


def embed_texture(plan, asset_id, jpeg_quality):
    """Var olan varlığın oyun GLB'sindeki görseli kaynağından (boya varsa boyalı 8K, yoksa ham 8K) sınıfın boyunda yeniden yazar;
    çıkarılmış dokuyu aynı baytlarla yazar, .import'unu ayarlar. GLB'de görsel dışında yalnız konumlar kayar: ağ, iskelet ve klipler
    (tools/rig_fix.py'nin düzelttikleri dahil) bayt bayt kalır."""
    asset = asset_by_id(plan, asset_id)
    name, size, fmt = texture_class(plan, asset["texture_class"])
    game_glb = os.path.join(ROOT, asset["dir"], asset_id + ".glb")
    if not os.path.exists(game_glb):
        sys.exit("%s: oyun GLB'si yok (%s)" % (asset_id, _rel(game_glb)))
    images = source_images(asset)
    doc, binary = read_glb(game_glb)
    blobs = [binary[v.get("byteOffset", 0): v.get("byteOffset", 0) + v["byteLength"]] for v in doc.get("bufferViews", [])]
    print("%s (%s, %d² %s):" % (asset_id, name, size, fmt.upper()))
    targets = dict(extracted_textures(game_glb))
    written = []
    for index, img in enumerate(doc.get("images", [])):
        if "bufferView" not in img or index not in images:
            continue
        mime, blob = images[index]
        new_blob, old_size, new_size = resize_image(blob, mime, size, jpeg_quality)
        blobs[img["bufferView"]] = new_blob
        img["mimeType"] = mime
        written.append((targets[index], new_blob))
        print("  görsel %d: %dx%d → %dx%d (%.0f KB)" % (index, old_size[0], old_size[1], new_size[0], new_size[1], len(new_blob) / 1024.0))
    packed = pack_views(doc, blobs)
    tmp = game_glb + ".yeni"
    write_glb(tmp, doc, packed)
    os.replace(tmp, game_glb)
    for texture, blob in written:
        tmp = texture + ".yeni"
        with open(tmp, "wb") as fh:
            fh.write(blob)
        os.replace(tmp, texture)
        _apply_import(texture, size, fmt)


def print_classes(plan):
    """Her varlığın doku sınıfı ve bugünkü durumu. Döner: bekleyen varsa 1."""
    pending = 0
    print("%-12s %-10s %-10s %-46s %-11s %s" % ("varlık", "sınıf", "hedef", "doku", "boy", "içe aktarma"))
    for a in plan["assets"]:
        if not a.get("texture_class"):
            print("%-12s %-10s" % (a["id"], "-"))
            continue
        name, size, fmt = texture_class(plan, a["texture_class"])
        game_glb = os.path.join(ROOT, a["dir"], a["id"] + ".glb")
        if not os.path.exists(game_glb):
            print("%-12s %-10s %4d² %-4s  GLB yok" % (a["id"], name, size, fmt.upper()))
            continue
        for _, texture in extracted_textures(game_glb):
            if not os.path.exists(texture) or not os.path.exists(texture + ".import"):
                print("%-12s %-10s %4d² %-4s  %-46s henüz içe aktarılmadı" % (a["id"], name, size, fmt.upper(), _rel(texture)))
                pending += 1
                continue
            w, h = image_size(texture)
            params = read_import_params(texture + ".import")
            ok = all(params.get(k) == v for k, v in import_params(size, fmt))
            mode = {"0": "kayıpsız", "1": "kayıplı", "2": "VRAM", "3": "VRAM sıkıştırmasız", "4": "Basis"}.get(params.get("compress/mode"), "?")
            hq = " HQ" if params.get("compress/high_quality") == "true" else ""
            state = "tamam" if ok and max(w, h) == size else "BEKLİYOR"
            if state != "tamam":
                pending += 1
            print("%-12s %-10s %4d² %-4s  %-46s %4dx%-6d %s%s, sınır %s: %s" % (a["id"], name, size, fmt.upper(), _rel(texture),
                  w, h, mode, hq, params.get("process/size_limit", "?"), state))
    print("Bekleyen: %d" % pending)
    return 1 if pending else 0


def main():
    argv = sys.argv[1:]
    args = [a for a in argv if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in argv if a.startswith("--"))
    quality = int(opts.get("jpeg-quality", 2))
    if "classes" in opts:
        sys.exit(print_classes(load_plan()))
    if "textures" in opts:
        plan = load_plan()
        ids = [a["id"] for a in plan["assets"] if a.get("texture_class")] if args == ["all"] else args
        if not ids:
            sys.exit(__doc__)
        for asset_id in ids:
            write_textures(plan, asset_id, quality)
        return
    if "embed" in opts:
        if not args:
            sys.exit(__doc__)
        plan = load_plan()
        for asset_id in args:
            embed_texture(plan, asset_id, quality)
        return
    if len(args) != 2:
        sys.exit(__doc__)
    plan = load_plan()
    cls = None
    if "class" in opts:
        cls = texture_class(plan, opts["class"])
    else:
        asset = asset_for_glb(plan, args[1])
        if asset and asset.get("texture_class"):
            cls = texture_class(plan, asset["texture_class"])
    if "max-size" in opts:
        max_size = int(opts["max-size"])
    elif cls is not None:
        max_size = cls[1]
    else:
        max_size = DEFAULT_MAX_SIZE
        print("  doku sınıfı bulunamadı (--class verilmedi, çıktı klasörü planda yok): en büyük kenar %d, .import ayarlanmaz" % max_size)
    prepare(args[0], args[1], max_size, quality, cls)


if __name__ == "__main__":
    main()
