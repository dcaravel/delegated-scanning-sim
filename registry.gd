extends Control

signal config_updated

@export var registry_name = ""
@export var selection = 0
@export var enabled:bool = false

var items = ["Default","prod","dev","other"]

@onready var cluster = $Cluster
@onready var registry = $Registry
@onready var enabled_switch = $EnabledSwitch
@onready var disabled_label = $DisabledLabel
@onready var disabled_label_2 = $DisabledLabel2

func _ready():
	for i in items.size():
		cluster.add_item(items[i])
	
	registry.text = registry_name
	cluster.select(selection)
	enabled_switch.button_pressed = enabled

func _process(_delta):
	disabled_label.visible = !enabled
	disabled_label_2.visible = !enabled
	pass

func _on_cluster_item_selected(index):
	selection = index
	config_updated.emit()

func _on_enabled_switch_toggled(toggled_on):
	enabled = toggled_on
	config_updated.emit()
