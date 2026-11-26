// Bir klip öbeğinin çeşit sayısı. On ve üzeri belirgindir (RICH_GROUP_MIN): hangi öbeğin yeterince çeşidi olduğu bir bakışta
// görünsün. Renge yaslanmaz: ekran okuyucuya sözle söylenir, zengin öbeğin sayısı görsel olarak da dolu rozettir. word: sayının
// çeşit olmadığı yerde (aramanın sonuç sayısı) okunan sözcük.
import { RICH_GROUP_MIN } from "@/components/animations/clip-text";
import { cn } from "@/lib/utils";

export function CountBadge({ count, rich = count >= RICH_GROUP_MIN, word = "çeşit" }: { count: number; rich?: boolean; word?: string }) {
  return (
    <span className={cn("anim-count", rich && "is-rich")}>
      <span aria-hidden="true">{count.toLocaleString("tr-TR")}</span>
      <span className="sr-only">{`, ${count.toLocaleString("tr-TR")} ${word}${rich ? `, ${RICH_GROUP_MIN} ve üzeri` : ""}`}</span>
    </span>
  );
}
