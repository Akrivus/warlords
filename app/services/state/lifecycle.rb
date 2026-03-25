module State
  class Lifecycle
    def initialize(current_year:, current_turn:, upcoming_turn:)
      @current_year = current_year
      @current_turn = current_turn
      @upcoming_turn = upcoming_turn
    end

    def active?(state, turn: current_turn)
      return true if state.expires_year.blank?
      return true if current_year < state.expires_year
      return false if current_year > state.expires_year
      return true if state.expires_turn.blank?

      turn <= state.expires_turn
    end

    def stale?(state, turn: current_turn)
      return false if state.expires_year.blank?
      return true if current_year > state.expires_year
      return false if current_year < state.expires_year
      return false if state.expires_turn.blank?

      turn > state.expires_turn
    end

    def expiring_after_upcoming_turn?(state)
      return false if state.expires_year.blank? || current_year < state.expires_year
      return false if state.expires_turn.blank?

      upcoming_turn >= state.expires_turn
    end

    private

    attr_reader :current_year, :current_turn, :upcoming_turn
  end
end
