extends Area2D

var SPEED = 80
var curr_direction := Vector2.RIGHT

func _process(delta: float) -> void:
	position.x += SPEED * curr_direction.x * delta
