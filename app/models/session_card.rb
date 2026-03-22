class SessionCard < ApplicationRecord
  STATUSES = %w[pending resolved skipped exhausted].freeze
  RESPONSES = %w[a b].freeze

  belongs_to :game_session
  belongs_to :card_definition, optional: true
  has_many :event_logs, dependent: :nullify

  validates :source_type, :title, :body, :response_a_text, :response_b_text, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :chosen_response, inclusion: { in: RESPONSES }, allow_nil: true
  validates :cycle_number, :slot_index, numericality: { greater_than: 0, only_integer: true }
  validates :speaker_name, presence: true, if: -> { speaker_type.present? || speaker_key.present? }

  scope :pending, -> { where(status: "pending") }
  scope :resolved, -> { where(status: "resolved") }

  def follow_up_card_key_for(response_key)
    public_send("response_#{response_key}_follow_up_card_key")
  end
end
