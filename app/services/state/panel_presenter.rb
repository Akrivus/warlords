module State
  class PanelPresenter
    Entry = Struct.new(
      :key,
      :name,
      :description,
      :icon_key,
      :icon_label,
      :duration_label,
      :behavior_tags,
      keyword_init: true
    )

    def initialize(game_session:)
      @game_session = game_session
    end

    def entries
      @entries ||= active_states.filter_map do |state|
        definition = definition_for(state)
        next if definition.blank?

        Entry.new(
          key: state.state_key,
          name: state_label_for(state, definition),
          description: state_description_for(definition),
          icon_key: state_icon_key_for(definition),
          icon_label: state_icon_label_for(state, definition),
          duration_label: duration_label_for(state),
          behavior_tags: behavior_tags_for(state, definition)
        )
      end
    end

    def empty?
      entries.empty?
    end

    private

    attr_reader :game_session

    def active_states
      game_session.session_states.select { |state| lifecycle.active?(state) }
    end

    def definition_for(state)
      registry_definition = Registry.fetch(state.state_key)
      database_definition = state_definitions_by_key[state.state_key.to_s]

      {
        name: database_definition&.label.presence || registry_definition[:name],
        description: database_definition&.description.presence || registry_definition[:description],
        icon: database_definition&.icon_asset_key.presence || registry_definition[:icon],
        on_turn_start_effects: registry_definition[:on_turn_start_effects],
        weight_modifiers: registry_definition[:weight_modifiers]
      }
    rescue ArgumentError
      nil
    end

    def duration_label_for(state)
      return "Until year end" if state.expires_year.present? && state.expires_turn.blank?
      return "Ongoing" if state.expires_year.blank? && state.expires_turn.blank?
      return "Until year #{state.expires_year.abs} BCE" if state.expires_year.present? && current_year < state.expires_year

      turns_left = state.expires_turn.to_i - current_turn
      return "Expires this turn" if turns_left <= 0
      return "1 turn left" if turns_left == 1

      "#{turns_left} turns left"
    end

    def behavior_tags_for(state, definition)
      tags = []
      tags << "Turn effect" if Array(definition[:on_turn_start_effects]).any?
      tags << "Eligibility" if affects_eligibility?(state.state_key)
      tags << "Weighting" if Array(definition[:weight_modifiers]).any?
      tags << "Year-end" if state.expires_year.present? && state.expires_turn.blank?
      tags
    end

    def affects_eligibility?(state_key)
      eligibility_state_keys.include?(state_key.to_s)
    end

    def eligibility_state_keys
      @eligibility_state_keys ||= CardDefinition
        .for_scenario(game_session.scenario_key)
        .active
        .filter_map { |card| Array(card.spawn_rules["required_session_states"]).presence }
        .flatten
        .map(&:to_s)
        .uniq
    end

    def current_turn
      game_session.context_value("time.cards_resolved_this_year").to_i
    end

    def current_year
      game_session.context_value("time.year").to_i
    end

    def state_label_for(state, definition)
      definition[:name].presence || state.state_key.to_s.humanize
    end

    def state_description_for(definition)
      definition[:description].presence || "This active state is currently affecting the session."
    end

    def state_icon_key_for(definition)
      definition[:icon].to_s.strip.presence
    end

    def state_icon_label_for(state, definition)
      source = definition[:name].presence || state.state_key.to_s.tr("_", " ")
      tokens = source.scan(/[A-Za-z0-9]+/)
      return "?" if tokens.empty?

      initials = if tokens.one?
        tokens.first.first(2)
      else
        tokens.first(2).map { |token| token.first }.join
      end

      initials.upcase
    end

    def state_definitions_by_key
      @state_definitions_by_key ||= StateDefinition
        .for_scenario(game_session.scenario_key)
        .where(key: active_states.map(&:state_key))
        .index_by(&:key)
    end

    def lifecycle
      @lifecycle ||= Lifecycle.new(
        current_year: current_year,
        current_turn: current_turn,
        upcoming_turn: current_turn + 1
      )
    end
  end
end
