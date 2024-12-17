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

extends CharacterBody3D


var target_velocity: Vector3 = Vector3.ZERO

@onready var _visuals: Node3D = %Visuals
@onready var _walk_run_mod: VbgWalkRunSkeletonModifier3d = %WalkRunMod

func _physics_process(delta: float) -> void:
	if !is_on_floor():
		velocity = velocity + Vector3.DOWN * delta * 20.0

	var input_dir := Input.get_vector("move_left", "move_right", "move_backward", "move_forward")

	var move_dir := _get_camera_relative_move_vector(input_dir, get_viewport().get_camera_3d())

	target_velocity = move_dir * 1.6
	if Input.is_action_pressed("run"):
		target_velocity *= 3.0

	velocity = velocity.move_toward(target_velocity, abs(delta * 5.0))

	var dir := velocity.normalized()
	if velocity.length() > 0.01:
		# Rotate character toward direction of movement.
		var prior_global_rotation_y = _visuals.global_rotation.y
		var angular_speed = 2*PI
		var new_global_rotation_y = _rotate_angle_toward_target_angle(prior_global_rotation_y, atan2(-dir.x, -dir.z), delta * angular_speed)
		_visuals.global_rotation.y = new_global_rotation_y


	# Have camera follow character.
	var cam_pos := global_position
	cam_pos.y += 1.5
	cam_pos.z += 3.0
	get_viewport().get_camera_3d().global_position = cam_pos

	if velocity.length() > 0.01:
		_walk_run_mod.influence = 1.0
		_walk_run_mod.current_velocity = velocity.length()
	else:
		_walk_run_mod.influence = 0.0

	move_and_slide()


func _rotate_angle_toward_target_angle(start_angle: float, target_angle: float, radians: float) -> float:
	var diff := angle_difference(start_angle, target_angle)
	var amount_to_rotate := radians
	if is_finite(amount_to_rotate) && !is_nan(amount_to_rotate):
		if absf(amount_to_rotate) > absf(diff):
			amount_to_rotate = diff
			
		if is_zero_approx(diff):
			return target_angle
			
		var ratio := absf(amount_to_rotate / diff)
		var new_angle = lerp_angle(start_angle, target_angle, ratio)
		return new_angle
	else:
		return start_angle


func _get_camera_relative_move_vector(input_vector: Vector2, camera: Camera3D) -> Vector3:
	# move_vector should be 2D vector where (0,1) is up, (1,0) is right, (-1, 0) is left, and (0,-1) is down on
	# the input axes.

	var world_move_vector := Vector3(input_vector.x, 0, -input_vector.y)
	var cam_relative_world_move_vector := world_move_vector.rotated(Vector3.UP, camera.global_rotation.y)
	return cam_relative_world_move_vector