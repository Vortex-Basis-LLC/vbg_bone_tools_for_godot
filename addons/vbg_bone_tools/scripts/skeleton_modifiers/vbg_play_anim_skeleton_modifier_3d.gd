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
class_name VbgPlayAnimSkeletonModifier3d extends VbgBaseAnimSkeletonModifier3d

@export var _anim_ref: VbgAnimRef



func _get_animation() -> Animation:
	if _anim_ref:
		return _anim_ref.get_animation()
	else:
		return null

func get_unscaled_anim_length() -> float:
	var anim := _anim_ref.get_animation()
	if !anim:
		return 0

	return anim.length

func get_anim_loop_mode() -> VbgAnimRef.VbgLoopMode:
	if !_anim_ref:
		return VbgAnimRef.VbgLoopMode.DEFAULT

	return _anim_ref.loop_mode

func get_default_anim_loop_mode() -> VbgAnimRef.VbgLoopMode:
	var anim := _get_animation()
	if !anim:
		return VbgAnimRef.VbgLoopMode.NO_LOOP

	if anim.loop_mode == Animation.LoopMode.LOOP_LINEAR:
		return VbgAnimRef.VbgLoopMode.LOOP
	else:
		return VbgAnimRef.VbgLoopMode.NO_LOOP


func _apply_bone_modifications() -> void:
	var skeleton := get_skeleton()
	if !skeleton || !_anim_ref:
		return

	var anim := _get_animation()
	if !anim:
		return

	var frame_anim_time = get_unscaled_anim_time()

	for track_index in anim.get_track_count():
		var track_path := anim.track_get_path(track_index)
		var bone_name := track_path.get_concatenated_subnames()
		var track_type := anim.track_get_type(track_index)
		var bone := skeleton.find_bone(bone_name)
		if bone != -1:
			if track_type == Animation.TrackType.TYPE_ROTATION_3D:
				var bone_rotation := anim.rotation_track_interpolate(track_index, frame_anim_time)
				skeleton.set_bone_pose_rotation(bone, bone_rotation)
			elif track_type == Animation.TrackType.TYPE_POSITION_3D:
				var bone_pos := anim.position_track_interpolate(track_index, frame_anim_time)
				skeleton.set_bone_pose_position(bone, bone_pos)
