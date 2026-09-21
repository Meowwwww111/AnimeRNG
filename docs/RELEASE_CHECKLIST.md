# Studio and release checks

## Local smoke test (manual; not yet executed by ChatGPT)

- Stop Play, pull the entire commit, confirm Rojo sync, then Play.
- Spawn in the plaza with a visible humanoid starter companion. Verify head/limbs/weapons attach correctly and stay attached after movement and respawn.
- Walk to each enemy tier. Check auto attacks, health reduction, one reward per death, no attacks after death, respawn, retreat, and enemy player damage.
- Stand outside combat range: rewards must not increase. The old Attack RemoteFunction must not exist.
- Roll at the arch with E. Check coin deduction, actual outcome, model/equip changes only for stronger units, and Odds percentages.
- Craft with too few materials, craft tiers out of order, and repeat an already-crafted charm: all must fail without a debit. Craft and use earned potions and unbound sigils.
- Equip old units, claim each milestone only once, and check level/damage growth.
- Kill the World 1 boss; enter World 2 through the portal; test World 2 damage/rewards and return. Die in World 2; respawn safely in World 1 while keeping the unlock.
- Two-player Studio test, session-only mode: both walk to the same trade arch, invite/join, edit offers, ready, wait 3 seconds, confirm twice. Change an offer after readiness; both approvals must reset. Test cancellation, disconnect, expiry, insufficient resources and invalid numbers.
- Test small mobile screens, tapping prompts, scrolling menus, closing panels and camera movement.
- Profile at the intended player count before raising server capacity. This is a flat-map, kinematic NPC prototype, not general-purpose pathfinding.

## Data safety

- Use a separate published TEST experience. Do not test against real players' production data.
- StudioPersistence=false should perform no DataStore requests. StudioPersistence=true must use only the separate Studio data-store name.
- Simulate failed loads, save throttling, server shutdown, overlapping joins, lease expiry and ambiguous receipt responses. Confirm no fallback overwrites, stale sessions, duplicated grants or migration loss.
- Add durable trade escrow and recovery before live trading; do not simply remove the Studio gate.

## Before accepting Robux

- Create real pass/product IDs in the Creator Dashboard; no IDs are supplied by this project.
- Review the latest Roblox paid-random-item requirements. Paid luck is a probability modifier covered by that policy.
- Verify PolicyService restrictions in a real test environment. Failed/unknown policy must remain fail-closed. Earned-only play remains available.
- Verify every character's numerical odds before purchase and after modifiers. Check the shop's current/pass/potion previews and rounded-probability disclaimer.
- Confirm ProcessReceipt grants once across retries and server changes, grants durably before acknowledgment, and does not rely on a client purchase-completed event.
- Test account restrictions changing, existing pass ownership, bought potion activation, offline timers and one-hour duration caps.
- Review receipt-table growth and save budgets before a large launch; do not prune receipt IDs without a durable replacement deduplication design.
- Complete experience content/maturity, asset-ownership and monetization settings yourself. This repository does not publish the game or change Creator Dashboard settings.

## Primary reference documentation (reviewed during implementation)

- https://create.roblox.com/docs/production/monetization/paid-random-items
- https://create.roblox.com/docs/reference/engine/classes/PolicyService
- https://create.roblox.com/docs/production/monetization/developer-products
- https://create.roblox.com/docs/cloud-services/data-stores
- https://rojo.space/docs/v7/project-format/
