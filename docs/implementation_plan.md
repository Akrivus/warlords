# Implementation Plan

## Goal

Build RomeBots as a reusable card-state engine, then prove it through the RomeBots scenario.

The first implementation should prioritize a playable vertical slice over broad future-proofing.

## Phase 1: RomeBots vertical slice

Build the smallest playable version of the engine through one scenario.

Scope:
- landing page
- start a RomeBots run
- create a `GameSession`
- seed a small set of RomeBots `CardDefinition` records
- build a year-1 deck
- create `SessionCard` records for that deck
- present one active card
- choose response A or B
- resolve the response in backend services
- apply context mutations
- record event log entries
- advance to the next card
- continue through multiple cards

Technical targets:
- ERB views
- standard Rails controllers
- JSONB-backed context state
- PORO services for deck building and response resolution
- minimal styling
- tests for the core loop

Success criteria:
- a player can start a RomeBots run
- a 12-card year is generated (or partially represented in milestone form)
- a card is shown
- the player picks one of two responses
- the session state changes
- the next card becomes available

## Phase 2: stronger engine structure

Refine the generic engine boundaries.

Scope:
- cleaner separation between engine services and scenario services
- year-summary state between RomeBots cycles
- explicit cycle advancement service instead of automatically chaining years
- small end-state seam with deterministic catastrophic failures only
- explicit scenario namespace structure
- improved deck summary / cycle summary UI
- stronger event log display
- clearer session end-state handling
- more robust authored fallback card handling

Success criteria:
- the engine no longer feels tightly welded to RomeBots
- the RomeBots scenario remains easy to extend

## Phase 3: UI polish and progressive enhancement

Scope:
- Turbo improvements
- partial-based layout cleanup
- helper-based delta formatting
- sound preference settings
- optional audio cue hooks
- mobile polish

Success criteria:
- the app feels smooth and coherent without adding architectural chaos

## Phase 4: content and scenario expansion

Potential additions:
- richer RomeBots card pool
- multiple endings
- authored fallback systems
- scenario selection UI
- scenario metadata
- stronger deck visualization
- first experiments with generated cards (if still justified)

## Phase 5: future engine expansion (not required now)

Potential future work:
- generated card templates
- AI-assisted card filling
- world-influenced deck building
- shared-state or async scenario experiments
- Diado scenario prototype

This phase should only happen after the core loop is proven fun.

## Architectural principles

- engine layer stays generic
- scenario layer owns game-specific rules
- controllers stay thin
- core rules live in service/domain objects
- context mutations are structured and testable
- do not build multiplayer/shared-world systems before they are required
- do not make generated cards a dependency for milestone 1

## Testing strategy

At minimum:
- model validations and associations
- service tests for deck building
- service tests for response resolution
- request/system tests for:
  - starting a run
  - seeing an active card
  - choosing a response
  - advancing state

As complexity grows:
- test scenario-specific eligibility
- test cycle transitions
- test fallback card filling
- test end-state conditions
