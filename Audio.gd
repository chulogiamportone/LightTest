extends Node

@onready var player: AudioStreamPlayer = AudioStreamPlayer.new()



func play_music(path: String):
	var new_stream = load(path)
	if new_stream:
		player.stream = new_stream
		player.play()

func stop_music():
	player.stop()
