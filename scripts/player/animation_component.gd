extends Node
enum BodyLayer {
	HEAD,
	BODY,
	HAND,
	LEGS,
}
@onready var body: AnimatedSprite2D = $"../Graphic/Body"
@onready var head: AnimatedSprite2D = $"../Graphic/Head"
@onready var legs: AnimatedSprite2D = $"../Graphic/Legs"
@onready var hand: AnimatedSprite2D = $"../Graphic/Hand"


func play_animation(anim: String) -> void:
	head.play(anim)
	body.play(anim)
	hand.play(anim)
	legs.play(anim)


func play_animation_by_layer(layer: BodyLayer, anim: String) -> void:
	match layer:
		BodyLayer.HEAD:
			head.play(anim)
		BodyLayer.BODY:
			body.play(anim)
		BodyLayer.HAND:
			hand.play(anim)
		BodyLayer.LEGS:
			legs.play(anim)


func _on_idle_state_entered() -> void:
	play_animation("idle")

func _on_move_state_entered() -> void:
	play_animation("move")

func _on_jump_state_entered() -> void:
	play_animation("jump")

func _on_fall_state_entered() -> void:
	play_animation("jump")
