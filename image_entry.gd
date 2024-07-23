extends HBoxContainer
class_name ImageEntry

var index:int
var text:String
var button_group:ButtonGroup
var button_pressed:bool

@onready var check_box = $CheckBox

func _ready():
	check_box.text = text
	check_box.button_group = button_group
	check_box.button_pressed = button_pressed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_delete_button_pressed():
	Config.delete_image(index)
