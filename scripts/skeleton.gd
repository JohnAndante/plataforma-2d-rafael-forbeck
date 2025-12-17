extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var wall_detector_01: RayCast2D = $WallDetector01
@onready var wall_detector_02: RayCast2D = $WallDetector02
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var turn_timer: Timer = $TurnTimer

const SPEED = 10 * 100
const JUMP_VELOCITY = -400.0
var will_turn := false

enum SkeletonState {
	walk,
	dead,
	idle,
}

var curr_status: SkeletonState
var curr_direction := Vector2.RIGHT

func _ready() -> void:
	turn_timer.start()
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	match curr_status:
		SkeletonState.walk:
			walk_state(delta)
		SkeletonState.dead:
			dead_state(delta)
		SkeletonState.idle:
			idle_state(delta)
	
	move_and_slide()

func go_to_walk_state():
	curr_status = SkeletonState.walk
	anim.play("walk")

func go_to_dead_state():
	curr_status = SkeletonState.dead
	anim.play("dead")
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	velocity.x = 0

func go_to_idle_state():
	velocity.x = 0
	curr_status = SkeletonState.idle
	anim.play("idle")

func walk_state(delta: float):
	var direction := curr_direction.x
	velocity.x = SPEED * direction * delta
	
	if must_turn():
		update_raycasts()
		if must_turn():
			will_turn = true
			turn_timer.start()
			go_to_idle_state()
		

func dead_state(_delta: float):
	pass
	
func idle_state(_delta: float):
	pass

func take_damage():
	go_to_dead_state()

func turn_around():
	curr_direction.x *= -1
	scale.x *= -1

func must_turn() -> bool:
	return wall_detector_01.is_colliding() || wall_detector_02.is_colliding() || !ground_detector.is_colliding()
	
func update_raycasts():
	wall_detector_01.force_raycast_update()
	wall_detector_02.force_raycast_update()
	ground_detector.force_raycast_update()

func _on_timer_timeout() -> void:
	if curr_status == SkeletonState.idle:
		if will_turn:
			turn_around()
			will_turn = false
		go_to_walk_state()
