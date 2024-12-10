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
class_name VbgBlendSkeletonModifier3d extends VbgBaseAnimSkeletonModifier3d

@export var _anim_ref: VbgAnimRef

@export_range(0.0, 1.0) var blend_weight: float = 1.0

@export var blend_in_time: float = 0.2
@export var blend_out_time: float = 0.2

# If set, then the saved skeleton pose will be used as base pose instead
#   of the current skeleton.
@export var use_saved_pose_as_base: VbgSaveSkeletonPoseNode

# TODO: Provide a resource that names a bone and a weight. Allow a list to be provided.

@export_enum(" ") var filter_to_bone_branch: String = &"":
	set(value):
		filter_to_bone_branch = value
		_update_included_bones()

var _bone_inclusion_map: Dictionary = {}


func _validate_property(property: Dictionary) -> void:
	if Engine.is_editor_hint():
		if property.name == "filter_to_bone_branch":
			var skeleton := get_skeleton()
			if skeleton:
				# Provide dynamic drop down list for the animation names.
				property.hint = PROPERTY_HINT_ENUM
				var bone_names := []
				var bone_count := skeleton.get_bone_count()
				for bone_index in bone_count:
					bone_names.append(skeleton.get_bone_name(bone_index))
				property.hint_string = ",".join(bone_names)


func _ready() -> void:
	_update_included_bones()

	super._ready()


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


func _update_included_bones() -> void:
	_bone_inclusion_map = {}
	if !filter_to_bone_branch.is_empty():
		var skeleton := get_skeleton()
		var filter_bone := skeleton.find_bone(filter_to_bone_branch)
		var bone_count := skeleton.get_bone_count()
		for bone_index in bone_count:
			if _is_bone_same_or_ancestor(filter_bone, bone_index):
				_bone_inclusion_map[bone_index] = true


func _is_bone_included(bone_index: int) -> bool:
	if filter_to_bone_branch.is_empty() || _bone_inclusion_map.has(bone_index):
		return true
	else:
		return false


func _is_bone_same_or_ancestor(ancestor_bone: int, other_bone: int) -> bool:
	if ancestor_bone == other_bone:
		return true
	var other_bone_parent := get_skeleton().get_bone_parent(other_bone)
	if other_bone_parent == -1:
		return false
	else:
		return _is_bone_same_or_ancestor(ancestor_bone, other_bone_parent)


func _apply_bone_modifications() -> void:
	var skeleton := get_skeleton()
	if !skeleton || !_anim_ref:
		return

	var anim := _get_animation()
	if !anim:
		return

	if !_is_playing:
		return

	var frame_anim_time = get_unscaled_anim_time()

	var anim_time := get_anim_time()
	var anim_length := get_anim_length()

	var blend_weight_to_use := blend_weight
	if anim_time < blend_in_time:
		blend_weight_to_use = blend_weight_to_use * (1.0 - ((blend_in_time - anim_time) / blend_in_time))
	else:
		var blend_out_start_time := anim_length - blend_out_time
		if anim_time > blend_out_start_time:
			blend_weight_to_use = blend_weight_to_use * (1.0 - ((anim_time - blend_out_start_time) / blend_out_time))

	# TODO: If using saved pose, we should actually be processing every bone instead of just
	# ones with a track present.

	for track_index in anim.get_track_count():
		var track_path := anim.track_get_path(track_index)
		var bone_name := track_path.get_concatenated_subnames()
		var track_type := anim.track_get_type(track_index)
		var bone := skeleton.find_bone(bone_name)
		if bone != -1 && _is_bone_included(bone):
			var bone_blend_weight := blend_weight_to_use

			if track_type == Animation.TrackType.TYPE_ROTATION_3D:
				var current_bone_rotation: Quaternion
				if use_saved_pose_as_base:
					var saved_pose := use_saved_pose_as_base.saved_skeleton_pose
					if saved_pose:
						current_bone_rotation = saved_pose.bone_poses[bone].rotation
				else:
					current_bone_rotation = skeleton.get_bone_pose_rotation(bone)

				var target_bone_rotation := anim.rotation_track_interpolate(track_index, frame_anim_time)
				var blended_bone_rotation: Quaternion = lerp(current_bone_rotation, target_bone_rotation, bone_blend_weight)
				skeleton.set_bone_pose_rotation(bone, blended_bone_rotation)
			elif track_type == Animation.TrackType.TYPE_POSITION_3D:
				var current_bone_pos: Vector3 = skeleton.get_bone_pose_position(bone)
				if use_saved_pose_as_base:
					var saved_pose := use_saved_pose_as_base.saved_skeleton_pose
					if saved_pose:
						current_bone_pos = saved_pose.bone_poses[bone].position
				else:
					current_bone_pos = skeleton.get_bone_pose_position(bone)

				var target_bone_pos := anim.position_track_interpolate(track_index, frame_anim_time)
				var blended_bone_pos: Vector3 = lerp(current_bone_pos, target_bone_pos, bone_blend_weight)
				skeleton.set_bone_pose_position(bone, blended_bone_pos)
