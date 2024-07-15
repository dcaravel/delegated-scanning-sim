extends HBoxContainer
class_name LogEntry

@export var desc:String = ""
@export var icon_text:String = ""

func _ready():
	$IconWrap/Letter.update_icon_text(icon_text)
	%Desc.text = desc

func _exit_tree():
	queue_free()
