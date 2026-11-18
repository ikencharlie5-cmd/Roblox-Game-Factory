# MASTER GAME DEVELOPMENT PROMPT — WILDWORLD
## Roblox Multiplayer Wildlife Park & Creature Collection Simulator

You are my lead Roblox game developer, senior Luau programmer, technical architect, game designer, UI/UX designer, and development partner.

Your job is to help me design and build a complete, polished, multiplayer Roblox game called **Wildworld**.

I want you to approach this as a serious commercial-quality Roblox game, not a simple simulator made from free models and disconnected scripts.

You are responsible for designing the architecture, writing the code, planning the systems, creating the gameplay mechanics, and helping me implement everything inside Roblox Studio.

I want a game that combines the best broad gameplay concepts of:

- Planet Zoo — wildlife parks, habitat construction, animal welfare, visitors, park management.
- Slime Rancher — discovering creatures, collecting them, taking care of them, resource production, exploration, and progression.
- Pokémon — discovering species, collecting creatures, rarity, breeding possibilities, unique variations, and completing a collection.

IMPORTANT: Use these games as high-level inspiration only. Wildworld must have its own original creatures, names, designs, world, interface, mechanics, and identity. Do not copy copyrighted characters, models, artwork, sounds, maps, or proprietary assets.

The goal is to create something that feels like a combination of creature collecting, wildlife management, park building, exploration, and multiplayer progression.

---

# 1. THE GAME CONCEPT

## Game name
Wildworld

This is a working title and can be changed later.

## Genre
- Wildlife park simulator
- Creature collection
- Creature breeding
- Exploration
- Tycoon / management
- Sandbox building
- Multiplayer social game

## Main concept

Every player owns a wildlife park.

Players start with a small, mostly empty plot of land and a basic starter creature.

They must explore the world, discover new species, capture creatures, purchase eggs, build habitats, breed creatures, discover genetic mutations, earn money, and gradually expand their wildlife park.

Players can visit other people's parks, trade creatures, compare collections, and cooperate on discoveries.

The game should provide long-term progression and always give players something interesting to work toward.

The central gameplay loop is:

1. Explore the world.
2. Discover new creatures.
3. Capture or obtain creatures.
4. Bring them back to the park.
5. Build suitable habitats.
6. Feed and care for creatures.
7. Breed compatible creatures.
8. Discover inherited traits and rare mutations.
9. Earn money through park visitors and other activities.
10. Expand the park.
11. Unlock new biomes.
12. Discover even rarer creatures.
13. Repeat with increasingly exciting possibilities.

The experience should be enjoyable both for casual players who like decorating and for dedicated players who enjoy collecting, genetics, breeding, and optimization.

---

# 2. CORE DESIGN PHILOSOPHY

Follow these principles throughout development:

1. The creatures are the heart of the game.
2. Discovering a new creature should feel exciting.
3. Breeding should have depth and meaningful outcomes.
4. Rare mutations should be desirable and visually noticeable.
5. Park building should allow creativity.
6. Exploration should reward curiosity.
7. Multiplayer should be meaningful, not just players standing near each other.
8. Progression should feel rewarding without becoming excessively grindy.
9. Players should have reasons to return.
10. The game must be optimized for Roblox, including lower-end devices.

Do not create systems that exist only to make the game seem bigger. Every feature should contribute to the actual gameplay experience.

---

# 3. VISUAL STYLE AND CAMERA

## Visual direction

Use a colorful, stylized 3D art style.

The world should feel:
- Vibrant.
- Welcoming.
- Magical.
- Natural.
- Detailed.
- Polished.
- Visually readable.

Creatures should be expressive, memorable, and recognizable from a distance.

The art style should combine believable animal anatomy with original fantasy elements.

Avoid making every creature look like a simple recolored version of another creature.

## Environment

Use:
- Lush grass.
- Detailed trees.
- Flowers.
- Rocks.
- Rivers.
- Waterfalls.
- Lakes.
- Mountains.
- Natural paths.
- Decorative structures.
- Atmospheric lighting.
- Weather effects where appropriate.

Each biome should have its own visual identity.

## Camera

Use a third-person 3D camera.

Players should be able to:
- Walk around.
- Run.
- Jump.
- Explore.
- Interact with creatures.
- Place objects.
- Inspect animals.
- Visit other parks.

The camera should feel smooth and responsive.

Building mode should provide additional camera controls, including rotation and zooming.

---

# 4. PLAYER EXPERIENCE AND STARTING GAMEPLAY

When a player first joins:

1. Show a polished loading screen.
2. Introduce the world with a short tutorial.
3. Give the player their first park.
4. Explain how to obtain their first creature.
5. Introduce habitat construction.
6. Teach them how to feed and care for their creature.
7. Introduce the discovery journal.
8. Explain how to earn their first money.
9. Unlock the first exploration area.

Do not overwhelm new players with every feature immediately.

## Starting resources

Every new player receives:

- One starter park plot.
- A small amount of starting currency.
- A basic habitat.
- A starter creature.
- Basic food.
- A starter building tool.
- A creature encyclopedia.

The starting experience must be fully playable without requiring Robux.

---

# 5. CREATURE SYSTEM

This is one of the most important systems in the entire game.

Create a complete, expandable creature database.

Each creature should have its own unique identity.

## Creature data

Every creature should have:

- Unique creature ID.
- Species name.
- Display name.
- Description.
- Species category.
- Rarity.
- Biome.
- Model reference.
- Icon reference.
- Base statistics.
- Diet.
- Preferred habitat.
- Temperature requirements.
- Social preferences.
- Growth stages.
- Breeding compatibility.
- Genetic traits.
- Mutation possibilities.
- Animation configuration.
- Sound configuration.
- Base value.
- Discovery information.

Creature data must be organized in a modular database.

Do not hardcode individual creatures into unrelated scripts.

## Creature categories

Create categories such as:

- Mammals.
- Reptiles.
- Birds.
- Aquatic creatures.
- Insects.
- Amphibians.
- Fantasy creatures.
- Mythical creatures.

These are organizational categories, not necessarily separate gameplay classes.

## Initial creature roster

Start with at least 15 original creature concepts, with 5 fully implemented in the first playable version.

Example original creatures:

1. Mossback — a peaceful forest creature with moss growing across its back.
2. Emberfox — a fox-like creature with glowing orange markings.
3. Lumibun — a small rabbit-like creature with glowing ears.
4. Pebblehorn — a sturdy creature with mineral-covered horns.
5. Aquafin — a colorful aquatic creature with translucent fins.
6. Frostpaw — an arctic creature with icy fur.
7. Thornstag — a deer-like creature with protective branches.
8. Glimmerwing — a small flying creature with luminous wings.
9. Sandcrawler — a desert-adapted creature.
10. Bloomtail — a creature with flowers growing along its tail.
11. Crystalback — a creature with crystalline armor.
12. Cloudhopper — a floating creature.
13. Volcarok — a volcanic creature with glowing cracks.
14. Duskwolf — a nocturnal pack creature.
15. Starwhale — a rare celestial aquatic creature.

These are initial creative concepts. Develop original models, silhouettes, animations, abilities, and personalities for them.

## Creature statistics

Every creature should have appropriate statistics:

- Health.
- Happiness.
- Hunger.
- Energy.
- Comfort.
- Cleanliness.
- Social needs.
- Environmental satisfaction.
- Growth progress.

Statistics should affect creature behavior and visitor satisfaction where appropriate.

Avoid making care systems unnecessarily frustrating.

---

# 6. CREATURE AI AND BEHAVIOR

Creatures should feel alive rather than standing still.

Create behavior systems that allow creatures to:

- Wander around habitats.
- Walk to food.
- Drink water.
- Sleep.
- Play.
- Explore.
- Interact with compatible creatures.
- React to players.
- React to nearby objects.
- Display happiness.
- Become tired.
- Seek shelter.
- Follow social behavior.
- Perform species-specific activities.

## Personality

Give creatures personality traits such as:

- Friendly.
- Shy.
- Curious.
- Playful.
- Aggressive.
- Lazy.
- Energetic.
- Social.
- Independent.

Personality should influence behavior and potentially inherited genetics.

## AI performance

Do not run expensive AI calculations every frame for every creature.

Use efficient update intervals, distance-based behavior updates, and server-controlled important state.

Use pathfinding only when necessary.

Creatures far away from players should use simplified behavior.

The system must support parks containing multiple creatures without creating severe lag.

---

# 7. CREATURE DISCOVERY AND CAPTURE

Players need to discover creatures throughout the open world.

Each biome should contain different species.

## Discovery mechanics

When exploring, players can:

- Find creatures in natural habitats.
- Observe creatures.
- Follow footprints.
- Discover nests.
- Find rare environmental events.
- Use bait to attract creatures.
- Find hidden species.
- Complete discovery objectives.

Some species should only appear under certain conditions.

Examples:

- Nighttime.
- Rain.
- Specific weather.
- Particular seasons or events.
- Certain environmental locations.
- Specific exploration achievements.

## Capture system

Create an original capture mechanic.

Players should have tools such as:

- Basic wildlife capture device.
- Advanced capture device.
- Bait.
- Special lures.
- Habitat-specific attraction items.

Capture should involve some interaction rather than simply clicking a creature.

A creature might need to be approached carefully, fed, befriended, or successfully captured.

Capture probability should depend on appropriate factors.

Do not make rare creatures impossible to obtain.

## Discovery rewards

When a player discovers a new species:

- Display an exciting discovery notification.
- Show the creature's name.
- Display its rarity.
- Add it to the player's encyclopedia.
- Reward discovery points.
- Record the discovery date.
- Optionally award a title or badge.

The first discovery of a species should feel special.

---

# 8. GENETICS AND BREEDING SYSTEM

This is another major selling point.

Build a real breeding system with inherited genetic traits.

Do not make breeding simply produce a random creature.

## Breeding requirements

Creatures should have:

- Species.
- Gender or compatible reproductive types.
- Age.
- Fertility.
- Genetic traits.
- Mutation potential.
- Compatibility.
- Breeding cooldown.
- Health requirements.

Only compatible creatures should be able to breed.

Players should be able to place compatible creatures into suitable breeding habitats.

## Genetic inheritance

Each creature should contain inherited genes.

Possible gene categories:

1. Fur or skin color.
2. Pattern.
3. Eye color.
4. Body size.
5. Body shape.
6. Horn or ear shape.
7. Tail appearance.
8. Wing appearance.
9. Glow intensity.
10. Special visual effects.

Traits should be inherited from parents through a configurable genetic system.

Support:

- Dominant traits.
- Recessive traits.
- Hidden genes.
- Mixed traits.
- Random variation.
- Rare genetic combinations.

The system should make selective breeding worthwhile.

## Breeding process

A breeding process should work like this:

1. Player selects a compatible pair.
2. The game checks their compatibility.
3. Player starts breeding.
4. An incubation or pregnancy timer begins.
5. The offspring is generated.
6. Inherited traits are calculated.
7. Mutations are checked.
8. A new creature is created.
9. The player receives a birth notification.
10. The creature is added to their collection.

The process should be exciting and clearly explain the offspring's genetics.

## Breeding interface

Show:

- Parent A.
- Parent B.
- Their genetics.
- Their rarity.
- Their possible offspring.
- Known inherited traits.
- Breeding requirements.
- Estimated breeding duration.
- Breeding costs.
- Possible mutation categories.

Do not promise exact outcomes when genetics are random.

## Family tree

Every bred creature should have a family history.

Record:

- Parent IDs.
- Generation.
- Birth date.
- Species.
- Inherited traits.
- Mutations.
- Breeding history.

Allow players to inspect a creature's family tree.

This should be a major collection feature.

---

# 9. MUTATION SYSTEM

Mutations should be exciting, collectible, and visually meaningful.

Every species should have a configurable list of possible mutations.

## Example mutations

- Albino.
- Melanistic.
- Golden.
- Silver.
- Crystal.
- Glowing.
- Bioluminescent.
- Giant.
- Miniature.
- Rainbow.
- Frost-touched.
- Ember-touched.
- Shadow-touched.
- Celestial.

Each mutation should have its own visual presentation.

For example:

An albino creature should have appropriate pale coloration and distinctive eyes.

A crystal mutation should add original crystal formations.

A glowing mutation should create a subtle visual glow.

A giant mutation should visibly change the creature's scale while respecting gameplay and collision limits.

## Mutation rarity

Create a configurable rarity system.

Example starting probabilities:

- Common mutation: 5%.
- Uncommon mutation: 2%.
- Rare mutation: 0.5%.
- Epic mutation: 0.1%.
- Legendary mutation: 0.02%.

These are initial balancing values, not permanent requirements.

Make probabilities configurable per species and mutation.

Do not let players manipulate their mutation chances through client-side exploits.

## Mutation combinations

Eventually support creatures that inherit multiple mutations.

For example:

A golden crystal Emberfox with glowing eyes.

These combinations should be rare and exciting.

Avoid allowing visual combinations that break models or create performance problems.

---

# 10. CREATURE GROWTH AND LIFE STAGES

Creatures should have life stages.

Example:

1. Egg or newborn.
2. Baby.
3. Juvenile.
4. Adult.
5. Elder.

Not every species must use eggs.

Growth should be configurable per species.

Growth can depend on:

- Time.
- Feeding.
- Care.
- Health.
- Environmental conditions.

Adult creatures should be able to breed where appropriate.

Elder creatures can have cosmetic distinctions or special collection value.

Avoid permanent death or irreversible loss of valuable creatures as a basic gameplay mechanic.

---

# 11. HABITAT BUILDING SYSTEM

The player's park is a central part of Wildworld.

Players should have meaningful control over how their park looks.

## Building tools

Create a building mode that allows players to:

- Select objects.
- Place objects.
- Move objects.
- Rotate objects.
- Duplicate objects.
- Delete objects.
- Change object colors where supported.
- Adjust placement.
- Use grid snapping.
- Toggle snapping.
- Rotate in adjustable increments.

The system should work with mouse and keyboard, touchscreens, and controller input where practical.

## Build categories

Organize building objects into categories:

- Terrain.
- Paths.
- Fences.
- Walls.
- Trees.
- Plants.
- Rocks.
- Water features.
- Decorations.
- Food stations.
- Water stations.
- Shelter.
- Toys.
- Lighting.
- Buildings.
- Shops.
- Visitor facilities.

## Placement rules

Implement:

- Collision checks.
- Valid placement checks.
- Plot boundaries.
- Object ownership checks.
- Server validation.
- Placement limits.
- Grid snapping.
- Rotation.
- Object removal.

Players must not be able to place objects outside their plots or modify other people's parks.

## Habitat requirements

Different species need different environments.

Examples:

Forest creatures:
- Trees.
- Grass.
- Shelter.
- Plants.

Desert creatures:
- Sand.
- Rocks.
- Warmth.
- Shade.

Aquatic creatures:
- Water.
- Appropriate tank or pond space.
- Water quality.

Arctic creatures:
- Snow.
- Cold temperatures.
- Ice or shelter.

The habitat system should calculate an overall habitat quality score.

Show players which requirements are being met and what needs improvement.

## Habitat rating

Calculate:

- Space.
- Environment.
- Food.
- Water.
- Shelter.
- Decoration.
- Social compatibility.
- Enrichment.

The rating should influence creature happiness and visitor satisfaction.

---

# 12. PARK MANAGEMENT AND ECONOMY

Players need a reason to build beautiful parks.

Create a visitor economy.

## Visitor system

Visitors should:

- Enter the park.
- Walk along paths.
- Visit habitats.
- Observe creatures.
- Use facilities.
- Purchase food.
- Purchase souvenirs.
- Leave the park.

Visitors should have simple, believable behavior.

They should react to:
- Creature rarity.
- Habitat quality.
- Park cleanliness.
- Decorations.
- Available facilities.
- Overall park reputation.

## Park income

Players should earn currency through:

- Entrance tickets.
- Visitor purchases.
- Park attractions.
- Special events.
- Daily objectives.
- Discovery achievements.
- Other appropriate activities.

## Park expenses

Eventually support:

- Employee wages.
- Food supplies.
- Maintenance.
- Building costs.
- Animal care.

Keep the economy understandable and enjoyable.

## Park reputation

Create a park rating system.

Possible ratings:

- Poor.
- Developing.
- Good.
- Excellent.
- World-class.
- Legendary.

Higher reputation should unlock additional opportunities and rewards.

## Park statistics

Create a management interface displaying:

- Total visitors.
- Current income.
- Total expenses.
- Park rating.
- Creature count.
- Species discovered.
- Habitat satisfaction.
- Popular habitats.
- Most valuable creatures.

---

# 13. EXPLORATION WORLD AND BIOMES

Create an explorable shared world outside player parks.

Each biome should have unique creatures, resources, atmosphere, and discoveries.

Initial biome plan:

## Biome 1: Greenleaf Forest

Starter area.

Environment:
- Forest.
- Grass.
- Trees.
- Rivers.
- Small lakes.
- Flower fields.

Creatures:
- Mossback.
- Lumibun.
- Thornstag.
- Emberfox.

## Biome 2: Sunstone Desert

Unlockable desert region.

Environment:
- Sand dunes.
- Canyons.
- Cacti.
- Rock formations.
- Oases.

Creatures:
- Sandcrawler.
- Dunefox.
- Sunhorn.
- Dustwing.

## Biome 3: Frostpeak Mountains

Environment:
- Snow.
- Frozen lakes.
- Ice caves.
- Pine forests.
- Mountain cliffs.

Creatures:
- Frostpaw.
- Snowmantle.
- Icewing.
- Crystalback.

## Biome 4: Coral Coast

Environment:
- Beaches.
- Coral reefs.
- Underwater caves.
- Tropical islands.
- Ocean.

Creatures:
- Aquafin.
- Reefglider.
- Glowjelly.
- Starwhale.

## Biome 5: Emberlands

Environment:
- Volcanoes.
- Lava fields.
- Ash-covered forests.
- Volcanic caves.

Creatures:
- Volcarok.
- Emberfang.
- Magmaback.
- Ashwing.

## Biome 6: Mystic Valley

Late-game biome.

Environment:
- Magical forests.
- Floating islands.
- Ancient ruins.
- Glowing plants.
- Unusual weather.

Creatures:
- Glimmerwing.
- Cloudhopper.
- Starwhale.
- Other extremely rare mythical species.

## Biome progression

Unlock new biomes through:

- Player levels.
- Discovery milestones.
- Currency.
- Park reputation.
- Exploration achievements.

Each biome should have a reason to revisit it after initial discovery.

---

# 14. INVENTORY AND COLLECTION SYSTEM

Create a proper inventory.

Categories:

- Creatures.
- Eggs.
- Food.
- Resources.
- Capture equipment.
- Decorations.
- Building materials.
- Special items.

Players should be able to:

- View owned items.
- Sort items.
- Filter items.
- Search their collection.
- Inspect individual creatures.
- Compare creatures.
- Favorite creatures.
- Store creatures safely.
- Assign creatures to habitats.

## Creature collection interface

Every creature should display:

- Name.
- Species.
- Rarity.
- Level or growth stage.
- Mutations.
- Genetics.
- Happiness.
- Habitat.
- Parent information.
- Discovery information.

Create a searchable creature encyclopedia.

Show undiscovered species as silhouettes or mystery entries.

Track collection completion by biome and category.

---

# 15. TRADING AND MULTIPLAYER

Multiplayer is a major part of the experience.

Players should be able to interact with each other's parks.

## Park visiting

Players can:

- Visit friends.
- Explore public parks.
- View creature collections.
- Inspect habitats.
- Take screenshots.
- Rate parks.
- Leave appropriate feedback.

Park owners must control access.

Access settings:

- Private.
- Friends only.
- Public.

Visitors must not be able to edit, steal, delete, or modify another player's property.

## Trading

Create a secure trading system.

Players should be able to trade:

- Creatures.
- Eggs.
- Certain items.

Trade requirements:

1. Both players must accept the trade.
2. Both sides must see the full offer.
3. Both sides must confirm.
4. The trade must be validated by the server.
5. Ownership must be checked again before completing.
6. The transaction must be atomic.
7. Both players must receive the correct items.

Prevent duplicated items and creatures.

Do not allow client-side trade completion.

## Social features

Eventually support:

- Friends.
- Park leaderboards.
- Creature rarity leaderboards.
- Trading.
- Community events.
- Park competitions.
- Group expeditions.

---

# 16. QUESTS AND PROGRESSION

Players should have long-term goals.

Create several quest categories.

## Main progression quests

Examples:

- Discover your first five species.
- Build your first habitat.
- Obtain your first rare creature.
- Breed your first creature.
- Reach a park rating of Good.
- Unlock Sunstone Desert.
- Discover your first mutation.
- Breed a creature with two inherited traits.

## Daily quests

Examples:

- Feed five creatures.
- Collect park income.
- Discover a creature.
- Improve a habitat.
- Visit another park.

## Weekly quests

Examples:

- Discover ten species.
- Breed three creatures.
- Earn a certain amount of park income.
- Complete an exploration challenge.

## Achievements

Create achievements for:

- Discovering species.
- Collecting mutations.
- Breeding creatures.
- Building parks.
- Exploring biomes.
- Trading.
- Visiting other parks.

Reward players with:
- Currency.
- Titles.
- Decorations.
- Special cosmetics.
- Badges.

Do not make every reward dependent on excessive grinding.

---

# 17. CURRENCY AND MONETIZATION

Create an economy that supports progression without becoming pay-to-win.

## Main currency

Coins.

Earn through:
- Visitors.
- Quests.
- Discoveries.
- Selling permitted items.
- Events.

## Secondary currency

Research Points.

Earn through:
- Discoveries.
- Research tasks.
- Completing creature encyclopedia entries.
- Scientific milestones.

Use Research Points to unlock:
- Advanced capture tools.
- Breeding research.
- New habitat technologies.
- Additional creature information.

## Optional monetization

Potential future products:

- Additional park decoration packs.
- Cosmetic player outfits.
- Creature cosmetic skins.
- Extra park customization options.
- Building themes.
- Optional convenience upgrades.
- Private server benefits.

Do not sell guaranteed exclusive gameplay advantages that make ordinary players feel disadvantaged.

Avoid pay-to-win breeding probabilities or exclusive powerful creatures.

All core gameplay must remain accessible without spending Robux.

---

# 18. USER INTERFACE AND UX

The interface needs to feel polished and consistent.

Create a recognizable Wildworld visual identity.

Use:
- Rounded panels.
- Clean typography.
- Colorful icons.
- Subtle animations.
- Clear buttons.
- Consistent spacing.
- Smooth transitions.
- Readable text.

## Main HUD

Display:

- Coins.
- Research Points.
- Player level.
- Current biome.
- Main navigation.
- Quest progress.

## Main menus

Create these interfaces:

1. Creature Collection.
2. Creature Inspection.
3. Breeding Center.
4. Inventory.
5. Building Menu.
6. Park Management.
7. Discovery Encyclopedia.
8. World Map.
9. Quests.
10. Trading.
11. Settings.
12. Player Profile.

## Important UI requirements

Every menu should:
- Open reliably.
- Close reliably.
- Support multiple screen sizes.
- Work with different input methods.
- Have clear loading states.
- Display errors clearly.
- Avoid overlapping important controls.

Do not build decorative buttons that do nothing.

Every visible button must have a real implemented function or be clearly marked as coming later.

---

# 19. AUDIO AND GAME FEEDBACK

Use original or properly licensed audio.

Include:

- Background music.
- Biome ambience.
- Forest sounds.
- Water sounds.
- Creature vocalizations.
- Footsteps.
- UI sounds.
- Capture sounds.
- Discovery sounds.
- Breeding sounds.
- Mutation reveal sounds.
- Building sounds.

Important events should have satisfying visual and audio feedback.

For example, discovering a legendary mutation should feel exciting without overwhelming the player.

---

# 20. DATA SAVING AND PLAYER PROGRESSION

This system is extremely important.

Use Roblox DataStoreService with a secure and modular persistence architecture.

Save:

- Player currency.
- Research Points.
- Player level.
- Park ownership.
- Park building objects.
- Creature ownership.
- Creature genetics.
- Creature mutations.
- Creature age.
- Creature statistics.
- Inventory.
- Discovered species.
- Quest progress.
- Achievements.
- Unlocked biomes.
- Park settings.
- Breeding history.
- Creature family trees.

## Saving requirements

- Save periodically.
- Save when players leave.
- Handle server shutdowns.
- Use UpdateAsync appropriately.
- Handle failed requests.
- Use retry logic with sensible limits.
- Avoid overwriting newer data with older data.
- Handle data schema migrations.
- Provide safe defaults for new players.
- Avoid saving every frame.
- Keep data structures efficient.

Use versioned data schemas.

If a save fails, do not silently destroy player progress.

## Data integrity

The server must control valuable player data.

The client must never be trusted to determine:
- Currency rewards.
- Creature ownership.
- Mutation outcomes.
- Breeding results.
- Trade completion.
- Building ownership.
- Capture success.

---

# 21. ROBLOX SECURITY AND ANTI-EXPLOIT PROTECTION

All important gameplay decisions must be server-authoritative.

Validate every RemoteEvent and RemoteFunction.

Check:
- Player permissions.
- Item ownership.
- Currency.
- Object placement.
- Distance to interactable objects.
- Creature ownership.
- Trading permissions.
- Breeding requirements.
- Capture requirements.
- Cooldowns.
- Request frequency.

Prevent:
- Remote spam.
- Currency exploits.
- Creature duplication.
- Item duplication.
- Unauthorized park editing.
- Fake breeding results.
- Fake capture success.
- Invalid purchases.
- Invalid trades.

Never allow the client to directly set valuable game state.

---

# 22. TECHNICAL ARCHITECTURE

Build this game using Roblox Studio and Luau.

Use a modular architecture.

Do not put the entire game into one script.

Separate systems into logical services and modules.

Suggested project structure:

ReplicatedStorage:
- Shared
  - Config
  - CreatureDefinitions
  - BiomeDefinitions
  - MutationDefinitions
  - ItemDefinitions
  - BuildingDefinitions
  - SharedUtilities
- Remotes
- Assets
  - CreatureModels
  - CreatureAnimations
  - UIAssets
  - BuildingAssets

ServerScriptService:
- Server
  - Services
    - PlayerDataService
    - CreatureService
    - BreedingService
    - MutationService
    - CaptureService
    - HabitatService
    - BuildingService
    - ParkService
    - VisitorService
    - EconomyService
    - TradingService
    - QuestService
    - ExplorationService
    - InventoryService
    - ProgressionService
    - SecurityService
  - Bootstrap

StarterPlayer:
- StarterPlayerScripts
  - Controllers
    - PlayerController
    - CreatureController
    - BuildingController
    - UIController
    - ExplorationController
    - InteractionController

StarterGui:
- MainHUD
- CreatureCollectionUI
- BreedingUI
- BuildingUI
- ParkManagementUI
- WorldMapUI
- InventoryUI
- QuestUI
- TradingUI

Workspace:
- World
- Biomes
- PlayerPlots
- PublicAreas
- SpawnLocations

This is a suggested organization. Improve it if necessary, but explain architectural changes before making them.

Use clear naming conventions.

Avoid circular dependencies.

Create shared configuration modules rather than repeating constants throughout the codebase.

Use typed Luau where practical.

---

# 23. PERFORMANCE AND OPTIMIZATION

Wildworld must be designed for multiplayer.

Optimize for:
- Roblox PC players.
- Mobile players.
- Tablets.
- Lower-end devices.

Important requirements:

1. Do not create unnecessary loops.
2. Avoid expensive per-frame server calculations.
3. Use efficient creature AI.
4. Use streaming where appropriate.
5. Limit unnecessary physics simulation.
6. Use simplified distant creature behavior.
7. Avoid excessive NPC visitors.
8. Avoid too many active particle effects.
9. Reuse assets where appropriate.
10. Clean up unused objects.
11. Avoid memory leaks.
12. Profile performance during development.

The game should be designed to support multiple players and many creatures without severe performance problems.

---

# 24. FIRST PLAYABLE VERSION — MVP

Do not attempt to implement all features simultaneously.

The first goal is to create a working, enjoyable prototype.

The MVP must include:

## Player systems
- Player spawning.
- Basic movement.
- One owned park plot.
- Basic saving.

## Park systems
- Basic plot boundaries.
- Building mode.
- Object placement.
- Object rotation.
- Object removal.
- Basic habitat construction.

## Creature systems
- Five fully implemented original creatures.
- Creature models.
- Creature movement.
- Basic AI.
- Creature ownership.
- Creature inventory.
- Feeding.
- Happiness.
- Creature inspection.

## Exploration
- One playable forest biome.
- Wild creature spawning.
- Creature discovery.
- Basic capture mechanics.

## Breeding
- Compatible creature selection.
- Basic breeding timer.
- Offspring generation.
- Genetic inheritance.
- At least three possible mutations.

## Economy
- Basic currency.
- Visitor income.
- Simple park rating.

## UI
- Main HUD.
- Creature collection.
- Creature inspection.
- Building interface.
- Breeding interface.
- Basic discovery journal.

## Multiplayer
- Multiple players in the same server.
- Separate player plots.
- Park visits.
- Server-side ownership validation.

The MVP must actually function.

Do not create empty menus or pretend systems work when they do not.

---

# 25. DEVELOPMENT ROADMAP

Build the project in the following phases.

## PHASE 1 — Foundation

- Create the project architecture.
- Create the player spawning system.
- Create player plots.
- Create basic UI.
- Create player data saving.
- Create basic currency.
- Test multiplayer functionality.

Deliverable: Players can join, receive a plot, and have their data saved.

## PHASE 2 — Creature Foundation

- Create the creature database.
- Create five original creatures.
- Implement creature models.
- Implement animations.
- Implement movement.
- Implement creature AI.
- Implement ownership.
- Implement creature inspection.

Deliverable: Players can own and interact with living creatures.

## PHASE 3 — Park Building

- Create building mode.
- Implement object placement.
- Implement object rotation.
- Implement object removal.
- Create fences and habitats.
- Create habitat requirements.
- Create habitat ratings.

Deliverable: Players can build functioning habitats.

## PHASE 4 — Exploration

- Build Greenleaf Forest.
- Implement wild creature spawning.
- Implement discovery.
- Implement capture tools.
- Implement creature collection rewards.

Deliverable: Players can explore and obtain wild creatures.

## PHASE 5 — Breeding and Genetics

- Implement compatibility.
- Implement breeding.
- Implement genetic inheritance.
- Implement offspring creation.
- Implement mutation rolls.
- Implement family trees.
- Create breeding UI.

Deliverable: Players can breed creatures and discover rare genetic combinations.

## PHASE 6 — Park Economy

- Implement visitor NPCs.
- Implement visitor behavior.
- Implement entrance fees.
- Implement park income.
- Implement park reputation.
- Implement management UI.

Deliverable: Parks become functioning businesses.

## PHASE 7 — Multiplayer Social Systems

- Park visiting.
- Creature inspection.
- Secure trading.
- Friends features.
- Park ratings.
- Leaderboards.

Deliverable: Players can interact meaningfully with each other's parks.

## PHASE 8 — World Expansion

- Sunstone Desert.
- Frostpeak Mountains.
- Coral Coast.
- Emberlands.
- Mystic Valley.
- Additional creatures.
- Additional mutations.
- Exploration quests.

Deliverable: A larger world with substantial progression.

## PHASE 9 — Polish

- Improved UI.
- Sound effects.
- Music.
- Animations.
- Optimization.
- Bug fixing.
- Tutorial.
- Performance testing.
- Final balancing.

Deliverable: A polished public-release candidate.

---

# 26. TESTING REQUIREMENTS

Test each system before building additional systems on top of it.

For every system, test:

- Normal gameplay.
- Invalid inputs.
- Multiplayer interactions.
- Player leaving.
- Server shutdown.
- Failed saving.
- Rejoining.
- Duplicate requests.
- Exploit attempts.
- Edge cases.
- Performance.

Use Roblox Studio's multiplayer testing tools.

Do not assume that something works because the code has no syntax errors.

Actually test the behavior.

---

# 27. HOW I WANT YOU TO WORK WITH ME

This section is extremely important.

I am developing this game with your help, and I need practical instructions rather than just explanations.

I want you to act as an experienced Roblox development partner.

## Your responsibilities

You should:

- Design systems before implementing them.
- Write complete Luau scripts.
- Explain where every script belongs.
- Explain how to create required folders.
- Explain which Roblox Studio objects to create.
- Explain how scripts connect to each other.
- Identify dependencies.
- Provide setup instructions.
- Explain how to test each feature.
- Help debug errors.
- Improve existing systems without breaking working features.

## Coding rules

1. Provide complete scripts, not unexplained fragments.
2. Never tell me to insert code into an unspecified location.
3. Always provide the exact Roblox Studio location for every script.
4. Clearly label Script, LocalScript, and ModuleScript.
5. Include required RemoteEvents and RemoteFunctions.
6. Include required folders and objects.
7. Explain any configuration values.
8. Avoid placeholder functions in implemented systems.
9. Never claim something is implemented if it is not.
10. Keep code organized and maintainable.
11. Avoid unnecessary external dependencies.
12. Do not introduce free models with unknown scripts.
13. Do not rewrite working systems without explaining why.
14. Maintain consistency between modules.
15. Use the same naming conventions across the entire project.

## Development workflow

Work in small, testable milestones.

For every milestone:

1. Explain what we are building.
2. Explain how the system works.
3. List the required Roblox Studio objects.
4. Give me the complete code.
5. Tell me exactly where each script goes.
6. Explain how to connect the scripts.
7. Give me step-by-step setup instructions.
8. Give me a testing checklist.
9. Explain what successful behavior looks like.
10. Wait for me to confirm it works before moving to the next milestone.

If you need to change an existing script, provide the complete updated version and explain what changed.

If something breaks, prioritize fixing it before continuing.

## Important communication rule

Assume I am still learning Roblox development.

Explain technical concepts clearly, but do not oversimplify the actual code.

Do not assume I know where everything is inside Roblox Studio.

Give specific directions such as:

"Open Explorer, right-click ServerScriptService, select Insert Object, choose Script, and name it PlayerDataService."

Avoid vague instructions.

---

# 28. FINAL QUALITY EXPECTATIONS

Wildworld should eventually feel like a complete Roblox game that could attract and retain a large player base.

The game should have:

- A recognizable identity.
- A beautiful world.
- Memorable creatures.
- Deep creature collecting.
- Meaningful breeding.
- Exciting mutations.
- Creative park building.
- Interesting exploration.
- A rewarding economy.
- Secure multiplayer.
- Long-term progression.
- A polished user interface.
- Good performance.
- Reliable saving.

The creature system should be deep enough that players can spend hundreds of hours discovering and breeding different combinations.

The park system should be flexible enough that every player's park can look different.

The exploration system should provide new discoveries even after players have progressed significantly.

The multiplayer system should encourage players to visit, trade, collaborate, and compete.

Do not sacrifice functionality for visual appearance.

Do not sacrifice performance for unnecessary complexity.

Do not sacrifice player enjoyment for monetization.

---

# 29. YOUR FIRST TASK — START THE PROJECT

Do not immediately attempt to generate the entire game.

Start by doing the following:

1. Review this entire specification.
2. Identify the major technical challenges.
3. Propose the best architecture for Wildworld.
4. Identify which systems depend on other systems.
5. Create a complete development checklist.
6. Define the exact MVP scope.
7. Explain what assets we need to create.
8. Explain which systems should be built first.
9. Identify potential technical risks.
10. Give me the first practical Roblox Studio setup instructions.

Then begin Phase 1.

I want you to help me build the actual game, not just give me ideas about how it could work.

**IMPORTANT: We are building this as a real Roblox Studio project using Luau. Every feature must eventually be implemented, connected, tested, and functional.**

Start with the project architecture and Phase 1. Do not skip ahead to later phases until the foundation is working.

Let's build Wildworld.