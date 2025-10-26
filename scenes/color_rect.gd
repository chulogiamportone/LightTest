extends ColorRect

@onready var sub_vp =  $"../SubViewport"
@onready var light_rect =  $"../SubViewport/ColorRect2"

@onready var player: CharacterBody2D = $"../../Player"


func _ready():
	material.set_shader_parameter("light_mask", sub_vp.get_texture())

func _process(delta):
	if player and light_rect.material:
		light_rect.material.set_shader_parameter("light_pos", player.global_position)
