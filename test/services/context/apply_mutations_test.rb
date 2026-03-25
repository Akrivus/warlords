require "test_helper"

module Context
  class ApplyMutationsTest < ActiveSupport::TestCase
    test "accepts keys defined by the RomeBots context schema" do
      context_state = Scenarios::Romebots::Configuration.initial_context.except("flags.married")

      updated = ApplyMutations.call(
        context_state: context_state,
        mutations: [{ op: "set", key: "flags.married", value: true }]
      )

      assert_equal true, updated["flags.married"]
    end

    test "still accepts ad hoc keys already present in the session context" do
      context_state = Scenarios::Romebots::Configuration.initial_context.merge("actors.armenian_envoys_known" => false)

      updated = ApplyMutations.call(
        context_state: context_state,
        mutations: [{ op: "set", key: "actors.armenian_envoys_known", value: true }]
      )

      assert_equal true, updated["actors.armenian_envoys_known"]
    end

    test "rejects keys that are neither schema-defined nor present in the context hash" do
      error = assert_raises(ArgumentError) do
        ApplyMutations.call(
          context_state: Scenarios::Romebots::Configuration.initial_context,
          mutations: [{ op: "set", key: "actors.unknown", value: true }]
        )
      end

      assert_includes error.message, "Unknown context key: actors.unknown"
    end

    test "clear on flags sets false instead of deleting the key" do
      updated = ApplyMutations.call(
        context_state: Scenarios::Romebots::Configuration.initial_context.merge("flags.met_cicero" => true),
        mutations: [{ op: "clear", key: "flags.met_cicero" }]
      )

      assert updated.key?("flags.met_cicero")
      assert_equal false, updated["flags.met_cicero"]
    end
  end
end
