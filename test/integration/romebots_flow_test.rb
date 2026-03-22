require "test_helper"

class RomebotsFlowTest < ActionDispatch::IntegrationTest
  test "player can finish a year, review the summary, and continue into the next year" do
    get root_path
    assert_response :success
    assert_select "h1", "RomeBots"

    post game_sessions_path, params: { scenario_key: "romebots" }
    session = GameSession.order(:created_at).last

    assert_redirected_to game_session_path(session)
    follow_redirect!
    assert_response :success
    assert_select "h3", "Relationships"
    assert_select "h3", "Faction Pressures"
    12.times do |index|
      session.reload
      post game_session_choices_path(session), params: { response_key: "a" }

      expected_location = index == 11 ? summary_game_session_path(session) : game_session_path(session)
      assert_redirected_to expected_location
    end

    session.reload
    assert_equal "year_summary", session.status

    follow_redirect!
    assert_response :success
    assert_select "h1", /Year 44 in review/
    assert_select "form button", /Continue To Next Year/

    post advance_game_session_path(session)
    assert_redirected_to game_session_path(session)

    follow_redirect!
    assert_response :success
    session.reload
    assert_equal "active", session.status
    assert_equal 2, session.cycle_number
    assert_equal 43, session.context_state["time.year"]
    assert_select "h1", "43 BCE"
  end

  test "player is redirected to a simple ending when a catastrophic state is reached" do
    session = Sessions::StartRun.call(scenario_key: "romebots")
    session.update!(context_state: session.context_state.merge("state.health" => 0))

    post game_session_choices_path(session), params: { response_key: "a" }
    assert_redirected_to ending_game_session_path(session)

    follow_redirect!
    assert_response :success
    session.reload
    assert_equal "failed", session.status
    assert_select "h1", "Octavian is dead"
  end
end
