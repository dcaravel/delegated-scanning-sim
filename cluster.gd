extends Control

@export var cluster_name:String = ""
@export var registry_name:String = ""
@export var cloud_text:String = ""
@export var show_cloud:bool = false
@export var highlight_registry:bool = false

var default_cluster_name = "cluster"

@onready var cluster_name_obj = $Label/ClusterName
@onready var registry = $Registry
@onready var cloud_label = $Cloud/CloudLabel
@onready var cloud = $Cloud

func _process(_delta):
	var val = default_cluster_name
	if cluster_name != null && cluster_name.length() > 0:
		val = cluster_name
	cluster_name_obj.text = val
	
	if registry_name != null && registry_name.length() > 0:
		registry.text = registry_name
		registry.visible = true
	else:
		registry.visible = false
		
	if show_cloud:
		cloud_label.text = cloud_text
		cloud.visible=true
		registry.modulate.a = 0.2
	else:
		cloud.visible=false
		registry.modulate.a = 1.0
