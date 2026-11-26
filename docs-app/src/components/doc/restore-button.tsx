"use client";

// Eski sürüme dönüş: metni geri getirir, yeni sürüm olarak yazar; hiçbir sürüm silinmez.
import { RotateCcw } from "lucide-react";
import { useRouter } from "next/navigation";
import { useTransition } from "react";
import { toast } from "sonner";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import { restoreAction } from "@/lib/actions";

export function RestoreButton({ docId, n, isSource }: { docId: string; n: number; isSource: boolean }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const restore = () =>
    startTransition(async () => {
      try {
        const revision = await restoreAction(docId, n);
        toast.success(`${n}. sürüme dönüldü (yeni sürüm ${revision.n})`);
        router.push(`/history/${docId}`);
      } catch (error) {
        toast.error(error instanceof Error ? error.message : "Geri dönülemedi");
      }
    });
  return (
    <AlertDialog>
      <AlertDialogTrigger render={<Button variant="outline" size="sm" disabled={pending} />}>
        <RotateCcw /> Bu sürüme dön
      </AlertDialogTrigger>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>{n}. sürüme dönülsün mü?</AlertDialogTitle>
          <AlertDialogDescription>
            Belgenin metni {n}. sürümdeki hâline döner ve bu yeni bir sürüm olarak kaydedilir. Bugünkü metin geçmişte kalır.
            {isSource ? " Bu bir kaynak belge: dosyası da değişir." : ""}
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>Vazgeç</AlertDialogCancel>
          <AlertDialogAction onClick={restore}>Bu sürüme dön</AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
