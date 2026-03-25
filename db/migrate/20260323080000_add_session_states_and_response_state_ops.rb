class AddSessionStatesAndResponseStateOps < ActiveRecord::Migration[8.1]
  def change
    create_table :session_states do |t|
      t.references :game_session, null: false, foreign_key: true
      t.string :state_key, null: false
      t.string :source_card_key
      t.string :source_response_key
      t.integer :applied_turn, null: false
      t.integer :applied_year, null: false
      t.integer :expires_turn
      t.integer :expires_year
      t.json :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :session_states, [:game_session_id, :state_key], unique: true
    add_index :session_states, [:game_session_id, :expires_year]

    add_column :card_definitions, :response_a_states, :json, null: false, default: []
    add_column :card_definitions, :response_b_states, :json, null: false, default: []
    add_column :session_cards, :response_a_states, :json, null: false, default: []
    add_column :session_cards, :response_b_states, :json, null: false, default: []
  end
end
