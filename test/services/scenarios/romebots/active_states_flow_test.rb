require "test_helper"

class SessionStatesFlowTest < ActiveSupport::TestCase
  setup do
    reset_game_data!
    UserIdentity.delete_all
    User.delete_all
    @user = create_user(email: "states@example.com")
  end

  test "adding a session state persists a single runtime row" do
    session = build_session_with_opening_card!(
      response_a_states: [{ action: "add", key: "guard_mobilized", duration: { turns: 5 } }]
    )

    Choices::ResolveResponse.call(game_session: session, response_key: "a")
    session.reload

    state = session.session_states.find_by!(state_key: "guard_mobilized")
    assert_equal 1, session.session_states.where(state_key: "guard_mobilized").count
    assert_equal 1, state.applied_turn
    assert_equal(-44, state.applied_year)
    assert_equal 6, state.expires_turn
    assert_equal(-44, state.expires_year)
  end

  test "removing a session state clears the runtime row" do
    session = build_session_with_opening_card!(
      response_a_states: [{ action: "remove", key: "guard_mobilized" }]
    )
    session.session_states.create!(
      state_key: "guard_mobilized",
      source_card_key: "older_source",
      source_response_key: "a",
      applied_turn: 0,
      applied_year: -44,
      expires_turn: 3,
      expires_year: -44,
      metadata: {}
    )

    Choices::ResolveResponse.call(game_session: session, response_key: "a")
    session.reload

    assert_not session.session_states.exists?(state_key: "guard_mobilized")
  end

  test "re-adding the same session state refreshes instead of stacking" do
    session = build_session_with_opening_card!(
      response_a_states: [{ action: "add", key: "guard_mobilized" }],
      second_card_response_a_states: [{ action: "add", key: "guard_mobilized", duration: { turns: 5 } }]
    )

    Choices::ResolveResponse.call(game_session: session, response_key: "a")
    session.reload
    first_applied_turn = session.session_states.find_by!(state_key: "guard_mobilized").applied_turn

    Choices::ResolveResponse.call(game_session: session, response_key: "a")
    session.reload

    state = session.session_states.find_by!(state_key: "guard_mobilized")
    assert_equal 1, session.session_states.where(state_key: "guard_mobilized").count
    assert_operator state.applied_turn, :>, first_applied_turn
    assert_equal 7, state.expires_turn
  end

  test "a session state can apply recurring turn-start effects while active" do
    session = build_session_with_opening_card!(
      response_a_states: [{ action: "add", key: "eastern_intrigue", duration: { turns: 2 } }]
    )
    starting_circle = session.context_state["factions.octavian_circle"]
    opening_card_id = session.current_card.id

    Choices::ResolveResponse.call(game_session: session, response_key: "a")
    session.reload

    assert_equal starting_circle + 1, session.context_state["factions.octavian_circle"]
    assert session.session_states.exists?(state_key: "eastern_intrigue")
    assert_not_equal opening_card_id, session.current_card_id
  end

  test "a newly added timed active state affects the very next card exactly once via turn-start processing" do
    session = build_session_with_opening_card!(
      response_a_states: [{ action: "add", key: "eastern_intrigue", duration: { turns: 2 } }]
    )
    starting_circle = session.context_state["factions.octavian_circle"]

    Context::ResolveResponseMutations.call(
      game_session: session,
      session_card: session.current_card,
      response_key: "a"
    )
    session.reload

    assert_equal starting_circle, session.context_state["factions.octavian_circle"]
    assert session.session_states.exists?(state_key: "eastern_intrigue")

    Scenarios::Romebots::ActiveStates::ProcessTurnStart.call(game_session: session)
    session.reload

    assert_equal starting_circle + 1, session.context_state["factions.octavian_circle"]
  end

  test "session states expire after their turn duration is reached" do
    session = build_session_with_opening_card!(
      response_a_states: [{ action: "add", key: "guard_mobilized", duration: { turns: 1 } }]
    )
    starting_public_order = session.context_state["state.public_order"]

    Choices::ResolveResponse.call(game_session: session, response_key: "a")
    session.reload

    assert_equal starting_public_order + 1, session.context_state["state.public_order"]
    assert_not session.session_states.exists?(state_key: "guard_mobilized")
  end

  test "session states marked until year end expire before the summary is generated" do
    session = build_session_with_opening_card!(
      response_a_states: [{ action: "add", key: "whisper_campaign" }]
    )

    12.times do
      Choices::ResolveResponse.call(game_session: session, response_key: "a")
      session.reload
    end

    assert_equal "year_summary", session.status
    assert_not session.session_states.exists?(state_key: "whisper_campaign")
    assert_includes session.summary_data.dig("chronicle", "expired_this_year").map { |entry| entry["state_key"] }, "whisper_campaign"
  end

  test "explicit duration overrides the registry default" do
    session = build_session_with_opening_card!(
      response_a_states: [{ action: "add", key: "guard_mobilized", duration: { turns: 5 } }]
    )

    Choices::ResolveResponse.call(game_session: session, response_key: "a")
    session.reload

    assert_equal 6, session.session_states.find_by!(state_key: "guard_mobilized").expires_turn
  end

  test "immediate response effects still behave exactly as before" do
    session = build_session_with_opening_card!(
      response_a_effects: [{ op: "increment", key: "state.legitimacy", value: 4 }],
      response_a_states: [{ action: "add", key: "mourning_period" }]
    )
    starting_legitimacy = session.context_state["state.legitimacy"]

    Choices::ResolveResponse.call(game_session: session, response_key: "a")
    session.reload

    assert_equal starting_legitimacy + 4, session.context_state["state.legitimacy"]
  end

  test "a session state can make cards eligible while active" do
    session = build_custom_session_for_spawn_rules!(
      context_state: Scenarios::Romebots::Configuration.initial_context.merge("actors.armenian_envoys_known" => true),
      state_keys: ["eastern_intrigue"]
    )
    create_deck_candidate!(
      key: "eastern_court",
      weight: 150,
      tags: ["intrigue"],
      spawn_rules: {
        min_year: -43,
        max_year: -43,
        required_context: [{ key: "actors.armenian_envoys_known", equals: true }],
        required_session_states: ["eastern_intrigue"]
      }
    )
    12.times do |index|
      create_deck_candidate!(
        key: "filler_spawn_#{index}",
        weight: 100 - index,
        repeatable: true,
        spawn_rules: { min_year: -43, max_year: -43, repeatable: true }
      )
    end

    Decks::BuildForSession.call(game_session: session)

    assert session.session_cards.joins(:card_definition).exists?(card_definitions: { key: "eastern_court" })
  end

  test "expiring a session state removes its active eligibility and weight effects" do
    session = build_custom_session_for_spawn_rules!(
      context_state: Scenarios::Romebots::Configuration.initial_context.merge("actors.armenian_envoys_known" => true),
      state_keys: []
    )
    create_deck_candidate!(
      key: "eastern_court",
      weight: 150,
      tags: ["intrigue"],
      spawn_rules: {
        min_year: -43,
        max_year: -43,
        required_context: [{ key: "actors.armenian_envoys_known", equals: true }],
        required_session_states: ["eastern_intrigue"]
      }
    )
    create_deck_candidate!(
      key: "intrigue_low",
      weight: 90,
      tags: ["intrigue"],
      spawn_rules: { min_year: -43, max_year: -43 }
    )
    12.times do |index|
      create_deck_candidate!(
        key: "filler_future_#{index}",
        weight: 120 - index,
        tags: ["civic"],
        repeatable: true,
        spawn_rules: { min_year: -43, max_year: -43, repeatable: true }
      )
    end

    Decks::BuildForSession.call(game_session: session)

    assert_not session.session_cards.joins(:card_definition).exists?(card_definitions: { key: "eastern_court" })
    assert_not session.session_cards.joins(:card_definition).exists?(card_definitions: { key: "intrigue_low" })
  end

  test "persistent truths written to context_state remain after session state expiry" do
    session = build_session_with_opening_card!(
      response_a_effects: [{ op: "set", key: "flags.met_cicero", value: true }],
      response_a_states: [{ action: "add", key: "eastern_intrigue", duration: { turns: 1 } }]
    )

    Choices::ResolveResponse.call(game_session: session, response_key: "a")
    session.reload

    assert_equal true, session.context_state["flags.met_cicero"]
    assert_not session.session_states.exists?(state_key: "eastern_intrigue")
  end

  test "context_state and session state can both be used in spawn rule evaluation" do
    session = build_custom_session_for_spawn_rules!(
      context_state: Scenarios::Romebots::Configuration.initial_context.merge("actors.armenian_envoys_known" => true),
      state_keys: ["eastern_intrigue"]
    )
    create_deck_candidate!(
      key: "dual_gate",
      weight: 160,
      spawn_rules: {
        min_year: -43,
        max_year: -43,
        required_context: [{ key: "actors.armenian_envoys_known", equals: true }],
        required_session_states: ["eastern_intrigue"]
      }
    )
    12.times do |index|
      create_deck_candidate!(
        key: "filler_dual_#{index}",
        weight: 90 - index,
        repeatable: true,
        spawn_rules: { min_year: -43, max_year: -43, repeatable: true }
      )
    end

    Decks::BuildForSession.call(game_session: session)
    assert session.session_cards.joins(:card_definition).exists?(card_definitions: { key: "dual_gate" })

    session.update!(current_card: nil)
    session.event_logs.delete_all
    session.session_cards.destroy_all
    session.session_states.delete_all
    Decks::BuildForSession.call(game_session: session, force: true)

    assert_not session.session_cards.joins(:card_definition).exists?(card_definitions: { key: "dual_gate" })
  end

  test "session state weight modifiers only affect future deck builds" do
    session = build_custom_session_for_spawn_rules!(
      context_state: Scenarios::Romebots::Configuration.initial_context,
      state_keys: ["whisper_campaign"]
    )
    create_deck_candidate!(key: "plain_high", weight: 110, tags: ["civic"], spawn_rules: { min_year: -43, max_year: -43 })
    create_deck_candidate!(key: "intrigue_low", weight: 90, tags: ["intrigue"], spawn_rules: { min_year: -43, max_year: -43 })
    10.times do |index|
      create_deck_candidate!(key: "filler_#{index}", weight: 80 - index, tags: ["civic"], repeatable: true, spawn_rules: { min_year: -43, max_year: -43, repeatable: true })
    end
    create_deck_candidate!(key: "outside_cut", weight: 10, tags: ["civic"], repeatable: true, spawn_rules: { min_year: -43, max_year: -43, repeatable: true })

    Decks::BuildForSession.call(game_session: session)

    assert session.session_cards.joins(:card_definition).exists?(card_definitions: { key: "intrigue_low" })
    assert_not session.session_cards.joins(:card_definition).exists?(card_definitions: { key: "outside_cut" })
  end

  private

  def build_session_with_opening_card!(response_a_effects: [], response_a_states: [], second_card_response_a_states: [])
    create_deck_candidate!(
      key: "opening",
      weight: 200,
      response_a_effects: response_a_effects,
      response_a_states: response_a_states
    )
    create_deck_candidate!(
      key: "second",
      weight: 190,
      response_a_states: second_card_response_a_states
    )
    10.times do |index|
      create_deck_candidate!(key: "filler_#{index}", weight: 150 - index, repeatable: true)
    end

    Sessions::StartRun.call(scenario_key: "romebots", user: @user)
  end

  def build_custom_session_for_spawn_rules!(context_state:, state_keys:)
    session = GameSession.create!(
      user: @user,
      scenario_key: "romebots",
      status: "active",
      cycle_number: 2,
      context_state: context_state.merge(
        "time.year" => -43,
        "time.cycle_number" => 2,
        "time.cards_resolved_this_year" => 0
      ),
      deck_state: {}
    )

    state_keys.each do |state_key|
      session.session_states.create!(
        state_key: state_key,
        source_card_key: "manual",
        source_response_key: "a",
        applied_turn: 0,
        applied_year: -44,
        metadata: {}
      )
    end

    session
  end

  def create_deck_candidate!(key:, weight:, tags: ["test"], response_a_effects: [], response_a_states: [], repeatable: false, spawn_rules: nil)
    CardDefinition.create!(
      scenario_key: "romebots",
      key: key,
      title: key.titleize,
      body: "#{key} body",
      speaker_type: "figure",
      speaker_key: key,
      speaker_name: key.titleize,
      portrait_key: key,
      faction_key: "test_faction",
      card_type: "authored",
      active: true,
      weight: weight,
      tags: tags,
      spawn_rules: spawn_rules || { min_year: -44, max_year: 14, repeatable: repeatable },
      response_a_text: "Choose A",
      response_a_effects: response_a_effects,
      response_a_states: response_a_states,
      response_b_text: "Choose B",
      response_b_effects: [],
      response_b_states: []
    )
  end
end
