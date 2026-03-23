require "digest"

class ApplicationController < ActionController::Base
  include ApplicationHelper

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  respond_to :html
  helper_method :oauth_provider_enabled?

  private

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
