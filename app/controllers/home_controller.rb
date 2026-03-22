class HomeController < ApplicationController
  def index
    @latest_session = GameSession.order(created_at: :desc).first

    render_view("home/index") if Rails.env.test?
  end
end
