extends Area3D

@onready var collision = $Collision/CollisionShape

func switch(state:bool):
	collision.call_deferred("set_disabled",!state)
