class_name GessenBook
extends Node

var chapters = []
var parts = {}

func _init():
	_init_chapters()
	_init_parts()

func _init_chapters():
	chapters = [
		ChapterData.new(1, "Идеал свободного образования", 24, "I", ["Свобода", "Руссо", "Толстой"], 0.7),
		ChapterData.new(2, "Дисциплина, свобода, личность", 24, "I", ["Дисциплина", "Личность", "Долг"], 0.8),
		ChapterData.new(3, "Ступень аномии", 34, "I", ["Игра", "Фребель", "Монтессори"], 0.6),
		ChapterData.new(4, "Ступень гетерономии", 33, "I", ["Школа", "Труд", "Дьюи"], 0.9),
		ChapterData.new(5, "Авторитет и свобода", 22, "I", ["Авторитет", "Наказание", "Община"], 0.75),
		ChapterData.new(6, "Система единой школы", 23, "I", ["Единая школа", "Либерализм", "Равенство"], 0.85),
		ChapterData.new(7, "Автономия", 34, "I", ["Самообразование", "Библиотека", "Университет"], 0.65),
		ChapterData.new(8, "Цель научного образования", 19, "II", ["Научность", "Мышление", "Критицизм"], 0.9),
		ChapterData.new(9, "Состав научного образования", 23, "II", ["Классификация", "Науки", "Естествознание"], 0.8),
		ChapterData.new(10, "Эпизодический курс", 19, "II", ["Эпизод", "Наглядность", "Познание"], 0.7),
		ChapterData.new(11, "Систематический курс", 15, "II", ["Система", "Преподавание", "Догматизм"], 0.95),
		ChapterData.new(12, "Теория университета", 22, "II", ["Университет", "Исследование", "Свобода"], 0.6),
		ChapterData.new(13, "Национальное образование", 26, "III", ["Нация", "Ушинский", "Фихте"], 0.8),
		ChapterData.new(14, "Физическое образование", 90, "III", ["Тело", "Гигиена", "Здоровье"], 0.5),
	]

func _init_parts():
	parts = {
		"I": {
			"name": "Нравственное",
			"color": Color("#E8DDD0"),
			"roof": Color("#C8B8A8"),
			"accent": Color("#A89880"),
			"position": Vector3(-150, 0, 0)
		},
		"II": {
			"name": "Научное",
			"color": Color("#D0DCE8"),
			"roof": Color("#B0C0D0"),
			"accent": Color("#8090A0"),
			"position": Vector3(0, 0, 0)
		},
		"III": {
			"name": "Национальное",
			"color": Color("#D0E8D8"),
			"roof": Color("#A8C8B8"),
			"accent": Color("#709880"),
			"position": Vector3(150, 0, 0)
		}
	}

func get_min_pages():
	var min_p = 999
	for ch in chapters:
		if ch.pages < min_p:
			min_p = ch.pages
	return min_p

func get_max_pages():
	var max_p = 0
	for ch in chapters:
		if ch.pages > max_p:
			max_p = ch.pages
	return max_p
