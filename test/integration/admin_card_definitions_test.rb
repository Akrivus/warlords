require "test_helper"

class AdminCardDefinitionsTest < ActionDispatch::IntegrationTest
  setup do
    ActiveStorage::Current.url_options = { host: "example.com", protocol: "http" }
    User.reset_column_information
    @admin_user = create_user(email: "admin@example.com")
    User.where(id: @admin_user.id).update_all(admin: true)
    @admin_user.reload
    @player_user = create_user(email: "player@example.com")
  end

  test "admin index renders" do
    sign_in @admin_user

    get "/admin/card_definitions"

    assert_response :success
    assert_includes response.body, "Card Definitions"
  end

  test "non-admin users are redirected away from admin" do
    sign_in @player_user

    get "/admin/card_definitions"

    assert_redirected_to root_path
  end

  test "admin can create update and destroy a card definition" do
    sign_in @admin_user

    post "/admin/card_definitions",
         params: {
           card_definition: {
             scenario_key: "romebots",
             key: "admin_card",
             title: "Admin Card",
             body: "Created from ActiveAdmin.",
             card_type: "authored",
             active: "1",
             weight: "42",
             tags_json: "[\"politics\",\"admin\"]",
             spawn_rules_json: "{\"min_year\":-44}",
             response_a_text: "Take the bold option.",
             response_a_effects_json: "[{\"op\":\"increment\",\"key\":\"state.legitimacy\",\"value\":1}]",
             response_b_text: "Take the careful option.",
             response_b_effects_json: "[{\"op\":\"increment\",\"key\":\"state.senate_support\",\"value\":1}]",
             speaker_type: "figure",
             speaker_key: "agrippa",
             speaker_name: "Agrippa",
             portrait_key: "agrippa",
             faction_key: "octavian_circle",
             portrait_upload: fixture_file_upload("uploaded_portrait.svg", "image/svg+xml")
           }
         }

    created_card = CardDefinition.find_by!(scenario_key: "romebots", key: "admin_card")
    assert_redirected_to "/admin/card_definitions/#{created_card.id}"
    assert_equal ["politics", "admin"], created_card.tags
    assert created_card.portrait_upload.attached?

    patch "/admin/card_definitions/#{created_card.id}",
          params: {
            card_definition: {
              title: "Admin Card Revised",
              response_a_follow_up_card_key: "antonys_terms",
              response_b_follow_up_card_key: "whisper_campaign",
              spawn_rules_json: "{\"min_year\":-44,\"max_year\":-43}",
              portrait_upload: fixture_file_upload("uploaded_portrait_alt.svg", "image/svg+xml")
            }
          }

    assert_redirected_to "/admin/card_definitions/#{created_card.id}"
    created_card.reload
    assert_equal "Admin Card Revised", created_card.title
    assert_equal "antonys_terms", created_card.response_a_follow_up_card_key
    assert_equal "whisper_campaign", created_card.response_b_follow_up_card_key
    assert_equal({ "min_year" => -44, "max_year" => -43 }, created_card.spawn_rules)
    assert_equal "uploaded_portrait_alt.svg", created_card.portrait_upload.filename.to_s

    patch "/admin/card_definitions/#{created_card.id}",
          params: {
            card_definition: {
              remove_portrait_upload: "1"
            }
          }

    assert_redirected_to "/admin/card_definitions/#{created_card.id}"
    created_card.reload
    assert_not created_card.portrait_upload.attached?

    assert_difference("CardDefinition.count", -1) do
      delete "/admin/card_definitions/#{created_card.id}"
    end

    assert_redirected_to "/admin/card_definitions"
  end

  test "admin can create a linked follow-up card from an existing card" do
    sign_in @admin_user

    source_card = CardDefinition.find_by!(scenario_key: "romebots", key: "ciceros_offer")

    get "/admin/card_definitions/new_follow_up", params: { source_card_id: source_card.id, follow_up_slot: "a" }
    assert_redirected_to(/\/admin\/card_definitions\/new/)

    post "/admin/card_definitions",
         params: {
           source_card_id: source_card.id,
           follow_up_slot: "a",
           card_definition: {
             scenario_key: source_card.scenario_key,
             key: "cicero_aftermath",
             title: "Cicero Aftermath",
             body: "The alliance has immediate consequences.",
             card_type: source_card.card_type,
             active: "1",
             weight: "50",
             tags_json: "[\"follow_up\"]",
             spawn_rules_json: "{}",
             response_a_text: "Lean in.",
             response_a_effects_json: "[]",
             response_b_text: "Back away.",
             response_b_effects_json: "[]"
           }
         }

    source_card.reload
    created_card = CardDefinition.find_by!(scenario_key: "romebots", key: "cicero_aftermath")

    assert_equal "cicero_aftermath", source_card.response_a_follow_up_card_key
    assert_redirected_to "/admin/card_definitions/#{source_card.id}/edit"

    get "/admin/card_definitions/#{source_card.id}"
    assert_includes response.body, created_card.title
  end
end
