require "test_helper"
require "view_component/test_case"

class State::IndicatorBadgeComponentTest < ViewComponent::TestCase
  test "renders a state indicator badge with the requested tone" do
    render_inline(State::IndicatorBadgeComponent.new(label: "Critical", tone: "critical"))

    assert_selector ".state-indicator.state-indicator--critical", text: "Critical"
  end
end
