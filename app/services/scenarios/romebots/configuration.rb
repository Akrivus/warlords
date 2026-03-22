module Scenarios
  module Romebots
    module Configuration
      module_function

      DECK_SIZE = 12
      SCENARIO_KEY = "romebots".freeze

      VISIBLE_STATE_KEYS = %w[
        state.legitimacy
        state.treasury
        state.public_order
        state.military_support
        state.senate_support
        state.health
        state.heir_pressure
      ].freeze

      VISIBLE_RELATION_KEYS = %w[
        relations.agrippa
        relations.cicero
        relations.antony
        relations.plebs
      ].freeze

      VISIBLE_FACTION_KEYS = %w[
        factions.octavian_circle
        factions.senate_bloc
        factions.antonian_faction
        factions.julian_house
      ].freeze

      def initial_context
        {
          "time.year" => 44,
          "time.cycle_number" => 1,
          "time.cards_resolved_this_year" => 0,
          "state.legitimacy" => 55,
          "state.treasury" => 45,
          "state.public_order" => 50,
          "state.military_support" => 40,
          "state.senate_support" => 35,
          "state.health" => 85,
          "state.heir_pressure" => 10,
          "relations.antony" => -2,
          "relations.cicero" => 1,
          "relations.agrippa" => 2,
          "relations.legions" => 1,
          "relations.plebs" => 0,
          "factions.julian_house" => 2,
          "factions.octavian_circle" => 2,
          "factions.senate_bloc" => 1,
          "factions.antonian_faction" => -2,
          "factions.roman_priesthood" => 0,
          "factions.senatorial_families" => 0,
          "factions.legions" => 1,
          "flags.caesar_assassinated" => true,
          "flags.caesar_adopted_heir" => true,
          "flags.returned_to_rome" => false,
          "flags.met_cicero" => false,
          "flags.antony_compromised" => false,
          "flags.antony_open_enemy" => false,
          "flags.married" => false,
          "flags.has_heir" => false,
          "flags.proscriptions_used" => false,
          "flags.second_triumvirate_formed" => false,
          "flags.sextus_active" => true
        }
      end
    end
  end
end
