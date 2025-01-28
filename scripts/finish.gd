extends StaticBody3D
@onready var win_sound: AudioStreamPlayer = $winSound
@onready var stabbert: RigidBody3D = $"../../stabbert"
@onready var hud: CanvasLayer = $"../../Hud"

var bodyEntered: bool = false
var won: bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not won and bodyEntered and stabbert.stabbed:
		win_sound.play()
		won = true
		hud.finished = true

func _on_finish_area_area_entered(area: Area3D) -> void:
	bodyEntered = true

func _on_finish_area_area_exited(area: Area3D) -> void:
	bodyEntered = false
