# Game Flow

## Purpose

This document defines the core gameplay loop for RomeBots.

RomeBots is a card-driven state engine:
- session state determines which cards are eligible
- a deck or card pool is built from eligible cards
- the player resolves cards by choosing one of two responses
- responses mutate state
- mutated state affects future card availability and outcomes

The first scenario (RomeBots) is a specific implementation of this loop:
- one turn = one year
- each year produces a 12-card deck
- the player resolves cards over the course of the run

## Core engine loop

1. Player starts or resumes a session
2. The system loads session state/context
3. The system determines whether a new cycle/deck must be built or refreshed
4. Eligible cards are selected based on current context and scenario rules
5. The current active card is presented
6. The player selects response A or response B
7. The backend validates and resolves the response
8. The response applies structured mutations to session context
9. The action and outcome are written to the event log
10. The session advances:
   - current card resolves
   - deck state updates
   - cycle progression may update
   - end-state conditions may be checked
11. If cards remain, the next active card is rendered
12. If the cycle is exhausted, the session may enter a year-summary or transition state before the next cycle begins
13. If an end-state is reached, an ending state is rendered
14. The loop repeats until the session ends

## Session lifecycle

A session represents one run or save state for a specific scenario.

A session should track:
- scenario key
- overall status
- current cycle position
- current card state
- session context
- deck state
- event history
- end state if complete

A session may be:
- active
- year_summary
- paused
- completed
- failed
- abandoned

## Cycle lifecycle

A cycle is a scenario-defined unit of progression.

Examples:
- RomeBots: one cycle = one year
- Future scenarios may use seasons, turns, reign phases, campaign phases, etc.

A cycle may:
- generate a new deck
- refill or partially rebuild card slots
- advance time
- apply passive effects
- unlock or retire card families

The engine should support scenario-defined cycle rules.

RomeBots currently pauses at a year-summary state after the final card of a year resolves. The next year only begins when the player explicitly continues.

## Deck lifecycle

A deck or card pool is the current set of cards available within a cycle.

The exact presentation may vary by scenario, but conceptually the engine should support:
- selecting authored cards based on eligibility
- ordering or weighting those cards
- filling required slots if the scenario expects a fixed deck size
- tracking which cards are pending, resolved, skipped, exhausted, or discarded

In RomeBots:
- each year should generate a 12-card deck
- eligible authored cards are selected first
- missing slots may eventually be filled by generic system cards or generated cards
- initial implementation should prefer authored fallback cards before AI-generated cards

## Card lifecycle

A card is the primary gameplay unit.

A card contains:
- a prompt or event description
- optional metadata such as tags or category
- exactly two responses
- rules for when it can appear
- rules or effects for what each response does

A card may be:
- authored (hand-built content)
- system (generic fallback content)
- generated (AI-assisted or templated dynamic content)

Initial implementation should focus on authored cards.

## Response lifecycle

Each card has exactly two responses:
- response A
- response B

A response may:
- mutate context values
- set or clear flags
- increment counters
- branch future eligibility
- pull a single authored follow-up card forward
- add event log entries
- trigger cycle or deck updates
- trigger end-state checks

The response should resolve on the backend and return a structured result.

## Context model

Session context is the main source of truth for card eligibility and outcome resolution.

Context should be stored as structured keys, not inferred solely from event history.

Examples:
- `politics.senate_support`
- `military.legion_loyalty`
- `family.married`
- `rivals.antony_status`
- `public.unrest`
- `time.year`

Context operations should support:
- set a key
- increment or decrement a value
- clear or reset a key
- append tags or markers if needed

The engine should treat context as:
- persistent context (longer-term state)
- temporal context (cycle-specific or short-lived state)
- derived context (computed values, not always stored)

## Event logging

Every resolved card should generate event log entries.

At minimum, log:
- cycle started
- deck built or refreshed
- card presented
- response chosen
- mutations applied
- cycle advanced
- session ended

The event log should support:
- player recap
- debugging
- future analytics or balancing
- save/load auditing

## End states

The engine should support explicit session end states.

A session can end through:
- victory
- collapse / failure
- narrative conclusion
- scenario-specific end condition
- soft end awaiting future content

End states should be scenario-driven but stored consistently.

## AI or generated cards

Generated cards are a future extension, not a first milestone dependency.

If added later:
- generation should use structured context summaries
- generated cards should remain constrained by scenario tone and archetypes
- generated cards should be inspectable and debuggable
- generated cards may be cached or reused only after the core loop is proven

Generated cards should not replace authored cards as the primary content source in early development.

## Engine boundaries

Controllers should:
- load session state
- render the current card/deck state
- receive response submissions
- call engine services
- render or redirect

Controllers should not:
- determine card eligibility directly
- mutate session context inline
- contain scenario rules
- embed major balance logic

Core logic should live in domain services.
