// Sayfa durumu: renge bağlı kalmasın diye biçimle de ayrılır (dolu, yarım, halka, baklava).
import { type Status, STATUSES } from "@/lib/statuses";
import { cn } from "@/lib/utils";

export function StatusGlyph({ status, className }: { status: Status | null; className?: string }) {
  if (!status) return null;
  return (
    <svg viewBox="0 0 12 12" className={cn("size-2.5 shrink-0", className)} role="img" aria-label={STATUSES[status]}>
      <title>{STATUSES[status]}</title>
      {status === "oyunda" && <circle cx="6" cy="6" r="4.5" fill="currentColor" />}
      {status === "kismen" && (
        <>
          <circle cx="6" cy="6" r="4.2" fill="none" stroke="currentColor" strokeWidth="1.4" />
          <path d="M6 1.8A4.2 4.2 0 0 0 6 10.2Z" fill="currentColor" />
        </>
      )}
      {status === "tasarim" && <circle cx="6" cy="6" r="4.2" fill="none" stroke="currentColor" strokeWidth="1.4" />}
      {status === "yeni" && <path d="M6 1.2L10.8 6L6 10.8L1.2 6Z" fill="none" stroke="currentColor" strokeWidth="1.4" />}
    </svg>
  );
}

export function StatusBadge({ status }: { status: Status | null }) {
  if (!status) return null;
  return (
    <span className="inline-flex items-center gap-1.5 rounded-sm border px-1.5 py-0.5 text-xs text-muted-foreground">
      <StatusGlyph status={status} />
      {STATUSES[status]}
    </span>
  );
}
