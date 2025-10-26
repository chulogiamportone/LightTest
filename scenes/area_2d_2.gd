extends Area2D

@onready var canvas_layer: CanvasLayer = $"../../CanvasLayer"

func _ready():
	# Conectar con el manager de oscuridad
	canvas_layer.add_light_area(self)
