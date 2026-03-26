module Sessions
  class CurrentCardComponent < ApplicationComponent
    include SessionsHelper

    attr_reader :game_session, :card

    def initialize(game_session:, card:)
      @game_session = game_session
      @card = card
    end

    def card_present?
      card.present?
    end

    def deck_progress_label
      super(game_session)
    end

    def portrait_path
      speaker_portrait_image_path(card)
    end

    def speaker_name
      card.speaker_name.presence || "Unknown Speaker"
    end

    def speaker_type_label
      super(card)
    end

    def speaker_faction_label
      super(card)
    end

    def placeholder_initials
      speaker_placeholder_initials(card)
    end

    def placeholder_label
      portrait_placeholder_label(card)
    end

    def response_a_label
      response_button_label("a", card.response_a_text)
    end

    def response_b_label
      response_button_label("b", card.response_b_text)
    end

    def response_a_path
      helpers.game_session_choices_path(game_session, response_key: "a")
    end

    def response_b_path
      helpers.game_session_choices_path(game_session, response_key: "b")
    end

    erb_template <<~'ERB'
      <article class="panel hero-card">
        <% if card_present? %>
          <p class="card-slot">Card <%= card.slot_index %> of <%= game_session.deck_state["total_cards"] %></p>
          <div class="speaker-strip">
            <div class="speaker-portrait <%= "speaker-portrait--placeholder" if portrait_path.blank? %>">
              <% if portrait_path.present? %>
                <%= image_tag portrait_path,
                    alt: "#{speaker_name} portrait",
                    class: "speaker-portrait-image" %>
              <% else %>
                <span class="speaker-portrait-initials"><%= placeholder_initials %></span>
                <span class="speaker-portrait-caption"><%= placeholder_label %></span>
              <% end %>
            </div>
            <div class="speaker-meta">
              <p class="speaker-name"><%= speaker_name %></p>
              <div class="speaker-detail-row">
                <% if speaker_type_label.present? %>
                  <span class="speaker-chip"><%= speaker_type_label %></span>
                <% end %>
                <% if speaker_faction_label.present? %>
                  <span class="speaker-chip speaker-chip-faction"><%= speaker_faction_label %></span>
                <% end %>
              </div>
            </div>
          </div>
          <h2><%= card.title %></h2>
          <p class="card-body"><%= card.body %></p>

          <div class="response-list">
            <%= button_to response_a_label, response_a_path, method: :post, class: "response-button response-a" %>
            <%= button_to response_b_label, response_b_path, method: :post, class: "response-button response-b" %>
          </div>
        <% else %>
          <p class="eyebrow">No Active Card</p>
          <h2>The session is between states.</h2>
          <p class="card-body">Use the summary or ending flow to continue from here.</p>
        <% end %>
      </article>
    ERB
  end
end
