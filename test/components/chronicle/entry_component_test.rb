require "test_helper"
require "view_component/test_case"

class Chronicle::EntryComponentTest < ViewComponent::TestCase
  test "renders a primary chronicle entry with summary and state changes" do
    event_log = EventLog.new(
      event_type: "response_resolved",
      title: "Fallback title",
      occurred_at: Time.current,
      payload: {
        "card_title" => "Senate at Dusk",
        "card_body" => "This is a much longer card body than the component should fully show in the log entry.",
        "response_text" => "Choose caution",
        "response_log" => "The envoys back down.",
        "session_states_added" => [{ "state_key" => "guard_mobilized" }],
        "session_states_removed" => [{ "state_name" => "Senate Support" }]
      }
    )

    entry = Chronicle::EntryPresenter.new(event_log: event_log)

    render_inline(Chronicle::EntryComponent.new(entry: entry, truncate_length: 24))

    assert_selector "li strong", text: "Senate at Dusk"
    assert_text "This is a much longer..."
    assert_text "Choose caution"
    assert_text "The envoys back down."
    assert_text "State gained: Guard mobilized"
    assert_text "State lost: Senate Support"
  end
end
