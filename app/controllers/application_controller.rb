class ApplicationController < ActionController::Base
  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def render_view(template_path)
    render inline: File.read(Rails.root.join("app/views/#{template_path}.html.erb")), type: :erb, layout: false
  end
end
