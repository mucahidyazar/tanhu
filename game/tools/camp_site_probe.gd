extends SceneTree
## Geliştirme aracı: ana kampın (Göl Obası) camp3 yeri için adayları ölçer (structures.md §11.1'in Godot karşılığı): ped dairesinde zeminin
## en büyük farkı, en yakın engel (orman, kaya, yurt, ahır; World.collect_obstacles), en yakın yol (PathNetwork) ve ateşe uzaklık.
##   Godot --headless --path . -s res://tools/camp_site_probe.gd -- --at=-17.6,2.2 [--at=...]

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := (load("res://scenes/world/world.tscn") as PackedScene).instantiate() as World
	root.add_child(world)
	var t := 0
	while not world.is_built() and t < 600:
		await process_frame
		t += 1
	await process_frame
	var shape := world.get_terrain_shape()
	var obstacles := world.collect_obstacles()
	var cands: Array[Vector2] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--at="):
			var p := arg.substr(5).split(",")
			cands.append(Vector2(float(p[0]), float(p[1])))
	if cands.is_empty():
		cands = [Vector2(-17.6, 2.2), Vector2(-16.0, 8.0), Vector2(-19.0, -2.0), Vector2(-14.0, 12.0), Vector2(16.0, 6.0), Vector2(-20.0, 5.0)]
	var paths := root.get_tree().get_first_node_in_group(&"path_network")
	if OS.get_cmdline_user_args().has("--search"):
		# Izgara araması: ped dairesinde (r 4,3) engel yok, zemin farkı ≤0,45 m, ateşe 13–26 m, yola ≥3 m.
		var best: Array = []
		for ix in range(-30, 31):
			for iz in range(-30, 31):
				var c := Vector2(float(ix), float(iz))
				var dist := c.length()
				if dist < 13.0 or dist > 26.0:
					continue
				var clear := INF
				for o in obstacles:
					clear = minf(clear, Vector2(o.x - c.x, o.y - c.y).length() - o.z)
				if clear < 4.3:
					continue
				var lo := INF
				var hi := -INF
				for ring in [0.0, 2.0, 4.0]:
					for k in 12:
						var a := TAU * float(k) / 12.0
						var h := shape.height_at(c.x + sin(a) * ring, c.y + cos(a) * ring)
						lo = minf(lo, h)
						hi = maxf(hi, h)
				var pd := float(paths.call(&"distance_to_paths", c)) if paths else INF
				if hi - lo > 0.45 or pd < 3.0:
					continue
				best.append([hi - lo, c, clear, pd])
		best.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		for row in best.slice(0, 30):
			print("[camp_site] aday %s: fark %.2f, engel %.1f m, yol %.1f m, ateş %.1f m" % [row[1], row[0], row[2], row[3], (row[1] as Vector2).length()])
		quit()
		return
	for c in cands:
		var lo := INF
		var hi := -INF
		for ring in [0.0, 1.5, 3.0, 4.0]:
			for k in 16:
				var a := TAU * float(k) / 16.0
				var h := shape.height_at(c.x + sin(a) * ring, c.y + cos(a) * ring)
				lo = minf(lo, h)
				hi = maxf(hi, h)
		var nearest := INF
		var what := Vector3.ZERO
		for o in obstacles:
			var d := Vector2(o.x - c.x, o.y - c.y).length() - o.z
			if d < nearest:
				nearest = d
				what = o
		var pd := INF
		if paths and paths.has_method(&"distance_to_paths"):
			pd = float(paths.call(&"distance_to_paths", c))
		print("[camp_site] %s: zemin farkı %.2f m (%.2f..%.2f), en yakın engel %.2f m %s, yol %.1f m, ateşe %.1f m" % [c, hi - lo, lo, hi, nearest, what, pd, c.length()])
	quit()
