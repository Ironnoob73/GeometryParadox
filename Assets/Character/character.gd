extends CharacterBody3D

@onready var collision = $CollisionShape
@onready var visual = $CollisionShape/Visual
@onready var cam = $CollisionShape/Camera
@onready var space_detect = $CollisionShape/SpaceDetect
@onready var ground_detect = $CollisionShape/GroundDetect
@onready var ground_finder = $CollisionShape/GroundFinder

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
		find_ground()
		collision.disabled = true
		towards += 1
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		tween.tween_property(self, "_inSpin", true, 0)
		tween.tween_property(collision, "rotation_degrees:y",collision.rotation_degrees.y+90, 0.25)
		tween.tween_property(self, "_inSpin", false, 0)
		tween.tween_callback(spin)
	if Input.is_action_just_pressed("ui_page_down") and !_inSpin and spin_space_detect():
		find_ground()
		collision.disabled = true
		towards -= 1
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		tween.tween_property(self, "_inSpin", true, 0)
		tween.tween_property(collision, "rotation_degrees:y",collision.rotation_degrees.y-90, 0.25)
		tween.tween_property(self, "_inSpin", false, 0)
		tween.tween_callback(spin)
		
func _physics_process(delta):
	# Record Inerita & Add the gravity.
	if is_on_floor():
		_inertia.x = velocity.x
		_inertia.y = velocity.z
	else:	velocity.y -= gravity * delta * GravityMulti

	# Handle jump.
	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up")) and is_on_floor():
		velocity.y = JumpVelocity
	
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
		if is_on_floor() :	velocity.x = lerp(velocity.x,0.0,0.5)
		else:				velocity.x = lerp(_inertia.x,0.0,0.5)
	if velocity.z * input_vec <= 0 and velocity.z!=0:
		if is_on_floor() :	velocity.z = lerp(velocity.z,0.0,0.5)
		else:				velocity.z = lerp(_inertia.y,0.0,0.5)
		
	# Rotate
	if !is_on_floor() and !_inSpin:
		if !rotate_direct:
			if towards == 0 or towards == 1:
				if velocity.x > 0 or velocity.z < 0:	rotate_direct = -1
				if velocity.x < 0 or velocity.z > 0:	rotate_direct = 1
			else:
				if velocity.x > 0 or velocity.z < 0:	rotate_direct = 1
				if velocity.x < 0 or velocity.z > 0:	rotate_direct = -1
		visual.rotation.z += delta * RotateSpeed * rotate_direct
	else:
		rotate_direct = 0
		visual.rotation.z = lerp(visual.rotation.z,get_floor_actual_angle() + (floor( ((visual.rotation.z+(PI/4)) * 2) / PI ) * (PI/2)),0.5)

	if !_inSpin : move_and_slide()

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
	if space_detect.get_collision_count() == 0 : return true
	else : return false
	
func find_ground():
	if ground_detect.get_collision_count() == 0 and is_on_floor():
		if towards == 0 or towards == 2 :
			self.position.z = ground_finder.get_collision_point(0).z
		else :
			self.position.x = ground_finder.get_collision_point(0).x
