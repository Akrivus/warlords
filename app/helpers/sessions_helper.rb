module SessionsHelper
  PORTRAIT_ASSET_EXTENSIONS = %w[avif webp png jpg jpeg svg].freeze

  def visible_state_rows(game_session)
    visible_state_presenter(game_session).sections.find { |section| section.key == :core }&.rows.to_a
  end

  def visible_relationship_rows(game_session)
    visible_state_presenter(game_session).sections.find { |section| section.key == :relationships }&.rows.to_a
  end

  def visible_faction_rows(game_session)
    visible_state_presenter(game_session).sections.find { |section| section.key == :factions }&.rows.to_a
  end

  def visible_state_presenter(game_session)
    @visible_state_presenters ||= {}
    @visible_state_presenters[game_session.object_id] ||= State::VisibleStatePresenter.new(game_session: game_session)
  end

  def active_states_panel_presenter(game_session)
    @active_states_panel_presenters ||= {}
    @active_states_panel_presenters[game_session.object_id] ||= State::PanelPresenter.new(game_session: game_session)
  end

  def chronicle_entries(game_session, include_system_events: false, include_state_events: false)
    Chronicle::FeedBuilder.new(
      game_session: game_session,
      include_system_events: include_system_events,
      include_state_events: include_state_events
    ).entries
  end

  def deck_progress_label(game_session)
    resolved = game_session.deck_state["resolved_cards"] || 0
    total = game_session.deck_state["total_cards"] || 0
    "#{resolved} / #{total} cards resolved"
  end

  def response_button_label(letter, text)
    text
  end

  def speaker_faction_label(session_card)
    return if session_card.faction_key.blank?

    session_card.faction_key.to_s.tr("_", " ").humanize
  end

  def speaker_type_label(session_card)
    return if session_card.speaker_type.blank?

    session_card.speaker_type.to_s.tr("_", " ").humanize
  end

  def speaker_portrait_image_path(session_card)
    uploaded_path = uploaded_portrait_path(session_card)
    return uploaded_path if uploaded_path.present?

    logical_path = portrait_asset_logical_path(session_card.portrait_key)
    return if logical_path.blank?

    image_path(logical_path)
  end

  def speaker_placeholder_initials(session_card)
    source = session_card.speaker_name.presence || session_card.portrait_key.to_s.tr("_", " ")
    tokens = source.scan(/[A-Za-z0-9]+/)
    return "?" if tokens.empty?

    initials = if tokens.one?
      tokens.first.first(2)
    else
      tokens.first(2).map { |token| token.first }.join
    end

    initials.upcase
  end

  def portrait_placeholder_label(session_card)
    session_card.portrait_key.presence || "portrait-pending"
  end

  def context_label(key)
    key.split(".").last.tr("_", " ").humanize
  end

  def signed_context_value(value)
    number = value.to_i
    number.positive? ? "+#{number}" : number.to_s
  end

  def summary_delta_class(delta)
    return "delta-positive" if delta.positive?
    return "delta-negative" if delta.negative?

    "delta-neutral"
  end

  def summary_delta_label(delta)
    delta.positive? ? "+#{delta}" : delta.to_s
  end

  private

  def uploaded_portrait_path(session_card)
    card_definition = session_card.card_definition
    return if card_definition.blank? || !card_definition.portrait_upload.attached?

    url_for(card_definition.portrait_upload)
  end

  def portrait_asset_logical_path(portrait_key)
    normalized_key = portrait_key.to_s.strip
    return if normalized_key.blank?

    extension = PORTRAIT_ASSET_EXTENSIONS.find do |candidate|
      Rails.root.join("app/assets/images/portraits/#{normalized_key}.#{candidate}").exist?
    end

    return if extension.blank?

    "portraits/#{normalized_key}.#{extension}"
  end
end
