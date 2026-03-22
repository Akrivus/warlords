class EventLog < ApplicationRecord
  belongs_to :game_session
  belongs_to :session_card, optional: true

  validates :event_type, :title, :occurred_at, presence: true
end
