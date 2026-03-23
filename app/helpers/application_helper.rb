module ApplicationHelper
  def omniauth_authorize_path(_resource_name, provider)
    "/users/auth/#{provider}"
  end

  def omniauth_authorize_url(resource_name, provider)
    omniauth_authorize_path(resource_name, provider)
  end

  # This is part of a test harness because Codex for some reason can't get layouts working.
  def app_render(template_path, **locals)
    return render(template_path, locals) unless Rails.env.test?

    file_path = Rails.root.join("app/views/#{template_path}.html.erb")

    render inline: File.read(file_path), type: :erb, layout: false
  end

  # This is part of the above test harness, because inline ERB screws up partial paths.
  def app_partial(partial_path, **locals)
    return render(partial_path, locals) unless Rails.env.test?

    segments = partial_path.split("/")
    partial_name = segments.pop
    file_path = Rails.root.join("app/views", *segments, "_#{partial_name}.html.erb")

    render inline: File.read(file_path), type: :erb, locals: locals
  end
end
