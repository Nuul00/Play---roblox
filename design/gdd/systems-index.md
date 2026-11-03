# Список систем CoinSprint

**Version**: 0.1
**Last Updated**: 2026-11-02
**Author**: Claude (`/reverse-document`)
**Status**: Draft

Все GDD восстановлены по коду. Пометки внутри: `[ИЗ КОДА]` — так работает сейчас, `[НУЖЕН ВАШ ОТВЕТ]` — решение за командой.

| # | Система | GDD | Статус кода | Главные файлы | Зависит от |
|---|---|---|---|---|---|
| 1 | Экономика монет и прокачка киоска | [economy-gdd.md](economy-gdd.md) | реализовано | `GameConfig`, `GameServer`, `PlayerSystems` | 2, 3, 4, 5, 6, 7 |
| 2 | Яйца, питомцы и индекс | [eggs-pets-gdd.md](eggs-pets-gdd.md) | реализовано | `GameConfig`, `GameServer`, `PlayerSystems`, `ShopUI`, `InventoryUI`, `PetIndex` | 1, 3, 6, 7 |
| 3 | Магниты в руке и зелья | [shop-items-gdd.md](shop-items-gdd.md) | реализовано | `ShopConfig`, `MagnetVisuals`, `PlayerSystems`, `ShopPanels` | 1, 6, 7 |
| 4 | Ребёрт | [rebirth-gdd.md](rebirth-gdd.md) | реализовано | `Rebirth.server`, `RebirthUI` | 1, 6, 7 |
| 5 | Ежедневные награды и достижения | [rewards-gdd.md](rewards-gdd.md) | реализовано | `DailyConfig`, `DailyRewards.server`, `DailyUI`, `ShopConfig.Badges` | 1, 3, 7 |
| 6 | Миры и телепорт | [worlds-gdd.md](worlds-gdd.md) | 3 мира готовы, 2 «coming soon» | `WorldsConfig`, `WorldTeleport.server`, `SkyIsles`, `Pond` | 1 |
| 7 | Данные игрока и лидерборды | [player-data-gdd.md](player-data-gdd.md) | реализовано | `WorldProgress.server` | все |

## Без отдельного GDD
| Что | Файлы | Почему |
|---|---|---|
| HUD и общий интерфейс | `GameHUD`, `MainHUD`, `MenuIcons` | описан в разделах «Player-Facing UI» каждой системы; отдельный UI-документ можно сделать через `/ui-design` |
| Визуал и окружение | `ThemedVisuals`, `NeonVisuals`, `SunsetVisuals`, `PetVisuals`, `*FX.client`, `Environment.server`, `PortalArt.server`, `PortalDecor`, `PortalModels.server`, `GlowFX.client`, `CloudPortalStyle.server`, `AvatarPose` | оформление, не игровая логика |
| Монетизация | — | в коде нет `MarketplaceService`: геймпассов и платных товаров пока нет |

## Порядок зависимостей
```
Данные игрока (7)
  └─ Экономика (1) ← Миры (6)
       ├─ Яйца и питомцы (2)
       ├─ Магниты и зелья (3)
       ├─ Ребёрт (4)
       └─ Награды (5)
```
