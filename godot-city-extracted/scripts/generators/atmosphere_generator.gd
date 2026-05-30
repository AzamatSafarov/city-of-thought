extends RefCounted
class_name AtmosphereGenerator

var params: Dictionary

func _init(p_params):
    params = p_params

func generate(city: Node3D):
    var world_env = WorldEnvironment.new()
    world_env.name = "WorldEnvironment"
    var env = Environment.new()
    
    var tod = params.timeOfDay
    var hue = params.dominantHue / 360.0
    var sat = params.saturationBase / 100.0
    var bright = params.brightnessBase / 100.0
    
    # Sky
    env.background_mode = Environment.BG_COLOR
    env.background_color = _sky_color(tod, hue, sat, bright)
    
    # Sun
    var sun = DirectionalLight3D.new()
    sun.name = "Sun"
    sun.light_color = _sun_color(tod)
    sun.light_energy = _sun_energy(tod)
    sun.shadow_enabled = true
    sun.shadow_bias = 0.05
    sun.rotation = _sun_rotation(tod)
    city.add_child(sun)
    
    # Fog
    if params.fogDensity > 0:
        env.fog_enabled = true
        env.fog_mode = Environment.FOG_MODE_DEPTH
        env.fog_density = params.fogDensity * 0.008
        env.fog_light_color = env.background_color
        env.fog_aerial_perspective = 0.3
    
    # Ambient
    env.ambient_light_source = Environment.AMBIENT_SOURCE_BG
    env.ambient_light_color = _ambient_color(tod, hue)
    env.ambient_light_energy = 0.3 + bright * 0.5
    
    # Glow для окон
    if params.windowLightFrequency > 0:
        env.glow_enabled = true
        env.glow_intensity = 0.5 * params.windowLightFrequency
        env.glow_strength = 0.8
        env.glow_bloom = 0.1
    
    # Tonemap
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.tonemap_exposure = 0.9
    
    world_env.environment = env
    city.add_child(world_env)

func _sky_color(tod, hue, sat, bright) -> Color:
    match tod:
        "dawn":
            return Color.from_hsv(0.08, 0.4 * sat, 0.6 + bright * 0.3)
        "day":
            return Color.from_hsv(0.55, 0.15 * sat, 0.75 + bright * 0.2)
        "golden_hour":
            return Color.from_hsv(0.12, 0.5 * sat, 0.55 + bright * 0.25)
        "dusk":
            return Color.from_hsv(hue, 0.35 * sat, 0.3 + bright * 0.3)
        "night":
            return Color("#060A14")
        "midnight":
            return Color("#020408")
    return Color.from_hsv(hue, 0.3 * sat, 0.4 + bright * 0.3)

func _sun_color(tod) -> Color:
    match tod:
        "dawn":       return Color("#FFD4A0")
        "day":        return Color("#FFF8E7")
        "golden_hour": return Color("#FFAA60")
        "dusk":       return Color("#C890A0")
        "night":      return Color("#4048A0")
        "midnight":   return Color("#202440")
    return Color.WHITE

func _sun_energy(tod) -> float:
    match tod:
        "dawn":       return 0.6
        "day":        return 1.2
        "golden_hour": return 0.9
        "dusk":       return 0.4
        "night":      return 0.2
        "midnight":   return 0.05
    return 0.8

func _sun_rotation(tod) -> Vector3:
    match tod:
        "dawn":       return Vector3(deg_to_rad(15), deg_to_rad(-45), 0)
        "day":        return Vector3(deg_to_rad(60), deg_to_rad(-30), 0)
        "golden_hour": return Vector3(deg_to_rad(10), deg_to_rad(60), 0)
        "dusk":       return Vector3(deg_to_rad(5), deg_to_rad(120), 0)
        "night":      return Vector3(deg_to_rad(-10), deg_to_rad(45), 0)
        "midnight":   return Vector3(deg_to_rad(-5), deg_to_rad(90), 0)
    return Vector3(deg_to_rad(45), deg_to_rad(-45), 0)

func _ambient_color(tod, hue) -> Color:
    var base = Color.from_hsv(hue, 0.2, 0.5)
    match tod:
        "dawn":       return base.lightened(0.3)
        "day":        return base.lightened(0.5)
        "golden_hour": return base.blend(Color("#FFAA60"))
        "dusk":       return base.darkened(0.2)
        "night":      return base.darkened(0.5)
        "midnight":   return base.darkened(0.6)
    return base
