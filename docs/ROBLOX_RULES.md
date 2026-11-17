# Roblox coding rules

## Structure (Rojo)
- `src/server` → ServerScriptService.Server (`Main.server.luau` starts every Service)
- `src/client` → StarterPlayer.StarterPlayerScripts.Client
- `src/shared` → ReplicatedStorage.Shared
- A Service is a ModuleScript returning a table with `Init()` (setup) and optional `Start()`
  (loops/connections). Main calls all Inits, then all Starts.

## Networking
- Declare every remote in `Shared/Remotes.luau`; never create remotes elsewhere.
- Client → server: RemoteEvent/RemoteFunction, server validates everything.
- Server → client: fire events for UI updates; client never decides outcomes.
- Rate-limit spammable remotes (`Config.RemoteCooldown`).

## Data
- Only `DataService` touches DataStoreService. Use `DataService.Get(player)` /
  `DataService.Update(player, fn)`.
- Changes go through `DataService.Update` so leaderstats/UI stay in sync.

## Style
- `--!strict`, typed function params, PascalCase modules, camelCase locals.
- `task.wait/spawn/delay` (never `wait`, `spawn`, `delay`).
- Prefer `:GetAttribute`/`:SetAttribute` for simple replicated state.
- Tween with TweenService; never move parts every frame on the server.

## Monetization
- `MarketplaceService.ProcessReceipt` handled only in `MonetizationService`.
- Always return `PurchaseGranted` only after data is updated.
- Game Pass checks are cached per player on join.
