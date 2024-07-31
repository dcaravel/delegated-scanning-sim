extends Control
class_name Arch

const MAX_ZINDEX = 10

const metadata_pill_scene = preload("res://pills/metadata_pill_sm.tscn")
const indexreport_pill_scene = preload("res://pills/index_report_pill_sm.tscn")
const vulnreport_pill_scene = preload("res://pills/vuln_report_pill_sm.tscn")
const sig_pill_scene = preload("res://pills/signatures_pill_sm.tscn")
const error_scene = preload("res://error_popup.tscn")
const image_status_mini = preload("res://ImageStatusMini.tscn")

const play_icon = preload("res://assets/play-svgrepo-com-16x16.png")
const pause_icon = preload("res://assets/pause-svgrepo-com-16x16.png")

const version_txt_path = "res://version.txt"

const nil:Callable = Callable()
const _PathSegment = preload("res://scripts/path_segment.gd")
const CENTRAL_CLUSTER_IDX:int = -1

const pill_scenes:Array = [
	metadata_pill_scene,
	indexreport_pill_scene,
	vulnreport_pill_scene,
	sig_pill_scene,
]

enum {MD,IR,VR,SIG}
enum ENABLED_FOR {NONE, ALL, SPECIFIC}

@export var have_metadata:bool = false
@export var have_index_report:bool = false
@export var have_vuln_report:bool = false
@export var have_signatures:bool = false
@export var have_error:bool = false

# maps a cluster index (key) to the names of all the cluster local registries (val)
var cluster_registries = {
	0: ["prod.registry.io"],
	1: ["dev.registry.io"],
}

var cur_path_segment_idx=0

var enabled_for:ENABLED_FOR
var pause_seg:PathSegment
var pausing:bool = false
var pausing_enabled:bool = false

var c1Paths:Node2D = Node2D.new()
var c2Paths:Node2D = Node2D.new()
var cluster_cpaths = {}

var animationPlayers:Array[AnimationPlayer] = []
var animationRegHighlight:String = "highlight-registry"

var initial_log_letter = 64
var last_log_letter:int = initial_log_letter

var done_ready:bool = false

@onready var big_cloud:Node2D = $BigCloud
@onready var big_cloud_label:Label = $BigCloud/BigCloudLabel
@onready var prod_cluster:Control = $ProdCluster
@onready var dev_cluster:Control = $DevCluster
@onready var other_cluster:Control = $OtherCluster
@onready var pause:Path2D = $Paths/pause
@onready var paths:Node2D = $Paths
@onready var c_paths:Node2D = $Paths/cPaths
@onready var speed_slider:HSlider = $FlowControls/SpeedSlider
@onready var forward_step_button = $FlowControls/ForwardStepButton
@onready var back_step_button = $FlowControls/BackStepButton
@onready var pause_play_button = $FlowControls/PausePlayButton
@onready var image_status_zoomed = $ImageStatusZoomed
@onready var delegated_scanning_config = $DelegatedScanningConfig
@onready var c_0_to_central = $"Paths/c0-to-central"
@onready var central_to_c_0 = $"Paths/central-to-c0"
@onready var c_1_to_central = $"Paths/c1-to-central"
@onready var central_to_c_1 = $"Paths/central-to-c1"
@onready var c_2_to_central = $"Paths/c2-to-central"
@onready var central_to_c_2 = $"Paths/central-to-c2"
@onready var central_from_sensor_start = $"Paths/central-from-sensor-start"
@onready var central_error_from_sensor = $"Paths/central-error-from-sensor"
@onready var central_scan_error = $"Paths/central-scan-error"
@onready var central_match = $"Paths/central-match"
@onready var central_scan = $"Paths/central-scan"
@onready var central_roxctl_start = $"Paths/central-roxctl-start"
@onready var central_roxctl_to_central_scan = $"Paths/central-roxctl-to-central-scan"
@onready var central_delegate_error = $"Paths/central-delegate-error"
@onready var central_roxctl_to_cluster = $"Paths/central-roxctl-to-cluster"
@onready var none_radio = $EnabledForRadios/NoneRadio
@onready var all_registries_radio = $EnabledForRadios/AllRegistriesRadio
@onready var dev = $DelegatedScanningConfig/dev
@onready var prod = $DelegatedScanningConfig/prod
@onready var quay = $DelegatedScanningConfig/quay
@onready var default_cluster_option = $DelegatedScanningConfig/DefaultClusterOption
@onready var popup_menu = $PopupMenu
@onready var version_label = $VersionLabel


@onready var cluster_scenes = {
	0: prod_cluster,
	1: dev_cluster,
	2: other_cluster
}

@onready var to_cluster_paths = {
	0: central_to_c_0,
	1: central_to_c_1,
	2: central_to_c_2,
}

@onready var to_central_paths = {
	0: c_0_to_central,
	1: c_1_to_central,
	2: c_2_to_central,
}

# any registries in this dict are cluster local, any others are assumed internet accessable
@onready var local_registries_animates = {
	"prod.registry.io": _prodAnimateCB,
	"dev.registry.io": _devAnimateCB,
}

func get_text_file_content(filePath):
	var file = FileAccess.open(filePath, FileAccess.READ)
	var content = file.get_as_text()
	return content

func _ready():
	version_label.text = "v" + get_text_file_content(version_txt_path)
	# The enum and list of clusters must be the same, otherwise the dropdowns will not match the output
	assert(Global.CLUSTER.size() == Global.CLUSTERS.size())
	
	SignalManager.log_entry_popped.connect(_on_log_entry_pop)
	SignalManager.log_cleared.connect(_on_log_clear)
	SignalManager.deploy_to_cluster.connect(_on_deploy_to_cluster)
	SignalManager.context_menu.connect(_on_context_menu)
	
	for cluster:String in Global.CLUSTERS:
		default_cluster_option.add_item(cluster)

	var apPath:String = "Registry/AnimationPlayer"
	animationPlayers = [
		null,
		prod_cluster.get_node(apPath),
		dev_cluster.get_node(apPath),
		other_cluster.get_node(apPath),
	]
	
	pause_seg = PathSegment.new(pause)
	pause.hide()
	
	big_cloud.hide()
	
	for c in paths.get_children():
		c.show()
	
	for c in c_paths.get_children():
		c.show()
	
	c1Paths = c_paths.duplicate()
	c1Paths.name = "c1Paths"
	c1Paths.position += dev_cluster.position - prod_cluster.position
	paths.add_child(c1Paths)
	
	c2Paths = c_paths.duplicate()
	c2Paths.name = "c2Paths"
	c2Paths.position += other_cluster.position - prod_cluster.position
	paths.add_child(c2Paths)

	cluster_cpaths = {
		0: c_paths,
		1: c1Paths,
		2: c2Paths,
	}
	
	# Set the initial speed value to the slider set in the editor / scene
	_on_speed_slider_value_changed(speed_slider.value)
	_sync_enabled_for_radio()
	#_on_save_test_code_edit_ready()
	done_ready = true
	_reset()

func _reset(soft:bool=false):
	if !done_ready:
		return
		
	Config.set_moving(false)
	cur_path_segment_idx = 0
	have_metadata = false
	have_index_report = false
	have_vuln_report = false
	have_signatures = false
	have_error = false
	
	for segment in Config.active_path():
		segment.reset()

	for a in animationPlayers:
		if a == null:
			continue
		a.stop()
	
	_del_all_log_entry()
	
	if !soft:
		#print_tree_pretty()
		Config.clear_active_path()
		Config.reset_cluster_clicked()
		big_cloud.hide()
		big_cloud_label.text = ""
		for c in cluster_scenes.values():
			c.show_cloud = false

func _errorC(text:String, pos:Global.Pos=Global.Pos.BOT, offsetX:int=0) -> Callable:
	return Callable(self, "_error").bind(text, pos, offsetX)
	
func _error(text:String="ERR", pos:Global.Pos=Global.Pos.BOT, offsetX:int=0) -> Node:
	var err:ErrorPopup = error_scene.instantiate()
	err.LabelText = text
	err.LabelPosition = pos
	err.LabelOffsetX = offsetX
	err.z_index = MAX_ZINDEX
	return err

func _rdot() -> Node:
	var dot = Sprite2D.new()
	dot.name = "_rdot"
	dot.scale = Vector2(0.3, 0.3)
	dot.modulate = Color(255, 0, 0, 1.0)
	dot.texture = preload("res://assets/white-circle.png")
	dot.z_index = MAX_ZINDEX
	return dot

func _pillC(idx:int) -> Callable:
	return Callable(self, "_pill").bind(idx)
	
func _pill(idx:int):
	var pill:Node2D = Node2D.new()
	pill.name = "pill" + str(idx)
	var c = pill_scenes[idx].instantiate()
	pill.add_child(c)
	c.active=true
	c.scale = Vector2(0.5, 0.5)
	c.position = Vector2(-12, -6)
	c.z_index = MAX_ZINDEX
	return pill

func _docker_icon() -> Sprite2D:
	var end_icon = Sprite2D.new()
	end_icon.name = "_docker_icon"
	end_icon.scale = Vector2(0.2, 0.2)
	end_icon.position = Vector2(0, -5)
	end_icon.texture = preload("res://assets/docker-mark-blue.png")
	end_icon.z_index = MAX_ZINDEX
	return end_icon

func _dot() -> Node:
	var dot = Sprite2D.new()
	dot.name = "_dot"
	dot.scale = Vector2(0.3, 0.3)
	var lc:Color = Global.TRAIL_COLOR
	dot.modulate = Color(lc.r, lc.g, lc.b, 1.0)
	dot.texture = preload("res://assets/white-circle.png")
	dot.z_index = MAX_ZINDEX
	return dot

func _image_status() -> ImageStatusMini:
	var dupe = image_status_mini.instantiate()
	dupe.name = "_image_status"
	dupe.have_metadata = have_metadata
	dupe.have_index_report = have_index_report
	dupe.have_vuln_report = have_vuln_report
	dupe.have_signatures = have_signatures
	dupe.have_error = have_error
	
	dupe.position = Vector2(-13, -21)
	dupe.show()
	dupe.z_index = MAX_ZINDEX+1
	return dupe

func _process(delta):
	_sync_image_status()
	
	if cur_path_segment_idx >= Config.active_path().size():
		forward_step_button.disabled = true
	else:
		forward_step_button.disabled = false
		
	if !Config.moving():
		pause_play_button.icon = play_icon
		return
	pause_play_button.icon = pause_icon

	if cur_path_segment_idx >= Config.active_path().size():
		Config.set_moving(false)
		return
	
	var segment:PathSegment = Config.active_path()[cur_path_segment_idx]
	if !pausing_enabled || !pausing:
		if segment.walk(delta):
			pausing = true
			cur_path_segment_idx += 1
	else:
		if pause_seg.walk(delta):
			pausing = false
			pause_seg.reset()

func _sync_image_status():
	image_status_zoomed.have_metadata = have_metadata
	image_status_zoomed.have_index_report = have_index_report
	image_status_zoomed.have_vuln_report = have_vuln_report
	image_status_zoomed.have_signatures = have_signatures
	image_status_zoomed.have_error = have_error


func _sync_enabled_for_radio():
	var group:ButtonGroup = none_radio.button_group
	var button:CheckBox = group.get_pressed_button()
	
	if button == none_radio:
		enabled_for = ENABLED_FOR.NONE
		delegated_scanning_config.hide()
	elif button == all_registries_radio:	
		enabled_for = ENABLED_FOR.ALL
		delegated_scanning_config.show()
	else:
		enabled_for = ENABLED_FOR.SPECIFIC
		delegated_scanning_config.show()
	
	_config_updated()
	
class SegCreator:
	var base:Node
	var dwicon:Callable
	var deicon:Callable
	var dsicon:Callable
	var dtrail:bool = true
	
	func _init(p_base:Node):
		base = p_base
	
	func c(p_name:String) -> PathSegment:
		var n = base.get_node(p_name)
		var ps = PathSegment.new(n)
		ps.wicon(dwicon)
		ps.eicon(deicon)
		ps.sicon(dsicon)
		ps.trail(dtrail)
		return ps
	
	func wicon(p_icon:Callable) -> SegCreator:
		dwicon = p_icon
		return self
	
	func eicon(p_icon:Callable) -> SegCreator:
		deicon = p_icon
		return self
	
	func sicon(p_icon:Callable) -> SegCreator:
		dsicon = p_icon
		return self
	
	func trail(p_trail:bool) -> SegCreator:
		dtrail = p_trail
		return self

# Returns:
# 0 = true if should delegate, false otherwise
# 1 = cluster index to delegate to (for roxctl requests)
# [<delegate>, <cluster>]
func _should_delegate_to_cluster(image:String):
	if enabled_for == ENABLED_FOR.NONE:
		return [false, -1]
	
	# subtracting 1 so that "None" = -1, "prod" = 0, and so on
	var def_cluster_idx = default_cluster_option.selected-1

	var dele_config_regs_list = [dev, prod, quay]
	var cluster_idx = def_cluster_idx
	if enabled_for == ENABLED_FOR.ALL:
		for reg in dele_config_regs_list:
			if !reg.enabled:
				continue # skip this list item if it isn't toggled on

			var reg_path = reg.registry_name
			if image.begins_with(reg_path):
				cluster_idx = def_cluster_idx if reg.selection == 0 else reg.selection-1
				return [true, cluster_idx]

		return [true, cluster_idx]
	
	if enabled_for == ENABLED_FOR.SPECIFIC:
		for reg in dele_config_regs_list:
			if !reg.enabled:
				continue  # skip this list item if it isn't toggled on

			var reg_path = reg.registry_name
			if image.begins_with(reg_path):
				cluster_idx = def_cluster_idx if reg.selection == 0 else reg.selection-1
				return [true, cluster_idx]
		
	return [false, -1]

func _extract_registry(p_image:String) -> String:
	return p_image.get_slice("/", 0)

@onready var central_roxctl_start_sc = SegCreator.new(central_roxctl_start).wicon(_dot).eicon(_dot)
@onready var central_to_central_start_sc = SegCreator.new(central_roxctl_to_central_scan).wicon(_dot).eicon(_dot).trail(false)
@onready var central_scan_cloud_sc = SegCreator.new(central_scan).wicon(_dot)
@onready var central_scan_error_network_sc = SegCreator.new(central_scan_error).wicon(_dot)
@onready var central_scan_error_no_cluster_sc = SegCreator.new(central_delegate_error).wicon(_dot)
@onready var central_passthrough_sc = SegCreator.new(central_roxctl_to_cluster).wicon(_dot).trail(false)
@onready var sensor_to_central_start_sc = SegCreator.new(central_from_sensor_start).wicon(_dot).trail(false)
@onready var central_match_sc = SegCreator.new(central_match).wicon(_dot)
@onready var central_save_error_sc = SegCreator.new(central_error_from_sensor).wicon(_dot)

func _A() -> Array[PathSegment]:
	return [central_roxctl_start_sc.c("a1"),]

func _BQ() -> Array[PathSegment]:
	var cPaths:Node2D = cluster_cpaths[Config.get_cluster_clicked()]

	var sc = SegCreator.new(cPaths.get_node("c0-deploy")).wicon(_dot).eicon(_dot)

	return [
		sc.c("a1"),
		sc.c("a2").trail(false).sicon(nil).eicon(nil),
	]

func _C() -> Array[PathSegment]:
	return [central_to_central_start_sc.c("a1"),]

func _D() -> Array[PathSegment]:
	big_cloud_label.text = _extract_registry(Config.get_active_image())
	big_cloud.show()
	return [
		central_scan_cloud_sc.c("a1").sicon(_dot),
		central_scan_cloud_sc.c("a2").eicon(_pillC(MD)).micon(_midIconCBC("Get metadata from registry"), 40),
		central_scan_cloud_sc.c("a2").reverse().eicon(_pillC(MD)).wicon(_pillC(MD)).onevent(_metadataCB).trail(false),
		central_scan_cloud_sc.c("a3"),
		central_scan_cloud_sc.c("a4").micon(_midIconCBC("Get index report from indexer"), 40),
		central_scan_cloud_sc.c("a5").eicon(_docker_icon).micon(_midIconCBC("Get layers from registry"), 40),
		central_scan_cloud_sc.c("a5").reverse().wicon(_docker_icon).eicon(_pillC(IR)).trail(false),
		central_scan_cloud_sc.c("a4").reverse().wicon(_pillC(IR)).eicon(_pillC(IR)).onevent(_indexReportCB).trail(false),
		central_scan_cloud_sc.c("a6"),
		central_scan_cloud_sc.c("a7").micon(_midIconCBC("Get vuln report from matcher"), 30),
		central_scan_cloud_sc.c("a7_1").micon(_midIconCBC("Get index report from indexer"), 30),
		central_scan_cloud_sc.c("a7_1").reverse().sicon(_pillC(IR)).wicon(_pillC(IR)).trail(false),
		central_scan_cloud_sc.c("a7").reverse().sicon(_pillC(VR)).wicon(_pillC(VR)).eicon(_pillC(VR)).onevent(_vulnReportCB).trail(false),
		central_scan_cloud_sc.c("a8"),
		central_scan_cloud_sc.c("a9").micon(_midIconCBC("Get image signature from registry"), 30),
		central_scan_cloud_sc.c("a9").reverse().sicon(_pillC(SIG)).wicon(_pillC(SIG)).eicon(_pillC(SIG)).onevent(_signatureCB).trail(false),
		central_scan_cloud_sc.c("a10").eicon(_dot),
		central_scan_cloud_sc.c("a11").wicon(_image_status).eicon(_image_status).micon(_midIconCBC("Store final image in DB"), 20),
		central_scan_cloud_sc.c("a11").reverse().trail(false),
		central_scan_cloud_sc.c("a12").wicon(_image_status).eicon(_dot),
	]

func _E() -> Array[PathSegment]:
	var reg = _extract_registry(Config.get_active_image())
	return [
		central_scan_error_network_sc.c("a1").sicon(_dot),
		central_scan_error_network_sc.c("a2").eicon(_errorC("", Global.Pos.TOP)).onevent(local_registries_animates[reg]).micon(_midIconCBC("Fail to get metadata from registry - unreachable"), 20),
		central_scan_error_network_sc.c("a2").wicon(_rdot).reverse().eicon(_rdot).onevent(_errorStatusCB).trail(false),
		central_scan_error_network_sc.c("a3").eicon(_dot).wicon(_rdot),
		central_scan_error_network_sc.c("a4").eicon(_image_status).wicon(_rdot).micon(_midIconCBC("Store scan with error in DB (if no existing image)"), 20),
		central_scan_error_network_sc.c("a5").eicon(_dot),
	]

func _F() -> Array[PathSegment]:
	return [
		central_scan_error_no_cluster_sc.c("a1").sicon(_dot),
		central_scan_error_no_cluster_sc.c("a2").eicon(_errorC("", Global.Pos.TOP)).micon(_midIconCBC("Fail to delegate, no cluster specified"), 20).onevent(_errorStatusCB),
		central_scan_error_no_cluster_sc.c("a3").wicon(_rdot).eicon(_dot),		
	]

func _G() -> Array[PathSegment]:
	return [
		central_passthrough_sc.c("a1"),
	]

func _HQ() -> Array[PathSegment]:
	var dst_cluster:int = _get_dst_cluster()
	var cPaths:Node2D = to_cluster_paths[dst_cluster]
	
	var sc = SegCreator.new(cPaths).wicon(_dot).eicon(_dot).sicon(_dot)
	var offset:int = 50
	if dst_cluster == 1: # middle cluster - shorter offset, assumes only 3 Clusters
		offset = 25

	return [
		sc.c("a1").altcolor().micon(_midIconCBC("Delegate scan to sensor"), offset),
		sc.c("a2").trail(false),
	]

func _I() -> Array[PathSegment]:
	var dst_cluster:int = _get_dst_cluster()
	var cPaths:Node2D = cluster_cpaths[dst_cluster]
	var sc = SegCreator.new(cPaths.get_node("c0-scan-cloud")).wicon(_dot)

	var c = cluster_scenes[dst_cluster]
	c.cloud_text = _extract_registry(Config.get_active_image())
	c.show_cloud = true

	return [
		sc.c("a1").sicon(_dot).wicon(_dot),
		sc.c("a2").eicon(_pillC(MD)).micon(_midIconCBC("Get metadata from registry"), 40),
		sc.c("a2").wicon(_pillC(MD)).reverse().eicon(_pillC(MD)).onevent(_metadataCB).trail(false),
		sc.c("a3"),
		sc.c("a4").micon(_midIconCBC("Get index report from indexer"), 50),
		sc.c("a5").eicon(_docker_icon).micon(_midIconCBC("Get layers from registry"), 40),
		sc.c("a5").wicon(_docker_icon).eicon(_pillC(IR)).reverse().trail(false),
		sc.c("a4").wicon(_pillC(IR)).eicon(_pillC(IR)).reverse().onevent(_indexReportCB).trail(false),
		sc.c("a6"),
		sc.c("a7").eicon(_pillC(SIG)).micon(_midIconCBC("Get image signature from registry"), 80),
		sc.c("a7").wicon(_pillC(SIG)).eicon(_pillC(SIG)).reverse().onevent(_signatureCB).trail(false),
		sc.c("a8").eicon(_dot).micon(_midIconCBC("Send match request to central"), 24),
	]

func _J() -> Array[PathSegment]:
	var dst_cluster:int = _get_dst_cluster()

	var cPaths:Node2D = cluster_cpaths[dst_cluster]
	var sc = SegCreator.new(cPaths.get_node("c0-scan-local")).wicon(_dot)

	return [
		sc.c("a1").sicon(_dot).wicon(_dot),
		sc.c("a2").eicon(_pillC(MD)).micon(_midIconCBC("Get metadata from registry"), 30),
		sc.c("a2").wicon(_pillC(MD)).reverse().eicon(_pillC(MD)).onevent(_metadataCB).trail(false),
		sc.c("a3"),
		sc.c("a4").micon(_midIconCBC("Get index report from indexer"), 60),
		sc.c("a5").eicon(_docker_icon).micon(_midIconCBC("Get layers from registry"), 30),
		sc.c("a5").wicon(_docker_icon).eicon(_pillC(IR)).reverse().trail(false),
		sc.c("a4").wicon(_pillC(IR)).eicon(_pillC(IR)).reverse().onevent(_indexReportCB).trail(false),
		sc.c("a6"),
		sc.c("a7").eicon(_pillC(SIG)).micon(_midIconCBC("Get image signature from registry"), 70),
		sc.c("a7").wicon(_pillC(SIG)).eicon(_pillC(SIG)).reverse().onevent(_signatureCB).trail(false),
		sc.c("a8").eicon(_dot).micon(_midIconCBC("Send match request to central"), 24),
	]

func _K() -> Array[PathSegment]:
	var reg = _extract_registry(Config.get_active_image())
	var dst_cluster:int = _get_dst_cluster()
	var cPaths:Node2D = cluster_cpaths[dst_cluster]
	var sc = SegCreator.new(cPaths.get_node("c0-scan-local-error")).wicon(_dot)

	return [
		sc.c("a1").sicon(_dot),
		sc.c("a2").eicon(_errorC("", Global.Pos.TOP)).micon(_midIconCBC("Fail to get metadata from registry - unreachable"), 20),
		sc.c("a2").reverse().onevent(local_registries_animates[reg]).eicon(_rdot).trail(false),
		sc.c("a3").wicon(_rdot).eicon(_dot).micon(_midIconCBC("Send failure to central"), 100),
	]

func _L() -> Array[PathSegment]:
	var dst_cluster:int = _get_dst_cluster()
	var cPaths:Node2D = cluster_cpaths[dst_cluster]
	var sc = SegCreator.new(cPaths.get_node("c0-scan-central")).wicon(_dot)
	return [
		sc.c("a1").sicon(_dot).eicon(_dot).micon(_midIconCBC("Send scan request to central"), 140),
	]

func _MC() -> Array[PathSegment]:
	var dst_cluster:int =  _get_dst_cluster()
	var cPaths:Node2D = cluster_cpaths[ dst_cluster]
	var toCentralPath:Node2D = to_central_paths[dst_cluster]
	
	var sc = SegCreator.new(toCentralPath).wicon(_dot).eicon(_dot).sicon(_dot)
	var scEnd = SegCreator.new(cPaths.get_node("c0-end")).wicon(_dot).trail(false)

	return [
		scEnd.c("a1"),
		sc.c("a1").wicon(_dot),
		sensor_to_central_start_sc.c("a1"),
	]

func _N() -> Array[PathSegment]:
	return [
		central_match_sc.c("a1").sicon(_dot),
		central_match_sc.c("a2").eicon(_pillC(VR)).micon(_midIconCBC("Get vuln report from matcher"), 30),
		central_match_sc.c("a2").reverse().wicon(_pillC(VR)).eicon(_pillC(VR)).onevent(_vulnReportCB).trail(false),
		central_match_sc.c("a3"),
		central_match_sc.c("a4").sicon(_dot).wicon(_image_status).eicon(_image_status).micon(_midIconCBC("Store final image in DB"), 20),
		central_match_sc.c("a5").wicon(_dot).eicon(_dot),
	]

func _O() -> Array[PathSegment]:
	return [
		central_save_error_sc.c("a1").wicon(_rdot).sicon(_dot),
		central_save_error_sc.c("a2").wicon(_rdot).sicon(_dot).eicon(_image_status).micon(_midIconCBC("Store scan with error in DB (if no existing image)"), 20),
		central_save_error_sc.c("a3").eicon(_dot),
	]

func _P() -> Array[PathSegment]:
	return [
		central_to_central_start_sc.c("b1").wicon(_image_status).eicon(_image_status),
	]

func _Q() -> Array[PathSegment]:
	return [
		central_to_central_start_sc.c("b1").wicon(_image_status).eicon(_image_status),
	]

func _get_dst_cluster() -> int:
	var tmp = _should_delegate_to_cluster(Config.get_active_image())
	var dst_cluster:int = tmp[1]
	if Config.get_cluster_clicked() == -1:
		return dst_cluster
	
	return Config.get_cluster_clicked()

# See docs\research.md for meaning of A, B, C etc.
func _build_path(p_path_num:int) -> Array[PathSegment]: 
	# print("Path: ", p_path_num)
	var path:Array[PathSegment] = []
	match p_path_num:
		1: # scan central cloud
			path.append_array(_A())
			path.append_array(_C())
			path.append_array(_D())
			path.append_array(_P())
		2: # scan central error - no network path
			path.append_array(_A())
			path.append_array(_C())
			path.append_array(_E())
			path.append_array(_P())
		3: # scan central error - no cluster
			path.append_array(_A())
			path.append_array(_C())
			path.append_array(_F())
			path.append_array(_P())
		4: # central to sensor - index via cloud
			path.append_array(_A())
			path.append_array(_G())
			path.append_array(_HQ())
			path.append_array(_I())
			path.append_array(_MC())
			path.append_array(_N())
			path.append_array(_P())
		5: # central to sensor - index via local
			path.append_array(_A())
			path.append_array(_G())
			path.append_array(_HQ())
			path.append_array(_J())
			path.append_array(_MC())
			path.append_array(_N())
			path.append_array(_P())
		6: # central to sensor - error - no network path
			path.append_array(_A())
			path.append_array(_G())
			path.append_array(_HQ())
			path.append_array(_K())
			path.append_array(_MC())
			path.append_array(_O())
			path.append_array(_P())
		7: # sensor deploy - index via cloud
			path.append_array(_BQ())
			path.append_array(_I())
			path.append_array(_MC())
			path.append_array(_N())
		8: # sensor deploy - index via local
			path.append_array(_BQ())
			path.append_array(_J())
			path.append_array(_MC())
			path.append_array(_N())
		9: # sensor deploy - index error - no network path
			path.append_array(_BQ())
			path.append_array(_K())
			path.append_array(_MC())
			path.append_array(_O())
		10: # sensor deploy to central - scan via cloud
			path.append_array(_BQ())
			path.append_array(_L())
			path.append_array(_MC())
			path.append_array(_D())
		11: # sensor deploy to central - scan error - no network path
			path.append_array(_BQ())
			path.append_array(_L())
			path.append_array(_MC())
			path.append_array(_E())

	return path

func _get_path(p_src_cluster_idx:int, p_image:String) -> Array[PathSegment]:
	if p_src_cluster_idx == CENTRAL_CLUSTER_IDX:
		return _get_path_central_start(p_image)
	
	return _get_path_cluster_start(p_src_cluster_idx, p_image)

func _get_path_central_start(image:String) -> Array[PathSegment]:
	var tmp = _should_delegate_to_cluster(image)
	var should_delegate:bool = tmp[0]
	var dst_cluster:int = tmp[1]

	var reg:String = _extract_registry(image)
	var reg_internet_accessable:bool = !local_registries_animates.has(reg)

	if !should_delegate:
		# 01 if reg_internet_accessable else 02
		return _build_path(1) if reg_internet_accessable else _build_path(2)
	
	if dst_cluster == CENTRAL_CLUSTER_IDX:
		return _build_path(3)
	
	if reg_internet_accessable:
		return _build_path(4)
	
	if cluster_registries.has(dst_cluster) && cluster_registries[dst_cluster].has(reg):
		return _build_path(5)

	return _build_path(6)

func _get_path_cluster_start(p_src_cluster_idx:int, image:String) -> Array[PathSegment]:
	var tmp = _should_delegate_to_cluster(image)
	var should_delegate:bool = tmp[0]
	
	var reg:String = _extract_registry(image)
	var reg_internet_accessable:bool = !local_registries_animates.has(reg)

	if !should_delegate:
		# 10 if reg_internet_accessable else 11
		return _build_path(10) if reg_internet_accessable else _build_path(11)
	
	if reg_internet_accessable:
		return _build_path(7)

	if cluster_registries.has(p_src_cluster_idx) && cluster_registries[p_src_cluster_idx].has(reg):
		return _build_path(8)

	return _build_path(9)

func _metadataCB(p_event:Global.Event):
	match p_event:
		Global.Event.END:
			have_metadata = true
		Global.Event.RESET:
			have_metadata = false

func _indexReportCB(p_event:Global.Event):
	match p_event:
		Global.Event.END:
			have_index_report = true
		Global.Event.RESET:
			have_index_report = false

func _vulnReportCB(p_event:Global.Event):
	match p_event:
		Global.Event.END:
			have_vuln_report = true
		Global.Event.RESET:
			have_vuln_report = false

func _signatureCB(p_event:Global.Event):
	match p_event:
		Global.Event.END:
			have_signatures = true
		Global.Event.RESET:
			have_signatures = false

func _errorStatusCB(p_event:Global.Event):
	match p_event:
		Global.Event.END:
			have_error = true
		Global.Event.RESET:
			have_error = false

func _prodAnimateCB(p_event:Global.Event):
	_clusterAnimate(p_event, Global.CLUSTER.PROD)

func _devAnimateCB(p_event:Global.Event):
	_clusterAnimate(p_event, Global.CLUSTER.DEV)
	
func _otherAnimateCB(p_event:Global.Event):
	_clusterAnimate(p_event, Global.CLUSTER.OTHER)

func _clusterAnimate(p_event:Global.Event, p_cluster:Global.CLUSTER=Global.CLUSTER.CENTRAL):
	match p_event:
		Global.Event.START:
			animationPlayers[p_cluster].play(animationRegHighlight)
		Global.Event.END:
			have_error = true			
		Global.Event.RESET:
			animationPlayers[p_cluster].stop()
			have_error = false

func _add_log_entry(p_icon_text:String, p_text:String):
	SignalManager.push_log_entry.emit(p_icon_text, p_text)

func _del_log_entry():
	SignalManager.pop_log_entry.emit()

func _del_all_log_entry():
	SignalManager.clear_log.emit()

# should be one entry here per step in the slider
var walk_speeds_px:Array[float] = [
	10,
	50,
	100,
	250,
	400,
	500,
	600,
	800,
	1000,
	2000,
	10000,
]
func _on_speed_slider_value_changed(value:float):
	Config.update_walk_speed_px(walk_speeds_px[value])

func _on_log_entry_pop():
	last_log_letter -= 1
	if last_log_letter < initial_log_letter:
		last_log_letter = initial_log_letter

func _on_log_clear():
	last_log_letter = initial_log_letter

func _get_next_log_letter() -> String:
	last_log_letter += 1
	return char(last_log_letter)

func _get_last_log_letter() -> String:
	return char(last_log_letter)
	
func _midIconCBC(p_text:String) -> Callable:
	return Callable(self, "_midIconCB").bind(p_text)

func _midIconCB(p_text:String) -> Node:
	var s = preload("res://letter_icon.tscn")
	var i = s.instantiate()
	i.scale = Vector2(0.6, 0.6)
	i.update_icon_text(_get_next_log_letter())
	_add_log_entry(_get_last_log_letter(), p_text)
	return i

func _config_updated():
	# TODO: instead of doing a full reset, perhaps just change the behavior of the flow controls
	_reset()

func _on_prod_config_updated():
	_config_updated()

func _on_dev_config_updated():
	_config_updated()

func _on_quay_config_updated():
	_config_updated()

func _on_default_cluster_option_item_selected(_index):
	_config_updated()

func _on_context_menu(_p_cluster:Global.CLUSTER):
	# disabled in preference # buttons
	#popup_menu.active_cluster = p_cluster
	#popup_menu.position = get_viewport().get_mouse_position()
	#popup_menu.show()
	pass

func _on_none_radio_toggled(_toggled_on):
	_sync_enabled_for_radio()

func _on_all_registries_radio_toggled(_toggled_on):
	_sync_enabled_for_radio()
	
func _on_specific_registries_radio_toggled(_toggled_on):
	_sync_enabled_for_radio()

func _on_back_step_button_pressed():
	Config.set_moving(false)
	if cur_path_segment_idx >= Config.active_path().size():
		cur_path_segment_idx = Config.active_path().size()-1
	var seg:PathSegment
	var progress:float
	
	if Config.active_path().size() == 0:
		return
		
	seg = Config.active_path()[cur_path_segment_idx]
	progress = seg.progress()
	
	seg.reset()
	if cur_path_segment_idx >= 1:
		cur_path_segment_idx -= 1
		
func _on_deploy_to_cluster(p_cluster:Global.CLUSTER):
	_reset()
	
	if !Config.has_images():
		print("ERROR: no images, cannot deploy")
		return
	# print("prepping path for image: ", Config.get_active_image())
	Config.set_cluster_clicked(p_cluster-1)
	# Config.set_active_path(_prep_path(p_cluster, Config.get_active_image()))
	Config.set_active_path(_get_path(p_cluster-1, Config.get_active_image()))
	Config.set_moving(true)

func _on_reset_button_pressed():
	_reset()

func _on_pause_play_button_pressed():
	if !Config.moving() && cur_path_segment_idx >= Config.active_path().size():
		_reset(true)
	
	Config.toggle_moving()

#
#@onready var save_test_code_edit = $SaveTestCodeEdit
#var path:String = "user://savegame.save"
#
#func _on_save_test_code_edit_ready():
	#var file:FileAccess = FileAccess.open(path, FileAccess.READ)
	#if file == null:
		#print("WARN: Loading saved data ", path, ": ", error_string(FileAccess.get_open_error()))
		#return
	#
	#var content = file.get_as_text()
	#save_test_code_edit.text = content
#
#func _on_save_test_code_edit_text_changed():
	#var file:FileAccess = FileAccess.open(path, FileAccess.WRITE)
	#file.store_string(save_test_code_edit.text)
