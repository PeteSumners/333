# TODO: 
# efficiency improvement: if a weight modification doesn't improve the car's performance, try 
# modifying that weight in the opposite direction before moving on to the next weight.

extends KinematicBody

var generation = 0
var trial_number = 0
var trials_per_generation = 4
var score = 0
var best_score = 0

var front_distance = 0
var left_distance = 0
var right_distance = 0

var throttle = 0
var turn_velocity = 0

var top_speed = 7
var turn_top_speed = 3

var collision_throttle = 1 # 0 when we've hit a wall

# indices for modifying weights
var current_weight_i = 0
var current_weight_j = 0
var current_weight_k = 0

var weights = [[[-5.609273, 1.051665, -4.087031], [4.964757, 3.835046, -5.348293], [-1.108453, 1.526532, 7.237458], [-4.451486, 9.887965, -0.274695]], [[5.66667, -10, -6.312488], [-0.516353, -2.975431, -6.001421], [9.896377, 4.657638, 8.416399], [-0.088724, -4.725235, 2.105932]], [[-8.207224, -0.507557], [6.881296, -9.531243], [-10, -1.077558], [10, -7.588428]]]



var best_weights = []

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	#var weights = [[21, 22, 23], [21, 22, 23], [21, 22, 23]]
	#for i in range(weights.size()):
	#	print(i)
	# pass # Replace with function body.
	#randomize_weights()
	#modify_weights()
	#randomize_weights()
	#zero_weights()
	print('starting weights: ' + str(weights))
	reset_car()



func zero_weights():
	for i in range(weights.size()):
		for j in range(weights[i].size()):
			for k in range(weights[i][j].size()):
				weights[i][j][k] = 0

func randomize_weights():
	for i in range(weights.size()):
		for j in range(weights[i].size()):
			for k in range(weights[i][j].size()):
				weights[i][j][k] = rand_range(-10, 10)

# modify a single, random weight to be a new value between -10 and 10
func modify_weights():
	# print (str(current_weight_i) + str(current_weight_j) + str(current_weight_k))
	for n in range(1): # modify (up to) 1 weight at a time
#		var i = randi() % (weights.size())
#		var j = randi() % (weights[i].size())
#		var k = randi() % (weights[i][j].size())
		
		var weight = weights[current_weight_i][current_weight_j][current_weight_k]
		var weight_change = rand_range(-3, 3)
		weight += weight_change
		
		# bounds on new weight
		if (weight < -10.0):
			weight = -10.0
		elif (weight > 10.0):
			weight = 10.0
		
		weights[current_weight_i][current_weight_j][current_weight_k] = weight
		increment_weight_index()

# TODO: modulus instead of if statements
func increment_weight_index():
	current_weight_k += 1
	if (current_weight_k > weights[current_weight_i][current_weight_j].size()-1):
		current_weight_k = 0
		current_weight_j += 1
		if (current_weight_j > weights[current_weight_i].size()-1):
			current_weight_j = 0
			current_weight_i += 1
			if (current_weight_i > weights.size()-1):
				current_weight_i = 0

func _process(delta):
	var rotation_amount = delta*turn_top_speed*turn_velocity*collision_throttle
	
	propagate()

	# move the car forward based on throttle
	move_and_slide(global_transform.basis.z * throttle * top_speed * collision_throttle, Vector3.UP)

	# Rotate around the car's local Y axis
	rotate_object_local(Vector3.UP, rotation_amount)

func nn_gain(input):
	return (input / (1.0 + abs(input)))

# input must be array of three float values
# updates throttle and turn speed based on distance sensor input
func propagate():
	var neurons = [	[0, 0, 0], # don't include bias neurons
					[0, 0, 0], 
					[0, 0, 0], 
					[0, 0]
	]
	
	neurons[0] = [left_distance, front_distance, right_distance]
	
	for i in range(neurons.size()-1):
		for j in range(neurons[i].size()+1): # include bias neuron
			var current_neuron_output = 1 # default (bias) neuron value
			if (j < neurons[i].size()): # not bias neuron
				current_neuron_output = nn_gain(neurons[i][j])
			# current_neuron_output defaults to 1 (the bias)
			for k in range(neurons[i+1].size()): # ignore bias neuron in next layer
				neurons[i+1][k] += current_neuron_output * weights[i][j][k]
	# print(neurons)
	
	throttle = nn_gain(neurons[3][0])
	turn_velocity = nn_gain(neurons[3][1])

func _on_Front_Sensor_distance_measured(distance):
	front_distance=distance
	#print("front: " + str(front_distance)) 


func _on_Left_Sensor_distance_measured(distance):
	left_distance=distance
	#print("left: " + str(left_distance)) 


func _on_Right_Sensor_distance_measured(distance):
	right_distance=distance
	#print('right: ' + str(right_distance))

func reset_car():
	front_distance = 0
	left_distance = 0
	right_distance = 0

	throttle = 0
	turn_velocity = 0
	
	global_transform.origin=Vector3.ZERO
	set_rotation(Vector3.ZERO)
	
	collision_throttle = 1

# update score and best weights based on the last trial, and modify weights for the next one 
func start_next_trial():
	score=global_transform.origin.z#/(1+abs(global_transform.origin.x)) # forward distance, compensating for x-offset
	if (score > best_score):
		handle_new_best_score()
	
	if (trial_number < trials_per_generation):
		modify_weights()
		reset_car()
		trial_number+=1
	else:
		start_next_generation()
	
func handle_new_best_score():
	if (score > best_score):
		best_weights=weights.duplicate(true)
		best_score=score
		#print('new record: ' + str(best_score))
		#print('best weights: ' + str(best_weights))

# choose the best weight set, and then do the next generation of trials based on it
func start_next_generation():
	print('generation ' + str(generation))
	print('best weights: ' + str(best_weights))
	print('best score: ' + str(best_score))
	print('...')
	
	generation+=1
	weights=best_weights.duplicate(true)
	# best_score=0 # don't reset best score between generations, silly
	trial_number=0
	start_next_trial()

func _on_Timer_timeout():
	start_next_trial()


func _on_CollisionDetector_body_entered(body):
	print(body)
	collision_throttle = 0
