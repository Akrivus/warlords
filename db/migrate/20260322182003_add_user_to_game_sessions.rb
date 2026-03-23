class AddUserToGameSessions < ActiveRecord::Migration[8.1]
  class MigrationGameSession < ApplicationRecord
    self.table_name = "game_sessions"
  end

  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  def up
    add_reference :game_sessions, :user, foreign_key: true

    return unless MigrationUser.count == 1

    MigrationGameSession.where(user_id: nil).update_all(user_id: MigrationUser.first.id)
  end

  def down
    remove_reference :game_sessions, :user, foreign_key: true
  end
end
