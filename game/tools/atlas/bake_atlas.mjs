#!/usr/bin/env node
// Atlasın dokularını ve kıvrımlı yollarını basar (godot.md §4.8): data/atlas/geography.json → assets/map/*.png, data/atlas/shapes.json.
// Kredi harcamaz, ağ kullanmaz; birkaç saniye sürer. Godot (hud_atlas.gdshader) bu dokuları her karede okur, yeniden üretmez.
//   node tools/atlas/bake_atlas.mjs
// Dokular (prototipin relief.js'i ve textures.js'i gibi):
//   atlas_nh.png     RGBA  R, G eğim (x, z; ±GMAX), B yükseklik (0..HMAX birim), A akış (ırmak ağı, log)
//   atlas_bio.png    RGBA  R orman, G kum, B taşlık, A yeşil güney
//   atlas_env.png    RGBA  R güneş gölgesi, G çukur-sırt (AO), B kıyıdan uzaklık (0,5 kıyı), A göl
//   atlas_river.png  gri   ırmaklar (membada ince, ağızda geniş)
//   atlas_cloud.png  RGBA  dikişsiz bulut gürültüsü: R düşük, G orta, B yüksek frekans
//   atlas_brush.png  RGBA  dikişsiz fırça darbeleri: R iri, G ince, B leke, A tek yönlü iz
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { clamp, lerp, pnoise2, rng, TAU } from './math.mjs';
import { organicPath } from './geo_paths.mjs';
import { generateRelief, makeGeo, riverPaths } from './relief_core.mjs';
import { writePng } from './png.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const GAME = resolve(HERE, '..', '..');
const json = JSON.parse(readFileSync(join(GAME, 'data', 'atlas', 'geography.json'), 'utf8'));
const geo = makeGeo(json);
const OUT = join(GAME, 'assets', 'map');

const relief = generateRelief(geo, (s) => process.stdout.write(`${s} `));
console.log(`\nkabartma ${relief.w}×${relief.d}, ${relief.ms} ms`);
writePng(join(OUT, 'atlas_nh.png'), relief.w, relief.d, 4, new Uint8Array(relief.nh.buffer));
writePng(join(OUT, 'atlas_bio.png'), relief.w, relief.d, 4, new Uint8Array(relief.bio.buffer));
writePng(join(OUT, 'atlas_env.png'), relief.w, relief.d, 4, new Uint8Array(relief.env.buffer));

// ---------- Irmaklar (relief.js riverTexture): yuvarlak uçlu kalın çizgi, kenarı yumuşak ----------
const paths = riverPaths();
{
  const W = 3584, H = Math.round((W * geo.MAP_D) / geo.MAP_W), K = W / geo.MAP_W;
  const buf = new Float32Array(W * H);
  const seg = (ax, ay, bx, by, r) => {
    const x0 = Math.max(0, Math.floor(Math.min(ax, bx) - r - 1)), x1 = Math.min(W - 1, Math.ceil(Math.max(ax, bx) + r + 1));
    const y0 = Math.max(0, Math.floor(Math.min(ay, by) - r - 1)), y1 = Math.min(H - 1, Math.ceil(Math.max(ay, by) + r + 1));
    const vx = bx - ax, vy = by - ay, l2 = vx * vx + vy * vy || 1;
    for (let y = y0; y <= y1; y++) {
      for (let x = x0; x <= x1; x++) {
        const px = x + 0.5, py = y + 0.5;
        const t = clamp(((px - ax) * vx + (py - ay) * vy) / l2);
        const d = Math.hypot(px - ax - vx * t, py - ay - vy * t);
        const c = clamp(r + 0.5 - d);
        if (c > buf[y * W + x]) buf[y * W + x] = c;
      }
    }
  };
  for (const { w, pts } of paths) {
    const n = pts.length;
    for (let i = 0; i < n - 1; i++) {
      const t = i / (n - 1);
      const lw = Math.max(0.9, w * 0.62 * lerp(0.3, 1, t));
      seg((pts[i][0] + geo.MAP_W / 2) * K, (pts[i][1] + geo.MAP_D / 2) * K, (pts[i + 1][0] + geo.MAP_W / 2) * K, (pts[i + 1][1] + geo.MAP_D / 2) * K, lw / 2);
    }
  }
  const out = new Uint8Array(W * H);
  for (let i = 0; i < out.length; i++) out[i] = Math.round(buf[i] * 255);
  writePng(join(OUT, 'atlas_river.png'), W, H, 1, out);
  console.log(`ırmaklar ${W}×${H}`);
}

// ---------- Bulut gürültüsü (textures.js makeCloudTexture, birebir) ----------
{
  const size = 256;
  const data = new Uint8Array(size * size * 4);
  for (let y = 0, i = 0; y < size; y++) {
    for (let x = 0; x < size; x++, i++) {
      const u = (x / size) * 4, v = (y / size) * 4;
      let lo = 0, a = 1, f = 1;
      for (let o = 0; o < 4; o++) {
        lo += a * pnoise2(u * f, v * f, 4 * f);
        a *= 0.5;
        f *= 2;
      }
      const mid = pnoise2((x / size) * 16, (y / size) * 16, 16) + 0.5 * pnoise2((x / size) * 32, (y / size) * 32, 32);
      const hi = pnoise2((x / size) * 64, (y / size) * 64, 64);
      data[i * 4] = clamp(128 + lo * 150, 0, 255);
      data[i * 4 + 1] = clamp(128 + mid * 150, 0, 255);
      data[i * 4 + 2] = clamp(128 + hi * 170, 0, 255);
      data[i * 4 + 3] = 255;
    }
  }
  writePng(join(OUT, 'atlas_cloud.png'), size, size, 4, data);
}

// ---------- Fırça darbeleri (textures.js makeBrushTexture'ın karşılığı): iki ucu sivrilen darbeler, dikişsiz ----------
function strokeField(size, count, lenLo, lenHi, widLo, widHi, seed, flow = 0) {
  const f = new Float32Array(size * size).fill(128);
  const r = rng(seed);
  for (let n = 0; n < count; n++) {
    const v = 30 + Math.floor(r() * 16) * 13;
    const alpha = r.range(0.25, 0.7);
    const cx = r() * size, cy = r() * size;
    const len = r.range(lenLo, lenHi), wid = r.range(widLo, widHi) * (0.85 + r() * 0.3);
    const ang = flow ? Math.sin(cx * 0.01 + seed) * flow + Math.cos(cy * 0.013) * flow + r.range(-0.4, 0.4) : r() * TAU;
    const ca = Math.cos(ang), sa = Math.sin(ang);
    const ext = len * 0.5 + wid;
    for (let y = Math.floor(cy - ext); y <= Math.ceil(cy + ext); y++) {
      for (let x = Math.floor(cx - ext); x <= Math.ceil(cx + ext); x++) {
        const dx = x + 0.5 - cx, dy = y + 0.5 - cy;
        const u = dx * ca + dy * sa, w = -dx * sa + dy * ca;
        const t = u / len + 0.5;
        if (t < 0 || t > 1) continue;
        const half = Math.sin(Math.PI * Math.min(1, t * 0.92 + 0.06)) * wid * 0.5;
        const c = clamp(half - Math.abs(w) + 0.5);
        if (c <= 0) continue;
        const k = (((y % size) + size) % size) * size + (((x % size) + size) % size);
        f[k] += (v - f[k]) * alpha * c;
      }
    }
  }
  return f;
}
{
  const size = 1024;
  const a = strokeField(size, 2600, 70, 210, 22, 60, 11);
  const b = strokeField(size, 9000, 18, 62, 6, 18, 23);
  const d = strokeField(size, 3000, 60, 180, 4, 11, 41, 0.6);
  const data = new Uint8Array(size * size * 4);
  const K = size / 8;
  for (let y = 0, i = 0; y < size; y++) {
    for (let x = 0; x < size; x++, i++) {
      const n = pnoise2(x / K, y / K, 8) + 0.5 * pnoise2((x / K) * 2, (y / K) * 2, 16);
      data[i * 4] = a[i];
      data[i * 4 + 1] = b[i];
      data[i * 4 + 2] = clamp(128 + n * 150, 0, 255);
      data[i * 4 + 3] = d[i];
    }
  }
  writePng(join(OUT, 'atlas_brush.png'), size, size, 4, data);
}

// ---------- Kıvrımlı yollar: siyasi sınırlar, ırmaklar, Çin Surları (harita birimi) ----------
{
  const r4 = (v) => Math.round(v * 10000) / 10000;
  const pts = (list) => list.map(([x, z]) => [r4(x), r4(z)]);
  const polities = {};
  for (const p of json.polities) if (p.poly) polities[p.id] = pts(organicPath(p, geo.toMap));
  const shapes = {
    doc: "Atlasın kıvrımlı yolları (bake_atlas.mjs; harita birimi, x doğu, z güney): siyasi sınırlar prototipin organicPath'ıyla, ırmaklar riverPaths'ıyla (aynı tohum), Çin Surları köşe noktalarıyla. HudMapPage siyasi katmanı bunlardan çizer, adları ve ırmak adlarını bunlara göre yerleştirir.",
    polities,
    rivers: paths.map((p) => ({ id: p.id, w: p.w, pts: pts(p.pts) })),
    wall: pts(json.wall.map(([lon, lat]) => geo.toMap(lon, lat))),
  };
  writeFileSync(join(GAME, 'data', 'atlas', 'shapes.json'), `${JSON.stringify(shapes)}\n`);
  console.log(`shapes.json: ${Object.keys(polities).length} sınır, ${paths.length} ırmak`);
}
