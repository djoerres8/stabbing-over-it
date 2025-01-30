extends Area3D

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var hud: CanvasLayer = $"../Hud"

const ROTATION_SPEED = .4 # number of degrees the coin rotates every frame
const BOB_SPEED = 2.0 # Speed of the bobbing motion
const BOB_HEIGHT = 0.2 # Maximum height of the bobbing motion

var base_y: float = 0.0
var time_passed: float = 0.0
var collected = false

func _ready() -> void:
	base_y = global_transform.origin.y  # Store original Y position
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate_y(deg_to_rad(ROTATION_SPEED))
	
	# Bobbing motion
	time_passed += delta
	global_transform.origin.y = base_y + sin(time_passed * BOB_SPEED) * BOB_HEIGHT

func _on_body_entered(body: Node3D) -> void:
	if not collected:
		collected = true
		hud.collectables += 1
		audio_stream_player.play()
		self.visible = false
	
	await audio_stream_player.finished
	queue_free()
