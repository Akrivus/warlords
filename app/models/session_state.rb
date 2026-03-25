class SessionState < ApplicationRecord
  belongs_to :game_session

  validates :state_key, presence: true, uniqueness: { scope: :game_session_id }
  validates :applied_turn, :applied_year, presence: true, numericality: { only_integer: true }

  scope :ordered, -> { order(:state_key, :id) }
end
