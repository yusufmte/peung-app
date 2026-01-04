extends Control

var starting_server = randi_range(0, 1)
var current_server = 0
var serve_marker = []
var serve_label = []
var deuce_label
var match_score_label = []
var match_score = [0,0]
var game_score_label = []
var game_score = [0,0]
var remove_point_button = []
var name_label = []
var player_rect = []
var gamestate = "" #"ongoing", "onegame_win", "match_partial_win", "match_complete_win"
var win_scene = preload("res://scenes/win.tscn")
var win_box
var deuce = false
var games_needed_to_win_match = int(Global.num_games / 2) + 1

## A dictionary mapping sound keys (strings) to AudioStreamWAV objects
## of loaded sound resources. When no sound resource is available for a particular
## key, the value will be `null`.
var sounds_dict : Dictionary
## A list of sound keys that are currently queued up to be played
var sound_queue : Array[String] = []
var sound_currently_playing : bool = false

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
	
	remove_point_button.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P1ColorRect/P1MarginContainer/P1VBox/ControlsHBox/RemovePointButtonMargin/RemovePointButton)
	remove_point_button.append($ColorRect/MarginContainer/VBoxContainer/HBoxContainer/P2ColorRect/P2MarginContainer/P2VBox/ControlsHBox/RemovePointButtonMargin/RemovePointButton)
	for i in [0,1]:
		remove_point_button[i].pressed.connect(confiscate_point.bind(i))
	
	for i in [0,1]:
		if player_rect[i].color.v < 0.5:
			serve_label[i].add_theme_color_override("font_color", Color.WHITE)
			match_score_label[i].add_theme_color_override("font_color", Color.WHITE)
			game_score_label[i].add_theme_color_override("font_color", Color.WHITE)
			name_label[i].add_theme_color_override("font_color", Color.WHITE)
			remove_point_button[i].add_theme_color_override("font_color", Color.WHITE)
			remove_point_button[i].add_theme_color_override("font_disabled_color", Color.WHITE)
			remove_point_button[i].add_theme_color_override("font_hover_pressed_color", Color.WHITE)
			remove_point_button[i].add_theme_color_override("font_hover_color", Color.WHITE)
			remove_point_button[i].add_theme_color_override("font_outline_color", Color.WHITE)
			remove_point_button[i].add_theme_color_override("font_focus_color", Color.WHITE)
			remove_point_button[i].add_theme_color_override("font_pressed_color", Color.WHITE)

	if Global.num_games == 1:
		for label in match_score_label:
			label.add_theme_color_override("font_color", Color(0,0,0,0))

	# Load all available sounds
	for key in Global.sound_keys():
		sounds_dict[key] = Global.load_sound(key)

	# Listen for TTS utterenace end
	DisplayServer.tts_set_utterance_callback(
		DisplayServer.TTS_UTTERANCE_ENDED,
		Callable(self, "_on_tts_utterance_ended"),
	)
	
	gamestate = "ongoing"
	announce_server()

func reset_game():
	game_score.fill(0)
	deuce = false
	deuce_label.hide()
	for label in game_score_label:
		label.text = "0"
	starting_server = randi_range(0, 1)
	update_server()
	
	sound_queue.clear()
	if Global.num_games > 1:
		queue_sound("match score")
		announce_scores(match_score)
		queue_sound("game score")
		announce_scores(game_score)
	gamestate = "ongoing"
	announce_server()
	
func _unhandled_input(event):
	if not event is InputEventMouseButton:
		return

	if event.is_pressed():
		if gamestate == "ongoing":
			var player_at_pos = get_player_at_pos(event.position)
			if player_at_pos != 2:
				award_point(player_at_pos)

# Gets player 1 or player 2 color rect node that contains the position, if any
func get_player_at_pos(pos : Vector2):
	for i in [0,1]:
		if player_rect[i].get_global_rect().has_point(pos):
			return i
	return 2 # indicates neither color rect node contains the position

func award_point(player_being_awarded):
	game_score[player_being_awarded] = game_score[player_being_awarded] + 1
	game_score_label[player_being_awarded].text = str(game_score[player_being_awarded])
	update_server()
	
	if check_for_game_or_match_victory():
		return
	
	sound_queue.clear()
	queue_sound("point award chime")
	queue_sound([Global.p1_name, Global.p2_name][player_being_awarded])
	queue_sound("point")
	announce_scores(game_score)
	update_deuce_label()
	announce_server()

func confiscate_point(player_being_punished):
	if game_score[player_being_punished] > 0:
		game_score[player_being_punished] = game_score[player_being_punished] - 1
		game_score_label[player_being_punished].text = str(game_score[player_being_punished])
		update_server()
		
		sound_queue.clear()
		queue_sound("point rescind chime")
		queue_sound("point removed from")
		queue_sound([Global.p1_name, Global.p2_name][player_being_punished])
		announce_scores(game_score)
		update_deuce_label()
		announce_server()
			
		if gamestate != "ongoing" and not check_for_game_or_match_victory(): #if the gamestate was not "ongoing", but there isn't a victor anymore
			prematurely_remove_win_box()
			if gamestate == "match_complete_win": # because the match score is updated early when a whole multigame match is won, the unearned match points must be rescinded here
				if match_score[0] > match_score[1]:
					match_score[0] = match_score[0] - 1
					match_score_label[0].text = str(match_score[0])
				if match_score[1] > match_score[0]:
					match_score[1] = match_score[1] - 1
					match_score_label[1].text = str(match_score[1])
			gamestate = "ongoing"
		
		if check_for_game_or_match_victory():
			return

func is_deuce():
	return (game_score[0] >= 10 and game_score[1] >= 10)

func update_deuce_label():
	if is_deuce():
		deuce_label.show()
		if game_score[0] == 10 and game_score[1] == 10:
			queue_sound("deuce") # playing this here ensures "deuce" is only said once, or when you return to 10-10 via point confiscation
	else:
		deuce_label.hide()

func show_win_box(winning_player,win_type):
	win_box = win_scene.instantiate()
	win_box.initialize(winning_player,win_type)
	add_child(win_box)
	win_box.rematch.connect(_on_rematch_pressed)
	win_box.nextgame.connect(_on_nextgame_pressed)

func prematurely_remove_win_box():
	remove_child(win_box)

func _on_rematch_pressed():
	match_score.fill(0)
	for label in match_score_label:
		label.text = "0"
	reset_game()

func _on_nextgame_pressed():
	var victor = check_game_victor()
	match_score[victor] = match_score[victor] + 1
	match_score_label[victor].text = str(match_score[victor])
	reset_game()

func check_game_victor():
	if game_score[0] > 10 or game_score[1] > 10: #someone winning (if there is a 2pt lead, checked below)
		if game_score[0] > (game_score[1] + 1):
			return 0
		if game_score[1] > (game_score[0] + 1):
			return 1
	return 2 #no one winning

func check_for_game_or_match_victory():
	var victor = check_game_victor()
	if check_game_victor() < 2 and gamestate == "ongoing": # this means someone is newly winning the GAME
		if Global.num_games == 1: # if there is one game, declare the victor
			sound_queue.clear()
			queue_sound("victory chime")
			queue_sound([Global.p1_name, Global.p2_name][victor])
			queue_sound("wins the game")
			show_win_box(victor,"onegame")
			gamestate = "onegame_win"
			return true
		else: # if there are multiple games, either declare the game or match victor
			if (match_score[victor] + 1) < games_needed_to_win_match: # more games left in the match
				sound_queue.clear()
				queue_sound("victory chime")
				queue_sound([Global.p1_name, Global.p2_name][victor])
				queue_sound("wins the game")
				show_win_box(victor,"match_partial")
				gamestate = "match_partial_win"
				return true
			else: # once victor wins this game, they will have won the match
				sound_queue.clear()
				queue_sound("grand victory chime")
				queue_sound([Global.p1_name, Global.p2_name][victor])
				queue_sound("wins the match")
				match_score[victor] = match_score[victor] + 1 # the match score incrementation is usually in the "nextgame" button - so when the match is won, this needs to be done here
				match_score_label[victor].text = str(match_score[victor])
				show_win_box(victor,"match_complete")
				gamestate = "match_complete_win"
				return true
	return false

func update_server():
	if not is_deuce():
		if ((game_score[0]+game_score[1]) % 4) < 2: #serve alternates every 2pts
			set_server_to(starting_server)
		else:
			set_server_to(1 - starting_server) #makes server 0 if starting server was 1, and vice versa
	else: #serve alternates every 1pt in deuce mode
			set_server_to(((game_score[0]+game_score[1]) + starting_server) % 2) #this is weird, but i believe ends up correctly calculating the deuce server

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

## Queue the playing of a sound which is specified by sound key
func queue_sound(key:String) -> void:

	# Do not queue anything if TTS would be needed but TTS is unavailable,
	# otherwise an item would get stuck in the queue and never count as played
	var sound_resource_is_available : bool = sounds_dict.has(key) and sounds_dict[key] is AudioStreamWAV
	if (not sound_resource_is_available) and (not Global.tts_is_available()):
		return

	if not sound_currently_playing:
		sound_currently_playing = true
		play_sound(key)
	else:
		sound_queue.push_back(key)

func _on_audio_stream_player_finished() -> void:
	_on_play_sound_finish()

func _on_tts_utterance_ended(_utterance_id : int) -> void:
	_on_play_sound_finish()

## we call this whether the sound was played via TTS or via audio stream
func _on_play_sound_finish() -> void:
	if sound_queue.is_empty():
		sound_currently_playing = false
	else:
		assert(sound_currently_playing)
		play_sound(sound_queue.pop_front())

func announce_server():
	queue_sound([Global.p1_name, Global.p2_name][current_server])
	queue_sound("serve")

func announce_scores(scores):
	for score in scores:
		queue_sound(str(score))

func _on_ReturnButton_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
