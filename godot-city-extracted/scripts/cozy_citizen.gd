class_name CozyCitizen
extends CharacterBody3D

var speed = 1.5
var color = Color("#8B7355")

var walk_direction = Vector3.ZERO
var walk_time = 0.0

func _ready():
	_setup_visual()
	_pick_new_direction()

func _setup_visual():
	var body = MeshInstance3D.new()
	body.mesh = CapsuleMesh.new()
	body.mesh.height = 1.8
	body.mesh.radius = 0.4
	body.material_override = _make_material(color, 0.8, 0.0)
	body.position.y = 0.9
	add_child(body)
	
	var head = MeshInstance3D.new()
	head.mesh = SphereMesh.new()
	head.mesh.radius = 0.35
	head.mesh.height = 0.7
	head.material_override = _make_material(color.lightened(0.15), 0.7, 0.0)
	head.position.y = 2.0
	add_child(head)
	
	if randf() > 0.5:
		var hat = MeshInstance3D.new()
		hat.mesh = CylinderMesh.new()
		hat.mesh.top_radius = 0.0
		hat.mesh.bottom_radius = 0.4
		hat.mesh.height = 0.5
		var hat_colors = [
			Color("#8B4513"), Color("#2F4F4F"),
			Color("#8B0000"), Color("#DAA520")
		]
		hat.material_override = _make_material(
			hat_colors[randi() % hat_colors.size()], 0.7, 0.0
		)
		hat.position.y = 2.35
		add_child(hat)
	
	var col = CollisionShape3D.new()
	col.shape = CapsuleShape3D.new()
	col.shape.height = 1.8
	col.shape.radius = 0.4
	col.position.y = 0.9
	add_child(col)

func _make_material(c, roughness, metalness):
	var mat = StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = roughness
	mat.metallic = metalness
	return mat

func _pick_new_direction():
	var angle = randf() * TAU
	walk_direction = Vector3(cos(angle), 0, sin(angle)).normalized()
	walk_time = 2.0 + randf() * 5.0

func _physics_process(delta):
	walk_time -= delta
	if walk_time <= 0:
		_pick_new_direction()
	
	var vel = walk_direction * speed
	velocity = vel
	move_and_slide()
	
	# Поворачиваемся по направлению движения
	if walk_direction.length() > 0.01:
		var target_rot = atan2(walk_direction.x, walk_direction.z)
		rotation.y = lerp_angle(rotation.y, target_rot, delta * 4.0)
	
	# Отскок от границ
	if position.x < -250 or position.x > 250:
		walk_direction.x *= -1
	if position.z < -150 or position.z > 150:
		walk_direction.z *= -1
