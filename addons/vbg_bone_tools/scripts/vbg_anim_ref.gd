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
class_name VbgAnimRef extends Resource

# Either anim or anim_lib/name should be provided to reference an animation.

enum VbgLoopMode { DEFAULT, LOOP, NO_LOOP }


@export var anim: Animation

@export var anim_lib: AnimationLibrary:
	set(value):
		anim_lib = value
		_cached_anim_lib_anim = null
		_anim_lib_anim_not_found = false
		# This is so that _validate_property will be called again to refresh animation list.
		notify_property_list_changed()

@export_enum(" ") var anim_name: String:
	set(value):
		anim_name = value
		_cached_anim_lib_anim = null
		_anim_lib_anim_not_found = false


@export var loop_mode: VbgLoopMode = VbgLoopMode.DEFAULT


var _cached_anim_lib_anim: Animation
var _anim_lib_anim_not_found: bool = false




func _validate_property(property: Dictionary) -> void:
	if Engine.is_editor_hint():
		if property.name == "anim_name":
			if anim_lib:
				# Provide dynamic drop down list for the animation names.
				property.hint = PROPERTY_HINT_ENUM
				property.hint_string = ",".join(anim_lib.get_animation_list())



func get_animation() -> Animation:
	if anim:
		return anim
	else:
		if anim_lib && !anim_name.is_empty():
			if !_cached_anim_lib_anim && !_anim_lib_anim_not_found:
				_cached_anim_lib_anim = anim_lib.get_animation(anim_name)
				if !_cached_anim_lib_anim:
					_anim_lib_anim_not_found = true

			return _cached_anim_lib_anim

	return null
