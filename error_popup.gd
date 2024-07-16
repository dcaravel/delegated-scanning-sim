extends Control
class_name ErrorPopup

const _C = preload("res://scripts/constants.gd")

@export var LabelPosition:Constants.Pos = Constants.Pos.BOT
@export var LabelText:String = "ERR"
@export var LabelOffsetX:int = 0

var _def_label_offsetX:int = 0

func _ready():
	_def_label_offsetX = $LabelBot.position.x
	$LabelTop.text = LabelText
	$LabelBot.text = LabelText
	$LabelTop.visible = false
	$LabelBot.visible = false

func _process(_delta):
	$LabelTop.text = LabelText
	$LabelBot.text = LabelText
	if LabelText == "":
		$LabelTop.visible = false
		$LabelBot.visible = false
		return
		
	if LabelPosition == Constants.Pos.TOP:
		$LabelTop.visible = true
		$LabelBot.visible = false
	elif LabelPosition == Constants.Pos.BOT:
		$LabelTop.visible = false
		$LabelBot.visible = true
	
	$LabelTop.position.x = _def_label_offsetX + LabelOffsetX
	$LabelBot.position.x = _def_label_offsetX + LabelOffsetX

func _exit_tree():
	queue_free()
