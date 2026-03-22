require "test_helper"

class DecksBuildForSessionTest < ActiveSupport::TestCase
  setup do
    reset_game_data!
    load Rails.root.join("db/seeds.rb")
  end

  test "builds a 12 card deck and snapshots the first card" do
    session = GameSession.create!(
      scenario_key: "romebots",
      status: "active",
      cycle_number: 1,
      context_state: Scenarios::Romebots::Configuration.initial_context,
      deck_state: {},
      started_at: Time.current
    )

    Decks::BuildForSession.call(game_session: session)
    session.reload

    assert_equal 12, session.session_cards.count
    assert_equal 12, session.deck_state["total_cards"]
    assert_equal 0, session.deck_state["resolved_cards"]
    assert_equal "Caesar's Will", session.current_card.title
    assert_equal "Julius Caesar", session.current_card.speaker_name
    assert_equal "julian_house", session.current_card.faction_key
    assert_equal "caesar", session.current_card.portrait_key
    assert_equal "card_presented", session.event_logs.first.event_type
  end

  test "session cards preserve speaker metadata even if the definition later changes" do
    session = GameSession.create!(
      scenario_key: "romebots",
      status: "active",
      cycle_number: 1,
      context_state: Scenarios::Romebots::Configuration.initial_context,
      deck_state: {},
      started_at: Time.current
    )

    Decks::BuildForSession.call(game_session: session)
    session_card = session.current_card
    session_card.card_definition.update!(speaker_name: "A Different Caesar")

    session_card.reload

    assert_equal "Julius Caesar", session_card.speaker_name
    assert_equal "caesar", session_card.portrait_key
    assert_equal "julian_house", session_card.faction_key
  end
end
