class_name Target
extends Node3D

## A hittable target: three concentric rings on a backing board. Balls that
## enter the Face area score points by ring distance from the target centre,
## trigger a brief emission flash on the rings, and play a short beep.

signal target_hit(points: int)

const HIT_COOLDOWN := 1.0

var _last_hit := {}  # instance id -> _time
var _time := 0.0


# NOTIFICATION_ENTER_TREE is always dispatched synchronously (unlike
# NOTIFICATION_READY, whose propagation timing relative to a caller's
# immediately-following add_child() is not guaranteed the same way headless
# under the dummy renderer/xr-off harness). Build the hit sound here so
# `$HitSound.stream` is populated as soon as the node is in the tree.
func _enter_tree() -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED

	var duration := 0.1
	var freq := 880.0
	var amplitude := 0.4
	var sample_count := int(stream.mix_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in range(sample_count):
		var t := i / float(stream.mix_rate)
		var fade := 1.0 - (i / float(sample_count))
		var sample := sin(TAU * freq * t) * amplitude * fade
		var sample_16 := int(clamp(sample, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_16)
	stream.data = bytes

	$HitSound.stream = stream


func _ready() -> void:
	$Face.body_entered.connect(_on_face_body_entered)


func _physics_process(delta: float) -> void:
	_time += delta


func points_for_local_hit(local_pos: Vector3) -> int:
	return Scoring.points_for_ring_distance(Vector2(local_pos.x, local_pos.y).length())


func _on_face_body_entered(body: Node3D) -> void:
	if not body.is_in_group("balls"):
		return
	var id := body.get_instance_id()
	if _last_hit.has(id) and _time - _last_hit[id] < HIT_COOLDOWN:
		return
	var points := points_for_local_hit(to_local(body.global_position))
	if points > 0:
		_last_hit[id] = _time
		emit_signal("target_hit", points)
		_flash()
		$HitSound.play()


func _flash() -> void:
	for ring in $Rings.get_children():
		var mat: StandardMaterial3D = ring.get_surface_override_material(0)
		if mat == null:
			mat = ring.mesh.surface_get_material(0)
		mat.emission_enabled = true
		mat.emission = Color(1, 1, 1)
		mat.emission_energy_multiplier = 2.0
		create_tween().tween_property(mat, "emission_energy_multiplier", 0.0, 0.15)
