// Atlas pişirme araçlarının deterministik matematiği: prototipin src/core/math.js'inden birebir (aynı tohum aynı kabartmayı verir).
export const TAU = Math.PI * 2;
export const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
export const lerp = (a, b, t) => a + (b - a) * t;

// a > b olduğunda da çalışır (ters yönlü geçiş için).
export function smooth(a, b, x) {
  const t = clamp((x - a) / (b - a));
  return t * t * (3 - 2 * t);
}

export function rng(seed = 1) {
  let a = seed >>> 0;
  const f = () => {
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  f.range = (lo, hi) => lo + (hi - lo) * f();
  return f;
}

const PERM = new Uint8Array(512);
{
  const r = rng(1337);
  const p = Array.from({ length: 256 }, (_, i) => i);
  for (let i = 255; i > 0; i--) {
    const j = Math.floor(r() * (i + 1));
    [p[i], p[j]] = [p[j], p[i]];
  }
  for (let i = 0; i < 512; i++) PERM[i] = p[i & 255];
}

const fade = (t) => t * t * t * (t * (t * 6 - 15) + 10);

function g2(h, x, y) {
  switch (h & 7) {
    case 0: return x + y;
    case 1: return -x + y;
    case 2: return x - y;
    case 3: return -x - y;
    case 4: return x;
    case 5: return -x;
    case 6: return y;
    default: return -y;
  }
}

export function noise2(x, y) {
  const xi = Math.floor(x), yi = Math.floor(y);
  const X = xi & 255, Y = yi & 255;
  const fx = x - xi, fy = y - yi;
  const u = fade(fx), v = fade(fy);
  const A = PERM[X] + Y, B = PERM[X + 1] + Y;
  return lerp(
    lerp(g2(PERM[A], fx, fy), g2(PERM[B], fx - 1, fy), u),
    lerp(g2(PERM[A + 1], fx, fy - 1), g2(PERM[B + 1], fx - 1, fy - 1), u),
    v,
  );
}

// Dikişsiz tekrar eden 2B gürültü (bulut ve fırça dokuları için).
export function pnoise2(x, y, per) {
  const xi = Math.floor(x), yi = Math.floor(y);
  const fx = x - xi, fy = y - yi;
  const x0 = ((xi % per) + per) % per, x1 = (x0 + 1) % per;
  const y0 = ((yi % per) + per) % per, y1 = (y0 + 1) % per;
  const h = (a, b) => PERM[PERM[a & 255] + (b & 255)];
  const u = fade(fx), v = fade(fy);
  return lerp(
    lerp(g2(h(x0, y0), fx, fy), g2(h(x1, y0), fx - 1, fy), u),
    lerp(g2(h(x0, y1), fx, fy - 1), g2(h(x1, y1), fx - 1, fy - 1), u),
    v,
  );
}

export function fbm2(x, y, oct = 4, lac = 2, gain = 0.5) {
  let a = 1, f = 1, s = 0, n = 0;
  for (let i = 0; i < oct; i++) {
    s += a * noise2(x * f + i * 17.3, y * f - i * 9.1);
    n += a;
    a *= gain;
    f *= lac;
  }
  return s / n;
}

// Sırt şeklinde gürültü (dağlar için), 0..1 döner.
export function ridge2(x, y, oct = 4) {
  let a = 1, f = 1, s = 0, n = 0;
  for (let i = 0; i < oct; i++) {
    const v = 1 - Math.abs(noise2(x * f + i * 13.1, y * f + i * 7.7));
    s += a * v * v;
    n += a;
    a *= 0.5;
    f *= 2.1;
  }
  return s / n;
}
