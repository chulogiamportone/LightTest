class_name Camera
extends Camera2D

#region Variables exportadas
@export var pan_speed: float = 4000.0
@export var zoom_step: float = 0.75
@export var zoom_min: float = 3
@export var zoom_max: float = 3
@export var follow_smoothness: float = 0.1  # Nueva variable para suavizar seguimiento
#endregion

#region Variables internas
var _dragging: bool = false
var time_to_transition_camera: float = 0.5

# Referencia al objetivo a seguir (personaje activo)
var follow_target: CharacterBody2D = null

#endregion

#region Inicialización
func _ready() -> void:
	add_to_group("main_camera")
	# Opcional: iniciar zoom en valor mínimo
	_set_zoom(Vector2(zoom_min, zoom_min))
#endregion

#region Manejo de entrada
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(zoom - Vector2(zoom_step, zoom_step))
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(zoom + Vector2(zoom_step, zoom_step))
		elif event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = true
		elif not event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		position -= event.relative * zoom.x
#endregion

#region Movimiento de cámara
func _physics_process(delta: float) -> void:
	if follow_target:
		var target_pos = follow_target.global_position
		position = position.lerp(target_pos, follow_smoothness)
#endregion

#region Funciones de zoom
func _set_zoom(new_zoom: Vector2) -> void:
	var z: float = clamp(new_zoom.x, zoom_min, zoom_max)
	zoom = Vector2(z, z)
#endregion

#region Funciones públicas
func set_follow_target(target: Node2D) -> void:
	follow_target = target
#endregion
