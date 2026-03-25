module Scenarios
  module Romebots
    module ActiveStateRegistry
      module_function

      DEFINITIONS = {
        "guard_mobilized" => {
          key: "guard_mobilized",
          name: "Guard Mobilized",
          description: "Octavian keeps trusted men under arms and within reach.",
          category: "military",
          default_duration: { turns: 3 },
          on_turn_start_effects: [
            { op: "increment", key: "state.public_order", value: 1 }
          ],
          weight_modifiers: [],
          chronicle_tags: ["security", "muscle"],
          visibility: "public"
        },
        "whisper_campaign" => {
          key: "whisper_campaign",
          name: "Whisper Campaign",
          description: "Rumors and insinuations spread through elite and street networks.",
          category: "political",
          default_duration: { until_year_end: true },
          on_turn_start_effects: [
            { op: "decrement", key: "state.legitimacy", value: 1 }
          ],
          weight_modifiers: [
            { tags: ["intrigue"], delta: 25 }
          ],
          chronicle_tags: ["rumors", "intrigue"],
          visibility: "public"
        },
        "grain_crisis" => {
          key: "grain_crisis",
          name: "Grain Crisis",
          description: "Short supplies turn every queue and marketplace into a threat.",
          category: "civic",
          default_duration: { until_year_end: true },
          on_turn_start_effects: [
            { op: "decrement", key: "state.public_order", value: 2 }
          ],
          weight_modifiers: [],
          chronicle_tags: ["scarcity", "urban_pressure"],
          visibility: "public"
        },
        "eastern_intrigue" => {
          key: "eastern_intrigue",
          name: "Eastern Intrigue",
          description: "Diplomacy, trade, and court pressure from the eastern Mediterranean stay live.",
          category: "diplomatic",
          default_duration: { turns: 2 },
          on_turn_start_effects: [
            { op: "increment", key: "factions.octavian_circle", value: 1 }
          ],
          weight_modifiers: [
            { tags: ["intrigue"], delta: 30 }
          ],
          chronicle_tags: ["east", "court", "diplomacy"],
          visibility: "public"
        },
        "mourning_period" => {
          key: "mourning_period",
          name: "Mourning Period",
          description: "Public life slows under ritual grief and political symbolism.",
          category: "ceremonial",
          default_duration: { until_year_end: true },
          on_turn_start_effects: [],
          weight_modifiers: [],
          chronicle_tags: ["ritual", "memory"],
          visibility: "public"
        },
        "veteran_discontent" => {
          key: "veteran_discontent",
          name: "Veteran Discontent",
          description: "Caesar's old soldiers grow impatient with promises instead of payment.",
          category: "military",
          default_duration: { turns: 2 },
          on_turn_start_effects: [
            { op: "decrement", key: "state.military_support", value: 1 }
          ],
          weight_modifiers: [],
          chronicle_tags: ["veterans", "pay"],
          visibility: "public"
        }
      }.freeze

      def definitions
        DEFINITIONS
      end

      def fetch(state_key)
        definitions.fetch(state_key.to_s) do
          raise ArgumentError, "Unknown active session state: #{state_key}"
        end
      end

      def snapshot_for(active_state)
        definition = fetch(active_state.state_key)

        {
          "key" => active_state.state_key,
          "name" => definition[:name],
          "description" => definition[:description],
          "category" => definition[:category],
          "visibility" => definition[:visibility],
          "chronicle_tags" => Array(definition[:chronicle_tags]),
          "applied_turn" => active_state.applied_turn,
          "applied_year" => active_state.applied_year,
          "expires_turn" => active_state.expires_turn,
          "expires_year" => active_state.expires_year,
          "metadata" => active_state.metadata || {}
        }
      end
    end
  end
end
