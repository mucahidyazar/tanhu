"use client";

// Klip oynatıcı: Google model-viewer (gölge, nötr ortam ışığı, döndürülebilir kamera) karakterin GLB'sini gösterir;
// GLB'deki her animasyonun adı klip anahtarıdır. Klip değişirken oynatma önce durur, yeni klip baştan başlar (geçiş
// karışımı yok: klip olduğu gibi görünsün). Geçişlerde ve kökü yerinden giden kliplerde kamera geri çekilir: kişi çerçeveden
// çıkmasın; oturuşların kökü yerinde durur (isWideClip). Hareket azaltma tercihinde hiçbir klip kendiliğinden oynamaz, Oynat düğmesi
// başlatır. Bileşen karakter başına yeniden kurulur (key): yükleme, hata ve oynatma durumu karakterle sıfırlanır. Klip listesi
// ayrı bileşendir (clip-browser.tsx); seçili klibin kaynağı, etiketleri ve bilgileri burada, görünümün altındadır.
import { LoaderCircle, Pause, Play, RefreshCw, Repeat, TriangleAlert } from "lucide-react";
import { createElement, type ReactNode, useEffect, useEffectEvent, useRef, useState } from "react";
import { useModelViewerStatus } from "@/components/media/use-model-viewer";
import { type ClipUse, isWideClip, loopText, type SourcePart, tagChips } from "@/components/animations/clip-text";
import type { AnimCharacter, AnimCharacterClip, AnimClip } from "@/lib/animations";
import { cn } from "@/lib/utils";

// model-viewer'ın burada kullanılan yüzü (3.5.0).
type ModelViewerElement = HTMLElement & {
  animationName: string | undefined;
  readonly availableAnimations: string[];
  readonly paused: boolean;
  readonly duration: number;
  readonly loaded: boolean;
  currentTime: number;
  timeScale: number;
  cameraOrbit: string;
  updateComplete: Promise<boolean>;
  getCameraOrbit(): { theta: number; phi: number; radius: number };
  jumpCameraToGoal(): void;
  play(options?: { repetitions: number; pingpong: boolean }): void;
  pause(): void;
};

const RATES = [0.5, 1, 1.5, 2] as const;
const SECONDS = new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const rateLabel = (r: number) => `${r.toLocaleString("tr-TR")}×`;
const megabytes = (bytes: number) => `${(bytes / 1_048_576).toLocaleString("tr-TR", { maximumFractionDigits: 1 })} MB`;
// Görüntüleyicinin ekran okuyucuya söylediği metinler (kendi varsayılanı İngilizcedir): yönerge ve kameranın baktığı yön.
const A11Y_TR = JSON.stringify({
  "interaction-prompt": "Döndürmek için fare, dokunma ya da ok tuşlarını kullan.",
  front: "Önden görünüm",
  right: "Sağdan görünüm",
  back: "Arkadan görünüm",
  left: "Soldan görünüm",
  "upper-front": "Üstten, önden görünüm",
  "upper-right": "Üstten, sağdan görünüm",
  "upper-back": "Üstten, arkadan görünüm",
  "upper-left": "Üstten, soldan görünüm",
  "lower-front": "Alttan, önden görünüm",
  "lower-right": "Alttan, sağdan görünüm",
  "lower-back": "Alttan, arkadan görünüm",
  "lower-left": "Alttan, soldan görünüm",
});
// Kameranın uzaklığı, modeli tam gösteren uzaklığa oranla: olağan, yerinden giden klipte ve elle uzaklaşmanın sınırı.
const NORMAL_RADIUS = "105%";
const WIDE_RADIUS = "150%";
const MAX_RADIUS = "250%";

type Phase = "loading" | "ready" | "error";

// Kaynak satırı: İngilizce parça (metinden hareketin istemi) kendi diliyle okunur.
export function SourceText({ parts }: { parts: SourcePart[] }) {
  return parts.map((part, i) => (part.lang ? <span key={i} lang={part.lang}>{part.text}</span> : part.text));
}

export function ClipPlayer({
  character,
  clip,
  info,
  sourceParts,
  uses,
  rate,
  onRate,
  loop,
  onLoop,
  reducedMotion,
}: {
  character: AnimCharacter;
  clip: AnimCharacterClip;
  // Klibin kütüphanedeki bilgisi (kütüphanede yoksa yok).
  info: AnimClip | undefined;
  sourceParts: SourcePart[];
  // Klibin bu kişideki yeri: sahnede oynuyor mu, varsayılanı mı (clipUses).
  uses: ClipUse[];
  rate: number;
  onRate: (rate: number) => void;
  loop: boolean;
  onLoop: (loop: boolean) => void;
  reducedMotion: boolean;
}) {
  const clipKey = clip.key;
  const clipName = info?.tr ?? clip.key;
  const wide = isWideClip(info);
  const canLoad = Boolean(character.glbUrl && character.glbExists);
  const { status: script, retry: retryScript } = useModelViewerStatus(canLoad);
  const viewer = useRef<ModelViewerElement | null>(null);
  const stage = useRef<HTMLDivElement>(null);
  const timeText = useRef<HTMLSpanElement>(null);
  const seek = useRef<HTMLInputElement>(null);
  const [attempt, setAttempt] = useState(0);
  // Kameranın ilk yeri: öğe kurulurken bir kez yazılır, sonrasını applyFraming yürütür (bakış açısı kalsın diye özellikten).
  const [startOrbit] = useState(() => `auto auto ${wide ? WIDE_RADIUS : NORMAL_RADIUS}`);
  const [phase, setPhase] = useState<Phase>("loading");
  const [progress, setProgress] = useState(0);
  const [failure, setFailure] = useState<string | null>(null);
  const [playing, setPlaying] = useState(false);
  const [available, setAvailable] = useState<string[] | null>(null);
  // Yüklenen GLB'den okunan gerçek süreler (klip anahtarına göre); yoksa dosyadaki süre gösterilir.
  const [measured, setMeasured] = useState<Record<string, number>>({});

  const options = () => ({ repetitions: loop ? Infinity : 1, pingpong: false });
  const duration = measured[clip.key] ?? clip.duration ?? 0;
  const controlsReady = phase === "ready" && script === "ready";

  const remember = (el: ModelViewerElement) => {
    const key = el.animationName;
    const d = el.duration;
    if (key && d > 0) setMeasured((m) => (m[key] === d ? m : { ...m, [key]: d }));
  };

  // Zaman göstergesi ve sürgü her karede öğeden okunur; React yeniden çizilmez. Sürgü odaktayken kullanıcıya bırakılır.
  const paintTime = () => {
    const el = viewer.current;
    if (!el) return;
    const total = el.duration || 0;
    const t = Math.max(0, total ? Math.min(el.currentTime || 0, total) : el.currentTime || 0);
    const label = SECONDS.format(t);
    // React'in metin düğümü yerinde kalsın: yalnız değeri değişir.
    const text = timeText.current?.firstChild;
    if (text && text.nodeValue !== label) text.nodeValue = label;
    const slider = seek.current;
    if (slider && document.activeElement !== slider) slider.value = String(t);
  };

  // Kamerayı klibe göre yerleştirir, bakış açısı kalır. Yalnız uzaklık değişir; hareket azaltma tercihinde geçişsiz.
  const applyFraming = useEffectEvent(() => {
    const el = viewer.current;
    if (!el?.loaded) return;
    const orbit = el.getCameraOrbit();
    el.cameraOrbit = `${orbit.theta}rad ${orbit.phi}rad ${wide ? WIDE_RADIUS : NORMAL_RADIUS}`;
    if (reducedMotion) el.jumpCameraToGoal();
  });
  useEffect(() => {
    applyFraming();
  }, [wide]);

  // Öğenin klibini seçili klibe getirir ve oynatma durumunu kurar. Klip değişirken önce durur: model-viewer duran
  // öğede bütün eylemleri sıfırlar, yeni klip ilk karesinden başlar.
  const sync = useEffectEvent(async (reason: "load" | "clip") => {
    const el = viewer.current;
    if (!el) return;
    if (el.animationName !== clipKey) {
      el.pause();
      el.animationName = clipKey;
      await el.updateComplete;
      if (viewer.current !== el) return;
    } else if (reason === "clip") {
      return;
    }
    // Yükleme bitmediyse durumu yükleme olayı kurar.
    if (!el.loaded) return;
    if (reason === "load") {
      el.timeScale = rate;
      setAvailable([...el.availableAnimations]);
      // Model yüklenirken klip değiştiyse kamera yeni klibe göre yerleşsin.
      applyFraming();
    }
    // autoplay klibi sonsuz döngüyle başlatır; döngü kapalıysa bir kez oynasın. Hareket azaltmada öğe durur.
    if (reducedMotion) el.pause();
    else el.play(options());
    setPlaying(!el.paused);
    remember(el);
    paintTime();
  });

  const onFailed = useEffectEvent(async (type: string | undefined) => {
    setPhase("error");
    if (type === "webglcontextlost") {
      setFailure("Tarayıcı 3B çizim bağlamını yitirdi (WebGL). Sayfayı yenile.");
      return;
    }
    // GLB'nin durumunu ilk baytını isteyerek öğren: 404 ile bozuk dosya ayrı söylensin.
    let status: number | null = null;
    try {
      const res = await fetch(character.glbUrl ?? "", { headers: { Range: "bytes=0-0" }, cache: "no-store" });
      status = res.status;
      await res.body?.cancel();
    } catch {
      status = null;
    }
    setFailure(
      status === 404
        ? `GLB bulunamadı (404): ${character.glbPath}`
        : status !== null && status >= 400
          ? `GLB alınamadı (HTTP ${status}): ${character.glbPath}`
          : `GLB açılamadı: dosya bozuk olabilir ya da tarayıcı okuyamadı (${character.glbPath}).`,
    );
  });

  // Öğe kurulunca: klip ve hız yazılır (model daha yükleniyor), olaylar bağlanır. Yeniden deneme öğeyi baştan kurar.
  const attach = useEffectEvent((el: ModelViewerElement) => {
    el.animationName = clipKey;
    el.timeScale = rate;
    const onProgress = (e: Event) => setProgress((e as CustomEvent<{ totalProgress?: number }>).detail?.totalProgress ?? 0);
    const onLoad = () => {
      setFailure(null);
      setPhase("ready");
      void sync("load");
    };
    const onError = (e: Event) => void onFailed((e as CustomEvent<{ type?: string }>).detail?.type);
    const onPlay = () => setPlaying(true);
    const onStop = () => {
      setPlaying(false);
      paintTime();
    };
    const events: [string, (e: Event) => void][] = [
      ["progress", onProgress],
      ["load", onLoad],
      ["error", onError],
      ["play", onPlay],
      ["pause", onStop],
      ["finished", onStop],
    ];
    for (const [name, fn] of events) el.addEventListener(name, fn);
    // Olay bağlanmadan yüklenmişse kaçmasın.
    if (el.loaded) onLoad();
    return () => {
      for (const [name, fn] of events) el.removeEventListener(name, fn);
    };
  });
  useEffect(() => {
    const el = viewer.current;
    return el ? attach(el) : undefined;
  }, [script, attempt]);

  useEffect(() => {
    void sync("clip");
  }, [clipKey]);

  useEffect(() => {
    if (viewer.current) viewer.current.timeScale = rate;
  }, [rate]);

  // Döngü oynarken değişirse hemen işler; durmuşken bir sonraki Oynat'ta.
  const applyLoop = useEffectEvent(() => {
    const el = viewer.current;
    if (el?.loaded && !el.paused) el.play(options());
  });
  useEffect(() => {
    applyLoop();
  }, [loop]);

  // Fare tekerleği sayfayı kaydırsın: model-viewer tekerleği yakınlaştırmaya alır, sayfa görünümün üstünde takılırdı.
  // Görünüme tıklanınca (imleç içerideyken) düz tekerlek de yakınlaştırır. Ctrl'li tekerlek hep modele gider: dokunmatik
  // yüzeyde iki parmakla açma tarayıcıya ctrl+tekerlek olarak gelir; durdurulsaydı model değil bütün sayfa büyürdü.
  // Dokunmatik ekranın iki parmağı (pointer olayları) zaten hep çalışır.
  useEffect(() => {
    const el = stage.current;
    if (!el) return;
    let engaged = false;
    const onWheel = (e: WheelEvent) => {
      if (!engaged && !e.ctrlKey) e.stopPropagation();
    };
    const engage = () => {
      engaged = true;
    };
    const release = () => {
      engaged = false;
    };
    el.addEventListener("wheel", onWheel, { capture: true, passive: true });
    el.addEventListener("pointerdown", engage);
    el.addEventListener("pointerleave", release);
    return () => {
      el.removeEventListener("wheel", onWheel, { capture: true });
      el.removeEventListener("pointerdown", engage);
      el.removeEventListener("pointerleave", release);
    };
  }, []);

  const tick = useEffectEvent(() => paintTime());
  useEffect(() => {
    if (!controlsReady) return;
    let frame = 0;
    const loopFrame = () => {
      tick();
      frame = requestAnimationFrame(loopFrame);
    };
    frame = requestAnimationFrame(loopFrame);
    return () => cancelAnimationFrame(frame);
  }, [controlsReady]);

  const toggle = () => {
    const el = viewer.current;
    if (!el || !controlsReady) return;
    if (el.paused) el.play(options());
    else el.pause();
  };

  const retry = () => {
    if (script === "error") {
      retryScript();
      return;
    }
    setFailure(null);
    setProgress(0);
    setPhase("loading");
    setAttempt((n) => n + 1);
  };

  const missingClip = controlsReady && available !== null && !available.includes(clip.key);
  let overlay: ReactNode = null;
  if (!canLoad) {
    overlay = (
      <StageMessage tone="error" title="Bu karakterin GLB dosyası yok">
        <code>{character.glbPath || "(yol yazılmamış)"}</code> bulunamadı. Godot aracı <code>game/tools/clip_library_export.gd</code> yeniden çalışınca gelir.
      </StageMessage>
    );
  } else if (script === "error") {
    overlay = (
      <StageMessage tone="error" title="3B görüntüleyici yüklenemedi" action={{ label: "Yeniden dene", onClick: retry }}>
        model-viewer betiği (cdn.jsdelivr.net) alınamadı. Bağlantıyı denetleyip yeniden dene.
      </StageMessage>
    );
  } else if (script !== "ready") {
    overlay = <StageMessage tone="busy" title="3B görüntüleyici yükleniyor…" />;
  } else if (phase === "error") {
    overlay = (
      <StageMessage tone="error" title="Model yüklenemedi" action={{ label: "Yeniden dene", onClick: retry }}>
        {failure ?? "GLB'nin durumu soruluyor…"}
      </StageMessage>
    );
  } else if (phase === "loading") {
    overlay = (
      <StageMessage tone="busy" title="Model yükleniyor…" detail={`%${Math.round(progress * 100)}${character.bytes ? ` · ${megabytes(character.bytes)}` : ""}`} />
    );
  }

  return (
    <div className="anim-player">
      <div ref={stage} className="anim-stage" aria-busy={canLoad && phase === "loading" ? true : undefined}>
        {canLoad && script === "ready"
          ? createElement(
              "model-viewer",
              {
                key: `mv-${attempt}`,
                ref: viewer,
                src: character.glbUrl,
                alt: `${character.name}: 3B model, ${clipName} klibi`,
                a11y: A11Y_TR,
                autoplay: !reducedMotion,
                "camera-controls": "",
                "camera-orbit": startOrbit,
                "max-camera-orbit": `Infinity auto ${MAX_RADIUS}`,
                "shadow-intensity": "1",
                "environment-image": "neutral",
                "interaction-prompt": "none",
                "touch-action": "pan-y",
                class: "anim-model",
              },
              // Kendi yükleme göstergemiz var: öğenin ilerleme çubuğu boş yuvayla gizlenir.
              createElement("div", { slot: "progress-bar" }),
            )
          : null}
        {overlay}
        {missingClip ? (
          <p className="anim-stage-warn" role="status">
            <TriangleAlert className="size-4 shrink-0" aria-hidden="true" />
            <span>
              Bu GLB'de «{clip.key}» adlı animasyon yok; model-viewer ilk animasyonu oynatıyor. GLB'deki adlar: {available?.length ? available.join(", ") : "yok"}.
            </span>
          </p>
        ) : null}
      </div>

      <div className="anim-transport">
        <button type="button" className="anim-play" onClick={toggle} disabled={!controlsReady}>
          {playing ? <Pause className="size-4" aria-hidden="true" /> : <Play className="size-4" aria-hidden="true" />}
          {playing ? "Duraklat" : "Oynat"}
        </button>
        <label className="anim-seek">
          <span className="sr-only">Zaman (saniye)</span>
          <input
            ref={seek}
            type="range"
            min={0}
            max={duration || 1}
            step={0.01}
            defaultValue={0}
            disabled={!controlsReady || !duration}
            onChange={(e) => {
              const el = viewer.current;
              if (el) el.currentTime = Number(e.currentTarget.value);
              paintTime();
            }}
          />
        </label>
        <p className="anim-time">
          <span ref={timeText}>{SECONDS.format(0)}</span>
          <span aria-hidden="true"> / </span>
          <span className="sr-only"> saniye; klibin süresi </span>
          {SECONDS.format(duration)} sn
        </p>
      </div>

      <div className="anim-options">
        <div className="anim-rates" role="group" aria-label="Hız">
          <span className="anim-options-label" aria-hidden="true">
            Hız
          </span>
          {RATES.map((r) => (
            <button key={r} type="button" aria-pressed={rate === r} onClick={() => onRate(r)} className={cn("anim-chip", rate === r && "is-active")}>
              {rateLabel(r)}
            </button>
          ))}
        </div>
        <button type="button" aria-pressed={loop} onClick={() => onLoop(!loop)} className={cn("anim-chip", loop && "is-active")}>
          <Repeat className="size-3.5" aria-hidden="true" />
          Döngü
          <span className="anim-chip-state" aria-hidden="true">
            {loop ? "açık" : "kapalı"}
          </span>
        </button>
      </div>

      {/* Duyurusu AnimationStudio'daki kalıcı canlı bölgededir: bu öğe karakterle yeniden kurulur. */}
      <p className="anim-source">
        <strong>{clipName}</strong>: <SourceText parts={sourceParts} />
      </p>
      {info && tagChips(info).length ? (
        <ul className="anim-tags" aria-label="Klibin etiketleri">
          {tagChips(info).map((tag) => (
            <li key={`${tag.kind}-${tag.label}`} className="anim-tag">
              <span className="anim-tag-kind">{tag.kind}</span> {tag.label}
            </li>
          ))}
        </ul>
      ) : null}
      <ul className="anim-meta" aria-label="Klibin bilgileri">
        {uses.map((use) => (
          <li key={use.text} className={use.live ? "is-live" : undefined}>
            {use.text}
          </li>
        ))}
        <li>{loopText(clip.loop, info?.seatLoop)}</li>
        {clip.frames ? <li>{clip.frames.toLocaleString("tr-TR")} kare</li> : null}
        <li>
          <code>{clip.key}</code>
        </li>
        {character.bytes ? <li>GLB {megabytes(character.bytes)}</li> : null}
      </ul>
      <p className="anim-hint">Sürükleyerek döndür. Yakınlaşmak için iki parmakla aç, Ctrl'ye basılıyken tekerleği çevir ya da görünüme tıklayıp tekerleği çevir.</p>
    </div>
  );
}

function StageMessage({
  tone,
  title,
  detail,
  children,
  action,
}: {
  tone: "busy" | "error";
  title: string;
  detail?: string;
  children?: ReactNode;
  action?: { label: string; onClick: () => void };
}) {
  return (
    <div className={cn("anim-stage-msg", tone === "error" && "is-error")}>
      {tone === "busy" ? <LoaderCircle className="size-5 motion-safe:animate-spin" aria-hidden="true" /> : <TriangleAlert className="size-5" aria-hidden="true" />}
      {/* Yalnız başlık duyurulur: yüzde her değiştiğinde ekran okuyucu konuşmasın. */}
      <p className="anim-stage-title" role={tone === "error" ? "alert" : "status"}>
        {title}
      </p>
      {detail ? (
        <p className="anim-stage-text" aria-hidden="true">
          {detail}
        </p>
      ) : null}
      {children ? <p className="anim-stage-text">{children}</p> : null}
      {action ? (
        <button type="button" className="anim-chip" onClick={action.onClick}>
          <RefreshCw className="size-3.5" aria-hidden="true" />
          {action.label}
        </button>
      ) : null}
    </div>
  );
}
