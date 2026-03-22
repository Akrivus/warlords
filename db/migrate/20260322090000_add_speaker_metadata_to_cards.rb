class AddSpeakerMetadataToCards < ActiveRecord::Migration[8.1]
  def change
    change_table :card_definitions do |t|
      t.string :speaker_type
      t.string :speaker_key
      t.string :speaker_name
      t.string :portrait_key
      t.string :faction_key
    end

    change_table :session_cards do |t|
      t.string :speaker_type
      t.string :speaker_key
      t.string :speaker_name
      t.string :portrait_key
      t.string :faction_key
    end
  end
end
