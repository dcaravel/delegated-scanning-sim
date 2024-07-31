extends HBoxContainer
class_name ImageEntry

var index:int
var text:String
var button_group:ButtonGroup
var button_pressed:bool

@onready var check_box = $CheckBox
@onready var key_label = $KeyLabel

func _ready():
	key_label.text = str(index+1)
	if index+1 > 9: # 10 do not show
		key_label.modulate.a = 0
	check_box.text = text
	check_box.button_group = button_group
	check_box.button_pressed = button_pressed

func _on_delete_button_pressed():
	Config.delete_image(index)
