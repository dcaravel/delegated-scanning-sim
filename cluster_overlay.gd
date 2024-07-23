extends Label
class_name ClusterOverlay

var mouse_over = false
var overlay_visible_alpha:float
var overlay_visible_text:String

signal hover_start
signal hover_end

func _ready():
	z_index = Global.OVERLAY_ZINDEX
	
	var sb:StyleBoxFlat = get_theme_stylebox("normal")
	add_theme_stylebox_override("normal", sb.duplicate())
	
	overlay_visible_alpha = get_theme_stylebox("normal").bg_color.a
	overlay_visible_text = text
	
	_set_overlay_hidden()

func _process(_delta):
	if !mouse_over:
		_set_overlay_hidden()
	elif Config.is_active_path():
		_set_overlay_visible(false)
	else:
		_set_overlay_visible()

# full == true indicates the overlay should be obviously visible (cover stuff behind)
# otherwise, can display a 'very light' affect to indicate a hover but the contents
# of the cluster control should still be visible
func _set_overlay_visible(full:bool=true):
	if full:
		get_theme_stylebox("normal").bg_color.a = overlay_visible_alpha
		text = overlay_visible_text
	else:
		#get_theme_stylebox("normal").bg_color.a = 0.2
		#text = ""
		_set_overlay_hidden()

func _set_overlay_hidden():
	get_theme_stylebox("normal").bg_color.a = 0.0
	text = ""

func _on_mouse_entered():
	mouse_over = true
	hover_start.emit()

func _on_mouse_exited():
	mouse_over = false
	hover_end.emit()
