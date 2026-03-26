require "test_helper"

class StateDefinitionTest < ActiveSupport::TestCase
  test "registry helper maps current runtime definitions into db attributes" do
    definition = State::Registry.fetch("guard_mobilized")

    attributes = StateDefinition.attributes_from_registry(
      scenario_key: "romebots",
      definition: definition
    )

    assert_equal "romebots", attributes[:scenario_key]
    assert_equal "guard_mobilized", attributes[:key]
    assert_equal "modifier", attributes[:state_type]
    assert_equal "Guard Mobilized", attributes[:label]
    assert_equal "guard_mobilized", attributes[:icon]
    assert_equal({ turns: 3 }, attributes[:default_duration])
    assert_equal "military", attributes[:metadata][:category]
    assert_equal "state_registry", attributes[:metadata][:registry_source]
  end

  test "validates allowed definition fields" do
    state_definition = StateDefinition.new(
      scenario_key: "romebots",
      key: "omens_favorable",
      state_type: "flag",
      label: "Omens Favorable",
      visibility: "public",
      stacking_rule: "unique_ignore",
      default_duration: {},
      metadata: {}
    )

    assert state_definition.valid?
  end

  test "parses json textarea fields for admin authoring" do
    state_definition = StateDefinition.new(
      scenario_key: "romebots",
      key: "omens_favorable",
      state_type: "flag",
      label: "Omens Favorable",
      visibility: "public",
      stacking_rule: "unique_ignore"
    )

    state_definition.default_duration_json = "{\"turns\":2}"
    state_definition.metadata_json = "{\"category\":\"omens\",\"chronicle_tags\":[\"augury\"]}"

    assert state_definition.valid?
    assert_equal({ "turns" => 2 }, state_definition.default_duration)
    assert_equal({ "category" => "omens", "chronicle_tags" => ["augury"] }, state_definition.metadata)
  end
end
