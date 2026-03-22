module Sessions
  class CheckEndState
    CONDITIONS = [
      {
        key: "state.health",
        threshold: 0,
        title: "Octavian is dead",
        body: "Your body fails before the regime can harden. Rome moves on without your design.",
        code: "death"
      },
      {
        key: "state.public_order",
        threshold: 0,
        title: "Rome falls into chaos",
        body: "The streets outpace your authority. Bread, fear, and rumor finish the year faster than you do.",
        code: "civil_disorder"
      },
      {
        key: "state.military_support",
        threshold: 0,
        title: "The legions abandon you",
        body: "Without armed loyalty, your claim becomes a speech with no audience.",
        code: "military_collapse"
      }
    ].freeze

    def self.call(...)
      new(...).call
    end

    def initialize(game_session:)
      @game_session = game_session
    end

    def call
      condition = CONDITIONS.find { |entry| game_session.context_state[entry[:key]].to_i <= entry[:threshold] }
      return unless condition

      {
        "code" => condition[:code],
        "title" => condition[:title],
        "body" => condition[:body],
        "status" => "failed",
        "year" => game_session.context_value("time.year")
      }
    end

    private

    attr_reader :game_session
  end
end
