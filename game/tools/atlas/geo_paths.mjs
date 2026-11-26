// Atlasın kıvrımlı yolları (saf): ırmaklar ve siyasi sınırlar prototipin rng'li orta nokta kaydırmasıyla (src/map/relief-core.js
// riverPaths, src/map/relief.js organicPath); aynı tohum aynı kıvrımı verir, Godot bu sonucu data/atlas/shapes.json'dan okur.
import { rng } from './math.mjs';

// Harita: geography.json'un "map" bölümü (lon0, lon1, lat0, lat1, w, d).
export function makeToMap(map) {
  return (lon, lat) => [((lon - map.lon0) / (map.lon1 - map.lon0) - 0.5) * map.w, ((map.lat1 - lat) / (map.lat1 - map.lat0) - 0.5) * map.d];
}

// Irmaklar: düz çizgiler beş düzey orta nokta kaydırmasıyla kıvrılır (riverPaths, birebir).
export function riverPaths(rivers, toMap) {
  return rivers.map((river, n) => {
    const r = rng(n * 31 + 7);
    let pts = river.pts.map((p) => toMap(p[0], p[1]));
    let amp = 0.2;
    for (let level = 0; level < 5; level++) {
      const next = [pts[0]];
      for (let i = 0; i < pts.length - 1; i++) {
        const a = pts[i], b = pts[i + 1];
        const nx = -(b[1] - a[1]), nz = b[0] - a[0];
        const t = r.range(-1, 1) * amp;
        next.push([(a[0] + b[0]) / 2 + nx * t, (a[1] + b[1]) / 2 + nz * t], b);
      }
      pts = next;
      amp *= 0.92;
    }
    return { id: river.id, w: river.w, pts };
  });
}

// Siyasi sınır: kapalı çokgen dört düzey orta nokta kaydırmasıyla doğallaşır (organicPath, birebir; tohum kimlikten).
export function organicPath(p, toMap) {
  let seed = 7;
  for (const ch of p.id) seed = (seed * 31 + ch.charCodeAt(0)) >>> 0;
  const r = rng(seed);
  let pts = p.poly.map(([lon, lat]) => toMap(lon, lat));
  let amp = 0.09;
  for (let level = 0; level < 4; level++) {
    const next = [];
    for (let i = 0; i < pts.length; i++) {
      const a = pts[i], b = pts[(i + 1) % pts.length];
      next.push(a);
      const nx = -(b[1] - a[1]), nz = b[0] - a[0];
      const t = r.range(-1, 1) * amp;
      next.push([(a[0] + b[0]) / 2 + nx * t, (a[1] + b[1]) / 2 + nz * t]);
    }
    pts = next;
    amp *= 0.86;
  }
  return pts;
}
