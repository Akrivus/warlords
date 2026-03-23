module Cycles
  class Advance
    def self.call(...)
      new(...).call
    end

    def initialize(game_session:)
      @game_session = game_session
    end

    def call
      raise ArgumentError, "Session is not awaiting a year summary" unless game_session.summary?

      ActiveRecord::Base.transaction do
        if (end_state = Sessions::CheckEndState.call(game_session: game_session))
          Sessions::ReachEndState.call(game_session: game_session, end_state: end_state)
        else
          advance_cycle!
        end
      end

      game_session.reload
    end

    private

    attr_reader :game_session

    def advance_cycle!
      previous_summary = game_session.summary_data
      next_context = game_session.context_state.deep_dup
      next_context["time.year"] += 1
      next_context["time.cycle_number"] += 1
      next_context["time.cards_resolved_this_year"] = 0

      game_session.update!(
        status: "active",
        cycle_number: game_session.cycle_number + 1,
        current_card: nil,
        context_state: next_context,
        deck_state: {
          "previous_year_summary" => previous_summary,
          "cycle_start_context" => next_context.deep_dup
        }
      )

      Logs::RecordEvent.call(
        game_session: game_session,
        event_type: "cycle_advanced",
        title: "Year #{game_session.context_value('time.year')} begins",
        body: "The next RomeBots year opens and a fresh deck is drawn."
      )

      Decks::BuildForSession.call(game_session: game_session)
    end
  end
end
