require "test_helper"

class CyclesAdvanceTest < ActiveSupport::TestCase
  setup do
    reset_game_data!
    load Rails.root.join("db/seeds.rb")
    @session = Sessions::StartRun.call(scenario_key: "romebots")
    @session.session_cards.where(cycle_number: 1).order(:slot_index).each do
      Choices::ResolveResponse.call(game_session: @session, response_key: "a")
      @session.reload
    end
  end

  test "advances from year summary into the next year and builds a new deck" do
    assert_equal "year_summary", @session.status
    assert_equal 44, @session.context_state["time.year"]

    Cycles::Advance.call(game_session: @session)
    @session.reload

    assert_equal "active", @session.status
    assert_equal 2, @session.cycle_number
    assert_equal 43, @session.context_state["time.year"]
    assert_equal 0, @session.context_state["time.cards_resolved_this_year"]
    assert_equal 12, @session.session_cards.where(cycle_number: 2).count
    assert_predicate @session.current_card, :present?
    assert_includes @session.event_logs.limit(6).map(&:event_type), "cycle_advanced"
  end
end
