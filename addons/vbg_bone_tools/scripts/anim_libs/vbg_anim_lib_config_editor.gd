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

class_name VbgAnimLibConfigEditor extends RefCounted

var _anim_lib: AnimationLibrary
var _config_path: String
var _config: ConfigFile


static func open_anim_lib_config(anim_lib: AnimationLibrary) -> VbgAnimLibConfigEditor:
	if !anim_lib:
		return null
	
	var anim_lib_config := VbgAnimLibConfigEditor.new()
	anim_lib_config._anim_lib = anim_lib
	anim_lib_config._config_path = anim_lib.resource_path + ".import"

	anim_lib_config._config = ConfigFile.new()
	anim_lib_config._config.load(anim_lib_config._config_path)

	return anim_lib_config


func set_bone_map(bone_map: BoneMap) -> void:
	if !_config:
		printerr("VbgAnimLibConfigEditor::set_bone_map: config not loaded")
		return

	var subresources := _config.get_value("params", "_subresources") as Dictionary
	if subresources:
		subresources = subresources.duplicate(true)
	else:
		subresources = {}

	if !subresources.has("nodes"):
		subresources["nodes"] = {}
	if !subresources["nodes"].has("PATH:Skeleton3D"):
		subresources["nodes"]["PATH:Skeleton3D"] = {}

	subresources["nodes"]["PATH:Skeleton3D"]["retarget/bone_map"] = bone_map

	_config.set_value("params", "_subresources", subresources)


func set_rest_pose_to_external_animation(anim: Animation) -> void:
	if !_config:
		printerr("VbgAnimLibConfigEditor::set_bone_map: config not loaded")
		return
		
	var subresources := _config.get_value("params", "_subresources") as Dictionary
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

	_config.set_value("params", "_subresources", subresources)


func save_config_changes():
	_config.save(_config_path)