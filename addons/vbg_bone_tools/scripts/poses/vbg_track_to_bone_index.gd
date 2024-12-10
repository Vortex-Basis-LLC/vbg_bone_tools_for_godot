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
class_name VbgTrackToBoneIndex extends RefCounted

var skeleton: Skeleton3D
var anim: Animation

var bone_position_tracks: Array[int]
var bone_rotation_tracks: Array[int]
var bone_scale_tracks: Array[int]

var tracks_to_bones: Array[int]


func _init(skeleton: Skeleton3D, anim: Animation) -> void:
	self.skeleton = skeleton
	self.anim = anim

	var bone_count := skeleton.get_bone_count() if skeleton else 0
	var track_count := anim.get_track_count() if anim else 0

	bone_position_tracks = []
	bone_position_tracks.resize(bone_count)
	bone_rotation_tracks = []
	bone_rotation_tracks.resize(bone_count)
	bone_scale_tracks = []
	bone_scale_tracks.resize(bone_count)

	tracks_to_bones = []
	tracks_to_bones.resize(track_count)

	for bone_index in bone_count:
		bone_position_tracks[bone_index] = -1
		bone_rotation_tracks[bone_index] = -1
		bone_scale_tracks[bone_index] = -1

	for track_index in track_count:
		tracks_to_bones[track_index] = -1

	if anim && skeleton:
		for track_index in anim.get_track_count():
			var track_path := anim.track_get_path(track_index)
			var bone_name := track_path.get_concatenated_subnames()
			var track_type := anim.track_get_type(track_index)
			var bone := skeleton.find_bone(bone_name)
			if bone != -1:
				tracks_to_bones[track_index] = bone
				if track_type == Animation.TrackType.TYPE_ROTATION_3D:
					bone_rotation_tracks[bone] = track_index
				elif track_type == Animation.TrackType.TYPE_POSITION_3D:
					bone_position_tracks[bone] = track_index
				elif track_type == Animation.TrackType.TYPE_SCALE_3D:
					bone_scale_tracks[bone] = track_index


func get_bone_index_for_track_index(track_index: int) -> int:
	return tracks_to_bones[track_index]

func get_track_for_bone_rotation(bone_index) -> int:
	return bone_rotation_tracks[bone_index]

func get_track_for_bone_position(bone_index) -> int:
	return bone_position_tracks[bone_index]

func get_track_for_bone_scale(bone_index) -> int:
	return bone_scale_tracks[bone_index]