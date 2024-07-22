extends Control

@export var cluster_name:String = ""
@export var cluster:Global.CLUSTER = Global.CLUSTER.CENTRAL
@export var registry_name:String = ""
@export var cloud_text:String = ""
@export var show_cloud:bool = false
@export var highlight_registry:bool = false

@onready var cluster_name_obj = $Label/ClusterName
@onready var registry = $Registry
@onready var cloud_label = $Cloud/CloudLabel
@onready var cloud = $Cloud
@onready var overlay:ClusterOverlay = $ClusterOverlay

var default_cluster_name = "cluster"
var mouse_over = false

func _ready():
	overlay.hover_start.connect(_hover_start)
	overlay.hover_end.connect(_hover_end)

func _hover_start():
	mouse_over = true
	
func _hover_end():
	mouse_over = false

func _process(_delta):
	var val = default_cluster_name
	if cluster_name != null && cluster_name.length() > 0:
		val = cluster_name
	cluster_name_obj.text = val
	
	if registry_name != null && registry_name.length() > 0:
		registry.text = registry_name
		registry.show()
	else:
		registry.hide()
		
	if show_cloud:
		cloud_label.text = cloud_text
		cloud.show()
		registry.modulate.a = 0.2
	else:
		cloud.hide()
		registry.modulate.a = 1.0
	
	if mouse_over && Input.is_action_just_pressed("deploy_or_roxctl"):
		SignalManager.deploy_to_cluster.emit(cluster)
		print("click ", cluster_name, " -- ", cluster)
	
