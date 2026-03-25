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
      mutation_result = Context::ResolveResponseMutations.call(
        game_session: game_session,
        session_card: active_card,
        response_key: response_key
      )
      @context_before_resolution = mutation_result.fetch(:context_before)
      @context_after_resolution = mutation_result.fetch(:context_after)
      @state_operation_summary = mutation_result.fetch(:state_operation_summary)
    end

    def resolve_active_card!
      active_card.update!(
        status: "resolved",
        chosen_response: response_key,
        resolution_summary: response_text
      )

      Logs::RecordEvent.call(
        game_session: game_session,
        event_type: "response_resolved",
        title: active_card.title,
        body: response_log_text,
        payload: chronicle_payload,
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
        State::ProcessTurnStart.call(game_session: game_session)

        if (end_state = Sessions::CheckEndState.call(game_session: game_session))
          Sessions::ReachEndState.call(game_session: game_session, end_state: end_state, session_card: active_card)
          return
        end

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
        State::ExpireForYearEnd.call(game_session: game_session)
        summary = Chronicle::YearSummary.call(game_session: game_session)
        game_session.update!(
          current_card: nil,
          status: "year_summary",
          deck_state: refreshed_deck_state.merge("year_summary" => summary)
        )
        Logs::RecordEvent.call(
          game_session: game_session,
          event_type: "year_ended",
          title: "Year #{game_session.year_label} complete",
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

    def response_log_text
      active_card.resolution_summary.presence || response_text
    end

    def chronicle_payload
      {
        "card_key" => active_card.card_definition&.key || active_card.metadata["card_key"],
        "card_title" => active_card.title,
        "card_body" => active_card.body,
        "response_key" => response_key,
        "response_text" => response_text,
        "response_log" => response_log_text,
        "immediate_effects" => Array(response_effects).map { |effect| effect.stringify_keys },
        "context_changes" => context_changes,
        "session_states_added" => Array(@state_operation_summary&.dig("session_states_added")),
        "session_states_removed" => Array(@state_operation_summary&.dig("session_states_removed"))
      }
    end

    def context_changes
      before_context = @context_before_resolution || {}
      after_context = @context_after_resolution || game_session.context_state

      (before_context.keys | after_context.keys).filter_map do |key|
        before_value = before_context[key]
        after_value = after_context[key]
        next if before_value == after_value

        change = {
          "key" => key,
          "before" => before_value,
          "after" => after_value
        }

        if before_value.is_a?(Numeric) && after_value.is_a?(Numeric)
          change["delta"] = after_value - before_value
        end

        change
      end
    end
  end
end
