extends Node

@export var health: int = 10;
@export var despawn_on_death: Node3D;
@export var onhit_sound: AudioStreamPlayer3D

signal attack_hit(damage: int)
signal final_blow()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    final_blow.connect(_on_final_blow)

func ev_attack_hit(damage: int) -> void:
    health -= damage
    attack_hit.emit(damage)
    print("Ouch i got hit for ", damage, " damage and have ", health, "!")
    onhit_sound.play()

    if health <= 0:
        final_blow.emit()

func _on_final_blow() -> void:
    if despawn_on_death:
        despawn_on_death.queue_free()
