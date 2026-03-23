class HomeController < ApplicationController
  def index
    @latest_session = current_user&.game_sessions&.order(created_at: :desc)&.first

    app_render("home/index")
  end
end
