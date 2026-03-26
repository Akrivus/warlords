Rails.application.config.to_prepare do
  ViewComponent::Base.config.view_component_path = "app/components"
end
