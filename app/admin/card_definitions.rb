# frozen_string_literal: true

ActiveAdmin.register CardDefinition do
  permit_params :scenario_key,
                :key,
                :title,
                :body,
                :card_type,
                :active,
                :weight,
                :tags_json,
                :spawn_rules_json,
                :response_a_text,
                :response_a_effects_json,
                :response_a_follow_up_card_key,
                :response_b_text,
                :response_b_effects_json,
                :response_b_follow_up_card_key,
                :speaker_type,
                :speaker_key,
                :speaker_name,
                :portrait_key,
                :faction_key,
                :portrait_upload,
                :remove_portrait_upload

  config.sort_order = "scenario_key_asc"

  scope :all, default: true
  scope :active
  scope :inactive do |card_definitions|
    card_definitions.where(active: false)
  end

  filter :card_type, as: :select, collection: CardDefinition::CARD_TYPES
  filter :active
  filter :title
  filter :speaker_name
  filter :speaker_type, as: :select, collection: CardDefinition.pluck(:speaker_type).uniq
  filter :speaker_key,  as: :select, collection: CardDefinition.pluck(:speaker_key).uniq
  filter :faction_key,  as: :select, collection: CardDefinition.pluck(:faction_key).uniq

  index do
    selectable_column
    id_column
    column :card_type
    column :title
    column :speaker_name
    actions
  end

  show do
    attributes_table do
      row :active
      row :card_type
      row :title
      row :body
      row :speaker_name
      row :portrait_upload do |card|
        if card.portrait_upload.attached?
          div do
            image_tag helpers.url_for(card.portrait_upload), style: "max-width: 180px; height: auto; border-radius: 12px;"
          end
        else
          status_tag "none"
        end
      end

      row(:tags) { |card| pre JSON.pretty_generate(card.tags || []) }
      row(:spawn_rules) { |card| pre JSON.pretty_generate(card.spawn_rules || {}) }
      row :response_a_text
      row(:response_a_effects) { |card| pre JSON.pretty_generate(card.response_a_effects || []) }
      row :response_a_follow_up_card_key do |card|
        if card.response_a_follow_up_card.present?
          link_to(card.response_a_follow_up_card.title, resource_path(card.response_a_follow_up_card))
        elsif card.response_a_follow_up_card_key.present?
          status_tag "missing", class: "inactive"
          span " #{card.response_a_follow_up_card_key}"
        else
          status_tag "none"
        end
      end
      row :response_b_text
      row(:response_b_effects) { |card| pre JSON.pretty_generate(card.response_b_effects || []) }
      row :response_b_follow_up_card_key do |card|
        if card.response_b_follow_up_card.present?
          link_to(card.response_b_follow_up_card.title, resource_path(card.response_b_follow_up_card))
        elsif card.response_b_follow_up_card_key.present?
          status_tag "missing", class: "inactive"
          span " #{card.response_b_follow_up_card_key}"
        else
          status_tag "none"
        end
      end

      row :speaker_type
      row :speaker_key
      row :faction_key
      row :portrait_key
      row :key
      row :scenario_key
      row :weight

      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors
    follow_up_options = CardDefinition.follow_up_options_for(
      scenario_key: f.object.scenario_key.presence || params.dig(:card_definition, :scenario_key) || "romebots",
      exclude_id: f.object.id
    )
    follow_up_hint = lambda do |card, response_key|
      current_follow_up = card.public_send("#{response_key}_follow_up_card")
      links = []

      if current_follow_up.present?
        links << helpers.link_to("Open linked card", resource_path(current_follow_up))
      elsif card.public_send("#{response_key}_follow_up_card_key").present?
        links << helpers.content_tag(:span, "Saved key not found in this scenario.")
      end

      if card.persisted?
        links << helpers.link_to(
          "Create new follow-up card",
          new_follow_up_admin_card_definitions_path(
            source_card_id: card.id,
            follow_up_slot: response_key.to_s.delete_prefix("response_").first
          )
        )
      end

      helpers.safe_join(links, " | ".html_safe)
    end

    f.inputs "Card Content" do
      f.input :title
      f.input :body, input_html: { rows: 6 }
      f.input :card_type, as: :select, collection: CardDefinition::CARD_TYPES
      f.input :scenario_key
      f.input :key
      f.input :active
      f.input :weight
    end

    f.inputs "Speaker" do
      f.input :speaker_name

      if f.object.portrait_upload.attached?
        f.input :portrait_upload,
                as: :file,
                hint: (
                  helpers.safe_join(
                    [
                      helpers.image_tag(
                        helpers.url_for(f.object.portrait_upload),
                        style: "max-width: 180px; height: auto; display: block; margin-bottom: 0.75rem; border-radius: 12px;"
                      ),
                      helpers.content_tag(:span, "Upload a new file to replace the current portrait.")
                    ]
                  )
                )
        f.input :remove_portrait_upload, as: :boolean, required: false, label: "Remove uploaded portrait"
      else
        f.input :portrait_upload, as: :file, hint: "Optional. Uploaded portraits override portrait_key asset lookup."
      end

      f.input :speaker_type
      f.input :speaker_key
      f.input :faction_key
      f.input :portrait_key
    end

    f.inputs "Eligibility And Metadata" do
      f.input :tags_json,
              as: :text,
              label: "Tags (JSON array)",
              input_html: { rows: 5 },
              hint: 'Example: ["politics", "opening"]'
      f.input :spawn_rules_json,
              as: :text,
              label: "Spawn Rules (JSON object)",
              input_html: { rows: 8 },
              hint: 'Example: {"min_year":-44,"one_time_only":true}'
    end

    f.inputs "Response A" do
      f.input :response_a_text, input_html: { rows: 3 }, label: "Response A Text"
      f.input :response_a_effects_json,
              as: :text,
              label: "Response A Effects (JSON array)",
              input_html: { rows: 8 },
              hint: 'Example: [{"op":"increment","key":"state.legitimacy","value":3}]'
      f.input :response_a_follow_up_card_key,
              as: :select,
              collection: follow_up_options,
              include_blank: "No follow-up card",
              label: "Response A Follow-Up Card",
              input_html: { class: "follow-up-select" },
              hint: follow_up_hint.call(f.object, :response_a)
    end

    f.inputs "Response B" do
      f.input :response_b_text, input_html: { rows: 3 }, label: "Response B Text"
      f.input :response_b_effects_json,
              as: :text,
              label: "Response B Effects (JSON array)",
              input_html: { rows: 8 },
              hint: 'Example: [{"op":"set","key":"flags.married","value":true}]'
      f.input :response_b_follow_up_card_key,
              as: :select,
              collection: follow_up_options,
              include_blank: "No follow-up card",
              label: "Response B Follow-Up Card",
              input_html: { class: "follow-up-select" },
              hint: follow_up_hint.call(f.object, :response_b)
    end

    f.actions
  end

  sidebar "Follow-Up Links", only: [:show, :edit] do
    attributes_table_for resource do
      row("Response A") do |card|
        if card.response_a_follow_up_card.present?
          link_to(card.response_a_follow_up_card.title, resource_path(card.response_a_follow_up_card))
        else
          link_to("Create follow-up card", new_follow_up_admin_card_definitions_path(source_card_id: card.id, follow_up_slot: "a"))
        end
      end

      row("Response B") do |card|
        if card.response_b_follow_up_card.present?
          link_to(card.response_b_follow_up_card.title, resource_path(card.response_b_follow_up_card))
        else
          link_to("Create follow-up card", new_follow_up_admin_card_definitions_path(source_card_id: card.id, follow_up_slot: "b"))
        end
      end
    end
  end

  collection_action :new_follow_up, method: :get do
    source_card = CardDefinition.find(params[:source_card_id])
    slot = params[:follow_up_slot].to_s

    redirect_to new_resource_path(
      card_definition: {
        scenario_key: source_card.scenario_key,
        card_type: source_card.card_type,
        active: true,
        weight: source_card.weight,
        speaker_name: source_card.speaker_name,
        speaker_type: source_card.speaker_type,
        speaker_key: source_card.speaker_key,
        portrait_key: source_card.portrait_key,
        faction_key: source_card.faction_key
      },
      source_card_id: source_card.id,
      follow_up_slot: slot
    )
  end

  controller do
    def create
      super do |success, _failure|
        success.html do
          purge_uploaded_portrait_if_requested(resource)
          link_new_follow_up_card!(resource)
          redirect_to redirect_target_for(resource) and return
        end
      end
    end

    def update
      super do |success, _failure|
        success.html do
          purge_uploaded_portrait_if_requested(resource)
          link_new_follow_up_card!(resource)
          redirect_to redirect_target_for(resource) and return
        end
      end
    end

    private

    def purge_uploaded_portrait_if_requested(resource)
      remove_requested = ActiveModel::Type::Boolean.new.cast(permitted_params.dig(:card_definition, :remove_portrait_upload))
      new_upload = permitted_params.dig(:card_definition, :portrait_upload)
      return unless remove_requested && new_upload.blank? && resource.portrait_upload.attached?

      resource.portrait_upload.purge
    end

    def link_new_follow_up_card!(resource)
      source_card_id = params[:source_card_id].presence
      follow_up_slot = params[:follow_up_slot].presence
      return if source_card_id.blank? || follow_up_slot.blank?

      source_card = CardDefinition.find_by(id: source_card_id)
      return unless source_card

      normalized_slot = follow_up_slot.to_s.sub(/\Aresponse_/, "")
      attribute_name = "response_#{normalized_slot}_follow_up_card_key"
      return unless %w[response_a_follow_up_card_key response_b_follow_up_card_key].include?(attribute_name)

      source_card.update!(attribute_name => resource.key)
      flash[:notice] = "#{flash[:notice].presence || 'Card saved.'} Linked as follow-up for #{source_card.title}."
    end

    def redirect_target_for(resource)
      source_card_id = params[:source_card_id].presence
      return resource_path(resource) if source_card_id.blank?

      edit_resource_path(CardDefinition.find(source_card_id))
    end
  end

  action_item :create_response_a_follow_up, only: :show do
    link_to "Create Response A Follow-Up", new_follow_up_admin_card_definitions_path(source_card_id: resource.id, follow_up_slot: "a")
  end

  action_item :create_response_b_follow_up, only: :show do
    link_to "Create Response B Follow-Up", new_follow_up_admin_card_definitions_path(source_card_id: resource.id, follow_up_slot: "b")
  end

end
