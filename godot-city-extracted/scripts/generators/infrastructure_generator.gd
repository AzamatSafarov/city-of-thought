extends RefCounted
class_name InfrastructureGenerator

var rng: RandomNumberGenerator
var params: Dictionary

func _init(p_rng, p_params):
    rng = p_rng
    params = p_params

func generate(city: Node3D):
    var parent = Node3D.new()
    parent.name = "Infrastructure"
    city.add_child(parent)
    
    var gs = params.gridSize
    var bs = params.blockSize
    var occupied = city.occupied_cells
    
    # Фонари вдоль дорог
    for x in range(gs):
        for z in range(gs):
            var cell = Vector2i(x, z)
            if occupied.get(cell, "") == "road":
                if rng.randf() < 0.4:
                    _place_streetlamp(cell, bs, city, parent)
                if rng.randf() < 0.15:
                    _place_bench(cell, bs, city, parent)
    
    # Мосты через реки
    for river in city.rivers:
        var crossings = _find_crossings(river, occupied)
        for crossing in crossings:
            _place_bridge(crossing, bs, city, parent)
    
    # Ворота на границах районов (если есть части книги)
    _place_gates(gs, bs, city, parent)
    
    # Статуи у монументов
    _place_statues(city, parent)
    
    # Часовая башня в центре для радиального layout
    if params.layoutType == "radial":
        _place_clocktower(gs, bs, city, parent)
    
    # Флаги для manifesto стиля
    if params.style == "constructivist" or params.style == "brutalist":
        _place_flags(city, parent)
    
    # Скамейки в парках
    for x in range(gs):
        for z in range(gs):
            var cell = Vector2i(x, z)
            if occupied.get(cell, "") == "park":
                if rng.randf() < 0.3:
                    _place_bench(cell, bs, city, parent)
                if rng.randf() < 0.2:
                    _place_fountain_small(cell, bs, city, parent)

func _place_streetlamp(cell: Vector2i, bs: float, city: Node3D, parent: Node3D):
    var h = city.get_height_at(cell)
    var pos = Vector3(cell.x * bs + bs / 2.0, h, cell.y * bs + bs / 2.0)
    
    var root = Node3D.new()
    root.position = pos
    
    # Столб
    var pole = MeshInstance3D.new()
    pole.mesh = CylinderMesh.new()
    pole.mesh.top_radius = 0.08
    pole.mesh.bottom_radius = 0.12
    pole.mesh.height = 4.0
    pole.position.y = 2.0
    var pmat = StandardMaterial3D.new()
    pmat.albedo_color = Color("#3A3A3A")
    pole.material_override = pmat
    root.add_child(pole)
    
    # Фонарь
    var lamp = MeshInstance3D.new()
    lamp.mesh = SphereMesh.new()
    lamp.mesh.radius = 0.3
    lamp.mesh.height = 0.5
    lamp.position.y = 4.2
    var lmat = StandardMaterial3D.new()
    lmat.albedo_color = Color("#FFF8D0")
    lmat.emission_enabled = true
    lmat.emission = Color("#FFF8D0")
    lmat.emission_energy_multiplier = 2.0
    lamp.material_override = lmat
    root.add_child(lamp)
    
    # PointLight
    var light = OmniLight3D.new()
    light.position.y = 4.0
    light.light_color = Color("#FFF8D0")
    light.light_energy = 0.8
    light.omni_range = 12.0
    light.shadow_enabled = false
    root.add_child(light)
    
    parent.add_child(root)

func _place_bench(cell: Vector2i, bs: float, city: Node3D, parent: Node3D):
    var h = city.get_height_at(cell)
    var pos = Vector3(cell.x * bs + bs / 2.0 + rng.randf() * 2 - 1, h, cell.y * bs + bs / 2.0)
    
    var bench = MeshInstance3D.new()
    bench.mesh = BoxMesh.new()
    bench.mesh.size = Vector3(2.0, 0.5, 0.6)
    bench.position = pos
    bench.position.y += 0.25
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#6B4A2A")
    bench.material_override = mat
    parent.add_child(bench)

func _place_bridge(crossing: Vector2i, bs: float, city: Node3D, parent: Node3D):
    var h = city.get_height_at(crossing)
    var pos = Vector3(crossing.x * bs + bs / 2.0, h + 1.0, crossing.y * bs + bs / 2.0)
    
    var bridge = MeshInstance3D.new()
    bridge.mesh = BoxMesh.new()
    bridge.mesh.size = Vector3(bs * 0.9, 0.3, bs * 0.9)
    bridge.position = pos
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#8A8A8A")
    bridge.material_override = mat
    parent.add_child(bridge)
    
    # Перила
    for side in [-1, 1]:
        var rail = MeshInstance3D.new()
        rail.mesh = CylinderMesh.new()
        rail.mesh.top_radius = 0.05
        rail.mesh.bottom_radius = 0.05
        rail.mesh.height = 1.0
        rail.position = pos + Vector3(side * bs * 0.4, 0.5, 0)
        rail.material_override = mat
        parent.add_child(rail)

func _place_gates(gs, bs, city, parent):
    # Ворота между районами (3 части = 2 границы)
    var x_mid = gs / 2
    var z_mid = gs / 2
    
    for border in [x_mid, z_mid]:
        for z in range(gs):
            var cell = Vector2i(border, z)
            if city.occupied_cells.get(cell, "") == "road":
                var h = city.get_height_at(cell)
                var pos = Vector3(cell.x * bs + bs / 2.0, h, cell.y * bs + bs / 2.0)
                
                for side in [-1, 1]:
                    var col = MeshInstance3D.new()
                    col.mesh = CylinderMesh.new()
                    col.mesh.top_radius = 0.3
                    col.mesh.bottom_radius = 0.4
                    col.mesh.height = 5.0
                    col.position = pos + Vector3(side * 3.0, 2.5, 0)
                    var mat = StandardMaterial3D.new()
                    mat.albedo_color = Color("#7A7A7A")
                    col.material_override = mat
                    parent.add_child(col)
                break

func _place_statues(city, parent):
    var buildings = city.get_node_or_null("Buildings")
    if not buildings:
        return
    for b in buildings.get_children():
        if b.name.begins_with("Monument") and rng.randf() < 0.5:
            var statue = MeshInstance3D.new()
            statue.mesh = CylinderMesh.new()
            statue.mesh.top_radius = 0.0
            statue.mesh.bottom_radius = 0.5
            statue.mesh.height = 3.0
            statue.position = b.position + Vector3(3.0, 1.5, 3.0)
            var mat = StandardMaterial3D.new()
            mat.albedo_color = Color("#9A9A9A")
            statue.material_override = mat
            parent.add_child(statue)

func _place_clocktower(gs, bs, city, parent):
    var center = Vector3(gs * bs / 2.0, 0, gs * bs / 2.0)
    var cell = Vector2i(gs / 2, gs / 2)
    center.y = city.get_height_at(cell)
    
    var tower = MeshInstance3D.new()
    tower.mesh = BoxMesh.new()
    tower.mesh.size = Vector3(4.0, 20.0, 4.0)
    tower.position = center + Vector3(0, 10.0, 0)
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#8A7A6A")
    tower.material_override = mat
    parent.add_child(tower)
    
    # Шпиль
    var spire = MeshInstance3D.new()
    spire.mesh = PrismMesh.new()
    spire.mesh.size = Vector3(3.0, 5.0, 3.0)
    spire.position = center + Vector3(0, 22.5, 0)
    spire.material_override = mat
    parent.add_child(spire)

func _place_flags(city, parent):
    var buildings = city.get_node_or_null("Buildings")
    if not buildings:
        return
    for b in buildings.get_children().slice(0, 5):
        var flag = MeshInstance3D.new()
        flag.mesh = BoxMesh.new()
        flag.mesh.size = Vector3(1.5, 0.8, 0.05)
        flag.position = b.position + Vector3(0, b.get_meta("height", 10.0) + 2.0, 0)
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color("#AA2020")
        flag.material_override = mat
        parent.add_child(flag)

func _place_fountain_small(cell, bs, city, parent):
    var h = city.get_height_at(cell)
    var pos = Vector3(cell.x * bs + bs / 2.0, h, cell.y * bs + bs / 2.0)
    
    # Kenney fountain если есть
    var scene = load("res://assets/models/buildings/pavement-fountain.glb")
    if scene:
        var inst = scene.instantiate()
        inst.position = pos
        inst.scale = Vector3(0.8, 0.8, 0.8)
        parent.add_child(inst)
    else:
        var f = MeshInstance3D.new()
        f.mesh = CylinderMesh.new()
        f.mesh.top_radius = 1.5
        f.mesh.bottom_radius = 1.8
        f.mesh.height = 0.5
        f.position = pos + Vector3(0, 0.25, 0)
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color("#7A7A8A")
        f.material_override = mat
        parent.add_child(f)
