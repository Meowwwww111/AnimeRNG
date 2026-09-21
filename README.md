# AnimeRNG

Original anime-inspired Roblox RNG action game.

## MVP
- No pity system
- Server-authoritative weighted RNG
- Character inventory/equip
- Monster combat and material drops
- Craftable permanent luck
- Temporary luck boosts
- DataStore persistence
- Trading architecture
- Rojo-ready project

## Setup
1. Install Roblox Studio.
2. Install Rojo CLI and the Rojo Studio plugin.
3. Clone this repository.
4. In the repo run `rojo serve`.
5. Open a Roblox Baseplate, open the Rojo plugin, and connect.
6. Sync the project and press Play.

The project uses original characters. Add your own models/animations/art later.

## Security
RNG, rewards, inventory, crafting and combat validation live on the server. Never move these decisions to LocalScripts.
