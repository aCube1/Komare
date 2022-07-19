extends Node

enum {
	STATE_IDLE,
	STATE_WALK,
	STATE_FALL,
	STATE_JUMP,
}

export var max_speed: float
export var ground_accel_time: float # Time to reach max speed
export var air_accel_time: float # Time to reach max speed
export(float, 0, 1) var stop_friction # Stop time percentage
export(float, 0, 1) var slip_friction # Friction to change the motion

export var jump_height: int
export var ascent_time: float # Time to reach jump peak
export var descent_time: float # Time to fall
export var max_coyote_time: float
export var max_jumpbuffer_time: float
export var max_gravity: float

var current_state := STATE_IDLE
var motion := 0
var coyote_timer := 0.0
var jumpbuffer_timer := 0.0

onready var unit := owner as Unit

onready var jump_gravity: float = (jump_height * 2.0) / pow(ascent_time, 2)
onready var fall_gravity: float = (jump_height * 2.0) / pow(descent_time, 2)
onready var jump_impulse: float = (jump_height * 2.0) / ascent_time

onready var ground_acceleration := (max_speed * 2.0) / pow(ground_accel_time, 2)
onready var air_acceleration := (max_speed * 2.0) / pow(air_accel_time, 2)

func _process(delta: float) -> void:
	if Input.is_action_pressed("Right"):
		motion += 1
		unit.flip_h(false)
	if Input.is_action_pressed("Left"):
		motion -= 1
		unit.flip_h(true)

	if Input.is_action_just_pressed("Jump") or jumpbuffer_timer > 0.0:
		# If the Unit is on those states, he can jump
		if [STATE_IDLE, STATE_WALK].has(current_state):
			unit.jump(jump_impulse)
			jumpbuffer_timer = 0.0 # Reset the jumpbuffer timer, the Unit jumped
		elif jumpbuffer_timer <= 0.0:
			jumpbuffer_timer = max_jumpbuffer_time # Start the jumpbuffer timer

	# If Jump is released, cut the jump height
	if Input.is_action_just_released("Jump"):
		unit.cut_jump()

	if coyote_timer > 0.0:
		coyote_timer -= delta
	if jumpbuffer_timer > 0.0:
		jumpbuffer_timer -= delta

func _physics_process(delta: float) -> void:
	### STATE MACHINE ###
	if motion == 0 or unit.is_on_wall():
		set_state(STATE_IDLE)
	else:
		set_state(STATE_WALK)

	if unit.velocity.y > 0.0:
		if not unit.is_on_floor() and unit.was_on_floor:
			coyote_timer = max_coyote_time
			unit.velocity.y = 0.0 # Remove the remainder gravity of the Unit
		else:
			set_state(STATE_FALL)
	elif unit.velocity.y < 0.0:
		set_state(STATE_JUMP)
		coyote_timer = 0.0 # Stop the coyote timer, the Unit already jumped

	### MOVEMENT ###
	unit.set_label("%s" % get_acceleration())
	check_state()

	update_gravity()
	if coyote_timer <= 0.0:
		unit.apply_gravity(delta, max_gravity)

	unit.move(delta, motion, get_acceleration(), max_speed)
	motion = 0

func check_state() -> void:
	match current_state:
		STATE_IDLE:
			unit.apply_friction(stop_friction)
			unit.play_animation("Idle")
		STATE_WALK:
			if sign(unit.velocity.x) != motion:
				unit.apply_friction(slip_friction)
			unit.play_animation("Walk")
		STATE_FALL:
			unit.set_snap(unit.DEFAULT_SNAP)
			unit.play_animation("Fall")
		STATE_JUMP:
			unit.set_snap(unit.NO_SNAP)
			unit.play_animation("Jump")

func update_gravity() -> void:
	unit.set_gravity(fall_gravity if unit.velocity.y > 0.0 else jump_gravity)

func get_acceleration() -> float:
	return ground_acceleration if is_zero_approx(unit.velocity.y) else air_acceleration

func set_state(next: int) -> void:
	if next != current_state:
		current_state = next
