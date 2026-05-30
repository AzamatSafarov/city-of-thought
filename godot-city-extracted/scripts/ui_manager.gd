extends CanvasLayer

var title_label: Label
var meta_label: Label
var preset_buttons: Array = []

func _ready():
    add_to_group("ui")
    _build_ui()

func _build_ui():
    var panel = Panel.new()
    panel.anchors_preset = Control.PRESET_TOP_RIGHT
    panel.size = Vector2(300, 400)
    panel.position = Vector2(-320, 20)
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.96, 0.94, 0.9, 0.9)
    style.corner_radius_top_left = 12
    style.corner_radius_top_right = 12
    style.corner_radius_bottom_left = 12
    style.corner_radius_bottom_right = 12
    panel.add_theme_stylebox_override("panel", style)
    add_child(panel)
    
    var vbox = VBoxContainer.new()
    vbox.anchors_preset = Control.PRESET_FULL_RECT
    vbox.offset_left = 15
    vbox.offset_top = 15
    vbox.offset_right = -15
    vbox.offset_bottom = -15
    panel.add_child(vbox)
    
    title_label = Label.new()
    title_label.text = "City of Thought"
    title_label.add_theme_font_size_override("font_size", 18)
    title_label.modulate = Color(0.2, 0.2, 0.3)
    vbox.add_child(title_label)
    
    meta_label = Label.new()
    meta_label.text = "Select a book to generate world"
    meta_label.add_theme_font_size_override("font_size", 11)
    meta_label.modulate = Color(0.4, 0.4, 0.5)
    vbox.add_child(meta_label)
    
    var sep = HSeparator.new()
    vbox.add_child(sep)
    
    var books = ["gessen", "plato", "nietzsche", "kafka", "marx", "tolstoy", "rousseau"]
    for book in books:
        var btn = Button.new()
        btn.text = book.capitalize()
        btn.pressed.connect(func():
            _load_preset(book)
        )
        vbox.add_child(btn)
    
    var hint = Label.new()
    hint.text = "Scroll: zoom | Click building: inspect"
    hint.add_theme_font_size_override("font_size", 9)
    hint.modulate = Color(0.5, 0.5, 0.6, 0.7)
    vbox.add_child(hint)

func _load_preset(book_name: String):
    var path = "res://presets/%s.json" % book_name
    var city = get_tree().get_first_node_in_group("city_manager")
    if city and city.has_method("load_from_json"):
        city.load_from_json(path)
        title_label.text = city.params.title
        meta_label.text = "%s (%d) — %s" % [city.params.author, city.params.year, city.params.genre]
        print("Loaded preset: ", book_name)
    else:
        print("CityManager not found")

func show_chapter(chapter, part_data):
    title_label.text = chapter.title
    meta_label.text = "Chapter %d · %d pages · %s" % [chapter.number, chapter.pages, part_data.get("name", "")]
