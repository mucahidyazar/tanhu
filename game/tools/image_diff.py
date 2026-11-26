#!/usr/bin/env python3
"""
Piksel karşılaştırma aracı (godot.md §8.5): iki PNG'yi piksel piksel karşılaştırır ve en az bir renk kanalı
eşikten (8/255) çok değişen piksellerin oranını yazar. Oran sınırı (%0,5) aşmıyorsa iki kare "aynı" sayılır.
Menü karesi her işte referansla karşılaştırılır (tests/refs/; nasıl yapıldığı docs/testler.md'de).

Kullanım:
  python3 tools/image_diff.py <referans.png> <yeni.png> [--threshold=8] [--max-ratio=0.5] [--diff=fark.png]

  --threshold=8     Bir kanaldaki farkın sayıldığı en küçük değer: fark bundan BÜYÜKSE piksel "değişti" sayılır
                    (0..255; varsayılan 8, yani 8/255).
  --max-ratio=0.5   Değişen piksellerin izin verilen en çok oranı, yüzde (varsayılan 0,5).
  --diff=yol.png    Fark görüntüsü: referans soluk gri, değişen pikseller kırmızı (koyuluğu farkın büyüklüğü).

Yalnız R, G, B karşılaştırılır (ekran görüntüsünün saydamlık kanalı her yerde 255'tir). Çıkış kodu: 0 = aynı
(oran ≤ sınır), 1 = farklı, 2 = dosya okunamadı ya da boyutlar farklı.

Bağımlılık yoktur: PNG standart kitaplıkla (zlib) açılır; numpy kuruluysa hesap hızlanır (yoksa birkaç saniye sürer).
Desteklenen PNG: 8 ya da 16 bit gri, gri + saydam, RGB, RGBA ve 8 bit paletli; taramalı (Adam7) PNG desteklenmez.
"""
import struct
import signal
import sys
import zlib

try:
    import numpy as np
except ImportError:  # numpy yoksa yavaş ama aynı sonuçlu saf Python yolu
    np = None

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
DEFAULT_THRESHOLD = 8
DEFAULT_MAX_RATIO = 0.5
# Renk türü → kanal sayısı (0 gri, 2 RGB, 3 paletli, 4 gri + saydam, 6 RGBA).
CHANNELS = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}


class PngError(Exception):
    pass


def read_png(path):
    """PNG'yi okur: (genişlik, yükseklik, RGB baytları) döner; satır satır, piksel başına 3 bayt."""
    try:
        with open(path, "rb") as f:
            data = f.read()
    except OSError as e:
        raise PngError(f"açılamadı: {e}")
    if data[:8] != PNG_SIGNATURE:
        raise PngError("PNG değil")
    pos = 8
    header = None
    palette = None
    idat = []
    while pos + 8 <= len(data):
        length, kind = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", body)
        elif kind == b"PLTE":
            palette = body
        elif kind == b"IDAT":
            idat.append(body)
        elif kind == b"IEND":
            break
    if header is None:
        raise PngError("IHDR yok")
    width, height, depth, color, _compression, _filter, interlace = header
    if color not in CHANNELS:
        raise PngError(f"bilinmeyen renk türü {color}")
    if interlace != 0:
        raise PngError("taramalı (Adam7) PNG desteklenmez")
    if depth not in (8, 16) or (color == 3 and depth != 8):
        raise PngError(f"desteklenmeyen bit derinliği {depth}")
    if color == 3 and palette is None:
        raise PngError("paletli PNG'de PLTE yok")
    channels = CHANNELS[color]
    bpp = channels * depth // 8
    stride = width * bpp
    try:
        raw = zlib.decompress(b"".join(idat))
    except zlib.error as e:
        raise PngError(f"bozuk görüntü verisi: {e}")
    if len(raw) < height * (stride + 1):
        raise PngError("görüntü verisi eksik")
    pixels = unfilter(raw, height, stride, bpp)
    return width, height, to_rgb(pixels, width, height, color, depth, palette)


def unfilter(raw, height, stride, bpp):
    """PNG satır süzgeçlerini (None, Sub, Up, Average, Paeth) geri alır; süzgeçsiz baytları döner."""
    out = bytearray(height * stride)
    prev = bytearray(stride)
    pos = 0
    for y in range(height):
        kind = raw[pos]
        line = bytearray(raw[pos + 1:pos + 1 + stride])
        pos += stride + 1
        if kind == 1:
            for i in range(bpp, stride):
                line[i] = (line[i] + line[i - bpp]) & 255
        elif kind == 2:
            if np is not None:
                line = bytearray((np.frombuffer(line, np.uint8) + np.frombuffer(prev, np.uint8)).tobytes())
            else:
                line = bytearray((a + b) & 255 for a, b in zip(line, prev))
        elif kind == 3:
            for i in range(stride):
                left = line[i - bpp] if i >= bpp else 0
                line[i] = (line[i] + ((left + prev[i]) >> 1)) & 255
        elif kind == 4:
            _paeth(line, prev, stride, bpp)
        elif kind != 0:
            raise PngError(f"bilinmeyen satır süzgeci {kind} (satır {y})")
        out[y * stride:(y + 1) * stride] = line
        prev = line
    return out


def _paeth(line, prev, stride, bpp):
    for i in range(bpp):
        line[i] = (line[i] + prev[i]) & 255
    for i in range(bpp, stride):
        a = line[i - bpp]
        b = prev[i]
        c = prev[i - bpp]
        pa = b - c if b > c else c - b
        pb = a - c if a > c else c - a
        pc = a + b - c - c
        if pc < 0:
            pc = -pc
        if pa <= pb and pa <= pc:
            pred = a
        elif pb <= pc:
            pred = b
        else:
            pred = c
        line[i] = (line[i] + pred) & 255


def to_rgb(pixels, width, height, color, depth, palette):
    """Süzgeçsiz baytları piksel başına 3 baytlık RGB'ye çevirir (16 bit kanalın üst baytı alınır)."""
    channels = CHANNELS[color]
    if depth == 16:
        pixels = pixels[0::2]
    if color == 2:
        return bytes(pixels)
    if color == 6:
        rgb = bytearray(width * height * 3)
        rgb[0::3] = pixels[0::4]
        rgb[1::3] = pixels[1::4]
        rgb[2::3] = pixels[2::4]
        return bytes(rgb)
    if color == 3:
        return b"".join(palette[i * 3:i * 3 + 3] for i in pixels)
    gray = pixels[0::channels]
    rgb = bytearray(width * height * 3)
    rgb[0::3] = gray
    rgb[1::3] = gray
    rgb[2::3] = gray
    return bytes(rgb)


def compare(a, b, threshold):
    """İki RGB bayt dizisi: (değişen piksel sayısı, piksel başına en büyük kanal farkı) döner."""
    if np is not None:
        da = np.frombuffer(a, np.uint8).reshape(-1, 3).astype(np.int16)
        db = np.frombuffer(b, np.uint8).reshape(-1, 3).astype(np.int16)
        delta = np.abs(da - db).max(axis=1).astype(np.uint8)
        return int((delta > threshold).sum()), delta.tobytes()
    delta = bytearray(len(a) // 3)
    changed = 0
    for p in range(len(delta)):
        i = p * 3
        d = max(abs(a[i] - b[i]), abs(a[i + 1] - b[i + 1]), abs(a[i + 2] - b[i + 2]))
        delta[p] = d
        if d > threshold:
            changed += 1
    return changed, bytes(delta)


def write_diff(path, width, height, ref, delta, threshold):
    """Fark görüntüsü: referansın soluk gri hâli; eşiği aşan pikseller farkla koyulaşan kırmızı."""
    if np is not None:
        r = np.frombuffer(ref, np.uint8).reshape(height, width, 3).astype(np.int32)
        d = np.frombuffer(delta, np.uint8).reshape(height, width).astype(np.int32)
        gray = 40 + (r[..., 0] * 3 + r[..., 1] * 6 + r[..., 2]) // 40
        out = np.repeat(gray[..., None], 3, axis=2)
        hot = d > threshold
        fade = np.maximum(0, 160 - d)
        out[hot] = np.stack([np.full_like(fade, 255), fade, fade], axis=-1)[hot]
        body = np.concatenate([np.zeros((height, 1), np.uint8), out.astype(np.uint8).reshape(height, width * 3)], axis=1)
        _write_rgb_png(path, width, height, body.tobytes())
        return
    rows = bytearray()
    for y in range(height):
        rows.append(0)
        for x in range(width):
            p = y * width + x
            i = p * 3
            gray = 40 + (ref[i] * 3 + ref[i + 1] * 6 + ref[i + 2]) // 40
            d = delta[p]
            if d > threshold:
                rows += bytes((255, max(0, 160 - d), max(0, 160 - d)))
            else:
                rows += bytes((gray, gray, gray))
    _write_rgb_png(path, width, height, bytes(rows))


def _write_rgb_png(path, width, height, rows):
    """Süzgeçsiz (her satır 0 baytıyla başlar) RGB satırlarını PNG olarak yazar."""
    png = PNG_SIGNATURE
    png += _chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    png += _chunk(b"IDAT", zlib.compress(rows, 6))
    png += _chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def _chunk(kind, body):
    return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)


def parse_args(argv):
    opts = {"threshold": DEFAULT_THRESHOLD, "max_ratio": DEFAULT_MAX_RATIO, "diff": None}
    files = []
    for arg in argv:
        if arg.startswith("--threshold="):
            try:
                opts["threshold"] = int(arg.split("=", 1)[1])
            except ValueError:
                raise ValueError("--threshold tamsayı olmalı (0..255)")
        elif arg.startswith("--max-ratio="):
            try:
                opts["max_ratio"] = float(arg.split("=", 1)[1].replace(",", "."))
            except ValueError:
                raise ValueError("--max-ratio yüzde olarak sayı olmalı (ör. 0,5)")
        elif arg.startswith("--diff="):
            opts["diff"] = arg.split("=", 1)[1]
        elif arg in ("-h", "--help"):
            return None, None
        elif arg.startswith("--"):
            raise ValueError(f"bilinmeyen argüman: {arg}")
        else:
            files.append(arg)
    if len(files) != 2:
        raise ValueError("iki PNG gerekli: referans ve yeni")
    if not 0 <= opts["threshold"] <= 255:
        raise ValueError("--threshold 0..255 olmalı")
    return files, opts


def main(argv):
    try:
        files, opts = parse_args(argv)
    except ValueError as e:
        print(f"image_diff: {e}", file=sys.stderr)
        return 2
    if files is None:
        print(__doc__)
        return 0
    images = []
    for path in files:
        try:
            images.append(read_png(path))
        except PngError as e:
            print(f"image_diff: {path}: {e}", file=sys.stderr)
            return 2
    (wa, ha, ref), (wb, hb, new) = images
    if (wa, ha) != (wb, hb):
        print(f"image_diff: boyutlar farklı: {files[0]} {wa}×{ha}, {files[1]} {wb}×{hb} (aynı --window ile alın)",
              file=sys.stderr)
        return 2
    threshold = opts["threshold"]
    changed, delta = compare(ref, new, threshold)
    total = wa * ha
    ratio = 100.0 * changed / total if total else 0.0
    same = ratio <= opts["max_ratio"]
    print(f"Değişen piksel (bir kanalda fark > {threshold}/255): {changed} / {total} = %{ratio:.3f}"
          f" (sınır %{opts['max_ratio']:g}) → {'AYNI' if same else 'FARKLI'}")
    print(f"En büyük kanal farkı: {max(delta) if delta else 0}/255")
    if opts["diff"]:
        write_diff(opts["diff"], wa, ha, ref, delta, threshold)
        print(f"Fark görüntüsü: {opts['diff']}")
    return 0 if same else 1


if __name__ == "__main__":
    # Çıktı kesilirse (ör. "| head") Unix araçları gibi sessizce dur; Python yığın dökümü yazmasın.
    if hasattr(signal, "SIGPIPE"):
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    sys.exit(main(sys.argv[1:]))
