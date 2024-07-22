extends RefCounted
class_name PathSegment

var path:Path2D
var path_follow:PathFollow2D

var started_walk:bool = false

var end_icon:Node
var end_icon_creator:Callable

var icon:Node
var walk_icon_creator:Callable

var start_icon:Node
var start_icon_creator:Callable

var mid_icon:Node
var mid_icon_creator:Callable
var mid_icon_px:int

# (start, end, reset)
var callbacks:Array[Callable]

var lines:Array[Line2D]
var draw_trail:bool
var inner_progress:float
var reverse_dir:bool
var use_alt_color:bool

var walk_speed_px:float

func _init(p_path:Path2D):
	path = p_path

	SignalManager.walk_speed_updated.connect(_on_walk_speed_update)
	_on_walk_speed_update() # set the initial speed

func _on_walk_speed_update() -> void:
	walk_speed_px = Config.get_walk_speed_px()

# returns the total progress walked so far
func progress() -> float:
	if path_follow == null:
		return 0
			
	if reverse_dir:
		return 1-path_follow.progress_ratio
	return path_follow.progress_ratio

func _reset_progress():
	if reverse_dir:
		inner_progress=path.curve.get_baked_length()
		if path_follow != null:
			path_follow.progress_ratio = 1
	else:
		inner_progress=0
		if path_follow != null:
			path_follow.progress_ratio = 0

func reset(hard:bool=true):
	_reset_progress()
	if path_follow != null:
		path.remove_child(path_follow)
		path_follow.queue_free()
		path_follow = null

	if start_icon != null:
		path.remove_child(start_icon)
		start_icon.queue_free()
		start_icon = null

	if mid_icon != null:
		path.remove_child(mid_icon)
		mid_icon.queue_free()
		mid_icon = null
		SignalManager.pop_log_entry.emit()
	
	if draw_trail:
		for i in range(0, lines.size()):
			var l = lines[i]
			path.remove_child(l)
			l.queue_free()
		lines.clear()
	
	started_walk = false

	if hard:
		_callback(Global.Event.RESET)

func _callback(p_event:Global.Event):
	for cb in callbacks:
		if cb.is_null():
			continue
		
		cb.call(p_event)

func walk(delta) -> bool:
	if !started_walk:
		reset(false)
		if path_follow == null:
			path_follow = PathFollow2D.new()
			path_follow.name = "PathSegment-PathFollow2D"
			path_follow.rotates = false
			path.add_child(path_follow)
			_reset_progress()
			
		if !start_icon_creator.is_null():
			start_icon = start_icon_creator.call()
			start_icon.position = _cur_path_pos()
			path.add_child(start_icon)
		if !walk_icon_creator.is_null():
			icon = walk_icon_creator.call()
			path_follow.add_child(icon)
		if draw_trail:
			for i in range(0,path.curve.point_count-1):
				var start = path.curve.get_point_position(i)
				var l = Line2D.new()
				l.name="PathSegment-Line2D"
				l.width = 2
				if !use_alt_color:
					l.default_color=Global.TRAIL_COLOR
				else:
					l.default_color=Global.TRAIL_COLOR_ALT
				l.add_point(start)
				l.add_point(start)
				path.add_child(l)
				lines.append(l)

		
		_callback(Global.Event.START)
		
		started_walk = true
	
	var done = _walk_by_px(delta) if Config.walk_by_px() else _walk_by_ratio(delta)
	
	_draw_line()
	_draw_mid_icon()
	
	if done:
		if icon != null:
			path_follow.remove_child(icon)
			icon.queue_free()
			icon = null
			
		_callback(Global.Event.END)
		if !end_icon_creator.is_null() && end_icon == null:
			end_icon = end_icon_creator.call()
			path_follow.add_child(end_icon)
	
	return done

func _draw_mid_icon():
	if mid_icon_creator.is_null() || mid_icon:
		# if is nothing to create or the icon already created, do nothing
		return

	var draw_it := false
	if inner_progress <= mid_icon_px && reverse_dir:
		draw_it = true
	elif inner_progress >= mid_icon_px:
		draw_it = true

	var pos = path.curve.sample_baked(mid_icon_px)
	if !draw_it:
		return

	mid_icon = mid_icon_creator.call()
	mid_icon.position = pos
	path.add_child(mid_icon)


func _draw_line():
	if !draw_trail:
		return
		
	var active_line:float = 0.0
	var dist = 0
	for i in range(0,path.curve.point_count-2):
		var start = path.curve.get_point_position(i)
		var end = path.curve.get_point_position(i+1)
		dist += start.distance_to(end)
		
		if path_follow.progress > dist:
			# the current progress is higher then the distance so far
			# so we must be at the next line of the curve
			lines[active_line].set_point_position(1, end)
			active_line += 1

	if active_line < lines.size():
		lines[active_line].set_point_position(1, _cur_path_pos())

func _walk_by_px(delta) -> bool:
	if reverse_dir:
		inner_progress -= (walk_speed_px * delta)
	else:
		inner_progress += (walk_speed_px * delta)

	path_follow.progress = inner_progress
	if reverse_dir:
		if inner_progress <= 0:
			path_follow.progress = 0
			inner_progress = 0
			return true
		return false
		
	if inner_progress >= path.curve.get_baked_length():
		path_follow.progress = path.curve.get_baked_length()
		inner_progress = path.curve.get_baked_length()
		return true

	return false

func _walk_by_ratio(_delta) -> bool:
	return true # NOT IMPLEMENTED
	# var ratio = path_follow.progress_ratio + (walk_speed_ratio * delta)
	# path_follow.progress_ratio = ratio
	# if ratio >= 1.0:
	# 	path_follow.progress_ratio = 1.0
	# 	return true
	
	# return false

func _cur_path_pos() -> Vector2:
	return path.curve.sample_baked(path_follow.progress)
	
func trail(draw:bool) -> PathSegment:
	self.draw_trail = draw
	return self

func wicon(creator:Callable) -> PathSegment:
	self.walk_icon_creator = creator
	return self

func sicon(creator:Callable) -> PathSegment:
	self.start_icon_creator = creator
	return self

func eicon(creator:Callable) -> PathSegment:
	self.end_icon_creator = creator
	return self

func micon(creator:Callable, px:int) -> PathSegment:
	self.mid_icon_creator = creator
	self.mid_icon_px = px
	return self

func onevent(p_callback:Callable) -> PathSegment:
	self.callbacks.append(p_callback)
	return self

func reverse(rev:bool=true) -> PathSegment:
	self.reverse_dir = rev
	reset(false)
	return self

func altcolor(p_altcolor:bool=true) -> PathSegment:
	use_alt_color = p_altcolor
	reset(false)
	return self
