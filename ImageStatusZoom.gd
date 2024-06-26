extends Control

@export var have_metadata:bool = false
@export var have_index_report:bool = false
@export var have_vuln_report:bool = false
@export var have_signatures:bool = false
@export var have_error:bool = false

var inactive_color = Color("ffffff1e")
var inactive_stylebox = preload("res://theme/panel/inactive.stylebox")
var metadata_stylebox = preload("res://theme/panel/metadata.stylebox")
var index_report_stylebox = preload("res://theme/panel/indexreport.stylebox")
var vuln_report_stylebox = preload("res://theme/panel/vulnreport.stylebox")
var signatures_stylebox = preload("res://theme/panel/signatures.stylebox")

# Called when the node enters the scene tree for the first time.
func _ready():
	$ErrorLabel.visible = have_error


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$MetadataPill.add_theme_stylebox_override("normal", metadata_stylebox if have_metadata else inactive_stylebox)
	$IndexReportPill.add_theme_stylebox_override("normal", index_report_stylebox if have_index_report else inactive_stylebox)
	$VulnReportPill.add_theme_stylebox_override("normal",  vuln_report_stylebox if have_vuln_report else inactive_stylebox)
	$SignaturesPill.add_theme_stylebox_override("normal",  signatures_stylebox if have_signatures else inactive_stylebox)
	$ErrorLabel.visible = have_error
	
	_update_font($MetadataPill, have_metadata)
	_update_font($IndexReportPill, have_index_report)
	_update_font($VulnReportPill, have_vuln_report)
	_update_font($SignaturesPill, have_signatures)


func _update_font(control, cond):
	if cond:
		control.remove_theme_color_override("font_color")
	else:
		control.add_theme_color_override("font_color", inactive_color)
