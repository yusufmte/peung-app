extends Control

var starting_server = randi_range(0, 1)
var total_game_points = 0
var total_match_points = 0
var current_server = 0
var serve_marker = []
var serve_label = []
var deuce_label
var match_score_label = []
var match_score = [0,0]
var game_score_label = []
var game_score = [0,0]
var name_label = []
var player_rect = []
var match_ongoing = true
var one_game_of_multiple_win_screen = false
var deuce = false
var games_needed_to_win_match = int(Global.num_games / 2) + 1

## A dictionary mapping sound keys (strings) to AudioStreamWAV objects
## of loaded sound resources. When no sound resource is available for a particular
## key, the value will be `null`.
var sounds_dict : Dictionary

func _ready():
	var return_button = $ColorRect/MarginContainer/VBoxContainer/ReturnButtonMargin/ReturnButton
	return_button.pressed.connect(_on_ReturnButton_pressed)
	
	serve_marker.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P1ColorRect/P1MarginContainer/P1VBox/ServeMarker)
	serve_marker.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P2ColorRect/P2MarginContainer/P2VBox/ServeMarker)
	update_server()
	
	deuce_label = $ColorRect/DeuceLabel
	
	serve_label.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P1ColorRect/P1MarginContainer/P1VBox/ServeMarker/ServeLabel)
	serve_label.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P2ColorRect/P2MarginContainer/P2VBox/ServeMarker/ServeLabel)

	match_score_label.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P1ColorRect/P1MarginContainer/P1VBox/MatchScoreMargin/MatchScore)
	match_score_label.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P2ColorRect/P2MarginContainer/P2VBox/MatchScoreMargin/MatchScore)
	
	name_label.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P1ColorRect/P1MarginContainer/P1VBox/Name)
	name_label.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P2ColorRect/P2MarginContainer/P2VBox/Name)
	name_label[0].text = Global.p1_name
	name_label[1].text = Global.p2_name
	
	game_score_label.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P1ColorRect/P1MarginContainer/P1VBox/GameScore)
	game_score_label.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P2ColorRect/P2MarginContainer/P2VBox/GameScore)
	
	player_rect.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P1ColorRect)
	player_rect.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P2ColorRect)
	
	player_rect[0].color = Global.p1_color
	player_rect[1].color = Global.p2_color
	
	for i in [0,1]:
		if player_rect[i].color.v < 0.5:
			serve_label[i].add_theme_color_override("font_color", Color.WHITE)
			match_score_label[i].add_theme_color_override("font_color", Color.WHITE)
			game_score_label[i].add_theme_color_override("font_color", Color.WHITE)
			name_label[i].add_theme_color_override("font_color", Color.WHITE)
	
	if Global.num_games == 1:
		for label in match_score_label:
			label.add_theme_color_override("font_color", Color(0,0,0,0))

	# Load all available sounds
	for key in Global.sound_keys():
		sounds_dict[key] = Global.load_sound(key)

func reset_game():
	game_score.fill(0)
	total_game_points = 0
	deuce = false
	deuce_label.hide()
	for label in game_score_label:
		label.text = "0"
	for label in serve_label:
		label.text = "SERVE"
	starting_server = randi_range(0, 1)
	update_server()
	
func _unhandled_input(event):
	if not match_ongoing:
		return
	if not event is InputEventMouseButton:
		return

	if event.is_pressed() and one_game_of_multiple_win_screen:
			one_game_of_multiple_win_screen = false
			reset_game()
	elif event.is_released() and event.is_action_released("primary"):
		award_point(get_player_rect_at_pos(event.position))
	elif event.is_pressed() and event.is_action_pressed("secondary"):
		confiscate_point(get_player_rect_at_pos(event.position))

# Gets player 1 or player 2 color rect node that contains the position, if any
func get_player_rect_at_pos(pos : Vector2):
	for child in $ColorRect/MarginContainer/VBoxContainer/HBoxContainer.get_children():
		if child.get_global_rect().has_point(pos):
			return child

func award_point(rect):
	var player_being_awarded = player_rect.find(rect)
	total_game_points = total_game_points + 1
	game_score[player_being_awarded] = game_score[player_being_awarded] + 1
	game_score_label[player_being_awarded].text = str(game_score[player_being_awarded])
	update_deuce_label()
	update_server()
	check_for_game_victory()

func confiscate_point(rect):
	var player_being_punished = player_rect.find(rect)
	if game_score[player_being_punished] > 0:
		total_game_points = total_game_points - 1
		game_score[player_being_punished] = game_score[player_being_punished] - 1
		game_score_label[player_being_punished].text = str(game_score[player_being_punished])
		update_deuce_label()
		update_server()

func is_deuce():
	return (game_score[0] >= 10 and game_score[1] >= 10)

func update_deuce_label():
	if is_deuce():
		deuce_label.show()
	else:
		deuce_label.hide()

func check_for_game_victory():
	if game_score[0] < 10 and game_score[1] < 10: #neither deuce nor victory
		return
	if game_score[0] > 10 or game_score[1] > 10: #someone winning (if there is a 2pt lead, checked below)
			if game_score[0] > (game_score[1] + 1):
				game_victory(0)
			if game_score[1] > (game_score[0] + 1):
				game_victory(1)

func game_victory(game_winning_player):
	if Global.num_games > 1:
		award_game_point(game_winning_player)
		total_match_points = total_match_points + 1
	else:
		declare_game_winner(game_winning_player)
		match_ongoing = false

func award_game_point(game_winning_player):
	match_score[game_winning_player] = match_score[game_winning_player] + 1
	match_score_label[game_winning_player].text = str(match_score[game_winning_player])
	check_for_match_victory()
	if match_ongoing:
		declare_game_winner(game_winning_player)
		one_game_of_multiple_win_screen = true

func check_for_match_victory():
	if match_score[0] >= games_needed_to_win_match:
		declare_match_winner(0)
	if match_score[1] >= games_needed_to_win_match:
		declare_match_winner(1)

func declare_game_winner(game_winning_player):
	serve_label[game_winning_player].text = "WIN!!"
	serve_marker[game_winning_player].show()
	serve_marker[(game_winning_player + 1) % 2].hide()

func declare_match_winner(match_winning_player):
	match_ongoing = false
	serve_label[match_winning_player].text = "MATCH WIN!!"
	serve_marker[match_winning_player].show()
	serve_marker[(match_winning_player + 1) % 2].hide()

func update_server():
	if not is_deuce():
		if (total_game_points % 4) < 2: #serve alternates every 2pts
			set_server_to(starting_server)
		else:
			set_server_to(1 - starting_server) #makes server 0 if starting server was 1, and vice versa
	else: #serve alternates every 1pt in deuce mode
			set_server_to((total_game_points + starting_server) % 2) #this is weird, but i believe ends up correctly calculating the deuce server

func set_server_to(server):
	current_server = server
	if current_server == 0:
		serve_marker[0].show()
		serve_marker[1].hide()
	else:
		serve_marker[0].hide()
		serve_marker[1].show()

## Play a sound by key, first checking if there is an existing wav to use,
## and if not then attempting to use TTS as a fallback.
func play_sound(key:String) -> void:
	if sounds_dict.has(key) and sounds_dict[key] is AudioStreamWAV:
		$AudioStreamPlayer.stream = sounds_dict[key]
		$AudioStreamPlayer.play()
	else:
		Global.speak_tts(key)

func _on_ReturnButton_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
