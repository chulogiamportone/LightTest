extends Node

@onready var characters: Array[CharacterBody2D] = []

@onready var camera: Camera = $"../Camera"


var active_char: CharacterBody2D = null
var follower_char: CharacterBody2D = null

func _ready():
	# Recopilar personajes hijos
	for child in get_children():
		if child.is_in_group("characters"):
			characters.append(child)
	
	if characters.size() > 0:
		set_active_character(characters[0])

func _input(event):
	if event.is_action_pressed("follow"):  # E para interactuar
		if active_char and active_char.can_interact and active_char.nearby_character:
			var target = active_char.nearby_character
			if follower_char == target:
				# Si ya sigue, dejar de seguir
				stop_following()
			else:
				# Nuevo seguidor: si hay otro, dejarlo
				if follower_char:
					follower_char.set_following(false, null)
				start_following(target)
	
	if event.is_action_pressed("switch_character"):  # C para cambiar personaje
		if active_char and active_char.can_interact and active_char.nearby_character:
			switch_to_character(active_char.nearby_character)

	if event.is_action_pressed("toggle_follow"):  # F para que el seguidor deje de seguir
		stop_following()

	if event.is_action_pressed("swap_follow"):  # G para intercambiar líder y seguidor
		swap_leader_follower()

func set_active_character(character: CharacterBody2D):
	if active_char:
		active_char.set_active(false)
	active_char = character
	active_char.set_active(true)
	camera.set_follow_target(active_char)
	
func start_following(character: CharacterBody2D):
	follower_char = character
	follower_char.set_following(true, active_char)
	#print("Personaje ", follower_char.name, " ahora sigue a ", active_char.name)

func stop_following():
	if follower_char:
		follower_char.set_following(false, null)
		#print("Personaje ", follower_char.name, " dejó de seguir")
		follower_char = null

func switch_to_character(character: CharacterBody2D):
	if character == active_char:
		return
	# Solo cambiar si está cerca
	var dist = active_char.global_position.distance_to(character.global_position)
	if dist > 150:
		#print("Personajes muy lejos para cambiar")
		return
	
	set_active_character(character)
	
	# Si el seguidor es el nuevo activo, actualizar
	if follower_char == character:
		follower_char = null

func swap_leader_follower():
	if not follower_char:
		#print("No hay seguidor para intercambiar")
		return
	
	# Intercambiar roles
	var old_leader = active_char
	var old_follower = follower_char
	
	stop_following()
	set_active_character(old_follower)
	start_following(old_leader)
	#print("Intercambiados líder y seguidor")
