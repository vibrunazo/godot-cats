extends SceneTree
## Deterministic regression check for ParticleProcessMaterial migration.
## Asserts that the material properties each scene's GPUParticles2D loads
## match the migrated Godot 3 semantics (Godot 4 silently ignores Godot 3
## property names, which zeroed particle velocities and piled threads up
## in one spot). In rendered mode, also saves a screenshot of a settled
## yarn blast. Usage: -- capture=<absolute PNG path>

## Intended values, migrated from the Godot 3 build (b1d5736546667f745c).
## Godot 3 semantics: X + X_random=R becomes range [X*(1-R), X].
const EXPECTED: Dictionary = {
	"res://scenes/blast/Blast03.tscn": {
		"initial_velocity": Vector2(0.0, 120.0),
		"angular_velocity": Vector2(0.0, 200.0),
		"damping": Vector2(180.0, 180.0),
		"angle": Vector2(0.0, 720.0),
	},
	"res://scenes/blast/Blast04.tscn": {
		"initial_velocity": Vector2(0.0, 200.0),
		"angular_velocity": Vector2(104.0, 200.0),
		"damping": Vector2(180.0, 180.0),
		"angle": Vector2(0.0, 180.0),
		"scale": Vector2(0.0, 0.4),
	},
	"res://scenes/cats/Cat03.tscn": {
		"initial_velocity": Vector2(20.0, 20.0),
	},
}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	create_timer(15.0).timeout.connect(func() -> void:
		push_error("BLAST TEST FAILED: timed out")
		quit(1))
	for path: String in EXPECTED:
		var packed: PackedScene = load(path) as PackedScene
		assert(packed != null, "cannot load " + path)
		var node: Node = packed.instantiate()
		var materials: Array[ParticleProcessMaterial] = []
		for child: Node in node.find_children("*", "GPUParticles2D", true, false):
			var particles: GPUParticles2D = child as GPUParticles2D
			var material: ParticleProcessMaterial = particles.process_material as ParticleProcessMaterial
			assert(material != null, path + ": GPUParticles2D without ParticleProcessMaterial")
			materials.append(material)
		assert(not materials.is_empty(), path + " has no GPUParticles2D")
		for material: ParticleProcessMaterial in materials:
			if path == "res://scenes/blast/Blast03.tscn":
				# Yarn spin is tuned with angular velocity, not the old additive
				# angle curve (which becomes a multiplier in Godot 4).
				assert(material.angle_curve == null, "Yarn still uses the old angle multiplier")
				assert(material.angular_velocity_min <= material.angular_velocity_max)
				# Spin damp: threads spin fast at blast start, then slow to a
				# stop over their lifetime via an angular velocity curve.
				var spin_curve: CurveTexture = material.angular_velocity_curve as CurveTexture
				assert(spin_curve != null, "Yarn lost its spin damp curve")
				assert(spin_curve.curve != null, "Yarn spin damp curve has no Curve")
				assert(is_equal_approx(spin_curve.curve.sample_baked(0.0), 1.0), "Yarn spin damp should start at full speed")
				assert(spin_curve.curve.sample_baked(0.4) < 0.9, "Yarn spin damp should be fading by mid life")
				assert(is_zero_approx(spin_curve.curve.sample_baked(1.0)), "Yarn spin damp should reach zero by end of lifetime")
				print("Yarn spin range (degrees/s): ", material.angular_velocity_min, " to ", material.angular_velocity_max)
			_check_range(material, "initial_velocity", EXPECTED[path]["initial_velocity"])
			if EXPECTED[path].has("damping"):
				_check_range(material, "damping", EXPECTED[path]["damping"])
			if EXPECTED[path].has("angle"):
				_check_range(material, "angle", EXPECTED[path]["angle"])
			if EXPECTED[path].has("angular_velocity"):
				_check_range(material, "angular_velocity", EXPECTED[path]["angular_velocity"])
			if EXPECTED[path].has("scale"):
				_check_range(material, "scale", EXPECTED[path]["scale"])
		node.free()
		print("PASS ", path)
	var wants_capture: bool = false
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("capture="):
			wants_capture = true
	if wants_capture:
		# Visual proof on a real renderer: settled yarn-thread burst.
		var blast: Node2D = (load("res://scenes/blast/Blast03.tscn") as PackedScene).instantiate()
		blast.position = Vector2(832.0, 384.0)
		root.add_child(blast)
		blast.call("start")
		await create_timer(0.7).timeout
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		for argument: String in OS.get_cmdline_user_args():
			if argument.begins_with("capture="):
				if image == null or image.save_png(argument.trim_prefix("capture=")) != OK:
					push_error("BLAST TEST FAILED: capture could not be saved")
					quit(1)
					return
				print("CAPTURE saved")
		blast.free()
	print("BLAST TEST completed")
	quit(0)

func _check_range(material: ParticleProcessMaterial, base: String, expected: Vector2) -> void:
	var actual: Vector2 = Vector2(material.get(base + "_min"), material.get(base + "_max"))
	assert(actual.is_equal_approx(expected), "%s: %s is %s, expected %s" % [material.resource_name, base, actual, expected])
