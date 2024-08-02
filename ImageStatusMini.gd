extends Panel
class_name ImageStatusMini

@export var have_metadata:bool = false
@export var have_index_report:bool = false
@export var have_vuln_report:bool = false
@export var have_signatures:bool = false
@export var have_sigverification:bool = true
@export var have_error:bool = false

@onready var metadata_pill = $MetadataPill
@onready var index_report_pill = $IndexReportPill
@onready var vuln_report_pill = $VulnReportPill
@onready var signatures_pill = $SignaturesPill
@onready var signatures_verification_pill = $SignaturesVerificationPill
@onready var error = $Error

func clone() -> ImageStatusMini:
	var dupe = self.duplicate()
	dupe.have_metadata = have_metadata
	dupe.have_index_report = have_index_report
	dupe.have_vuln_report = have_vuln_report
	dupe.have_signatures = have_signatures
	dupe.have_sigverification = have_sigverification
	dupe.have_error = have_error
	return dupe
	
func _ready():
	_sync()
	
func _process(_delta):
	_sync()

func _sync():
	metadata_pill.active=have_metadata
	index_report_pill.active=have_index_report
	vuln_report_pill.active=have_vuln_report
	signatures_pill.active=have_signatures
	signatures_verification_pill.active=have_sigverification
	error.visible=have_error
