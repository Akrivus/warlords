# RomeBots Context

## Purpose

This document defines the first-pass session context model for the RomeBots scenario.

RomeBots uses structured context keys stored in `GameSession.context_state`.
These keys drive:
- card eligibility
- response resolution
- deck generation
- visible state display
- end-state checks

The goal for milestone 1 is not to model every detail of Roman political life.
The goal is to define a small, legible state model that produces meaningful card behavior.

## Context design principles

RomeBots context should be:
- small enough to reason about
- explicit enough to debug
- flexible enough to expand
- split between visible state and hidden flags
- sufficient for authored card conditions and effects

Use event logs for historical record.
Use context keys for current truth.

## Initial context buckets

RomeBots context should begin with four conceptual buckets:

- `time.*`
- `state.*`
- `relations.*`
- `factions.*`
- `flags.*`

Additional buckets can be added later if needed.

## Time keys

### `time.year`
- type: integer
- visible: yes
- example start: `44`
- meaning: current scenario year label, represented as BCE countdown for early RomeBots implementation if desired

### `time.cycle_number`
- type: integer
- visible: optional
- default: `1`
- meaning: internal cycle counter, where one cycle equals one year

### `time.cards_resolved_this_year`
- type: integer
- visible: yes
- default: `0`
- meaning: number of resolved cards in the current yearly deck

## State keys

These are the main player-facing power indicators.

### `state.legitimacy`
- type: integer
- visible: yes
- range: `0..100`
- default: `55`
- meaning: Octavian's perceived right to rule and political credibility

### `state.treasury`
- type: integer
- visible: yes
- range: `0..100`
- default: `45`
- meaning: available money and fiscal breathing room

### `state.public_order`
- type: integer
- visible: yes
- range: `0..100`
- default: `50`
- meaning: urban stability, unrest pressure, and social calm

### `state.military_support`
- type: integer
- visible: yes
- range: `0..100`
- default: `40`
- meaning: support from troops, veterans, and armed power centers

### `state.senate_support`
- type: integer
- visible: yes
- range: `0..100`
- default: `35`
- meaning: support from the senate and elite political class

### `state.health`
- type: integer
- visible: yes
- range: `0..100`
- default: `85`
- meaning: Octavian's bodily resilience and long-term survivability

### `state.heir_pressure`
- type: integer
- visible: yes
- range: `0..100`
- default: `10`
- meaning: urgency around marriage, succession, and dynastic continuity

## Relationship keys

These represent personal or factional alignment.
For milestone 1, keep them numeric and simple.

### `relations.antony`
- type: integer
- visible: optional
- range: `-5..5`
- default: `-2`
- meaning: current alignment or hostility with Antony

### `relations.cicero`
- type: integer
- visible: optional
- range: `-5..5`
- default: `1`
- meaning: current trust or working alignment with Cicero

### `relations.agrippa`
- type: integer
- visible: optional
- range: `-5..5`
- default: `2`
- meaning: closeness and trust with Agrippa

### `relations.legions`
- type: integer
- visible: optional
- range: `-5..5`
- default: `1`
- meaning: personal loyalty from military followers beyond broad military support

### `relations.plebs`
- type: integer
- visible: optional
- range: `-5..5`
- default: `0`
- meaning: relationship with the urban public

## Faction keys

These represent bloc-level alignment or pressure.
For milestone 1, keep them numeric and simple.

### `factions.julian_house`
- type: integer
- visible: optional
- range: `-5..5`
- default: `2`
- meaning: confidence from Caesar's household and memory-politics camp

### `factions.octavian_circle`
- type: integer
- visible: optional
- range: `-5..5`
- default: `2`
- meaning: confidence from Octavian's inner circle and rising loyalists

### `factions.senate_bloc`
- type: integer
- visible: optional
- range: `-5..5`
- default: `1`
- meaning: pressure or alignment from Cicero's senatorial coalition

### `factions.antonian_faction`
- type: integer
- visible: optional
- range: `-5..5`
- default: `-2`
- meaning: current warmth or hostility from Antony's camp

### `factions.roman_priesthood`
- type: integer
- visible: optional
- range: `-5..5`
- default: `0`
- meaning: confidence from priestly interpreters and temple interests

### `factions.senatorial_families`
- type: integer
- visible: optional
- range: `-5..5`
- default: `0`
- meaning: pressure from marriage-minded elite houses

### `factions.legions`
- type: integer
- visible: optional
- range: `-5..5`
- default: `1`
- meaning: bloc-level veteran and legion sentiment beyond personal ties

## Flag keys

Flags are mostly hidden booleans used for eligibility and branching.

### `flags.caesar_assassinated`
- type: boolean
- visible: no
- default: `true`

### `flags.caesar_adopted_heir`
- type: boolean
- visible: no
- default: `true`

### `flags.returned_to_rome`
- type: boolean
- visible: no
- default: `false`

### `flags.met_cicero`
- type: boolean
- visible: no
- default: `false`

### `flags.antony_compromised`
- type: boolean
- visible: no
- default: `false`

### `flags.antony_open_enemy`
- type: boolean
- visible: no
- default: `false`

### `flags.married`
- type: boolean
- visible: semi-hidden
- default: `false`

### `flags.has_heir`
- type: boolean
- visible: semi-hidden
- default: `false`

### `flags.proscriptions_used`
- type: boolean
- visible: no
- default: `false`

### `flags.second_triumvirate_formed`
- type: boolean
- visible: no
- default: `false`

### `flags.sextus_active`
- type: boolean
- visible: no
- default: `false`

## Milestone 1 recommended starting context

```json
{
  "time.year": 44,
  "time.cycle_number": 1,
  "time.cards_resolved_this_year": 0,

  "state.legitimacy": 55,
  "state.treasury": 45,
  "state.public_order": 50,
  "state.military_support": 40,
  "state.senate_support": 35,
  "state.health": 85,
  "state.heir_pressure": 10,

  "relations.antony": -2,
  "relations.cicero": 1,
  "relations.agrippa": 2,
  "relations.legions": 1,
  "relations.plebs": 0,

  "factions.julian_house": 2,
  "factions.octavian_circle": 2,
  "factions.senate_bloc": 1,
  "factions.antonian_faction": -2,
  "factions.roman_priesthood": 0,
  "factions.senatorial_families": 0,
  "factions.legions": 1,

  "flags.caesar_assassinated": true,
  "flags.caesar_adopted_heir": true,
  "flags.returned_to_rome": false,
  "flags.met_cicero": false,
  "flags.antony_compromised": false,
  "flags.antony_open_enemy": false,
  "flags.married": false,
  "flags.has_heir": false,
  "flags.proscriptions_used": false,
  "flags.second_triumvirate_formed": false,
  "flags.sextus_active": true
}
```

Mutation rules

Milestone 1 should support only a small mutation vocabulary:

set
increment
decrement
clear

Example effect payloads:

[
  { "op": "set", "key": "flags.returned_to_rome", "value": true },
  { "op": "increment", "key": "state.legitimacy", "value": 5 },
  { "op": "decrement", "key": "state.senate_support", "value": 3 }
]
Guardrails

For milestone 1:

clamp state.* values to 0..100
clamp relations.* values to -5..5
clamp factions.* values to -5..5
booleans should remain booleans
missing keys should not be silently invented by typo-prone content

A central context mutation service should validate mutations before applying them.

Visibility guidance

Milestone 1 UI should show at least:

time.year
state.legitimacy
state.treasury
state.public_order
state.military_support
state.senate_support
state.health
state.heir_pressure

Relationship keys and flags may remain hidden or debug-only at first.
Faction keys may be shown in a compact pressure readout when useful.

Expansion guidance

Later additions may include:

war.*
family.*
dynasty.*
rivals.*
omens.*

Do not add them until cards actually need them.
