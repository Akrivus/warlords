# RomeBots Cards

## Purpose

This document defines the first-pass card content model and initial authored seed cards for the RomeBots scenario.

It exists to:
- give Codex concrete card content to seed into `CardDefinition`
- define the expected shape of a RomeBots card
- establish writing standards for the first playable vertical slice
- provide a small, controlled Year 1 card pool

This document is intentionally small and practical.

It should not attempt to encode all of Roman history before the first playable loop exists.

## Milestone 1 card philosophy

Milestone 1 should use:
- a small authored card pool
- historically grounded but concise card writing
- simple spawn rules
- simple response effects
- minimal hidden complexity

The goal is to prove:
- deck generation
- active card presentation
- two-response resolution
- context mutation
- event logging
- progression to the next card

## Card structure

Each RomeBots card should be representable as a `CardDefinition` with roughly this shape:

- `scenario_key`
- `key`
- `title`
- `body`
- `speaker_type`
- `speaker_key`
- `speaker_name`
- `portrait_key`
- `faction_key`
- `card_type`
- `active`
- `weight`
- `tags`
- `spawn_rules`
- `response_a_text`
- `response_a_effects`
- `response_a_follow_up_card_key`
- `response_b_text`
- `response_b_effects`
- `response_b_follow_up_card_key`

## Recommended first-pass card JSON shape

A first-pass seed format may look like this:

```json
{
  "scenario_key": "romebots",
  "key": "caesars_will",
  "title": "Caesar's Will",
  "body": "Your father's will is opened. He names you his son and heir. Rome is now full of men who would prefer otherwise.",
  "card_type": "authored",
  "active": true,
  "weight": 100,
  "tags": ["opening", "politics", "legitimacy", "family"],
  "spawn_rules": {
    "min_year": -44,
    "max_year": -44,
    "required_flags": ["flags.caesar_assassinated"],
    "one_time_only": true
  },
  "response_a_text": "Claim the name immediately.",
  "response_a_effects": [
    { "op": "increment", "key": "state.legitimacy", "value": 10 },
    { "op": "increment", "key": "state.risk", "value": 5 },
    { "op": "set", "key": "flags.caesar_adopted", "value": true }
  ],
  "response_b_text": "Move carefully and avoid open declaration.",
  "response_b_effects": [
    { "op": "increment", "key": "state.legitimacy", "value": 4 },
    { "op": "increment", "key": "state.senate_support", "value": 2 },
    { "op": "set", "key": "flags.caesar_adopted", "value": true }
  ]
}
````

This format can evolve, but milestone 1 should keep effects simple and explicit.

Speaker metadata should remain lightweight for now. Cards may name a speaker, portrait key, and faction key directly on the card record without introducing full character or faction tables yet.

## First-pass effect operations

Milestone 1 should only require these effect operations:

* `set`
* `increment`
* `decrement` (or `increment` with negative values if preferred)
* `clear`

Anything more complex should wait until the core loop is proven.

RomeBots may also attach a single authored follow-up card key to a response. This is intentionally limited to one-step follow-ups, not general dialogue trees.

## Writing rules for RomeBots cards

Each card should:

* describe one clear dilemma or event
* be concise enough to read quickly
* have exactly two distinct responses
* make both responses plausible
* imply tradeoffs
* feel historically flavored, not textbook-dry
* avoid walls of prose
* avoid requiring niche lore to understand the stakes

## Tone rules

Cards should balance:

* political danger
* personal pettiness
* statecraft
* irony
* dark humor
* tension

Cards should not sound like:

* encyclopedia summaries
* modern product copy
* random AI fanfic sludge
* fully comedic nonsense with no stakes

## Milestone 1 seed pool

For the first playable slice, seed a small set of cards centered on the immediate aftermath of Caesar's assassination.

Recommended target:

* 8 to 12 authored cards
* enough to build a partial or full Year 1 deck
* a few generic fallback cards if needed

The following cards are first-pass authored seeds.

---

## Seed Card 1: Caesar's Will

### Key

`caesars_will`

### Intent

Opening legitimacy card. Establishes the player's claim and first strategic posture.

### Suggested data

```json
{
  "scenario_key": "romebots",
  "key": "caesars_will",
  "title": "Caesar's Will",
  "body": "Your father's will is opened. He names you his son and heir. Rome is now full of men who would prefer otherwise.",
  "card_type": "authored",
  "active": true,
  "weight": 100,
  "tags": ["opening", "politics", "legitimacy", "family"],
  "spawn_rules": {
    "min_year": -44,
    "max_year": -44,
    "one_time_only": true
  },
  "response_a_text": "Claim the name immediately.",
  "response_a_effects": [
    { "op": "set", "key": "flags.caesar_adopted", "value": true },
    { "op": "increment", "key": "state.legitimacy", "value": 10 },
    { "op": "increment", "key": "state.risk", "value": 5 },
    { "op": "increment", "key": "relations.antony", "value": -1 }
  ],
  "response_b_text": "Move carefully and test the room first.",
  "response_b_effects": [
    { "op": "set", "key": "flags.caesar_adopted", "value": true },
    { "op": "increment", "key": "state.legitimacy", "value": 5 },
    { "op": "increment", "key": "state.senate_support", "value": 2 },
    { "op": "increment", "key": "state.risk", "value": 1 }
  ]
}
```

---

## Seed Card 2: Return to Rome

### Key

`return_to_rome`

### Intent

Early momentum card. Do you move fast and bold or slow and safe?

### Suggested data

```json
{
  "scenario_key": "romebots",
  "key": "return_to_rome",
  "title": "Return to Rome",
  "body": "Friends urge you to return to the city at once. Delay may keep you safe. Delay may also make you irrelevant.",
  "card_type": "authored",
  "active": true,
  "weight": 90,
  "tags": ["opening", "politics", "mobility", "risk"],
  "spawn_rules": {
    "min_year": -44,
    "max_year": -44,
    "one_time_only": true
  },
  "response_a_text": "Ride for Rome immediately.",
  "response_a_effects": [
    { "op": "increment", "key": "state.legitimacy", "value": 6 },
    { "op": "increment", "key": "state.risk", "value": 4 },
    { "op": "increment", "key": "state.military_support", "value": 2 }
  ],
  "response_b_text": "Gather support quietly before moving.",
  "response_b_effects": [
    { "op": "increment", "key": "state.senate_support", "value": 3 },
    { "op": "increment", "key": "state.risk", "value": -1 },
    { "op": "increment", "key": "state.legitimacy", "value": 2 }
  ]
}
```

---

## Seed Card 3: The Comet

### Key

`the_comet`

### Intent

Propaganda / omen card. Lets the player lean into symbolism or restraint.

### Suggested data

```json
{
  "scenario_key": "romebots",
  "key": "the_comet",
  "title": "The Comet",
  "body": "A bright star hangs over the games. Some call it a sign. Others call it theater waiting to happen.",
  "card_type": "authored",
  "active": true,
  "weight": 75,
  "tags": ["omen", "propaganda", "legitimacy", "public"],
  "spawn_rules": {
    "min_year": -44,
    "max_year": -43,
    "one_time_only": true
  },
  "response_a_text": "Call it Caesar ascending.",
  "response_a_effects": [
    { "op": "increment", "key": "state.legitimacy", "value": 8 },
    { "op": "increment", "key": "state.public_order", "value": 2 },
    { "op": "increment", "key": "state.senate_support", "value": -2 }
  ],
  "response_b_text": "Say little. Let people decide for themselves.",
  "response_b_effects": [
    { "op": "increment", "key": "state.legitimacy", "value": 3 },
    { "op": "increment", "key": "state.senate_support", "value": 1 }
  ]
}
```

---

## Seed Card 4: Cicero's Offer

### Key

`ciceros_offer`

### Intent

Early alliance tradeoff. Senate cover vs future entanglement.

### Suggested data

```json
{
  "scenario_key": "romebots",
  "key": "ciceros_offer",
  "title": "Cicero's Offer",
  "body": "Cicero offers you praise, introductions, and a place in his plans against Antony. He smiles like a man borrowing someone else's knife.",
  "card_type": "authored",
  "active": true,
  "weight": 85,
  "tags": ["senate", "alliance", "cicero", "politics"],
  "spawn_rules": {
    "min_year": -44,
    "max_year": -43,
    "one_time_only": true
  },
  "response_a_text": "Take the alliance. You need his voice.",
  "response_a_effects": [
    { "op": "increment", "key": "relations.cicero", "value": 2 },
    { "op": "increment", "key": "state.senate_support", "value": 5 },
    { "op": "increment", "key": "relations.antony", "value": -2 }
  ],
  "response_b_text": "Keep him close, but owe him nothing.",
  "response_b_effects": [
    { "op": "increment", "key": "relations.cicero", "value": 1 },
    { "op": "increment", "key": "state.senate_support", "value": 2 },
    { "op": "increment", "key": "state.legitimacy", "value": 1 }
  ]
}
```

---

## Seed Card 5: Antony's Terms

### Key

`antonys_terms`

### Intent

Rival posture card. Peace now vs sharper confrontation later.

### Suggested data

```json
{
  "scenario_key": "romebots",
  "key": "antonys_terms",
  "title": "Antony's Terms",
  "body": "Antony offers peace with the confidence of a man who thinks he can kill you later if you disappoint him.",
  "card_type": "authored",
  "active": true,
  "weight": 85,
  "tags": ["antony", "rival", "politics", "power"],
  "spawn_rules": {
    "min_year": -44,
    "max_year": -43,
    "one_time_only": true
  },
  "response_a_text": "Accept the peace. For now.",
  "response_a_effects": [
    { "op": "increment", "key": "relations.antony", "value": 2 },
    { "op": "increment", "key": "state.risk", "value": -2 },
    { "op": "increment", "key": "state.legitimacy", "value": -1 }
  ],
  "response_b_text": "Refuse. Let him know you are not his boy.",
  "response_b_effects": [
    { "op": "increment", "key": "relations.antony", "value": -3 },
    { "op": "increment", "key": "state.legitimacy", "value": 4 },
    { "op": "increment", "key": "state.risk", "value": 4 }
  ]
}
```

---

## Seed Card 6: Veterans Want Payment

### Key

`veterans_want_payment`

### Intent

Classic resource tradeoff. Buy loyalty or conserve treasury.

### Suggested data

```json
{
  "scenario_key": "romebots",
  "key": "veterans_want_payment",
  "title": "Veterans Want Payment",
  "body": "Caesar's veterans remember promises better than speeches. They want land, silver, or a reason to believe you'll matter.",
  "card_type": "authored",
  "active": true,
  "weight": 80,
  "tags": ["military", "veterans", "treasury", "loyalty"],
  "spawn_rules": {
    "min_year": -44,
    "max_year": -42
  },
  "response_a_text": "Pay them. Loyalty first.",
  "response_a_effects": [
    { "op": "increment", "key": "state.treasury", "value": -10 },
    { "op": "increment", "key": "state.military_support", "value": 6 },
    { "op": "increment", "key": "state.legitimacy", "value": 2 }
  ],
  "response_b_text": "Delay and negotiate.",
  "response_b_effects": [
    { "op": "increment", "key": "state.treasury", "value": -2 },
    { "op": "increment", "key": "state.military_support", "value": -2 },
    { "op": "increment", "key": "state.risk", "value": 2 }
  ]
}
```

---

## Seed Card 7: Grain Anxiety

### Key

`grain_anxiety`

### Intent

Public stability pressure. Very Rome.

### Suggested data

```json
{
  "scenario_key": "romebots",
  "key": "grain_anxiety",
  "title": "Grain Anxiety",
  "body": "The markets mutter. Bread is thinner, tempers are shorter, and the city has a gift for blaming whoever looks important.",
  "card_type": "authored",
  "active": true,
  "weight": 70,
  "tags": ["public", "grain", "order", "urban"],
  "spawn_rules": {
    "min_year": -44,
    "max_year": -30
  },
  "response_a_text": "Spend to stabilize supply.",
  "response_a_effects": [
    { "op": "increment", "key": "state.treasury", "value": -6 },
    { "op": "increment", "key": "state.public_order", "value": 5 }
  ],
  "response_b_text": "Blame hoarders and squeeze the market.",
  "response_b_effects": [
    { "op": "increment", "key": "state.public_order", "value": 1 },
    { "op": "increment", "key": "state.risk", "value": 2 },
    { "op": "increment", "key": "state.legitimacy", "value": -1 }
  ]
}
```

---

## Seed Card 8: Marriage Proposal

### Key

`marriage_proposal`

### Intent

Dynastic/factional alliance card. Early version keeps it generic enough.

### Suggested data

```json
{
  "scenario_key": "romebots",
  "key": "marriage_proposal",
  "title": "Marriage Proposal",
  "body": "An allied house offers marriage. The match is politically useful. The bride, like most of Rome, has opinions you have not yet been asked to hear.",
  "card_type": "authored",
  "active": true,
  "weight": 60,
  "tags": ["family", "marriage", "alliance", "dynasty"],
  "spawn_rules": {
    "min_year": -44,
    "max_year": -35,
    "excluded_flags": ["flags.married"]
  },
  "response_a_text": "Accept. Rome runs on useful marriages.",
  "response_a_effects": [
    { "op": "set", "key": "flags.married", "value": true },
    { "op": "increment", "key": "state.legitimacy", "value": 3 },
    { "op": "increment", "key": "state.senate_support", "value": 2 }
  ],
  "response_b_text": "Decline. Keep your options open.",
  "response_b_effects": [
    { "op": "increment", "key": "state.legitimacy", "value": -1 },
    { "op": "increment", "key": "state.risk", "value": 1 }
  ]
}
```

---

## Seed Card 9: Whisper Campaign

### Key

`whisper_campaign`

### Intent

Generic propaganda pressure card that can recur.

### Suggested data

```json
{
  "scenario_key": "romebots",
  "key": "whisper_campaign",
  "title": "Whisper Campaign",
  "body": "The city is suddenly full of small stories about you. None of them are flattering. All of them are useful to someone.",
  "card_type": "authored",
  "active": true,
  "weight": 55,
  "tags": ["propaganda", "public", "rivals", "recurring"],
  "spawn_rules": {
    "min_year": -44,
    "max_year": 14,
    "repeatable": true
  },
  "response_a_text": "Answer it loudly.",
  "response_a_effects": [
    { "op": "increment", "key": "state.legitimacy", "value": 2 },
    { "op": "increment", "key": "state.treasury", "value": -2 }
  ],
  "response_b_text": "Ignore it and punish the source quietly.",
  "response_b_effects": [
    { "op": "increment", "key": "state.risk", "value": 1 },
    { "op": "increment", "key": "state.public_order", "value": 1 }
  ]
}
```

---

## Seed Card 10: Omen at Dawn

### Key

`omen_at_dawn`

### Intent

Generic fallback omen card for early years.

### Suggested data

```json
{
  "scenario_key": "romebots",
  "key": "omen_at_dawn",
  "title": "Omen at Dawn",
  "body": "Priests, servants, and drunks all agree that something unusual happened before sunrise. This is Rome, so now it is your problem.",
  "card_type": "system",
  "active": true,
  "weight": 30,
  "tags": ["fallback", "omen", "public"],
  "spawn_rules": {
    "min_year": -44,
    "max_year": 14,
    "repeatable": true
  },
  "response_a_text": "Sponsor rites and make a show of it.",
  "response_a_effects": [
    { "op": "increment", "key": "state.treasury", "value": -2 },
    { "op": "increment", "key": "state.public_order", "value": 2 },
    { "op": "increment", "key": "state.legitimacy", "value": 1 }
  ],
  "response_b_text": "Dismiss it. Rome has work to do.",
  "response_b_effects": [
    { "op": "increment", "key": "state.senate_support", "value": 1 },
    { "op": "increment", "key": "state.public_order", "value": -1 }
  ]
}
```

---

## Seed Card 11: A Loyal Friend

### Key

`a_loyal_friend`

### Intent

Generic ally-building fallback card. Stands in for early companion support.

### Suggested data

```json
{
  "scenario_key": "romebots",
  "key": "a_loyal_friend",
  "title": "A Loyal Friend",
  "body": "One of your companions asks for trust, responsibility, and the chance to prove useful. Rome is built on favors and survives on competent men.",
  "card_type": "system",
  "active": true,
  "weight": 35,
  "tags": ["fallback", "ally", "administration", "military"],
  "spawn_rules": {
    "min_year": -44,
    "max_year": 14,
    "repeatable": true
  },
  "response_a_text": "Give him a command.",
  "response_a_effects": [
    { "op": "increment", "key": "state.military_support", "value": 2 },
    { "op": "increment", "key": "state.risk", "value": 1 }
  ],
  "response_b_text": "Keep him close, but untested.",
  "response_b_effects": [
    { "op": "increment", "key": "state.senate_support", "value": 1 },
    { "op": "increment", "key": "state.risk", "value": -1 }
  ]
}
```

---

## Seed Card 12: A Narrow Escape

### Key

`a_narrow_escape`

### Intent

Generic danger/fallback card. Useful for tension and testing risk systems.

### Suggested data

```json
{
  "scenario_key": "romebots",
  "key": "a_narrow_escape",
  "title": "A Narrow Escape",
  "body": "A rumor, a crowd, a bad alley, a frightened horse. Whatever happened, you are alive, which is more than some men were hoping for.",
  "card_type": "system",
  "active": true,
  "weight": 25,
  "tags": ["fallback", "danger", "risk", "public"],
  "spawn_rules": {
    "min_year": -44,
    "max_year": 14,
    "repeatable": true
  },
  "response_a_text": "Double the guard and make it visible.",
  "response_a_effects": [
    { "op": "increment", "key": "state.treasury", "value": -3 },
    { "op": "increment", "key": "state.risk", "value": -2 },
    { "op": "increment", "key": "state.legitimacy", "value": -1 }
  ],
  "response_b_text": "Laugh it off. Fear is expensive.",
  "response_b_effects": [
    { "op": "increment", "key": "state.risk", "value": 2 },
    { "op": "increment", "key": "state.legitimacy", "value": 1 }
  ]
}
```

---

## Milestone 1 deck-building recommendation

For milestone 1, deck building should be simple and deterministic enough to debug.

Recommended behavior:

1. Filter active `CardDefinition` records for `scenario_key = "romebots"`
2. Filter by simple year eligibility
3. Filter by simple required/excluded flags
4. Prefer one-time opening cards in Year 1
5. Fill remaining slots with generic authored/system fallback cards
6. Create `SessionCard` records for the year
7. Mark one as active

Avoid complicated weighting systems in the first pass unless they are trivial to test.

## Milestone 1 card resolution recommendation

For milestone 1:

* only apply simple structured effects
* write an `EventLog` entry describing the chosen response
* mark the `SessionCard` as resolved
* advance to the next unresolved `SessionCard`
* if none remain, advance the year or end the milestone slice

## Notes on future refinement

Later versions may add:

* stricter year-specific chains
* card families
* cooldowns
* mutually exclusive branches
* relationship-gated cards
* marriage-candidate-specific cards
* Livia-specific or Antony-specific arcs
* generated card supplements

None of that is required for the first playable version.

## Summary

Milestone 1 RomeBots cards should be:

* small in number
* strongly authored
* easy to seed
* easy to debug
* easy to read
* rich enough to feel like Rome

The purpose of this document is not to finish the scenario.

The purpose is to make the first playable deck real.
