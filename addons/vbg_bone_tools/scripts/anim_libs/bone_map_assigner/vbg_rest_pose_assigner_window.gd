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
class_name VbgRestPoseAssignerWindow extends Window

@onready var _anim_picker_container: VBoxContainer = %AnimPickerContainer

var _anim_picker: EditorResourcePicker

func _ready() -> void:
	if _anim_picker_container:
		_anim_picker = EditorResourcePicker.new()
		_anim_picker.base_type = "Animation"
		_anim_picker_container.add_child(_anim_picker)


func _on_button_close_pressed() -> void:
	self.hide()


func _on_close_requested() -> void:
	self.hide()


func _on_button_assign_rest_pose_pressed() -> void:
	if _anim_picker && _anim_picker.edited_resource:
		_assign_rest_pose_to_selected_animation_libraries(_anim_picker.edited_resource as Animation)
	else:
		_alert("No animation selected.")


func _assign_rest_pose_to_selected_animation_libraries(anim: Animation) -> void:
	# For every selected AnimationLibrary in the FileSystem panel, we will open its .import
	# file and set the assigned rest pose to the one in question.

	var assigned_rest_pose_count := 0

	var paths := EditorInterface.get_selected_paths()
	for path in paths:
		var anim_lib := load(path) as AnimationLibrary
		if anim_lib:
			prints("Changing rest pose for anim lib: ", path)

			var anim_lib_config_editor := VbgAnimLibConfigEditor.open_anim_lib_config(anim_lib)
			anim_lib_config_editor.set_rest_pose_to_external_animation(anim)
			anim_lib_config_editor.save_config_changes()
			anim_lib_config_editor.reimport_file()

			assigned_rest_pose_count = assigned_rest_pose_count + 1

	print("Rest pose assignment complete.")
	_alert(str(assigned_rest_pose_count) + " rest pose(s) assigned.")


func _alert(message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.dialog_text = message
	dialog.confirmed.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()
