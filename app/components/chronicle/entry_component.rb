module Chronicle
  class EntryComponent < ApplicationComponent
    attr_reader :entry, :truncate_length

    def initialize(entry:, truncate_length: 140)
      @entry = entry
      @truncate_length = truncate_length
    end

    def state_changes
      @state_changes ||= [
        *Array(entry.session_states_added).map { |state| { prefix: "State gained:", state: state } },
        *Array(entry.session_states_removed).map { |state| { prefix: "State lost:", state: state } }
      ]
    end

    def state_change_label(state)
      state["state_name"] || state["state_key"].to_s.humanize
    end

    erb_template <<~'ERB'
      <li>
        <strong><%= entry.title %></strong>
        <% if entry.primary? && entry.card_body.present? %>
          <span><%= helpers.truncate(entry.card_body, length: truncate_length) %></span>
        <% end %>
        <% if entry.primary? && entry.response_text.present? %>
          <span><%= entry.response_text %></span>
        <% end %>
        <% if entry.summary.present? %>
          <span><%= entry.summary %></span>
        <% end %>
        <% if entry.visible_state_changes? %>
          <% state_changes.each do |change| %>
            <span><%= change[:prefix] %> <%= state_change_label(change[:state]) %></span>
          <% end %>
        <% end %>
      </li>
    ERB
  end
end
