module Logs
  class RecordEvent
    def self.call(...)
      new(...).call
    end

    def initialize(game_session:, event_type:, title:, body: nil, payload: {}, session_card: nil)
      @game_session = game_session
      @event_type = event_type
      @title = title
      @body = body
      @payload = payload
      @session_card = session_card
    end

    def call
      game_session.event_logs.create!(
        event_type: event_type,
        title: title,
        body: body,
        payload: payload,
        occurred_at: Time.current,
        cycle_number: game_session.cycle_number,
        card_key: session_card&.card_definition&.key,
        session_card: session_card
      )
    end

    private

    attr_reader :game_session, :event_type, :title, :body, :payload, :session_card
  end
end
