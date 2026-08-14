##func _calculate_jump_power():
##var ratio = 0.4
##jump_power = 6.2 * 60
##for i in range(1, max_jump_height):
##jump_power += 6.2 * 60 * ratio
##ratio *= 0.82
class_name PlayerCharacter
extends CharacterBody2D
const CAMERA = preload("uid://bm3byjlyocjfa")

@onready var animation_component: Node = $AnimationComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var inventory_component: InventoryComponent = $InventoryComponent
@onready var player_sync_state: Node = $PlayerSyncState

#输入
var dir: float
var up: bool = false
var down: bool = false

#跳跃逻辑
const jump_power: float = 742.86912 # 372（像素/秒）6.2 * 60
var _jump_limit: bool = false
var _jumping: bool = false

#状态机
@onready var state_chart: StateChart = $StateChart
@onready var idle: AtomicState = $StateChart/Root/Motion/Idle
@onready var move: AtomicState = $StateChart/Root/Motion/Move
@onready var jump: AtomicState = $StateChart/Root/Motion/Jump
@onready var fall: AtomicState = $StateChart/Root/Motion/Fall

#同步
var _last_sync_state: String = "idle_entered"

#func _ready():
	#if not is_multiplayer_authority():
		#return
	#position = Vector2(790.0, 492.0)
	###相机跟随
	#var camera = CAMERA.instantiate()
	#self.add_child(camera)
	###状态机初始化
	#idle.state_physics_processing.connect(_on_idle_state_physics_processing)
	#move.state_physics_processing.connect(_on_move_state_physics_processing)
	#jump.state_entered.connect(_on_jump_state_entered)
	#jump.state_physics_processing.connect(_on_jump_state_physics_processing)
	#fall.state_physics_processing.connect(_on_fall_state_physics_processing)
	#fall.state_exited.connect(_on_fall_state_exited)


func _ready():
	if is_multiplayer_authority():
		initialize_local()
		get_parent().set_local_player(self)

func initialize_local():
	position = Vector2(790,492)
	var camera = CAMERA.instantiate()
	add_child(camera)
	idle.state_physics_processing.connect(_on_idle_state_physics_processing)
	move.state_physics_processing.connect(_on_move_state_physics_processing)
	jump.state_entered.connect(_on_jump_state_entered)
	jump.state_physics_processing.connect(_on_jump_state_physics_processing)
	fall.state_physics_processing.connect(_on_fall_state_physics_processing)
	fall.state_exited.connect(_on_fall_state_exited)

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		velocity = player_sync_state.velocity
		if player_sync_state.motion_state != _last_sync_state:
			state_chart.send_event(player_sync_state.motion_state)
			_last_sync_state = player_sync_state.motion_state
		return
	player_sync_state.velocity = self.velocity
	
	dir = Input.get_axis("left", "right")
	up = Input.is_action_pressed("up")
	down = Input.is_action_pressed("down")
	#if movement_component.is_jumping or movement_component.is_falling:
	#state_chart.send_event("fall_entered")
	#return
	#if movement_component.is_moving:
	#state_chart.send_event("move_entered")
	#return
	#state_chart.send_event("idle_entered")


## 状态机
@warning_ignore("unused_parameter")
func _on_idle_state_physics_processing(delta: float) -> void:
	if !is_on_floor():
		state_chart.send_event("fall_entered")
		return
	elif up:
		state_chart.send_event("jump_entered")
		return
	elif dir:
		state_chart.send_event("move_entered")
		return


func _on_move_state_physics_processing(delta: float) -> void:
	if !is_on_floor():
		state_chart.send_event("fall_entered")
		return
	elif up:
		state_chart.send_event("jump_entered")
		return
	elif is_zero_approx(dir):
		state_chart.send_event("idle_entered")
		return

	movement_component.move_and_update(delta)
	movement_component.apply_gravity(delta)
	movement_component.apply_friction()
	movement_component.apply_falling_demage()


func _on_fall_state_physics_processing(delta: float) -> void:
	if is_on_floor():
		if up:
			state_chart.send_event("jump_entered")
		elif dir:
			state_chart.send_event("move_entered")
		else:
			state_chart.send_event("idle_entered")
		return
	movement_component.move_and_update(delta)
	movement_component.apply_gravity(delta)
	movement_component.apply_friction()
	movement_component.apply_falling_demage()


func _on_fall_state_exited() -> void:
	movement_component.apply_falling_demage()


func _on_jump_state_entered() -> void:
	_jumping = true
	_jump_limit = false


func _on_jump_state_physics_processing(delta: float) -> void:
	if up: #TODO:and not movement_component.on_ladder
		#if movement_component.under_liquid:
		#velocity.y -= GlobalPhysics.EMERSION_SPEED * delta
		if !_jump_limit:
			if _jumping and velocity.y < 0:
				velocity.y -= GlobalPhysics.JUMP_ACCEL * delta
			elif is_on_floor():
				_jumping = true
				velocity.y -= GlobalPhysics.JUMP_ACCEL * delta

			if velocity.y < -jump_power:
				velocity.y = -jump_power
				_jumping = false
				_jump_limit = true
	else:
		_jumping = false
		_jump_limit = false
	movement_component.move_and_update(delta)
	movement_component.apply_gravity(delta)
	movement_component.apply_friction()
	movement_component.apply_falling_demage()
	if velocity.y > 0 and !is_on_floor():
		state_chart.send_event("fall_entered")
		return
	if is_on_floor():
		if dir:
			state_chart.send_event("move_entered")
		else:
			state_chart.send_event("idle_entered")
		return
