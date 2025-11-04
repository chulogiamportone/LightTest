extends Node2D
const ambiente = "uid://y0uxal17cunu"
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var audio_stream_player_2d_2: AudioStreamPlayer2D = $AudioStreamPlayer2D2



func _on_audio_stream_player_2d_finished() -> void:
	audio_stream_player_2d.play()


func _on_audio_stream_player_2d_2_finished() -> void:
	audio_stream_player_2d_2.play()
