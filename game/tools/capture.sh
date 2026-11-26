#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Oyunu açar, birkaç saniye bekler, ekran görüntüsü alır ve kapatır.
# Geliştirme sırasında görseli kontrol etmek için kullanılır.
#
# Kullanım:
#   tools/capture.sh <çıktı.png> [kare_sayısı] [ek argümanlar...]
# Örnek:
#   tools/capture.sh /tmp/menu.png 180
#   tools/capture.sh /tmp/yakin.png 120 --pose=0,1.2,3,0,-5 --hide-ui
#   tools/capture.sh /tmp/menu.png 90 --scene=res://scenes/ui/main_menu.tscn
#   tools/capture.sh /tmp/menu169.png 240 --window=3200x1800   (büyütülmüş pencere yerine bu piksel boyutunda; 16:9 karşılaştırma için)
#   tools/capture.sh /tmp/menu.png 360 --window=1920x1080 --freeze-time=12   (kararlı kare; menü referansı, docs/testler.md)
#
# Bu betiğin kendi argümanları:
#   --scene=res://...     Godot'ya çalıştırılacak sahne olarak verilir.
#   --timeout=SN          Güvenlik süresi (varsayılan 90 sn); dolunca Godot kapatılır. Uzun koşular için
#                         (ör. bütçe ölçümü, scenes/dev/budget_probe.tscn) büyütülür.
#   --freeze-time[=SN]    Kararlı kare (scripts/dev/capture.gd): Godot'ya ayrıca --fixed-fps 60 verilir (her kare
#                         1/60 sn sayılır: canlandırmalar kare sayısına bağlanır) ve --save-dir ile --settings-file
#                         verilmemişse oyuncunun kayıtları ve ayarları yerine boş bir geçici klasör kullanılır
#                         (menü karesi kayıt kartına ve ayarlara bağlı kalmaz). Geçici klasör çıkışta silinir.
# Not: Pencere açtığı için kum havuzu dışında çalıştırılmalıdır.
# ---------------------------------------------------------------------------
set -uo pipefail

cd "$(dirname "$0")/.."
source tools/_godot_lock.sh
godot_import_locked

out="${1:?çıktı yolu gerekli}"
frames="${2:-150}"
shift 2 2>/dev/null || shift $#
log="${out%.png}.log"

# --scene=... argümanı Godot'a doğrudan çalıştırılacak sahne olarak verilir; --timeout bu betiğindir.
# (--window=GxY argümanını oyun içindeki yakalama aracı uygular: pencereyi bu piksel boyutuna getirir.)
scene=()
engine=()
rest=()
timeout=90
freeze=0
has_save_dir=0
has_settings=0
for a in "$@"; do
	case "$a" in
		--scene=*) scene=("${a#--scene=}") ;;
		--timeout=*) timeout="${a#--timeout=}" ;;
		*)
			case "$a" in
				--freeze-time | --freeze-time=*) freeze=1 ;;
				--save-dir=*) has_save_dir=1 ;;
				--settings-file=*) has_settings=1 ;;
			esac
			rest+=("$a")
			;;
	esac
done
if ! [[ "$timeout" =~ ^[0-9]+$ ]]; then
	echo "--timeout saniye olmalı: $timeout" >&2
	exit 2
fi

# Kararlı kare: sabit kare adımı ve oyuncunun dosyalarından bağımsız, boş bir kayıt ve ayar klasörü.
if [[ $freeze -eq 1 ]]; then
	engine+=(--fixed-fps 60)
	tmp="$(mktemp -d "${TMPDIR:-/tmp}/tanhu_capture.XXXXXX")"
	trap 'rm -rf "$tmp"' EXIT
	mkdir -p "$tmp/kayitlar"
	[[ $has_save_dir -eq 0 ]] && rest+=("--save-dir=$tmp/kayitlar")
	[[ $has_settings -eq 0 ]] && rest+=("--settings-file=$tmp/ayarlar.cfg")
fi

"$GODOT" --path . --resolution 1920x1080 ${engine[@]+"${engine[@]}"} ${scene[@]+"${scene[@]}"} -- --capture="$out" --frames="$frames" ${rest[@]+"${rest[@]}"} >"$log" 2>&1 &
pid=$!
# Güvenlik: en fazla $timeout saniye bekle.
waited=0
while kill -0 "$pid" 2>/dev/null; do
	if ((waited >= timeout)); then
		kill "$pid" 2>/dev/null || true
		echo "[capture] süre doldu (${timeout} sn), Godot kapatıldı; uzun koşular için --timeout=SN" | tee -a "$log"
		break
	fi
	sleep 1
	waited=$((waited + 1))
done
wait "$pid" 2>/dev/null

grep -E "ERROR|SCRIPT ERROR|SHADER ERROR|WARNING|capture\]|budget\]|Parse Error|error\(" "$log" | grep -vE "editor_settings|hiservices|NSXPC|Connection [Ii]nvalid" | head -60
# "hata=" yalnızca görüntünün kaydedilip kaydedilmediğini söyler. Günlükteki gerçek hatalar (betik,
# gölgelendirici, ayrıştırma) ayrıca sayılır; macOS'un ve günlük dosyasının zararsız uyarıları sayılmaz.
errors=$(grep -E "SCRIPT ERROR|SHADER ERROR|Parse Error|^ERROR" "$log" \
	| grep -vcE "editor_settings|hiservices|NSXPC|Connection [Ii]nvalid|Failed to open|log file|ret != noErr|resources still in use|ObjectDB instances")
echo "[capture] günlükteki hata satırı: ${errors:-0}" | tee -a "$log"
# Görüntü bu koşuda yazıldıysa yakalama aracı yolunu "hata=0" ile günlüğe yazar (eski bir dosya başarı sayılmaz).
if grep -F "[capture] $out " "$log" | grep -q "hata=0"; then
	echo "OK: $out"
else
	echo "Görüntü alınamadı, günlük: $log"
	exit 1
fi
