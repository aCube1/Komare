extends KinematicBody2D
class_name Unit

enum {
	DEFAULT_SNAP,
	NO_SNAP,
}

var snap := Vector2.ZERO
var velocity := Vector2.ZERO
var was_on_floor := false

export(NodePath) var anim_sprite
export(NodePath) var anim_player
export(NodePath) var anim_tree

onready var animated_sprite: AnimatedSprite = get_node_or_null(anim_sprite)
onready var animation_player: AnimationPlayer = get_node_or_null(anim_player)
onready var animation_tree: AnimationTree = get_node_or_null(anim_tree)

onready var current_gravity: float setget set_gravity

func _ready() -> void:
	set_snap(DEFAULT_SNAP)

### MOVEMENT ###
func move(delta: float, motion: int, acceleration: float, max_speed: float) -> void:
	velocity.x += acceleration * motion * delta
	velocity.x = clamp(velocity.x, -max_speed, max_speed)

	was_on_floor = is_on_floor() # Check if the Unit is on floor before apply next movement
	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP)

func jump(impulse: float) -> void:
	velocity.y = -impulse

func cut_jump() -> void:
	# Half the unit's vertical velocity
	velocity.y *= 0.5

func apply_gravity(delta: float, max_gravity: float = 1000) -> void:
	# Don't let the unit be an unstoppable meteor
	velocity.y = min(velocity.y + current_gravity * delta, max_gravity)

func apply_friction(delta: float, friction: float) -> void:
	# if the next friction is greater than 0 apply friction
	if abs(velocity.x) > 0.0 and abs(velocity.x) + friction * delta > 0.0:
		velocity.x += friction * sign(velocity.x) * delta
	else:
		velocity.x = 0.0 # If next friction is lower than 0, set velocity to 0

func set_velocity_x(value: float) -> void:
	velocity.x = value

func set_velocity_y(value: float) -> void:
	velocity.y = value

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
	if animation_tree != null:
		var playback = animation_tree.get("parameters/playback")
		if playback is AnimationNodeStateMachinePlayback:
			playback.travel(name)
	elif animation_player != null and animation_player.current_animation != name:
		animation_player.play(name)

func flip_h(flip: bool) -> void:
	if animated_sprite != null:
		animated_sprite.flip_h = flip

func flip_v(flip: bool) -> void:
	if animated_sprite != null:
		animated_sprite.flip_v = flip

