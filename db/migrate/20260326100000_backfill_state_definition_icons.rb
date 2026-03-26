class BackfillStateDefinitionIcons < ActiveRecord::Migration[8.1]
  class StateDefinition < ApplicationRecord
    self.table_name = "state_definitions"
  end

  ICON_KEYS = {
    "guard_mobilized" => "guard_mobilized",
    "whisper_campaign" => "whisper_campaign",
    "grain_crisis" => "grain_crisis",
    "eastern_intrigue" => "eastern_intrigue",
    "mourning_period" => "mourning_period",
    "veteran_discontent" => "veteran_discontent"
  }.freeze

  def up
    ICON_KEYS.each do |key, icon|
      StateDefinition.where(scenario_key: "romebots", key: key).update_all(icon: icon)
    end
  end

  def down
    StateDefinition.where(scenario_key: "romebots", key: ICON_KEYS.keys, icon: ICON_KEYS.values).update_all(icon: nil)
  end
end
