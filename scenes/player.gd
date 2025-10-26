extends CharacterBody2D

const SPEED = 120.0
const FOLLOW_SPEED = 120.0
const FOLLOW_DISTANCE = 50.0

@onready var interaction_area = $InteractionArea

var is_active = false
var is_following = false
var follow_target: CharacterBody2D = null

var can_interact = false
var nearby_character: CharacterBody2D = null

# Variables para correr
const RUN_SPEED = 240.0
const RUN_DURATION = 3.0
const RUN_COOLDOWN = 3.0

var is_running = false
var run_time_left = 0.0
var cooldown_time_left = 0.0


@onready var color_rect: ColorRect = $"../../CanvasLayer/ColorRect"
func _ready():
	if name == "Player":
		is_active = true

func _physics_process(delta):
	handle_run_timers(delta)
	
	if is_active:
		handle_movement()
	elif is_following and follow_target:
		handle_follow(delta)
	move_and_slide()

func handle_movement():
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1
		rotation_degrees = -90
	if Input.is_action_pressed("ui_down"):
		dir.y += 1
		rotation_degrees = 90
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
		rotation_degrees = 180
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
		rotation_degrees = 0
	if Input.is_action_pressed("ui_up") and Input.is_action_pressed("ui_left"):
		rotation_degrees = -135
	if Input.is_action_pressed("ui_up") and Input.is_action_pressed("ui_right"):
		rotation_degrees = -45
	if Input.is_action_pressed("ui_down") and Input.is_action_pressed("ui_left"):
		rotation_degrees = 135
	if Input.is_action_pressed("ui_down") and Input.is_action_pressed("ui_right"):
		rotation_degrees = 45
	dir = dir.normalized()
	
	var current_speed = SPEED
	if is_running:
		current_speed = RUN_SPEED
	
	velocity = dir * current_speed

func handle_follow(delta):
	# Detectar input para correr también cuando sigue
	if is_following and is_active == false:
		if Input.is_action_pressed("run") and cooldown_time_left <= 0 and not is_running:
			start_running()
	
	var dist = global_position.distance_to(follow_target.global_position)
	if dist > FOLLOW_DISTANCE:
		var dir = (follow_target.global_position - global_position).normalized()
		
		var current_speed = FOLLOW_SPEED
		if is_running:
			current_speed = RUN_SPEED
		
		velocity = dir * current_speed
		rotation = dir.angle()
	else:
		velocity = velocity.lerp(Vector2.ZERO, 0.1)

func handle_run_timers(delta):
	if is_running:
		run_time_left -= delta
		if run_time_left <= 0:
			is_running = false
			cooldown_time_left = RUN_COOLDOWN
	elif cooldown_time_left > 0:
		cooldown_time_left -= delta

func _input(event):
	# Solo el personaje activo maneja input para correr
	if is_active:
		if event.is_action_pressed("run") and cooldown_time_left <= 0 and not is_running:
			start_running()

func start_running():
	is_running = true
	run_time_left = RUN_DURATION

func set_active(active: bool):
	is_active = active
	modulate.a = 1.0 if active else 0.7

func set_following(following: bool, target: CharacterBody2D):
	is_following = following
	follow_target = target

func _on_interaction_area_body_entered(body):
	if body.is_in_group("characters") and body != self:
		nearby_character = body
		can_interact = true

func _on_interaction_area_body_exited(body):
	if body == nearby_character:
		nearby_character = null
		can_interact = false
