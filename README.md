**I created this over a weekend with AI, it's okay-ish but kinda rough in the human usability department.**

# RomeBots

RomeBots is a Rails-based browser game framework for card-driven narrative strategy games.

The project is designed as a reusable engine for games where:
- a game session tracks evolving state and context
- a deck or card pool is built from that state
- the player is presented with cards representing dilemmas, events, or opportunities
- each card offers exactly two responses
- the chosen response mutates session state
- the updated state influences future card selection

The first intended scenario built on this framework is RomeBots:
- the player is Octavian
- each turn represents one year
- each year generates a 12-card deck
- cards represent political, military, personal, and narrative events
- choices shape the course of the reign until an ending is reached

The long-term architecture should allow additional scenarios, including more systemic or shared-world variants such as Diado, without requiring a full rewrite.

## Core design goals

- Build a reusable card-state engine, not a one-off hardcoded game
- Keep the first implementation focused on a single-player, session-local scenario
- Use Rails conventions and server-rendered HTML-first UI
- Keep game rules in Ruby domain objects, not controllers or views
- Make scenario-specific rules pluggable
- Reach a playable vertical slice quickly

## Technical direction

The app should prefer:
- Rails conventions
- ERB views
- Turbo for partial page updates
- Stimulus for lightweight enhancements only
- POROs / service objects for deck building and choice resolution
- JSONB for flexible early-state storage
- small, testable increments

The app should avoid:
- frontend framework sprawl
- overbuilding for multiplayer/shared-world features too early
- baking scenario-specific assumptions into the engine layer
- putting gameplay rules directly into controllers or helpers

## Core gameplay loop

At a high level:

1. Start or resume a game session
2. Build or refresh the session's card pool based on context
3. Present the next card to the player
4. Player selects one of two responses
5. Backend resolves the response
6. Session context is updated
7. The result is logged
8. The card pool is updated or advanced as needed
9. The loop continues until the cycle or run ends

## Initial product strategy

RomeBots should first prove the core engine through the RomeBots scenario.

The first playable milestone should support:
- starting a RomeBots run
- generating a year-based 12-card deck
- presenting a card
- choosing one of two responses
- applying context changes
- recording an event log
- continuing through multiple cards

This is intentionally narrower than the eventual engine ambitions.

## Documentation

See:
- `docs/game_flow.md`
- `docs/domain_model.md`
- `docs/scenario_model.md`
- `docs/ui_guidelines.md`
- `docs/implementation_plan.md`
- `docs/codex_instructions.md`

## Authentication

RomeBots supports:
- email/password authentication through Devise
- Google sign-in through Devise OmniAuth
- GitHub sign-in through Devise OmniAuth

Set these environment variables to enable SSO providers:
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `GITHUB_CLIENT_ID`
- `GITHUB_CLIENT_SECRET`

Development callback URLs:
- `http://localhost:3000/users/auth/google_oauth2/callback`
- `http://localhost:3000/users/auth/github/callback`

Production should use the same callback paths on your real host.

Current account matching behavior:
- first match existing provider identities by `provider + uid`
- otherwise match an existing `User` by provider email
- if a matching user exists, link the provider to that user automatically
- if no user exists, create one and link the provider
- if the provider does not return an email, reject sign-in
