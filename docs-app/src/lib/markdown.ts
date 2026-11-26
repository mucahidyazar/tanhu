// Markdown yardımcıları: başlık kimlikleri ve özel kutular. Okuma ekranı ve düzenleyici önizlemesi aynı eklentileri kullanır.
import type { Blockquote, Heading as MdHeading, Paragraph, Root, Text } from "mdast";
import { toString } from "mdast-util-to-string";
import remarkGfm from "remark-gfm";
import remarkParse from "remark-parse";
import { unified } from "unified";
import { visit } from "unist-util-visit";
import { slugify } from "./text";

export interface Heading {
  depth: number;
  text: string;
  id: string;
  line: number;
}

export const CALLOUTS = {
  not: "Senin notun",
  celiski: "Çelişki",
  oneri: "Öneri",
  acik: "Açık soru",
  durum: "Oyunda şu an",
} as const;
export type CalloutKind = keyof typeof CALLOUTS;

const unique = (seen: Map<string, number>, base: string) => {
  const n = seen.get(base) ?? 0;
  seen.set(base, n + 1);
  return n === 0 ? base : `${base}-${n}`;
};

// Başlıklara kimlik yazar: içindekiler, not bağı ve kaynak bağları aynı kimliği kullanır.
export function remarkHeadingIds() {
  return (tree: Root) => {
    const seen = new Map<string, number>();
    visit(tree, "heading", (node: MdHeading) => {
      const id = unique(seen, slugify(toString(node)));
      node.data = { ...node.data, hProperties: { ...(node.data?.hProperties ?? {}), id } };
    });
  };
}

// «> [!CELISKI]» ile başlayan alıntı kutu olur: etiket metinden silinir, kutunun türü data-callout'a yazılır.
export function remarkCallouts() {
  return (tree: Root) => {
    visit(tree, "blockquote", (node: Blockquote) => {
      const first = node.children[0] as Paragraph | undefined;
      if (first?.type !== "paragraph") return;
      const lead = first.children[0] as Text | undefined;
      if (lead?.type !== "text") return;
      const match = lead.value.match(/^\[!([A-Za-zÇĞİIÖŞÜçğıöşü]+)\]\s*/);
      if (!match) return;
      const kind = slugify(match[1]);
      if (!(kind in CALLOUTS)) return;
      lead.value = lead.value.slice(match[0].length);
      if (!lead.value) first.children.shift();
      if (first.children.length === 0) node.children.shift();
      node.data = { ...node.data, hProperties: { ...(node.data?.hProperties ?? {}), "data-callout": kind } };
    });
  };
}

export const REMARK_PLUGINS = [remarkGfm, remarkHeadingIds, remarkCallouts];

// Metindeki başlıklar, bulundukları satırla (düzenleyici o satırda açılır).
export function extractHeadings(markdown: string): Heading[] {
  const tree = unified().use(remarkParse).use(remarkGfm).parse(markdown) as Root;
  const seen = new Map<string, number>();
  const out: Heading[] = [];
  visit(tree, "heading", (node: MdHeading) => {
    const text = toString(node);
    out.push({ depth: node.depth, text, id: unique(seen, slugify(text)), line: node.position?.start.line ?? 1 });
  });
  return out;
}

// Çözümleyicisiz başlık taraması: arama her eşleşen belgede çalıştırır, tam çözümleme orada saniyeler sürüyor.
// Kimlikleri remarkHeadingIds ile aynı üretir; kod blokları atlanır, satır içi işaretler silinir.
export function scanHeadings(markdown: string): Heading[] {
  const seen = new Map<string, number>();
  const out: Heading[] = [];
  let fence = "";
  markdown.split("\n").forEach((line, index) => {
    const marker = line.match(/^ {0,3}(`{3,}|~{3,})/);
    if (marker) {
      if (!fence) fence = marker[1][0];
      else if (marker[1][0] === fence) fence = "";
      return;
    }
    if (fence) return;
    const match = line.match(/^ {0,3}(#{1,6})[ \t]+(.+?)[ \t]*#*\s*$/);
    if (!match) return;
    const text = match[2].replace(/\[([^\]]*)\]\([^)]*\)/g, "$1").replace(/[*`]/g, "");
    out.push({ depth: match[1].length, text, id: unique(seen, slugify(text)), line: index + 1 });
  });
  return out;
}

export const countCallouts = (markdown: string, kind: string) => (markdown.match(new RegExp(`^>\\s*\\[!${kind}\\]`, "gm")) ?? []).length;
