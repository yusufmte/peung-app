extends Control

var starting_server = randi_range(0, 1)
var total_game_points = 0
var total_match_points = 0
var current_server = 0
var serve_marker = []
var serve_label = []
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

func _ready():
	var return_button = $ColorRect/MarginContainer/VBoxContainer/ReturnButtonMargin/ReturnButton
	return_button.pressed.connect(_on_ReturnButton_pressed)
	
	serve_marker.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P1ColorRect/P1MarginContainer/P1VBox/ServeMarker)
	serve_marker.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P2ColorRect/P2MarginContainer/P2VBox/ServeMarker)
	update_server()
	
	serve_label.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P1ColorRect/P1MarginContainer/P1VBox/ServeMarker/ServeLabel)
	serve_label.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P2ColorRect/P2MarginContainer/P2VBox/ServeMarker/ServeLabel)

	match_score_label.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P1ColorRect/P1MarginContainer/P1VBox/MatchScoreMargin/MatchScore)
	match_score_label.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P2ColorRect/P2MarginContainer/P2VBox/MatchScoreMargin/MatchScore)
	if Global.num_games == 1:
		for label in match_score_label:
			label.add_theme_color_override("font_color", Color(0,0,0,0))
	
	name_label.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P1ColorRect/P1MarginContainer/P1VBox/Name)
	name_label.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P2ColorRect/P2MarginContainer/P2VBox/Name)
	name_label[0].text = Global.p1_name
	name_label[1].text = Global.p2_name
	
	game_score_label.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P1ColorRect/P1MarginContainer/P1VBox/GameScore)
	game_score_label.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P2ColorRect/P2MarginContainer/P2VBox/GameScore)
	
	player_rect.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P1ColorRect)
	player_rect.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P2ColorRect)

func reset_game():
	game_score.fill(0)
	total_game_points = 0
	deuce = false
	for label in game_score_label:
		label.text = "0"
	for label in serve_label:
		label.text = "SERVE"
	starting_server = randi_range(0, 1)
	update_server()
	
func _unhandled_input(event):
	if match_ongoing and event is InputEventMouseButton and event.pressed:
		if one_game_of_multiple_win_screen:
			one_game_of_multiple_win_screen = false
			reset_game()
		else:
			var mouse_pos = event.position
			for child in $ColorRect/MarginContainer/VBoxContainer/HBoxContainer.get_children():
				if child.get_global_rect().has_point(mouse_pos):
					match event.button_index:
						MOUSE_BUTTON_LEFT: # corresponds to touchscreen tap via project settings
							award_point(child)
						MOUSE_BUTTON_RIGHT: # corresponds to touchscreen long press (on android) via project settings
							confiscate_point(child)

func award_point(rect):
	var player_being_awarded = player_rect.find(rect)
	total_game_points = total_game_points + 1
	game_score[player_being_awarded] = game_score[player_being_awarded] + 1
	game_score_label[player_being_awarded].text = str(game_score[player_being_awarded])
	update_server()
	check_for_game_victory_or_deuce()

func confiscate_point(rect):
	var player_being_punished = player_rect.find(rect)
	if game_score[player_being_punished] > 0:
		total_game_points = total_game_points - 1
		game_score[player_being_punished] = game_score[player_being_punished] - 1
		game_score_label[player_being_punished].text = str(game_score[player_being_punished])
		update_server()

func check_for_game_victory_or_deuce():
	if game_score[0] < 10 and game_score[1] < 10: #neither deuce nor victory
		return
	if game_score[0] > 10 or game_score[1] > 10: #someone winning (if there is a 2pt lead, checked below)
			if game_score[0] > (game_score[1] + 1):
				game_victory(0)
			if game_score[1] > (game_score[0] + 1):
				game_victory(1)
	if game_score[0] == 10 and game_score[1] == 10: #deuce
		activate_deuce_mode()

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

func activate_deuce_mode():
	deuce = true

func update_server():
	if not deuce:
		if (total_game_points % 4) < 2: #serve alternates every 2pts
			if starting_server == 0:
				set_server_to(0)
			else:
				set_server_to(1)
		else:
			if starting_server == 0:
				set_server_to(1)
			else:
				set_server_to(0)
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

func _on_ReturnButton_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
