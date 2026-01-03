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
		
	$ColorRect/MarginContainer/VBoxContainer/CenterMargin/CenterHBox/ScrollContainer.get_v_scroll_bar().custom_minimum_size.x = 150

	DirAccess.make_dir_absolute(Global.sounds_dir)

	%TTSVoicesDropdown.clear()
	var voices = DisplayServer.tts_get_voices_for_language("en")
	if not voices.is_empty():
		var selected_index : int = 0
		var selected_voice : String = Global.get_tts_voice()
		for i in voices.size():
			%TTSVoicesDropdown.add_item(voices[i])
			if voices[i] == selected_voice:
				selected_index = i
		%TTSVoicesDropdown.select(selected_index)
	else:
		%TTSVoicesDropdown.add_item("TTS not available", 0)
		%TTSVoicesDropdown.select(0)
		%TTSVoicesDropdown.disabled = true
		Global.set_and_save_tts_voice("")

	_update_buttons_enabledness()
	set_status_text("")

## Set the status label at the bottom to display some text. 
func set_status_text(text:String) -> void:
	%StatusLabel.text = text

func _on_ReturnButton_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_record_button_pressed() -> void:
	if recording_effect.is_recording_active():
		recording = recording_effect.get_recording()
		mic.stop()
		recording_effect.set_recording_active(false)
		$%RecordButton.set_icon_to_start()

		var selected_items : PackedInt32Array = %AudioManagerItemList.get_selected_items()
		if selected_items.size() != 1:
			set_status_text("Recording should not be enabled when there isn't a unique selection!")
			return
		var sound_key : String = %AudioManagerItemList.get_item_text(selected_items[0])
		var user_path : String = Global.get_user_sound_path(sound_key)
		var err = recording.save_to_wav(user_path)
		if err == OK:
			set_status_text("Saved custom override for %s" % sound_key)
		else:
			set_status_text("Error: Unable to save custom override for %s" % sound_key)
	else:
		mic.play()
		recording_effect.set_recording_active(true)
		$%RecordButton.set_icon_to_stop()

	_update_buttons_enabledness()

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

func _on_play_button_pressed() -> void:
	var selected_items : PackedInt32Array = %AudioManagerItemList.get_selected_items()
	if selected_items.size() != 1:
		set_status_text("Play button should not be enabled when there isn't a unique selection!")
		return
	var sound_key : String = %AudioManagerItemList.get_item_text(selected_items[0])
	var sound = Global.load_sound(sound_key)
	if sound is AudioStreamWAV:
		set_status_text("Playing %s from asset" % sound_key)
		player.stream = sound
		player.play()
	else:
		set_status_text("Playing %s using TTS" % sound_key)
		Global.speak_tts(sound_key)

func _on_delete_button_pressed() -> void:
	var selected_items : PackedInt32Array = %AudioManagerItemList.get_selected_items()
	if selected_items.size() != 1:
		set_status_text("Delete button should not be enabled when there isn't a unqiue selection!")
		return
	var sound_key : String = %AudioManagerItemList.get_item_text(selected_items[0])
	var user_path : String = Global.get_user_sound_path(sound_key)
	if not FileAccess.file_exists(user_path):
		set_status_text("Delete button should not be enabled when the corresponding file does not exist!")
		return
	var err = DirAccess.remove_absolute(user_path)
	if err == OK:
		set_status_text("Deleted custom override for %s" % sound_key)
	else:
		set_status_text("Error: Unable to delete custom override for %s" % sound_key)
	_update_buttons_enabledness()


func _on_tts_voices_dropdown_item_selected(index: int) -> void:
	var voice : String = %TTSVoicesDropdown.get_item_text(
		%TTSVoicesDropdown.get_item_index(
			%TTSVoicesDropdown.get_selected_id()
		)
	)
	Global.set_and_save_tts_voice(voice)
