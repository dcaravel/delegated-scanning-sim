@tool
extends Control


@export var have_metadata:bool = false
@export var have_index_report:bool = false
@export var have_vuln_report:bool = false
@export var have_signatures:bool = false
@export var have_sigverification:bool = false
@export var have_error:bool = false

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


# Called when the node enters the scene tree for the first time.
func _ready():
	error_label.visible = have_error

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	metadata_pill.add_theme_stylebox_override("normal", metadata_stylebox if have_metadata else inactive_stylebox)
	index_report_pill.add_theme_stylebox_override("normal", index_report_stylebox if have_index_report else inactive_left_stylebox)
	vuln_report_pill.add_theme_stylebox_override("normal",  vuln_report_stylebox if have_vuln_report else inactive_right_stylebox)
	signatures_pill.add_theme_stylebox_override("normal",  signatures_stylebox if have_signatures else inactive_stylebox)
	signature_verification_pill.add_theme_stylebox_override("normal",  signature_verification_stylebox if have_sigverification else inactive_stylebox)
	error_label.visible = have_error
	
	_update_font(metadata_pill, have_metadata)
	_update_font(index_report_pill, have_index_report)
	_update_font(vuln_report_pill, have_vuln_report)
	_update_font(signatures_pill, have_signatures)
	_update_font(signature_verification_pill, have_sigverification)


func _update_font(control, cond):
	if cond:
		control.remove_theme_color_override("font_color")
	else:
		control.add_theme_color_override("font_color", inactive_color)
