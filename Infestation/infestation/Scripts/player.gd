extends CharacterBody2D

const SPEED = 100.0
const SPRINT_SPEED = 200.0
const JUMP_VELOCITY = -400.0
const FOOTSTEP_INTERVAL = 0.25

@onready var anim = $AnimatedSprite2D
@onready var footstep = $FootstepPlayer
@onready var death_audio = $DeathPlayer
@onready var gun_audio = $GunPlayer  # AudioStreamPlayer2D for MachineGun.mp3

var footstep_timer = 0.0
var is_dead = false

# --- Projectile ---
var ProjectileScene = preload("res://Scene/Projectile.tscn")  # adjust path if needed

# --- Shooting cooldown ---
var can_shoot = true
var shoot_cooldown = 1.0  # seconds between shooting sequences
var is_shooting = false  # lock movement while shooting

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = move_toward(velocity.x, 0, 1000 * delta)
		velocity.y += get_gravity().y * delta
		move_and_slide()
		return

	var is_sprinting = Input.is_action_pressed("sprint")
	var direction := Input.get_axis("ui_left", "ui_right")
	var current_speed = SPRINT_SPEED if is_sprinting else SPEED

	# --- MOVEMENT LOCKED WHILE SHOOTING ---
	if not is_shooting:
		if direction != 0:
			velocity.x = direction * current_speed
			anim.flip_h = direction < 0
			if is_on_floor():
				anim.play("Sprint" if is_sprinting else "Strafe")
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			if is_on_floor():
				anim.play("Idle")
	else:
		# lock horizontal movement
		velocity.x = 0

	# --- JUMP ---
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_shooting:
		velocity.y = JUMP_VELOCITY
		anim.play("Jump")

	# --- SHOOT (ground only) ---
	if Input.is_action_just_pressed("shoot") and can_shoot and is_on_floor():
		can_shoot = false
		is_shooting = true
		shoot()
		start_shoot_cooldown()

	# --- FOOTSTEPS ---
	if velocity.x == 0 or not is_on_floor():
		if footstep.playing:
			footstep.stop()
		footstep_timer = 0.0
	elif is_on_floor() and velocity.x != 0:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			footstep.play()
			footstep_timer = FOOTSTEP_INTERVAL

	# --- GRAVITY & MOVEMENT ---
	velocity.y += get_gravity().y * delta
	move_and_slide()

	if is_on_floor() and anim.animation == "Jump":
		anim.play("Idle" if direction == 0 else ("Sprint" if is_sprinting else "Strafe"))

	if Input.is_action_just_pressed("die"):
		die()


# --- SHOOT FUNCTION ---
func shoot() -> void:
	anim.play("Shoot")  # start shoot animation

	if gun_audio:
		gun_audio.play()  # play once per sequence

	for i in range(3):
		var bullet = ProjectileScene.instantiate()
		var offset_x = 15 if not anim.flip_h else -15
		bullet.global_position = global_position + Vector2(offset_x, -5)
		bullet.direction = -1 if anim.flip_h else 1
		get_tree().current_scene.add_child(bullet)

		await get_tree().create_timer(0.1).timeout  # 0.5s interval between bullets

	# done shooting: unlock movement and reset animation
	is_shooting = false
	if is_on_floor():
		anim.play("Idle" if Input.get_axis("ui_left", "ui_right") == 0 else "Strafe")


# --- Cooldown helper ---
func start_shoot_cooldown():
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true


# --- DEATH FUNCTION ---
func die() -> void:
	if is_dead:
		return
	is_dead = true

	if footstep.playing:
		footstep.stop()
	footstep_timer = 0.0

	anim.play("Death")
	death_audio.play()

	await death_audio.finished
	respawn()


# --- RESPAWN FUNCTION ---
func respawn() -> void:
	global_position = Vector2(100, 100)
	is_dead = false
	velocity = Vector2.ZERO
	anim.play("Idle")
