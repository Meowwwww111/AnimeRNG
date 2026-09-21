# AnimeRNG / Starfall RNG — 0.3.0

A source-built, original anime-inspired **3D Roblox prototype**. Models and two worlds are constructed by Luau when the server starts. This is not a finished commercial release; no copyrighted anime models or remote asset scripts are bundled.

## Update and play on Windows

1. Stop **Play** in Studio. Keep Rojo running.
2. In a second terminal in this repository run `git pull --ff-only`.
3. Wait for Rojo to sync, then press **Play** again. The map and models appear during Play, not in Edit mode.
4. To start Rojo later, double-click `START-ROJO.cmd`, or run `.\rojo.exe serve default.project.json` with `rojo.exe` in this folder. The server binds to loopback only.

No new Studio plugin is required. This repository does not give ChatGPT direct control over your PC; you still pull changes, run Studio and report Output errors.

## What is implemented

- **Two physical worlds**: Starfall Village and Eclipse Wastes, with a safe plaza, paths, scenery, summon arches, crafting workbenches, trading arches, shops, portals and boss arenas.
- **Ten original articulated low-poly companions** with different palettes, hair, swords/staves/gauntlets, mantles and high-rarity glowing details. They follow the player, approach enemies, swing their arms/weapons and attack automatically.
- **Six enemy archetypes**: eye-detailed slime, humanoid bandit, ogre, horned demon, large titan and horned Void Devourer. Twenty spawns across both worlds, server-owned HP, movement, melee attacks, respawns and a telegraphed boss area attack.
- Damage numbers, attack streaks, skill pulses, summon/death effects and in-world health/name labels.
- Monster rewards and damage-contribution sharing; companion XP and levels; every fifth companion attack has a damage bonus. World 1's boss unlocks World 2.
- Server-only independent RNG, **no pity**. Base rarity weights total 1,000,000; Starborn Hero has 1/200,000 base odds before bonuses. The live Details panel shows each character's actual normalized chance.
- Stacked character collection, manual equip, automatic selection of a stronger newly rolled unit, and a free starter so players cannot become unable to fight after running out of coins.
- Three one-time permanent luck-crafting tiers, craftable 10-minute potions, and unbound sigils that can be consumed for permanent luck (maximum ten). Collection diversity adds a small earned luck bonus. Existing saved permanent luck is preserved.
- Five claimable milestone quests; no daily-streak punishment or forced purchases.
- Safe-by-default persistence, plus an isolated, session-only Studio mode.
- **Studio session-only trading** of earned materials, earned potions and unbound sigils: invitations, editable offers, server validation, readiness, a 3-second review wait, final confirmations, cancellation, timeout and disconnect handling.
- **Disabled-by-default monetization implementation**: gamepass ownership verification, policy-gated paid luck, dynamic per-outcome odds previews, and receipt-idempotent potion grants. No product IDs or pricing are invented.

## Controls

Walk toward a slime to start automatic companion combat. Monsters can hurt you; move away to retreat. Use the bottom Auto button to stop/start companion attacks.

At a summon arch press **E** (or tap the proximity prompt) to roll for 10 earned coins. Your strongest unit remains equipped. At the workbench press **E** to choose recipes. **B** or Inventory opens your collection. Quests grants earned milestone rewards. Odds displays individual chances. The physical portal unlocks after defeating the World 1 boss.

The old center-screen ROLL/FIGHT SLIME developer panel and client-invoked Attack remote have been removed. UI is secondary to the world, not a simulated fight button.

## Saving and migration

`GameConfig.StudioPersistence=false` means Studio uses fresh, in-memory data. This is intentional: a local test does not touch live saves and works without publishing/API access. Progress in this mode resets when Play stops.

For a separate published test experience, enable Studio API access and set StudioPersistence=true to use `AnimeRNG_Studio_v3`, not the production data store. Published servers use `AnimeRNG_PlayerData_v1` and migrate the old inventory arrays to stacked dictionaries in a versioned envelope, preserving coins, units and permanent luck.

Production loads fail closed: failed reads never become writable default data. Profiles use UpdateAsync session leases, autosaves, release-on-leave, retries and receipt fencing. This custom persistence implementation still needs Roblox multi-server, outage and shutdown testing before public release. Back up production data before schema migrations.

## Trading and purchases — important limits

**Live trading is intentionally unavailable.** Updating two player saves is not an atomic transaction. A durable escrow/journal with idempotent recovery and fault-injection tests is required before live trading or cash items can be enabled. The Studio prototype refuses persistent-data mode as well. Use a two-player local server test with session-only data.

**PurchasesEnabled=false**, **LuckPassId=0**, **LuckPotionProductId=0**. Set genuine IDs only after the monetization review in `docs/RELEASE_CHECKLIST.md`. Passes already activated on an account, paid potions, characters, Robux and bound permanent upgrades are not tradable in this build. The shop has no auto-purchase prompts.

Paid and earned boosts are separate. Restricted accounts use only earned luck; failed policy lookups disable paid luck. A purchase receipt is acknowledged only after its grant and receipt ID are saved together. An ambiguous receipt save fences the session rather than allowing a stale autosave to overwrite the grant. Bought potions become an owned consumable, not an immediately expiring timer.

## Tests and build

`tests/rules.spec.luau` exercises odds, no-pity selection boundaries, migration, crafting, levels and trade validation. `tests/data.spec.lua` uses mocked stores to test load failures, leases, duplicate receipts and fencing. `python tools/check_local.py` runs offline Lua-compatible syntax and mock checks where liblua5.4 is installed; it is **not** a Roblox simulator.

The GitHub Actions workflow compiles the source with pinned upstream Luau, runs the pure Luau tests, and builds a `.rbxlx` using Rojo 7.7.0. It uploads the place as a workflow artifact. Successful compilation/build does not prove Roblox physics, networking, mobile usability or persistence correctness; run the Studio checklist too.

## Still beyond this milestone

Custom skinned meshes, licensed art/audio, uploaded animation assets, production-grade navigation around arbitrary terrain, live trading escrow, cash-item trading, raids, clans, PvP, an endless tower and public-launch balancing are not completed. This update provides the physical gameplay and modular services to extend—not a claim that every future system is finished.
