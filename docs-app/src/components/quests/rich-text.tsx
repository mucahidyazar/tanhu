"use client";

// Görev metninin satır içi biçimi: `ters tırnak` kod olur, **kalın** kalın; ters tırnaklı bilinen bir görev kimliği o
// görevin kartına bağ olur (QuestNav), kartın kendi kimliği (self) bağ olmaz. İstenirse «30 XP» gibi ödüller vurgulanır.
import { createContext, Fragment, type MouseEvent, type ReactNode, useContext } from "react";
import type { ClientQuest, QuestKind } from "@/lib/quests";
import { KIND_LABEL, questHref } from "./quest-filter";

export type QuestNav = {
  byId: ReadonlyMap<string, ClientQuest>;
  // Kartı görünür kılar, ona kayar ve vurgular. Bağ yeni sekmede açılıyorsa (Ctrl, orta tuş) dokunmaz.
  go: (id: string, event?: MouseEvent<HTMLAnchorElement>) => void;
};

export const QuestNavContext = createContext<QuestNav | null>(null);

export function QuestLink({ id, from, children }: { id: string; from?: QuestKind; children?: ReactNode }) {
  const nav = useContext(QuestNavContext);
  const quest = nav?.byId.get(id);
  if (!nav || !quest) return <code className="qst-code">{id}</code>;
  // Yalnız kimlik görünüyorsa adı ipucu olarak yazılır; ad görünüyorsa ipucu gereksizdir.
  const other = from && from !== quest.kind ? ` · ${KIND_LABEL[quest.kind]}` : "";
  return (
    <a href={questHref(quest)} className="qst-qlink" title={children ? undefined : `${quest.titleTr}${other}`} onClick={(e) => nav.go(id, e)}>
      {children ?? <code>{id}</code>}
    </a>
  );
}

const XP = /(\d[\d.,]*\s?XP\b)/;

function Plain({ text, xp }: { text: string; xp: boolean }) {
  // Önce **kalın**, sonra XP: ikisi de kısa ve iç içe geçmez.
  const parts = text.split(/(\*\*[^*]+\*\*)/);
  return (
    <>
      {parts.map((part, i) => {
        if (part.startsWith("**") && part.endsWith("**") && part.length > 4) return <strong key={i}>{part.slice(2, -2)}</strong>;
        if (!xp) return <Fragment key={i}>{part}</Fragment>;
        return (
          <Fragment key={i}>
            {part.split(XP).map((bit, j) =>
              j % 2 === 1 ? (
                <strong key={j} className="qst-xp-inline">
                  {bit}
                </strong>
              ) : (
                <Fragment key={j}>{bit}</Fragment>
              ),
            )}
          </Fragment>
        );
      })}
    </>
  );
}

export function RichText({ text, xp = false, from, self }: { text: string; xp?: boolean; from?: QuestKind; self?: string }) {
  const nav = useContext(QuestNavContext);
  const parts = text.split("`");
  return (
    <>
      {parts.map((part, i) => {
        // Tek sayıda ters tırnak varsa son parça düz metin kalır.
        const isCode = i % 2 === 1 && i < parts.length - 1;
        if (!isCode) return <Plain key={i} text={i % 2 === 1 ? `\`${part}` : part} xp={xp} />;
        if (part !== self && nav?.byId.has(part)) return <QuestLink key={i} id={part} from={from} />;
        return (
          <code key={i} className="qst-code">
            {part}
          </code>
        );
      })}
    </>
  );
}
