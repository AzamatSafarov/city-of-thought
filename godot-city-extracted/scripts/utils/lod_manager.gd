extends Node3D

## LODManager (Level of Detail)
## Встроенная в Godot 4.3 оптимизация через visibility и shadow
## Применяется ко всем объектам с MeshInstance3D + LODDistance скрипт
## Расстояния: LOD0 (<60), LOD1 (60-120), LOD2 (120-200), LOD3 (>200)
## LOD3 = Mesh удаляется, только AABBs

class_name LODManager

@export var lod_d1: float = 60.0    # Медиум LOD
@export var lod_d2: float = 120.0   # Далёкий LOD
@export var lod_d3: float = 200.0   # Убираем меш
@export var check_interval: float = 0.5

var _timer: float = 0.0
var _camera: Camera3D = null
var _targets: Array[Node3D] = []
var _buildings: Array[Node3D] = []
var _trees: Array[Node3D] = []
var _props: Array[Node3D] = []

func _ready():
    # Ищем камеру
    var viewport = get_viewport()
    if viewport and viewport.get_camera_3d():
        _camera = viewport.get_camera_3d()
    print("[LOD] Manager initialized")

func register_building(node: Node3D):
    _buildings.append(node)
    _targets.append(node)

func register_tree(node: Node3D):
    _trees.append(node)
    _targets.append(node)

func register_prop(node: Node3D):
    _props.append(node)
    _targets.append(node)

func _process(delta: float) -> void:
    _timer += delta
    if _timer < check_interval:
        return
    _timer = 0.0
    
    if _camera == null:
        _camera = get_viewport().get_camera_3d()
        if _camera == null:
            return
    
    var cam_pos = _camera.global_position
    var count_culled: int = 0
    
    for node in _targets:
        if not is_instance_valid(node):
            continue
        
        var dist = node.global_position.distance_to(cam_pos)
        var meshes = _find_meshes(node)
        var lights = _find_lights(node)
        
        # LOD0: полное качество
        if dist < lod_d1:
            for m in meshes:
                if m is MeshInstance3D:
                    m.visible = true
                    m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
            for l in lights:
                if l is Light3D:
                    l.visible = true
        # LOD1: убираем тени
        elif dist < lod_d2:
            for m in meshes:
                if m is MeshInstance3D:
                    m.visible = true
                    m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            for l in lights:
                if l is Light3D:
                    l.visible = false
        # LOD2: убираем меш, оставляем коллизии
        elif dist < lod_d3:
            for m in meshes:
                if m is MeshInstance3D:
                    m.visible = false
            for l in lights:
                if l is Light3D:
                    l.visible = false
            count_culled += 1
        # LOD3: скрываем полностью
        else:
            for m in meshes:
                if m is MeshInstance3D:
                    m.visible = false
            node.visible = false
            count_culled += 1
    
    # print("[LOD] Culled: ", count_culled, "/", _targets.size())

func _find_meshes(node: Node3D) -> Array:
    var result: Array = []
    if node is MeshInstance3D:
        result.append(node)
    for child in node.get_children():
        if child is MeshInstance3D:
            result.append(child)
    return result

func _find_lights(node: Node3D) -> Array:
    var result: Array = []
    for child in node.get_children():
        if child is Light3D:
            result.append(child)
    return result
