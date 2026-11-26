"use client";

// Bir görevin kartı. Varsayılan özettir: uzun alanlar birkaç satırda kesilir, adımların, bayrakların ve başka belgelerdeki
// anışların ilk birkaçı görünür. «Ayrıntı» tam metni, adımların ayrıntısını ve belgedeki özgün satırı açar; özgün satır
// sayfayla gelmez (yükü büyütür), ilk açılışta /quests/raw'dan istenir. Yoldaş görevinin adımları merdiven olarak çizilir:
// eşik (`ties`), zaman ve seçili perdedeki adım. Adımı boş görevin kartı tanım cümlesi, anışlar ve göndermelerle dolar.
// Belgeye giden bağlar düz <a>'dır: Next'in istemci içi geçişinde tarayıcı :target'ı güncellemez, satır vurgusu çıkmaz.
import { ChevronDown, FileText } from "lucide-react";
import Link from "next/link";
import { memo, useContext, useState } from "react";
import type { ClientQuest, QuestKind, QuestStatus, QuestStep } from "@/lib/quests";
import { type ActKey, type ActLookup, actKeyOf, formatNumber, KIND_LABEL, STATUS, stepActKeys } from "./quest-filter";
import { QuestLink, QuestNavContext, RichText } from "./rich-text";

const FLAG_LIMIT = 6;
const STEP_LIMIT = 3;
const MENTION_LIMIT = 2;

// Belge başlığı bağda kısa yazılır: sondaki uzun parantez (saat, süre) düşer.
const shortHeading = (title: string) => title.replace(/\s*\([^()]{25,}\)$/, "").trim();
// Göndermenin etiketi bölüm numarasını taşır («act1.md §8.4»): başlıktaki numara yinelenmez.
const refHeading = (title: string) => shortHeading(title).replace(/^\d+(?:\.\d+)*\.?\s+/, "");

export function StatusChip({ status }: { status: QuestStatus }) {
  const s = STATUS[status] ?? STATUS.design;
  return (
    <span className="qst-status" data-status={status}>
      <span aria-hidden="true">{s.glyph}</span>
      <span className="sr-only">Durum: </span>
      {s.label}
    </span>
  );
}

// Eşik yalnız sayıysa yoldaş onayıdır: «6» → «`ties` ≥ 6».
function thresholdText(value: string): string {
  return /^\d+$/.test(value.trim()) ? `\`ties\` ≥ ${value.trim()}` : value;
}

const hasMeta = (s: QuestStep) => Boolean(s.label || s.when || s.threshold);

function Steps({ quest, open }: { quest: ClientQuest; open: boolean }) {
  const steps = (quest.steps ?? []).filter((s) => s.text?.trim());
  if (steps.length === 1 && !hasMeta(steps[0]) && !steps[0].detail) {
    return (
      <dd className={open ? undefined : "qst-clamp3"}>
        <RichText text={steps[0].text} from={quest.kind} />
      </dd>
    );
  }
  const shown = open ? steps : steps.slice(0, STEP_LIMIT);
  return (
    <dd>
      <ol className="qst-steps">
        {shown.map((s, i) => (
          <li key={i}>
            {hasMeta(s) ? (
              <span className="qst-step-meta">
                {s.label ? <strong>{s.label} </strong> : null}
                {s.when ? (
                  <span>
                    <RichText text={s.when} from={quest.kind} />{" "}
                  </span>
                ) : null}
                {s.threshold ? (
                  <span>
                    <RichText text={thresholdText(s.threshold)} from={quest.kind} />{" "}
                  </span>
                ) : null}
              </span>
            ) : null}
            <span className={open ? "qst-step-text" : "qst-step-text qst-clamp3"}>
              <RichText text={s.text} from={quest.kind} />
            </span>
            {open && s.detail ? (
              <span className="qst-step-detail">
                <RichText text={s.detail} from={quest.kind} />
              </span>
            ) : null}
          </li>
        ))}
      </ol>
      {steps.length > shown.length ? <p className="qst-more-note">+{steps.length - shown.length} adım daha</p> : null}
    </dd>
  );
}

function Ladder({ quest, act, open }: { quest: ClientQuest; act: ActKey | null; open: boolean }) {
  const steps = quest.steps ?? [];
  // «bu perdede»: adımın perdeleri perde süzgeciyle aynı kuralla okunur («III ya da IV», yalnız `mq4_dailin_ordos`).
  const nav = useContext(QuestNavContext);
  const lookup: ActLookup = (id) => {
    const q = nav?.byId.get(id);
    return q ? actKeyOf(q.act) : null;
  };
  return (
    <ol className="qst-ladder" aria-label="Adımlar">
      {steps.map((s, i) => {
        const last = i === steps.length - 1;
        const here = act !== null && stepActKeys(s.when, lookup).includes(act);
        const label = s.label?.trim() || `${i + 1}. adım`;
        return (
          <li key={i} data-current={here || undefined}>
            <span className="qst-rung" aria-hidden="true">
              {i + 1}
            </span>
            <div className="qst-rung-body">
              <p className="qst-rung-head">
                <strong>{label} </strong>
                {last && steps.length > 1 && !/\bson\b/i.test(label) ? <span className="qst-tag">son </span> : null}
                {here ? <span className="qst-tag">bu perdede </span> : null}
                {s.when ? (
                  <span>
                    <RichText text={s.when} from={quest.kind} />{" "}
                  </span>
                ) : null}
                {s.threshold ? (
                  <span className="qst-threshold">
                    eşik <RichText text={thresholdText(s.threshold)} from={quest.kind} />
                  </span>
                ) : null}
              </p>
              <p className="qst-rung-text">
                <RichText text={s.text} from={quest.kind} />
              </p>
              {open && s.detail && s.detail !== s.text ? (
                <p className="qst-step-detail">
                  <RichText text={s.detail} from={quest.kind} />
                </p>
              ) : null}
            </div>
          </li>
        );
      })}
    </ol>
  );
}

type CardProps = {
  quest: ClientQuest;
  level: 3 | 4;
  // Bağla gelinen kart: kalıcı çerçeve; flash her gelişte değişir ki vurgu yeniden oynasın.
  target: boolean;
  flash: "a" | "b" | null;
  act: ActKey | null;
};

// Belgedeki özgün satırın yüklenişi: ilk «Ayrıntı»da istenir, kart takılı kaldıkça yeniden istenmez.
type RawState = { status: "idle" | "loading" | "error" } | { status: "done"; text: string };

export const QuestCard = memo(function QuestCard({ quest, level, target, flash, act }: CardProps) {
  const [open, setOpen] = useState(false);
  const [raw, setRaw] = useState<RawState>({ status: "idle" });
  const Heading = level === 3 ? "h3" : "h4";
  const companion = quest.kind === "companion";
  const { steps = [], flags: allFlags = [], otherIds = [], related = [], progress = [], refs = [], elsewhere = [] } = quest;
  const flags = open ? allFlags : allFlags.slice(0, FLAG_LIMIT);
  const mentions = open ? elsewhere : elsewhere.slice(0, MENTION_LIMIT);
  // Her görevin belgede bir satırı vardır, «Ayrıntı» en azından onu açar. Hata olursa yeniden açınca yeniden istenir.
  const loadRaw = () => {
    if (raw.status === "loading" || raw.status === "done") return;
    setRaw({ status: "loading" });
    fetch(`/quests/raw?id=${encodeURIComponent(quest.id)}`, { cache: "no-store" })
      .then((res) => (res.ok ? res.text() : Promise.reject(new Error(`HTTP ${res.status}`))))
      .then((text) => setRaw({ status: "done", text }))
      .catch(() => setRaw({ status: "error" }));
  };
  const toggle = () => {
    if (!open) loadRaw();
    setOpen(!open);
  };
  const bodyId = `${quest.id}-body`;
  const titleId = `${quest.id}-title`;
  const xp = quest.xp && quest.xp > 0 ? quest.xp : null;
  // Parça parça ödülde rozet en çok XP'yi yazar («Direk başına 5 XP …» → en çok 75 XP); bölüm toplamı da bunu toplar.
  const xpMax = xp && quest.xpMax && quest.xpMax > xp ? quest.xpMax : null;

  return (
    <article
      id={quest.id}
      className="qst-card"
      aria-labelledby={titleId}
      data-status={quest.status}
      data-open={open || undefined}
      data-target={target || undefined}
      data-flash={target && flash ? flash : undefined}
    >
      <div className="qst-card-top">
        {companion && quest.family ? <span className="qst-eyebrow">{quest.family}</span> : <code className="qst-id">{quest.id}</code>}{" "}
        <StatusChip status={quest.status} />
      </div>
      <Heading id={titleId} className="qst-title" tabIndex={-1} data-quest-heading="">
        {quest.titleTr}
        {quest.titleEn ? (
          <>
            {" "}
            <span lang="en" className="qst-title-en">
              {quest.titleEn}
            </span>
          </>
        ) : null}
      </Heading>
      {companion || quest.when || quest.place || xp ? (
        <p className="qst-meta">
          {companion ? <code className="qst-id">{quest.id} </code> : null}
          {quest.when ? (
            <span>
              <span className="sr-only">Zaman: </span>
              <RichText text={quest.when} from={quest.kind} />{" "}
            </span>
          ) : null}
          {quest.place ? (
            <span>
              <span className="qst-meta-label">Yer</span> <RichText text={quest.place} from={quest.kind} />{" "}
            </span>
          ) : null}
          {xp ? <span className="qst-xp">{xpMax ? `en çok ${formatNumber(xpMax)}` : formatNumber(xp)} XP</span> : companion ? <span className="qst-no-xp">XP yok</span> : null}
        </p>
      ) : null}

      <div id={bodyId}>
        {quest.description ? (
          <p className="qst-description">
            <RichText text={quest.description} from={quest.kind} self={quest.id} />
          </p>
        ) : !companion && !steps.length ? (
          <p className="qst-bare-note">Aile tablosunda yalnız adı yazılı.</p>
        ) : null}
        {companion && steps.length ? <Ladder quest={quest} act={act} open={open} /> : null}
        {quest.trigger || (!companion && steps.length) || quest.reward || quest.outcome ? (
          <dl className="qst-fields">
            {quest.trigger ? (
              <>
                <dt>Tetik</dt>
                <dd className={open ? undefined : "qst-clamp2"}>
                  <RichText text={quest.trigger} from={quest.kind} />
                </dd>
              </>
            ) : null}
            {!companion && steps.length ? (
              <>
                {/* II–VI aile tablolarındaki parantez içi tek satır adım değil, görevin notudur. */}
                <dt>{quest.kind === "side" && quest.act !== "I" && steps.length === 1 ? "Not" : "Adımlar"}</dt>
                <Steps quest={quest} open={open} />
              </>
            ) : null}
            {quest.reward ? (
              <>
                <dt>Ödül</dt>
                <dd className={open ? undefined : "qst-clamp2"}>
                  <RichText text={quest.reward} xp from={quest.kind} />
                </dd>
              </>
            ) : null}
            {quest.outcome ? (
              <>
                <dt>Dallanma → yankı</dt>
                <dd className={open ? undefined : "qst-clamp3"}>
                  <RichText text={quest.outcome} from={quest.kind} />
                </dd>
              </>
            ) : null}
          </dl>
        ) : null}

        {elsewhere.length ? (
          <div className="qst-mentions">
            <p className="qst-row-label">Başka belgelerde</p>
            <ul>
              {mentions.map((m, i) => (
                <li key={`${m.href}-${i}`}>
                  <a href={m.href} className="qst-qlink">
                    <code>{m.doc}</code> {shortHeading(m.title)}
                  </a>
                  <span className={open ? "qst-mention-text" : "qst-mention-text qst-clamp2"}>
                    <RichText text={m.text} from={quest.kind} self={quest.id} />
                  </span>
                </li>
              ))}
            </ul>
            {elsewhere.length > mentions.length ? <p className="qst-more-note">+{elsewhere.length - mentions.length} anış daha</p> : null}
          </div>
        ) : null}

        {allFlags.length ? (
          <div className="qst-row">
            <span className="qst-row-label">Bayraklar</span>
            <ul className="qst-flags">
              {flags.map((flag) => (
                <li key={flag} className="qst-flag">
                  {flag}
                </li>
              ))}
              {allFlags.length > flags.length ? <li className="qst-more-note">+{allFlags.length - flags.length}</li> : null}
            </ul>
          </div>
        ) : null}

        {otherIds.length ? (
          <div className="qst-row">
            <span className="qst-row-label">Kimlikler</span>
            <ul className="qst-flags">
              {otherIds.map((id) => (
                <li key={id} className="qst-flag">
                  {id}
                </li>
              ))}
            </ul>
          </div>
        ) : null}

        {related.length ? (
          <div className="qst-row">
            <span className="qst-row-label">İlgili</span>
            <ul className="qst-related">
              {related.map((id) => (
                <li key={id}>
                  <QuestLink id={id} from={quest.kind}>
                    <RelatedLabel id={id} from={quest.kind} />
                  </QuestLink>
                </li>
              ))}
            </ul>
          </div>
        ) : null}

        {refs.length ? (
          <div className="qst-row">
            <span className="qst-row-label">Göndermeler</span>
            <ul className="qst-related">
              {refs.map((r) => (
                <li key={r.href}>
                  <a href={r.href} className="qst-qlink">
                    <code>{r.label}</code> {refHeading(r.title)}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        ) : null}

        {open ? (
          <div className="qst-raw" aria-busy={raw.status === "loading" || undefined}>
            <p className="qst-row-label">Belgedeki metin</p>
            {raw.status === "done" ? (
              <pre>{raw.text}</pre>
            ) : raw.status === "error" ? (
              <p className="qst-more-note">Belgedeki satır alınamadı; «Belgede aç» bağı onu belgede gösterir.</p>
            ) : (
              <p className="qst-more-note">Belgedeki satır yükleniyor…</p>
            )}
          </div>
        ) : null}
      </div>

      <div className="qst-card-foot">
        <button type="button" className="qst-more-button" aria-expanded={open} aria-controls={bodyId} onClick={toggle}>
          <ChevronDown aria-hidden="true" />
          {open ? "Özete dön" : "Ayrıntı"}
        </button>
        <span className="qst-foot-links">
          {progress.length ? (
            <span className="qst-progress-links">
              Yol Haritası:{" "}
              {progress.map((id, i) => (
                <span key={id}>
                  {i ? ", " : null}
                  <Link href={`/roadmap#item-${id}`} prefetch={false} className="qst-source-link">
                    {id}
                  </Link>
                </span>
              ))}
            </span>
          ) : null}
          <a href={quest.source.href} className="qst-source-link">
            <FileText aria-hidden="true" />
            Belgede aç
            <span className="qst-source-doc">{quest.source.doc}</span>
          </a>
        </span>
      </div>
    </article>
  );
});

// İlgili görev bağının görünen adı: kimlik ve Türkçe ad; başka sekmedeyse türü de yazar.
function RelatedLabel({ id, from }: { id: string; from: QuestKind }) {
  const quest = useContext(QuestNavContext)?.byId.get(id);
  if (!quest) return <code>{id}</code>;
  return (
    <>
      <code>{id}</code> {quest.titleTr}
      {quest.kind !== from ? <span className="qst-related-kind"> · {KIND_LABEL[quest.kind].toLocaleLowerCase("tr-TR")}</span> : null}
    </>
  );
}
