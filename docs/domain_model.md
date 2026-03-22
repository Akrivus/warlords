# Domain Model

This document defines the core engine entities for RomeBots.

RomeBots is a reusable card-state engine.  
These models should represent engine-level concepts, not hardcoded RomeBots assumptions.

## Core entities

### GameSession

Represents one player run or save state for a specific scenario.

Responsibilities:
- identify the scenario being played
- store mutable session context
- track current cycle and deck state
- track active card
- track overall run status
- provide the main source of truth for progression

Possible attributes:
- scenario_key
- status
- cycle_number
- current_card_id
- context_state (jsonb)
- deck_state (jsonb)
- seed
- started_at
- ended_at

Notes:
- `context_state` stores persistent and temporal context
- `deck_state` can store cycle-local deck metadata early on
- some JSONB may later be normalized if needed

---

### CardDefinition

Represents a canonical authored or system card definition.

Responsibilities:
- define when a card is eligible
- define the card text and metadata
- define the two responses and their effects
- act as reusable source content across sessions

Possible attributes:
- scenario_key
- key
- title
- body
- speaker_type
- speaker_key
- speaker_name
- portrait_key
- faction_key
- card_type
- active
- weight
- tags (jsonb)
- spawn_rules (jsonb)
- response_a_text
- response_a_effects (jsonb)
- response_a_follow_up_card_key
- response_b_text
- response_b_effects (jsonb)
- response_b_follow_up_card_key
- metadata (jsonb)

Notes:
- `scenario_key` scopes cards to a scenario
- `card_type` may distinguish authored/system/generated-template if needed
- `spawn_rules` should remain data-driven where practical
- complex rules may still delegate to scenario services

---

### SessionCard

Represents a card instance attached to a specific game session.

Responsibilities:
- capture the actual card shown in a run
- track per-session card status
- preserve generated or mutated card content if needed
- track which response was chosen

Possible attributes:
- game_session_id
- card_definition_id (nullable for fully generated cards)
- source_type
- speaker_type
- speaker_key
- speaker_name
- portrait_key
- faction_key
- cycle_number
- slot_index
- status
- title
- body
- response_a_text
- response_a_follow_up_card_key
- response_b_text
- response_b_follow_up_card_key
- chosen_response
- resolution_summary
- generation_params (jsonb)
- fingerprint
- metadata (jsonb)

Notes:
- authored cards can be copied into `SessionCard` for historical stability
- generated cards can exist without a `CardDefinition`
- this is the runtime object the UI will usually present

---

### EventLog

Represents a structured record of what happened in a session.

Responsibilities:
- record card presentation and resolution history
- support player recap
- support debugging and balancing
- support future timeline views

Possible attributes:
- game_session_id
- event_type
- title
- body
- payload (jsonb)
- occurred_at
- cycle_number
- card_key
- session_card_id

Notes:
- append-only in normal play
- useful for both UX and debugging

## Optional / near-term engine entities

### ScenarioDefinition (optional model or config-backed concept)

Represents metadata about a scenario.

Possible attributes:
- key
- name
- description
- active
- metadata (jsonb)

Notes:
- this may start as code/config instead of a table
- useful if multiple scenarios are surfaced in the UI

---

### GeneratedCardTemplate (future)

Represents reusable generated card content or archetypes.

Possible attributes:
- scenario_key
- fingerprint
- title
- body
- response_a_text
- response_b_text
- tags (jsonb)
- input_signature (jsonb)
- quality_score
- approved
- metadata (jsonb)

Notes:
- future only
- not required for milestone 1

## Relationships

Likely first-pass relationships:

- `GameSession has_many :session_cards`
- `GameSession has_many :event_logs`
- `GameSession belongs_to :current_card, class_name: "SessionCard", optional: true`

- `SessionCard belongs_to :game_session`
- `SessionCard belongs_to :card_definition, optional: true`

There is intentionally no direct assumption that all cards are authored or that all sessions share the same deck logic.

## State storage strategy

Initial recommended approach:
- store most mutable state in `GameSession.context_state` (jsonb)
- store some cycle-local metadata in `GameSession.deck_state` (jsonb)
- use `SessionCard` for per-run card history and active deck representation

This allows:
- rapid iteration
- debuggability
- flexibility while rules are still evolving

Avoid premature normalization of every context key.

## Service/domain objects

These should be plain Ruby services or POROs rather than Active Record models.

### Sessions::StartRun
Creates a new session for a given scenario.

### Decks::BuildForSession
Builds or refreshes the current cycle's deck.

### Cards::EligibleForSession
Finds or evaluates cards that can spawn given context.

### Cards::PresentNext
Chooses the next card to show from the active deck.

### Choices::ResolveResponse
Validates and resolves response A or B.

### Context::ApplyMutations
Applies structured context changes.

### Cycles::Advance
Handles cycle progression rules.

### Sessions::CheckEndState
Determines whether the session should end.

### Logs::RecordEvent
Writes structured event log entries.

## First-pass schema bias

The minimum useful tables for milestone 1 are likely:
- game_sessions
- card_definitions
- session_cards
- event_logs

This is enough to prove the core loop.

## Questions intentionally left open

These do not need to be fully solved immediately:
- whether `ScenarioDefinition` is DB-backed or code/config-backed
- whether `spawn_rules` are fully declarative or partly service-driven
- whether deck order is precomputed or partially dynamic
- whether `deck_state` should remain JSONB or be partially normalized later
- whether generated cards should ever become reusable templates
