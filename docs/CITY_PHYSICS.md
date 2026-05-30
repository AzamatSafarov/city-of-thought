# Физика и логика генерации города — City of Thought

Город строится слоями, как настоящий: от геологии к архитектуре. Каждый слой — Godot-класс. Параметры из JSON определяют каждый слой напрямую.

---

## 0. Общий Pipeline

```
JSON params → Layer0 Terrain → Layer1 Water → Layer2 Roads
  → Layer3 Zones → Layer4 Buildings → Layer5 Life → Layer6 Atmosphere
```

Каждый слой получает `seed` + `params` и порождает сцену для следующего слоя.

---

## Layer 0: Terrain (Рельеф)

**Класс:** `TerrainGenerator`  
**Нода:** `MeshInstance3D` с `PlaneMesh` + displacement  
**Параметры:** `terrainRoughness`, `gridSize`, `blockSize`

### Алгоритм

```gdscript
func generate_terrain(params):
    var size = params.gridSize * params.blockSize
    var subdivisions = params.gridSize * 2  # чем мельче сетка, тем плавнее рельеф
    
    var mesh = PlaneMesh.new()
    mesh.size = Vector2(size, size)
    mesh.subdivide_width = subdivisions
    mesh.subdivide_depth = subdivisions
    
    var surface = mesh.get_mesh_arrays()  # или SurfaceTool
    var vertices = surface[ArrayMesh.ARRAY_VERTEX]
    
    # Fractal Brownian Motion — многооктавный Perlin noise
    for i in vertices.size():
        var x = vertices[i].x
        var z = vertices[i].z
        var height = fbm(x, z, octaves=4, persistence=0.5)
        height *= params.terrainRoughness * params.blockSize * 0.3
        vertices[i].y = height
    
    # Эрозия: реки протекают от максимумов к минимумам
    if params.waterPresence > 0:
        rivers = watershed_erode(vertices, params.waterPresence)
    
    apply_vertices(mesh, vertices)
    
    # Материал земли по vegetationType
    var mat = StandardMaterial3D.new()
    mat.albedo_color = _terrain_color(params.vegetationType)
    mat.roughness = 0.95
    mesh.material_override = mat
```

### Цвета terrain по vegetationType

| vegetationType | Цвет земли | Смысл |
|---------------|-----------|-------|
| deciduous | #8AB88A | Трава, жизненный цикл |
| coniferous | #5A7A5A | Хвойный лес, вечность |
| palm | #AACC88 | Тропики, экзотика |
| dead | #8B7355 | Упадок, пустошь |
| crystalline | #A0A8B8 | Холод, математика |

### Эрозия (Watershed)

```gdscript
func watershed_erode(vertices, water_presence):
    var river_count = int(water_presence * 5) + 1  # 1-6 рек
    var rivers = []
    
    for r in river_count:
        # Найти случайный локальный максимум
        var start = find_local_max(vertices)
        var river = [start]
        var current = start
        
        while true:
            var lowest_neighbor = find_lowest_neighbor(current, vertices)
            if lowest_neighbor == current:
                break  # локальный минимум = озеро
            river.append(lowest_neighbor)
            current = lowest_neighbor
        
        # Выдавить русло: понизить вершины вдоль реки
        for v_idx in river:
            vertices[v_idx].y -= 1.5  # глубина русла
        
        rivers.append(river)
    
    return rivers
```

---

## Layer 1: Water (Вода)

**Класс:** `WaterGenerator`  
**Ноды:** `MeshInstance3D` (реки, озёра, пруды)  
**Параметры:** `waterPresence`, `layoutType`

### Алгоритм

```gdscript
func generate_water(rivers, params):
    var water_parent = Node3D.new()
    water_parent.name = "Water"
    
    # 1. Реки из watershed
    for river in rivers:
        var river_mesh = _build_river_mesh(river, width=3.0 + params.waterPresence * 8)
        water_parent.add_child(river_mesh)
    
    # 2. Озёра в локальных минимумах (Perlin noise threshold)
    var lake_count = int(params.waterPresence * 3)
    for i in lake_count:
        var pos = find_local_minimum(terrain)
        var radius = 5.0 + randf() * 15.0 * params.waterPresence
        var lake = _build_lake_mesh(pos, radius)
        water_parent.add_child(lake)
    
    # 3. Фонтаны в центрах радиальных/системных layout
    if params.layoutType == "radial":
        var fountain = _build_fountain(Vector3.ZERO)
        water_parent.add_child(fountain)
    
    return water_parent
```

### Типы водных объектов

| Объект | Условие появления | Godot меш |
|--------|------------------|-----------|
| River | waterPresence > 0, watershed найден | PlaneMesh по точкам реки + ширина |
| Lake | waterPresence > 0.2 | CylinderMesh (flattened) |
| Pond | waterPresence > 0.1, случайно | Small CylinderMesh |
| Canal | layoutType == "grid", waterPresence > 0.3 | BoxMesh, прямоугольный |
| Fountain | layoutType == "radial", waterPresence > 0.4 | CylinderMesh + Particles |
| Well | buildingDensity > 0.7, organic layout | CylinderMesh (глубокая) |

### Материал воды

```gdscript
func _make_water_mat():
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#6AA0C0")
    mat.roughness = 0.05
    mat.metallic = 0.1
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color.a = 0.7
    return mat
```

---

## Layer 2: Roads (Дорожная сеть)

**Класс:** `RoadGenerator`  
**Ноды:** `MeshInstance3D` (дороги) + `StaticBody3D` (коллизия)  
**Параметры:** `layoutType`, `roadWidth`, `connectivity`, `gridSize`

### Алгоритм

```gdscript
func generate_roads(params, terrain, water_rivers):
    var road_parent = Node3D.new()
    road_parent.name = "Roads"
    
    var grid = Grid.new(params.gridSize, params.blockSize)
    var occupied = {}  # cell → тип (road/water/building/park)
    
    # 1. Пометить клетки с водой как занятые
    for river in water_rivers:
        for cell in river:
            occupied[cell] = "water"
    
    # 2. Генерация магистралей по layoutType
    var highways = _generate_highways(params.layoutType, grid)
    for h in highways:
        _place_road(h, params.roadWidth * 1.5, occupied)
    
    # 3. Квартальная сетка внутри районов
    var streets = _generate_streets(grid, params.layoutType, occupied)
    for s in streets:
        _place_road(s, params.roadWidth, occupied)
    
    # 4. Дополнительные связи (connectivity)
    if params.connectivity > 0.5:
        var extra = _generate_extra_connections(grid, params.connectivity, occupied)
        for e in extra:
            _place_road(e, params.roadWidth * 0.6, occupied)  # переулки
    
    # 5. Мосты через реки
    for river in water_rivers:
        var crossings = find_road_river_crossings(occupied, river)
        for c in crossings:
            _place_bridge(c, params.roadWidth * 1.2)
    
    return road_parent
```

### Layout → паттерн дорог

| layoutType | Паттерн магистралей | Паттерн улиц |
|-----------|---------------------|-------------|
| grid | Декартова сетка: горизонтали + вертикали | Прямоугольные кварталы |
| organic | Space-filling curve (Hilbert/Peano) | Кривые, адаптируются к рельефу |
| radial | Лучи от центра + концентрические кольца | Секторные кварталы |
| deformed | Grid + Perlin distortion | Разорванные кварталы |

### Типы дорожных объектов

| Объект | Ширина | Условие | Godot меш |
|--------|--------|---------|-----------|
| Highway | roadWidth * 1.5 | layoutType магистраль | PlaneMesh с curb |
| Street | roadWidth | Квартальная сетка | PlaneMesh |
| Alley | roadWidth * 0.6 | connectivity > 0.5 | PlaneMesh (узкий) |
| Path | roadWidth * 0.4 | В парках, пешеходный | PlaneMesh + noise |
| Bridge | roadWidth * 1.2 | Пересечение с рекой | BoxMesh (арочный) |
| Stairs | roadWidth | Участки с Δheight > 3 | BoxMesh лестница |
| Archway | — | Между двумя зданиями | CSGCombiner (арка) |
| Gate | — | На границе частей книги | BoxMesh колонны + решётка |
| Pavement | — | Вдоль зданий | PlaneMesh бордюр |

---

## Layer 3: Zones (Зонирование)

**Класс:** `ZoneGenerator`  
**Параметры:** `buildingDensity`, `parkRatio`, `gridSize`

### Алгоритм

```gdscript
func generate_zones(grid, occupied, params):
    var zones = {}
    var total_cells = params.gridSize * params.gridSize
    
    var building_target = int(total_cells * params.buildingDensity)
    var park_target = int(total_cells * params.parkRatio)
    var road_count = occupied.values().count("road")
    var water_count = occupied.values().count("water")
    
    var available = total_cells - road_count - water_count
    
    # 1. Парки: кластеризация (парки группируются)
    var park_clusters = _cluster_cells(grid, park_target, "park", occupied)
    for cell in park_clusters:
        occupied[cell] = "park"
    
    # 2. Строительство: всё оставшееся доступное
    for cell in grid.cells:
        if cell not in occupied:
            occupied[cell] = "building"
    
    return occupied  # cell → "road" | "water" | "park" | "building"
```

### Кластеризация парков

```gdscript
func _cluster_cells(grid, target_count, zone_type, occupied):
    var clusters = []
    var placed = 0
    
    # Seed-ячейки для кластеров
    var seeds = _random_empty_cells(grid, int(target_count / 4), occupied)
    
    for seed in seeds:
        var cluster = [seed]
        var queue = [seed]
        var max_size = 3 + randi() % 5  # кластер 3-7 ячеек
        
        while queue.size() > 0 and cluster.size() < max_size:
            var current = queue.pop_front()
            for neighbor in grid.neighbors(current):
                if neighbor not in occupied and neighbor not in cluster:
                    cluster.append(neighbor)
                    queue.append(neighbor)
                    placed += 1
                    if placed >= target_count:
                        return cluster
        
        clusters.append_array(cluster)
    
    return clusters
```

---

## Layer 4: Buildings (Здания)

**Класс:** `BuildingGenerator` — расширяет текущий `CozyBuilding`  
**Параметры:** `style`, `material`, `buildingHeightRange`, `skyscraperRatio`, `blockSubdivisions`, `windowPatterns`

### Алгоритм

```gdscript
func generate_buildings(occupied, grid, params, book_data):
    var building_parent = Node3D.new()
    building_parent.name = "Buildings"
    
    # Группируем главы по частям книги → районы города
    var districts = _group_chapters_by_part(book_data)
    
    for district_name in districts:
        var district = districts[district_name]
        var district_cells = _find_cells_for_district(district, occupied, grid)
        
        for chapter in district.chapters:
            var cell = district_cells.pop_front()
            if cell == null:
                break
            
            # Количество зданий в квартале = blockSubdivisions
            var subdivisions = params.blockSubdivisions
            var positions = _subdivide_cell(cell, subdivisions)
            
            for pos in positions:
                var building = _create_building_for_chapter(
                    chapter, district, pos, params
                )
                building_parent.add_child(building)
    
    return building_parent
```

### Подразделение квартала

```gdscript
func _subdivide_cell(cell, count):
    var center = cell.center
    var size = cell.size
    var positions = []
    
    match count:
        1:
            positions = [center]
        2:
            # Два здания: горизонтально
            positions = [
                center + Vector3(-size.x * 0.25, 0, 0),
                center + Vector3(size.x * 0.25, 0, 0)
            ]
        3:
            # L-форма или линия
            positions = [
                center + Vector3(-size.x * 0.25, 0, -size.z * 0.25),
                center + Vector3(size.x * 0.25, 0, -size.z * 0.25),
                center + Vector3(0, 0, size.z * 0.25)
            ]
        4:
            # Квартал 2x2
            var offset = size * 0.25
            positions = [
                center + Vector3(-offset.x, 0, -offset.z),
                center + Vector3(offset.x, 0, -offset.z),
                center + Vector3(-offset.x, 0, offset.z),
                center + Vector3(offset.x, 0, offset.z)
            ]
    
    return positions
```

### Тип здания по главе

| Условие | Тип здания | Высота | Меш |
|---------|-----------|--------|-----|
| is_monument (pages > среднего) | Monument | 120-160% max | BoxMesh + PrismMesh крыша |
| pages < 10, dialogue | Pavilion/Беседка | 2-5 | PrismMesh |
| skyscraperRatio > random | Skyscraper | 80-100% max | Tall BoxMesh |
| blockSubdivisions == 1 | Villa/Особняк | 60-80% max | BoxMesh + Gable roof |
| concept includes "школа"/"университет" | Academy | 70-90% max | BoxMesh + Columns |
| concept includes "церковь"/"религия" | Chapel | 50-70% max | PrismMesh + spire |
| concept includes "разрушение"/"кризис" | Ruin | 20-40% max | Fractured BoxMesh |
| concept includes "стройка"/"будущее" | Scaffold | 30-50% max | BoxMesh + Grid lines |

### Style → форма здания

| style | Основной меш | Крыша | Детали |
|-------|-------------|-------|--------|
| classical | BoxMesh | PrismMesh (gable) | Колонны, треугольный фронтон |
| baroque | BoxMesh (bulging) | Dome (SphereMesh) | Орнамент, выступы |
| brutalist | BoxMesh (raw) | Flat + выступы | Бетонные плиты, нет декора |
| minimal | BoxMesh (clean) | Flat | Никаких деталей |
| organic | CylinderMesh | Dome | Волнистые линии |
| deconstructivist | Fractured BoxMesh | Angular Prism | Разрывы, наклоны |
| neo_gothic | Tall BoxMesh | Spire (ConeMesh) | Стрельчатые арки |
| constructivist | Geometric BoxMesh | Flat + antenna | Геометрические выступы |

---

## Layer 5: Vegetation (Растительность)

**Класс:** `VegetationGenerator`  
**Ноды:** `MeshInstance3D` × N  
**Параметры:** `treeDensity`, `vegetationType`, `parkRatio`

### Алгоритм

```gdscript
func generate_vegetation(occupied, params):
    var veg_parent = Node3D.new()
    veg_parent.name = "Vegetation"
    
    var tree_count = int(occupied.size() * params.treeDensity * 2)
    
    for i in tree_count:
        # Только в парковых клетках и на границах дорог
        var cell = _random_cell_where(occupied, ["park", "building"])
        var pos = random_position_in_cell(cell)
        
        var tree = _create_tree(params.vegetationType)
        tree.position = pos
        veg_parent.add_child(tree)
    
    # Живые изгороди вдоль улиц
    for road_cell in _filter(occupied, "road"):
        if randf() < 0.3:
            var hedge = _create_hedge()
            hedge.position = road_cell.edge_position
            veg_parent.add_child(hedge)
    
    return veg_parent
```

---

## Layer 6: Life (Жители и животные)

**Класс:** `LifeGenerator` — расширяет текущий `CozyCitizen`  
**Параметры:** `particleType`, `particleCount`, `movementSpeed`

### Алгоритм

```gdscript
func generate_life(buildings, roads, params):
    var life_parent = Node3D.new()
    life_parent.name = "Life"
    
    # 1. Жители — связаны с зданиями
    var citizen_count = buildings.size() * 0.3  # 30% от количества зданий
    for i in citizen_count:
        var building = buildings.pick_random()
        var citizen = _create_citizen(building, params)
        citizen.position = building.position + Vector3(randf()*10, 0, randf()*10)
        life_parent.add_child(citizen)
    
    # 2. Животные — связаны с зонами
    var animals = _create_animals(params)
    for animal in animals:
        life_parent.add_child(animal)
    
    # 3. Частицы — атмосфера
    var particles = _create_particles(params)
    life_parent.add_child(particles)
    
    return life_parent
```

---

## Layer 7: Atmosphere (Атмосфера)

**Класс:** `AtmosphereGenerator`  
**Ноды:** `WorldEnvironment`, `DirectionalLight3D`, `Fog`, CPUParticles3D  
**Параметры:** `timeOfDay`, `fogDensity`, `windSpeed`, `cloudCoverage`, `dominantHue`

### Алгоритм

```gdscript
func generate_atmosphere(params):
    var world_env = WorldEnvironment.new()
    var env = Environment.new()
    
    # 1. Sky по timeOfDay
    env.background_mode = Environment.BG_COLOR
    env.background_color = _sky_color(params.timeOfDay, params.dominantHue)
    
    # 2. Свет
    var sun = DirectionalLight3D.new()
    sun.light_color = _sun_color(params.timeOfDay)
    sun.light_energy = _sun_energy(params.timeOfDay)
    sun.rotation = _sun_rotation(params.timeOfDay)
    
    # 3. Fog
    if params.fogDensity > 0:
        env.fog_enabled = true
        env.fog_mode = Environment.FOG_MODE_DEPTH
        env.fog_density = params.fogDensity * 0.01
        env.fog_light_color = env.background_color
    
    # 4. Ambient
    env.ambient_light_source = Environment.AMBIENT_SOURCE_BG
    env.ambient_light_color = _ambient_color(params.timeOfDay)
    env.ambient_light_energy = 0.4 + params.brightnessBase / 200.0
    
    # 5. Glow (для окон)
    env.glow_enabled = true
    env.glow_intensity = 0.4 * params.windowLightFrequency
    
    world_env.environment = env
    return {"world_env": world_env, "sun": sun}
```

### timeOfDay → параметры

| timeOfDay | Sky color | Sun color | Sun energy | Fog |
|-----------|-----------|-----------|------------|-----|
| dawn | #F5E6D3 | #FFD4A0 | 0.6 | 0.15 |
| day | #D6E6F0 | #FFF8E7 | 1.2 | 0.0 |
| golden_hour | #F0D8A0 | #FFAA60 | 0.9 | 0.05 |
| dusk | #A898B8 | #C890A0 | 0.5 | 0.25 |
| night | #060A14 | #4048A0 | 0.3 | 0.4 |
| midnight | #020408 | #202440 | 0.15 | 0.6 |

---

## Связь параметров ↔ физика (шпаргалка)

| Параметр | Что контролирует | Код |
|----------|-----------------|-----|
| gridSize | Количество кварталов N×N | `for x in gridSize: for z in gridSize:` |
| blockSize | Размер квартала в метрах | `cell.size = Vector3(blockSize, 0, blockSize)` |
| roadWidth | Ширина улиц | `road_mesh.width = roadWidth` |
| layoutType | Паттерн дорог | `match layoutType: "grid" → manhattan()` |
| connectivity | Доп. переулки | `if randf() < connectivity: add_alley()` |
| style | Форма зданий | `match style: "baroque" → dome_roof()` |
| material | Цвет фасада | `mat.albedo = material_colors[material]` |
| buildingHeightRange | min/max высота | `h = lerp(min, max, chapter.pages_ratio)` |
| skyscraperRatio | Доля высотных | `if randf() < skyscraperRatio: h = max * 0.9` |
| buildingDensity | Застройка | `building_cells = total * density` |
| blockSubdivisions | Зданий в квартале | `subdivide_cell(cell, blockSubdivisions)` |
| dominantHue | Оттенок города | `Color.from_hsv(dominantHue/360, ...)` |
| saturationBase | Интенсивность | `mat.albedo.s = saturationBase/100` |
| brightnessBase | Яркость | `mat.albedo.v = brightnessBase/100` |
| timeOfDay | Освещение | `sun.energy = time_of_day_energy[timeOfDay]` |
| fogDensity | Туман | `env.fog_density = fogDensity * 0.01` |
| windSpeed | Скорость частиц | `particle.velocity = Vector3(windSpeed, 0, 0)` |
| cloudCoverage | Облака | `cloud_count = cloudCoverage * 20` |
| particleType | Тип частиц | `match particleType: "ash" → grey_dust()` |
| particleCount | Количество частиц | `CPUParticles3D.amount = particleCount` |
| terrainRoughness | Рельеф | `height *= terrainRoughness * blockSize` |
| waterPresence | Вода | `river_count = int(waterPresence * 5) + 1` |
| treeDensity | Деревья | `tree_count = cells * treeDensity * 2` |
| vegetationType | Тип деревьев | `match vegType: "coniferous" → cone_mesh()` |
| parkRatio | Парки | `park_cells = total * parkRatio` |
| movementSpeed | Темп жизни | `citizen.speed = movementSpeed * 3` |

---

## Process Notes

- Инструменты: read_file (все файлы репозитория city-of-thought), terminal (unzip архива), write_file
- Проблема: Godot-проект запакован в zip, пришлось разархивировать
- Найдено: 5 скриптов (main, cozy_building, cozy_citizen, gessen_book, chapter_data, ui_manager) + 2 сцены
- Текущая генерация: земля (PlaneMesh) → вода (PlaneMesh) → здания кольцом вокруг монумента → жители (блуждание) — без рельефа, дорог, растительности
- Физика отсутствует: нет коллизий между жителями, нет navmesh, здания левитируют
- Добавлено: полная 7-слойная система с Godot-псевдокодом для каждого слоя
- Связь: каждый параметр из JSON теперь имеет прямое отображение в код генерации
