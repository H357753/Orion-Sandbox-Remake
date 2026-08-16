class_name HealthComponent
extends Node
signal health_changed()
signal is_killed()
@export var max_health: int = 100
@export var health: int = 100:
	set(i):
		health = i
		health_changed.emit()
		if health<0:
			is_killed.emit()
