# Sunset Sky Egg

First island egg only; other eggs keep their catalog, prices and models.
Sunset shell and nine companion models are authored in `SunsetVisuals.luau`
using Roblox parts as 3D interpretations of the supplied artwork.

| Pet | Rarity | Chance | Coins |
|---|---|---:|---:|
| Cloud Puff | Common | 30% | ×1.2 |
| Sunset Bunny | Common | 25% | ×1.3 |
| Dusk Kitty | Uncommon | 18% | ×1.5 |
| Amber Deer | Uncommon | 12% | ×1.7 |
| Twilight Unicorn | Rare | 7% | ×2.2 |
| Rosy Sky Whale | Rare | 5% | ×2.6 |
| Sunset Dragon | Epic | 2% | ×3.5 |
| Dawn Phoenix | Legendary | 0.5% | ×8 |
| Celestial Castle | Legendary | 0.5% | ×10 |

Price remains 50 coins. Triple opening costs 150, with three independent rolls.
The table shows base chances; an active luck potion keeps the stronger of two
rolls for each individual egg, as before.

Every egg now offers OPEN ×1 / OPEN ×3. Tap KEEP on a pet card to enable
AUTO-DELETE for future hatches of that species; tap again to keep them.
Existing inventory is never removed by this preference. Auto-deleted hatches
still count towards eggs opened but do not equip or add pets to inventory.
Preferences are saved with published-game profiles; local Studio sessions reset.

Existing IDs 1–6 become the first six sunset pets. Their inventory counts and
equipment remain attached to those IDs. The three extra pets use IDs 37–39;
all other eggs retain IDs 7–36. No saved counts are discarded.

Source changes sync through the connected Rojo session. Launch F5 again to see
the updated shell, models and UI. The shell is constructed on server startup.
`tests/SunsetEggsPlaytest.client.luau` exercises the real purchase remotes in a
disposable local Studio playtest. Do not run the funded test on a live server.

Validation: local Studio playtest passed all 600,000 integer rolls, 39 model
constructors, triple purchases for all six eggs, exact prices and inventory
counts, auto-delete toggles and rejection of hatch amount 2. Cloud profile
persistence was not exercised in Studio (DataStores disabled in config).
