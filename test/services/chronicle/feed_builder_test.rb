require "test_helper"

module Chronicle
  class FeedBuilderTest < ActiveSupport::TestCase
    setup do
      reset_game_data!
      UserIdentity.delete_all
      User.delete_all
      @user = create_user(email: "chronicle@example.com")
    end

    test "response_resolved includes chronicle-friendly payload data" do
      session = build_session_with_opening_card!(
        response_a_effects: [{ op: "increment", key: "state.legitimacy", value: 4 }],
        response_a_states: [{ action: "add", key: "guard_mobilized", duration: { turns: 5 } }]
      )
      starting_legitimacy = session.context_state["state.legitimacy"]

      Choices::ResolveResponse.call(game_session: session, response_key: "a")
      event = session.reload.event_logs.find_by!(event_type: "response_resolved")

      assert_equal "a", event.payload["response_key"]
      assert_equal "Choose A", event.payload["response_text"]
      assert_equal "Choose A", event.payload["response_log"]
      assert_equal "Opening", event.payload["card_title"]
      assert_equal "opening body", event.payload["card_body"]
      assert_equal [{ "op" => "increment", "key" => "state.legitimacy", "value" => 4 }], event.payload["immediate_effects"]
      assert_includes event.payload["context_changes"], { "key" => "state.legitimacy", "before" => starting_legitimacy, "after" => starting_legitimacy + 4, "delta" => 4 }
      assert_includes event.payload["session_states_added"].map { |state| state["state_key"] }, "guard_mobilized"
    end

    test "state lifecycle events are recorded with consistent payloads" do
      session = build_session_with_opening_card!(
        response_a_states: [{ action: "add", key: "guard_mobilized", duration: { turns: 1 } }]
      )

      Choices::ResolveResponse.call(game_session: session, response_key: "a")
      session.reload

      added_event = session.event_logs.find_by!(event_type: "session_state_added")
      expired_event = session.event_logs.find_by!(event_type: "session_state_expired")

      assert_equal "guard_mobilized", added_event.payload["state_key"]
      assert_equal "opening", added_event.payload["source_card_key"]
      assert_equal "a", added_event.payload["source_response_key"]
      assert_equal 2, added_event.payload["expires_turn"]
      assert_equal(-44, added_event.payload["expires_year"])

      assert_equal "guard_mobilized", expired_event.payload["state_key"]
      assert_equal "opening", expired_event.payload["source_card_key"]
      assert_equal "a", expired_event.payload["source_response_key"]
      assert_equal "turn_duration_reached", expired_event.payload["reason"]
    end

    test "chronicle feed builder returns readable entries in chronological order" do
      session = build_session_with_opening_card!

      Choices::ResolveResponse.call(game_session: session, response_key: "a")
      session.reload

      entries = Chronicle::FeedBuilder.new(game_session: session).entries

      assert_equal ["response_resolved", "year_started", "session_started"], entries.first(3).map(&:event_type)
      assert_equal entries.sort_by(&:occurred_at).reverse.map(&:occurred_at), entries.map(&:occurred_at)
    end

    test "low-value system events are filtered by default" do
      session = build_session_with_opening_card!

      entries = Chronicle::FeedBuilder.new(game_session: session).entries
      event_types = entries.map(&:event_type)

      assert_includes event_types, "year_started"
      refute_includes event_types, "deck_built"
      refute_includes event_types, "card_presented"
    end

    test "session state changes can appear alongside the related narrative event" do
      session = build_session_with_opening_card!(
        response_a_states: [
          { action: "add", key: "guard_mobilized", duration: { turns: 5 } }
        ]
      )
      session.session_states.create!(
        state_key: "mourning_period",
        source_card_key: "older_source",
        source_response_key: "b",
        applied_turn: 0,
        applied_year: -44,
        expires_year: -44,
        metadata: {}
      )
      session.current_card.update!(
        response_a_states: [
          { action: "add", key: "guard_mobilized", duration: { turns: 5 } },
          { action: "remove", key: "mourning_period" }
        ]
      )

      Choices::ResolveResponse.call(game_session: session, response_key: "a")
      entry = Chronicle::FeedBuilder.new(game_session: session.reload).entries.find(&:primary?)

      assert_includes entry.session_states_added.map { |state| state["state_key"] }, "guard_mobilized"
      assert_includes entry.session_states_removed.map { |state| state["state_key"] }, "mourning_period"
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
