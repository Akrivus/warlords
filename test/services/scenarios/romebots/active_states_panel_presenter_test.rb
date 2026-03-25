require "test_helper"

module Scenarios
  module Romebots
    class ActiveStatesPanelPresenterTest < ActiveSupport::TestCase
      setup do
        reset_game_data!
        UserIdentity.delete_all
        User.delete_all
        @user = create_user(email: "active-state-panel@example.com")
        @session = GameSession.create!(
          user: @user,
          scenario_key: "romebots",
          status: "active",
          cycle_number: 1,
          context_state: Scenarios::Romebots::Configuration.initial_context.merge(
            "time.year" => -44,
            "time.cards_resolved_this_year" => 2
          ),
          deck_state: {}
        )
      end

      test "formats turn-based duration text" do
        @session.session_states.create!(
          state_key: "guard_mobilized",
          source_card_key: "opening",
          source_response_key: "a",
          applied_turn: 1,
          applied_year: -44,
          expires_turn: 5,
          expires_year: -44,
          metadata: {}
        )

        entry = ActiveStatesPanelPresenter.new(game_session: @session).entries.first

        assert_equal "3 turns left", entry.duration_label
      end

      test "formats year-end duration text" do
        @session.session_states.create!(
          state_key: "whisper_campaign",
          source_card_key: "opening",
          source_response_key: "a",
          applied_turn: 1,
          applied_year: -44,
          expires_turn: nil,
          expires_year: -44,
          metadata: {}
        )

        entry = ActiveStatesPanelPresenter.new(game_session: @session).entries.first

        assert_equal "Until year end", entry.duration_label
        assert_includes entry.behavior_tags, "Year-end"
      end

      test "filters out expired runtime states" do
        @session.session_states.create!(
          state_key: "guard_mobilized",
          source_card_key: "opening",
          source_response_key: "a",
          applied_turn: 0,
          applied_year: -44,
          expires_turn: 1,
          expires_year: -44,
          metadata: {}
        )

        presenter = ActiveStatesPanelPresenter.new(game_session: @session)

        assert presenter.empty?
      end

      test "panel liveness matches shared lifecycle semantics" do
        @session.session_states.create!(
          state_key: "guard_mobilized",
          source_card_key: "opening",
          source_response_key: "a",
          applied_turn: 1,
          applied_year: -44,
          expires_turn: 2,
          expires_year: -44,
          metadata: {}
        )
        @session.session_states.create!(
          state_key: "grain_crisis",
          source_card_key: "opening",
          source_response_key: "a",
          applied_turn: 1,
          applied_year: -44,
          expires_turn: nil,
          expires_year: -44,
          metadata: {}
        )
        @session.session_states.create!(
          state_key: "veteran_discontent",
          source_card_key: "opening",
          source_response_key: "a",
          applied_turn: 0,
          applied_year: -44,
          expires_turn: 1,
          expires_year: -44,
          metadata: {}
        )

        lifecycle = SessionStateLifecycle.new(current_year: -44, current_turn: 2, upcoming_turn: 3)
        expected_keys = @session.session_states.select { |state| lifecycle.active?(state) }.map(&:state_key).sort

        presenter_keys = ActiveStatesPanelPresenter.new(game_session: @session).entries.map(&:key).sort

        assert_equal expected_keys, presenter_keys
      end
    end
  end
end
