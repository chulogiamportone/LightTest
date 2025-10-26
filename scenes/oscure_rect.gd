# DarknessController.gd
extends Node

@export var dark_rect_path: NodePath = NodePath("")
@export var hole_nodes: Array[NodePath] = []         # nodos en el mundo (Player, Position2D, etc.)
@export var hole_radii_px: Array[float] = []        # radios en píxeles (mismo orden que hole_nodes)
@export var max_holes: int = 16                     # <= MAX_HOLES en el shader
@export var collect_group_name: String = "light_hole"         # opcional: nombre de grupo para auto-recolección

@onready var cam: Camera = $"../../Camera"


var world_holes_pos: Array[Vector2] = []
var world_holes_radii_px: Array[float] = []

var _shader_mat: ShaderMaterial = null
var _dark_rect: ColorRect = null

func _ready() -> void:
	# 1) Si se asignó en el Inspector, usar la ruta
	if str(dark_rect_path) != "":
		_dark_rect = get_node_or_null(dark_rect_path) as ColorRect

	# 2) Buscar por nombre "DarkRect"
	if _dark_rect == null:
		var found_by_name: Node = get_tree().get_root().find_node("DarkRect", true, false) as Node
		if found_by_name != null and found_by_name is ColorRect:
			_dark_rect = found_by_name as ColorRect

	# 3) Buscar primer ColorRect recursivamente
	if _dark_rect == null:
		_dark_rect = _find_first_colorrect(get_tree().get_root())

	if _dark_rect == null:
		push_error("[Darkness] Dark rect no encontrado. Asigna 'dark_rect_path' o nombra tu ColorRect 'DarkRect'.")
		return

	var mat := _dark_rect.material
	if mat == null or not (mat is ShaderMaterial):
		push_error("[Darkness] El ColorRect debe tener un ShaderMaterial con el shader de agujeros asignado.")
		return

	_shader_mat = mat as ShaderMaterial

	if str(collect_group_name) != "":
		_collect_group_holes(collect_group_name)


func _find_first_colorrect(node: Node) -> ColorRect:
	for child in node.get_children():
		if child is ColorRect:
			return child as ColorRect
		var res: ColorRect = _find_first_colorrect(child)
		if res != null:
			return res
	return null

func _process(_delta: float) -> void:
	
	if _shader_mat == null:
		return

	
	var vp_size: Vector2 = get_viewport().size
	if vp_size.x == 0.0 or vp_size.y == 0.0:
		return
	
	var positions: PackedVector2Array = PackedVector2Array()
	var radii: PackedFloat32Array = PackedFloat32Array()
	var count: int = 0

	# 1) huecos por NodePath (hole_nodes)
	var limit_nodes: int = int(min(hole_nodes.size(), max_holes))
	for idx in range(limit_nodes):
		if count >= max_holes:
			break
		var path: NodePath = hole_nodes[idx] as NodePath
		var node: Node = get_node_or_null(path) as Node
		if node == null:
			continue
		var screen_pos_px: Vector2 = _world_to_screen(node.global_position, cam, vp_size)
		var uv: Vector2 = Vector2(screen_pos_px.x / vp_size.x, screen_pos_px.y / vp_size.y)
		positions.append(uv)

		var radius_px: float = 180.0
		if idx < hole_radii_px.size():
			radius_px = float(hole_radii_px[idx])
		var divisor: float = float(max(vp_size.x, vp_size.y))
		var radius_uv: float = radius_px / divisor
		radii.append(radius_uv)

		count += 1

	# 2) huecos por posición (world_holes_pos)
	var limit_world: int = int(min(world_holes_pos.size(), max_holes - count))
	for i in range(limit_world):
		if count >= max_holes:
			break
		var wpos: Vector2 = world_holes_pos[i]
		var rpx: float = float(world_holes_radii_px[i])
		var screen_pos_px: Vector2 = _world_to_screen(wpos, cam, vp_size)
		var uv2: Vector2 = Vector2(screen_pos_px.x / vp_size.x, screen_pos_px.y / vp_size.y)
		positions.append(uv2)
		var divisor2: float = float(max(vp_size.x, vp_size.y))
		
		var radius_uv2: float = rpx / divisor2
		radii.append(radius_uv2)
		count += 1

	# completar hasta max_holes (el shader espera el array completo)
	while positions.size() < max_holes:
		positions.append(Vector2.ZERO)
		radii.append(0.0)

	_shader_mat.set_shader_parameter("holes_count", count)
	_shader_mat.set_shader_parameter("holes_pos", positions)
	_shader_mat.set_shader_parameter("holes_radius", radii)

# convierte world -> screen en px respetando cam position/rotation/zoom
func _world_to_screen(world_pos: Vector2, cam: Camera2D, vp_size: Vector2) -> Vector2:
	if cam != null:
		var cam_pos: Vector2 = cam.global_position
		var rel: Vector2 = world_pos - cam_pos
		var cam_rot: float = cam.global_rotation
		rel = rel.rotated(-cam_rot)
		rel = Vector2(rel.x * cam.zoom.x, rel.y * cam.zoom.y)
		var screen_center: Vector2 = vp_size * 0.5
		var screen_pos: Vector2 = screen_center + rel
		return screen_pos
	else:
		return world_pos

# --- API para agregar / quitar huecos en tiempo de ejecución ---

func add_hole_node(node: Node, radius_px: float = 100.0) -> int:
	var p: NodePath = node.get_path()
	hole_nodes.append(p)
	hole_radii_px.append(radius_px)
	return hole_nodes.size() - 1

func remove_hole_node(node: Node) -> bool:
	var p: NodePath = node.get_path()
	for i in range(hole_nodes.size()):
		if hole_nodes[i] == p:
			hole_nodes.remove_at(i)
			if i < hole_radii_px.size():
				hole_radii_px.remove_at(i)
			return true
	return false

func add_hole_at_world_pos(world_pos: Vector2, radius_px: float = 100.0) -> int:
	world_holes_pos.append(world_pos)
	world_holes_radii_px.append(radius_px)
	return world_holes_pos.size() - 1

func remove_world_hole(index: int) -> bool:
	if index >= 0 and index < world_holes_pos.size():
		world_holes_pos.remove_at(index)
		world_holes_radii_px.remove_at(index)
		return true
	return false

func set_hole_radius_for_node(node: Node, radius_px: float) -> bool:
	var p: NodePath = node.get_path()
	for i in range(hole_nodes.size()):
		if hole_nodes[i] == p:
			hole_radii_px[i] = radius_px
			return true
	return false

func set_world_hole_pos(index: int, world_pos: Vector2) -> bool:
	if index >= 0 and index < world_holes_pos.size():
		world_holes_pos[index] = world_pos
		return true
	return false

func clear_all_holes() -> void:
	hole_nodes.clear()
	hole_radii_px.clear()
	world_holes_pos.clear()
	world_holes_radii_px.clear()

func _collect_group_holes(group_name: String) -> void:
	hole_nodes.clear()
	hole_radii_px.clear()
	var nodes: Array = get_tree().get_nodes_in_group(group_name)
	for n in nodes:
		if n is Node:
			hole_nodes.append((n as Node).get_path())
			var r: float
			if n.name=="Player":
				r= 200.0
			else:
				r= 400.0
			if (n as Node).has_meta("radius"):
				r = float((n as Node).get_meta("radius"))
			elif (n as Node).has_method("get_radius"):
				r = float((n as Node).call("get_radius"))
			hole_radii_px.append(r)
