# Аудит безопасности — 2026-11-08 (read-only, src/ не менялся)

Вывод: архитектура сервер-авторитетная, критичных дыр (подмена валюты/дюп через ремоуты) не найдено.
Почти все ремоуты имеют rate limit и проверку типов. Остались средние риски вокруг антителепорта и ивент-пикапов.

## Карта ремоутов
| Remote | Файл | Валидация | Rate limit |
|---|---|---|---|
| GameAction | GameServer.server.luau:220 | type(kind), arg по ветке; SetEquipped проверяет owned | 0.15 с |
| GameIndexClaim | GameServer:274 | int + Config.Eggs, флаг IndexClaimed | 1 с |
| buy | GameServer:355 | kind/zoneId/eggId/amount, дистанция, монеты | 12/с + PurchaseCooldown |
| DailyRewardClaim (RF) | DailyRewards.server.luau:7 | без аргументов, серверное время | 0.5 с |
| TokenShop (RF) | TokenShop.server.luau:42 | arg string, whitelist | 0.3 с |
| WorldTeleport (RF) | WorldTeleport.server.luau:147 | id, уровень, цена, QuestGate | 3 с |
| QuickTravel (RF) | PassPerks.server.luau:246 | index number, пасс, мир куплен | 2 с |
| PetMachines fuse | PetMachines.server.luau:270 | int, дистанция, мир | 0.3 с |
| Rebirth | Rebirth.server.luau:215 | без аргументов | 2 с |
| QuestLine | QuestLine.server.luau:406 | action=="claim" | CLAIM_COOLDOWN |
| TradeRemote | Trading.server.luau:156 | validCode, free(), clamp | 0.12 с |
| RushShoot | CoinRush.server.luau:1031 | фаза и патроны на сервере | 0.17 с |

Instance через ремоуты не передаются. ProcessReceipt идемпотентен (Save_Receipts + DataStore + немедленное сохранение).

## КРИТИЧНО
Не найдено.

## ВАЖНО

1. Анти-телепорт не защищает ивент-пикапы (LocalEvents.server.luau:168-176 и 254-262; FrozenEvent.server.luau:148-158)
   - Проверка скачков и blockedUntil есть только в цикле сбора монет (GameServer.server.luau:935-972). Пикапы ивентов
     берутся по Touched (<=12 студов) и магнитом без проверки блокировки.
   - Сценарий: эксплойтер телепортом обходит все пикапы за секунды. Лимит Cap на игрока ограничивает ущерб
     (8 кристаллов / E.Cap), но награда идёт мгновенно и вне геймплея.
   - Фикс: при срабатывании чита писать p:SetAttribute("CheatBlockedUntil", now+3); в give() LocalEvents и в
     Touched FrozenEvent: if (p:GetAttribute("CheatBlockedUntil") or 0) > os.clock() then return false end.
     Плюс минимальный интервал между подборами (~0.4 с на игрока).

2. Лимит скорости считается от клиентского WalkSpeed (GameServer.server.luau:948)
   - speed = h.WalkSpeed*2+60. WalkSpeed реплицируется от владельца персонажа: эксплойтер ставит 500, лимит растёт
     вместе с ним, спидхак проходит проверку.
   - Фикс: считать лимит от серверного значения (PlayerSystems: уровень + зелья + пассы), а не из Humanoid; либо каждый
     тик сравнивать h.WalkSpeed с серверным, при превышении возвращать значение и ставить strike.

3. Окно ServerTP 3 с прощает любые скачки (GameServer.server.luau:951; WorldTeleport:139; PassPerks:276)
   - После легального ТП (QuickTravel раз в 2 с, мир раз в 3 с) любые скачки не наказываются, только пауза сбора 1 с.
   - Фикс: вместе с ServerTP ставить ServerTPTarget (Vector3) и прощать скачок, только если новая позиция в радиусе
     ~30 студов от цели.

4. Обмен: сохранение не ожидается (Trading.server.luau:146-153)
   - Обмен атомарен, но сохранение запускается task.spawn(pcall, ...) и не ждётся. Падение сервера до сохранения у
     одного игрока откатит обмен, у другого он останется: дюп питомца.
   - Фикс: перед close() дождаться SaveProfileNow для обоих (с таймаутом), при сбое логировать; опционально журнал
     обменов в отдельном DataStore.

## МЕЛОЧИ

5. GameAction equip (GameServer.server.luau:224): значение вставляется в список до проверки владения; SetEquipped
   отфильтрует, но лучше сразу if owned(p,arg) <= 0 then return end. Ветка title вызывает t.Has(p) от клиентского
   ввода — убедиться, что это не тяжёлая функция.

6. Апгрейд "max" (GameServer:438) — цикл до 250 итераций за запрос; ограничено rate limit 12/с и интерактом,
   допустимо.

7. DevMax.server.luau: возврат при not IsStudio (строка 9) — в live не работает. GameConfig.luau:21
   DevMaxInStudio=true — не забыть, что команды /coins /max доступны любому игроку в Studio team-test.
   Фикс: добавить проверку p.UserId == game.CreatorId.

8. Monetization.server.luau:234-246 (starter): повторный чек выдаёт набор снова — для идемпотентности это обеспечено
   Save_Receipts, но UI должен блокировать кнопку при Save_StarterBought, иначе игрок заплатит за повтор.

9. Trading request (Trading.server.luau:162-181): 3 с кулдаун только на пару, а один игрок может рассылать запросы
   разным целям (~8/с по общему лимиту 0.12 с) — спам всплывающими окнами. Фикс: общий кулдаун request 2 с.

10. RemoteFunction от клиента (DailyRewardClaim, TokenShop, WorldTeleport, QuickTravel): только OnServerInvoke,
    InvokeClient не используется — подвесить сервер нельзя. Оставить.

## Проверено без замечаний
Покупки яиц (amount 1/3/9, пасс Hatch9, дистанция, кулдаун вылупления), апгрейды (серверная цена и ZoneMax),
магазин магнитов (порядок тиров, мир продажи, potion отклоняется), Daily (нет yield между проверкой и наградой),
Rebirth, QuestLine (шаг сдвигается до выдачи), PetMachines, IndexClaim (флаг до выдачи), RushShoot,
PromptGamePassPurchaseFinished (серверное событие), пассы/продукты с Id=0 игнорируются.

## Приоритет
1) п.2 (WalkSpeed), 2) п.1 (пикапы ивентов), 3) п.4 (сохранение обмена), затем п.3 и мелочи.
