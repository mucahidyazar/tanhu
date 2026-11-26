// Animasyonlar: karakterlerin hareket klipleri (K90). Bir karakter seçilir, klibi oynatılır; klipler öbek öbek listelenir, en
// üstte kişinin sahnede oynadıkları ve çeşitleri (K91). Her klibin kaynağı (kendi alımı, taşıyıcıdan aktarım, metinden üretim, ters türetme, iskeletin
// hediyesi) yazar. Altta klip kütüphanesi ve kredisi. Veri docs/assets/animations/manifest.json'dadır (Godot aracı yazar). Adres
// paylaşılabilir: /animations?character=<id>&clip=<anahtar>&group=<öbek>&q=<arama>. Seçimi istemci adresten okur
// (AnimationStudio); üst bilgideki başlık aynı kuralla (selection.ts) yazılır.
import type { Metadata } from "next";
import { cache } from "react";
import { AnimationsBody } from "@/components/animations/sections";
import { firstParam, resolveSelection, selectionTitle } from "@/components/animations/selection";
import { Kusak } from "@/components/brand";
import { readAnimations } from "@/lib/animations";

export const dynamic = "force-dynamic";

type Props = { searchParams: Promise<Record<string, string | string[] | undefined>> };

// Aynı istekte üst bilgi ve sayfa dosyayı bir kez okur.
const load = cache(() => readAnimations());

export async function generateMetadata({ searchParams }: Props): Promise<Metadata> {
  const query = await searchParams;
  const view = load();
  const selection = view.state === "ok" ? resolveSelection(view, { character: firstParam(query.character), clip: firstParam(query.clip), group: firstParam(query.group) }) : null;
  return { title: selectionTitle(selection) };
}

export default function AnimationsPage() {
  return (
    <main className="mx-auto w-full min-w-0 max-w-6xl px-5 py-10 lg:px-10">
      <h1 className="font-display text-3xl font-medium tracking-wide">Animasyonlar</h1>
      <Kusak className="mt-3" />
      <p className="mt-4 max-w-3xl font-serif text-lg text-muted-foreground">
        Bir karakter seç, istediğin klibi oynat: her karakter bütün klipleri taşır, klibin nereden geldiği altında yazar. Bir Meshy hareketi bir kez satın alınır, öteki
        karakterlere ClipRetarget ile 0 krediyle aktarılır.
      </p>
      <AnimationsBody view={load()} />
    </main>
  );
}
