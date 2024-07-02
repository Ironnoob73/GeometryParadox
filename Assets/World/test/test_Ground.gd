extends CSGBox3D

@onready var character = $"../../Character"

func _process(_delta):
	material.set_shader_parameter("offset", - character.get_camera_pos() * 0.1)
