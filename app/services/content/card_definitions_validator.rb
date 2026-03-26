module Content
  class CardDefinitionsValidator
    PORTRAIT_ASSET_EXTENSIONS = %w[avif webp png jpg jpeg svg].freeze
    ALLOWED_SPAWN_RULE_KEYS = %w[
      min_year
      max_year
      one_time_only
      repeatable
      required_flags
      excluded_flags
      required_context
      required_session_states
    ].freeze
    REQUIRED_FIELDS = %i[scenario_key key title body response_a_text response_b_text].freeze

    Issue = Struct.new(:severity, :scenario_key, :card_key, :field, :message, keyword_init: true) do
      def error?
        severity == :error
      end

      def warning?
        severity == :warning
      end

      def to_text
        location = [scenario_key.presence || "missing-scenario", card_key.presence || "missing-key"].join("/")
        field_text = field.present? ? " [#{field}]" : ""
        "#{severity.upcase}: #{location}#{field_text} #{message}"
      end
    end

    class Report
      attr_reader :issues

      def initialize
        @issues = []
      end

      def add(severity:, scenario_key:, card_key:, field:, message:)
        issues << Issue.new(
          severity: severity,
          scenario_key: scenario_key,
          card_key: card_key,
          field: field,
          message: message
        )
      end

      def add_error(scenario_key:, card_key:, field:, message:)
        add(severity: :error, scenario_key:, card_key:, field:, message:)
      end

      def add_warning(scenario_key:, card_key:, field:, message:)
        add(severity: :warning, scenario_key:, card_key:, field:, message:)
      end

      def errors
        issues.select(&:error?)
      end

      def warnings
        issues.select(&:warning?)
      end

      def success?
        errors.empty?
      end

      def summary_line
        "#{errors.count} error(s), #{warnings.count} warning(s)"
      end

      def to_text
        ([summary_line] + issues.map(&:to_text)).join("\n")
      end
    end

    def self.call(...)
      new(...).call
    end

    def initialize(cards: CardDefinition.all.to_a, include_asset_warnings: true)
      @cards = Array(cards)
      @include_asset_warnings = include_asset_warnings
      @report = Report.new
      @cards_by_scenario = @cards.group_by { |card| card.scenario_key.to_s }
    end

    def call
      validate_duplicate_keys
      cards.each { |card| validate_card(card) }
      report
    end

    private

    attr_reader :cards, :include_asset_warnings, :report, :cards_by_scenario

    def validate_duplicate_keys
      cards
        .group_by { |card| [card.scenario_key.to_s, card.key.to_s] }
        .each_value do |group|
          next unless group.size > 1

          group.each do |card|
            add_error(card, :key, "duplicate card key within scenario")
          end
        end
    end

    def validate_card(card)
      validate_required_fields(card)
      validate_card_type(card)
      validate_tags(card)
      validate_spawn_rules(card)
      validate_choice(card, "a")
      validate_choice(card, "b")
      validate_follow_up(card, "a")
      validate_follow_up(card, "b")
      validate_portrait_reference(card)
    end

    def validate_required_fields(card)
      REQUIRED_FIELDS.each do |field|
        add_error(card, field, "is required") if card.public_send(field).blank?
      end
    end

    def validate_card_type(card)
      return if CardDefinition::CARD_TYPES.include?(card.card_type)

      add_error(card, :card_type, "must be one of #{CardDefinition::CARD_TYPES.join(', ')}")
    end

    def validate_tags(card)
      return if card.tags.is_a?(Array)

      add_error(card, :tags, "must be a JSON array")
    end

    def validate_spawn_rules(card)
      rules = card.spawn_rules
      unless rules.is_a?(Hash)
        add_error(card, :spawn_rules, "must be a JSON object")
        return
      end

      normalized = rules.stringify_keys

      unknown_keys = normalized.keys - ALLOWED_SPAWN_RULE_KEYS
      unknown_keys.each do |key|
        add_warning(card, :spawn_rules, "includes unsupported key #{key.inspect}")
      end

      min_year = integerish(normalized["min_year"])
      max_year = integerish(normalized["max_year"])
      if min_year && max_year && min_year > max_year
        add_error(card, :spawn_rules, "min_year cannot be greater than max_year")
      end

      if normalized["one_time_only"] && normalized["repeatable"]
        add_error(card, :spawn_rules, "cannot be both one_time_only and repeatable")
      end

      required_flags = validate_flag_list(card, normalized["required_flags"], :required_flags)
      excluded_flags = validate_flag_list(card, normalized["excluded_flags"], :excluded_flags)

      overlap = required_flags & excluded_flags
      overlap.each do |flag|
        add_error(card, :spawn_rules, "cannot require and exclude the same flag #{flag.inspect}")
      end

      validate_required_context(card, normalized["required_context"], required_flags, excluded_flags)
      validate_required_session_states(card, normalized["required_session_states"])
    end

    def validate_flag_list(card, raw_value, field)
      return [] if raw_value.nil?
      unless raw_value.is_a?(Array)
        add_error(card, field, "must be an array")
        return []
      end

      raw_value.filter_map do |flag|
        unless flag.is_a?(String)
          add_error(card, field, "must only include string keys")
          next
        end

        unless ContextSchema.valid_key?(flag)
          add_error(card, field, "references unknown context key #{flag.inspect}")
          next
        end

        unless ContextSchema.family_for(flag) == :flags
          add_error(card, field, "must reference only flags.* keys, got #{flag.inspect}")
          next
        end

        flag
      end
    end

    def validate_required_context(card, raw_value, required_flags, excluded_flags)
      return if raw_value.nil?
      unless raw_value.is_a?(Array)
        add_error(card, :required_context, "must be an array")
        return
      end

      raw_value.each_with_index do |condition, index|
        unless condition.is_a?(Hash)
          add_error(card, :required_context, "entry #{index} must be an object")
          next
        end

        normalized = condition.stringify_keys
        key = normalized["key"]
        if key.blank?
          add_error(card, :required_context, "entry #{index} must include key")
          next
        end

        unless ContextSchema.valid_key?(key)
          add_error(card, :required_context, "entry #{index} references unknown context key #{key.inspect}")
          next
        end

        if normalized.key?("equals") && normalized.key?("value") && normalized["equals"] != normalized["value"]
          add_error(card, :required_context, "entry #{index} cannot provide conflicting equals and value")
        end

        expected_value = if normalized.key?("equals")
          normalized["equals"]
        elsif normalized.key?("value")
          normalized["value"]
        else
          true
        end

        next unless ContextSchema.family_for(key) == :flags

        if expected_value == true && excluded_flags.include?(key)
          add_error(card, :required_context, "entry #{index} requires #{key.inspect} true but excluded_flags forbids it")
        end

        if expected_value == false && required_flags.include?(key)
          add_error(card, :required_context, "entry #{index} requires #{key.inspect} false but required_flags requires it true")
        end
      end
    end

    def validate_required_session_states(card, raw_value)
      return if raw_value.nil?
      unless raw_value.is_a?(Array)
        add_error(card, :required_session_states, "must be an array")
        return
      end

      raw_value.each do |state_key|
        unless state_key.is_a?(String)
          add_error(card, :required_session_states, "must only include string keys")
          next
        end

        State::Registry.fetch(state_key)
      rescue ArgumentError
        add_error(card, :required_session_states, "references unknown session state #{state_key.inspect}")
      end
    end

    def validate_choice(card, response_key)
      text_field = :"response_#{response_key}_text"
      effects_field = :"response_#{response_key}_effects"
      states_field = :"response_#{response_key}_states"

      add_error(card, text_field, "is required") if card.public_send(text_field).blank?
      validate_effects_array(card, effects_field, card.public_send(effects_field))
      validate_states_array(card, states_field, card.public_send(states_field))
    end

    def validate_effects_array(card, field, raw_value)
      unless raw_value.is_a?(Array)
        add_error(card, field, "must be an array")
        return
      end

      raw_value.each_with_index do |effect, index|
        unless effect.is_a?(Hash)
          add_error(card, field, "entry #{index} must be an object")
          next
        end

        normalized = effect.stringify_keys
        op = normalized["op"]
        key = normalized["key"]

        unless Context::ApplyMutations::VALID_OPERATIONS.include?(op)
          add_error(card, field, "entry #{index} uses unsupported op #{op.inspect}")
        end

        if key.blank?
          add_error(card, field, "entry #{index} must include key")
          next
        end

        unless ContextSchema.valid_key?(key)
          add_error(card, field, "entry #{index} references unknown context key #{key.inspect}")
        end
      end
    end

    def validate_states_array(card, field, raw_value)
      unless raw_value.is_a?(Array)
        add_error(card, field, "must be an array")
        return
      end

      raw_value.each_with_index do |operation, index|
        unless operation.is_a?(Hash)
          add_error(card, field, "entry #{index} must be an object")
          next
        end

        normalized = operation.stringify_keys
        action = normalized["action"]
        state_key = normalized["key"]

        unless State::ApplyResponseOperations::VALID_ACTIONS.include?(action)
          add_error(card, field, "entry #{index} uses unsupported action #{action.inspect}")
        end

        if state_key.blank?
          add_error(card, field, "entry #{index} must include key")
          next
        end

        begin
          State::Registry.fetch(state_key)
        rescue ArgumentError
          add_error(card, field, "entry #{index} references unknown session state #{state_key.inspect}")
        end

        validate_state_duration(card, field, index, normalized["duration"]) if action == "add"
      end
    end

    def validate_state_duration(card, field, index, raw_value)
      return if raw_value.nil?
      unless raw_value.is_a?(Hash)
        add_error(card, field, "entry #{index} duration must be an object")
        return
      end

      normalized = raw_value.stringify_keys
      turns = normalized["turns"]
      until_year_end = normalized["until_year_end"]

      if turns.present? && until_year_end
        add_error(card, field, "entry #{index} duration cannot specify both turns and until_year_end")
      end

      if turns.present? && turns.to_i <= 0
        add_error(card, field, "entry #{index} duration turns must be greater than 0")
      end
    end

    def validate_follow_up(card, response_key)
      field = :"response_#{response_key}_follow_up_card_key"
      follow_up_key = card.public_send(field)
      return if follow_up_key.blank?

      unless follow_up_key.is_a?(String)
        add_error(card, field, "must be a string card key")
        return
      end

      if follow_up_key == card.key
        add_error(card, field, "cannot reference the same card as its own follow-up")
      end

      scenario_cards = cards_by_scenario.fetch(card.scenario_key.to_s, [])
      matching_card = scenario_cards.find { |candidate| candidate.key == follow_up_key }
      return if matching_card

      add_error(card, field, "references missing card #{follow_up_key.inspect} in scenario #{card.scenario_key.inspect}")
    end

    def validate_portrait_reference(card)
      return unless include_asset_warnings
      return if card.portrait_key.blank?
      return if card.respond_to?(:portrait_upload) && card.portrait_upload.attached?
      return if portrait_asset_exists?(card.portrait_key)

      add_warning(card, :portrait_key, "does not resolve to an uploaded portrait or asset file")
    end

    def portrait_asset_exists?(portrait_key)
      normalized_key = portrait_key.to_s.strip
      return false if normalized_key.blank?

      PORTRAIT_ASSET_EXTENSIONS.any? do |extension|
        Rails.root.join("app/assets/images/portraits/#{normalized_key}.#{extension}").exist?
      end
    end

    def integerish(value)
      return if value.nil?
      Integer(value, exception: false)
    end

    def add_error(card, field, message)
      report.add_error(
        scenario_key: card.scenario_key,
        card_key: card.key,
        field: field,
        message: message
      )
    end

    def add_warning(card, field, message)
      report.add_warning(
        scenario_key: card.scenario_key,
        card_key: card.key,
        field: field,
        message: message
      )
    end
  end
end
