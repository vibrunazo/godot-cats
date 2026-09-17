extends SceneTree
## Probe: how did Blast03's angle curve survive the migration?

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	create_timer(8.0).timeout.connect(func() -> void:
		push_error("PROBE timed out")
		quit(1))
	var blast: Node2D = (load("res://scenes/blast/Blast03.tscn") as PackedScene).instantiate()
	var particles: GPUParticles2D = blast.get_node("GPUParticles2D") as GPUParticles2D
	var material: ParticleProcessMaterial = particles.process_material as ParticleProcessMaterial
	var curve_texture: CurveTexture = material.angle_curve as CurveTexture
	if curve_texture == null:
		print("CURVE null!")
	else:
		var curve: Curve = curve_texture.curve
		print("CURVE points=", curve.get_point_count(), " min=", curve.min_value, " max=", curve.max_value)
		for i: int in curve.get_point_count():
			print("POINT ", i, ": ", curve.get_point_position(i))
	blast.free()
	quit(0)
