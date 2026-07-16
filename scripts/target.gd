class_name Target
extends Node3D

## A hittable target: three concentric rings on a backing board. Balls and
## arrows that enter the Face area score points by ring distance from the
## target centre, trigger a brief emission flash on the rings, and play a short beep.

signal target_hit(points: int)

const HIT_COOLDOWN := 1.0

## Local-space center of the scoring rings. Stays ZERO for targets whose origin
## is the disc center; set in the scene when the origin is elsewhere (e.g. the
## archery target's origin is at the stand base for easy ground placement).
@export var bull_center: Vector3 = Vector3.ZERO

var _last_hit := {}  # instance id -> _time
var _time := 0.0


# NOTIFICATION_ENTER_TREE is always dispatched synchronously (unlike
# NOTIFICATION_READY, whose propagation timing relative to a caller's
# immediately-following add_child() is not guaranteed the same way headless
# under the dummy renderer/xr-off harness). Build the hit sound here so
# `$HitSound.stream` is populated as soon as the node is in the tree, unless
# the scene already assigned a stream, in which case building is skipped.
func _enter_tree() -> void:
	if $HitSound.stream != null:
		return
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
	var rel := local_pos - bull_center
	return Scoring.points_for_ring_distance(Vector2(rel.x, rel.y).length())


func _on_face_body_entered(body: Node3D) -> void:
	if not (body.is_in_group("balls") or body.is_in_group("arrows")):
		return
	register_hit(body, body.global_position)


## Direct hit registration for projectiles whose collider may be disabled
## before the Face area samples the overlap (arrows freeze on stick).
## `world_hit` is the exact impact point used for ring scoring; `body` keys
## the per-projectile cooldown.
func register_hit(body: Node3D, world_hit: Vector3) -> void:
	var id := body.get_instance_id()
	if _last_hit.has(id) and _time - _last_hit[id] < HIT_COOLDOWN:
		return
	var points := points_for_local_hit(to_local(world_hit))
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
