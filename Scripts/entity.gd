extends Node2D

var x_position : float
var y_position : float
var x_speed : float
var y_speed : float
var ground_speed : float
var ground_angle : float
var ground : bool
var space : Physics2DDirectSpaceState
var layer : int

export(PoolStringArray) var tags

export(float) var width_radius
export(float) var height_radius
export(float) var push_radius
export(float) var wall_shift

func _start():
	space = get_world_2d().direct_space_state
	
	x_position = global_position.x
	y_position = global_position.y

func _update(delta : float, loops := 2):
	if ground:
		x_speed = ground_speed * cos(deg2rad(ground_angle))
		y_speed = ground_speed * -sin(deg2rad(ground_angle))
	
	x_position += x_speed * delta
	y_position += y_speed * delta
	
	var steps := int(max(1, loops))
	while steps > 0:
		var wall_left := _sensor_cast(Vector2(-max(push_radius, width_radius), wall_shift if (ground and fmod(round(ground_angle / 4.0), 90.0) == 0.0) else 0.0), Vector2.LEFT)
		if wall_left.collision:
			x_position += wall_left.destination.x
			y_position += wall_left.destination.y
			if ground: ground_speed = 0.0
			else: x_speed = 0.0
		
		var wall_right := _sensor_cast(Vector2(max(push_radius, width_radius), wall_shift if (ground and fmod(round(ground_angle / 4.0), 90.0) == 0.0) else 0.0), Vector2.RIGHT)
		if wall_right.collision:
			x_position += wall_right.destination.x
			y_position += wall_right.destination.y
			if ground: ground_speed = 0.0
			else: x_speed = 0.0
		
		var ceiling_left := _sensor_cast(Vector2(-width_radius + 2.0, -height_radius), Vector2.UP)
		var ceiling_right := _sensor_cast(Vector2(width_radius - 2.0, -height_radius), Vector2.UP)
		var ceiling_center := _sensor_cast(Vector2(0.0, -height_radius), Vector2.UP)
		var ceiling_sensor
		
		if ceiling_center.distance > min(ceiling_left.distance, ceiling_right.distance):
			if ceiling_right.distance < ceiling_left.distance:
				ceiling_sensor = ceiling_right
			else:
				ceiling_sensor = ceiling_left
		else:
			ceiling_sensor = ceiling_center
		
		if not ground and y_speed < 0.0 and ceiling_sensor.collision:
			y_position += ceiling_sensor.destination.y
			
			if ceiling_sensor.normal.y < 0.9 and y_speed < -1.75:
				ground_angle = fmod(720.0 - rad2deg(atan2(ceiling_sensor.normal.x, -ceiling_sensor.normal.y)), 360.0)
				ground_speed = y_speed * -sign(sin(deg2rad(ground_angle)))
				ground = true
			
			y_speed = 0.0
		
		var floor_left := _sensor_cast(Vector2(-width_radius + 2.0, height_radius), Vector2.DOWN)
		var floor_right := _sensor_cast(Vector2(width_radius - 2.0, height_radius), Vector2.DOWN)
		var floor_center := _sensor_cast(Vector2(0.0, height_radius), Vector2.DOWN)
		var floor_sensor
		
		if floor_center.distance > min(floor_left.distance, floor_right.distance):
			if floor_right.distance < floor_left.distance:
				floor_sensor = floor_right
			else:
				floor_sensor = floor_left
		else:
			floor_sensor = floor_center
		
		if not ground and y_speed >= 0.0 and floor_sensor.collision:
			y_position += floor_sensor.destination.y
			ground_angle = fmod(720.0 - rad2deg(atan2(floor_sensor.normal.x, -floor_sensor.normal.y)), 360.0)
			ground_speed = x_speed
			if abs(x_speed) <= abs(y_speed):
				if ground_angle >= 45.0 and ground_angle <= 315.0:
					ground_speed = y_speed * -sign(sin(deg2rad(ground_angle)))
				elif ground_angle >= 22.5 and ground_angle <= 337.5:
					ground_speed = y_speed * 0.5 * -sign(sin(deg2rad(ground_angle)))
			ground = true
		
		if ground:
			if floor_sensor.distance <= 16.0:
				x_position += floor_sensor.destination.x
				y_position += floor_sensor.destination.y
			
			var angle_left = _sensor_cast(Vector2(-width_radius + 2.0, height_radius), Vector2.DOWN)
			var angle_right = _sensor_cast(Vector2(width_radius - 2.0, height_radius), Vector2.DOWN)
			
			if angle_left.distance <= 16.0 and angle_right.distance <= 16.0:
				ground_angle = fmod(720.0 - rad2deg(atan2(angle_right.point.y - angle_left.point.y, angle_right.point.x - angle_left.point.x)), 360.0)
			
			if not (floor_sensor.collision or floor_sensor.distance <= 16.0):
				x_speed = ground_speed * cos(deg2rad(ground_angle))
				y_speed = ground_speed * -sin(deg2rad(ground_angle))
				ground_angle = 0.0
				ground = false
		
		steps -= 1
	
	global_position = Vector2(round(x_position), round(y_position))
	global_rotation = deg2rad(360.0 - round(ground_angle))

func _compare_tag(tag : String) -> bool:
	var result := false
	for t in tags:
		if t == tag:
			result = true
	
	return result

func _sensor_cast(anchor : Vector2, direction : Vector2) -> Dictionary:
	var sensor_angle := deg2rad(360.0 - ground_angle)
	
	var from := Vector2(anchor.x * abs(direction.y), anchor.y * abs(direction.x)).rotated(sensor_angle)
	from.x += x_position
	from.y += y_position
	
	var to := (anchor + (direction * 32.0)).rotated(sensor_angle)
	to.x += x_position
	to.y += y_position
	
	anchor = anchor.rotated(sensor_angle)
	anchor.x += x_position
	anchor.y += y_position
	
	var results := []
	var exclude := []
	var temp := space.intersect_ray(from, to, exclude, 15)
	
	while not temp.empty():
		results.append(temp)
		exclude.append(temp.collider)
		temp = space.intersect_ray(from, to, exclude, 15)
	
	for result in results:
		if result.collider.has_method("_compare_tag"):
			if (result.collider._compare_tag("Solid") or result.collider._compare_tag("Platform") and y_speed >= 0.0 and y_position + (height_radius - max(4.0, abs(y_speed))) <= result.collider.global_position.y) and result.collider._compare_tag("Layer" + var2str(layer)):
				var distance = from.distance_to(result.position) - from.distance_to(anchor)
				return { "collision": distance <= 0.0, "distance": distance, "destination": result.position - anchor, "point": result.position, "normal": result.normal }
	
	return { "collision": false, "distance": 32.0, "destination": Vector2.ZERO, "point": Vector2.ZERO, "normal": Vector2.UP }
