extends AudioStreamPlayer3D

@export var hitbox: CollisionShape3D
@export var ground_check: RayCast3D
var last_position_stepped: Vector3 = Vector3.ZERO
@export_range(0.1, 10.0, 0.1) var footstep_spacing: float = 2.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    var is_on_floor = ground_check.is_colliding()
    if last_position_stepped.distance_to(global_transform.origin) > footstep_spacing && is_on_floor:
        play()
        last_position_stepped = global_transform.origin
    pass
