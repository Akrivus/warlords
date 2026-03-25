module Scenarios
  module Romebots
    class ChronicleEntryPresenter
      attr_reader :event_log

      def initialize(event_log:)
        @event_log = event_log
      end

      def event_type
        event_log.event_type
      end

      def occurred_at
        event_log.occurred_at
      end

      def cycle_number
        event_log.cycle_number
      end

      def primary?
        event_type == "response_resolved"
      end

      def low_value_system_event?
        %w[deck_built card_presented active_states_processed].include?(event_type)
      end

      def card_title
        payload["card_title"].presence || event_log.title
      end

      def card_body
        payload["card_body"].presence || event_log.session_card&.body || event_log.body
      end

      def response_key
        payload["response_key"]
      end

      def response_text
        payload["response_text"]
      end

      def response_log
        payload["response_log"].presence || event_log.body
      end

      def session_states_added
        Array(payload["session_states_added"])
      end

      def session_states_removed
        Array(payload["session_states_removed"])
      end

      def title
        primary? ? card_title : event_log.title
      end

      def summary
        if primary?
          response_log.presence || response_text
        else
          event_log.body
        end
      end

      def visible_state_changes?
        session_states_added.any? || session_states_removed.any?
      end

      def renderable?
        primary? || !low_value_system_event?
      end

      private

      def payload
        @payload ||= (event_log.payload || {}).deep_stringify_keys
      end
    end
  end
end
