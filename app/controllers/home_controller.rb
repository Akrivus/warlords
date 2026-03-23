class HomeController < ApplicationController
  def index
    @latest_session = current_user&.game_sessions&.order(created_at: :desc)&.first

    render_view("home/index") if Rails.env.test?
  end
end
