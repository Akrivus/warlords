class CardDefinition < ApplicationRecord
  CARD_TYPES = %w[authored system generated].freeze

  has_many :session_cards, dependent: :nullify

  validates :scenario_key, :key, :title, :body, :response_a_text, :response_b_text, presence: true
  validates :card_type, inclusion: { in: CARD_TYPES }
  validates :weight, numericality: { only_integer: true }
  validates :key, uniqueness: { scope: :scenario_key }
  validates :speaker_name, presence: true, if: -> { speaker_type.present? || speaker_key.present? }

  scope :active, -> { where(active: true) }
  scope :for_scenario, ->(scenario_key) { where(scenario_key:) }

  def follow_up_card_key_for(response_key)
    public_send("response_#{response_key}_follow_up_card_key")
  end
end
