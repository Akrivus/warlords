# Scenario Model

## Purpose

RomeBots is an engine.  
Scenarios are game-specific rule and content packages built on top of that engine.

A scenario defines:
- what a cycle means
- how decks are built
- what cards exist
- what context keys matter
- how end states are determined
- how the game should feel

The first scenario is RomeBots.

## Engine vs scenario boundary

### Engine layer

The engine should know about:
- sessions
- card definitions
- session cards
- deck construction interfaces
- response resolution interfaces
- context mutation primitives
- event logging
- cycle advancement hooks

The engine should not know:
- who Octavian is
- what a Roman consul is
- what a satrap is
- what specific historical milestones exist
- scenario-specific flavor logic

### Scenario layer

The scenario should know:
- card pools
- context keys
- cycle rules
- spawn weighting
- special rule overrides
- end conditions
- flavor and narrative tone

## RomeBots scenario

RomeBots is the first scenario and should be the first vertical slice.

### Core assumptions

- scenario key: `romebots`
- the player is Octavian
- one cycle = one year
- each year should generate a 12-card deck
- cards are drawn from an authored historical or semi-historical pool
- each card has exactly two responses
- the player resolves cards to shape the reign
- the run continues until death, collapse, transformation, or another scenario-defined ending

### Content bias

RomeBots should favor:
- authored cards
- historically grounded prompts
- branching but constrained divergence
- major political, military, familial, and personal dilemmas
- visible context shifts that meaningfully change later eligibility

### Initial fallback strategy

If the authored eligible pool does not fully satisfy deck needs:
- first use authored generic/system fallback cards
- only later consider AI-generated cards
- generated cards are not required for milestone 1

## Future scenarios

Future scenarios may change:
- cycle meaning
- deck size
- deck refill timing
- whether decks are personal or world-influenced
- whether cards can re-enter circulation
- whether state is session-local or shared-world influenced

## Diado as a future scenario

Diado should be treated as a future scenario, not a milestone-1 requirement.

Potential Diado differences:
- more systemic world-state influence
- deck generation based on shared or global conditions
- possible card recirculation or reintroduction
- more emergent faction dynamics
- weaker historical rails than RomeBots

These differences should influence how engine seams are designed, but should not drive premature implementation complexity.

## Scenario implementation shape

A scenario may eventually define code under a namespace such as:
- `Scenarios::RomeBots::...`
- `Scenarios::Diado::...`

Possible scenario-specific services:
- `Scenarios::RomeBots::BuildDeck`
- `Scenarios::RomeBots::ResolveCard`
- `Scenarios::RomeBots::CheckEndState`

The exact shape can evolve, but the boundary should remain:
- engine provides primitives
- scenario provides rules and content