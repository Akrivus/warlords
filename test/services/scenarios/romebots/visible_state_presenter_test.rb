require "test_helper"

module Scenarios
  module Romebots
    class VisibleStatePresenterTest < ActiveSupport::TestCase
      setup do
        reset_game_data!
        load Rails.root.join("db/seeds.rb")
        UserIdentity.delete_all
        User.delete_all
        @user = create_user(email: "presenter@example.com")
        @session = Sessions::StartRun.call(scenario_key: "romebots", user: @user)
      end

      test "includes newly added state metrics when present in context" do
        context_state = @session.context_state.merge(
          "state.spy_network" => 62
        )
        @session.update!(context_state: context_state, deck_state: @session.deck_state.merge("cycle_start_context" => context_state.deep_dup))

        presenter = VisibleStatePresenter.new(game_session: @session)
        core_labels = presenter.sections.find { |section| section.key == :core }.rows.map(&:label)

        assert_includes core_labels, "Spy network"
      end

      test "assigns compact icon labels for rendered rows" do
        presenter = VisibleStatePresenter.new(game_session: @session)
        legitimacy_row = presenter.sections.find { |section| section.key == :core }.rows.find { |row| row.key == "state.legitimacy" }

        assert_equal "LG", legitimacy_row.icon_label
      end

      test "surfaces recently changed and current-card-relevant rows ahead of neutral extras" do
        context_state = @session.context_state.merge(
          "relations.agrippa" => 4,
          "relations.legions" => 0,
          "factions.roman_priesthood" => 0
        )
        @session.update!(
          context_state: context_state,
          deck_state: @session.deck_state.merge(
            "cycle_start_context" => Scenarios::Romebots::Configuration.initial_context
          )
        )
        current_card = @session.current_card || @session.session_cards.pending.order(:slot_index).first
        current_card ||= SessionCard.create!(
          game_session: @session,
          cycle_number: @session.cycle_number,
          slot_index: 99,
          title: "Agrippa",
          body: "Agrippa presses his case.",
          response_a_text: "A",
          response_b_text: "B",
          speaker_key: "agrippa",
          speaker_name: "Agrippa",
          portrait_key: "agrippa"
        )
        @session.update!(current_card: current_card) if @session.current_card.blank?
        current_card.update!(speaker_key: "agrippa", portrait_key: "agrippa")
        Logs::RecordEvent.call(
          game_session: @session,
          event_type: "response_resolved",
          title: "Recent change",
          payload: {
            "immediate_effects" => [
              { "op" => "increment", "key" => "relations.agrippa", "value" => 2 }
            ]
          }
        )

        presenter = VisibleStatePresenter.new(game_session: @session)
        relationship_rows = presenter.sections.find { |section| section.key == :relationships }.rows

        assert_equal "Agrippa", relationship_rows.first.label
        assert_includes relationship_rows.first.css_classes, "state-row--changed"
        assert_equal "up", relationship_rows.first.indicator_tone
      end

      test "omits configured metrics that are absent from the current context" do
        context_state = @session.context_state.except("state.senate_support")
        @session.update!(context_state: context_state)

        presenter = VisibleStatePresenter.new(game_session: @session)
        core_labels = presenter.sections.find { |section| section.key == :core }.rows.map(&:label)

        refute_includes core_labels, "Senate support"
      end

      test "sorts relationship rows by current score so negative ties sink" do
        context_state = @session.context_state.merge(
          "relations.agrippa" => 3,
          "relations.cicero" => 1,
          "relations.antony" => -4,
          "relations.plebs" => 0,
          "relations.legions" => 0
        )
        @session.update!(context_state: context_state)

        presenter = VisibleStatePresenter.new(game_session: @session)
        relationship_labels = presenter.sections.find { |section| section.key == :relationships }.rows.map(&:label)

        assert_equal ["Agrippa", "Cicero", "Legions", "Plebs"], relationship_labels.first(4)
      end
    end
  end
end
