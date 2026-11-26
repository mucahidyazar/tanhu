// Sayfa içi yol haritası: «```ilerleme» bloğu. Bir perdenin kimliği o perdenin fazlarını ve maddelerini, bir fazın
// kimliği yalnız o fazı gösterir. Durumlar İlerleme'den (content/progress.json) canlı gelir; bileşen dosya okumaz.
import { InlineText } from "@/components/progress/inline-text";
import Link from "next/link";
import type { Phase, ProgressView } from "@/lib/progress";
import type { ProgressState } from "@/lib/statuses";

const GLYPH: Record<ProgressState, string> = { bitti: "✓", suruyor: "◐", yapilacak: "○" };
const LABEL: Record<ProgressState, string> = { bitti: "bitti", suruyor: "sürüyor", yapilacak: "yapılacak" };

function PhaseOutline({ phase, index, progress }: { phase: Phase; index: number; progress: ProgressView }) {
  const items = progress.items.filter((i) => i.phase === phase.id);
  const done = items.filter((i) => i.status === "bitti").length;
  return (
    <div className="doc-progress-phase">
      <div className="doc-progress-head">
        <span>
          <span className="doc-progress-index">Faz {index}</span> {phase.title}
        </span>
        <Link href={`/roadmap#${phase.id}`} prefetch={false}>
          {done} / {items.length}
        </Link>
      </div>
      {phase.exit ? <p className="doc-progress-exit">Çıkış ölçütü: <InlineText text={phase.exit} /></p> : null}
      {items.length ? (
        <ul className="doc-progress-items">
          {items.map((item) => (
            <li key={item.id} data-status={item.status}>
              <span className="doc-progress-glyph" aria-label={LABEL[item.status]} title={LABEL[item.status]}>
                {GLYPH[item.status]}
              </span>
              <span>
                <InlineText text={item.title} />
                {item.area ? <span className="doc-progress-area"> · {item.area}</span> : null}
              </span>
            </li>
          ))}
        </ul>
      ) : (
        <p className="doc-progress-exit">Bu fazda henüz madde yok.</p>
      )}
    </div>
  );
}

export function ProgressOutline({ ids, progress }: { ids: string[]; progress?: ProgressView }) {
  if (!progress) {
    return (
      <div className="doc-progress">
        <p className="doc-progress-exit">Yol haritası: {ids.join(", ")} (İlerleme verisi bu görünümde yok).</p>
      </div>
    );
  }
  return (
    <div className="doc-progress">
      {ids.map((id) => {
        const act = progress.acts.find((a) => a.id === id);
        const phase = act ? null : progress.phases.find((p) => p.id === id);
        if (!act && !phase) {
          return (
            <p key={id} className="doc-progress-missing">
              İlerleme'de böyle bir perde ya da faz yok: <code>{id}</code>
            </p>
          );
        }
        const actId = act ? act.id : phase!.act;
        const ordered = progress.phases.filter((p) => p.act === actId);
        const shown = act ? ordered : [phase!];
        return (
          <div key={id} className="doc-progress-act">
            {shown.map((p) => (
              <PhaseOutline key={p.id} phase={p} index={ordered.indexOf(p) + 1} progress={progress} />
            ))}
          </div>
        );
      })}
    </div>
  );
}
