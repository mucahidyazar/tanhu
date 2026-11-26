#!/usr/bin/env node
// Prototipin atlas coğrafyasını Godot verisine döker (godot.md §4.8): src/map/geography.js satırları, src/i18n/strings/geo.js ve
// atlas.js dizgeleri → data/atlas/geography.json. Bir kez koşulur; sonra JSON kaynaktır, bake_atlas.mjs onu okur.
// Godot'nun eklediği satırlar ve evler (iç haritaların atlas noktaları) aşağıdaki GODOT_* tablolarındadır; prototipte yoktur.
//   node tools/atlas/dump_geography.mjs [prototipin_kökü]
import { writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { makeToMap, riverPaths } from './geo_paths.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const GAME = resolve(HERE, '..', '..');
const PROTO = resolve(process.argv[2] ?? '/Users/mucahidyazar/Code/tests/tanhu-programatic-test');
const imp = (rel) => import(pathToFileURL(join(PROTO, rel)).href);

const G = await imp('src/map/geography.js');
const geoStrings = (await imp('src/i18n/strings/geo.js')).default;
const atlasStrings = (await imp('src/i18n/strings/atlas.js')).default;

const r4 = (v) => Math.round(v * 10000) / 10000;
const LON0 = 58, LON1 = 136, LAT0 = 23, LAT1 = 58;
const map = {
  doc: "Harita iç birimi (geography.js): alan 1.500 birim², gösterim 75.000 km² (bir birim ≈7,07 km). x doğu, z güney; harita (0, 0) çevresinde. Gerçek sahne düzeyinde bir birim 1.000 sahne metresidir (iç haritanın kendi metresi).",
  area_units: G.MAP_AREA_UNITS, area_km2: G.AREA_KM2, km_per_unit: r4(G.KM_PER_UNIT),
  lon0: LON0, lon1: LON1, lat0: LAT0, lat1: LAT1, w: r4(G.MAP_W), d: r4(G.MAP_D),
};
const toMap = makeToMap({ ...map, w: G.MAP_W, d: G.MAP_D });

// ---------- Godot'nun ekleri ----------

// MÖ 228 (Çocukluk, K36, story.md §5): Hun MÖ 215'e dek Ordos'tadır (SJ 110 悉收河南地). Prototipin dönemleri 210'da başlar ve 210'un
// Ç'in'i Ordos'u örter; Çocukluk'un haritası bu yüzden kendi dönemini taşır: Hun çekirdeği Yin Dağları'nın iki yanı ve Ordos, batıda
// Yüeçi. Çin bu dönemde birleşmemiştir (Ç'in MÖ 221): çizilmez. Açılma koşulu 'childhood' (Çocukluk'un kuralı) koşul dili değildir.
const UNLOCK_CHILDHOOD = 'childhood';
const HUN = '#8a2622', YUE = '#2f8071';
const xiongnu210 = G.POLITIES.find((p) => p.id === 'xiongnu');
const yuezhi210 = G.POLITIES.find((p) => p.id === 'yuezhi');
const GODOT_ERAS = [{ id: '228', unlock: UNLOCK_CHILDHOOD }];
const GODOT_POLITIES = [
  {
    id: 'xiongnu_228', group: 'xiongnu', unlock: UNLOCK_CHILDHOOD, style: 'core', color: HUN, layer: 'states', eras: ['228'], at: [108.6, 43.6], rank: 10,
    poly: [[100.5, 43], [104, 40.6], [106.2, 38.6], [107.2, 37.6], [109.5, 37.4], [110.8, 38.2], [111.2, 40], [112, 41.2], [112.8, 44], [112, 47.5],
      [110, 49.2], [105, 49.6], [100.5, 48], [99.5, 45]],
  },
  { ...yuezhi210, id: 'yuezhi_228', group: 'yuezhi', unlock: UNLOCK_CHILDHOOD, eras: ['228'] },
];
const GODOT_EVENTS = [
  { id: 'birth', unlock: UNLOCK_CHILDHOOD, era: '228', at: null },
  { id: 'childhood', unlock: UNLOCK_CHILDHOOD, era: '228', at: null },
];
const GODOT_STRINGS = {
  'geo.eras.228.label': ['MÖ 228', '228 BC'],
  'geo.eras.228.title': ["Ordos'ta çocukluk", 'A childhood in the Ordos'],
  'geo.polities.xiongnu_228.name': ['Hun Tanhuluğu', 'Xiongnu'],
  'geo.polities.xiongnu_228.note': [
    "Teoman'ın Hunları Yin Dağları'nın iki yanında ve Sarı Irmak kıvrımının içinde, Ordos'ta otlar. MÖ 215'te Ç'in generali Meng Tian onları buradan kuzeye sürecektir.",
    "Teoman's Xiongnu graze on both sides of the Yin Mountains and inside the Yellow River bend, in the Ordos. In 215 BC the Qin general Meng Tian will drive them north from here.",
  ],
  'geo.polities.yuezhi_228.name': ['Yüeçi', 'Yuezhi'],
  'geo.polities.yuezhi_228.note': [
    "Hexi koridorunun efendisi; sürüleriyle yer değiştiren göçer bir ülke. Teoman'ın yıllarında doğuda Tung-hu güçlü, batıda Yüeçi parlaktır.",
    "Masters of the Hexi corridor, a state that moves with its herds. In Teoman's years the Donghu are strong in the east and the Yuezhi flourish in the west.",
  ],
  'geo.events.birth.name': ['Doğum', 'Birth'],
  'geo.events.birth.year': ['MÖ 234', '234 BC'],
  'geo.events.birth.note': [
    "Mete, Teoman'ın Ordos'taki güz otlağında, Lan Hatun'un yurdunda doğar.",
    "Mete is born in Lan Hatun's yurt, on Teoman's autumn pasture in the Ordos.",
  ],
  'geo.events.childhood.name': ['Koyun Sırtında', "On a Sheep's Back"],
  'geo.events.childhood.year': ['MÖ 228', '228 BC'],
  'geo.events.childhood.note': [
    'Hun çocukları ata binmeyi koyun sırtında öğrenir, küçük yaylarıyla kuş ve fare vurur (SJ 110).',
    'Xiongnu boys learn to ride on the backs of sheep and shoot birds and rats with small bows (SJ 110).',
  ],
  // İç haritaların düzeyleri ve yerel adları (prototipin HOMES'u; Godot'nun dünyalarına göre).
  'atlas.home.lake_valley': ['Göl Vadisi', 'Lake Valley'],
  // Menünün kampı rastgele bir obadır, Tanhu'nun kampı değildir (K106): prototipin «Tanhu Kampı» dizgeleri yerine.
  'atlas.you.place': ['Göl Obası', 'Lake Camp'],
  'atlas.crumb.camp': ['Göl Obası', 'Lake Camp'],
  'atlas.local.camp': ['Göl Obası', 'Lake Camp'],
  // Hikâyenin Tanhu Kampı (Yola Çıkış, MÖ 213; K41'in tanhu_camp konağı): Göl Obası'ndan ayrı (K106).
  'atlas.home.tanhu_winter': ["Tanhu'nun kış yurdu", "The Tanhu's winter grounds"],
  'atlas.home.ordos_bend': ['Sarı Irmak Kıvrımı', 'The Yellow River Bend'],
  // I. Perde'nin Kışlak'ı (act1.md §4): Hexi Koridoru'nda Buz Kolu'nun vadisi.
  'atlas.home.ice_branch_valley': ['Buz Kolu Vadisi', 'The Ice Branch Valley'],
  'atlas.local.ice_branch': ['Buz Kolu', 'Ice Branch'],
  'atlas.local.qilian_foot': ['Çilyan Eteği', 'The Qilian Foothills'],
  'atlas.local.bone_throat': ['Kemik Boğazı', 'Bone Throat'],
  'atlas.local.ordos_pasture': ["Teoman'ın güz otlağı", "Teoman's autumn pasture"],
  // Godot'nun harita sayfası: yürünür alan, görev, yerler, katmanlar (yerel düzeyden kalanlar).
  'atlas.side.quest': ['Görev', 'Quest'],
  'atlas.side.places': ['Yerler', 'Places'],
  'atlas.layer.quest': ['Görev', 'Quest'],
  'atlas.layer.area': ['Yürünür alan', 'Walkable area'],
  'atlas.layer.clouds': ['Bulutlar', 'Clouds'],
  // Başka yere yakınlaşma 6 birimde durur (K40; site Harita): yol kapalıysa bu satır yazar.
  'atlas.road.closed': ['Bu yol henüz açılmadı.', 'This road is not open yet.'],
  'atlas.road.closed_roam': ["Serbest Gez'de yol kapalı.", 'Roads are closed in Free Roam.'],
  'atlas.layer.places': ['Yer adları', 'Place names'],
  'atlas.scale.local': ['Sahne metresi', 'Scene metres'],
};

// İç haritaların evi (prototipin HOMES'u, travel.md §1.3): WorldMap'in anahtarı → boylam, enlem. Ev sahnenin (0, 0) noktasıdır, sahnede
// 1.000 m bir harita birimidir; kuzey haritanın kuzeyidir (döndürme yok). names: gerçek sahne düzeyinin adları [anahtar, x, z (m),
// en küçük ve en büyük görüş (birim), tür]. carve: kabartmaya oyulan gölün hattı (bake_atlas.mjs; sahnedeki gölle aynı yer).
// reveal: Serbest Gez 'camp' (başta ve kamp satırları), Çocukluk 'childhood'; era: açılışta seçilen dönem (boşsa ilk açık dönem).
const CAMP_NAMES = [
  ['atlas.local.lake', -20, -620, 0.45, 9, 'lake'],
  ['atlas.local.orkhon_valley', 290, -1760, 0.7, 9, 'river'],
  ['atlas.local.foothills', -980, 260, 0.7, 9, 'range'],
];
// Kampın gölü ve ırmağı (scripts/world/terrain_shape.gd RIVER_POINTS: z, merkez x, yarı genişlik; ISLANDS ve SIDE_LAKES): ateş (0, 0).
const CAMP_CARVE = {
  doc: 'Kampın vadisi (terrain_shape.gd): ırmak ve göl [z, merkez x, yarı genişlik] m, ayrı göller [x, z, yarıçap], adacıklar [x, z, yarıçap].',
  river: [[-140, -175, 0], [-250, -125, 22], [-370, -75, 55], [-500, -25, 150], [-660, 15, 185], [-830, 75, 115], [-1030, 140, 50],
    [-1280, 210, 40], [-1580, 260, 65], [-1980, 300, 85], [-2600, 330, 60]],
  lakes: [[-390, -1260, 190]],
  islands: [[10, -650, 62], [-45, -545, 24], [95, -770, 34]],
};

// Çocukluk'un Ordos'u (story.md §5, layout.json river): Sarı Irmak kampın ≈680 m doğusunda, kıvrımın içinde; enlem 39 (light.json).
// Kıvrımın doğu kolunun 39°K'deki yerinden 0,68 birim batıya iğnelenir (bir birim 1.000 sahne metresi).
const ORDOS_LAT = 39.0;
const ORDOS_RIVER_EAST_M = 680;
function ordosPin() {
  const yr = riverPaths(G.RIVERS, toMap).find((r) => r.id === 'yellow_river');
  const z = toMap(0, ORDOS_LAT)[1];
  const xMin = toMap(109.6, 0)[0], xMax = toMap(111.8, 0)[0];
  let best = -Infinity;
  for (let i = 0; i < yr.pts.length - 1; i++) {
    const [ax, az] = yr.pts[i], [bx, bz] = yr.pts[i + 1];
    if ((az - z) * (bz - z) > 0 || az === bz) continue;
    const x = ax + ((z - az) / (bz - az)) * (bx - ax);
    if (x >= xMin && x <= xMax && x > best) best = x;
  }
  if (!Number.isFinite(best)) throw new Error('ordos: Sarı Irmak 39°K doğu kolunda bulunamadı');
  const x = best - ORDOS_RIVER_EAST_M / 1000;
  const lon = LON0 + (x / G.MAP_W + 0.5) * (LON1 - LON0);
  return { lonlat: [r4(lon), ORDOS_LAT], riverX: best };
}
const ordos = ordosPin();
GODOT_EVENTS[0].at = ordos.lonlat;
GODOT_EVENTS[1].at = [r4(ordos.lonlat[0] + 0.08), r4(ORDOS_LAT + 0.05)];

// Hikâyenin Tanhu Kampı (K106): menünün kampından ayrı; enlem Yola Çıkış'ın ışığından (46,5°K).
const TANHU_CAMP_LONLAT = [105.2, 46.5];

const HOMES = {
  camp: {
    doc: "Menünün ve Serbest Gez'in kampı Göl Obası (E20, K106): Hangay eteğinde, Orhun'un yukarı vadisindeki göllü vadide rastgele bir oba, hikâyenin dışında (prototipin CAMP_LONLAT'ı ve Göl Vadisi'si; K20 ve K67'nin 47,35°K'si, data/maps/camp/map.json pin).",
    lonlat: G.CAMP_LONLAT, valley: 'atlas.home.lake_valley', reveal: 'camp', era: '', names: CAMP_NAMES, carve: CAMP_CARVE,
  },
  ordos: {
    doc: "Çocukluk'un kasabası (childhood_ordos; story.md §5): Sarı Irmak kıvrımının içinde Teoman'ın güz otlağı; ırmak 680 m doğuda, 39°K.",
    lonlat: ordos.lonlat, valley: 'atlas.home.ordos_bend', reveal: 'childhood', era: '228',
    names: [['geo.rivers.yellow_river.name', ORDOS_RIVER_EAST_M, -420, 0.45, 9, 'river'], ['atlas.local.ordos_pasture', -60, -560, 0.7, 9, 'range']],
  },
  depart_yurt: {
    doc: "Yola Çıkış (depart_yurt; story.md §6): kuzeydeki Tanhu Kampı, kış, MÖ 213; K41'in tanhu_camp konağı da burasıdır. Göl Obası'nın güneydoğusunda, Hangay ile Gobi arasındaki bozkırda (gerçek coğrafyada ≈190 km); enlem ışığınki (data/maps/depart_yurt/light.json 46,5°K; K106).",
    lonlat: TANHU_CAMP_LONLAT, valley: 'atlas.home.tanhu_winter', reveal: 'camp', era: '210',
    names: [],
  },
  kislak: {
    doc: "I. Perde'nin Kışlak'ı (act1.md §4; travel.md §1.3 hexi_winter): Hexi Koridoru'nda, Çilyan Dağları'nın kuzey eteğinde Yüeçi'nin kış kampı, 99,4°D 38,9°K (data/maps/kislak/map.json pin). Ulu Ocak sahnenin (0, 0)'ıdır; harita x −450..950, z −760..290 (kuzey −Z): iz pinU + bounds/1000. Buz Kolu batıdan doğuya akar, Kemik Boğazı kuzeydoğudadır.",
    lonlat: [99.4, 38.9], valley: 'atlas.home.ice_branch_valley', reveal: 'camp', era: '210',
    names: [['atlas.local.ice_branch', 140, -200, 0.45, 9, 'river'], ['atlas.local.qilian_foot', -120, 260, 0.7, 9, 'range'],
      ['atlas.local.bone_throat', 560, -660, 0.45, 9, 'range']],
  },
};

// ---------- Döküm ----------

const ll = (p) => [r4(p[0]), r4(p[1])];
const cleanRow = (row) => {
  const out = {};
  for (const [k, v] of Object.entries(row)) {
    if (v === undefined) continue;
    if (k === 'poly' || k === 'pts') out[k] = v.map(ll);
    else if (k === 'at' && Array.isArray(v)) out[k] = ll(v);
    else out[k] = v;
  }
  return out;
};
const rows = (list) => list.map(cleanRow);

const strings = {};
for (const [k, v] of Object.entries({ ...geoStrings, ...atlasStrings, ...GODOT_STRINGS })) strings[k] = { tr: v[0], en: v[1] };

const sunV = [-0.68, 0.46, -0.42];
const sunL = Math.hypot(...sunV);
const out = {
  doc: "Atlas coğrafyası (godot.md §4.8; site Harita): prototipin src/map/geography.js satırları ve geo.js, atlas.js dizgeleri, tools/atlas/dump_geography.mjs döker. Satır biçimi geography.js'inkidir (id, group, unlock, eras, rumour, at [boylam, enlem], poly, pts). Godot'nun ekleri: MÖ 228 dönemi ve satırları (Çocukluk), Mete'nin doğumu ve Koyun Sırtında olayları, iç haritaların evleri (homes). Kabartma ve kıvrımlı yollar bake_atlas.mjs'tedir (assets/map/, data/atlas/shapes.json).",
  version: 1,
  map: { ...map, sun: sunV.map((a) => r4(a / sunL)), haze: '#a9bdd2' },
  conds: { home: G.HOME_COND },
  eras: rows([...GODOT_ERAS, ...G.ERAS]),
  sea: G.SEA.map(ll), islands: G.ISLANDS.map((p) => p.map(ll)),
  lakes: rows(G.LAKES), ranges: rows(G.RANGES), plateaus: rows(G.PLATEAUS), deserts: rows(G.DESERTS),
  forests: G.FORESTS.map((p) => p.map(ll)), lush: G.LUSH.map((p) => p.map(ll)), plains: G.PLAINS.map((p) => p.map(ll)),
  rivers: rows(G.RIVERS), wall: G.WALL.map(ll), seas: rows(G.SEAS), regions: rows(G.REGIONS),
  polities: rows([...GODOT_POLITIES, ...G.POLITIES]), clans: rows(G.CLANS), cities: rows(G.CITIES),
  events: rows([...GODOT_EVENTS, ...G.EVENTS]),
  homes: HOMES,
  strings,
};
const path = join(GAME, 'data', 'atlas', 'geography.json');
writeFileSync(path, `${JSON.stringify(out, null, '\t')}\n`);
console.log(`geography.json: ${Object.keys(strings).length} dizge, ${out.polities.length} siyasi satır, Ordos ${ordos.lonlat} (ırmak x ${ordos.riverX.toFixed(3)})`);
