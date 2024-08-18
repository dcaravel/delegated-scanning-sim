extends Control

@export var _have_metadata:bool = false
@export var _have_index_report:bool = false
@export var _have_vuln_report:bool = false
@export var _have_signatures:bool = false
@export var _have_sigverification:bool = false
@export var _have_error:bool = false

var inactive_color = Color("ffffff1e")
var inactive_stylebox = preload("res://theme/panel/inactive.stylebox")
var inactive_left_stylebox = preload("res://theme/panel/inactive_left.stylebox")
var inactive_right_stylebox = preload("res://theme/panel/inactive_right.stylebox")
var metadata_stylebox = preload("res://theme/panel/metadata.stylebox")
var index_report_stylebox = preload("res://theme/panel/indexreport.stylebox")
var vuln_report_stylebox = preload("res://theme/panel/vulnreport.stylebox")
var signatures_stylebox = preload("res://theme/panel/signatures.stylebox")
var signature_verification_stylebox = preload("res://theme/panel/signature_verification.stylebox")

@onready var error_label = $ErrorLabel
@onready var metadata_pill = $MetadataPill
@onready var index_report_pill = $IndexReportPill
@onready var vuln_report_pill = $VulnReportPill
@onready var signatures_pill = $SignaturesPill
@onready var signature_verification_pill = $SignatureVerificationPill
@onready var animation_player = $AnimationPlayer
@onready var scan_label = $ScanLabel

enum STATE {IDLE, ANIMATING}
var state:STATE = STATE.IDLE

func _sync_state():

	metadata_pill.add_theme_stylebox_override("normal", metadata_stylebox if _have_metadata else inactive_stylebox)
	_update_font(metadata_pill, _have_metadata)
	signatures_pill.add_theme_stylebox_override("normal",  signatures_stylebox if _have_signatures else inactive_stylebox)
	_update_font(signatures_pill, _have_signatures)
	signature_verification_pill.add_theme_stylebox_override("normal",  signature_verification_stylebox if _have_sigverification else inactive_stylebox)
	_update_font(signature_verification_pill, _have_sigverification)
	error_label.visible = _have_error
	
	if state == STATE.IDLE:
		index_report_pill.add_theme_stylebox_override("normal", index_report_stylebox if _have_index_report else inactive_left_stylebox)
		_update_font(index_report_pill, _have_index_report)
		vuln_report_pill.add_theme_stylebox_override("normal",  vuln_report_stylebox if _have_vuln_report else inactive_right_stylebox)
		_update_font(vuln_report_pill, _have_vuln_report)
	
func have_metadata(val:bool=true):
	if val == _have_metadata:
		return
	_have_metadata = val
	_sync_state()


func have_index_report(val:bool=true):
	if val == _have_index_report:
		return
	_have_index_report = val
	_sync_state()


func have_vuln_report(val:bool=true):
	if val == _have_vuln_report:
		return
	_have_vuln_report = val
	
	if val == true && state == STATE.IDLE:
		_sync_state()
		state = STATE.ANIMATING
		animation_player.play("doscan")
		return
	
	if val == false:
		animation_player.stop()
		state = STATE.IDLE
	
	_sync_state()

func have_signatures(val:bool=true):
	if val == _have_signatures:
		return
	_have_signatures = val
	_sync_state()

	
func have_sigverification(val:bool=true):
	if val == _have_sigverification:
		return
	_have_sigverification = val
	_sync_state()

	
func have_error(val:bool=true):
	if val == _have_error:
		return
	_have_error = val
	_sync_state()	

func _ready():
	_sync_state()
	#_on_animation_player_animation_finished("doscan")
	

func _update_font(control, cond):
	if cond:
		control.remove_theme_color_override("font_color")
	else:
		control.add_theme_color_override("font_color", inactive_color)
