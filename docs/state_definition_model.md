# State Definition Model

## Purpose

This adds a database-backed home for **state definitions** without changing how runtime state is applied tonight.

- `session_states` remains the table for active state instances attached to a `GameSession`.
- `state_definitions` is the new table for the static metadata that currently lives in [`app/services/state/registry.rb`](C:\Users\akriv\OneDrive\Desktop\warlords\app\services\state\registry.rb).

## How the current registry maps to DB-backed definitions

Each current registry entry maps to one `state_definitions` row:

- `key` maps directly from the registry key
- `state_type` is currently `"modifier"` for the runtime active-state registry
- `label` maps from registry `name`
- `description`, `visibility`, and `default_duration` map directly
- `stacking_rule` is recorded as `"unique_refresh"` because runtime behavior today refreshes the single `SessionState` row for a given `state_key`
- richer registry-only fields such as `category`, `on_turn_start_effects`, `weight_modifiers`, and `chronicle_tags` are stored under `metadata`
- `scenario_key` is set to `"romebots"` for the current snapshot

The migration intentionally backfills the current registry into the table so the foundation is inspectable immediately, even though runtime reads still come from Ruby code.

## Intentionally deferred

This foundation does **not** do the following yet:

- replace `State::Registry` as the runtime source of truth
- add admin UI or authoring flows for `state_definitions`
- move `ContextSchema` or `Configuration.initial_context` into the database
- introduce runtime loading, caching, or validation against DB rows
- reconcile non-modifier state definitions such as future `flag` or `context_state` records

That keeps tonight's change low-risk and avoids touching resolution, expiry, deck-building, or presenter behavior.

## Likely runtime integration later

A safe next step would be to add a repository layer that reads `state_definitions` and returns the same shape the current registry returns.

At that point:

1. `State::Registry.fetch` could delegate to DB-backed definitions for a scenario.
2. `State::PanelPresenter`, `GameSession#state_snapshot`, and deck-weight logic could keep calling the same registry interface.
3. Admin/configuration tooling could edit `state_definitions` rows without forcing a simultaneous rewrite of active `SessionState` behavior.

The important boundary is:

- `state_definitions` describes what a state **is**
- `session_states` describes which states are **currently active** for a session
