extends Node

const MAX_HOLES := 16

@export var camera_node: Camera2D
@export var color_rect: ColorRect
@export var mask_viewport: Viewport
@export var hole_nodes: Array[NodePath] = [] # arrastrar Player y PointLight2D paths en el inspector
@export var default_radius_px: float = 100.0
@export var rays_per_light: int = 96
@export var update_static_every_n_frames: int = 1 # si tenes luces estáticas, podés bajar frecuencia

var _frame_counter: int = 0
var _poly_pool: Array = [] # para reusar Polygon2D nodes

func _ready() -> void:
	# init pool vacio
	_poly_pool.clear()

	# Asegurate que viewport size coincide con ventana
	_sync_viewport_size()
	
	
	debug_mask_status()
	debug_create_test_mask()
	
	
func _process(delta: float) -> void:
	
	if not camera_node or not color_rect or not mask_viewport:
		return

	_frame_counter += 1
	_sync_viewport_size()

	# actualizar máscara (podés optimizar actualizando solo luces moviles)
	_update_mask()

	# pasar la textura del viewport al shader
	var mat := color_rect.material
	if mat:
		mat.set_shader_parameter("light_mask", mask_viewport.get_texture())
		mat.set_shader_parameter("mask_size", mask_viewport.get_texture().get_size())


	
func _sync_viewport_size() -> void:
	# Get viewport size as Vector2 (floats) for shader and conversions
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	# Convert to Vector2i to compare/assign to mask_viewport.size (which is Vector2i)
	var vp_size_i: Vector2i = Vector2i(vp_size)

	# Only update mask_viewport.size if different
	if mask_viewport.size != vp_size_i:
		mask_viewport.size = vp_size_i

	# Also store vp_size (Vector2) in a field or pass it to shader where needed
	# e.g. if you keep vp_size in a variable, return it or set a member var

func _update_mask() -> void:
	var mask_root := mask_viewport.get_node_or_null("mask_root") as Node2D
	if not mask_root:
		print("DEBUG: mask_root NULL en _update_mask")
		return

	var needed := hole_nodes.size()
	# crear pool si hace falta
	while _poly_pool.size() < needed:
		var p := Polygon2D.new()
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# asegurar que la posición local es (0,0)
		p.position = Vector2.ZERO
		p.color = Color(1,1,1,1)
		_poly_pool.append(p)
		mask_root.add_child(p)

	# ocultar / limpiar no usados
	for i in range(_poly_pool.size()):
		_poly_pool[i].polygon = PackedVector2Array()
		_poly_pool[i].visible = i < needed

	var vp_size = mask_viewport.size

	for i in range(needed):
		var path := hole_nodes[i]
		if not has_node(path):
			continue
		var node := get_node(path)
		if not node:
			continue

		var world_pos = node.global_position
		var radius_px := default_radius_px
		if node.has_meta("hole_radius"):
			radius_px = float(node.get_meta("hole_radius"))

		# calcular polígono
		var poly_pts := compute_light_polygon(world_pos, radius_px, rays_per_light, camera_node, vp_size)

		# convertir puntos a coordenadas LOCALES de mask_root (en caso mask_root tenga offset)
		var local_pts := PackedVector2Array()
		var root_global_pos := mask_root.global_position
		for pt in poly_pts:
			# pt está en coordenadas de viewport (píxeles desde 0,0). Si mask_root está en 0,0 queda igual.
			# Si no, restamos la posición global del root.
			local_pts.append(pt - root_global_pos)

		var poly2d = _poly_pool[i]
		poly2d.polygon = local_pts
		poly2d.color = Color(1, 1, 1, 1)
		poly2d.visible = true

	# debug info simple
	# print cantidad poligonos y puntos del primero
	if _poly_pool.size() > 0:
		var p0 = _poly_pool[0]
		print("DEBUG: _update_mask -> pool_size:", _poly_pool.size(), " first poly points:", p0.polygon.size())

func compute_light_polygon(world_pos: Vector2, radius_px: float, segments: int, cam: Camera2D, vp_size: Vector2) -> PackedVector2Array:
	var world: World2D = get_viewport().get_world_2d()
	var space: PhysicsDirectSpaceState2D = world.direct_space_state

	var pts: PackedVector2Array = PackedVector2Array()

	# convertir px a unidades world (teniendo en cuenta zoom)
	var radius_world: float = radius_px / cam.zoom.x

	# opción: si querés que los rayos usen todas las capas, pon -1 o (1<<31)-1; mejor limitar a la capa del TileMap
	var collision_mask: int = -1

	# debug counters
	var hits := 0

	for j in range(segments):
		var ang: float = float(j) * TAU / float(segments)
		var dir: Vector2 = Vector2(cos(ang), sin(ang))
		var from: Vector2 = world_pos
		var to: Vector2 = world_pos + dir * radius_world

		var params := PhysicsRayQueryParameters2D.new()
		params.from = from
		params.to = to
		params.exclude = [] # podés agregar la luz misma si tiene cuerpo físico
		params.collide_with_bodies = true
		params.collide_with_areas = true
		params.collision_mask = collision_mask

		var res: Dictionary = space.intersect_ray(params)

		var hit_point: Vector2
		if res and res.has("position"):
			hit_point = res["position"]
			hits += 1
		else:
			hit_point = to

		# convertir world -> viewport px (misma lógica que usás en otros scripts)
		var rel: Vector2 = hit_point - cam.global_position
		if cam.rotation != 0.0:
			rel = rel.rotated(-cam.rotation)
		rel = rel * cam.zoom
		var screen_px: Vector2 = rel + vp_size * 0.5

		pts.append(screen_px)

		# debug print de los primeros rays
		if j < 6:
			print("ray ", j, " from:", from, " to:", to, " hit:", hit_point, " screen_px:", screen_px, " hit? ", res.size() > 0)

	# imprime resumen
	print("DEBUG compute_light_polygon: world_pos:", world_pos, " radius_px:", radius_px, " rays:", segments, " hits:", hits)

	return pts



@onready var mask_root: Node2D = $LightMaskViewport/mask_root

func debug_mask_status() -> void:
	
	print("mask_root class:", mask_root.get_class())
	
	mask_viewport.transparent_bg = true
	mask_viewport.render_target_update_mode = 3
	
	# Basic checks
	if not mask_viewport:
		print("DEBUG: mask_viewport is NULL")
		return

	# Ensure viewport update mode and transparency (en tiempo de ejecución)
	

	# Sizes
	var vp_size_vec2: Vector2 = get_viewport().get_visible_rect().size
	var vp_size_i: Vector2i = Vector2i(vp_size_vec2)
	print("DEBUG: main viewport size (Vector2): ", vp_size_vec2)
	print("DEBUG: mask_viewport.size (Vector2i): ", mask_viewport.size, " converted: ", vp_size_i)

	# Texture
	var tex := mask_viewport.get_texture()
	if tex:
		print("DEBUG: mask texture available. size: ", tex.get_size(), " (Vector2i)")
	else:
		print("DEBUG: mask texture is NULL")

	# mask_root and polygons
	var mask_root := mask_viewport.get_node_or_null("mask_root") as Node2D
	if not mask_root:
		print("DEBUG: mask_root NOT found inside mask_viewport (expected Node2D named 'mask_root')")
		return

	print("DEBUG: mask_root child_count: ", mask_root.get_child_count())

	# show polygon pool info (if using _poly_pool) or direct children
	for i in range(mask_root.get_child_count()):
		var ch := mask_root.get_child(i)
		print("--- child ", i, " class: ", ch.get_class(), " name: ", ch.name, " visible: ", ch.visible)
		if ch is Polygon2D:
			var p := ch as Polygon2D
			print("    polygon points count: ", p.polygon.size())
			if p.polygon.size() > 0:
				print("    first point: ", p.polygon[0])
			print("    color (r,g,b,a): ", p.color.r, p.color.g, p.color.b, p.color.a)

	# show first hole arrays (if exist)
	var mat := color_rect.material
	if mat:
		var hc := 0
		if mat.get_shader_parameter("holes_count"):
			hc = mat.get_shader_parameter("holes_count")
		print("DEBUG: shader holes_count (from material): ", hc)
		if hc > 0 and mat.get_shader_parameter("holes_pos"):
			var pos_arr = mat.get_shader_parameter("holes_pos")
			var rad_arr = mat.get_shader_parameter("holes_radius")
			print("DEBUG: first hole pos (from material): ", pos_arr[0], " radius: ", rad_arr[0])
	# quick visual check: create a debug sprite showing mask texture on screen
	if tex:
		if not has_node("dbg_mask_sprite"):
			var dbg := Sprite2D.new()
			dbg.name = "dbg_mask_sprite"
			dbg.texture = tex
			dbg.position = Vector2(10, 10)
			dbg.scale = Vector2(0.25, 0.25)
			add_child(dbg)
		else:
			var dbg2 := get_node("dbg_mask_sprite") as Sprite2D
			dbg2.texture = tex

	# print a small sample of the texture pixels (optional, may be heavy)
	# var img := tex.get_image()
	# print("DEBUG: sample pixel (0,0): ", img.get_pixel(0,0))




# language: gdscript
func debug_create_test_mask():
	var vp := mask_viewport
	var root := mask_root

	# Clear existing children
	for c in root.get_children():
		c.queue_free()

	# Ensure viewport config
	vp.transparent_bg = true


	# Create a circular polygon centered in viewport
	var size = vp.size
	var center := Vector2(size.x * 0.5, size.y * 0.5)
	var segs = 48
	var radius = min(size.x, size.y) * 0.15

	var pts := PackedVector2Array()
	for i in range(segs):
		var ang := float(i) / float(segs) * TAU
		var p = Vector2(cos(ang), sin(ang)) * radius + center
		pts.append(p)

	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.position = Vector2.ZERO
	poly.color = Color(1, 1, 1, 1) # white -> visible in mask
	root.add_child(poly)

	print("DEBUG: test polygon added. mask_root child_count:", root.get_child_count())
