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
@onready var border = $Border

var default_cluster_name = "cluster"
var mouse_over = false

var default_border_color:Color
var highlight_border_color:Color = Color(1.0, 1.0, 1.0, 1.0)

func _ready():
	default_border_color = border.default_color
	
	overlay.show()
	overlay.hover_start.connect(_hover_start)
	overlay.hover_end.connect(_hover_end)

func _hover_start():
	mouse_over = true
	border.default_color = highlight_border_color
	
func _hover_end():
	mouse_over = false
	border.default_color = default_border_color

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
		
	if mouse_over && Input.is_action_just_pressed("context_menu"):
		SignalManager.context_menu.emit(cluster)
	
