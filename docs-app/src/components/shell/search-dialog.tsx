"use client";

// Komut paleti: ⌘K ile açılır, bütün belgelerde tam metin arar.
import { FileText, Loader2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { Command, CommandDialog, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from "@/components/ui/command";
import type { SearchHit } from "@/lib/search";

const OPEN_EVENT = "tanhu:ara";

export const openSearch = () => window.dispatchEvent(new Event(OPEN_EVENT));

export function SearchDialog() {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [hits, setHits] = useState<SearchHit[]>([]);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setOpen((v) => !v);
      }
    };
    const onOpen = () => setOpen(true);
    window.addEventListener("keydown", onKey);
    window.addEventListener(OPEN_EVENT, onOpen);
    return () => {
      window.removeEventListener("keydown", onKey);
      window.removeEventListener(OPEN_EVENT, onOpen);
    };
  }, []);

  useEffect(() => {
    if (query.trim().length < 2) {
      setHits([]);
      setBusy(false);
      return;
    }
    const controller = new AbortController();
    setBusy(true);
    const timer = setTimeout(() => {
      fetch(`/api/search?q=${encodeURIComponent(query)}`, { signal: controller.signal })
        .then((r) => r.json())
        .then((rows: SearchHit[]) => setHits(rows))
        .catch(() => {})
        .finally(() => {
          // İptal edilen istek, yerine başlayanın «aranıyor» durumunu kapatmasın.
          if (!controller.signal.aborted) setBusy(false);
        });
    }, 160);
    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [query]);

  const pages = hits.filter((h) => h.kind === "sayfa");
  const sources = hits.filter((h) => h.kind === "kaynak");
  const lore = hits.filter((h) => h.kind === "ansiklopedi");
  const go = (hit: SearchHit) => {
    setOpen(false);
    router.push(hit.href ?? `/docs/${hit.id}${hit.anchor ? `#${hit.anchor}` : ""}`);
  };
  const row = (hit: SearchHit) => (
    <CommandItem key={hit.id} value={hit.id} onSelect={() => go(hit)} className="items-start">
      <FileText className="mt-0.5 size-4 shrink-0" />
      <span className="min-w-0">
        <span className="block font-medium">
          {hit.title}
          <span className="ml-2 text-xs font-normal text-muted-foreground">{hit.section || hit.group}</span>
        </span>
        <span className="line-clamp-2 block text-xs text-muted-foreground">{hit.snippet}</span>
      </span>
    </CommandItem>
  );

  return (
    <CommandDialog open={open} onOpenChange={setOpen} title="Belgelerde ara" description="Sayfa adı ya da metindeki bir sözcük yaz" className="sm:max-w-2xl">
      <Command shouldFilter={false}>
        <CommandInput placeholder="Örneğin: yurt kurma süresi, Kut, Kara Boran" value={query} onValueChange={setQuery} />
        <CommandList className="max-h-[60vh]">
          {query.trim().length >= 2 && !busy && <CommandEmpty>Bu sözcük hiçbir belgede yok.</CommandEmpty>}
          {busy && hits.length === 0 && (
            <div className="flex items-center gap-2 p-4 text-sm text-muted-foreground">
              <Loader2 className="size-4 animate-spin" /> Aranıyor
            </div>
          )}
          {lore.length > 0 && <CommandGroup heading="Ansiklopedi">{lore.map(row)}</CommandGroup>}
          {pages.length > 0 && <CommandGroup heading="Sayfalar">{pages.map(row)}</CommandGroup>}
          {sources.length > 0 && <CommandGroup heading="Kaynak belgeler">{sources.map(row)}</CommandGroup>}
        </CommandList>
      </Command>
    </CommandDialog>
  );
}
