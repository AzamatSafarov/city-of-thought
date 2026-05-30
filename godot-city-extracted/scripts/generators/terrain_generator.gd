extends RefCounted
class_name TerrainGenerator

var rng: RandomNumberGenerator
var params: Dictionary

func _init(p_rng, p_params):
    rng = p_rng
    params = p_params

func generate(parent: Node3D) -> Dictionary:
    var gs = params.gridSize
    var bs = params.blockSize
    var size = gs * bs
    
    # Создаём массив высот
    var heights = {}
    var roughness = params.terrainRoughness
    var amplitude = bs * roughness * 0.6
    
    # 1. Базовый шум
    for x in range(gs):
        for z in range(gs):
            var wx = x * bs + bs / 2.0
            var wz = z * bs + bs / 2.0
            var h = _fbm(wx * 0.05, wz * 0.05, 4, 0.5) * amplitude
            heights[Vector2i(x, z)] = h
    
    # 2. Горы на границах (континентальный хребет)
    var mountain_border = true  # по умолчанию горы по краям
    if mountain_border:
        var center = Vector2(gs / 2.0, gs / 2.0)
        for x in range(gs):
            for z in range(gs):
                var dist_to_center = Vector2(x, z).distance_to(center)
                var max_dist = gs * 0.5
                var border_factor = clampf((dist_to_center / max_dist) - 0.3, 0.0, 1.0)
                # Чем ближе к краю — тем выше горы
                var mountain_height = border_factor * border_factor * bs * 1.5 * roughness
                heights[Vector2i(x, z)] += mountain_height
    
    # 3. Отдельные пики (массивы)
    var peak_count = int(roughness * 6) + 1
    for i in range(peak_count):
        var px = rng.randf() * gs
        var pz = rng.randf() * gs
        var peak_height = rng.randf() * bs * 1.2 * roughness
        var radius = rng.randf() * 3 + 2
        for x in range(max(0, int(px - radius)), min(gs, int(px + radius) + 1)):
            for z in range(max(0, int(pz - radius)), min(gs, int(pz + radius) + 1)):
                var d = Vector2(x, z).distance_to(Vector2(px, pz))
                if d < radius:
                    var factor = 1.0 - (d / radius)
                    heights[Vector2i(x, z)] += peak_height * factor * factor
    
    # 4. Эрозия: речные долины
    if params.waterPresence > 0:
        var river_count = int(params.waterPresence * 4) + 1
        for r in range(river_count):
            var start = _find_mountain_peak(gs, heights)
            var current = start
            for step in range(gs * 3):
                var lowest = _lowest_neighbor(current, gs, heights)
                if lowest == current:
                    break
                # Выкопать долину
                var cell = Vector2i(int(current.x), int(current.y))
                if heights.has(cell):
                    heights[cell] -= 1.5
                current = lowest
    
    # 5. Море по краям (continent mode)
    if params.get("continent_mode", true):
        var ocean_width = int(gs * 0.15)
        for x in range(gs):
            for z in range(gs):
                var dist_to_edge = min(min(x, gs - 1 - x), min(z, gs - 1 - z))
                if dist_to_edge < ocean_width:
                    var depth = 1.0 - (dist_to_edge / float(ocean_width))
                    heights[Vector2i(x, z)] -= depth * depth * bs * 0.8
    
    # 6. Создать меш terrain
    _build_terrain_mesh(parent, gs, bs, heights)
    
    # 7. Создать горы как 3D объекты (Mountain meshes)
    _build_mountain_meshes(parent, gs, bs, heights)
    
    return heights

func _build_terrain_mesh(parent: Node3D, gs: int, bs: float, heights: Dictionary):
    var size = gs * bs
    var mesh = PlaneMesh.new()
    mesh.size = Vector2(size, size)
    mesh.subdivide_width = gs * 2
    mesh.subdivide_depth = gs * 2
    
    var st = SurfaceTool.new()
    st.create_from(mesh, 0)
    var arr = st.commit_to_arrays()
    var verts = arr[Mesh.ARRAY_VERTEX]
    
    # Displace vertices
    for i in range(verts.size()):
        var x = verts[i].x + size / 2.0
        var z = verts[i].z + size / 2.0
        var cell_x = int(x / bs)
        var cell_z = int(z / bs)
        cell_x = clampi(cell_x, 0, gs - 1)
        cell_z = clampi(cell_z, 0, gs - 1)
        var h = heights.get(Vector2i(cell_x, cell_z), 0.0)
        verts[i].y = h
    
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(verts.size()):
        st.add_vertex(verts[i])
    st.generate_normals()
    var terrain_mesh = st.commit()
    
    var mi = MeshInstance3D.new()
    mi.name = "Terrain"
    mi.mesh = terrain_mesh
    mi.material_override = _terrain_material()
    mi.cast_shadow = true
    parent.add_child(mi)

func _build_mountain_meshes(parent: Node3D, gs: int, bs: float, heights: Dictionary):
    var mountain_parent = Node3D.new()
    mountain_parent.name = "Mountains"
    parent.add_child(mountain_parent)
    
    # Найти пики выше порога
    var threshold = bs * 0.5
    var peaks = []
    for x in range(gs):
        for z in range(gs):
            var h = heights.get(Vector2i(x, z), 0.0)
            if h > threshold:
                var is_peak = true
                var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
                for d in dirs:
                    var nh = heights.get(Vector2i(x,z) + d, -999)
                    if nh > h:
                        is_peak = false
                        break
                if is_peak:
                    peaks.append(Vector2i(x, z))
    
    # Ограничим количество пиков
    peaks.shuffle()
    for peak in peaks.slice(0, min(peaks.size(), 8)):
        var h = heights.get(peak, 0.0)
        var pos = Vector3(
            peak.x * bs + bs / 2.0,
            h - bs * 0.3,  # чуть ниже вершины
            peak.y * bs + bs / 2.0
        )
        
        var mountain = MeshInstance3D.new()
        mountain.mesh = CylinderMesh.new()
        mountain.mesh.top_radius = 0.0
        mountain.mesh.bottom_radius = bs * 0.6
        mountain.mesh.height = h * 0.8
        mountain.position = pos
        mountain.position.y += h * 0.4
        
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color("#5A5A5A")
        mat.roughness = 0.95
        mountain.material_override = mat
        mountain.cast_shadow = true
        mountain_parent.add_child(mountain)
        
        # Снежная шапка если высоко
        if h > bs * 0.8:
            var snow = MeshInstance3D.new()
            snow.mesh = CylinderMesh.new()
            snow.mesh.top_radius = 0.0
            snow.mesh.bottom_radius = bs * 0.25
            snow.mesh.height = h * 0.15
            snow.position = pos + Vector3(0, h * 0.7, 0)
            var smat = StandardMaterial3D.new()
            smat.albedo_color = Color("#E8E8E8")
            snow.material_override = smat
            mountain_parent.add_child(snow)

func _find_mountain_peak(gs: int, heights: Dictionary) -> Vector2:
    var max_h = -999
    var peak = Vector2(0, 0)
    for x in range(gs):
        for z in range(gs):
            var h = heights.get(Vector2i(x, z), 0.0)
            if h > max_h:
                max_h = h
                peak = Vector2(x, z)
    return peak

func _lowest_neighbor(pos: Vector2, gs: int, heights: Dictionary) -> Vector2:
    var dirs = [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]
    var lowest = pos
    var min_h = heights.get(Vector2i(int(pos.x), int(pos.y)), 999)
    for d in dirs:
        var n = pos + d
        var nx = int(n.x)
        var nz = int(n.y)
        if nx >= 0 and nx < gs and nz >= 0 and nz < gs:
            var nh = heights.get(Vector2i(nx, nz), 999)
            if nh < min_h:
                min_h = nh
                lowest = n
    return lowest

func _fbm(x: float, y: float, octaves: int, persistence: float) -> float:
    var total = 0.0
    var amp = 1.0
    var freq = 1.0
    var max_val = 0.0
    for i in range(octaves):
        total += _noise(x * freq, y * freq) * amp
        max_val += amp
        amp *= persistence
        freq *= 2.0
    return total / max_val

func _noise(x: float, y: float) -> float:
    return (sin(x * 12.9898 + y * 78.233) * 43758.5453) - floor(sin(x * 12.9898 + y * 78.233) * 43758.5453)

func _terrain_material() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()
    var veg = params.vegetationType
    match veg:
        "deciduous":  mat.albedo_color = Color("#7AA87A")
        "coniferous": mat.albedo_color = Color("#4A6A4A")
        "palm":       mat.albedo_color = Color("#9AC878")
        "dead":       mat.albedo_color = Color("#8B7355")
        "crystalline": mat.albedo_color = Color("#A0B0C8")
        _:            mat.albedo_color = Color("#7AA87A")
    mat.roughness = 0.95
    return mat
