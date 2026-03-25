module Context
  class ResolveResponseMutations
    def self.call(...)
      new(...).call
    end

    def initialize(game_session:, session_card:, response_key:)
      @game_session = game_session
      @session_card = session_card
      @response_key = response_key.to_s
    end

    def call
      context_before = game_session.context_state.deep_dup
      updated_context = ApplyMutations.call(
        context_state: context_before,
        mutations: response_effects
      )

      # Sequencing here is gameplay-sensitive and intentionally preserved:
      # 1. apply immediate context mutations
      # 2. increment resolved-card count
      # 3. persist context
      # 4. apply active-state add/remove operations against that persisted context
      updated_context["time.cards_resolved_this_year"] += 1
      game_session.update!(context_state: updated_context)

      state_operation_summary = Scenarios::Romebots::ActiveStates::ApplyResponseOperations.call(
        game_session: game_session,
        session_card: session_card,
        response_key: response_key
      )

      {
        context_before: context_before,
        context_after: game_session.reload.context_state.deep_dup,
        state_operation_summary: state_operation_summary
      }
    end

    private

    attr_reader :game_session, :session_card, :response_key

    def response_effects
      session_card.public_send("response_#{response_key}_effects")
    end
  end
end
