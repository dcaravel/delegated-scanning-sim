extends Control

@export var cluster_name:String = ""
@export var registry_name:String = ""
@export var cloud_text:String = ""
@export var show_cloud:bool = false
@export var highlight_registry:bool = false

var default_cluster_name = "cluster"

func _process(_delta):
	var val = default_cluster_name
	if cluster_name != null && cluster_name.length() > 0:
		val = cluster_name
	%ClusterName.text = val
	
	if registry_name != null && registry_name.length() > 0:
		$Registry.text = registry_name
		$Registry.visible = true
	else:
		$Registry.visible = false
		

	var c = $Cloud
	if show_cloud:
		$Cloud/CloudLabel.text = cloud_text
		c.visible=true
		$Registry.modulate.a = 0.2
	else:
		c.visible=false
		$Registry.modulate.a = 1.0
