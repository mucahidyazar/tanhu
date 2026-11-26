// Bir görevin belgedeki özgün satırı (markdown): kartın «Ayrıntı»sı ilk açılınca istenir, sayfayla gelmez (sayfanın
// yükünü büyütür). /quests/raw?id=sq_crow_war → düz metin; görev ya da satırı yoksa 404.
import type { NextRequest } from "next/server";
import { getQuestData } from "@/lib/quests";

export const dynamic = "force-dynamic";

const HEADERS = { "Content-Type": "text/plain; charset=utf-8", "Cache-Control": "no-store", "X-Content-Type-Options": "nosniff" };

export function GET(request: NextRequest) {
  const id = request.nextUrl.searchParams.get("id") ?? "";
  const raw = getQuestData().quests.find((q) => q.id === id)?.raw;
  if (!raw) return new Response("Görev ya da belgedeki satırı bulunamadı.", { status: 404, headers: HEADERS });
  return new Response(raw, { headers: HEADERS });
}
