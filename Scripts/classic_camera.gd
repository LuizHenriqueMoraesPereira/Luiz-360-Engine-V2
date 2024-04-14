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
var shift_result_x : float
var shift_result_y : float
var shift_timer : float
var ground_offset : float
var ground_old : bool

export(float) var margin_l = -16.0
export(float) var margin_r = 0.0
export(float) var margin_t = -48.0
export(float) var margin_b = 16.0
export(float) var timer_expire = 120.0
export(float) var shift_limit_h = 64.0
export(float) var shift_limit_v = 96.0

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
		
		if target.action == 2 or target.action == 3:
			if shift_timer < timer_expire:
				shift_timer += delta_time
			else:
				if target.action == 2:
					shift_y = max(shift_y - (2.0 * delta_time), -shift_limit_v)
				if target.action == 3:
					shift_y = min(shift_y + (2.0 * delta_time), shift_limit_v)
		else:
			shift_timer = 0.0
			if abs(shift_y) > 0.0:
				shift_y = max(abs(shift_y) - (2.0 * delta_time), 0.0) * sign(shift_y)
		
		if target.ground and abs(target.ground_speed) >= 5.0 and target.animation_direction == sign(target.ground_speed):
			shift_x = min(abs(shift_x) + (3.0 * delta_time), shift_limit_h) * sign(target.ground_speed)
		
		if target.ground and target.action == 5:
			shift_x = min(abs(shift_x) + (2.5 * delta_time), shift_limit_h) * sign(target.animation_direction)
		
		if abs(shift_x) > 0.0 and not (target.ground and abs(target.ground_speed) >= 5.0 or target.action == 5):
			shift_x = max(abs(shift_x) - (3.0 * delta_time), 0.0) * sign(shift_x)
		
		ground_old = target.ground
	
	if camera_x < min_x + window_half_width:
		camera_x = min(camera_x + (2.0 * delta_time), min_x + window_half_width)
	elif camera_x > max_x - window_half_width:
		camera_x = max(camera_x - (2.0 * delta_time), max_x - window_half_width)
	
	if camera_y < min_y + window_half_height:
		camera_y = min(camera_y + (2.0 * delta_time), min_y + window_half_height)
	elif camera_y > max_y - window_half_height:
		camera_y = max(camera_y - (2.0 * delta_time), max_y - window_half_height)
	
	shift_result_x = shift_x
	shift_result_y = shift_y
	
	if camera_x <= min_x + window_half_width - shift_x:
		shift_result_x = clamp(min_x + window_half_width - camera_x, shift_x, 0.0)
	
	if camera_x >= max_x - window_half_width - shift_x:
		shift_result_x = clamp(max_x - window_half_width - camera_x, 0.0, shift_x)
	
	if camera_y <= min_y + window_half_height - shift_y:
		shift_result_y = clamp(min_y + window_half_height - camera_y, shift_y, 0.0)
	
	if camera_y >= max_y - window_half_height - shift_y:
		shift_result_y = clamp(max_y - window_half_height - camera_y, 0.0, shift_y)
	
	if target != null:
		if shift_result_x > 0.0:
			shift_result_x = clamp(shift_result_x - (camera_x - target.global_position.x), 0.0, shift_result_x)
		if shift_result_x < 0.0:
			shift_result_x = clamp(shift_result_x - (camera_x - target.global_position.x), shift_result_x, 0.0)
			
		if shift_result_y > 0.0:
			shift_result_y = clamp(shift_result_y - (camera_y - target.global_position.y), 0.0, shift_result_y)
		if shift_result_y < 0.0:
			shift_result_y = clamp(shift_result_y - (camera_y - target.global_position.y), shift_result_y, 0.0)
	
	global_position.x = clamp(round(camera_x + shift_result_x), window_half_width, scene.scene_width - window_half_width)
	global_position.y = clamp(round(camera_y + shift_result_y), window_half_height, scene.scene_height - window_half_height)
