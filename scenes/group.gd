extends Node2D
# group.gd


# Referencias
@export var characters: Array[CharacterBody2D] = []
@export var selection_color := Color(1.0, 1.0, 0.0, 0.5)
@export var normal_color := Color(1.0, 1.0, 1.0, 1.0)
@export var group_spacing := 50.0
@export var move_speed := 200.0
@export var double_click_time := 0.3

# Variables de selección
var selected_chars: Array[CharacterBody2D] = []
var last_click_time := 0.0
var click_count := 0

# Variables de navegación
var nav_region: NavigationRegion2D

func _ready():
	# Buscar NavigationRegion2D en la escena
	nav_region = get_tree().get_first_node_in_group("navigation")
	
	# Configurar señales para cada personaje
	for char in characters:
		if char.has_signal("input_event"):
			char.input_event.connect(_on_character_clicked.bind(char))
		else:
			# Si no tiene Area2D, agregar detección manual
			char.set_meta("clickable", true)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Detectar click en el mapa para mover
		if selected_chars.size() > 0:
			var target_pos = get_global_mouse_position()
			move_selected_to(target_pos)

func _on_character_clicked(viewport, event, shape_idx, char: CharacterBody2D):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var current_time = Time.get_ticks_msec() / 1000.0
		print("pasas")
		# Detectar doble click
		if current_time - last_click_time < double_click_time:
			click_count += 1
			if click_count >= 2:
				select_all_characters()
				click_count = 0
		else:
			click_count = 1
			select_single_character(char)
		
		last_click_time = current_time

func select_single_character(char: CharacterBody2D):
	# Deseleccionar todos
	for c in selected_chars:
		c.modulate = normal_color
	
	selected_chars.clear()
	
	# Seleccionar uno
	selected_chars.append(char)
	char.modulate = selection_color

func select_all_characters():
	selected_chars.clear()
	
	for char in characters:
		selected_chars.append(char)
		char.modulate = selection_color

func move_selected_to(target_pos: Vector2):
	if selected_chars.size() == 1:
		# Movimiento individual
		move_character(selected_chars[0], target_pos)
	else:
		# Movimiento en grupo con formación
		move_group_formation(target_pos)

func move_character(char: CharacterBody2D, target: Vector2):
	if nav_region == null:
		# Movimiento directo sin pathfinding
		char.set_meta("target_pos", target)
	else:
		# Usar NavigationAgent2D si existe
		var nav_agent = char.get_node_or_null("NavigationAgent2D")
		if nav_agent:
			nav_agent.target_position = target

func move_group_formation(center_target: Vector2):
	var num_chars = selected_chars.size()
	
	# Calcular posiciones en formación circular
	var angle_step = TAU / num_chars
	var positions = []
	
	for i in range(num_chars):
		var angle = angle_step * i
		var offset = Vector2(cos(angle), sin(angle)) * group_spacing
		var target_pos = center_target + offset
		positions.append(target_pos)
	
	# Asignar posiciones a cada personaje
	for i in range(num_chars):
		move_character(selected_chars[i], positions[i])

func _process(delta):
	# Mover personajes hacia sus objetivos
	for char in selected_chars:
		if char.has_meta("target_pos"):
			var target = char.get_meta("target_pos")
			var direction = (target - char.global_position).normalized()
			var distance = char.global_position.distance_to(target)
			
			if distance > 5.0:
				char.velocity = direction * move_speed
				char.move_and_slide()
			else:
				char.velocity = Vector2.ZERO
				char.remove_meta("target_pos")
