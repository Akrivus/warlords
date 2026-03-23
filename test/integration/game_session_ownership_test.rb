require "test_helper"

class GameSessionOwnershipTest < ActionDispatch::IntegrationTest
  setup do
    UserIdentity.delete_all
    User.delete_all
    @player_one = create_user(email: "player_one@example.com")
    @player_two = create_user(email: "player_two@example.com")
  end

  test "authenticated user can create and view their own session" do
    sign_in @player_one

    post game_sessions_path, params: { scenario_key: "romebots" }
    session = GameSession.order(:created_at).last

    assert_equal @player_one, session.user
    assert_redirected_to game_session_path(session)

    follow_redirect!
    assert_response :success
    assert_select "h1", "44 BCE"
  end

  test "user cannot access another user's session" do
    session = Sessions::StartRun.call(scenario_key: "romebots", user: @player_one)
    sign_in @player_two

    get game_session_path(session)
    assert_response :not_found

    sign_in @player_two
    post game_session_choices_path(session), params: { response_key: "a" }
    assert_response :not_found
  end

  test "session creation attaches ownership correctly" do
    sign_in @player_one

    assert_difference("GameSession.where(user: @player_one).count", 1) do
      post game_sessions_path, params: { scenario_key: "romebots" }
    end

    session = GameSession.order(:created_at).last
    assert_equal @player_one.id, session.user_id
  end
end
