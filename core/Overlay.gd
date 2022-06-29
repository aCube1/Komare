extends CanvasLayer

onready var popup = $Popup
onready var label = $Popup/Label
onready var timer = $Timer

func _unhandled_key_input(event: InputEventKey) -> void:
	if event.pressed:
		match event.scancode:
			KEY_F12:
				toggle_overlay()

func toggle_overlay() -> void:
	popup.visible = not popup.visible
	if popup.visible and timer.is_stopped():
		update_overlay()
		timer.start()

	if not popup.visible:
		timer.stop()

func update_overlay() -> void:
	label.text = """Vsync Enabled: %s
		FPS: %d
		DT: %fs
		DrawCalls: %d
	""" % [
		OS.is_vsync_enabled(),
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.TIME_PROCESS),
		Performance.get_monitor(Performance.RENDER_2D_DRAW_CALLS_IN_FRAME),
	]
	popup.rect_size = label.rect_size

func _on_Timer_timeout() -> void:
	update_overlay()
