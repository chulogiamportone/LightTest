extends Node

func _ready():
	var size = 512
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	for x in range(size):
		for y in range(size):
			var dx = (x - size/2.0) / (size/2.0)
			var dy = (y - size/2.0) / (size/2.0)
			var dist = sqrt(dx*dx + dy*dy)
			var alpha = clamp(1.0 - dist, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	img.save_png("res://light_texture.png")
	print("Textura creada!")
