extends Node

enum {
	STATE_IDLE,
	STATE_WALK,
	STATE_FALL,
	STATE_JUMP,
}

export(float) var slip_friction := 32.0
export(float) var ground_friction := 24.0
export(float) var air_friction := 8.0

export(int) var jump_height
export(int) var jump_distance
export(float) var ascent_time # Time to reach jump peak
export(float) var descent_time # Time to fall

var current_state := STATE_IDLE
var last_state := current_state
var motion := 0
var last_motion := 0

onready var parent: KinematicBody2D = get_parent()

onready var jump_gravity: float = (jump_height * 2.0) / pow(ascent_time, 2)
onready var fall_gravity: float = (jump_height * 2.0) / pow(descent_time, 2)
onready var jump_impulse: float = (jump_height * 2.0) / ascent_time

onready var max_speed: float = sqrt(jump_distance * jump_impulse)
onready var acceleration := max_speed * 2.0

func _process(_delta: float) -> void:
	if Input.is_action_pressed("Right"):
		motion += 1
		parent.flip_h(false)
		set_state(STATE_WALK)
	if Input.is_action_pressed("Left"):
		motion -= 1
		parent.flip_h(true)
		set_state(STATE_WALK)

	if motion == 0 or parent.is_on_wall():
		set_state(STATE_IDLE)
	if parent.velocity.y > 0.0:
		set_state(STATE_FALL)

	# If the Unit is on those states, he can jump
	if Input.is_action_just_pressed("Jump"):
		if [STATE_IDLE, STATE_WALK].has(current_state):
				set_state(STATE_JUMP)

	# If Jump is released, cut the jump height
	if Input.is_action_just_released("Jump"):
		parent.cut_jump()

func _physics_process(delta: float) -> void:
	check_state(delta)

	parent.set_gravity(get_gravity())
	parent.apply_gravity(delta)
	parent.walk(delta, motion, acceleration, max_speed)
	motion = 0

func check_state(delta: float) -> void:
	match current_state:
		STATE_IDLE:
			if parent.is_on_floor():
				parent.apply_friction(delta, ground_friction)
			else:
				parent.apply_friction(delta, air_friction)
			parent.play_animation("Idle")
		STATE_WALK:
			if last_motion != motion:
				parent.apply_friction(delta, slip_friction)
				last_motion = motion
			parent.play_animation("Walk")
		STATE_FALL:
			parent.set_snap(parent.DEFAULT_SNAP)
			parent.play_animation("Fall")
		STATE_JUMP:
			parent.set_snap(parent.NO_SNAP)
			parent.jump(jump_impulse)
			parent.play_animation("Jump")

func get_gravity() -> float:
	return fall_gravity if parent.velocity.y > 0.0 else jump_gravity

func set_state(next: int) -> void:
	if next != current_state:
		last_state = current_state
		current_state = next
