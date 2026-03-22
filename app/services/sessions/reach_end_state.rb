module Sessions
  class ReachEndState
    def self.call(...)
      new(...).call
    end

    def initialize(game_session:, end_state:, session_card: nil)
      @game_session = game_session
      @end_state = end_state
      @session_card = session_card
    end

    def call
      game_session.update!(
        current_card: nil,
        status: end_state.fetch("status", "failed"),
        ended_at: Time.current,
        deck_state: game_session.deck_state.merge(
          "end_state" => end_state,
          "resolved_cards" => cycle_cards.resolved.count,
          "pending_cards" => cycle_cards.pending.count
        )
      )

      Logs::RecordEvent.call(
        game_session: game_session,
        event_type: "session_ended",
        title: end_state.fetch("title"),
        body: end_state.fetch("body"),
        payload: end_state,
        session_card: session_card
      )

      game_session
    end

    private

    attr_reader :game_session, :end_state, :session_card

    def cycle_cards
      game_session.session_cards.where(cycle_number: game_session.cycle_number)
    end
  end
end
