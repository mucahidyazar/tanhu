// Düzenleme ekranı: sayfada gövde ve ön bilgi ayrı, kaynak belgede bütün dosya.
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { DocEditor } from "@/components/doc/doc-editor";
import { assetCards } from "@/lib/assets";
import { progressView } from "@/lib/progress";
import { bodyOf, getDoc, readDocText } from "@/lib/catalog";
import { syncDoc } from "@/lib/history";

export const dynamic = "force-dynamic";

type Props = {
  params: Promise<{ id: string[] }>;
  searchParams: Promise<{ line?: string; satir?: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const doc = getDoc((await params).id.map(decodeURIComponent).join("/"));
  return { title: doc ? `Düzenle: ${doc.title}` : "Düzenle" };
}

export default async function EditPage({ params, searchParams }: Props) {
  const doc = getDoc((await params).id.map(decodeURIComponent).join("/"));
  if (!doc) notFound();
  const { line: lineParam, satir } = await searchParams;
  const revision = syncDoc(doc);
  const text = readDocText(doc);
  const line = Number(lineParam ?? satir);
  return (
    <DocEditor
      key={doc.id}
      doc={{ id: doc.id, kind: doc.kind, title: doc.title, summary: doc.kind === "sayfa" ? doc.summary : "", status: doc.status, relPath: doc.relPath }}
      initialText={doc.kind === "sayfa" ? bodyOf(doc, text) : text}
      baseRev={revision.n}
      startLine={Number.isFinite(line) && line > 0 ? line : null}
      assets={assetCards()}
      progress={progressView()}
    />
  );
}
