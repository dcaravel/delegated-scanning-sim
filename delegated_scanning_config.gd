extends Control

@onready var default_cluster_control = $DefaultClusterControl
@onready var add_registry_box = $AddRegistryBox
@onready var registries_box = $RegistriesBox
@onready var default_cluster_option = $DefaultClusterControl/DefaultClusterOption
@onready var all_registries_desc = $AddRegistryBox/AllRegistriesDesc
@onready var specific_registries_desc = $AddRegistryBox/SpecificRegistriesDesc
@onready var registries: VBoxContainer = $RegistriesBox/Registries
@onready var add_registry_button: Button = $RegistriesBox/AddRegistryButton
@onready var lines: Node2D = $Lines

const _registry_scene = preload("res://registry_real.tscn")

func _ready():
	for cluster:String in Global.CLUSTERS:
		default_cluster_option.add_item(cluster)
		
	default_cluster_control.hide()
	add_registry_box.hide()
	registries_box.hide()
	lines.hide()
	
	add_registry_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	
	SignalManager.dele_scan_config_updated.connect(_on_dele_config_updated)

func _on_default_cluster_option_item_selected(index):
	SignalManager.dele_scan_update_default_cluster.emit(index-1)

func _on_none_radio_pressed():
	SignalManager.dele_scan_update_enabled_for.emit(Global.ENABLED_FOR.NONE)

func _on_all_registries_radio_pressed():
	SignalManager.dele_scan_update_enabled_for.emit(Global.ENABLED_FOR.ALL)

func _on_specific_registries_radio_pressed():
	SignalManager.dele_scan_update_enabled_for.emit(Global.ENABLED_FOR.SPECIFIC)

func _sync_registry_controls() -> void:
	var cfg = Config.get_delegated_scanning_config()
	
	if cfg.get_enabled_for() == Global.ENABLED_FOR.NONE:
		default_cluster_control.hide()
		add_registry_box.hide()
		registries_box.hide()
		lines.hide()
		return
	
	default_cluster_control.show()
	lines.show()
		
	if cfg.get_num_registries() > 0:
		registries_box.show()
		add_registry_box.hide()
		return
	
	registries_box.hide()
	add_registry_box.show()
	if cfg.get_enabled_for() == Global.ENABLED_FOR.ALL:
		all_registries_desc.show()
		specific_registries_desc.hide()
	else:
		all_registries_desc.hide()
		specific_registries_desc.show()

func _on_add_registry_button_pressed() -> void:
	Config.get_delegated_scanning_config().add_registry()

func _on_dele_config_updated():
	var cfg = Config.get_delegated_scanning_config()
	
	if add_registry_button.get_parent() != null:
		add_registry_button.get_parent().remove_child(add_registry_button)
	
	var children_count = registries.get_child_count()
	for idx in cfg.get_num_registries():
		if idx > children_count-1:
			registries.add_child(_create_registry_entry(idx))
			continue
		
		# It's possible as the # of children have shifted they may not have the correct
		# id anymore
		registries.get_child(idx).set_id(idx)

	if children_count > cfg.get_num_registries():
		for idx in children_count - cfg.get_num_registries():
			var c = registries.get_child(registries.get_child_count()-1)
			registries.remove_child(c)
			c.queue_free()
	
	if cfg.get_num_registries() != Global.MAX_DELE_CONFIG_REGISTRIES:
		registries.add_child(add_registry_button)

	_sync_registry_controls()

func _create_registry_entry(p_idx:int) -> Control:
	var r:Control = _registry_scene.instantiate()
	r.set_id(p_idx)

	return r

func _clear_focus(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == 1: # left click
		Config.clear_focus(get_viewport())

func _on_registries_box_gui_input(event: InputEvent) -> void:
	_clear_focus(event)

func _on_color_rect_gui_input(event: InputEvent) -> void:
	_clear_focus(event)

func _on_add_registry_box_gui_input(event: InputEvent) -> void:
	_clear_focus(event)

func _on_default_cluster_control_gui_input(event: InputEvent) -> void:
	_clear_focus(event)
