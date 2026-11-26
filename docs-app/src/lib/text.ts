// Türkçe metin yardımcıları: arama ve bölüm bağı için katlama, tarih biçimi (sunucu ve istemci).

const FOLD: Record<string, string> = {
  ı: "i", İ: "i", I: "i", ş: "s", Ş: "s", ğ: "g", Ğ: "g", ç: "c", Ç: "c", ö: "o", Ö: "o", ü: "u", Ü: "u",
};

// «Gün Işığı» → «gun isigi»: aramada «isik» «ışık»ı bulur. Harf sayısı korunur: katlanmış metindeki konum özgün metinde de geçerlidir.
export function fold(text: string): string {
  return text
    .replace(/[ıİIşŞğĞçÇöÖüÜ]/g, (c) => FOLD[c] ?? c)
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "");
}

export function slugify(text: string): string {
  return fold(text).replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "bolum";
}

const LONG = new Intl.DateTimeFormat("tr-TR", { day: "numeric", month: "long", year: "numeric", hour: "2-digit", minute: "2-digit" });
const SHORT = new Intl.DateTimeFormat("tr-TR", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" });

export const formatLong = (iso: string) => LONG.format(new Date(iso));
export const formatShort = (iso: string) => SHORT.format(new Date(iso));
