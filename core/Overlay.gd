extends CanvasLayer

onready var popup = $Popup
onready var label = $Popup/Label
onready var timer = $Timer

func _ready() -> void:
	if OS.is_debug_build():
		toggle_overlay() # Activate the overlay on startup

func _unhandled_key_input(event: InputEventKey) -> void:
	if event.pressed:
		match event.scancode:
			KEY_F12:
				toggle_overlay()
			KEY_F11:
				### STOLEN CODE :) ###
				get_tree().set_debug_collisions_hint(not get_tree().is_debugging_collisions_hint())
				var root_node: Node = get_tree().get_root()
				var queue_stack: Array = []
				queue_stack.push_back(root_node)
				# Traverse tree to call update methods where available.
				while not queue_stack.empty():
					var node: Node = queue_stack.pop_back()
					if is_instance_valid(node):
						if node is TileMap:
							node.show_collision = get_tree().is_debugging_collisions_hint()
						if node.has_method("update"):
							#warning-ignore:unsafe_method_access
							node.update()
						var children_count: int = node.get_child_count()
						for child_index in range(0, children_count):
							queue_stack.push_back(node.get_child(child_index))
				### END OF STOLEN CODE ###

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
		%s
	""" % [
		OS.is_vsync_enabled(),
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.TIME_PROCESS),
		Performance.get_monitor(Performance.RENDER_2D_DRAW_CALLS_IN_FRAME),
		get_tree().is_debugging_collisions_hint()
	]
	popup.rect_size = label.rect_size

func _on_Timer_timeout() -> void:
	update_overlay()
