#!/usr/bin/env python3
"""
Menü referans görüntüsündeki (assets/_reference/menu_camp.png, 1672x941) bir pikselin dünyadaki yerini bulur:
menü kamerasından (tools/menu_camera_fit.json) o piksele giden ışın zemine (y = verilen yükseklik) indirilir.
Ayrıca bir dünya noktasının görüntüdeki pikselini de hesaplar (kontrol için).

Kullanım:
  python3 tools/menu_backproject.py px <u> <v> [y]       # piksel → dünya (x, z)
  python3 tools/menu_backproject.py world <x> <y> <z>    # dünya → piksel (u, v)
"""
import json
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAM = json.load(open(os.path.join(ROOT, "tools", "menu_camera_fit.json"), encoding="utf-8"))
W, H = CAM["image_size"]
POS = CAM["position"]
PITCH = math.radians(CAM["pitch_deg"])
VF = math.radians(CAM["vfov_deg_16_9"])
T = math.tan(VF / 2.0)
TA = T * W / H


def ray(u, v):
    x = (u / W * 2.0 - 1.0) * TA
    y = (1.0 - v / H * 2.0) * T
    # Kamera yaw=0: yalnızca X ekseninde eğim (pitch); d = Rx(pitch) * (x, y, -1).
    cy, sy = math.cos(PITCH), math.sin(PITCH)
    dx = x
    dy = y * cy - (-1.0) * sy
    dz = y * sy + (-1.0) * cy
    n = math.sqrt(dx * dx + dy * dy + dz * dz)
    return dx / n, dy / n, dz / n


def to_world(u, v, ground_y=0.0):
    dx, dy, dz = ray(u, v)
    s = (ground_y - POS[1]) / dy
    return POS[0] + dx * s, POS[2] + dz * s


def to_pixel(x, y, z):
    rx, ry, rz = x - POS[0], y - POS[1], z - POS[2]
    cy, sy = math.cos(PITCH), math.sin(PITCH)
    # Kamera uzayına: Rx(-pitch) uygula.
    vx = rx
    vy = ry * cy + rz * sy
    vz = -ry * sy + rz * cy
    u = ((vx / -vz) / TA * 0.5 + 0.5) * W
    v = (0.5 - (vy / -vz) / T * 0.5) * H
    return u, v


if __name__ == "__main__":
    if len(sys.argv) >= 4 and sys.argv[1] == "px":
        gy = float(sys.argv[4]) if len(sys.argv) > 4 else 0.0
        x, z = to_world(float(sys.argv[2]), float(sys.argv[3]), gy)
        print("dünya x=%.2f z=%.2f (y=%.2f)" % (x, z, gy))
    elif len(sys.argv) == 5 and sys.argv[1] == "world":
        u, v = to_pixel(float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4]))
        print("piksel u=%.0f v=%.0f" % (u, v))
    else:
        sys.exit(__doc__)
