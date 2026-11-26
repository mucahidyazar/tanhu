// Atlasın yeryüzü üreticisi (prototipin src/map/relief-core.js'inden; godot.md §4.8): dağ kuşakları, akarsu erozyonu, ırmak ağları,
// biyomlar ve güneş gölgesi. Saf hesap; tools/atlas/bake_atlas.mjs koşar, dokular assets/map/ altına basılır.
// Prototipten farkları: coğrafya data/atlas/geography.json'dan gelir (makeGeo), kampın gölü yerine evlerin (homes.*.carve) gölü
// oyulur: Godot'nun kamp dünyasının vadisi ve gölü (terrain_shape.gd) haritada aynı yerdedir. Gerisi birebirdir (aynı tohum, aynı sonuç).
import { clamp, fbm2, lerp, noise2, ridge2, rng, smooth } from './math.mjs';
import { makeToMap, riverPaths as riverPathsOf } from './geo_paths.mjs';

export const RW = 1536;
// Doku kodlama aralıkları: yükseklik (harita birimi) ve eğim.
export const HMAX = 0.7, GMAX = 3;
// Haritanın sabit güneşi: kuzeybatıdan alçak açıyla.
export const SUN = (() => {
  const v = [-0.68, 0.46, -0.42];
  const l = Math.hypot(...v);
  return v.map((a) => a / l);
})();
// Kabartma yükseklik çarpanı: dağlar gerçeğe göre abartılı ama masal gibi değil.
const VS = 0.5;

// geography.json → üreticinin tabloları (prototipin geography.js adlarıyla).
export function makeGeo(json) {
  const m = json.map;
  const toMap = makeToMap(m);
  return {
    toMap, MAP_W: m.w, MAP_D: m.d, SEA: json.sea, ISLANDS: json.islands, LAKES: json.lakes, RANGES: json.ranges, PLATEAUS: json.plateaus,
    DESERTS: json.deserts, FORESTS: json.forests, LUSH: json.lush, PLAINS: json.plains, RIVERS: json.rivers,
    HOMES: Object.values(json.homes).filter((h) => h.carve).map((h) => ({ at: toMap(h.lonlat[0], h.lonlat[1]), carve: h.carve })),
  };
}

let G = null;
let MAP_W = 1, MAP_D = 1, RD = 1;
let UNITS_PER_DEG_LAT = 1, UNITS_PER_DEG_LON = 1, Z_AT_LAT0 = 0;
let toMap = null;
const latAt = (z) => (Z_AT_LAT0 - z) / UNITS_PER_DEG_LAT;
function useGeo(geo) {
  G = geo;
  ({ MAP_W, MAP_D, toMap } = geo);
  RD = Math.round((RW * MAP_D) / MAP_W);
  UNITS_PER_DEG_LAT = toMap(0, 0)[1] - toMap(0, 1)[1];
  UNITS_PER_DEG_LON = toMap(1, 0)[0] - toMap(0, 0)[0];
  Z_AT_LAT0 = toMap(0, 0)[1];
}
export const riverPaths = () => riverPathsOf(G.RIVERS, toMap);

// Kurulum adımları (yalnız günlük).
const STEP = { coast: 'coast', mountains: 'mountains', rivers: 'rivers', valleys: 'valleys', slopes: 'slopes', biomes: 'biomes', done: 'done' };

// ---------- Izgara yardımcıları ----------

const gridX = (i, w) => (i / (w - 1) - 0.5) * MAP_W;
const gridZ = (j, d) => (j / (d - 1) - 0.5) * MAP_D;
const toGrid = (w, d) => ([lon, lat]) => {
  const [x, z] = toMap(lon, lat);
  return [(x / MAP_W + 0.5) * (w - 1), (z / MAP_D + 0.5) * (d - 1)];
};

// Çokgen doldurma (tek-çift kuralı).
function fillPoly(out, w, d, poly, map = toGrid(w, d)) {
  const P = poly.map(map);
  let y0 = Infinity, y1 = -Infinity;
  for (const p of P) {
    y0 = Math.min(y0, p[1]);
    y1 = Math.max(y1, p[1]);
  }
  const hits = [];
  for (let j = Math.max(0, Math.ceil(y0)); j <= Math.min(d - 1, Math.floor(y1)); j++) {
    hits.length = 0;
    for (let k = 0; k < P.length; k++) {
      const a = P[k], b = P[(k + 1) % P.length];
      if ((a[1] <= j && b[1] > j) || (b[1] <= j && a[1] > j)) hits.push(a[0] + ((j - a[1]) / (b[1] - a[1])) * (b[0] - a[0]));
    }
    hits.sort((p, q) => p - q);
    for (let k = 0; k + 1 < hits.length; k += 2) {
      const i0 = Math.max(0, Math.ceil(hits[k])), i1 = Math.min(w - 1, Math.floor(hits[k + 1]));
      for (let i = i0; i <= i1; i++) out[j * w + i] = 1;
    }
  }
  return out;
}

function polyMask(polys, w, d) {
  const m = new Float32Array(w * d);
  for (const p of polys) fillPoly(m, w, d, p);
  return m;
}

// Yinelenen kutu bulanıklığı.
function blur(a, w, h, r, passes = 2) {
  if (r < 1) return a;
  const t = new Float32Array(a.length);
  const norm = 1 / (2 * r + 1);
  for (let p = 0; p < passes; p++) {
    for (let j = 0; j < h; j++) {
      let s = 0;
      const row = j * w;
      for (let i = -r; i <= r; i++) s += a[row + clamp(i, 0, w - 1)];
      for (let i = 0; i < w; i++) {
        t[row + i] = s * norm;
        s += a[row + Math.min(w - 1, i + r + 1)] - a[row + Math.max(0, i - r)];
      }
    }
    for (let i = 0; i < w; i++) {
      let s = 0;
      for (let j = -r; j <= r; j++) s += t[clamp(j, 0, h - 1) * w + i];
      for (let j = 0; j < h; j++) {
        a[j * w + i] = s * norm;
        s += t[Math.min(h - 1, j + r + 1) * w + i] - t[Math.max(0, j - r) * w + i];
      }
    }
  }
  return a;
}

function upsample(a, w0, d0, w1, d1) {
  const out = new Float32Array(w1 * d1);
  for (let j = 0, k = 0; j < d1; j++) {
    const fz = (j / (d1 - 1)) * (d0 - 1);
    const j0 = Math.min(d0 - 2, Math.floor(fz)), v = fz - j0;
    for (let i = 0; i < w1; i++, k++) {
      const fx = (i / (w1 - 1)) * (w0 - 1);
      const i0 = Math.min(w0 - 2, Math.floor(fx)), u = fx - i0;
      const q = j0 * w0 + i0;
      out[k] = lerp(lerp(a[q], a[q + 1], u), lerp(a[q + w0], a[q + w0 + 1], u), v);
    }
  }
  return out;
}

// Gürültüyle yırtılmış doğal kenar: bulanık maskeyi eşikler.
function naturalEdge(m, w, d, r, amp, freq, soft = 0.05, seed = 0) {
  const b = blur(Float32Array.from(m), w, d, r);
  const out = new Float32Array(w * d);
  for (let j = 0, k = 0; j < d; j++) {
    const z = gridZ(j, d);
    for (let i = 0; i < w; i++, k++) {
      const v = b[k];
      if (v < 0.01 || v > 0.99) { out[k] = v > 0.5 ? 1 : 0; continue; }
      const x = gridX(i, w);
      out[k] = smooth(0.5 - soft, 0.5 + soft, v + fbm2(x * freq + seed, z * freq - seed, 4) * amp);
    }
  }
  return out;
}

// ---------- Akarsu erozyonu ----------

const SQ2 = Math.SQRT2;

// Taban noktalarından taşan su yolları (priority flood) ve akarsu aşındırması (Braun ve Willett).
function erode(h, T, w, d, cell, seed, hard, iters, { K, relax, slopeMax, diffuse }) {
  const N = w * d;
  const order = new Int32Array(N), recv = new Int32Array(N), A = new Float32Array(N), fl = new Float32Array(N), rd = new Float32Array(N);
  const seen = new Uint8Array(N);
  // Küme.
  const heapI = new Int32Array(N + 8), heapK = new Float32Array(N + 8);
  let hs = 0;
  const push = (idx, key) => {
    let i = hs++;
    while (i > 0) {
      const p = (i - 1) >> 1;
      if (heapK[p] <= key) break;
      heapK[i] = heapK[p];
      heapI[i] = heapI[p];
      i = p;
    }
    heapK[i] = key;
    heapI[i] = idx;
  };
  const pop = () => {
    const top = heapI[0];
    hs--;
    if (hs > 0) {
      const key = heapK[hs], idx = heapI[hs];
      let i = 0;
      for (;;) {
        let c = 2 * i + 1;
        if (c >= hs) break;
        if (c + 1 < hs && heapK[c + 1] < heapK[c]) c++;
        if (heapK[c] >= key) break;
        heapK[i] = heapK[c];
        heapI[i] = heapI[c];
        i = c;
      }
      heapK[i] = key;
      heapI[i] = idx;
    }
    return top;
  };
  // Tabanın kıyısı: kuyruk yalnız buradan başlar.
  const frontier = [];
  for (let j = 0, k = 0; j < d; j++) {
    for (let i = 0; i < w; i++, k++) {
      const edge = i === 0 || j === 0 || i === w - 1 || j === d - 1;
      if (edge) seed[k] = 1;
    }
  }
  for (let j = 1; j < d - 1; j++) {
    for (let i = 1; i < w - 1; i++) {
      const k = j * w + i;
      if (seed[k] && (!seed[k - 1] || !seed[k + 1] || !seed[k - w] || !seed[k + w])) frontier.push(k);
    }
  }
  const off = [-1, 1, -w, w, -w - 1, -w + 1, w - 1, w + 1];
  const dist = [cell, cell, cell, cell, cell * SQ2, cell * SQ2, cell * SQ2, cell * SQ2];
  const area = cell * cell;

  for (let it = 0; it < iters; it++) {
    // Yollar her adımda yeniden bulunur.
    seen.fill(0);
    let cnt = 0;
    hs = 0;
    for (let k = 0; k < N; k++) {
      if (seed[k]) {
        seen[k] = 1;
        recv[k] = -1;
        fl[k] = h[k];
      }
    }
    for (const k of frontier) push(k, fl[k]);
    // Kenardaki taban hücreleri de suyu alır.
    for (let i = 1; i < w - 1; i++) {
      for (const [k, r] of [[w + i, i], [(d - 2) * w + i, (d - 1) * w + i]]) {
        if (!seen[k]) {
          seen[k] = 1;
          recv[k] = r;
          rd[k] = cell;
          fl[k] = h[k];
          push(k, fl[k]);
        }
      }
    }
    for (let j = 1; j < d - 1; j++) {
      for (const [k, r] of [[j * w + 1, j * w], [j * w + w - 2, j * w + w - 1]]) {
        if (!seen[k]) {
          seen[k] = 1;
          recv[k] = r;
          rd[k] = cell;
          fl[k] = h[k];
          push(k, fl[k]);
        }
      }
    }
    while (hs > 0) {
      const c = pop();
      if (!seed[c]) order[cnt++] = c;
      const key = fl[c];
      const x = c % w, y = (c - x) / w;
      if (x === 0 || y === 0 || x === w - 1 || y === d - 1) continue;
      for (let q = 0; q < 8; q++) {
        const n = c + off[q];
        if (seen[n]) continue;
        seen[n] = 1;
        recv[n] = c;
        rd[n] = dist[q];
        const f = h[n] > key ? h[n] : key + 1e-6;
        fl[n] = f;
        push(n, f);
      }
    }

    // Akış birikimi: membadan mansaba.
    A.fill(1);
    for (let k = cnt - 1; k >= 0; k--) {
      const i = order[k], r = recv[i];
      if (r >= 0) A[r] += A[i];
    }

    // Örtük akarsu aşındırması: mansaptan membaya.
    for (let k = 0; k < cnt; k++) {
      const i = order[k], r = recv[i];
      if (r < 0) continue;
      const hr = h[r];
      if (h[i] <= hr) continue;
      const f = (K * hard[i] * Math.sqrt(A[i] * area)) / rd[i];
      let v = (h[i] + f * hr) / (1 + f);
      const top = hr + slopeMax * rd[i];
      if (v > top) v = top;
      h[i] = v;
    }

    // Yamaç yayılması ve dağ yükselmesi.
    if (diffuse > 0) {
      for (let k = 0; k < cnt; k++) {
        const i = order[k];
        const x = i % w, y = (i - x) / w;
        if (x === 0 || y === 0 || x === w - 1 || y === d - 1) continue;
        h[i] += ((h[i - 1] + h[i + 1] + h[i - w] + h[i + w]) * 0.25 - h[i]) * diffuse;
      }
    }
    if (relax > 0 && it < iters - 1) {
      for (let k = 0; k < cnt; k++) {
        const i = order[k];
        h[i] += (T[i] - h[i]) * relax;
      }
    }
  }
  return A;
}

// ---------- Üretim ----------

// Kaba ızgarada dağ kuşaklarının taban yüksekliği. Alan kıvrılır: sıralar cetvelle çizilmiş gibi durmaz.
function rangeField(w, d) {
  const out = new Float32Array(w * d);
  const map = toGrid(w, d);
  // Kuşak genişliği enlem derecesidir.
  const pxPerDeg = (UNITS_PER_DEG_LAT / MAP_D) * (d - 1);
  const pxPerKm = (w - 1) / MAP_W;
  const warpX = new Float32Array(w * d), warpZ = new Float32Array(w * d);
  for (let j = 0, k = 0; j < d; j++) {
    const z = gridZ(j, d);
    for (let i = 0; i < w; i++, k++) {
      const x = gridX(i, w);
      warpX[k] = (fbm2(x * 0.17 + 40, z * 0.17 + 9, 4) * 1.5 + fbm2(x * 0.62 + 3, z * 0.62, 2) * 0.35) * pxPerKm;
      warpZ[k] = (fbm2(x * 0.17 - 13, z * 0.17 + 51, 4) * 1.5 + fbm2(x * 0.62, z * 0.62 + 8, 2) * 0.35) * pxPerKm;
    }
  }
  const reach = 2.2 * pxPerKm;
  for (const r of G.RANGES) {
    const P = r.pts.map(map);
    const hw = (r.w * 1.5 * pxPerDeg) / 2 + 2;
    let x0 = Infinity, x1 = -Infinity, y0 = Infinity, y1 = -Infinity;
    for (const q of P) {
      x0 = Math.min(x0, q[0]); x1 = Math.max(x1, q[0]);
      y0 = Math.min(y0, q[1]); y1 = Math.max(y1, q[1]);
    }
    const i0 = Math.max(0, Math.floor(x0 - hw - reach)), i1 = Math.min(w - 1, Math.ceil(x1 + hw + reach));
    const j0 = Math.max(0, Math.floor(y0 - hw - reach)), j1 = Math.min(d - 1, Math.ceil(y1 + hw + reach));
    for (let j = j0; j <= j1; j++) {
      for (let i = i0; i <= i1; i++) {
        const k = j * w + i;
        const px = i + warpX[k], py = j + warpZ[k];
        let best = 1e9;
        for (let q = 0; q < P.length - 1; q++) {
          const a = P[q], b = P[q + 1];
          const vx = b[0] - a[0], vy = b[1] - a[1], l2 = vx * vx + vy * vy || 1;
          const t = clamp(((px - a[0]) * vx + (py - a[1]) * vy) / l2);
          const dd = (px - a[0] - vx * t) ** 2 + (py - a[1] - vy * t) ** 2;
          if (dd < best) best = dd;
        }
        const dd = Math.sqrt(best) / hw;
        if (dd >= 1) continue;
        // Kubbe kesiti: omurga yüksek, etekler yumuşak iner.
        const v = r.h * (1 - dd * dd) ** 1.2;
        if (v > out[k]) out[k] = v;
      }
    }
  }
  return out;
}

export function generateRelief(geo, progress = () => {}) {
  useGeo(geo);
  const { SEA, ISLANDS, LAKES, PLATEAUS, DESERTS, FORESTS, LUSH, PLAINS } = G;
  const t0 = Date.now();
  const w2 = RW, d2 = RD;
  const levels = [
    { w: Math.round(w2 / 4), d: Math.round(d2 / 4), iters: 46, K: 0.05, relax: 0.022, slopeMax: 1.25, diffuse: 0.035 },
    { w: Math.round(w2 / 2), d: Math.round(d2 / 2), iters: 12, K: 0.045, relax: 0.03, slopeMax: 1.5, diffuse: 0.035 },
    { w: w2, d: d2, iters: 4, K: 0.04, relax: 0.03, slopeMax: 1.8, diffuse: 0.05 },
  ];

  progress(STEP.coast);
  // Tam çözünürlükte maskeler. Kenarlar gürültüyle doğallaşır.
  const seaRaw = polyMask([SEA], w2, d2);
  const islRaw = polyMask(ISLANDS, w2, d2);
  for (let i = 0; i < seaRaw.length; i++) seaRaw[i] = islRaw[i] ? 0 : seaRaw[i];
  const sea = naturalEdge(seaRaw, w2, d2, 5, 0.3, 1.5, 0.02, 3);

  const lakeMask = new Float32Array(w2 * d2);
  const lakeId = new Int16Array(w2 * d2).fill(-1);
  LAKES.forEach((l, n) => {
    // Büyük göller doğal kıyı kazanır; küçükler eriyip kaybolmasın.
    const m = naturalEdge(polyMask([l.poly], w2, d2), w2, d2, l.big ? 7 : 2, l.big ? 0.42 : 0.2, l.big ? 2.6 : 5, 0.04, n * 3 + 11);
    for (let i = 0; i < m.length; i++) {
      if (m[i] > lakeMask[i]) lakeMask[i] = m[i];
      if (m[i] > 0.5) lakeId[i] = n;
    }
  });
  // Evlerin gölü (homes.*.carve; terrain_shape.gd'nin ırmağı, gölleri ve adacıkları): sahnede 1000 m bir harita birimidir; kuzey -z.
  {
    const id = LAKES.length;
    const seg = (px, pz, ax, az, bx, bz) => {
      const vx = bx - ax, vz = bz - az;
      const t = clamp(((px - ax) * vx + (pz - az) * vz) / (vx * vx + vz * vz || 1));
      return [Math.hypot(px - ax - vx * t, pz - az - vz * t), t];
    };
    for (const home of G.HOMES) {
      const c = home.carve;
      // Irmak: [z, merkez x, yarı genişlik] → (x, z, yarı genişlik) km.
      const R = c.river.map(([z, x, hw]) => [x / 1000, z / 1000, hw / 1000]);
      const L = (c.lakes ?? []).map(([x, z, r]) => [x / 1000, z / 1000, r / 1000]);
      const I = (c.islands ?? []).map(([x, z, r]) => [x / 1000, z / 1000, r / 1000]);
      let x0 = Infinity, x1 = -Infinity, z0 = Infinity, z1 = -Infinity;
      for (const [x, z, w] of [...R, ...L]) {
        x0 = Math.min(x0, x - w); x1 = Math.max(x1, x + w); z0 = Math.min(z0, z - w); z1 = Math.max(z1, z + w);
      }
      const pad = 0.06;
      for (let j = 0; j < d2; j++) {
        const z = gridZ(j, d2) - home.at[1];
        if (z < z0 - pad || z > z1 + pad) continue;
        for (let i = 0; i < w2; i++) {
          const x = gridX(i, w2) - home.at[0];
          if (x < x0 - pad || x > x1 + pad) continue;
          let v = 0;
          for (let s = 0; s < R.length - 1; s++) {
            const [d, t] = seg(x, z, R[s][0], R[s][1], R[s + 1][0], R[s + 1][1]);
            const hw = lerp(R[s][2], R[s + 1][2], t);
            if (hw <= 0) continue;
            v = Math.max(v, smooth(hw + 0.02, hw - 0.02, d));
          }
          for (const [lx, lz, r] of L) v = Math.max(v, smooth(r + 0.02, r - 0.02, Math.hypot(x - lx, z - lz)));
          for (const [ix, iz, r] of I) v = Math.min(v, smooth(r - 0.012, r + 0.012, Math.hypot(x - ix, z - iz)));
          const k = j * w2 + i;
          if (v > lakeMask[k]) lakeMask[k] = v;
          if (v > 0.5) lakeId[k] = id;
        }
      }
    }
  }

  const sand = naturalEdge(polyMask(DESERTS.filter((q) => q.tone === 'sand').map((q) => q.poly), w2, d2), w2, d2, 26, 0.62, 0.62, 0.26, 21);
  const stone = naturalEdge(polyMask(DESERTS.filter((q) => q.tone === 'stone').map((q) => q.poly), w2, d2), w2, d2, 30, 0.62, 0.52, 0.32, 33);
  const forestBase = naturalEdge(polyMask(FORESTS, w2, d2), w2, d2, 34, 0.74, 0.8, 0.2, 44);
  const lush = naturalEdge(polyMask(LUSH, w2, d2), w2, d2, 40, 0.5, 0.42, 0.34, 55);
  const plains = blur(polyMask(PLAINS, w2, d2), w2, d2, 26);

  // Kaba ızgara.
  const L0 = levels[0];
  const toLevel = (m, L) => {
    const out = new Float32Array(L.w * L.d);
    for (let j = 0, k = 0; j < L.d; j++) {
      const jj = Math.min(d2 - 1, Math.round((j / (L.d - 1)) * (d2 - 1)));
      for (let i = 0; i < L.w; i++, k++) out[k] = m[jj * w2 + Math.min(w2 - 1, Math.round((i / (L.w - 1)) * (w2 - 1)))];
    }
    return out;
  };

  progress(STEP.mountains);
  const rng0 = blur(rangeField(L0.w, L0.d), L0.w, L0.d, 1);
  const plateau0 = new Float32Array(L0.w * L0.d);
  const plateauCore0 = new Float32Array(L0.w * L0.d);
  for (const p of PLATEAUS) {
    const m = polyMask([p.poly], L0.w, L0.d);
    const b = blur(Float32Array.from(m), L0.w, L0.d, 8);
    for (let j = 0, k = 0; j < L0.d; j++) {
      const z = gridZ(j, L0.d);
      for (let i = 0; i < L0.w; i++, k++) {
        const v = smooth(0.18, 0.82, b[k] + fbm2(gridX(i, L0.w) * 0.34 + 8, z * 0.34 - 5, 3) * 0.34);
        plateau0[k] = Math.max(plateau0[k], v * p.h);
        if (p.h > 0.2 && v > 0.97 && fbm2(gridX(i, L0.w) * 0.5, z * 0.5 + 30, 2) > 0.08) plateauCore0[k] = 1;
      }
    }
  }
  const sand0 = toLevel(sand, L0), stone0 = toLevel(stone, L0), plains0 = toLevel(plains, L0);
  // Kuşak çevresinde geniş eteklik.
  const foot0 = blur(Float32Array.from(rng0), L0.w, L0.d, 9, 2);

  let T = new Float32Array(L0.w * L0.d);
  const mtnAmp0 = new Float32Array(L0.w * L0.d);
  for (let j = 0, k = 0; j < L0.d; j++) {
    const z = gridZ(j, L0.d);
    for (let i = 0; i < L0.w; i++, k++) {
      const x = gridX(i, L0.w);
      // Kıvrılan alan: sırtlar düz çizgi gibi uzamasın.
      const wx = x + fbm2(x * 0.14 + 4, z * 0.14 + 9, 3) * 1.5, wz = z + fbm2(x * 0.14 - 7, z * 0.14 - 2, 3) * 1.5;
      const roll = fbm2(wx * 0.2 + 3, wz * 0.2 - 7, 4) * 0.5 + 0.5;
      const m = rng0[k];
      const rid = ridge2(wx * 0.34 + 5, wz * 0.34 + 2, 5) * 0.58 + ridge2(wx * 0.92 - 8, wz * 0.92 + 6, 4) * 0.42;
      const along = 0.62 + 0.7 * (fbm2(wx * 0.11 + 20, wz * 0.11, 3) * 0.5 + 0.5);
      // Bozkır ve ova: tepeler ovalarda sönükleşir.
      const flat = 1 - 0.85 * plains0[k];
      const low = ridge2(wx * 0.62 + 11, wz * 0.62 - 3, 4);
      const low2 = ridge2(wx * 1.9 + 3, wz * 1.9 + 7, 3);
      let y = 0.012 + roll * 0.05 * flat + (low * low) * 0.095 * flat * (1 - sand0[k] * 0.8) + (low2 * low2) * 0.036 * flat * (1 - sand0[k]);
      // Yaylanın içinde doğu-batı uzanan sırtlar.
      const platRid = ridge2(wx * 0.3, wz * 0.95 + 4, 4);
      y += plateau0[k] * VS * (0.84 + 0.2 * roll + 0.34 * platRid * platRid);
      y += foot0[k] * VS * 0.34 * (0.5 + roll);
      y += m * VS * along * (0.36 + 0.92 * rid);
      // Çöller geniş çanak gibidir.
      y *= 1 - 0.42 * Math.max(sand0[k], stone0[k] * 0.55);
      T[k] = y;
      mtnAmp0[k] = smooth(0.02, 0.2, m);
    }
  }

  // Büyük ırmaklar önceden vadilerine yerleşir, drenaj onları izler.
  const paths = riverPaths();
  {
    const cw = L0.w, cd = L0.d;
    const carve = new Float32Array(cw * cd);
    const kx = (cw - 1) / MAP_W, kz = (cd - 1) / MAP_D;
    for (const p of paths) {
      const depth = 0.006 + p.w * 0.0036;
      for (let s = 0; s < p.pts.length - 1; s++) {
        const [ax, az] = p.pts[s], [bx, bz] = p.pts[s + 1];
        const steps = Math.max(1, Math.ceil(Math.hypot((bx - ax) * kx, (bz - az) * kz)));
        for (let q = 0; q <= steps; q++) {
          const x = lerp(ax, bx, q / steps), z = lerp(az, bz, q / steps);
          const i = Math.round((x / MAP_W + 0.5) * (cw - 1)), j = Math.round((z / MAP_D + 0.5) * (cd - 1));
          if (i < 0 || j < 0 || i >= cw || j >= cd) continue;
          carve[j * cw + i] = Math.max(carve[j * cw + i], depth);
        }
      }
    }
    blur(carve, cw, cd, 1, 2);
    for (let k = 0; k < T.length; k++) T[k] = Math.max(0.006, T[k] - carve[k] * 2.4);
  }

  // Göl seviyeleri çevrelerinin biraz altına oturur.
  const lakeLevel = new Float32Array(LAKES.length + 1);
  {
    const sum = new Float32Array(LAKES.length + 1), cnt = new Float32Array(LAKES.length + 1);
    const lid0 = new Int16Array(L0.w * L0.d).fill(-1);
    for (let j = 0, k = 0; j < L0.d; j++) {
      const jj = Math.min(d2 - 1, Math.round((j / (L0.d - 1)) * (d2 - 1)));
      for (let i = 0; i < L0.w; i++, k++) {
        const id = lakeId[jj * w2 + Math.min(w2 - 1, Math.round((i / (L0.w - 1)) * (w2 - 1)))];
        lid0[k] = id;
        if (id >= 0) {
          sum[id] += T[k];
          cnt[id]++;
        }
      }
    }
    for (let n = 0; n <= LAKES.length; n++) lakeLevel[n] = cnt[n] ? (sum[n] / cnt[n]) * 0.82 : 0.03;
  }

  // Kayaç sertliği: farklı aşınma, daha zengin sırtlar.
  const makeHard = (L) => {
    const out = new Float32Array(L.w * L.d);
    for (let j = 0, k = 0; j < L.d; j++) {
      const z = gridZ(j, L.d);
      for (let i = 0; i < L.w; i++, k++) out[k] = 0.6 + 0.8 * (fbm2(gridX(i, L.w) * 0.7 + 31, z * 0.7 + 17, 3) * 0.5 + 0.5);
    }
    return out;
  };
  // Su toplanan taban noktaları: deniz, göl, çöl çanakları ve yayla içi.
  const makeSeed = (L, plateauCore) => {
    const seed = new Uint8Array(L.w * L.d);
    for (let j = 0, k = 0; j < L.d; j++) {
      const jj = Math.min(d2 - 1, Math.round((j / (L.d - 1)) * (d2 - 1)));
      for (let i = 0; i < L.w; i++, k++) {
        const q = jj * w2 + Math.min(w2 - 1, Math.round((i / (L.w - 1)) * (w2 - 1)));
        if (sea[q] > 0.5 || lakeMask[q] > 0.5 || sand[q] > 0.82 || stone[q] > 0.86 || plateauCore[k]) seed[k] = 1;
      }
    }
    return seed;
  };
  // Deniz ve göller tabanda sabitlenir.
  const fixWater = (h, Tt, L) => {
    for (let j = 0, k = 0; j < L.d; j++) {
      const jj = Math.min(d2 - 1, Math.round((j / (L.d - 1)) * (d2 - 1)));
      for (let i = 0; i < L.w; i++, k++) {
        const q = jj * w2 + Math.min(w2 - 1, Math.round((i / (L.w - 1)) * (w2 - 1)));
        if (sea[q] > 0.5) {
          h[k] = 0;
          Tt[k] = 0;
        } else if (lakeId[q] >= 0) {
          h[k] = lakeLevel[lakeId[q]];
          Tt[k] = lakeLevel[lakeId[q]];
        }
      }
    }
  };

  let h = Float32Array.from(T);
  let A = null;
  let plateauCore = plateauCore0;
  let amp = mtnAmp0;
  levels.forEach((L, n) => {
    progress(n === 0 ? STEP.rivers : n === 1 ? STEP.valleys : STEP.slopes);
    if (n > 0) {
      const P = levels[n - 1];
      h = upsample(h, P.w, P.d, L.w, L.d);
      amp = upsample(amp, P.w, P.d, L.w, L.d);
      plateauCore = upsample(plateauCore, P.w, P.d, L.w, L.d).map((v) => (v > 0.7 ? 1 : 0));
      // İnce ölçek ayrıntı: kabartmanın üstüne yalnız dağlarda eklenir.
      T = new Float32Array(L.w * L.d);
      const f = n === 1 ? 1.5 : 3.2, a = n === 1 ? 0.05 : 0.024;
      for (let j = 0, k = 0; j < L.d; j++) {
        const z = gridZ(j, L.d);
        for (let i = 0; i < L.w; i++, k++) {
          const x = gridX(i, L.w);
          const r = ridge2(x * f + n * 7, z * f - n * 3, 4) - 0.55;
          const hill = fbm2(x * f * 1.4 + n, z * f * 1.4, 3);
          const v = h[k] + r * a * (0.26 + amp[k]) + hill * 0.011 * (1 - amp[k]);
          T[k] = v;
          h[k] = v;
        }
      }
    }
    fixWater(h, T, L);
    const seed = makeSeed(L, plateauCore);
    const hard = makeHard(L);
    const cell = MAP_W / (L.w - 1);
    A = erode(h, T, L.w, L.d, cell, seed, hard, L.iters, L);
    fixWater(h, T, L);
  });

  progress(STEP.biomes);
  // Kıyıda kara denize yumuşak iner.
  const seaSoft = blur(Float32Array.from(sea), w2, d2, 2);
  const seaWide = blur(Float32Array.from(sea), w2, d2, 22);
  const N = w2 * d2;
  const cell = MAP_W / (w2 - 1);
  for (let j = 0, k = 0; j < d2; j++) {
    const z = gridZ(j, d2);
    for (let i = 0; i < w2; i++, k++) {
      const x = gridX(i, w2);
      if (sea[k] > 0.5) {
        h[k] = 0;
      } else {
        h[k] = Math.max(0.004, h[k]) * smooth(0.5, 0.2, seaSoft[k]) + 0.003;
      }
      // Harita kenarı puslanacak yere doğru alçalır.
      const edge = Math.min(x + MAP_W / 2, MAP_W / 2 - x, z + MAP_D / 2, MAP_D / 2 - z);
      h[k] *= smooth(0, 0.9, edge);
    }
  }

  // Normal ve akış.
  const nh = new Uint8ClampedArray(N * 4), bio = new Uint8ClampedArray(N * 4), env = new Uint8ClampedArray(N * 4);
  let maxFlow = 1;
  for (let k = 0; k < N; k++) if (A[k] > maxFlow) maxFlow = A[k];
  const logMax = Math.log(1 + maxFlow);
  const curv = blur(Float32Array.from(h), w2, d2, 4, 2);
  const curvWide = blur(Float32Array.from(h), w2, d2, 18, 2);
  const shadow = sunShadow(h, w2, d2, cell);

  for (let j = 0, k = 0; j < d2; j++) {
    const z = gridZ(j, d2);
    const lat = latAt(z);
    const jm = Math.max(0, j - 1), jp = Math.min(d2 - 1, j + 1);
    for (let i = 0; i < w2; i++, k++) {
      const x = gridX(i, w2);
      const im = Math.max(0, i - 1), ip = Math.min(w2 - 1, i + 1);
      const gx = (h[j * w2 + ip] - h[j * w2 + im]) / ((ip - im) * cell);
      const gz = (h[jp * w2 + i] - h[jm * w2 + i]) / ((jp - jm) * cell);
      const slope = Math.hypot(gx, gz);
      const y = h[k];
      const flow = Math.log(1 + A[k]) / logMax;
      nh[k * 4] = (gx / GMAX) * 127.5 + 127.5;
      nh[k * 4 + 1] = (gz / GMAX) * 127.5 + 127.5;
      nh[k * 4 + 2] = (y / HMAX) * 255;
      nh[k * 4 + 3] = flow * 255;

      // Orman yamaçta ve yüksekte seyrelir, vadilerde yoğunlaşır.
      const treeLine = lerp(0.15, 0.27, clamp((z + MAP_D / 2) / MAP_D));
      let fo = forestBase[k] * smooth(treeLine + 0.02, treeLine - 0.05, y + noise2(x * 2.6, z * 2.6) * 0.03) * smooth(1.7, 0.9, slope);
      // Bozkır dağlarında orman güneş görmeyen kuzey yamaçlara çekilir.
      const northSlope = smooth(0.06, 0.5, gz);
      const inner = (1 - lush[k]) * smooth(0.06, 0.13, y) * smooth(treeLine, treeLine - 0.04, y);
      fo = Math.max(fo, northSlope * inner * 0.82 * smooth(52, 38, lat) * (1 - sand[k]) * (1 - stone[k]));
      // Kuru bölgelerde yalnız ırmak boyu yeşerir.
      const valley = smooth(0.42, 0.72, flow);
      fo = Math.max(fo, smooth(0.25, 0.8, noise2(x * 4.1, z * 4.1) + 0.6) * valley * 0.42 * (1 - sand[k]) * smooth(0.2, 0.12, y));
      bio[k * 4] = fo * 255;
      bio[k * 4 + 1] = sand[k] * 255;
      bio[k * 4 + 2] = stone[k] * 255;
      bio[k * 4 + 3] = lush[k] * 255;

      env[k * 4] = shadow[k] * 255;
      // Çukur koyu, sırt açık: gölgeyi derinleştirir.
      const ao = clamp(0.62 + (y - curv[k]) * 26 + (y - curvWide[k]) * 3.2, 0, 1.2) / 1.2;
      env[k * 4 + 1] = ao * 255;
      // Kıyıdan uzaklık: 0.5 kıyıdır, 1'e gidince açık deniz.
      env[k * 4 + 2] = (sea[k] > 0.5 ? 0.5 + 0.5 * smooth(0.5, 1, seaWide[k]) : 0.5 * smooth(0, 0.5, seaWide[k])) * 255;
      env[k * 4 + 3] = lakeMask[k] * 255;
    }
  }
  progress(STEP.done);
  return { h, nh, bio, env, w: w2, d: d2, ms: Date.now() - t0 };
}

// Güneşe doğru yürüyerek yumuşak gölge hesaplar. Yükseklik gölgede biraz abartılır.
function sunShadow(h, w, d, cell) {
  const out = new Float32Array(w * d);
  const E = 1.12;
  const hyp = Math.hypot(SUN[0], SUN[2]);
  const dx = SUN[0] / hyp, dz = SUN[2] / hyp, rise = (SUN[1] / hyp) * cell * 1.5;
  const stepX = dx * 1.5, stepZ = dz * 1.5;
  for (let j = 0, k = 0; j < d; j++) {
    for (let i = 0; i < w; i++, k++) {
      const y0 = h[k] * E;
      if (y0 <= 0) { out[k] = 1; continue; }
      let lit = 1, px = i, pz = j, ry = y0 + 0.002;
      for (let s = 1; s <= 36; s++) {
        px += stepX;
        pz += stepZ;
        ry += rise;
        if (px < 0 || pz < 0 || px >= w - 1 || pz >= d - 1 || ry > 0.95) break;
        const hh = h[(pz | 0) * w + (px | 0)] * E;
        const gap = ry - hh;
        if (gap < 0) { lit = 0; break; }
        // Yarı gölge: yakın engel keskin, uzak engel yumuşak.
        const pen = gap / (s * 0.0055);
        if (pen < lit) lit = pen;
      }
      out[k] = lit;
    }
  }
  return blur(out, w, d, 1, 1);
}
