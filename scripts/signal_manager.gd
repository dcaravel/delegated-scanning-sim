extends Node

signal pop_log_entry
signal log_entry_popped # when a log entry is successfully popped

signal clear_log
signal log_cleared

signal push_log_entry(p_icon_text:String, p_text:String)

signal walk_speed_updated
