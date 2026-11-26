"use client";

// Gözden geçirme işareti: sayfa sonra değişirse işaret kendiliğinden düşer.
import { Check, FileClock } from "lucide-react";
import { useTransition } from "react";
import { Button } from "@/components/ui/button";
import { setReviewedAction } from "@/lib/actions";

export function ReviewButton({ docId, state }: { docId: string; state: "tamam" | "degisti" | null }) {
  const [pending, startTransition] = useTransition();
  const toggle = (value: boolean) => startTransition(() => setReviewedAction(docId, value));
  if (state === "tamam") {
    return (
      <Button variant="secondary" size="sm" disabled={pending} onClick={() => toggle(false)} title="İşareti kaldır">
        <Check /> Gözden geçirildi
      </Button>
    );
  }
  return (
    <Button variant="outline" size="sm" disabled={pending} onClick={() => toggle(true)} title={state === "degisti" ? "Gözden geçirdikten sonra değişti" : undefined}>
      {state === "degisti" ? <FileClock /> : <Check />}
      {state === "degisti" ? "Değişti, yeniden bak" : "Gözden geçirdim"}
    </Button>
  );
}
