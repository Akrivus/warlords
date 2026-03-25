# Context and Chronicle Architecture

## Purpose

This note clarifies how RomeBots session truth should be represented.

The current prototype already uses `GameSession.context_state` as the main source of truth for session state.  
This remains correct.

What needs refinement is the distinction between:

- stable session truth
- timed or behavior-bearing state
- raw event history
- curated historical memory

This document defines that split.

## Core idea

RomeBots has one overall session truth model.

That truth is made of four layers:

1. `context_state` for stable and current session truth
2. active session states for timed or recurring modifiers
3. event logs for raw mechanical history
4. chronicle entries or chronicle summaries for curated historical memory

These layers serve different purposes and should not be collapsed into one system.

---

## 1. Context State

`GameSession.context_state` remains the primary store for stable session truth.

Use it for:
- scalar values
- relationship values
- faction values
- permanent facts

Examples:
- `state.legitimacy`
- `state.treasury`
- `state.public_order`
- `relations.cicero`
- `relations.antony`
- `factions.senate`
- `flags.caesar_adopted`
- `flags.married`
- `flags.cicero_dead`

### Rules

- `context_state` should remain easy to inspect and debug
- permanent facts should stay here
- numeric values should stay here
- relationships and faction values should stay here
- not every current truth needs its own table

### Important distinction

Some context entries are effectively permanent facts.  
Examples:
- adopted
- married
- heir exists
- rival is dead

These should remain simple context values without expiry logic.

---

## 2. Active Session States

Some session truths are not simple facts. They:
- last for a limited time
- may apply recurring effects
- may influence future card selection
- may shape year summaries or historical memory

Examples:
- `guard_mobilized`
- `whisper_campaign`
- `grain_crisis`
- `mourning_period`
- `veteran_discontent`

These are called **active session states**.

### Why they are separate

These states need metadata such as:
- when they started
- when they expire
- what card/response created them
- whether they apply recurring effects
- whether they modify future card weighting or eligibility

That metadata does not fit cleanly into plain boolean flags.

### Recommended persistence model

Persist active states as database rows tied to a `GameSession`.

Suggested model:
- `ActiveSessionState`

Suggested fields:
- `game_session_id`
- `state_key`
- `source_card_key`
- `source_response_key`
- `applied_turn`
- `applied_year`
- `expires_turn`
- `expires_year`
- `metadata`

### Definition source

The meaning of each possible active state does **not** need a DB table yet.

For v1, state definitions should live in plain Ruby code as a small registry/hash/module.

This registry defines:
- what a state means
- default duration
- recurring effects
- card-weight modifiers
- optional chronicle tags

This is not a DB-backed authoring system yet.

### Why a Ruby registry is acceptable

In the current prototype, the definition behavior already acts like code-backed data.  
Persisting active instances in the DB is enough for runtime truth.

There is no need yet to build a `StateDefinition` database model or admin CRUD just to define:
- `guard_mobilized`
- `grain_crisis`
- `whisper_campaign`

That would be extra ceremony without clear product value.

---

## 3. Event Log

`EventLog` should remain the raw mechanical history of the run.

Use it for:
- debugging
- audit trail
- replaying what happened
- tracing card resolution and state changes

Examples:
- year began
- yearly deck assembled
- card shown
- response chosen
- immediate effects applied
- active state added or removed

### Rules

- event logs can remain structured and complete
- event logs do not need to be elegant prose
- event logs should prioritize correctness and inspectability

The event log is not the same thing as the chronicle.

---

## 4. Chronicle

The chronicle is curated historical memory.

It should answer questions like:
- what kind of ruler is emerging?
- what major pressures defined this year?
- what should future cards “remember”?
- what is fun and meaningful for the player to reread?

The chronicle is not a replay of every card in order.

### Chronicle goals

- readable
- selective
- state-aware
- useful for summaries
- useful for future content generation
- more narrative than stdout

Examples:
- “The veterans were paid, and Caesar’s old soldiers remembered.”
- “Antony’s whisper campaign spread through Rome for much of the year.”
- “Octavian chose caution entering the city, building his circle before his spectacle.”

### Chronicle relationship to EventLog

- `EventLog` = exact mechanical trace
- `Chronicle` = curated memory layer

Chronicle entries may be:
- separate persisted rows later
- derived summaries at year end first
- generated only for important events in v1

A full chronicle table is not required immediately if year summaries can serve the first milestone.

---

## Definitions vs Instances

This distinction matters:

### Definitions
These describe what a thing means.
Examples:
- what `grain_crisis` does
- what `guard_mobilized` does
- what card-weight bias `whisper_campaign` applies

Definitions can live in code for now.

### Instances
These describe what is currently active in a session.
Examples:
- `grain_crisis` active in this run
- expires at year end
- came from `grain_anxiety`, response A

Instances should be persisted because they are runtime session truth.

---

## Recommended v1 implementation shape

### Keep:
- `GameSession.context_state` as JSONB
- `EventLog` as raw history

### Add:
- `ActiveSessionState` model for timed/recurring states
- a small Ruby registry for active state definitions
- optional year-summary / chronicle generation that uses:
  - context deltas
  - important event logs
  - active/recent session states

### Do not add yet:
- DB-backed state definition admin
- a generic rules engine
- stacked duplicate state behavior
- a giant chronicle CMS

---

## Runtime flow

### On card response
1. apply immediate response effects to `context_state`
2. add/remove any active session states
3. write raw `EventLog`
4. optionally mark the event as chronicle-worthy or produce better summary text later

### Before next playable card / turn start
1. process recurring effects from active session states
2. apply those effects to `context_state`
3. expire states whose duration has ended
4. use active session states when building/selecting future cards where supported by the current engine

### At year end
1. expire year-end states
2. generate a year summary / chronicle summary
3. build the next year

---

## Naming guidance

Use these terms consistently:

- **context state** = persistent session truth in `GameSession.context_state`
- **active session state** = timed or recurring `SessionState` instance
- **weight modifier** = registry metadata used only during deck building to bias future card selection
- **event log** = raw mechanical history
- **chronicle** = curated historical memory

Avoid mixing these concepts under a vague umbrella like “flags” once timing and recurring behavior are involved.

For authoring semantics:

- `clear` on `flags.*` means "set false"
- it does **not** delete the key or remove the flag from `context_state`

---

## Summary

RomeBots session truth should be treated as:

- `context_state` for stable facts and numeric values
- `ActiveSessionState` rows for timed or recurring modifiers
- `weight_modifiers` in the Ruby registry for deck-building bias metadata
- `EventLog` for raw history
- `Chronicle` or year summaries for readable historical memory

This keeps the system explicit, testable, and easier to extend without turning all state into either plain flags or a giant rules engine.
