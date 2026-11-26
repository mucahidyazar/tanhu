// Kenar çubuğunda sabitlenen bağlantılar: data/pins.json, kullanıcının sırasıyla. Yalnız site içi adresler tutulur; ad ve
// simge her çizimde kenar çubuğunun kendi verisinden çözülür (sayfa adı değişince sabitlenen de değişir).
import fs from "node:fs";
import path from "node:path";
import { DATA_DIR } from "./catalog";
import { writeAtomic } from "./history";

export const PINS_FILE = path.join(DATA_DIR, "pins.json");
const MAX_PINS = 40;

const clean = (value: unknown): string[] =>
  [...new Set((Array.isArray(value) ? value : []).filter((x): x is string => typeof x === "string" && /^\/[A-Za-z0-9/_#.-]*$/.test(x)))].slice(0, MAX_PINS);

export function readPins(): string[] {
  if (!fs.existsSync(PINS_FILE)) return [];
  try {
    return clean((JSON.parse(fs.readFileSync(PINS_FILE, "utf8")) as { pins?: unknown }).pins);
  } catch {
    return [];
  }
}

export function writePins(list: unknown): string[] {
  const pins = clean(list);
  writeAtomic(PINS_FILE, `${JSON.stringify({ pins }, null, 1)}\n`);
  return pins;
}
