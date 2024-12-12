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
class_name VbgBoneMapAssignerWindow extends Window

@onready var _bone_map_picker_container: VBoxContainer = %BoneMapPickerContainer

var _bone_map_picker: EditorResourcePicker

func _ready() -> void:
	if _bone_map_picker_container:
		_bone_map_picker = EditorResourcePicker.new()
		_bone_map_picker.base_type = "BoneMap"
		_bone_map_picker_container.add_child(_bone_map_picker)


func _on_button_close_pressed() -> void:
	self.hide()


func _on_close_requested() -> void:
	self.hide()


func _on_button_assign_bone_map_pressed() -> void:
	if _bone_map_picker && _bone_map_picker.edited_resource:
		_assign_bone_map_to_selected_animation_libraries(_bone_map_picker.edited_resource as BoneMap)
	else:
		_alert("No bone map selected.")


func _assign_bone_map_to_selected_animation_libraries(bone_map: BoneMap) -> void:
	# For every selected AnimationLibrary in the FileSystem panel, we will open its .import
	# file and set the assigned bone map to the one in question.

	var assigned_bone_map_count := 0

	var paths := EditorInterface.get_selected_paths()
	for path in paths:
		var anim_lib := load(path) as AnimationLibrary
		if anim_lib:
			prints("Changing bone map for anim lib: ", path)

			var config := ConfigFile.new()
			var config_path := path + ".import"
			config.load(config_path)

			var subresources := config.get_value("params", "_subresources") as Dictionary
			if subresources:
				subresources = subresources.duplicate(true)
			else:
				subresources = {}

			if !subresources.has("nodes"):
				subresources["nodes"] = {}
			if !subresources["nodes"].has("PATH:Skeleton3D"):
				subresources["nodes"]["PATH:Skeleton3D"] = {}

			subresources["nodes"]["PATH:Skeleton3D"]["retarget/bone_map"] = bone_map

			config.set_value("params", "_subresources", subresources)
			config.save(path + ".import")
			assigned_bone_map_count = assigned_bone_map_count + 1
	
	print("Bone map assignment complete.")
	_alert(str(assigned_bone_map_count) + " bone map(s) assigned.")


func _alert(message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.dialog_text = message
	dialog.confirmed.connect(func(): print("Closed"))
	add_child(dialog)
	dialog.popup_centered()
