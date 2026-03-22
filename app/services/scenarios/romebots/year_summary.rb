module Scenarios
  module Romebots
    class YearSummary
      def self.call(...)
        new(...).call
      end

      def initialize(game_session:)
        @game_session = game_session
      end

      def call
        {
          "year" => game_session.context_value("time.year"),
          "title" => "Year #{game_session.context_value('time.year')} in review",
          "headline" => headline,
          "highlights" => highlights,
          "state_snapshot" => state_snapshot
        }
      end

      private

      attr_reader :game_session

      def cycle_start_context
        game_session.deck_state["cycle_start_context"] || {}
      end

      def highlights
        visible_deltas
          .sort_by { |delta| -delta["delta"].abs }
          .first(4)
      end

      def visible_deltas
        Scenarios::Romebots::Configuration::VISIBLE_STATE_KEYS.filter_map do |key|
          from = cycle_start_context[key]
          to = game_session.context_state[key]
          next if from.nil? || to.nil?

          delta = to - from
          next if delta.zero?

          {
            "key" => key,
            "label" => key.split(".").last.humanize,
            "from" => from,
            "to" => to,
            "delta" => delta
          }
        end
      end

      def state_snapshot
        Scenarios::Romebots::Configuration::VISIBLE_STATE_KEYS.map do |key|
          {
            "label" => key.split(".").last.humanize,
            "value" => game_session.context_state[key]
          }
        end
      end

      def headline
        strongest_gain = highlights.select { |delta| delta["delta"].positive? }.max_by { |delta| delta["delta"] }
        strongest_loss = highlights.select { |delta| delta["delta"].negative? }.min_by { |delta| delta["delta"] }

        parts = []
        parts << "Octavian closes the year with #{strongest_gain['label'].downcase} rising by #{strongest_gain['delta']}." if strongest_gain
        parts << "#{strongest_loss['label']} slipped by #{strongest_loss['delta'].abs}, leaving the regime more brittle." if strongest_loss
        parts << fallback_headline if parts.empty?
        parts.join(" ")
      end

      def fallback_headline
        "The year ends without dramatic swings, but the state remains delicately balanced."
      end
    end
  end
end
