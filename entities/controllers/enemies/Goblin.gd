extends Node

enum {
	STATE_IDLE,
	STATE_WALK,
}

const JUMP_HEIGHT := 32
const DESCENT_TIME := 0.4

export var slip_friction: float
export var stop_friction: float
export var max_speed: float
export(float, 0, 1) var accel_time # Time to reach max speed

var current_state := STATE_IDLE
var motion := 0
var last_motion := 0
var fall_gravity: float = (JUMP_HEIGHT * 2.0) / pow(DESCENT_TIME, 2)

onready var unit := owner as Unit
onready var target_detector := unit.get_node_or_null("Pivot/TargetDetector")

onready var acceleration := (max_speed * 2.0) / pow(accel_time, 2)

func _ready() -> void:
	unit.set_gravity(fall_gravity)

func _physics_process(delta: float) -> void:
	var next_velocity := Vector2(unit.velocity.x + acceleration * motion * delta,
								 unit.velocity.y + fall_gravity * delta)

	# If the Unit don't fall, move it
	if unit.test_move(unit.transform, next_velocity):
		current_state = STATE_WALK
	else:
		current_state = STATE_IDLE
	if unit.is_on_wall():
		motion *= -1 # Invert the motion

	if not unit.is_on_floor():
		current_state = STATE_IDLE

	check_state()
	unit.apply_gravity(delta)
	unit.move(delta, motion, acceleration, max_speed)

func check_state() -> void:
	match current_state:
		STATE_IDLE:
			motion = 0
			unit.play_animation("Idle")
		STATE_WALK:
			if motion == 0:
				motion = [-1, 1][randi() % 2]
			if last_motion != motion:
				last_motion = motion
			unit.play_animation("Walk")
