extends Node

enum {
	STATE_IDLE,
	STATE_WALK,
	STATE_FALL,
	STATE_JUMP,
}

export(float) var slip_friction
export(float) var ground_friction
export(float) var air_friction

export(int) var jump_distance
export(int) var jump_height
export(float) var ascent_time # Time to reach jump peak
export(float) var descent_time # Time to fall
export(float) var max_coyote_time
export(float) var max_jumpbuffer_time

var current_state := STATE_IDLE
var motion := 0
var last_motion := 0
var coyote_timer := 0.0
var jumpbuffer_timer := 0.0

onready var parent: KinematicBody2D = get_parent()

onready var jump_gravity: float = (jump_height * 2.0) / pow(ascent_time, 2)
onready var fall_gravity: float = (jump_height * 2.0) / pow(descent_time, 2)
onready var jump_impulse: float = (jump_height * 2.0) / ascent_time

onready var max_speed: float = sqrt(jump_distance * jump_impulse)
onready var acceleration := max_speed * 2.0

func _process(delta: float) -> void:
	if Input.is_action_pressed("Right"):
		motion += 1
		parent.flip_h(false)
	if Input.is_action_pressed("Left"):
		motion -= 1
		parent.flip_h(true)

	if Input.is_action_just_pressed("Jump") or jumpbuffer_timer > 0.0:
		# If the Unit is on those states, he can jump
		if [STATE_IDLE, STATE_WALK].has(current_state):
			parent.jump(jump_impulse)
			jumpbuffer_timer = 0.0 # Reset the jumpbuffer timer, the Unit jumped
		elif jumpbuffer_timer <= 0.0:
			jumpbuffer_timer = max_jumpbuffer_time # Start the jumpbuffer timer

	# If Jump is released, cut the jump height
	if Input.is_action_just_released("Jump"):
		parent.cut_jump()

	if coyote_timer > 0.0:
		coyote_timer -= delta
	if jumpbuffer_timer > 0.0:
		jumpbuffer_timer -= delta

func _physics_process(delta: float) -> void:
	if motion == 0 or parent.is_on_wall():
		set_state(STATE_IDLE)
	else:
		set_state(STATE_WALK)

	if parent.velocity.y > 0.0:
		if not parent.is_on_floor() and parent.was_on_floor:
			coyote_timer = max_coyote_time
			parent.velocity.y = 0.0 # Remove the remainder gravity of the Unit
		else:
			set_state(STATE_FALL)
	if parent.velocity.y < 0.0:
		set_state(STATE_JUMP)
		coyote_timer = 0.0 # Stop the coyote timer, the Unit already jumped

	parent.set_label("%s" %  ["idle", "walk", "fall", "jump"][current_state])
	check_state(delta)

	parent.set_gravity(get_gravity())
	if coyote_timer <= 0.0:
		parent.apply_gravity(delta)

	parent.move(delta, motion, acceleration, max_speed)
	motion = 0

func check_state(delta: float) -> void:
	match current_state:
		STATE_IDLE:
			if parent.velocity.y > 0.0:
				parent.apply_friction(delta, air_friction)
			else:
				parent.apply_friction(delta, ground_friction)
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
			parent.play_animation("Jump")

func get_gravity() -> float:
	return fall_gravity if parent.velocity.y > 0.0 else jump_gravity

func set_state(next: int) -> void:
	if next != current_state:
		current_state = next
