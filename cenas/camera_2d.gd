extends Camera2D

# Duração padrão do shake (segundos)
@export var default_duration: float = 0.5
# Intensidade padrão do shake (pixels)
@export var default_magnitude: float = 10.0
# Fator de redução da intensidade (quanto maior, mais rápido para de tremer)
@export var decrease_factor: float = 1.0

# --- variáveis internas ---
var _shake_time: float = 0.0
var _shake_duration: float = 0.0
var _shake_magnitude: float = 0.0
var _original_offset: Vector2
var _rng := RandomNumberGenerator.new()

func _ready():
	_rng.randomize()
	# Guarda o offset original para depois restaurar
	_original_offset = offset

func _process(delta):
	if _shake_time > 0.0:
		# Progresso de 1→0 para suavizar a magnitude
		var progress = _shake_time / _shake_duration
		var current_mag = _shake_magnitude * progress
		# Offset aleatório em X e Y
		var dx = _rng.randf_range(-1.0, 1.0) * current_mag
		var dy = _rng.randf_range(-1.0, 1.0) * current_mag
		offset = _original_offset + Vector2(dx, dy)
		
		# Decrementa o tempo de shake
		_shake_time -= delta * decrease_factor
		if _shake_time <= 0.0:
			# Restaura exatamente o offset original
			offset = _original_offset
	# else: mantém offset original

# Chame esta função para disparar o shake:
#   duration = duração em segundos
#   magnitude = quão forte o shake (pixels)
func shake(duration: float=default_duration, magnitude: float=default_magnitude) -> void:
	_shake_duration = duration
	_shake_time = duration
	_shake_magnitude = magnitude
