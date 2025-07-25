class_name Player
extends CharacterBody3D

signal weapon_switched(weapon_name: String)

enum WEAPON_TYPE { DEFAULT, GRENADE }

## Character maximum run speed on the ground.
@export var move_speed := 8.0
## Speed of shot bullets.
@export var bullet_speed := 10.0
## Forward impulse after a melee attack.
@export var attack_impulse := 10.0
## Movement acceleration (how fast character achieve maximum speed)
@export var acceleration := 4.0
## Jump impulse
@export var jump_initial_impulse := 12.0
## Jump impulse when player keeps pressing jump
@export var jump_additional_force := 4.5
## Player model rotaion speed
@export var rotation_speed := 12.0
## Minimum horizontal speed on the ground. This controls when the character's animation tree changes
## between the idle and running states.
@export var stopping_speed := 1.0
## Max throwback force after player takes a hit
@export var max_throwback_force := 15.0
## Projectile cooldown
@export var shoot_cooldown := 0.5
## Grenade cooldown
@export var grenade_cooldown := 0.5

@onready var _rotation_root: Node3D = $CharacterRotationRoot
@onready var _camera_controller: CameraController = $CameraController
@onready var _attack_animation_player: AnimationPlayer = $CharacterRotationRoot/MeleeAnchor/AnimationPlayer
@onready var _ground_shapecast: ShapeCast3D = $GroundShapeCast
@onready var _grenade_aim_controller: GrenadeLauncher = $GrenadeLauncher
@onready var _character_skin: CharacterSkin = $CharacterRotationRoot/CharacterSkin
@onready var _username: Label3D = $Username
@onready var _ui_aim_recticle: ColorRect = %AimRecticle
@onready var _ui_coins_container: HBoxContainer = %CoinsContainer
@onready var _step_sound: AudioStreamPlayer3D = $StepSound
@onready var _landing_sound: AudioStreamPlayer3D = $LandingSound
@onready var _bullet_instantiator : Node = $BulletInstantiator
@onready var _coin_instantiator : Node = $CoinInstantiator
@onready var _position_synchronizer = $PropertySynchronizer

@onready var _equipped_weapon: WEAPON_TYPE = WEAPON_TYPE.DEFAULT
@onready var _move_direction := Vector3.ZERO
@onready var _last_strong_direction := Vector3.FORWARD
@onready var _gravity: float = -30.0
@onready var _ground_height: float = 0.0
@onready var _start_position := global_transform.origin
@onready var _coins := 0
@onready var _is_on_floor_buffer := false

@onready var _shoot_cooldown_tick := shoot_cooldown
@onready var _grenade_cooldown_tick := grenade_cooldown

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_camera_controller.setup(self)
	_grenade_aim_controller.visible = false
	emit_signal("weapon_switched", WEAPON_TYPE.keys()[0])
	
#	Expose all functions that may be called remotely
	GDSync.expose_func(attack)
	GDSync.expose_func(apply_damage)
	GDSync.expose_func(damage)
	set_multiplayer_data.call_deferred()

func set_multiplayer_data():
	var client_id : int = name.to_int()
	
#	Give the player model the color of this client
	_character_skin.set_color(GDSync.player_get_data(client_id, "Color", Color.WHITE))
	
#	Display the username of this client
	_username.text = GDSync.player_get_data(client_id, "Username", "Unkown")
	
#	Make sure to only display the username of OTHER players, not yourself
	_username.visible = !GDSync.is_gdsync_owner(self)

func _physics_process(delta: float) -> void:
#	Only process inputs if this is YOUR player model
	if !GDSync.is_gdsync_owner(self): return
	
	
	
	# Calculate ground height for camera controller
	if _ground_shapecast.get_collision_count() > 0:
		for collision_result in _ground_shapecast.collision_result:
			_ground_height = max(_ground_height, collision_result.point.y)
	else:
		_ground_height = global_position.y + _ground_shapecast.target_position.y
	if global_position.y < _ground_height:
		_ground_height = global_position.y

	# Swap weapons
	if Input.is_action_just_pressed("swap_weapons"):
		_equipped_weapon = WEAPON_TYPE.DEFAULT if _equipped_weapon == WEAPON_TYPE.GRENADE else WEAPON_TYPE.GRENADE
		_grenade_aim_controller.visible = _equipped_weapon == WEAPON_TYPE.GRENADE
		emit_signal("weapon_switched", WEAPON_TYPE.keys()[_equipped_weapon])

	# Get input and movement state
	var is_attacking := Input.is_action_pressed("attack") and not _attack_animation_player.is_playing() and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE
	var is_just_attacking := Input.is_action_just_pressed("attack") and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE
	var is_just_jumping := Input.is_action_just_pressed("jump") and is_on_floor() and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE
	var is_aiming := Input.is_action_pressed("aim") and is_on_floor() and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE
	var is_air_boosting := Input.is_action_pressed("jump") and not is_on_floor() and velocity.y > 0.0 and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE
	var is_just_on_floor := is_on_floor() and not _is_on_floor_buffer

	_is_on_floor_buffer = is_on_floor()
	_move_direction = _get_camera_oriented_input()

	# To not orient quickly to the last input, we save a last strong direction,
	# this also ensures a good normalized value for the rotation basis.
	if _move_direction.length() > 0.2:
		_last_strong_direction = _move_direction.normalized()
	if is_aiming:
		_last_strong_direction = _camera_controller.global_transform.basis * Vector3.BACK

	_orient_character_to_direction(_last_strong_direction, delta)

	# We separate out the y velocity to not interpolate on the gravity
	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.lerp(_move_direction * move_speed, acceleration * delta)
	if _move_direction.length() == 0 and velocity.length() < stopping_speed:
		velocity = Vector3.ZERO
	velocity.y = y_velocity

	# Set aiming camera and UI
	if is_aiming:
		_camera_controller.set_pivot(_camera_controller.CAMERA_PIVOT.OVER_SHOULDER)
		_grenade_aim_controller.throw_direction = _camera_controller.camera.quaternion * Vector3.FORWARD
		_grenade_aim_controller.from_look_position = _camera_controller.camera.global_position
		_ui_aim_recticle.visible = true
	else:
		_camera_controller.set_pivot(_camera_controller.CAMERA_PIVOT.THIRD_PERSON)
		_grenade_aim_controller.throw_direction = _last_strong_direction.normalized().rotated(_last_strong_direction.cross(Vector3.UP).normalized(), _camera_controller.camera.rotation.x)
		_grenade_aim_controller.from_look_position = global_position
		_ui_aim_recticle.visible = false

	# Update attack state and position

	_shoot_cooldown_tick += delta
	_grenade_cooldown_tick += delta

	if is_attacking:
		match _equipped_weapon:
			WEAPON_TYPE.DEFAULT:
				if is_aiming and is_on_floor():
					if _shoot_cooldown_tick > shoot_cooldown:
						_shoot_cooldown_tick = 0.0
						shoot()
				elif is_just_attacking:
#					Call attack on this player model for yourself and for all other clients
					attack()
					GDSync.call_func(attack)
			WEAPON_TYPE.GRENADE:
				if _grenade_cooldown_tick > grenade_cooldown:
					_grenade_cooldown_tick = 0.0
					_grenade_aim_controller.throw_grenade()

	velocity.y += _gravity * delta

	if is_just_jumping:
		velocity.y += jump_initial_impulse
	elif is_air_boosting:
		velocity.y += jump_additional_force * delta

	# Set character animation
	if is_just_jumping:
		_character_skin.jump()
	elif not is_on_floor() and velocity.y < 0:
		_character_skin.fall()
	elif is_on_floor():
		var xz_velocity := Vector3(velocity.x, 0, velocity.z)
		if xz_velocity.length() > stopping_speed:
			_character_skin.set_moving(true)
			_character_skin.set_moving_speed(inverse_lerp(0.0, move_speed, xz_velocity.length()))
		else:
			_character_skin.set_moving(false)

	if is_just_on_floor:
		_landing_sound.play()

	var position_before := global_position
	move_and_slide()
	var position_after := global_position

	# If velocity is not 0 but the difference of positions after move_and_slide is,
	# character might be stuck somewhere!
	var delta_position := position_after - position_before
	var epsilon := 0.001
	if delta_position.length() < epsilon and velocity.length() > epsilon:
		global_position += get_wall_normal() * 0.1
	
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is SynchronizedRigidBody3D:
			c.get_collider().apply_central_impulse(-c.get_normal())


func attack() -> void:
	_attack_animation_player.play("Attack")
	_character_skin.punch()
	velocity = _rotation_root.transform.basis * Vector3.BACK * attack_impulse


func shoot() -> void:
#	Instantiate a bullet using the NodeInstantiator
#	The NodeInstantiator will automatically spawn it on all other clients
	var bullet : Node = _bullet_instantiator.instantiate_node()
	
#	Set all bullet properties. The NodeInstantiator will automatically detect
#	all changes made to the bullet in this frame and synchronize them
	bullet.shooter_name = name
	var origin := global_position + Vector3.UP
	var aim_target := _camera_controller.get_aim_target()
	var aim_direction := (aim_target - origin).normalized()
	bullet.velocity = aim_direction * bullet_speed
	bullet.distance_limit = 14.0
	bullet.global_position = origin


func reset_position() -> void:
	transform.origin = _start_position
	
#	Pause synchronizer interpolation so the character actually teleports
#	If not paused, the character wil "slide" towards the point
	_position_synchronizer.pause_interpolation(0.2)


func collect_coin() -> void:
	_coins += 1
	
#	Only show the coin UI if YOUR player model picked it up
	if GDSync.is_gdsync_owner(self): _ui_coins_container.update_coins_amount(_coins)


func lose_coins() -> void:
	var lost_coins: int = min(_coins, 5)
	_coins -= lost_coins
	for i in lost_coins:
		#	Instantiate coins using the NodeInstantiator
		#	The NodeInstantiator will automatically spawn it on all other clients
		var coin : Node = _coin_instantiator.instantiate_node()
		
		#	Set all coin properties. The NodeInstantiator will automatically detect
		#	all changes made to the coin in this frame and synchronize them
		coin.global_position = global_position
		coin.spawn(1.5)
	
	#	Only show the coin UI if YOUR player model lost coins
	if GDSync.is_gdsync_owner(self): _ui_coins_container.update_coins_amount(_coins)


func _get_camera_oriented_input() -> Vector3:
	if _attack_animation_player.is_playing() || Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		return Vector3.ZERO

	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var input := Vector3.ZERO
	# This is to ensure that diagonal input isn't stronger than axis aligned input
	input.x = -raw_input.x * sqrt(1.0 - raw_input.y * raw_input.y / 2.0)
	input.z = -raw_input.y * sqrt(1.0 - raw_input.x * raw_input.x / 2.0)

	input = _camera_controller.global_transform.basis * input
	input.y = 0.0
	return input


func play_foot_step_sound() -> void:
	_step_sound.pitch_scale = randfn(1.2, 0.2)
	_step_sound.play()


func damage(_impact_point: Vector3, force: Vector3) -> void:
	if GDSync.is_gdsync_owner(self):
		apply_damage(_impact_point, force)
	else:
		GDSync.call_func_on(name.to_int(), apply_damage, [_impact_point, force])

func apply_damage(_impact_point: Vector3, force: Vector3):
	force.y = abs(force.y)
	velocity = force.limit_length(max_throwback_force)
	lose_coins()


func _orient_character_to_direction(direction: Vector3, delta: float) -> void:
	var left_axis := Vector3.UP.cross(direction)
	var rotation_basis := Basis(left_axis, Vector3.UP, direction).get_rotation_quaternion()
	var model_scale := _rotation_root.transform.basis.get_scale()
	_rotation_root.transform.basis = Basis(_rotation_root.transform.basis.get_rotation_quaternion().slerp(rotation_basis, delta * rotation_speed)).scaled(
		model_scale
	)
