extends Node3D

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	_setup_ground()
	_setup_water()
	_generate_city()
	_spawn_simple_citizens(20)
	_setup_camera()

func _setup_ground():
	var ground = $Ground
	if not is_instance_valid(ground):
		return
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#8AB88A")
	mat.roughness = 0.95
	ground.material_override = mat

func _setup_water():
	var water = $Water
	if not is_instance_valid(water):
		return
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#6AA0C0")
	mat.roughness = 0.05
	mat.metallic = 0.1
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.7
	water.material_override = mat

func _generate_city():
	var book = GessenBook.new()
	var min_p = book.get_min_pages()
	var max_p = book.get_max_pages()
	var buildings_parent = $Buildings
	var label_parent = $Labels
	
	for chapter in book.chapters:
		var part = book.parts[chapter.part]
		var px = part["position"].x
		var pz = part["position"].z
		
		var b_count = int(remap(chapter.pages, min_p, max_p, 5, 15))
		var center_x = px + (-30.0 + rng.randf() * 60.0)
		var center_z = pz + (-25.0 + rng.randf() * 50.0)
		
		var monument = CozyBuilding.new()
		monument.setup(chapter, part, true)
		monument.position = Vector3(center_x, 0, center_z)
		monument.add_to_group("buildings")
		buildings_parent.add_child(monument)
		
		for i in range(b_count):
			var angle = (i / float(b_count)) * TAU + (-0.3 + rng.randf() * 0.6)
			var dist = 12.0 + rng.randf() * 23.0
			var bx = center_x + cos(angle) * dist
			var bz = center_z + sin(angle) * dist
			
			var building = CozyBuilding.new()
			building.setup(chapter, part, false)
			building.position = Vector3(bx, 0, bz)
			building.rotation.y = -0.2 + rng.randf() * 0.4
			building.add_to_group("buildings")
			buildings_parent.add_child(building)
		
		_add_label(Vector3(center_x, 40, center_z - 15), chapter.title, str(chapter.pages) + " pp")
	
	print("City generated: ", buildings_parent.get_child_count(), " buildings")

func _add_label(pos, text, sub):
	var label_parent = $Labels
	if not is_instance_valid(label_parent):
		return
	var label = Label3D.new()
	label.text = text + "\n" + sub
	label.position = pos
	label.font_size = 48
	label.modulate = Color("#4A4A5A")
	label.outline_size = 0
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_parent.add_child(label)

func _spawn_simple_citizens(count):
	var citizens_parent = $Citizens
	if not is_instance_valid(citizens_parent):
		return
	var colors = [
		Color("#8B7355"), Color("#A0522D"), Color("#6B8E6B"),
		Color("#8B6969"), Color("#7A6A50"), Color("#6B5B45")
	]
	for i in range(count):
		var citizen = CozyCitizen.new()
		citizen.color = colors[rng.randi() % colors.size()]
		citizen.position = Vector3(
			-200.0 + rng.randf() * 400.0,
			0.5,
			-100.0 + rng.randf() * 200.0
		)
		citizen.add_to_group("citizens")
		citizens_parent.add_child(citizen)
	print("Spawned ", count, " citizens")

func _setup_camera():
	var cam = get_viewport().get_camera_3d()
	if not is_instance_valid(cam):
		return
	cam.position = Vector3(0, 120, 280)
	cam.look_at(Vector3(0, 0, 0))

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(-15)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(15)

func _zoom_camera(amount):
	var cam = get_viewport().get_camera_3d()
	if not is_instance_valid(cam):
		return
	var dir = cam.position.normalized()
	cam.position += dir * amount
	cam.position.x = clamp(cam.position.x, 50, 800)
	cam.position.y = clamp(cam.position.y, 40, 500)
	cam.position.z = clamp(cam.position.z, 50, 800)
