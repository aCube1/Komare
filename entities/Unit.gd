extends KinematicBody2D
class_name Unit

enum {
	DEFAULT_SNAP,
	NO_SNAP,
}

var snap := Vector2.ZERO
var velocity := Vector2.ZERO
var was_on_floor := false

onready var current_gravity: float setget set_gravity

func _ready() -> void:
	set_snap(DEFAULT_SNAP)

### DEBUG ONLY ###
func set_label(text: String) -> void:
	$Label.text = text

### MOVEMENT ###
func move(delta: float, motion: int, acceleration: float, max_speed: float) -> void:
	velocity.x += acceleration * motion * delta
	velocity.x = clamp(velocity.x, -max_speed, max_speed)

	was_on_floor = is_on_floor() # Check if the Unit is on floor before apply next movement
	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP)

func jump(impulse: float) -> void:
	velocity.y = -impulse

func cut_jump() -> void:
	velocity.y *= 0.5

func apply_gravity(delta: float, max_gravity: float = 1000) -> void:
	# Don't let the unit be an unstoppable meteor
	velocity.y = min(velocity.y + current_gravity * delta, max_gravity)

func apply_friction(friction: float) -> void:
	velocity.x = lerp(velocity.x, 0, friction)

func set_gravity(gravity: float) -> void:
	current_gravity = gravity

func set_snap(option: int) -> void:
	match option:
		DEFAULT_SNAP:
			snap = Vector2.DOWN * 8.0
		NO_SNAP:
			snap = Vector2.ZERO

### SPRITE AND ANIMATION ###
func play_animation(name: String) -> void:
	if get_node_or_null("AnimatedSprite/Tree") != null:
		var state_machine = $AnimatedSprite/Tree["parameters/playback"]
		if state_machine is AnimationNodeStateMachinePlayback:
			state_machine.travel(name)
	elif get_node_or_null("AnimatedSprite/Player") != null \
	and $AnimatedSprite/Player.current_animation != name:
		$AnimatedSprite/Player.play(name)

func flip_h(flip: bool) -> void:
	if $AnimatedSprite != null:
		$AnimatedSprite.flip_h = flip

func flip_v(flip: bool) -> void:
	if $AnimatedSprite != null:
		$AnimatedSprite.flip_v = flip

