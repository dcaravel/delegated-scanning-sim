extends Node2D

@export var icon_text:String = ""

func _ready():
	%IconText.text = icon_text

func update_icon_text(p_icon_text):
	icon_text = p_icon_text
	%IconText.text = p_icon_text

func _exit_tree():
	queue_free()