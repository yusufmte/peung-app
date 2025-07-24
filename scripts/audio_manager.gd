extends Control

var recording_effect : AudioEffectRecord
var recording : AudioStreamWAV

var mic : AudioStreamPlayer
var player : AudioStreamPlayer
var item_list : ItemList

func _ready() -> void:
	var return_button = $ColorRect/MarginContainer/VBoxContainer/ReturnButtonMargin/ReturnButton
	return_button.pressed.connect(_on_ReturnButton_pressed)
	recording_effect = AudioServer.get_bus_effect(AudioServer.get_bus_index("Record"), 0)
	mic = $RecordingAudioStream
	player = $RecordingPlaybackAudioStream

	item_list = %AudioManagerItemList
	item_list.clear()
	for key in Global.sound_keys():
		item_list.add_item(key)

	_update_buttons_enabledness()

func _on_ReturnButton_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_record_button_pressed() -> void:
	if recording_effect.is_recording_active():
		recording = recording_effect.get_recording()
		mic.stop()
		recording_effect.set_recording_active(false)
		$%RecordButton.set_icon_to_start()

		# Play back the recorded thing to demo how to get the stream and play it
		player.stream = recording
		player.play()
	else:
		mic.play()
		recording_effect.set_recording_active(true)
		$%RecordButton.set_icon_to_stop()

func _update_buttons_enabledness() -> void:
	var nothing_selected : bool = not %AudioManagerItemList.is_anything_selected()
	%RecordButton.disabled = nothing_selected
	%PlayButton.disabled = nothing_selected

	if nothing_selected:
		%DeleteButton.disabled = true
	else:
		var selected_items : PackedInt32Array = %AudioManagerItemList.get_selected_items()
		if selected_items.size() != 1:
			%DeleteButton.disabled = true
		else:
			var sound_key : String = %AudioManagerItemList.get_item_text(selected_items[0])
			%DeleteButton.disabled = not FileAccess.file_exists(Global.get_user_sound_path(sound_key))

func _on_audio_manager_item_list_item_selected(index: int) -> void:
	_update_buttons_enabledness()
