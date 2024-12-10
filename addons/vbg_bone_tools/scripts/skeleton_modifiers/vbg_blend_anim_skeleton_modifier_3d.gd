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


@export var bone_filter: VbgBoneFilterConfig = null:
	set(value):
		bone_filter = value
		_refesh_bone_filter_obj()


###
### Add Bone Filter section is just a helper for adding bones to the bone_filter.
###
@export_category("Add Bone Filter")
@export_enum(" ") var filter_bone_name: String = &"":
	set(value):
		filter_bone_name = value

@export var add_bone_filter_entry: bool:
	set(value):
		if !bone_filter:
			bone_filter = VbgBoneFilterConfig.new()
			bone_filter.default_weight = 0
			bone_filter.entries = []

		var entry = VbgBoneFilterConfigEntry.new()
		entry.bone_name = filter_bone_name
		entry.weight = 0.0
		entry.include_children = true
		bone_filter.entries.append(entry)
		_refesh_bone_filter_obj()


@export_category("Debug")
@export var refresh_bone_filter: bool:
	set(value):
		_refesh_bone_filter_obj()


var _bone_filter_obj: VbgBoneFilter
var _cached_track_to_bone_index: VbgTrackToBoneIndex

func _validate_property(property: Dictionary) -> void:
	if Engine.is_editor_hint():
		if property.name == "filter_bone_name":
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
	_refesh_bone_filter_obj()

	super._ready()


func _refesh_bone_filter_obj() -> void:
	_bone_filter_obj = VbgBoneFilter.new(get_skeleton(), bone_filter)


func _get_animation() -> Animation:
	if _anim_ref:
		return _anim_ref.get_animation()
	else:
		return null

func get_unscaled_anim_length() -> float:
	var anim := _get_animation()
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


func _get_cached_track_to_bone_index(anim: Animation) -> VbgTrackToBoneIndex:
	if _cached_track_to_bone_index:
		if _cached_track_to_bone_index.anim != anim || _cached_track_to_bone_index.skeleton != get_skeleton():
			_cached_track_to_bone_index = null

	if !_cached_track_to_bone_index:
		_cached_track_to_bone_index = VbgTrackToBoneIndex.new(get_skeleton(), anim)

	return _cached_track_to_bone_index


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

	# TODO: The blend times shouldn't be used when looping and not transitioning into or out of this animation.

	var blend_weight_to_use := blend_weight
	if anim_time < blend_in_time:
		blend_weight_to_use = blend_weight_to_use * (1.0 - ((blend_in_time - anim_time) / blend_in_time))
	else:
		var blend_out_start_time := anim_length - blend_out_time
		if anim_time > blend_out_start_time:
			blend_weight_to_use = blend_weight_to_use * (1.0 - ((anim_time - blend_out_start_time) / blend_out_time))

	var track_to_bone_index := _get_cached_track_to_bone_index(anim)

	var bone_count := skeleton.get_bone_count()
	for bone in bone_count:
		var bone_blend_weight := blend_weight_to_use
		if _bone_filter_obj:
			bone_blend_weight *= _bone_filter_obj.get_bone_weight(bone)

		var rotation_track := track_to_bone_index.get_track_for_bone_rotation(bone)
		var position_track := track_to_bone_index.get_track_for_bone_position(bone)
		var scale_track := track_to_bone_index.get_track_for_bone_scale(bone)

		if rotation_track != -1:
			var current_bone_rotation: Quaternion
			if use_saved_pose_as_base:
				var saved_pose := use_saved_pose_as_base.saved_skeleton_pose
				if saved_pose:
					current_bone_rotation = saved_pose.bone_poses[bone].rotation
			else:
				current_bone_rotation = skeleton.get_bone_pose_rotation(bone)

			var target_bone_rotation := anim.rotation_track_interpolate(rotation_track, frame_anim_time)
			var blended_bone_rotation: Quaternion = lerp(current_bone_rotation, target_bone_rotation, bone_blend_weight)
			skeleton.set_bone_pose_rotation(bone, blended_bone_rotation)

		if position_track != -1:
			var current_bone_pos: Vector3
			if use_saved_pose_as_base:
				var saved_pose := use_saved_pose_as_base.saved_skeleton_pose
				if saved_pose:
					current_bone_pos = saved_pose.bone_poses[bone].position
			else:
				current_bone_pos = skeleton.get_bone_pose_position(bone)

			var target_bone_pos := anim.position_track_interpolate(position_track, frame_anim_time)
			var blended_bone_pos: Vector3 = lerp(current_bone_pos, target_bone_pos, bone_blend_weight)
			skeleton.set_bone_pose_position(bone, blended_bone_pos)

		if scale_track != -1:
			var current_bone_scale: Vector3
			if use_saved_pose_as_base:
				var saved_pose := use_saved_pose_as_base.saved_skeleton_pose
				if saved_pose:
					current_bone_scale = saved_pose.bone_poses[bone].scale
			else:
				current_bone_scale = skeleton.get_bone_pose_scale(bone)

			var target_bone_scale := anim.scale_track_interpolate(scale_track, frame_anim_time)
			var blended_bone_scale: Vector3 = lerp(current_bone_scale, target_bone_scale, bone_blend_weight)
			skeleton.set_bone_pose_scale(bone, blended_bone_scale)