require "digest"

class ApplicationController < ActionController::Base
  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  respond_to :html
  helper_method :oauth_provider_enabled?

  private

  def render_view(template_path)
    render inline: File.read(Rails.root.join("app/views/#{template_path}.html.erb")), type: :erb, layout: false
  end

  def authenticate_admin!
    authenticate_user!
    return if current_admin_user

    redirect_to root_path, alert: "Admin access required."
  end

  def current_admin_user
    current_user if current_user&.admin?
  end

  def oauth_provider_enabled?(provider)
    Rails.env.test? || Devise.omniauth_configs.key?(provider.to_sym)
  end
end
