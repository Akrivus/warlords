class ContextSchema
  FAMILY_PREFIXES = {
    time: "time.",
    state: "state.",
    relations: "relations.",
    factions: "factions.",
    flags: "flags."
  }.freeze

  class << self
    # `Configuration.initial_context` remains the seeded payload for new sessions.
    # This schema exposes that key set as an explicit seam for validation/metadata.
    def valid_keys
      @valid_keys ||= Configuration.initial_context.keys.map(&:to_s).freeze
    end

    def valid_key?(key)
      valid_keys.include?(key.to_s)
    end

    def family_for(key)
      normalized_key = key.to_s

      FAMILY_PREFIXES.each do |family, prefix|
        return family if normalized_key.start_with?(prefix)
      end

      nil
    end
  end
end
