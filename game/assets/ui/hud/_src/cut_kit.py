#!/usr/bin/env python3
"""
HUD takımının kesicisi (Tanhu, oyun içi HUD; kaynak: docs/media/review/hud_referans.webp).

sheets/ altındaki gpt-image-2 sayfaları (tools/imagegen/gen.sh, istekleri prompts/ altında) düz macenta (#FF00FF) zeminde
ya da saydam üretildi. Bu betik:
  1. macentayı anahtarlar: alfa = macenta fazlası min(R, B) - G'den, kenar pikselleri macentadan arındırılır (renk çözülür),
  2. sayfayı boşluklarından parçalara böler (yatay, sonra dikey kesim; sıra yukarıdan aşağı, soldan sağa),
  3. her parçayı adına göre kırpar, alfayla çarpılmış (premultiplied) alanda alan ortalamasıyla küçültür ve
     ../<ad>.png olarak yazar (Godot bunları içe aktarır; _src klasörü .gdignore'la dışarıda kalır),
  4. çerçevelerin ölçülerini (halkanın iç yarıçapı, çubuğun kanalı) yazar: GDScript sabitleri bunlardan gelir.

Kullanım (game/ içinde):
  python3 assets/ui/hud/_src/cut_kit.py            # hepsini keser ve yazar
  python3 assets/ui/hud/_src/cut_kit.py --list     # yalnız parçaları ve kutularını listeler

Bağımlılık: numpy ve ffmpeg (PNG okuma ve yazma).
"""
import json
import subprocess
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
SHEETS = HERE / "sheets"
OUT = HERE.parent

# Sayfa → parçaların sırayla adları (None: atla) ve hedef boyları (en uzun kenar, piksel; 4K'de 2x çizim için 1080 boyunun ≈2,5 katı).
PLAN = {
    "portrait_frame": [("portrait_ring", 420)],
    "map_frame": [("map_ring", 720), ],
    "bars": [("bar_frame", 900), (None, 0), ("bar_fill_red", 640), ("bar_fill_green", 640),
             ("slot_square", 128), (None, 0), ("badge_level", 140)],
    "quest": [("quest_rule", 900), ("quest_banner", 160), ("marker_diamond", 128), ("marker_arrow", 112), ("marker_pin", 128)],
    # Bulutların adı kuyruğunun yönüdür (referansta kuyruk dışa bakar: soldaki bulutun kuyruğu sola).
    "hotbar": [("cloud_right", 180), ("slot_hex", 200), (None, 0), ("button_round", 176), ("badge_count", 64),
               ("cloud_left", 180), ("xp_frame", 1400), ("xp_fill", 900)],
    # Envanter (I; docs/media/review/hud_envanter_referans.webp): boş pano, parçalar ve oynanan kişilerin boy görselleri.
    "inv_panel": [("inv_panel", 1392)],
    "inv_parts": [("inv_pill", 480), ("inv_pill_hot", 480), ("inv_label", 380), ("inv_ribbon", 720), ("inv_motif", 96),
                  ("icon_coins", 120), ("icon_weight", 120), ("icon_mortar", 120), ("icon_swap", 120), ("icon_trash", 120),
                  ("inv_select", 200)],
    "body_mete": [("body_mete_child", 760)],
    "body_child": [("body_child", 760)],
    "icons": [("icon_sword", 144), ("icon_shield", 144), ("icon_bow", 144), ("icon_boot", 144),
              ("icon_herb", 144), ("icon_potion", 144), ("icon_bag", 144), ("icon_book", 144),
              ("icon_map", 144), ("icon_toy_bow", 144), ("icon_lark", 144), ("icon_mouse", 144)],
}
# Portreler: kare kırpım (x, y, kenar; kaynak pikseli), yuvarlak maske, hedef kenar.
PORTRAITS = {
    "portrait_mete": ("portrait_mete_child", (150, 80, 1000), 360),
    "portrait_child": ("portrait_child", (150, 60, 1000), 360),
}
# Parlayan parçaların (seçim çerçevesi, ısınmış düğme) yarı saydam ışığı macenta zeminden pembe kalır: altına boyanır.
GLOW_TINT = {"inv_select": (0.98, 0.78, 0.36), "inv_pill_hot": (0.98, 0.78, 0.36)}
# Kesimde parça sayılan en küçük kutu (piksel) ve birleşen boşluk payı.
MIN_PIECE = 24
GAP = 10
PAD = 3


def read_png(path: Path) -> np.ndarray:
    probe = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "stream=width,height", "-of", "csv=p=0", str(path)],
                           capture_output=True, text=True, check=True)
    w, h = (int(v) for v in probe.stdout.strip().split(","))
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(path), "-f", "rawvideo", "-pix_fmt", "rgba", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.uint8).reshape(h, w, 4).astype(np.float32) / 255.0


def write_png(path: Path, img: np.ndarray) -> None:
    h, w = img.shape[:2]
    data = (np.clip(img, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8).tobytes()
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgba", "-s", f"{w}x{h}", "-i", "-",
                    "-frames:v", "1", "-pix_fmt", "rgba", str(path)], input=data, check=True)


def key_magenta(img: np.ndarray) -> np.ndarray:
    """Macenta zemini saydamlaştırır; saydam üretilmiş sayfada artık macenta lekeleri de gider."""
    rgb = img[..., :3]
    a0 = img[..., 3]
    m = np.minimum(rgb[..., 0], rgb[..., 2]) - rgb[..., 1]
    # Zeminin macenta gücü ≥0,9'dur (sayfaların kenarındaki %1'lik dilim; üretim zemini düz değil, hafif dokuludur): 0,88'den
    # güçlü macenta tam saydam, tol'den zayıfı tam opaktır.
    tol, bg = 0.10, 0.88
    a_key = np.clip((bg - m) / (bg - tol), 0.0, 1.0)
    a = np.minimum(a0, a_key)
    # Renk çözme: gözlenen = a·ön + (1−a)·macenta → ön = (gözlenen − (1−a)·macenta) / a (yalnız anahtarın değdiği pikseller).
    key = np.array([1.0, 0.0, 1.0], dtype=np.float32)
    keyed = a_key < 0.999
    safe = np.maximum(a_key, 0.05)[..., None]
    fg = (rgb - (1.0 - a_key)[..., None] * key) / safe
    rgb = np.where(keyed[..., None], np.clip(fg, 0.0, 1.0), rgb)
    # Kalan pembelik: R ve B, G'nin çok üstündeyse ikisi de geri çekilir.
    spill = np.clip(np.minimum(rgb[..., 0], rgb[..., 2]) - rgb[..., 1] - 0.04, 0.0, None)
    rgb = rgb.copy()
    rgb[..., 0] -= spill
    rgb[..., 2] -= spill
    a = np.where(a < 0.04, 0.0, a)
    out = np.concatenate([np.clip(rgb, 0.0, 1.0), a[..., None]], axis=-1)
    return out


def _runs(mask_1d: np.ndarray, gap: int) -> list:
    idx = np.flatnonzero(mask_1d)
    if idx.size == 0:
        return []
    runs = []
    start = prev = idx[0]
    for i in idx[1:]:
        if i - prev > gap:
            runs.append((start, prev + 1))
            start = i
        prev = i
    runs.append((start, prev + 1))
    return runs


def pieces(img: np.ndarray) -> list:
    """Parçaların kutuları (x0, y0, x1, y1): önce satır bantları, bandın içinde sütun kesimleri, kutu yeniden daraltılır."""
    mask = img[..., 3] > 0.25
    out = []
    for y0, y1 in _runs(mask.any(axis=1), GAP):
        band = mask[y0:y1]
        for x0, x1 in _runs(band.any(axis=0), GAP):
            sub = band[:, x0:x1]
            rows = np.flatnonzero(sub.any(axis=1))
            if rows.size == 0:
                continue
            by0, by1 = y0 + rows[0], y0 + rows[-1] + 1
            if (x1 - x0) < MIN_PIECE or (by1 - by0) < MIN_PIECE:
                continue
            out.append((int(x0), int(by0), int(x1), int(by1)))
    return out


def _weights(n_in: int, n_out: int) -> np.ndarray:
    """Alan ortalamasının 1B ağırlıkları (n_out × n_in)."""
    w = np.zeros((n_out, n_in), dtype=np.float32)
    s = n_in / n_out
    for j in range(n_out):
        a, b = j * s, (j + 1) * s
        i0, i1 = int(np.floor(a)), int(np.ceil(b))
        for i in range(i0, min(i1, n_in)):
            w[j, i] = min(b, i + 1) - max(a, i)
        w[j] /= max(w[j].sum(), 1e-6)
    return w


def resize(img: np.ndarray, w: int, h: int) -> np.ndarray:
    a = img[..., 3:4]
    pre = np.concatenate([img[..., :3] * a, a], axis=-1)
    wy = _weights(img.shape[0], h)
    wx = _weights(img.shape[1], w)
    res = np.einsum("yi,ijc->yjc", wy, pre)
    res = np.einsum("xj,yjc->yxc", wx, res)
    alpha = res[..., 3:4]
    rgb = np.where(alpha > 1e-4, res[..., :3] / np.maximum(alpha, 1e-4), 0.0)
    return np.concatenate([rgb, alpha], axis=-1)


def bleed(img: np.ndarray, passes: int = 6) -> np.ndarray:
    """Saydam piksellere komşu opak pikselin rengini taşır (süzgeçli çizimde koyu kenar olmasın)."""
    out = img.copy()
    filled = out[..., 3] > 0.02
    for _ in range(passes):
        acc = np.zeros_like(out[..., :3])
        cnt = np.zeros(out.shape[:2], dtype=np.float32)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            shifted = np.roll(out[..., :3], (dy, dx), axis=(0, 1))
            ok = np.roll(filled, (dy, dx), axis=(0, 1))
            acc += shifted * ok[..., None]
            cnt += ok
        grow = (~filled) & (cnt > 0)
        out[..., :3] = np.where(grow[..., None], acc / np.maximum(cnt, 1)[..., None], out[..., :3])
        filled = filled | grow
    return out


def tint_glow(img: np.ndarray, tint: tuple) -> np.ndarray:
    """Yarı saydam ışığı (alfa < 0,85) altın tona çeker; parlaklığı korunur."""
    out = img.copy()
    a = out[..., 3]
    soft = (a < 0.85)[..., None]
    lum = out[..., :3].max(axis=-1, keepdims=True)
    gold = np.clip(np.array(tint, dtype=np.float32) * np.maximum(lum, 0.6), 0.0, 1.0)
    out[..., :3] = np.where(soft, gold, out[..., :3])
    return out


def soften_edges(img: np.ndarray, share: float) -> np.ndarray:
    """Kırpılan ışığın dikdörtgen sınırı görünmesin: alfa kenarlara doğru (genişliğin share'i) söner."""
    out = img.copy()
    h, w = out.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.minimum(np.minimum(xx, w - 1 - xx) / (w * share), np.minimum(yy, h - 1 - yy) / (h * share))
    soft = out[..., 3] < 0.85
    out[..., 3] = np.where(soft, out[..., 3] * np.clip(d, 0.0, 1.0), out[..., 3])
    return out


def fade_right(img: np.ndarray, start: float) -> np.ndarray:
    """Ad şeridi sağa doğru söner (referanstaki gibi): start'tan sonra renk o sütunun rengi, alfa doğrusal sıfıra."""
    out = img.copy()
    h, w = out.shape[:2]
    x0 = int(w * start)
    base = out[:, x0:x0 + 1, :3].copy()
    t = np.clip((np.arange(w, dtype=np.float32) - x0) / max(w - 1 - x0, 1), 0.0, 1.0)
    fade = 1.0 - t
    right = np.arange(w) >= x0
    out[:, right, :3] = np.broadcast_to(base, (h, int(right.sum()), 3))
    out[..., 3] *= fade[None, :]
    return out


def crop(img: np.ndarray, box: tuple, pad: int = PAD) -> np.ndarray:
    x0, y0, x1, y1 = box
    h, w = img.shape[:2]
    return img[max(y0 - pad, 0):min(y1 + pad, h), max(x0 - pad, 0):min(x1 + pad, w)]


def fit(img: np.ndarray, longest: int) -> np.ndarray:
    h, w = img.shape[:2]
    k = longest / max(h, w)
    if k >= 1.0:
        return img
    return resize(img, max(int(round(w * k)), 1), max(int(round(h * k)), 1))


def ring_metrics(img: np.ndarray) -> dict:
    """Halkanın merkezi ve yarıçapları: merkezden dışa 72 ışında ilk opak ve opaktan sonraki ilk saydam piksel (iç ve dış)."""
    a = img[..., 3]
    h, w = a.shape
    ys, xs = np.nonzero(a > 0.5)
    # Halkanın dış çemberi: süssüz yönlerdeki (köşegenler) en dış opak pikseller; merkez kutunun ortası yerine ışınlarla bulunur.
    cx, cy = (xs.min() + xs.max()) / 2.0, (ys.min() + ys.max()) / 2.0
    for _ in range(3):
        inner = []
        for t in np.linspace(0, 2 * np.pi, 72, endpoint=False):
            d = np.array([np.cos(t), np.sin(t)])
            r = 0.0
            while r < max(w, h):
                x, y = int(cx + d[0] * r), int(cy + d[1] * r)
                if not (0 <= x < w and 0 <= y < h):
                    break
                if a[y, x] > 0.5:
                    break
                r += 1.0
            inner.append((cx + d[0] * r, cy + d[1] * r))
        pts = np.array(inner)
        # En küçük kareler çember uydurması (iç kenar).
        A = np.column_stack([2 * pts[:, 0], 2 * pts[:, 1], np.ones(len(pts))])
        b = (pts ** 2).sum(axis=1)
        sol, *_ = np.linalg.lstsq(A, b, rcond=None)
        cx, cy = sol[0], sol[1]
        r_in = float(np.sqrt(sol[2] + cx ** 2 + cy ** 2))
    return {"center": [round(float(cx), 1), round(float(cy), 1)], "inner_radius": round(r_in, 1), "size": [w, h]}


def channel_metrics(img: np.ndarray) -> dict:
    """Çubuk çerçevesinin koyu kanalı: dikey ortadaki satırda ve sütunda koyu (lacivert) piksellerin aralığı."""
    rgb = img[..., :3]
    a = img[..., 3]
    lum = rgb.mean(axis=-1)
    dark = (lum < 0.28) & (a > 0.9)
    h, w = a.shape
    row = dark[h // 2]
    cols = np.flatnonzero(row)
    mid = int((cols[0] + cols[-1]) // 2) if cols.size else w // 2
    col = dark[:, mid]
    rows = np.flatnonzero(col)
    return {"size": [w, h], "channel_x": [int(cols[0]), int(cols[-1]) + 1] if cols.size else [0, w],
            "channel_y": [int(rows[0]), int(rows[-1]) + 1] if rows.size else [0, h]}


def main() -> int:
    list_only = "--list" in sys.argv
    metrics = {}
    for sheet, names in PLAN.items():
        img = key_magenta(read_png(SHEETS / f"{sheet}.png"))
        boxes = pieces(img)
        print(f"{sheet}: {len(boxes)} parça")
        for i, box in enumerate(boxes):
            name = names[i][0] if i < len(names) else "?"
            print(f"  {i}: {name} kutu={box} boy={box[2] - box[0]}x{box[3] - box[1]}")
        if list_only:
            continue
        for i, (name, longest) in enumerate(names):
            if name is None or i >= len(boxes):
                continue
            piece = crop(img, boxes[i])
            if name in GLOW_TINT:
                piece = soften_edges(tint_glow(piece, GLOW_TINT[name]), 0.08)
            if name == "inv_ribbon":
                piece = fade_right(piece, 0.5)
            piece = bleed(fit(piece, longest))
            write_png(OUT / f"{name}.png", piece)
            if name in ("portrait_ring", "map_ring"):
                metrics[name] = ring_metrics(piece)
            elif name in ("bar_frame", "xp_frame"):
                metrics[name] = channel_metrics(piece)
            else:
                metrics[name] = {"size": [piece.shape[1], piece.shape[0]]}
    if not list_only:
        # Büyük harita (M) halkası: aynı sayfanın tam çözünürlüklü kopyası (4K'de ≈1700 piksel çizilir).
        big = key_magenta(read_png(SHEETS / "map_frame.png"))
        piece = bleed(fit(crop(big, pieces(big)[0]), 1200))
        write_png(OUT / "map_ring_large.png", piece)
        metrics["map_ring_large"] = ring_metrics(piece)
        for sheet, (name, (x, y, side), size) in PORTRAITS.items():
            img = read_png(SHEETS / f"{sheet}.png")
            sq = img[y:y + side, x:x + side].copy()
            sq[..., 3] = 1.0
            sq = resize(sq, size, size)
            yy, xx = np.mgrid[0:size, 0:size]
            r = np.sqrt((xx + 0.5 - size / 2) ** 2 + (yy + 0.5 - size / 2) ** 2)
            sq[..., 3] = np.clip(size / 2 - r, 0.0, 1.0)
            write_png(OUT / f"{name}.png", sq)
            metrics[name] = {"size": [size, size]}
        (HERE / "metrics.json").write_text(json.dumps(metrics, indent=1, ensure_ascii=False) + "\n")
        print(json.dumps(metrics, indent=1, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
