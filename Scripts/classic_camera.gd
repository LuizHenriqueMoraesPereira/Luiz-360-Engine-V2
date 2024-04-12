extends Node2D

const window_half_width : int = 160
const window_half_height : int = 120

var camera_x : float
var camera_y : float
var min_x : float
var min_y : float
var max_x : float
var max_y : float
var shift_x : float
var shift_y : float
var ground_offset : float
var ground_old : bool

export(float) var margin_l = -16.0
export(float) var margin_r = 0.0
export(float) var margin_t = -48.0
export(float) var margin_b = 16.0

onready var scene : Node = $".."
onready var target : Node2D = $"../Player"

func _ready():
	camera_x = target.global_position.x
	camera_y = target.global_position.y
	
	max_x = scene.scene_width
	max_y = scene.scene_height

func _physics_process(delta):
	var delta_time : float = float(60.0 * delta)
	
	if not target == null:
		if target.ground:
			if not target.ground == ground_old:
				ground_offset = camera_y - target.global_position.y
			
			if abs(ground_offset) > 0.0:
				ground_offset = max(abs(ground_offset) - (4.0 * delta_time), 0.0) * sign(ground_offset)
			
			camera_y = clamp(target.global_position.y + ground_offset, min_y + window_half_height, max_y - window_half_height)
		
		if target.global_position.x < camera_x + margin_l and camera_x > min_x + window_half_width:
			camera_x = target.global_position.x - margin_l
		
		if target.global_position.x > camera_x + margin_r and camera_x < max_x - window_half_width:
			camera_x = target.global_position.x - margin_r
		
		if not target.ground:
			if target.global_position.y < camera_y + margin_t and camera_y > min_y + window_half_height:
				camera_y = target.global_position.y - margin_t
			
			if target.global_position.y > camera_y + margin_b and camera_y < max_y - window_half_height:
				camera_y = target.global_position.y - margin_b
		
		ground_old = target.ground
	
	global_position.x = clamp(camera_x, window_half_width, scene.scene_width - window_half_width)
	global_position.y = clamp(camera_y, window_half_height, scene.scene_height - window_half_height)
