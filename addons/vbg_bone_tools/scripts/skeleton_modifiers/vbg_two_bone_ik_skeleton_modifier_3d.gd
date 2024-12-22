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
class_name VbgTwoBoneIkSkeletonModifier3d extends SkeletonModifier3D

@export_enum(" ") var bone_name: String

@export var target: Node3D

@export var align_target_rotation: bool = false


func _validate_property(property: Dictionary) -> void:
	if property.name == "bone_name":
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()


func _process_modification() -> void:
	_process_step()
	# Sometimes requires two steps to get to desired position.
	_process_step()


func _process_step() -> void:
	# REFERENCE: 
	#   The following site contains a very detailed explanation of two bone IK math:
	#		https://theorangeduck.com/page/simple-two-joint
	#	The law of cosines can be used to calculate angles within triangles when you know the side lengths:
	#		https://en.wikipedia.org/wiki/Law_of_cosines

	var skeleton := get_skeleton()
	var move_bone := skeleton.find_bone(bone_name)
	if move_bone == -1 || !target:
		return

	var move_bone_transform := skeleton.get_bone_global_pose(move_bone)

	var bone2 := skeleton.get_bone_parent(move_bone)
	var bone1 := skeleton.get_bone_parent(bone2)

	var bone1_transform := skeleton.get_bone_global_pose(bone1)
	var bone1_global_rotation := Quaternion(bone1_transform.basis)
	var bone1_global_rotation_inverse := bone1_global_rotation.inverse()

	var bone2_transform := skeleton.get_bone_global_pose(bone2)
	var bone2_global_rotation := Quaternion(bone2_transform.basis)
	var bone2_global_rotation_inverse := bone2_global_rotation.inverse()

	# Determine target position in local coordinates.
	var target_pos := skeleton.global_transform.inverse() * target.global_position

	# a: Position at head of bone1
	# b: Position at head of bone2
	# c: Position at tail of bone2

	var a_pos := bone1_transform.origin
	var b_pos := bone2_transform.origin
	var c_pos := skeleton.get_bone_global_pose(move_bone).origin

	var c_minus_a := c_pos - a_pos
	var b_minus_a := b_pos - a_pos
	var c_minus_b := c_pos - b_pos
	var target_minus_a := target_pos - a_pos

	var dir_to_c_from_a := c_minus_a.normalized()
	var dir_to_b_from_a := b_minus_a.normalized()
	var dir_to_a_from_b := -dir_to_b_from_a
	var dir_to_c_from_b := c_minus_b.normalized()
	var dir_to_target_from_a := target_minus_a.normalized()

	var length_bone1_squared := b_minus_a.length_squared()
	var length_bone1 := sqrt(length_bone1_squared)

	var length_bone2_squared := c_minus_b.length_squared()
	var length_bone2 := sqrt(length_bone2_squared)

	# Target length will be limited by total length of the two bones (but we apply a small epsilon to 
	# keep bones from being completely folder on top of eachother or completely straight).
	var epsilon := 0.01
	var dist_to_target_squared := target_minus_a.length_squared()
	var dist_to_target := sqrt(dist_to_target_squared)
	var max_dist_to_target := length_bone1 + length_bone2 - epsilon
	if dist_to_target < epsilon:
		dist_to_target = epsilon
		dist_to_target_squared = dist_to_target * dist_to_target
	elif dist_to_target > max_dist_to_target:
		dist_to_target_squared = dist_to_target * dist_to_target

	#
	# Contraction or extension to get the moving bone to the expected distance from first joint.
	#
	var contraction_extension_axis := dir_to_c_from_a.cross(dir_to_b_from_a).normalized()

	var current_angle_between_bones_1_and_2 := acos(dir_to_a_from_b.dot(dir_to_c_from_b))
	# The following is calculated using the law of cosines given that we know how far away we want the tail of bone 2 
	# to be away from the head of bone 1.
	var desired_angle_between_bones_1_and_2 := acos((dist_to_target_squared - length_bone1_squared - length_bone2_squared) / (-2.0 * length_bone1 * length_bone2))

	var bone2_local_rotation := skeleton.get_bone_pose_rotation(bone2)
	var bone2_contraction_extension_rotation: Quaternion = Quaternion(bone2_global_rotation_inverse * contraction_extension_axis, desired_angle_between_bones_1_and_2 - current_angle_between_bones_1_and_2)
	var new_bone2_local_rotation := bone2_local_rotation * bone2_contraction_extension_rotation
	skeleton.set_bone_pose_rotation(bone2, new_bone2_local_rotation)
	
	#
	# Rotate the first joint so that move_bone is aligned with the target position.
	#
	var overall_swing_axis := dir_to_c_from_a.cross(dir_to_target_from_a).normalized()

	# Figure out amount to rotate around the contraction or extension axis so that the tail of bone 2 stays on
	# the same line (if you drew a line from tail of bone 2's original position to the head of bone 1).
	var current_ac_ab_angle := acos(dir_to_c_from_a.dot(dir_to_b_from_a))
	var desired_ac_ab_angle := acos((length_bone2_squared - length_bone1_squared - dist_to_target_squared) / (-2.0 * length_bone1 * dist_to_target))
	var ac_ab_adjustment_rotation: Quaternion = Quaternion(bone1_global_rotation_inverse * contraction_extension_axis, desired_ac_ab_angle - current_ac_ab_angle)

	# Figure out amount you need to swing the whole bone chain to align the tail of bone 2 with the target position.
	var swing_angle := acos(dir_to_c_from_a.dot(dir_to_target_from_a))
	var swing_rotation: Quaternion = Quaternion(bone1_global_rotation_inverse * overall_swing_axis, swing_angle)

	# Apply rotations to bone 1 in local space.
	var bone1_local_rotation := skeleton.get_bone_pose_rotation(bone1)
	var new_bone1_local_rotation := bone1_local_rotation * (ac_ab_adjustment_rotation * swing_rotation)
	skeleton.set_bone_pose_rotation(bone1, new_bone1_local_rotation)


	# See if we should align the move bone to the axes of the target object.
	if align_target_rotation:
		_align_bone_to_target_object_axes(skeleton, move_bone, target)



func _align_bone_to_target_object_axes(skeleton: Skeleton3D, move_bone: int, target: Node3D) -> void:
	if !skeleton || !target:
		return

	# This method assumes that target's forward (z negative) will point down the length of the bone where the bone will point to.
	# Since the positive y-axis of the bone points down the bone, we will first align the negative-z axis of target to
	# the positive z axis of the target. And, then we'll do a roll around that axis to align one of the other axes.

	var parent_bone := skeleton.get_bone_parent(move_bone)
	var move_bone_rest_pose := skeleton.get_bone_rest(move_bone)
	var parent_bone_pose := skeleton.get_bone_global_pose(parent_bone)
	var move_bone_global_pose_with_rest := parent_bone_pose * move_bone_rest_pose
	var move_bone_global_rest_basis := move_bone_global_pose_with_rest.basis.orthonormalized()

	var target_pose_rel_to_skeleton := (skeleton.global_transform.inverse() * target.global_transform)
	var target_rel_to_skeleton_basis := target_pose_rel_to_skeleton.basis.orthonormalized()

	# Align the -y axis of bone with z axis of target.
	var move_bone_global_pose := skeleton.get_bone_global_pose(move_bone)
	var adjustment := Quaternion(-move_bone_global_rest_basis.y, target_rel_to_skeleton_basis.z)
	move_bone_global_pose.basis =  Basis(adjustment) * move_bone_global_rest_basis

	# That will align one of the three axes together, but we still need to do one more to properly align the axes.

	# IMPORTANT!!!: I tried just using Quaternion(vector1, vector2) to do the final adjustment below, but it creates
	#   instability and jumping around at certain points. The following method provides consistent, desired behavior.

	# Align x to x.
	var final_axis := target_rel_to_skeleton_basis.z
	var final_angle := acos(move_bone_global_pose.basis.x.dot(target_rel_to_skeleton_basis.x))
	var adjustment2: Quaternion
	# We need to see which side of the following plane we are on to decide if we need to use that
	# angle as a positive or negative in our roll.
	var plane := Plane(Vector3.ZERO, target_rel_to_skeleton_basis.z, target_rel_to_skeleton_basis.x)
	var dist := plane.distance_to(move_bone_global_pose.basis.x)
	if dist >= 0:
		adjustment2 = Quaternion(final_axis, final_angle)
	else:
		adjustment2 = Quaternion(final_axis, -final_angle)
	move_bone_global_pose.basis =  Basis(adjustment2) * Basis(adjustment) * move_bone_global_rest_basis
	skeleton.set_bone_global_pose(move_bone, move_bone_global_pose)

