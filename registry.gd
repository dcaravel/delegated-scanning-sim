extends Control

signal config_updated

@export var registry_name = ""
@export var selection = 0
@export var enabled:bool = false

@onready var cluster = $Cluster
@onready var registry = $Registry
@onready var enabled_switch = $EnabledSwitch
@onready var disabled_label = $DisabledLabel
@onready var disabled_label_2 = $DisabledLabel2

func _ready():
	cluster.add_item("Default")
	for i in range(1, Global.CLUSTERS.size()):
		var clusterStr:String = Global.CLUSTERS[i]
		cluster.add_item(clusterStr)
	
	registry.text = registry_name
	cluster.select(selection)
	enabled_switch.button_pressed = enabled

func _process(_delta):
	disabled_label.visible = !enabled
	disabled_label_2.visible = !enabled
	cluster.visible = enabled

func _on_cluster_item_selected(index):
	selection = index
	config_updated.emit()

func _on_enabled_switch_toggled(toggled_on):
	enabled = toggled_on
	config_updated.emit()
