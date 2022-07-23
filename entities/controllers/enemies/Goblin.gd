extends Node

### BEHAVIOR ###
## Walk to the left or the right, the walk side is randomic.
## After walk, be idle for a few moments and chose a random side to walk.
## If target enter the raycast, enter in Attack State.
## After the attack animation ends, set the state to Idle and restart the timer.

enum {
	STATE_IDLE,
	STATE_WALK,
	STATE_ATTACK,
}

const JUMP_HEIGHT := 32
const DESCENT_TIME := 0.4

export var max_speed: float
export var accel_time: float # Time to reach max speed
export var stop_time: float # Time to stop
export var max_walking_time: float
export var max_idle_time: float

var current_state := STATE_IDLE setget set_state
var motion := 0
var walking_time := max_walking_time
var idle_time := max_idle_time
var fall_gravity: float = (JUMP_HEIGHT * 2.0) / pow(DESCENT_TIME, 2)

onready var unit := owner as Unit
onready var pivot: Position2D = unit.get_node("Pivot")
onready var ground_detector: Area2D = pivot.get_node("GroundDetector")
onready var target_detector: RayCast2D = pivot.get_node("TargetDetector")

onready var acceleration := (max_speed * 2.0) / pow(accel_time, 2)
onready var desaceleration := (max_speed * -2.0) / pow(stop_time, 2)

func _ready() -> void:
	randomize()
	unit.set_gravity(fall_gravity)

func _physics_process(delta: float) -> void:
	if not [STATE_ATTACK].has(current_state):
		if not unit.is_on_floor() or motion == 0:
			set_state(STATE_IDLE)
		else:
			set_state(STATE_WALK)
			if target_detector.is_colliding():
				set_state(STATE_ATTACK)

	check_state(delta)
	if ground_detector.get_overlapping_bodies().empty():
		if pivot.scale.x == motion:
			motion = 0
		walking_time = 0.0
	elif unit.is_on_wall():
		if pivot.scale.x == motion:
			motion *= -1
		walking_time = 0.0

	if motion != 0:
		pivot.scale.x = motion
		unit.flip_h(motion < 0)
	unit.apply_gravity(delta)
	unit.move(delta, motion, acceleration, max_speed)

func check_state(delta: float) -> void:
	match current_state:
		STATE_IDLE:
			idle_time -= delta
			if idle_time <= 0.0:
				motion = [-1, 1][randi() % 2] # Move to the left or the right
				idle_time = max_idle_time + rand_range(-1.0, 1.0)
			unit.apply_friction(delta, desaceleration)
			unit.play_animation("Idle")
		STATE_WALK:
			walking_time -= delta
			if walking_time <= 0.0:
				walking_time = max_walking_time + rand_range(-0.5, 0.5)
				motion = 0
			unit.play_animation("Walk")
		STATE_ATTACK:
			motion = 0
			idle_time = 0.0
			unit.apply_friction(delta, desaceleration)
			unit.play_animation("Attack")

func set_state(next: int) -> void:
	current_state = next
