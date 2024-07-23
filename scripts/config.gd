extends Node

##################
## Walking / Moving
##################
var _moving = true

var _walk_by_px:bool = true
var _walk_speed_px:float = 0

func moving() -> bool:
	return _moving

func set_moving(p_moving:bool) -> void:
	_moving = p_moving
	SignalManager.moving_updated.emit()

func toggle_moving() -> void:
	_moving = !_moving
	SignalManager.moving_updated.emit()

func get_walk_speed_px() -> float:
	return _walk_speed_px

func update_walk_speed_px(p_new_speed:float) -> void:
	_walk_speed_px = p_new_speed
	SignalManager.walk_speed_updated.emit()

func walk_by_px() -> bool:
	return _walk_by_px

##################
## Active Path
##################
var _active_path:Array[PathSegment]

func is_active_path() -> bool:
	return _active_path.size() > 0
	
func active_path() -> Array[PathSegment]:
	return _active_path

func clear_active_path() -> void:
	_active_path = []

func set_active_path(p_path:Array[PathSegment]) -> void:
	_active_path = p_path

##################
## Images
##################
var _images:Array[String] = [
	"docker.io/library/nginx:1.25.0",
	"quay.io/rhacs-eng/main:latest",
	"prod.registry.io/hello/world:stable",
	"dev.registry.io/repo/path:2.0",
]
var _default_active_image = 0
var _active_image:int = _default_active_image

func has_images() -> bool:
	return _images.size() > 0
	
func has_image(p_image:String) -> bool:
	for img in _images:
		if img == p_image:
			return true
	
	return false

func get_images() -> Array[String]:
	return _images

func add_image(p_image:String):
	if has_image(p_image):
		return
		
	_images.append(p_image)
	SignalManager.images_updated.emit()

func delete_image(p_idx:int):
	_images.remove_at(p_idx)
	SignalManager.images_updated.emit()
	set_active_image(_active_image) # by calling this with the same index the set_active_image method will sanitize the value

func set_active_image(p_image_idx:int) -> void:
	if _images.size() == 0:
		_active_image = _default_active_image
		return
		
	if p_image_idx < 0:
		_active_image = 0
	elif p_image_idx > _images.size()-1:
		_active_image = _images.size()-1
	else:
		_active_image = p_image_idx
		
	print("Active image: ", _active_image, " ", _images[_active_image], " -- ", _images)
	SignalManager.active_image_updated.emit()

func get_active_image_idx() -> int:
	return _active_image
	
func get_active_image() -> String:
	return _images[_active_image]
