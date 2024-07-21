extends Control

signal config_updated

@export var registry_name = ""
@export var selection = 0
@export var enabled:bool = false

var items = ["Default","prod","dev","other"]

func _ready():
	for i in items.size():
		$Cluster.add_item(items[i])
	
	$Registry.text = registry_name
	$Cluster.select(selection)
	$EnabledSwitch.button_pressed = enabled

func _process(_delta):
	#$Registry.visible = enabled
	#$Cluster.visible = enabled
	$DisabledLabel.visible = !enabled
	$DisabledLabel2.visible = !enabled
	pass

func _on_cluster_item_selected(index):
	selection = index
	config_updated.emit()

func _on_enabled_switch_toggled(toggled_on):
	enabled = toggled_on
	config_updated.emit()
