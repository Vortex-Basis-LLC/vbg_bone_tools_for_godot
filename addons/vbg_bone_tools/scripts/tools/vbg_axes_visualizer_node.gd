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
class_name VbgAxesVisualizerNode extends Node3D

enum AXIS_MARKER_SHAPE { SPHERE, BOX }

@export var node_to_track: Node3D:
	set(value):
		node_to_track = value
		_setup_markers()
		notify_property_list_changed()
		if !(node_to_track is Skeleton3D):
			bone_name = ""
			_try_unsubscribe_from_skeleton_updated()
		else:
			_check_if_need_to_subscribe_to_skeleton_updated()


@export_enum(" ") var bone_name: String

@export var marker_shape: AXIS_MARKER_SHAPE:
	set(value):
		marker_shape = value
		_setup_markers()

# Distance from origin at which to display the marker.
@export var marker_offset: float = 0.2

# Size of marker.
@export var marker_scale: float = 0.1:
	set(value):
		marker_scale = value
		_setup_markers()


var _ready_has_been_called := false
var _subscribed_to_skeleton_update_on: Skeleton3D = null

var _x_marker: MeshInstance3D
var _y_marker: MeshInstance3D
var _z_marker: MeshInstance3D
var _neg_x_marker: MeshInstance3D
var _neg_y_marker: MeshInstance3D
var _neg_z_marker: MeshInstance3D


func _validate_property(property: Dictionary) -> void:
	if property.name == "bone_name":
		var skeleton: Skeleton3D = node_to_track as Skeleton3D
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()


func _ready() -> void:
	_ready_has_been_called = true
	_check_if_need_to_subscribe_to_skeleton_updated()
	_setup_markers()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			_check_if_need_to_subscribe_to_skeleton_updated()
		NOTIFICATION_EXIT_TREE:
			_try_unsubscribe_from_skeleton_updated()
		NOTIFICATION_PREDELETE:
			_try_unsubscribe_from_skeleton_updated()


func _try_unsubscribe_from_skeleton_updated() -> void:
	if _subscribed_to_skeleton_update_on:
		if is_instance_valid(_subscribed_to_skeleton_update_on):
			_subscribed_to_skeleton_update_on.skeleton_updated.disconnect(_skeleton_updated)
		_subscribed_to_skeleton_update_on = null

func _check_if_need_to_subscribe_to_skeleton_updated() -> void:
	var skeleton := node_to_track as Skeleton3D
	if skeleton:
		# If we haven't already subscribed to skeleton updated, subscribe now.
		if node_to_track != _subscribed_to_skeleton_update_on:
			_try_unsubscribe_from_skeleton_updated()
			skeleton.skeleton_updated.connect(_skeleton_updated)
			_subscribed_to_skeleton_update_on = skeleton
	else:
		_try_unsubscribe_from_skeleton_updated()


func _setup_markers() -> void:
	if !_ready_has_been_called:
		return

	if _x_marker:
		_x_marker.queue_free()
	if _y_marker:
		_y_marker.queue_free()
	if _z_marker:
		_z_marker.queue_free()
	if _neg_x_marker:
		_neg_x_marker.queue_free()
	if _neg_y_marker:
		_neg_y_marker.queue_free()
	if _neg_z_marker:
		_neg_z_marker.queue_free()

	_x_marker = _create_marker(Color(1,0,0))
	_y_marker = _create_marker(Color(0,1,0))
	_z_marker = _create_marker(Color(0,0,1))

	_neg_x_marker = _create_marker(Color(0.35,0,0))
	_neg_y_marker = _create_marker(Color(0,0.35,0))
	_neg_z_marker = _create_marker(Color(0,0,0.35))


func _create_marker(color: Color) -> MeshInstance3D:
	var marker = MeshInstance3D.new()

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	marker.material_override = mat

	if marker_shape == AXIS_MARKER_SHAPE.SPHERE:
		var shape := SphereMesh.new()
		shape.radius = marker_scale / 2
		shape.height = marker_scale
		marker.mesh = shape
	elif marker_shape == AXIS_MARKER_SHAPE.BOX:
		var shape := BoxMesh.new()
		shape.size = Vector3(marker_scale * 0.75, marker_scale * 0.75, marker_scale * 0.75)
		marker.mesh = shape

	add_child(marker)
	return marker


func _skeleton_updated() -> void:
	_update_marker_positions()


func _process(delta: float) -> void:
	if _subscribed_to_skeleton_update_on:
		return

	_update_marker_positions()


func _update_marker_positions() -> void:
	if !node_to_track:
		return

	if !is_instance_valid(node_to_track):
		_try_unsubscribe_from_skeleton_updated()
		return

	var target_space: Transform3D = node_to_track.global_transform
	if !bone_name.is_empty() && node_to_track is Skeleton3D:
		var skeleton := node_to_track as Skeleton3D
		var bone := skeleton.find_bone(bone_name)
		if bone != -1:
			target_space = target_space * skeleton.get_bone_global_pose(bone)

	if _x_marker:
		_x_marker.global_position = target_space * Vector3(marker_offset, 0, 0)
	if _y_marker:
		_y_marker.global_position = target_space * Vector3(0, marker_offset, 0)
	if _z_marker:
		_z_marker.global_position = target_space * Vector3(0, 0, marker_offset)
	if _neg_x_marker:
		_neg_x_marker.global_position = target_space * Vector3(-marker_offset, 0, 0)
	if _neg_y_marker:
		_neg_y_marker.global_position = target_space * Vector3(0, -marker_offset, 0)
	if _neg_z_marker:
		_neg_z_marker.global_position = target_space * Vector3(0, 0, -marker_offset)