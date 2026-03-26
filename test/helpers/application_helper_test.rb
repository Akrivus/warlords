require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "state icon image path resolves matching assets" do
    path = state_icon_image_path("veteran_discontent")

    assert_includes path, "state_icons/veteran_discontent.svg"
  end

  test "state icon image path returns nil when the asset is missing" do
    assert_nil state_icon_image_path("missing_state_icon")
  end

  test "state icon placeholder label uses initials from the label" do
    assert_equal "VD", state_icon_placeholder_label("Veteran Discontent", "veteran_discontent")
  end
end
