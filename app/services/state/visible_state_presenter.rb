module State
  class VisibleStatePresenter
    Section = Struct.new(:key, :title, :rows, keyword_init: true)
    Row = Struct.new(
      :key,
      :label,
      :icon_label,
      :display_value,
      :indicator_label,
      :indicator_tone,
      :css_classes,
      keyword_init: true
    )

    def initialize(game_session:)
      @game_session = game_session
    end

    def sections
      @sections ||= Configuration::DISPLAY_GROUPS.filter_map do |group_key, group_definition|
        rows = rows_for(group_key)
        next if rows.empty?

        Section.new(
          key: group_key,
          title: group_definition.fetch(:title),
          rows: rows
        )
      end
    end

    def state_snapshot
      sections.map do |section|
        {
          "title" => section.title,
          "rows" => section.rows.map do |row|
            {
              "key" => row.key,
              "label" => row.label,
              "value" => row.display_value
            }
          end
        }
      end
    end

    def highlightable_keys
      rows_for(:core).map(&:key)
    end

    private

    attr_reader :game_session

    def rows_for(group_key)
      candidate_keys_for(group_key)
        .filter_map { |key| build_row(key, group_key) if visible?(key, group_key) }
        .sort_by { |row| [-row_score(row), row.label] }
    end

    def candidate_keys_for(group_key)
      prefix = group_definition(group_key).fetch(:prefix)
      configured_keys = display_config.keys.select { |key| display_config[key][:group] == group_key }
      discovered_keys = context_state.keys.select { |key| key.start_with?(prefix) }

      (configured_keys + discovered_keys).uniq
    end

    def build_row(key, group_key)
      recent_delta = recent_delta_for(key)
      cycle_delta = cycle_delta_for(key)
      severe = severe?(key)
      active = active_for_current_card?(key, group_key)

      Row.new(
        key: key,
        label: context_label(key),
        icon_label: icon_label_for(key),
        display_value: format_value(key),
        indicator_label: indicator_label_for(recent_delta, cycle_delta, severe, active),
        indicator_tone: indicator_tone_for(recent_delta, cycle_delta, severe, active),
        css_classes: css_classes_for(recent_delta, cycle_delta, severe, active)
      )
    end

    def row_score(row)
      numeric_value(row.key) || 0
    end

    def visible?(key, group_key)
      return false unless context_state.key?(key)
      return false if context_state[key].nil?
      return true if group_key == :core

      definition = definition_for(key)
      return true if definition[:always_visible]
      return true if active_for_current_card?(key, group_key)
      return true if recent_delta_for(key)
      return true if cycle_delta_for(key)

      numeric_value(key).to_i != 0
    end

    def context_state
      game_session.context_state || {}
    end

    def display_config
      Configuration::DISPLAY_CONFIG
    end

    def group_definition(group_key)
      Configuration::DISPLAY_GROUPS.fetch(group_key)
    end

    def definition_for(key)
      display_config[key] || inferred_definition_for(key)
    end

    def inferred_definition_for(key)
      group = Configuration::DISPLAY_GROUPS.find do |_group_key, definition|
        key.start_with?(definition.fetch(:prefix))
      end&.first

      {
        group: group,
        priority: 10,
        always_visible: group == :core
      }
    end

    def context_label(key)
      key.split(".").last.tr("_", " ").humanize
    end

    def format_value(key)
      value = context_state[key]
      case definition_for(key)[:group]
      when :relationships, :factions
        signed_value(value)
      else
        value
      end
    end

    def signed_value(value)
      number = value.to_i
      number.positive? ? "+#{number}" : number.to_s
    end

    def icon_label_for(key)
      configured_icon = definition_for(key)[:icon]
      return configured_icon if configured_icon.present?

      context_label(key).split.map { |token| token.first }.join.first(2).upcase
    end

    def indicator_label_for(recent_delta, cycle_delta, severe, active)
      return "Rising #{signed_value(recent_delta)}" if recent_delta.to_i.positive?
      return "Falling #{signed_value(recent_delta)}" if recent_delta.to_i.negative?
      return "Year #{signed_value(cycle_delta)}" if cycle_delta
      return "Critical" if severe
      return "In play" if active

      nil
    end

    def indicator_tone_for(recent_delta, cycle_delta, severe, active)
      return "up" if recent_delta.to_i.positive? || cycle_delta.to_i.positive?
      return "down" if recent_delta.to_i.negative? || cycle_delta.to_i.negative?
      return "critical" if severe
      return "active" if active

      "neutral"
    end

    def css_classes_for(recent_delta, cycle_delta, severe, active)
      classes = ["state-row"]
      classes << "state-row--changed" if recent_delta || cycle_delta
      classes << "state-row--rising" if recent_delta.to_i.positive? || cycle_delta.to_i.positive?
      classes << "state-row--falling" if recent_delta.to_i.negative? || cycle_delta.to_i.negative?
      classes << "state-row--critical" if severe
      classes << "state-row--active" if active
      classes.join(" ")
    end

    def recent_delta_for(key)
      recent_effects[key]
    end

    def recent_effects
      @recent_effects ||= begin
        effects = Array(
          latest_response_log&.payload&.dig("immediate_effects") ||
          latest_response_log&.payload&.dig("effects")
        )

        effects.each_with_object({}) do |effect, memo|
          op = effect["op"] || effect[:op]
          effect_key = effect["key"] || effect[:key]
          value = effect["value"] || effect[:value]

          delta =
            case op
            when "increment"
              value.to_i
            when "decrement"
              -value.to_i
            else
              nil
            end

          next if effect_key.blank? || delta.nil? || delta.zero?

          memo[effect_key] = delta
        end
      end
    end

    def latest_response_log
      @latest_response_log ||= begin
        loaded_logs = Array(game_session.event_logs)
        loaded_logs.find { |event| event.event_type == "response_resolved" } ||
          loaded_logs.find { |event| event.event_type == "response_chosen" } ||
          game_session.event_logs.where(event_type: ["response_resolved", "response_chosen"]).order(occurred_at: :desc, id: :desc).first
      end
    end

    def cycle_delta_for(key)
      from = cycle_snapshot.context_state[key]
      to = context_state[key]
      return unless from.is_a?(Numeric) && to.is_a?(Numeric)

      delta = to - from
      delta.zero? ? nil : delta
    end

    def severe?(key)
      value = numeric_value(key)
      return false if value.nil?

      definition = definition_for(key)
      low = definition[:severe_below]
      high = definition[:severe_above]

      return true if low && value <= low
      return true if high && value >= high

      return value.abs >= 4 if [:relationships, :factions].include?(definition[:group])
      return true if definition[:group] == :core && value <= 20

      false
    end

    def active_for_current_card?(key, group_key)
      current_card = game_session.current_card
      return false if current_card.blank?

      suffix = key.split(".").last

      case group_key
      when :factions
        current_card.faction_key.to_s == suffix
      when :relationships
        [current_card.speaker_key, current_card.portrait_key].map(&:to_s).include?(suffix)
      else
        false
      end
    end

    def numeric_value(key)
      value = context_state[key]
      value.is_a?(Numeric) ? value : nil
    end

    def cycle_snapshot
      @cycle_snapshot ||= CycleSnapshot.new(game_session: game_session)
    end
  end
end
