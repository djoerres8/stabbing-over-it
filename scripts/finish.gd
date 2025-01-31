extends StaticBody3D
@onready var win_sound: AudioStreamPlayer = $winSound
@onready var stabbert: RigidBody3D = $"../../stabbert"
@onready var hud: CanvasLayer = $"../../Hud"
@onready var you_win: Node3D = $"../youWin"
@onready var high_score_text: MeshInstance3D = $"../../Obstacles/Hill1-tower/HighScoreTime/highScore"

var config = ConfigFile.new()
var bodyEntered: bool = false

var timeHighScore = 0
var flingsHighScore = 99999

func _ready() -> void:
	load_high_score()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not hud.finished and bodyEntered and stabbert.stabbed:
		win_sound.play()
		hud.finished = true
		save_high_score()
		
	if hud.finished:
		# Smoothly move the you win text up
		you_win.position = you_win.position.lerp(Vector3(0, 0, 0), 2.0 * delta)
		# Stop moving when close enough
		if you_win.position.distance_to(Vector3(0, 0, 0)) < 0.1:
			you_win.position = Vector3(0, 0, 0)
			
	else:
		# Smoothly move the you win text back down
		you_win.position = you_win.position.lerp(Vector3(0, -3000, 0), 2.0 * delta)
		# Stop moving when close enough
		if you_win.position.distance_to(Vector3(0, -3000, 0)) < 0.1:
			you_win.position = Vector3(0, -3000, 0)
		

func _on_finish_area_area_entered(area: Area3D) -> void:
	bodyEntered = true

func _on_finish_area_area_exited(area: Area3D) -> void:
	bodyEntered = false
	
func save_high_score():
	# get time and flings
	var flings = hud.flings
	var time = hud.time
	
	if flingsHighScore > flings:
		config.set_value("score", "flings", flings)

	if timeHighScore < time:
		config.set_value("score", "time", time)

	config.save("res://savegame.cfg")
	load_high_score()
	
func load_high_score():
	var file = config.load("res://savegame.cfg")
	if file == OK:
		var timeHighScore = config.get_value("score", "time")
		var flingsHighScore = config.get_value("score", "flings")
		var printTime = 0
		var printFlings = 99999
		
		if timeHighScore != null:
			printTime = timeHighScore
			
		if flingsHighScore != null:
			printFlings = flingsHighScore
			

		high_score_text.mesh.text = """High Score:
Time: """ + "%02d:%02d.%02d" % [fmod(printTime, 3600) / 60, fmod(printTime, 60), fmod(printTime, 1) * 100] + """
flings: """ + str(printFlings)
	
