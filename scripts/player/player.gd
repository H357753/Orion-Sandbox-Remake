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
@onready var sync_state: Node = $SyncState
@onready var interaction_component: InteractionComponent = $InteractionComponent
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
var world:World

## 输入
var dir: float
var up: bool = false
var down: bool = false

## 跳跃逻辑
const jump_power: float = 742.86912 # 372（像素/秒）6.2 * 60
var _jump_limit: bool = false
var _jumping: bool = false

## 状态机
@onready var state_chart: StateChart = $StateChart
@onready var idle: AtomicState = $StateChart/Root/Motion/Idle
@onready var move: AtomicState = $StateChart/Root/Motion/Move
@onready var jump: AtomicState = $StateChart/Root/Motion/Jump
@onready var fall: AtomicState = $StateChart/Root/Motion/Fall

## 同步
var _last_sync_state: String = "idle_entered"

## 选中物品
var selected_item_index: int = 0
func set_selected_item_index(i:int) -> void:
	selected_item_index = i

##初始化
func _ready():
	if is_multiplayer_authority():
		initialize_local()
		get_parent().set_local_player(self)
		world = get_parent().get_world()


func initialize_local():
	position = Vector2(932.0,502.0)
	var camera = CAMERA.instantiate()
	add_child(camera)
	idle.state_physics_processing.connect(_on_idle_state_physics_processing)
	move.state_physics_processing.connect(_on_move_state_physics_processing)
	jump.state_entered.connect(_on_jump_state_entered)
	jump.state_physics_processing.connect(_on_jump_state_physics_processing)
	fall.state_physics_processing.connect(_on_fall_state_physics_processing)
	fall.state_exited.connect(_on_fall_state_exited)


## 输入
@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		velocity = sync_state.velocity
		if sync_state.motion_state != _last_sync_state:
			state_chart.send_event(sync_state.motion_state)
			_last_sync_state = sync_state.motion_state
		return
	sync_state.velocity = self.velocity

	dir = Input.get_axis("left", "right")
	up = Input.is_action_pressed("up")
	down = Input.is_action_pressed("down")
	

func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		animation_component.set_direcation(sync_state.flip)
		return
	if Input.is_action_just_pressed("mouse_left_interaction"):
		var item = inventory_component.get_item(selected_item_index)
		interaction_component.primary_use(world,item,self)
	if not is_zero_approx(dir):
		sync_state.flip = false if dir >= 0 else true
	animation_component.set_direction(sync_state.flip)

func get_collision_rect() -> CollisionShape2D:
	return collision_shape_2d


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
