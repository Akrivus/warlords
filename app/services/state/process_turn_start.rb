module State
  class ProcessTurnStart
      def self.call(...)
        new(...).call
      end

      def initialize(game_session:)
        @game_session = game_session
      end

      def call
        apply_recurring_effects!
        expire_finished_states!
        game_session.reload
      end

      private

      attr_reader :game_session

      def apply_recurring_effects!
        mutations = active_states_for_upcoming_turn.flat_map do |state|
          Array(Registry.fetch(state.state_key)[:on_turn_start_effects])
        end
        return if mutations.empty?

        updated_context = Context::ApplyMutations.call(
          context_state: game_session.context_state,
          mutations: mutations
        )
        game_session.update!(context_state: updated_context)

        Logs::RecordEvent.call(
          game_session: game_session,
          event_type: "active_states_processed",
          title: "Recurring pressures shape the turn",
          body: "Active session states apply their ongoing effects before the next card appears.",
          payload: {
            "state_keys" => active_states_for_upcoming_turn.map(&:state_key),
            "effects" => mutations
          }
        )
      end

      def expire_finished_states!
        expiring_states.each do |state|
          definition = Registry.fetch(state.state_key)
          state.destroy!

          Logs::RecordEvent.call(
            game_session: game_session,
            event_type: "session_state_expired",
            title: "#{definition[:name]} expires",
            body: "#{definition[:name]} has run its course.",
            payload: {
              "state_key" => state.state_key,
              "state_name" => definition[:name],
              "source_card_key" => state.source_card_key,
              "source_response_key" => state.source_response_key,
              "expires_turn" => state.expires_turn,
              "expires_year" => state.expires_year,
              "reason" => "turn_duration_reached"
            }
          )
        end
      end

      def active_states_for_upcoming_turn
        @active_states_for_upcoming_turn ||= game_session.session_states.ordered.select do |state|
          lifecycle.active?(state, turn: upcoming_turn)
        end
      end

      def expiring_states
        @expiring_states ||= game_session.session_states.ordered.select do |state|
          lifecycle.stale?(state, turn: upcoming_turn) || lifecycle.expiring_after_upcoming_turn?(state)
        end
      end

      def current_year
        game_session.context_value("time.year").to_i
      end

      def current_turn
        game_session.context_value("time.cards_resolved_this_year").to_i
      end

      def upcoming_turn
        current_turn + 1
      end

      def lifecycle
        @lifecycle ||= Lifecycle.new(
          current_year: current_year,
          current_turn: current_turn,
          upcoming_turn: upcoming_turn
        )
      end
  end
end
