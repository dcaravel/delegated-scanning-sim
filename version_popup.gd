extends Panel

var mouse_over_4_7 = false
var mouse_over_4_8 = false

var default_border_color:Color
var highlight_border_color:Color = Color(1.0, 1.0, 1.0, 0.1)

@onready var panel_4_7: Panel = $VBoxContainer/Panel_4_7
var panel_4_7_stylebox:StyleBox
@onready var panel_4_8: Panel = $VBoxContainer/Panel_4_8
var panel_4_8_stylebox:StyleBox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_over_4_7 = false
	mouse_over_4_8 = false
	panel_4_7_stylebox = panel_4_7.get_theme_stylebox("panel")
	default_border_color = panel_4_7_stylebox.bg_color
	panel_4_8_stylebox = panel_4_8.get_theme_stylebox("panel")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if mouse_over_4_7 && Input.is_action_just_pressed("deploy_or_roxctl"):
		SignalManager.version_change.emit("4.7")
	elif mouse_over_4_8 && Input.is_action_just_pressed("deploy_or_roxctl"):
		SignalManager.version_change.emit("4.8")

func _on_panel_4_7_mouse_entered() -> void:
	mouse_over_4_7 = true
	panel_4_7_stylebox.bg_color = highlight_border_color


func _on_panel_4_7_mouse_exited() -> void:
	mouse_over_4_7 = false
	panel_4_7_stylebox.bg_color = default_border_color


func _on_panel_4_8_mouse_entered() -> void:
	mouse_over_4_8 = true
	panel_4_8_stylebox.bg_color = highlight_border_color


func _on_panel_4_8_mouse_exited() -> void:
	mouse_over_4_8 = false
	panel_4_8_stylebox.bg_color = default_border_color
