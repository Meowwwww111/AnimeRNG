# Studio checklist — 0.4.0

Stop Play, pull, restart Rojo, reconnect and sync before testing. Preserve your own art/place files and inspect Rojo's proposed changes before accepting them.

## Boot and visuals
- Run Play. Confirm Output reports 0.4.0 and has no red errors from `Presentation`, `VisualFactory` or the services.
- Confirm the original central UI remains replaced by the physical game, and that the starter has articulated limbs and layered facial/hair details.
- Compare outfits through the normal inventory/equip flow. Do not change rarity odds or add production debug grants just to preview rare units.
- The source visuals live on the client in `Workspace/AnimeRNG_LocalVisuals`. Server actors intentionally look like invisible roots in Server view. This is not missing server art.
- Original character/enemy labels and HP should update. Equip, die and respawn repeatedly; there should be one companion, not an increasing number of copies.

## Movement
- Walk, stop, strafe and turn near the spawn: companion follow should be continuously rendered rather than visibly stepping every server tick.
- Approach enemies, watch walk/attack poses, retreat and let them return home. Verify HP/rewards change only from server combat.
- Test two local players and Studio's available network emulation. Check for freezes, snapping, floor clipping and delayed VFX at different frame rates. Record actual FPS before claiming performance gains.
- Travel between worlds: the old world's cosmetic actors should disappear; returning should rebuild/reuse them without duplicate labels or leaks.
- Approved external art overrides are currently static: do not expect their uploaded animation clips to play automatically.

## World separation/access
- Fresh session-only Studio profile: try the World 1 portal before killing the boss. It must refuse entry.
- World 1 should be daylight village/shrine scenery; World 2 should be a nighttime fortress/rift environment with visibly different enemy forms.
- Using Studio's server inspection tools in a disposable test, place the character outside its current world's bounds. It must return to that world's arrival point within the next server tick.
- Test a locked player's forced position near X=6000. They must return to World 1 and must not receive World 2 drops or use World 2 stations.
- After legitimate unlock, portal entry to World 2 should succeed. Authorized travel is intentional; a saved unlocked profile is not a gate failure.
- Leave/rejoin, respawn and disconnect during travel. Confirm world assignment and companion state are consistent.

## Economy regression
- Rolling is still server-authoritative with no pity; all existing IDs, odds and saved ownership remain unchanged.
- Crafting, potions, quest claims and server rewards still work. Cross-world hits cannot pay rewards.
- Purchases stay off and trading remains Studio session-only. This update does not enable or certify production monetization or trading.

## Offline tests

On a machine with Python and liblua5.4, run `python tools/check_presentation.py` from the repo. This runs compatibility parsing and mocked tests only. It is not proof of a successful Roblox engine build or playtest.
