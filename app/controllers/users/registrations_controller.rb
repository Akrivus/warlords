module Users
  class RegistrationsController < Devise::RegistrationsController
    def new
      build_resource
      yield resource if block_given?
      app_render("users/registrations/new")
    end
  end
end
