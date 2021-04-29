extends Node2D

signal red_scored
signal blue_scored

#A prototype of a simple playing algorithm (currently buggy). You can set it to 0 too!
var players = 2

var compute_allowed = false
var red_turning = false
var blue_turning = false
var red_attack = false
var blue_attack = false

var score_allowed = true

var puck_is_out = false
var auto_centering = true

var p1_pressing = false
var p2_pressing = false
var p1_index
var p2_index
var p1_target_position
var p2_target_position

var blue_score = 0
var red_score = 0

var vibration_supported = false

onready var blue = $Blue
onready var red = $Red
onready var blue_goal_particles = $BlueGoalParticles
onready var red_goal_particles = $RedGoalParticles

onready var puck = $Puck
onready var puck_sprite = $Puck/PuckSprite
onready var puck_explosion_particles = $PuckExplosionParticles
onready var puck_timer = $PuckTimer

onready var tween = $Tween

onready var spawn_sound = $SpawnSound
onready var score_sound = $ScoreSound

onready var attack_timer = $AttackTimer

func _ready():
	if players != 2:
		red_attack = false
		blue_attack = false
		compute_allowed = true
		attack_timer.start()
	spawn_sound.play()
	blue.position = Vector2(100, 300)
	red.position = Vector2(924, 300)
	puck.position = Vector2(512, 300)
	puck.linear_velocity = Vector2.ZERO
	puck.angular_velocity = 0
	tween.interpolate_property(puck_sprite, "modulate", \
			Color(1, 1, 1, 0), Color(1, 1, 1, 1), 1, Tween.TRANS_CUBIC)
	tween.interpolate_property(puck_sprite, "scale", \
			Vector2(1.5, 1.5), Vector2(1, 1), 1, Tween.TRANS_CUBIC)
	tween.start()
	if OS.get_name() == "Android" || "iOS":
		vibration_supported = true

func _physics_process(_delta):
	if players == 0 and compute_allowed:
		compute_blue_move()
		compute_red_move()
	elif players == 1 and compute_allowed:
		compute_red_move()
	if puck_is_out == true or Input.is_action_just_pressed("ui_select"):
		center_puck()

func _unhandled_input(event):
	if event is InputEventScreenDrag:
		if p1_pressing == true and event.index == p1_index and players != 0:
			blue.move_and_slide((event.position - blue.position) * 40)
		if players == 2:
			if p2_pressing == true and event.index == p2_index:
				red.move_and_slide((event.position - red.position) * 40)
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < 512:
				p1_index = event.index
				p1_pressing = true
			if event.position.x > 512:
				p2_index = event.index
				p2_pressing = true
		if event.pressed == false:
			if event.index == p1_index:
				p1_pressing = false
			if event.index == p2_index:
				p2_pressing = false

func _on_PuckVisibilityNotifier_screen_exited():
	if auto_centering:
		puck_is_out = true

func _on_PuckVisibilityNotifier_screen_entered():
	puck_is_out = false

func _on_BlueGoal_body_entered(body):
	if body.name == "Puck" and score_allowed:
		goal()
		blue_goal_particles.emitting = true
		emit_signal("red_scored")

func _on_RedGoal_body_entered(body):
	if body.name == "Puck" and score_allowed:
		goal()
		red_goal_particles.emitting = true
		emit_signal("blue_scored")

func goal():
	puck.hide()
	puck.set_deferred("mode", RigidBody2D.MODE_STATIC)
	puck_explosion_particles.position = puck.position
	puck_explosion_particles.direction = puck.linear_velocity
	puck_explosion_particles.emitting = true
	score_allowed = false
	auto_centering = false
	score_sound.play()
	if vibration_supported:
		Input.vibrate_handheld()
	puck_timer.start()

func _on_Tween_tween_step(_object, _key, elapsed, _value):
	if elapsed >= 0.5:
		puck.mode = RigidBody2D.MODE_RIGID

func _on_PuckTimer_timeout():
	center_puck()
	puck.show()
	score_allowed = true
	auto_centering = true

func center_puck():
	spawn_sound.play()
	tween.interpolate_property(puck_sprite, "modulate", \
				Color(1, 1, 1, 0), Color(1, 1, 1, 1), 1, Tween.TRANS_CUBIC)
	tween.interpolate_property(puck_sprite, "scale", \
				Vector2(1.5, 1.5), Vector2(1, 1), 1, Tween.TRANS_CUBIC)
	tween.start()
	puck.position = Vector2(512, 300)
	puck.linear_velocity = Vector2.ZERO
	puck.angular_velocity = 0

func compute_red_move():
	if puck_is_out or auto_centering == false:
		red.move_and_slide((Vector2(924, 300) - red.position) * 4)
	else:
		var distance = (puck.position - red.position) + Vector2(randf() - 0.5, \
				randf() - 0.5) * puck.linear_velocity.length() / 25
		if distance.length() < 20:
#			red.move_and_slide(distance * -20)
			distance += Vector2(randf() - 0.5, randf() - 0.5) * 60
		if distance.x < -150 and red_turning:
			red_turning = false
		if distance.x > -50 and red_attack:
			red_attack = false
		if puck.position.x > 600:
			red.move_and_slide(distance * puck.linear_velocity.length() / 100)
		elif distance.x < 0 and red_turning == false:
			if puck.linear_velocity.length() < 10:
				if red_attack:
					red.move_and_slide((distance + Vector2(20, 0)) * 10)
				else:
					red.move_and_slide((distance + Vector2(300, 0)) * 2)
			elif puck.linear_velocity.length() > 1000:
				red.move_and_slide((distance + Vector2(200, 0)) * 20)
			else:
				red.move_and_slide(distance * puck.linear_velocity.length() / 50)
		else:
			if red_turning == false:
				red_turning = true
			if distance.y < 0:
	#				red.move_and_slide(Vector2(distance.x * cos(distance.angle()), distance.y * sin(distance.angle())) * puck.linear_velocity.length() / 100)
				red.move_and_slide(distance.rotated(deg2rad(90)) * puck.linear_velocity.length() / 100)
			if distance.y > 0:
	#				red.move_and_slide(Vector2(distance.x * cos(distance.angle()), distance.y * sin(distance.angle())) * puck.linear_velocity.length() / 100)
				red.move_and_slide(distance.rotated(deg2rad(-90)) * puck.linear_velocity.length() / 100)

func compute_blue_move():
	if puck_is_out or auto_centering == false:
		blue.move_and_slide((Vector2(100, 300) - blue.position) * 4)
	else:
		var distance = (puck.position - blue.position) + Vector2(randf() - 0.5, \
				randf() - 0.5) * puck.linear_velocity.length() / 25
		if distance.length() < 20:
#			blue.move_and_slide(distance * -20)
			distance += Vector2(randf() - 0.5, randf() - 0.5) * 60
		if distance.x > 150 and blue_turning:
			blue_turning = false
		if distance.x < 50 and blue_attack:
			blue_attack = false
		if puck.position.x < 424:
			blue.move_and_slide(distance * puck.linear_velocity.length() / 100)
		elif distance.x > 0 and blue_turning == false:
			if puck.linear_velocity.length() < 10:
				if blue_attack:
					blue.move_and_slide((distance - Vector2(20, 0)) * 10)
				else:
					blue.move_and_slide((distance - Vector2(300, 0)) * 2)
			elif puck.linear_velocity.length() > 1000:
				blue.move_and_slide((distance - Vector2(200, 0)) * 20)
			else:
				blue.move_and_slide(distance * puck.linear_velocity.length() / 50)
		else:
			if blue_turning == false:
				blue_turning = true
			if distance.y < 0:
	#				blue.move_and_slide(Vector2(distance.x * cos(distance.angle()), distance.y * sin(distance.angle())) * puck.linear_velocity.length() / 100)
				blue.move_and_slide(distance.rotated(deg2rad(-90)) * puck.linear_velocity.length() / 100)
			if distance.y > 0:
	#				blue.move_and_slide(Vector2(distance.x * cos(distance.angle()), distance.y * sin(distance.angle())) * puck.linear_velocity.length() / 100)
				blue.move_and_slide(distance.rotated(deg2rad(90)) * puck.linear_velocity.length() / 100)

func _on_AttackTimer_timeout():
	if auto_centering:
		if randf() > 0.5:
			red_attack = true
		if randf() > 0.5:
			blue_attack = true

#func _on_CornerWalls_body_entered(body):
#	if body.name == "Puck":
#		center_puck()
