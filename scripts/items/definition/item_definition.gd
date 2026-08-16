class_name ItemDefinition
extends Resource

@export var name: String
@export var texture: Texture
@export var icon: Texture
@export var max_stack: int = 99
@export var description: String
@export var destroyable: bool = false

func equip():
	pass

func unequip():
	pass

func primary_use(world:World,item_stack:ItemStack,pos:Vector2,player:PlayerCharacter):
	pass

func secondary_use(world:World,item_stack:ItemStack,pos:Vector2,player:PlayerCharacter):
	pass

func update(item_stack:ItemStack,delta):
	pass

#@export var type: ItemType = ItemType.MATERIAL:
	#set(i):
		#type = i
		#match type:
			#ItemType.MATERIAL:
				#max_stack = 99
				#destroyable = false   # 明确设置默认值
			#ItemType.WEAPON:
				#max_stack = 1
				#destroyable = true
