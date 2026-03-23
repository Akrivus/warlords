module Users
  class RegistrationsController < Devise::RegistrationsController
    def new
      build_resource
      yield resource if block_given?
      render_view("users/registrations/new") if Rails.env.test?
    end
  end
end
