import "@fontsource/alegreya/400.css";
import "@fontsource/alegreya/400-italic.css";
import "@fontsource/alegreya/700.css";
import "@fontsource/alegreya-sans/400.css";
import "@fontsource/alegreya-sans/500.css";
import "@fontsource/alegreya-sans/700.css";
import "@fontsource/cinzel/500.css";
import "@fontsource/cinzel/600.css";
import "@fontsource/ibm-plex-mono/400.css";
import "./globals.css";
import type { Metadata } from "next";
import type { ReactNode } from "react";
import { MobileNav } from "@/components/shell/mobile-nav";
import { SearchDialog } from "@/components/shell/search-dialog";
import { Sidebar } from "@/components/shell/sidebar";
import { ThemeProvider } from "@/components/shell/theme-provider";
import { Toaster } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { buildNav } from "@/lib/nav";

// Her istek diskten okunur: belgeler uygulama dışından da değişebilir.
export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: { default: "Tanhu Belgeleri", template: "%s · Tanhu Belgeleri" },
  description: "Tanhu oyununun belgeleri: okuma, not alma, düzenleme ve sürüm geçmişi.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  const nav = buildNav();
  return (
    <html lang="tr" suppressHydrationWarning>
      <body className="antialiased">
        <ThemeProvider>
          <TooltipProvider>
            <div className="flex min-h-dvh">
              <aside className="sticky top-0 hidden h-dvh w-72 shrink-0 bg-sidebar text-sidebar-foreground lg:block">
                <Sidebar nav={nav} />
              </aside>
              <div className="flex min-w-0 flex-1 flex-col">
                <MobileNav nav={nav} />
                {children}
              </div>
            </div>
            <SearchDialog />
            <Toaster position="bottom-right" />
          </TooltipProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
