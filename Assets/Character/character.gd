extends CharacterBody3D

const VERY_SMALL_NUMBER = 0.0001

@onready var collision = $CollisionShape
@onready var visual = $CollisionShape/Visual
@onready var cam = $CollisionShape/Camera
@onready var space_detect = $CollisionShape/SpaceDetect
@onready var ground_detect = $CollisionShape/GroundDetect
@onready var ground_finder = $CollisionShape/GroundFinder
@onready var platform_detect = $CollisionShape/PlatformDetect

@export var Speed = 10
@export var JumpVelocity = 20
@export var GravityMulti = 10
@export var RotateSpeed = 5

var _inertia : Vector2 = Vector2.ZERO
var _inSpin : bool = false

var rotate_direct : int = 0
var towards : int = 0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	spin()

func _unhandled_key_input(_event):
	# Spin
	if Input.is_action_just_pressed("ui_page_up") and !_inSpin and spin_space_detect():
		collision.disabled = true
		towards += 1
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		tween.tween_property(self, "_inSpin", true, 0)
		tween.tween_property(collision, "rotation_degrees:y",collision.rotation_degrees.y+90, 0.25)
		tween.tween_property(self, "_inSpin", false, 0)
		tween.tween_callback(spin)
	if Input.is_action_just_pressed("ui_page_down") and !_inSpin and spin_space_detect():
		collision.disabled = true
		towards -= 1
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		tween.tween_property(self, "_inSpin", true, 0)
		tween.tween_property(collision, "rotation_degrees:y",collision.rotation_degrees.y-90, 0.25)
		tween.tween_property(self, "_inSpin", false, 0)
		tween.tween_callback(spin)
		
func _physics_process(delta):
	#Plat Collision
	if velocity.y > 0 :
		set_collision_mask_value(4,false)
	else :
		set_collision_mask_value(4,true)
	 
	#Stop Rotate
	if !_inSpin :
		find_ground()
		
	if velocity.x > -VERY_SMALL_NUMBER and velocity.x < VERY_SMALL_NUMBER:
		velocity.x = 0
	if velocity.z > -VERY_SMALL_NUMBER and velocity.z < VERY_SMALL_NUMBER:
		velocity.z = 0
		
	# Record Inerita & Add the gravity.
	if is_on_floor():
		_inertia.x = velocity.x
		_inertia.y = velocity.z
	else:	velocity.y -= gravity * delta * GravityMulti
	
	# Move & Stop
	var input_vec : float = 0
	if towards == 0 or towards == 3 :
		input_vec = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	else :
		input_vec = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
		
	if towards == 0 or towards == 2: 
		velocity.x = lerp(velocity.x,input_vec * Speed , 0.1)
	else :
		velocity.z = lerp(velocity.z,input_vec * Speed , 0.1)
		
	if velocity.x * input_vec <= 0 and velocity.x!=0:
		velocity.x = lerp(velocity.x,0.0,0.5)
		#else:				velocity.x = lerp(_inertia.x,0.0,0.5)
	if velocity.z * input_vec <= 0 and velocity.z!=0:
		velocity.z = lerp(velocity.z,0.0,0.5)
		#else:				velocity.z = lerp(_inertia.y,0.0,0.5)
		
	# Rotate
	#print(velocity," ",rotate_direct)
	if !is_on_floor() and !_inSpin:
		if velocity.x != 0 or velocity.z != 0 :
			if rotate_direct == 0 :
				if towards == 0 or towards == 1:
					if velocity.x > 0 or velocity.z < 0:	rotate_direct = -1
					if velocity.x < 0 or velocity.z > 0:	rotate_direct = 1
				else:
					if velocity.x > 0 or velocity.z < 0:	rotate_direct = 1
					if velocity.x < 0 or velocity.z > 0:	rotate_direct = -1
			else:
				visual.rotation.z += delta * RotateSpeed * rotate_direct
		else :
			visual.rotation.z = lerp(visual.rotation.z,floor( ((visual.rotation.z+(PI/4)) * 2) / PI ) * (PI/2),0.5)
	elif is_on_floor():
		rotate_direct = 0
		visual.rotation.z = lerp(visual.rotation.z,get_floor_actual_angle() + (floor( ((visual.rotation.z+(PI/4)) * 2) / PI ) * (PI/2)),0.5)

	# Handle jump.
	if (Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_up")) and is_on_floor():
		velocity.y = JumpVelocity
		
	if !_inSpin :
		move_and_slide()

func spin():
	match towards:
		-1 :
			towards = 3
		4 :
			towards = 0
	collision.disabled = false

func get_floor_actual_angle():
	if get_floor_angle() != 0 and get_floor_normal() != Vector3(0,1,0) :
		if abs(get_floor_angle()/get_floor_normal().x) < 2 :
			if get_floor_normal().x < 0 :
				if towards == 0 : return get_floor_angle()
				elif towards == 2 : return -get_floor_angle()
			elif get_floor_normal().x > 0 :
				if towards == 0 : return -get_floor_angle()
				elif towards == 2 : return get_floor_angle()
		if abs(get_floor_angle()/get_floor_normal().z) < 2 :
			if get_floor_normal().z < 0 :
				if towards == 3 : return get_floor_angle()
				elif towards == 1 : return -get_floor_angle()
			elif get_floor_normal().z > 0 :
				if towards == 3 : return -get_floor_angle()
				elif towards == 1 : return get_floor_angle()
	return 0

func spin_space_detect():
	space_detect.force_shapecast_update()
	if space_detect.get_collision_count() == 0 : return true
	else : return false
	
func find_ground():
	if !ground_detect.is_colliding() and is_on_floor() and ground_finder.is_colliding():
		var modi = 0
		if towards == 0 or towards == 2 :
			if self.position.z > ground_finder.get_collision_point(0).z :
				modi = -0.5
			elif self.position.z < ground_finder.get_collision_point(0).z :
				modi = 0.5
			self.position.z = ground_finder.get_collision_point(0).z + modi
		else :
			if self.position.x > ground_finder.get_collision_point(0).x :
				modi = -0.5
			elif self.position.x < ground_finder.get_collision_point(0).x :
				modi = 0.5
			self.position.x = ground_finder.get_collision_point(0).x + modi

func _on_platform_detect_area_entered(area):
	area.switch(true)
func _on_platform_detect_area_exited(area):
	area.switch(false)

func get_camera_pos():
	var final_h : float = 0
	match towards :
		0 :	final_h = cam.global_position.x
		1 :	final_h = -cam.global_position.z
		2 :	final_h = -cam.global_position.x
		3 :	final_h = cam.global_position.z
	return Vector2(final_h * 0.55,cam.global_position.y + 0.5)
