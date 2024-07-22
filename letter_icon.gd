extends Node2D
class_name LetterIcon

@export var icon_text:String = ""

@onready var icon_text_obj = $LetterIcon/IconText

func _ready():
	icon_text_obj.text = icon_text

func update_icon_text(p_icon_text):
	icon_text = p_icon_text
	
	if icon_text_obj != null:
		icon_text_obj.text = p_icon_text
