extends CharacterBody2D

const SPEED = 100.0
const SPRINT_SPEED = 200.0
const JUMP_VELOCITY = -400.0
const FOOTSTEP_INTERVAL = 0.25  # seconds between footsteps

@onready var anim = $AnimatedSprite2D
@onready var footstep = $FootstepPlayer   # AudioStreamPlayer2D

var footstep_timer = 0.0

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Check sprint key
	var is_sprinting = Input.is_action_pressed("sprint")
	var current_speed = SPRINT_SPEED if is_sprinting else SPEED

	# Get horizontal input
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * current_speed
		anim.flip_h = direction < 0

		# Play proper animation
		if is_sprinting:
			if anim.animation != "Sprint":
				anim.play("Sprint")
		else:
			if anim.animation != "Strafe":
				anim.play("Strafe")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if anim.animation != "Idle":
			anim.play("Idle")

	# Stop footstep if not moving or in air
	if velocity.x == 0 or not is_on_floor():
		if footstep.playing:
			footstep.stop()
		footstep_timer = 0.0

	# Handle footsteps continuously
	if is_on_floor() and velocity.x != 0:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			footstep.play()
			footstep_timer = FOOTSTEP_INTERVAL

	move_and_slide()
