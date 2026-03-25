module Scenarios
  module Romebots
    class CycleSnapshot
      def initialize(game_session:)
        @game_session = game_session
      end

      def context_state
        game_session.deck_state["cycle_start_context"] || {}
      end

      private

      attr_reader :game_session
    end
  end
end
