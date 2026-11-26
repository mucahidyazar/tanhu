// Varlık şeridi: sayfadaki «```varlik» bloğu ve sayfa sonundaki «Bu sayfanın varlıkları». Dosya okumaz; kartlar
// sunucudan gelir (lib/assets.ts), böylece okuma ekranında da düzenleyici önizlemesinde de çalışır.
import Link from "next/link";
import type { AssetCard } from "@/lib/assets";

export function AssetStrip({ cards, ids, assets }: { cards?: AssetCard[]; ids?: string[]; assets?: Record<string, AssetCard> }) {
  const items = cards?.map((card) => ({ id: card.id, card })) ?? (ids ?? []).map((id) => ({ id, card: assets?.[id] ?? null }));
  if (items.length === 0) return null;
  return (
    <div className="doc-assets">
      {items.map(({ id, card }) =>
        card ? (
          <Link key={id} href={`/assets/${card.group}#${card.id}`} prefetch={false} className="doc-asset">
            {/* Yerel küçük görsel: next/image gerekmez. */}
            {card.thumb ? <img src={card.thumb} alt="" loading="lazy" /> : <span className="doc-asset-empty">Görsel henüz yok</span>}
            <span className="doc-asset-name">{card.tr}</span>
          </Link>
        ) : (
          // Katalog verilmediyse (ör. eski sürüm görünümü) kimlik yalın gösterilir; verildiyse eksik kimlik işaretlenir.
          <span key={id} className={assets ? "doc-asset is-missing" : "doc-asset"} title={assets ? "Bu kimlik varlık kataloğunda yok" : undefined}>
            <span className="doc-asset-empty">{assets ? "Katalogda yok" : "Varlık"}</span>
            <span className="doc-asset-name">
              <code>{id}</code>
            </span>
          </span>
        ),
      )}
    </div>
  );
}
