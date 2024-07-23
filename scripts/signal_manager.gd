extends Node

signal pop_log_entry
signal log_entry_popped # when a log entry is successfully popped

signal clear_log
signal log_cleared

signal push_log_entry(p_icon_text:String, p_text:String)

signal moving_updated
signal walk_speed_updated

signal deploy_to_cluster(p_cluster:Global.CLUSTER)
signal context_menu(p_cluster:Global.CLUSTER)
signal images_updated
