"use client";

// Yeni belge sürümü: bütün belgelerin o anki sürümünü adıyla damgalar.
import { Tag } from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { createReleaseAction } from "@/lib/actions";

export function ReleaseDialog({ suggested, changed }: { suggested: string; changed: number }) {
  const [open, setOpen] = useState(false);
  const [version, setVersion] = useState(suggested);
  const [title, setTitle] = useState("");
  const [note, setNote] = useState("");
  const [pending, startTransition] = useTransition();
  const save = () =>
    startTransition(async () => {
      try {
        const release = await createReleaseAction({ version, title, note });
        toast.success(`${release.version} oluşturuldu`);
        setOpen(false);
        setTitle("");
        setNote("");
      } catch (error) {
        toast.error(error instanceof Error ? error.message : "Sürüm oluşturulamadı");
      }
    });
  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger render={<Button size="sm" />}>
        <Tag /> Yeni sürüm
      </DialogTrigger>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Yeni belge sürümü</DialogTitle>
          <DialogDescription>Bütün belgelerin bugünkü hâli bu adla damgalanır. Son sürümden beri {changed} belge değişti.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-1.5">
          <Label htmlFor="rel-version">Sürüm</Label>
          <Input id="rel-version" value={version} onChange={(e) => setVersion(e.target.value)} className="w-32" />
        </div>
        <div className="grid gap-1.5">
          <Label htmlFor="rel-title">Başlık</Label>
          <Input id="rel-title" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Örneğin: İlk okuma düzeltmeleri" />
        </div>
        <div className="grid gap-1.5">
          <Label htmlFor="rel-note">Not</Label>
          <Textarea id="rel-note" rows={3} value={note} onChange={(e) => setNote(e.target.value)} />
        </div>
        <DialogFooter>
          <Button onClick={save} disabled={!version.trim() || pending}>Sürümü oluştur</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
