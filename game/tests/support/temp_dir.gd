extends RefCounted
## Testler için geçici klasör: oyuncunun user:// klasörüne (kayıtlar, ayarlar) asla dokunulmaz.
## Sistemin geçici klasöründe (TMPDIR; kum havuzunda da yazılabilir) her çağrıda boş bir klasör açar.
##   const TempDir := preload("res://tests/support/temp_dir.gd")
##   var dir := TempDir.fresh("kayit_testi")   # ".../tanhu3_tests/kayit_testi"
##   ...
##   TempDir.wipe(dir)


## Boş bir geçici klasör (varsa içi temizlenir) ve mutlak yolu.
static func fresh(name: String) -> String:
	var base := OS.get_environment("TMPDIR")
	if base.is_empty():
		base = OS.get_temp_dir()
	var dir := base.path_join("tanhu3_tests").path_join("%s_%d" % [name, OS.get_process_id()])
	DirAccess.make_dir_recursive_absolute(dir)
	wipe(dir, false)
	return dir


## Klasördeki dosyaları siler; remove_dir ise klasörü de.
static func wipe(dir: String, remove_dir: bool = true) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		DirAccess.remove_absolute(dir.path_join(f))
	if remove_dir:
		DirAccess.remove_absolute(dir)
