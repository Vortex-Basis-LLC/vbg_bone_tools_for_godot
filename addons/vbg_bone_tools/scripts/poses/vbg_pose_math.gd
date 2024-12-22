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
class_name VbgPoseMath extends RefCounted


## Modify pose of the selected bone so that its axes in rest pose will be aligned
## with specified axes of the target axes (where target_basis is in the world's global space).
static func align_bone_to_target_global_basis_and_offset_by_rest_pose(
		skeleton: Skeleton3D, 
		move_bone: int, 
		target_basis: Basis,
		bone_y_axis_to_target_axis: Vector3 = Vector3(0, 0, -1),
		bone_x_axis_to_target_axis: Vector3 = Vector3(1, 0, 0)
	) -> void:

	var target_basis_in_skeleton_space := (skeleton.global_transform.basis.inverse() * target_basis).orthonormalized()
	align_bone_to_target_basis_in_skeleton_space_and_offset_by_rest_pose(skeleton, move_bone, target_basis_in_skeleton_space, bone_y_axis_to_target_axis, bone_x_axis_to_target_axis)


## Modify pose of the selected bone so that it's axes in rest pose will be aligned
## with specified axes of the target axes (where target_basis is in skeleton's space).
static func align_bone_to_target_basis_in_skeleton_space_and_offset_by_rest_pose(
		skeleton: Skeleton3D, 
		move_bone: int, 
		target_basis_in_skeleton_space: Basis,
		bone_y_axis_to_target_axis: Vector3 = Vector3(0, 0, -1),
		bone_x_axis_to_target_axis: Vector3 = Vector3(1, 0, 0)
	) -> void:

	if !skeleton:
		return

	# This method assumes that target's forward (z negative) will point down the length of the bone where the bone will point to.
	# Since the positive y-axis of the bone points down the bone, we will first align the negative-z axis of target to
	# the positive z axis of the target. And, then we'll do a roll around that axis to align one of the other axes.

	var parent_bone := skeleton.get_bone_parent(move_bone)
	var move_bone_rest_pose := skeleton.get_bone_rest(move_bone)
	var parent_bone_pose := skeleton.get_bone_global_pose(parent_bone)
	var move_bone_global_pose_with_rest := parent_bone_pose * move_bone_rest_pose
	var move_bone_global_rest_basis := move_bone_global_pose_with_rest.basis.orthonormalized()

	# Align the -y axis of bone with specified axis of target.
	var initial_target_axis := target_basis_in_skeleton_space * bone_y_axis_to_target_axis

	var move_bone_global_pose := skeleton.get_bone_global_pose(move_bone)
	var adjustment := Quaternion(move_bone_global_rest_basis.y, initial_target_axis)
	move_bone_global_pose.basis =  Basis(adjustment) * move_bone_global_rest_basis

	# That will align one of the three axes together, but we still need to do one more to properly align the axes.

	# IMPORTANT!!!: I tried just using Quaternion(vector1, vector2) to do the final adjustment below, but it creates
	#   instability and jumping around at certain points. The following method provides consistent, desired behavior.

	# Align x to x.
	var second_axis := target_basis_in_skeleton_space * bone_x_axis_to_target_axis
	var final_angle := acos(move_bone_global_pose.basis.x.dot(second_axis))
	var adjustment2: Quaternion
	# We need to see which side of the following plane we are on to decide if we need to use that
	# angle as a positive or negative in our roll.
	var plane := Plane(Vector3.ZERO, initial_target_axis, second_axis)
	var dist := plane.distance_to(move_bone_global_pose.basis.x)
	if dist >= 0:
		adjustment2 = Quaternion(initial_target_axis, final_angle)
	else:
		adjustment2 = Quaternion(initial_target_axis, -final_angle)
	move_bone_global_pose.basis =  Basis(adjustment2) * Basis(adjustment) * move_bone_global_rest_basis
	skeleton.set_bone_global_pose(move_bone, move_bone_global_pose)





## Modify pose of the selected bone so that its y-axis will be aligned
## with the target axis in global space.
static func align_bone_to_single_axis_in_global_space(
		skeleton: Skeleton3D, 
		move_bone: int, 
		target_axis_in_global_space: Vector3
	) -> void:

	if !skeleton:
		return

	var target_axis_in_skeleton_space := skeleton.global_transform.basis.inverse() * target_axis_in_global_space

	align_bone_to_single_axis_in_skeleton_space(skeleton, move_bone, target_axis_in_skeleton_space)


## Modify pose of the selected bone so that its y-axis will be aligned
## with the target axis in skeleton space.
static func align_bone_to_single_axis_in_skeleton_space(
		skeleton: Skeleton3D, 
		move_bone: int, 
		target_axis_in_skeleton_space: Vector3
	) -> void:

	if !skeleton:
		return

	var bone_pose := skeleton.get_bone_global_pose(move_bone).orthonormalized()

	var adjustment := Quaternion(bone_pose.basis.y, target_axis_in_skeleton_space)
	bone_pose.basis = bone_pose.basis * Basis(adjustment)

	skeleton.set_bone_global_pose(move_bone, bone_pose)
