class_name Player extends CharacterBody3D

@export_range(1, 35, 1) var speed: float = 10 # m/s
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2

@export_range(0.1, 3.0, 0.1) var jump_height: float = 1 # m
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1

var jumping: bool = false
var mouse_captured: bool = false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity
var grav_vel: Vector3 # Gravity velocity
var jump_vel: Vector3 # Jumping velocity

# a point to control the direction of the player's parts
@onready var pivot: Node3D = $Pivot
# Sprite hand on the player
@onready var hand: Sprite2D = $CanvasLayer/Control/hudhand
@onready var hitcast: RayCast3D = $Pivot/hitcast

var hand_sprite_position: Vector2
var going_to_max = true
@onready var BOB_Y_MIN: float = hand.transform.origin.y + 40
@onready var BOB_Y_MAX: float = hand.transform.origin.y
@export_range(0.1, 10.0, 0.1) var bob_rate: float = 3.0


func _ready() -> void:
	capture_mouse()
	hand_sprite_position = hand.position

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_dir = event.relative * 0.001
		if mouse_captured: _rotate_camera()
	if Input.is_action_just_pressed(&"exit"): get_tree().quit()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed(&"jump"): jumping = true
	if mouse_captured: _handle_joypad_camera_rotation(delta)
	velocity = _walk(delta) + _gravity(delta) + _jump(delta)
	if velocity != Vector3.ZERO && is_on_floor():
		hand.transform.origin.y = bob_between(hand.transform.origin.y, BOB_Y_MIN, BOB_Y_MAX, 0.05, delta)
		hand.transform.origin.x = bob_between(hand.transform.origin.x, hand_sprite_position.x - 0.04, hand_sprite_position.x + 0.04, 0.05, delta / 4.0)
	move_and_slide()

	if Input.is_action_just_pressed(&"primary_action"):
		attack(delta)

func attack(_delta: float) -> void:
	var obj = hitcast.get_collider()
	if obj:
		print("Hit a ", obj.name)
		# send damage to the object and have it respond
		if obj.has_method("on_attack_hit"):
			obj.on_attack_hit(2)

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _rotate_camera(sens_mod: float = 1.0) -> void:
	pivot.rotation.y -= look_dir.x * camera_sens * sens_mod
	pivot.rotation.x = clamp(pivot.rotation.x - look_dir.y * camera_sens * sens_mod, -1.5, 1.5)

func _handle_joypad_camera_rotation(delta: float, sens_mod: float = 1.0) -> void:
	var joypad_dir: Vector2 = Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
	if joypad_dir.length() > 0:
		look_dir += joypad_dir * delta
		_rotate_camera(sens_mod)
		look_dir = Vector2.ZERO

func _walk(delta: float) -> Vector3:
	move_dir = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var _forward: Vector3 = pivot.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
	return walk_vel

func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel

func _jump(delta: float) -> Vector3:
	if jumping:
		if is_on_floor(): jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
		jumping = false
		return jump_vel
	jump_vel = Vector3.ZERO if is_on_floor() or is_on_ceiling_only() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	return jump_vel

func bob_between(curr: float, min_val: float, max_val: float, tolerance: float, delta: float) -> float:
	if (going_to_max and curr >= max_val - tolerance) or (!going_to_max and curr <= min_val + tolerance):
		going_to_max = !going_to_max

	return lerp(curr, max_val if going_to_max else min_val, bob_rate * delta)
