# RomeBots Scenario

## Purpose

RomeBots is the first scenario built on the RomeBots engine.

It is a single-player, card-driven historical strategy game where the player takes the role of Octavian (the future Augustus) and navigates a lifetime of political, military, personal, and dynastic choices.

RomeBots exists to prove the RomeBots engine through a constrained, historically grounded scenario with strong authored content and a clear cycle structure.

## Core fantasy

The player is Octavian.

Each cycle represents one year of life and rule.

Each year generates a deck of 12 cards representing:
- political dilemmas
- military opportunities or threats
- family and marriage decisions
- propaganda and legitimacy pressures
- factional conflict
- social or public mood
- personal health, succession, or mortality

Each card presents exactly two responses.

The player's responses shape:
- relationships
- faction pressure
- legitimacy
- military strength
- public mood
- family structure
- succession stability
- long-term survival and legacy

The run continues until Octavian dies, the regime collapses, or another scenario-defined ending is reached.

## Core scenario assumptions

- scenario key: `romebots`
- player character: Octavian
- one cycle = one year
- each year should aim to produce a 12-card deck
- cards are primarily authored and historically grounded
- each card has exactly two responses
- the game is not a strict historical replay; divergence is allowed within authored constraints
- major historical beats should influence the card pool, but the player's choices determine how they unfold

## First milestone scope

The first milestone should prove the core loop, not the full historical campaign.

For milestone 1:
- the player starts in the immediate post-Caesar period
- a small authored Year 1 card pool is enough
- the deck may be a partial representation before the full 12-card yearly experience is complete
- the goal is to make the game playable, not historically exhaustive

The minimum satisfying milestone is:
- start a RomeBots run
- generate the first year's deck (or milestone-sized subset)
- present a card
- choose one of two responses
- apply state changes
- log the outcome
- continue to the next card

## Time model

### Cycle

A cycle is one year.

Examples:
- cycle 1 = 44 BCE
- cycle 2 = 43 BCE
- cycle 3 = 42 BCE
- etc.

The exact year label may be derived from:
- a fixed starting year
- the current cycle number
- scenario metadata

### Within-year deck

Each year should aim to produce 12 cards.

This mirrors a month-like rhythm and gives the year a consistent structure, even if the cards are not literally tied to months.

The 12-card deck is:
- a design structure
- a pacing constraint
- a content budget for each year
- a useful UI concept

### Early implementation flexibility

For milestone 1:
- it is acceptable to generate fewer than 12 fully-authored cards
- generic authored fallback cards may fill empty slots
- the UI does not need to fully visualize all 12 slots immediately
- the engine should still conceptually support a yearly 12-card deck

## Deck generation rules

## Overview

At the start of a year:
1. Determine the current year and session context
2. Evaluate authored cards for eligibility
3. Select cards appropriate to the year and current context
4. Fill the deck toward the 12-card target
5. Create `SessionCard` instances for the year's deck
6. Present the next unresolved card

## Authored card priority

The deck should prefer:
1. year-specific authored cards
2. context-reactive authored cards
3. generic authored fallback cards
4. future generated cards (not required for milestone 1)

Generated cards are explicitly **not required** for the first milestone.

## Selection bias

Deck building should consider:
- current year or year range
- required historical beats
- current context values
- card weights
- card cooldowns or exhaustion
- whether a card has already appeared in this run
- whether mutually exclusive cards are already active or resolved

## Rebuild timing

For RomeBots, the default assumption is:

- a new 12-card deck is built at the start of each year
- the yearly deck remains mostly stable during that year
- card resolution changes context immediately
- those context changes should strongly affect future years
- limited within-year dynamic replacement is acceptable later, but should not be required for milestone 1

This means RomeBots should initially prefer **stable yearly decks** over constantly reshuffling decks after every choice.

That makes the system:
- more understandable
- easier to debug
- more thematic
- closer to the intended "one roll = one year" feel

## Card types

RomeBots cards should generally fall into one or more of these categories:

- politics
- military
- family
- marriage
- propaganda
- religion / omens
- public order
- rivals
- senate
- allies
- succession
- health
- administration
- scandal
- finance

These are tags or categories, not necessarily separate systems.

## Context model

RomeBots should use structured context keys stored in `GameSession.context_state`.

The exact keys may evolve, but the initial model should remain understandable and small.

## Recommended initial visible context keys

These are likely visible to the player in milestone 1 or soon after:

- `time.year`
- `state.legitimacy`
- `state.treasury`
- `state.public_order`
- `state.military_support`
- `state.senate_support`
- `state.heir_pressure`
- `state.health`

## Recommended initial hidden or semi-hidden context keys

These may be used internally before being surfaced in UI:

- `flags.caesar_adopted`
- `flags.caesar_assassinated`
- `flags.cicero_alive`
- `flags.antony_hostile`
- `flags.second_triumvirate_formed`
- `flags.married`
- `flags.has_heir`
- `flags.proscriptions_enabled`
- `flags.perusia_resolved`
- `flags.sextus_active`

## Recommended relationship-style keys

These can remain numeric or symbolic in `context_state` initially:

- `relations.antony`
- `relations.cicero`
- `relations.livia`
- `relations.agrippa`
- `relations.senate`
- `relations.plebs`
- `relations.legions`

These do not need separate models in milestone 1.

## Recommended faction-style keys

These can also remain lightweight numeric keys in `context_state`:

- `factions.julian_house`
- `factions.octavian_circle`
- `factions.senate_bloc`
- `factions.antonian_faction`
- `factions.roman_priesthood`
- `factions.senatorial_families`
- `factions.legions`

These should remain schema-light for now and can be surfaced in a compact pressure panel.

## Context principles

RomeBots context should:
- be explicit and debuggable
- favor a small number of meaningful keys
- avoid storing every tiny narrative detail as permanent state
- use event logs for history and context keys for current truth
- allow divergence without turning into incoherent chaos

## Card structure

Each RomeBots card should define:

- `scenario_key`
- `key`
- `title`
- `body`
- `card_type`
- `tags`
- `spawn_rules`
- `response_a_text`
- `response_a_effects`
- `response_b_text`
- `response_b_effects`

## Spawn rule concepts

A card's `spawn_rules` may include:

- minimum year
- maximum year
- required flags
- excluded flags
- minimum stat thresholds
- maximum stat thresholds
- required prior card keys
- excluded prior card keys
- weight modifiers based on context
- one-time-only or repeatable behavior
- cooldown behavior

Not all of these need to exist in milestone 1.

## Response effects

Response effects should be structured and data-driven where practical.

Supported effect concepts should eventually include:

- set context key
- increment/decrement numeric context key
- clear or reset context key
- mark a card family exhausted
- add event tags
- schedule future consequence flags
- trigger immediate end-state check
- trigger deck/cycle metadata updates

Milestone 1 should only implement the simplest useful subset:
- set
- increment/decrement
- clear

## Card writing principles

RomeBots cards should feel:
- concise
- legible
- characterful
- historically flavored
- constrained enough to be testable

A card should generally:
- set up one clear dilemma
- present two distinct strategic or tonal responses
- imply meaningful tradeoffs
- avoid excessive prose walls
- avoid requiring hidden lore to understand the stakes

## Tone

RomeBots should balance:
- historical gravity
- dark humor
- irony
- personal pettiness
- statecraft
- pressure

It should not read like:
- dry textbook summaries
- modern corporate UI copy
- fully comedic parody with no stakes
- unconstrained AI improv

## Historical philosophy

RomeBots is historically grounded, not historically imprisoned.

Guidelines:
- major historical pressures should appear
- familiar figures should matter
- the player's choices should allow divergence
- divergence should remain legible and scenario-authored
- "what happened" should inform the card pool, not dictate a single railroad

## End-state philosophy

RomeBots should support multiple endings.

Potential ending categories:
- stable principate
- unstable survival
- civil collapse
- assassination
- dynastic success
- dynastic failure
- early death
- hollow victory

Milestone 1 does not need a full ending matrix, but the engine should assume that RomeBots is a long-run scenario with multiple possible outcomes.

## Milestone 1 content recommendation

For the first playable vertical slice, the card pool should be intentionally small.

Recommended target:
- 8 to 16 authored cards total
- enough to build a partial Year 1 deck
- a few generic fallback cards
- a very small set of context keys

This is better than trying to write all of Roman history before the first button works.

## Suggested Year 1 opening beats

The first playable slice should bias toward the immediate aftermath of Caesar's assassination.

Possible opening cards include:

- Caesar's will is read
- a political ally urges Octavian to return to Rome
- an omen or celestial sign appears
- Cicero seeks alliance against Antony
- Antony offers terms
- a marriage alliance is proposed
- public unrest or grain anxiety rises
- a veteran loyalty question emerges

These should be treated as first-pass authored content, not strict canon.

## UI expectations for RomeBots

The RomeBots active session screen should prioritize:

- current year label
- active card
- two response buttons
- visible state summary
- recent event log
- optional deck progress indicator (e.g. "3 / 12 cards resolved this year")

The UI does not need to show all 12 cards visually in milestone 1.

## What RomeBots should NOT force yet

Do not require in milestone 1:
- AI-generated cards
- a full 60+ year content set
- every historical figure as a dedicated model
- fully normalized relationship systems
- dynamic within-year deck regeneration
- Diado-style shared-world card circulation
- multiplayer or async world simulation

RomeBots should first prove:
- the card loop is fun
- the yearly pacing works
- context mutations feel meaningful
- the engine can support scenario-specific flavor cleanly

## Recommended namespace shape

RomeBots-specific logic may eventually live under:

- `Scenarios::RomeBots::BuildDeck`
- `Scenarios::RomeBots::EligibleCards`
- `Scenarios::RomeBots::ResolveResponse`
- `Scenarios::RomeBots::CheckEndState`

The engine should provide generic primitives, but RomeBots can own its special rules.

## Summary

RomeBots is the first RomeBots scenario.

It should be treated as:
- the initial vertical slice
- the first content proving ground
- the first deck-building and response-resolution testbed
- a historically grounded authored scenario with stable yearly decks and exactly two-choice cards

Its job is not to solve every future scenario problem.

Its job is to make the RomeBots engine feel real.
