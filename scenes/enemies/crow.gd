extends CharacterBody2D

var direction: Vector2 = Vector2.RIGHT
var speed: int = 0
@export var making_noises: bool = false


func _ready():
	$AnimationPlayer.play("idle")


func _process(delta):
	var angle = direction.angle()
	$Sprite2D.rotation = PI + angle if direction.x < 0 else angle
	$CollisionShape2D.rotation = PI + angle if direction.x < 0 else angle
	if direction.x < 0:
		$Sprite2D.scale.x = -abs($Sprite2D.scale.x)
		$CollisionShape2D.scale.x = -abs($CollisionShape2D.scale.x)
	else:
		$Sprite2D.scale.x = abs($Sprite2D.scale.x)
		$CollisionShape2D.scale.x = abs($CollisionShape2D.scale.x)
	
	if making_noises && randf() >= 0.999:
		$AnimationPlayer.play("caw")
		await $AnimationPlayer.animation_finished
		$AnimationPlayer.play("idle")
	position += direction * speed * delta


func fly(custom_speed):
	$AnimationPlayer.play("fly", -1, custom_speed)
