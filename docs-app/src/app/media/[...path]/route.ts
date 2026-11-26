// Projedeki görsel ve ses dosyalarını belgelere verir: yalnız docs/research ve public altından, yalnız izinli uzantılarla.
import fs from "node:fs";
import path from "node:path";
import { Readable } from "node:stream";
import type { NextRequest } from "next/server";
import { REPO_ROOT } from "@/lib/catalog";

// Belgelerin görselleri docs/ altında, oyunun görselleri ve sesleri game/ (Godot projesi) altındadır.
const ROOTS = ["docs/", "game/"];
const TYPES: Record<string, string> = {
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".gif": "image/gif",
  ".mp3": "audio/mpeg",
  ".wav": "audio/wav",
  ".ogg": "audio/ogg",
  ".mp4": "video/mp4",
  ".webm": "video/webm",
  // Ansiklopedinin 3B görünümü (model-viewer) Godot projesindeki karakter modellerini okur.
  ".glb": "model/gltf-binary",
};

export async function GET(request: NextRequest, { params }: { params: Promise<{ path: string[] }> }) {
  const { path: parts } = await params;
  const rel = parts.map(decodeURIComponent).join("/");
  const full = path.resolve(REPO_ROOT, rel);
  const inside = path.relative(REPO_ROOT, full).replace(/\\/g, "/");
  const type = TYPES[path.extname(full).toLowerCase()];
  if (!type || inside.startsWith("..") || !ROOTS.some((root) => inside.startsWith(root)) || !fs.existsSync(full)) {
    return new Response("Bulunamadı", { status: 404 });
  }
  const { size } = fs.statSync(full);
  const headers = { "Content-Type": type, "Accept-Ranges": "bytes", "Cache-Control": "no-cache" };
  // Ses ve video oynatıcı ileri sarmak için aralık ister.
  const range = request.headers.get("range")?.match(/^bytes=(\d*)-(\d*)$/);
  if (range) {
    const start = range[1] ? Number(range[1]) : 0;
    const end = Math.min(range[2] ? Number(range[2]) : size - 1, size - 1);
    if (start > end) return new Response(null, { status: 416, headers: { "Content-Range": `bytes */${size}` } });
    const stream = Readable.toWeb(fs.createReadStream(full, { start, end })) as ReadableStream;
    return new Response(stream, { status: 206, headers: { ...headers, "Content-Range": `bytes ${start}-${end}/${size}`, "Content-Length": String(end - start + 1) } });
  }
  return new Response(Readable.toWeb(fs.createReadStream(full)) as ReadableStream, { headers: { ...headers, "Content-Length": String(size) } });
}
