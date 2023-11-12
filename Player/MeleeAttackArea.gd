extends Area3D

@onready var collision_shape: CollisionShape3D = $CollisionShape3d



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)


func activate():
#	In this demo hitboxes are only enabled for the host, where all collision checks are performed.
#	Any interactions such as taking damage are simply broadcast to other clients.
	if !GDSync.is_host(): return
	collision_shape.set_deferred("disabled", false)


func deactivate():
#	In this demo hitboxes are only enabled for the host, where all collision checks are performed.
#	Any interactions such as taking damage are simply broadcast to other clients.
	if !GDSync.is_host(): return
	collision_shape.set_deferred("disabled", true)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("damageables"):
		var impact_point := global_position - body.global_position
		var force := -impact_point
		body.damage(impact_point, force)
