class_name PlayerCamera
extends Camera2D

# Follow Variables
export(float, 0.01, 1, 0.01) var smooth_follow_factor := 0.5 # 0.01 = slow, 0.1 = fast, 0.5 = very fast, 1 = instant

var target = null
var time_scale := 1.0 # used to adjust camera follow rate with changes in time scale

# Shake Settings
export(int, 2, 3, 1) var directional_trauma_exponent = 2 # squared or cubed trauma exponent
export(int, 2, 3, 1) var noise_trauma_exponent = 2 # squared or cubed trauma exponent
export(float, 0, 1, 0.1) var directional_trauma_decay_rate = 0.8 # how quickly trauma will decay
export(float, 0, 1, 0.1) var noise_trauma_decay_rate = 0.8 # how quickly trauma will decay
export var max_shake_offset := Vector2(100, 75) # max position offset during shake
export var max_shake_roll := 0.1 # max radians to rotate during shake

var min_trauma_magnitude := 0.0 # min limit for trauma magnitude
var max_trauma_magnitude := 1.0 # max limit for trauma magnitude
var trauma_direction := Vector2.ZERO
var noise_y := 0 #used to retrieve noise values from texture
var noise_direction := Vector2.ZERO
var current_directional_trauma := 0.0 # current level of directional shake
var current_noise_trauma := 0.0 # current level of noise shake

onready var screen_shake := true # toggle screen shake setting
onready var shake_magnitude := 1.0 # shake intensity 0-1
onready var noise := OpenSimplexNoise.new()


#Start
func _ready():
	set_as_toplevel(true)
	_generate_noise()
	# set target

# connect to event bus singleton for screenshake events
	Events.connect("cam_directional_screen_shaked", self, "_on_directional_shaked")
	Events.connect("cam_noise_screen_shaked", self, "_on_noise_shaked")


func _physics_process(delta):
	# follow target if valid
	if target != null:
		_follow_target()
	else:
		print("Cam error: no targets found.")
	
	# apply shake_screen() if there is trauma and screen shake is enabled
	if screen_shake:
		if current_directional_trauma or current_noise_trauma:
			#decay and clamp current trauma values
			current_directional_trauma = max(current_directional_trauma - directional_trauma_decay_rate * delta, min_trauma_magnitude)
			current_noise_trauma = max(current_noise_trauma - noise_trauma_decay_rate * delta, min_trauma_magnitude)
			_shake_screen()


func _follow_target():
	global_position.x += (target.global_position.x - global_position.x) * smooth_follow_factor * time_scale
	global_position.y += (target.global_position.y - global_position.y) * smooth_follow_factor * time_scale


func _generate_noise():
	randomize()
	noise.seed = randi()
	noise.period = 4
	noise.octaves = 2

func _on_directional_shaked(trauma: float, direction: Vector2):
	current_directional_trauma = min(current_directional_trauma + trauma, max_trauma_magnitude)
	
	trauma_direction.x = direction.normalized().x
	trauma_direction.y = direction.normalized().y

func _on_noise_shaked(trauma: float):
	current_noise_trauma = min(current_noise_trauma + trauma, max_trauma_magnitude)

# apply the current screen shake to the camera position offset and rotation
func _shake_screen():
	var direction_amount = pow(current_directional_trauma, directional_trauma_exponent)
	var noise_amount = pow(current_noise_trauma, noise_trauma_exponent)
	noise_y += 1 # scroll noise texture
	
	rotation += max_shake_roll * (noise_amount * noise.get_noise_2d(noise.seed, noise_y))
	offset.x = max_shake_offset.x * ((noise_amount * noise.get_noise_2d(noise.seed * 2, noise_y)) + (direction_amount * trauma_direction.x)) * shake_magnitude
	offset.y = max_shake_offset.y * ((noise_amount * noise.get_noise_2d(noise.seed * 3, noise_y)) + (direction_amount * trauma_direction.y)) * shake_magnitude
