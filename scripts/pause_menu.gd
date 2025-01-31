extends Control
		
var sfx_bus = AudioServer.get_bus_index("SFX")
var music_bus = AudioServer.get_bus_index("Music")
		
func _ready():
	$AnimationPlayer.play("RESET")
	AudioServer.set_bus_volume_db(sfx_bus, 10)
	
func _process(delta):
	if Input.is_action_just_pressed("pause") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("pause") and get_tree().paused:
		resume()

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")

func pause():
	get_tree().paused = true
	$AnimationPlayer.play("blur")

func _on_resume_pressed():
	if get_tree().paused:
		resume()

func _on_quit_pressed():
	if get_tree().paused:
		get_tree().quit()


func _on_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(music_bus, value)
	
	if value == -30:
		AudioServer.set_bus_mute(music_bus, true)
	else:
		AudioServer.set_bus_mute(music_bus, false)


func _on_h_slider_2_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus, value)
	
	if value == -30:
		AudioServer.set_bus_mute(sfx_bus, true)
	else:
		AudioServer.set_bus_mute(sfx_bus, false)
