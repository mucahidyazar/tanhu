#!/usr/bin/env python3
"""
Şarkının sözlü bölümünü ses izine ayırır ve perdesini çıkarır (K75; audio.md §2 «Sözlü bölümün ayrılması»).
tools/song/song_measure.mjs çağırır; kip (F / (F + F♯)) ve motif (A→G→F→D) orada, bu betiğin perde dizisinden hesaplanır.

Yöntem: Demucs (htdemucs; ağırlığı yoksa htdemucs_ft) ile iki gövde (ses / geri kalanı), ses izinin perdesi
librosa.pyin ile (80–700 Hz, 22.050 Hz, kare 2048, adım 256 ≈ 11,6 ms).

Hiçbir şey indirmez. Demucs, torch ve librosa yorumlayıcıda kurulu olmalı (uv'de `--offline`: yalnız önbellek);
model ağırlıkları torch hub önbelleğinde (~/.cache/torch/hub/checkpoints) bulunmalı. Ağırlık yoksa ya da kitaplık
eksikse 3 ile çıkar; torch hub'ın indirme işlevi betik başında kapatılır, HuggingFace çevrimdışı açılır.

Kullanım:
  uv run --offline --no-python-downloads --no-project --python 3.12 --with demucs --with librosa \\
      python tools/song/song_separate.py <girdi> <çıktı.json> [--model=htdemucs] [--device=cpu] [--stem-out=ses.wav]
  ... tools/song/song_separate.py --probe          yalnız yoklar: 0 = hazır (JSON satırı), 3 = kurulu değil
  ... tools/song/song_separate.py <ses_izi.wav> <çıktı.json> --stem
                                                   girdi zaten ses izidir: Demucs atlanır, yalnız pYIN

  --model=ad       Demucs modeli (varsayılan: ağırlığı diskte olan ilk model: htdemucs, htdemucs_ft).
  --device=cpu     torch aygıtı (cpu ya da mps).
  --stem-out=yol   Ayrılan ses izini 16 bit mono WAV olarak yazar (kulakla dinlemek için).

Çıktı JSON: {"model", "sr": 22050, "hop": 256, "fmin": 80, "fmax": 700,
             "f0": [Hz ya da null, ...], "prob": [0..1, ...]}  (k. kare zamanı k·hop/sr saniye)
Çıkış kodu: 0 = tamam, 2 = kullanım ya da dosya hatası, 3 = Demucs, librosa ya da ağırlık yok (indirme yapılmaz).
"""
import json
import os
import re
import sys
import wave

# Ağ yok: HuggingFace önbelleği dışına çıkmaz (Demucs 4.1 önce HF deposuna bakar).
os.environ.setdefault("HF_HUB_OFFLINE", "1")
os.environ.setdefault("TRANSFORMERS_OFFLINE", "1")

PITCH_SR = 22050
HOP = 256
FRAME = 2048
FMIN = 80.0
FMAX = 700.0
MODELS = ("htdemucs", "htdemucs_ft")
UNAVAILABLE = 3


def fail(message: str, code: int) -> None:
    print(message, file=sys.stderr)
    sys.exit(code)


def block_downloads() -> None:
    """torch hub'ın indirme işlevini kapatır: önbellekte olmayan ağırlık hata verir, indirilmez."""
    import torch.hub

    def no_download(url, *args, **kwargs):
        raise RuntimeError(f"indirme yapılmaz (K75 koşusu): {url}")

    torch.hub.download_url_to_file = no_download


def remote_files() -> dict:
    """Demucs'un uzak model listesi: imza → dosya adı (torch hub önbelleğindeki ad)."""
    from demucs.pretrained import REMOTE_ROOT

    files = {}
    for line in (REMOTE_ROOT / "files.txt").read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("root:"):
            continue
        files[line.split("-", 1)[0]] = line.rsplit("/", 1)[-1]
    return files


def weights_present(name: str) -> bool:
    """Modelin bütün ağırlık dosyaları torch hub önbelleğinde mi?"""
    import torch.hub
    from demucs.pretrained import REMOTE_ROOT

    yaml_file = REMOTE_ROOT / f"{name}.yaml"
    if not yaml_file.exists():
        return False
    match = re.search(r"models:\s*\[([^\]]*)\]", yaml_file.read_text())
    if not match:
        return False
    sigs = [s.strip().strip("'\"") for s in match.group(1).split(",") if s.strip()]
    files = remote_files()
    checkpoints = os.path.join(torch.hub.get_dir(), "checkpoints")
    return bool(sigs) and all(sig in files and os.path.exists(os.path.join(checkpoints, files[sig])) for sig in sigs)


def pick_model(requested: str | None) -> str:
    names = (requested,) if requested else MODELS
    for name in names:
        if weights_present(name):
            return name
    fail(f"Demucs ağırlığı diskte yok ({', '.join(names)}); indirme yapılmaz", UNAVAILABLE)
    return ""


def load_model(name: str):
    """Modeli yerel ağırlıktan yükler (eski uzak depo yolu: torch hub önbelleği)."""
    try:
        from demucs.pretrained import REMOTE_ROOT, _parse_remote_files
        from demucs.repo import AnyModelRepo, BagOnlyRepo, RemoteRepo

        model_repo = RemoteRepo(_parse_remote_files(REMOTE_ROOT / "files.txt"))
        model = AnyModelRepo(model_repo, BagOnlyRepo(REMOTE_ROOT, model_repo)).get_model(name)
    except ImportError:
        from demucs.pretrained import get_model

        model = get_model(name)
    model.eval()
    return model


def separate_vocals(path: str, name: str, device: str):
    """Demucs ile ses izi → (mono numpy dizisi, örnekleme hızı)."""
    import torch
    from demucs.apply import apply_model
    from demucs.audio import AudioFile

    model = load_model(name)
    wav = AudioFile(path).read(streams=0, samplerate=model.samplerate, channels=model.audio_channels)
    ref = wav.mean(0)
    wav = (wav - ref.mean()) / (ref.std() + 1e-8)
    with torch.no_grad():
        sources = apply_model(model, wav[None], device=device, shifts=1, split=True, overlap=0.25, progress=False)[0]
    sources = sources * (ref.std() + 1e-8) + ref.mean()
    vocals = sources[model.sources.index("vocals")].mean(0)
    return vocals.cpu().numpy(), model.samplerate


def write_wav(path: str, samples, sr: int) -> None:
    import numpy as np

    pcm = (np.clip(samples, -1.0, 1.0) * 32767.0).astype("<i2")
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(sr)
        out.writeframes(pcm.tobytes())


def pitch_track(samples, sr: int) -> dict:
    import librosa
    import numpy as np

    y = librosa.resample(np.asarray(samples, dtype=np.float32), orig_sr=sr, target_sr=PITCH_SR) if sr != PITCH_SR else samples
    f0, voiced, prob = librosa.pyin(y, fmin=FMIN, fmax=FMAX, sr=PITCH_SR, frame_length=FRAME, hop_length=HOP)
    return {
        "sr": PITCH_SR,
        "hop": HOP,
        "fmin": FMIN,
        "fmax": FMAX,
        "f0": [round(float(f), 2) if v and np.isfinite(f) else None for f, v in zip(f0, voiced)],
        "prob": [round(float(p), 3) for p in np.nan_to_num(prob)],
    }


def probe() -> None:
    try:
        import demucs
        import librosa
        import torch  # noqa: F401
    except ImportError as exc:
        fail(f"kitaplık yok: {exc.name}", UNAVAILABLE)
    block_downloads()
    name = pick_model(None)
    print(json.dumps({"ok": True, "model": name, "demucs": demucs.__version__, "librosa": librosa.__version__}))


def main(argv: list[str]) -> None:
    opts = {a.split("=", 1)[0]: (a.split("=", 1)[1] if "=" in a else True) for a in argv if a.startswith("--")}
    files = [a for a in argv if not a.startswith("--")]
    if "--probe" in opts:
        probe()
        return
    if len(files) != 2:
        fail(__doc__, 2)
    source, out = files
    if not os.path.exists(source):
        fail(f"girdi yok: {source}", 2)
    try:
        import librosa  # noqa: F401
    except ImportError:
        fail("kitaplık yok: librosa", UNAVAILABLE)
    if "--stem" in opts:
        import librosa

        samples, sr = librosa.load(source, sr=PITCH_SR, mono=True)
        result = {"model": "ses izi (ayırma yok)", **pitch_track(samples, sr)}
    else:
        try:
            import demucs  # noqa: F401
            import torch  # noqa: F401
        except ImportError as exc:
            fail(f"kitaplık yok: {exc.name}", UNAVAILABLE)
        block_downloads()
        requested = opts.get("--model")
        name = pick_model(requested if isinstance(requested, str) else None)
        device = opts.get("--device") if isinstance(opts.get("--device"), str) else "cpu"
        samples, sr = separate_vocals(source, name, device)
        if isinstance(opts.get("--stem-out"), str):
            write_wav(opts["--stem-out"], samples, sr)
        result = {"model": name, **pitch_track(samples, sr)}
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(result, handle)


if __name__ == "__main__":
    main(sys.argv[1:])
