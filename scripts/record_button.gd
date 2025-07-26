extends Button

var record_icon_start : CompressedTexture2D
var record_icon_stop : CompressedTexture2D

func _ready() -> void:
	record_icon_start = load("res://icons/record.png")
	record_icon_stop = load("res://icons/stop_record.png")

func set_icon_to_start() -> void:
	self.icon = record_icon_start

func set_icon_to_stop() -> void:
	self.icon = record_icon_stop
