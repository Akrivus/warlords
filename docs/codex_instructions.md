# Codex Instructions

This repository is a Rails application for RomeBots, a reusable card-driven narrative strategy engine.

The first scenario is RomeBots, but the engine should remain generic enough to support future scenarios.

You should treat `README.md` and the files in `docs/` as the intended architecture unless the implementation clearly supersedes them.

## Core technical preferences

Prefer:
- standard Rails conventions
- ERB templates
- Turbo
- Stimulus only for lightweight enhancements
- plain Ruby service/domain objects for game rules
- JSONB for flexible early-state storage
- small, testable increments

Avoid:
- introducing React, Vue, or other major frontend frameworks unless explicitly requested
- embedding gameplay rules in controllers or helpers
- building speculative multiplayer/shared-world systems early
- over-generalizing before the RomeBots vertical slice is playable
- rewriting unrelated code while implementing focused tasks

## Product architecture

RomeBots has three conceptual layers:

1. Engine layer
   - generic session, card, deck, context, and resolution logic

2. Scenario layer
   - game-specific rules and content (RomeBots first)

3. Presentation layer
   - Rails controllers, views, helpers, and lightweight JS

Do not hardcode RomeBots assumptions into the engine layer if a small abstraction boundary can prevent it.

Do not build broad abstraction systems that are not yet required by the RomeBots vertical slice.

## Core gameplay assumptions

The primary gameplay unit is a card.

A card:
- is presented to the player
- contains exactly two responses
- mutates session state when resolved

The core loop is:
- load session
- build or refresh deck for current cycle
- present active card
- submit response A or B
- resolve in backend logic
- mutate context
- log the result
- advance to next card or cycle

## Core models

The initial core models are likely:
- `GameSession`
- `CardDefinition`
- `SessionCard`
- `EventLog`

It is acceptable for milestone 1 to keep most mutable state in:
- `GameSession.context_state` (jsonb)
- `GameSession.deck_state` (jsonb)

Avoid prematurely normalizing every context concept.

## Service/domain expectations

Core logic should live in service objects or POROs such as:
- `Sessions::StartRun`
- `Decks::BuildForSession`
- `Cards::EligibleForSession`
- `Cards::PresentNext`
- `Choices::ResolveResponse`
- `Context::ApplyMutations`
- `Cycles::Advance`
- `Sessions::CheckEndState`
- `Logs::RecordEvent`

These names may evolve, but the separation of concerns should remain.

## Scenario expectations

The first scenario is RomeBots.

RomeBots assumptions:
- scenario key: `romebots`
- one cycle = one year
- each year should produce a 12-card deck
- authored cards are the primary content source
- generic authored fallback cards are preferred over AI-generated cards in early development

Future scenarios (such as Diado) may have different deck generation rules.

Do not implement future scenario complexity unless explicitly requested.

## Frontend expectations

The UI is HTML-first and server-driven.

Prefer:
- ERB partials
- Turbo updates for active card, state summary, and event log
- minimal JS for enhancements only

The main active session UI should prioritize:
- active card display
- two response actions
- visible state summary
- recent event log
- cycle/deck progress

## Testing expectations

For any non-trivial behavior:
- add or update tests

At minimum, test:
- deck creation
- card presentation
- response resolution
- context mutation
- session advancement

Do not leave major gameplay logic untested if it can reasonably be tested.

## Working style

When implementing a task:
1. Read the relevant docs first
2. Inspect the current project structure
3. Make a small implementation plan
4. Implement incrementally
5. Run tests or otherwise validate the change
6. Summarize what changed and any assumptions made

## Documentation expectations

If implementation materially changes intended behavior or structure:
- update the relevant docs

Do not let docs silently drift away from reality.

## When requirements are unclear

Prefer:
- the simplest implementation that supports the RomeBots vertical slice
- preserving future scenario compatibility through small seams
- explicit TODO notes over speculative systems
- authored content over generated content in milestone 1