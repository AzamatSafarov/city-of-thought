extends CanvasLayer

var title_label
var meta_label
var concepts_label

func _ready():
	add_to_group("ui")
	
	# Создаём UI элементы кодом, не зависим от tscn
	title_label = Label.new()
	title_label.position = Vector2(20, 20)
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.modulate = Color(0.2, 0.2, 0.3, 1)
	add_child(title_label)
	
	meta_label = Label.new()
	meta_label.position = Vector2(20, 50)
	meta_label.add_theme_font_size_override("font_size", 12)
	meta_label.modulate = Color(0.4, 0.4, 0.5, 1)
	add_child(meta_label)
	
	concepts_label = Label.new()
	concepts_label.position = Vector2(20, 75)
	concepts_label.add_theme_font_size_override("font_size", 11)
	concepts_label.modulate = Color(0.5, 0.5, 0.6, 1)
	add_child(concepts_label)
	
	var instructions = Label.new()
	instructions.position = Vector2(20, 120)
	instructions.add_theme_font_size_override("font_size", 10)
	instructions.modulate = Color(0.5, 0.5, 0.6, 0.7)
	instructions.text = "Drag to orbit / Scroll to zoom / Click building"
	add_child(instructions)

func show_chapter(chapter, part_data):
	title_label.text = chapter.title
	meta_label.text = "Глава %d · %d страниц · %s" % [chapter.number, chapter.pages, part_data["name"]]
	concepts_label.text = "Концепты: " + ", ".join(chapter.concepts)
