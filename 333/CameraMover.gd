extends KinematicBody

# How fast the player moves in meters per second.
export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
# export var fall_acceleration = 0

var velocity = Vector3.ZERO
var mouse_sensitivity = .5
onready var camera=$Camera

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		camera.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))

func _physics_process(delta):
	var direction = Vector3.ZERO

	var basis = get_global_transform().basis

	# direction to allow camera to pan.
	if Input.is_action_pressed("ui_right"):
		direction += basis.x
	if Input.is_action_pressed("ui_left"):
		direction -= basis.x
	if Input.is_action_pressed("ui_up"):
		direction -= basis.z
	if Input.is_action_pressed("ui_down"):
		direction += basis.z
	if Input.is_action_pressed("fly_up"):
		direction += Vector3.UP
	if Input.is_action_pressed("fly_down"):
		direction -= Vector3.UP

	direction = direction.normalized()
	velocity = direction * speed
	# velocity.y -= fall_acceleration * delta
	velocity = move_and_slide(velocity, Vector3.UP)
