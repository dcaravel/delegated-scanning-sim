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
signal active_image_updated


# Delegated Scanning Config
signal dele_scan_update_enabled_for(p_for:Global.ENABLED_FOR)
signal dele_scan_update_default_cluster(p_idx:int)
signal dele_scan_add_registry(p_reg:Global.Registry)
signal dele_scan_update_registry(p_reg_idx:int, p_reg:Global.Registry)
signal dele_scan_delete_registry(p_reg_idx:int)
signal dele_scan_config_updated

# Version Setting
signal version_change(p_version:String)
