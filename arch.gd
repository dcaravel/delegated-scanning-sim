extends Control
class_name Arch

@export var have_metadata:bool = false
@export var have_index_report:bool = false
@export var have_vuln_report:bool = false
@export var have_signatures:bool = false
@export var have_error:bool = false

const _PathSegment = preload("res://scripts/path_segment.gd")
const _C = preload("res://scripts/constants.gd")

var moving=false
var cur_path_segment_idx=0

var all_path_segments:Array[PathSegment] = []
var active_path:Array[PathSegment]

var walk_by_px:bool = true
var walk_speed_px:float
var max_walk_speed_px:float = 1600.0
var walk_speed_ratio:float = 0.6


const MAX_ZINDEX = 10
const metadata_pill_scene = preload("res://pills/metadata_pill_sm.tscn")
const indexreport_pill_scene = preload("res://pills/index_report_pill_sm.tscn")
const vulnreport_pill_scene = preload("res://pills/vuln_report_pill_sm.tscn")
const sig_pill_scene = preload("res://pills/signatures_pill_sm.tscn")
const image_status_mini = preload("res://ImageStatusMini.tscn")

const play_icon = preload("res://assets/play-svgrepo-com-16x16.png")
const pause_icon = preload("res://assets/pause-svgrepo-com-16x16.png")

const error_scene = preload("res://error_popup.tscn")

const nil:Callable = Callable()

enum ENABLED_FOR {NONE, ALL, SPECIFIC}
enum PATH_SOURCE {CENTRAL, SENSOR_EVENT}

# CLUSTER values MUST match the dropdown in the dele registry config
enum CLUSTER {CENTRAL,PROD,DEV,OTHER}

# REGISTRY and REGISTRIES MUST have same order
enum REGISTRY {DOCKER,QUAY,DEV,PROD}
const REGISTRIES=["docker.io","quay.io","dev","prod"]

var enabled_for:ENABLED_FOR

var line_color:Color = Color("afafff", 1.0)
var line_color_alt:Color = Color("ffff0f", 1.0)

var pause_seg:PathSegment
var pausing:bool = false
var pausing_enabled:bool = false

const pill_scenes:Array = [
	metadata_pill_scene,
	indexreport_pill_scene,
	vulnreport_pill_scene,
	sig_pill_scene,
]

enum {MD,IR,VR,SIG}

var c1Paths:Node2D = Node2D.new()
var c2Paths:Node2D = Node2D.new()
var animationPlayers:Array[AnimationPlayer] = []
var animationRegHighlight:String = "highlight-registry"

var initial_log_letter = 64
var last_log_letter:int = initial_log_letter

func _ready():
	animationPlayers = [
		null,
		$ProdCluster/Registry/AnimationPlayer,
		$DevCluster/Registry/AnimationPlayer,
		$OtherCluster/Registry/AnimationPlayer,
	]
	
	pause_seg = PathSegment.new(self, %pause)
	%pause.visible = false
	
	$BigCloud.visible = false
	
	for c in $Paths.get_children():
		c.visible = true
	
	for c in $Paths/cPaths.get_children():
		c.visible = true
	
	c1Paths = $Paths/cPaths.duplicate()
	c1Paths.name = "c1Paths"
	c1Paths.position += $DevCluster.position - $ProdCluster.position
	$Paths.add_child(c1Paths)
	
	c2Paths = $Paths/cPaths.duplicate()
	c2Paths.name = "c2Paths"
	c2Paths.position += $OtherCluster.position - $ProdCluster.position
	$Paths.add_child(c2Paths)
	
	# Set the initial speed value to the slider set in the editor / scene
	_on_speed_slider_value_changed(%SpeedSlider.value)
	_sync_enabled_for_radio()
	_reset()

func _errorC(text:String, pos:Constants.Pos=Constants.Pos.BOT, offsetX:int=0) -> Callable:
	return Callable(self, "_error").bind(text, pos, offsetX)
	
func _error(text:String="ERR", pos:Constants.Pos=Constants.Pos.BOT, offsetX:int=0) -> Node:
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
	dot.modulate = Color(line_color.r, line_color.g, line_color.b, 1.0)
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
	dupe.visible = true
	dupe.z_index = MAX_ZINDEX+1
	return dupe

func _metadata(v:bool=true) -> Callable:
	return func():have_metadata=v

func _index_report(v:bool=true) -> Callable:
	return func():have_index_report=v

func _vuln_report(v:bool=true) -> Callable:
	return func():have_vuln_report=v

func _signatures(v:bool=true) -> Callable:
	return func():have_signatures=v
	
func _error_status(v:bool=true) -> Callable:
	return func():have_error=v

func _process(delta):
	_sync_image_status()
	
	if cur_path_segment_idx >= active_path.size():
		%ForwardStepButton.disabled = true
	else:
		%ForwardStepButton.disabled = false
		
	if !moving:
		%PausePlayButton.icon = play_icon
		return

	%PausePlayButton.icon = pause_icon
	

	if cur_path_segment_idx >= active_path.size():
		moving = false
		return
	
	var segment:PathSegment = active_path[cur_path_segment_idx]
	if !pausing_enabled || !pausing:
		if segment.walk(delta):
			pausing = true
			cur_path_segment_idx += 1
	else:
		if pause_seg.walk(delta):
			pausing = false
			pause_seg.reset()

func _on_none_radio_toggled(_toggled_on):
	_sync_enabled_for_radio()

func _on_all_registries_radio_toggled(_toggled_on):
	_sync_enabled_for_radio()

func _on_specific_registries_radio_toggled(_toggled_on):
	_sync_enabled_for_radio()

func _sync_image_status():
	$ImageStatusZoomed.have_metadata = have_metadata
	$ImageStatusZoomed.have_index_report = have_index_report
	$ImageStatusZoomed.have_vuln_report = have_vuln_report
	$ImageStatusZoomed.have_signatures = have_signatures
	$ImageStatusZoomed.have_error = have_error

func _reset(soft:bool=false):
	moving = false
	cur_path_segment_idx = 0
	have_metadata = false
	have_index_report = false
	have_vuln_report = false
	have_signatures = false
	have_error = false
	
	for segment in all_path_segments:
		segment.reset()

	for a in animationPlayers:
		if a == null:
			continue
		a.stop()

	if !soft:
		#print_tree_pretty()
		all_path_segments = []
		active_path = []
		$BigCloud.visible = false
		$BigCloud/BigCloudLabel.text = ""
		for c in CLUSTER:
			_cloud(CLUSTER.get(c), -1, -1, false)
		$Images/DockerImage.set_active_button_idx(ImageControl.buttonsIdx.NONE)
		$Images/QuayImage.set_active_button_idx(ImageControl.buttonsIdx.NONE)
		$Images/ProdImage.set_active_button_idx(ImageControl.buttonsIdx.NONE)
		$Images/DevImage.set_active_button_idx(ImageControl.buttonsIdx.NONE)
	
	_del_all_log_entry()
	last_log_letter = initial_log_letter

func _on_back_step_button_pressed():
	var orig_moving = moving
	moving = false
	if cur_path_segment_idx >= active_path.size():
		cur_path_segment_idx = active_path.size()-1
	var seg:PathSegment
	var progress:float
	seg = active_path[cur_path_segment_idx]
	progress = seg.progress()
	
	seg.reset()
	if cur_path_segment_idx >= 1:
		cur_path_segment_idx -= 1

	#if progress > 0.20:
		#seg.reset()
		#print("reset progress > .2: ", cur_path_segment_idx)
	#else:
		#seg.reset()
		#print("reset progress: ", cur_path_segment_idx)
		#if cur_path_segment_idx >= 1:
			#cur_path_segment_idx -= 1
			#active_path[cur_path_segment_idx].reset()
			#print("reset progress (seg >=1): ", cur_path_segment_idx)
	moving = orig_moving

func _sync_enabled_for_radio():
	var group:ButtonGroup = %NoneRadio.button_group
	var button:CheckBox = group.get_pressed_button()
	
	if button == %NoneRadio:
		enabled_for = ENABLED_FOR.NONE
		$DelegatedScanningConfig.visible = false
	elif button == %AllRegistriesRadio:	
		enabled_for = ENABLED_FOR.ALL
		$DelegatedScanningConfig.visible = true
	else:
		enabled_for = ENABLED_FOR.SPECIFIC
		$DelegatedScanningConfig.visible = true
	
func _sync_active_path_from_config():
	pass

# returns true if the image should be scanned by a sensor IF sensor is
# evaluating the request (no worky for central)
func _scan_image_via_cluster(image:String) -> bool:
	if enabled_for == ENABLED_FOR.NONE:
		return false
	
	if enabled_for == ENABLED_FOR.ALL:
		return true
	
	var regs = [%dev, %prod, %quay]	
	for reg in regs:
		if !reg.enabled:
			continue
		var reg_path = reg.registry_name
		if image.begins_with(reg_path):
			return true

	return false

# [<delegate>, <cluster>, <control to highlight>]
func _get_matching_dele_config_entry(image:String):
	if enabled_for == ENABLED_FOR.NONE:
		return [false, 0]
	
	var def_cluster_idx = %DefaultClusterOption.selected	
	print("def_cluster_idx: ", def_cluster_idx)
	print("0: ", %dev.registry_name)
	print("1: ", %prod.registry_name)
	print("2: ", %quay.registry_name)

	var regs = [%dev, %prod, %quay]
	var cluster_idx = def_cluster_idx
	if enabled_for == ENABLED_FOR.ALL:
		for reg in regs:
			if !reg.enabled:
				continue
			var reg_path = reg.registry_name
			if image.begins_with(reg_path):
				cluster_idx = def_cluster_idx if reg.selection == 0 else reg.selection
				return [true, cluster_idx]
		return [true, cluster_idx]
	
	if enabled_for == ENABLED_FOR.SPECIFIC:
		for reg in regs:
			if !reg.enabled:
				continue
			var reg_path = reg.registry_name
			if image.begins_with(reg_path):
				cluster_idx = def_cluster_idx if reg.selection == 0 else reg.selection
				return [true, cluster_idx]
		
	return [false, 0]
	
func _get_registry(image:String) -> REGISTRY:
	for idx in range(0, REGISTRIES.size()):
		if image.begins_with(REGISTRIES[idx]):
			return idx as REGISTRY
		
	return REGISTRY.DOCKER

class SegCreator:
	var base:Node
	var parent:Arch
	var dwicon:Callable
	var deicon:Callable
	var dsicon:Callable
	var dtrail:bool = true
	
	func _init(p_parent:Arch, p_base:Node):
		parent = p_parent
		base = p_base
	
	func c(p_name:String) -> PathSegment:
		var n = base.get_node(p_name)
		var ps = PathSegment.new(parent, n)
		# ps.name = "PathSegment"
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

func _prep_path(src_cluster:CLUSTER, image:String) -> Array[PathSegment]:
	var reg = _get_registry(image)
	var isLocal = _scan_image_via_cluster(image) 
	var resp = _get_matching_dele_config_entry(image)
	# var delegate = resp[0] # if true, and src_cluster == central, should delegate
	var dst_cluster = resp[1] # if src_clsuter == central, this is the cluster to delegate too
	
	var cPaths = $"Paths/cPaths"
	var toCentralPaths = $"Paths/c0-to-central"
	var toClusterPaths = $"Paths/central-to-c0"
	match src_cluster:
		CLUSTER.CENTRAL:
			match dst_cluster:
				CLUSTER.DEV:
					cPaths = c1Paths
					toCentralPaths = $"Paths/c1-to-central"
					toClusterPaths = $"Paths/central-to-c1"
				CLUSTER.OTHER:
					cPaths = c2Paths
					toCentralPaths = $"Paths/c2-to-central"
					toClusterPaths = $"Paths/central-to-c2"
		CLUSTER.DEV:
			cPaths = c1Paths
			toCentralPaths = $"Paths/c1-to-central"
		CLUSTER.OTHER:
			cPaths = c2Paths
			toCentralPaths = $"Paths/c2-to-central"
	
	var scToCentral = SegCreator.new(self, toCentralPaths).wicon(_dot).eicon(_dot).sicon(_dot)
	var scToCluster = SegCreator.new(self, toClusterPaths).wicon(_dot).eicon(_dot).sicon(_dot)

	var scDeloy = SegCreator.new(self, cPaths.get_node("c0-deploy")).wicon(_dot).eicon(_dot)
	var scScanCloud = SegCreator.new(self, cPaths.get_node("c0-scan-cloud")).wicon(_dot)
	var scScanCentral = SegCreator.new(self, cPaths.get_node("c0-scan-central")).wicon(_dot)
	var scScanLocal = SegCreator.new(self, cPaths.get_node("c0-scan-local")).wicon(_dot)
	var scScanLocalError = SegCreator.new(self, cPaths.get_node("c0-scan-local-error")).wicon(_dot).eicon(_dot)
	var scEnd = SegCreator.new(self, cPaths.get_node("c0-end")).wicon(_dot).trail(false)
	var scCentralFromSensorStart = SegCreator.new(self, $"Paths/central-from-sensor-start").wicon(_dot).trail(false)
	
	var scCentralErrorFromSensor = SegCreator.new(self, $"Paths/central-error-from-sensor").wicon(_dot)
	var scCentralError = SegCreator.new(self, $"Paths/central-scan-error").wicon(_dot)
	var scCentralMatch = SegCreator.new(self, $"Paths/central-match").wicon(_dot)
	var scCentralScan = SegCreator.new(self, $"Paths/central-scan").wicon(_dot)
	var scCentralDeploy = SegCreator.new(self, $"Paths/central-roxctl-start").wicon(_dot).eicon(_dot)
	var scCentralToCentralScan = SegCreator.new(self, $"Paths/central-roxctl-to-central-scan").wicon(_dot).eicon(_dot).trail(false)
	var scCentralDelegateError = SegCreator.new(self, $"Paths/central-delegate-error").wicon(_dot)
	var scCentralToCluster = SegCreator.new(self, $"Paths/central-roxctl-to-cluster").wicon(_dot).trail(false)
	
	var path:Array[PathSegment] = []
	
	var pathCentralMatch = [
		scCentralMatch.c("a1").sicon(_dot),
		scCentralMatch.c("a2").eicon(_pillC(VR)).micon(_midIconCBC("Get vuln report from matcher"), 30),
		scCentralMatch.c("a2").reverse().wicon(_pillC(VR)).eicon(_pillC(VR)).onevent(_vulnReportCB).trail(false),
		scCentralMatch.c("a3"),
		scCentralMatch.c("a4").sicon(_dot).wicon(_image_status).eicon(_image_status).micon(_midIconCBC("Store final image in DB"), 20),
		scCentralMatch.c("a5").wicon(_dot).eicon(_dot),
	]
	
	var pathCentralScan = [
		scCentralScan.c("a1").sicon(_dot),
		scCentralScan.c("a2").eicon(_pillC(MD)).micon(_midIconCBC("Get metadata from registry"), 40),
		scCentralScan.c("a2").reverse().eicon(_pillC(MD)).wicon(_pillC(MD)).onevent(_metadataCB).trail(false),
		scCentralScan.c("a3"),
		scCentralScan.c("a4").micon(_midIconCBC("Get index report from indexer"), 40),
		scCentralScan.c("a5").eicon(_docker_icon).micon(_midIconCBC("Get layers from registry"), 40),
		scCentralScan.c("a5").reverse().wicon(_docker_icon).eicon(_pillC(IR)).trail(false),
		scCentralScan.c("a4").reverse().wicon(_pillC(IR)).eicon(_pillC(IR)).onevent(_indexReportCB).trail(false),
		scCentralScan.c("a6"),
		scCentralScan.c("a7").micon(_midIconCBC("Get vuln report from matcher"), 30),
		scCentralScan.c("a7_1").micon(_midIconCBC("Get index report from indexer"), 30),
		scCentralScan.c("a7_1").reverse().sicon(_pillC(IR)).wicon(_pillC(IR)).trail(false),
		scCentralScan.c("a7").reverse().sicon(_pillC(VR)).wicon(_pillC(VR)).eicon(_pillC(VR)).onevent(_vulnReportCB).trail(false),
		scCentralScan.c("a8"),
		scCentralScan.c("a9").micon(_midIconCBC("Get image signature from registry"), 30),
		scCentralScan.c("a9").reverse().sicon(_pillC(SIG)).wicon(_pillC(SIG)).eicon(_pillC(SIG)).onevent(_signatureCB).trail(false),
		scCentralScan.c("a10").eicon(_dot),
		scCentralScan.c("a11").wicon(_image_status).eicon(_image_status).micon(_midIconCBC("Store final image in DB"), 20),
		scCentralScan.c("a11").reverse().trail(false),
		scCentralScan.c("a12").wicon(_image_status).eicon(_dot),
	]
	
	var regErrorAnimate = nil
	if reg == REGISTRY.DEV:
		regErrorAnimate = _devAnimateCB
	elif reg == REGISTRY.PROD:
		regErrorAnimate = _prodAnimateCB
	
	var pathCentralScanError = [
		## Scan In Central - Cannot reach Registry
		scCentralError.c("a1").sicon(_dot),
		scCentralError.c("a2").eicon(_errorC("", Constants.Pos.TOP)).onevent(regErrorAnimate).micon(_midIconCBC("Fail to get metadata from registry - unreachable"), 20),
		scCentralError.c("a2").wicon(_rdot).reverse().eicon(_rdot).onevent(_errorStatusCB).trail(false),
		scCentralError.c("a3").eicon(_dot).wicon(_rdot),
		scCentralError.c("a4").eicon(_image_status).wicon(_rdot).micon(_midIconCBC("Store scan with error in DB (if no existing image)"), 20),
		scCentralError.c("a5").eicon(_dot),
	]
	
	var pathScanLocal = [
		scScanLocal.c("a1").sicon(_dot).wicon(_dot),
		scScanLocal.c("a2").eicon(_pillC(MD)).micon(_midIconCBC("Get metadata from registry"), 30),
		scScanLocal.c("a2").wicon(_pillC(MD)).reverse().eicon(_pillC(MD)).onevent(_metadataCB).trail(false),
		scScanLocal.c("a3"),
		scScanLocal.c("a4").micon(_midIconCBC("Get index report from indexer"), 60),
		scScanLocal.c("a5").eicon(_docker_icon).micon(_midIconCBC("Get layers from registry"), 30),
		scScanLocal.c("a5").wicon(_docker_icon).eicon(_pillC(IR)).reverse().trail(false),
		scScanLocal.c("a4").wicon(_pillC(IR)).eicon(_pillC(IR)).reverse().onevent(_indexReportCB).trail(false),
		scScanLocal.c("a6"),
		scScanLocal.c("a7").eicon(_pillC(SIG)).micon(_midIconCBC("Get image signature from registry"), 70),
		scScanLocal.c("a7").wicon(_pillC(SIG)).eicon(_pillC(SIG)).reverse().onevent(_signatureCB).trail(false),
		scScanLocal.c("a8").eicon(_dot).micon(_midIconCBC("Send match request to central"), 24),
		
		scEnd.c("a1"),
		scToCentral.c("a1").wicon(_image_status),
		scCentralFromSensorStart.c("a1"),
	]
	pathScanLocal.append_array(pathCentralMatch)
	
	var pathScanLocalError = [
		## Scan In Sensor - Cannot reach Registry
		scScanLocalError.c("a1").sicon(_dot),
		scScanLocalError.c("a2").eicon(_errorC("", Constants.Pos.TOP)).micon(_midIconCBC("Fail to get metadata from registry - unreachable"), 20),
		scScanLocalError.c("a2").reverse().onevent(regErrorAnimate).eicon(_rdot).trail(false),
		scScanLocalError.c("a3").wicon(_rdot).eicon(_dot).micon(_midIconCBC("Send failure to central"), 100),
		
		scEnd.c("a1"),
		scToCentral.c("a1").wicon(_error),
		scCentralFromSensorStart.c("a1"),
		
		scCentralErrorFromSensor.c("a1").wicon(_rdot).sicon(_dot),
		scCentralErrorFromSensor.c("a2").wicon(_rdot).sicon(_dot).eicon(_image_status).micon(_midIconCBC("Store scan with error in DB (if no existing image)"), 20),
		scCentralErrorFromSensor.c("a3").eicon(_dot),
	]

	if !isLocal: # Scan handled by central regardless of where flow starts
		_displayBigCloud(reg)
		
		if src_cluster == CLUSTER.CENTRAL:
			path.append_array([
				scCentralDeploy.c("a1"),
				
				scCentralToCentralScan.c("a1"),
			])
		else:
			path.append_array([
				scDeloy.c("a1"),
				scDeloy.c("a2").trail(false).sicon(nil).eicon(nil),
				
				scScanCentral.c("a1").sicon(_dot).eicon(_dot).micon(_midIconCBC("Send scan request to central"), 140),
				
				scEnd.c("a1"),
				scToCentral.c("a1").wicon(_dot),
				scCentralFromSensorStart.c("a1"),
			])
		
		if reg == REGISTRY.DOCKER || reg == REGISTRY.QUAY:
			path.append_array(pathCentralScan)
		else:
			path.append_array(pathCentralScanError)
		
		if src_cluster == CLUSTER.CENTRAL:
			path.append_array([
				scCentralToCentralScan.c("b1").wicon(_image_status).eicon(_image_status),
			])
		return path
	
	if src_cluster == CLUSTER.CENTRAL:
		path.append_array([
			scCentralDeploy.c("a1")
		])
		if dst_cluster == CLUSTER.CENTRAL:
			path.append_array([
				scCentralToCentralScan.c("a1"),
				
				scCentralDelegateError.c("a1").sicon(_dot),
				scCentralDelegateError.c("a2").eicon(_errorC("", Constants.Pos.TOP)).micon(_midIconCBC("Fail to delegate, no cluster specified"), 20),
				scCentralDelegateError.c("a3").wicon(_rdot).eicon(_dot),
				
				scCentralToCentralScan.c("b1").wicon(_rdot).eicon(_errorC("", Constants.Pos.BOT, 10)),
			])
			return path
		
		var offset:int = 50
		if dst_cluster ==CLUSTER.DEV:
			offset = 25
		path.append_array([
			scCentralToCluster.c("a1"),
			scToCluster.c("a1").altcolor().micon(_midIconCBC("Delegate scan to sensor"), offset),
			scToCluster.c("a2").trail(false),
		])
	else:
		path.append_array([
			scDeloy.c("a1"),
			scDeloy.c("a2").trail(false).sicon(nil).eicon(nil),
		])
	
	if reg == REGISTRY.DEV:
		if src_cluster == CLUSTER.DEV || (src_cluster == CLUSTER.CENTRAL && dst_cluster == CLUSTER.DEV):
			path.append_array(pathScanLocal)
		else:
			path.append_array(pathScanLocalError)

		return path
	
	if reg == REGISTRY.PROD:
		if src_cluster == CLUSTER.PROD || (src_cluster == CLUSTER.CENTRAL && dst_cluster == CLUSTER.PROD):
			path.append_array(pathScanLocal)
		else:
			path.append_array(pathScanLocalError)
			
		return path
	
	if reg == REGISTRY.DOCKER || reg == REGISTRY.QUAY:
		# c0-scan-cloud
		_cloud(src_cluster, dst_cluster, reg)
		path.append_array([
			scScanCloud.c("a1").sicon(_dot).wicon(_dot),
			scScanCloud.c("a2").eicon(_pillC(MD)).micon(_midIconCBC("Get metadata from registry"), 40),
			scScanCloud.c("a2").wicon(_pillC(MD)).reverse().eicon(_pillC(MD)).onevent(_metadataCB).trail(false),
			scScanCloud.c("a3"),
			scScanCloud.c("a4").micon(_midIconCBC("Get index report from indexer"), 50),
			scScanCloud.c("a5").eicon(_docker_icon).micon(_midIconCBC("Get layers from registry"), 40),
			scScanCloud.c("a5").wicon(_docker_icon).eicon(_pillC(IR)).reverse().trail(false),
			scScanCloud.c("a4").wicon(_pillC(IR)).eicon(_pillC(IR)).reverse().onevent(_indexReportCB).trail(false),
			scScanCloud.c("a6"),
			scScanCloud.c("a7").eicon(_pillC(SIG)).micon(_midIconCBC("Get image signature from registry"), 80),
			scScanCloud.c("a7").wicon(_pillC(SIG)).eicon(_pillC(SIG)).reverse().onevent(_signatureCB).trail(false),
			scScanCloud.c("a8").eicon(_dot).micon(_midIconCBC("Send match request to central"), 24),
			
			scEnd.c("a1"),
			scToCentral.c("a1").wicon(_image_status),
			scCentralFromSensorStart.c("a1"),
		])
		path.append_array(pathCentralMatch)
		
		return path

	return path

func _metadataCB(p_event:Constants.Event):
	match p_event:
		Constants.Event.END:
			have_metadata = true
		Constants.Event.RESET:
			have_metadata = false

func _indexReportCB(p_event:Constants.Event):
	match p_event:
		Constants.Event.END:
			have_index_report = true
		Constants.Event.RESET:
			have_index_report = false

func _vulnReportCB(p_event:Constants.Event):
	match p_event:
		Constants.Event.END:
			have_vuln_report = true
		Constants.Event.RESET:
			have_vuln_report = false

func _signatureCB(p_event:Constants.Event):
	match p_event:
		Constants.Event.END:
			have_signatures = true
		Constants.Event.RESET:
			have_signatures = false

func _errorStatusCB(p_event:Constants.Event):
	match p_event:
		Constants.Event.END:
			have_error = true
		Constants.Event.RESET:
			have_error = false

func _prodAnimateCB(p_event:Constants.Event):
	_clusterAnimate(p_event, CLUSTER.PROD)

func _devAnimateCB(p_event:Constants.Event):
	_clusterAnimate(p_event, CLUSTER.DEV)
	
func _otherAnimateCB(p_event:Constants.Event):
	_clusterAnimate(p_event, CLUSTER.OTHER)

func _clusterAnimate(p_event:Constants.Event, p_cluster:CLUSTER=CLUSTER.CENTRAL):
	match p_event:
		Constants.Event.START:
			animationPlayers[p_cluster].play(animationRegHighlight)
		Constants.Event.END:
			have_error = true			
		Constants.Event.RESET:
			animationPlayers[p_cluster].stop()
			have_error = false

func _cloudC(p_cluster:CLUSTER, p_reg:REGISTRY, p_show:bool=true):
	return Callable(self, "_cloud").bind(p_cluster, p_reg, p_show)

func _cloud(p_src_cluster:CLUSTER, p_dst_cluster:CLUSTER, p_reg:REGISTRY, p_show:bool=true):
	
	var c
	match p_src_cluster:
		CLUSTER.CENTRAL:
			match p_dst_cluster:
				CLUSTER.PROD:
					c = $ProdCluster
				CLUSTER.DEV:
					c = $DevCluster
				CLUSTER.OTHER:
					c = $OtherCluster
				_:
					return
		CLUSTER.PROD:
			c = $ProdCluster
		CLUSTER.DEV:
			c = $DevCluster
		CLUSTER.OTHER:
			c = $OtherCluster
		_:
			return
	
	c.cloud_text = REGISTRIES[p_reg]
	c.show_cloud = p_show

func _displayBigCloud(reg:REGISTRY):
	if reg == REGISTRY.DOCKER || reg == REGISTRY.QUAY:
		$BigCloud/BigCloudLabel.text = REGISTRIES[reg]
		$BigCloud.visible = true
		
func _doDeploy(cluster:CLUSTER, image:ImageControl, buttonIdx:ImageControl.buttonsIdx):
	_reset()
	image.set_active_button_idx(buttonIdx)
	active_path = _prep_path(cluster, image.image_reference)
	moving = true

func _on_docker_image_prod_pressed():
	_doDeploy(CLUSTER.PROD, %DockerImage, ImageControl.buttonsIdx.PROD)
func _on_prod_image_prod_pressed():
	_doDeploy(CLUSTER.PROD, %ProdImage, ImageControl.buttonsIdx.PROD)
func _on_dev_image_prod_pressed():
	_doDeploy(CLUSTER.PROD, %DevImage, ImageControl.buttonsIdx.PROD)
func _on_quay_image_prod_pressed():
	_doDeploy(CLUSTER.PROD, %QuayImage, ImageControl.buttonsIdx.PROD)

func _on_docker_image_dev_pressed():
	_doDeploy(CLUSTER.DEV, %DockerImage, ImageControl.buttonsIdx.DEV)
func _on_prod_image_dev_pressed():
	_doDeploy(CLUSTER.DEV, %ProdImage, ImageControl.buttonsIdx.DEV)
func _on_dev_image_dev_pressed():
	_doDeploy(CLUSTER.DEV, %DevImage, ImageControl.buttonsIdx.DEV)
func _on_quay_image_dev_pressed():
	_doDeploy(CLUSTER.DEV, %QuayImage, ImageControl.buttonsIdx.DEV)

func _on_docker_image_other_pressed():
	_doDeploy(CLUSTER.OTHER, %DockerImage, ImageControl.buttonsIdx.OTHER)
func _on_prod_image_other_pressed():
	_doDeploy(CLUSTER.OTHER, %ProdImage, ImageControl.buttonsIdx.OTHER)
func _on_dev_image_other_pressed():
	_doDeploy(CLUSTER.OTHER, %DevImage, ImageControl.buttonsIdx.OTHER)
func _on_quay_image_other_pressed():
	_doDeploy(CLUSTER.OTHER, %QuayImage, ImageControl.buttonsIdx.OTHER)

func _on_docker_image_roxctl_pressed():
	_doDeploy(CLUSTER.CENTRAL, %DockerImage, ImageControl.buttonsIdx.ROXCTL)
func _on_prod_image_roxctl_pressed():
	_doDeploy(CLUSTER.CENTRAL, %ProdImage, ImageControl.buttonsIdx.ROXCTL)
func _on_dev_image_roxctl_pressed():
	_doDeploy(CLUSTER.CENTRAL, %DevImage, ImageControl.buttonsIdx.ROXCTL)
func _on_quay_image_roxctl_pressed():
	_doDeploy(CLUSTER.CENTRAL, %QuayImage, ImageControl.buttonsIdx.ROXCTL)

func _on_reset_button_pressed():
	_reset()

func _on_pause_play_button_pressed():
	if !moving && cur_path_segment_idx >= active_path.size():
		_reset(true)
	
	moving = !moving

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
func _on_speed_slider_value_changed(value):
	walk_by_px = true
	walk_speed_px = walk_speeds_px[value]

func _add_log_entry(p_icon_text:String, p_text:String):
	%LogPanel.add(p_icon_text, p_text)

func _del_log_entry():
	var r = %LogPanel.del()
	if r:
		last_log_letter -= 1

func _del_all_log_entry():
	%LogPanel.delAll()

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

