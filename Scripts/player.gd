extends "entity.gd"

var animation : String = "idle"
var animation_old : String = "none"
var animation_direction : int = 1
var animation_speed : float = 1.0
var animation_angle : float = 0.0
var animation_repeat_count : int = 0
var animation_linked : String = "none"
var animation_finished : bool = false

onready var sprite : Sprite = $Sprite
onready var hit_box : Area2D = $Area2D
onready var animator : AnimationPlayer = $AnimationPlayer

var smooth_angle : float
var input_horizontal : int
var input_vertical : int
var control_lock : float
var action : int

var allow_input : bool = true
var allow_direction : bool = true

export(bool) var partial_rotation = true
export(bool) var snapped_rotation = true
export(float, 1.0, 45.0) var rotation_snap = 45.0

export(float) var acceleration = 0.046875
export(float) var air_acceleration = 0.09375
export(float) var deceleration = 0.5
export(float) var friction = 0.046875
export(float) var top_speed = 6.0
export(float) var slope_factor = 0.125
export(float) var gravity_force = 0.21875
export(float) var jump_force = -6.5
export(float) var jump_release_force = -4.0

func _ready():
	_start()

func _physics_process(delta):
	var delta_time : float = float(60.0 * delta)
	
	input_horizontal = (1 if Input.is_action_pressed("Right") else 0) - (1 if Input.is_action_pressed("Left") else 0)
	input_vertical = (1 if Input.is_action_pressed("Down") else 0) - (1 if Input.is_action_pressed("Up") else 0)
	
	if allow_input:
		if ground:
			ground_speed -= slope_factor * sin(deg2rad(ground_angle)) * delta_time
		
		if input_horizontal < 0:
			if ground and control_lock <= 0.0:
				if ground_speed > 0.0:
					ground_speed -= deceleration * delta_time
					if ground_speed <= 0.0:
						ground_speed = -deceleration
				elif ground_speed > -top_speed:
					ground_speed -= acceleration * delta_time
					if ground_speed <= -top_speed:
						ground_speed = -top_speed
			elif not ground:
				if x_speed > -top_speed:
					x_speed -= air_acceleration * delta_time
					if x_speed <= -top_speed:
						x_speed = -top_speed
		
		if input_horizontal > 0:
			if ground and control_lock <= 0.0:
				if ground_speed < 0.0:
					ground_speed += deceleration * delta_time
					if ground_speed >= 0.0:
						ground_speed = deceleration
				elif ground_speed < top_speed:
					ground_speed += acceleration * delta_time
					if ground_speed >= top_speed:
						ground_speed = top_speed
			elif not ground:
				if x_speed < top_speed:
					x_speed += air_acceleration * delta_time
					if x_speed >= top_speed:
						x_speed = top_speed
		
		if ground and input_horizontal == 0 and control_lock <= 0.0:
			ground_speed -= min(abs(ground_speed), friction * delta_time) * sign(ground_speed)
			if abs(ground_speed) < friction:
				ground_speed = 0.0
	
	if not ground and y_speed < 0.0 and y_speed > -4.0:
		x_speed -= ((floor(abs(x_speed / 0.125)) * sign(x_speed)) / 256.0) * delta_time
	
	_update(delta_time, 16)
	
	if x_position <= $"../Camera2D".min_x + 16.0 and x_speed < 0.0:
		x_position = $"../Camera2D".min_x + 16.0
		if ground: ground_speed = 0.0
		else: x_speed = 0.0
	
	if x_position >= $"../Camera2D".max_x - 16.0 and x_speed > 0.0:
		x_position = $"../Camera2D".max_x - 16.0
		if ground: ground_speed = 0.0
		else: x_speed = 0.0
	
	match action:
		0:
			allow_input = true
			allow_direction = true
			_action_common()
		1:
			allow_input = true
			allow_direction = true
			_action_jump()
		2:
			allow_input = false
			allow_direction = false
			_action_lookup()
		3:
			allow_input = false
			allow_direction = false
			_action_crouchdown()
		4:
			allow_input = true
			allow_direction = false
			_action_skidding()
	
	if not ground:
		y_speed += gravity_force * delta_time
		if y_speed > 16.0:
			y_speed = 16.0
	
	if allow_direction and input_horizontal != 0:
		animation_direction = input_horizontal
	
	sprite.flip_h = animation_direction < 0
	
	if animation_old != animation:
		animation_old = animation
		animator.play(animation)
		animation_finished = false
	
	if animation_finished:
		if animation_repeat_count > 0:
			animation_repeat_count -= 1
		elif animation_linked != "none":
			animator.play(animation_linked)
			animation_finished = false
	
	if ground:
		if abs(fmod(ground_angle - smooth_angle + 540.0, 360.0) - 180.0) < 60.0:
			if partial_rotation:
				if abs(fmod(0.0 - ground_angle + 540.0, 360.0) - 180.0) >= 40.0:
					smooth_angle += (fmod(ground_angle - smooth_angle + 540.0, 360.0) - 180.0) * max(0.165, abs(ground_speed / 16.0) * 0.8) * delta_time
				else:
					smooth_angle += (fmod(0.0 - smooth_angle + 540.0, 360.0) - 180.0) * max(0.165, abs(ground_speed / 16.0) * 0.8) * delta_time
			else:
					smooth_angle += (fmod(ground_angle - smooth_angle + 540.0, 360.0) - 180.0) * max(0.165, abs(ground_speed / 16.0) * 0.8) * delta_time
			
			smooth_angle = fmod(720.0 + smooth_angle, 360.0)
		else:
			smooth_angle = fmod(720.0 + ground_angle, 360.0)
		
		if animation == "walk" or animation == "run" or animation == "dash":
			animation_angle = smooth_angle
		else:
			animation_angle = 0.0
	else:
		smooth_angle = 0.0
		
		if animation_angle < 180.0:
			animation_angle = max(animation_angle - (4.0 * delta_time), 0.0)
		else:
			animation_angle = fmod(min(animation_angle + (4.0 * delta_time), 360.0), 360.0)
	
	if animation == "jump":
		animation_angle = 0.0
	
	global_position = Vector2(round(x_position), round(y_position))
	global_rotation = 0.0
	if snapped_rotation:
		sprite.global_rotation = deg2rad(360.0 - round(animation_angle / rotation_snap) * rotation_snap)
	else:
		sprite.global_rotation = deg2rad(360.0 - round(animation_angle))
	hit_box.global_rotation = deg2rad(360.0 - round(ground_angle))
	
	if ground:
		if control_lock <= 0.0:
			if abs(ground_speed) < 2.5 and ground_angle >= 35.0 and ground_angle <= 325.0:
				control_lock = 30
				
				if ground_angle >= 75.0 and ground_angle <= 285.0:
					x_speed = ground_speed * cos(deg2rad(ground_angle))
					y_speed = ground_speed * -sin(deg2rad(ground_angle))
					ground_angle = 0.0
					ground = false
				else:
					if ground_angle < 180.0:
						ground_speed -= deceleration
					else:
						ground_speed += deceleration
		else:
			control_lock -= delta_time

func _on_animation_finished(_anim_name):
	animation_finished = true

func _action_common() -> void:
	if ground:
		if abs(ground_speed) <= 0.0:
			animation = "idle"
			animation_linked = "bored"
			animator.playback_speed = 1.0
		else:
			if abs(ground_speed) < 5.0:
				animation = "walk"
			elif abs(ground_speed) < 10.0:
				animation = "run"
			else:
				animation = "dash"
			
			animation_linked = "none"
			animator.playback_speed = 1.0 + abs(ground_speed / 2.0)
	else:
		if abs(ground_speed) < 5.0:
			animation = "walk"
		elif abs(ground_speed) < 10.0:
			animation = "run"
		else:
			animation = "dash"
		
		animation_linked = "none"
		animator.playback_speed = 1.0 + abs(ground_speed / 2.0)
	
	if ground and ground_speed == 0.0 and input_horizontal == 0:
		if input_vertical < 0:
			action = 2
			return
		
		if input_vertical > 0:
			action = 3
			return
	
	if ground and abs(ground_speed) >= 4.0 and (ground_speed > 0.0 and input_horizontal < 0 or ground_speed < 0.0 and input_horizontal > 0) and not (ground_angle >= 45.0 and ground_angle <= 315.0):
		allow_direction = false
		animation_direction = input_horizontal
		action = 4
		return
	
	if ground and Input.is_action_just_pressed("Fire 1"):
		animation = "jump"
		animation_linked = "none"
		x_speed += jump_force * sin(deg2rad(ground_angle))
		y_speed += jump_force * cos(deg2rad(ground_angle))
		ground_angle = 0.0
		ground = false
		control_lock = 0.0
		action = 1
		return

func _action_jump() -> void:
	animation = "jump"
	animation_linked = "none"
	animator.playback_speed = 2.0 + abs(ground_speed / 4.0)
	
	if Input.is_action_just_released("Fire 1") and y_speed < jump_release_force:
		y_speed = jump_release_force
	
	if ground:
		action = 0
		return

func _action_lookup() -> void:
	animation = "lookup"
	animation_linked = "none"
	animator.playback_speed = 1.0
	
	if not (ground and ground_speed == 0.0 and input_vertical < 0):
		action = 0
		return

func _action_crouchdown() -> void:
	animation = "crouchdown"
	animation_linked = "none"
	animator.playback_speed = 1.0
	
	if not (ground and ground_speed == 0.0 and input_vertical > 0):
		action = 0
		return

func _action_skidding() -> void:
	animation = "skidding"
	animation_linked = "none"
	animator.playback_speed = 2.0
	
	if ground_speed > 0.0 and input_horizontal > 0 or ground_speed < 0.0 and input_horizontal < 0 or abs(ground_speed) < friction or not ground:
		action = 0
		return
	
	if ground and Input.is_action_just_pressed("Fire 1"):
		animation = "jump"
		animation_linked = "none"
		x_speed += jump_force * sin(deg2rad(ground_angle))
		y_speed += jump_force * cos(deg2rad(ground_angle))
		ground_angle = 0.0
		ground = false
		control_lock = 0.0
		action = 1
		return
