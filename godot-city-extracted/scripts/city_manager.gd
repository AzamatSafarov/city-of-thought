extends Node3D
class_name CityManager

# ════════════════════════════════════════════════════════════════
# City of Thought — MONOLITHIC Godot 4.3 Generator
# Все генераторы встроены в один файл — никаких внешних зависимостей
# ════════════════════════════════════════════════════════════════

var rng := RandomNumberGenerator.new()
var params: Dictionary

var occupied_cells: Dictionary = {}
var terrain_heights: Dictionary = {}
var rivers: Array = []
var buildings: Array = []

# ==== KENNEY MODELS ====
var kenney_buildings: Array = [
    "res://assets/models/buildings/building-small-a.glb",
    "res://assets/models/buildings/building-small-b.glb",
    "res://assets/models/buildings/building-small-c.glb",
    "res://assets/models/buildings/building-small-d.glb",
    "res://assets/models/buildings/building-garage.glb"
]

# ==== POLYHAVEN NATURE MODELS (CC0) ====
var polyhaven_trees: Array = [
    "res://assets/models/polyhaven/island_tree_01/island_tree_01_1k.gltf",
    "res://assets/models/polyhaven/island_tree_02/island_tree_02_1k.gltf",
    "res://assets/models/polyhaven/island_tree_03/island_tree_03_1k.gltf"
]
var polyhaven_rocks: Array = [
    "res://assets/models/polyhaven/boulder_01/boulder_01_1k.gltf",
    "res://assets/models/polyhaven/rock_moss_set_01/rock_moss_set_01_1k.gltf",
    "res://assets/models/polyhaven/rock_moss_set_02/rock_moss_set_02_1k.gltf"
]
var polyhaven_props: Array = [
    "res://assets/models/polyhaven/dead_tree_trunk/dead_tree_trunk_1k.gltf",
    "res://assets/models/polyhaven/fern_02/fern_02_1k.gltf",
    "res://assets/models/polyhaven/tree_stump_01/tree_stump_01_1k.gltf"
]

# ==== POLYHAVEN INFRASTRUCTURE (CC0) ====
var polyhaven_lights: Array = [
    "res://assets/models/polyhaven/street_lamp_01/street_lamp_01_1k.gltf",
    "res://assets/models/polyhaven/street_lamp_02/street_lamp_02_1k.gltf",
    "res://assets/models/polyhaven/wooden_lantern_01/wooden_lantern_01_1k.gltf",
    "res://assets/models/polyhaven/brass_diya_lantern/brass_diya_lantern_1k.gltf"
]
var polyhaven_street_deco: Array = [
    "res://assets/models/polyhaven/horse_statue_01/horse_statue_01_1k.gltf",
    "res://assets/models/polyhaven/concrete_cat_statue/concrete_cat_statue_1k.gltf",
    "res://assets/models/polyhaven/wooden_barrels_01/wooden_barrels_01_1k.gltf",
    "res://assets/models/polyhaven/wooden_crate_02/wooden_crate_02_1k.gltf",
    "res://assets/models/polyhaven/treasure_chest/treasure_chest_1k.gltf",
    "res://assets/models/polyhaven/vintage_grandfather_clock_01/vintage_grandfather_clock_01_1k.gltf"
]
var polyhaven_street_furniture: Array = [
    "res://assets/models/polyhaven/wooden_picnic_table/wooden_picnic_table_1k.gltf",
    "res://assets/models/polyhaven/outdoor_table_chair_set_01/outdoor_table_chair_set_01_1k.gltf"
]
var polyhaven_fences: Array = [
    "res://assets/models/polyhaven/modular_chainlink_fence/modular_chainlink_fence_1k.gltf"
]

# ==== ENTRY POINT ====
func _ready():
    rng.randomize()
    params = _default_params()
    _apply_book_params()
    _build_city()
    _setup_camera()
    set_process_input(true)
    add_to_group("city_manager")

# ==== DEFAULT PARAMS ====
func _default_params() -> Dictionary:
    return {
        "gridSize": 14,
        "blockSize": 20.0,
        "roadWidth": 3.0,
        "layoutType": "grid",
        "connectivity": 0.7,
        "terrainRoughness": 0.15,
        "waterPresence": 0.3,
        "buildingDensity": 0.7,
        "parkRatio": 0.12,
        "blockSubdivisions": 2,
        "buildingHeightRange": {"min": 8, "max": 40},
        "skyscraperRatio": 0.2,
        "style": "classical",
        "material": "stone",
        "vegetationType": "deciduous",
        "treeDensity": 0.25,
        "timeOfDay": "dusk",
        "fogDensity": 0.3,
        "windSpeed": 0.6,
        "particleType": "dust",
        "particleCount": 80,
        "genre": "treatise",
        "author": "Unknown",
        "title": "City of Thought",
        "year": 1900
    }

# ==== LOAD FROM JSON ====
func load_from_json(json_path: String):
    var file = FileAccess.open(json_path, FileAccess.READ)
    if file:
        var json = JSON.new()
        var err = json.parse(file.get_as_text())
        if err == OK:
            var data = json.data
            if data.has("topology"):
                params.gridSize = data.topology.get("gridSize", 14)
                params.blockSize = data.topology.get("blockSize", 20)
                params.roadWidth = data.topology.get("roadWidth", 3)
                params.layoutType = data.topology.get("layoutType", "grid")
                params.connectivity = data.topology.get("connectivity", 0.7)
            if data.has("architecture"):
                params.style = data.architecture.get("style", "classical")
                params.material = data.architecture.get("material", "stone")
                params.skyscraperRatio = data.architecture.get("skyscraperRatio", 0.2)
                params.buildingDensity = data.architecture.get("buildingDensity", 0.7)
                params.blockSubdivisions = data.architecture.get("blockSubdivisions", 2)
            if data.has("life"):
                params.timeOfDay = data.life.get("timeOfDay", "dusk")
                params.fogDensity = data.life.get("fogDensity", 0.3)
                params.windSpeed = data.life.get("windSpeed", 0.6)
                params.particleType = data.life.get("particleType", "dust")
                params.particleCount = data.life.get("particleCount", 80)
            if data.has("nature"):
                params.terrainRoughness = data.nature.get("terrainRoughness", 0.15)
                params.waterPresence = data.nature.get("waterPresence", 0.3)
                params.treeDensity = data.nature.get("treeDensity", 0.25)
                params.vegetationType = data.nature.get("vegetationType", "deciduous")
                params.parkRatio = data.nature.get("parkRatio", 0.12)
            if data.has("meta"):
                params.genre = data.meta.get("genre", "treatise")
                params.author = data.meta.get("author", "Unknown")
                params.title = data.meta.get("title", "City of Thought")
                params.year = data.meta.get("year", 1900)
        file.close()
    _clear_city()
    _build_city()

func _clear_city():
    for child in get_children():
        if child.name != "Camera3D":
            child.queue_free()
    occupied_cells.clear()
    terrain_heights.clear()
    rivers.clear()
    buildings.clear()

# ==== BOOK MAPPING ====
func _apply_book_params():
    match params.genre:
        "essay":
            params.gridSize = 8; params.buildingDensity = 0.45
            params.parkRatio = 0.25; params.layoutType = "organic"
        "treatise":
            params.gridSize = 14; params.buildingDensity = 0.75
            params.parkRatio = 0.10; params.layoutType = "grid"
        "dialogue":
            params.gridSize = 10; params.buildingDensity = 0.55
            params.parkRatio = 0.20; params.layoutType = "radial"
        "poetry":
            params.gridSize = 6; params.buildingDensity = 0.25
            params.parkRatio = 0.40; params.layoutType = "organic"
        "manifesto":
            params.gridSize = 12; params.buildingDensity = 0.85
            params.parkRatio = 0.05; params.layoutType = "grid"
            params.style = "constructivist"
        "autobiography":
            params.gridSize = 16; params.buildingDensity = 0.65
            params.parkRatio = 0.15; params.layoutType = "deformed"
        "critique":
            params.gridSize = 12; params.buildingDensity = 0.70
            params.parkRatio = 0.10; params.layoutType = "deformed"
    if params.year < 500:
        params.timeOfDay = "day"; params.style = "classical"
    elif params.year < 1500:
        params.timeOfDay = "golden_hour"; params.style = "neo_gothic"
    elif params.year < 1800:
        params.timeOfDay = "dusk"; params.style = "classical"
    elif params.year < 1900:
        params.timeOfDay = "night"; params.style = "neo_gothic"
    elif params.year < 1950:
        params.timeOfDay = "midnight"; params.style = "constructivist"
    match params.style:
        "classical":  params.material = "stone"; params.dominantHue = 215
        "baroque":    params.material = "marble"; params.dominantHue = 30
        "brutalist":  params.material = "concrete"; params.dominantHue = 200
        "minimal":    params.material = "glass"; params.dominantHue = 200
        "organic":    params.material = "wood"; params.dominantHue = 100
        "deconstructivist": params.material = "metal"; params.dominantHue = 280
        "neo_gothic": params.material = "stone"; params.dominantHue = 280
        "constructivist": params.material = "concrete"; params.dominantHue = 10

# ==== MAIN BUILD SEQUENCE ====
func _build_city():
    print("[CityManager] Building: ", params.title)
    print("[CityManager] Style: ", params.style, " | Layout: ", params.layoutType)

    _gen_terrain()
    _gen_water()
    _mark_water_cells()
    _gen_roads()
    _mark_road_cells()
    _gen_zones()
    _gen_buildings()
    _gen_vegetation()
    _gen_infrastructure()
    _gen_life()
    _gen_atmosphere()

    print("[CityManager] Done: ", buildings.size(), " buildings, ", rivers.size(), " rivers")

# ==== TERRAIN (Layer 0) ====
func _gen_terrain():
    var parent = Node3D.new()
    parent.name = "Terrain"
    add_child(parent)

    var gs = params.gridSize
    var bs = params.blockSize
    var size = gs * bs

    # Perlin-like noise heightmap
    for x in range(gs):
        for z in range(gs):
            var wx = x * bs + bs / 2.0
            var wz = z * bs + bs / 2.0
            var h = _fbm(wx * 0.05, wz * 0.05, 4, 0.5) * bs * params.terrainRoughness * 0.6
            # Mountains on edges (continental ridge)
            var center = Vector2(gs / 2.0, gs / 2.0)
            var dist = Vector2(x, z).distance_to(center)
            var max_dist = gs * 0.5
            var border = clampf((dist / max_dist) - 0.3, 0.0, 1.0)
            h += border * border * bs * 1.5 * params.terrainRoughness
            # Ocean on edges
            var edge_dist = min(min(x, gs - 1 - x), min(z, gs - 1 - z))
            var ocean_width = int(gs * 0.15)
            if edge_dist < ocean_width:
                var depth = 1.0 - (edge_dist / float(ocean_width))
                h -= depth * depth * bs * 0.8
            terrain_heights[Vector2i(x, z)] = h

    # Build displaced plane mesh
    var plane = PlaneMesh.new()
    plane.size = Vector2(size, size)
    plane.subdivide_width = gs * 2
    plane.subdivide_depth = gs * 2
    var st = SurfaceTool.new()
    st.create_from(plane, 0)
    var arr = st.commit_to_arrays()
    var verts = arr[Mesh.ARRAY_VERTEX]
    for i in range(verts.size()):
        var vx = verts[i].x + size / 2.0
        var vz = verts[i].z + size / 2.0
        var cx = clampi(int(vx / bs), 0, gs - 1)
        var cz = clampi(int(vz / bs), 0, gs - 1)
        verts[i].y = terrain_heights.get(Vector2i(cx, cz), 0.0)
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(verts.size()):
        st.add_vertex(verts[i])
    st.generate_normals()
    var terrain_mesh = st.commit()
    var mi = MeshInstance3D.new()
    mi.mesh = terrain_mesh
    mi.material_override = _terrain_material()
    mi.cast_shadow = true
    parent.add_child(mi)

    # Mountain peaks as 3D cones
    var mparent = Node3D.new()
    mparent.name = "Mountains"
    parent.add_child(mparent)
    var threshold = bs * 0.5
    var peaks = []
    for x in range(gs):
        for z in range(gs):
            var h = terrain_heights.get(Vector2i(x, z), 0.0)
            if h > threshold:
                var is_peak = true
                var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
                for d in dirs:
                    var nh = terrain_heights.get(Vector2i(x,z) + d, -999)
                    if nh > h:
                        is_peak = false
                        break
                if is_peak:
                    peaks.append(Vector2i(x, z))
    peaks.shuffle()
    for peak in peaks.slice(0, min(peaks.size(), 8)):
        var h = terrain_heights.get(peak, 0.0)
        var pos = Vector3(peak.x * bs + bs/2, h - bs*0.3, peak.y * bs + bs/2)
        var mountain = MeshInstance3D.new()
        mountain.mesh = CylinderMesh.new()
        mountain.mesh.top_radius = 0.0
        mountain.mesh.bottom_radius = bs * 0.6
        mountain.mesh.height = h * 0.8
        mountain.position = pos + Vector3(0, h*0.4, 0)
        mountain.material_override = _mountain_material()
        mountain.cast_shadow = true
        mparent.add_child(mountain)
        # Snow cap
        if h > bs * 0.8:
            var snow = MeshInstance3D.new()
            snow.mesh = CylinderMesh.new()
            snow.mesh.top_radius = 0.0
            snow.mesh.bottom_radius = bs * 0.25
            snow.mesh.height = h * 0.15
            snow.position = pos + Vector3(0, h*0.7, 0)
            snow.material_override = _snow_material()
            mparent.add_child(snow)

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
    var n = sin(x * 12.9898 + y * 78.233) * 43758.5453
    return n - floor(n)

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

func _mountain_material() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#5A5A5A")
    mat.roughness = 0.95
    return mat

func _snow_material() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#E8E8E8")
    return mat


# ==== WATER (Layer 1) ====
func _gen_water():
    var wp = params.waterPresence
    if wp <= 0.001:
        return
    var gs = params.gridSize
    var bs = params.blockSize
    var parent = Node3D.new()
    parent.name = "Water"
    add_child(parent)
    var river_count = int(wp * 5) + 1
    for r in range(river_count):
        var start = _find_mountain_peak(gs)
        var river = [start]
        var current = start
        for step in range(gs * 3):
            var lowest = _lowest_neighbor(current, gs)
            if lowest == current:
                break
            river.append(lowest)
            current = lowest
        rivers.append(river)
        _build_river_mesh(river, parent)
    # Lakes
    var lake_count = int(wp * 3)
    for i in range(lake_count):
        var lake = _find_local_minimum(gs)
        _build_lake_mesh(lake, parent)
    # Fountain for radial
    if params.layoutType == "radial":
        _build_fountain_mesh(Vector3(gs*bs/2, 0, gs*bs/2), parent)

func _find_mountain_peak(gs: int) -> Vector2i:
    var max_h = -999
    var peak = Vector2i(0, 0)
    for x in range(gs):
        for z in range(gs):
            var h = terrain_heights.get(Vector2i(x, z), 0.0)
            if h > max_h:
                max_h = h
                peak = Vector2i(x, z)
    return peak

func _lowest_neighbor(cell: Vector2i, gs: int) -> Vector2i:
    var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
    var lowest = cell
    var min_h = terrain_heights.get(cell, 999)
    for d in dirs:
        var n = cell + d
        if n.x >= 0 and n.x < gs and n.y >= 0 and n.y < gs:
            var nh = terrain_heights.get(n, 999)
            if nh < min_h:
                min_h = nh
                lowest = n
    return lowest

func _find_local_minimum(gs: int) -> Vector2i:
    var candidates = []
    for x in range(gs):
        for z in range(gs):
            candidates.append(Vector2i(x, z))
    candidates.shuffle()
    for i in range(min(10, candidates.size())):
        var cell = candidates[i]
        var h = terrain_heights.get(cell, 999)
        var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
        var is_min = true
        for d in dirs:
            if terrain_heights.get(cell + d, 999) < h:
                is_min = false
                break
        if is_min:
            return cell
    return Vector2i(0, 0)

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
    var mi = MeshInstance3D.new()
    mi.mesh = CylinderMesh.new()
    mi.mesh.top_radius = bs * 0.8
    mi.mesh.bottom_radius = bs * 0.8
    mi.mesh.height = 0.2
    mi.position = Vector3(cell.x * bs + bs/2, -0.15, cell.y * bs + bs/2)
    mi.material_override = _water_mat()
    parent.add_child(mi)

func _build_fountain_mesh(pos: Vector3, parent: Node3D):
    var mi = MeshInstance3D.new()
    mi.mesh = CylinderMesh.new()
    mi.mesh.top_radius = 2.0
    mi.mesh.bottom_radius = 2.0
    mi.mesh.height = 1.0
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

func _mark_water_cells():
    for river in rivers:
        for cell in river:
            occupied_cells[cell] = "water"

# ==== ROADS (Layer 2) ====
func _gen_roads():
    var gs = params.gridSize
    var bs = params.blockSize
    var rw = params.roadWidth
    var parent = Node3D.new()
    parent.name = "Roads"
    add_child(parent)
    match params.layoutType:
        "grid":
            for x in range(gs):
                for z in range(gs):
                    if x % 3 == 0 or z % 3 == 0:
                        occupied_cells[Vector2i(x, z)] = "road_temp"
                        _place_road_cell(Vector2i(x, z), bs, rw, parent)
        "organic":
            for i in range(int(gs * gs * 0.15)):
                var x = rng.randi() % gs
                var z = rng.randi() % gs
                occupied_cells[Vector2i(x, z)] = "road_temp"
                _place_road_cell(Vector2i(x, z), bs, rw, parent)
        "radial":
            var center = Vector2i(gs / 2, gs / 2)
            for dist in range(1, gs / 2, 2):
                var ring_cells = _get_ring_cells(center, dist, gs)
                for cell in ring_cells:
                    occupied_cells[cell] = "road_temp"
                    _place_road_cell(cell, bs, rw, parent)
            # Spokes
            var spokes = 6
            for s in range(spokes):
                var angle = (TAU / spokes) * s
                for dist in range(1, gs / 2):
                    var x = int(center.x + cos(angle) * dist)
                    var z = int(center.y + sin(angle) * dist)
                    if x >= 0 and x < gs and z >= 0 and z < gs:
                        occupied_cells[Vector2i(x, z)] = "road_temp"
                        _place_road_cell(Vector2i(x, z), bs, rw, parent)
        "deformed":
            for i in range(int(gs * gs * 0.2)):
                var x = rng.randi() % gs
                var z = rng.randi() % gs
                if rng.randf() < 0.7:
                    occupied_cells[Vector2i(x, z)] = "road_temp"
                    _place_road_cell(Vector2i(x, z), bs, rw, parent)

func _place_road_cell(cell: Vector2i, bs: float, rw: float, parent: Node3D):
    var mi = MeshInstance3D.new()
    mi.mesh = BoxMesh.new()
    mi.mesh.size = Vector3(bs * 0.9, 0.15, bs * 0.9)
    mi.position = Vector3(cell.x * bs + bs/2, 0.1, cell.y * bs + bs/2)
    mi.material_override = _road_mat()
    parent.add_child(mi)

func _road_mat() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#4A5058")
    mat.roughness = 0.85
    return mat

func _get_ring_cells(center: Vector2i, radius: int, gs: int) -> Array:
    var cells = []
    var circumference = int(2 * PI * radius)
    for i in range(circumference):
        var angle = (TAU / circumference) * i
        var x = int(center.x + cos(angle) * radius)
        var z = int(center.y + sin(angle) * radius)
        if x >= 0 and x < gs and z >= 0 and z < gs:
            cells.append(Vector2i(x, z))
    return cells

func _mark_road_cells():
    for cell in occupied_cells.keys():
        if occupied_cells[cell] == "road_temp":
            occupied_cells[cell] = "road"

# ==== ZONES (Layer 3) ====
func _gen_zones():
    var gs = params.gridSize
    var park_cells = int(gs * gs * params.parkRatio)
    var placed = 0
    for i in range(1000):
        if placed >= park_cells:
            break
        var x = rng.randi() % gs
        var z = rng.randi() % gs
        var cell = Vector2i(x, z)
        if not occupied_cells.has(cell):
            occupied_cells[cell] = "park"
            placed += 1

# ==== BUILDINGS (Layer 4) ====
func _gen_buildings():
    var parent = Node3D.new()
    parent.name = "Buildings"
    add_child(parent)

    var gs = params.gridSize
    var bs = params.blockSize
    var bd = params.buildingDensity
    var total_cells = gs * gs
    var building_cells = int(total_cells * bd)
    var placed = 0

    # Сначала заполняем незанятые клетки
    var available = []
    for x in range(gs):
        for z in range(gs):
            var cell = Vector2i(x, z)
            if not occupied_cells.has(cell):
                available.append(cell)
    available.shuffle()

    for cell in available:
        if placed >= building_cells:
            break
        occupied_cells[cell] = "building"
        placed += 1

    # Определяем монументы
    var building_list = []
    for x in range(gs):
        for z in range(gs):
            var cell = Vector2i(x, z)
            if occupied_cells.get(cell, "") == "building":
                building_list.append(cell)
    building_list.shuffle()

    var monument_count = max(1, int(building_list.size() * 0.08))
    var monuments = []
    var regular = []
    for i in range(building_list.size()):
        if i < monument_count:
            monuments.append(building_list[i])
        else:
            regular.append(building_list[i])

    # Строим монументы
    for cell in monuments:
        var b = _create_building(cell, true)
        parent.add_child(b)
        buildings.append(b)

    # Обычные здания
    for cell in regular:
        var b = _create_building(cell, false)
        parent.add_child(b)
        buildings.append(b)

func _create_building(cell: Vector2i, is_monument: bool) -> Node3D:
    var bs = params.blockSize
    var h_range = params.buildingHeightRange
    var h_min = h_range.min
    var h_max = h_range.max
    if is_monument:
        h_min *= 1.5
        h_max *= 1.6
    var h = h_min + rng.randf() * (h_max - h_min)
    var w = 10 + rng.randf() * 8
    var d = 8 + rng.randf() * 6

    var root = Node3D.new()
    var pos = Vector3(cell.x * bs + bs/2, 0, cell.y * bs + bs/2)
    root.position = pos

    # Основной корпус
    var body = MeshInstance3D.new()
    body.mesh = BoxMesh.new()
    body.mesh.size = Vector3(w, h, d)
    body.position.y = h / 2.0
    body.material_override = _building_material()
    body.cast_shadow = true
    root.add_child(body)

    # Крыша по стилю
    _add_roof(root, h, w, d)

    # Детали стиля
    _add_style_details(root, h, w, d, is_monument)

    # Окна
    _add_windows(root, h, w, d, pos)

    return root

func _add_roof(parent: Node3D, h: float, w: float, d: float):
    var roof: MeshInstance3D
    match params.style:
        "classical", "neo_gothic":
            roof = MeshInstance3D.new()
            roof.mesh = PrismMesh.new()
            roof.mesh.size = Vector3(w + 2, h * 0.15, d + 2)
            roof.position.y = h + h * 0.075
        "baroque", "organic":
            roof = MeshInstance3D.new()
            roof.mesh = SphereMesh.new()
            roof.mesh.radius = max(w, d) * 0.4
            roof.position.y = h + max(w, d) * 0.2
        "brutalist", "constructivist", "minimal":
            roof = MeshInstance3D.new()
            roof.mesh = BoxMesh.new()
            roof.mesh.size = Vector3(w + 1, 1.5, d + 1)
            roof.position.y = h + 0.75
        _:
            roof = MeshInstance3D.new()
            roof.mesh = BoxMesh.new()
            roof.mesh.size = Vector3(w + 1, 1.5, d + 1)
            roof.position.y = h + 0.75
    if roof:
        roof.material_override = _accent_material()
        parent.add_child(roof)

func _add_style_details(parent: Node3D, h: float, w: float, d: float, is_monument: bool):
    match params.style:
        "classical":
            if is_monument:
                var ox_list = [-w * 0.6, w * 0.6]
                for ox in ox_list:
                    var col = MeshInstance3D.new()
                    col.mesh = CylinderMesh.new()
                    col.mesh.top_radius = w * 0.06
                    col.mesh.bottom_radius = w * 0.08
                    col.mesh.height = h * 0.4
                    col.position = Vector3(ox, h * 0.2, w * 0.4)
                    col.material_override = _building_material()
                    parent.add_child(col)
        "baroque":
            var volute = MeshInstance3D.new()
            volute.mesh = TorusMesh.new()
            volute.mesh.inner_radius = w * 0.1
            volute.mesh.outer_radius = w * 0.15
            volute.position = Vector3(w * 0.5, h * 0.3, d * 0.4)
            volute.material_override = _accent_material()
            parent.add_child(volute)
        "neo_gothic":
            var side_list = [-1, 1]
            for side in side_list:
                var spur = MeshInstance3D.new()
                spur.mesh = BoxMesh.new()
                spur.mesh.size = Vector3(w * 0.15, h * 0.6, w * 0.2)
                spur.position = Vector3(side * w * 0.55, h * 0.3, 0)
                spur.material_override = _building_material()
                parent.add_child(spur)
            # Шпиль
            var spire = MeshInstance3D.new()
            spire.mesh = CylinderMesh.new()
            spire.mesh.top_radius = 0.0
            spire.mesh.bottom_radius = w * 0.15
            spire.mesh.height = h * 0.4
            spire.position.y = h + h * 0.2
            spire.material_override = _accent_material()
            parent.add_child(spire)
        "constructivist":
            var ant = MeshInstance3D.new()
            ant.mesh = CylinderMesh.new()
            ant.mesh.top_radius = 0.05
            ant.mesh.bottom_radius = 0.2
            ant.mesh.height = h * 0.3
            ant.position.y = h + h * 0.15
            ant.material_override = _accent_material()
            parent.add_child(ant)
        "organic":
            var vine = MeshInstance3D.new()
            vine.mesh = TorusMesh.new()
            vine.mesh.inner_radius = w * 0.2
            vine.mesh.outer_radius = w * 0.25
            vine.position = Vector3(w * 0.4, h * 0.2, 0)
            vine.rotation_degrees = Vector3(45, 0, 0)
            vine.material_override = _vegetation_material()
            parent.add_child(vine)

func _add_windows(parent: Node3D, h: float, w: float, d: float, pos: Vector3):
    var rows = max(1, int(h / 12))
    var lit = 2 + rng.randi() % 4
    for r in range(rows):
        if r >= lit:
            continue
        var wy = h * 0.3 + r * 12
        # Front
        var win = MeshInstance3D.new()
        win.mesh = PlaneMesh.new()
        win.mesh.size = Vector2(w * 0.5, 2)
        win.position = Vector3(0, wy, d / 2 + 0.1)
        win.material_override = _window_material()
        parent.add_child(win)

func _building_material() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()
    match params.material:
        "stone":    mat.albedo_color = Color("#8A8A8A")
        "concrete": mat.albedo_color = Color("#7A7A7A")
        "marble":   mat.albedo_color = Color("#F0E8E0")
        "glass":    mat.albedo_color = Color("#C0D0E0")
        "metal":    mat.albedo_color = Color("#6A6A7A")
        "wood":     mat.albedo_color = Color("#8A6A4A")
        "brick":    mat.albedo_color = Color("#A06050")
        "ice":      mat.albedo_color = Color("#E0F0F8")
        _:          mat.albedo_color = Color("#8A8A8A")
    mat.roughness = 0.8
    return mat

func _accent_material() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()
    mat.albedo_color = _building_material().albedo_color.lightened(0.15)
    mat.roughness = 0.6
    return mat

func _window_material() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#FFD57A")
    mat.emission_enabled = true
    mat.emission = Color("#FFD57A")
    mat.emission_energy_multiplier = 0.5
    return mat

func _vegetation_material() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#6A8A5A")
    mat.roughness = 0.9
    return mat

# ==== VEGETATION (Layer 5) ====
func _gen_vegetation():
    var parent = Node3D.new()
    parent.name = "Vegetation"
    add_child(parent)
    var gs = params.gridSize
    var bs = params.blockSize
    var td = params.treeDensity
    var tree_count = int(gs * gs * td * 3)
    for i in range(tree_count):
        var x = rng.randi() % gs
        var z = rng.randi() % gs
        var cell = Vector2i(x, z)
        var occ = occupied_cells.get(cell, "")
        if occ == "park" or occ == "" or occ == "building":
            var world_pos = Vector3(x * bs + bs/2 + rng.randf()*4-2, 0, z * bs + bs/2 + rng.randf()*4-2)
            # Определяем тип и создаём
            var tree_type = _pick_tree_type(occ)
            var tree = _create_tree_by_type(tree_type, world_pos)
            if tree:
                tree.position = world_pos
                parent.add_child(tree)
                # LOD регистрация
                # LOD регистрация
                var lod = get_parent().get_node_or_null("LODManager")
                if lod and lod.has_method("register_tree"):
                        lod.register_tree(tree)
    # Добавляем декорации — камни, пни, папоротники
    _scatter_decorations(parent, gs, bs)

func _pick_tree_type(occ: String) -> String:
    var roll = rng.randf()
    if polyhaven_trees.size() > 0 and roll < 0.5:
        return "polyhaven"
    if occ == "park":
        return params.vegetationType  # процедурный
    return "polyhaven" if rng.randf() < 0.3 else params.vegetationType

func _create_tree_by_type(ttype: String, pos: Vector3) -> Node3D:
    if ttype == "polyhaven":
        return _load_polyhaven_tree()
    else:
        return _create_tree_procedural(ttype)

func _load_polyhaven_tree() -> Node3D:
    # Выбираем случайное дерево из PolyHaven
    var idx = rng.randi() % polyhaven_trees.size()
    var path = polyhaven_trees[idx]
    var inst = _load_gltf(path)
    if inst:
        # Масштабируем для вписания в карту
        var scale = 0.8 + rng.randf() * 0.5
        inst.scale = Vector3(scale, scale, scale)
    return inst

func _create_tree_procedural(treetype: String) -> Node3D:
    var root = Node3D.new()
    var trunk = MeshInstance3D.new()
    trunk.mesh = CylinderMesh.new()
    trunk.mesh.top_radius = 0.3
    trunk.mesh.bottom_radius = 0.5
    trunk.mesh.height = 6 + rng.randf() * 4
    trunk.position.y = trunk.mesh.height / 2
    trunk.material_override = _trunk_material()
    root.add_child(trunk)

    var crown = MeshInstance3D.new()
    match treetype:
        "coniferous":
            crown.mesh = CylinderMesh.new()
            crown.mesh.top_radius = 0.0
            crown.mesh.bottom_radius = 3 + rng.randf() * 2
            crown.mesh.height = 6 + rng.randf() * 3
        "palm":
            crown.mesh = SphereMesh.new()
            crown.mesh.radius = 2 + rng.randf()
        "dead":
            crown.mesh = CylinderMesh.new()
            crown.mesh.top_radius = 0.0
            crown.mesh.bottom_radius = 1.5
            crown.mesh.height = 4
        "crystalline":
            crown.mesh = PrismMesh.new()
            crown.mesh.size = Vector3(3, 5, 3)
        _:
            crown.mesh = SphereMesh.new()
            crown.mesh.radius = 3 + rng.randf() * 2
    crown.position.y = trunk.mesh.height + crown.mesh.height / 2
    crown.material_override = _crown_material()
    root.add_child(crown)
    return root

func _load_gltf(path: String) -> Node3D:
    # GLTF (text) с внешними ресурсами: через GLTFDocument
    if path.ends_with(".gltf"):
        var doc = GLTFDocument.new()
        var state = GLTFState.new()
        var err = doc.append_from_file(path, state)
        if err == OK:
            var scene = doc.generate_scene(state)
            if scene:
                return scene
        return null
    # GLB (binary single-file): direct load
    var scene = load(path)
    if scene:
        var inst = scene.instantiate()
        if inst:
            return inst
    return null

func _scatter_decorations(parent: Node3D, gs: int, bs: float):
    """Разбрасываем камни, пни, папоротники, статуи, бочки, ящики, мебель по карте"""
    var deco_count = int(gs * gs * 0.6)
    for i in range(deco_count):
        var x = rng.randi() % gs
        var z = rng.randi() % gs
        var cell = Vector2i(x, z)
        var occ = occupied_cells.get(cell, "")
        if occ == "park" or occ == "" or occ == "building" or occ == "road":
            var world_pos = Vector3(x * bs + bs/2 + rng.randf()*4-2, 0, z * bs + bs/2 + rng.randf()*4-2)
            _place_random_deco(parent, world_pos, occ == "park")

func _place_random_deco(parent: Node3D, pos: Vector3, is_park: bool = false):
    var roll = rng.randf()
    var deco: Node3D = null
    
    if roll < 0.12 and polyhaven_rocks.size() > 0:
        # Камень
        deco = _load_gltf(polyhaven_rocks[rng.randi() % polyhaven_rocks.size()])
        if deco:
            var s = 0.6 + rng.randf() * 0.8
            deco.scale = Vector3(s, s, s)
    elif roll < 0.22 and polyhaven_props.size() > 0:
        # Пень или папоротник
        deco = _load_gltf(polyhaven_props[rng.randi() % polyhaven_props.size()])
        if deco:
            var s = 0.8 + rng.randf() * 0.5
            deco.scale = Vector3(s, s, s)
    elif roll < 0.30 and polyhaven_street_deco.size() > 0:
        # Статуя, бочки, ящик, сундук
        deco = _load_gltf(polyhaven_street_deco[rng.randi() % polyhaven_street_deco.size()])
        if deco:
            var s = 0.5 + rng.randf() * 0.5
            deco.scale = Vector3(s, s, s)
    elif is_park and roll < 0.38 and polyhaven_street_furniture.size() > 0:
        # Столы и стулья только в парках
        deco = _load_gltf(polyhaven_street_furniture[rng.randi() % polyhaven_street_furniture.size()])
        if deco:
            var s = 0.7 + rng.randf() * 0.4
            deco.scale = Vector3(s, s, s)
    
    if deco:
        deco.position = pos
        # Небольшой случайный поворот
        deco.rotation.y = rng.randf() * TAU
        parent.add_child(deco)
        var lod = get_parent().get_node_or_null("LODManager")
        if lod and lod.has_method("register_prop"):
            lod.register_prop(deco)

func _trunk_material() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#6A4A3A")
    mat.roughness = 0.9
    return mat

func _crown_material() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()
    match params.vegetationType:
        "deciduous":  mat.albedo_color = Color("#6A8A5A")
        "coniferous": mat.albedo_color = Color("#2A5A3A")
        "palm":       mat.albedo_color = Color("#8AB84A")
        "dead":       mat.albedo_color = Color("#5A4A3A")
        "crystalline": mat.albedo_color = Color("#A0C0E0")
        _:            mat.albedo_color = Color("#6A8A5A")
    mat.roughness = 0.8
    return mat

# ==== INFRASTRUCTURE (Layer 6) ====
func _gen_infrastructure():
    var parent = Node3D.new()
    parent.name = "Infrastructure"
    add_child(parent)
    var gs = params.gridSize
    var bs = params.blockSize
    for x in range(gs):
        for z in range(gs):
            var cell = Vector2i(x, z)
            if occupied_cells.get(cell, "") == "road":
                if rng.randf() < 0.3:
                    _place_streetlamp(cell, bs, parent)
                if rng.randf() < 0.1:
                    _place_bench(cell, bs, parent)
    # Размещение заборов по границам парков
    _place_park_fences(parent, gs, bs)
    # Clock tower for radial
    if params.layoutType == "radial":
        var tower = MeshInstance3D.new()
        tower.mesh = BoxMesh.new()
        tower.mesh.size = Vector3(8, 30, 8)
        tower.position = Vector3(gs*bs/2, 15, gs*bs/2)
        tower.material_override = _building_material()
        parent.add_child(tower)
        # Spire
        var spire = MeshInstance3D.new()
        spire.mesh = CylinderMesh.new()
        spire.mesh.top_radius = 0.0
        spire.mesh.bottom_radius = 4.0
        spire.mesh.height = 10
        spire.position = Vector3(gs*bs/2, 35, gs*bs/2)
        spire.material_override = _accent_material()
        parent.add_child(spire)

func _place_streetlamp(cell: Vector2i, bs: float, parent: Node3D):
    if polyhaven_lights.size() > 0 and rng.randf() < 0.7:
        # Используем PolyHaven модель фонаря
        var lamp = _load_gltf(polyhaven_lights[rng.randi() % polyhaven_lights.size()])
        if lamp:
            lamp.position = Vector3(cell.x*bs+bs/2 + rng.randf()*2-1, 0, cell.y*bs+bs/2 + rng.randf()*2-1)
            # Вращение стоящего объекта
            lamp.rotation.y = rng.randf() * TAU
            parent.add_child(lamp)
            var lod = get_parent().get_node_or_null("LODManager")
            if lod and lod.has_method("register_prop"):
                lod.register_prop(lamp)
            return
    # Процедурный fallback
    var pole = MeshInstance3D.new()
    pole.mesh = CylinderMesh.new()
    pole.mesh.top_radius = 0.15
    pole.mesh.bottom_radius = 0.2
    pole.mesh.height = 8
    pole.position = Vector3(cell.x*bs+bs/2, 4, cell.y*bs+bs/2)
    pole.material_override = _metal_material()
    parent.add_child(pole)
    var light = OmniLight3D.new()
    light.position = Vector3(cell.x*bs+bs/2, 8, cell.y*bs+bs/2)
    light.light_color = Color("#FFD0A0")
    light.light_energy = 2.0
    light.omni_range = 20.0
    parent.add_child(light)

func _place_bench(cell: Vector2i, bs: float, parent: Node3D):
    if polyhaven_street_furniture.size() > 0 and rng.randf() < 0.5:
        var bench = _load_gltf(polyhaven_street_furniture[rng.randi() % polyhaven_street_furniture.size()])
        if bench:
            bench.position = Vector3(cell.x*bs+bs/2 + rng.randf()*2-1, 0, cell.y*bs+bs/2 + rng.randf()*4-2)
            bench.rotation.y = rng.randf() * PI
            var s = 0.5 + rng.randf() * 0.3
            bench.scale = Vector3(s, s, s)
            parent.add_child(bench)
            var lod = get_parent().get_node_or_null("LODManager")
            if lod and lod.has_method("register_prop"):
                lod.register_prop(bench)
            return
    # Процедурный fallback
    var bench = MeshInstance3D.new()
    bench.mesh = BoxMesh.new()
    bench.mesh.size = Vector3(4, 1, 1.5)
    bench.position = Vector3(cell.x*bs+bs/2, 0.5, cell.y*bs+bs/2)
    bench.material_override = _wood_material()
    parent.add_child(bench)

func _place_park_fences(parent: Node3D, gs: int, bs: float):
    """Размещаем заборы вокруг парков через PolyHaven модель"""
    if polyhaven_fences.size() == 0:
        return
    for x in range(gs-1):
        for z in range(gs-1):
            var cell = Vector2i(x, z)
            var occ = occupied_cells.get(cell, "")
            if occ == "park":
                # Проверяем соседей — если рядом дорога или пустота, ставим забор
                var neighbors = [Vector2i(x+1,z), Vector2i(x-1,z), Vector2i(x,z+1), Vector2i(x,z-1)]
                for n in neighbors:
                    if n.x >= 0 and n.x < gs and n.y >= 0 and n.y < gs:
                        var nocc = occupied_cells.get(n, "")
                        if nocc != "park" and rng.randf() < 0.15:
                            var fence = _load_gltf(polyhaven_fences[0])
                            if fence:
                                fence.position = Vector3(x*bs+bs/2, 0, z*bs+bs/2)
                                fence.rotation.y = 0 if abs(n.x - x) > 0 else PI/2
                                fence.scale = Vector3(0.4, 0.4, 0.4)
                                parent.add_child(fence)

func _metal_material() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#5A5A6A")
    mat.metallic = 0.6
    mat.roughness = 0.4
    return mat

func _wood_material() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#7A5A3A")
    mat.roughness = 0.8
    return mat

# ==== LIFE (Layer 7) ====
func _gen_life():
    var parent = Node3D.new()
    parent.name = "Life"
    add_child(parent)
    var gs = params.gridSize
    var bs = params.blockSize
    # Citizens
    var citizen_count = int(buildings.size() * 0.3)
    for i in range(citizen_count):
        var citizen = _create_citizen()
        citizen.position = Vector3(rng.randf()*gs*bs, 0.5, rng.randf()*gs*bs)
        parent.add_child(citizen)
    # Animals based on climate
    var animals = _choose_animals()
    for atype in animals:
        var count = rng.randi() % 3 + 1
        for i in range(count):
            var a = _create_animal(atype)
            a.position = Vector3(rng.randf()*gs*bs, 0.5, rng.randf()*gs*bs)
            parent.add_child(a)
    # Birds
    for i in range(5):
        var bird = _create_bird()
        bird.position = Vector3(rng.randf()*gs*bs, 15 + rng.randf()*20, rng.randf()*gs*bs)
        parent.add_child(bird)

func _choose_animals() -> Array:
    match params.vegetationType:
        "deciduous": return ["deer", "rabbit", "fox"]
        "coniferous": return ["deer", "wolf", "bear"]
        "palm": return ["parrot", "monkey"]
        "dead": return ["crow", "rat"]
        "crystalline": return ["butterfly"]
        _: return ["deer", "rabbit"]

func _create_citizen() -> Node3D:
    var root = Node3D.new()
    var body = MeshInstance3D.new()
    body.mesh = CapsuleMesh.new()
    body.mesh.height = 1.6
    body.mesh.radius = 0.35
    body.position.y = 0.8
    var colors = [Color("#8B7355"), Color("#A0522D"), Color("#6B8E6B"), Color("#4A6A7A"), Color("#7A5A6A")]
    var mat = StandardMaterial3D.new()
    mat.albedo_color = colors[rng.randi() % colors.size()]
    body.material_override = mat
    root.add_child(body)
    var head = MeshInstance3D.new()
    head.mesh = SphereMesh.new()
    head.mesh.radius = 0.3
    head.position.y = 1.85
    root.add_child(head)
    return root

func _create_animal(atype: String) -> Node3D:
    var root = Node3D.new()
    match atype:
        "deer":
            var body = MeshInstance3D.new()
            body.mesh = CapsuleMesh.new()
            body.mesh.height = 1.4; body.mesh.radius = 0.3
            body.position.y = 0.7
            var mat = StandardMaterial3D.new()
            mat.albedo_color = Color("#A08060")
            body.material_override = mat
            root.add_child(body)
        "rabbit":
            var body = MeshInstance3D.new()
            body.mesh = SphereMesh.new()
            body.mesh.radius = 0.2; body.position.y = 0.2
            var mat = StandardMaterial3D.new()
            mat.albedo_color = Color("#D0C0B0")
            body.material_override = mat
            root.add_child(body)
        "fox":
            var body = MeshInstance3D.new()
            body.mesh = CapsuleMesh.new()
            body.mesh.height = 0.9; body.mesh.radius = 0.22
            body.position.y = 0.45
            var mat = StandardMaterial3D.new()
            mat.albedo_color = Color("#D06020")
            body.material_override = mat
            root.add_child(body)
        "crow":
            var body = MeshInstance3D.new()
            body.mesh = SphereMesh.new()
            body.mesh.radius = 0.18
            var mat = StandardMaterial3D.new()
            mat.albedo_color = Color("#1A1A1A")
            body.material_override = mat
            root.add_child(body)
            root.position.y = 5
        "wolf":
            var body = MeshInstance3D.new()
            body.mesh = CapsuleMesh.new()
            body.mesh.height = 1.3; body.mesh.radius = 0.28
            body.position.y = 0.65
            var mat = StandardMaterial3D.new()
            mat.albedo_color = Color("#6A6A7A")
            body.material_override = mat
            root.add_child(body)
        "bear":
            var body = MeshInstance3D.new()
            body.mesh = CapsuleMesh.new()
            body.mesh.height = 1.6; body.mesh.radius = 0.5
            body.position.y = 0.8
            var mat = StandardMaterial3D.new()
            mat.albedo_color = Color("#4A3A2A")
            body.material_override = mat
            root.add_child(body)
        "parrot":
            var body = MeshInstance3D.new()
            body.mesh = CapsuleMesh.new()
            body.mesh.height = 0.4; body.mesh.radius = 0.12
            body.position.y = 0.2
            var mat = StandardMaterial3D.new()
            mat.albedo_color = Color("#FF4040")
            body.material_override = mat
            root.add_child(body)
            root.position.y = 12
        "monkey":
            var body = MeshInstance3D.new()
            body.mesh = CapsuleMesh.new()
            body.mesh.height = 0.7; body.mesh.radius = 0.18
            body.position.y = 0.35
            var mat = StandardMaterial3D.new()
            mat.albedo_color = Color("#8A6A4A")
            body.material_override = mat
            root.add_child(body)
        "butterfly":
            var body = MeshInstance3D.new()
            body.mesh = SphereMesh.new()
            body.mesh.radius = 0.05
            var mat = StandardMaterial3D.new()
            mat.albedo_color = Color("#FF80FF")
            body.material_override = mat
            root.add_child(body)
            for side in [-1, 1]:
                var wing = MeshInstance3D.new()
                wing.mesh = BoxMesh.new()
                wing.mesh.size = Vector3(0.15, 0.01, 0.2)
                wing.position = Vector3(side * 0.12, 0, 0)
                wing.material_override = mat
                root.add_child(wing)
            root.position.y = 2
        "rat":
            var body = MeshInstance3D.new()
            body.mesh = CapsuleMesh.new()
            body.mesh.height = 0.3; body.mesh.radius = 0.08
            body.position.y = 0.15
            var mat = StandardMaterial3D.new()
            mat.albedo_color = Color("#5A5A5A")
            body.material_override = mat
            root.add_child(body)
    return root

func _create_bird() -> Node3D:
    var root = Node3D.new()
    var body = MeshInstance3D.new()
    body.mesh = SphereMesh.new()
    body.mesh.radius = 0.25
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#5A5A3A")
    body.material_override = mat
    root.add_child(body)
    for side in [-1, 1]:
        var wing = MeshInstance3D.new()
        wing.mesh = BoxMesh.new()
        wing.mesh.size = Vector3(0.6, 0.05, 0.25)
        wing.position = Vector3(side * 0.4, 0.1, 0)
        wing.material_override = mat
        root.add_child(wing)
    return root

# ==== ATMOSPHERE (Layer 8) ====
func _gen_atmosphere():
    var env = get_node_or_null("WorldEnvironment")
    if not env:
        env = WorldEnvironment.new()
        env.name = "WorldEnvironment"
        add_child(env)
    var e = Environment.new()
    match params.timeOfDay:
        "dawn":
            e.background_color = Color("#F0C8A0")
            e.ambient_light_color = Color("#E0B890")
            e.fog_light_color = Color("#F0C8A0")
        "day":
            e.background_color = Color("#87CEEB")
            e.ambient_light_color = Color("#A0C8E0")
            e.fog_light_color = Color("#C0D8E8")
        "golden_hour":
            e.background_color = Color("#E8A860")
            e.ambient_light_color = Color("#D09050")
            e.fog_light_color = Color("#E8A860")
        "dusk":
            e.background_color = Color("#060a14")
            e.ambient_light_color = Color("#1a2848")
            e.fog_light_color = Color("#050810")
        "night":
            e.background_color = Color("#020408")
            e.ambient_light_color = Color("#0a1020")
            e.fog_light_color = Color("#020408")
        "midnight":
            e.background_color = Color("#010204")
            e.ambient_light_color = Color("#050810")
            e.fog_light_color = Color("#010204")
    e.fog_enabled = true
    e.fog_mode = Environment.FOG_MODE_EXPONENTIAL
    e.fog_density = params.fogDensity * 0.003
    env.environment = e

    # Directional light (sun/moon)
    var sun = get_node_or_null("DirectionalLight3D")
    if not sun:
        sun = DirectionalLight3D.new()
        sun.name = "DirectionalLight3D"
        add_child(sun)
    match params.timeOfDay:
        "dawn":
            sun.light_color = Color("#FFD0A0")
            sun.light_energy = 0.8
            sun.position = Vector3(100, 50, 80)
        "day":
            sun.light_color = Color("#FFFFFF")
            sun.light_energy = 1.2
            sun.position = Vector3(100, 200, 80)
        "golden_hour":
            sun.light_color = Color("#FF8040")
            sun.light_energy = 1.0
            sun.position = Vector3(100, 30, 80)
        "dusk":
            sun.light_color = Color("#806040")
            sun.light_energy = 0.6
            sun.position = Vector3(80, 60, 60)
        "night", "midnight":
            sun.light_color = Color("#405080")
            sun.light_energy = 0.2
            sun.position = Vector3(-50, 100, -50)
    sun.look_at(Vector3(params.gridSize*params.blockSize/2, 0, params.gridSize*params.blockSize/2))
    sun.shadow_enabled = true
    sun.shadow_bias = -0.0005

    # Particles
    if params.particleCount > 0 and params.particleType != "none":
        var particles = CPUParticles3D.new()
        particles.name = "Particles"
        particles.amount = params.particleCount
        particles.lifetime = 8.0
        particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
        var gs = params.gridSize
        var bs = params.blockSize
        particles.emission_box_extents = Vector3(gs*bs, 30, gs*bs)
        match params.particleType:
            "dust":
                particles.gravity = Vector3(params.windSpeed, -0.2, 0)
            "ash":
                particles.gravity = Vector3(params.windSpeed*0.5, -0.8, 0)
            "snow":
                particles.gravity = Vector3(0, -1.5, 0)
            "leaves":
                particles.gravity = Vector3(params.windSpeed*2, -0.5, 0)
            "rain":
                particles.gravity = Vector3(0, -8.0, 0)
            "sparks", "embers":
                particles.gravity = Vector3(0, 0.5, 0)
        var pmat = StandardMaterial3D.new()
        match params.particleType:
            "dust":   pmat.albedo_color = Color("#C8B8A8")
            "ash":    pmat.albedo_color = Color("#4A4A4A")
            "snow":   pmat.albedo_color = Color("#FFFFFF")
            "leaves": pmat.albedo_color = Color("#6A8A3A")
            "rain":   pmat.albedo_color = Color("#8090A0")
            "sparks": pmat.albedo_color = Color("#FF8040")
            "embers": pmat.albedo_color = Color("#FF4040")
        if params.particleType in ["sparks", "embers"]:
            pmat.emission_enabled = true
            pmat.emission = pmat.albedo_color
        particles.material_override = pmat
        add_child(particles)

# ==== CAMERA ====
func _setup_camera():
    var cam = get_node_or_null("Camera3D")
    if not cam:
        cam = Camera3D.new()
        cam.name = "Camera3D"
        add_child(cam)
    var gs = params.gridSize
    var bs = params.blockSize
    cam.position = Vector3(gs*bs*0.5, gs*bs*0.4, gs*bs*1.0)
    cam.look_at(Vector3(gs*bs*0.5, 0, gs*bs*0.5))
    cam.fov = 50.0

# ==== INPUT ====
func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _zoom_camera(-20)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _zoom_camera(20)

func _zoom_camera(amount):
    var cam = get_node_or_null("Camera3D")
    if not cam:
        return
    var center = Vector3(params.gridSize*params.blockSize*0.5, 0, params.gridSize*params.blockSize*0.5)
    var dir = (cam.position - center).normalized()
    cam.position += dir * amount
    var max_dist = params.gridSize * params.blockSize * 1.5
    if cam.position.distance_to(center) < 30.0:
        cam.position = center + dir * 30.0
    if cam.position.distance_to(center) > max_dist:
        cam.position = center + dir * max_dist

# ==== UTILITIES ====
func get_cell_world_pos(cell: Vector2i) -> Vector3:
    var half = params.blockSize / 2.0
    return Vector3(cell.x * params.blockSize + half, 0, cell.y * params.blockSize + half)

func get_height_at(cell: Vector2i) -> float:
    return terrain_heights.get(cell, 0.0)

func is_valid_cell(cell: Vector2i) -> bool:
    var gs = params.gridSize
    return cell.x >= 0 and cell.x < gs and cell.y >= 0 and cell.y < gs