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

@onready var point_light_2d: PointLight2D = $PointLight2D

@onready var area_2d: StaticBody2D = $"../../Doors/Door"

@onready var sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var audio_stream_player_2d_2: AudioStreamPlayer2D = $AudioStreamPlayer2D2

@export var drop_distance := 32.0


var is_sound_play:bool=false

func play_sound(path: String):
	sfx.stream = load(path)
	sfx.play()


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
	
	if Input.is_action_just_pressed("ui_accept"):
		if area_2d.is_open:
			area_2d.close_door()
		else:
			area_2d.open_door()  # Llama a la función de apertura de la puerta
	
	if Input.is_action_just_pressed("drop"):
		_drop_selected()
	if Input.is_action_just_pressed("use_item"):
		_use_selected()

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
	if dir!=Vector2.ZERO:
		if !is_sound_play:
			play_sound("res://stepwood.wav")
			is_sound_play=true
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

func _drop_selected():
	var inv: Node = get_tree().get_first_node_in_group("inventory")
	if inv == null:
		return
	var item_scene: PackedScene = inv.consume_selected_item()
	if item_scene:
		var dropped := item_scene.instantiate()
		# Asegurate que en tu escena principal exista un nodo "Items"
		get_parent().get_parent().get_node("Items").add_child(dropped)
		audio_stream_player_2d_2.play()
		if rotation_degrees>-135 and rotation_degrees<-45:
			dropped.global_position = global_position + Vector2.UP * drop_distance
		if rotation_degrees<135 and rotation_degrees>45:
			dropped.global_position = global_position + Vector2.DOWN * drop_distance
		if rotation_degrees<-135 or rotation_degrees>135:
			dropped.global_position = global_position + Vector2.LEFT * drop_distance
		if rotation_degrees>-45 and rotation_degrees<45:
			dropped.global_position = global_position + Vector2.RIGHT * drop_distance

func _use_selected():
	var inv: Node = get_tree().get_first_node_in_group("inventory")
	if inv == null:
		return
	var item_scene: PackedScene = inv.get_selected_item()
	if item_scene == null:
		return


func _on_audio_stream_player_2d_finished() -> void:
	is_sound_play=false
