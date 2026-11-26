// Markdown görünümü: okuma ekranında sunucuda, düzenleyici önizlemesinde istemcide çalışır.
import Link from "next/link";
import type { ReactNode } from "react";
import ReactMarkdown, { type Components } from "react-markdown";
import { AssetStrip } from "@/components/doc/asset-strip";
import { ProgressOutline } from "@/components/progress/progress-outline";
import type { AssetCard } from "@/lib/assets";
import { sourceAlias } from "@/lib/ids";
import { CALLOUTS, type CalloutKind, REMARK_PLUGINS } from "@/lib/markdown";
import type { ProgressView } from "@/lib/progress";

export interface HeadingInfo {
  id: string;
  text: string;
  line: number;
  depth: number;
}

const AUDIO = /\.(mp3|wav|ogg|m4a)$/i;
const VIDEO = /\.(mp4|webm)$/i;
const RESEARCH_DOCS = new Set(["act1-script", "bozkir-ekonomi", "cadir-otag", "code-audit", "groups-research", "hayvanlar", "kopuz", "menu-spec", "mete-tarih", "mitoloji", "oyun-seviye-tasarimi", "sanat-animasyon", "ses-tasarimi", "varlik-hatti", "yoldaslar"]);
const DESIGN_DOCS = new Set(["decisions", "architecture", "act0-text", "act1", "army", "audio", "companions", "contract-requests", "economy", "fauna", "godot", "progression", "settlement", "story", "structures", "survival", "time", "travel", "weather"]);

// Metin içinde `time.md`, `d2/core.md` gibi belge adları o belgeye bağlanır.
function docHref(name: string): string | null {
  const match = name.match(/^(?:docs\/design\/|docs\/research\/)?(d[23]\/)?([a-z0-9-]+)\.md$/);
  if (!match) return null;
  const [, round, base] = match;
  if (round) return `/docs/source/design/${round}${sourceAlias(base)}`;
  if (DESIGN_DOCS.has(base)) return `/docs/source/design/${base}`;
  if (RESEARCH_DOCS.has(base)) return `/docs/source/research/${sourceAlias(base)}`;
  return null;
}

function nodeText(node: unknown): string {
  const n = node as { value?: string; children?: unknown[] };
  if (typeof n.value === "string") return n.value;
  return (n.children ?? []).map(nodeText).join("");
}

// «```varlik» ve «```ilerleme» bloklarındaki kimlikler: satır, virgül ya da boşlukla ayrılır.
const blockIds = (text: string) => text.split(/[\s,]+/).map((s) => s.trim()).filter(Boolean);

// Görev tablolarının satırları da bağlanabilir: ilk hücresi ya da ilk hücreden sonraki hücresi `mq_count` gibi bir görev
// kimliğiyle başlayan satır o kimliği çapa alır (/docs/source/design/act1#mq_count, story#mq2_hunt). Kimlik sayfada
// ilk geçtiği satırda çapadır; karar satırı kendi çapasını korur. Aynı hücrede «;» ile ardından gelen görevler (story.md
// §11'in aile tabloları) hücre içinde görünmez çapa alır (story#sq2_freed; satırı globals.css `tr:has(:target)` vurgular).
// src/lib/quests.ts aynı kuralla bağ kurar: bu dosya istemcide de çalıştığı için node:fs'li o modülü içe aktaramaz, kural
// iki yerde yazılıdır. scripts/quests-check.mjs (npm run quests) iki kopyanın kalıplarını ve bütün tasarım belgelerinde
// verdikleri çapaları karşılaştırır.
const QUEST_ROW = /^\s*\|\s*(?:[^|]*\|\s*)??`((?:mq|sq|cq)\d*_[a-z0-9_]+)`/;
const DECISION_ROW = /^\s*\|\s*[*_]*K\d{1,3}[*_]*\s*\|/;
const QUEST_ITEM = /;\s*`((?:mq|sq|cq)\d*_[a-z0-9_]+)`/g;

function questRowAnchors(source: string): Map<number, string> {
  const out = new Map<number, string>();
  const seen = new Set<string>();
  let fence = "";
  source.split("\n").forEach((line, index) => {
    const marker = line.match(/^ {0,3}(`{3,}|~{3,})/);
    if (marker) {
      if (!fence) fence = marker[1][0];
      else if (marker[1][0] === fence) fence = "";
      return;
    }
    if (fence || DECISION_ROW.test(line)) return;
    const id = line.match(QUEST_ROW)?.[1];
    if (!id || seen.has(id)) return;
    seen.add(id);
    out.set(index + 1, id);
  });
  return out;
}

// Hücre çapaları: anahtar «satır:sütun», ters tırnağın yeri (1'den). Kimlik sayfada bir satırın çapasıysa verilmez.
function questCellAnchors(lines: string[], rows: Map<number, string>): Map<string, string> {
  const out = new Map<string, string>();
  const taken = new Set(rows.values());
  for (const [line, id] of rows) {
    const text = lines[line - 1] ?? "";
    const start = text.indexOf(`\`${id}\``);
    const end = text.indexOf("|", start);
    for (const m of text.slice(start, end < 0 ? undefined : end).matchAll(QUEST_ITEM)) {
      if (taken.has(m[1])) continue;
      taken.add(m[1]);
      out.set(`${line}:${start + (m.index ?? 0) + m[0].indexOf("`") + 1}`, m[1]);
    }
  }
  return out;
}

// Hücre çapası satır çapası gibi üst çubuğun altında kalmasın (globals.css: .doc-table tr[id]).
const CELL_ANCHOR = { scrollMarginTop: "5rem" };

export function MarkdownView({
  source,
  headingExtra,
  assets,
  progress,
}: {
  source: string;
  headingExtra?: (heading: HeadingInfo) => ReactNode;
  assets?: Record<string, AssetCard>;
  progress?: ProgressView;
}) {
  const questRows = questRowAnchors(source);
  const questCells = questCellAnchors(source.split("\n"), questRows);
  const heading = (Tag: "h2" | "h3" | "h4", depth: number): Components["h2"] =>
    function HeadingBlock({ node, children, ...props }) {
      const info: HeadingInfo = { id: String(props.id ?? ""), text: nodeText(node), line: node?.position?.start.line ?? 1, depth };
      return (
        <Tag {...props} className="group/heading" data-title={info.text}>
          {children}
          {headingExtra?.(info)}
        </Tag>
      );
    };

  const components: Components = {
    h1: heading("h2", 1),
    h2: heading("h2", 2),
    h3: heading("h3", 3),
    h4: heading("h4", 4),
    pre: ({ node, children, ...props }) => {
      const inner = node?.children?.[0] as { type?: string; properties?: { className?: unknown } } | undefined;
      const classes = inner?.type === "element" && Array.isArray(inner.properties?.className) ? inner.properties.className : [];
      if (classes.includes("language-varlik")) return <AssetStrip ids={blockIds(nodeText(inner))} assets={assets} />;
      if (classes.includes("language-ilerleme")) return <ProgressOutline ids={blockIds(nodeText(inner))} progress={progress} />;
      return <pre {...props}>{children}</pre>;
    },
    table: ({ node: _node, ...props }) => (
      <div className="doc-table">
        <table {...props} />
      </div>
    ),
    // Karar tablosunun satırları bağlanabilir: «| K45 | …» satırı #k45 çapasını alır (/docs/source/design/decisions#k45).
    // Görev satırı görev kimliğini alır (questRowAnchors).
    tr: ({ node, ...props }) => {
      const first = (node?.children ?? []).find((c) => (c as { type?: string }).type === "element");
      const key = first ? nodeText(first).trim() : "";
      const id = /^K\d{1,3}$/.test(key) ? key.toLowerCase() : questRows.get(node?.position?.start.line ?? 0);
      return <tr id={id} {...props} />;
    },
    blockquote: ({ node: _node, children, ...props }) => {
      const kind = (props as Record<string, unknown>)["data-callout"] as CalloutKind | undefined;
      if (!kind) return <blockquote>{children}</blockquote>;
      return (
        <aside className="callout" data-callout={kind}>
          <div className="callout-label">{CALLOUTS[kind]}</div>
          {children}
        </aside>
      );
    },
    a: ({ node: _node, href = "", children }) => {
      if (href.startsWith("/")) return <Link href={href} prefetch={false}>{children}</Link>;
      if (href.startsWith("#")) return <a href={href}>{children}</a>;
      return <a href={href} target="_blank" rel="noreferrer">{children}</a>;
    },
    code: ({ node, className, children }) => {
      const text = typeof children === "string" ? children : null;
      const href = text && !className ? docHref(text) : null;
      if (href) return <Link href={href} prefetch={false}><code>{text}</code></Link>;
      const start = node?.position?.start;
      const anchor = text && start && questCells.get(`${start.line}:${start.column}`) === text ? text : null;
      if (anchor) {
        return (
          <>
            <span id={anchor} style={CELL_ANCHOR} />
            <code className={className}>{children}</code>
          </>
        );
      }
      return <code className={className}>{children}</code>;
    },
    img: ({ node: _node, src, alt }) => {
      if (typeof src !== "string") return null;
      if (AUDIO.test(src)) {
        return (
          <span className="doc-audio">
            <audio controls preload="none" src={src} />
            {alt ? <span>{alt}</span> : null}
          </span>
        );
      }
      if (VIDEO.test(src)) {
        // Poster varsa videonun yanında aynı adla .jpg durur: öncesinde kare görünür, video yalnız oynatınca iner.
        return (
          <span className="doc-figure">
            <video controls preload="metadata" src={src} poster={src.replace(VIDEO, ".jpg")} className="doc-video" />
            {alt ? <span className="doc-figure-caption">{alt}</span> : null}
          </span>
        );
      }
      const portrait = src.includes("/portraits/");
      return (
        <span className={portrait ? "doc-figure is-portrait" : "doc-figure"}>
          <a href={src} target="_blank" rel="noreferrer" tabIndex={-1}>
            {/* Yerel, boyutu belirsiz dosya: next/image gerekmez. */}
            <img src={src} alt={alt ?? ""} loading="lazy" />
          </a>
          {alt ? <span className="doc-figure-caption">{alt}</span> : null}
        </span>
      );
    },
  };

  return (
    <ReactMarkdown remarkPlugins={REMARK_PLUGINS} components={components}>
      {source}
    </ReactMarkdown>
  );
}
