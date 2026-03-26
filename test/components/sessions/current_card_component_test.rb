require "test_helper"
require "view_component/test_case"

class Sessions::CurrentCardComponentTest < ViewComponent::TestCase
  setup do
    UserIdentity.delete_all
    User.delete_all
  end

  test "renders the active card with placeholder portrait and response buttons" do
    user = create_user(email: "component-card@example.com")
    session = Sessions::StartRun.call(scenario_key: "romebots", user: user)
    session.current_card.update!(
      speaker_name: "Senate Envoys",
      speaker_type: "group",
      portrait_key: "missing_portrait",
      faction_key: "senate_bloc"
    )

    render_inline(Sessions::CurrentCardComponent.new(game_session: session, card: session.current_card))

    assert_selector ".card-slot", text: "Card 1 of 12"
    assert_selector ".speaker-portrait--placeholder"
    assert_selector ".speaker-portrait-initials", text: "SE"
    assert_selector ".speaker-chip", text: "Group"
    assert_selector ".speaker-chip-faction", text: "Senate bloc"
    assert_selector "form button.response-a", text: session.current_card.response_a_text
    assert_selector "form button.response-b", text: session.current_card.response_b_text
  end

  test "renders the empty fallback when there is no active card" do
    user = create_user(email: "component-empty-card@example.com")
    session = Sessions::StartRun.call(scenario_key: "romebots", user: user)
    session.update!(current_card: nil)

    render_inline(Sessions::CurrentCardComponent.new(game_session: session, card: nil))

    assert_selector "p.eyebrow", text: "No Active Card"
    assert_selector "h2", text: "The session is between states."
    assert_text "Use the summary or ending flow to continue from here."
  end
end
