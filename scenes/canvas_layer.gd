extends CanvasLayer

@onready var darkness_rect = $ColorRect
@onready var light_viewport = $SubViewport
@onready var light_canvas = $SubViewport/Node2D

var light_circles = {}
var main_camera: Camera2D = null

func _ready():
	# Configurar viewport
	light_viewport.size = get_viewport().size
	light_viewport.transparent_bg = true
	light_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	# Configurar shader
	var shader_material = ShaderMaterial.new()
	shader_material.shader = preload("uid://b8ymci7aycqp3")
	darkness_rect.material = shader_material
	
	await get_tree().process_frame
	shader_material.set_shader_parameter("light_texture", light_viewport.get_texture())
	
	# Buscar la cámara en toda la escena
	main_camera = find_camera_recursive(get_tree().root)

func find_camera_recursive(node: Node) -> Camera2D:
	if node is Camera2D and node.enabled:
		return node
	for child in node.get_children():
		var result = find_camera_recursive(child)
		if result:
			return result
	return null

func _process(_delta):
	# Sincronizar la posición del canvas con la cámara
	if not main_camera or not is_instance_valid(main_camera):
		main_camera = get_viewport().get_camera_2d()
	
	if main_camera:
		light_canvas.global_position = -main_camera.get_screen_center_position() + get_viewport().size / 2.0
	
	# Actualizar posiciones de las luces
	for area in light_circles:
		if is_instance_valid(area):
			var light_sprite = light_circles[area]
			light_sprite.global_position = area.global_position

func add_light_area(area: Area2D):
	var radius = 100.0
	
	for child in area.get_children():
		if child is CollisionShape2D and child.shape is CircleShape2D:
			radius = child.shape.radius
			break
	
	# Crear sprite circular con gradiente
	var light = Sprite2D.new()
	light.texture = create_circle_gradient(int(radius * 2))
	light.centered = true
	light.global_position = area.global_position
	
	light_canvas.add_child(light)
	light_circles[area] = light

func remove_light_area(area: Area2D):
	if area in light_circles:
		light_circles[area].queue_free()
		light_circles.erase(area)

func create_circle_gradient(size: int) -> ImageTexture:
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = size / 2.0
	
	for x in range(size):
		for y in range(size):
			var dx = x - center
			var dy = y - center
			var dist = sqrt(dx * dx + dy * dy)
			var normalized_dist = dist / center
			var alpha = clamp(1.0 - normalized_dist, 0.0, 1.0)
			alpha = pow(alpha, 0.5)
			img.set_pixel(x, y, Color(alpha, alpha, alpha, 1.0))
	
	return ImageTexture.create_from_image(img)
