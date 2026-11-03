# Neon District eggs

All ten named pets from each reference row are included (the artwork's label
says nine, but each row depicts ten). Existing egg prices stay 2,500 / 10,000 /
50,000 coins. Three independent 3D collections are authored in NeonVisuals.

| Chance | Rarity | Disco Grid | Tech Core | City Lights |
|---:|---|---|---|---|
| 30% | Common | Pixel Cat | Core Cat | Skyline Cat |
| 24% | Common | Disco Bunny | Mecha Bunny | City Panda |
| 18% | Uncommon | Neon Raccoon | Security Dog | Metro Fox |
| 12% | Uncommon | Grid Panda | Repair Panda | Street Owl |
| 7% | Rare | Holo Wolf | Drone Fox | Tower Wolf |
| 5% | Rare | Laser Owl | AI Owl | Neon Deer |
| 2% | Epic | Disco Lion | Cyber Lion | Sky Lion |
| 1% | Epic | Synth Shark | Data Shark | Hover Whale |
| 0.9% | Legendary | Cube Dragon | Nano Dragon | Sky Dragon |
| 0.1% | Secret | Matrix Bot | Core Robot | Aerial Bot |

Each column sums to 100%. Luck potions retain their existing two-roll behavior.
Multipliers scale with egg progression, ending at ×105 / ×180 / ×300.
IDs 19–36 are retained for the first six companions of each neon collection;
extra pets use IDs 46–57. Owned counts and equipment referencing existing IDs
are retained. All three island catalogs were compared with the saved baseline
and are unchanged. The original neon species are replaced at their existing IDs.

Disco: mirrored egg tiles, pixel faces, headphones, equalizer lights.
Tech: cyan power cells, armour panels, circuit traces, mechanical details.
City: illuminated skyline, windows, antennae, hover rotor and skyline trims.
Species have distinct ears, antlers, manes, tails, fins, feathers and bat wings.
These are locally authored Roblox geometry interpretations of the supplied art,
not imported meshes from the illustration.

Egg stands retain their positions, interaction zones and pedestals. Construction
happens at server startup; clients wait for EggReady before cloning displays.
The hatch menu and collection book scroll to show the tenth pet. All ten also
fit the billboard in two rows of five. Single/triple hatch and saved auto-delete
preferences continue through the existing server purchase path.

Backup: tools/backups/before-neon-eggs.json contains the exact sources and
catalog from before this change. It can be used to restore individual files.

Tests: NeonEggsPlaytest.client.luau checks all 600,000 weighted outcomes, 57
unique IDs, model construction/bounds, single/triple purchases, exact charges,
auto-delete ON/OFF and invalid batch sizes using real Studio client/server
remotes. NeonReview.client.luau is a temporary visual gallery, not production UI.

Validation completed in local Roblox Studio: all 600,000 rolls and 57 model
constructors passed. Each neon egg passed single/triple pricing and results,
auto-delete ON/OFF, inventory counts, and rejection of amount 2. After visual
refinement, all 57 model bounds and all 3 final shells passed again. Cloud
profile persistence was not exercised (Studio DataStores remain disabled).
