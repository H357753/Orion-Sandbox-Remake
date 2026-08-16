class_name CreatureEntity
extends Entity
@onready var physics_component: PhysicsComponent = $PhysicsComponent
@onready var health_component: HealthComponent = $HealthComponent
func _apply_physics(delta:float) -> void:
	physics_component.move_and_update(delta)
	physics_component.apply_gravity(delta)
	physics_component.apply_friction()
	physics_component.apply_falling_demage()
