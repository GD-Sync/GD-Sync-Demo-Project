extends RigidBody3D

const COINS_COUNT := 5

@onready var _destroy_sound: AudioStreamPlayer3D = $DestroySound
@onready var _collision_shape: CollisionShape3D = $CollisionShape3d
@onready var _coin_instantiator : Node = $CoinInstantiator
@onready var _box_instantiator : Node = $BoxInstantiator

func _ready():
	GDSync.expose_func(destroy_box)

func damage(_impact_point: Vector3, _force: Vector3):
	for i in range(COINS_COUNT):
		var coin : Node = _coin_instantiator.instantiate_node()
		coin.global_position = global_position
		coin.spawn()
	
	var destroyed_box : Node = _box_instantiator.instantiate_node()
	destroyed_box.global_position = global_position
	
	destroy_box()
	GDSync.call_func(destroy_box)

func destroy_box():
	_collision_shape.set_deferred("disabled", true)
	_destroy_sound.pitch_scale = randfn(1.0, 0.1)
	_destroy_sound.play()
	await _destroy_sound.finished
	queue_free()
