// Animasyonlar sayfasının sunucuda çizilen bölümleri: boş ve hata durumları, kredi özeti ve öbek öbek klip kütüphanesi tablosu.
// Etkileşimli kısım (seçici, oynatıcı, klip listesi) AnimationStudio'dadır; adresteki seçimi o okur ve doğrular (selection.ts).
import Link from "next/link";
import type { ReactNode } from "react";
import { AnimationStudio } from "@/components/animations/animation-studio";
import { tagLine } from "@/components/animations/clip-text";
import { CountBadge } from "@/components/animations/count-badge";
import type { AnimClip, AnimClipGroup, AnimClipInfo, AnimationsView } from "@/lib/animations";
import { formatLong } from "@/lib/text";

type Ready = Extract<AnimationsView, { state: "ok" }>;

const EXPORTER = "game/tools/clip_library_export.gd";
const DECISIONS_HREF = "/docs/source/design/decisions";
const fmt = (n: number) => n.toLocaleString("tr-TR");

export function AnimationsBody({ view }: { view: AnimationsView }) {
  if (view.state === "missing") {
    return (
      <Notice title="Animasyon kütüphanesi henüz yazılmadı">
        <p>
          Godot aracı <code>{EXPORTER}</code> çalışınca <code>{view.file}</code> ve her karakterin bütün kliplerini taşıyan GLB dosyası yazılır; sayfa onları buradan okur.
        </p>
        <p>
          Kural{" "}
          <Link href={`${DECISIONS_HREF}#k90`} prefetch={false}>
            K90
          </Link>
          : bir hareket bir kez satın alınır, öteki karakterler onu ClipRetarget ile alır.
        </p>
      </Notice>
    );
  }
  if (view.state === "invalid") {
    return (
      <Notice title="Animasyon kütüphanesi okunamadı" error>
        <p>
          <code>{view.file}</code> geçerli bir JSON değil: {view.error}
        </p>
        <p>
          Dosya elle düzenlenmez; Godot aracını (<code>{EXPORTER}</code>) yeniden çalıştırmak düzeltir.
        </p>
      </Notice>
    );
  }
  return (
    <>
      <Studio view={view} />
      <Library view={view} />
    </>
  );
}

function Notice({ title, error = false, children }: { title: string; error?: boolean; children: ReactNode }) {
  return (
    <section className={error ? "anim-empty is-error" : "anim-empty"} role={error ? "alert" : undefined} aria-label={title}>
      <h2>{title}</h2>
      {children}
    </section>
  );
}

// Hazır karakter yoksa boş durum; varsa seçici, oynatıcı ve klip listesi (seçimi adresten AnimationStudio okur). İstemciye
// tablonun notları gitmez: yalnız listenin ve kaynak satırının gördüğü alanlar.
function Studio({ view }: { view: Ready }) {
  if (!view.characters.some((c) => c.ready)) {
    return (
      <Notice title="Henüz oynatılabilir karakter yok">
        <p>
          Kütüphanede {fmt(view.characters.length)} karakter, kuyrukta {fmt(view.pending.length)} karakter var; hiçbirinin klibi oynatılabilir değil.
        </p>
      </Notice>
    );
  }
  const clips = view.clips.map((c): AnimClip => ({
    key: c.key,
    tr: c.tr,
    en: c.en,
    group: c.group,
    seat: c.seat,
    tags: c.tags,
    meshyAction: c.meshyAction,
    kind: c.kind,
    prompt: c.prompt,
    derived: c.derived,
    loop: c.loop,
    seatLoop: c.seatLoop,
    travelM: c.travelM,
    purchases: c.purchases,
  }));
  return <AnimationStudio characters={view.characters} pending={view.pending} clips={clips} groups={view.groups} carriers={view.carriers} />;
}

function Library({ view }: { view: Ready }) {
  const { credits } = view;
  const made = view.clips.filter((c) => c.prompt).length;
  const store = view.clips.filter((c) => c.meshyAction != null).length;
  const derived = view.clips.filter((c) => c.kind === "derived").length;
  const rig = view.clips.filter((c) => c.kind === "rig").length;
  return (
    <section className="mt-12" aria-labelledby="anim-library-title">
      <h2 id="anim-library-title" className="text-lg font-bold">
        Klip kütüphanesi <span className="text-sm font-normal text-muted-foreground">· {fmt(view.clips.length)} klip</span>
      </h2>
      <div className="anim-ledger">
        <p>
          <Link href={view.ruleHref} prefetch={false}>
            {view.rule}
          </Link>
          : Meshy'de bir hareket bir kez satın alınır; aynı klip öteki karakterlere ClipRetarget ile 0 krediyle aktarılır. Yürüme ve koşma her karakterin iskeletiyle gelir.{" "}
          <Link href={`${DECISIONS_HREF}#k91`} prefetch={false}>
            K91
          </Link>
          : kişi öbek başına kendi çeşidini alır, önce sahnenin seçimi oynar; oyuncu karakteri çeşit almaz, kendi kliplerini oynar.
        </p>
        <dl className="anim-credits">
          <div>
            <dt>Mağaza hareketleri</dt>
            <dd>
              <b>{fmt(credits.spent_on_actions)}</b> kredi
              <small>
                {fmt(credits.purchases)} alım, {fmt(credits.distinct_actions)} farklı hareket
              </small>
            </dd>
          </div>
          <div>
            <dt>Metinden hareketler</dt>
            <dd>
              <b>{fmt(credits.motions.credits)}</b> kredi
              <small>{fmt(credits.motions.count)} hareket: metinden üretim ve iskelete uygulama</small>
            </dd>
          </div>
          <div className={credits.duplicate_credits > 0 ? "is-warn" : undefined}>
            <dt>Tekrar alımlar</dt>
            <dd>
              <b>{fmt(credits.duplicate_credits)}</b> kredi
              <small>Mağaza kredisinin içinde; aynı hareketin ikinci alımı</small>
            </dd>
          </div>
          <div>
            <dt>Hareketlere toplam</dt>
            <dd>
              <b>{fmt(credits.total)}</b> kredi
              <small>Mağaza ve metinden; iskelet görevleri hariç</small>
            </dd>
          </div>
        </dl>
        <p className="anim-ledger-mix">
          {fmt(view.clips.length)} klibin {fmt(store)} tanesi mağazadan alındı, {fmt(made)} tanesi metinden üretildi; {fmt(derived)} tanesi ters türetildi, {fmt(rig)} tanesi iskeletin hediyesi (bu
          ikisine kredi gitmedi).
        </p>
        <p className="anim-ledger-meta">
          Kaynak: <code>{view.file}</code>
          {view.updated && !Number.isNaN(Date.parse(view.updated)) ? <> · güncellendi {formatLong(view.updated)}</> : null}
        </p>
      </div>
      <p className="mt-4 text-sm text-muted-foreground">
        Bir grubu açınca klipleri listelenir. «Karakter» klibi GLB'sinde taşıyanların sayısı; «kendi» klibi modelin kendi rol klibi olarak taşıyanların, «atanmış» ClipVariety'nin onu varsayılan olarak verdiği
        kişilerin sayısı.
      </p>
      {view.groups.length ? (
        <div className="anim-lib-groups">
          {view.groups.map((group) => (
            <LibraryGroup key={group.key} group={group} clips={view.clips.filter((c) => c.group === group.key)} />
          ))}
        </div>
      ) : (
        <p className="mt-3 text-sm text-muted-foreground">Kütüphanede klip yok.</p>
      )}
    </section>
  );
}

// Tablonun notu: metinden hareketin istemi İngilizcedir, ekran okuyucu onu İngilizce okusun.
function NoteText({ note }: { note: string }) {
  const parts = note.match(/^([\s\S]*İstem: «)([\s\S]*?)(»[\s\S]*)$/);
  if (!parts) return note;
  return (
    <>
      {parts[1]}
      <span lang="en">{parts[2]}</span>
      {parts[3]}
    </>
  );
}

// Klibin nereden geldiği, tek sözcükle: Meshy hareket numarası, metinden, ters türetilmiş ya da iskelet.
function originOf(clip: AnimClipInfo): ReactNode {
  if (clip.meshyAction != null) return `Meshy ${clip.meshyAction}`;
  if (clip.prompt) return "Metinden";
  if (clip.kind === "derived") return clip.derived ? `Ters: ${clip.derived.fromTr}` : "Ters türetilmiş";
  return clip.kind === "rig" ? "İskelet" : "—";
}

function LibraryGroup({ group, clips }: { group: AnimClipGroup; clips: AnimClipInfo[] }) {
  return (
    <details className="anim-lib-group">
      <summary>
        <span className="anim-lib-group-name">{group.tr}</span> <CountBadge count={group.count} />
        <span className="anim-lib-group-credits">{fmt(group.credits)} kredi</span>
      </summary>
      <div className="doc-table anim-lib">
        <table>
          <thead>
            <tr>
              <th scope="col">Klip</th>
              <th scope="col">Kaynak</th>
              <th scope="col">Alındığı yer (kredi)</th>
              <th scope="col" className="anim-num">
                Kredi
              </th>
              <th scope="col" className="anim-num">
                Karakter
              </th>
            </tr>
          </thead>
          <tbody>
            {clips.map((c) => {
              const tags = tagLine(c);
              return (
                <tr key={c.key}>
                  <th scope="row" data-label="Klip">
                    <span className="anim-lib-name">{c.tr}</span> <code>{c.key}</code>
                    {tags ? <span className="anim-lib-tags">{tags}</span> : null}
                    {c.note ? (
                      <span className="anim-lib-note">
                        <NoteText note={c.note} />
                      </span>
                    ) : null}
                  </th>
                  <td data-label="Kaynak">{originOf(c)}</td>
                  <td data-label="Alındığı yer">
                    {c.purchases.length
                      ? c.purchases.map((p) => `${p.name} (${fmt(p.credits)})`).join(", ")
                      : c.kind === "rig"
                        ? "İskelet göreviyle geldi, ek kredi yok"
                        : c.kind === "derived"
                          ? "Türetildi, ek kredi yok"
                          : "—"}
                  </td>
                  <td data-label="Kredi" className="anim-num">
                    {fmt(c.credits)}
                  </td>
                  <td data-label="Karakter" className="anim-num">
                    {fmt(c.usedBy)}
                    {c.ownBy ? <span className="anim-lib-sub"> · kendi {fmt(c.ownBy)}</span> : null}
                    {c.assignedTo ? <span className="anim-lib-sub"> · atanmış {fmt(c.assignedTo)}</span> : null}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </details>
  );
}
