extends Node

func _init():
	SignalManager.dele_scan_update_enabled_for.connect(_on_enabled_for_updated)
	SignalManager.dele_scan_update_default_cluster.connect(_on_default_cluster_updated)

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
	"quay.io/rhacs-eng/main:latest",
	"prod.registry.io/hello/world:stable",
	"dev.reg.local/repo/path:2.0",
]
var _max_images_size = 5
var _default_active_image = 0
var _active_image_idx:int = _default_active_image

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
	p_image = p_image.strip_edges()
	
	if p_image.is_empty():
		return
		
	if has_image(p_image):
		return
		
	if _images.size() >= _max_images_size:
		return

	_images.append(p_image)
	SignalManager.images_updated.emit()

func delete_image(p_idx:int):
	_images.remove_at(p_idx)

	if _active_image_idx > _images.size()-1:
		_active_image_idx = _images.size()-1

	SignalManager.images_updated.emit()
	set_active_image(_active_image_idx)

func set_active_image(p_image_idx:int) -> void:
	if _images.size() == 0:
		_active_image_idx = _default_active_image
		return

	if p_image_idx > _images.size()-1:
		# do nothing if trying to set an index > max
		return

	if p_image_idx < 0:
		_active_image_idx = 0
	else:
		_active_image_idx = p_image_idx
		
	# print("Active image: ", _active_image, " ", _images[_active_image], " -- ", _images)
	SignalManager.active_image_updated.emit()

func get_active_image_idx() -> int:
	return _active_image_idx
	
func get_active_image() -> String:
	return _images[_active_image_idx]

func at_max_images() -> bool:
	return _images.size() == _max_images_size

#########################
## Current Cluster Click #TODO: Find better name for this
#########################

var _cluster_clicked:int=-1

func set_cluster_clicked(p_cluster_idx:int):
	if p_cluster_idx < -1:
		# Central is -1, can't go below that
		p_cluster_idx = -1
		return
	

	# TODO: Add list of clusters to global config when ready
	# if p_cluster_idx > cluster_list.size():
		# return

	_cluster_clicked = p_cluster_idx

func get_cluster_clicked() -> int:
	return _cluster_clicked

func reset_cluster_clicked() -> void:
	_cluster_clicked = -1

#########################
## Input?
#########################

var keyToAction = {
	KEY_1: Callable(self, "_handleNumKey").bind(0),
	KEY_2: Callable(self, "_handleNumKey").bind(1),
	KEY_3: Callable(self, "_handleNumKey").bind(2),
	KEY_4: Callable(self, "_handleNumKey").bind(3),
	KEY_5: Callable(self, "_handleNumKey").bind(4),
	KEY_6: Callable(self, "_handleNumKey").bind(5),
	KEY_7: Callable(self, "_handleNumKey").bind(6),
	KEY_8: Callable(self, "_handleNumKey").bind(7),
	KEY_9: Callable(self, "_handleNumKey").bind(8),
}

var _key_input_paused:bool = false

func pause_global_num_key_input_processing() -> void:
	_key_input_paused = true

func unpause_global_num_key_input_processing() -> void:
	_key_input_paused = false

func _handleNumKey(p_num:int) -> void:
	if !_key_input_paused:
		set_active_image(p_num)

func _input(event:InputEvent):
	if event is InputEventKey and event.pressed and keyToAction.has(event.keycode):
		keyToAction[event.keycode].call()

func clear_focus(v:Viewport) -> void:
	var c = v.gui_get_focus_owner()
	if c == null:
		return
	c.release_focus()

#########################
## DelegatedScanningConfig
#########################

# The default cluster IDX that represents 'None' (if Central scan) or 'Default' (if sensor deploy) 
var _delegated_scanning_config:DelegatedScanningConfig = DelegatedScanningConfig.new()

func get_delegated_scanning_config() -> DelegatedScanningConfig:
	return _delegated_scanning_config

func _on_enabled_for_updated(p_enabled_for:Global.ENABLED_FOR):
	_delegated_scanning_config.set_enabled_for(p_enabled_for)
	SignalManager.dele_scan_config_updated.emit()

func _on_default_cluster_updated(p_idx:int):
	print("Default Cluster ID updated via signal: ", p_idx)
	_delegated_scanning_config.set_default_cluster_idx(p_idx)
	SignalManager.dele_scan_config_updated.emit()

class DelegatedScanningConfig:
	var _enabled_for:Global.ENABLED_FOR
	var _registries:Array[Global.Registry]
	var _default_cluster_idx:int

	func _init():
		_default_cluster_idx = -1
	
	func _is_valid_registry_idx(p_idx:int) -> bool:
		if p_idx < 0:
			return false
			
		if p_idx > _registries.size()-1:
			return false
			
		return true
	
	func get_enabled_for() -> Global.ENABLED_FOR:
		return _enabled_for
	
	func get_registries() -> Array[Global.Registry]:
		return _registries
	
	func get_num_registries() -> int:
		return _registries.size()
	
	func get_registry(p_idx:int) -> Global.Registry:
		if !_is_valid_registry_idx(p_idx):
			return null
			
		return _registries[p_idx]
	
	func get_default_cluster() -> int:
		return _default_cluster_idx
	
	func set_default_cluster_idx(p_idx:int) -> void:
		# TODO: add validation?
		_default_cluster_idx = p_idx
		SignalManager.dele_scan_config_updated.emit()

	func set_enabled_for(p_enabled_for:Global.ENABLED_FOR) -> void:
		_enabled_for = p_enabled_for
		SignalManager.dele_scan_config_updated.emit()

	func add_registry(p_path:String="", p_cluster_idx:int=Global.CENTRAL_CLUSTER_IDX) -> bool:
		if _registries.size() == Global.MAX_DELE_CONFIG_REGISTRIES:
			return false

		_registries.append(Global.Registry.new(p_path, p_cluster_idx))
		SignalManager.dele_scan_config_updated.emit()
		return true

	func update_registry(p_idx:int, p_path:String, p_cluster_idx:int=-1):
		if !_is_valid_registry_idx(p_idx):
			return null
		
		_registries[p_idx] = Global.Registry.new(p_path, p_cluster_idx)
		SignalManager.dele_scan_config_updated.emit()


	func delete_registry(p_idx:int) -> bool:
		if p_idx < 0:
			return false
		
		if p_idx >= get_num_registries():
			return false

		_registries.remove_at(p_idx)
		SignalManager.dele_scan_config_updated.emit()
		return true

class ShouldDelegateResult:
	var _should:bool
	var _dst_cluster:int

	func _init(p_should:bool, p_cluster_idx:int):
		_should = p_should
		_dst_cluster = p_cluster_idx
	
	func should_delegate() -> bool:
		return _should
	
	func dst_cluster() -> int:
		return _dst_cluster

func should_delegate(p_image:String) -> ShouldDelegateResult:
	var c:DelegatedScanningConfig = get_delegated_scanning_config()
	var e_for:Global.ENABLED_FOR = c.get_enabled_for()

	if e_for == Global.ENABLED_FOR.NONE:
		return ShouldDelegateResult.new(false, -1)

	if e_for == Global.ENABLED_FOR.ALL:
		for reg:Global.Registry in c.get_registries():
			if reg.match(p_image):
				var cluster_idx = c.get_default_cluster() if reg.get_cluster_idx() == Global.CENTRAL_CLUSTER_IDX else reg.get_cluster_idx()
				return ShouldDelegateResult.new(true, cluster_idx)
		
		return ShouldDelegateResult.new(true, c.get_default_cluster())
	
	if e_for == Global.ENABLED_FOR.SPECIFIC:
		for reg:Global.Registry in c.get_registries():
			if reg.match(p_image):
				var cluster_idx = c.get_default_cluster() if reg.get_cluster_idx() == Global.CENTRAL_CLUSTER_IDX else reg.get_cluster_idx()
				return ShouldDelegateResult.new(true, cluster_idx)
	

	return ShouldDelegateResult.new(false, -1)
