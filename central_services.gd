extends Control

@onready var overlay = $Overlay
@onready var border = $Border

var mouse_over = false

var default_border_color:Color
var highlight_border_color:Color = Color(1.0, 1.0, 1.0, 1.0)

func _ready():
	default_border_color = border.default_color
	
	overlay.hover_start.connect(_hover_start)
	overlay.hover_end.connect(_hover_end)
	overlay.overlay_visible_text = "Click: Scan selected image"

func _process(_delta):
	if mouse_over && Input.is_action_just_pressed("deploy_or_roxctl"):
		SignalManager.deploy_to_cluster.emit(Global.CLUSTER.CENTRAL)
		
	if mouse_over && Input.is_action_just_pressed("context_menu"):
		SignalManager.context_menu.emit(Global.CLUSTER.CENTRAL)

func _hover_start():
	mouse_over = true
	border.default_color = highlight_border_color
	
func _hover_end():
	mouse_over = false
	border.default_color = default_border_color
