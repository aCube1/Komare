extends KinematicBody2D

enum {
	DEFAULT_SNAP,
	NO_SNAP,
}

var snap := Vector2.ZERO
var velocity := Vector2.ZERO

onready var current_gravity: float setget set_gravity

### MOVEMENT ###
func walk(delta: float, motion: int, acceleration: float, max_speed: float) -> void:
	velocity.x += acceleration * motion * delta
	velocity.x = clamp(velocity.x, -max_speed, max_speed)

	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP)

func jump(impulse: float) -> void:
	velocity.y = -impulse

func cut_jump() -> void:
	velocity.y -= velocity.y / 2

func apply_gravity(delta: float) -> void:
	velocity.y += current_gravity * delta

func apply_friction(delta: float, friction: float) -> void:
	velocity.x = int(lerp(velocity.x, 0, friction * delta))

func set_gravity(gravity: float) -> void:
	current_gravity = gravity

### SPRITE AND ANIMATION ###
func play_animation(name: String) -> void:
	if $AnimationTree != null:
		var state_machine = $AnimationTree["parameters/playback"]
		if state_machine is AnimationNodeStateMachinePlayback:
			state_machine.travel(name)
	elif $AnimationPlayer != null and $AnimationPlayer.current_animation != name:
		$AnimationPlayer.play(name)

func flip_h(flip: bool) -> void:
	if $AnimatedSprite != null:
		$AnimatedSprite.flip_h = flip

func flip_v(flip: bool) -> void:
	if $AnimatedSprite != null:
		$AnimatedSprite.flip_v = flip

func set_snap(option: int) -> void:
	match option:
		DEFAULT_SNAP:
			snap = Vector2.DOWN * 8.0
		NO_SNAP:
			snap = Vector2.ZERO
