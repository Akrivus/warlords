class ChoicesController < ApplicationController
  before_action :authenticate_user!

  def create
    game_session = current_user.game_sessions.find(params[:game_session_id])
    Choices::ResolveResponse.call(game_session: game_session, response_key: params[:response_key])

    redirect_to destination_for(game_session.reload), status: :see_other
  rescue ArgumentError => error
    redirect_to destination_for(game_session.reload), alert: error.message, status: :see_other
  end

  private

  def destination_for(game_session)
    return ending_game_session_path(game_session) if game_session.end_state?
    return summary_game_session_path(game_session) if game_session.summary?

    game_session_path(game_session)
  end
end
