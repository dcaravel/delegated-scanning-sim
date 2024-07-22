extends Control
class_name LogPanel

const log_entry_scene = preload("res://log_entry.tscn")

@onready var log_entries = $ScrollContainer/LogEntries

func _ready():
	SignalManager.clear_log.connect(delAll)
	SignalManager.pop_log_entry.connect(del)
	SignalManager.push_log_entry.connect(add)

func add(icon_text:String, text:String):
	var le = log_entry_scene.instantiate()
	le.desc = text
	le.icon_text = icon_text
	
	if log_entries.get_child_count() > 0:
		var sep = HSeparator.new()
		sep.name = "LogPanel-HSeparator"
		log_entries.add_child(sep)
	
	log_entries.add_child(le)
	
func del() -> bool:
	var el = log_entries
	var statuses:Array[bool] = []
	
	var c = _get_last_child(el)
	if c == null:
		return false

	if c is HSeparator:
		return _remove_last(el)
	
	# assume we have a sparator and another node		
	statuses.append(_remove_last(el))
	statuses.append(_remove_last(el))
	
	for s in statuses:
		if s:
			SignalManager.log_entry_popped.emit()
			return true
	
	return false

func delAll():
	while del():
		pass
	SignalManager.log_cleared.emit()

func _get_last_child(el:Node) -> Node:
	var cnt = el.get_child_count()
	if cnt == 0:
		return null
	return el.get_child(cnt-1)
	
func _remove_last(el:Node) -> bool:
	var cnt = el.get_child_count()
	if cnt == 0:
		return false
	var c = el.get_child(cnt-1)
	el.remove_child(c)
	c.queue_free()
	return true

func get_all() -> Array[LogEntry]:
	return []
