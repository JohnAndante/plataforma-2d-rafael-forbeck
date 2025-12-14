extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 80.0
const JUMP_VELOCITY = -300.0
const DASH_VELOCITY = 200
const DASH_AIR_FRICTION = 600.0
const DASH_DURATION_SECONDS = 0.5

enum PlayerState {
	idle,
	walk,
	jump,
	fall,
	duck,
	dash,
	dashed_jump,
	dashed_fall,
}

var curr_state: PlayerState
var curr_direction: Vector2 = Vector2.RIGHT;
var dash_timer

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
		PlayerState.duck:
			duck_state()
		PlayerState.dash:
			dash_state()
		PlayerState.dashed_jump:
			dashed_jump_state()
		PlayerState.dashed_fall:
			dashed_fall_state()
	move_and_slide()

func go_to_idle_state():
	curr_state = PlayerState.idle
	anim.play("idle")

func go_to_duck_state():
	curr_state = PlayerState.duck
	anim.play("duck")

func go_to_walk_state():
	curr_state = PlayerState.walk
	anim.play("walk")

func go_to_dash_state():
	curr_state = PlayerState.dash
	anim.play("dash")
	
	var dash_direction = curr_direction.x
	velocity.x = dash_direction * DASH_VELOCITY
	
	dash_timer = DASH_DURATION_SECONDS

func go_to_jump_state():
	curr_state = PlayerState.jump
	anim.play("jump")
	velocity.y = JUMP_VELOCITY

func go_to_dashed_jump_state():
	curr_state = PlayerState.dashed_jump
	anim.play("jump")
	velocity.y = JUMP_VELOCITY * 1.1

func go_to_fall_state():
	if velocity.y < 0:
		velocity.y = move_toward(velocity.y, 0, SPEED)
		
	curr_state = PlayerState.fall
	anim.play("falling")

func go_to_dashed_fall_state():
	curr_state = PlayerState.dashed_fall
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
	if Input.is_action_just_pressed("down"):
		go_to_duck_state()
		return
	if Input.is_action_just_pressed("dash"):
		go_to_dash_state()
		return

func duck_state():
	move_until_stopped()
	
	if Input.is_action_just_released("down"):
		go_to_idle_state()
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
	if Input.is_action_just_pressed("down"):
		go_to_duck_state()
		return
	if Input.is_action_just_pressed("dash"):
		go_to_dash_state()
		return

func dash_state():
	dash_timer -= get_physics_process_delta_time()
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		go_to_dashed_jump_state()
		return
	
	if Input.is_action_just_released("dash") or dash_timer <= 0:
		if is_on_floor():
			go_to_idle_state()
		else:
			go_to_fall_state()
		return

func jump_state():
	move()
	
	if velocity.y < 0 and Input.is_action_just_released("jump"):
		go_to_fall_state()
	
	if velocity.y > 0:
		go_to_fall_state()
		return
		
	if velocity.y == 0:
		if is_on_floor() and velocity.x == 0:
			if Input.is_action_pressed("down"):
				go_to_duck_state()
			else:
				go_to_idle_state()
			return
		if is_on_floor() and velocity.x != 0:
			go_to_walk_state()
			return

func dashed_jump_state():
	velocity.x = move_toward(velocity.x, 0, DASH_AIR_FRICTION * get_physics_process_delta_time())
	
	if velocity.y < 0 and Input.is_action_just_released("jump"):
		go_to_dashed_fall_state()
		return
	
	if velocity.y > 0:
		go_to_dashed_fall_state()
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

func dashed_fall_state():
	velocity.x = move_toward(velocity.x, 0, DASH_AIR_FRICTION * get_physics_process_delta_time())
	
	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
		return
	
	if abs(velocity.x) < SPEED:
		go_to_fall_state()
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
		curr_direction = Vector2.RIGHT;
	elif direction < 0:
		anim.flip_h = true
		curr_direction = Vector2.LEFT;

func move_until_stopped():
	# Used when player can't move
	# Apply current velocity until zero
	velocity.x = move_toward(velocity.x, 0, SPEED)
	
func apply_air_inertia(delta: float):
	velocity.x = move_toward(velocity.x, 0, DASH_AIR_FRICTION * delta)

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
