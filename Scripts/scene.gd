extends Node

const window_half_width := 160
const window_half_height := 120

export(int) var scene_width = 320
export(int) var scene_height = 240

func _camera(x : float, y : float):
	var canvas := get_viewport().canvas_transform
	canvas.origin = Vector2(-(clamp(round(x), window_half_width, scene_width - window_half_width) - window_half_width), -(clamp(round(y), window_half_height, scene_height - window_half_height) - window_half_height))
	get_viewport().canvas_transform = canvas
