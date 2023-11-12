extends Node3D

@export var scale_decay: Curve
@export var distance_limit: float = 5.0

var velocity: Vector3 = Vector3.ZERO

@onready var _area: Area3D = $Area3d
@onready var _bullet_visuals: Node3D = $Bullet
@onready var _projectile_sound: AudioStreamPlayer3D = $ProjectileSound

@onready var _time_alive := 0.0
@onready var _alive_limit := 0.0

var shooter_name : String = ""

func _ready():
#	Expose all functions that may be called remotely
	GDSync.expose_func(queue_free)

func _multiplayer_ready() -> void:
#	_multiplayer_ready() is called when instantiating this node using a NodeInstaniator
#	_multiplayer_ready() is called after all variables are synchronized. This is not the case yet during _ready()
	_area.body_entered.connect(_on_body_entered)
	look_at(global_position + velocity)
	_alive_limit = distance_limit / velocity.length()
	_projectile_sound.pitch_scale = randfn(1.0, 0.1)
	_projectile_sound.play()


func _process(delta: float) -> void:
	#	Only move the bullet on the host client
	if !GDSync.is_host(): return
	global_position += velocity * delta
	_time_alive += delta
	
	_bullet_visuals.scale = Vector3.ONE * scale_decay.sample(_time_alive/_alive_limit)
	
	if _time_alive > _alive_limit:
		destroy_bullet()


func _on_body_entered(body: Node3D) -> void:
	if body.name == shooter_name:
		return
	
#	In this demo hitboxes are only enabled for the host, where all collision checks are performed.
#	Any interactions such as taking damage are simply broadcast to other clients.
	if GDSync.is_host() and body.is_in_group("damageables"):
		var impact_point := global_position - body.global_position
		body.damage(impact_point, velocity)
	destroy_bullet()

func destroy_bullet():
#	Destroy the bullet locally
	queue_free()
	
#	Destroy the bullet on other clients
	GDSync.call_func(queue_free)
