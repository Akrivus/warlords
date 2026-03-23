class GameSession < ApplicationRecord
  STATUSES = %w[active year_summary paused completed failed abandoned].freeze

  belongs_to :user, optional: true
  belongs_to :current_card, class_name: "SessionCard", optional: true
  has_many :session_cards, -> { order(:cycle_number, :slot_index) }, dependent: :destroy
  has_many :event_logs, -> { order(occurred_at: :desc, id: :desc) }, dependent: :destroy

  validates :user, presence: true, on: :create
  validates :scenario_key, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :cycle_number, numericality: { greater_than: 0, only_integer: true }

  scope :active, -> { where(status: "active") }
  scope :awaiting_year_summary, -> { where(status: "year_summary") }

  def context_value(key)
    context_state.fetch(key, nil)
  end

  def year_label
    year = context_value('time.year')
    "#{year.abs} #{year > 0 ? "CE" : "BCE"}"
  end

  def summary?
    status == "year_summary"
  end

  def terminal?
    %w[completed failed abandoned].include?(status)
  end

  def end_state?
    deck_state["end_state"].present?
  end

  def summary_data
    deck_state["year_summary"] || {}
  end

  def end_state_data
    deck_state["end_state"] || {}
  end

  def resolved_cards_count
    session_cards.resolved.count
  end

  def pending_cards_count
    session_cards.pending.count
  end
end
