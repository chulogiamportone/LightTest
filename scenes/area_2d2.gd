extends Area2D

@onready var color_rect: ColorRect = $"../ColorRect"

func _ready() -> void:
	color_rect.add_hole_node(self, 10.0)
