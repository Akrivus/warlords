module Decks
  class BuildForSession
    def self.call(...)
      new(...).call
    end

    def initialize(game_session:, force: false)
      @game_session = game_session
      @force = force
    end

    def call
      return game_session if existing_cycle_cards? && !force

      ActiveRecord::Base.transaction do
        selected_cards.each_with_index do |definition, index|
          game_session.session_cards.create!(
            card_definition: definition,
            source_type: "card_definition",
            cycle_number: game_session.cycle_number,
            slot_index: index + 1,
            status: "pending",
            title: definition.title,
            body: definition.body,
            response_a_text: definition.response_a_text,
            response_a_effects: definition.response_a_effects,
            response_a_states: definition.response_a_states,
            response_a_follow_up_card_key: definition.response_a_follow_up_card_key,
            response_b_text: definition.response_b_text,
            response_b_effects: definition.response_b_effects,
            response_b_states: definition.response_b_states,
            response_b_follow_up_card_key: definition.response_b_follow_up_card_key,
            speaker_type: definition.speaker_type,
            speaker_key: definition.speaker_key,
            speaker_name: definition.speaker_name,
            portrait_key: definition.portrait_key,
            faction_key: definition.faction_key,
            fingerprint: "#{definition.key}-#{game_session.cycle_number}-#{index + 1}",
            metadata: {
              "tags" => definition.tags,
              "card_type" => definition.card_type
            }
          )
        end

        State::ProcessTurnStart.call(game_session: game_session)
        activate_next_card!
        sync_deck_state!
        log_cycle_events
      end

      game_session
    end

    private

    attr_reader :game_session, :force

    def existing_cycle_cards?
      game_session.session_cards.where(cycle_number: game_session.cycle_number).exists?
    end

    def selected_cards
      @selected_cards ||= begin
        eligible = CardDefinition.active.for_scenario(game_session.scenario_key).select { |card| eligible?(card) }
        ordered = eligible.sort_by { |card| [-effective_weight(card), card.key] }
        selected = ordered.first(Configuration::DECK_SIZE)
        repeatables = ordered.select { |card| repeatable_card?(card) }

        index = 0
        while selected.count < Configuration::DECK_SIZE && repeatables.any?
          selected << repeatables[index % repeatables.length]
          index += 1
        end

        selected
      end
    end

    def eligible?(definition)
      rules = definition.spawn_rules.stringify_keys
      year = historical_year

      return false if rules["min_year"] && year < rules["min_year"].to_i
      return false if rules["max_year"] && year > rules["max_year"].to_i

      required_flags_met?(rules) &&
        excluded_flags_cleared?(rules) &&
        required_context_met?(rules) &&
        required_session_states_met?(rules) &&
        repeatable_or_unused?(definition, rules)
    end

    def repeatable_or_unused?(definition, rules)
      return true if rules["repeatable"]
      return true unless rules["one_time_only"]

      !game_session.session_cards.joins(:card_definition).exists?(card_definitions: { id: definition.id })
    end

    def repeatable_card?(definition)
      definition.spawn_rules.stringify_keys["repeatable"]
    end

    def historical_year
      game_session.context_value("time.year").to_i
    end

    def effective_weight(card_definition)
      card_definition.weight + state_weight_modifier(card_definition)
    end

    def state_weight_modifier(card_definition)
      game_session.session_states.sum do |state|
        definition = State::Registry.fetch(state.state_key)
        Array(definition[:weight_modifiers]).sum do |modifier|
          next 0 unless modifier_matches_card?(modifier, card_definition)

          modifier[:delta].to_i
        end
      end
    end

    def modifier_matches_card?(modifier, card_definition)
      card_key_match = modifier[:card_keys].blank? || Array(modifier[:card_keys]).include?(card_definition.key)
      tag_match = modifier[:tags].blank? || (Array(card_definition.tags) & Array(modifier[:tags])).any?

      card_key_match && tag_match
    end

    def required_flags_met?(rules)
      Array(rules["required_flags"]).all? { |flag| game_session.context_state[flag] }
    end

    def excluded_flags_cleared?(rules)
      Array(rules["excluded_flags"]).none? { |flag| game_session.context_state[flag] }
    end

    def required_context_met?(rules)
      Array(rules["required_context"]).all? do |condition|
        context_condition_met?(condition)
      end
    end

    def required_session_states_met?(rules)
      required_state_keys = Array(rules["required_session_states"]).map(&:to_s)
      return true if required_state_keys.empty?

      state_keys = game_session.session_states.pluck(:state_key)
      required_state_keys.all? { |state_key| state_keys.include?(state_key) }
    end

    def context_condition_met?(condition)
      normalized = condition.stringify_keys
      key = normalized.fetch("key")
      expected_value =
        if normalized.key?("equals")
          normalized["equals"]
        elsif normalized.key?("value")
          normalized["value"]
        else
          true
        end

      game_session.context_state[key] == expected_value
    end

    def activate_next_card!
      next_card = game_session.session_cards.pending.where(cycle_number: game_session.cycle_number).order(:slot_index).first
      game_session.update!(current_card: next_card)
    end

    def sync_deck_state!
      cycle_cards = game_session.session_cards.where(cycle_number: game_session.cycle_number)
      existing_state = game_session.deck_state.deep_dup
      existing_state["cycle_start_context"] ||= game_session.context_state.deep_dup
      game_session.update!(
        deck_state: existing_state.merge(
          "cycle_number" => game_session.cycle_number,
          "total_cards" => cycle_cards.count,
          "resolved_cards" => cycle_cards.resolved.count,
          "pending_cards" => cycle_cards.pending.count,
          "year_summary" => nil,
          "end_state" => nil
        )
      )
    end

    def log_cycle_events
      Logs::RecordEvent.call(
        game_session: game_session,
        event_type: "year_started",
        title: "Year #{game_session.year_label} begins",
        body: "A new RomeBots year opens with #{game_session.deck_state['total_cards']} cards."
      )
      Logs::RecordEvent.call(
        game_session: game_session,
        event_type: "deck_built",
        title: "Yearly deck assembled",
        body: "The Senate, streets, and camp all send their demands.",
        payload: { "deck_size" => game_session.deck_state["total_cards"] }
      )
      return unless game_session.current_card

      Logs::RecordEvent.call(
        game_session: game_session,
        event_type: "card_presented",
        title: game_session.current_card.title,
        body: game_session.current_card.body,
        session_card: game_session.current_card
      )
    end
  end
end
