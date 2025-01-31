extends CanvasLayer

@onready var timeLabel: Label = $time
@onready var flingsLabel: Label = $flings
@onready var collectablesLabel: Label = $Collectables

var flings: int = 0
var time: float = 0.0
var minutes: int = 0
var seconds: int = 0
var msec: int = 0
var started: bool = false
var finished: bool = false
var collectables: int = 0

func _process(delta) -> void:
	if started and not finished:
		time += delta
		msec = fmod(time, 1) * 100
		seconds = fmod(time, 60)
		minutes = fmod(time, 3600) / 60
		
		timeLabel.text = "Time: " + get_time_formatted()
		flingsLabel.text = "Flings: " + str(flings)
	
	collectablesLabel.text = "Collectables: " + str(collectables) + "/3"

func stop_timer() -> void:
	set_process(false)
	
func start_timer() -> void:
	started = true
	
func reset_timer() -> void:
	time = 0.0
	
func count_fling() -> void:
	if not finished:
		flings += 1
	
func get_time_formatted() -> String:
	return "%02d:%02d.%02d" % [minutes, seconds, msec]
