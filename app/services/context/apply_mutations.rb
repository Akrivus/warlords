module Context
  class ApplyMutations
    STATE_RANGE = 0..100
    RELATION_RANGE = -5..5
    FACTION_RANGE = -5..5
    VALID_OPERATIONS = %w[set increment decrement clear].freeze

    def self.call(...)
      new(...).call
    end

    def initialize(context_state:, mutations:)
      @context_state = context_state.deep_dup
      @mutations = Array(mutations)
    end

    def call
      mutations.each { |mutation| apply_mutation(mutation.stringify_keys) }
      context_state
    end

    private

    attr_reader :context_state, :mutations

    def apply_mutation(mutation)
      operation = mutation.fetch("op")
      key = mutation.fetch("key")
      value = mutation["value"]

      raise ArgumentError, "Unsupported mutation op: #{operation}" unless VALID_OPERATIONS.include?(operation)
      raise ArgumentError, "Unknown context key: #{key}" unless valid_context_key?(key)

      case operation
      when "set"
        context_state[key] = normalize(key, value)
      when "increment"
        context_state[key] = normalize(key, context_state.fetch(key) + value.to_i)
      when "decrement"
        context_state[key] = normalize(key, context_state.fetch(key) - value.to_i)
      when "clear"
        context_state[key] = normalize(key, nil)
      end
    end

    def valid_context_key?(key)
      Scenarios::Romebots::ContextSchema.valid_key?(key) || context_state.key?(key)
    end

    def normalize(key, value)
      # For flags, "clear" is author-facing shorthand for setting false.
      # It does not delete the key from context_state.
      return false if key.start_with?("flags.") && value.nil?
      return !!value if key.start_with?("flags.")
      return value.to_i.clamp(STATE_RANGE.min, STATE_RANGE.max) if key.start_with?("state.")
      return value.to_i.clamp(RELATION_RANGE.min, RELATION_RANGE.max) if key.start_with?("relations.")
      return value.to_i.clamp(FACTION_RANGE.min, FACTION_RANGE.max) if key.start_with?("factions.")
      return value.to_i if key.start_with?("time.")

      value
    end
  end
end
