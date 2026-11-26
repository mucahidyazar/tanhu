// Oyunun simgesi, boy damgası (src/core/textures.js drawTamga) ve yurt kuşağı.
import { cn } from "@/lib/utils";

// Oyunun simgesi: Godot projesinin game/icon.png dosyasından küçültülmüş kopya (public/brand). Yanında ad yazdığı için
// ekran okuyucuya gizlidir. Favicon ve uygulama simgesi de aynı dosyadan üretildi (src/app/favicon.ico, icon.png).
export function GameIcon({ className, large = false }: { className?: string; large?: boolean }) {
  return (
    // Yerel, sabit boyutlu küçük görsel: next/image gerekmez.
    <img
      src={large ? "/brand/tanhu-icon-256.webp" : "/brand/tanhu-icon.webp"}
      alt=""
      aria-hidden="true"
      width={large ? 256 : 96}
      height={large ? 256 : 96}
      className={cn("shrink-0 rounded-[22%] shadow-sm", className)}
    />
  );
}

export function Tamga({ className }: { className?: string }) {
  return (
    <svg viewBox="-1 -1 2 2" className={className} aria-hidden="true" fill="none" stroke="currentColor" strokeWidth={0.11} strokeLinecap="round" strokeLinejoin="round">
      <circle cx="0" cy="-0.02" r="0.62" />
      <path d="M0 -0.95V0.95M-0.46 -0.52L0 -0.1L0.46 -0.52M-0.34 0.5L0 0.2L0.34 0.5" />
    </svg>
  );
}

export function Kusak({ className }: { className?: string }) {
  return <div aria-hidden="true" className={cn("kusak", className)} />;
}
