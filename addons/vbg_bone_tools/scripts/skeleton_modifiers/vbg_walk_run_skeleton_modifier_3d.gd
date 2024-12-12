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
class_name VbgWalkRunSkeletonModifier3d extends SkeletonModifier3D

# Blend between walk and run animations depending on speed.

@export var walk_anim_ref: VbgAnimRef
@export var walk_anim_speed: float = -1

@export var run_anim_ref: VbgAnimRef
@export var run_anim_speed: float = -1

@export var current_velocity: float = 0

var _walk_cycle_ratio: float = 0.0
var _last_ticks_usec: int = 0

func _ready() -> void:
	_last_ticks_usec = Time.get_ticks_usec()
	_reprocess_anims()


func _reprocess_anims():
	if walk_anim_ref:
		var walk_anim := walk_anim_ref.get_animation()
		walk_anim_speed = VbgLocomotionAnimSpeedAnalyzer.detect_speed_from_left_toes(get_skeleton(), walk_anim)

	if run_anim_ref:
		var run_anim := run_anim_ref.get_animation()
		run_anim_speed = VbgLocomotionAnimSpeedAnalyzer.detect_speed_from_left_toes(get_skeleton(), run_anim)


func _process_modification() -> void:
	var current_ticks_usec = Time.get_ticks_usec()
	var delta: float = float(current_ticks_usec - _last_ticks_usec) / 1000000.0
	self._last_ticks_usec = current_ticks_usec

	var skeleton = get_skeleton()
	if !skeleton:
		return

	if !walk_anim_ref || !run_anim_ref:
		return

	var walk_anim := walk_anim_ref.get_animation()
	var run_anim := run_anim_ref.get_animation()
	if !walk_anim || !run_anim:
		return

	var saved_pose := VbgSavedSkeletonPose.new()
	saved_pose.skeleton = skeleton

	# Figure out how far to advance the walk cycle.
	if current_velocity <= walk_anim_speed:
		# Time-scaled walk.
		var time_scalar :=  walk_anim_speed / current_velocity
		_walk_cycle_ratio = _walk_cycle_ratio + (delta / (walk_anim.length * time_scalar))
	elif current_velocity <= run_anim_speed:
		# Blended-version of walk and run.
		var run_blend_weight := (current_velocity - walk_anim_speed) / (run_anim_speed - walk_anim_speed)
		var time_scalar := float(lerp(walk_anim_speed, run_anim_speed, run_blend_weight)) / current_velocity
		_walk_cycle_ratio = _walk_cycle_ratio + (delta / (walk_anim.length * time_scalar))
	else:
		# Time-scaled run.
		var time_scalar := run_anim_speed / current_velocity
		_walk_cycle_ratio = _walk_cycle_ratio + (delta / (run_anim.length * time_scalar))

	var walk_cycle_ratio_to_use := fmod(_walk_cycle_ratio, 1.0)
	_walk_cycle_ratio = walk_cycle_ratio_to_use

	# Blend animation based on current speed and stage of walk cycle.
	var walk_anim_time := walk_anim.length * walk_cycle_ratio_to_use
	var run_anim_time := run_anim.length * walk_cycle_ratio_to_use

	# TODO: Save the VbgTrackToBoneIndex instances when animations are set or setup in _ready

	if current_velocity <= walk_anim_speed:
		var walk_blend_weight := (current_velocity / walk_anim_speed)
		saved_pose.blend_to_anim_frame(walk_anim, walk_anim.length * walk_cycle_ratio_to_use, VbgTrackToBoneIndex.new(skeleton, walk_anim), 1.0, null)
	elif current_velocity < run_anim_speed:
		# Show blended version of walk and run.
		var run_blend_weight := (current_velocity - walk_anim_speed) / (run_anim_speed - walk_anim_speed)
		saved_pose.blend_to_anim_frame(walk_anim, walk_anim_time, VbgTrackToBoneIndex.new(skeleton, walk_anim), 1.0, null)
		saved_pose.blend_to_anim_frame(run_anim, run_anim_time, VbgTrackToBoneIndex.new(skeleton, run_anim), run_blend_weight, null)
	else:
		# Show sped up version of run.
		saved_pose.blend_to_anim_frame(run_anim, run_anim.length * walk_cycle_ratio_to_use, VbgTrackToBoneIndex.new(skeleton, run_anim), 1.0, null)
	
	# Apply the blended pose.
	saved_pose.apply_to_compatible_skeleton(skeleton)


