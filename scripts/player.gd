extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var reload_timer: Timer = $ReloadTimer
@onready var left_wall_detector_1: RayCast2D = $WallDetectors/LeftWallDetector1
@onready var left_wall_detector_2: RayCast2D = $WallDetectors/LeftWallDetector2
@onready var right_wall_detector_1: RayCast2D = $WallDetectors/RightWallDetector1
@onready var right_wall_detector_2: RayCast2D = $WallDetectors/RightWallDetector2

@export var MAX_SPEED = 80.0
const JUMP_VELOCITY = -300.0
@export var ACCELERATION = 4.5 * 1000
@export var DECELERATION = 3.5 * 1000
const DASH_MAX_SPEED = 200
const DASH_AIR_FRICTION = 200
const DASH_DURATION_SECONDS = 1
@export var MAX_JUMP_COUNTS = 2
@export var WALL_SLIDE_GRIP_PERC := 60 * 0.01
@export var WALL_JUMP_VELOCITY := 600.0

enum PlayerState {
	idle,
	walk,
	jump,
	fall,
	duck,
	dash,
	dashed_jump,
	dashed_fall,
	wall_slide,
	wall_dash,
	swimming,
	dead,
}

var curr_state: PlayerState
var curr_direction: Vector2 = Vector2.RIGHT;
var dash_timer
var jump_count := 0

func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:
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
		PlayerState.wall_slide:
			wall_slide_state(delta)
		PlayerState.wall_dash:
			wall_dash_state(delta)
		PlayerState.swimming:
			swimming_state(delta)
		PlayerState.dead:
			dead_state(delta)
	
	move_and_slide()
	
	if is_on_floor():
		jump_count = 0

func go_to_idle_state():
	curr_state = PlayerState.idle
	anim.play("idle")

func go_to_duck_state():
	curr_state = PlayerState.duck
	anim.play("duck")
	
	set_lower_collision()
	set_lower_hitbox()

func exit_from_duck_state():
	set_regular_collision()
	set_regular_hitbox()

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
	jump_count += 1

func go_to_fall_state():
	if velocity.y < 0:
		velocity.y = move_toward(velocity.y, 0, MAX_SPEED)
		
	curr_state = PlayerState.fall
	anim.play("falling")

func go_to_dashed_fall_state():
	curr_state = PlayerState.dashed_fall
	anim.play("falling")

func go_to_wall_slide_state():
	curr_state = PlayerState.wall_slide
	anim.play("wall_slide")
	jump_count = 0

func go_to_wall_jump_state():
	var direction = -1 if is_right_wall_colliding() else 1
	velocity.y = JUMP_VELOCITY
	velocity.x = direction * WALL_JUMP_VELOCITY
	
	anim.flip_h = (direction == -1)
	curr_direction.x = direction
	
	jump_count = 1
	curr_state = PlayerState.jump
	anim.play("jump")

func go_to_wall_dash_state():
	curr_state = PlayerState.wall_dash
	anim.play("jump")
	
	velocity.y = JUMP_VELOCITY * WALL_SLIDE_GRIP_PERC
	velocity.x = 0
	
	dash_timer = 0.3

func go_to_swimming_state():
	curr_state = PlayerState.swimming
	anim.play("swimming")

func go_to_dead_state():
	if curr_state == PlayerState.dead:
		return
	
	curr_state = PlayerState.dead
	anim.play("dead")
	velocity = Vector2.ZERO
	reload_timer.start()

func idle_state(delta: float):
	apply_gravity(delta)
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

func duck_state(delta: float):
	apply_gravity(delta)
	move_until_stopped()
	
	if Input.is_action_just_released("down"):
		exit_from_duck_state()
		go_to_idle_state()
		return

func walk_state(delta: float):
	apply_gravity(delta)
	move(delta)
	
	if velocity.x == 0:
		go_to_idle_state()
		return
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
	if !is_on_floor():
		jump_count = 1
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
	apply_gravity(delta)
	move(delta)
		
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			exit_from_dash_state()
			go_to_dashed_jump_state()
			return
		elif can_double_jump():
			exit_from_dash_state()
			go_to_jump_state()
			return
	
	if Input.is_action_just_released("dash") or dash_timer <= 0:
		exit_from_dash_state()
		
		if is_on_floor():
			go_to_idle_state()
		else:
			go_to_fall_state()
		return

func jump_state(delta: float):
	apply_gravity(delta)
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
	apply_gravity(delta)
	move(delta)
	
	if velocity.y < 0 and Input.is_action_just_released("jump"):
		go_to_dashed_fall_state()
		return
	if velocity.y > 0:
		go_to_dashed_fall_state()
		return

func fall_state(delta: float):
	apply_gravity(delta)
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_double_jump():
		go_to_jump_state()
		return
		
	var direction := Input.get_axis("left", "right")
		
	if is_left_wall_colliding() and direction < 0: 
		go_to_wall_slide_state()
	elif is_right_wall_colliding() and direction > 0:
		go_to_wall_slide_state()
	
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
	apply_gravity(delta)
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

func wall_slide_state(delta: float):
	apply_gravity(delta)
	
	if is_left_wall_colliding():
		anim.flip_h = false
	elif is_right_wall_colliding():
		anim.flip_h = true
	
	if is_on_floor():
		go_to_idle_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		go_to_wall_jump_state()
		return
	
	if Input.is_action_just_pressed("dash"):
		go_to_wall_dash_state()
		return
	
	if Input.is_action_pressed("down"):
		go_to_fall_state()
		return
	
	if !is_left_wall_colliding() and !is_right_wall_colliding():
		go_to_fall_state()
		return

func wall_jump_state():
	pass

func wall_dash_state(delta: float):
	dash_timer -= delta
	
	# Manter o personagem colado na parede durante a subida
	# Isso evita que ele pare de subir se você soltar o analógico
	velocity.x = 0 
	
	if Input.is_action_just_pressed("jump"):
		go_to_wall_jump_state()
		return

	if dash_timer <= 0 or velocity.y >= 0:
		if is_left_wall_colliding() or is_right_wall_colliding():
			go_to_wall_slide_state()
		else:
			go_to_fall_state()
		return
		
	if is_on_ceiling():
		go_to_fall_state()

func swimming_state(_delta: float):
	pass

func dead_state(delta):
	apply_gravity(delta)

func move(delta: float):
	
	if curr_state == PlayerState.wall_slide or curr_state == PlayerState.wall_dash:
		velocity.x = 0
		return
	
	update_direction()
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	
	if curr_state == PlayerState.dash:
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, DASH_AIR_FRICTION * delta)
		return
	
	if curr_state == PlayerState.dashed_fall || curr_state == PlayerState.dashed_jump:
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, DASH_AIR_FRICTION * delta)
		return
	
	if direction:
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)

func apply_gravity(delta: float):
	if not is_on_floor():
		if curr_state == PlayerState.wall_slide:
			velocity += get_gravity() * wall_min_slide_angle * delta 
			velocity.y = min(velocity.y, MAX_SPEED * 0.8) 
		else:
			velocity += get_gravity() * delta

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
	velocity.x = move_toward(velocity.x, 0, MAX_SPEED)

func set_lower_collision():
	collision_shape.shape.radius = 2.84
	collision_shape.shape.height = 5.68
	collision_shape.position.y = 3

func set_lower_hitbox():
	hitbox_collision_shape.shape.size.y = 11
	hitbox_collision_shape.position.y = 2.5

func set_regular_collision():
	collision_shape.shape.radius = 2.84
	collision_shape.shape.height = 8.4
	collision_shape.position.y = 0.6

func set_regular_hitbox():
	hitbox_collision_shape.shape.size.y = 16
	hitbox_collision_shape.position.y = 0

func can_double_jump() -> bool:
	return jump_count < MAX_JUMP_COUNTS

func hit_enemy(area: Area2D):
	if velocity.y > 0:
		area.get_parent().take_damage()
		jump_count = 0
		go_to_jump_state()
	else:
		go_to_dead_state()

func hit_lethal_area():
	go_to_dead_state()
	
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		hit_enemy(area)
		return
	
	if area.is_in_group("LethalArea"):
		hit_lethal_area()
		return

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("LethalArea"):
		go_to_dead_state()
		return
		
	if body.is_in_group("Water"):
		go_to_swimming_state()
		return

func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()

func is_left_wall_colliding() -> bool:
	return left_wall_detector_1.is_colliding() and left_wall_detector_2.is_colliding() and is_on_wall()

func is_right_wall_colliding() -> bool:
	return right_wall_detector_1.is_colliding() and right_wall_detector_2.is_colliding() and is_on_wall()
