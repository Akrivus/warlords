class AddFollowUpCardKeys < ActiveRecord::Migration[8.1]
  def change
    change_table :card_definitions do |t|
      t.string :response_a_follow_up_card_key
      t.string :response_b_follow_up_card_key
    end

    change_table :session_cards do |t|
      t.string :response_a_follow_up_card_key
      t.string :response_b_follow_up_card_key
    end
  end
end
