import type { NextConfig } from "next";
import legacy from "./src/lib/legacy-ids.json";

type Redirect = { source: string; destination: string; permanent: boolean };

// Eski Türkçe adresler (2026-11-04'e dek) kalıcı olarak İngilizce adreslere gider: eski bağ ve yer imi çalışır.
// Önce tek tek eşlemeler, sonra önek yedekleri; Next sırayla bakar.
function legacyRedirects(): Redirect[] {
  const out: Redirect[] = [];
  const add = (source: string, destination: string) => out.push({ source, destination, permanent: true });
  const routes = [
    ["belge", "docs"],
    ["duzenle", "edit"],
    ["gecmis", "history"],
  ] as const;
  for (const [from, to] of Object.entries(legacy.pageRoutes as Record<string, string>)) add(`/belge/${from}`, to);
  for (const [oldPrefix, newPrefix] of routes) {
    for (const [from, to] of Object.entries(legacy.pages as Record<string, string>)) add(`/${oldPrefix}/${from}`, `/${newPrefix}/${to}`);
    for (const [from, to] of Object.entries(legacy.categories as Record<string, string>)) add(`/${oldPrefix}/${from}`, `/${newPrefix}/${to}`);
    // Kaynak belgeler: önce Türkçe dosya adlı olanlar takma adlarına, sonra grup önekleri.
    for (const [fromGroup, toGroup] of Object.entries(legacy.sourceGroups as Record<string, string>)) {
      for (const [file, alias] of Object.entries(legacy.sourceNames as Record<string, string>)) add(`/${oldPrefix}/${fromGroup}/${file}`, `/${newPrefix}/${toGroup}/${alias}`);
    }
    // Grup dizinleri önce: «/belge/kaynak/oyun» «/belge/kaynak/:name» kuralına düşmesin (yanlış hedef, 404).
    for (const [fromGroup, toGroup] of Object.entries(legacy.sourceGroups as Record<string, string>)) add(`/${oldPrefix}/${fromGroup}`, `/${newPrefix}/${toGroup}`);
    for (const [fromGroup, toGroup] of Object.entries(legacy.sourceGroups as Record<string, string>)) add(`/${oldPrefix}/${fromGroup}/:name`, `/${newPrefix}/${toGroup}/:name`);
    add(`/${oldPrefix}/:path*`, `/${newPrefix}/:path*`);
  }
  // Yeni adreste Türkçe dosya adı yazılırsa takma ada gider (ör. /docs/source/research/bozkir-ekonomi).
  // Yalnız büyük-küçük harf farkı olanlar atlanır (README → readme): Next eşlemeyi harf duyarsız yapar, döngü olur.
  for (const toGroup of Object.values(legacy.sourceGroups as Record<string, string>)) {
    for (const [file, alias] of Object.entries(legacy.sourceNames as Record<string, string>)) {
      if (file.toLowerCase() !== alias.toLowerCase()) add(`/docs/${toGroup}/${file}`, `/docs/${toGroup}/${alias}`);
    }
  }
  for (const [from, to] of Object.entries(legacy.routes as Record<string, string>)) add(from, to);
  add("/varliklar/:group", "/assets/:group");
  add("/medya/:path*", "/media/:path*");
  add("/api/ara", "/api/search");
  // Yol haritası sayfası İlerleme ile birleşti.
  add("/docs/development/roadmap", "/roadmap");
  // Notlarım sayfası Notlar'la birleşti: elle yazılan notlar /notes'un «Yazdığın notlar» görünümünde.
  add("/docs/general/my-notes", "/notes?view=written");
  return out;
}

// Uygulama her isteği diskten okur (belgeler, sürümler, notlar): önbellek yok, sayfalar dinamik.
const nextConfig: NextConfig = {
  devIndicators: false,
  turbopack: {
    root: process.cwd(),
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
  async redirects() {
    return legacyRedirects();
  },
};

export default nextConfig;
