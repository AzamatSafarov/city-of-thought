#!/usr/bin/env python3
"""PDF → City of Thought JSON пресет.
Извлекает текст из PDF (книги философов), анализирует через базовую эвристику,
генерирует JSON пресет для Godot city_manager.

Требует: pip install PyMuPDF llm-wiki  # llm-wiki для API вызовов
Или: pip install PyMuPDF

Пример: python3 pdf_to_preset.py ~/books/platon_philosophia.pdf --author Plato
"""

import argparse, json, os, sys, subprocess, re, textwrap
from pathlib import Path

# ==== HEURISTIC KEYWORD MAPPING ====
# Базовые правила: ключевые слова → параметры города
KEYWORD_MAP = {
    "architecture": {
        "колонна": "classical", "column": "classical", "пьедестал": "classical",
        "дом": "classical", "храм": "classical", "temple": "classical",
        "дворец": "baroque", "castle": "baroque", "дворц": "baroque",
        "католиц": "baroque", "базилик": "baroque", "cathedral": "baroque",
        "душ": "brutalist", "трущоб": "brutalist", "slum": "brutalist",
        "бетон": "brutalist", "concrete": "brutalist", "завод": "brutalist",
        "фабрик": "brutalist", "factory": "brutalist", "industrial": "brutalist",
        "простор": "minimal", "minimal": "minimal", "чистый": "minimal",
        "природа": "organic", "дерев": "organic", "лес": "organic", "nature": "organic",
        "лома": "deconstructivist", "разруш": "deconstructivist", "deconstruct": "deconstructivist",
        "готик": "neo_gothic", "gothic": "neo_gothic", "монастыр": "neo_gothic",
        "совет": "constructivist", "constructiv": "constructivist", "массов": "constructivist",
        "коммуна": "constructivist",
    },
    "atmosphere": {
        "сумрак": "dusk", "dusk": "dusk", "вечер": "dusk",
        "темн": "night", "night": "night", "полноч": "night", "midnight": "night",
        "рассвет": "dawn", "dawn": "dawn", "утро": "dawn",
        "золот": "golden_hour", "golden": "golden_hour",
        "днев": "day", "day": "day", "свет": "day",
        "мгла": "fog", "fog": "fog", "туман": "fog", "мист": "mist",
        "огон": "embers", "fire": "embers", "плам": "embers", "flame": "embers",
        "пепел": "ash", "ash": "ash", "пыль": "dust", "dust": "dust",
        "лист": "leaves", "leaves": "leaves", "осен": "leaves",
        "искр": "sparks", "sparks": "sparks", "spark": "sparks",
        "снег": "snow", "snow": "snow", "зима": "snow",
        "дым": "fog", "smoke": "fog", "дыш": "fog",
    },
    "material": {
        "мрамор": "marble", "marble": "marble", "каррар": "marble",
        "камен": "stone", "stone": "stone", "rock": "stone",
        "стекл": "glass", "glass": "glass", "прозрач": "glass",
        "кирпич": "brick", "brick": "brick",
        "дерев": "wood", "wood": "wood",
        "метал": "metal", "metal": "metal",
        "лед": "ice", "ice": "ice", "холод": "ice",
        "бетон": "concrete", "concrete": "concrete",
    },
    "vegetation": {
        "дуб": "deciduous", " oak": "deciduous", "берез": "deciduous", "листоч": "deciduous",
        "хвой": "coniferous", "сосн": "coniferous", "ель": "coniferous", "pine": "coniferous",
        "пальм": "palm", "palm": "palm", "тропик": "palm",
        "мёртв": "dead", "dead": "dead", "сух": "dead", "wither": "dead",
        "кристал": "crystalline", "crystal": "crystalline", "ледян": "crystalline",
    },
    "layout": {
        "сетк": "grid", "grid": "grid", "прямо": "grid", "straight": "grid",
        "круг": "radial", "радиал": "radial", "центр": "radial", "цирку": "radial",
        "лабиринт": "organic", "organic": "organic", "река": "organic", "river": "organic",
        "изгиб": "deformed", "deform": "deformed", "крив": "deformed",
    },
    "genre": {
        "эссе": "essay", "essay": "essay", "очерк": "essay",
        "трактат": "treatise", "treatise": "treatise", "диссертац": "treatise",
        "диалог": "dialogue", "dialogue": "dialogue", "разговор": "dialogue",
        "поэз": "poetry", "poetry": "poetry", "стих": "poetry", "vers": "poetry",
        "манифест": "manifesto", "manifesto": "manifesto", "указ": "manifesto",
        "критик": "critique", "critique": "critique", "обзор": "critique",
        "автобиограф": "autobiography", "autobiograph": "autobiography", "воспоминания": "autobiography",
    },
    "emotion": {
        "надежд": "hope", "hope": "hope", "свет": "hope",
        "отчаян": "despair", "despair": "despair", "безысход": "despair",
        "ярост": "rage", "rage": "rage", "гнев": "rage", "anger": "rage",
        "мир": "serenity", "serene": "serenity", "спок": "serenity", "calm": "serenity",
        "тоск": "melancholy", "melanchol": "melancholy", "груст": "melancholy", "sad": "melancholy",
        "тревог": "anxiety", "anxious": "anxiety", "боязнь": "anxiety",
        "экстаз": "ecstasy", "ecstasy": "ecstasy", "восторг": "ecstasy", "bliss": "ecstasy",
    }
}

def extract_text_from_pdf(pdf_path: str) -> str:
    """Извлекает текст из PDF через PyMuPDF (fitz)"""
    try:
        import fitz
        doc = fitz.open(pdf_path)
        text_parts = []
        # Берём первые 20 страниц (вступление достаточно для определения стиля)
        for page_num in range(min(20, len(doc))):
            page = doc.load_page(page_num)
            text_parts.append(page.get_text())
        doc.close()
        return "\n".join(text_parts)
    except ImportError:
        print("ERROR: PyMuPDF (fitz) not installed. Run: pip install PyMuPDF")
        print("Falling back to pdftotext...")
        try:
            r = subprocess.run(["pdftotext", "-l", "20", pdf_path, "-"], capture_output=True, text=True)
            return r.stdout
        except FileNotFoundError:
            print("ERROR: pdftotext not found either. Install poppler-utils.")
            sys.exit(1)

def analyze_text(text: str) -> dict:
    """Анализирует текст через эвристику и возвращает параметры"""
    text_lower = text.lower()
    scores = {k: {} for k in KEYWORD_MAP}
    
    # Подсчитываем вхождения ключевых слов
    for category, keywords in KEYWORD_MAP.items():
        for kw, value in keywords.items():
            count = text_lower.count(kw.lower())
            if count > 0:
                if value not in scores[category]:
                    scores[category][value] = 0
                scores[category][value] += count
    
    results = {}
    # Выбираем победителя в каждой категории
    for category, values in scores.items():
        if values:
            winner = max(values, key=values.get)
            results[category] = winner
        else:
            # Дефолтные значения
            defaults = {
                "architecture": "classical",
                "atmosphere": "dusk",
                "material": "stone",
                "vegetation": "deciduous",
                "layout": "grid",
                "genre": "treatise",
                "emotion": "serenity"
            }
            results[category] = defaults.get(category, "")
    
    return results

def build_preset(analysis: dict, title: str, author: str, year: int = 1900) -> dict:
    """Формирует JSON пресет для city_manager.gd"""
    
    style = analysis.get("architecture", "classical")
    # Материал по стилю если не определён
    material = analysis.get("material", "stone")
    if material == "stone" and style in ["brutalist", "constructivist"]:
        material = "concrete"
    if material == "stone" and style in ["organic"]:
        material = "wood"
    if material == "stone" and style in ["neo_gothic"]:
        material = "stone"
    
    atmosphere = analysis.get("atmosphere", "dusk")
    # Подбираем particles под атмосферу
    particle_map = {
        "dusk": "dust", "night": "embers", "midnight": "embers",
        "dawn": "leaves", "day": "dust", "golden_hour": "leaves",
        "fog": "fog"
    }
    particle_type = particle_map.get(atmosphere, "dust")
    
    # Параметры города по жанру
    genre = analysis.get("genre", "treatise")
    density_map = {
        "essay": 0.4, "poetry": 0.3, "dialogue": 0.5, "manifesto": 0.9,
        "treatise": 0.7, "critique": 0.8, "autobiography": 0.6
    }
    density = density_map.get(genre, 0.7)
    
    layout_map = {
        "essay": "organic", "poetry": "organic", "dialogue": "radial",
        "manifesto": "grid", "treatise": "grid", "critique": "deformed",
        "autobiography": "organic"
    }
    layout = analysis.get("layout", layout_map.get(genre, "grid"))
    
    return {
        "meta": {
            "title": title,
            "author": author,
            "year": year,
            "genre": genre,
            "school": "auto",
            "emotion": analysis.get("emotion", "serenity")
        },
        "book_to_world": {
            "city_type": _genre_to_city_type(genre),
            "building_style": style,
            "material": material,
            "atmosphere": atmosphere,
            "dominant_shape": _shape_for_style(style),
            "time_of_day": _time_for_atmosphere(atmosphere),
            "vegetation_level": _vegetation_for_genre(genre),
            "wildlife": _animals_for_emotion(analysis.get("emotion", "serenity"))
        },
        "topology": {
            "gridSize": 14,
            "blockSize": 20.0,
            "roadWidth": 3.0,
            "layoutType": layout,
            "connectivity": 0.7,
            "terrainRoughness": 0.25
        },
        "architecture": {
            "style": style,
            "material": material,
            "buildingDensity": density,
            "skyscraperRatio": 0.15 if style == "constructivist" else 0.05,
            "blockSubdivisions": 2
        },
        "nature": {
            "terrainRoughness": 0.2,
            "waterPresence": 0.3 if genre in ["poetry", "essay"] else 0.5,
            "treeDensity": 0.35 if genre in ["essay", "poetry"] else 0.2,
            "vegetationType": analysis.get("vegetation", "deciduous"),
            "parkRatio": 0.2 if genre in ["essay", "poetry", "dialogue"] else 0.1
        },
        "life": {
            "timeOfDay": _time_for_atmosphere(atmosphere),
            "fogDensity": 0.4 if atmosphere in ["dusk", "midnight", "fog"] else 0.15,
            "windSpeed": 0.6 if atmosphere in ["dusk", "night"] else 0.3,
            "particleType": particle_type,
            "particleCount": {"dust": 60, "ash": 40, "snow": 100, "leaves": 80, "rain": 200, "sparks": 30, "embers": 50}.get(particle_type, 60)
        }
    }

def _genre_to_city_type(genre: str) -> str:
    mapping = {
        "essay": "village", "poetry": "garden", "dialogue": "agora",
        "manifesto": "fortress", "treatise": "academy", "critique": "labyrinth",
        "autobiography": "estate"
    }
    return mapping.get(genre, "city")

def _shape_for_style(style: str) -> str:
    shapes = {
        "classical": "column", "baroque": "dome", "brutalist": "monolith",
        "minimal": "plane", "organic": "branch", "deconstructivist": "shard",
        "neo_gothic": "spire", "constructivist": "block"
    }
    return shapes.get(style, "column")

def _time_for_atmosphere(atm: str) -> str:
    times = {"dusk": "dusk", "night": "night", "midnight": "midnight",
             "dawn": "dawn", "day": "day", "golden_hour": "golden_hour",
             "fog": "dusk"}
    return times.get(atm, "dusk")

def _vegetation_for_genre(genre: str) -> str:
    veg = {"essay": "high", "poetry": "abundant", "dialogue": "moderate",
           "manifesto": "sparse", "treatise": "moderate", "critique": "sparse",
           "autobiography": "high"}
    return veg.get(genre, "moderate")

def _animals_for_emotion(emotion: str) -> list:
    """Возвращает типы животных под настроение"""
    animals = {
        "hope": ["bird", "deer"], "despair": ["rat", "crow"],
        "rage": ["wolf", "eagle"], "serenity": ["swan", "butterfly"],
        "melancholy": ["cat", "snake"], "anxiety": ["rat", "spider"],
        "ecstasy": ["parrot", "dolphin"]
    }
    return animals.get(emotion, ["bird", "deer"])

# ===== LLM API INTEGRATION (опционально) =====

def analyze_with_llm(text: str, api_key: str = None) -> dict:
    """Если есть API ключ — используем LLM для более точного анализа"""
    # Пока только heuristics — LLM модуль опционален
    return analyze_text(text)

# ===== CLI =====

def main():
    parser = argparse.ArgumentParser(description="PDF book → City of Thought JSON preset")
    parser.add_argument("pdf", help="Path to PDF file")
    parser.add_argument("--author", default="Unknown", help="Book author")
    parser.add_argument("--title", default="Untitled", help="Book title")
    parser.add_argument("--year", type=int, default=1900, help="Publication year")
    parser.add_argument("-o", "--output", help="Output JSON path")
    args = parser.parse_args()
    
    print(f"Processing: {args.pdf}")
    
    # Extract
    text = extract_text_from_pdf(args.pdf)
    print(f"  Extracted {len(text)} chars")
    
    # Analyze
    analysis = analyze_text(text)
    print(f"  Analysis: {json.dumps(analysis, indent=2, ensure_ascii=False)}")
    
    # Build preset
    preset = build_preset(analysis, args.title, args.author, args.year)
    
    # Save
    safe_title = re.sub(r'[^\w\-_\.]', '_', args.title.lower())[:40]
    output = args.output or f"/home/akuta/city-of-thought/godot-city-extracted/presets/{safe_title}.json"
    os.makedirs(os.path.dirname(output), exist_ok=True)
    
    with open(output, 'w', encoding='utf-8') as f:
        json.dump(preset, f, indent=2, ensure_ascii=False)
    
    print(f"  Saved: {output}")
    
    # Print summary
    print("\n=== CITY PREVIEW ===")
    bw = preset["book_to_world"]
    print(f"  City Type: {bw['city_type']}")
    print(f"  Style: {bw['building_style']} ({bw['material']})")
    print(f"  Time: {bw['time_of_day']} | Atmosphere: {bw['atmosphere']}")
    print(f"  Layout: {preset['topology']['layoutType']}")
    print(f"  Density: {preset['architecture']['buildingDensity']}")
    print(f"  Trees: {preset['nature']['vegetationType']} ({preset['nature']['treeDensity']})")
    print(f"  Particles: {preset['life']['particleType']}")

if __name__ == "__main__":
    main()
