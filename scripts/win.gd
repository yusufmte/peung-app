extends Control

signal rematch
signal nextgame

func initialize(winning_player,victory_type):
	if victory_type == "onegame":
		%VictoryLabel.text = [Global.p1_name, Global.p2_name][winning_player] + " wins the game!"
		%VictoryButton.text = "rematch!"
		%VictoryButton.pressed.connect(_on_rematch_pressed)
	if victory_type == "match_partial":
		%VictoryLabel.text = [Global.p1_name, Global.p2_name][winning_player] + " wins the game! but the match continues... (best of " + str(Global.num_games) + ")"
		%VictoryButton.text = "next game..."
		%VictoryButton.pressed.connect(_on_nextgame_pressed)
	if victory_type == "match_complete":
		%VictoryLabel.text = [Global.p1_name, Global.p2_name][winning_player] + " wins!! the match, that is."
		%VictoryButton.text = "rematch!"
		%VictoryButton.pressed.connect(_on_rematch_pressed)

func _on_rematch_pressed():
	emit_signal("rematch")
	queue_free()

func _on_nextgame_pressed():
	emit_signal("nextgame")
	queue_free()
