# State Flow Audit

## Scope

This audit covers three state buckets in the current RomeBots codebase:

- **Flags**: boolean-ish keys under `flags.*` inside `GameSession.context_state`
- **Context state**: numeric + boolean keys inside `GameSession.context_state` (`time.*`, `state.*`, `relations.*`, `factions.*`, `flags.*`)
- **Modifiers / active states**: timed `SessionState` rows keyed by `state_key`, with definitions in `Scenarios::Romebots::ActiveStateRegistry`

## Source of truth

### Persistent session truth

- `GameSession.context_state` is the main durable store for session truth.
- Schema ownership:
  - `db/migrate/20260321120000_create_rome_bots_core.rb`
  - `db/schema.rb` `game_sessions.context_state`
- Model owner:
  - `GameSession` in `app/models/game_session.rb`
- Initial shape comes from `Scenarios::Romebots::Configuration.initial_context` in `app/services/scenarios/romebots/configuration.rb:54`

### Timed / recurring modifier truth

- `session_states` table stores active timed state instances.
- Schema ownership:
  - `db/migrate/20260323080000_add_session_states_and_response_state_ops.rb:3`
  - `db/schema.rb` `session_states`
- Model owner:
  - `SessionState` in `app/models/session_state.rb`
- Definition owner:
  - `Scenarios::Romebots::ActiveStateRegistry::DEFINITIONS` in `app/services/scenarios/romebots/active_state_registry.rb`
- Runtime accessor:
  - `GameSession#state_snapshot` in `app/models/game_session.rb:55`

### Authored mutation definitions

- Card-authored writes are stored on `CardDefinition.response_a_effects`, `response_b_effects`, `response_a_states`, and `response_b_states`.
- These are copied onto `SessionCard` when a deck card or follow-up is instantiated:
  - `Decks::BuildForSession#call` in `app/services/decks/build_for_session.rb:16`
  - `FollowUps::EnqueueForResponse#create_follow_up_from_definition` in `app/services/follow_ups/enqueue_for_response.rb`
- Admin authors edit them through JSON text fields in `app/admin/card_definitions.rb`, backed by `CardDefinition::JSON_TEXT_FIELDS` in `app/models/card_definition.rb`

## Where state is persisted

| State type | Persisted in | Owner |
| --- | --- | --- |
| Flags | `game_sessions.context_state["flags.*"]` | `GameSession` + `Context::ApplyMutations` |
| Context state | `game_sessions.context_state` | `GameSession` + `Context::ApplyMutations` |
| Active modifiers | `session_states` rows | `SessionState` + `ActiveStates::ApplyResponseOperations` |
| Active-state definitions | in-code registry, not DB | `Scenarios::Romebots::ActiveStateRegistry` |
| Cycle snapshot used for UI/year summary deltas | `game_sessions.deck_state["cycle_start_context"]` | `Decks::BuildForSession#sync_deck_state`, `Cycles::Advance#advance_cycle!` |
| Readable history / derived state events | `event_logs.payload` | `Logs::RecordEvent` callers |

## Lifecycle paths

### Created

#### Context state / flags

- Session bootstraps `context_state` from `Configuration.initial_context` in `Sessions::StartRun#call` (`app/services/sessions/start_run.rb:15`)
- Card response mutations are applied through `Context::ApplyMutations.call` inside `Choices::ResolveResponse#update_session_state!` (`app/services/choices/resolve_response.rb:50`)
- Turn-start recurring effects from active states also write through `Context::ApplyMutations.call` in `ActiveStates::ProcessTurnStart#apply_recurring_effects!` (`app/services/scenarios/romebots/active_states/process_turn_start.rb:23`)
- New year rollover mutates `time.year`, `time.cycle_number`, and resets `time.cards_resolved_this_year` in `Cycles::Advance#advance_cycle!` (`app/services/cycles/advance.rb:29`)

#### Active states / modifiers

- A response adds an active state via `SessionCard.response_[a|b]_states`
- `Choices::ResolveResponse#update_session_state!` delegates to `ActiveStates::ApplyResponseOperations.call` after the context write (`app/services/choices/resolve_response.rb:58`)
- `ActiveStates::ApplyResponseOperations#add_state!` creates or refreshes a unique `SessionState` row via `find_or_initialize_by(state_key:)` (`app/services/scenarios/romebots/active_states/apply_response_operations.rb:48`)
- Duration is derived from explicit response JSON or registry default duration in `#normalized_duration` (`app/services/scenarios/romebots/active_states/apply_response_operations.rb:132`)

### Mutated

#### Context state / flags

- `Context::ApplyMutations` supports `set`, `increment`, `decrement`, `clear` (`app/services/context/apply_mutations.rb:26`)
- Prefix-based normalization is implicit:
  - `flags.*` become booleans; `clear` becomes `false` not removal (`app/services/context/apply_mutations.rb:46`)
  - `state.*` clamps to `0..100`
  - `relations.*` and `factions.*` clamp to `-5..5`
  - `time.*` coerces to integer
- `Choices::ResolveResponse#update_session_state!` always increments `time.cards_resolved_this_year` after applying card effects (`app/services/choices/resolve_response.rb:56`)

#### Active states / modifiers

- `add_state!` is also the refresh path because of the unique `(game_session_id, state_key)` index and `find_or_initialize_by` (`db/migrate/20260323080000_add_session_states_and_response_state_ops.rb:17`, `app/services/scenarios/romebots/active_states/apply_response_operations.rb:52`)
- Refresh overwrites `applied_turn`, `applied_year`, expiry fields, `source_card_key`, `source_response_key`, and `metadata`
- Turn-start recurring effects do **not** mutate `SessionState`; they mutate only `context_state` based on registry-defined `on_turn_start_effects` (`app/services/scenarios/romebots/active_states/process_turn_start.rb:23`)

### Expired / removed

#### Context state / flags

- There is no true delete path for `context_state` during normal play
- `Context::ApplyMutations#clear` sets `flags.*` to `false`, not nil/removal (`app/services/context/apply_mutations.rb:47`)
- Non-flag keys can become `nil` through `clear`, but current seeded gameplay appears to avoid this for main numeric keys
- New year rollover resets only the `time.*` cycle counters, not other context keys (`app/services/cycles/advance.rb:31`)

#### Active states / modifiers

- Explicit removal:
  - `ActiveStates::ApplyResponseOperations#remove_state!` destroys the row if present (`app/services/scenarios/romebots/active_states/apply_response_operations.rb:96`)
- Turn-duration expiry:
  - `ActiveStates::ProcessTurnStart#expire_finished_states!` destroys rows where `stale_state?` or `expires_after_upcoming_turn?` is true (`app/services/scenarios/romebots/active_states/process_turn_start.rb:47`)
- Year-end expiry:
  - `ActiveStates::ExpireForYearEnd#call` destroys rows whose `expires_year <= current_year` and `expires_turn.blank?` (`app/services/scenarios/romebots/active_states/expire_for_year_end.rb:13`)
- Session end cleanup:
  - `GameSession` has `has_many :session_states, dependent: :destroy` (`app/models/game_session.rb:8`)

## Main write paths

### Context / flags writes

1. `Sessions::StartRun#call`
   - seeds full `context_state`
2. `Choices::ResolveResponse#update_session_state!`
   - applies card response effects
   - increments `time.cards_resolved_this_year`
   - persists with `game_session.update!(context_state: updated_context)`
3. `ActiveStates::ProcessTurnStart#apply_recurring_effects!`
   - applies registry recurring effects before next card presentation
4. `Cycles::Advance#advance_cycle!`
   - increments year/cycle and resets resolved-card counter

### Active-state writes

1. `ActiveStates::ApplyResponseOperations#add_state!`
   - create/refresh `SessionState`
2. `ActiveStates::ApplyResponseOperations#remove_state!`
   - explicit destroy
3. `ActiveStates::ProcessTurnStart#expire_finished_states!`
   - automatic destroy after relevant turn
4. `ActiveStates::ExpireForYearEnd#call`
   - automatic destroy at year summary boundary

## Read paths used by card selection / resolution / rendering

### Card selection / deck building

- `Decks::BuildForSession#eligible?` reads:
  - `time.year` via `historical_year` (`app/services/decks/build_for_session.rb:105`)
  - `required_flags` from `game_session.context_state` (`app/services/decks/build_for_session.rb:131`)
  - `excluded_flags` from `game_session.context_state` (`app/services/decks/build_for_session.rb:135`)
  - `required_context` by exact equality against `game_session.context_state[key]` (`app/services/decks/build_for_session.rb:153`)
  - `required_session_states` using `game_session.session_states.pluck(:state_key)` (`app/services/decks/build_for_session.rb:145`)
- `Decks::BuildForSession#effective_weight` reads `SessionState` rows and registry `weight_modifiers` (`app/services/decks/build_for_session.rb:109`)

### Card resolution

- `Choices::ResolveResponse#response_effects` reads frozen response JSON from the current `SessionCard` (`app/services/choices/resolve_response.rb:42`)
- `Choices::ResolveResponse#response_state_operations` reads timed-state operations from the same `SessionCard` (`app/services/choices/resolve_response.rb:46`)
- `Sessions::CheckEndState#call` reads `state.health`, `state.public_order`, and `state.military_support` from `context_state` both before and after turn-start recurring effects (`app/services/sessions/check_end_state.rb`)

### UI rendering

#### Visible state panel

- `VisibleStatePresenter` reads `game_session.context_state` directly (`app/services/scenarios/romebots/visible_state_presenter.rb:105`)
- It derives:
  - candidate rows from configured keys plus discovered prefix matches (`:state.`, `:factions.`, `:relations.`) (`app/services/scenarios/romebots/visible_state_presenter.rb:62`)
  - recent deltas from the latest response event log payload, not from live mutation replay (`app/services/scenarios/romebots/visible_state_presenter.rb:192`)
  - cycle deltas from `deck_state["cycle_start_context"]` (`app/services/scenarios/romebots/visible_state_presenter.rb:230`)
  - active highlighting from `current_card` speaker/faction metadata, not from state rows (`app/services/scenarios/romebots/visible_state_presenter.rb:260`)
- Rendered in:
  - `app/views/sessions/_state_panel.html.erb`
  - `app/views/sessions/show.html.erb`

#### Active states panel

- `ActiveStatesPanelPresenter` reads `game_session.session_states` and reimplements its own `active?` filter (`app/services/scenarios/romebots/active_states_panel_presenter.rb:40`)
- It also scans `CardDefinition.spawn_rules["required_session_states"]` to tag active states as affecting eligibility (`app/services/scenarios/romebots/active_states_panel_presenter.rb:84`)
- Rendered in:
  - `app/views/sessions/_active_states_panel.html.erb`
  - `app/views/sessions/show.html.erb`

#### Chronicle / year summary

- `Choices::ResolveResponse#chronicle_payload` writes both `context_changes` and `session_states_added/removed` into `EventLog.payload` (`app/services/choices/resolve_response.rb:143`)
- `ChronicleEntryPresenter` reads those arrays for UI labels in `app/views/sessions/_event_log.html.erb`
- `YearSummary` reads:
  - current `context_state`
  - `deck_state["cycle_start_context"]`
  - `VisibleStatePresenter#state_snapshot`
  - `GameSession#state_snapshot` through `ActiveStates::ChronicleSnapshot`

## Problems / risks

### 1. Duplicate active-state liveness logic

- `ActiveStates::ProcessTurnStart` and `ActiveStatesPanelPresenter` each define their own rules for whether a `SessionState` is active.
- Files:
  - `app/services/scenarios/romebots/active_states/process_turn_start.rb`
  - `app/services/scenarios/romebots/active_states_panel_presenter.rb`
- Risk:
  - UI can drift from gameplay if one rule changes without the other.

### 2. Mutation ordering is important but implicit

- `Choices::ResolveResponse#update_session_state!` writes context effects, increments turn counter, persists, then applies active-state add/remove operations, and only later does `ProcessTurnStart` apply recurring effects for the next card.
- File:
  - `app/services/choices/resolve_response.rb:50`
- Risk:
  - Semantics such as "does a newly added timed state affect the very next card?" depend on this exact ordering.
  - The current answer is yes, because add/remove happens before `ProcessTurnStart`.

### 3. "Clear" does not mean remove for flags

- `Context::ApplyMutations#clear` maps `flags.*` to `false`, not missing/null.
- File:
  - `app/services/context/apply_mutations.rb:47`
- Risk:
  - Authoring JSON that says "clear flag" reads like deletion, but spawn-rule checks behave as simple falsey checks.
  - This is easy to misunderstand in content authoring.

### 4. Context keys are validated only by presence in the current hash

- `Context::ApplyMutations` rejects unknown keys by checking `context_state.key?(key)` at runtime.
- File:
  - `app/services/context/apply_mutations.rb:32`
- Risk:
  - The real schema is implicit in `Configuration.initial_context`.
  - Dynamically introduced keys outside initial context are impossible unless another writer manually inserts them first.
  - UI discovery code (`VisibleStatePresenter#candidate_keys_for`) suggests dynamic keys are expected, but mutation code discourages them.

### 5. Naming is not fully aligned across docs and code

- Runtime code uses `session_states` / "active states".
- The prompt language "modifiers" maps most closely to registry `weight_modifiers` plus timed `SessionState` rows.
- Older docs still use broader language like "flags" and "active session state".
- Files:
  - `app/services/scenarios/romebots/active_state_registry.rb`
  - `docs/scenarios/romebots/context_and_chronicles.md`
  - `docs/scenarios/romebots/overview.md`
- Risk:
  - Contributors can conflate persistent flags, numeric context, and timed active states.

### 6. Hidden transition via `deck_state["cycle_start_context"]`

- UI deltas and year summaries rely on a snapshot in `deck_state`, not on a first-class "cycle" model.
- Files:
  - `app/services/decks/build_for_session.rb:173`
  - `app/services/cycles/advance.rb:36`
  - `app/services/scenarios/romebots/visible_state_presenter.rb:239`
  - `app/services/scenarios/romebots/year_summary.rb:27`
- Risk:
  - This snapshot is operationally important, but it is stored under a generic JSON blob and only set opportunistically.

### 7. Possible stale / unreachable path smell: `response_state_operations`

- `Choices::ResolveResponse#response_state_operations` exists but is not used directly; actual processing goes through `ApplyResponseOperations`, which re-reads from `SessionCard`.
- File:
  - `app/services/choices/resolve_response.rb:46`
- Risk:
  - Small dead-code smell and another place for future divergence.

## Recommendations

1. Extract a single `SessionStateLifecycle` or `SessionStateStatus` helper that answers `active?`, `stale?`, and `expiring_after_upcoming_turn?`, then use it from both `ProcessTurnStart` and `ActiveStatesPanelPresenter`.
2. Introduce a small schema/registry object for context keys so `Configuration.initial_context` is not the only practical source of truth for valid keys and normalization rules.
3. Rename author-facing "clear" semantics in admin/docs to "set false" for flags, or document explicitly that `clear` on `flags.*` does not remove the key.
4. Consolidate context mutation entry points behind a single service that also owns turn-counter increments, instead of splitting "apply mutations here" and "increment time counter here".
5. Move `cycle_start_context` handling behind a dedicated helper so presenters and summaries stop reaching into `deck_state` directly.
6. Add a narrow "state terminology" doc section or code comment near `GameSession`/`SessionState` clarifying:
   - `context_state` = persistent truth
   - `session_states` = timed modifiers
   - `weight_modifiers` = registry metadata that only matters during deck building
7. Remove or inline `Choices::ResolveResponse#response_state_operations` unless you plan to reuse it.

## Lowest-risk cleanup target for tonight

The safest cleanup is **removing or inlining the unused `Choices::ResolveResponse#response_state_operations` helper** in `app/services/choices/resolve_response.rb`.

Why this is lowest risk:

- it is documentation-level dead-code cleanup
- it does not change persisted data shape
- it does not alter mutation ordering
- it reduces one misleading read path without touching gameplay behavior

The next-lowest-risk cleanup after that would be extracting shared `SessionState` liveness predicates without changing their logic.
