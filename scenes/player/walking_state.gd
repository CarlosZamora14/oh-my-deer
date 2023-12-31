extends State

const SPEED = 100.0
const JUMP_VELOCITY = -240.0
const FRICTION = 300;

var hunger_active: bool = true

@export var sprite: Sprite2D
@export var collision_shape: CollisionShape2D
@export var projectiles_collision: Area2D
@export var head: Area2D

func enter():
	animation_player.play("walk")

func physics_update(_delta):
	if randf() >= 0.999 && hunger_active:
		hunger_active = false
		actor.increase_hunger()
		await get_tree().create_timer(10.0, false).timeout
		hunger_active = true
		
	var direction
#	var directiony
	if actor.can_control_character:
		var is_jump_pressed: bool = Input.is_action_pressed("jump")
		
		if is_jump_pressed && actor.is_on_floor() && actor.can_jump:
			actor.can_jump = false
			actor.velocity.y = JUMP_VELOCITY
		
		direction = Input.get_axis("left", "right")
#		directiony = Input.get_axis("down", "jump")
#
#	if directiony:
#		actor.velocity.y = directiony * SPEED
	if direction:
		actor.velocity.x = direction * SPEED
		sprite.scale.x = -1 if direction < 0 else 1
		collision_shape.scale.x = 1 if direction >= 0 else -1
		projectiles_collision.scale.x = 1 if direction >= 0 else -1
		head.scale.x = 1 if direction >= 0 else -1
	elif actor.cutscene_speed:
		actor.velocity.x = actor.cutscene_speed
	else:
		transitioned.emit(self, "IdleState")
