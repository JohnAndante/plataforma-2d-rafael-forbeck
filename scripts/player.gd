extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 80.0
const JUMP_VELOCITY = -300.0

enum PlayerState {
	idle,
	walk,
	jump,
	fall,
}

var curr_state: PlayerState

func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta:float) -> void:
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	match curr_state:
		PlayerState.idle:
			idle_state()
		PlayerState.walk:
			walk_state()
		PlayerState.jump:
			jump_state()
		PlayerState.fall:
			fall_state()

	move_and_slide()
	
func go_to_idle_state():
	curr_state = PlayerState.idle
	anim.play("idle")
	pass
	
func go_to_walk_state():
	curr_state = PlayerState.walk
	anim.play("walk")
	pass
	
func go_to_jump_state():
	curr_state = PlayerState.jump
	anim.play("jump")
	velocity.y = JUMP_VELOCITY
	pass
	
func go_to_fall_state():
	curr_state = PlayerState.fall
	anim.play("falling")
	
func idle_state():
	move()
		
	if velocity.x != 0:
		go_to_walk_state()
		return
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
	if velocity.y < 0:
		go_to_fall_state()
		return

func walk_state():
	move()
	
	if velocity.x == 0:
		go_to_idle_state()
		return
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
	if !is_on_floor() and velocity.y > 0:
		go_to_fall_state()
		return

func jump_state():
	move()
	
	if velocity.y > 0:
		go_to_fall_state()
		return
		
	if velocity.y == 0:
		if is_on_floor() and velocity.x == 0:
			go_to_idle_state()
			return
		if is_on_floor() and velocity.x != 0:
			go_to_walk_state()
			return
	
func fall_state():
	move()
	
	if velocity.y == 0:
		if is_on_floor() and velocity.x == 0:
			go_to_idle_state()
			return
		if is_on_floor() and velocity.x != 0:
			go_to_walk_state()
			return

func move():
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


func temp(_delta: float) -> void:
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
