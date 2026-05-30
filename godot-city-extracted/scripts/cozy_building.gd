class_name CozyBuilding
extends Node3D

var chapter
var part_data
var is_monument = false

var building_color
var roof_color
var accent_color
var base_height = 8.0

func setup(ch, part, monument = false):
	chapter = ch
	part_data = part
	is_monument = monument
	building_color = part["color"]
	roof_color = part["roof"]
	accent_color = part["accent"]
	_generate()

func _generate():
	var book = GessenBook.new()
	var min_p = book.get_min_pages()
	var max_p = book.get_max_pages()
	var h = remap(chapter.pages, min_p, max_p, 4.0, 24.0)
	if is_monument:
		h = remap(chapter.pages, min_p, max_p, 12.0, 40.0)
	var w = (3.0 + randf() * 3.0)
	if is_monument:
		w = (6.0 + randf() * 4.0)
	var d = w * (0.6 + randf() * 0.3)
	
	var body = MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.mesh.size = Vector3(w, h, d)
	body.material_override = _make_material(building_color, 0.9, 0.0)
	body.position.y = h / 2.0
	body.cast_shadow = true
	add_child(body)
	
	var roof = MeshInstance3D.new()
	if randf() > 0.5:
		roof.mesh = BoxMesh.new()
		roof.mesh.size = Vector3(w + 0.5, 0.8, d + 0.5)
	else:
		roof.mesh = PrismMesh.new()
		roof.mesh.size = Vector3(w + 0.4, 2.0, d + 0.4)
	roof.material_override = _make_material(roof_color, 0.7, 0.1)
	roof.position.y = h + 0.4
	roof.cast_shadow = true
	add_child(roof)
	
	var win_rows = max(1, int(h / 5.0))
	var win_cols = max(1, int(w / 3.0))
	var lit_chance = remap(chapter.pages, min_p, max_p, 0.2, 0.6)
	for r in range(win_rows):
		for c in range(win_cols):
			if randf() > lit_chance:
				continue
			var win = MeshInstance3D.new()
			win.mesh = BoxMesh.new()
			win.mesh.size = Vector3(0.8, 1.0, 0.15)
			var win_color = Color("#FFF8E7")
			if randf() > 0.3:
				win_color = Color("#D0E8FF")
			win.material_override = _make_material(win_color, 0.1, 0.0, 0.6)
			var col_t = 0.0
			if win_cols > 1:
				col_t = float(c) / float(win_cols - 1)
			win.position = Vector3(
				-w / 2.0 + 1.2 + col_t * (w - 2.4),
				2.5 + r * 5.0,
				d / 2.0 + 0.1
			)
			add_child(win)
	
	if is_monument:
		var door = MeshInstance3D.new()
		door.mesh = BoxMesh.new()
		door.mesh.size = Vector3(2.0, 3.5, 0.3)
		door.material_override = _make_material(accent_color, 0.6, 0.1)
		door.position = Vector3(0, 1.75, d / 2.0 + 0.2)
		add_child(door)
		
		for ox_value in [-2.5, 2.5]:
			var col = MeshInstance3D.new()
			col.mesh = CylinderMesh.new()
			col.mesh.top_radius = 0.3
			col.mesh.bottom_radius = 0.35
			col.mesh.height = h * 0.4
			col.material_override = _make_material(accent_color.darkened(0.1), 0.6, 0.2)
			col.position = Vector3(ox_value, h * 0.2, d / 2.0 + 0.5)
			add_child(col)
	
	var base = MeshInstance3D.new()
	base.mesh = BoxMesh.new()
	base.mesh.size = Vector3(w + 1.0, 0.6, d + 2.0)
	base.material_override = _make_material(building_color.darkened(0.15), 0.95, 0.0)
	base.position.y = 0.3
	add_child(base)
	
	var col_shape = CollisionShape3D.new()
	col_shape.shape = BoxShape3D.new()
	col_shape.shape.size = Vector3(w, h + 2.0, d)
	col_shape.position.y = (h + 2.0) / 2.0
	var area = Area3D.new()
	area.add_child(col_shape)
	area.input_event.connect(_on_input_event)
	add_child(area)
	
	base_height = h

func _make_material(color_val, roughness, metalness, emissive = 0.0):
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_val
	mat.roughness = roughness
	mat.metallic = metalness
	if emissive > 0.0:
		mat.emission_enabled = true
		mat.emission = color_val
		mat.emission_energy_multiplier = emissive
	return mat

func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select()

func _select():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		ui.show_chapter(chapter, part_data)
	_pulse()

func _pulse():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.05, 1.05, 1.05), 0.15)
	tween.tween_property(self, "scale", Vector3.ONE, 0.15)

func get_height():
	return base_height
