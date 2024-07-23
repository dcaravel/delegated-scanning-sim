extends MarginContainer

const image_entry_scene = preload("res://image_entry.tscn")

var button_group_res:ButtonGroup = preload("res://theme/image_entry_button_group.tres")
var button_group:ButtonGroup
	
@onready var image_container = $VBoxContainer/ScrollContainer/ImageContainer
@onready var image_name_edit = $VBoxContainer/HBoxContainer/ImageNameEdit

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalManager.images_updated.connect(_update_images)
	SignalManager.active_image_updated.connect(_update_active_image)
	
	#button_group = button_group_res.duplicate()
	#button_group.pressed.connect(_image_selected)

	_update_images()
	
func _update_active_image():
	button_group.get_buttons()[Config.get_active_image_idx()].button_pressed = true
		

func _image_selected(_base_button:BaseButton):
	var pressed = button_group.get_pressed_button()
	#print("button group size: ", button_group.get_buttons().size(), " -- selected button ", _base_button.text, " -- pressed: ", pressed.text)
	for button_idx:int in button_group.get_buttons().size():
		var button = button_group.get_buttons()[button_idx]
		if _base_button == button:
			Config.set_active_image(button_idx)
			return

func _add_image(idx:int, image:String, pressed:bool = false):
	var image_entry:ImageEntry = image_entry_scene.instantiate()
	image_entry.text = image
	image_entry.button_group = button_group
	image_entry.button_pressed = pressed
	image_entry.index = idx
	image_container.add_child(image_entry)

func _update_images():
	if button_group != null:
		button_group.pressed.disconnect(_image_selected)
		button_group = null
	
	button_group = button_group_res.duplicate()
	button_group.pressed.connect(_image_selected)
		
	_clear_images()
	for idx in Config.get_images().size():
		var item = Config.get_images()[idx]
		var pressed = idx == Config.get_active_image_idx()
		_add_image(idx, item, pressed)

func _clear_images():
	while image_container.get_child_count() > 0:
		var last_child:ImageEntry = image_container.get_children()[-1]
		image_container.remove_child(last_child)
		last_child.queue_free()
		last_child = null


func _process(delta):
	pass

func _on_add_image_button_pressed():
	Config.add_image(image_name_edit.text)

func _on_image_name_edit_text_submitted(new_text):
	Config.add_image(new_text)