class CardDefinition < ApplicationRecord
  CARD_TYPES = %w[authored system generated].freeze
  JSON_TEXT_FIELDS = {
    tags_json: { attribute: :tags, default: [] },
    spawn_rules_json: { attribute: :spawn_rules, default: {} },
    response_a_effects_json: { attribute: :response_a_effects, default: [] },
    response_b_effects_json: { attribute: :response_b_effects, default: [] }
  }.freeze

  attr_accessor :remove_portrait_upload

  has_one_attached :portrait_upload
  has_many :session_cards, dependent: :nullify

  before_validation :apply_json_text_fields

  validates :scenario_key, :key, :title, :body, :response_a_text, :response_b_text, presence: true
  validates :card_type, inclusion: { in: CARD_TYPES }
  validates :weight, numericality: { only_integer: true }
  validates :key, uniqueness: { scope: :scenario_key }
  validates :speaker_name, presence: true, if: -> { speaker_type.present? || speaker_key.present? }

  scope :active, -> { where(active: true) }
  scope :for_scenario, ->(scenario_key) { where(scenario_key:) }

  def response_a_follow_up_card
    return if response_a_follow_up_card_key.blank?

    self.class.find_by(scenario_key:, key: response_a_follow_up_card_key)
  end

  def response_b_follow_up_card
    return if response_b_follow_up_card_key.blank?

    self.class.find_by(scenario_key:, key: response_b_follow_up_card_key)
  end

  def self.follow_up_options_for(scenario_key:, exclude_id: nil)
    relation = for_scenario(scenario_key).order(:title, :key)
    relation = relation.where.not(id: exclude_id) if exclude_id.present?

    relation.map do |card|
      label = [card.title.presence, card.key].compact.join(" (")
      label = "#{label})" if card.title.present?
      [label, card.key]
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      active
      body
      card_type
      created_at
      faction_key
      id
      key
      portrait_key
      response_a_follow_up_card_key
      response_a_text
      response_b_follow_up_card_key
      response_b_text
      scenario_key
      speaker_key
      speaker_name
      speaker_type
      title
      updated_at
      weight
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[portrait_upload_attachment portrait_upload_blob session_cards]
  end

  def follow_up_card_key_for(response_key)
    public_send("response_#{response_key}_follow_up_card_key")
  end

  JSON_TEXT_FIELDS.each do |virtual_attribute, config|
    define_method(virtual_attribute) do
      raw_value = instance_variable_get("@#{virtual_attribute}")
      return raw_value if raw_value.present?

      JSON.pretty_generate(public_send(config[:attribute]).presence || config[:default])
    end

    define_method("#{virtual_attribute}=") do |value|
      instance_variable_set("@#{virtual_attribute}", value)
    end
  end

  private

  def apply_json_text_fields
    JSON_TEXT_FIELDS.each do |virtual_attribute, config|
      raw_value = instance_variable_get("@#{virtual_attribute}")
      next if raw_value.nil?

      parsed_value = parse_json_text_field(raw_value, virtual_attribute, config[:default])
      public_send("#{config[:attribute]}=", parsed_value) unless parsed_value.nil?
    end
  end

  def parse_json_text_field(raw_value, virtual_attribute, default)
    return default if raw_value.blank?

    JSON.parse(raw_value)
  rescue JSON::ParserError => error
    errors.add(virtual_attribute, "must be valid JSON: #{error.message}")
    nil
  end
end
