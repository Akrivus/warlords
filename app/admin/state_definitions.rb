# frozen_string_literal: true

ActiveAdmin.register StateDefinition do
  permit_params :scenario_key,
                :key,
                :state_type,
                :label,
                :description,
                :icon,
                :visibility,
                :stacking_rule,
                :default_duration_json,
                :metadata_json

  config.sort_order = "scenario_key_asc"

  scope :all, default: true
  scope :modifier do |state_definitions|
    state_definitions.where(state_type: "modifier")
  end
  scope :flag do |state_definitions|
    state_definitions.where(state_type: "flag")
  end
  scope :context_state do |state_definitions|
    state_definitions.where(state_type: "context_state")
  end

  filter :scenario_key
  filter :key
  filter :label
  filter :state_type, as: :select, collection: StateDefinition::STATE_TYPES
  filter :visibility, as: :select, collection: StateDefinition::VISIBILITIES
  filter :stacking_rule, as: :select, collection: StateDefinition::STACKING_RULES

  index do
    selectable_column
    id_column
    column :state_type
    column :label
    column("Icon") do |state|
      if state.icon.present? && helpers.state_icon_image_path(state.icon).present?
        image_tag helpers.state_icon_image_path(state.icon), style: "width: 2rem; height: 2rem; border-radius: 10px; object-fit: cover;"
      else
        status_tag(state.icon.presence || "none")
      end
    end
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :stacking_rule
      row :scenario_key
      row :key
      row :label
      row :state_type
      row :description
      row :icon
      row :icon_preview do |state|
        if state.icon.present? && helpers.state_icon_image_path(state.icon).present?
          image_tag helpers.state_icon_image_path(state.icon), style: "max-width: 96px; height: auto; border-radius: 12px;"
        else
          status_tag "none"
        end
      end
      row :visibility

      row(:default_duration) { |state| pre JSON.pretty_generate(state.default_duration || {}) }
      row(:metadata) { |state| pre JSON.pretty_generate(state.metadata || {}) }

      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs "State Definition" do
      f.input :scenario_key
      f.input :key
      f.input :label
      f.input :state_type, as: :select, collection: StateDefinition::STATE_TYPES
      f.input :visibility, as: :select, collection: StateDefinition::VISIBILITIES
      f.input :stacking_rule, as: :select, collection: StateDefinition::STACKING_RULES
      if f.object.icon.present? && helpers.state_icon_image_path(f.object.icon).present?
        f.input :icon,
                hint: (
                  helpers.safe_join(
                    [
                      helpers.image_tag(
                        helpers.state_icon_image_path(f.object.icon),
                        style: "width: 4rem; height: 4rem; display: block; margin-bottom: 0.75rem; border-radius: 14px; object-fit: cover;"
                      ),
                      helpers.content_tag(:span, "Asset convention: app/assets/images/state_icons/<icon>.<ext>")
                    ]
                  )
                )
      else
        f.input :icon, hint: "Asset convention: app/assets/images/state_icons/<icon>.<ext>"
      end
      f.input :description, input_html: { rows: 4 }
    end

    f.inputs "Behavior Metadata" do
      f.input :default_duration_json,
              as: :text,
              label: "Default Duration (JSON object)",
              input_html: { rows: 6 },
              hint: 'Example: {"turns": 3} or {"until_year_end": true}'
      f.input :metadata_json,
              as: :text,
              label: "Metadata (JSON object)",
              input_html: { rows: 12 },
              hint: 'Example: {"category":"military","chronicle_tags":["security"],"weight_modifiers":[]}'
    end

    f.actions
  end
end
