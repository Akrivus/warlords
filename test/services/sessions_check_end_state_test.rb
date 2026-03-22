require "test_helper"

class SessionsCheckEndStateTest < ActiveSupport::TestCase
  setup do
    reset_game_data!
    load Rails.root.join("db/seeds.rb")
  end

  test "returns nil for stable state" do
    session = Sessions::StartRun.call(scenario_key: "romebots")

    assert_nil Sessions::CheckEndState.call(game_session: session)
  end

  test "detects catastrophic death" do
    session = Sessions::StartRun.call(scenario_key: "romebots")
    session.update!(context_state: session.context_state.merge("state.health" => 0))

    end_state = Sessions::CheckEndState.call(game_session: session)

    assert_equal "death", end_state["code"]
    assert_equal "failed", end_state["status"]
  end
end
