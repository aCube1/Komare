extends Node

enum {
	STATE_IDLE,
	STATE_WALK,
	STATE_FALL,
	STATE_JUMP,
}

const DEFAULT_SNAP := Vector2.DOWN * 8.0
const NO_SNAP := Vector2.ZERO

export(float) var ground_friction := 48.0
export(float) var slip_friction := 24.0
export(float) var air_friction := 8.0

export(float) var time_to_ascent := 0.40
export(float) var time_to_descent := 0.30
export(int) var jump_height := 48
export(int) var jump_distance := 96

var snap := DEFAULT_SNAP
var current_state := STATE_IDLE setget set_state
var last_state := STATE_IDLE
var velocity := Vector2.ZERO
var motion := 0
var can_jump := false

onready var parent: KinematicBody2D = get_parent()

onready var jump_gravity: float = (2.0 * jump_height) / pow(time_to_ascent, 2)
onready var fall_gravity: float = (2.0 * jump_height) / pow(time_to_descent, 2)
onready var jump_impulse: float = (2.0 * jump_height) / time_to_ascent
onready var current_gravity: float = fall_gravity

onready var max_speed: float = jump_distance / (2.0 * time_to_ascent)
onready var acceleration := max_speed * 2.0

func _process(_delta: float) -> void:
	if Input.is_action_pressed("Left"):
		motion -= 1
		parent.flip_h(true)
	if Input.is_action_pressed("Right"):
		motion += 1
		parent.flip_h(false)

	if motion != 0:
		set_state(STATE_WALK)
	else:
		set_state(STATE_IDLE)

	if parent.is_on_floor():
		snap = DEFAULT_SNAP
		can_jump = true
	else:
		set_state(STATE_FALL)

	if Input.is_action_pressed("Jump") and can_jump:
		snap = NO_SNAP
		set_state(STATE_JUMP)

func _physics_process(delta: float) -> void:
	check_state(delta)

	velocity.y += current_gravity * delta
	velocity = parent.move_and_slide_with_snap(velocity, snap, Vector2.UP)
	motion = 0

func check_state(delta: float) -> void:
	match current_state:
		STATE_IDLE:
			parent.play_animation("Idle")
			velocity.x = int(lerp(velocity.x, 0, ground_friction * delta))
		STATE_WALK:
			parent.play_animation("Move")
			move(delta)
		STATE_FALL:
			parent.play_animation("Fall")
			fall()
			set_state(last_state) # Return to the previous state
		STATE_JUMP:
			parent.play_animation("Jump")
			jump()
			set_state(last_state) # Return to the previous state

func move(delta: float) -> void:
	velocity.x += acceleration * motion * delta
	velocity.x = clamp(velocity.x, -max_speed, max_speed)

func fall() -> void:
	can_jump = false
	current_gravity = fall_gravity

func jump() -> void:
	can_jump = false
	current_gravity = jump_gravity
	velocity.y = -jump_impulse

func set_state(next: int) -> void:
	last_state = current_state
	current_state = next
