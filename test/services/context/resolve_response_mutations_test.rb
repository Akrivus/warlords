require "test_helper"

module Context
  class ResolveResponseMutationsTest < ActiveSupport::TestCase
    setup do
      reset_game_data!
      UserIdentity.delete_all
      User.delete_all
      @user = create_user(email: "context-sequencing@example.com")
    end

    test "increments resolved-card count before applying active-state operations" do
      session = build_session_with_opening_card!(
        response_a_states: [{ action: "add", key: "guard_mobilized", duration: { turns: 1 } }]
      )

      result = ResolveResponseMutations.call(
        game_session: session,
        session_card: session.current_card,
        response_key: "a"
      )
      state = session.reload.session_states.find_by!(state_key: "guard_mobilized")

      assert_equal 1, result.fetch(:context_after)["time.cards_resolved_this_year"]
      assert_equal 1, state.applied_turn
      assert_equal 2, state.expires_turn
    end

    test "does not apply recurring turn-start effects during response mutation sequencing" do
      session = build_session_with_opening_card!(
        response_a_states: [{ action: "add", key: "eastern_intrigue", duration: { turns: 2 } }]
      )
      starting_circle = session.context_state["factions.octavian_circle"]

      ResolveResponseMutations.call(
        game_session: session,
        session_card: session.current_card,
        response_key: "a"
      )
      session.reload

      assert_equal starting_circle, session.context_state["factions.octavian_circle"]

      Scenarios::Romebots::ActiveStates::ProcessTurnStart.call(game_session: session)
      session.reload

      assert_equal starting_circle + 1, session.context_state["factions.octavian_circle"]
    end

    private

    def build_session_with_opening_card!(response_a_effects: [], response_a_states: [])
      create_deck_candidate!(
        key: "opening",
        weight: 200,
        response_a_effects: response_a_effects,
        response_a_states: response_a_states
      )
      create_deck_candidate!(key: "second", weight: 190)
      10.times do |index|
        create_deck_candidate!(key: "filler_#{index}", weight: 150 - index, repeatable: true)
      end

      Sessions::StartRun.call(scenario_key: "romebots", user: @user)
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
end
