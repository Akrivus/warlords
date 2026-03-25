# Card Authoring Contract

This document describes the current hand-authored card/content contract implemented in this codebase as of March 25, 2026.

It is intentionally descriptive, not aspirational. The goal is to define what the engine actually accepts and how authored data is actually interpreted today.

## Scope

The primary authoring record is `CardDefinition`.

- Persisted source: `card_definitions` table
- Runtime copy: `session_cards` rows are snapshots copied from a `CardDefinition` when a deck is built or a follow-up card is enqueued
- Current supported scenario: only `scenario_key: "romebots"` is accepted by `Sessions::StartRun`

## Normalized Card Shape

A currently valid authored card is a `CardDefinition` with this effective shape:

```ruby
{
  scenario_key: String,
  key: String,
  title: String,
  body: String,
  card_type: "authored" | "system" | "generated",
  active: true | false,
  weight: Integer,
  tags: Array,
  spawn_rules: Hash,
  response_a_text: String,
  response_a_effects: Array,
  response_a_states: Array,
  response_a_follow_up_card_key: String | nil,
  response_b_text: String,
  response_b_effects: Array,
  response_b_states: Array,
  response_b_follow_up_card_key: String | nil,
  speaker_name: String | nil,
  speaker_type: String | nil,
  speaker_key: String | nil,
  portrait_key: String | nil,
  faction_key: String | nil,
  portrait_upload: ActiveStorage attachment | nil,
  metadata: Hash
}
```

Important normalization notes:

- The story text field is `body`. There is no separate persisted `text` field.
- In ActiveAdmin, authors edit JSON-backed fields through textareas:
  - `tags_json`
  - `spawn_rules_json`
  - `response_a_effects_json`
  - `response_a_states_json`
  - `response_b_effects_json`
  - `response_b_states_json`
- Those textarea values are parsed with `JSON.parse` before validation completes.
- The engine copies card content into `SessionCard`, so later edits to the definition do not alter already-built deck cards.

## Core Fields

### Required persisted fields

These are model-validated and must be present on `CardDefinition`:

- `scenario_key`
- `key`
- `title`
- `body`
- `response_a_text`
- `response_b_text`
- `card_type`
- `weight`

Additional model rules:

- `card_type` must be one of `authored`, `system`, `generated`
- `weight` must be an integer
- `key` must be unique within `scenario_key`
- `speaker_name` becomes required if either `speaker_type` or `speaker_key` is present

### Optional but implemented fields

- `active`
  - Default `true`
  - Deck building only considers `active` cards
- `metadata`
  - Present in schema, but not part of the current authoring contract for seeded/manual cards

### `id`

- Database primary key only
- Not used as an author-facing identity key in gameplay
- Runtime follow-ups and deck logic use `key`, not `id`

### Title and body/text

- `title` is the card headline shown to the player
- `body` is the full card text shown to the player
- No separate `text` alias exists in the implementation

### Year / phase / availability

There is no dedicated `year`, `phase`, or `availability` column.

Availability is encoded inside `spawn_rules`. Currently implemented keys are:

- `min_year`
- `max_year`
- `one_time_only`
- `repeatable`
- `required_flags`
- `excluded_flags`
- `required_context`
- `required_session_states`

`phase` is not implemented anywhere as a first-class concept.

### Tags

- Stored as `tags` JSON with default `[]`
- Used in deck weighting via active-state `weight_modifiers`
- Not currently validated for element type, format, or uniqueness
- In practice, seeds use arrays of lowercase strings

### Weights / priorities

- Base card weight is `weight` (integer)
- Selection order is by descending `effective_weight`, then `key`
- `effective_weight = weight + session_state_weight_modifiers`
- There is no separate `priority` field
- The closest equivalent to author-facing priority is high `weight`

### Involved characters / entities

Current structured speaker/entity fields:

- `speaker_name`
- `speaker_type`
- `speaker_key`
- `faction_key`

These are display and flavor metadata copied into `SessionCard`.

Current behavior:

- `speaker_name` is rendered in the UI
- `speaker_type` and `faction_key` are rendered as chips
- `speaker_key` is stored but mainly acts as a stable metadata handle
- There is no array of involved characters/entities; only a single speaker/faction bundle is modeled directly

### Image / icon references

Current implemented card portrait fields:

- `portrait_key`
- `portrait_upload`

Behavior:

- Uploaded `portrait_upload` overrides `portrait_key` asset lookup in admin/UI flows
- `portrait_key` is copied into `SessionCard`
- There is no separate card icon field in `CardDefinition`
- State icons exist elsewhere in `Configuration::DISPLAY_CONFIG`, but those are not part of card authoring

## Conditions

Conditions are encoded in `spawn_rules`.

### Currently supported `spawn_rules` keys

#### Chronology / year gating

- `min_year`
- `max_year`

Eligibility fails when:

- current `time.year < min_year`
- current `time.year > max_year`

#### Flags

- `required_flags: [context_key, ...]`
- `excluded_flags: [context_key, ...]`

Behavior:

- Each entry is checked directly against `game_session.context_state`
- `required_flags` require a truthy value
- `excluded_flags` require a falsey value
- Keys are not validated at author-save time

#### Context states

- `required_context: [{ key:, equals: ... }]`
- `required_context: [{ key:, value: ... }]`

Behavior:

- Each condition is normalized with string keys
- `equals` and `value` are treated as synonyms
- If neither `equals` nor `value` is supplied, the engine assumes the expected value is `true`
- Matching is exact equality only
- No operators like `>`, `<`, `>=`, `includes`, or range checks currently exist

#### Modifiers / active session states

- `required_session_states: [state_key, ...]`

Behavior:

- Every listed state key must appear in current `session_states`
- These keys are compared as strings
- There is no author-save validation that the state key exists in `State::Registry`

#### Reuse / repetition controls

- `one_time_only: true`
- `repeatable: true`

Behavior:

- `repeatable: true` always allows reuse
- Otherwise, `one_time_only: true` blocks the card if any `session_card` in the run already used that `card_definition`
- If neither key is present, a card is reusable across cycles only if selected again and not otherwise blocked
- Repeatable cards may be duplicated to fill the deck to `Configuration::DECK_SIZE`

### Scenario-specific conditions

There is no generic plug-in condition DSL today.

The only scenario-specific conditioning currently comes from:

- `scenario_key`
- the concrete `ContextSchema` key set seeded by `Configuration.initial_context`
- `State::Registry` definitions used by `required_session_states` and weight modifiers

## Choices

The player-facing model currently assumes exactly two choices.

### Required choice fields

- `response_a_text`
- `response_b_text`

These are required by model validation and rendered as the two response buttons.

### Optional choice fields

For each choice branch:

- `response_[a|b]_effects`
- `response_[a|b]_states`
- `response_[a|b]_follow_up_card_key`

Current defaults in schema:

- effects arrays default to `[]`
- state-operation arrays default to `[]`
- follow-up keys default to `nil`

### Follow-ups / nested actions

Follow-up support is implemented through:

- `response_a_follow_up_card_key`
- `response_b_follow_up_card_key`

Behavior:

- The key is resolved within the same `scenario_key`
- If a matching pending card for the current cycle already exists, that card is reused and marked with follow-up metadata
- Otherwise, the engine can create a new `SessionCard` snapshot from the referenced `CardDefinition`
- Follow-up creation is blocked if a card with that definition key has already appeared in the current cycle
- Follow-up depth is capped at 1 through `metadata["follow_up_depth"]`
- Missing referenced follow-up definitions fail silently at runtime by producing no follow-up card

There is no deeper nested authored action tree beyond:

- immediate effects
- state add/remove operations
- one optional follow-up card per response

## Effects

Current response handling splits into two effect buckets:

- immediate context mutations: `response_[a|b]_effects`
- persistent/timed session-state operations: `response_[a|b]_states`

### Immediate effect types

`response_[a|b]_effects` must be an array of mutation hashes interpreted by `Context::ApplyMutations`.

Currently supported `op` values:

- `set`
- `increment`
- `decrement`
- `clear`

Normalized mutation shape:

```ruby
{ op: String, key: String, value: any }
```

Actual runtime rules:

- `op` is required
- `key` is required
- `value` is used by `set`, `increment`, and `decrement`
- `clear` ignores `value`

### State mutation types

`response_[a|b]_states` must be an array of state operation hashes interpreted by `State::ApplyResponseOperations`.

Currently supported `action` values:

- `add`
- `remove`

Normalized shapes:

```ruby
{ action: "add", key: String, duration: { turns: Integer } | { until_year_end: true } }
{ action: "remove", key: String, reason: String? }
```

Behavior:

- `key` must exist in `State::Registry` or resolution raises an error
- `add` refreshes an existing state row if the same `state_key` is already active
- `remove` is a no-op if the state row is absent

### Immediate vs persistent effects

#### Immediate

- Applied from `response_[a|b]_effects`
- Written into `game_sessions.context_state`
- Applied before `time.cards_resolved_this_year` is incremented
- Then `time.cards_resolved_this_year` is incremented by 1 as part of response resolution

#### Persistent / timed

- Applied from `response_[a|b]_states`
- Stored as `session_states` rows
- May carry duration:
  - `{ turns: N }`
  - `{ until_year_end: true }`
  - omitted, which means no expiry is recorded
- May apply recurring context mutations on future turns via `State::Registry[:on_turn_start_effects]`

### Supported key families and normalization

Immediate context mutations are normalized by key prefix:

- `flags.*`
  - coerced to boolean
  - `clear` becomes `false`, not deletion
- `state.*`
  - coerced to integer
  - clamped to `0..100`
- `relations.*`
  - coerced to integer
  - clamped to `-5..5`
- `factions.*`
  - coerced to integer
  - clamped to `-5..5`
- `time.*`
  - coerced to integer

Unknown keys raise at resolution time unless they already exist in the current `context_state`.

### Recurring effects from persistent states

Persistent state definitions live in `State::Registry`, not in card JSON.

Current state keys:

- `guard_mobilized`
- `whisper_campaign`
- `grain_crisis`
- `eastern_intrigue`
- `mourning_period`
- `veteran_discontent`

Each registry entry may define:

- `default_duration`
- `on_turn_start_effects`
- `weight_modifiers`
- presentation metadata like `name`, `description`, `category`, `chronicle_tags`, `visibility`

### Follow-up triggers / event logging

Response resolution records event data in `event_logs`.

Current logged authored-effect payloads include:

- `card_key`
- `card_title`
- `card_body`
- `response_key`
- `response_text`
- `response_log`
- `immediate_effects`
- `context_changes`
- `session_states_added`
- `session_states_removed`

Other effect-related event types include:

- `follow_up_queued`
- `session_state_added`
- `session_state_removed`
- `active_states_processed`
- `session_state_expired`

## What Actually Gets Validated

### Validated today

- required core strings listed above
- `card_type` inclusion
- `weight` integer-ness
- `key` uniqueness within scenario
- JSON textarea syntactic validity when using admin virtual fields
- `speaker_name` presence when `speaker_type` or `speaker_key` is set

### Not validated today

- `tags` element type / string-ness / uniqueness
- `spawn_rules` shape
- allowed `spawn_rules` keys
- `required_flags` / `excluded_flags` key existence
- `required_context` item shape
- `required_context` operators
- `required_session_states` key existence
- `response_[a|b]_effects` item shape
- `response_[a|b]_effects[*].op` at author-save time
- `response_[a|b]_effects[*].key` existence at author-save time
- `response_[a|b]_states` item shape
- `response_[a|b]_states[*].action` at author-save time
- `response_[a|b]_states[*].key` registry existence at author-save time
- follow-up key existence
- self-referential / circular follow-up authoring
- `speaker_type` allowed vocabulary
- `portrait_key` asset existence
- `faction_key` vocabulary

## Validation Gaps And Inconsistencies

### Missing validation

Concrete missing checks:

- A card can save with malformed `spawn_rules` semantics as long as the JSON parses.
- A card can save with unsupported effect ops and only fail when the response is chosen.
- A card can save with unknown context keys and only fail when that branch resolves.
- A card can save with unknown `response_[a|b]_states[*].key` and only fail when chosen.
- A follow-up card key can point to no card at all; the admin UI warns visually, but model validation does not enforce it.
- `scenario_key` is only presence-validated on `CardDefinition`, even though gameplay only supports `romebots`.

### Inconsistent field usage

- Story text is always `body`, but requirement language and some docs may say `text`.
- Availability is encoded in `spawn_rules`, not dedicated fields.
- "Modifiers" in product language map to two different runtime systems:
  - active `session_states`
  - registry `weight_modifiers`
- There is no `priority` field, only `weight`.

### Duplicate semantics under different names

- `required_context` accepts both `equals` and `value` for the same exact-equality comparison.
- `clear` reads like deletion, but for `flags.*` it means `set false`.
- "Active state", "session state", and "modifier" refer to overlapping but not identical concepts in docs/code.

### References that can break silently

- `response_[a|b]_follow_up_card_key`
  - missing target card does not raise during author save
  - runtime simply produces no follow-up
- `portrait_key`
  - missing asset can fall back to placeholder presentation
- `required_flags` / `excluded_flags`
  - typoed keys simply evaluate against missing/falsey context and may change eligibility silently
- `required_context`
  - typoed keys compare against `nil` and can silently fail eligibility
- tag-driven weight modifiers
  - mistyped tags do not raise; they just stop affecting weight

## Practical Authoring Rules For Today

If you are hand-authoring a card against the current implementation, the safest contract is:

1. Treat `key`, `title`, `body`, `response_a_text`, and `response_b_text` as mandatory.
2. Use only `scenario_key: "romebots"` for playable content.
3. Put availability logic only in `spawn_rules`, using the currently implemented keys listed above.
4. Use only the supported immediate mutation ops: `set`, `increment`, `decrement`, `clear`.
5. Use only the supported session-state actions: `add`, `remove`.
6. Restrict context keys to those already present in `Configuration.initial_context`.
7. Restrict session-state keys to those defined in `State::Registry`.
8. Treat follow-up card keys as same-scenario `CardDefinition.key` references.

## Concrete Validation Needs

The current implementation would benefit most from:

- schema validation for `spawn_rules`
- schema validation for response effects and state operations
- author-time validation of context keys against `ContextSchema`
- author-time validation of session-state keys against `State::Registry`
- author-time validation of follow-up key references within `scenario_key`
- normalization of `required_context` to one comparison key name
- explicit documentation or UI wording that `clear flags.*` means `false`, not removal
