module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      handle_callback("Google")
    end

    def github
      handle_callback("GitHub")
    end

    def failure
      redirect_to new_user_session_path, alert: "We could not sign you in through #{failed_strategy_name}."
    end

    private

    def handle_callback(provider_name)
      result = User.from_omniauth(request.env["omniauth.auth"])

      if result.user.present?
        set_flash_message(:notice, :success, kind: provider_name)
        sign_in_and_redirect result.user, event: :authentication
      else
        redirect_to new_user_session_path, alert: result.error || "We could not sign you in through #{provider_name}."
      end
    end

    def failed_strategy_name
      failed_strategy = request.env["omniauth.error.strategy"]
      failed_strategy&.name&.to_s&.humanize || "that provider"
    end
  end
end
