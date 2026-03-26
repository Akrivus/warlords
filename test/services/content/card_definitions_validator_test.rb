require "test_helper"

module Content
  class CardDefinitionsValidatorTest < ActiveSupport::TestCase
    test "seeded cards validate without hard errors" do
      reset_game_data!
      load Rails.root.join("db/seeds.rb")

      report = CardDefinitionsValidator.call(cards: CardDefinition.order(:scenario_key, :key).to_a)

      assert report.success?, report.to_text
      assert report.warnings.any?, "expected portrait warnings for unresolved seed portrait assets"
    end

    test "reports duplicate keys, missing fields, bad ops, broken references, malformed choices, and contradictory conditions" do
      duplicate_a = build_card(
        key: "duplicate_card",
        portrait_key: "missing_portrait",
        body: ""
      )
      duplicate_b = build_card(
        key: "duplicate_card",
        title: "Duplicate Sibling"
      )
      invalid = build_card(
        key: "broken_card",
        spawn_rules: {
          min_year: -40,
          max_year: -44,
          repeatable: true,
          one_time_only: true,
          required_flags: ["flags.married"],
          excluded_flags: ["flags.married"],
          required_context: [
            { key: "flags.married", equals: false },
            { key: "flags.unknown_flag", equals: true }
          ],
          required_session_states: ["unknown_state"]
        },
        response_a_effects: [
          { op: "teleport", key: "state.legitimacy", value: 3 },
          { op: "set", key: "flags.nope", value: true }
        ],
        response_b_effects: "not-an-array",
        response_a_states: [
          { action: "toggle", key: "grain_crisis" },
          { action: "add", key: "unknown_state", duration: { turns: 0, until_year_end: true } }
        ],
        response_b_states: { action: "remove", key: "grain_crisis" },
        response_a_follow_up_card_key: "missing_follow_up"
      )

      report = CardDefinitionsValidator.call(cards: [duplicate_a, duplicate_b, invalid])
      error_text = report.errors.map(&:to_text).join("\n")

      assert_not report.success?
      assert_includes error_text, "duplicate card key within scenario"
      assert_includes error_text, "[body] is required"
      assert_includes error_text, "uses unsupported op \"teleport\""
      assert_includes error_text, "references unknown context key \"flags.nope\""
      assert_includes error_text, "[response_b_effects] must be an array"
      assert_includes error_text, "uses unsupported action \"toggle\""
      assert_includes error_text, "references unknown session state \"unknown_state\""
      assert_includes error_text, "references missing card \"missing_follow_up\""
      assert_includes error_text, "min_year cannot be greater than max_year"
      assert_includes error_text, "cannot require and exclude the same flag"
      assert_includes error_text, "requires \"flags.married\" false but required_flags requires it true"
    end

    test "treats missing portrait assets as warnings" do
      report = CardDefinitionsValidator.call(cards: [build_card(key: "portrait_warning", portrait_key: "missing_portrait")])

      assert report.success?, report.to_text
      assert_equal 1, report.warnings.count
      assert_includes report.warnings.first.to_text, "does not resolve to an uploaded portrait or asset file"
    end

    private

    def build_card(overrides = {})
      CardDefinition.new(
        {
          scenario_key: "romebots",
          key: "card_#{SecureRandom.hex(4)}",
          title: "Test Card",
          body: "Body text",
          card_type: "authored",
          active: true,
          weight: 10,
          tags: ["test"],
          spawn_rules: {},
          response_a_text: "Choice A",
          response_a_effects: [{ op: "increment", key: "state.legitimacy", value: 1 }],
          response_a_states: [],
          response_a_follow_up_card_key: nil,
          response_b_text: "Choice B",
          response_b_effects: [{ op: "increment", key: "state.public_order", value: 1 }],
          response_b_states: [],
          response_b_follow_up_card_key: nil,
          speaker_name: "Speaker",
          speaker_type: "figure",
          speaker_key: "speaker",
          portrait_key: "caesar",
          faction_key: "julian_house"
        }.merge(overrides)
      )
    end
  end
end
