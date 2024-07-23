extends PopupMenu

# So that can create deploy event w/ proper cluster
@export var active_cluster:Global.CLUSTER

func _ready():
	SignalManager.images_updated.connect(_update_images)
	
	for item in Config.get_images():
		add_item(item)

	index_pressed.connect(_on_index_pressed)

func _update_images() -> void:
	clear()
	reset_size()
	if !Config.has_images():
		add_item(Global.NO_IMAGE_AVAIL_ERR)
		set_item_disabled(0, true)
		return
		
	for item in Config.get_images():
		add_item(item)

func _on_index_pressed(index: int):
	Config.set_active_image(index)
	
	SignalManager.deploy_to_cluster.emit(active_cluster)
