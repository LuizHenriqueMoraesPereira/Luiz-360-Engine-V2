extends Node

func _ready():
	for _i in range(32):
		var channel = preload("res://Objects/audio_channel.tscn").instance()
		add_child(channel)

func _play_sample(sample : AudioStream):
	for channel in get_children():
		if channel is AudioStreamPlayer:
			if channel.stream == null:
				channel.stream = sample
				channel.play()
				break

func _stop_sample(sample : AudioStream):
	for channel in get_children():
		if channel is AudioStreamPlayer:
			if channel.stream == sample:
				channel.stop()
				channel.stream = null
				break
