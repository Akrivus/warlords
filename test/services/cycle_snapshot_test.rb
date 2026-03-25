require "test_helper"

class CycleSnapshotTest < ActiveSupport::TestCase
  setup do
    reset_game_data!
    UserIdentity.delete_all
    User.delete_all
    @user = create_user(email: "cycle-snapshot@example.com")
  end

  test "returns the stored cycle_start_context snapshot" do
    session = GameSession.create!(
      user: @user,
      scenario_key: "romebots",
      status: "active",
      cycle_number: 1,
      context_state: Configuration.initial_context,
      deck_state: { "cycle_start_context" => { "state.legitimacy" => 55 } }
    )

    snapshot = CycleSnapshot.new(game_session: session)

    assert_equal({ "state.legitimacy" => 55 }, snapshot.context_state)
  end

  test "returns an empty hash when the snapshot is absent" do
    session = GameSession.create!(
      user: @user,
      scenario_key: "romebots",
      status: "active",
      cycle_number: 1,
      context_state: Configuration.initial_context,
      deck_state: {}
    )

    snapshot = CycleSnapshot.new(game_session: session)

    assert_equal({}, snapshot.context_state)
  end

  test "cycle snapshot still drives year summary deltas" do
    session = GameSession.create!(
      user: @user,
      scenario_key: "romebots",
      status: "year_summary",
      cycle_number: 1,
      context_state: Configuration.initial_context.merge(
        "state.legitimacy" => 60
      ),
      deck_state: {
        "cycle_start_context" => Configuration.initial_context.merge(
          "state.legitimacy" => 55
        )
      }
    )

    summary = Chronicle::YearSummary.call(game_session: session)
    legitimacy_delta = summary.fetch("highlights").find { |entry| entry["key"] == "state.legitimacy" }

    assert_equal 55, legitimacy_delta["from"]
    assert_equal 60, legitimacy_delta["to"]
    assert_equal 5, legitimacy_delta["delta"]
  end
end
