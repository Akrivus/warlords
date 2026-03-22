module Sessions
  class StartRun
    def self.call(...)
      new(...).call
    end

    def initialize(scenario_key:)
      @scenario_key = scenario_key
    end

    def call
      raise ArgumentError, "Unsupported scenario: #{scenario_key}" unless scenario_key == Scenarios::Romebots::Configuration::SCENARIO_KEY

      ActiveRecord::Base.transaction do
        game_session = GameSession.create!(
          scenario_key: scenario_key,
          status: "active",
          cycle_number: 1,
          context_state: Scenarios::Romebots::Configuration.initial_context,
          deck_state: {},
          seed: SecureRandom.hex(4),
          started_at: Time.current
        )

        Logs::RecordEvent.call(
          game_session: game_session,
          event_type: "session_started",
          title: "RomeBots begins",
          body: "Octavian steps into Rome's vacuum with a famous name and limited patience."
        )

        Decks::BuildForSession.call(game_session: game_session)
        game_session.reload
      end
    end

    private

    attr_reader :scenario_key
  end
end
