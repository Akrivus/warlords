# ViewComponent Extraction Candidates

This review focused on the Rails session UI in `app/views/sessions`, because that is where nearly all of the game-specific rendering lives today. There is no existing `app/components` directory yet, so the best first extractions are the places with the most branching, the clearest UI boundaries, and the highest chance of growing again soon.

## Extract now

### 1. `ChronicleEntryComponent`
- Current partial/view(s): `app/views/sessions/_event_log.html.erb`, backed by `app/services/chronicle/entry_presenter.rb` and `app/services/chronicle/feed_builder.rb`
- Why it repeats or branches:
  - The event log loops over entries and conditionally renders different content for primary entries, summaries, chosen responses, and visible state gains/losses.
  - This is already event-type-driven UI, and the branching will grow as more event types are surfaced.
  - The current partial mixes feed layout concerns with per-entry rendering rules.
- Expected props / inputs:
  - `entry:`
  - Optional display flags such as `truncate_length:` or `show_state_changes:`
- Why it is worth extracting:
  - This is the cleanest component seam in the codebase tonight: one item, one presenter, one visual unit, lots of conditional output.
  - It would keep `_event_log` as a simple list shell and make future event variants safer to add.
  - It is the strongest immediate candidate.

### 2. `CurrentCardComponent`
- Current partial/view(s): `app/views/sessions/show.html.erb`
- Why it repeats or branches:
  - The current-card block is the densest template in the app: it handles missing-card fallback, portrait-or-placeholder rendering, optional speaker chips, body text, and two choice buttons.
  - It is currently embedded directly in the page view, so the main session template is carrying both page layout and detailed card presentation logic.
  - Even though it only appears in one page today, it already behaves like a standalone card UI object.
- Expected props / inputs:
  - `game_session:`
  - `card:`
  - `deck_progress_label:`
  - `choice_path_builder:` or precomputed choice URLs for responses A/B
  - Optionally precomputed presentation values such as `portrait_path`, `speaker_type_label`, `speaker_faction_label`
- Why it is worth extracting:
  - It would remove the biggest concentration of branching markup from `show.html.erb`.
  - This is likely to change as card variants, disabled states, previews, or richer speaker treatment are added.
  - It creates a strong foundation for later extracting smaller subcomponents only if they become necessary.

### 3. `StatePanelComponent`
- Current partial/view(s): `app/views/sessions/_state_panel.html.erb`, rendered from `app/views/sessions/show.html.erb`, `app/views/sessions/summary.html.erb`, and `app/views/sessions/ending.html.erb`
- Why it repeats or branches:
  - The panel is already reused three times, and each render depends on a presenter with nested sections and rows.
  - Inside the partial, each row conditionally renders indicator badges and multiple CSS states.
  - This is more than a shared partial now; it is a stable UI unit with a fairly rich input contract.
- Expected props / inputs:
  - `title:`
  - `state_presenter:`
  - `panel_class:` or a more generic `html_class:`
- Why it is worth extracting:
  - It already has the repetition needed to justify a component.
  - A component would make the repeated side-panel usage in show/summary/ending more explicit and easier to preview/test.
  - The presenter boundary is already in place, so the extraction cost should be moderate.

### 4. `StateRowIndicatorComponent` or `BadgeComponent`
- Current partial/view(s): primarily indicator spans in `app/views/sessions/_state_panel.html.erb`, plus tag/badge-style spans in `app/views/sessions/_active_states_panel.html.erb`, `app/views/sessions/show.html.erb`, `app/views/sessions/summary.html.erb`, and `app/views/sessions/ending.html.erb`
- Why it repeats or branches:
  - The app uses several badge-like UI elements: session meta pills, state indicators, speaker chips, active-state tags, and duration labels.
  - The visual pattern is repeated, but the semantics are still slightly fragmented.
- Expected props / inputs:
  - `label:`
  - `tone:` or `variant:`
  - `size:` if needed
  - Optional `html_class:`
- Why it is worth extracting:
  - This is a good fourth choice if you want a small supporting primitive after the three larger components above.
  - It would help standardize status UI, but it is less urgent than the three candidates above because the repeated markup is still simple.

## Extract later

### `SessionHeaderComponent`
- Current partial/view(s): `app/views/sessions/show.html.erb`, `app/views/sessions/summary.html.erb`, `app/views/sessions/ending.html.erb`
- Why it repeats or branches:
  - All three pages share the same `session-header` structure with eyebrow, title, and right-side pills.
  - The content differs slightly per page, but the structure is clearly converging.
- Expected props / inputs:
  - `eyebrow:`
  - `title:`
  - `meta_items:` or left/right slot content
- Why it is not worth extracting yet:
  - The repetition is real, but the markup is still shallow and readable.
  - Extracting the heavier content blocks first would buy more clarity tonight.

### `ActiveStatePanelComponent`
- Current partial/view(s): `app/views/sessions/_active_states_panel.html.erb`
- Why it repeats or branches:
  - It renders a list of entries with optional duration labels and behavior tags, plus an empty state.
  - This is structurally similar to a component, but it currently appears in only one place.
- Expected props / inputs:
  - `active_states_presenter:`
  - `panel_class:`
- Why it is not worth extracting yet:
  - The presenter already does most of the hard work and the template is still compact.
  - It becomes much more compelling if the same panel appears on additional pages or if each active state entry gains more behavior.

### `ChoiceButtonRowComponent`
- Current partial/view(s): response button block in `app/views/sessions/show.html.erb`
- Why it repeats or branches:
  - The current card renders two buttons with mirrored structure and choice-specific styling.
  - Choice rows are a likely future pattern if cards gain disabled states, hotkeys, outcome previews, or more than two responses.
- Expected props / inputs:
  - `choices:`
  - `submit_path:` or per-choice URL
  - `method:`
  - Optional `disabled:` / `variant:`
- Why it is not worth extracting yet:
  - Today it is only two straightforward `button_to` calls.
  - This is probably better folded into `CurrentCardComponent` first, then split later only if the choice UI becomes more complex.

### `SummaryHighlightListComponent`
- Current partial/view(s): summary highlight list in `app/views/sessions/summary.html.erb`
- Why it repeats or branches:
  - Each highlight renders a label, a delta badge, and a from/to range.
  - It has a mini row structure with tone-based styling.
- Expected props / inputs:
  - `highlights:`
- Why it is not worth extracting yet:
  - The pattern is self-contained but currently single-use.
  - It does not appear to be under the same growth pressure as the chronicle or current card UI.

## Not worth it

### Standalone `PortraitComponent`
- Current partial/view(s): portrait wrapper inside `app/views/sessions/show.html.erb`
- Why it repeats or branches:
  - It has a real image-vs-placeholder branch and could technically stand alone.
- Expected props / inputs:
  - `portrait_path:`
  - `speaker_name:`
  - `placeholder_initials:`
  - `placeholder_label:`
- Why it is not worth extracting:
  - On its own, the portrait wrapper is too narrow and only used once.
  - It makes more sense as an internal piece of `CurrentCardComponent` than as one of the first public components.

### Standalone `SpeakerChipComponent`
- Current partial/view(s): speaker type/faction chips in `app/views/sessions/show.html.erb`
- Why it repeats or branches:
  - There are two chips with small variant differences.
- Expected props / inputs:
  - `label:`
  - `variant:`
- Why it is not worth extracting:
  - The branch count is tiny and the current markup is already easy to scan.
  - A general badge primitive would subsume this later if needed.

### Standalone `PillComponent` for session meta only
- Current partial/view(s): header pills in `app/views/sessions/show.html.erb`, `app/views/sessions/summary.html.erb`, `app/views/sessions/ending.html.erb`
- Why it repeats or branches:
  - The same `.pill` class appears in multiple headers.
- Expected props / inputs:
  - `label:`
- Why it is not worth extracting:
  - This is styling reuse more than behavior reuse.
  - Converting plain text spans into a dedicated component now would add indirection without reducing meaningful complexity.

### Wrapping the existing partials one-for-one without narrowing their API
- Current partial/view(s): `app/views/sessions/_state_panel.html.erb`, `app/views/sessions/_active_states_panel.html.erb`, `app/views/sessions/_event_log.html.erb`
- Why it repeats or branches:
  - These partials are already shared.
- Expected props / inputs:
  - Same as today.
- Why it is not worth extracting:
  - A mechanical partial-to-component migration, without using the component boundary to clarify responsibilities, would mostly add churn.
  - The best extractions are the ones that either isolate branching item rendering (`ChronicleEntryComponent`) or remove a dense composite block from a page (`CurrentCardComponent`).

## Ranked recommendation

If only 2 to 4 components should be extracted immediately, the best order is:

1. `ChronicleEntryComponent`
2. `CurrentCardComponent`
3. `StatePanelComponent`
4. `BadgeComponent` or `StateRowIndicatorComponent` only if a small shared primitive is useful in the same pass

That gives the highest payoff tonight:
- one event-driven list item component
- one dense card/choice composite component
- one clearly reusable side-panel component
- optionally one small status-ui primitive if needed to unify badges across the extracted components
