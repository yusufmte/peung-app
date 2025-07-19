extends Control

var p1_name_label
var p1_color_picker
var p2_name_label
var p2_color_picker
var num_games_option
	
func _ready():
	p1_name_label = $ColorRect/MarginContainer/VBoxContainer/PlayersMargin/PlayersHBox/Player1HBox/Player1
	p1_color_picker = $ColorRect/MarginContainer/VBoxContainer/PlayersMargin/PlayersHBox/Player1HBox/Player1ColorPickerButton
	p2_name_label = $ColorRect/MarginContainer/VBoxContainer/PlayersMargin/PlayersHBox/Player2HBox/Player2
	p2_color_picker = $ColorRect/MarginContainer/VBoxContainer/PlayersMargin/PlayersHBox/Player2HBox/Player2ColorPickerButton
	num_games_option = $ColorRect/MarginContainer/VBoxContainer/BottomMargin/BottomHBox/GamesMargin/GamesVBox/NumGames
	p1_name_label.text = Global.p1_name
	p1_color_picker.color = Global.p1_color
	p2_name_label.text = Global.p2_name
	p2_color_picker.color = Global.p2_color
	num_games_option.select(Global.num_games_index)
	
	var quit_button = $ColorRect/MarginContainer/VBoxContainer/BottomMargin/BottomHBox/ButtonsMargin/ButtonsVBox/QuitButtonMargin/QuitButton
	quit_button.pressed.connect(_on_QuitButton_pressed)
	
	var start_button = $ColorRect/MarginContainer/VBoxContainer/BottomMargin/BottomHBox/ButtonsMargin/ButtonsVBox/StartButtonMargin/StartButton
	start_button.pressed.connect(_on_StartButton_pressed)
	
	var audio_manager_button = $ColorRect/MarginContainer/VBoxContainer/TopMargin/TopHBox/AudioManagerButton
	audio_manager_button.pressed.connect(_on_AudioManagerButton_pressed)
	
	var help_button = $ColorRect/MarginContainer/VBoxContainer/TopMargin/TopHBox/HelpButton
	help_button.pressed.connect(_on_HelpButton_pressed)

func update_globals():
	Global.p1_name = p1_name_label.text
	Global.p1_color = p1_color_picker.color
	Global.p2_name = p2_name_label.text
	Global.p2_color = p2_color_picker.color
	Global.num_games_index = num_games_option.selected
	Global.num_games = int(num_games_option.get_item_text(num_games_option.selected))

func _on_QuitButton_pressed():
	get_tree().quit()

func _on_StartButton_pressed():
	update_globals()
	get_tree().change_scene_to_file("res://scenes/match.tscn")

func _on_AudioManagerButton_pressed():
	update_globals()
	get_tree().change_scene_to_file("res://scenes/audio_manager.tscn")

func _on_HelpButton_pressed():
	update_globals()
	get_tree().change_scene_to_file("res://scenes/help.tscn")
