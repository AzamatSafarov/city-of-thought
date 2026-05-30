extends RefCounted
class_name RoadGenerator

var rng: RandomNumberGenerator
var params: Dictionary

func _init(p_rng, p_params):
    rng = p_rng
    params = p_params

func generate(city: Node3D, heights: Dictionary):
    var gs = params.gridSize
    var bs = params.blockSize
    var road_parent = Node3D.new()
    road_parent.name = "Roads"
    city.add_child(road_parent)
    
    match params.layoutType:
        "grid":
            _build_grid_roads(gs, bs, heights, road_parent, city)
        "organic":
            _build_organic_roads(gs, bs, heights, road_parent, city)
        "radial":
            _build_radial_roads(gs, bs, heights, road_parent, city)
        "deformed":
            _build_deformed_roads(gs, bs, heights, road_parent, city)
    
    # Дополнительные переулки по connectivity
    if params.connectivity > 0.3:
        _build_extra_connections(gs, bs, heights, road_parent, city)

func _build_grid_roads(gs, bs, heights, parent, city):
    # Магистрали каждые 3-4 клетки
    var interval = 3
    for x in range(0, gs, interval):
        for z in range(gs):
            var cell = Vector2i(x, z)
            if not city.occupied_cells.has(cell):
                city.occupied_cells[cell] = "road"
                _place_road_segment(cell, bs, heights, parent, params.roadWidth * 1.2)
    for z in range(0, gs, interval):
        for x in range(gs):
            var cell = Vector2i(x, z)
            if not city.occupied_cells.has(cell):
                city.occupied_cells[cell] = "road"
                _place_road_segment(cell, bs, heights, parent, params.roadWidth * 1.2)
    
    # Обычные улицы
    for x in range(gs):
        for z in range(gs):
            var cell = Vector2i(x, z)
            if not city.occupied_cells.has(cell):
                if x % 2 == 0 or z % 2 == 0:
                    city.occupied_cells[cell] = "road"
                    _place_road_segment(cell, bs, heights, parent, params.roadWidth)

func _build_organic_roads(gs, bs, heights, parent, city):
    # L-system: начинаем от центра, идём к границам с изгибами
    var center = Vector2i(gs / 2, gs / 2)
    var num_branches = 3 + rng.randi() % 4
    for b in range(num_branches):
        var current = center
        var dir = _random_dir()
        for step in range(gs * 2):
            if not city.occupied_cells.has(current):
                city.occupied_cells[current] = "road"
                _place_road_segment(current, bs, heights, parent, params.roadWidth)
            # Случайный поворот
            if rng.randf() < 0.3:
                dir = _random_dir()
            current += dir
            if current.x < 0 or current.x >= gs or current.y < 0 or current.y >= gs:
                break

func _build_radial_roads(gs, bs, heights, parent, city):
    var center = Vector2i(gs / 2, gs / 2)
    var spokes = 6 + rng.randi() % 4
    var rings = gs / 3
    # Спицы
    for s in range(spokes):
        var angle = (TAU / spokes) * s
        for r in range(1, gs):
            var x = int(center.x + cos(angle) * r)
            var z = int(center.y + sin(angle) * r)
            if x >= 0 and x < gs and z >= 0 and z < gs:
                var cell = Vector2i(x, z)
                if not city.occupied_cells.has(cell):
                    city.occupied_cells[cell] = "road"
                    _place_road_segment(cell, bs, heights, parent, params.roadWidth * 1.2)
    # Кольца
    for ring in range(1, rings):
        var radius = ring * 3
        for a in range(360):
            var rad = deg_to_rad(a)
            var x = int(center.x + cos(rad) * radius)
            var z = int(center.y + sin(rad) * radius)
            if x >= 0 and x < gs and z >= 0 and z < gs:
                var cell = Vector2i(x, z)
                if not city.occupied_cells.has(cell):
                    city.occupied_cells[cell] = "road"
                    _place_road_segment(cell, bs, heights, parent, params.roadWidth)

func _build_deformed_roads(gs, bs, heights, parent, city):
    # Grid + distortion
    for x in range(gs):
        for z in range(gs):
            var off = _noise_distort(x, z)
            var dx = int(off.x * 2)
            var dz = int(off.y * 2)
            var cell = Vector2i(clampi(x + dx, 0, gs - 1), clampi(z + dz, 0, gs - 1))
            if x % 2 == 0 or z % 2 == 0:
                if not city.occupied_cells.has(cell):
                    city.occupied_cells[cell] = "road"
                    _place_road_segment(cell, bs, heights, parent, params.roadWidth)

func _build_extra_connections(gs, bs, heights, parent, city):
    var conns = int(params.connectivity * 10)
    for i in range(conns):
        var a = Vector2i(rng.randi() % gs, rng.randi() % gs)
        var b = Vector2i(rng.randi() % gs, rng.randi() % gs)
        # Bresenham line
        var line = _bresenham(a, b)
        for cell in line:
            if not city.occupied_cells.has(cell):
                city.occupied_cells[cell] = "road"
                _place_road_segment(cell, bs, heights, parent, params.roadWidth * 0.5)

func _place_road_segment(cell, bs, heights, parent, width):
    var pos = Vector3(cell.x * bs + bs / 2.0, 0.05, cell.y * bs + bs / 2.0)
    var h = heights.get(cell, 0.0)
    pos.y = h + 0.05
    
    var mesh = BoxMesh.new()
    mesh.size = Vector3(bs * 0.9, 0.1, bs * 0.9)
    var mi = MeshInstance3D.new()
    mi.mesh = mesh
    mi.position = pos
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#888888")
    mat.roughness = 0.9
    mi.material_override = mat
    parent.add_child(mi)

func _random_dir() -> Vector2i:
    var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
    return dirs[rng.randi() % dirs.size()]

func _noise_distort(x, z) -> Vector2:
    return Vector2(
        sin(x * 0.5 + z * 0.3) * 0.5,
        cos(x * 0.3 + z * 0.5) * 0.5
    )

func _bresenham(a: Vector2i, b: Vector2i) -> Array:
    var pts = []
    var dx = absi(b.x - a.x)
    var dz = absi(b.y - a.y)
    var sx = 1 if a.x < b.x else -1
    var sz = 1 if a.y < b.y else -1
    var err = dx - dz
    var current = a
    while true:
        pts.append(Vector2i(current.x, current.y))
        if current == b:
            break
        var e2 = err * 2
        if e2 > -dz:
            err -= dz
            current.x += sx
        if e2 < dx:
            err += dx
            current.y += sz
    return pts
