extends Node

enum {
	STATE_IDLE,
	STATE_WALK,
	STATE_FALL,
}

export(float) var ground_friction := 24.0
export(float) var air_friction := 4.0

export(float) var ascent_time := 0.40
export(float) var descent_time := 0.30
export(int) var jump_height := 48
export(int) var jump_distance := 96

var current_state := STATE_IDLE
var motion := 0
var can_jump := false

onready var parent: KinematicBody2D = get_parent()

onready var jump_gravity: float = (jump_height * 2.0) / pow(ascent_time, 2)
onready var fall_gravity: float = (jump_height * 2.0) / pow(descent_time, 2)
onready var jump_impulse: float = (jump_height * 2.0) / ascent_time

onready var max_speed: float = jump_distance / (ascent_time * 2.0)
onready var acceleration := max_speed * 2.0

func _process(_delta: float) -> void:
	if Input.is_action_pressed("Right"):
		motion += 1
		parent.flip_h(false)
		current_state = STATE_WALK
	if Input.is_action_pressed("Left"):
		motion -= 1
		parent.flip_h(true)
		current_state = STATE_WALK

func _physics_process(delta: float) -> void:
	if motion == 0:
		current_state = STATE_IDLE

	if not parent.is_on_floor():
		current_state = STATE_FALL
	else:
		parent.set_snap(parent.DEFAULT_SNAP)

	parent.set_label("%s" % motion)

	check_state(delta)

	parent.apply_gravity(delta)
	parent.velocity = parent.move_and_slide_with_snap(parent.velocity, parent.snap, Vector2.UP)

func check_state(delta: float) -> void:
	match current_state:
		STATE_IDLE:
			parent.apply_friction(delta, ground_friction)
			parent.play_animation("Idle")
		STATE_WALK:
			parent.walk(delta, motion, acceleration, max_speed)
			parent.play_animation("Walk")
			motion = 0
		STATE_FALL:
			parent.set_gravity(fall_gravity)
			parent.play_animation("Fall")
