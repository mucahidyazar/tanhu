#!/usr/bin/env python3
"""
Retexture çıktısının renk dokusunu iskeletli modele takar. Örnek: Önsöz'ün 39 yaşındaki Hereka'sı (hereka_young)
Hereka'nın ağını ve iskeletini kullanır, yalnız dokusu değişir (asset_plan.json: variant_of, retexture).

Meshy Retexture (enable_original_uv) kaynak modelin UV'lerini korur; iskelet görevi (rigging) de ağı ve UV'leri
korur. Araç önce iki GLB'nin UV kümelerini karşılaştırır (1/4096'ya nicelenmiş UV çiftlerinin örtüşmesi). Örtüşme
yeterliyse iskeletli GLB'nin temel renk görselini Retexture GLB'sininkiyle değiştirir; ağ, iskelet ve klipler
aynen kalır. Örtüşme düşükse hiçbir şey yazmaz ve 1 ile çıkar (o zaman varyant ayrıca iskeletlenmelidir).

Çeşit kadroya kendi kimliğiyle girecekse çıktı düzeltilmiş kaynak GLB'den alınır ve meta.json'una "variant_of": "<kaynak>" yazılır: kendi ham
iskeleti yoktur, tools/rig_fix.py kaynağınkini okur (K92).

Kullanım:
  python3 tools/glb_swap_texture.py <iskeletli.glb> <retexture.glb> <çıktı.glb> [--min-overlap=0.95]
"""
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from glb_prepare import read_glb, write_glb  # noqa: E402

FLOAT = 5126
QUANT = 4096.0


def _view_bytes(doc, binary, view_index):
    view = doc["bufferViews"][view_index]
    start = view.get("byteOffset", 0)
    return binary[start: start + view["byteLength"]], view.get("byteStride", 0)


def uv_set(doc, binary):
    """Bütün ilkellerin TEXCOORD_0 değerleri, nicelenmiş (u, v) kümesi olarak."""
    out = set()
    for mesh in doc.get("meshes", []):
        for prim in mesh.get("primitives", []):
            index = prim.get("attributes", {}).get("TEXCOORD_0")
            if index is None:
                continue
            acc = doc["accessors"][index]
            if acc.get("componentType") != FLOAT or acc.get("type") != "VEC2" or "bufferView" not in acc:
                continue
            data, stride = _view_bytes(doc, binary, acc["bufferView"])
            stride = stride or 8
            base = acc.get("byteOffset", 0)
            for i in range(acc["count"]):
                u, v = struct.unpack_from("<ff", data, base + i * stride)
                out.add((round(u * QUANT), round(v * QUANT)))
    return out


def base_color_image(doc):
    """İlk malzemenin temel renk görselinin sırası (yoksa None)."""
    for mat in doc.get("materials", []):
        tex = mat.get("pbrMetallicRoughness", {}).get("baseColorTexture")
        if tex is None:
            continue
        source = doc["textures"][tex["index"]].get("source")
        if source is not None:
            return source
    return None


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    if len(args) != 3:
        sys.exit(__doc__)
    rigged_path, retex_path, out_path = args
    min_overlap = float(opts.get("min-overlap", "0.95"))
    rig_doc, rig_bin = read_glb(rigged_path)
    tex_doc, tex_bin = read_glb(retex_path)
    a, b = uv_set(rig_doc, rig_bin), uv_set(tex_doc, tex_bin)
    if not a or not b:
        sys.exit("UV bulunamadı (iskeletli: %d, retexture: %d)" % (len(a), len(b)))
    overlap = len(a & b) / float(min(len(a), len(b)))
    print("[uv] iskeletli %d, retexture %d nokta; örtüşme %.3f (sınır %.2f)" % (len(a), len(b), overlap, min_overlap))
    if overlap < min_overlap:
        sys.exit("UV'ler örtüşmüyor: doku takılamaz, varyant ayrıca iskeletlenmeli.")
    rig_img, tex_img = base_color_image(rig_doc), base_color_image(tex_doc)
    if rig_img is None or tex_img is None:
        sys.exit("Temel renk dokusu bulunamadı (iskeletli: %s, retexture: %s)" % (rig_img, tex_img))
    new_blob, _ = _view_bytes(tex_doc, tex_bin, tex_doc["images"][tex_img]["bufferView"])
    views = rig_doc["bufferViews"]
    blobs = [rig_bin[v.get("byteOffset", 0): v.get("byteOffset", 0) + v["byteLength"]] for v in views]
    target_view = rig_doc["images"][rig_img]["bufferView"]
    old_len = len(blobs[target_view])
    blobs[target_view] = new_blob
    rig_doc["images"][rig_img]["mimeType"] = tex_doc["images"][tex_img].get("mimeType", "image/png")
    # BIN bölümünü yeniden diz: her bufferView 4 bayta hizalanır (glb_prepare.prepare ile aynı).
    out = bytearray()
    for v, blob in zip(views, blobs):
        out += b"\0" * ((4 - len(out) % 4) % 4)
        v["byteOffset"] = len(out)
        v["byteLength"] = len(blob)
        out += blob
    if rig_doc.get("buffers"):
        rig_doc["buffers"][0]["byteLength"] = len(out)
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    write_glb(out_path, rig_doc, bytes(out))
    print("[doku] %.1f MB → %.1f MB; %s yazıldı (%.1f MB)" % (old_len / 1e6, len(new_blob) / 1e6, out_path, os.path.getsize(out_path) / 1e6))


if __name__ == "__main__":
    main()
