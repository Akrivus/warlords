require "test_helper"

class CardDefinitionTest < ActiveSupport::TestCase
  test "parses JSON textarea fields into engine attributes" do
    card = CardDefinition.new(
      scenario_key: "romebots",
      key: "admin_created_card",
      title: "Admin Created Card",
      body: "Created from the internal authoring interface.",
      card_type: "authored",
      weight: 10,
      response_a_text: "Response A",
      response_b_text: "Response B",
      tags_json: "[\"admin\", \"test\"]",
      spawn_rules_json: "{\"min_year\":-44,\"repeatable\":true}",
      response_a_effects_json: "[{\"op\":\"increment\",\"key\":\"state.legitimacy\",\"value\":2}]",
      response_b_effects_json: "[{\"op\":\"set\",\"key\":\"flags.tested\",\"value\":true}]"
    )

    assert card.valid?
    assert_equal ["admin", "test"], card.tags
    assert_equal({ "min_year" => -44, "repeatable" => true }, card.spawn_rules)
    assert_equal [{ "op" => "increment", "key" => "state.legitimacy", "value" => 2 }], card.response_a_effects
    assert_equal [{ "op" => "set", "key" => "flags.tested", "value" => true }], card.response_b_effects
  end

  test "adds validation errors when JSON textarea fields are invalid" do
    card = CardDefinition.new(
      scenario_key: "romebots",
      key: "broken_json_card",
      title: "Broken Json Card",
      body: "This should fail validation.",
      card_type: "authored",
      weight: 5,
      response_a_text: "Response A",
      response_b_text: "Response B",
      tags_json: "[not valid json]"
    )

    assert_not card.valid?
    assert_includes card.errors[:tags_json].first, "must be valid JSON"
  end
end
