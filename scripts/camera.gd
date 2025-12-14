extends Camera2D

var target: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_target()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	position = target.position

func get_target() -> Node2D:
	var nodes = get_tree().get_nodes_in_group('Player')
	if nodes.size() == 0:
		push_error("Player not found - Player group is empty when Camera node was initializated.")
		return null
		
	target = nodes[0]
	return target
