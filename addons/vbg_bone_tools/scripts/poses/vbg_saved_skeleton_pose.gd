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
class_name VbgSavedSkeletonPose extends RefCounted

# Save bone poses for an entire skeleton.

var skeleton: Skeleton3D

# Array of bone poses matching bone indexes in skeleton.
var bone_poses: Array[VbgSavedBonePose]



func clone() -> VbgSavedSkeletonPose:
	var copy := VbgSavedSkeletonPose.new()
	copy.skeleton = skeleton
	copy.bone_poses = []
	copy.bone_poses.resize(bone_poses.size())

	var bone_index := 0
	for bone_pose in bone_poses:
		var bone_pose_copy := VbgSavedBonePose.new()
		bone_pose_copy.rotation = bone_pose.rotation
		bone_pose_copy.position = bone_pose.position
		bone_pose_copy.scale = bone_pose.scale
		copy.bone_poses[bone_index] = bone_pose_copy
		bone_index += 1

	return copy


func save_current_pose() -> void:
	save_current_pose_from_compatible_skeleton(skeleton)


func save_current_pose_from_compatible_skeleton(source_skeleton: Skeleton3D) -> void:
	# NOTE: It is assumed this skeleton is compatible with the original one in terms of bone
	#  order and bone count.

	if !source_skeleton:
		return
		
	var bone_count := source_skeleton.get_bone_count()
	var new_bone_poses: Array[VbgSavedBonePose] = []
	new_bone_poses.resize(bone_count)

	for bone_index in bone_count:
		var bone_pose := VbgSavedBonePose.new()
		bone_pose.rotation = source_skeleton.get_bone_pose_rotation(bone_index)
		bone_pose.position = source_skeleton.get_bone_pose_position(bone_index)
		bone_pose.scale = source_skeleton.get_bone_pose_scale(bone_index)
		new_bone_poses[bone_index] = bone_pose

	bone_poses = new_bone_poses


func apply_to_compatible_skeleton(target_skeleton: Skeleton3D) -> void:
	# NOTE: It is assumed this skeleton is compatible with the original one in terms of bone
	#  order and bone count.

	var bone_count := target_skeleton.get_bone_count()
	for bone in bone_count:
		var saved_bone_pose := bone_poses[bone]
		if saved_bone_pose:
			skeleton.set_bone_pose_rotation(bone, saved_bone_pose.rotation)
			skeleton.set_bone_pose_position(bone, saved_bone_pose.position)
			skeleton.set_bone_pose_scale(bone, saved_bone_pose.scale)


func blend_to_pose(other_pose: VbgSavedSkeletonPose, weight: float, bone_filter: VbgBoneFilter) -> void:
	# Blend in place towards another saved pose with a compatible skeleton.
	if !other_pose:
		return

	var bone_count := skeleton.get_bone_count()
	for bone in bone_count:
		var bone_blend_weight := weight
		if bone_filter:
			bone_blend_weight *= bone_filter.get_bone_weight(bone)

		if bone_blend_weight == 0.0:
			continue

		var bone_pose := bone_poses[bone]
		var other_bone_pose := other_pose.bone_poses[bone]

		bone_pose.rotation = lerp(bone_pose.rotation, other_bone_pose.rotation, bone_blend_weight)
		bone_pose.position = lerp(bone_pose.position, other_bone_pose.position, bone_blend_weight)
		bone_pose.scale = lerp(bone_pose.scale, other_bone_pose.scale, bone_blend_weight)


func blend_to_anim_frame(anim: Animation, frame_anim_time: float, track_to_bone_index: VbgTrackToBoneIndex, weight: float, bone_filter: VbgBoneFilter) -> void:
	var bone_count := skeleton.get_bone_count()
	for bone in bone_count:
		var bone_blend_weight := weight
		if bone_filter:
			bone_blend_weight *= bone_filter.get_bone_weight(bone)

		if bone_blend_weight == 0.0:
			continue

		var bone_pose := bone_poses[bone]

		var rotation_track := track_to_bone_index.get_track_for_bone_rotation(bone)
		var position_track := track_to_bone_index.get_track_for_bone_position(bone)
		var scale_track := track_to_bone_index.get_track_for_bone_scale(bone)

		if rotation_track != -1:
			var target_bone_rotation := anim.rotation_track_interpolate(rotation_track, frame_anim_time)
			bone_pose.rotation = lerp(bone_pose.rotation, target_bone_rotation, bone_blend_weight)

		if position_track != -1:
			var target_bone_pos := anim.position_track_interpolate(position_track, frame_anim_time)
			bone_pose.position = lerp(bone_pose.position, target_bone_pos, bone_blend_weight)

		if scale_track != -1:
			var target_bone_scale := anim.scale_track_interpolate(scale_track, frame_anim_time)
			bone_pose.scale = lerp(bone_pose.scale, target_bone_scale, bone_blend_weight)

