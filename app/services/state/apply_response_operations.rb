module State
  class ApplyResponseOperations
    VALID_ACTIONS = %w[add remove].freeze

    def self.call(...)
      new(...).call
    end

    def initialize(game_session:, session_card:, response_key:)
      @game_session = game_session
      @session_card = session_card
      @response_key = response_key.to_s
    end

    def call
      response_state_operations.each_with_object(
        {
          "session_states_added" => [],
          "session_states_removed" => []
        }
      ) do |operation, summary|
        result = apply_operation(operation.stringify_keys)
        next unless result

        summary.fetch(result.fetch("collection")) << result.fetch("entry")
      end
    end

    private

    attr_reader :game_session, :session_card, :response_key

    def response_state_operations
      session_card.public_send("response_#{response_key}_states")
    end

    def apply_operation(operation)
      action = operation.fetch("action")
      state_key = operation.fetch("key")

      raise ArgumentError, "Unsupported state action: #{action}" unless VALID_ACTIONS.include?(action)

      action == "add" ? add_state!(state_key, operation) : remove_state!(state_key, operation)
    end

    def add_state!(state_key, operation)
      definition = Registry.fetch(state_key)
      duration = normalized_duration(operation["duration"], definition[:default_duration])

      state = game_session.session_states.find_or_initialize_by(state_key: state_key)
      replacing = state.persisted?
      state.update!(
        source_card_key: session_card.card_definition&.key || session_card.title.parameterize(separator: "_"),
        source_response_key: response_key,
        applied_turn: current_turn,
        applied_year: current_year,
        expires_turn: duration[:expires_turn],
        expires_year: duration[:expires_year],
        metadata: {
          "duration" => duration[:raw],
          "definition_visibility" => definition[:visibility]
        }.compact
      )

      Logs::RecordEvent.call(
        game_session: game_session,
        event_type: "session_state_added",
        title: "#{definition[:name]} #{replacing ? 'refreshes' : 'begins'}",
        body: state_event_body(definition[:description], duration[:raw], replacing),
        payload: state_event_payload(
          state_key: state_key,
          state_name: definition[:name],
          duration: duration[:raw],
          expires_turn: state.expires_turn,
          expires_year: state.expires_year,
          refreshed: replacing
        ),
        session_card: session_card
      )

      {
        "collection" => "session_states_added",
        "entry" => state_summary(
          state_key: state_key,
          state_name: definition[:name],
          expires_turn: state.expires_turn,
          expires_year: state.expires_year,
          duration: duration[:raw],
          refreshed: replacing
        )
      }
    end

    def remove_state!(state_key, operation)
      definition = Registry.fetch(state_key)
      state = game_session.session_states.find_by(state_key: state_key)
      return unless state

      existing_expiry = {
        "expires_turn" => state.expires_turn,
        "expires_year" => state.expires_year
      }
      state.destroy!

      Logs::RecordEvent.call(
        game_session: game_session,
        event_type: "session_state_removed",
        title: "#{definition[:name]} ends",
        body: operation["reason"].presence || "#{definition[:name]} is explicitly removed.",
        payload: state_event_payload(
          state_key: state_key,
          state_name: definition[:name],
          expires_turn: existing_expiry["expires_turn"],
          expires_year: existing_expiry["expires_year"]
        ),
        session_card: session_card
      )

      {
        "collection" => "session_states_removed",
        "entry" => state_summary(
          state_key: state_key,
          state_name: definition[:name],
          expires_turn: existing_expiry["expires_turn"],
          expires_year: existing_expiry["expires_year"]
        )
      }
    end

    def normalized_duration(explicit_duration, default_duration)
      raw = (explicit_duration.presence || default_duration.presence || {}).deep_stringify_keys

      if raw["turns"].present?
        turns = raw["turns"].to_i

        {
          raw: { "turns" => turns },
          expires_turn: current_turn + turns,
          expires_year: current_year
        }
      elsif raw["until_year_end"]
        {
          raw: { "until_year_end" => true },
          expires_turn: nil,
          expires_year: current_year
        }
      else
        {
          raw: {},
          expires_turn: nil,
          expires_year: nil
        }
      end
    end

    def state_event_body(description, duration, replacing)
      prefix = replacing ? "The active state is refreshed." : description
      return prefix if duration.blank?

      "#{prefix} Duration: #{duration.inspect}."
    end

    def current_turn
      game_session.context_value("time.cards_resolved_this_year").to_i
    end

    def current_year
      game_session.context_value("time.year").to_i
    end

    def source_card_key
      session_card.card_definition&.key || session_card.title.parameterize(separator: "_")
    end

    def state_event_payload(state_key:, state_name:, duration: nil, expires_turn: nil, expires_year: nil, refreshed: false)
      {
        "state_key" => state_key,
        "state_name" => state_name,
        "source_card_key" => source_card_key,
        "source_response_key" => response_key,
        "duration" => duration,
        "expires_turn" => expires_turn,
        "expires_year" => expires_year,
        "refreshed" => refreshed
      }.compact
    end

    def state_summary(state_key:, state_name:, expires_turn:, expires_year:, duration: nil, refreshed: false)
      {
        "state_key" => state_key,
        "state_name" => state_name,
        "source_card_key" => source_card_key,
        "source_response_key" => response_key,
        "expires_turn" => expires_turn,
        "expires_year" => expires_year,
        "duration" => duration,
        "refreshed" => refreshed
      }.compact
    end
  end
end
