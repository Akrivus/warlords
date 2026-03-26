require "test_helper"

class AdminStateDefinitionsTest < ActionDispatch::IntegrationTest
  setup do
    User.reset_column_information
    @admin_user = create_user(email: "state-admin@example.com")
    User.where(id: @admin_user.id).update_all(admin: true)
    @admin_user.reload
  end

  test "admin index renders" do
    sign_in @admin_user

    get "/admin/state_definitions"

    assert_response :success
    assert_includes response.body, "State Definitions"
  end

  test "admin can create update and destroy a state definition" do
    sign_in @admin_user

    post "/admin/state_definitions",
         params: {
           state_definition: {
             scenario_key: "romebots",
             key: "omens_favorable",
             label: "Omens Favorable",
             state_type: "flag",
             description: "A favorable sign has spread through the city.",
             icon: "laurel",
             visibility: "public",
             stacking_rule: "unique_ignore",
             default_duration_json: "{\"turns\":2}",
             metadata_json: "{\"category\":\"omens\",\"chronicle_tags\":[\"augury\"],\"weight_modifiers\":[]}"
           }
         }

    created_state = StateDefinition.find_by!(scenario_key: "romebots", key: "omens_favorable")
    assert_redirected_to "/admin/state_definitions/#{created_state.id}"
    assert_equal({ "turns" => 2 }, created_state.default_duration)
    assert_equal "omens", created_state.metadata["category"]
    assert_equal "laurel", created_state.icon

    patch "/admin/state_definitions/#{created_state.id}",
          params: {
            state_definition: {
              label: "Omens Most Favorable",
              default_duration_json: "{\"until_year_end\":true}",
              metadata_json: "{\"category\":\"omens\",\"chronicle_tags\":[\"augury\",\"approval\"],\"weight_modifiers\":[{\"tags\":[\"ceremony\"],\"delta\":10}]}"
            }
          }

    assert_redirected_to "/admin/state_definitions/#{created_state.id}"
    created_state.reload
    assert_equal "Omens Most Favorable", created_state.label
    assert_equal({ "until_year_end" => true }, created_state.default_duration)
    assert_equal ["augury", "approval"], created_state.metadata["chronicle_tags"]

    assert_difference("StateDefinition.count", -1) do
      delete "/admin/state_definitions/#{created_state.id}"
    end

    assert_redirected_to "/admin/state_definitions"
  end

  test "admin show renders icon preview when a matching state icon asset exists" do
    sign_in @admin_user

    state_definition = StateDefinition.create!(
      scenario_key: "romebots",
      key: "veteran_discontent",
      label: "Veteran Discontent",
      description: "Veterans are growing restless.",
      icon: "veteran_discontent",
      state_type: "modifier",
      visibility: "public",
      stacking_rule: "unique_refresh",
      default_duration: {},
      metadata: {}
    )

    get "/admin/state_definitions/#{state_definition.id}"

    assert_response :success
    assert_match %r{state_icons/veteran_discontent(?:-[a-f0-9]+)?\.svg}, response.body
  end
end
