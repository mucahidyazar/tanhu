"use client";

// Dar ekranda üst çubuk: kenar çubuğu çekmecede açılır.
import { Menu } from "lucide-react";
import { useState } from "react";
import { GameIcon } from "@/components/brand";
import { Sidebar } from "@/components/shell/sidebar";
import { Sheet, SheetContent, SheetTitle } from "@/components/ui/sheet";
import type { NavData } from "@/lib/nav";

export function MobileNav({ nav }: { nav: NavData }) {
  const [open, setOpen] = useState(false);
  return (
    <div className="sticky top-0 z-30 flex items-center gap-2 border-b bg-sidebar px-3 py-2 text-sidebar-foreground lg:hidden">
      <button type="button" aria-label="Belgeleri aç" onClick={() => setOpen(true)} className="rounded-sm p-1.5 hover:bg-sidebar-accent">
        <Menu className="size-5" />
      </button>
      <GameIcon className="size-6" />
      <span className="font-display text-sm tracking-[0.14em]">TANHU</span>
      <Sheet open={open} onOpenChange={setOpen}>
        <SheetContent side="left" className="w-80 max-w-[85vw] bg-sidebar p-0 text-sidebar-foreground" showCloseButton={false}>
          <SheetTitle className="sr-only">Belgeler</SheetTitle>
          <Sidebar nav={nav} onNavigate={() => setOpen(false)} />
        </SheetContent>
      </Sheet>
    </div>
  );
}
