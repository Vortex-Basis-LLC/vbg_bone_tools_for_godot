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
class_name VbgBipedalLocomotionAnimFrameScanner extends RefCounted



var anim: Animation
var track_to_bone_index: VbgTrackToBoneIndex
var skeleton: Skeleton3D

var _min_left_toe_pos: Vector3
var _max_left_toe_pos: Vector3
var _min_right_toe_pos: Vector3
var _max_right_toe_pos: Vector3

var _anim_frame_count: int
var _left_toe_pos_by_frame: Array[Vector3]


# Walk cycle start position is where the left thigh is passing back behind the right thigh as right thigh moves forward.
var out_walk_cycle_start_time: float
# This should be the offset as a percentage of anim.length where the walk cycle start position is.
var out_walk_cycle_start_ratio_offset: float
var out_estimated_speed_by_left_toe: float




func first_pass() -> void:
	_anim_frame_count = round(anim.length / anim.step) + 1

	var anim_pose := VbgSavedSkeletonPose.new()
	anim_pose.skeleton = skeleton

	var left_toe := skeleton.find_bone("LeftToes")
	var right_toe := skeleton.find_bone("RightToes")

	var left_lower_leg := skeleton.find_bone("LeftLowerLeg")
	var right_lower_leg := skeleton.find_bone("RightLowerLeg")

	# Initialize state using the final frame of the animation.
	var last_frame_anim_time = anim.length - anim.step
	anim_pose.blend_to_anim_frame(anim, last_frame_anim_time, track_to_bone_index, 1.0, null)
	anim_pose.apply_to_compatible_skeleton(skeleton)

	var left_toe_transform := skeleton.get_bone_global_pose(left_toe)
	var left_toe_pos := left_toe_transform.origin

	var right_toe_transform := skeleton.get_bone_global_pose(right_toe)
	var right_toe_pos := right_toe_transform.origin

	var left_lower_leg_transform := skeleton.get_bone_global_pose(left_lower_leg)
	var left_lower_leg_pos := left_lower_leg_transform.origin

	var right_lower_leg_transform := skeleton.get_bone_global_pose(right_lower_leg)
	var right_lower_leg_pos := right_lower_leg_transform.origin

	_min_left_toe_pos = left_toe_pos
	_max_left_toe_pos = left_toe_pos
	_min_right_toe_pos = right_toe_pos
	_max_right_toe_pos = right_toe_pos

	var last_left_toe_pos := left_toe_pos
	var last_right_toe_pos := right_toe_pos

	var last_left_lower_leg_pos := left_lower_leg_pos
	var last_right_lower_leg_pos := right_lower_leg_pos
	
	_left_toe_pos_by_frame = []
	_left_toe_pos_by_frame.resize(_anim_frame_count)

	var anim_frame: int = 0
	var anim_time: float = 0
	while anim_time <= anim.length:
		anim_pose.blend_to_anim_frame(anim, anim_time, track_to_bone_index, 1.0, null)
		anim_pose.apply_to_compatible_skeleton(skeleton)

		left_toe_transform = skeleton.get_bone_global_pose(left_toe)
		left_toe_pos = left_toe_transform.origin
		_left_toe_pos_by_frame[anim_frame] = left_toe_pos

		right_toe_transform = skeleton.get_bone_global_pose(right_toe)
		right_toe_pos = right_toe_transform.origin

		left_lower_leg_transform = skeleton.get_bone_global_pose(left_lower_leg)
		left_lower_leg_pos = left_lower_leg_transform.origin

		right_lower_leg_transform = skeleton.get_bone_global_pose(right_lower_leg)
		right_lower_leg_pos = right_lower_leg_transform.origin

		_min_left_toe_pos.x = min(_min_left_toe_pos.x, left_toe_pos.x)
		_min_left_toe_pos.y = min(_min_left_toe_pos.y, left_toe_pos.y)
		_min_left_toe_pos.z = min(_min_left_toe_pos.z, left_toe_pos.z)

		_max_left_toe_pos.x = min(_max_left_toe_pos.x, left_toe_pos.x)
		_max_left_toe_pos.y = min(_max_left_toe_pos.y, left_toe_pos.y)
		_max_left_toe_pos.z = min(_max_left_toe_pos.z, left_toe_pos.z)

		_min_right_toe_pos.x = min(_min_right_toe_pos.x, right_toe_pos.x)
		_min_right_toe_pos.y = min(_min_right_toe_pos.y, right_toe_pos.y)
		_min_right_toe_pos.z = min(_min_right_toe_pos.z, right_toe_pos.z)

		_max_right_toe_pos.x = min(_max_right_toe_pos.x, right_toe_pos.x)
		_max_right_toe_pos.y = min(_max_right_toe_pos.y, right_toe_pos.y)
		_max_right_toe_pos.z = min(_max_right_toe_pos.z, right_toe_pos.z)

		if last_left_lower_leg_pos.z >= last_right_lower_leg_pos.z:
			# Left lower leg was previously in front or even with right lower leg.
			if right_lower_leg_pos.z > left_lower_leg_pos.z:
				# Right lower leg is now in front of left lower leg, so the canonical walk cycle should
				# be considered to start here.
				out_walk_cycle_start_time = anim_time
				out_walk_cycle_start_ratio_offset = anim_time / anim.length

		last_left_toe_pos = left_toe_pos
		last_right_toe_pos = right_toe_pos

		last_left_lower_leg_pos = left_lower_leg_pos
		last_right_lower_leg_pos = right_lower_leg_pos

		anim_time += anim.step
		anim_frame += 1

	# Scan for foot on ground, starting at left foot moving back (we will look for where the left toe reaches max z then changes direction)
	var walk_cycle_start_frame: int = round((out_walk_cycle_start_ratio_offset * anim.length) / anim.step)
	var toe_going_back_frame_index: int = _find_frame_left_toe_starting_to_go_back(walk_cycle_start_frame, _anim_frame_count)

	# We'll look at z position of toe going back and go forward 25% of frames and use change in toe's z position to
	# estimate ground speed as our backup guess. We'll try using a possibly better method down below.
	var toe_z_1 = _find_left_toe_pos_for_frame(toe_going_back_frame_index).z
	var go_forward_frames := roundf(_anim_frame_count * 0.25)
	var toe_z_2 = _find_left_toe_pos_for_frame(toe_going_back_frame_index + go_forward_frames).z
	out_estimated_speed_by_left_toe = absf(toe_z_1 - toe_z_2) / (go_forward_frames * anim.step)

	# Second attempt to get speed, but this one relies on foot rising a certain amount off of the floor.
	# The goal is to cover more of the time that the foot is on the floor.
	var left_toe_y_range := _max_left_toe_pos.y - _min_left_toe_pos.y
	var left_toe_rise_threshold := left_toe_y_range * 0.05
	var start_toe_y := _find_left_toe_pos_for_frame(toe_going_back_frame_index).y
	for i in _anim_frame_count:
		var new_y : = _find_left_toe_pos_for_frame(toe_going_back_frame_index + i).y
		# We are looking for a frame where the toe has come off of the ground by the indicated threshold.
		if new_y > (start_toe_y + left_toe_rise_threshold):
			var left_foot_off_ground_frame := _get_frame_index_to_use(toe_going_back_frame_index + i)
			var new_toe_z_2 = _find_left_toe_pos_for_frame(left_foot_off_ground_frame - 1).z
			var new_out_estimated_speed_by_left_toe = absf(toe_z_1 - new_toe_z_2) / ((i - 1) * anim.step)
			out_estimated_speed_by_left_toe = new_out_estimated_speed_by_left_toe
			break


func _get_frame_index_to_use(frame: int) -> int:
	if frame < 0:
		return _anim_frame_count - ((-frame) % _anim_frame_count)
	else:
		return frame % _anim_frame_count

func _find_left_toe_pos_for_frame(frame: int) -> Vector3:
	return _left_toe_pos_by_frame[_get_frame_index_to_use(frame)]

func _find_frame_left_toe_starting_to_go_back(start_frame: int, frames_left_to_look_at: int) -> int:
	var found_moving_forward : = false
	for i in frames_left_to_look_at:
		var frame := start_frame + i
		var prior_z := _find_left_toe_pos_for_frame(frame - 1).z
		var current_z := _find_left_toe_pos_for_frame(frame).z
		if !found_moving_forward:
			if current_z > prior_z:
				found_moving_forward = true
		else:
			if current_z < prior_z && current_z > ((_min_left_toe_pos.z + _max_left_toe_pos.z) / 2.0):
				# We're moving back after having been moving forward and we are in front of the left toe's midpoint position.
				return frame
	
	# Error: Just return start_frame.
	return start_frame
