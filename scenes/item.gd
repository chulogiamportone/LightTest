extends Node2D
const item_scene = preload("uid://divvmi4dc1wbp")
  # cada ítem puede ser su propio tipo, pero con el mismo sistema
var player_inside := false



@onready var sprite_2d: Sprite2D = $Sprite2D

func _set_text(url:String) -> void:
	sprite_2d= $Sprite2D
	sprite_2d.texture=load(url)
	
	
func _on_body_entered(body):
	if body.name == "Player":
		player_inside = true

func _on_body_exited(body):
	if body.name == "Player":
		player_inside = false

func _process(delta):
	
	if player_inside and Input.is_action_just_pressed("pickup"):
		var inv = get_tree().get_first_node_in_group("inventory")
		if inv and inv.add_item(item_scene):
			queue_free()
			
func get_texture() -> Texture2D:
	return self.sprite_2d.texture
