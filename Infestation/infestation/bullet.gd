extends Area2D

const SPEED = 400.0
var direction = 1  # 1 = right, -1 = left

@onready var sprite = $Sprite2D

func _ready():
	# Rotate sprite based on direction
	sprite.rotation_degrees = 0 if direction == 1 else 180

	# Auto-delete after 3 seconds
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _process(delta):
	position.x += SPEED * direction * delta

func _on_body_entered(_body):
	queue_free()
