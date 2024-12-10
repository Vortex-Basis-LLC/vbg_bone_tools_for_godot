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
class_name VbgBaseAnimSkeletonModifier3d extends SkeletonModifier3D

# Base class for animation SkeletonModifier3D that provides for keeping time
# and looping controls.

@export var auto_play: bool = true

@export var anim_speed: float = 1.0:
	set(value):
		# TODO: Change anim position to match original scaled time.
		if anim_speed <= 0.0:
			anim_speed = 0.01
		else:
			anim_speed = value

@export_category("Debug")
@export var play_from_start_in_editor: bool:
	set(value):
		play_from_start()

@export var stop_in_editor: bool:
	set(value):
		stop()


var _is_playing: bool = false
var _anim_time: float = 0.0
var _last_ticks_usec: int = 0
var _should_loop: bool = false
var _should_play: bool = false


func _ready() -> void:
	_last_ticks_usec = Time.get_ticks_usec()

	if auto_play:
		play_from_start()


func get_unscaled_anim_length() -> float:
	# Should be overridden by derived class.
	return 0

func get_anim_loop_mode() -> VbgAnimRef.VbgLoopMode:
	# Should be overridden by derived class.
	return VbgAnimRef.VbgLoopMode.DEFAULT

func get_default_anim_loop_mode() -> VbgAnimRef.VbgLoopMode:
	# Should be overridden by derived class.
	return VbgAnimRef.VbgLoopMode.NO_LOOP


func play_from_start():
	_last_ticks_usec = Time.get_ticks_usec()
	_anim_time = 0.0
	_is_playing = true
	_should_play = true

	var loop_mode = get_anim_loop_mode()

	if loop_mode == VbgAnimRef.VbgLoopMode.DEFAULT:
		_should_loop = get_default_anim_loop_mode() == VbgAnimRef.VbgLoopMode.LOOP
	else:
		_should_loop = loop_mode == VbgAnimRef.VbgLoopMode.LOOP


func get_anim_length() -> float:
	return get_unscaled_anim_length() / anim_speed

func get_anim_time() -> float:
	return _anim_time

func get_unscaled_anim_time() -> float:
	return _anim_time * anim_speed


func stop() -> void:
	_is_playing = false
	_should_play = false


func _process_modification() -> void:
	var current_ticks_usec = Time.get_ticks_usec()
	var delta: float = float(current_ticks_usec - _last_ticks_usec) / 1000000.0
	self._last_ticks_usec = current_ticks_usec

	if _should_play:
		_anim_time = _anim_time + delta

	var unscaled_anim_length := get_unscaled_anim_length()
	var scaled_anim_length := unscaled_anim_length / anim_speed

	if _anim_time > scaled_anim_length:
		if _should_loop:
			_anim_time = fmod(_anim_time, scaled_anim_length)
		else:
			_should_play = false
			_is_playing = false

	_apply_bone_modifications()


func _apply_bone_modifications():
	# Should be overridden by derived classes.
	pass
