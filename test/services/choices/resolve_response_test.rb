require "test_helper"

module Choices
  class ResolveResponseTest < ActiveSupport::TestCase
    setup do
      reset_game_data!
      load Rails.root.join("db/seeds.rb")
      UserIdentity.delete_all
      User.delete_all
      @user = create_user(email: "player_one@example.com")
      @session = Sessions::StartRun.call(scenario_key: "romebots", user: @user)
    end

    test "resolves a response, mutates context, and advances to the next card" do
      current_card = @session.current_card
      starting_legitimacy = @session.context_state["state.legitimacy"]
      starting_julian_pressure = @session.context_state["factions.julian_house"]
      starting_antony_relation = @session.context_state["relations.antony"]

      Choices::ResolveResponse.call(game_session: @session, response_key: "a")
      @session.reload
      current_card.reload

      assert_equal "resolved", current_card.status
      assert_equal "a", current_card.chosen_response
      assert_equal starting_legitimacy + 10, @session.context_state["state.legitimacy"]
      assert_equal starting_julian_pressure + 2, @session.context_state["factions.julian_house"]
      assert_equal starting_antony_relation - 1, @session.context_state["relations.antony"]
      assert_equal 1, @session.context_state["time.cards_resolved_this_year"]
      assert_not_equal current_card.id, @session.current_card_id
      assert_equal 1, @session.deck_state["resolved_cards"]
      assert_equal "card_presented", @session.event_logs.first.event_type
    end

    test "response with no follow up behaves normally" do
      Choices::ResolveResponse.call(game_session: @session, response_key: "a")
      @session.reload

      assert_equal "Return to Rome", @session.current_card.title
    end

    test "response with follow up activates an existing pending follow up card next" do
      6.times do
        Choices::ResolveResponse.call(game_session: @session, response_key: "a")
        @session.reload
      end

      assert_equal "Grain Anxiety", @session.current_card.title
      assert_equal "whisper_campaign", @session.current_card.response_b_follow_up_card_key

      Choices::ResolveResponse.call(game_session: @session, response_key: "b")
      @session.reload

      assert_equal "Whisper Campaign", @session.current_card.title
      assert_equal "whisper_campaign", @session.current_card.card_definition.key
      assert_equal @session.session_cards.find_by(title: "Grain Anxiety").id, @session.current_card.metadata["follow_up_parent_session_card_id"]
      assert_equal 1, @session.current_card.metadata["follow_up_depth"]
    end

    test "response with follow up can create a new follow up card predictably" do
      reset_game_data!

      source_card = CardDefinition.create!(
        scenario_key: "romebots",
        key: "source_card",
        title: "Source Card",
        body: "A source card.",
        speaker_type: "figure",
        speaker_key: "source",
        speaker_name: "Source",
        portrait_key: "source",
        faction_key: "source_faction",
        card_type: "authored",
        active: true,
        weight: 200,
        tags: ["test"],
        spawn_rules: { min_year: -44, max_year: -44, one_time_only: true },
        response_a_text: "Trigger follow up.",
        response_a_effects: [{ op: "increment", key: "state.legitimacy", value: 1 }],
        response_a_follow_up_card_key: "hidden_follow_up",
        response_b_text: "Do nothing.",
        response_b_effects: [{ op: "increment", key: "state.legitimacy", value: 0 }]
      )
      follow_up_card = CardDefinition.create!(
        scenario_key: "romebots",
        key: "hidden_follow_up",
        title: "Hidden Follow Up",
        body: "The consequence arrives.",
        speaker_type: "group",
        speaker_key: "followers",
        speaker_name: "Followers",
        portrait_key: "followers",
        faction_key: "test_faction",
        card_type: "authored",
        active: true,
        weight: 0,
        tags: ["test"],
        spawn_rules: { min_year: -44, max_year: -44, one_time_only: true },
        response_a_text: "Continue.",
        response_a_effects: [{ op: "increment", key: "state.public_order", value: 1 }],
        response_b_text: "Refuse.",
        response_b_effects: [{ op: "increment", key: "state.public_order", value: -1 }]
      )
      11.times do |index|
        CardDefinition.create!(
          scenario_key: "romebots",
          key: "filler_#{index}",
          title: "Filler #{index}",
          body: "Filler card #{index}.",
          speaker_type: "group",
          speaker_key: "filler_#{index}",
          speaker_name: "Filler #{index}",
          portrait_key: "filler_#{index}",
          faction_key: "filler_faction",
          card_type: "system",
          active: true,
          weight: 100 - index,
          tags: ["test"],
          spawn_rules: { min_year: -44, max_year: -44, repeatable: true },
          response_a_text: "A",
          response_a_effects: [{ op: "increment", key: "state.public_order", value: 0 }],
          response_b_text: "B",
          response_b_effects: [{ op: "increment", key: "state.public_order", value: 0 }]
        )
      end

      custom_session = Sessions::StartRun.call(scenario_key: "romebots", user: @user)
      custom_session.reload
      assert_equal source_card.id, custom_session.current_card.card_definition_id
      refute custom_session.session_cards.where(card_definition_id: follow_up_card.id).exists?

      Choices::ResolveResponse.call(game_session: custom_session, response_key: "a")
      custom_session.reload

      created_follow_up = custom_session.current_card
      parent_session_card = custom_session.session_cards.find_by!(card_definition_id: source_card.id)
      assert_equal "Hidden Follow Up", created_follow_up.title
      assert_equal follow_up_card.id, created_follow_up.card_definition_id
      assert_equal 13, custom_session.session_cards.where(cycle_number: 1).count
      assert_equal 13, created_follow_up.slot_index
      assert_equal parent_session_card.id, created_follow_up.metadata["follow_up_parent_session_card_id"]
    end
  end
end
