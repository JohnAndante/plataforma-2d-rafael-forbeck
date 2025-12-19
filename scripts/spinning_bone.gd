extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var SPEED = 120
var curr_direction := Vector2.RIGHT

func _process(delta: float) -> void:
	position.x += SPEED * curr_direction.x * delta

func set_direction(new_direction) -> void:
	self.curr_direction = Vector2(new_direction, 0)
	anim.flip_h = new_direction < 0

func _on_self_destruct_timer_timeout() -> void:
	queue_free()

func _on_area_entered(_area: Area2D) -> void:
	queue_free()

func _on_body_entered(_body: Node2D) -> void:
	queue_free()
