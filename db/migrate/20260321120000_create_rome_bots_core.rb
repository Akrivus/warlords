class CreateRomeBotsCore < ActiveRecord::Migration[8.1]
  def change
    create_table :game_sessions do |t|
      t.string :scenario_key, null: false
      t.string :status, null: false, default: "active"
      t.integer :cycle_number, null: false, default: 1
      t.integer :current_card_id
      t.json :context_state, null: false, default: {}
      t.json :deck_state, null: false, default: {}
      t.string :seed
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end

    create_table :card_definitions do |t|
      t.string :scenario_key, null: false
      t.string :key, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.string :card_type, null: false, default: "authored"
      t.boolean :active, null: false, default: true
      t.integer :weight, null: false, default: 0
      t.json :tags, null: false, default: []
      t.json :spawn_rules, null: false, default: {}
      t.string :response_a_text, null: false
      t.json :response_a_effects, null: false, default: []
      t.string :response_b_text, null: false
      t.json :response_b_effects, null: false, default: []
      t.json :metadata, null: false, default: {}

      t.timestamps
    end

    create_table :session_cards do |t|
      t.references :game_session, null: false, foreign_key: true
      t.references :card_definition, foreign_key: true
      t.string :source_type, null: false, default: "card_definition"
      t.integer :cycle_number, null: false
      t.integer :slot_index, null: false
      t.string :status, null: false, default: "pending"
      t.string :title, null: false
      t.text :body, null: false
      t.string :response_a_text, null: false
      t.json :response_a_effects, null: false, default: []
      t.string :response_b_text, null: false
      t.json :response_b_effects, null: false, default: []
      t.string :chosen_response
      t.text :resolution_summary
      t.json :generation_params, null: false, default: {}
      t.string :fingerprint
      t.json :metadata, null: false, default: {}

      t.timestamps
    end

    create_table :event_logs do |t|
      t.references :game_session, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :title, null: false
      t.text :body
      t.json :payload, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.integer :cycle_number
      t.string :card_key
      t.references :session_card, foreign_key: true

      t.timestamps
    end

    add_index :game_sessions, :scenario_key
    add_index :game_sessions, :status
    add_index :card_definitions, [:scenario_key, :key], unique: true
    add_index :card_definitions, [:scenario_key, :active]
    add_index :session_cards, [:game_session_id, :cycle_number, :slot_index], unique: true
    add_index :session_cards, [:game_session_id, :status]
    add_index :event_logs, [:game_session_id, :occurred_at]

    add_foreign_key :game_sessions, :session_cards, column: :current_card_id
  end
end
