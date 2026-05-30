extends Node3D
class_name CityManager

# ===== CONFIG =====
var rng := RandomNumberGenerator.new()
var params: Dictionary

# ===== GENERATORS =====
var terrain_gen: TerrainGenerator
var water_gen: WaterGenerator
var road_gen: RoadGenerator
var zone_gen: ZoneGenerator
var building_gen: BuildingGenerator
var vegetation_gen: VegetationGenerator
var life_gen: LifeGenerator
var atmosphere_gen: AtmosphereGenerator
var infra_gen: InfrastructureGenerator

# ===== STATE =====
var occupied_cells: Dictionary = {}  # Vector2i → "water" | "road" | "park" | "building"
var terrain_heights: Dictionary = {}  # Vector2i → float
var rivers: Array = []
var buildings: Array = []

func _ready():
    rng.randomize()
    params = _default_params()
    _apply_book_params()
    _build_city()
    _setup_camera()
    set_process_input(true)
    add_to_group("city_manager")

func _default_params() -> Dictionary:
    return {
        "gridSize": 14,
        "blockSize": 20,
        "roadWidth": 3,
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
        "dominantHue": 215,
        "saturationBase": 20,
        "brightnessBase": 30,
        "accentHueShift": 30,
        "windowLightFrequency": 0.4,
        "genre": "treatise",
        "author": "Unknown",
        "title": "City of Thought",
        "year": 1900
    }

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
                var bh = data.architecture.get("buildingHeightRange", {})
                params.buildingHeightRange = {"min": bh.get("min", 8), "max": bh.get("max", 40)}
            if data.has("color"):
                params.dominantHue = data.color.get("dominantHue", 215)
                params.saturationBase = data.color.get("saturationBase", 20)
                params.brightnessBase = data.color.get("brightnessBase", 30)
                params.accentHueShift = data.color.get("accentHueShift", 30)
            if data.has("life"):
                params.timeOfDay = data.life.get("timeOfDay", "dusk")
                params.fogDensity = data.life.get("fogDensity", 0.3)
                params.windSpeed = data.life.get("windSpeed", 0.6)
                params.particleType = data.life.get("particleType", "dust")
                params.particleCount = data.life.get("particleCount", 80)
                params.windowLightFrequency = data.life.get("windowLightFrequency", 0.4)
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

func _apply_book_params():
    # Auto-configure from genre if no JSON loaded
    match params.genre:
        "essay":
            params.gridSize = 8
            params.buildingDensity = 0.45
            params.parkRatio = 0.25
            params.layoutType = "organic"
        "treatise":
            params.gridSize = 14
            params.buildingDensity = 0.75
            params.parkRatio = 0.10
            params.layoutType = "grid"
        "dialogue":
            params.gridSize = 10
            params.buildingDensity = 0.55
            params.parkRatio = 0.20
            params.layoutType = "radial"
        "poetry":
            params.gridSize = 6
            params.buildingDensity = 0.25
            params.parkRatio = 0.40
            params.layoutType = "organic"
        "manifesto":
            params.gridSize = 12
            params.buildingDensity = 0.85
            params.parkRatio = 0.05
            params.layoutType = "grid"
            params.style = "constructivist"
        "autobiography":
            params.gridSize = 16
            params.buildingDensity = 0.65
            params.parkRatio = 0.15
            params.layoutType = "deformed"
        "critique":
            params.gridSize = 12
            params.buildingDensity = 0.70
            params.parkRatio = 0.10
            params.layoutType = "deformed"
    
    # Auto-configure from era (year)
    if params.year < 0:
        params.timeOfDay = "dawn"
        params.style = "classical"
    elif params.year < 500:
        params.timeOfDay = "day"
        params.style = "classical"
    elif params.year < 1500:
        params.timeOfDay = "golden_hour"
        params.style = "neo_gothic"
    elif params.year < 1800:
        params.timeOfDay = "dusk"
        params.style = "classical"
    elif params.year < 1900:
        params.timeOfDay = "night"
        params.style = "neo_gothic"
    elif params.year < 1950:
        params.timeOfDay = "midnight"
        params.style = "constructivist"
    else:
        params.timeOfDay = "midnight" if params.style == "brutalist" else "dusk"
    
    # Auto-configure from philosophy style
    match params.style:
        "classical":
            params.material = "stone"
            params.dominantHue = 215
        "baroque":
            params.material = "marble"
            params.dominantHue = 30
        "brutalist":
            params.material = "concrete"
            params.dominantHue = 200
        "minimal":
            params.material = "glass"
            params.dominantHue = 200
        "organic":
            params.material = "wood"
            params.dominantHue = 100
        "deconstructivist":
            params.material = "metal"
            params.dominantHue = 280
        "neo_gothic":
            params.material = "stone"
            params.dominantHue = 280
        "constructivist":
            params.material = "concrete"
            params.dominantHue = 10

func _build_city():
    print("[CityManager] ════════════════════════════")
    print("[CityManager] Building: ", params.title)
    print("[CityManager] Author:   ", params.author)
    print("[CityManager] Year:     ", params.year)
    print("[CityManager] Genre:    ", params.genre)
    print("[CityManager] Style:    ", params.style)
    print("[CityManager] Layout:   ", params.layoutType)
    print("[CityManager] ════════════════════════════")
    
    # Layer 0: Terrain
    terrain_gen = TerrainGenerator.new(rng, params)
    terrain_heights = terrain_gen.generate(self)
    
    # Layer 1: Water
    water_gen = WaterGenerator.new(rng, params)
    rivers = water_gen.generate(self, terrain_heights)
    _mark_water_cells()
    
    # Layer 2: Roads
    road_gen = RoadGenerator.new(rng, params)
    road_gen.generate(self, terrain_heights)
    _mark_road_cells()
    
    # Layer 3: Zones
    zone_gen = ZoneGenerator.new(rng, params)
    zone_gen.generate(self)
    
    # Layer 4: Buildings
    building_gen = BuildingGenerator.new(rng, params)
    buildings = building_gen.generate(self)
    
    # Layer 5: Vegetation
    vegetation_gen = VegetationGenerator.new(rng, params)
    vegetation_gen.generate(self)
    
    # Layer 6: Infrastructure (фонари, мосты, ворота)
    infra_gen = InfrastructureGenerator.new(rng, params)
    infra_gen.generate(self)
    
    # Layer 7: Life
    life_gen = LifeGenerator.new(rng, params)
    life_gen.generate(self)
    
    # Layer 8: Atmosphere
    atmosphere_gen = AtmosphereGenerator.new(params)
    atmosphere_gen.generate(self)
    
    print("[CityManager] ✅ Complete: %d buildings, %d rivers, %d cells" % [
        buildings.size(), rivers.size(), occupied_cells.size()
    ])

func _mark_water_cells():
    for river in rivers:
        for cell in river:
            occupied_cells[cell] = "water"

func _mark_road_cells():
    for cell in occupied_cells.keys():
        if occupied_cells[cell] == "road_temp":
            occupied_cells[cell] = "road"

func _setup_camera():
    var cam = $Camera3D if has_node("Camera3D") else null
    if not cam:
        cam = Camera3D.new()
        cam.name = "Camera3D"
        add_child(cam)
    var gs = params.gridSize
    var bs = params.blockSize
    cam.position = Vector3(gs * bs * 0.5, gs * bs * 0.4, gs * bs * 1.0)
    cam.look_at(Vector3(gs * bs * 0.5, 0, gs * bs * 0.5))
    cam.fov = 50.0

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
    var dir = (cam.position - Vector3(params.gridSize * params.blockSize * 0.5, 0, params.gridSize * params.blockSize * 0.5)).normalized()
    cam.position += dir * amount
    var max_dist = params.gridSize * params.blockSize * 1.5
    var min_dist = 30.0
    if cam.position.length() < min_dist:
        cam.position = dir * min_dist
    if cam.position.length() > max_dist:
        cam.position = dir * max_dist

func get_cell_world_pos(cell: Vector2i) -> Vector3:
    var half = params.blockSize / 2.0
    return Vector3(cell.x * params.blockSize + half, 0, cell.y * params.blockSize + half)

func get_height_at(cell: Vector2i) -> float:
    return terrain_heights.get(cell, 0.0)

func is_valid_cell(cell: Vector2i) -> bool:
    var gs = params.gridSize
    return cell.x >= 0 and cell.x < gs and cell.y >= 0 and cell.y < gs
