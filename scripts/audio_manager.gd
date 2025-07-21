extends Control

var recording_effect : AudioEffect
var recording
var mic
var player

func _ready():
	var return_button = $ColorRect/MarginContainer/VBoxContainer/ReturnButtonMargin/ReturnButton
	return_button.pressed.connect(_on_ReturnButton_pressed)
	recording_effect = AudioServer.get_bus_effect(AudioServer.get_bus_index("Record"), 0)
	mic = $RecordingAudioStream
	player = $RecordingPlaybackAudioStream

func _on_ReturnButton_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_record_button_pressed() -> void:
	if recording_effect.is_recording_active():
		recording = recording_effect.get_recording()
		mic.stop()
		recording_effect.set_recording_active(false)

		# Play back the recorded thing to demo how to get the stream and play it
		player.stream = recording
		player.play()
	else:
		mic.play()
		recording_effect.set_recording_active(true)
