extends RefCounted
class_name BuildingGenerator

var rng: RandomNumberGenerator
var params: Dictionary
var kenney_buildings: Array = [
    "res://assets/models/buildings/building-small-a.glb",
    "res://assets/models/buildings/building-small-b.glb",
    "res://assets/models/buildings/building-small-c.glb",
    "res://assets/models/buildings/building-small-d.glb",
    "res://assets/models/buildings/building-garage.glb"
]

func _init(p_rng, p_params):
    rng = p_rng
    params = p_params

func generate(city: Node3D) -> Array:
    var buildings = []
    var parent = Node3D.new()
    parent.name = "Buildings"
    city.add_child(parent)
    
    var gs = params.gridSize
    var bs = params.blockSize
    var occupied = city.occupied_cells
    
    # Собираем все building-клетки
    var building_cells = []
    for x in range(gs):
        for z in range(gs):
            var cell = Vector2i(x, z)
            if occupied.get(cell, "") == "building":
                building_cells.append(cell)
    
    building_cells.shuffle()
    
    # Определяем монументы — крупные главы / центральные идеи
    var monument_count = max(1, int(building_cells.size() * 0.08))
    var monuments = building_cells.slice(0, monument_count)
    var regular = building_cells.slice(monument_count)
    
    for cell in monuments:
        var b = _create_monument(cell, city)
        parent.add_child(b)
        buildings.append(b)
    
    # Обычные здания с подразделением квартала
    for cell in regular:
        var count = params.blockSubdivisions
        var positions = _subdivide_cell(cell, count, bs)
        for pos in positions:
            var b = _create_building(pos, cell, city, false)
            parent.add_child(b)
            buildings.append(b)
    
    return buildings

func _subdivide_cell(cell: Vector2i, count: int, bs: float) -> Array:
    var center = Vector3(cell.x * bs + bs / 2.0, 0, cell.y * bs + bs / 2.0)
    var half = bs * 0.35
    var positions = []
    
    match count:
        1:
            positions = [center]
        2:
            positions = [
                center + Vector3(-half * 0.5, 0, 0),
                center + Vector3(half * 0.5, 0, 0)
            ]
        3:
            positions = [
                center + Vector3(-half * 0.5, 0, -half * 0.5),
                center + Vector3(half * 0.5, 0, -half * 0.5),
                center + Vector3(0, 0, half * 0.5)
            ]
        4:
            var o = half * 0.5
            positions = [
                center + Vector3(-o, 0, -o),
                center + Vector3(o, 0, -o),
                center + Vector3(-o, 0, o),
                center + Vector3(o, 0, o)
            ]
    
    return positions

func _create_monument(cell: Vector2i, city: Node3D) -> Node3D:
    var pos = Vector3(cell.x * params.blockSize + params.blockSize / 2.0, 0, cell.y * params.blockSize + params.blockSize / 2.0)
    pos.y = city.get_height_at(cell)
    
    var root = Node3D.new()
    root.name = "Monument_%d_%d" % [cell.x, cell.y]
    root.position = pos
    
    # Основной объём — высокий
    var h = params.buildingHeightRange.max * 1.2
    var w = params.blockSize * 0.7
    
    var body = _build_body(h, w, w * 0.7)
    root.add_child(body)
    
    # Крыша по стилю
    var roof = _build_roof(h, w)
    root.add_child(roof)
    
    # Детали
    _add_style_details(root, h, w, true)
    
    # Коллизия для клика
    _add_clickable(root, w, h)
    
    return root

func _create_building(pos: Vector3, cell: Vector2i, city: Node3D, is_monument: bool) -> Node3D:
    pos.y = city.get_height_at(cell)
    
    var root = Node3D.new()
    root.position = pos
    
    # Шанс Kenney-модели (30%)
    if rng.randf() < 0.3 and kenney_buildings.size() > 0:
        var path = kenney_buildings[rng.randi() % kenney_buildings.size()]
        var scene = load(path)
        if scene:
            var inst = scene.instantiate()
            inst.scale = Vector3(0.8, rng.randf() * 0.5 + 0.8, 0.8)
            root.add_child(inst)
            _add_clickable(root, 4, 8)
            return root
    
    # Процедурное здание
    var ratio = rng.randf()
    var is_skyscraper = ratio < params.skyscraperRatio
    var h: float
    var w = params.blockSize * 0.35
    
    if is_skyscraper:
        h = params.buildingHeightRange.max * (0.8 + rng.randf() * 0.2)
    else:
        var min_h = params.buildingHeightRange.min
        var max_h = params.buildingHeightRange.max
        h = lerp(min_h, max_h, rng.randf())
    
    var body = _build_body(h, w, w * (0.6 + rng.randf() * 0.3))
    root.add_child(body)
    
    var roof = _build_roof(h, w)
    root.add_child(roof)
    
    # Окна
    _add_windows(root, h, w)
    
    # Детали стиля
    _add_style_details(root, h, w, false)
    
    _add_clickable(root, w, h)
    
    return root

func _build_body(h: float, w: float, d: float) -> MeshInstance3D:
    var mi = MeshInstance3D.new()
    var mesh: Mesh
    
    match params.style:
        "organic":
            mesh = CylinderMesh.new()
            mesh.top_radius = w * 0.4
            mesh.bottom_radius = w * 0.5
            mesh.height = h
        "baroque":
            # Bulging box — используем BoxMesh с масштабом
            mesh = BoxMesh.new()
            mesh.size = Vector3(w * 1.1, h, d * 1.05)
        _:
            mesh = BoxMesh.new()
            mesh.size = Vector3(w, h, d)
    
    mi.mesh = mesh
    mi.position.y = h / 2.0
    mi.cast_shadow = true
    mi.material_override = _building_material()
    return mi

func _build_roof(h: float, w: float) -> MeshInstance3D:
    var mi = MeshInstance3D.new()
    var mesh: Mesh
    var y_pos = h
    
    match params.style:
        "classical", "constructivist":
            mesh = PrismMesh.new()
            mesh.size = Vector3(w + 0.5, 2.0, w * 0.7 + 0.5)
            y_pos = h + 1.0
        "baroque", "organic":
            mesh = SphereMesh.new()
            mesh.radius = w * 0.4
            mesh.height = w * 0.6
            y_pos = h + w * 0.2
        "neo_gothic":
            mesh = CylinderMesh.new()
            mesh.top_radius = 0.0
            mesh.bottom_radius = w * 0.25
            mesh.height = h * 0.3
            y_pos = h + h * 0.15
        "brutalist", "minimal", "deconstructivist":
            mesh = BoxMesh.new()
            mesh.size = Vector3(w * 0.9, 0.5, w * 0.6)
            y_pos = h + 0.25
        _:
            mesh = PrismMesh.new()
            mesh.size = Vector3(w + 0.5, 2.0, w * 0.7 + 0.5)
            y_pos = h + 1.0
    
    mi.mesh = mesh
    mi.position.y = y_pos
    mi.cast_shadow = true
    mi.material_override = _roof_material()
    return mi

func _add_windows(parent: Node3D, h: float, w: float):
    var rows = max(1, int(h / 4.0))
    var cols = max(1, int(w / 2.5))
    var lit_chance = params.windowLightFrequency
    
    for r in range(rows):
        for c in range(cols):
            if rng.randf() > lit_chance:
                continue
            var win = MeshInstance3D.new()
            win.mesh = BoxMesh.new()
            win.mesh.size = Vector3(0.6, 0.8, 0.1)
            
            var ct = 0.0
            if cols > 1:
                ct = float(c) / float(cols - 1)
            
            win.position = Vector3(
                -w / 2.0 + 0.8 + ct * (w - 1.6),
                1.5 + r * 4.0,
                w * 0.35 / 2.0 + 0.05
            )
            
            # Случайно — на заднюю стенку тоже
            if rng.randf() > 0.5:
                win.position.z *= -1
            
            var win_color = Color("#FFF8E7")
            if rng.randf() > 0.3:
                win_color = Color("#D0E8FF")
            if rng.randf() < 0.1:
                win_color = Color("#FFD4A0")  # тёплое окно
            
            var mat = StandardMaterial3D.new()
            mat.albedo_color = win_color
            mat.emission_enabled = true
            mat.emission = win_color
            mat.emission_energy_multiplier = 0.5 + rng.randf() * 0.5
            win.material_override = mat
            parent.add_child(win)

func _add_style_details(parent: Node3D, h: float, w: float, is_monument: bool):
    match params.style:
        "classical":
            # Колонны для монумента
            if is_monument:
                for ox in [-w * 0.6, w * 0.6]:
                    var col = MeshInstance3D.new()
                    col.mesh = CylinderMesh.new()
                    col.mesh.top_radius = w * 0.06
                    col.mesh.bottom_radius = w * 0.08
                    col.mesh.height = h * 0.4
                    col.position = Vector3(ox, h * 0.2, w * 0.4)
                    col.material_override = _building_material()
                    parent.add_child(col)
        "neo_gothic":
            # Стрельчатые арки — выступы по бокам
            for side in [-1, 1]:
                var spur = MeshInstance3D.new()
                spur.mesh = BoxMesh.new()
                spur.mesh.size = Vector3(w * 0.15, h * 0.6, w * 0.2)
                spur.position = Vector3(side * w * 0.55, h * 0.3, 0)
                spur.material_override = _building_material()
                parent.add_child(spur)
        "constructivist":
            # Антенна/флаг на крыше
            var antenna = MeshInstance3D.new()
            antenna.mesh = CylinderMesh.new()
            antenna.mesh.top_radius = 0.05
            antenna.mesh.bottom_radius = 0.1
            antenna.mesh.height = h * 0.3
            antenna.position = Vector3(0, h + h * 0.15, 0)
            antenna.material_override = _roof_material()
            parent.add_child(antenna)
        "deconstructivist":
            # Разрыв — два блока под углом
            if not is_monument and rng.randf() < 0.3:
                var shift = MeshInstance3D.new()
                shift.mesh = BoxMesh.new()
                shift.mesh.size = Vector3(w * 0.5, h * 0.7, w * 0.35)
                shift.position = Vector3(w * 0.2, h * 0.35, 0)
                shift.rotation_degrees = Vector3(0, 0, 5)
                shift.material_override = _building_material()
                parent.add_child(shift)
        "baroque":
            # Орнамент — выступающий карниз
            var cornice = MeshInstance3D.new()
            cornice.mesh = BoxMesh.new()
            cornice.mesh.size = Vector3(w * 1.2, 0.4, d * 1.1)
            cornice.position = Vector3(0, h * 0.7, 0)
            cornice.material_override = _roof_material()
            parent.add_child(cornice)
        "organic":
            # Лиана — вьющаяся трубка на стене
            if rng.randf() < 0.4:
                var vine = MeshInstance3D.new()
                vine.mesh = TorusMesh.new()
                vine.mesh.inner_radius = w * 0.1
                vine.mesh.outer_radius = w * 0.15
                vine.position = Vector3(w * 0.4, h * 0.3, w * 0.3)
                vine.rotation_degrees = Vector3(45, 0, 0)
                var vm = StandardMaterial3D.new()
                vm.albedo_color = Color("#4A8A4A")
                vine.material_override = vm
                parent.add_child(vine)

func _building_material() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()
    var mat_name = params.material
    var base_hue = params.dominantHue / 360.0
    var sat = params.saturationBase / 100.0
    var bright = params.brightnessBase / 100.0
    
    match mat_name:
        "stone":   mat.albedo_color = Color.from_hsv(base_hue, sat * 0.3, bright * 0.9)
        "concrete": mat.albedo_color = Color.from_hsv(base_hue, sat * 0.1, bright * 0.8)
        "glass":   mat.albedo_color = Color.from_hsv(base_hue, sat * 0.5, bright * 1.2)
        "brick":   mat.albedo_color = Color.from_hsv(base_hue * 0.95, sat * 0.7, bright * 0.75)
        "marble":  mat.albedo_color = Color.from_hsv(base_hue, sat * 0.2, bright * 1.1)
        "metal":   mat.albedo_color = Color.from_hsv(base_hue, sat * 0.4, bright * 0.7); mat.metallic = 0.6
        "wood":    mat.albedo_color = Color.from_hsv(base_hue * 0.9, sat * 0.6, bright * 0.6)
        "ice":     mat.albedo_color = Color.from_hsv(base_hue, sat * 0.1, bright * 1.3); mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.albedo_color.a = 0.8
    
    mat.roughness = 0.8
    return mat

func _roof_material() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()
    var h = params.dominantHue + params.accentHueShift
    mat.albedo_color = Color.from_hsv(h / 360.0, params.saturationBase / 150.0, params.brightnessBase / 120.0)
    mat.roughness = 0.7
    return mat

func _add_clickable(node: Node3D, w: float, h: float):
    var area = Area3D.new()
    var shape = CollisionShape3D.new()
    shape.shape = BoxShape3D.new()
    shape.shape.size = Vector3(w, h + 2, w)
    shape.position.y = h / 2.0
    area.add_child(shape)
    area.input_event.connect(func(_c, event, _p, _n, _s):
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _on_building_click(node)
    )
    node.add_child(area)

func _on_building_click(building):
    var tween = building.create_tween()
    tween.tween_property(building, "scale", Vector3(1.1, 1.1, 1.1), 0.15)
    tween.tween_property(building, "scale", Vector3.ONE, 0.15)
    print("Building clicked: ", building.name)
