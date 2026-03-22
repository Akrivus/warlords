module FollowUps
  class EnqueueForResponse
    def self.call(...)
      new(...).call
    end

    def initialize(session_card:, response_key:)
      @session_card = session_card
      @response_key = response_key.to_s
    end

    def call
      return if follow_up_key.blank?
      return if follow_up_depth >= 1

      existing_follow_up || create_follow_up_from_definition
    end

    private

    attr_reader :session_card, :response_key

    delegate :game_session, to: :session_card

    def follow_up_key
      session_card.follow_up_card_key_for(response_key)
    end

    def follow_up_depth
      session_card.metadata.fetch("follow_up_depth", 0).to_i
    end

    def existing_follow_up
      card = game_session.session_cards.pending
        .where(cycle_number: game_session.cycle_number)
        .joins(:card_definition)
        .where(card_definitions: { key: follow_up_key, scenario_key: game_session.scenario_key })
        .order(:slot_index)
        .first

      return unless card

      card.update!(
        metadata: card.metadata.merge(
          "follow_up_depth" => 1,
          "follow_up_parent_session_card_id" => session_card.id
        )
      )
      card
    end

    def create_follow_up_from_definition
      definition = CardDefinition.active.for_scenario(game_session.scenario_key).find_by(key: follow_up_key)
      return unless definition
      return if follow_up_already_seen?

      follow_up_card = game_session.session_cards.create!(
        card_definition: definition,
        source_type: "card_definition",
        cycle_number: game_session.cycle_number,
        slot_index: next_slot_index,
        status: "pending",
        title: definition.title,
        body: definition.body,
        response_a_text: definition.response_a_text,
        response_a_effects: definition.response_a_effects,
        response_a_follow_up_card_key: definition.response_a_follow_up_card_key,
        response_b_text: definition.response_b_text,
        response_b_effects: definition.response_b_effects,
        response_b_follow_up_card_key: definition.response_b_follow_up_card_key,
        speaker_type: definition.speaker_type,
        speaker_key: definition.speaker_key,
        speaker_name: definition.speaker_name,
        portrait_key: definition.portrait_key,
        faction_key: definition.faction_key,
        fingerprint: "#{definition.key}-#{game_session.cycle_number}-#{next_slot_index}",
        metadata: {
          "tags" => definition.tags,
          "card_type" => definition.card_type,
          "follow_up_depth" => 1,
          "follow_up_parent_session_card_id" => session_card.id
        }
      )

      Logs::RecordEvent.call(
        game_session: game_session,
        event_type: "follow_up_queued",
        title: "#{follow_up_card.title} is drawn forward",
        body: "A direct consequence of #{session_card.title} demands immediate attention.",
        payload: {
          "follow_up_card_key" => follow_up_key,
          "parent_session_card_id" => session_card.id
        },
        session_card: follow_up_card
      )

      follow_up_card
    end

    def follow_up_already_seen?
      game_session.session_cards.joins(:card_definition).exists?(
        cycle_number: game_session.cycle_number,
        card_definitions: { key: follow_up_key, scenario_key: game_session.scenario_key }
      )
    end

    def next_slot_index
      game_session.session_cards.where(cycle_number: game_session.cycle_number).maximum(:slot_index).to_i + 1
    end
  end
end
