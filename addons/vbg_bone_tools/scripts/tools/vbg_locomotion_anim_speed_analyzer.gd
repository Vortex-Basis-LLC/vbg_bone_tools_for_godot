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
class_name VbgLocomotionAnimSpeedAnalyzer extends RefCounted


static func detect_speed_from_left_toes(skeleton: Skeleton3D, anim: Animation, on_ground_y_threshold: float = 0.001) -> float:
	# Time LeftToes spend on the ground below on_ground_y_threshold will be used to estimate the forward speed of the animation.
	# It is assumed that -Z is forward.

	if !skeleton || !anim:
		return -1

	var track_to_bone_index :=  VbgTrackToBoneIndex.new(skeleton, anim)

	var left_toe := skeleton.find_bone("LeftToes")

	# Remember the original pose since we will overwrite the pose.
	var original_pose := VbgSavedSkeletonPose.new()
	original_pose.skeleton = skeleton
	original_pose.save_current_pose()

	# For each frame of the animation, check position of LeftToes bone on the ground and use that to estimate implied locomotion speed.
	var frame_scanner := VbgBipedalLocomotionAnimFrameScanner.new()
	frame_scanner.anim = anim
	frame_scanner.track_to_bone_index = track_to_bone_index
	frame_scanner.skeleton = skeleton

	frame_scanner.first_pass()
	
	# Restore the original pose.
	original_pose.apply_to_compatible_skeleton(skeleton)

	return frame_scanner.out_estimated_speed_by_left_toe
