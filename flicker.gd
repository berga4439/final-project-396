extends OmniLight3D

@export var MAX_LIGHT = 0.3
@export var MIN_LIGHT = 0.1
@export var noise: NoiseTexture2D

var current_light = (MIN_LIGHT + MAX_LIGHT) / 2.0
var time_passed = 0.0
var offset = 0.0

func _ready() -> void:
	noise.noise.seed = randi()
	offset = randf() * 100.0
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_passed += delta
	var sampled_noise = noise.noise.get_noise_1d(offset + time_passed * 10)
	sampled_noise = abs(sampled_noise)
	
	current_light = MIN_LIGHT + (sampled_noise * (MAX_LIGHT-MIN_LIGHT))
	light_energy = current_light
