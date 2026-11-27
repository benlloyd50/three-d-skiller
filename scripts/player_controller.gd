class_name Player extends CharacterBody3D

@export_range(1, 35, 1) var speed: float = 10 # m/s
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2

@export_range(0.1, 3.0, 0.1) var jump_height: float = 1 # m
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1
@export_range(0, 100, 1) var tilt_sens: float = 1
@export_range(0, 100, 1) var tilt_magnitude: float = 1.5

var jumping: bool = false
var mouse_captured: bool = false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity
var grav_vel: Vector3 # Gravity velocity
var jump_vel: Vector3 # Jumping velocity

# a point to control the direction of the player's parts
@onready var pivot: Node3D = $Pivot
# Sprite hand on the player
@onready var hand: Sprite2D = $CanvasLayer/Control/hudhand
@onready var camera: Camera3D = $Pivot/Camera3D
@onready var hitcast: RayCast3D = $Pivot/hitcast
@onready var hit_sound: AudioStreamPlayer3D = $hitsounds

var hand_sprite_position: Vector2
var going_to_max: Dictionary[String, bool] = {
    "x": false,
    "y": true
}
@onready var BOB_Y_MIN: float = hand.transform.origin.y
@onready var BOB_Y_MAX: float = hand.transform.origin.y + 40
@onready var BOB_X_MIN: float = hand.transform.origin.x - 30
@onready var BOB_X_MAX: float = hand.transform.origin.x
@export_range(0.1, 10.0, 0.1) var bob_rate: float = 3.0

@export var empty_hands: Texture2D
@export var pickaxe: Texture2D


func _ready() -> void:
    capture_mouse()
    hand_sprite_position = hand.position

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        look_dir = event.relative * 0.001
        if mouse_captured: _rotate_camera()
    if Input.is_action_just_pressed(&"exit"): get_tree().quit()

    if Input.is_key_pressed(KEY_1):
        hand.texture = empty_hands
    if Input.is_key_pressed(KEY_2):
        hand.texture = pickaxe

func _physics_process(delta: float) -> void:
    if Input.is_action_just_pressed(&"jump"): jumping = true
    if mouse_captured: _handle_joypad_camera_rotation(delta)
    velocity = _walk(delta) + _gravity(delta) + _jump(delta)
    if velocity != Vector3.ZERO:
        hand.transform.origin.y = bob_between(hand.transform.origin.y, BOB_Y_MIN, BOB_Y_MAX, 1, delta, "y")
        # hand.transform.origin.x = bob_between(hand.transform.origin.x, BOB_X_MIN, BOB_X_MAX, 0.5, delta, "x")
    _tilt_camera_with_move(delta)
    move_and_slide()

    if Input.is_action_just_pressed(&"primary_action"):
        attack(delta)

func attack(_delta: float) -> void:
    var obj = hitcast.get_collider()
    hit_sound.play()
    if obj:
        print("Hit a ", obj.name)
        # send damage to the object and have it respond
        if obj.has_method("ev_attack_hit"):
            obj.ev_attack_hit(2)
        else:
            print("The obj.name has no method to handle being hit.")

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
    var move_dir = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
    var _forward: Vector3 = pivot.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
    var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
    walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
    return walk_vel


# if we move left or right tilt the camera towards a max left and right
# if no movement camera goes back to 0
# tilt on the x of the camera pivot
func _tilt_camera_with_move(delta: float) -> void:
    var move_dir = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
    # var move_vec: Vector3 = pivot.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
    var z: float

    if move_dir.x > 0.999: # when walking right
        z = lerp(camera.rotation_degrees.z, -tilt_magnitude, tilt_sens * delta)
        camera.rotation_degrees.z = z
    if move_dir.x < -0.999: # when walking left
        z = lerp(camera.rotation_degrees.z, tilt_magnitude, tilt_sens * delta)
        camera.rotation_degrees.z = z

    # var rotation_to_zero = (0 - camera.rotation.z)
    z = lerp(camera.rotation_degrees.z, 0.0, tilt_sens * delta)
    camera.rotation_degrees.z = z


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

func bob_between(curr: float, min_val: float, max_val: float, tolerance: float, delta: float, direction: String, max_dict: Dictionary[String, bool] = going_to_max) -> float:
    var is_going_to_max = max_dict[direction]
    if (is_going_to_max and curr >= max_val - tolerance) or (!is_going_to_max and curr <= min_val + tolerance):
        max_dict[direction] = !is_going_to_max

    return lerp(curr, max_val if is_going_to_max else min_val, bob_rate * delta)
