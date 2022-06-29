extends KinematicBody2D

func play_animation(name: String) -> void:
	if $AnimationPlayer != null and $AnimationPlayer.current_animation != name:
		$AnimationPlayer.play(name)

func flip_h(flip: bool) -> void:
	if $AnimatedSprite != null:
		$AnimatedSprite.flip_h = flip

func flip_v(flip: bool) -> void:
	if $AnimatedSprite != null:
		$AnimatedSprite.flip_v = flip
