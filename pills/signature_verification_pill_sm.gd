extends Label
class_name SignatureVerificationPillSM

@export var active:bool = false

var inactive_color = Color("ffffff1e")
var inactive_stylebox = preload("res://theme/panel/inactive.stylebox")
var active_stylebox = preload("res://theme/panel/signature_verification.stylebox")

func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	add_theme_stylebox_override("normal", active_stylebox if active else inactive_stylebox)
	
	_update_font()


func _update_font():
	if active:
		remove_theme_color_override("font_color")
		return
		
	add_theme_color_override("font_color", inactive_color)
