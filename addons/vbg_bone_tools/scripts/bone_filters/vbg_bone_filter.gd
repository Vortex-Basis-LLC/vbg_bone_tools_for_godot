class_name VbgBoneFilter extends RefCounted

# Array with one entry for each bone that holds the weight to use for that bone.
var bone_weights: Array[float]

func _init(skeleton: Skeleton3D, bone_filter_config: VbgBoneFilterConfig) -> void:
	if !skeleton:
		bone_weights = []
		return

	var bone_count := skeleton.get_bone_count()
	bone_weights = []
	bone_weights.resize(bone_count)

	if !bone_filter_config:
		# Just use 1.0 weight for all bones.
		for bone in bone_count:
			bone_weights[bone] = 1.0
	else:
		for bone in bone_count:
			bone_weights[bone] = bone_filter_config.default_weight

		if bone_filter_config.entries:
			for entry in bone_filter_config.entries:
				var bone := skeleton.find_bone(entry.bone_name)
				if bone != -1:
					bone_weights[bone] = entry.weight
					if entry.include_children:
						_apply_weight_to_all_child_bones(skeleton, bone, entry.weight)


func _apply_weight_to_all_child_bones(skeleton: Skeleton3D, bone: int, weight: float) -> void:
	var bone_children := skeleton.get_bone_children(bone)
	if bone_children:
		for child_bone in bone_children:
			bone_weights[child_bone] = weight
			_apply_weight_to_all_child_bones(skeleton, child_bone, weight)


func get_bone_weight(bone: int) -> float:
	return bone_weights[bone]