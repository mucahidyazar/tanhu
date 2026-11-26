#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Birim testlerini başsız (pencere açmadan) çalıştırır.
# Önce kaynakları içe aktarır (class_name önbelleği için gerekli), sonra testleri koşar.
#
# Kullanım:
#   tools/run_tests.sh                    # tüm testler
#   tools/run_tests.sh --filter=profile   # dosya adında "profile" geçenler
# ---------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.."
source tools/_godot_lock.sh

godot_import_locked
"$GODOT" --headless --path . -s res://tests/run_tests.gd -- "$@" 2>&1 \
	| grep -vE "editor_settings|Failed to open log file|get_system_ca_certificates|rotate_file|os_macos.mm|^\s*at: "
exit "${PIPESTATUS[0]}"
