extends Node3D

@onready var state_machine: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/StateMachine/playback"]

func _ready():
#	Expose all functions that may be called remotely
	GDSync.expose_func(play_idle)
	GDSync.expose_func(play_spit_attack)
	GDSync.expose_func(play_poweroff)
	
	play_idle()

var idle : bool = false
func play_idle():
	state_machine.travel("play_idle")
	
#	If the animation state changes, synchronize it with all other clients
#	Only send this if this is this client is the host
	if !idle and GDSync.is_host(): GDSync.call_func(play_idle)
	idle = true

func play_spit_attack():
	state_machine.travel("spit_attack")
	
#	Activate the attack animation
#	Only send this if this is this client is the host
	if GDSync.is_host(): GDSync.call_func(play_spit_attack)

func play_poweroff():
	state_machine.travel("power_off")
	
#	Activate the poweroff animation
#	Only send this if this is this client is the host
	if GDSync.is_host(): GDSync.call_func(play_poweroff)
