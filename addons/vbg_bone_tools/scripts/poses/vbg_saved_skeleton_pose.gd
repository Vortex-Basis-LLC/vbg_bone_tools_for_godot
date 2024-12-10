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


func apply_to_compatible_skeleton(target_skeleton: Skeleton3D):
	# NOTE: It is assumed this skeleton is compatible with the original one in terms of bone
	#  order and bone count.

	var bone_count := target_skeleton.get_bone_count()
	for bone in bone_count:
		var saved_bone_pose := bone_poses[bone]
		if saved_bone_pose:
			skeleton.set_bone_pose_rotation(bone, saved_bone_pose.rotation)
			skeleton.set_bone_pose_position(bone, saved_bone_pose.position)
			skeleton.set_bone_pose_scale(bone, saved_bone_pose.scale)