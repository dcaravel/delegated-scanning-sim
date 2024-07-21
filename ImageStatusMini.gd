extends Panel
class_name ImageStatusMini

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

@onready var metadata_pill = $MetadataPill
@onready var index_report_pill = $IndexReportPill
@onready var vuln_report_pill = $VulnReportPill
@onready var signatures_pill = $SignaturesPill
@onready var error = $Error


func clone() -> ImageStatusMini:
	var dupe = self.duplicate()
	dupe.have_metadata = have_metadata
	dupe.have_index_report = have_index_report
	dupe.have_vuln_report = have_vuln_report
	dupe.have_signatures = have_signatures
	dupe.have_error = have_error
	return dupe

func _init():
	pass
	
func _ready():
	_sync()
	
func _process(_delta):
	_sync()

func _sync():
	metadata_pill.active=have_metadata
	index_report_pill.active=have_index_report
	vuln_report_pill.active=have_vuln_report
	signatures_pill.active=have_signatures
	error.visible=have_error
