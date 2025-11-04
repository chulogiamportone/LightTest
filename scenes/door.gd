# door.gd
extends StaticBody2D

# Variable para controlar si la puerta está abierta o cerrada
var is_open = false



# Referencia al sprite de la puerta
@onready var door_sprite: TextureRect = $Sprite2D
@onready var door_collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	door_collision.disabled = false


# Función que se llama cuando un cuerpo entra en el área
func _on_body_entered(body):
	if body.name == "Player":  # Asegúrate de que el nodo del jugador se llama "Player"
		# Mostrar un mensaje o cambiar el cursor para indicar que se puede interactuar
		print("Presiona 'E' para abrir la puerta")

# Función que se llama cuando un cuerpo sale del área
func _on_body_exited(body):
	if body.name == "Player":
		print("Fuera del área de interacción")

# Función para abrir la puerta
func open_door():
	if not is_open:
		is_open = true
		door_collision.disabled = true
		# Si usas AnimationPlayer, reproduce la animación de apertura
		door_sprite.position.y += 50  # Mueve la puerta hacia la derecha (ajusta según tu diseño)
		door_sprite.visible=false
# Función para cerrar la puerta
func close_door():
	if is_open:
		is_open = false
		door_collision.disabled = false
		# Si usas AnimationPlayer, reproduce la animación de cierre
		# Si no usas animaciones, simplemente cambia la posición del sprite
		door_sprite.position.y -= 50  # Mueve la puerta hacia la izquierda (ajusta según tu diseño)
		door_sprite.visible=true
		
