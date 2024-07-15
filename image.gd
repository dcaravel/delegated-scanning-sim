extends Control
class_name ImageControl

@export var image_reference = "placeholder"

signal prod_pressed
signal dev_pressed
signal other_pressed
signal roxctl_pressed

var active_button_style = preload("res://theme/panel/active_thing.stylebox")
enum buttonsIdx {NONE, PROD, DEV, OTHER, ROXCTL}
var active_button_idx = buttonsIdx.NONE
var buttons:Array[Control] = []

func set_active_button_idx(idx:buttonsIdx):
	active_button_idx = idx

func _ready():
	buttons = [
		null,
		$"deploy-prod",
		$"deploy-dev",
		$"deploy-other",
		$"roxctl",
	]
	$Label.text = image_reference

func _process(_delta):
	_style_active_button()

func _style_active_button():
	for b in buttons:
		if b == null:
			continue
		b.remove_theme_stylebox_override("normal")
		b.remove_theme_stylebox_override("hover")
	
	if active_button_idx == buttonsIdx.NONE:
		return
		
	buttons[active_button_idx].add_theme_stylebox_override("normal", active_button_style)
	buttons[active_button_idx].add_theme_stylebox_override("hover", active_button_style)

func _on_deployprod_pressed():
	active_button_idx = buttonsIdx.PROD
	prod_pressed.emit()

func _on_deploydev_pressed():
	active_button_idx = buttonsIdx.DEV
	dev_pressed.emit()

func _on_deployother_pressed():
	active_button_idx = buttonsIdx.OTHER
	other_pressed.emit()
	
func _on_roxctl_pressed():
	active_button_idx = buttonsIdx.ROXCTL
	roxctl_pressed.emit()

func _exit_tree():
	queue_free()