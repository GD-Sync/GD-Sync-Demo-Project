class_name CharacterSkin
extends Node3D

signal foot_step

@export var main_animation_player : AnimationPlayer

var moving_blend_path := "parameters/StateMachine/move/blend_position"

# False : set animation to "idle"
# True : set animation to "move"
@onready var moving : bool = false : set = set_moving

# Blend value between the walk and run cycle
# 0.0 walk - 1.0 run
@onready var move_speed : float = 0.0 : set = set_moving_speed
@onready var animation_tree : AnimationTree = $AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")

func _ready():
	main_animation_player["playback_default_blend_time"] = 0.1

func set_moving(value : bool):
#	If the animation state changes, synchronize it with all other clients
#	Only send this if this is YOUR player model
	moving = value
	if moving:
		state_machine.travel("move")
	else:
		state_machine.travel("idle")

func set_moving_speed(value : float):
	move_speed = clamp(value, 0.0, 1.0)
	animation_tree.set(moving_blend_path, move_speed)

func jump():
	state_machine.travel("jump")


func fall():
	state_machine.travel("fall")
	moving = false

func punch():
	animation_tree.set("parameters/PunchOneShot/request", 1)

func set_color(color : Color):
	color.a = 0.01
	$gdbot/Armature/Skeleton3D/gdbot_mesh.get_surface_override_material(1).set("shader_parameter/screen_color", color)
	$gdbot/Armature/Skeleton3D/gdbot_mesh.get_surface_override_material(2).set("emission", color)
