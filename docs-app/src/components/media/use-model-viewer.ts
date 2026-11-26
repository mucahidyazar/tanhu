// Google model-viewer'ı sayfaya yükleyen ortak kanca: Ansiklopedi'nin 3B sekmesi ve Animasyonlar sayfası kullanır.
// Betik yalnız gerektiğinde (görünüm açılınca) bir kez eklenir, sabit sürümdür. Betik yüklenemezse (ağ yok, CDN kapalı)
// ya da süresinde tanımlanmazsa durum «error» olur ve «Yeniden dene» yeniden yükler. Betik geç gelirse (zaman aşımından
// sonra) görünüm kendini toplar: durum «ready»ye döner.
import { useCallback, useEffect, useState } from "react";

export const MODEL_VIEWER_SRC = "https://cdn.jsdelivr.net/npm/@google/model-viewer@3.5.0/dist/model-viewer.min.js";
const SCRIPT_ID = "model-viewer-script";
// Betik bu sürede tanımlanmazsa yüklenemedi sayılır. İndirme yine de bırakılmaz: gelirse görünüm açılır.
const LOAD_TIMEOUT_MS = 20_000;

export type ModelViewerStatus = "idle" | "loading" | "ready" | "error";

// Aynı sayfadaki bütün görünümler tek yüklemeyi bekler.
let pending: Promise<void> | null = null;
// Yüklenemeyen betik sayısı. Tarayıcı yüklenemeyen modül adresini modül haritasında tutar ve aynı adresi ağa gitmeden
// yine hatayla bitirir; bu yüzden hatadan sonraki deneme adresi değiştirir (?r=1, ?r=2 …).
let failures = 0;

// Sayfadaki betik öğesi; yoksa eklenir. Hata kalıcıdır: öğe kaldırılır, sonraki deneme yeni adresle yeni öğe ekler.
// Zaman aşımında öğe yerinde kalır, çünkü ilk indirme hâlâ sürüyor olabilir; yeniden deneme onu bekler.
function scriptElement(): HTMLScriptElement {
  const found = document.getElementById(SCRIPT_ID);
  if (found instanceof HTMLScriptElement) return found;
  const script = document.createElement("script");
  script.id = SCRIPT_ID;
  script.type = "module";
  script.src = failures ? `${MODEL_VIEWER_SRC}?r=${failures}` : MODEL_VIEWER_SRC;
  script.addEventListener(
    "error",
    () => {
      failures += 1;
      script.remove();
    },
    { once: true },
  );
  document.head.appendChild(script);
  return script;
}

function loadModelViewer(): Promise<void> {
  if (customElements.get("model-viewer")) return Promise.resolve();
  if (pending) return pending;
  const attempt = new Promise<void>((resolve, reject) => {
    const script = scriptElement();
    const timer = window.setTimeout(() => reject(new Error("model-viewer zaman aşımı")), LOAD_TIMEOUT_MS);
    script.addEventListener(
      "error",
      () => {
        window.clearTimeout(timer);
        reject(new Error("model-viewer betiği yüklenemedi"));
      },
      { once: true },
    );
    void customElements.whenDefined("model-viewer").then(() => {
      window.clearTimeout(timer);
      resolve();
    });
  });
  pending = attempt;
  // Başarısız deneme akılda kalmaz: sonraki çağrı yeniden dener.
  attempt.catch(() => {
    if (pending === attempt) pending = null;
  });
  return attempt;
}

// active false iken hiçbir şey yüklenmez («idle»).
export function useModelViewerStatus(active: boolean): { status: ModelViewerStatus; retry: () => void } {
  const [status, setStatus] = useState<ModelViewerStatus>("idle");
  const [attempt, setAttempt] = useState(0);
  useEffect(() => {
    if (!active) return;
    if (customElements.get("model-viewer")) {
      setStatus("ready");
      return;
    }
    let alive = true;
    setStatus("loading");
    // Tanım hata durumunda da beklenir: zaman aşımından sonra gelen betik görünümü yine açar.
    void customElements.whenDefined("model-viewer").then(() => {
      if (alive) setStatus("ready");
    });
    loadModelViewer().catch(() => {
      if (alive && !customElements.get("model-viewer")) setStatus("error");
    });
    return () => {
      alive = false;
    };
  }, [active, attempt]);
  const retry = useCallback(() => setAttempt((n) => n + 1), []);
  return { status: active ? status : "idle", retry };
}
