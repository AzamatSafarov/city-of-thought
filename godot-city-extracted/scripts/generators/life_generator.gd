extends RefCounted
class_name LifeGenerator

var rng: RandomNumberGenerator
var params: Dictionary

func _init(p_rng, p_params):
    rng = p_rng
    params = p_params

func generate(city: Node3D):
    var parent = Node3D.new()
    parent.name = "Life"
    city.add_child(parent)
    
    # Жители
    var buildings = city.get_node_or_null("Buildings")
    if buildings:
        var citizen_count = int(buildings.get_child_count() * 0.3)
        for i in range(citizen_count):
            var citizen = _create_citizen()
            citizen.position = _random_ground_pos(city)
            parent.add_child(citizen)
    
    # Животные — выбор зависит от vegetationType и timeOfDay
    var animals = _choose_animals_for_climate()
    for animal_type in animals:
        var count = rng.randi() % 3 + 1
        for i in range(count):
            var animal = _create_animal(animal_type)
            animal.position = _random_ground_pos(city)
            parent.add_child(animal)
    
    # Птицы всегда
    for i in range(rng.randi() % 5 + 2):
        var bird = _create_bird()
        bird.position = _random_sky_pos(city)
        parent.add_child(bird)
    
    # Частицы
    _create_particles(parent)

func _choose_animals_for_climate() -> Array:
    var veg = params.vegetationType
    var tod = params.timeOfDay
    
    match veg:
        "deciduous":
            return ["deer", "rabbit", "squirrel", "fox"]
        "coniferous":
            return ["deer", "wolf", "owl", "bear"]
        "palm":
            return ["parrot", "monkey", "lizard"]
        "dead":
            return ["crow", "rat", "spider"]
        "crystalline":
            return ["butterfly", "moth"]
        _:
            return ["deer", "rabbit"]

func _create_citizen() -> Node3D:
    var root = Node3D.new()
    var body = MeshInstance3D.new()
    body.mesh = CapsuleMesh.new()
    body.mesh.height = 1.6
    body.mesh.radius = 0.35
    body.position.y = 0.8
    
    var colors = [
        Color("#8B7355"), Color("#A0522D"), Color("#6B8E6B"),
        Color("#8B6969"), Color("#7A6A50"), Color("#6B5B45"),
        Color("#4A6A7A"), Color("#7A5A6A"), Color("#5A7A5A")
    ]
    var mat = StandardMaterial3D.new()
    mat.albedo_color = colors[rng.randi() % colors.size()]
    mat.roughness = 0.8
    body.material_override = mat
    root.add_child(body)
    
    var head = MeshInstance3D.new()
    head.mesh = SphereMesh.new()
    head.mesh.radius = 0.3
    head.position.y = 1.85
    var hmat = mat.duplicate()
    hmat.albedo_color = mat.albedo_color.lightened(0.1)
    head.material_override = hmat
    root.add_child(head)
    
    if rng.randf() > 0.5:
        var hat = MeshInstance3D.new()
        hat.mesh = CylinderMesh.new()
        hat.mesh.top_radius = 0.0
        hat.mesh.bottom_radius = 0.4
        hat.mesh.height = 0.4
        hat.position.y = 2.15
        var hcolors = [Color("#8B4513"), Color("#2F4F4F"), Color("#8B0000"), Color("#DAA520")]
        var hcm = StandardMaterial3D.new()
        hcm.albedo_color = hcolors[rng.randi() % hcolors.size()]
        hat.material_override = hcm
        root.add_child(hat)
    
    # Скрипт блуждания
    var script = GDScript.new()
    script.source_code = '''extends Node3D
var speed = 1.2 + randf() * 0.6
var target: Vector3
var walk_time = 0.0
func _ready(): _pick_new_target()
func _pick_new_target():
    var gs = 14
    var bs = 20
    target = Vector3(randi() % gs * bs, 0, randi() % gs * bs)
    walk_time = 2.0 + randf() * 5.0
func _process(delta):
    walk_time -= delta
    if walk_time <= 0: _pick_new_target()
    var dir = (target - position).normalized()
    position += dir * speed * delta
    if dir.length() > 0.01:
        rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 3.0)
'''
    root.set_script(script)
    return root

func _create_animal(type: String) -> Node3D:
    match type:
        "bird":      return _create_bird()
        "cat":       return _create_cat()
        "dog":       return _create_dog()
        "deer":      return _create_deer()
        "rabbit":    return _create_rabbit()
        "squirrel":  return _create_squirrel()
        "fox":       return _create_fox()
        "wolf":      return _create_wolf()
        "owl":       return _create_owl()
        "bear":      return _create_bear()
        "crow":      return _create_crow()
        "rat":       return _create_rat()
        "spider":    return _create_spider()
        "parrot":    return _create_parrot()
        "monkey":    return _create_monkey()
        "lizard":    return _create_lizard()
        "butterfly": return _create_butterfly()
        "moth":      return _create_moth()
    return Node3D.new()

func _create_bird() -> Node3D:
    var root = Node3D.new()
    root.name = "Bird"
    var body = MeshInstance3D.new()
    body.mesh = SphereMesh.new()
    body.mesh.radius = 0.25
    body.position.y = 0
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
    root.position.y = 10 + rng.randf() * 15
    var script = GDScript.new()
    script.source_code = '''extends Node3D
var center: Vector3; var radius = 15.0; var angle = 0.0; var speed = 0.8
func _ready(): center = position; angle = randf() * TAU
func _process(delta):
    angle += speed * delta
    position.x = center.x + cos(angle) * radius
    position.z = center.z + sin(angle) * radius
    position.y = center.y + sin(angle * 2.0) * 2.0
    rotation.y = -angle + PI / 2
'''
    root.set_script(script)
    return root

func _create_cat() -> Node3D:
    var root = Node3D.new()
    root.name = "Cat"
    var body = MeshInstance3D.new()
    body.mesh = CapsuleMesh.new()
    body.mesh.height = 0.7; body.mesh.radius = 0.2
    body.position.y = 0.35
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#C89040")
    body.material_override = mat; root.add_child(body)
    var tail = MeshInstance3D.new()
    tail.mesh = CylinderMesh.new()
    tail.mesh.top_radius = 0.03; tail.mesh.bottom_radius = 0.06; tail.mesh.height = 0.5
    tail.position = Vector3(0, 0.4, -0.4); tail.rotation_degrees = Vector3(-30, 0, 0)
    tail.material_override = mat; root.add_child(tail)
    return root

func _create_dog() -> Node3D:
    var root = Node3D.new(); root.name = "Dog"
    var body = MeshInstance3D.new()
    body.mesh = CapsuleMesh.new()
    body.mesh.height = 1.0; body.mesh.radius = 0.25
    body.position.y = 0.5
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#8B6914")
    body.material_override = mat; root.add_child(body)
    var tail = MeshInstance3D.new()
    tail.mesh = CylinderMesh.new()
    tail.mesh.top_radius = 0.03; tail.mesh.bottom_radius = 0.05; tail.mesh.height = 0.4
    tail.position = Vector3(0, 0.6, -0.55); tail.rotation_degrees = Vector3(-20, 0, 0)
    tail.material_override = mat; root.add_child(tail)
    return root

func _create_deer() -> Node3D:
    var root = Node3D.new(); root.name = "Deer"
    var body = MeshInstance3D.new()
    body.mesh = CapsuleMesh.new()
    body.mesh.height = 1.4; body.mesh.radius = 0.3
    body.position.y = 0.7
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#A08060")
    body.material_override = mat; root.add_child(body)
    for side in [-1, 1]:
        var horn = MeshInstance3D.new()
        horn.mesh = CylinderMesh.new()
        horn.mesh.top_radius = 0.01; horn.mesh.bottom_radius = 0.04; horn.mesh.height = 0.5
        horn.position = Vector3(side * 0.2, 1.5, 0)
        horn.rotation_degrees = Vector3(15 * side, 0, 0)
        horn.material_override = mat; root.add_child(horn)
    return root

func _create_rabbit() -> Node3D:
    var root = Node3D.new(); root.name = "Rabbit"
    var body = MeshInstance3D.new()
    body.mesh = SphereMesh.new()
    body.mesh.radius = 0.2; body.position.y = 0.2
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#D0C0B0")
    body.material_override = mat; root.add_child(body)
    for side in [-1, 1]:
        var ear = MeshInstance3D.new()
        ear.mesh = BoxMesh.new()
        ear.mesh.size = Vector3(0.06, 0.3, 0.08)
        ear.position = Vector3(side * 0.12, 0.5, 0)
        ear.material_override = mat; root.add_child(ear)
    return root

func _create_squirrel() -> Node3D:
    var root = Node3D.new(); root.name = "Squirrel"
    var body = MeshInstance3D.new()
    body.mesh = CapsuleMesh.new()
    body.mesh.height = 0.5; body.mesh.radius = 0.15
    body.position.y = 0.25
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#A06020")
    body.material_override = mat; root.add_child(body)
    var tail = MeshInstance3D.new()
    tail.mesh = TorusMesh.new()
    tail.mesh.inner_radius = 0.1; tail.mesh.outer_radius = 0.2
    tail.position = Vector3(0, 0.5, -0.2)
    tail.rotation_degrees = Vector3(45, 0, 0)
    tail.material_override = mat; root.add_child(tail)
    return root

func _create_fox() -> Node3D:
    var root = Node3D.new(); root.name = "Fox"
    var body = MeshInstance3D.new()
    body.mesh = CapsuleMesh.new()
    body.mesh.height = 0.9; body.mesh.radius = 0.22
    body.position.y = 0.45
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#D06020")
    body.material_override = mat; root.add_child(body)
    var snout = MeshInstance3D.new()
    snout.mesh = BoxMesh.new()
    snout.mesh.size = Vector3(0.12, 0.1, 0.2)
    snout.position = Vector3(0, 0.55, 0.25)
    snout.material_override = mat; root.add_child(snout)
    return root

func _create_wolf() -> Node3D:
    var root = Node3D.new(); root.name = "Wolf"
    var body = MeshInstance3D.new()
    body.mesh = CapsuleMesh.new()
    body.mesh.height = 1.3; body.mesh.radius = 0.28
    body.position.y = 0.65
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#6A6A7A")
    body.material_override = mat; root.add_child(body)
    return root

func _create_owl() -> Node3D:
    var root = Node3D.new(); root.name = "Owl"
    var body = MeshInstance3D.new()
    body.mesh = SphereMesh.new()
    body.mesh.radius = 0.3; body.position.y = 0.3
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#5A4A2A")
    body.material_override = mat; root.add_child(body)
    for side in [-1, 1]:
        var eye = MeshInstance3D.new()
        eye.mesh = SphereMesh.new()
        eye.mesh.radius = 0.08
        eye.position = Vector3(side * 0.15, 0.35, 0.2)
        var emat = StandardMaterial3D.new()
        emat.albedo_color = Color("#FFD0A0")
        emat.emission_enabled = true; emat.emission = Color("#FFD0A0")
        eye.material_override = emat; root.add_child(eye)
    root.position.y = 6 + rng.randf() * 8
    return root

func _create_bear() -> Node3D:
    var root = Node3D.new(); root.name = "Bear"
    var body = MeshInstance3D.new()
    body.mesh = CapsuleMesh.new()
    body.mesh.height = 1.6; body.mesh.radius = 0.5
    body.position.y = 0.8
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#4A3A2A")
    body.material_override = mat; root.add_child(body)
    return root

func _create_crow() -> Node3D:
    var root = Node3D.new(); root.name = "Crow"
    var body = MeshInstance3D.new()
    body.mesh = SphereMesh.new()
    body.mesh.radius = 0.18; body.position.y = 0
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#1A1A1A")
    body.material_override = mat; root.add_child(body)
    root.position.y = 5 + rng.randf() * 10
    return root

func _create_rat() -> Node3D:
    var root = Node3D.new(); root.name = "Rat"
    var body = MeshInstance3D.new()
    body.mesh = CapsuleMesh.new()
    body.mesh.height = 0.3; body.mesh.radius = 0.08
    body.position.y = 0.15
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#5A5A5A")
    body.material_override = mat; root.add_child(body)
    return root

func _create_spider() -> Node3D:
    var root = Node3D.new(); root.name = "Spider"
    var body = MeshInstance3D.new()
    body.mesh = SphereMesh.new()
    body.mesh.radius = 0.1; body.position.y = 0.1
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#2A2A2A")
    body.material_override = mat; root.add_child(body)
    for i in range(8):
        var leg = MeshInstance3D.new()
        leg.mesh = CylinderMesh.new()
        leg.mesh.top_radius = 0.01; leg.mesh.bottom_radius = 0.02; leg.mesh.height = 0.3
        var angle = (TAU / 8) * i
        leg.position = Vector3(cos(angle) * 0.12, 0.05, sin(angle) * 0.12)
        leg.rotation_degrees = Vector3(0, rad_to_deg(angle), 60)
        leg.material_override = mat; root.add_child(leg)
    return root

func _create_parrot() -> Node3D:
    var root = Node3D.new(); root.name = "Parrot"
    var body = MeshInstance3D.new()
    body.mesh = CapsuleMesh.new()
    body.mesh.height = 0.4; body.mesh.radius = 0.12
    body.position.y = 0.2
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#FF4040")
    body.material_override = mat; root.add_child(body)
    root.position.y = 12 + rng.randf() * 8
    return root

func _create_monkey() -> Node3D:
    var root = Node3D.new(); root.name = "Monkey"
    var body = MeshInstance3D.new()
    body.mesh = CapsuleMesh.new()
    body.mesh.height = 0.7; body.mesh.radius = 0.18
    body.position.y = 0.35
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#8A6A4A")
    body.material_override = mat; root.add_child(body)
    return root

func _create_lizard() -> Node3D:
    var root = Node3D.new(); root.name = "Lizard"
    var body = MeshInstance3D.new()
    body.mesh = CapsuleMesh.new()
    body.mesh.height = 0.4; body.mesh.radius = 0.08
    body.position.y = 0.05
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#40A040")
    body.material_override = mat; root.add_child(body)
    return root

func _create_butterfly() -> Node3D:
    var root = Node3D.new(); root.name = "Butterfly"
    var body = MeshInstance3D.new()
    body.mesh = SphereMesh.new()
    body.mesh.radius = 0.05; body.position.y = 0
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#FF80FF")
    body.material_override = mat; root.add_child(body)
    for side in [-1, 1]:
        var wing = MeshInstance3D.new()
        wing.mesh = BoxMesh.new()
        wing.mesh.size = Vector3(0.15, 0.01, 0.2)
        wing.position = Vector3(side * 0.12, 0, 0)
        wing.material_override = mat; root.add_child(wing)
    root.position.y = 1 + rng.randf() * 3
    return root

func _create_moth() -> Node3D:
    var root = Node3D.new(); root.name = "Moth"
    var body = MeshInstance3D.new()
    body.mesh = SphereMesh.new()
    body.mesh.radius = 0.06; body.position.y = 0
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#B0A080")
    body.material_override = mat; root.add_child(body)
    for side in [-1, 1]:
        var wing = MeshInstance3D.new()
        wing.mesh = BoxMesh.new()
        wing.mesh.size = Vector3(0.12, 0.01, 0.25)
        wing.position = Vector3(side * 0.1, 0, 0)
        wing.material_override = mat; root.add_child(wing)
    root.position.y = 1 + rng.randf() * 3
    return root

func _create_particles(parent: Node3D):
    var ptype = params.particleType
    if ptype == "none" or params.particleCount <= 0:
        return
    
    var particles = CPUParticles3D.new()
    particles.name = "AtmosphereParticles"
    particles.amount = params.particleCount
    particles.lifetime = 8.0
    particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
    particles.emission_box_extents = Vector3(
        params.gridSize * params.blockSize, 30, params.gridSize * params.blockSize
    )
    particles.gravity = Vector3(0, -0.5, 0)
    
    var mat = StandardMaterial3D.new()
    match ptype:
        "dust":   mat.albedo_color = Color("#C8B8A8"); particles.gravity = Vector3(params.windSpeed, -0.2, 0)
        "ash":    mat.albedo_color = Color("#4A4A4A"); particles.gravity = Vector3(params.windSpeed * 0.5, -0.8, 0)
        "snow":   mat.albedo_color = Color("#FFFFFF"); particles.gravity = Vector3(0, -1.5, 0)
        "leaves": mat.albedo_color = Color("#6A8A3A"); particles.gravity = Vector3(params.windSpeed * 2, -0.5, 0)
        "rain":   mat.albedo_color = Color("#8090A0"); particles.gravity = Vector3(0, -8.0, 0)
        "sparks": mat.albedo_color = Color("#FF8040"); mat.emission_enabled = true; mat.emission = Color("#FF8040")
        "embers": mat.albedo_color = Color("#FF4040"); mat.emission_enabled = true; mat.emission = Color("#FF4040")
    
    particles.material_override = mat
    parent.add_child(particles)

func _random_ground_pos(city: Node3D) -> Vector3:
    var gs = params.gridSize; var bs = params.blockSize
    var x = rng.randi() % gs; var z = rng.randi() % gs
    var cell = Vector2i(x, z)
    var h = city.get_height_at(cell)
    return Vector3(x * bs + bs / 2.0 + rng.randf() * 4 - 2, h + 0.5, z * bs + bs / 2.0 + rng.randf() * 4 - 2)

func _random_sky_pos(city: Node3D) -> Vector3:
    var gs = params.gridSize; var bs = params.blockSize
    return Vector3(rng.randf() * gs * bs, 8 + rng.randf() * 20, rng.randf() * gs * bs)
