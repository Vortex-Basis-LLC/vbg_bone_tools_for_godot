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

			subresources["nodes"]["PATH:Skeleton3D"]["rest_pose/external_animation_library"] = anim
			# TODO: Should this always be 2 when dealing with standalone animation?
			subresources["nodes"]["PATH:Skeleton3D"]["rest_pose/load_pose"] = 2

			config.set_value("params", "_subresources", subresources)
			config.save(config_path)
			assigned_rest_pose_count = assigned_rest_pose_count + 1

	# Trigger reimport of the animation libraries.	
	EditorInterface.get_resource_filesystem().scan_sources()

	print("Rest pose assignment complete.")
	_alert(str(assigned_rest_pose_count) + " rest pose(s) assigned.")


func _alert(message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.dialog_text = message
	dialog.confirmed.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()
