#!/usr/bin/env python3
"""
Deri verisi yardımcıları (tools/rig_fix.py, garment_weights.py, hand_rig.py ortak kullanır): GLB'nin tek ilkelinin köşe konumları,
üçgenleri ve JOINTS_0/WEIGHTS_0'ı numpy dizisi olarak; ağırlığın ham dosyadan okunması ve dosyaya yazılması; aynı konumdaki köşelerin
(UV dikişi) kaynaştırılması ve ağırlık yumuşatma.

Ağırlıklar yoğun dizidir: köşe × eklem. Dosyaya yazarken her köşenin en büyük dört ağırlığı kalır, toplam 1'e normalize edilir; ham
değerinden ayrışmayan köşeler ham baytlarıyla kalır. Eklem bileşeni UNSIGNED_BYTE'tır (256 eklem), parmak kemikleri sığar.
"""
import json
import os
import struct

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAN_PATH = os.path.join(ROOT, "tools", "asset_plan.json")
RAW = os.path.join(ROOT, "assets", "_meshy_raw")
DTYPES = {5126: np.float32, 5123: np.uint16, 5125: np.uint32, 5121: np.uint8, 5122: np.int16, 5120: np.int8}
NUM = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def accessor_array(doc, binary, index):
    """Erişicinin verisi (kopya): adet × bileşen."""
    acc = doc["accessors"][index]
    view = doc["bufferViews"][acc["bufferView"]]
    offset = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    num = NUM[acc["type"]]
    dtype = DTYPES[acc["componentType"]]
    size = np.dtype(dtype).itemsize * num
    stride = view.get("byteStride", 0)
    if stride and stride != size:
        out = np.zeros((acc["count"], num), dtype)
        for k in range(acc["count"]):
            out[k] = np.frombuffer(binary, dtype, num, offset + k * stride)
        return out
    return np.frombuffer(binary, dtype, acc["count"] * num, offset).reshape(acc["count"], num).copy()


def write_array(doc, binary, index, values):
    """Erişicinin baytlarını yerinde yazar (binary: bytearray; boyut değişmez, adım yoksa)."""
    acc = doc["accessors"][index]
    view = doc["bufferViews"][acc["bufferView"]]
    offset = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    dtype = DTYPES[acc["componentType"]]
    if view.get("byteStride", 0) and view["byteStride"] != np.dtype(dtype).itemsize * NUM[acc["type"]]:
        raise ValueError("adımlı erişici desteklenmiyor")
    blob = np.asarray(values, dtype).tobytes()
    binary[offset:offset + len(blob)] = blob


def primitive(doc):
    """Kişinin tek ilkeli: Meshy kişisi tek ağ ve tek ilkeldir, başkası bu araçların alanı dışında."""
    meshes = doc.get("meshes", [])
    if len(meshes) != 1 or len(meshes[0]["primitives"]) != 1:
        raise ValueError("tek ağ, tek ilkel bekleniyordu (%d ağ)" % len(meshes))
    return meshes[0]["primitives"][0]


class Skin:
    """Bir GLB'nin ağı ve derisi: pos (metre), tris, joints, weights, names (skin eklem sırası)."""

    def __init__(self, doc, binary):
        prim = primitive(doc)
        attrs = prim["attributes"]
        self.pos = accessor_array(doc, binary, attrs["POSITION"]).astype(np.float64)
        self.tris = accessor_array(doc, binary, prim["indices"]).astype(np.int64).reshape(-1, 3)
        self.joints = accessor_array(doc, binary, attrs["JOINTS_0"]).astype(np.int64)
        self.weights = accessor_array(doc, binary, attrs["WEIGHTS_0"]).astype(np.float64)
        nodes = doc["nodes"]
        self.names = [nodes[i]["name"] for i in doc["skins"][0]["joints"]]
        self.index = {name: i for i, name in enumerate(self.names)}

    def dense(self, count=None):
        """Yoğun ağırlık: köşe × eklem (count verilirse fazladan boş sütun)."""
        out = np.zeros((len(self.pos), count or len(self.names)))
        np.put_along_axis(out, self.joints, self.weights, 1)
        return out


def raw_model_path(rig_id, plan=None):
    """Kişinin ham ana modeli (tools/prepare_character.py'nin kaynağı): ilk planlı klibin GLB'si, plansız kişide iskelet görevinin modeli."""
    if plan is None:
        with open(PLAN_PATH, encoding="utf-8") as fh:
            plan = json.load(fh)
    asset = next((a for a in plan["assets"] if a["id"] == rig_id), None)
    actions = asset.get("animations", []) if asset else []
    folder = os.path.join(RAW, rig_id)
    path = os.path.join(folder, "%s_animation_%d.glb" % (rig_id, actions[0])) if actions else os.path.join(folder, "%s_rigged_character.glb" % rig_id)
    return path


def raw_weights(rig_id, read_glb, names):
    """Ham dosyanın yoğun ağırlığı, names sırasıyla (ham dosyada olmayan eklem sütunu boş). Ham dosya yoksa durur: düzeltme hep hamdan hesaplanır."""
    path = raw_model_path(rig_id)
    if not os.path.exists(path):
        raise SystemExit("%s: ham model yok (%s); ağırlık düzeltmesi hamdan hesaplanır" % (rig_id, os.path.relpath(path, ROOT)))
    doc, binary = read_glb(path)
    skin = Skin(doc, binary)
    out = np.zeros((len(skin.pos), len(names)))
    dense = skin.dense()
    for i, name in enumerate(skin.names):
        out[:, names.index(name)] = dense[:, i]
    return out, skin


def top_four(dense, base_joints=None, base_weights=None, unchanged=None):
    """Yoğun ağırlıktan (joints, weights): en büyük dördü, toplam 1. unchanged True olan köşe base_* baytlarıyla kalır."""
    order = np.argsort(-dense, axis=1, kind="stable")[:, :4]
    weights = np.take_along_axis(dense, order, 1)
    total = weights.sum(1, keepdims=True)
    total[total <= 0.0] = 1.0
    weights = weights / total
    # Sıfır ağırlıklı yuvalar kemik 0'a düşer: glTF sıfır ağırlıkta eklem sırasını sormaz, ham dosyalar da böyledir.
    order = np.where(weights > 0.0, order, 0)
    if unchanged is not None:
        order[unchanged] = base_joints[unchanged]
        weights[unchanged] = base_weights[unchanged]
    return order, weights


def write_skin(doc, binary, joints, weights):
    """JOINTS_0 ve WEIGHTS_0'ı yerinde yazar (binary: bytearray)."""
    attrs = primitive(doc)["attributes"]
    write_array(doc, binary, attrs["JOINTS_0"], joints)
    write_array(doc, binary, attrs["WEIGHTS_0"], weights)


class Welded:
    """Aynı konumdaki köşeleri (UV dikişi) birleştiren çizge: kaynaşık köşeler ağırlıkta ayrışmasın, ağda yırtık açılmasın."""

    def __init__(self, pos, tris):
        _, inverse, counts = np.unique(np.round(pos, 5), axis=0, return_inverse=True, return_counts=True)
        self.of = np.asarray(inverse).ravel()
        self.count = len(counts)
        welded = self.of[tris]
        edges = np.concatenate([welded[:, [0, 1]], welded[:, [1, 2]], welded[:, [2, 0]]])
        edges = edges[edges[:, 0] != edges[:, 1]]
        self.edges = np.unique(np.sort(edges, axis=1), axis=0)

    def smooth(self, dense, mask, iterations=2, rate=0.5):
        """Ağırlığı mask > 0 köşelerde komşularına doğru yumuşatır (kaynaşık köşeler ortak değer alır). mask dışındaki köşeler aynen kalır."""
        columns = dense.shape[1]
        values = np.zeros((self.count, columns))
        hits = np.zeros(self.count)
        np.add.at(values, self.of, dense)
        np.add.at(hits, self.of, 1.0)
        values /= hits[:, None]
        reach = np.zeros(self.count)
        np.maximum.at(reach, self.of, mask)
        a, b = self.edges[:, 0], self.edges[:, 1]
        for _ in range(iterations):
            total = np.zeros_like(values)
            degree = np.zeros(self.count)
            np.add.at(total, a, values[b])
            np.add.at(total, b, values[a])
            np.add.at(degree, a, 1.0)
            np.add.at(degree, b, 1.0)
            degree[degree == 0.0] = 1.0
            share = (rate * reach)[:, None]
            values = values * (1.0 - share) + (total / degree[:, None]) * share
        out = values[self.of]
        keep = mask <= 0.0
        out[keep] = dense[keep]
        return out


def smooth_step(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)
