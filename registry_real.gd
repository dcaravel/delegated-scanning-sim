extends Control

@onready var cluster = $Cluster
@onready var registry = $Registry

var _reg_id:int = -1

func _ready():
	# TODO: Make this react to when clusters are changed.
	cluster.add_item("Default")
	for i in range(1, Global.CLUSTERS.size()):
		var clusterStr:String = Global.CLUSTERS[i]
		cluster.add_item(clusterStr)
	
	_sync_view()

func set_id(p_id:int):
	_reg_id = p_id
	
	if cluster != null and registry != null:
		_sync_view()
	
func _sync_view():
	var r = Config.get_delegated_scanning_config().get_registry(_reg_id)
	if r == null:
		return

	# without this check the carat position of the text edit will always be reset to the 0
	if registry.text != r.get_path():
		registry.text = r.get_path()
	
	var idx = r.get_cluster_idx()+1
	if cluster.selected != idx:
		cluster.select(idx)

func _on_cluster_item_selected(index):
	Config.get_delegated_scanning_config().update_registry(_reg_id, registry.text, index-1)
	
func _on_registry_text_changed(p_path:String) -> void:
	Config.get_delegated_scanning_config().update_registry(_reg_id, p_path, cluster.selected-1)

func _on_delete_button_pressed() -> void:
	Config.get_delegated_scanning_config().delete_registry(_reg_id)

func _on_registry_focus_entered() -> void:
	Config.pause_global_num_key_input_processing()

func _on_registry_focus_exited() -> void:
	Config.unpause_global_num_key_input_processing()
