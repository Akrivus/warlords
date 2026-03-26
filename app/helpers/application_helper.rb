module ApplicationHelper
  STATE_ICON_ASSET_EXTENSIONS = %w[avif webp png jpg jpeg svg].freeze

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

  def state_icon_image_path(icon_key)
    logical_path = state_icon_asset_logical_path(icon_key)
    return if logical_path.blank?

    image_path(logical_path)
  end

  def state_icon_placeholder_label(label, icon_key = nil)
    source = label.presence || icon_key.to_s.tr("_", " ")
    tokens = source.to_s.scan(/[A-Za-z0-9]+/)
    return "?" if tokens.empty?

    initials = if tokens.one?
      tokens.first.first(2)
    else
      tokens.first(2).map { |token| token.first }.join
    end

    initials.upcase
  end

  private

  def state_icon_asset_logical_path(icon_key)
    normalized_key = icon_key.to_s.strip
    return if normalized_key.blank?

    extension = STATE_ICON_ASSET_EXTENSIONS.find do |candidate|
      Rails.root.join("app/assets/images/state_icons/#{normalized_key}.#{candidate}").exist?
    end

    return if extension.blank?

    "state_icons/#{normalized_key}.#{extension}"
  end
end
