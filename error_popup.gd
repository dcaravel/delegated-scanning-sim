extends Control
class_name ErrorPopup

@export var LabelPosition:Global.Pos = Global.Pos.BOT
@export var LabelText:String = "ERR"
@export var LabelOffsetX:int = 0

var _def_label_offsetX:int = 0

@onready var label_top = $LabelTop
@onready var label_bot = $LabelBot

func _ready():
	_def_label_offsetX = label_bot.position.x
	label_top.text = LabelText
	label_bot.text = LabelText
	label_top.visible = false
	label_bot.visible = false

func _process(_delta):
	label_top.text = LabelText
	label_bot.text = LabelText
	if LabelText == "":
		label_top.visible = false
		label_bot.visible = false
		return
		
	if LabelPosition == Global.Pos.TOP:
		label_top.visible = true
		label_bot.visible = false
	elif LabelPosition == Global.Pos.BOT:
		label_top.visible = false
		label_bot.visible = true
	
	label_top.position.x = _def_label_offsetX + LabelOffsetX
	label_bot.position.x = _def_label_offsetX + LabelOffsetX
