class_name MovementComponent
extends Node
@onready var creature: CharacterBody2D = $".."
@export var move_speed: float = 84 * 60

var gravity_enabled: bool = true
var on_ladder: bool = false
var under_liquid: bool = false
var falling_distance: float

#func move_and_update(delta: float):
#if creature.dir:
#creature.velocity.x += move_speed * delta * creature.dir


func apply_gravity(delta: float):
	if !creature.is_on_floor() and !on_ladder and gravity_enabled:
		creature.velocity.y += GlobalPhysics.GRAVITY * delta


func apply_friction():
	if under_liquid:
		creature.velocity.x *= GlobalPhysics.HORIZONTAL_WATER_FRICTION
		creature.velocity.y *= GlobalPhysics.VERTICAL_WATER_FRICTION
	else:
		creature.velocity.x *= GlobalPhysics.HORIZONTAL_FRICTION
		if gravity_enabled and not on_ladder:
			creature.velocity.y *= GlobalPhysics.VERTICAL_FRICTION
		else:
			creature.velocity.y *= GlobalPhysics.HORIZONTAL_FRICTION
	creature.move_and_slide()


func apply_falling_demage():
	if gravity_enabled and not on_ladder:
		if creature.velocity.y > 0:
			falling_distance += creature.velocity.y / 60 # 转换为像素（因为速度是像素/秒）
		elif creature.velocity.y < 0:
			falling_distance -= creature.velocity.y / 60
		if creature.is_on_floor() and falling_distance > 0:
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
