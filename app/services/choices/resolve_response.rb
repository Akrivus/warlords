module Choices
  class ResolveResponse
    RESPONSES = %w[a b].freeze

    def self.call(...)
      new(...).call
    end

    def initialize(game_session:, response_key:)
      @game_session = game_session
      @response_key = response_key.to_s
    end

    def call
      raise ArgumentError, "Invalid response" unless RESPONSES.include?(response_key)
      raise ArgumentError, "No active card" unless active_card
      raise ArgumentError, "Session is not in active play" unless game_session.status == "active"
      raise ArgumentError, "Card already resolved" unless active_card.status == "pending"

      ActiveRecord::Base.transaction do
        update_session_state!
        resolve_active_card!
        follow_up_card = FollowUps::EnqueueForResponse.call(session_card: active_card, response_key: response_key)
        advance_to_next_card(preferred_next_card: follow_up_card)
      end

      game_session.reload
    end

    private

    attr_reader :game_session, :response_key

    def active_card
      @active_card ||= game_session.current_card
    end

    def response_text
      active_card.public_send("response_#{response_key}_text")
    end

    def response_effects
      active_card.public_send("response_#{response_key}_effects")
    end

    def update_session_state!
      updated_context = Context::ApplyMutations.call(
        context_state: game_session.context_state,
        mutations: response_effects
      )
      updated_context["time.cards_resolved_this_year"] += 1

      game_session.update!(context_state: updated_context)
    end

    def resolve_active_card!
      active_card.update!(
        status: "resolved",
        chosen_response: response_key,
        resolution_summary: response_text
      )

      Logs::RecordEvent.call(
        game_session: game_session,
        event_type: "response_chosen",
        title: "#{active_card.title}: option #{response_key.upcase}",
        body: response_text,
        payload: { "effects" => response_effects },
        session_card: active_card
      )
    end

    def advance_to_next_card(preferred_next_card: nil)
      if (end_state = Sessions::CheckEndState.call(game_session: game_session))
        Sessions::ReachEndState.call(game_session: game_session, end_state: end_state, session_card: active_card)
        return
      end

      next_card = preferred_next_card || game_session.session_cards.pending.where(cycle_number: game_session.cycle_number).order(:slot_index).first

      if next_card
        game_session.update!(
          current_card: next_card,
          deck_state: refreshed_deck_state
        )
        Logs::RecordEvent.call(
          game_session: game_session,
          event_type: "card_presented",
          title: next_card.title,
          body: next_card.body,
          session_card: next_card
        )
      else
        summary = Scenarios::Romebots::YearSummary.call(game_session: game_session)
        game_session.update!(
          current_card: nil,
          status: "year_summary",
          deck_state: refreshed_deck_state.merge("year_summary" => summary)
        )
        Logs::RecordEvent.call(
          game_session: game_session,
          event_type: "cycle_completed",
          title: "Year #{game_session.context_value('time.year')} complete",
          body: summary["headline"],
          payload: summary
        )
      end
    end

    def refreshed_deck_state
      cycle_cards = game_session.session_cards.where(cycle_number: game_session.cycle_number)
      {
        "cycle_number" => game_session.cycle_number,
        "total_cards" => cycle_cards.count,
        "resolved_cards" => cycle_cards.resolved.count,
        "pending_cards" => cycle_cards.pending.count
      }
    end
  end
end
