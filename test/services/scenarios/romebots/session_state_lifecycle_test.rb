require "test_helper"

module Scenarios
  module Romebots
    class SessionStateLifecycleTest < ActiveSupport::TestCase
      State = Struct.new(:expires_turn, :expires_year, keyword_init: true)

      test "active? matches current-turn panel semantics" do
        lifecycle = SessionStateLifecycle.new(current_year: -44, current_turn: 2, upcoming_turn: 3)

        assert lifecycle.active?(State.new(expires_turn: nil, expires_year: nil))
        assert lifecycle.active?(State.new(expires_turn: nil, expires_year: -44))
        assert lifecycle.active?(State.new(expires_turn: 2, expires_year: -44))
        assert_not lifecycle.active?(State.new(expires_turn: 1, expires_year: -44))
      end

      test "active? can be evaluated against the upcoming turn" do
        lifecycle = SessionStateLifecycle.new(current_year: -44, current_turn: 0, upcoming_turn: 1)

        assert lifecycle.active?(State.new(expires_turn: 1, expires_year: -44), turn: 1)
        assert_not lifecycle.active?(State.new(expires_turn: 0, expires_year: -44), turn: 1)
      end

      test "stale? matches upcoming-turn gameplay semantics" do
        lifecycle = SessionStateLifecycle.new(current_year: -44, current_turn: 0, upcoming_turn: 1)

        assert lifecycle.stale?(State.new(expires_turn: 0, expires_year: -44), turn: 1)
        assert_not lifecycle.stale?(State.new(expires_turn: 1, expires_year: -44), turn: 1)
        assert lifecycle.stale?(State.new(expires_turn: nil, expires_year: -45), turn: 1)
        assert_not lifecycle.stale?(State.new(expires_turn: nil, expires_year: nil), turn: 1)
      end

      test "expiring_after_upcoming_turn? preserves turn-expiry boundary" do
        lifecycle = SessionStateLifecycle.new(current_year: -44, current_turn: 0, upcoming_turn: 1)

        assert lifecycle.expiring_after_upcoming_turn?(State.new(expires_turn: 1, expires_year: -44))
        assert_not lifecycle.expiring_after_upcoming_turn?(State.new(expires_turn: 2, expires_year: -44))
        assert_not lifecycle.expiring_after_upcoming_turn?(State.new(expires_turn: nil, expires_year: -44))
        assert_not lifecycle.expiring_after_upcoming_turn?(State.new(expires_turn: 1, expires_year: -43))
      end
    end
  end
end
