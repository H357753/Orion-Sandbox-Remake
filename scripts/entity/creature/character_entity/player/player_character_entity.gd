class_name PlayerCharacterEntity
extends CharacterEntity
## 初始化
const CAMERA = preload("uid://bm3byjlyocjfa")

var up_control:bool = false
var down_control:bool = false
var dir: float = 0
@onready var animation_component: Node = $AnimationComponent
##  状态机
@onready var state_chart: StateChart = $StateChart
@onready var idle: AtomicState = $StateChart/Motion/Idle
@onready var move: AtomicState = $StateChart/Motion/Move
@onready var jump: AtomicState = $StateChart/Motion/Jump
@onready var fall: AtomicState = $StateChart/Motion/Fall
@onready var _player: CharacterBody2D = $"."
@onready var collision: CollisionShape2D = $CollisionShape2D

var jump_power:= 742.86912
#func _calculate_jump_power():
	#var ratio = 0.4
	#jump_power = 6.2 * 60
	#for i in range(1, max_jump_height):
		#jump_power += 6.2 * 60 * ratio
##ratio *= 0.82
var _jumping:bool
var _jump_limit:bool

## 同步
@export var sync_velocity:Vector2
@export var sync_motion_state:String
@export var sync_flip:int
var _last_sync_motion:String

func _ready() -> void:
	if not is_multiplayer_authority():
		return
	var camera := CAMERA.instantiate()
	add_child(camera)
	
	idle.state_physics_processing.connect(_on_idle_state_physics_processing)
	move.state_physics_processing.connect(_on_move_state_physics_processing)
	jump.state_entered.connect(_on_jump_state_entered)
	jump.state_physics_processing.connect(_on_jump_state_physics_processing)
	fall.state_physics_processing.connect(_on_fall_state_physics_processing)
	fall.state_exited.connect(_on_fall_state_exited)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		_player.velocity = sync_velocity
		if _last_sync_motion != sync_motion_state:
			state_chart.send_event(sync_motion_state)
			_last_sync_motion = sync_motion_state
		animation_component.set_direction(sync_flip)
		return
	dir = Input.get_axis("left", "right")
	up_control = Input.is_action_pressed("up")
	down_control = Input.is_action_pressed("down")
	
	sync_velocity = _player.velocity
	if not is_zero_approx(dir):
		sync_flip = false if dir >= 0 else true
	animation_component.set_direction(sync_flip)

## 状态机
@warning_ignore("unused_parameter")
func _on_idle_state_physics_processing(delta: float) -> void:
	if !_player.is_on_floor():
		state_chart.send_event("fall_entered")
		return
	elif up_control:
		state_chart.send_event("jump_entered")
		return
	elif dir:
		state_chart.send_event("move_entered")
		return

func _on_move_state_physics_processing(delta: float) -> void:
	if !_player.is_on_floor():
		state_chart.send_event("fall_entered")
		return
	elif up_control:
		state_chart.send_event("jump_entered")
		return
	elif is_zero_approx(dir):
		state_chart.send_event("idle_entered")
		return
	_apply_physics(delta)
	

func _on_fall_state_physics_processing(delta: float) -> void:
	if _player.is_on_floor():
		if up_control:
			state_chart.send_event("jump_entered")
		elif dir:
			state_chart.send_event("move_entered")
		else:
			state_chart.send_event("idle_entered")
		return
	_apply_physics(delta)


func _on_fall_state_exited() -> void:
	physics_component.apply_falling_demage()


func _on_jump_state_entered() -> void:
	_jumping = true
	_jump_limit = false


func _on_jump_state_physics_processing(delta: float) -> void:
	if up_control: #TODO:and not movement_component.on_ladder
		#if movement_component.under_liquid:
		#velocity.y -= GlobalPhysics.EMERSION_SPEED * delta
		if !_jump_limit:
			if _jumping and _player.velocity.y < 0:
				_player.velocity.y -= GlobalPhysics.JUMP_ACCEL * delta
			elif _player.is_on_floor():
				_jumping = true
				_player.velocity.y -= GlobalPhysics.JUMP_ACCEL * delta

			if _player.velocity.y < -jump_power:
				_player.velocity.y = -jump_power
				_jumping = false
				_jump_limit = true
	else:
		_jumping = false
		_jump_limit = false
	_apply_physics(delta)
	if _player.velocity.y > 0 and !_player.is_on_floor():
		state_chart.send_event("fall_entered")
		return
	if _player.is_on_floor():
		if dir:
			state_chart.send_event("move_entered")
		else:
			state_chart.send_event("idle_entered")
		return


func _on_motion_event_received(event: StringName) -> void:
	if is_multiplayer_authority():
		sync_motion_state = event
