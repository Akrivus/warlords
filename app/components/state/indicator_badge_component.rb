module State
  class IndicatorBadgeComponent < ApplicationComponent
    attr_reader :label, :tone, :html_class

    def initialize(label:, tone:, html_class: nil)
      @label = label
      @tone = tone
      @html_class = html_class
    end

    def classes
      [
        "state-indicator",
        "state-indicator--#{tone}",
        html_class
      ].compact.join(" ")
    end

    erb_template <<~'ERB'
      <span class="<%= classes %>"><%= label %></span>
    ERB
  end
end
