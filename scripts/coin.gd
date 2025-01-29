extends Area3D

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var hud: CanvasLayer = $"../Hud"

const ROTATION_SPEED = 2 # number of degrees the coin rotates every frame
var collected = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate_y(deg_to_rad(ROTATION_SPEED))

func _on_body_entered(body: Node3D) -> void:
	if not collected:
		collected = true
		hud.collectables += 1
		audio_stream_player.play()
		self.visible = false
	
	await audio_stream_player.finished
	queue_free()
