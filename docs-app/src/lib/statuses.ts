// Sayfa durumları: istemci bileşenleri de okur, bu yüzden catalog.ts'ten (node:fs) ayrıdır.
export const STATUSES = {
  oyunda: "Oyunda",
  kismen: "Kısmen oyunda",
  tasarim: "Yalnız tasarım",
  yeni: "Yeni istek",
} as const;
export type Status = keyof typeof STATUSES;
// Düzenleyicide «durum yok» seçeneği; dosyaya yazılmaz.
export const NO_STATUS = "yok";

// Godot ilerlemesindeki bir işin durumu (content/progress.json).
export const PROGRESS_STATES = { yapilacak: "Yapılacak", suruyor: "Sürüyor", bitti: "Bitti" } as const;
export type ProgressState = keyof typeof PROGRESS_STATES;

export const NOTE_KINDS ={ duzelt: "Düzeltilecek", karar: "Karar", soru: "Soru", fikir: "Fikir" } as const;
export type NoteKind = keyof typeof NOTE_KINDS;
