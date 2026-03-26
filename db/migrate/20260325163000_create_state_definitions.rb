class CreateStateDefinitions < ActiveRecord::Migration[8.1]
  class StateDefinition < ApplicationRecord
    self.table_name = "state_definitions"
  end

  REGISTRY_SNAPSHOT = {
    "guard_mobilized" => {
      label: "Guard Mobilized",
      description: "Octavian keeps trusted men under arms and within reach.",
      visibility: "public",
      default_duration: { turns: 3 },
      metadata: {
        category: "military",
        on_turn_start_effects: [
          { op: "increment", key: "state.public_order", value: 1 }
        ],
        weight_modifiers: [],
        chronicle_tags: ["security", "muscle"]
      }
    },
    "whisper_campaign" => {
      label: "Whisper Campaign",
      description: "Rumors and insinuations spread through elite and street networks.",
      visibility: "public",
      default_duration: { until_year_end: true },
      metadata: {
        category: "political",
        on_turn_start_effects: [
          { op: "decrement", key: "state.legitimacy", value: 1 }
        ],
        weight_modifiers: [
          { tags: ["intrigue"], delta: 25 }
        ],
        chronicle_tags: ["rumors", "intrigue"]
      }
    },
    "grain_crisis" => {
      label: "Grain Crisis",
      description: "Short supplies turn every queue and marketplace into a threat.",
      visibility: "public",
      default_duration: { until_year_end: true },
      metadata: {
        category: "civic",
        on_turn_start_effects: [
          { op: "decrement", key: "state.public_order", value: 2 }
        ],
        weight_modifiers: [],
        chronicle_tags: ["scarcity", "urban_pressure"]
      }
    },
    "eastern_intrigue" => {
      label: "Eastern Intrigue",
      description: "Diplomacy, trade, and court pressure from the eastern Mediterranean stay live.",
      visibility: "public",
      default_duration: { turns: 2 },
      metadata: {
        category: "diplomatic",
        on_turn_start_effects: [
          { op: "increment", key: "factions.octavian_circle", value: 1 }
        ],
        weight_modifiers: [
          { tags: ["intrigue"], delta: 30 }
        ],
        chronicle_tags: ["east", "court", "diplomacy"]
      }
    },
    "mourning_period" => {
      label: "Mourning Period",
      description: "Public life slows under ritual grief and political symbolism.",
      visibility: "public",
      default_duration: { until_year_end: true },
      metadata: {
        category: "ceremonial",
        on_turn_start_effects: [],
        weight_modifiers: [],
        chronicle_tags: ["ritual", "memory"]
      }
    },
    "veteran_discontent" => {
      label: "Veteran Discontent",
      description: "Caesar's old soldiers grow impatient with promises instead of payment.",
      visibility: "public",
      default_duration: { turns: 2 },
      metadata: {
        category: "military",
        on_turn_start_effects: [
          { op: "decrement", key: "state.military_support", value: 1 }
        ],
        weight_modifiers: [],
        chronicle_tags: ["veterans", "pay"]
      }
    }
  }.freeze

  def up
    create_table :state_definitions do |t|
      t.string :scenario_key, null: false
      t.string :key, null: false
      t.string :state_type, null: false
      t.string :label, null: false
      t.text :description
      t.string :icon
      t.string :visibility, null: false
      t.string :stacking_rule, null: false
      t.json :default_duration, null: false, default: {}
      t.json :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :state_definitions, [:scenario_key, :key], unique: true
    add_index :state_definitions, [:scenario_key, :state_type]

    StateDefinition.reset_column_information
    StateDefinition.insert_all!(registry_rows)
  end

  def down
    drop_table :state_definitions
  end

  private

  def registry_rows
    timestamp = Time.current

    REGISTRY_SNAPSHOT.map do |key, definition|
      {
        scenario_key: "romebots",
        key: key,
        state_type: "modifier",
        label: definition[:label],
        description: definition[:description],
        icon: nil,
        visibility: definition[:visibility],
        stacking_rule: "unique_refresh",
        default_duration: definition[:default_duration],
        metadata: definition[:metadata].merge(registry_source: "state_registry"),
        created_at: timestamp,
        updated_at: timestamp
      }
    end
  end
end
