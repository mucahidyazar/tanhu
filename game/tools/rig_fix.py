#!/usr/bin/env python3
"""
Meshy iskeletlerinin eklem hatalarını düzeltir ve her iskeletin sabit dönüş farkını ölçer. Kredi harcamaz, Meshy'yi çağırmaz.

Sorun (K92, /docs/development/asset-pipeline):
  - Meshy eklemleri uzun giysi ve zırh altında yanlış yere koyabilir: diz eklemi bacak çizgisinden 10-18 cm sapar (Baba, Ana,
    Ozan, Lan Hatun, Hereka 39, Hun Kadını) ve bacakta fazla yukarıda durur (uyluk/baldır Ana 0,84, sağlam iskelette 1,04-1,21),
    Mete'nin omurga eklemleri zırhın duvarlarına zikzak dizilir.
    Üst kol eklemi de bir yanda içeri kaçabilir (Mete'nin sol omzu 6,2 cm içeride ve yukarıda: üst kol 4,6 cm uzun, kol inince sol el
    sağdan 4 cm aşağıda).
  - Meshy iskeletinde parmak kemiği yoktur (24 kemik): el kapanmaz. Uzun giysi bacak kemiklerine katı bağlıdır: oturuşta etek davul gibi açılır.
  - Meshy klibi iskelete yazarken bu yanlış eklemlere göre sabit bir düzeltme ekler: klipte Δ_iskelet(t) = Δ_başvuru(t) · C.
    Eklem çizgisi düzelirken ağ da bükülür: bacakta çömelme ya da geriye dönük diz, gövdede bel kırığı.

Bu araç iki iş yapar:
  --apply: diz, omurga ve ayna farkı büyük omuz eklemlerini doğru yere taşır, kemiğin dinlenme yönünü klibin bıraktığı yöne çevirir ve
      ters bağ matrislerini yeniden yazar. Ağ ve doku değişmez; dosyanın ikili bölümünde ters bağ matrisleri ve taşınan kemiklerin sabit
      konum izleri değişir, taşınan omuzda köprücük ve üst kol geçişi yeni ekleme gelir. Dönüş izleri mutlak olduğu için klipler yeniden
      üretilmez. Hep ham iskeletten hesaplanır: aynı girdiyle yeniden çalıştırmak aynı dosyayı verir.
      Sıra hep aynıdır (K92): 1. eklemler ve ters bağ matrisleri, 2. ham ağırlık, 3. taşınan omuzun köprücük ve üst kol geçişi (öteki yanın aynası), 4. etek alanı
      (tools/garment_weights.py, data/garment_weights.json'daki kişide), 5. parmak kemikleri ve ağırlıkları (tools/hand_rig.py). Önceki koşunun parmakları önce çıkarılır, ağırlık hep hamdan
      yeniden kurulur: araç bir kez ya da on kez koşsa dosya aynıdır.
      6. Kendi yürüme ve koşmanın bacağı (2026-11-08, Huyan Hatun): Meshy yürümesi zincire görelidir, ham bacağı zincirinin %99,6'sına
      kadar açar ve kalçayı ona göre kaldırır. Diz çok taşınınca (Huyan Hatun: uyluk payı 0,425 → 0,52, zincir 82,8 → 77 cm) mutlak
      dönüşler bileği eski boylara göre koyar: kendi yürümenin bileği Meshy'nin zincir oranlı yolundan (yan ve ön-arka ortalaması F'ye
      gider) OWN_WALK_LIMIT_CM'den çok ayrışırsa bacak yeniden çözülür. Ayak yolu kendi kalça eklemine göre zincir oranıyla (düzeltilmiş /
      ham zincir) küçültülür, kalça bilek yüksekliği çevresinde aynı oranla iner, diz ClipRetarget'in iki kemikli çözümüyle ham dizin büküm
      yönüne kurulur, ayağın dünya dönüşü kalır. Çıktı ham klasörde bir kopyadır (assets/_meshy_raw/<id>/rig_fix/<id>_walking_armature.glb,
      _running_); ham dosyaya dokunulmaz. Oyunun <id>_walk.res ve <id>_run.res'i kalibrasyondan hemen önce bu kopyadan çıkarılır
      (tools/extract_animation.gd): prepare_character ham klipleri çıkardıktan sonra kalibrasyonu koşturduğu için kişi her yoldan tutarlı kalır.
      7. Kalça eklemi konum izinin çerçevesi (2026-11-08, Kujul): Meshy kimi iskelette kendi yürüme ve koşmanın uyluk konum izini (kalça
      ekleminin Hips'e göre yeri) yatık Hips'in dinlenme çerçevesinde değil, dünya hizasında yazar. Oyun izi Hips çerçevesinde okur: kalça
      eklemleri leğenden kayar, bacak kayan ekleme göre bükülür, bilek farkı F de bununla ölçülür. İz ham dinlenmeden HIP_TRACK_LIMIT_CM'den
      uzak, dünya hizasındaki bağ yerine yakınsa iz düzeltilmiş Hips çerçevesine çevrilir ve bacak 6. adımın çözümüyle Meshy'nin bileğine
      yeniden kurulur (kopya aynı rig_fix/ klasörüne). Kopya yalnız kalibrasyonu (C ve F) verir: Meshy bacağı kayık ekleme göre kurduğu için
      düzeltilen kalçada ön adımda bacak bükülür (Kujul: bilek taşıyıcının yürümesinden 5,7 cm yüksek). Kişinin kendi klibi kanonik
      sayılmaz (own_clips_canonical: false), oyunun yürüme ve koşması taşıyıcıdan aktarılır (character_fit_tool.gd --retarget).
  --calibrate: data/rig_calibration.json: her iskeletin kemik başına C'si ve bilek farkı F, kendi bedava yürüme klibinden (Meshy
      iskeletle birlikte verir; bacağı yeniden çözülen kişide kopyasından) başvuru iskeletininkiyle karşılaştırılarak. ClipRetarget kaynak
      ve hedef için bunu kullanır. Bacağı yeniden çözülen kişinin kendi klipleri önce kopyadan yeniden çıkarılır. Aynı dosyadaki limits,
      test_rig_health'in de okuduğu eşiklerdir: araçla sınama aynı ölçüyle karar verir.
      Kendi klibi Meshy'nin kanonik biçiminde olmayan iskelet (2026-11-08, Atşo): kadronun öteki 30 iskeletinde klip gövdede başvurunun
      hareketini sabit bir C ile verir (sapma 0,00°); Atşo'nun yürümesinde gövdenin sapması 2,3°, koşmasında 4,1°, kök %5,7 ve %9,6 alçak,
      sağ bacak zincirinin ancak 0,959'una açılır (kadroda 0,995-1,000). Gövde sapması CANONICAL_SPREAD_DEG'i aşan iskeletin gövde C'si
      dinlenme geometrisinden kestirilir (rest_rule: kadronun klip ölçülü iskeletlerinde bulunan kural), spread_deg kuralın o iskeletlerdeki
      en büyük hatasıdır, yürümedeki sapma walk_spread_deg'de kalır. Bilek farkı F de yürümeden ölçülmez: kanonik iskeletlerin ortancası
      (yürümeden ölçülen walk_feet'te kalır). Kaydına own_clips_canonical: false yazılır (7. adımın kişisine de): kendi yürüme ve koşması
      oyunda taşıyıcının yürüme ve koşmasından aktarılır (character_fit_tool.gd --retarget).

Kullanım (game/ klasöründe):
  python3 tools/rig_fix.py --report [id ...]       # ölçer, hiçbir şeyi değiştirmez; düzeltilmemiş sorun varsa çıkış kodu 1
  python3 tools/rig_fix.py --apply [id ...]        # GLB'leri düzeltir (id yoksa modeli olan herkes), sonra kalibrasyonu yazar
  python3 tools/rig_fix.py --calibrate             # kalibrasyonu yazar (bacağı yeniden çözülen kişinin kendi kliplerini önce kopyadan çıkarır)
Deneme için: --dir=<klasör> (<klasör>/<id>/<id>.glb; canlı kişi dosyalarına dokunmaz), --calibration=<dosya>.
Sonra içe aktarma gerekir: source tools/_godot_lock.sh && godot_import_locked
Aynı ağın doku çeşidi kendi iskeletini taşımaz: meta.json'una "variant_of": "<kaynak>" yazılır, ham iskeleti kaynağındır.
"""
import json
import math
import statistics
import os
import struct
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from glb_prepare import read_glb, write_glb  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHARACTERS = os.path.join(ROOT, "assets", "characters")
LIVE_CHARACTERS = CHARACTERS
RAW = os.path.join(ROOT, "assets", "_meshy_raw")
CALIBRATION_PATH = os.path.join(ROOT, "data", "rig_calibration.json")
GODOT = os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot")
# Başvuru iskeleti: omurga çizgisi tam düşey, C'si yok sayılır (Hips ve omurga C'si ≈ 0).
REFERENCE = "counter"
# Taşıyıcı: mesh'i yok, yalnız kaynak olarak kullanılır; düzeltilmez, kalibrasyonu ölçülür.
CARRIER = "_anim_library"
CARRIER_ARMATURE = "donor_walking_armature.glb"
# Sağlıklı iskelette diz, kalça-bilek çizgisinin önündedir (Mete 3,3, Kadın Kahraman 2,8, Hun Atlısı 2 cm; 1,7 m boya göre).
KNEE_FORWARD_CM_AT_170 = 2.5
# Diz bu kadar (cm) saparsa taşınır (iki bacak birlikte: sol ve sağ aynı kurala uysun).
KNEE_TOLERANCE_CM = 2.5
# Uyluğun bacak zincirindeki payı. Sağlam iskelette 0,51-0,55 (uyluk/baldır 1,04-1,21). Uzun giysi altında Meshy dizi yukarı da koyar
# (Ana 0,46, Ozan 0,45): bu pay altındaki bacakta diz THIGH_SHARE'e indirilir.
# 2026-11-08: 0,495 → 0,50 (Nanay'ın sağ uyluğu 0,499'du: diz çökmede diz kalça-bilek çizgisinin başında kalıyor, dizler kapanıyordu;
# sağlam aralık 0,51-0,55). Değişiklik yalnız Nanay ve Kujul'un iskeletine dokunur, kadronun kalanı ya 0,52'ye taşınmıştı ya 0,50'nin üstündedir.
THIGH_SHARE_MIN = 0.50
THIGH_SHARE = 0.52
# Omurga parçalarının (Hips'ten neck'e) düşeyden eğimleri arasındaki en büyük fark bundan büyükse zikzaktır. Sağlam iskelette 0-2,4.
SPINE_SPAN_LIMIT_DEG = 3.0
# Düz iskeletlerde omurga eklemlerinin Hips-neck çizgisi üzerindeki yeri (14 iskeletin ortancası).
SPINE_FRACTIONS = {"Spine02": 0.27, "Spine01": 0.54, "Spine": 0.82}
SPINE_GROUP = ("Spine02", "Spine01", "Spine")
# Düzeltilmiş iskelette iki bacak zinciri arasında izin verilen boy farkı (oran).
LEG_ASYMMETRY_LIMIT = 0.03
# Ham iskelette bacak farkı bundan büyükse Meshy'nin kendi yürüme ve koşması bir bacağı fazla büker: düzeltilmiş iskelete yeniden aktarılır
# (character_fit_tool.gd).
REBUILD_ASYMMETRY = 0.05
# Ayak ve parmakta bundan büyük sabit (derece) dinlenmeye taşınır: eski Meshy iskeletlerinin klipleri ayağı sabit bir açıyla
# kaldırır (Kadın Kahraman'ın kendi Bekleme 3'ünde parmak ucu 5 cm havada).
FOOT_CONSTANT_LIMIT_DEG = 8.0
FOOT_BONES = ("LeftFoot", "LeftToeBase", "RightFoot", "RightToeBase")
HIP_BONES = ("LeftUpLeg", "RightUpLeg")
# Üst kol ekleminin sol-sağ ayna farkı (cm, 1,7 m boya göre) bundan büyükse omuz yanlış yerdedir. Sağlam iskeletlerde 0,1-3,0, Mete'nin solu 5,8.
SHOULDER_ASYMMETRY_CM_AT_170 = 4.0
# Hangi yan yanlış: köprücüğün omuz zincirindeki payı (köprücük / (köprücük + üst kol)). 15 iskeletin ortancası; ondan uzak olan yan taşınır.
CLAVICLE_SHARE = 0.425
ARM_SIDES = ("Left", "Right")
# Kalibrasyon için yürüme klibinden alınan örnek sayısı.
SAMPLES = 33
FORWARD = (0.0, 0.0, 1.0)
# Düzeltilmiş iskelette kendi yürümenin bileği, Meshy'nin zincir oranlı ayak yolundan (yan ve ön-arka ortalaması F'ye gider) en çok bu
# kadar (cm) ayrışabilir; aşan kişide kendi yürüme ve koşmanın bacağı yeniden çözülür. test_rig_health'in ikiz sınamasıyla aynı eşik
# (TWIN_ANKLE_MAX): ayrışma o sınamada taşıyıcının aktarılan yürümesiyle farka döner. Kadroda en çok 3,9 (Ana); Huyan Hatun 5,4 (uyluk
# payı 0,425'ten 0,52'ye indi), yeniden çözülünce 0,7, ikiz sınaması 4,8 → 2,9 cm.
OWN_WALK_LIMIT_CM = 4.0
# Bacağı yeniden çözülen kendi klipler: (ham dosyanın adı, rol, klip adı); prepare_character'ın çıkardıklarıyla aynı.
OWN_CLIPS = (("walking", "walk", "Walk"), ("running", "run", "Run"))
# Yeniden çözülen kopyaların klasörü (assets/_meshy_raw/<id>/ altında; ham dosyalar değişmez).
RESOLVED_DIR = "rig_fix"
# ClipRetarget'in bacak çözümüyle aynı: bükülme yönü bundan kısa (iskelet birimi) kalırsa önden, zincirin bu payından sonra yumuşak uzama.
POLE_MIN = 0.5
SOFT_REACH = 0.97
# 7. adım: kendi klipte uyluk konum izi ham dinlenmeden bu kadar (cm) uzaksa ve dünya hizasındaki bağ yerine bu kadar yakınsa iz dünya
# hizasında yazılmıştır. Kadroda iz dinlenmeden 0-1,7 cm (hep Hips çerçevesinde); Kujul'da 9,1-9,2 cm, dünya hizasındaki bağ yerinden
# 1,1-1,3 cm (ham Hips 49,6° yatık, düzeltilmişi 29,3°): oyunda kalça eklemleri leğenden 6 cm kayıyor, F önde 4 cm çıkıyordu.
HIP_TRACK_LIMIT_CM = 3.0
# Kalibrasyon: kendi yürümede gövde kemiklerinin C sapması bundan büyükse (derece) klip Meshy'nin kanonik biçiminde değildir (kadronun
# öteki 30 iskeletinde 0,00; Atşo 2,32). test_rig_health'in gövde eşiğiyle aynı.
CANONICAL_SPREAD_DEG = 1.0
TORSO_BONES = ("Hips", "Spine02", "Spine01", "Spine", "neck", "Head")
# Dinlenme kuralı (rest_rule; 2026-11-08, gövde C'si klipte sabit 30 kişi ve taşıyıcı): Meshy'nin kanonik klibinde omurga (Spine02, Spine01,
# Spine) Spine02-neck çizgisini düşeye çeviren en kısa dönüşle, boyun ve baş dinlenme yönünde (C birim) oynar; Hips, Hips-Spine02
# parçasının öne eğiminin bu payı kadar geri döner (en küçük kareler; öne bileşenin hatası en çok 0,1°) ve bu kadar (derece) yana yatar.
# Yatışın dinlenmeden kestirilen bir karşılığı bulunmadı (kadroda -0,63 taşıyıcı … 0,94 Kantu): değer aralığın ortası, en büyük hatayı
# en küçük tutar. Kuralın en büyük hatası Hips 0,82° (taşıyıcı, Kantu), omurga 0,89° (Mete'nin zikzak ham omurgasında burulma), boyun ve
# baş 0,00°; kalibrasyon bunu her koşuda kanonik iskeletlerde yeniden ölçer ve kurala geçen kemiğin spread_deg'ine yazar.
REST_RULE_HIPS_SHARE = 0.413
REST_RULE_HIPS_ROLL_DEG = 0.15
COMP = {5126: "f", 5123: "H", 5125: "I", 5121: "B", 5122: "h", 5120: "b"}
NUM = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


# --- Küçük matematik (x, y, z, w) ----------------------------------------------------------------------------

def qmul(a, b):
    x1, y1, z1, w1 = a
    x2, y2, z2, w2 = b
    return (w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2, w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2,
            w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2, w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2)


def qconj(q):
    return (-q[0], -q[1], -q[2], q[3])


def qnorm(q):
    n = math.sqrt(sum(c * c for c in q)) or 1.0
    return tuple(c / n for c in q)


def qrot(q, v):
    u = q[:3]
    s = q[3]
    c = cross(u, v)
    d = dot(u, v)
    uu = dot(u, u)
    return tuple(2 * d * u[i] + (s * s - uu) * v[i] + 2 * s * c[i] for i in range(3))


def qangle_deg(q):
    return math.degrees(2 * math.atan2(math.sqrt(q[0] ** 2 + q[1] ** 2 + q[2] ** 2), abs(q[3])))


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def add(a, b):
    return tuple(x + y for x, y in zip(a, b))


def scale(a, s):
    return tuple(x * s for x in a)


def length(a):
    return math.sqrt(dot(a, a))


def unit(a):
    n = length(a) or 1.0
    return tuple(x / n for x in a)


def arc(a, b):
    """a yönünü b yönüne çeviren en kısa dönüş."""
    u, v = unit(a), unit(b)
    d = dot(u, v)
    if d > 0.999999:
        return (0.0, 0.0, 0.0, 1.0)
    if d < -0.999999:
        axis = cross(u, (1.0, 0.0, 0.0))
        if length(axis) < 1e-6:
            axis = cross(u, (0.0, 1.0, 0.0))
        axis = unit(axis)
        return (axis[0], axis[1], axis[2], 0.0)
    c = cross(u, v)
    return qnorm((c[0], c[1], c[2], 1.0 + d))


def trs_matrix(t, r, s):
    x, y, z, w = r
    m = [[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
         [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
         [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]]
    return [[m[0][0] * s[0], m[0][1] * s[1], m[0][2] * s[2], t[0]],
            [m[1][0] * s[0], m[1][1] * s[1], m[1][2] * s[2], t[1]],
            [m[2][0] * s[0], m[2][1] * s[1], m[2][2] * s[2], t[2]],
            [0.0, 0.0, 0.0, 1.0]]


def mat_mul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]


def affine_inverse(m):
    """Afin matrisin tersi (Gauss-Jordan)."""
    n = 4
    a = [row[:] + [1.0 if i == j else 0.0 for j in range(n)] for i, row in enumerate(m)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(a[r][c]))
        a[c], a[p] = a[p], a[c]
        d = a[c][c]
        a[c] = [v / d for v in a[c]]
        for r in range(n):
            if r != c:
                f = a[r][c]
                a[r] = [v - f * w for v, w in zip(a[r], a[c])]
    return [row[n:] for row in a]


# --- glTF ----------------------------------------------------------------------------------------------------

def read_accessor(doc, binary, index):
    acc = doc["accessors"][index]
    view = doc["bufferViews"][acc["bufferView"]]
    fmt = COMP[acc["componentType"]]
    num = NUM[acc["type"]]
    offset = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = view.get("byteStride", 0)
    size = struct.calcsize("<" + fmt) * num
    out = []
    for k in range(acc["count"]):
        out.append(struct.unpack_from("<%d%s" % (num, fmt), binary, offset + k * (stride or size)))
    return out


def write_accessor(doc, binary, index, values):
    acc = doc["accessors"][index]
    view = doc["bufferViews"][acc["bufferView"]]
    fmt = COMP[acc["componentType"]]
    num = NUM[acc["type"]]
    offset = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = view.get("byteStride", 0)
    size = struct.calcsize("<" + fmt) * num
    for k, value in enumerate(values):
        struct.pack_into("<%d%s" % (num, fmt), binary, offset + k * (stride or size), *value)
    # glTF, konum erişicisinde min/max ister; animasyon izi için de doğru kalsın.
    if "min" in acc and values:
        acc["min"] = [min(v[i] for v in values) for i in range(num)]
        acc["max"] = [max(v[i] for v in values) for i in range(num)]


class Rig:
    """glTF iskeleti: kemik adları, ebeveynler, yerel dinlenme dönüşümü. Konumlar Armature uzayında (Meshy'de cm)."""

    def __init__(self, doc):
        self.doc = doc
        nodes = doc["nodes"]
        skin = doc["skins"][0]
        self.joint_nodes = skin["joints"]
        self.names = [nodes[i]["name"] for i in self.joint_nodes]
        self.node_of = dict(zip(self.names, self.joint_nodes))
        parent = {}
        for i, node in enumerate(nodes):
            for c in node.get("children", []):
                parent[c] = i
        self.parent_node = parent
        joint_set = set(self.joint_nodes)
        self.parent = {}
        for name, node in self.node_of.items():
            p = parent.get(node)
            self.parent[name] = nodes[p]["name"] if p in joint_set else None
        self.local_t = {n: tuple(nodes[self.node_of[n]].get("translation", (0.0, 0.0, 0.0))) for n in self.names}
        self.local_r = {n: qnorm(tuple(nodes[self.node_of[n]].get("rotation", (0.0, 0.0, 0.0, 1.0)))) for n in self.names}
        self.local_s = {n: tuple(nodes[self.node_of[n]].get("scale", (1.0, 1.0, 1.0))) for n in self.names}
        self.order = []
        seen = set()

        def visit(name):
            if name in seen:
                return
            seen.add(name)
            if self.parent[name]:
                visit(self.parent[name])
            self.order.append(name)
        for n in self.names:
            visit(n)
        self.P, self.Q = {}, {}
        for n in self.order:
            p = self.parent[n]
            if p is None:
                self.P[n], self.Q[n] = self.local_t[n], self.local_r[n]
            else:
                self.P[n] = add(self.P[p], qrot(self.Q[p], self.local_t[n]))
                self.Q[n] = qnorm(qmul(self.Q[p], self.local_r[n]))

    def tilt(self, a, b):
        """a'dan b'ye parçanın düşeyden öne eğimi (derece; glTF ön +Z)."""
        d = sub(self.P[b], self.P[a])
        return math.degrees(math.atan2(d[2], d[1]))

    def spine_span(self):
        tilts = [self.tilt("Hips", "Spine02"), self.tilt("Spine02", "Spine01"), self.tilt("Spine01", "Spine"), self.tilt("Spine", "neck")]
        return max(tilts) - min(tilts)

    def thigh_share(self, side):
        """Uyluğun bacak zincirindeki payı."""
        h, k, a = self.P[side + "UpLeg"], self.P[side + "Leg"], self.P[side + "Foot"]
        thigh, shin = length(sub(k, h)), length(sub(a, k))
        return thigh / (thigh + shin)

    def knee(self, side):
        """Dizin kalça-bilek çizgisinden sapması: (öne cm, yana cm, zincir boyu, kalça-bilek)."""
        h, k, a = self.P[side + "UpLeg"], self.P[side + "Leg"], self.P[side + "Foot"]
        line = sub(a, h)
        u = unit(line)
        off = sub(sub(k, h), scale(u, dot(sub(k, h), u)))
        f = unit(sub(FORWARD, scale(u, dot(FORWARD, u))))
        s = unit(cross(u, f))
        return dot(off, f), dot(off, s), length(sub(k, h)) + length(sub(a, k)), length(line)


def mirror(p):
    """Düşey orta düzleme göre ayna (Meshy ağı x = 0'a ortalıdır)."""
    return (-p[0], p[1], p[2])


def arm_asymmetry(rig, bone="Arm"):
    """Kol zinciri ekleminin sol-sağ ayna farkı (iskelet birimi; Meshy'de cm)."""
    return length(sub(rig.P["Left" + bone], mirror(rig.P["Right" + bone])))


def clavicle_share(rig, side):
    """Köprücüğün omuz zincirindeki payı."""
    clavicle = length(sub(rig.P[side + "Arm"], rig.P[side + "Shoulder"]))
    upper = length(sub(rig.P[side + "ForeArm"], rig.P[side + "Arm"]))
    return clavicle / (clavicle + upper)


def height_of(doc):
    best = None
    for mesh in doc.get("meshes", []):
        for prim in mesh["primitives"]:
            acc = doc["accessors"][prim["attributes"]["POSITION"]]
            if "max" in acc:
                h = acc["max"][1] - acc["min"][1]
                best = max(best or 0.0, h)
    return best


def armature_path(rig_id):
    """İskeletin ham yürüme dosyası. Yoksa meta.json variant_of'un; o da yoksa kimin eksik olduğunu söyleyerek durur."""
    if rig_id == CARRIER:
        return os.path.join(RAW, CARRIER, CARRIER_ARMATURE)
    own = os.path.join(RAW, rig_id, "%s_walking_armature.glb" % rig_id)
    if os.path.exists(own):
        return own
    meta_file = os.path.join(CHARACTERS, rig_id, "meta.json")
    source = ""
    if os.path.exists(meta_file):
        with open(meta_file, encoding="utf-8") as fh:
            source = str(json.load(fh).get("variant_of") or "")
    if source:
        return armature_path(source)
    sys.exit("%s: ham iskelet yok (%s). Yeni kişi tools/prepare_character.py'den geçer; aynı ağın doku çeşidi meta.json'a \"variant_of\" yazar." % (rig_id, os.path.relpath(own, ROOT)))


def model_path(rig_id):
    return os.path.join(CHARACTERS, rig_id, rig_id + ".glb")


def raw_source_id(rig_id):
    """Ham dosyası olan kimlik: aynı ağın doku çeşidi kendi ham modelini taşımaz (meta.json variant_of)."""
    if os.path.isdir(os.path.join(RAW, rig_id)):
        return rig_id
    meta_file = os.path.join(CHARACTERS, rig_id, "meta.json")
    if os.path.exists(meta_file):
        with open(meta_file, encoding="utf-8") as fh:
            source = str(json.load(fh).get("variant_of") or "")
        if source:
            return raw_source_id(source)
    return rig_id


def clip_tracks(doc, binary):
    """Dosyanın ilk klibinin dönüş izleri: {kemik: (zamanlar, değerler)}."""
    anim = doc["animations"][0]
    nodes = doc["nodes"]
    out = {}
    for ch in anim["channels"]:
        target = ch["target"]
        if target.get("path") != "rotation" or "node" not in target:
            continue
        sampler = anim["samplers"][ch["sampler"]]
        times = [v[0] for v in read_accessor(doc, binary, sampler["input"])]
        values = [qnorm(v) for v in read_accessor(doc, binary, sampler["output"])]
        out[nodes[target["node"]].get("name")] = (times, values)
    return out


def sample(track, t):
    times, values = track
    if t <= times[0]:
        return values[0]
    if t >= times[-1]:
        return values[-1]
    lo, hi = 0, len(times) - 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if times[mid] <= t:
            lo = mid
        else:
            hi = mid
    f = (t - times[lo]) / (times[hi] - times[lo])
    a, b = values[lo], values[hi]
    if dot(a, b) < 0:
        b = tuple(-c for c in b)
    return qnorm(tuple(x * (1 - f) + y * f for x, y in zip(a, b)))


def clip_hip_offsets(doc, binary):
    """Dosyanın ilk klibinde uyluk köklerinin yerel konum izi: {kemik: (zamanlar, değerler)}. Meshy kimi iskelette kalça eklemini
    klipte dinlenmeden 0,4-1,7 cm oynatır; oyundaki .res klipleri bu izi taşır."""
    anim = doc["animations"][0]
    nodes = doc["nodes"]
    out = {}
    for ch in anim["channels"]:
        target = ch["target"]
        if target.get("path") != "translation" or "node" not in target:
            continue
        name = nodes[target["node"]].get("name")
        if name in HIP_BONES:
            sampler = anim["samplers"][ch["sampler"]]
            out[name] = ([v[0] for v in read_accessor(doc, binary, sampler["input"])], [tuple(v) for v in read_accessor(doc, binary, sampler["output"])])
    return out


def sample_vector(track, t):
    times, values = track
    if t <= times[0]:
        return values[0]
    if t >= times[-1]:
        return values[-1]
    lo, hi = 0, len(times) - 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if times[mid] <= t:
            lo = mid
        else:
            hi = mid
    f = (t - times[lo]) / (times[hi] - times[lo])
    return tuple(x * (1 - f) + y * f for x, y in zip(values[lo], values[hi]))


def clip_pose_globals(rig, tracks, t):
    """Klibin t anındaki kemik dünya dönüşleri (izi olmayan kemik dinlenme yönünde)."""
    G = {}
    for n in rig.order:
        local = sample(tracks[n], t) if n in tracks else rig.local_r[n]
        p = rig.parent[n]
        G[n] = local if p is None else qnorm(qmul(G[p], local))
    return G


def clip_length(tracks):
    return max(tr[0][-1] for tr in tracks.values())


def deltas_over_time(rig_rest, rig_struct, tracks, count=SAMPLES):
    """Her örnekte Δ = G(t) · Q_dinlenme⁻¹. rig_rest dinlenme yönlerini, rig_struct ağaç yapısını ve izsiz kemiği verir."""
    length_s = clip_length(tracks)
    out = []
    for i in range(count):
        G = clip_pose_globals(rig_struct, tracks, length_s * i / (count - 1))
        out.append({n: qnorm(qmul(G[n], qconj(rig_rest.Q[n]))) for n in rig_struct.names})
    return out


def mean_quat(quats):
    ref = quats[0]
    total = [0.0, 0.0, 0.0, 0.0]
    for q in quats:
        sign = -1.0 if dot(q, ref) < 0 else 1.0
        for i in range(4):
            total[i] += sign * q[i]
    return qnorm(tuple(total))


def clip_struct_names(rig):
    """Meshy'nin 24 kemiği: parmak kemikleri (LeftThumb1 ...) dışında kalanlar."""
    return [n for n in rig.names if not is_finger(n)]


def is_finger(name):
    return name.startswith(("LeftThumb", "LeftIndex", "LeftMiddle", "LeftRing", "LeftPinky", "RightThumb", "RightIndex", "RightMiddle", "RightRing", "RightPinky"))


def measure_constant(rest_a, struct_a, tracks_a, rest_ref, struct_ref, tracks_ref):
    """C = Δ_başvuru⁻¹ · Δ_iskelet (sağdan sabit) ve zamanla sapması (derece)."""
    da = deltas_over_time(rest_a, struct_a, tracks_a)
    db = deltas_over_time(rest_ref, struct_ref, tracks_ref)
    out = {}
    for n in struct_a.names:
        # Parmak kemiği kalibre edilmez: klip parmak izi taşımaz, poz HandGrip'ten gelir (tools/hand_rig.py).
        if n not in struct_ref.Q or n not in clip_struct_names(struct_a):
            continue
        qs = [qnorm(qmul(qconj(b[n]), a[n])) for a, b in zip(da, db)]
        m = mean_quat(qs)
        sd = max(qangle_deg(qmul(qconj(m), q)) for q in qs)
        out[n] = (m, sd)
    return out


def feet_over_time(rest, tracks, hips, count=SAMPLES):
    """Her örnekte bileklerin kalça eklemleri ortasına göre konumu ve kalçanın Δ'sı. Kemik boyları rest'ten (oyunda oynayan iskelet),
    dönüşler klipten: {"Left": v, "Right": v, "turn": q} listesi."""
    length_s = clip_length(tracks)
    out = []
    for i in range(count):
        t = length_s * i / (count - 1)
        G = clip_pose_globals(rest, tracks, t)
        P = {}
        for n in rest.order:
            p = rest.parent[n]
            offset = sample_vector(hips[n], t) if n in hips else rest.local_t[n]
            P[n] = (0.0, 0.0, 0.0) if p is None else add(P[p], qrot(G[p], offset))
        middle = scale(add(P["LeftUpLeg"], P["RightUpLeg"]), 0.5)
        out.append({"Left": sub(P["LeftFoot"], middle), "Right": sub(P["RightFoot"], middle), "turn": qnorm(qmul(G["Hips"], qconj(rest.Q["Hips"])))})
    return out


def leg_span(rest):
    """İki bacağın dinlenmedeki ortalama kalça-bilek uzaklığı."""
    return (length(sub(rest.P["LeftFoot"], rest.P["LeftUpLeg"])) + length(sub(rest.P["RightFoot"], rest.P["RightUpLeg"]))) / 2.0


def measure_feet(rest, tracks, hips, ref_rest, ref_tracks, ref_hips):
    """Bileğin kalça ortasına göre sabit farkı (F): bu iskeletin kendi klibinde, başvurununkine göre (kalça çerçevesinde, bu iskeletin
    biriminde). F'nin çoğu kalça eklemlerinin iskelete özgü yanal kaymasıdır (taşıyıcıda sağ bilek 5 cm dışarıda): düzeltilmezse aktarılan
    klipte bir bacak düzleşir, öteki bükülür. Yalnız yan ve ön-arka alınır: yükseklik farkı yürüyüşe özgüdür, ayakta kliplerde tabanı
    1,4 cm ayırıyordu. Dönüş: ({taraf: F}, {taraf: zamanla en büyük sapma}). Ölçek iki iskeletin bacak boyu oranıdır."""
    ratio = leg_span(rest) / leg_span(ref_rest)
    mine = feet_over_time(rest, tracks, hips)
    reference = feet_over_time(ref_rest, ref_tracks, ref_hips)
    offsets, spread = {}, {}
    for side in ("Left", "Right"):
        samples = [qrot(qconj(b["turn"]), sub(scale(a[side], 1.0 / ratio), b[side])) for a, b in zip(mine, reference)]
        samples = [(s[0], 0.0, s[2]) for s in samples]
        mean = scale(tuple(sum(s[i] for s in samples) for i in range(3)), 1.0 / len(samples))
        offsets[side] = [round(v * ratio, 3) for v in mean]
        spread[side] = round(max(length(sub(s, mean)) for s in samples) * ratio, 2)
    return offsets, spread


# --- Kendi yürüme ve koşmanın bacağı ----------------------------------------------------------------------------

def leg_chain(rig, side):
    """Bacak zincirinin boyu (uyluk + baldır, iskelet birimi)."""
    return length(sub(rig.P[side + "Leg"], rig.P[side + "UpLeg"])) + length(sub(rig.P[side + "Foot"], rig.P[side + "Leg"]))


def chain_ratios(fixed, raw):
    """Düzeltilmiş zincirin ham zincire oranı, yan başına. Meshy yürümesi zincire görelidir (her iskelette bacak zincirinin %99,6'sına
    kadar açılır, uzun ham zincirde kalça ona göre kalkar): düzeltilmiş iskelette ayak yolu bu oranla küçülür."""
    return {side: leg_chain(fixed, side) / leg_chain(raw, side) for side in ("Left", "Right")}


def legs_over_time(rest, tracks, hips, count=SAMPLES, base_hips=None):
    """Her örnekte bileğin kendi kalça eklemine göre konumu: {"Left": v, "Right": v} listesi (kemik boyları rest'ten, dönüşler klipten).
    base_hips verilirse bilek hips izleriyle kurulur, kalça eklemi base_hips izlerinden okunur (7. adım: Meshy'nin bileği düzeltilmiş
    kalça eklemine göre)."""
    length_s = clip_length(tracks)
    out = []
    for i in range(count):
        t = length_s * i / (count - 1)
        G = clip_pose_globals(rest, tracks, t)
        P = {}
        for n in rest.order:
            p = rest.parent[n]
            offset = sample_vector(hips[n], t) if n in hips else rest.local_t[n]
            P[n] = (0.0, 0.0, 0.0) if p is None else add(P[p], qrot(G[p], offset))
        base = {}
        for side in ("Left", "Right"):
            n = side + "UpLeg"
            base[side] = add(P[rest.parent[n]], qrot(G[rest.parent[n]], sample_vector(base_hips[n], t))) if base_hips and n in base_hips else P[n]
        out.append({side: sub(P[side + "Foot"], base[side]) for side in ("Left", "Right")})
    return out


def hip_track_frame(raw, fixed, hips):
    """7. adım: kendi klipteki uyluk konum izi dünya hizasında mı yazılmış? Öyleyse {kemik: (zamanlar, düzeltilmiş Hips çerçevesindeki
    değerler)}, değilse None. İz ham dinlenmeden HIP_TRACK_LIMIT_CM'den uzak ve dünya hizasındaki bağ yerine (eklemin Hips'e göre
    dünya farkı) bu kadar yakın olmalı; değerler düzeltilmiş iskeletin Hips dinlenme yönüne çevrilir: klipte Hips'in dönüşü
    Δ · Q_düzeltilmiş olduğundan kalça eklemi leğenle birlikte Δ · (bağ yeri) olur."""
    out = {}
    for n in HIP_BONES:
        if n not in hips:
            return None
        times, values = hips[n]
        if max(length(sub(v, raw.local_t[n])) for v in values) <= HIP_TRACK_LIMIT_CM:
            return None
        world = sub(raw.P[n], raw.P[raw.parent[n]])
        if max(length(sub(v, world)) for v in values) > HIP_TRACK_LIMIT_CM:
            return None
        inv = qconj(fixed.Q[fixed.parent[n]])
        out[n] = (times, [qrot(inv, v) for v in values])
    return out


def hip_frame_error(rig_id):
    """Kişinin ham yürümesinde uyluk konum izi dünya hizasında mı yazılmış (7. adım)? Öyleyse Meshy bacağı kayık kalça eklemine
    göre kurmuştur: kalça düzeltilince bilek ya yerinde kalır, bacak ön adımda bükülür (Kujul: bilek taşıyıcının yürümesinden 5,7 cm
    yüksek), ya bacakla taşınır, F 4 cm önde kalır (diz çökmede dizler kapanır). Kendi klibi kanonik sayılmaz: kopya yalnız kalibrasyonu
    (C ve F) verir, oyunun yürüme ve koşması taşıyıcıdan aktarılır."""
    if rig_id in (REFERENCE, CARRIER):
        return False
    walking = os.path.join(RAW, rig_id, "%s_walking_armature.glb" % rig_id)
    if not os.path.exists(walking):
        return False
    doc, binary = read_glb(walking)
    raw = Rig(doc)
    return hip_track_frame(raw, raw, clip_hip_offsets(doc, binary)) is not None


def hip_track_shift(raw, hips, frame):
    """Uyluk konum izinin düzeltmeyle en büyük kayması (cm, Hips'e göre dünya farkı; klibin sıfır pozunda)."""
    worst = 0.0
    for n, (_, values) in frame.items():
        for old, new in zip(hips[n][1], values):
            worst = max(worst, length(sub(old, new)))
    return worst


def own_walk_departure(raw, fixed, tracks, hips, own_tracks=None, own_hips=None, base_hips=None):
    """Düzeltilmiş iskelette kendi yürümenin bileği, Meshy'nin zincir oranlı ayak yolundan ne kadar ayrışıyor (cm, iki yanın en büyüğü):
    kalça eklemine göre; yan ve ön-arka ortalama fark (aktarımda F'ye gider) çıkarılır, yükseklik farkı kalır. tracks ve hips ham klibindir
    (Meshy'nin yolu); own_tracks verilmezse kendi yürüme ham klibin mutlak dönüşleridir. Diz taşınmayan iskelette 0. Huyan Hatun 5,4
    (uyluk payı 0,425 → 0,52); kadronun kalanı en çok 3,9 (Ana). base_hips (7. adım): Meshy'nin yolu düzeltilmiş kalça eklemine göre."""
    ratios = chain_ratios(fixed, raw)
    mine = legs_over_time(fixed, own_tracks or tracks, own_hips or hips)
    meshy = legs_over_time(raw, tracks, hips, base_hips=base_hips)
    worst = 0.0
    for side in ("Left", "Right"):
        diffs = [sub(a[side], scale(b[side], ratios[side])) for a, b in zip(mine, meshy)]
        mean = scale(tuple(sum(d[i] for d in diffs) for i in range(3)), 1.0 / len(diffs))
        mean = (mean[0], 0.0, mean[2])
        worst = max(worst, max(length(sub(d, mean)) for d in diffs))
    return worst


def soft_reach(distance, reach):
    """ClipRetarget._soft_reach: zincirin SOFT_REACH'ine kadar istenen uzaklık, sonrasında zincire üstel yaklaşır."""
    start = reach * SOFT_REACH
    if distance <= start:
        return distance
    room = reach - start
    return start + room * (1.0 - math.exp((start - distance) / room))


def resolved_path(rig_id, kind):
    """Bacağı yeniden çözülen kendi klibin kopyası: assets/_meshy_raw/<id>/rig_fix/ (--dir denemesinde <klasör>/<id>/rig_fix/)."""
    base = os.path.join(RAW, rig_id) if CHARACTERS == LIVE_CHARACTERS else os.path.join(CHARACTERS, rig_id)
    return os.path.join(base, RESOLVED_DIR, "%s_%s_armature.glb" % (rig_id, kind))


def own_clip_source(rig_id):
    """Kalibrasyonun ölçtüğü kendi yürüme: bacağı yeniden çözülmüşse kopyası, yoksa ham iskelet dosyası."""
    path = resolved_path(rig_id, "walking")
    return path if rig_id != CARRIER and os.path.exists(path) else armature_path(rig_id)


def fixed_rig(plan):
    """Planın düzeltilmiş iskeleti (ham yürüme dosyasının kopyasında) ve değişen kemiklerin yerel dinlenmesi."""
    import copy
    rig = plan["rig"]
    changed, _, _ = fixed_trs(plan)
    doc = copy.deepcopy(rig.doc)
    for n, (t, r) in changed.items():
        node = doc["nodes"][rig.node_of[n]]
        node["translation"] = [float(v) for v in t]
        node["rotation"] = [float(v) for v in r]
    return Rig(doc), changed


def resolve_legs(doc, binary, raw, fixed, changed, hip_frame=None):
    """Klibin bacak izlerini düzeltilmiş iskelete yeniden çözer; doc ve binary (bytearray) yerinde değişir. Her karede ayak, kendi kalça
    eklemine göre ham yolunun zincir oranı kadarına gider; kalça ortası bilek yüksekliği çevresinde (yanda ve önde dinlenme yeri
    çevresinde) aynı oranla iner: basan ayak bilek yüksekliğinde kalır. Bacak ClipRetarget._solve_leg ile kurulur: diz ham dizin büküm
    yönünde, uyluk ve baldır kendi eksenindeki burulmayı korur, ayağın dünya dönüşü kalır. Taşınan kemiklerin sabit konum izleri ve
    düğümleri düzeltilmiş dinlenmeye yazılır (çıkarılan klip yalnız dönüş ve kalça izi taşır).
    hip_frame (7. adım, hip_track_frame'in çıktısı): kalça eklemi düzeltilmiş izden kurulur ve iz klibe yazılır; bilek yine Meshy'nin
    (özgün izle kurulan) bileğidir, ayak yolu düzeltilmiş kalça eklemine göre zincir oranıyla küçülür."""
    nodes = doc["nodes"]
    anim = doc["animations"][0]
    samplers = {}
    for ch in anim["channels"]:
        target = ch["target"]
        if "node" in target:
            samplers[(nodes[target["node"]].get("name"), target.get("path"))] = anim["samplers"][ch["sampler"]]
    rot = {n: [qnorm(tuple(v)) for v in read_accessor(doc, binary, s["output"])] for (n, path), s in samplers.items() if path == "rotation"}
    pos = {n: [tuple(v) for v in read_accessor(doc, binary, s["output"])] for (n, path), s in samplers.items() if path == "translation"}
    count = len(rot["Hips"])
    if any(len(v) != count for v in list(rot.values()) + list(pos.values())):
        sys.exit("bacak yeniden çözülemedi: izlerin kare sayıları farklı")
    ratios = chain_ratios(fixed, raw)
    k = (ratios["Left"] + ratios["Right"]) / 2.0
    ankle_y = (raw.P["LeftFoot"][1] + raw.P["RightFoot"][1]) / 2.0
    rest_mid = scale(add(raw.P["LeftUpLeg"], raw.P["RightUpLeg"]), 0.5)
    legs = [s + n for s in ("Left", "Right") for n in ("UpLeg", "Leg", "Foot")]
    out = {n: list(rot[n]) for n in legs}
    root = next(n for n in raw.order if raw.parent[n] is None)
    root_track = list(pos[root])
    for i in range(count):
        local_r = {n: rot[n][i] if n in rot else raw.local_r[n] for n in raw.names}
        local_t = {n: pos[n][i] if n in pos else raw.local_t[n] for n in raw.names}
        G, P = {}, {}
        for n in raw.order:
            p = raw.parent[n]
            if p is None:
                G[n], P[n] = local_r[n], local_t[n]
            else:
                G[n] = qnorm(qmul(G[p], local_r[n]))
                P[n] = add(P[p], qrot(G[p], local_t[n]))
        # Kalça eklemi: 7. adımda düzeltilmiş izden (bilek ve dizin büküm yönü özgün izle kurulan Meshy pozundan kalır).
        H = dict(P)
        if hip_frame:
            for n, (_, values) in hip_frame.items():
                H[n] = add(P[raw.parent[n]], qrot(G[raw.parent[n]], values[i]))
        mid = scale(add(H["LeftUpLeg"], H["RightUpLeg"]), 0.5)
        new_mid = (rest_mid[0] + k * (mid[0] - rest_mid[0]), ankle_y + k * (mid[1] - ankle_y), rest_mid[2] + k * (mid[2] - rest_mid[2]))
        shift = sub(new_mid, mid)
        root_track[i] = add(pos[root][i], shift)
        hips_turn = qnorm(qmul(G[root], qconj(raw.Q[root])))
        for side in ("Left", "Right"):
            up, leg, foot = side + "UpLeg", side + "Leg", side + "Foot"
            thigh, shin = length(fixed.local_t[leg]), length(fixed.local_t[foot])
            hip = add(H[up], shift)
            goal = add(hip, scale(sub(P[foot], H[up]), ratios[side]))
            to_goal = sub(goal, hip)
            distance = max(soft_reach(length(to_goal), thigh + shin), abs(thigh - shin) * 1.001 + 0.001)
            along = unit(to_goal) if length(to_goal) > 1e-6 else (0.0, -1.0, 0.0)
            line = unit(sub(P[foot], P[up]))
            bend = sub(P[leg], P[up])
            pole = sub(bend, scale(line, dot(bend, line)))
            if length(pole) < POLE_MIN:
                pole = qrot(hips_turn, FORWARD)
            pole = sub(pole, scale(along, dot(pole, along)))
            pole = unit(pole) if length(pole) > 1e-6 else qrot(hips_turn, FORWARD)
            x = (thigh * thigh - shin * shin + distance * distance) / (2.0 * distance)
            height = math.sqrt(max(thigh * thigh - x * x, 0.0))
            knee = add(add(hip, scale(along, x)), scale(pole, height))
            ankle = add(hip, scale(along, distance))
            g_up = qnorm(qmul(arc(qrot(G[up], fixed.local_t[leg]), sub(knee, hip)), G[up]))
            g_leg = qnorm(qmul(arc(qrot(G[leg], fixed.local_t[foot]), sub(ankle, knee)), G[leg]))
            new = {up: qmul(qconj(G[raw.parent[up]]), g_up), leg: qmul(qconj(g_up), g_leg), foot: qmul(qconj(g_leg), G[foot])}
            for n, q in new.items():
                q = qnorm(q)
                # Komşu karelerle aynı yarı küre: ara değer kısa yoldan döner.
                if i > 0 and dot(q, out[n][i - 1]) < 0:
                    q = tuple(-c for c in q)
                out[n][i] = q
    for n in legs:
        write_accessor(doc, binary, samplers[(n, "rotation")]["output"], out[n])
    write_accessor(doc, binary, samplers[(root, "translation")]["output"], root_track)
    for n, (_, values) in (hip_frame or {}).items():
        write_accessor(doc, binary, samplers[(n, "translation")]["output"], [tuple(v) for v in values])
    for n, (t, r) in changed.items():
        node = nodes[raw.node_of[n]]
        node["translation"] = [float(v) for v in t]
        node["rotation"] = [float(v) for v in r]
        if (n, "translation") in samplers and n != root and n not in HIP_BONES:
            write_accessor(doc, binary, samplers[(n, "translation")]["output"], [tuple(t)] * count)


def resolve_own_clips(rig_id, plan):
    """Diz taşınınca kendi yürüme ve koşmanın bacağı gerekiyorsa (6. adım) ya da uyluk konum izi dünya hizasında yazılmışsa (7. adım)
    yeniden çözülür, kopyası yazılır (ham dosya değişmez). Gerekmiyorsa eski kopya silinir ve kalibrasyon ham klibe döner (oyunun .res'i
    prepare_character ham klibi yeniden çıkarana dek kalır, ikiz sınaması farkı gösterir). Notları döndürür."""
    notes = []
    walking = os.path.join(RAW, rig_id, "%s_walking_armature.glb" % rig_id)
    moved = any(side + "Leg" in plan["moves"] for side in ("Left", "Right"))
    departure = 0.0
    hip_frame = None
    if rig_id not in (REFERENCE, CARRIER) and os.path.exists(walking):
        fixed, changed = fixed_rig(plan)
        doc, binary = read_glb(walking)
        raw_tracks, raw_hips = clip_tracks(doc, binary), clip_hip_offsets(doc, binary)
        if moved:
            departure = own_walk_departure(plan["rig"], fixed, raw_tracks, raw_hips)
        hip_frame = hip_track_frame(plan["rig"], fixed, raw_hips)
    if departure <= OWN_WALK_LIMIT_CM and not hip_frame:
        for kind, _, _ in OWN_CLIPS:
            if os.path.exists(resolved_path(rig_id, kind)):
                os.remove(resolved_path(rig_id, kind))
        return notes
    ratios = chain_ratios(fixed, plan["rig"])
    shift = 0.0
    for kind, _, _ in OWN_CLIPS:
        src = os.path.join(RAW, rig_id, "%s_%s_armature.glb" % (rig_id, kind))
        if not os.path.exists(src):
            continue
        doc, binary = read_glb(src)
        raw = Rig(doc)
        if raw.names != plan["rig"].names or max(length(sub(raw.P[n], plan["rig"].P[n])) for n in raw.names) > 0.01:
            sys.exit("%s: %s iskeleti yürüme iskeletiyle aynı değil; bacak yeniden çözülemez" % (rig_id, os.path.basename(src)))
        frame = None
        if hip_frame:
            # Her klibin kendi izi: koşmanın izi yürümeninkiyle aynı çerçevede olmalı.
            own_hips = clip_hip_offsets(doc, binary)
            frame = hip_track_frame(raw, fixed, own_hips)
            if not frame:
                sys.exit("%s: %s'te uyluk konum izi yürümeninkiyle aynı çerçevede değil" % (rig_id, os.path.basename(src)))
            shift = max(shift, hip_track_shift(raw, own_hips, frame))
        binary = bytearray(binary)
        resolve_legs(doc, binary, raw, fixed, changed, frame)
        path = resolved_path(rig_id, kind)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        write_glb(path, doc, bytes(binary))
    doc, binary = read_glb(resolved_path(rig_id, "walking"))
    after = own_walk_departure(plan["rig"], fixed, raw_tracks, raw_hips, clip_tracks(doc, binary), clip_hip_offsets(doc, binary), hip_frame)
    # Yeniden çözülen yürüme zincir oranlı yoldan ancak yumuşak uzama kadar ayrılır; çok ayrışıyorsa çözüm yanlıştır.
    if after > 1.0:
        sys.exit("%s: yeniden çözülen yürüme zincir oranlı yoldan %.1f cm ayrışıyor" % (rig_id, after))
    if hip_frame:
        notes.append("kendi yürüme ve koşma: uyluk konum izi dünya hizasındaydı, Hips çerçevesine çevrildi (en çok %.1f cm); bacak Meshy'nin "
                     "bileğine zincir oranıyla yeniden çözüldü (sol %.3f, sağ %.3f; bilek yoldan %.1f cm) → %s (yalnız kalibrasyon; oyunun yürüme ve "
                     "koşması taşıyıcıdan: character_fit_tool.gd --retarget)" % (
                         shift, ratios["Left"], ratios["Right"], after, os.path.relpath(os.path.dirname(resolved_path(rig_id, "walking")), ROOT)))
    else:
        notes.append("kendi yürüme ve koşma: bacak zincir oranıyla yeniden çözüldü (sol %.3f, sağ %.3f; bilek yoldan %.1f → %.1f cm) → %s" % (
            ratios["Left"], ratios["Right"], departure, after, os.path.relpath(os.path.dirname(resolved_path(rig_id, "walking")), ROOT)))
    return notes


def extract_own_clips(ids):
    """Bacağı yeniden çözülen kişilerin oyundaki <id>_walk.res ve <id>_run.res'ini kopyadan çıkarır (tools/extract_animation.gd).
    Kalibrasyondan hemen önce koşar: prepare_character ham klipleri çıkardıktan sonra da oyun ve kalibrasyon aynı klibe bakar.
    --dir denemesinde canlı kişi dosyalarına yazılmaz."""
    if CHARACTERS != LIVE_CHARACTERS:
        return
    for rig_id in ids:
        # 7. adımın kopyası yalnız kalibrasyon içindir: oyunun yürüme ve koşması taşıyıcıdan (character_fit_tool.gd).
        if rig_id != CARRIER and hip_frame_error(rig_id):
            continue
        for kind, role, clip_name in OWN_CLIPS:
            src = resolved_path(rig_id, kind)
            if rig_id == CARRIER or not os.path.exists(src):
                continue
            stem = "%s_%s" % (rig_id, role)
            fresh = os.path.join(CHARACTERS, rig_id, stem + ".cozulen.res")
            result = subprocess.run([GODOT, "--headless", "--path", ROOT, "-s", "res://tools/extract_animation.gd", "--", src,
                                     "res://assets/characters/%s/%s.cozulen.res" % (rig_id, stem), clip_name], capture_output=True, text=True)
            line = [entry for entry in result.stdout.splitlines() if entry.startswith("[extract]")]
            if not line or not line[0].rstrip().endswith("hata=0") or not os.path.exists(fresh):
                if os.path.exists(fresh):
                    os.remove(fresh)
                sys.exit("%s/%s: yeniden çözülen klip çıkarılamadı\n%s" % (rig_id, role, result.stdout[-800:]))
            os.replace(fresh, os.path.join(CHARACTERS, rig_id, stem + ".res"))
            print("[rig_fix] %s/%s ← %s" % (rig_id, role, os.path.relpath(src, ROOT)))


# --- Plan ----------------------------------------------------------------------------------------------------

def plan_fix(rig_id):
    """Ham iskeletten düzeltme planı: {moves: {kemik: yeni konum}, turns: {kemik: dünya dönüşü}, notes: [...]}."""
    doc, binary = read_glb(armature_path(rig_id))
    rig = Rig(doc)
    model_doc, _ = read_glb(model_path(rig_id))
    height_m = height_of(model_doc) or 1.7
    moves, turns, notes = {}, {}, []
    shoulder_side = None
    target = KNEE_FORWARD_CM_AT_170 * height_m / 1.7
    need = False
    report = {}
    for side in ("Left", "Right"):
        fwd, lat, chain, span = rig.knee(side)
        report[side] = (fwd, lat, chain, span)
        if abs(fwd - target) > KNEE_TOLERANCE_CM or abs(lat) > KNEE_TOLERANCE_CM or rig.thigh_share(side) < THIGH_SHARE_MIN:
            need = True
    if need:
        for side in ("Left", "Right"):
            up, leg, foot = side + "UpLeg", side + "Leg", side + "Foot"
            h, k, a = rig.P[up], rig.P[leg], rig.P[foot]
            l1, l2 = length(sub(k, h)), length(sub(a, k))
            line = sub(a, h)
            u = unit(line)
            f = unit(sub(FORWARD, scale(u, dot(FORWARD, u))))
            share = l1 / (l1 + l2)
            k2 = add(add(h, scale(line, THIGH_SHARE if share < THIGH_SHARE_MIN else share)), scale(f, target))
            moves[leg] = k2
            turns[up] = arc(sub(k, h), sub(k2, h))
            turns[leg] = arc(sub(a, k), sub(a, k2))
            notes.append("%s diz %+.1f cm öne, %+.1f yana → %+.1f cm öne (zincir %.1f → %.1f cm)" % (
                side, report[side][0], report[side][1], target, l1 + l2, length(sub(k2, h)) + length(sub(a, k2))))
    # Omuz: üst kol eklemi öteki yanın aynasına taşınır (köprücüğü ortancadan uzak olan yan yanlıştır). Dirsek ve bilek yerinde kalır.
    if arm_asymmetry(rig) > SHOULDER_ASYMMETRY_CM_AT_170 * height_m / 1.7:
        wrong = max(ARM_SIDES, key=lambda side: abs(clavicle_share(rig, side) - CLAVICLE_SHARE))
        other = "Right" if wrong == "Left" else "Left"
        shoulder_side = wrong
        shoulder, arm, fore = wrong + "Shoulder", wrong + "Arm", wrong + "ForeArm"
        new_arm = mirror(rig.P[other + "Arm"])
        moves[arm] = new_arm
        turns[shoulder] = arc(sub(rig.P[arm], rig.P[shoulder]), sub(new_arm, rig.P[shoulder]))
        turns[arm] = arc(sub(rig.P[fore], rig.P[arm]), sub(rig.P[fore], new_arm))
        notes.append("%s omuz ayna farkı %.1f cm: eklem öteki yanın aynasına (üst kol %.1f → %.1f cm)" % (
            wrong, arm_asymmetry(rig), length(sub(rig.P[fore], rig.P[arm])), length(sub(rig.P[fore], new_arm))))
    ref_doc, ref_bin = read_glb(armature_path(REFERENCE))
    ref = Rig(ref_doc)
    constants = measure_constant(rig, rig, clip_tracks(doc, binary), ref, ref, clip_tracks(ref_doc, ref_bin))
    feet = [n for n in FOOT_BONES if qangle_deg(constants[n][0]) > FOOT_CONSTANT_LIMIT_DEG]
    if feet:
        for name in FOOT_BONES:
            turns[name] = constants[name][0]
        notes.append("ayak sabiti dinlenmeye taşındı (sol %.1f°, sağ %.1f°)" % (qangle_deg(constants["LeftFoot"][0]), qangle_deg(constants["RightFoot"][0])))
    if rig.spine_span() > SPINE_SPAN_LIMIT_DEG:
        hips, neck = rig.P["Hips"], rig.P["neck"]
        for name, frac in SPINE_FRACTIONS.items():
            moves[name] = add(hips, scale(sub(neck, hips), frac))
        # Dinlenme yönü: klibin içindeki sabit (C) dinlenmeye taşınır, klip başvurunun gövdesini oynatır.
        turns["Hips"] = constants["Hips"][0]
        spine = mean_quat([constants[n][0] for n in SPINE_GROUP])
        for name in SPINE_GROUP:
            turns[name] = spine
        notes.append("omurga zikzak (aralık %.1f°): eklemler Hips-neck çizgisine; Hips %.1f°, omurga %.1f° dinlenmeye taşındı" % (
            rig.spine_span(), qangle_deg(turns["Hips"]), qangle_deg(spine)))
    return {"rig": rig, "moves": moves, "turns": turns, "notes": notes, "height_m": height_m, "knees": report, "target_knee": target, "shoulder_side": shoulder_side}


def fixed_trs(plan):
    """Plandan yeni yerel dinlenme: {kemik: (t, r)} (yalnız değişenler) ve yeni dünya konum ve yönleri."""
    rig = plan["rig"]
    P = {n: plan["moves"].get(n, rig.P[n]) for n in rig.names}
    Q = {n: qnorm(qmul(plan["turns"][n], rig.Q[n])) if n in plan["turns"] else rig.Q[n] for n in rig.names}
    changed = {}
    for n in rig.order:
        p = rig.parent[n]
        if p is None:
            t2, r2 = P[n], Q[n]
        else:
            inv = qconj(Q[p])
            t2 = qrot(inv, sub(P[n], P[p]))
            r2 = qnorm(qmul(inv, Q[n]))
        old_t, old_r = rig.local_t[n], rig.local_r[n]
        if length(sub(t2, old_t)) > 1e-5 or qangle_deg(qmul(qconj(old_r), r2)) > 1e-4:
            changed[n] = (t2, r2)
    return changed, P, Q


# --- Uygulama ------------------------------------------------------------------------------------------------

def mirror_shoulder_weights(skin, dense, wrong):
    """Taşınan omuzun köprücük ve üst kol ağırlığı: toplamları kalır, paylaşımı öteki yanın aynadaki köşelerinden gelir. Meshy ağırlığı yanlış ekleme göre boyamıştır
    (Mete: geçiş solda x = 17, sağda 22 cm); eklem taşınıp ağırlık kalırsa eklemin içinde kalan köşeler kol inince yukarı kalkar, omuz kabarır."""
    import numpy as np
    other = "Right" if wrong == "Left" else "Left"
    shoulder, arm = skin.index[wrong + "Shoulder"], skin.index[wrong + "Arm"]
    o_shoulder, o_arm = skin.index[other + "Shoulder"], skin.index[other + "Arm"]
    total = dense[:, shoulder] + dense[:, arm]
    o_total = dense[:, o_shoulder] + dense[:, o_arm]
    targets = np.nonzero(total > 1e-4)[0]
    sources = np.nonzero(o_total > 1e-4)[0]
    keys, picks = np.unique(np.round(skin.pos[sources] * np.array([-1.0, 1.0, 1.0]), 5), axis=0, return_index=True)
    picks = sources[picks]
    share_source = dense[picks, o_arm] / o_total[picks]
    share = np.zeros(len(targets))
    for start in range(0, len(targets), 400):
        chunk = targets[start:start + 400]
        d2 = ((skin.pos[chunk][:, None, :] - keys[None, :, :]) ** 2).sum(2)
        near = np.argpartition(d2, 3, axis=1)[:, :4]
        d = np.sqrt(np.take_along_axis(d2, near, 1)) + 0.002
        w = 1.0 / d
        share[start:start + 400] = (share_source[near] * w).sum(1) / w.sum(1)
    dense[targets, arm] = total[targets] * share
    dense[targets, shoulder] = total[targets] * (1.0 - share)
    return targets


def finish_skin(rig_id, doc, binary, plan, garment=True, hands=True):
    """Köşe ağırlığı ve parmak kemikleri, sırayla: ham ağırlık, taşınan omuzun geçişi, etek alanı (tools/garment_weights.py), parmak kemikleri (tools/hand_rig.py). Hep hamdan
    hesaplanır: ağırlığın önceki koşudan kalanı okunmaz. doc yerinde değişir; yeni ikili bölümü ve notları döndürür."""
    import numpy as np
    import garment_weights
    import hand_rig
    import skin_data
    notes = []
    skin = skin_data.Skin(doc, binary)
    dense, raw = skin_data.raw_weights(raw_source_id(rig_id), read_glb, skin.names)
    if len(raw.pos) != len(skin.pos) or not np.array_equal(raw.pos, skin.pos):
        sys.exit("%s: ham modelin ağı oyun modeliyle aynı değil; ağırlık köşe sırasıyla taşınır" % rig_id)
    changed = np.zeros(len(skin.pos), bool)
    if plan["shoulder_side"]:
        changed[mirror_shoulder_weights(skin, dense, plan["shoulder_side"])] = True
    joint_pos = hand_rig.bind_positions(doc, binary, skin)
    welded = skin_data.Welded(skin.pos, skin.tris)
    if garment:
        dense, covered, note = garment_weights.apply(rig_id, skin, dense, joint_pos, welded)
        changed |= covered
        if note:
            notes.append(note)
    joints, weights = None, None
    if hands:
        binary, dense, touched, hand_notes = hand_rig.rig_hands(doc, binary, skin, dense, joint_pos, welded)
        changed |= touched
        notes += hand_notes
    joints, weights = skin_data.top_four(dense, raw.joints, raw.weights, ~changed)
    binary = bytearray(binary)
    skin_data.write_skin(doc, binary, joints, weights)
    return bytes(binary), notes


def apply_fix(rig_id, dry=False, garment=True, hands=True):
    path = model_path(rig_id)
    plan = plan_fix(rig_id)
    rig = plan["rig"]
    doc, binary = read_glb(path)
    # Önceki koşunun parmak kemikleri çıkar: iskelet hep 24 kemikten kurulur, sonra parmaklar bugünkü ele göre yeniden eklenir.
    import hand_rig
    binary = bytearray(hand_rig.strip_fingers(doc, binary))
    nodes = doc["nodes"]
    model = Rig(doc)
    if model.names != rig.names:
        missing = sorted(set(rig.names) ^ set(model.names))
        if set(rig.names) - set(model.names):
            sys.exit("%s: kemikler eşleşmiyor: %s" % (rig_id, missing))
    turned = [n for n in plan["turns"] if n in FOOT_BONES or n in SPINE_GROUP or n == "Hips"]
    left, right = rig.knee("Left")[2], rig.knee("Right")[2]
    if turned and abs(left - right) / min(left, right) > REBUILD_ASYMMETRY:
        # Kendi yürüme ve koşması ham dinlenmeden yeniden aktarılacak (rebuild_own_clips); döndürülmüş dinlenmede C'ler bunu bozar.
        sys.exit("%s: bacak farkı %%%.1f ile ayak ya da omurga düzeltmesi bir arada: bu araç bu birleşimi kurmaz" % (rig_id, 100.0 * abs(left - right) / min(left, right)))
    changed, _, _ = fixed_trs(plan)
    # 1. Yerel dinlenme: her kemik ham değerden yazılır (yeniden çalıştırma aynı dosyayı verir).
    for n in model.names:
        node = nodes[model.node_of[n]]
        t, r = changed.get(n, (rig.local_t.get(n), rig.local_r.get(n)))
        node["translation"] = [float(v) for v in t]
        node["rotation"] = [float(v) for v in r]
    # 2. Ters bağ matrisleri: yeni dünya matrisinin tersi.
    armature = [[1.0 if i == j else 0.0 for j in range(4)] for i in range(4)]
    hips_parent = model.parent_node.get(model.node_of[model.order[0]])
    chain = []
    while hips_parent is not None:
        chain.append(hips_parent)
        hips_parent = model.parent_node.get(hips_parent)
    for i in reversed(chain):
        node = nodes[i]
        armature = mat_mul(armature, trs_matrix(node.get("translation", (0, 0, 0)), node.get("rotation", (0, 0, 0, 1)), node.get("scale", (1, 1, 1))))
    world = {}
    for n in model.order:
        node = nodes[model.node_of[n]]
        local = trs_matrix(node["translation"], node["rotation"], node.get("scale", (1, 1, 1)))
        p = model.parent[n]
        world[n] = mat_mul(world[p] if p else armature, local)
    ibm = []
    for n in model.names:
        inv = affine_inverse(world[n])
        ibm.append(tuple(inv[r][c] for c in range(4) for r in range(4)))
    write_accessor(doc, binary, doc["skins"][0]["inverseBindMatrices"], ibm)
    # 3. Gömülü klipler: taşınan kemiğin sabit konum izi yeni dinlenmeye (yoksa eski konum yeni eklemi ezerdi).
    patched = 0
    for anim in doc.get("animations", []):
        for ch in anim["channels"]:
            target = ch["target"]
            if target.get("path") != "translation" or "node" not in target:
                continue
            name = nodes[target["node"]].get("name")
            if model.parent.get(name) is None:
                continue
            sampler = anim["samplers"][ch["sampler"]]
            values = read_accessor(doc, binary, sampler["output"])
            first = values[0]
            if max(length(sub(v, first)) for v in values) > 0.01:
                if name not in changed:
                    continue
                sys.exit("%s/%s: %s konum izi sabit değil; bu araç sabit izleri bekler" % (rig_id, anim.get("name"), name))
            # Düzeltilmeyen kemiğin izi de hamına döner: plan daralsa bile yeniden çalıştırma hamdan çalıştırmayla aynı konumları versin.
            if name not in changed and length(sub(first, rig.local_t[name])) < 1e-4:
                continue
            write_accessor(doc, binary, sampler["output"], [tuple(changed[name][0] if name in changed else rig.local_t[name])] * len(values))
            patched += 1 if name in changed else 0
    binary, skin_notes = finish_skin(rig_id, doc, bytes(binary), plan, garment, hands)
    plan["notes"] += skin_notes
    if not dry:
        write_glb(path, doc, binary)
        # 6. Kendi yürüme ve koşmanın bacağı (gerekirse; oyunun .res'i kalibrasyondan önce bu kopyadan çıkarılır).
        plan["notes"] += resolve_own_clips(rig_id, plan)
    return plan, changed, patched


def rest_rule(raw):
    """Gövde kemiklerinin dinlenme kuralına göre C'si (ham iskeletin dinlenmesine göre, dünya dönüşü): klibin sıfır pozu C · Q_ham.
    Omurga Spine02-neck çizgisini düşeye çeviren en kısa dönüş; boyun ve baş birim; Hips, Hips-Spine02 parçasının öne eğiminin
    REST_RULE_HIPS_SHARE'i kadar geri ve REST_RULE_HIPS_ROLL_DEG kadar yana (kemiğin kendi ekseni değil, eklemlerin yeri: Atşo'nun
    Hips'inin Y ekseni Spine02'den 100° sapar; kadronun kalanında 0°)."""
    spine = arc(sub(raw.P["neck"], raw.P["Spine02"]), (0.0, 1.0, 0.0))
    d = sub(raw.P["Spine02"], raw.P["Hips"])
    pitch = -REST_RULE_HIPS_SHARE * math.atan2(d[2], d[1])
    roll = math.radians(REST_RULE_HIPS_ROLL_DEG)
    angle = math.sqrt(pitch * pitch + roll * roll)
    s = math.sin(angle / 2.0) / angle if angle > 1e-12 else 0.5
    hips = qnorm((pitch * s, 0.0, roll * s, math.cos(angle / 2.0)))
    return {"Hips": hips, "Spine02": spine, "Spine01": spine, "Spine": spine, "neck": (0.0, 0.0, 0.0, 1.0), "Head": (0.0, 0.0, 0.0, 1.0)}


def is_canonical(entry):
    """Kendi klibi Meshy'nin kanonik biçiminde mi: gövde kemiklerinde C klip boyunca sabit."""
    return max(entry["spread_deg"][n] for n in TORSO_BONES) < CANONICAL_SPREAD_DEG


def rest_rule_error(rigs, zero_poses):
    """Dinlenme kuralının kanonik iskeletlerde (kendi klibi ölçülerek kalibre edilenler) en büyük hatası, kemik başına (derece)."""
    out = {}
    for n in TORSO_BONES:
        out[n] = round(max(qangle_deg(qmul(qconj(zero_poses[rid][n][1]), zero_poses[rid][n][0])) for rid in rigs if rid in zero_poses and is_canonical_measured(rigs[rid])), 2)
    return out


def is_canonical_measured(entry):
    """Kayıt kendi klibinden mi ölçüldü ve klip kanonik mi (dinlenme kuralına geçen kayıt walk_spread_deg taşır)."""
    return "walk_spread_deg" not in entry and is_canonical(entry)


def canonical_feet(rigs):
    """Kanonik iskeletlerin bilek farkı (F) ortancası, yan başına, ve ortancadan en büyük uzaklığı (cm). F dinlenme geometrisinden
    kestirilemiyor (yan bileşen 1,5, ön-arka 3,5 cm hatayla): kendi klibi kanonik olmayan iskelete kadronun ortancası verilir."""
    feet, spread = {}, {}
    entries = [e for rid, e in rigs.items() if is_canonical_measured(e)]
    for side in ("Left", "Right"):
        median = [round(statistics.median(e["feet"][side][i] for e in entries), 3) for i in range(3)]
        feet[side] = median
        spread[side] = round(max(length(sub(e["feet"][side], median)) for e in entries), 2)
    return feet, spread


def apply_rest_rule(rigs, zero_poses):
    """Kendi klibi kanonik olmayan iskeletin gövde C'si dinlenme kuralından (C = sıfır poz · Q_dinlenme⁻¹); spread_deg kuralın hatası,
    yürümedeki sapma walk_spread_deg'de kalır. Bilek farkı F kanonik iskeletlerin ortancası (feet_spread_cm: onların ortancadan en büyük
    uzaklığı), yürümeden ölçülen walk_feet'te kalır. own_clips_canonical: false. Başvuru ve taşıyıcı hep kendi klibinden."""
    error = rest_rule_error(rigs, zero_poses)
    feet, feet_spread = canonical_feet(rigs)
    for rig_id, entry in rigs.items():
        if rig_id in (REFERENCE, CARRIER) or is_canonical(entry):
            continue
        entry["walk_spread_deg"] = {n: entry["spread_deg"][n] for n in TORSO_BONES}
        for n in TORSO_BONES:
            _, rule_zero, rest_q = zero_poses[rig_id][n]
            entry["bones"][n] = [round(c, 6) for c in qnorm(qmul(rule_zero, qconj(rest_q)))]
            entry["spread_deg"][n] = error[n]
        entry["walk_feet"] = entry["feet"]
        entry["feet"] = {side: list(v) for side, v in feet.items()}
        entry["feet_spread_cm"] = dict(feet_spread)
        entry["own_clips_canonical"] = False


def calibrate(ids):
    # Bacağı yeniden çözülen kişinin oyundaki klipleri önce kopyadan: ölçülen F ve C oyunun oynattığı klibin olsun.
    extract_own_clips(ids)
    ref_doc, ref_bin = read_glb(armature_path(REFERENCE))
    ref_clip = Rig(ref_doc)
    ref_rest = Rig(read_glb(model_path(REFERENCE))[0])
    ref_tracks = clip_tracks(ref_doc, ref_bin)
    ref_hips = clip_hip_offsets(ref_doc, ref_bin)
    rigs = {}
    zero_poses = {}
    for rig_id in list(ids) + [CARRIER]:
        doc, binary = read_glb(armature_path(rig_id))
        clip = Rig(doc)
        rest = clip if rig_id == CARRIER else Rig(read_glb(model_path(rig_id))[0])
        walk_doc, walk_bin = read_glb(own_clip_source(rig_id)) if rig_id != CARRIER else (doc, binary)
        tracks, hips = clip_tracks(walk_doc, walk_bin), clip_hip_offsets(walk_doc, walk_bin)
        constants = measure_constant(rest, rest, tracks, ref_rest, ref_rest, ref_tracks)
        bones = {}
        spread = {}
        for name, (q, sd) in constants.items():
            bones[name] = [round(c, 6) for c in q]
            spread[name] = round(sd, 2)
        left, right = clip.knee("Left")[2], clip.knee("Right")[2]
        feet, feet_spread = measure_feet(rest, tracks, hips, ref_rest, ref_tracks, ref_hips)
        rigs[rig_id] = {"bones": bones, "spread_deg": spread, "feet": feet, "feet_spread_cm": feet_spread,
                        "rebuild_own_clips": abs(left - right) / min(left, right) > REBUILD_ASYMMETRY}
        if hip_frame_error(rig_id):
            rigs[rig_id]["own_clips_canonical"] = False
        # Klibin sıfır pozu (C · Q_dinlenme) ve dinlenme kuralınınki: kural kanonik iskeletlerde doğrulanır.
        rule = rest_rule(clip)
        zero_poses[rig_id] = {n: (qmul(constants[n][0], rest.Q[n]), qmul(rule[n], clip.Q[n]), rest.Q[n]) for n in TORSO_BONES}
    apply_rest_rule(rigs, zero_poses)
    data = {
        "_aciklama": "tools/rig_fix.py yazar; elle düzenlenmez. Her iskeletin kemik başına sabit dönüş farkı: klipte Δ_iskelet(t) = Δ_başvuru(t) · C (x, y, z, w; iskelet uzayı). Kendi bedava yürüme klibinden, başvuru iskeletininkiyle karşılaştırılarak ölçülür. ClipRetarget aktarırken kaynağınkini çıkarır, hedefinkini ekler: Δ_hedef = Δ_kaynak · C_kaynak⁻¹ · C_hedef. spread_deg: C'nin klip boyunca en büyük sapması; büyükse kemikte sabit bir fark yoktur (yeni iskeletlerde bacak). feet: bileğin iki kalça ekleminin ortasına göre sabit farkı (cm, kalça çerçevesinde, bu iskeletin biriminde); ClipRetarget ayak hedefinde kaynağınkini çıkarır, hedefinkini ekler. feet_spread_cm: klip boyunca en büyük sapması. rebuild_own_clips: ham iskeletin iki bacağı çok ayrışıyordu, yeni iskeletlerde Meshy klibi bacağı ona göre büktüğü için kişinin kendi yürüme ve koşması düzeltilmiş iskelete yeniden aktarılır (character_fit_tool.gd). Diz çok taşınan kişide (Huyan Hatun) ya da uyluk konum izi dünya hizasında yazılan kişide (Kujul) kendi yürüme ve koşmanın bacağı rig_fix'te yeniden çözülür (assets/_meshy_raw/<id>/rig_fix/): o kişinin C'si ve F'si bu kopyadan ölçülür. own_clips_canonical: false olan kişide kendi klibi Meshy'nin kanonik biçiminde değildir; oyunun yürüme ve koşması taşıyıcıdan aktarılır (character_fit_tool.gd --retarget). Uyluk konum izi dünya hizasında yazılan kişide (Kujul) C ve F 7. adımın kopyasındandır. Gövdede C'si sabit olmayan kişide (Atşo) gövde kemiklerinin (torso_bones) C'si dinlenme kuralından (rest_rule: omurga Spine02-neck çizgisini düşeye çeviren dönüş, boyun ve baş birim, Hips Hips-Spine02 eğiminin rest_rule_hips_share'i ve rest_rule_hips_roll_deg yatış), o kemiklerde spread_deg kuralın kanonik iskeletlerdeki en büyük hatası, walk_spread_deg yürümedeki sapmadır; feet kanonik iskeletlerin ortancası (feet_spread_cm onların ortancadan en büyük uzaklığı), walk_feet yürümeden ölçülendir.",
        "rest_rule": {"torso_bones": list(TORSO_BONES), "rest_rule_hips_share": REST_RULE_HIPS_SHARE, "rest_rule_hips_roll_deg": REST_RULE_HIPS_ROLL_DEG,
                      "error_deg": rest_rule_error(rigs, zero_poses)},
        "reference": REFERENCE,
        "limits": {"spine_span_deg": SPINE_SPAN_LIMIT_DEG, "knee_forward_cm_at_170": KNEE_FORWARD_CM_AT_170, "knee_tolerance_cm": KNEE_TOLERANCE_CM,
                   "leg_asymmetry": LEG_ASYMMETRY_LIMIT, "thigh_share_min": THIGH_SHARE_MIN, "foot_constant_deg": FOOT_CONSTANT_LIMIT_DEG,
                   "shoulder_asymmetry_cm_at_170": SHOULDER_ASYMMETRY_CM_AT_170},
        "rigs": rigs,
    }
    with open(CALIBRATION_PATH, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=1)
        fh.write("\n")
    print("[rig_fix] kalibrasyon: %d iskelet → %s" % (len(rigs), CALIBRATION_PATH))


def all_ids():
    return sorted(d for d in os.listdir(CHARACTERS) if os.path.exists(model_path(d)))


def report(ids):
    """Modelin bugünkü iskeletini ölçer. Sorun listesi (boşsa sağlıklı)."""
    problems = {}
    ref_doc, ref_bin = read_glb(armature_path(REFERENCE))
    ref_rest = Rig(read_glb(model_path(REFERENCE))[0])
    ref_tracks = clip_tracks(ref_doc, ref_bin)
    print("%-16s %6s %8s  %-22s %-22s %-12s %-12s %-22s %s" % ("kişi", "boy", "omurga°", "sol diz öne/yana", "sağ diz öne/yana", "bacak farkı", "uyluk payı", "omuz/dirsek farkı (cm)", "parmak kemiği"))
    for rig_id in ids:
        doc, _ = read_glb(model_path(rig_id))
        rig = Rig(doc)
        h = height_of(doc) or 1.7
        target = KNEE_FORWARD_CM_AT_170 * h / 1.7
        left, right = rig.knee("Left"), rig.knee("Right")
        issues = []
        if rig.spine_span() > SPINE_SPAN_LIMIT_DEG:
            issues.append("omurga zikzak %.0f°" % rig.spine_span())
        for side, k in (("sol", left), ("sağ", right)):
            if abs(k[0] - target) > KNEE_TOLERANCE_CM or abs(k[1]) > KNEE_TOLERANCE_CM:
                issues.append("%s diz %+.1f/%+.1f cm" % (side, k[0], k[1]))
        asym = abs(left[2] - right[2]) / min(left[2], right[2])
        if asym > LEG_ASYMMETRY_LIMIT:
            issues.append("bacak farkı %%%.1f" % (asym * 100))
        shares = (rig.thigh_share("Left"), rig.thigh_share("Right"))
        for side, share in zip(("sol", "sağ"), shares):
            if share < THIGH_SHARE_MIN:
                issues.append("%s diz yüksek (uyluk payı %.3f)" % (side, share))
        shoulder, elbow = arm_asymmetry(rig), arm_asymmetry(rig, "ForeArm")
        if shoulder > SHOULDER_ASYMMETRY_CM_AT_170 * h / 1.7:
            issues.append("omuz ayna farkı %.1f cm" % shoulder)
        fingers = [n for n in rig.names if is_finger(n)]
        left_count = len([n for n in fingers if n.startswith("Left")])
        if not fingers:
            issues.append("parmak kemiği yok")
        if left_count != len(fingers) - left_count:
            issues.append("parmak kemikleri simetrik değil (sol %d, sağ %d)" % (left_count, len(fingers) - left_count))
        clip_doc, clip_bin = read_glb(own_clip_source(rig_id))
        constants = measure_constant(rig, rig, clip_tracks(clip_doc, clip_bin), ref_rest, ref_rest, ref_tracks)
        walking = os.path.join(RAW, rig_id, "%s_walking_armature.glb" % rig_id)
        if rig_id not in (REFERENCE, CARRIER) and os.path.exists(walking) and own_clip_source(rig_id) == armature_path(rig_id):
            raw_doc, raw_bin = read_glb(walking)
            departure = own_walk_departure(Rig(raw_doc), rig, clip_tracks(raw_doc, raw_bin), clip_hip_offsets(raw_doc, raw_bin))
            if departure > OWN_WALK_LIMIT_CM:
                issues.append("kendi yürümesi zincir oranlı yoldan %.1f cm ayrı: bacağı yeniden çözülmeli (--apply)" % departure)
        for name in ("LeftFoot", "RightFoot"):
            if qangle_deg(constants[name][0]) > FOOT_CONSTANT_LIMIT_DEG:
                issues.append("%s sabiti %.1f°" % (name, qangle_deg(constants[name][0])))
        print("%-16s %6.2f %8.1f  %+6.1f %+6.1f %6.1f   %+6.1f %+6.1f %6.1f   %%%.1f  %.3f/%.3f  %.1f/%.1f  %2d  %s" % (
            rig_id, h, rig.spine_span(), left[0], left[1], left[2], right[0], right[1], right[2], asym * 100, shares[0], shares[1], shoulder, elbow, len(fingers), "; ".join(issues) or "sağlam"))
        if issues:
            problems[rig_id] = issues
    return problems


def use_paths(flags):
    """--dir ve --calibration: denemede canlı dosyalara dokunulmaz."""
    global CHARACTERS, CALIBRATION_PATH
    for flag in flags:
        if flag.startswith("--dir="):
            CHARACTERS = os.path.abspath(flag[len("--dir="):])
        elif flag.startswith("--calibration="):
            CALIBRATION_PATH = os.path.abspath(flag[len("--calibration="):])


def main():
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    use_paths(flags)
    ids = [a for a in sys.argv[1:] if not a.startswith("--")] or all_ids()
    if "--report" in flags:
        sys.exit(1 if report(ids) else 0)
    if "--apply" in flags:
        for rig_id in ids:
            plan, changed, patched = apply_fix(rig_id)
            print("[rig_fix] %s: %d kemik değişti, %d konum izi; %s" % (rig_id, len(changed), patched, " | ".join(plan["notes"]) or "eklem hatası yok"))
        calibrate(all_ids())
        return
    if "--calibrate" in flags:
        calibrate(all_ids())
        return
    sys.exit(__doc__)


if __name__ == "__main__":
    main()
