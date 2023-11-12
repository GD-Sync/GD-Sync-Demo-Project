extends Node3D

@onready var state_machine: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var cycle_state_machine: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/Cycle/playback"]
@onready var second_action_state_machine: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/Cycle/IDLE/playback"]
@onready var second_action_timer : Timer = $Timer
@onready var step_sounds := $StepSounds.get_children()

signal change_state(state_name : String)
signal footstep


func _ready():
#	Expose all functions that may be called remotely
	GDSync.expose_func(play_idle)
	GDSync.expose_func(play_walk)
	GDSync.expose_func(play_attack)
	GDSync.expose_func(play_poweroff)
	
	play_idle()

var idle : bool = false
func play_idle():
	if cycle_state_machine.get_current_node() == "IDLE": return
	cycle_state_machine.travel("IDLE")
	second_action_timer.start()
	emit_signal("change_state", "IDLE")
	
#	If the animation state changes, synchronize it with all other clients
#	Only send this if this is this client is the host
	if !idle and GDSync.is_host(): GDSync.call_func(play_idle)
	idle = true


func play_walk():
	cycle_state_machine.travel("WALK")
	emit_signal("change_state", "WALK")
	
#	If the animation state changes, synchronize it with all other clients
#	Only send this if this is this client is the host
	if idle and GDSync.is_host(): GDSync.call_func(play_walk)
	idle = false

func play_attack():
	state_machine.travel("headbutt")
	emit_signal("change_state", "HEADBUTT")
	
#	Activate the attack animation
#	Only send this if this is this client is the host
	if GDSync.is_host(): GDSync.call_func(play_attack)


func play_poweroff():
	state_machine.travel("poweroff")
	emit_signal("change_state", "POWEROFF")
	
#	Activate the poweroff animation
#	Only send this if this is this client is the host
	if GDSync.is_host(): GDSync.call_func(play_poweroff)


func play_random_step_sound():
	var random_sound: AudioStreamPlayer3D = step_sounds.pick_random()
	random_sound.pitch_scale = randfn(1.2, 0.2)
	random_sound.play()


func on_timer_second_action():
	# Play animation
	second_action_state_machine.travel("head move")
	second_action_timer.wait_time = randf_range(2.0, 8.0)


func check_idle_second_action_loop(state_name):
	if state_name == "IDLE" or second_action_timer.is_stopped(): return
	second_action_timer.stop()
