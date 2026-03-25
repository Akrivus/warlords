module Scenarios
  module Romebots
    module ActiveStates
      class ExpireForYearEnd
        def self.call(...)
          new(...).call
        end

        def initialize(game_session:)
          @game_session = game_session
        end

        def call
          year_end_states.each do |state|
            definition = ActiveStateRegistry.fetch(state.state_key)
            state.destroy!

            Logs::RecordEvent.call(
              game_session: game_session,
              event_type: "session_state_expired",
              title: "#{definition[:name]} fades with the year",
              body: "#{definition[:name]} does not carry into the next year.",
              payload: {
                "state_key" => state.state_key,
                "state_name" => definition[:name],
                "source_card_key" => state.source_card_key,
                "source_response_key" => state.source_response_key,
                "expires_turn" => state.expires_turn,
                "expires_year" => state.expires_year,
                "reason" => "year_end"
              }
            )
          end
        end

        private

        attr_reader :game_session

        def year_end_states
          current_year = game_session.context_value("time.year").to_i

          game_session.session_states.ordered.select do |state|
            state.expires_year.present? && state.expires_year <= current_year && state.expires_turn.blank?
          end
        end
      end
    end
  end
end
