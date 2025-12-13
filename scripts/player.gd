extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 80.0
const JUMP_VELOCITY = -300.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Change sprite flip based on direction
	# Its elif insted of else to not force a single direction when 0
	if direction > 0:
		anim.flip_h = false
	elif direction < 0:
		anim.flip_h = true
		
	if is_on_floor():
		if direction > 0:
			anim.play("walk")
		elif direction < 0:
			anim.play("walk")
		else:
			anim.play("idle")
	else:
		if velocity.y < 0:
			anim.play("jump")
		if velocity.y > 0:
			anim.play("falling")
	

	move_and_slide()
