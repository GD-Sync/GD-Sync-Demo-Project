class_name Coin
extends RigidBody3D

const MIN_LAUNCH_RANGE := 2.0
const MAX_LAUNCH_RANGE := 4.0
const MIN_LAUNCH_HEIGHT := 1.0
const MAX_LAUNCH_HEIGHT := 3.0

const SPAWN_TWEEN_DURATION := 1.0
const FOLLOW_TWEEN_DURATION := 0.5

var _coin_delay : float = 0.0

@onready var _collect_audio: AudioStreamPlayer3D = $CollectAudio
@onready var _player_detection_area: Area3D = $PlayerDetectionArea
@onready var _initial_tween_position := Vector3.ZERO
@onready var _target : Node = null

func _ready():
	GDSync.host_changed.connect(host_changed)
	GDSync.expose_func(collect_for_player)
	
	freeze = !GDSync.is_host()

func _multiplayer_ready():
#	_multiplayer_ready() is called when instantiating this node using a NodeInstaniator
#	_multiplayer_ready() is called after all variables are synchronized. This is not the case yet during _ready()
	await get_tree().create_timer(_coin_delay).timeout
	_player_detection_area.monitoring = true

func host_changed(is_host : bool, new_host_id : int):
#	Enable coin physics only for the host
	freeze = !is_host

func spawn(coin_delay : float = 0.5) -> void:
	var rand_height := MIN_LAUNCH_HEIGHT + (randf() * MAX_LAUNCH_HEIGHT)
	var rand_dir := Vector3.FORWARD.rotated(Vector3.UP, randf() * 2 * PI)
	var velocity := rand_dir * (MIN_LAUNCH_RANGE + (randf() * MAX_LAUNCH_RANGE))
	velocity.y = rand_height
	linear_velocity = velocity
	
	self._coin_delay = coin_delay


func set_target(new_target: PhysicsBody3D) -> void:
	PhysicsServer3D.body_add_collision_exception(get_rid(), new_target.get_rid())
	
	if _target == null:
		sleeping = true
		freeze = true
	
		_initial_tween_position = global_position
		_target = new_target
		var tween := create_tween()
		tween.tween_method(_follow, 0.0, 1.0, 0.5)
		tween.tween_callback(_collect)


func _follow(offset: float) -> void:
	if !is_instance_valid(_target): return
	global_position = lerp(_initial_tween_position, _target.global_position, offset)


func _on_body_entered(body: PhysicsBody3D) -> void:
#	In this demo hitboxes are only enabled for the host, where all collision checks are performed.
#	Any interactions such as taking damage are simply broadcast to other clients.
	if !GDSync.is_host(): return
	if body is Player:
		set_target(body)


func _collect() -> void:
#	Collect the coin locally
	collect_for_player(_target.get_path())
	
#	Collect the coin on all other clients
	GDSync.call_func(collect_for_player, str(_target.get_path()))

func collect_for_player(path : String):
	var target : Node = get_node_or_null(path)
	_collect_audio.pitch_scale = randfn(1.0, 0.1)
	_collect_audio.play()
	if target: target.collect_coin()
	hide()
	await _collect_audio.finished
	queue_free()
