# Полный каталог объектов City of Thought

---

## 1. ТЕРРАИН (Terrain)

| Объект | Godot меш | Когда появляется |
|--------|-----------|-----------------|
| Ground plane | PlaneMesh (displaced) | Всегда |
| Hill / Холм | Noise displacement | terrainRoughness > 0.1 |
| Mountain peak / Гора | CylinderMesh (cone) | Высота > порог, края |
| Mountain range / Хребет | CylinderMesh × N | terrainRoughness > 0.4 |
| Snow cap / Снежная шапка | CylinderMesh (small) | Высота > 80% max |
| Cliff / Утёс | Steep displacement | Граница океана |
| Valley / Долина | Erosion channel | Река протекла |
| Plateau / Плато | Flat area на высоте | waterPresence низкий |
| Cave entrance / Пещера | Negative space | dead vegetation |
| Island / Остров | Isolated high area | waterPresence > 0.5 |
| Peninsula / Полуостров | Connected to mainland | organic layout |

---

## 2. ВОДА (Water)

| Объект | Godot меш | Когда появляется |
|--------|-----------|-----------------|
| River / Река | BoxMesh segments | waterPresence > 0 |
| Stream / Ручей | Thin BoxMesh | waterPresence > 0.2, горы |
| Lake / Озеро | CylinderMesh (flat) | waterPresence > 0.2 |
| Pond / Пруд | Small CylinderMesh | park, случайно |
| Canal / Канал | BoxMesh straight | grid layout, waterPresence > 0.3 |
| Fountain / Фонтан | CylinderMesh + particles | radial layout, центр |
| Well / Колодец | CylinderMesh deep | organic layout |
| Waterfall / Водопад | Particles falling | Горы + река |
| Spring / Родник | Small sphere | coniferous forest |
| Ocean / Океан | Large PlaneMesh | continent_mode, края |
| Marsh / Болото | Flat area + particles | dead vegetation, низинка |

---

## 3. ДОРОГИ (Roads)

| Объект | Godot меш | Когда появляется |
|--------|-----------|-----------------|
| Highway / Магистраль | BoxMesh wide | grid, каждые 3 клетки |
| Street / Улица | BoxMesh medium | grid, остальные |
| Alley / Переулок | BoxMesh narrow | connectivity > 0.5 |
| Path / Тропа | BoxMesh thin | parks, между зданиями |
| Bridge / Мост | BoxMesh + cylinders | река + дорога |
| Stairs / Лестница | BoxMesh steps | Δheight > 3м |
| Archway / Арка | CSGCombiner | между двумя зданиями |
| Gate / Ворота | CylinderMesh × 2 | граница районов |
| Pavement / Тротуар | PlaneMesh | вдоль зданий |
| Crosswalk / Переход | Striped plane | intersections |
| Boardwalk / Набережная | BoxMesh elevated | вдоль реки |
| Tunnel / Туннель | Arch through hill | mountain + road |

---

## 4. ЗДАНИЯ (Buildings)

### Типы по главе

| Тип | Высота | Условие | Символ |
|-----|--------|---------|--------|
| Monument / Монумент | 120-160% max | is_monument | Ключевая идея |
| Skyscraper / Небоскрёб | 80-100% max | skyscraperRatio | Фундаментальная концепция |
| Academy / Академия | 70-90% max | concept = "school"/"uni" | Образование |
| Chapel / Часовня | 50-70% max | concept = "religion" | Духовность |
| Villa / Особняк | 60-80% max | blockSubdivisions = 1 | Единая тема |
| Pavilion / Беседка | 2-5 | dialogue, pages < 10 | Беседа |
| Ruin / Руины | 20-40% max | concept = "destruction" | Отвергнутая идея |
| Scaffold / Леса | 30-50% max | concept = "future" | Незавершённая мысль |
| Library / Библиотека | 80-100% | references > 5 | Литература |
| Tower / Башня | 90-120% | single idea, deep | Апогей |
| Dome / Купол | 60-80% | synthesis chapter | Синтез |
| Hut / Хижина | 10-20% | essay, simple | Простота |

### Архитектурные детали

| Деталь | Меш | Где |
|--------|-----|-----|
| Roof / Крыша | Prism/Dome/Cone/Flat | Верх здания |
| Window / Окно | BoxMesh, emission | Фасад |
| Door / Дверь | BoxMesh | Основание |
| Column / Колонна | CylinderMesh | classical monument |
| Pillar / Столб | CylinderMesh | gate, entrance |
| Balcony / Балкон | BoxMesh | baroque, brutalist |
| Stairs (ext) / Лестница | BoxMesh × N | elevated entrance |
| Fence / Забор | BoxMesh thin | villa boundary |
| Wall / Стена | BoxMesh | fortress |
| Arch / Арка | CSGCombiner | classical, neo_gothic |
| Lintel / Перекладина | BoxMesh | door top |
| Buttress / Контрфорс | BoxMesh angled | gothic |
| Gargoyle / Гаргулья | SphereMesh distorted | gothic |
| Volute / Волюта | TorusMesh | baroque |
| Cornice / Карниз | BoxMesh projecting | baroque |
| Pediment / Фронтон | PrismMesh | classical |
| Dome window / Окулус | CylinderMesh | dome top |
| Spire / Шпиль | ConeMesh | neo_gothic |
| Antenna / Антенна | CylinderMesh thin | constructivist |
| Flag / Флаг | PlaneMesh | constructivist, manifesto |
| Scaffolding / Леса | GridMesh | deconstructivist, ruin |
| Ivy / Плющ | TorusMesh chain | organic, old buildings |
| Moss / Мох | Noise on material | old stone |
| Cracks / Трещины | Normal map | deconstructivist, ruin |
| Graffiti / Граффити | Decal | dead vegetation |

---

## 5. РАСТИТЕЛЬНОСТЬ (Vegetation)

### Деревья

| Тип | Меш | Когда |
|-----|-----|-------|
| Oak / Дуб | Cylinder + Sphere crown | deciduous, large |
| Pine / Сосна | Cylinder + 3 cones | coniferous |
| Palm / Пальма | Cylinder + 6 leaves | palm, tropical |
| Dead tree / Мёртвое дерево | Cylinder thin + branches | dead |
| Crystal tree / Кристалл | Cylinder + PrismMesh | crystalline |
| Birch / Берёза | Thin trunk + light crown | deciduous, cold |
| Willow / Ива | Cylinder + hanging branches | water edge |
| Cypress / Кипарис | Tall cone | coniferous, Mediterranean |

### Кусты и малые формы

| Объект | Меш | Когда |
|--------|-----|-------|
| Bush / Куст | SphereMesh small | parks, building edges |
| Hedge / Живая изгородь | BoxMesh | road edges |
| Flower / Цветок | SphereMesh tiny | parks, spring |
| Grass patch / Трава | PlaneMesh / Kenney | everywhere |
| Wheat field / Пшеница | PlaneMesh + lines | farm areas |
| Vine / Лиана | TorusMesh chain | organic, walls |
| Moss / Мох | Noise texture | old stone, shade |
| Mushroom / Гриб | SphereMesh + Cylinder | forest floor |
| Fern / Папоротник | PlaneMesh × 3 | shade, moist |
| Reed / Тростник | CylinderMesh thin | water edge |
| Lily pad / Кувшинка | Circle plane | pond |
| Cactus / Кактус | CylinderMesh + spheres | palm, dry |

### Ландшафтные формы

| Объект | Меш | Когда |
|--------|-----|-------|
| Garden / Сад | Arranged flowers + paths | poetry, rousseau |
| Park / Парк | Clusters of trees + benches | parkRatio > 0 |
| Forest / Лес | Dense tree clusters | treeDensity > 0.5 |
| Grove / Роща | 5-10 trees together | deciduous |
| Jungle / Джунгли | Overlapping palms + vines | palm, high density |
| Swamp / Болото | Dead trees + fog | dead + water |
| Meadow / Луг | Grass + flowers | low density, flat |
| Rock / Камень | Dodecahedron | rough terrain |
| Boulder / Валун | Icosphere | mountains |
| Pebbles / Галька | Small spheres | river bank |
| Sand dune / Дюна | Displaced plane | palm, edge |

---

## 6. ЖИВОТНЫЕ (Animals)

### Наземные

| Животное | Меш | Где | Символ |
|----------|-----|-----|--------|
| Cat / Кот | Capsule + tail | roofs, alleys | Самостоятельная мысль |
| Dog / Собака | Capsule + tail | streets | Преданность идее |
| Deer / Олень | Capsule + horns | parks, forest | Невинность |
| Rabbit / Кролик | Sphere + ears | meadows, parks | Страх, бегство |
| Squirrel / Белка | Capsule + torus tail | deciduous trees | Проворство |
| Fox / Лиса | Capsule + snout | forests, dusk | Хитрость |
| Wolf / Волк | Capsule | coniferous, night | Опасность |
| Bear / Медведь | Large capsule | coniferous, mountains | Сила |
| Horse / Конь | Capsule × 2 + legs | squares, roads | Прогресс |
| Cow / Корова | Large capsule | meadows, farms | Мирность |
| Sheep / Овца | Fluffy spheres | meadows | Конформизм |
| Pig / Свинья | Capsule | farms | Телесность |
| Rat / Крыса | Small capsule | dead, ruins | Разложение |
| Spider / Паук | Sphere + 8 cylinders | dark corners | Сеть связей |
| Snake / Змея | Chain of spheres | organic, warm | Трансформация |
| Frog / Лягушка | Sphere | ponds, water | Преображение |

### Летающие

| Животное | Меш | Где | Символ |
|----------|-----|-----|--------|
| Bird / Птица | Sphere + 2 wings | sky, monuments | Свобода |
| Owl / Сова | Sphere + big eyes | night, libraries | Мудрость |
| Crow / Ворона | Sphere | ruins, dead | Критика, смерть |
| Parrot / Попугай | Capsule | palm, tropical | Яркость |
| Butterfly / Бабочка | Body + 2 wings | flowers, gardens | Душа |
| Moth / Моль | Body + 2 wings | night, lamps | Истлевание |
| Eagle / Орёл | Large bird | mountains, peaks | Власть |
| Seagull / Чайка | Bird small | ocean edge | Путешествие |

### Водные

| Животное | Меш | Где | Символ |
|----------|-----|-----|--------|
| Fish / Рыба | Capsule horizontal | water | Скрытый смысл |
| Dolphin / Дельфин | Capsule + tail | ocean | Игра |
| Swan / Лебедь | Bird large | lakes | Красота |
| Duck / Утка | Bird small | ponds | Простота |
| Turtle / Черепаха | Dome + 4 legs | water edge | Мудрость |
| Crab / Краб | BoxMesh + 6 legs | ocean edge | Защита |

---

## 7. ЖИТЕЛИ (Citizens)

| Тип | Внешность | Где | Символ |
|-----|-----------|-----|--------|
| Scholar / Учёный | Hat + glasses + book | libraries, academies | Знание |
| Monk / Монах | Robe + shaved head | chapels, neo_gothic | Молитва |
| Child / Ребёнок | Small size | parks, schools | Новая идея |
| Elder / Старец | White hair + cane | classical areas | Традиция |
| Wanderer / Странник | Cloak + staff | roads, edges | Чужая мысль |
| Worker / Рабочий | Cap + overalls | constructivist | Труд |
| Aristocrat / Аристократ | Top hat + cane | baroque areas | Привилегия |
| Rebel / Бунтарь | Bandana + flag | manifesto | Протест |
| Dreamer / Мечтатель | Looking up | poetry areas | Воображение |
| Bureaucrat / Бюрократ | Grey suit | kafka areas | Механизм |
| Peasant / Крестьянин | Simple clothes | essay areas | Земля |
| Merchant / Торговец | Bag + scales | grid intersections | Обмен |
| Artist / Художник | Beret + palette | organic areas | Творчество |
| Soldier / Солдат | Uniform + rifle | manifesto areas | Власть |

### Декор на жителях

| Объект | Меш | Когда |
|--------|-----|-------|
| Hat / Шляпа | CylinderMesh | 50% citizens |
| Bag / Сумка | BoxMesh | scholars, merchants |
| Book / Книга | BoxMesh small | scholars, monks |
| Lantern / Фонарь | CylinderMesh + emission | night, wanderers |
| Cane / Трость | CylinderMesh | elders |
| Umbrella / Зонт | ConeMesh | rain |
| Backpack / Рюкзак | BoxMesh | travelers |
| Basket / Корзина | CylinderMesh | peasants, markets |

---

## 8. ИНФРАСТРУКТУРА (Infrastructure)

| Объект | Меш | Где | Символ |
|--------|-----|-----|--------|
| Street lamp / Фонарь | Pole + sphere + light | roads | Просвещение |
| Bench / Скамейка | BoxMesh | parks, roads | Отдых |
| Signpost / Указатель | Pole + board | intersections | Навигация |
| Clock tower / Часовая башня | Box + spire | radial center | Время |
| Statue / Статуя | Cylinder / obelisk | monuments | Герой |
| Obelisk / Обелиск | Tall prism | classical square | Вечность |
| Tombstone / Надгробие | Small prism | dead areas | Утрата |
| Book stand / Стенд | Box + shelf | libraries | Доступ |
| Water pump / Насос | Cylinder + handle | village | Жизнь |
| Well / Колодец | Cylinder deep | organic | Источник |
| Fountain (small) / Фонтан | Cylinder + particles | parks, squares | Изобилие |
| Market stall / Лоток | Box + awning | grid centers | Торговля |
| Well cover / Колодезный домик | Box + roof | village | Защита |
| Gazebo / Беседка | 4 columns + roof | parks | Беседа |
| Trellis / Шпалера | Grid + vines | gardens | Рост |
| Sundial / Солнечные часы | Plane + rod | classical | Время |
| Bell / Колокол | Sphere + striker | neo_gothic | Тревога |
| Cannon / Пушка | Cylinder + wheels | fortress | Война |
| Chains / Цепи | TorusMesh | brutalist | Оковы |
| Barricade / Баррикада | Boxes | manifesto | Сопротивление |
| Scaffold / Строительные леса | Grid | critique | Незавершённость |

---

## 9. АТМОСФЕРА (Atmosphere)

### Освещение

| Объект | Тип | Где |
|--------|-----|-----|
| Sun / Солнце | DirectionalLight3D | day, golden_hour |
| Moon / Луна | DirectionalLight3D dim | night, midnight |
| Stars / Звёзды | Points / billboard | night |
| Street light glow / Уличный свет | OmniLight3D | вечер, ночь |
| Window glow / Свет окон | Emission material | dusk, night |
| Fog light / Туманный свет | SpotLight3D | fog > 0.3 |
| Fire / Огонь | OmniLight3D orange | embers, torches |
| Aurora / Аврора | Plane + emission shader | polar, crystalline |

### Погода

| Объект | Тип | Когда |
|--------|-----|-------|
| Cloud / Облако | Sphere cluster | cloudCoverage > 0 |
| Fog / Туман | Environment fog | fogDensity > 0 |
| Rain / Дождь | CPUParticles3D | rain particles |
| Snow / Снег | CPUParticles3D | snow particles |
| Dust / Пыль | CPUParticles3D | dust particles |
| Ash / Пепел | CPUParticles3D | ash particles |
| Leaves / Листья | CPUParticles3D | leaves particles |
| Sparks / Искры | CPUParticles3D + emission | sparks particles |
| Embers / Угли | CPUParticles3D + emission | embers particles |
| Lightning / Молния | Line + flash | baroque, night |
| Rainbow / Радуга | Arc plane | after rain, poetry |
| Mist / Дымка | Fog low density | dawn, organic |
| Steam / Пар | Particles rising | hot springs, factories |
| Smoke / Дым | Particles dark | chimneys, fires |
| Sandstorm / Песчаная буря | Particles brown | palm, dead |

---

## 10. ЗВУКОВАЯ СРЕДА (Soundscape)

| Объект | Тип | Когда |
|--------|-----|-------|
| Hum / Гул | AudioStreamPlayer | hum, machinery |
| Drone / Бормотание | AudioStreamPlayer | drone, darkness |
| Chime / Звон | AudioStreamPlayer | chime, clarity |
| Silence / Тишина | No audio | silence, minimal |
| Wind / Ветер | AudioStreamPlayer | wind, speed > 2 |
| Machinery / Механизм | AudioStreamPlayer | machinery, factories |
| Bells / Колокола | AudioStreamPlayer | bells, classical |
| Rain sound / Шум дождя | AudioStreamPlayer | rain |
| Birds / Пение птиц | AudioStreamPlayer | day, parks |
| Cicadas / Цикады | AudioStreamPlayer | golden_hour, hot |
| Wolves / Вой волков | AudioStreamPlayer | night, coniferous |
| Waves / Волны | AudioStreamPlayer | ocean edge |
| Footsteps / Шаги | AudioStreamPlayer | citizen proximity |
| Heartbeat / Сердцебиение | AudioStreamPlayer | midnight, kafka |
| Choir / Хор | AudioStreamPlayer | neo_gothic, baroque |

---

## 11. ДЕКОР (Decor)

| Объект | Меш | Где |
|--------|-----|-----|
| Painting / Картина | Plane on wall | baroque, classical |
| Tapestry / Гобелен | Plane + fabric | medieval |
| Bookshelf / Книжная полка | BoxMesh × N | library |
| Globe / Глобус | Sphere | classical, academy |
| Telescope / Телескоп | Cylinder + tripod | observatory |
| Chandelier / Люстра | Chain + lights | baroque, neo_gothic |
| Rug / Ковёр | PlaneMesh | interior |
| Curtain / Занавес | Plane + wave | baroque, neo_gothic |
| Trophy / Трофей | PrismMesh | manifesto |
| Mirror / Зеркало | Plane + metallic | deconstructivist, baroque |
| Skull / Череп | Sphere + details | neo_gothic, dead |
| Candle / Свеча | Cylinder + flame | neo_gothic, night |
| Torch / Факел | Cylinder + particles | ancient, dungeons |
| Flower pot / Цветочный горшок | Cylinder + plant | windows, organic |
| Mailbox / Почтовый ящик | Box + flag | suburban |
| Bicycle / Велосипед | Torus + frame | streets, minimal |
| Wheelbarrow / Тачка | Box + wheel | farms, essay |
| Cart / Повозка | Box + 2 wheels | medieval |
| Ship / Корабль | Hull + mast | ocean edge |
| Boat / Лодка | Small hull | ponds, rivers |
| Bridge ornament / Орнамент моста | Sphere + details | classical bridges |
| Lamp post hanging / Фонарь висючий | Chain + light | neo_gothic |
| Weather vane / Флюгер | Arrow + direction | roof tops |
| Chimney / Труба | Cylinder | brutalist, constructivist |
| Satellite dish / Спутниковая тарелка | Dish | constructivist, future |
| TV antenna / Телеантенна | V-shape | 20th century |
| Clothesline / Верёвка для белья | Line + clothes | essay, organic |
| Trash can / Мусорка | Cylinder | modern |
| Newspaper / Газета | Plane | streets, morning |
| Bench armrest / Подлокотник скамейки | Cylinder | detailed bench |
| Bird nest / Птичье гнездо | Twigs | tree tops |
| Spider web / Паутина | Lines | dead trees, corners |
| Footprints / Следы | Decal | snow, mud |
| Wheel tracks / Колея | Decal | roads, mud |
| Puddle / Лужа | Circle plane | after rain |
| Ice / Лёд | Transparent plane | winter, crystalline |
| Snow pile / Сугроб | Dodecahedron | winter |
| Fallen leaves / Опавшие листья | Planes | autumn, deciduous |
| Fallen branch / Упавшая ветка | Cylinder | forest |
| Mushroom ring / Кольцо грибов | Circle of spheres | meadows, fairy |
| Fairy ring / Сказочное кольцо | Particles circle | poetry, mystical |

---

## ИТОГО: 200+ объектов

| Категория | Количество |
|-----------|-----------|
| Терраин | 12 |
| Вода | 12 |
| Дороги | 13 |
| Здания (типы) | 13 |
| Арх. детали | 20 |
| Деревья | 8 |
| Кусты/малые формы | 13 |
| Ландшафтные формы | 10 |
| Наземные животные | 16 |
| Летающие животные | 8 |
| Водные животные | 7 |
| Жители (типы) | 15 |
| Декор на жителях | 8 |
| Инфраструктура | 20 |
| Освещение | 8 |
| Погода | 15 |
| Звуковая среда | 15 |
| Декор | 30 |
| **ИТОГО** | **~233** |
