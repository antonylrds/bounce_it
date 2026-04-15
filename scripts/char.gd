extends CharacterBody2D


@export var SPEED = 100.0
@export var JUMP_VELOCITY = -400.0
@export var DASH_SPEED = 100.0 * 4
@export var DASH_DURATION := 0.15
@export var ghost_node: PackedScene

var air_dash_count = 0
var is_dashing := false
var air_dash_limit = 1

func _ready():
	handle_animation("idle")

func should_run():
	if is_on_floor():
		handle_animation("running")
		

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("dash") and not is_dashing:
		var direction = -1 if $AnimatedSprite2D.flip_h else 1
		start_dash(direction)
	elif not is_on_floor():
		if velocity.y < 0:
			handle_animation("jump")
		elif velocity.y >= 0:
			handle_animation("fall")
		if not is_dashing:
			velocity += get_gravity() * delta
	else:
		air_dash_count = 0
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
				
		elif Input.is_action_pressed("left"):
			should_run()
		elif Input.is_action_pressed("right"):
			should_run()
			$AnimatedSprite2D.flip_h = false
		else:
			handle_animation("idle")
	
	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if not is_dashing:
		var direction := Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
func handle_animation(animation: String):
	if is_dashing:
		$AnimatedSprite2D.play("dash")
	else:
		$AnimatedSprite2D.play(animation)
	
func start_dash(direction: int):
	if not is_on_floor():
		if air_dash_count >= air_dash_limit:
			return
		air_dash_count += 1
	self.velocity.y = 0
	$AnimatedSprite2D.play("dash")
	is_dashing = true
	
	# Dash in the direction the player is currently facing/moving
	# If standing still, dash in the last moved direction or forward
	velocity.x = direction * DASH_SPEED
	
	# Start spawning ghosts
	var ghost_timer = get_tree().create_timer(DASH_DURATION)
	while ghost_timer:
		await get_tree().create_timer(0.05).timeout
		add_ghost()
	# Wait a tiny bit before spawning the next ghost
	
	# Use a SceneTreeTimer to stop the dash after DASH_DURATION seconds
	await get_tree().create_timer(DASH_DURATION).timeout
	
	is_dashing = false

func add_ghost():
	var ghost = ghost_node.instantiate()
	get_parent().add_child(ghost) # Add to the level, not the player
	
	var player_sprite = $AnimatedSprite2D
	
	# Set the ghost's position and appearance to match the player
	ghost.global_position = global_position
	ghost.sprite_frames = player_sprite.sprite_frames # Match the player's current frame
	ghost.flip_h = player_sprite.flip_h
	ghost.animation = player_sprite.animation
	ghost.frame = player_sprite.frame
