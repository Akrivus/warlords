module ApplicationHelper
  def omniauth_authorize_path(_resource_name, provider)
    "/users/auth/#{provider}"
  end

  def omniauth_authorize_url(resource_name, provider)
    omniauth_authorize_path(resource_name, provider)
  end
end
