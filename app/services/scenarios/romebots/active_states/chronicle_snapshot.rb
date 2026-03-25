module Scenarios
  module Romebots
    module ActiveStates
      class ChronicleSnapshot
        def self.call(...)
          new(...).call
        end

        def initialize(game_session:)
          @game_session = game_session
        end

        def call
          {
            "state_snapshot" => game_session.state_snapshot,
            "expired_this_year" => expired_this_year
          }
        end

        private

        attr_reader :game_session

        def expired_this_year
          game_session.event_logs
            .where(event_type: "session_state_expired", cycle_number: game_session.cycle_number)
            .order(:occurred_at, :id)
            .map do |event|
              {
                "state_key" => event.payload["state_key"],
                "reason" => event.payload["reason"]
              }
            end
        end
      end
    end
  end
end
