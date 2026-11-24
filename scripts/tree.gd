extends Node

@export var health: int = 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass

func on_attack_hit(damage: int) -> void:
    health -= damage
    print("O i was hit ", health)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    if health <= 0:
        print("Tree is dead")
        queue_free()
