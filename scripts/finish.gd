extends StaticBody3D
@onready var win_sound: AudioStreamPlayer = $winSound
@onready var stabbert: RigidBody3D = $"../../stabbert"
@onready var hud: CanvasLayer = $"../../Hud"
@onready var you_win: Node3D = $"../youWin"

var bodyEntered: bool = false
var won: bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not won and bodyEntered and stabbert.stabbed:
		win_sound.play()
		won = true
		hud.finished = true
		
	if won:
		# Smoothly move the you win text up
		you_win.position = you_win.position.lerp(Vector3(0, 0, 0), 2.0 * delta)
		# Stop moving when close enough
		if you_win.position.distance_to(Vector3(0, 0, 0)) < 0.01:
			you_win.position = Vector3(0, 0, 0)
		

func _on_finish_area_area_entered(area: Area3D) -> void:
	bodyEntered = true

func _on_finish_area_area_exited(area: Area3D) -> void:
	bodyEntered = false
