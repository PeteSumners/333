extends Spatial

signal distance_measured(distance)

var distance = 0
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	emit_signal("distance_measured", distance)
	# Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func get_distance():
	var space_state = get_world().direct_space_state
	
	# use global coordinates, not local to node
	# transform.basis.z * 20 is 20m in the transform's forward direction
	var global_origin = global_transform.origin
	var result = space_state.intersect_ray(global_origin, global_origin+global_transform.basis.z.normalized() * 20)
	if (result.size() != 0):
		distance=(global_origin-result.position).length()
	else:
		distance=20.0
	
	var normalized_distance=distance/20.0
	emit_signal("distance_measured", normalized_distance)
	
func _physics_process(delta):
	get_distance()
