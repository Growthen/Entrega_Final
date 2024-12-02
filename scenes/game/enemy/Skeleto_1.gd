extends CharacterBody2D

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

# Variables para control de animación y colisiones
@onready var _animation := $Animacion
@onready var _raycast_terrain := $Area2D/RayoTerreno
@onready var _raycast_wall := $Area2D/RayoPared
@onready var _raycast_vision_left := $Area2D/RayoI
@onready var _raycast_vision_right := $Area2D/RayoD
@onready var _audio_player= $AudioStreamPlayer2D 

var _skeleto_attack = preload("res://assets/sounds/slash.mp3")
var _skeleto_hurt = preload("res://assets/sounds/skeletohit.mp3")
var _skeleto_death = preload("res://assets/sounds/skeletodeath.mp3")
var _skeleto_idle = preload("res://assets/sounds/skeletoidle.mp3")
var _skeleto_run = preload("res://assets/sounds/SkeletoRun.mp3")


# Definición de parámetros de física
var _gravity = 10
var _speed = 25
# Dirección de movimiento
var _moving_left = true
# Copia del objeto que entra a colisión
var _body: Node2D
# Bandera de persecución
var _is_persecuted = false
# Bandera de no detectar colisiones
var _stop_detection = false
# Bandera de no detectar ataques
var _stop_attack = false
# Cuántos golpes aguanta
var _hit_to_die = 6
# Golpes recibidos
var _has_hits = 0
# Estado de muerte del enemigo
var die = false


func _ready():
	# Seteamos la direccion de movimiento
	# Si no seteamos la animación ponemos por defecto la animación idle 
	if not animation:
		animation = "run"
	# Iniciamos la animación
	_init_state()
	
func _physics_process(delta):
	if (die): return
	# Si la animación es de correr, aplicamos el movimiento
	if animation == "run":
		_move_character(delta)
		_turn()
	# Si la animación es de idle, aplicamos el movimiento
	elif animation == "idle":
		_move_idle()
	# Si la animación es de persecución, aplicamos la persecución
	if moving_direction == "active" and !_stop_detection:
		_detection()

func _move_character(_delta):
	# Aplicamos la gravedad
	velocity.y += _gravity
	# Aplicamos la dirección correcta
	if _moving_left:
		velocity.x = -_speed
	else:
		velocity.x = _speed
# Iniciamos el movimiento
	move_and_slide()

func _move_idle():
	# Aplicamos la gravidad
	velocity.y += _gravity
	# Aplicamos la dirección de movimiento
	velocity.x = 0
	# Iniciamos el movimiento
	move_and_slide()
	
func _on_area_2d_body_entered(body):
	# Validamos si la colición es con el personaje principal
	if body.is_in_group("player"):
		_stop_detection = true
		# Atacamos
		_attack()
		# Creamos la copia de objeto
		_body = body
		
func _on_area_2d_body_exited(__body):
	if not die:
		# Estado inicial
		_init_state()

func _turn():
	# Validamos si termino el terreno
	if not _raycast_terrain.is_colliding() or _raycast_wall.is_colliding():
		var _object = _raycast_wall.get_collider()
		if not _object or (_object and not _object.is_in_group("player")):
			_moving_left = !_moving_left
			
			if not _moving_left:
				scale.x = -abs(scale.x)
			else:
				scale.x = abs(scale.x)
			
func _attack():	
	# No atacamos si se seteó la banderita _stop_attack
	if _stop_attack:
		return
		
	if not _body:
		# Esperamos 1 segundos
		await get_tree().create_timer(0).timeout
		_attack()
		
	# Animación de atacar
	_animation.play("attack")
	_audio_player.stream = _skeleto_attack
	_audio_player.play()
	
func _init_state():
	if _stop_attack:
		return
	# Animación de estado inicial
	velocity.x = 0
	_animation.play(animation)
	# Limpiamos las variables
	_body = null
	_stop_detection = false

func _detection():
	# Si ya no hay tierra regresamos al estado inicial
	if not _raycast_terrain.is_colliding():
		# Iniciamos la animación
		_init_state()
		return
	# Obtenemos los colaiders
	var _object1 = _raycast_vision_left.get_collider()
	var _object2 = _raycast_vision_right.get_collider()
	
	# Validamos si la colisión es del lado izquerdo
	if _object1 and _object1.is_in_group("player"):
		_move(true)
	else:
		_is_persecuted = false
	
	# Validamos si la colisión es del lado derecho
	if _object2 and _object2.is_in_group("player"):
		_move(false)
	
	# No hay colisiones
	if not _object1 and not _object2 and _animation.get_animation() != "attack":
		_is_persecuted = false
		
		
func _move(_direction):
	# Si ya estamos en acción salimos
	if _is_persecuted or _animation.get_animation() == "attack":
		return
	# Aplicamos la gravidad
	velocity.y += _gravity
	# Aplicamos la dirección de movimiento
	if _moving_left:
		velocity.x = - _speed * 5
	else:
		velocity.x = _speed * 5
	# Iniciamos el movimiento
	_audio_player.stream = _skeleto_run
	_audio_player.play()
	move_and_slide()

func _on_area_2d_area_entered(area):
	# Si estan atacando al enemigo
	if area.is_in_group("hit"):
		_damage()
	elif area.is_in_group("die"):
		die = true
		_damage()

func _damage():	
	# Agregamos un golpe
	_has_hits += 1
	# Reproducimos sonido
	_audio_player.stream = _skeleto_hurt
	_audio_player.play()
	# Reproducimos la animación de pegar
	_animation.play("hit")
	
	# Validamos si tenemos ataque especial
	if Global.number_attack > 0:
		# Restamos 1 al ataque especial
		die = true
		Global.number_attack -= 1
	
	# Validamos si ya no tenemos ataque
	if Global.number_attack == 0:
		# Seteamos el ataque normal
		Global.attack_effect = "normal"

	if die or _hit_to_die <= _has_hits:
		# Seteamoas banderita no atacar
		_stop_attack = true
		die = true
		dead()
		velocity.x = 0

func dead():
	_animation.play("die")
	await(_animation.animation_finished)
	queue_free()
	
func _on_enemy_animation_animation_finished():
	if _animation.animation == "hit":
		if not _stop_attack: 
			_animation.play("idle")
			# Atacamos
			_attack()

func _on_animacion_animation_finished():
	if _animation.animation == "hit":
		if not _stop_attack: 
			_animation.play("idle")
			# Atacamos
			_attack()


func _on_animacion_frame_changed():
	if _stop_attack:
		return
	# Validamos si el frame de animación es 0
	if _animation.frame == 6 and _animation.get_animation() == "attack":
		# Pegamos al personaje
		
		if HealthDashboard.life > 0:
			# Reproducimos sonido
			pass
		else:
			_animation.play("idle")
		
		if _body:
			var _move_script = _body.get_node("MainCharacterMovement")
			_move_script.hit(3)
			_audio_player.stream = _skeleto_attack
			_audio_player.play()
	pass # Replace with function body.


func _on_area_2d_2_body_entered(body):
	if body is jugador:
		_animation.play("attack")


func _on_area_2d_2_body_exited(body):
	if body is jugador:
		_animation.play("idle")

