require "test_helper"

class RomebotsFlowTest < ActionDispatch::IntegrationTest
  setup do
    UserIdentity.delete_all
    User.delete_all
    @user = create_user(email: "player_one@example.com")
    sign_in @user
  end

  test "player can finish a year, review the summary, and continue into the next year" do
    get root_path
    assert_response :success
    assert_select "h1", "RomeBots"
    assert_select "form button", "Start A New Run"

    post game_sessions_path, params: { scenario_key: "romebots" }
    session = GameSession.order(:created_at).last

    assert_redirected_to game_session_path(session)
    follow_redirect!
    assert_response :success
    assert_select "h3", "Core State"
    assert_select "h3", "Character Relationships"
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
    assert_select "h1", /Year 44 BCE in review/
    assert_select "form button", /Continue To Next Year/

    post advance_game_session_path(session)
    assert_redirected_to game_session_path(session)

    follow_redirect!
    assert_response :success
    session.reload
    assert_equal "active", session.status
    assert_equal 2, session.cycle_number
    assert_equal(-43, session.context_state["time.year"])
    assert_select "h1", "43 BCE"
  end

  test "player is redirected to a simple ending when a catastrophic state is reached" do
    session = Sessions::StartRun.call(scenario_key: "romebots", user: @user)
    session.update!(context_state: session.context_state.merge("state.health" => 0))

    post game_session_choices_path(session), params: { response_key: "a" }
    assert_redirected_to ending_game_session_path(session)

    follow_redirect!
    assert_response :success
    session.reload
    assert_equal "failed", session.status
    assert_select "h1", "Octavian is dead"
  end

  test "active card renders a portrait image when a matching portrait asset exists" do
    session = Sessions::StartRun.call(scenario_key: "romebots", user: @user)
    session.current_card.update!(
      speaker_name: "Julius Caesar",
      speaker_type: "figure",
      portrait_key: "caesar",
      faction_key: "julian_house"
    )

    get game_session_path(session)

    assert_response :success
    assert_select "img.speaker-portrait-image[alt='Julius Caesar portrait']"
    assert_select ".speaker-chip", text: "Figure"
    assert_select ".speaker-chip-faction", text: "Julian house"
  end

  test "active card renders an uploaded portrait before falling back to portrait_key assets" do
    session = Sessions::StartRun.call(scenario_key: "romebots", user: @user)
    session.current_card.update!(
      speaker_name: "Julius Caesar",
      speaker_type: "figure",
      portrait_key: "caesar",
      faction_key: "julian_house"
    )
    session.current_card.card_definition.portrait_upload.attach(
      io: file_fixture("uploaded_portrait.svg").open,
      filename: "uploaded_portrait.svg",
      content_type: "image/svg+xml"
    )

    get game_session_path(session)

    assert_response :success
    assert_select "img.speaker-portrait-image[src*='/rails/active_storage/blobs/']"
  end

  test "active card falls back to a placeholder when no portrait asset exists" do
    session = Sessions::StartRun.call(scenario_key: "romebots", user: @user)
    session.current_card.update!(
      speaker_name: "Senate Envoys",
      speaker_type: "group",
      portrait_key: "missing_portrait",
      faction_key: "senate_bloc"
    )

    get game_session_path(session)

    assert_response :success
    assert_select ".speaker-portrait--placeholder", count: 1
    assert_select ".speaker-portrait-initials", text: "SE"
    assert_select ".speaker-portrait-caption", text: "missing_portrait"
    assert_select "img.speaker-portrait-image", count: 0
  end

  test "state panel renders when expected metrics are absent and new visible metrics appear" do
    session = Sessions::StartRun.call(scenario_key: "romebots", user: @user)
    session.update!(
      context_state: session.context_state
        .except("state.senate_support")
        .merge("state.spy_network" => 61)
    )

    get game_session_path(session)

    assert_response :success
    assert_select ".state-row-label", text: "Spy network"
    assert_select ".state-row-label", text: "Senate support", count: 0
  end
end
