extends Area2D

export(int) var top_left = 0
export(int) var top_right = 0
export(int) var bottom_left = 0
export(int) var bottom_right = 0
export(bool) var ground_only = false

var entities : Array

func _physics_process(_delta):
	for entity in entities:
		if entity.ground or not ground_only:
			if entity.x_position > global_position.x:
				if entity.y_position > global_position.y:
					entity.layer = bottom_right
				else:
					entity.layer = top_right
			elif entity.y_position > global_position.y:
				entity.layer = bottom_left
			else:
				entity.layer = top_left

func _on_area_entered(area : Area2D):
	if area.get_parent().has_method("_compare_tag"):
		entities.append(area.get_parent())

func _on_area_exited(area : Area2D):
	if area.get_parent().has_method("_compare_tag"):
		entities.erase(area.get_parent())
