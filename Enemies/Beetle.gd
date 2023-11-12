extends RigidBody3D

const PUFF_SCENE := preload("smoke_puff/smoke_puff.tscn")

@export var coins_count := 5
@export var stopping_distance := 0.0

@onready var _reaction_animation_player: AnimationPlayer = $ReactionLabel/AnimationPlayer
@onready var _detection_area: Area3D = $PlayerDetectionArea
@onready var _beetle_skin: Node3D = $BeetleRoot
@onready var _navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _death_collision_shape: CollisionShape3D = $DeathCollisionShape
@onready var _defeat_sound: AudioStreamPlayer3D = $DefeatSound
@onready var _coin_instantiator : Node = $CoinInstantiator

@onready var _target: Node3D = null
@onready var _alive: bool = true


func _ready() -> void:
#	Expose all functions that may be called remotely
	GDSync.expose_func(play_death_effect)
	
	_detection_area.body_entered.connect(_on_body_entered)
	_detection_area.body_exited.connect(_on_body_exited)
	_beetle_skin.play_idle()


func _physics_process(delta: float) -> void:
	#	Only perform AI behavior on the host
	if !GDSync.is_host(): return
	if not _alive:
		return
	
	if _target != null:
		_beetle_skin.play_walk()
		var target_look_position := _target.global_position
		target_look_position.y = global_position.y
		if target_look_position != Vector3.ZERO:
			look_at(target_look_position)
		
		_navigation_agent.target_position = _target.global_position
		
		var next_location = _navigation_agent.get_next_path_position()
		
		if not _navigation_agent.is_target_reached():
			var direction = (next_location - global_position)
			direction.y = 0
			direction = direction.normalized()
			
			var collision := move_and_collide(direction * delta * 3)
			if collision:
				var collider := collision.get_collider()
				if collider is Player:
					var impact_point: Vector3 = global_position - collider.global_position
					var force := -impact_point
					# Throws player up a little bit
					force.y = 0.5
					force *= 10.0
					collider.damage(impact_point, force)
					_beetle_skin.play_attack()
	else:
		_beetle_skin.play_idle()


func damage(impact_point: Vector3, force: Vector3) -> void:
	lock_rotation = false
	force = force.limit_length(3.0)
	apply_impulse(force, impact_point)
	
	if not _alive:
		return
	
#	Play death effect locally
	play_death_effect()
#	Play death effect on all other clients
	GDSync.call_func(play_death_effect)

func play_death_effect():
	_defeat_sound.play()
	_alive = false
	_beetle_skin.play_poweroff()

	_detection_area.body_entered.disconnect(_on_body_entered)
	_detection_area.body_exited.disconnect(_on_body_exited)
	_target = null
	_death_collision_shape.set_deferred("disabled", false)
	set_collision_layer_value(1, false)
	
	axis_lock_angular_x = false
	axis_lock_angular_y = false
	axis_lock_angular_z = false
	gravity_scale = 1.0
	
	await get_tree().create_timer(2).timeout
	var puff := PUFF_SCENE.instantiate()
	get_parent().add_child(puff)
	puff.global_position = global_position
	await puff.full
	
#	Only directly spawn coins on the host client
	if GDSync.is_host():
		for i in range(coins_count):
		#	Instantiate coins using the NodeInstantiator
		#	The NodeInstantiator will automatically spawn it on all other clients
			var coin : Node = _coin_instantiator.instantiate_node()
			
		#	Set all coin properties. The NodeInstantiator will automatically detect
		#	all changes made to the coin in this frame and synchronize them
			coin.global_position = global_position
			coin.spawn()
	
	hide()
	await get_tree().create_timer(2).timeout 
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body is Player and (_target == null || !is_instance_valid(_target)):
		_target = body
		_reaction_animation_player.play("found_player")


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		_target = null
		_reaction_animation_player.play("lost_player")
