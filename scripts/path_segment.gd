extends Node
class_name PathSegment

const blah = preload("res://arch.gd")
const _C = preload("res://scripts/constants.gd")

var parent:Arch

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


func _init(
	p_parent:Arch, 
	p_path:Path2D, 
	):
	
	parent = p_parent
	path = p_path
	
	path_follow = PathFollow2D.new()
	path_follow.rotates = false
	path.add_child(path_follow)
	
	parent.all_path_segments.append(self)
	
# returns the total progress walked so far
func progress() -> float:
	if reverse_dir:
		return 1-path_follow.progress_ratio
	return path_follow.progress_ratio

func reset(hard:bool=true):
	if reverse_dir:
		path_follow.progress_ratio = 1
		inner_progress=path.curve.get_baked_length()
	else:
		path_follow.progress_ratio = 0
		inner_progress=0
	
	if start_icon != null:
		path.remove_child(start_icon)
		start_icon.queue_free()
		start_icon = null
	
	if icon != null:
		path_follow.remove_child(icon)
		icon.queue_free()
		icon = null
	
	if end_icon != null:
		path_follow.remove_child(end_icon)
		end_icon.queue_free()
		end_icon = null

	if mid_icon != null:
		path.remove_child(mid_icon)
		mid_icon.queue_free()
		mid_icon = null
		parent._del_log_entry()
	
	if draw_trail:
		for i in range(0, lines.size()):
			var l = lines[i]
			path.remove_child(l)
			l.queue_free()
		lines.clear()
	
	started_walk = false

	if hard:
		_callback(Constants.Event.RESET)

func _callback(p_event:Constants.Event):
	for cb in callbacks:
		if cb.is_null():
			continue
		
		cb.call(p_event)

func walk(delta) -> bool:
	if !started_walk:
		reset(false)
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
				l.width = 2
				if !use_alt_color:
					l.default_color=parent.line_color
				else:
					l.default_color=parent.line_color_alt
				l.add_point(start)
				l.add_point(start)
				path.add_child(l)
				lines.append(l)
		
		_callback(Constants.Event.START)
		
		started_walk = true
	
	var done = _walk_by_px(delta) if parent.walk_by_px else _walk_by_ratio(delta)
	
	_draw_line()
	_draw_mid_icon()
	
	if done:
		path_follow.remove_child(icon)
		icon.queue_free()
		icon == null
		_callback(Constants.Event.END)
		if !end_icon_creator.is_null() && !end_icon:
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
		inner_progress -= (parent.walk_speed_px * delta)
	else:
		inner_progress += (parent.walk_speed_px * delta)

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

func _walk_by_ratio(delta) -> bool:
	var ratio = path_follow.progress_ratio + (parent.walk_speed_ratio * delta)
	path_follow.progress_ratio = ratio
	if ratio >= 1.0:
		path_follow.progress_ratio = 1.0
		return true
	
	return false

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
