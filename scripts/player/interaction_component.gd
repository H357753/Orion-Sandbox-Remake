class_name InteractionComponent
extends Node
func primary_use(world:World,stack:ItemStack,player:PlayerCharacter):
	if stack == null:
		return
	if stack.item == null:
		return
	var pos = world.get_global_mouse_position()
	stack.item.primary_use(world,stack,pos,player)
