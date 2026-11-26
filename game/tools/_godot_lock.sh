#!/usr/bin/env bash
# Aynı anda birden fazla "godot --import" çalışmasın diye basit bir kilit (mkdir atomiktir).
# Kullanım: source tools/_godot_lock.sh; godot_import_locked
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
TANHU_LOCK="${TMPDIR:-/tmp}/tanhu3_import.lock"
godot_import_locked() {
	local waited=0
	until mkdir "$TANHU_LOCK" 2>/dev/null; do
		sleep 1
		waited=$((waited + 1))
		# Eski (takılı kalmış) kilidi 180 sn sonra temizle.
		if [[ $waited -gt 180 ]]; then rm -rf "$TANHU_LOCK"; fi
	done
	"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
	rm -rf "$TANHU_LOCK"
}
