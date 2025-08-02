@tool
extends EditorContextMenuPlugin
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	script-ide: Virtual Popups
#
#	Virtual Popups for script-ide addon.godot 4
#	author:	"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
const SCENE : PackedScene = preload("res://addons/_Godot-IDE_/plugins/gd_override_functions/popup/virtuals_popup.tscn")
const ICON : Texture = preload("res://addons/_Godot-IDE_/shared_resources/func_virtual.svg")

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		var root : Node = Engine.get_main_loop().root
		var virtual_popup : Popup = root.get_node_or_null("_VPOPUP_")
		if is_instance_valid(virtual_popup) and !virtual_popup.is_queued_for_deletion():
			virtual_popup.config_update(true)
			virtual_popup.queue_free()

func callback(input : Object) -> void:
	var input_script : Script = null

	if input is Script:
		input_script = input
	elif input is CodeEdit:
		var script_editor: ScriptEditor = EditorInterface.get_script_editor()
		var scripts_editors : Array[ScriptEditorBase] = script_editor.get_open_script_editors()
		var scripts : Array[Script] = script_editor.get_open_scripts()
		var iscript : int = -1

		for x : int in range(scripts_editors.size()):
			if scripts_editors[x].get_base_editor() == input:
				iscript = x
				pass
		if iscript > -1 and iscript < scripts.size():
			input_script = scripts[iscript]

	if null == input_script:
		push_error("[PLUGIN] Error, can`t get current script - not valid!")
		return

	var root : Node = Engine.get_main_loop().root
	var virtual_popup : Popup = root.get_node_or_null("_VPOPUP_")
	if virtual_popup == null:
		virtual_popup = SCENE.instantiate()
		virtual_popup.set(&"name", &"_VPOPUP_")
		root.add_child(virtual_popup)
	virtual_popup.make_tree(input_script)
	virtual_popup.popup_centered.call_deferred()

func _popup_menu(_paths : PackedStringArray) -> void:
	add_context_menu_item("Override Virtual Functions", callback, ICON)
