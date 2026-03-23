require "test_helper"

class SessionsHelperTest < ActionView::TestCase
  setup do
    ActiveStorage::Current.url_options = { host: "example.com", protocol: "http" }
  end

  test "speaker portrait image path prefers uploaded portraits over portrait_key assets" do
    card_definition = CardDefinition.create!(
      scenario_key: "romebots",
      key: "uploaded_portrait_card",
      title: "Uploaded Portrait Card",
      body: "Body",
      card_type: "authored",
      active: true,
      weight: 1,
      response_a_text: "A",
      response_b_text: "B",
      speaker_type: "figure",
      speaker_key: "caesar",
      speaker_name: "Julius Caesar",
      portrait_key: "caesar",
      faction_key: "julian_house"
    )
    card_definition.portrait_upload.attach(
      io: file_fixture("uploaded_portrait.svg").open,
      filename: "uploaded_portrait.svg",
      content_type: "image/svg+xml"
    )
    session_card = SessionCard.new(card_definition:, portrait_key: "caesar")

    path = speaker_portrait_image_path(session_card)

    assert_includes path, "/rails/active_storage/blobs/"
  end

  test "speaker portrait image path resolves matching portrait assets" do
    session_card = SessionCard.new(portrait_key: "caesar")

    path = speaker_portrait_image_path(session_card)

    assert_includes path, "portraits/caesar.svg"
  end

  test "speaker portrait image path returns nil when no portrait asset exists" do
    session_card = SessionCard.new(portrait_key: "missing_portrait")

    assert_nil speaker_portrait_image_path(session_card)
  end

  test "speaker placeholder initials prefer speaker name" do
    session_card = SessionCard.new(speaker_name: "Priests Of The Games", portrait_key: "festival_priests")

    assert_equal "PO", speaker_placeholder_initials(session_card)
  end
end
