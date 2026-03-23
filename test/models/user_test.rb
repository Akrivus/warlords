require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    UserIdentity.delete_all
    User.delete_all
    clear_oauth_mocks!
  end

  teardown do
    clear_oauth_mocks!
  end

  test "links a provider to an existing user with the same email" do
    user = create_user(email: "octavian@example.com")
    auth = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "github-123",
      info: { email: "octavian@example.com" }
    )

    result = User.from_omniauth(auth)

    assert_equal user, result.user
    assert_nil result.error
    assert_equal 1, user.user_identities.where(provider: "github", uid: "github-123").count
  end

  test "creates a new user and identity when no user matches" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-123",
      info: { email: "new_player@example.com", email_verified: true }
    )

    result = User.from_omniauth(auth)

    assert_predicate result.user, :persisted?
    assert_equal "new_player@example.com", result.user.email
    assert_equal ["google_oauth2"], result.user.user_identities.pluck(:provider)
  end

  test "rejects google auth without a verified email" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-123",
      info: { email: "octavian@example.com", email_verified: false }
    )

    result = User.from_omniauth(auth)

    assert_nil result.user
    assert_equal "Google did not provide a verified email address.", result.error
  end
end
