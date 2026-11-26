// Ansiklopedi: oyunun mitolojisi ve önemli kişileri, oyunun Destan Kitabı görünümünde bir kitap (content/encyclopedia.json).
// /encyclopedia içindekiler, /encyclopedia/<kimlik> bir kayıt.
import "@fontsource/cinzel/700.css";
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { EncyclopediaBook } from "@/components/encyclopedia/book";
import { encyclopediaView } from "@/lib/encyclopedia";

export const dynamic = "force-dynamic";

type Props = { params: Promise<{ entry?: string[] }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const id = (await params).entry?.[0];
  const entry = id ? encyclopediaView().entries.find((e) => e.id === decodeURIComponent(id)) : null;
  return { title: entry ? `${entry.name} · Ansiklopedi` : "Ansiklopedi" };
}

export default async function EncyclopediaPage({ params }: Props) {
  const parts = (await params).entry ?? [];
  if (parts.length > 1) notFound();
  const { book, entries } = encyclopediaView();
  const id = parts[0] ? decodeURIComponent(parts[0]) : null;
  if (id && !entries.some((e) => e.id === id)) notFound();
  // Arka plan: oyunun ana menüsünün kamp görüntüsü (game/assets/_reference/menu_camp.png), bulanık ve küçük kopya.
  return <EncyclopediaBook book={book} entries={entries} initialId={id} backdrop="/brand/ency-backdrop.webp" />;
}
