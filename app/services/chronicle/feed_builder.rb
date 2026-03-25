module Chronicle
  class FeedBuilder
    DEFAULT_EVENT_TYPES = %w[
      session_started
      response_resolved
      year_started
      year_ended
      session_ended
    ].freeze

    STATE_EVENT_TYPES = %w[
      session_state_added
      session_state_removed
      session_state_expired
    ].freeze

    def initialize(game_session:, include_system_events: false, include_state_events: false)
      @game_session = game_session
      @include_system_events = include_system_events
      @include_state_events = include_state_events
    end

    def entries
      ordered_logs.filter_map do |event_log|
        entry = EntryPresenter.new(event_log: event_log)
        next unless include_entry?(entry)

        entry
      end.reverse
    end

    private

    attr_reader :game_session, :include_system_events, :include_state_events

    def ordered_logs
      Array(game_session.event_logs).sort_by { |event| [event.occurred_at, event.id] }
    end

    def include_entry?(entry)
      return true if DEFAULT_EVENT_TYPES.include?(entry.event_type)
      return true if include_state_events && STATE_EVENT_TYPES.include?(entry.event_type)
      return true if include_system_events && entry.renderable?

      false
    end
  end
end
