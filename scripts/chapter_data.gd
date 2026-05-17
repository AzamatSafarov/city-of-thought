class_name ChapterData
extends Resource

var number = 0
var title = ""
var pages = 0
var part = "I"
var concepts = []
var density = 0.7

func _init(p_number=0, p_title="", p_pages=0, p_part="I", p_concepts=[], p_density=0.7):
	number = p_number
	title = p_title
	pages = p_pages
	part = p_part
	concepts = p_concepts
	density = p_density
