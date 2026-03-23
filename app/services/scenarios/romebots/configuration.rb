module Scenarios
  module Romebots
    module Configuration
      module_function

      DECK_SIZE = 12
      SCENARIO_KEY = "romebots".freeze

      DISPLAY_GROUPS = {
        core: {
          title: "Core State",
          prefix: "state."
        },
        factions: {
          title: "Faction Pressures",
          prefix: "factions."
        },
        relationships: {
          title: "Character Relationships",
          prefix: "relations."
        }
      }.freeze

      DISPLAY_CONFIG = {
        "state.legitimacy" => { group: :core, priority: 100, always_visible: true, severe_below: 35, icon: "LG" },
        "state.health" => { group: :core, priority: 95, always_visible: true, severe_below: 35, icon: "HL" },
        "state.military_support" => { group: :core, priority: 90, always_visible: true, severe_below: 30, icon: "MS" },
        "state.treasury" => { group: :core, priority: 85, always_visible: true, severe_below: 25, icon: "TR" },
        "state.public_order" => { group: :core, priority: 80, always_visible: true, severe_below: 35, icon: "PO" },
        "state.senate_support" => { group: :core, priority: 70, always_visible: true, severe_below: 25, icon: "SN" },
        "state.heir_pressure" => { group: :core, priority: 50, always_visible: true, severe_above: 70, icon: "HP" },
        "relations.agrippa" => { group: :relationships, priority: 90, always_visible: true, icon: "AG" },
        "relations.cicero" => { group: :relationships, priority: 80, always_visible: true, icon: "CI" },
        "relations.antony" => { group: :relationships, priority: 100, always_visible: true, icon: "AN" },
        "relations.plebs" => { group: :relationships, priority: 70, always_visible: true, icon: "PL" },
        "factions.octavian_circle" => { group: :factions, priority: 100, always_visible: true, icon: "OC" },
        "factions.senate_bloc" => { group: :factions, priority: 90, always_visible: true, icon: "SB" },
        "factions.antonian_faction" => { group: :factions, priority: 95, always_visible: true, icon: "AF" },
        "factions.julian_house" => { group: :factions, priority: 85, always_visible: true, icon: "JH" }
      }.freeze

      VISIBLE_STATE_KEYS = DISPLAY_CONFIG.filter_map do |key, entry|
        key if entry[:group] == :core && entry[:always_visible]
      end.freeze

      VISIBLE_RELATION_KEYS = DISPLAY_CONFIG.filter_map do |key, entry|
        key if entry[:group] == :relationships && entry[:always_visible]
      end.freeze

      VISIBLE_FACTION_KEYS = DISPLAY_CONFIG.filter_map do |key, entry|
        key if entry[:group] == :factions && entry[:always_visible]
      end.freeze

      def initial_context
        {
          "time.year" => -44,
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
