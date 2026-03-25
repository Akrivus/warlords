module Scenarios
  module Romebots
    class ActiveStatesPanelPresenter
      Entry = Struct.new(
        :key,
        :name,
        :description,
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
            name: definition[:name],
            description: definition[:description],
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
        ActiveStateRegistry.fetch(state.state_key)
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

      def lifecycle
        @lifecycle ||= SessionStateLifecycle.new(
          current_year: current_year,
          current_turn: current_turn,
          upcoming_turn: current_turn + 1
        )
      end
    end
  end
end
