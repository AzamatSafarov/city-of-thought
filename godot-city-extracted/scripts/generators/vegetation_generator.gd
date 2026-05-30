extends RefCounted
class_name VegetationGenerator

var rng: RandomNumberGenerator
var params: Dictionary

var kenney_trees = [
    "res://assets/models/buildings/grass-trees.glb",
    "res://assets/models/buildings/grass-trees-tall.glb"
]

func _init(p_rng, p_params):
    rng = p_rng
    params = p_params

func generate(city: Node3D):
    var parent = Node3D.new()
    parent.name = "Vegetation"
    city.add_child(parent)
    
    var gs = params.gridSize
    var bs = params.blockSize
    var occupied = city.occupied_cells
    
    # Деревья в парках и на границах дорог
    var tree_count = int(occupied.size() * params.treeDensity * 1.5)
    
    for i in range(tree_count):
        var cell = _random_suitable_cell(gs, occupied)
        if cell == Vector2i(-1, -1):
            continue
        
        var h = city.get_height_at(cell)
        var pos = Vector3(
            cell.x * bs + bs / 2.0 + rng.randf() * bs * 0.4 - bs * 0.2,
            h,
            cell.y * bs + bs / 2.0 + rng.randf() * bs * 0.4 - bs * 0.2
        )
        
        var tree = _create_tree()
        tree.position = pos
        parent.add_child(tree)
    
    # Живые изгороди вдоль дорог
    for x in range(gs):
        for z in range(gs):
            var cell = Vector2i(x, z)
            if occupied.get(cell, "") == "road":
                if rng.randf() < 0.15:
                    _place_hedge(cell, bs, city, parent)
    
    # Трава на всех не-водных клетках (Kenney grass)
    for x in range(gs):
        for z in range(gs):
            var cell = Vector2i(x, z)
            var type = occupied.get(cell, "")
            if type != "water":
                if rng.randf() < 0.3:
                    _place_grass_patch(cell, bs, city, parent)

func _random_suitable_cell(gs: int, occupied: Dictionary) -> Vector2i:
    for attempt in range(50):
        var x = rng.randi() % gs
        var z = rng.randi() % gs
        var cell = Vector2i(x, z)
        var type = occupied.get(cell, "")
        if type == "park" or type == "building":
            return cell
    return Vector2i(-1, -1)

func _create_tree() -> Node3D:
    var root = Node3D.new()
    
    # 50% Kenney модель, 50% процедурная
    if rng.randf() < 0.5 and kenney_trees.size() > 0:
        var path = kenney_trees[rng.randi() % kenney_trees.size()]
        var scene = load(path)
        if scene:
            var inst = scene.instantiate()
            inst.scale = Vector3(1.2, rng.randf() * 0.5 + 1.0, 1.2)
            root.add_child(inst)
            return root
    
    # Процедурное дерево по vegetationType
    match params.vegetationType:
        "deciduous":
            _build_deciduous_tree(root)
        "coniferous":
            _build_coniferous_tree(root)
        "palm":
            _build_palm_tree(root)
        "dead":
            _build_dead_tree(root)
        "crystalline":
            _build_crystal_tree(root)
        _:
            _build_deciduous_tree(root)
    
    return root

func _build_deciduous_tree(parent: Node3D):
    var trunk = MeshInstance3D.new()
    trunk.mesh = CylinderMesh.new()
    trunk.mesh.top_radius = 0.15
    trunk.mesh.bottom_radius = 0.25
    trunk.mesh.height = 4.0
    trunk.position.y = 2.0
    trunk.material_override = _trunk_mat()
    parent.add_child(trunk)
    
    var crown = MeshInstance3D.new()
    crown.mesh = SphereMesh.new()
    crown.mesh.radius = 2.0
    crown.mesh.height = 3.5
    crown.position.y = 5.0
    crown.material_override = _leaf_mat(Color("#4A8A4A"))
    parent.add_child(crown)

func _build_coniferous_tree(parent: Node3D):
    var trunk = MeshInstance3D.new()
    trunk.mesh = CylinderMesh.new()
    trunk.mesh.top_radius = 0.1
    trunk.mesh.bottom_radius = 0.3
    trunk.mesh.height = 5.0
    trunk.position.y = 2.5
    trunk.material_override = _trunk_mat()
    parent.add_child(trunk)
    
    for i in range(3):
        var cone = MeshInstance3D.new()
        cone.mesh = CylinderMesh.new()
        cone.mesh.top_radius = 0.0
        cone.mesh.bottom_radius = 1.5 - i * 0.4
        cone.mesh.height = 2.0
        cone.position.y = 4.0 + i * 1.2
        cone.material_override = _leaf_mat(Color("#2A5A2A"))
        parent.add_child(cone)

func _build_palm_tree(parent: Node3D):
    var trunk = MeshInstance3D.new()
    trunk.mesh = CylinderMesh.new()
    trunk.mesh.top_radius = 0.08
    trunk.mesh.bottom_radius = 0.2
    trunk.mesh.height = 7.0
    trunk.position.y = 3.5
    trunk.material_override = _trunk_mat()
    parent.add_child(trunk)
    
    # Пальмовые листья — 6 вееров
    for i in range(6):
        var leaf = MeshInstance3D.new()
        leaf.mesh = BoxMesh.new()
        leaf.mesh.size = Vector3(1.5, 0.05, 3.0)
        var angle = (TAU / 6) * i
        leaf.position = Vector3(cos(angle) * 1.2, 7.0, sin(angle) * 1.2)
        leaf.rotation_degrees = Vector3(30, rad_to_deg(angle), 0)
        leaf.material_override = _leaf_mat(Color("#5AAA5A"))
        parent.add_child(leaf)

func _build_dead_tree(parent: Node3D):
    var trunk = MeshInstance3D.new()
    trunk.mesh = CylinderMesh.new()
    trunk.mesh.top_radius = 0.08
    trunk.mesh.bottom_radius = 0.2
    trunk.mesh.height = 5.0
    trunk.position.y = 2.5
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#4A3A2A")
    trunk.material_override = mat
    parent.add_child(trunk)
    
    # Сухие ветки
    for i in range(4):
        var branch = MeshInstance3D.new()
        branch.mesh = CylinderMesh.new()
        branch.mesh.top_radius = 0.03
        branch.mesh.bottom_radius = 0.06
        branch.mesh.height = 1.5
        var angle = (TAU / 4) * i
        branch.position = Vector3(cos(angle) * 0.5, 4.0, sin(angle) * 0.5)
        branch.rotation_degrees = Vector3(0, rad_to_deg(angle), 60)
        branch.material_override = mat
        parent.add_child(branch)

func _build_crystal_tree(parent: Node3D):
    var trunk = MeshInstance3D.new()
    trunk.mesh = CylinderMesh.new()
    trunk.mesh.top_radius = 0.05
    trunk.mesh.bottom_radius = 0.15
    trunk.mesh.height = 4.0
    trunk.position.y = 2.0
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#A0B8D0")
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color.a = 0.7
    trunk.material_override = mat
    parent.add_child(trunk)
    
    # Кристаллы на верхушке
    for i in range(5):
        var cryst = MeshInstance3D.new()
        cryst.mesh = PrismMesh.new()
        cryst.mesh.size = Vector3(0.5, 1.5, 0.3)
        var angle = (TAU / 5) * i
        cryst.position = Vector3(cos(angle) * 0.3, 4.5, sin(angle) * 0.3)
        cryst.rotation_degrees = Vector3(0, rad_to_deg(angle), 15)
        cryst.material_override = mat
        parent.add_child(cryst)

func _place_hedge(cell: Vector2i, bs: float, city: Node3D, parent: Node3D):
    var h = city.get_height_at(cell)
    var pos = Vector3(cell.x * bs + bs / 2.0, h, cell.y * bs + bs / 2.0)
    
    var hedge = MeshInstance3D.new()
    hedge.mesh = BoxMesh.new()
    hedge.mesh.size = Vector3(bs * 0.1, 1.2, bs * 0.8)
    hedge.position = pos + Vector3(bs * 0.35, 0.6, 0)
    hedge.material_override = _leaf_mat(Color("#3A7A3A"))
    parent.add_child(hedge)

func _place_grass_patch(cell: Vector2i, bs: float, city: Node3D, parent: Node3D):
    var h = city.get_height_at(cell)
    var pos = Vector3(cell.x * bs + bs / 2.0, h, cell.y * bs + bs / 2.0)
    
    # Kenney grass
    var scene = load("res://assets/models/buildings/grass.glb")
    if scene:
        var inst = scene.instantiate()
        inst.position = pos
        inst.scale = Vector3(1.2, rng.randf() * 0.3 + 0.9, 1.2)
        parent.add_child(inst)
    else:
        # Fallback: маленький зелёный куб
        var grass = MeshInstance3D.new()
        grass.mesh = BoxMesh.new()
        grass.mesh.size = Vector3(bs * 0.8, 0.05, bs * 0.8)
        grass.position = pos
        grass.material_override = _leaf_mat(Color("#6AAA6A"))
        parent.add_child(grass)

func _trunk_mat() -> StandardMaterial3D:
    var m = StandardMaterial3D.new()
    m.albedo_color = Color("#6B5B45")
    m.roughness = 0.9
    return m

func _leaf_mat(c: Color) -> StandardMaterial3D:
    var m = StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 0.85
    return m
