# MIT License

# Copyright (c) 2024 Vortex Basis, LLC

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends EditorPlugin


const MENU_ITEM_BULK_ASSIGN_BONE_MAP_TO_ANIM_LIBS: String = "VBG Bone Tools - Bulk Assign Bone Map To AnimLibs"


var bone_map_assigner_window: VbgBoneMapAssignerWindow


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_tool_menu_item(MENU_ITEM_BULK_ASSIGN_BONE_MAP_TO_ANIM_LIBS, _show_bone_map_assigner_window)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	if bone_map_assigner_window:
		bone_map_assigner_window.free()
		bone_map_assigner_window = null

	remove_tool_menu_item(MENU_ITEM_BULK_ASSIGN_BONE_MAP_TO_ANIM_LIBS)


func _show_bone_map_assigner_window() -> void:
	if !bone_map_assigner_window:
		bone_map_assigner_window = preload("res://addons/vbg_bone_tools/assets/anim_libs/bone_map_assigner/vbg_bone_map_assigner_window.tscn").instantiate() as VbgBoneMapAssignerWindow
		bone_map_assigner_window.size = Vector2i(500, 400)
		get_editor_interface().popup_dialog_centered(bone_map_assigner_window)
	else:
		bone_map_assigner_window.show()