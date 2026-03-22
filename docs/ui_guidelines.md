# UI Guidelines

## General direction

RomeBots should use an HTML-first, server-driven UI.

The frontend should prioritize:
- clarity
- responsiveness
- low complexity
- easy iteration
- strong support for text-heavy card interactions

The app does not require a complex graphics pipeline.

Preferred tools:
- semantic HTML
- ERB partials
- Turbo for partial updates
- Stimulus for lightweight enhancements only

## Core UI priorities

The player should always understand:
- what scenario they are playing
- what cycle they are in
- what card is active
- what the two choices are
- what changed after they chose
- how their broader state is evolving

## Primary screen regions

### Header
Shows:
- game/scenario title
- current cycle marker
- session status
- menu/settings access

### Active card panel
Shows:
- card title
- card body
- card metadata if relevant (tags, category, danger level)
- two response buttons

### Deck or cycle summary panel
May show:
- current cycle size
- remaining cards
- resolved cards count
- optionally visible card slots, depending on scenario presentation

For RomeBots, the UI may eventually show a 12-card yearly deck or a summary of the current year's deck state.

### State summary panel
Shows:
- visible context values
- key relationship or faction indicators
- current high-level situation

### Event log panel
Shows:
- recent card resolutions
- recent cycle transitions
- important state changes

## Page/state types

### Landing page
- start scenario
- resume session
- future scenario selection

### Active session page
- active card
- two responses
- visible state
- recent event log
- cycle/deck summary

### Result/update state
After resolving a card:
- what was chosen
- what changed
- whether a new card is now active
- whether the cycle advanced

### Settings page
- sound/music toggles
- browser notification preferences (future)
- optional display preferences

### End-of-run page
- ending summary
- run recap
- restart / return options

## Interaction rules

- each active card should present exactly two clear response options
- response actions should feel immediate
- state changes should be surfaced clearly after resolution
- avoid burying the player in secondary menus
- the main action should almost always be obvious

## Turbo usage

Prefer Turbo for:
- swapping the active card
- refreshing deck/cycle summary
- updating visible state
- appending event log entries
- rendering cycle transitions

Avoid:
- excessive nested complexity early on
- overengineering every UI region into separate reactive islands

## Stimulus usage

Use Stimulus only where it clearly helps:
- audio hooks
- keyboard shortcuts
- toggling side panels
- simple transition polish
- notification permission requests (future)

Do not move core card logic into Stimulus controllers.

## Helpers

Helpers should handle:
- rendering state badges
- formatting context deltas
- formatting cycle labels
- formatting event log summaries
- presenting response labels consistently

Helpers should not:
- mutate state
- determine card eligibility
- apply game rules

## Accessibility

Aim for:
- semantic HTML
- keyboard-friendly response selection
- visible focus states
- strong text contrast
- minimal dependence on sound
- clear button labeling for the two responses

## Mobile friendliness

The game should remain fully playable on mobile.

Requirements:
- stacked layout
- large tap targets for the two responses
- readable card text
- collapsible secondary panels if needed
- no core dependence on hover interactions

## Audio

Audio is optional enhancement.

Possible future hooks:
- response confirm
- danger cue
- victory/failure cue
- cycle transition cue
- background music toggle

Audio must never be required to understand game state.

## Browser notifications

Notifications are a future enhancement.

Possible uses:
- return reminders
- long-timer completions
- async scenario events in future modes

Notifications should not be a milestone-1 dependency.

## Visual tone

Initial implementation should prioritize:
- strong hierarchy
- clean spacing
- readable typography
- clear emphasis on the active card and two choices

Theme-specific decoration should come after the core loop feels good.