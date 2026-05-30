extends RefCounted
class_name ZoneGenerator

var rng: RandomNumberGenerator
var params: Dictionary

func _init(p_rng, p_params):
    rng = p_rng
    params = p_params

func generate(city: Node3D):
    var gs = params.gridSize
    var total = gs * gs
    
    var occupied = city.occupied_cells
    var used = 0
    for cell in occupied:
        used += 1
    
    var available = total - used
    
    # Парки — кластеры
    var park_cells = int(available * params.parkRatio)
    var clusters = _create_clusters(gs, park_cells, occupied)
    for cell in clusters:
        occupied[cell] = "park"
    
    # Всё остальное — строительство
    for x in range(gs):
        for z in range(gs):
            var cell = Vector2i(x, z)
            if not occupied.has(cell):
                occupied[cell] = "building"

func _create_clusters(gs, count, occupied) -> Array:
    var clusters = []
    var seeds = []
    
    # Сид-ячейки для кластеров
    for i in range(int(count / 3) + 1):
        var x = rng.randi() % gs
        var z = rng.randi() % gs
        var cell = Vector2i(x, z)
        if not occupied.has(cell) and not cell in seeds:
            seeds.append(cell)
    
    for seed in seeds:
        if clusters.size() >= count:
            break
        var queue = [seed]
        var cluster = [seed]
        var max_size = 3 + rng.randi() % 5
        
        while queue.size() > 0 and cluster.size() < max_size:
            var current = queue.pop_front()
            var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
            for d in dirs:
                var n = current + d
                if n.x < 0 or n.x >= gs or n.y < 0 or n.y >= gs:
                    continue
                if not occupied.has(n) and not n in cluster:
                    cluster.append(n)
                    queue.append(n)
                    if cluster.size() >= count:
                        break
        
        clusters.append_array(cluster)
        if clusters.size() >= count:
            break
    
    return clusters
