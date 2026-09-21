# 0.4.0 — anime-style presentation and separated worlds

This update supersedes the 0.3.0 README's descriptions of replicated rigs and Eclipse Wastes. It does not change saved character IDs, rarity odds, no-pity behavior, crafting recipes or purchase settings. Purchases and live trading remain disabled.

## What changed

- Ten original companions now use narrower body/head proportions, tapered hair locks, layered eyes/brows, articulated elbows/knees, collars, cuffs, boots, and different uniforms, haori, robes, armor and longcoats. Swords, scabbards, staves, crowns and scarves distinguish silhouettes.
- World 1 is a daylight shrine village with timber/plaster houses, tiled roofs, blossoms, bamboo and a torii-style boss entrance. World 2 is a nighttime obsidian citadel with bastions, battlements, rifts, crystals and a throne arena. Lighting is local to each player's world.
- World 2 is 6,000 studs away. Invisible perimeter barriers and server-owned world assignment enforce access even if a player walks on the original Baseplate, spoofs position or bypasses a portal prompt. A legitimately unlocked player can still enter through the portal. A fresh profile cannot.
- World 1 enemies include slime, shinobi, oni, winged fiend and shrine guardian forms. World 2 uses a floating wisp, closed-helmet sentinel, obsidian brute, scythe reaper, crystal colossus and crowned regent. Encounter stats remain on the existing catalog IDs.
- Server actors now replicate a single invisible root and pose/state attributes rather than moving all visible body parts. Client visuals interpolate snapshots on PreRender; follow motion uses frame-rate-independent smoothing; Motor6D animation updates on PreSimulation. Damage, targeting, rewards and access remain server-owned.
- Off-world and distant cosmetic models are culled. No more than two new visual models are built per render frame. This is an architectural performance change, not a measured FPS guarantee.

## References and source limits

Requested browsing references:
- https://create.roblox.com/store/category/3d/characters?keyword=anime&maxPrice=0
- https://create.roblox.com/store/category/3d

Those category pages did not expose individual model records through the available browser. **No Creator Store asset was downloaded, inspected, licensed, or imported by this patch.** These are still code-built original models, not professional custom skinned meshes.

Official anime character-reference pages consulted for art direction:
- Demon Slayer: https://demonslayer-anime.com/risshihen/character/
- Jujutsu Kaisen: https://jujutsukaisen.jp/character/
- Solo Leveling: https://sololeveling-anime.net/character/

Design influences are general clothing/silhouette ideas: layered swordsman clothing, high-collar uniforms and shadow-knight longcoats. No official character textures, logos, character models, names or downloaded anime art are bundled. These references are not claims of an asset license, affiliation or verified popularity ranking.

Technical references:
- https://create.roblox.com/docs/reference/engine/classes/Motor6D
- https://create.roblox.com/docs/reference/engine/classes/RunService

## Optional reviewed art overrides

Rojo now preserves local contents under `ReplicatedStorage/ArtAssets/Units` and `ReplicatedStorage/ArtAssets/Enemies`. Nothing is inserted from the web during Play.

After verifying a specific model's provenance and permitted use, inspect it in a separate throwaway place before putting sanitized art into your main project. Remove its scripts and packages; an arbitrary store model is not approved merely because it is free. Keep the original asset URL/ID and permission record with your art files.

For a reviewed template:
1. Put a Model in `ArtAssets/Units` named exactly like a catalog ID, for example `FlameDisciple`. Enemy names use `W1_Bandit`, `W2_Bandit`, etc.
2. Set its Boolean attribute `ArtReviewed` to true. A root named `HumanoidRootPart` or `Root`, or a valid PrimaryPart, is required. Match the procedural rig's root height/scale in Studio.
3. The client clones only that local template and strips non-allowlisted descendants before parenting. Scripts, modules, remotes, packages, audio and physics helpers are not carried over. External joint references are removed; disconnected geometry is welded. Templates over 180 parts fall back to the procedural model.
4. This adapter is a **static visual override**, not an automatic R6/R15 retargeter. An imported rig follows/moves with its actor, but uploaded animation IDs, artist-approved clips and retargeting are not configured. The built-in original rigs have procedural walk/attack animation.

`ArtReviewed` is your explicit review flag, not an automated malware or copyright certification. The sanitizer is defense in depth, not permission to insert untrusted scripts into your working place. Locally inserted art is not backed up by Git automatically: export reviewed models into a versioned art workflow before relying on them.

## Pull and play

Stop Play and stop the existing Rojo server with Ctrl+C. In the repo run:

```powershell
git pull --ff-only
.\rojo.exe serve default.project.json
```

Reconnect Rojo in Studio if necessary, accept the reviewed sync changes, and press Play. Restarting the server ensures the new `Presentation` LocalScript and preserved art folders are mapped. Do not copy only ModelFactory: this is a coordinated server/client update.

## Verification performed and remaining

The offline checks exercise interpolation/bounds rules and construct all ten companions plus six enemy types in both worlds using a lightweight Roblox API mock. They check hierarchy, rest-frame joint alignment, noncolliding geometry, budgets, template sanitization, locked travel and out-of-bounds recovery. The syntax runner uses Lua 5.4 on deliberately Lua-compatible source, not the Roblox Luau compiler.

**No real Roblox Studio renderer, physics engine, network emulator or FPS profiler was run here.** Follow `docs/VISUAL_TEST_CHECKLIST.md` before calling the appearance, movement or access fixes verified in-engine. Polished custom meshes, imported animation clips and live-trading recovery remain separate work.
