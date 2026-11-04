# Журнал решений

- 2026-11-02 — По прямому указанию владельца все дальнейшие изменения сохранять в текущий Roblox-мир «Untitled Experience», placeId 80725943753433. Это основной рабочий мир; новые отдельные rbxl-копии вместо него не создавать. Сохранение текущих изменений в этот мир подтверждено Roblox Studio.

- 2026-11-02 — Второй мир: Disco Grid, Tech Core и City Lights, по 10 именованных питомцев с референса (на арте подпись «9», но изображено 10). Шансы 30/24/18/12/7/5/2/1/0.9/0.1%, цены прежние. Новые ID 46–57, исходные ID и каталог первого мира сохранены. Детализированные модели из локальной геометрии в NeonVisuals; список яйца и индекс прокручиваются.

- 2026-11-02 — Первое яйцо острова — Sunset Sky Egg: 9 питомцев (2 Common, 2 Uncommon, 2 Rare, 1 Epic, 2 Legendary), 30/25/18/12/7/5/2/0.5/0.5%. Остальные яйца сохраняют состав. Для всех яиц — открытие ×1/×3 и сохраняемый выбор автоудаления будущих выпадений по виду питомца. Модели заката собраны из деталей по пользовательскому арту.

Формат: дата — решение — почему.

- 2026-11-01 — Задачи ведём в GitHub Issues + доске Projects, код только через PR — чтобы два человека и два Claude не мешали друг другу.
- 2026-11-01 — Яйца: у каждого 4 своих питомца (24 разные модели из PetAssets, Galaxy Phoenix — собранный из деталей), дороже яйцо — сильнее питомцы и выше шанс редких; цены 50 / 250 / 1000 и 2500 / 10000 / 50000 — чтобы яйца не повторяли друг друга и прогресс чувствовался.
- 2026-11-01 — Меню яйца открывается касанием яйца, без подсказки E; яйца ~7.5 студа высотой, к каждому ведёт тропинка от EggPath — так попросил владелец проекта.
- 2026-11-01 — Карта правится прямо в общем Team Create-плейсе; tools/create-landscape.mjs больше не источник правды для мира (киоск из Toolbox, кусты убраны вручную).
- 2026-11-01 — Питомцы берутся из паков пользователя: нужные модели скопированы в ReplicatedStorage.PetModels, сами паки лежат в ServerStorage.PetPacks (не грузятся в игру). В каждом яйце 6 питомцев одной серии: Common → Secret.
- 2026-11-01 — Дорожки — материал ландшафта Cobblestone: поверхность рельефа выше деталей-дорожек, поэтому видно именно ландшафт. Магазин открывается заходом в зелёный круг ShopZone.
- 2026-11-01 — Индекс питомцев — отдельная книга (PetIndex.client.luau): невыбитые питомцы чёрными силуэтами, за полную страницу яйца награда Cost×20 монет (GameIndexClaim, сохраняется в профиле).
- 2026-11-01 — Время суток (день/вечер/ночь) выбирает каждый игрок в настройках; меняется только у него на экране.
- 2026-11-01 — Пьедестал топ-3 по заработанным монетам в обоих мирах (аватары ставит WorldProgress); продавец сидит на стуле (AvatarPose).
- 2026-11-01 — Изменения другого ассистента («Expansion») отменены по просьбе владельца; сохранены в git stash и в папке Игра_backups.
- 2026-11-01 — Команда до 3 питомцев (Equip Best / Unequip All), бонус = 1 + Σ(x−1). Монеты = база × команда × доход × достижения × зелье монет.
- 2026-11-01 — Магниты — Tool в руке (5 видов, магазин магнитов у киоска), радиус = прокачка + бонус магнита в руке. Зелья монет/скорости/удачи на 5 минут. Достижения дают x1.05 каждое.

## Магниты: 20 видов
- 20 магнитов по картинке пользователя собраны из деталей Roblox (MagnetVisuals + Look в ShopConfig): корпус-подкова, наконечники и украшения (кристаллы, крылья, корона, цветы, молнии, кольцо, спираль, радуга).
- Покупка по порядку, цены 0 → 1.5M, бонус радиуса 0 → +23. Вкладка MAGNETS — прокручиваемая сетка 5×4.
- Это приближение из деталей; точные копии артов потребуют MeshPart/3D-моделей.

## Пруд, водопад, неоновый город, табло яиц
- Пруд и ручей строит модуль `ServerScriptService/Pond` при запуске сервера (вода по сетке вокселей 4×4×4, песчаный берег, камни, камыши, кувшинки, мостик, причал, водопад у подножия холма). Плоская деталь `Floor` первого мира невидима и проходима: она закрывала воду.
- Анимации Неонграда (`NeonRoadFX`, `NeonSkyFX`) включаются, когда камера рядом с городом, а не по атрибуту CurrentWorld. Старые скрипты места NeonStreetFX и NeonCityFX удалены (их заменили эти два).
- Прожекторы на всех башнях с маячками: основной луч, два луча-следа и шлейф в небе.
- `EggBillboards`: над каждым яйцом табло с ценой и питомцами (шанс, редкость); яйца парят и крутятся. Подиумы яиц в обоих мирах одного стиля.
- Пьедесталы: номер места и имя победителя на табличке спереди (Plate1..3), без висящих меток.

## Яйца Sakura и Starlight, автооткрытие
- Второе и третье яйцо острова — Sakura Egg (250) и Starlight Egg (1 000), по 9 питомцев. Модели питомцев и яиц собраны из деталей в `ReplicatedStorage/ThemedVisuals`, сервер ставит яйца при запуске (атрибут EggReady).
- Старые ID 7–18 перешли новым питомцам (сохранения целы), новые ID 40–45. Каталог правится в `tools/create-catalog.mjs`, сумма шансов каждого яйца — ровно 100%.
- Шансы: Sakura 32/24/17/12/7.5/4.5/2/0.9 (Legendary)/0.1 (Secret); Starlight 30/24/18/12/8/5/2.3/0.6 (Legendary)/0.1 (Secret); у Sunset последний питомец стал Secret 0.1%, Legendary 0.9%.
- Автооткрытие: кнопка AUTO OPEN в меню яйца, открывает по 3 (или по 1, если на 3 не хватает), пока игрок стоит у яйца и хватает монет; плашка сверху с кнопкой STOP.

## Sky Isles (3-я локация) и UI-правки
- Новый мир Sky Isles (SkyIsles под CoinSpeedWorld, X=1100, Y=300): монеты, магазин прокачек, магазин магнитов, 2 яйца (7/8, питомцы 58-75), радуга, облачные деревья. Требуется Speed 6.
- Магниты 21-25 (SkyOnly), уровни прокачек 11-15 только в небесном магазине; проверка на сервере в GameShopBuy.
- Телепорт: WorldsConfig + WorldTeleport.server (сервер валидирует мир/скорость/кулдаун); окно TELEPORT; порталы Neon <-> Sky.
- Убраны всплывающие тосты об успешных покупках (GameFeedback игнорирует success=true).
- Анимация открытия яиц: прозрачный оверлей, отдельные большие яйца вращаются по очереди (x1 / x3 / auto), без общей панели.
- SkyIslesFX: мягкая атмосфера и страховка от LocalTransparencyModifier > 0 на входе в мир.
- Открытие яиц: чем реже питомец, тем эффектнее — Rare+ яркая вспышка экрана и больше искр, Epic+ вращающиеся лучи, Legendary+ дрожание панели и дольше «напряжение», Secret — радужные искры/заголовок; аура яйца до раскрытия окрашивается в цвет редкости.
- Тосты «Speed/Income/Magnet: …» убраны. Облачный портал в Неонграде приглушается кодом (CloudPortalStyle.server.luau).


## Sky Isles evening redesign, new magnets/eggs, upgrades, rebirth
- Sky Isles rebuilt in code (SkyIsles.luau) to match the art: evening mood, gold neon outline, striped-awning shops with cloud signs, tiered egg podium with a golden arch/star, stepped rainbows, lamps, fences, flowers, pond, crystal islets. Lighting is driven by SkyIslesFX (ClockTime ~18, purple haze). FX also keeps resetting LocalTransparencyModifier on sky parts (cause unknown; parts arrived with it set).
- Sky eggs 7-9 (Cloud, Celestial, Crystal) with 24 new pets (ids 58-81); catalog generated by tools/create-catalog.mjs (re-copy GameConfig.luau via a temp file so Rojo picks it up).
- Magnets 21-30 are SkyOnly (sold in Sky Isles shop). Magnet shop tabs: MAGNETS and POTIONS only (the old upgrade tab was removed).
- Upgrades: speed/magnet/income/double, shown as "LEVEL n / zone cap". Zone caps 10 / 25 / 50 (island / neon / sky); price tier x3 from level 10 and x8 from level 25. Double-coin chance upgrade added.
- Rebirth: Rebirth.server.luau + RebirthUI. Costs 200000 * 3^r, up to 15, +75% coin bonus per rebirth; resets coins, speed (back to level 6), magnet/income/double upgrades; keeps pets, magnets, potions.

## Custom pet meshes
- Own pet models live in src/ReplicatedStorage/CustomPets/Pet<id>.model.json (a Model with a MeshPart whose MeshId/TextureID are rbxassetid values). PetVisuals checks this folder first, then falls back to procedural/library models.
- Pet 1 (Cloud Puff) uses a Tripo model, decimated to 16k triangles with a re-baked 1024 texture (sources in assets/pets/sunset_pet1, uploaded to Roblox from Studio's 3D importer).

## 2026-11-04 — HUD по мирам, гарантия, события

- HUD: картинки из ChatGPT (assets/hud/<мир>) загружены в Roblox, ID в `HudSkins.luau`.
  `HudSkin.client.luau` надевает скин мира поверх GameHUD/MainHUD; меню собрано за кнопкой «≡»
  (3D-окно на SurfaceGui), настройки в правом верхнем углу, панель инструментов Roblox скрыта.
- Магнит всегда в руках; снять/надеть — только в магазине магнитов (атрибут MagnetOff).
- Гарантия: Legendary каждые 100 питомцев, Secret каждые 2000, счётчики общие и в профиле
  (`ShopConfig.Pity`). Прогресс показан на плашке над табло ближайшего яйца.
- Объявление о Legendary+ на весь сервер, кинематографичное открытие, бонус за друзей (+10%, до +50%),
  +5% монет за каждую забранную страницу индекса, мировые события Golden/Lucky Hour.
- Оптимизация SkyIslesFX: 30/20 Гц, отсечение по дистанции, BulkMoveTo (≈25.8 → 20.3 мс/кадр).
