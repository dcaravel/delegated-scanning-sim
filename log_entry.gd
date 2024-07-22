extends HBoxContainer
class_name LogEntry

@export var desc:String = ""
@export var icon_text:String = ""

@onready var letter = $IconWrap/Letter
@onready var desc_obj = %Desc

func _ready():
	letter.update_icon_text(icon_text)
	desc_obj.text = desc
