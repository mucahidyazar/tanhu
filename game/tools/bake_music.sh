#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Kodla müzik, ortam ve efekt basma hattı (K28, K61; godot.md §3.3, audio.md §2–§4). Kredi harcamaz:
# sentez Godot'da (tools/bake_music.gd), kodlama yereldir (oggenc, ffmpeg).
#
# 1. Godot içe aktarması (kilitli): sınıf adları (SynthDsp, SynthKopuz …) için.
# 2. tools/bake_music.gd tarifleri (data/audio/bake/*.json) basar: ara WAV audio/gen/_wav/<id>.wav
#    (.gdignore'lu) ve hedefin .import'u (yalnız importer ve [params]).
# 3. Müzik: oggenc -q 2 (mono ≈96 kb/sn) → audio/gen/<id>.ogg; .import'ta loop, bpm, beat_count, bar_beats 2.
#    Ortam döngüsü: audio/ambience/gen/<id>.wav (22,05 kHz mono QOA, ileri döngü, son -1).
#    Efekt: audio/sfx/gen/<id>.wav (QOA). Ara WAV (kind wav, ör. şarkı ölçüsünün denetim kopuzu) yerinde kalır.
# 4. Godot içe aktarması (kilitli): .import'ların uid ve dest_files'ı dolar.
#
# Kullanım:
#   tools/bake_music.sh                                  # bütün tarifler
#   tools/bake_music.sh --only=camp_drone,wind_steppe    # yalnız bunlar
#   tools/bake_music.sh --list                           # tarifleri yazar
#   tools/bake_music.sh --only=wind_steppe --source=free:assets/_free/sound/wind_loop/wind1.wav --out="$TMPDIR/aday"
#       # karşılaştırma adayı: oyuna konmaz, .import yazılmaz
# ---------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.."
source tools/_godot_lock.sh

if ! command -v oggenc >/dev/null 2>&1; then
	echo "bake_music: oggenc yok (brew install vorbis-tools)" >&2
	exit 1
fi

godot_import_locked
log="$(mktemp "${TMPDIR:-/tmp}/bake_music.XXXXXX")"
"$GODOT" --headless --path . -s res://tools/bake_music.gd -- "$@" >"$log" 2>&1
status=$?
grep -vE "editor_settings|Failed to open log file|get_system_ca_certificates|rotate_file|os_macos.mm|^\s*at: |^BAKED|^$" "$log" || true

placed=0
while IFS=$'\t' read -r tag kind id wav target; do
	[[ "$tag" == "BAKED" && -n "${target:-}" ]] || continue
	case "$kind" in
		music)
			oggenc -Q -q 2 -o "$target" "$wav" || { echo "bake_music: $id Ogg'a çevrilemedi" >&2; status=1; continue; }
			;;
		ambience|sfx)
			cp "$wav" "$target"
			;;
		*)
			continue
			;;
	esac
	echo "  → ${target#"$PWD"/}"
	placed=$((placed + 1))
done <"$log"
rm -f "$log"

if [[ $placed -gt 0 ]]; then
	godot_import_locked
fi
exit $status
