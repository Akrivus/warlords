require "test_helper"

class CardDefinitionSeedTest < ActiveSupport::TestCase
  setup do
    CardDefinition.delete_all
    load Rails.root.join("db/seeds.rb")
  end

  test "seeded romebots cards carry speaker metadata" do
    card = CardDefinition.find_by!(scenario_key: "romebots", key: "caesars_will")

    assert_equal "figure", card.speaker_type
    assert_equal "caesar", card.speaker_key
    assert_equal "Julius Caesar", card.speaker_name
    assert_equal "caesar", card.portrait_key
    assert_equal "julian_house", card.faction_key
  end

  test "selected seeded cards include relationship and faction effects" do
    ciceros_offer = CardDefinition.find_by!(scenario_key: "romebots", key: "ciceros_offer")
    agrippa_card = CardDefinition.find_by!(scenario_key: "romebots", key: "a_loyal_friend")

    assert_includes ciceros_offer.response_a_effects, { "op" => "increment", "key" => "relations.cicero", "value" => 2 }
    assert_includes ciceros_offer.response_a_effects, { "op" => "increment", "key" => "factions.senate_bloc", "value" => 2 }
    assert_includes agrippa_card.response_a_effects, { "op" => "increment", "key" => "relations.agrippa", "value" => 1 }
    assert_includes agrippa_card.response_a_effects, { "op" => "increment", "key" => "factions.octavian_circle", "value" => 2 }
  end
end
