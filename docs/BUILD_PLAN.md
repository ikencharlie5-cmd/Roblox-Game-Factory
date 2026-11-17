# Build plan (follow in order, commit after each phase)

1. **Config** — put every number from SPEC.md into `src/shared/Config.luau`
   (currencies, prices, rates, upgrade tables, pass/product IDs as placeholders = 0).
2. **Data** — extend `Config.DefaultData`; confirm DataService saves/loads every field.
3. **World** — build the map in code (`Services/WorldService.luau`): baseplate, spawn,
   zones, signs. Use `Instance.new` + anchored Parts; name everything clearly.
4. **Core loop** — one Service per system (e.g. `IncomeService`, `UpgradeService`).
   Validate every remote on the server (type, range, cooldown, can-afford).
5. **Client UI** — HUD (currency, buttons), shop/upgrade menu, notifications.
   Built with code in `src/client/UI/`. Must work on phone (use Scale, min 44px buttons).
6. **Progression extras** — rebirth/prestige, zones unlock, daily reward.
7. **Monetization** — wire `MonetizationService` to the passes/products in Config.
8. **Polish** — sounds (rbxassetid placeholders OK), tweens, particles on rewards,
   tutorial arrow/text for first 60s.
9. **Checks** — `scripts/check.sh <slug>` clean + `docs/QUALITY_CHECKLIST.md` all ticked.
10. **README** — how to play, how to publish, Charlie TODO list.
