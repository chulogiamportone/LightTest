

extends Area2D

@export var pull_speed: float = 50.0  # Velocidad de atracción
@export var pull_strength: float = 20.0  # Fuerza de atracción

var bodies_in_area: Array = []


func _on_body_entered(body: Node2D) -> void:
	if body not in bodies_in_area :
		bodies_in_area.append(body)

func _on_body_exited(body: Node2D):
	if body in bodies_in_area:
		bodies_in_area.erase(body)

func _physics_process(delta: float):
	for body in bodies_in_area:
		if body is CharacterBody2D:
			var center_pos = global_position
			var direction = (center_pos - body.global_position).normalized()
			var distance = body.global_position.distance_to(center_pos)
			
			# Mover directamente la posición en lugar de modificar velocity
			var speed = pull_speed * min(distance / pull_strength, 1.0)
			body.global_position += direction * speed * delta
