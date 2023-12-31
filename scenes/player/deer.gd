extends CharacterBody2D

signal game_over()
signal player_throw_candy(marker_pos, candy_direction)
signal show_damage_indicator(pos, damage)

const SPEED = 100.0
const JUMP_VELOCITY = -240.0
const FRICTION = 300;

# Get the gravity from the project settings to be synced with RigidBody nodes.
var respawn_coords = Vector2(20, 220)
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player_lost: bool = false
var eating: bool = false
var can_throw_candy: bool = true
var transparent: bool = false
var can_control_character: bool = true
var cutscene_speed: int = 0
var respawn_active: bool = true
var can_jump: bool = true
var jump_timer_running: bool = false

var blood_particles: PackedScene = preload("res://scenes/player/blood_particles.tscn")

func _ready():
	Globals.male_deer_position = global_position
	Globals.connect("male_deer_death", respawn)
	Globals.connect("taking_hunger_damage", hunger_damage)


func get_kick(hunter):
	if hunter.global_position.x < global_position.x:
		velocity.x += 400
	else:
		velocity.x -= 400
	hit(30, hunter)


func get_waved(hunter_looking_at_right):
	if hunter_looking_at_right:
		velocity.x += -650
	else:
		velocity.x -= 650
	velocity.y -= 100
	hit(20, null)


func reset_shader():
	$Sprite2D.material.set_shader_parameter("progress", 0)
	$Sprite2D.material.set_shader_parameter("color", Vector3(1, 1, 1))

func hunger_damage():
	if Globals.male_deer_vulnerable:
		show_damage_indicator.emit(get_damage_indicator_pos(), min(10, Globals.male_deer_health))
		Globals.update_male_deer_health(Globals.male_deer_health - 10, null)
		Globals.male_deer_vulnerable = false
		$Sprite2D.material.set_shader_parameter("color", Vector3(0.996, 0.361, 0.325))
		$Sprite2D.material.set_shader_parameter("progress", 1.0)
		if (Globals.male_deer_health > 0):
			get_tree().create_timer(0.2, false).timeout.connect(reset_shader)
			var sound = AudioStreamPlayer.new()
			sound.stream = load("res://sounds/hungry-stomach.mp3")
			sound.volume_db = -10
			add_child(sound)
			sound.play()
			await sound.finished
			sound.queue_free()
			Globals.male_deer_vulnerable = true
		else:
			get_tree().create_timer(0.4, false).timeout.connect(reset_shader)


func increase_hunger():
	Globals.male_deer_hunger -= 1


func _physics_process(delta):
	if player_lost:
		return
	
	if is_on_floor() && !can_jump && !jump_timer_running:
		jump_timer_running = true
		await get_tree().create_timer(0.6, false).timeout
		can_jump = true
		jump_timer_running = false
	
	Globals.male_deer_position = global_position
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	move_and_slide()


func avoid_bullets():
	transparent = true
	call_deferred("avoid_bullets_aux")


func avoid_bullets_aux():
	$ProjectilesCollision/Collision.disabled = true

func reset():
	transparent = false
	call_deferred("reset_aux")
	$AnimationPlayer.play("idle")


func reset_aux():
	$ProjectilesCollision/Collision.disabled = false

func hit(damage, enemy):
	if transparent || player_lost || !Globals.male_deer_vulnerable || Globals.male_deer_health == 0:
		return

	if enemy != null && enemy.is_in_group("Bullet"):
		var bullet_position = enemy.global_position
		var blood = blood_particles.instantiate() as GPUParticles2D
		$Particles.add_child(blood)
		blood.global_position = bullet_position
		await get_tree().create_timer(0.1, false).timeout
		Globals.play_bullet_impact(bullet_position)
		blood.emitting = true
	
	show_damage_indicator.emit(get_damage_indicator_pos(), min(damage, Globals.male_deer_health))
	Globals.update_male_deer_health(Globals.male_deer_health - damage, enemy)
	$Sprite2D.material.set_shader_parameter("progress", 0.6)
	Globals.male_deer_vulnerable = false
	if (Globals.male_deer_health > 0):
		var sound = AudioStreamPlayer.new()
		sound.stream = load("res://sounds/deer-scream1.mp3")
		add_child(sound)
		sound.play()
	await get_tree().create_timer(0.6, false).timeout
	Globals.male_deer_vulnerable = true
	$Sprite2D.material.set_shader_parameter("progress", 0)


func increment_score():
	Globals.male_deer_score += 1


func get_damage_indicator_pos():
	var markers = $DamageMarkers.get_children()
	var marker_pos = markers.pick_random().global_position
	return marker_pos


func respawn():
	if player_lost:
		return

	can_control_character = false
	Globals.male_deer_vulnerable = false
	$DeathSound.play()
	if Globals.male_deer_lives == 0 || (Globals.male_deer_lives == 1 && !Globals.reducing_life_instantaneously):
		player_lost = true
	if !respawn_active:
		gravity = 0
		velocity.y = 0
	await get_tree().create_timer(0.6 if respawn_active || player_lost else 2.0).timeout
	can_control_character = true
	Globals.male_deer_vulnerable = true
	get_node("DeerCollision").disabled = false   # enable
	velocity = Vector2.ZERO
	if Globals.male_deer_lives > 1 || (Globals.male_deer_lives == 1 && Globals.reducing_life_instantaneously):
		if respawn_active:
			global_position = respawn_coords
			$DeerCollision.scale.x = 1
			$ProjectilesCollision.scale.x = 1
			$Sprite2D.scale.x = 1
			$HeadArea.scale.x = 1
			Globals.update_male_deer_health(100, null)
			Globals.male_deer_hunger = 5
	else:
		game_over.emit()
		hide()
	Globals.male_deer_falling = false
	


func _on_idle_timer_timeout():
	if randf() > 0.5:
		eating = true
		$AnimationPlayer.play("crouch")
		await $AnimationPlayer.animation_finished
		eating = false


func _on_timer_timeout():
	can_throw_candy = true
	
func save():
	var save_dict = {
		"player": true,
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"current_health" : Globals.male_deer_health,
		"lives": Globals.male_deer_lives,
		"score": Globals.male_deer_score
	}
	return save_dict

func cutscene_started():
	can_control_character = false
	

func cutscene_ended():
	can_control_character = true


func cliff_cutscene():
	$DeerCollision.scale.x = -1
	$HeadArea.scale.x = -1
	$ProjectilesCollision.scale.x = -1
	$Sprite2D.scale.x = -1
	cutscene_speed = 15
	await get_tree().create_timer(0.3, false).timeout
	cutscene_speed = 0


func cliff_cutscene_2nd_part():
	cutscene_speed = 10
	await get_tree().create_timer(1, false).timeout
	cutscene_speed = 0


func cliff_cutscene_3rd_part():
	$DeerCollision.scale.x = 1
	$ProjectilesCollision.scale.x = 1
	$Sprite2D.scale.x = 1
	$HeadArea.scale.x = 1
	await get_tree().create_timer(0.1, false).timeout
	cutscene_speed = 80
	await get_tree().create_timer(2.0, false).timeout
	Globals.male_deer_vulnerable = false
	await get_tree().create_timer(1, false).timeout
	cutscene_speed = 0
	gravity = 0
	await get_tree().create_timer(0.5, false).timeout


func walk_right_nonstop():
	can_control_character = false
	$DeerCollision.scale.x = 1
	$ProjectilesCollision.scale.x = 1
	$Sprite2D.scale.x = 1
	$HeadArea.scale.x = 1
	cutscene_speed = 45


func exit_scene(scene_name):
	can_control_character = false
	$DeerCollision.scale.x = 1
	$ProjectilesCollision.scale.x = 1
	$Sprite2D.scale.x = 1
	$HeadArea.scale.x = 1
	await get_tree().create_timer(0.1, false).timeout
	cutscene_speed = 45
	await get_tree().create_timer(2.0, false).timeout
	TransitionLayer.change_scene(scene_name)
	cutscene_speed = 0
