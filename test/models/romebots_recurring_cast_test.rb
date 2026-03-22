require "test_helper"

class RomebotsRecurringCastTest < ActiveSupport::TestCase
  setup do
    reset_game_data!
    load Rails.root.join("db/seeds.rb")
  end

  test "small recurring cast reappears across multiple cards with consistent speaker keys" do
    agrippa_cards = CardDefinition.where(scenario_key: "romebots", speaker_key: "agrippa").order(:key)
    antony_cards = CardDefinition.where(scenario_key: "romebots", speaker_key: "antony").order(:key)
    cicero_cards = CardDefinition.where(scenario_key: "romebots", speaker_key: "cicero").order(:key)

    assert_equal %w[a_loyal_friend a_narrow_escape return_to_rome], agrippa_cards.pluck(:key)
    assert_equal ["Mark Antony"], antony_cards.pluck(:speaker_name).uniq
    assert_equal %w[antonys_terms whisper_campaign], antony_cards.pluck(:key)
    assert_equal ["Cicero"], cicero_cards.pluck(:speaker_name).uniq
    assert_equal %w[ciceros_offer grain_anxiety], cicero_cards.pluck(:key)
  end
end
