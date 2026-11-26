// Komut paletinin tam metin araması.
import type { NextRequest } from "next/server";
import { search } from "@/lib/search";

export const dynamic = "force-dynamic";

export function GET(request: NextRequest) {
  return Response.json(search(request.nextUrl.searchParams.get("q") ?? ""));
}
