extends RefCounted
class_name WaterGenerator

var rng: RandomNumberGenerator
var params: Dictionary

func _init(p_rng, p_params):
    rng = p_rng
    params = p_params

func generate(parent: Node3D, heights: Dictionary) -> Array:
    var rivers = []
    var wp = params.waterPresence
    if wp <= 0.001:
        return rivers
    
    var gs = params.gridSize
    var river_count = int(wp * 5) + 1
    
    var water_parent = Node3D.new()
    water_parent.name = "Water"
    parent.add_child(water_parent)
    
    for r in range(river_count):
        # Найти старт — локальный максимум на границе
        var start = _find_start_on_edge(gs, heights)
        var river = [start]
        var current = start
        
        for step in range(gs * 3):  # max steps
            var lowest = _lowest_neighbor(current, gs, heights)
            if lowest == current or heights.get(lowest, 0) >= heights.get(current, 0):
                break
            river.append(lowest)
            current = lowest
        
        rivers.append(river)
        _build_river_mesh(river, water_parent)
    
    # Озёра в локальных минимумах
    var lake_count = int(wp * 3)
    for i in range(lake_count):
        var lake_pos = _find_local_minimum(gs, heights)
        if lake_pos:
            _build_lake_mesh(lake_pos, water_parent)
    
    # Фонтан в центре для радиального layout
    if params.layoutType == "radial":
        _build_fountain_mesh(Vector3(gs * params.blockSize / 2.0, 0, gs * params.blockSize / 2.0), water_parent)
    
    return rivers

func _find_start_on_edge(gs: int, heights: Dictionary) -> Vector2i:
    var edge = []
    for x in range(gs):
        edge.append(Vector2i(x, 0))
        edge.append(Vector2i(x, gs - 1))
    for z in range(gs):
        edge.append(Vector2i(0, z))
        edge.append(Vector2i(gs - 1, z))
    edge.shuffle()
    for cell in edge:
        if heights.get(cell, 0) > 0.5:
            return cell
    return edge[0]

func _lowest_neighbor(cell: Vector2i, gs: int, heights: Dictionary) -> Vector2i:
    var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
    var lowest = cell
    var min_h = heights.get(cell, 999)
    for d in dirs:
        var n = cell + d
        if n.x < 0 or n.x >= gs or n.y < 0 or n.y >= gs:
            continue
        var nh = heights.get(n, 999)
        if nh < min_h:
            min_h = nh
            lowest = n
    return lowest

func _find_local_minimum(gs: int, heights: Dictionary) -> Vector2i:
    var candidates = []
    for x in range(gs):
        for z in range(gs):
            candidates.append(Vector2i(x, z))
    candidates.shuffle()
    for cell in candidates[:10]:
        var h = heights.get(cell, 999)
        var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
        var is_min = true
        for d in dirs:
            var n = cell + d
            if heights.get(n, 999) < h:
                is_min = false
                break
        if is_min:
            return cell
    return candidates[0] if candidates.size() > 0 else Vector2i(0,0)

func _build_river_mesh(river: Array, parent: Node3D):
    var bs = params.blockSize
    for cell in river:
        var cx = cell.x * bs + bs / 2.0
        var cz = cell.y * bs + bs / 2.0
        var mesh = BoxMesh.new()
        mesh.size = Vector3(bs * 0.6, 0.3, bs * 0.6)
        var mi = MeshInstance3D.new()
        mi.mesh = mesh
        mi.position = Vector3(cx, -0.2, cz)
        mi.material_override = _water_mat()
        parent.add_child(mi)

func _build_lake_mesh(cell: Vector2i, parent: Node3D):
    var bs = params.blockSize
    var cx = cell.x * bs + bs / 2.0
    var cz = cell.y * bs + bs / 2.0
    var mesh = CylinderMesh.new()
    mesh.top_radius = bs * 0.8
    mesh.bottom_radius = bs * 0.8
    mesh.height = 0.2
    var mi = MeshInstance3D.new()
    mi.mesh = mesh
    mi.position = Vector3(cx, -0.15, cz)
    mi.material_override = _water_mat()
    parent.add_child(mi)

func _build_fountain_mesh(pos: Vector3, parent: Node3D):
    var mesh = CylinderMesh.new()
    mesh.top_radius = 2.0
    mesh.bottom_radius = 2.0
    mesh.height = 1.0
    var mi = MeshInstance3D.new()
    mi.mesh = mesh
    mi.position = pos + Vector3(0, 0.5, 0)
    mi.material_override = _water_mat()
    parent.add_child(mi)

func _water_mat() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#6AA0C0")
    mat.roughness = 0.05
    mat.metallic = 0.1
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color.a = 0.7
    return mat
