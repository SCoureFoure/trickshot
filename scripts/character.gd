extends Node3D

## Root of the character scene. Merges the KayKit animation packs (movement,
## general, ranged) into the scene's AnimationPlayer as named libraries, then
## plays a default idle animation. Loop mode is patched onto clips whose name
## matches a movement/idle keyword; everything else plays once.

const ANIM_PACKS := {
	"movement": "res://assets/kaykit/animations/Rig_Medium_MovementBasic.glb",
	"general": "res://assets/kaykit/animations/Rig_Medium_General.glb",
	"ranged": "res://assets/kaykit/animations/Rig_Medium_CombatRanged.glb",
}
const LOOP_KEYWORDS := ["Idle", "Walking", "Running", "Aiming", "Shooting"]

@export var default_anim := "general/Idle_A"
@onready var anim_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	_load_animation_packs()
	if anim_player.has_animation(default_anim):
		anim_player.play(default_anim)


func _load_animation_packs() -> void:
	for lib_name in ANIM_PACKS:
		var path: String = ANIM_PACKS[lib_name]
		var packed_scene: PackedScene = load(path)
		if packed_scene == null:
			push_warning("Missing anim pack: " + path)
			continue
		var instance := packed_scene.instantiate()
		var source_player: AnimationPlayer = instance.get_node_or_null("AnimationPlayer")
		if source_player == null:
			push_warning("Missing AnimationPlayer in anim pack: " + path)
			instance.free()
			continue
		var lib := source_player.get_animation_library("")
		for anim_name in lib.get_animation_list():
			for keyword in LOOP_KEYWORDS:
				if String(anim_name).contains(keyword):
					lib.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
					break
		anim_player.add_animation_library(lib_name, lib)
		instance.free()


## Plays the named animation if it exists; otherwise warns and leaves the
## current animation playing.
func play_anim(anim_name: StringName) -> void:
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
	else:
		push_warning("Unknown animation: " + String(anim_name))
