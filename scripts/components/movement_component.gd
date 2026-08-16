class_name MovementComponent
extends Node
@export var move_speed: float = 84 * 60

var gravity_enabled: bool = true
var on_ladder: bool = false
var under_liquid: bool = false

var falling_distance: float


func move_and_update(delta: float):
	if get_parent().dir:
		get_parent().velocity.x += move_speed * delta * get_parent().dir


func apply_gravity(delta: float):
	if !get_parent().is_on_floor() and !on_ladder and gravity_enabled:
		get_parent().velocity.y += GlobalPhysics.GRAVITY * delta


func apply_friction():
	if under_liquid:
		get_parent().velocity.x *= GlobalPhysics.HORIZONTAL_WATER_FRICTION
		get_parent().velocity.y *= GlobalPhysics.VERTICAL_WATER_FRICTION
	else:
		get_parent().velocity.x *= GlobalPhysics.HORIZONTAL_FRICTION
		if gravity_enabled and not on_ladder:
			get_parent().velocity.y *= GlobalPhysics.VERTICAL_FRICTION
		else:
			get_parent().velocity.y *= GlobalPhysics.HORIZONTAL_FRICTION
	get_parent().move_and_slide()


func apply_falling_demage():
	if gravity_enabled and not on_ladder:
		if get_parent().velocity.y > 0:
			falling_distance += owner.velocity.y / 60 # 转换为像素（因为速度是像素/秒）
		elif get_parent().velocity.y < 0:
			falling_distance += -owner.velocity.y / 60
		if get_parent().is_on_floor() and falling_distance > 0:
			#TODO: 处理坠落伤害
			falling_distance = 0.0


#const max_jump_height: int = 4
#const move_speed: float = 84 * 60 # 1.4 * 60 像素/秒
#var gravity_enabled: bool = true
#const jump_power: float = 742.86912 # 372（像素/秒）6.2 * 60

#var _jumping: bool = false
#var _jump_limit: bool = false

#var on_plate: bool = false

#if down:
#if on_plate: # 踩踏平台下落（可选）
#if not player.is_on_floor():
#player.position.y += 1.0 # 原逻辑直接加1像素，与时间无关（固定帧率行为）
#elif on_ladder:
#owner.velocity.y += move_speed * 1.6 * delta
