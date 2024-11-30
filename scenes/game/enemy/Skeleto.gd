extends CharacterBody2D
## Clase que controla animación y configuración del Enemigo
##
## Setea la animación y comportamiento del Enemigo 

# Acciones del Enemigo
@export_enum(
	"idle",
	"run",
) var animation: String

# Dirección de movimiento del Enemigo
@export_enum(
	"left",
	"right",
	"active",
) var moving_direction: String

# Definición de parametros de física
var _gravity = 10
var _speed = 25
# Definición de dirección de movimientos
var _moving_left = true
# Copia de objeto que entra a colisión
var _body: Node2D
# Vandera de persecución
var _is_persecuted = false
# Vandera de no detectar colisiones
var _stop_detection = false
# Vandera de no detectar ataques
var _stop_attack = false
# Cuantas veces aguanta
var _hit_to_die = 3
# Cuantas veces pegaron al personaje principal
var _has_hits = 0
# La muerte del cangrejo
var die = false

@onready var _animation := $Skeleto_Animacion

# Función de inicialización
func _ready():
	# Seteamos la direccion de movimiento
	if moving_direction == 'right':
		_moving_left = false
		scale.x = -scale.x
	# Si no seteamos la animación ponemos por defecto la animación idle
	if not animation:
		animation = "idle"
	# Iniciamos la animación
	_init_state()

func _process(delta):
	pass
	
func _move_character(_delta):
	# Aplicamos la gravidad
	velocity.y += _gravity
	
	# Aplicamos la dirección de movimiento
	if _moving_left:
		velocity.x = - _speed
	else:
		velocity.x = _speed

	# Iniciamos el movimiento
	move_and_slide()
	
func _init_state():
	if _stop_attack:
		return
	# Animación de estado inicial
	velocity.x = 0
	_animation.play(animation)
	_animation.play("Idle")
	# Limpiamos las variables
	_body = null
	_stop_detection = false
