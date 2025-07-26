extends Node


var p1_name = "Player 1"
var MUSHROOM_COLOR : Color = Color(0.86,0.61,0.43,1.00)
var p1_color = MUSHROOM_COLOR
var p2_name = "Player 2"
var TARO_COLOR : Color = Color(1.00,0.56,1.00,1.00)
var p2_color = TARO_COLOR
var num_games_index = 0
var num_games = 1
var sounds_dir = "user://sounds"
var settings_filepath = "user://settings.cfg"
var _tts_voice = null

var _base_sound_keys : Array[String] = [
	"point",
	"serve",
	"wins the game",
	"wins the match",
	"deuce",
	"match score",
	"game score",
	"victory chime", # (three notes ending with a longer chord)
	"grand victory chime", # (three series of three notes, ending with a longer greater chord)
	"point award chime", #  (a bell "ding")
	"point rescind chime", # (a low "vwoopt" sound)
]

func _ready() -> void:
	_tts_voice = get_tts_voice()

## Get the selected TTS voice by taking the global variable first,
## then if it's not initialized proceeding as follows:
## first take what's saved in config if there is a non-"" setting,
## fall back to taking the first voice if one is available,
## and finally fall back to "", which indicates that TTS is not available.
func get_tts_voice() -> String:
	if _tts_voice != null:
		return _tts_voice

	var voice : String = ""
	var cfg = ConfigFile.new()
	if (cfg.load(settings_filepath) == OK):
		voice = cfg.get_value("TTS", "voice", "")
	if voice == "":
		var voices = DisplayServer.tts_get_voices_for_language("en")
		if voices.size() > 0:
			voice = voices[0]

	return voice

## Set the tts voice to be used, and also save the selection to the persistent conig.
func set_and_save_tts_voice(voice : String) -> void:
	_tts_voice = voice
	var cfg = ConfigFile.new()
	cfg.load(settings_filepath) # a no-op if the config file is missing, no problem
	cfg.set_value("TTS", "voice", voice)
	cfg.save(settings_filepath)

## Whether a tts voice is available for use. If this is false then TTS will not work
## and the "end of an utterance!" will never come.
func tts_is_available() -> bool:
	return _tts_voice is String and _tts_voice != ""

## Keys that can be used to identify audio clips.
## This includes the currently set player names, as well as some numbers up
## to a limit.
func sound_keys() -> Array[String]:
	var player_name_keys : Array[String] = [p1_name, p2_name]
	var numbers : Array[String] = []
	for i in range(1,16):
		numbers.append(str(i))
	return player_name_keys + _base_sound_keys + numbers

## Convert string key into something that is allowed to be a filename
func sanitize_key(key: String) -> String:
	# lowercase, trim, replace spaces with underscores
	var s = key.strip_edges().to_lower().replace(" ", "_")
	# remove anything not a–z, 0–9, or underscore
	var regex = RegEx.new()
	regex.compile("[^a-z0-9_]")
	s = regex.sub(s, "", true)
	return s

## Get the "user://..." path for a sound resource. This is where
## a custom user-recorded sound would live if one existed.
## A string key is reduced using `sanitize_key`,
## so for example "Player 1" is treated the same as "player_1".
func get_user_sound_path(key: String) -> String:
	var name = sanitize_key(key) + ".wav"
	return sounds_dir.path_join(name)

## Get audio data by key.
## Expected keys are those returned by `sound_keys`,
## or any string representation of a non-negative integer (a score).
## A string key is reduced using `sanitize_key`,
## so for example "Player 1" is treated the same as "player_1".
## In descending priority order, the returned sound is either
## (1) a custom saved recording (user://sounds/{name}.wav),
## (2) an internal resource (res://sounds/{name}.wav),
## or (3) null.
## The returned object is either an AudioStreamWAV or null.
func load_sound(key : String) -> Variant:
	var user_path = get_user_sound_path(key)
	if FileAccess.file_exists(user_path):
		return AudioStreamWAV.load_from_file(user_path)
	var name = sanitize_key(key) + ".wav"
	var res_path = "res://sounds/%s" % name
	if ResourceLoader.exists(res_path, "AudioStreamWAV"):
		return ResourceLoader.load(res_path) as AudioStreamWAV
	return null

## Use system TTS to speak some text, doing nothing if TTS is unavailable
func speak_tts(text : String) -> void:
	if tts_is_available():
		DisplayServer.tts_speak(text, _tts_voice)
