module SessionsHelper
  def visible_state_rows(game_session)
    Scenarios::Romebots::Configuration::VISIBLE_STATE_KEYS.map do |key|
      [key.split(".").last.humanize, game_session.context_state[key]]
    end
  end

  def visible_relationship_rows(game_session)
    Scenarios::Romebots::Configuration::VISIBLE_RELATION_KEYS.map do |key|
      [context_label(key), signed_context_value(game_session.context_state[key])]
    end
  end

  def visible_faction_rows(game_session)
    Scenarios::Romebots::Configuration::VISIBLE_FACTION_KEYS.map do |key|
      [context_label(key), signed_context_value(game_session.context_state[key])]
    end
  end

  def deck_progress_label(game_session)
    resolved = game_session.deck_state["resolved_cards"] || 0
    total = game_session.deck_state["total_cards"] || 0
    "#{resolved} / #{total} cards resolved"
  end

  def response_button_label(letter, text)
    "#{letter.upcase}. #{text}"
  end

  def speaker_faction_label(session_card)
    return if session_card.faction_key.blank?

    session_card.faction_key.to_s.tr("_", " ").humanize
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
end
