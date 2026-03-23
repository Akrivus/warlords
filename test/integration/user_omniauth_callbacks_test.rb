require "test_helper"

class UserOmniauthCallbacksTest < ActionDispatch::IntegrationTest
  setup do
    UserIdentity.delete_all
    User.delete_all
    clear_oauth_mocks!
  end

  teardown do
    clear_oauth_mocks!
  end

  test "google callback signs in an existing matching user and links the provider" do
    user = create_user(email: "octavian@example.com")
    mock_oauth(provider: :google_oauth2, uid: "google-123", email: user.email, email_verified: true)

    get user_google_oauth2_omniauth_callback_path

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
    assert_equal user.id, controller.current_user.id
    assert_equal 1, user.user_identities.where(provider: "google_oauth2", uid: "google-123").count
  end

  test "github callback creates a user who can start a game session" do
    mock_oauth(provider: :github, uid: "github-123", email: "new_player@example.com")

    get user_github_omniauth_callback_path
    assert_redirected_to root_path

    follow_redirect!
    assert_response :success

    assert_difference("GameSession.count", 1) do
      post game_sessions_path, params: { scenario_key: "romebots" }
    end

    session = GameSession.order(:created_at).last
    assert_equal "new_player@example.com", session.user.email
  end

  test "callback rejects auth without an email" do
    mock_oauth(provider: :github, uid: "github-123", email: "")

    get user_github_omniauth_callback_path

    assert_redirected_to new_user_session_path
    assert_equal 0, User.count
  end

  test "sign in and registration screens show email auth and SSO options" do
    get new_user_session_path
    assert_response :success
    assert_select "input[type=email]"
    assert_select "button", text: "Sign in with Google"
    assert_select "button", text: "Sign in with GitHub"

    get new_user_registration_path
    assert_response :success
    assert_select "input[type=password]", minimum: 2
    assert_select "button", text: "Sign in with Google"
    assert_select "button", text: "Sign in with GitHub"
  end
end
