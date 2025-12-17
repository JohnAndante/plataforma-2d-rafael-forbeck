extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var reload_timer: Timer = $ReloadTimer

@export var MAX_SPEED = 80.0
const JUMP_VELOCITY = -300.0
@export var ACCELERATION = 4.5 * 1000
@export var DECELERATION = 3.5 * 1000
const DASH_MAX_SPEED = 200
const DASH_AIR_FRICTION = 200
const DASH_DURATION_SECONDS = 1
@export var MAX_JUMP_COUNTS = 2

enum PlayerState {
	idle,
	walk,
	jump,
	fall,
	duck,
	dash,
	dashed_jump,
	dashed_fall,
	dead,
}

var curr_state: PlayerState
var curr_direction: Vector2 = Vector2.RIGHT;
var dash_timer
var jump_count := 0

func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta:float) -> void:
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	match curr_state:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.fall:
			fall_state(delta)
		PlayerState.duck:
			duck_state(delta)
		PlayerState.dash:
			dash_state(delta)
		PlayerState.dashed_jump:
			dashed_jump_state(delta)
		PlayerState.dashed_fall:
			dashed_fall_state(delta)
		PlayerState.dead:
			dead_state(delta)
	move_and_slide()

func go_to_idle_state():
	curr_state = PlayerState.idle
	anim.play("idle")

func go_to_duck_state():
	curr_state = PlayerState.duck
	anim.play("duck")
	
	set_lower_collision()

func exit_from_duck_state():
	set_regular_collision()

func go_to_walk_state():
	curr_state = PlayerState.walk
	anim.play("walk")

func go_to_dash_state():
	curr_state = PlayerState.dash
	anim.play("dash")
	
	var dash_direction = curr_direction.x
	velocity.x = dash_direction * DASH_MAX_SPEED
	
	dash_timer = DASH_DURATION_SECONDS
	
	set_lower_collision()

func exit_from_dash_state(): 
	set_regular_collision()

func go_to_jump_state():
	curr_state = PlayerState.jump
	anim.play("jump")
	velocity.y = JUMP_VELOCITY
	jump_count += 1

func go_to_dashed_jump_state():
	curr_state = PlayerState.dashed_jump
	anim.play("jump")
	velocity.y = JUMP_VELOCITY * 1.1

func go_to_fall_state():
	if velocity.y < 0:
		velocity.y = move_toward(velocity.y, 0, MAX_SPEED)
		
	curr_state = PlayerState.fall
	anim.play("falling")

func go_to_dashed_fall_state():
	curr_state = PlayerState.dashed_fall
	anim.play("falling")

func go_to_dead_state():
	curr_state = PlayerState.dead
	anim.play("dead")
	velocity = Vector2.ZERO
	reload_timer.start()

func idle_state(delta: float):
	move(delta)
		
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

func duck_state(_delta: float):
	move_until_stopped()
	
	if Input.is_action_just_released("down"):
		exit_from_duck_state()
		go_to_idle_state()
		return

func walk_state(delta: float):
	move(delta)
	
	if velocity.x == 0:
		go_to_idle_state()
		return
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
	if !is_on_floor():
		jump_count += 1
		go_to_fall_state()
		return
	if Input.is_action_just_pressed("down"):
		go_to_duck_state()
		return
	if Input.is_action_just_pressed("dash"):
		go_to_dash_state()
		return

func dash_state(delta: float):
	dash_timer -= delta
	move(delta)
	
	if !is_on_floor() && Input.is_action_just_pressed("jump"):
		jump_count -= 1
		if can_double_jump():
			go_to_jump_state()
			return
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		exit_from_dash_state()
		go_to_dashed_jump_state()
		return
	
	if Input.is_action_just_released("dash") or dash_timer <= 0:
		exit_from_dash_state()
		
		if is_on_floor():
			go_to_idle_state()
		else:
			go_to_fall_state()
		return

func jump_state(delta: float):
	move(delta)
	
	if velocity.y < 0 && Input.is_action_just_released("jump"):
		go_to_fall_state()
		return
	if velocity.y > 0:
		go_to_fall_state()
		return
		
	if velocity.y != 0 || !is_on_floor():
		return
		
	if velocity.x == 0:
		if Input.is_action_pressed("down"):
			go_to_duck_state()
		else:
			go_to_idle_state()
		return
	if velocity.x != 0:
		go_to_walk_state()
		return

func dashed_jump_state(delta: float):
	move(delta)
	
	if velocity.y < 0 and Input.is_action_just_released("jump"):
		go_to_dashed_fall_state()
		return
	if velocity.y > 0:
		go_to_dashed_fall_state()
		return

func fall_state(delta: float):
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_double_jump():
		go_to_jump_state()
		return
	
	if velocity.y != 0:
		return 
	if !is_on_floor():
		return
		
	jump_count = 0
	
	if velocity.x == 0:
		go_to_idle_state()
		return
	if velocity.x != 0:
		go_to_walk_state()
		return

func dashed_fall_state(delta: float):
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_double_jump():
		go_to_jump_state()
		return
	
	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
		return
	if abs(velocity.x) < MAX_SPEED:
		go_to_fall_state()
		return

func dead_state(_delta):
	pass

func move(delta: float):
	update_direction()
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	
	if PlayerState.dash:
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, DASH_AIR_FRICTION * delta)
		return
	
	if PlayerState.dashed_fall || PlayerState.dashed_jump:
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, DASH_AIR_FRICTION * delta)
		#velocity.x = direction * MAX_SPEED
		return
	
	if direction:
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)

func update_direction():
	var direction := Input.get_axis("left", "right")
	
	# Change sprite flip based on direction
	# Its elif insted of else to not force a single direction when 0
	if direction > 0:
		anim.flip_h = false
		curr_direction = Vector2.RIGHT;
	elif direction < 0:
		anim.flip_h = true
		curr_direction = Vector2.LEFT;

func move_until_stopped():
	update_direction()
	
	# Used when player can't move
	# Apply current velocity until zero
	velocity.x = move_toward(velocity.x, 0, MAX_SPEED)

func set_lower_collision():
	collision_shape.shape.radius = 2.84
	collision_shape.shape.height = 5.68
	collision_shape.position.y = 3

func set_regular_collision():
	collision_shape.shape.radius = 2.84
	collision_shape.shape.height = 9.09
	collision_shape.position.y = 0	

func can_double_jump() -> bool:
	return jump_count < MAX_JUMP_COUNTS

func _on_hitbox_area_entered(area: Area2D) -> void:
	if curr_state == PlayerState.dead:
		return
		
	if velocity.y > 0:
		area.get_parent().take_damage()
		jump_count -= 1
		go_to_jump_state()
	else:
		go_to_dead_state()

func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()
