extends Node
signal hand_animation_started
signal hand_animation_middle
signal hand_animation_finished
@onready var player: PlayerCharacterEntity = $".."
@onready var head_point: Node2D = $"../Graphic/HeadPoint"
@onready var body: AnimatedSprite2D = $"../Graphic/Body"
@onready var head: AnimatedSprite2D = $"../Graphic/HeadPoint/Head"
@onready var legs: AnimatedSprite2D = $"../Graphic/Legs"
@onready var hand: AnimatedSprite2D = $"../Graphic/Hand"

const HEAD_DEGREES_MAX := 28.0
const HEAD_DEGREES_MIN := -28.0

const IDLE_FRAME := 0
const MOVE_BEGIN := 1
const MOVE_END := 14
const JUMP_FRAME := 19

const HAND_STRIKE_BEG := 15
const HAND_STRIKE_END := 18
const HAND_CONSUME_BEG := 16
const HAND_CONSUME_END := 18
const HAND_SHOVEL_BEG := 16
const HAND_SHOVEL_END := 18
const HAND_DIGGING_BEG := 17
const HAND_DIGGING_END := 18
const HAND_BAILER_FRAME := 18
const HAND_CAGE_BEG := 17
const HAND_CAGE_END := 18
const HAND_DROP_FRAME := 17
const HAND_FEED_FRAME := 17

enum BodyAnimState {
	IDLE,
	MOVE,
	FLY,
}

enum HandAnimType {
	NONE,
	SWING,
	REVERSE_SWING,
	STATIC,
}

enum AnimPosition {
	BEGIN,
	MIDDLE,
	END,
}

# 身体状态
var state: BodyAnimState = BodyAnimState.IDLE
var body_frame := IDLE_FRAME
var body_timer := 0.0
var frame_interval := 0.04  # 约40ms

# 手部独立状态
var hand_frame: int = IDLE_FRAME
var hand_anim_type: HandAnimType = HandAnimType.NONE
var hand_timer: float = 0.0
var hand_frame_interval: float = 0.04
var hand_fixed_accumulator: float = 0.0
const ORIGINAL_FRAME_RATE_MS := 16.0  # 原版 Core.FRAME_RATE = int(1000 / 60) = 16ms
const ORIGINAL_FRAME_RATE_SEC := ORIGINAL_FRAME_RATE_MS / 1000.0
var hand_beg_frame: int = 0
var hand_end_frame: int = 0
var hand_half_duration: float = 0.0   # 仅用于 SWING/REVERSE_SWING 的半程标记
var hand_anim_duration: float = 0.0
var anim_position: AnimPosition = AnimPosition.END
var static_duration: float = 0.0      # 仅用于 STATIC 类型的总持续时间（秒）

# 手持物品相关
var item_texture: Texture2D = null
var item_offset: Vector2 = Vector2.ZERO
var item_rotation: float = 0.0
var item_rotation_speed: float = 0.0
var hand_direction: int = 1
var is_hand_busy: bool = false

# 手部骨骼参数（性别相关，默认男性）
var hand_center: Vector2 = Vector2(18, 55)
var arm_length: float = 15.0

# 后坐力（外部设置，影响手部偏移）
var recoil: float = 0.0
var recoil_decay: float = 0.0   # 每帧衰减量，由外部控制

func _process(delta: float) -> void:
	# 更新身体
	match state:
		BodyAnimState.IDLE:
			body_frame = IDLE_FRAME
		BodyAnimState.FLY:
			body_frame = JUMP_FRAME
		BodyAnimState.MOVE:
			_update_move(delta)
	
	# 更新手部
	_update_hand(delta)
	
	# 更新后坐力
	if recoil != 0.0:
		recoil = move_toward(recoil, 0.0, recoil_decay * delta)
		if abs(recoil) < 0.01:
			recoil = 0.0
	
	# 应用帧
	_apply_frames()
	
	# 头部旋转
	_update_head_rotation.rpc()

@rpc("any_peer","call_local")
func set_direction(dir: bool) -> void:
	head.flip_h = dir
	body.flip_h = dir
	hand.flip_h = dir
	legs.flip_h = dir

@rpc("any_peer", "call_local")
func _update_head_rotation() -> void:
	var mouse_global := player.get_global_mouse_position()
	var player_pos := player.global_position
	var dx := mouse_global.x - player_pos.x
	var dy := mouse_global.y - player_pos.y
	var angle_rad := atan2(dy, abs(dx))
	var degrees := rad_to_deg(angle_rad)
	degrees = clamp(degrees, HEAD_DEGREES_MIN, HEAD_DEGREES_MAX)
	if head.flip_h:
		head_point.rotation = -deg_to_rad(degrees)
	else:
		head_point.rotation = deg_to_rad(degrees)

func _update_move(delta: float) -> void:
	body_timer += delta
	while body_timer >= frame_interval:
		body_timer -= frame_interval
		body_frame += 1
		if body_frame > MOVE_END:
			body_frame = MOVE_BEGIN

func _update_hand(delta: float) -> void:
	if not is_hand_busy or hand_anim_type == HandAnimType.NONE:
		return

	# 原版 CharacterEntity.updateAnimation() 接收的是固定 16ms tick。
	# 在 Godot 中用 accumulator 重建同样的固定时间步。
	hand_fixed_accumulator += delta
	while hand_fixed_accumulator >= ORIGINAL_FRAME_RATE_SEC:
		hand_fixed_accumulator -= ORIGINAL_FRAME_RATE_SEC
		_update_hand_fixed_tick()

	# 原版是在每一个固定 tick 中推进一次物品旋转。
	# 因此这里不能直接在 _process() 每渲染帧累加，否则 144/240Hz 会变快。

func _update_hand_fixed_tick() -> void:
	if not is_hand_busy or hand_anim_type == HandAnimType.NONE:
		return

	# 原版先累计 duration，再判断是否进入 MIDDLE。
	hand_anim_duration += ORIGINAL_FRAME_RATE_SEC
	if hand_anim_duration >= hand_half_duration \
	and anim_position == AnimPosition.BEGIN:
		anim_position = AnimPosition.MIDDLE
		hand_animation_middle.emit()

	# STATIC：原版在达到 frameRate 后结束，不推进帧。
	if hand_anim_type == HandAnimType.STATIC:
		if hand_anim_duration >= static_duration:
			stop_hand_animation()
		return

	hand_timer += ORIGINAL_FRAME_RATE_SEC

	# 原版使用 while，而不是 if；保留该语义以避免大步长丢 tick。
	while hand_timer >= hand_frame_interval and is_hand_busy:
		hand_timer -= hand_frame_interval
		match hand_anim_type:
			HandAnimType.SWING:
				if hand_frame + 1 > hand_end_frame:
					stop_hand_animation()
				else:
					hand_frame += 1
			HandAnimType.REVERSE_SWING:
				if hand_frame - 1 < hand_beg_frame:
					stop_hand_animation()
				else:
					hand_frame -= 1
			_:
				return

	# 原版只有动画仍处于 SWING/REVERSE_SWING 时才旋转物品。
	if is_hand_busy:
		if hand_anim_type == HandAnimType.SWING:
			item_rotation += item_rotation_speed
		elif hand_anim_type == HandAnimType.REVERSE_SWING:
			item_rotation -= item_rotation_speed

func _apply_frames() -> void:
	# 身体部件
	body.frame = body_frame
	head.frame = body_frame
	legs.frame = body_frame
	
	# 手部
	if is_hand_busy and hand_anim_type != HandAnimType.NONE:
		hand.frame = hand_frame
	else:
		hand.frame = body_frame
		item_rotation = 0.0  # 重置旋转

# ========== 公共设置接口 ==========
func set_state(new_state: BodyAnimState) -> void:
	if state == new_state:
		return
	state = new_state
	match state:
		BodyAnimState.IDLE:
			body_frame = IDLE_FRAME
		BodyAnimState.FLY:
			body_frame = JUMP_FRAME
		BodyAnimState.MOVE:
			if body_frame < MOVE_BEGIN or body_frame > MOVE_END:
				body_frame = MOVE_BEGIN

func set_move_speed(speed: float) -> void:
	# speed≈0.7 为正常移动
	frame_interval = speed * 800.0 / 14.0 / 1000.0

func set_recoil(value: float, decay: float = 50.0) -> void:
	recoil = value
	recoil_decay = decay

func get_is_hand_busy() -> bool:
	return is_hand_busy

func get_anim_position() -> AnimPosition:
	return anim_position

# ========== 核心手部动画启动器 ==========
func start_hand_animation(
	anim_type: HandAnimType,
	beg_frame: int,
	end_frame: int,
	speed: float,
	direction: int,
	item_rot_start: float = 0.0,
	rot_speed: float = 0.0,
	static_duration_ms: float = 250.0
) -> void:
	hand_anim_type = anim_type
	hand_beg_frame = beg_frame
	hand_end_frame = end_frame
	hand_direction = direction
	item_rotation = item_rot_start
	item_rotation_speed = rot_speed

	match anim_type:
		HandAnimType.SWING:
			hand_frame = beg_frame
			var effective_speed: float = max(speed, 10.0)
			# 原版：speed * Core.FRAME_RATE，再除以动画帧数量。
			var total_time: float = effective_speed * ORIGINAL_FRAME_RATE_SEC
			hand_frame_interval = total_time / float(end_frame - beg_frame + 1)
			hand_half_duration = total_time / 2.0

		HandAnimType.REVERSE_SWING:
			hand_frame = end_frame
			var effective_speed: float = max(speed, 10.0)
			var total_time: float = effective_speed * ORIGINAL_FRAME_RATE_SEC
			hand_frame_interval = total_time / float(end_frame - beg_frame + 1)
			hand_half_duration = total_time / 2.0

		HandAnimType.STATIC:
			hand_frame = beg_frame
			static_duration = max(static_duration_ms, ORIGINAL_FRAME_RATE_MS) / 1000.0
			hand_half_duration = static_duration / 2.0
			# STATIC 不需要逐帧推进。
			hand_frame_interval = 0.0

		_:
			hand_frame = IDLE_FRAME

	hand_timer = 0.0
	hand_anim_duration = 0.0
	hand_fixed_accumulator = 0.0
	anim_position = AnimPosition.BEGIN
	is_hand_busy = true
	hand_animation_started.emit()
	
func stop_hand_animation() -> void:
	hand_anim_type = HandAnimType.NONE
	is_hand_busy = false
	hand_timer = 0.0
	hand_fixed_accumulator = 0.0
	anim_position = AnimPosition.END
	hand_animation_finished.emit()

# 原版 Item.speed 的语义：持续时间 = speed * Core.FRAME_RATE，
# 而原版 Core.FRAME_RATE = int(1000 / 60) = 16ms。
func get_hand_duration_ms(speed: float) -> float:
	return max(speed, 10.0) * ORIGINAL_FRAME_RATE_MS

# ========== 具体动作接口 ==========

# 默认空手挥动（物品为空时使用）
func start_default_swing(direction: int) -> void:
	start_hand_animation(
		HandAnimType.SWING,
		HAND_STRIKE_BEG,
		HAND_STRIKE_END,
		10.0,           # HAND_SPEED
		direction,
		-100.0,
		get_rotation_speed(10)
	)

# 攻击（近战武器）
func start_strike_animation(speed: float, direction: int) -> void:
	start_hand_animation(
		HandAnimType.SWING,
		HAND_STRIKE_BEG,
		HAND_STRIKE_END,
		speed,
		direction,
		-100.0,
		get_rotation_speed(speed)
	)

# 使用消耗品（药水、食物）
func start_consume_animation(speed: float, direction: int) -> void:
	start_hand_animation(
		HandAnimType.REVERSE_SWING,
		HAND_CONSUME_BEG,
		HAND_CONSUME_END,
		speed,
		direction,
		0.0,
		2.0   # 固定速度
	)

# 铲子动作
func start_shovel_animation(speed: float, direction: int) -> void:
	start_hand_animation(
		HandAnimType.REVERSE_SWING,
		HAND_SHOVEL_BEG,
		HAND_SHOVEL_END,
		speed,
		direction,
		100.0,
		get_rotation_speed(speed) * 0.7
	)

# 挖掘/钻探（持续动作）
func start_digging_animation(speed: float, direction: int) -> void:
	start_hand_animation(
		HandAnimType.REVERSE_SWING,
		HAND_DIGGING_BEG,
		HAND_DIGGING_END,
		speed,
		direction,
		40.0,
		0.0
	)

# 舀水
func start_bailer_animation(direction: int) -> void:
	start_hand_animation(
		HandAnimType.STATIC,
		HAND_BAILER_FRAME,
		HAND_BAILER_FRAME,
		26.0,
		direction,
		50.0,
		0.0,
		get_hand_duration_ms(26.0)
	)

# 笼子（捕捉/放置）
func start_cage_animation(speed: float, direction: int) -> void:
	start_hand_animation(
		HandAnimType.REVERSE_SWING,
		HAND_CAGE_BEG,
		HAND_CAGE_END,
		speed,
		direction,
		50.0,
		0.0
	)

# 使用卷轴
func start_scroll_animation(direction: int) -> void:
	start_hand_animation(
		HandAnimType.STATIC,
		HAND_DROP_FRAME,   # 原版使用17帧
		HAND_DROP_FRAME,
		10.0,              # ScrollTeleportItem 默认 speed=10
		direction,
		0.0,
		0.0,
		get_hand_duration_ms(10.0)
	)

# 远程射击（根据目标位置调整手部帧）
func start_shoot_animation(target_pos: Vector2, direction: int, speed: float) -> void:
	# 计算武器指向角度（度）
	var hand_global_pos := hand.global_position  # 粗略用手的全局位置
	var dx := target_pos.x - hand_global_pos.x
	var dy := target_pos.y - hand_global_pos.y
	var angle_rad := atan2(dy, abs(dx))
	var angle_deg := rad_to_deg(angle_rad)
	if direction == -1:
		angle_deg = -angle_deg
	
	# 根据角度选择手部帧
	var frame: int
	if angle_deg >= -90 and angle_deg <= -30:
		frame = 16
	elif angle_deg > -30 and angle_deg < 30:
		frame = 17
	elif angle_deg >= 30 and angle_deg <= 90:
		frame = 18
	else:
		frame = 17
	
	# 射击动作是静态，但持续很短（约100ms）
	start_hand_animation(
		HandAnimType.STATIC,
		frame,
		frame,
		speed,
		direction,
		angle_deg,
		0.0,
		get_hand_duration_ms(speed)
	)
	# 后坐力由外部调用 set_recoil 处理

# 丢弃物品
func start_drop_animation(direction: int) -> void:
	start_hand_animation(
		HandAnimType.STATIC,
		HAND_DROP_FRAME,
		HAND_DROP_FRAME,
		0.0,
		direction,
		0.0,
		0.0,
		250.0
	)

# 喂宠物
func start_feed_animation(direction: int) -> void:
	start_hand_animation(
		HandAnimType.STATIC,
		HAND_FEED_FRAME,
		HAND_FEED_FRAME,
		0.0,
		direction,
		0.0,
		0.0,
		250.0
	)

# ========== 辅助工具 ==========
func get_rotation_speed(speed: int) -> float:
	match speed:
		10, 11:
			return 14.0
		12, 13:
			return 12.5
		14, 15:
			return 11.0
		16, 17:
			return 9.5
		18, 19, 20, 21:
			return 8.0
		22, 23, 24, 25:
			return 6.5
		26, 27, 28, 29, 30:
			return 5.5
		_:
			return 0.0

# ========== 状态信号连接（由外部 StateMachine 调用） ==========
func _on_idle_state_entered() -> void:
	set_state(BodyAnimState.IDLE)

func _on_move_state_entered() -> void:
	set_state(BodyAnimState.MOVE)

func _on_jump_state_entered() -> void:
	set_state(BodyAnimState.FLY)

func _on_fall_state_entered() -> void:
	set_state(BodyAnimState.FLY)
