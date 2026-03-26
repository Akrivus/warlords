class StateDefinition < ApplicationRecord
  STATE_TYPES = %w[flag modifier context_state].freeze
  VISIBILITIES = %w[public hidden debug].freeze
  STACKING_RULES = %w[unique_refresh unique_ignore stack replace].freeze
  JSON_TEXT_FIELDS = {
    default_duration_json: { attribute: :default_duration, default: {} },
    metadata_json: { attribute: :metadata, default: {} }
  }.freeze

  before_validation :apply_json_text_fields

  validates :scenario_key, :key, :state_type, :label, :visibility, :stacking_rule, presence: true
  validates :key, uniqueness: { scope: :scenario_key }
  validates :state_type, inclusion: { in: STATE_TYPES }
  validates :visibility, inclusion: { in: VISIBILITIES }
  validates :stacking_rule, inclusion: { in: STACKING_RULES }

  scope :for_scenario, ->(scenario_key) { where(scenario_key:) }
  scope :ordered, -> { order(:scenario_key, :key) }

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

  def self.attributes_from_registry(scenario_key:, definition:)
    {
      scenario_key: scenario_key,
      key: definition.fetch(:key).to_s,
      state_type: "modifier",
      label: definition.fetch(:name),
      description: definition[:description],
      icon: definition[:icon],
      visibility: definition[:visibility].presence || "hidden",
      stacking_rule: "unique_refresh",
      default_duration: definition[:default_duration].presence || {},
      metadata: {
        category: definition[:category],
        on_turn_start_effects: Array(definition[:on_turn_start_effects]),
        weight_modifiers: Array(definition[:weight_modifiers]),
        chronicle_tags: Array(definition[:chronicle_tags]),
        registry_source: "state_registry"
      }.compact
    }
  end

  def modifier?
    state_type == "modifier"
  end

  def icon_asset_key
    icon.to_s.strip.presence
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      created_at
      description
      icon
      id
      key
      label
      scenario_key
      stacking_rule
      state_type
      updated_at
      visibility
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
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
