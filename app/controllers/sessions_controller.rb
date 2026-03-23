class SessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_game_session, only: [:show, :summary, :advance, :ending]

  def create
    game_session = Sessions::StartRun.call(
      scenario_key: params.fetch(:scenario_key, Scenarios::Romebots::Configuration::SCENARIO_KEY),
      user: current_user
    )

    redirect_to destination_for(game_session)
  end

  def show
    redirect_to summary_game_session_path(@game_session) and return if @game_session.summary?
    redirect_to ending_game_session_path(@game_session) and return if @game_session.end_state?

    app_render("sessions/show")
  end

  def summary
    redirect_to destination_for(@game_session) and return unless @game_session.summary?

    @summary = @game_session.summary_data
    app_render("sessions/summary")
  end

  def advance
    Cycles::Advance.call(game_session: @game_session)
    redirect_to destination_for(@game_session), status: :see_other
  rescue ArgumentError => error
    redirect_to destination_for(@game_session), alert: error.message, status: :see_other
  end

  def ending
    redirect_to destination_for(@game_session) and return unless @game_session.end_state?

    @end_state = @game_session.end_state_data
    app_render("sessions/ending")
  end

  private

  def set_game_session
    @game_session = current_user.game_sessions.includes(
      :event_logs,
      :session_cards,
      current_card: { card_definition: { portrait_upload_attachment: :blob } }
    ).find(params[:id])
  end

  def destination_for(game_session)
    return ending_game_session_path(game_session) if game_session.end_state?
    return summary_game_session_path(game_session) if game_session.summary?

    game_session_path(game_session)
  end
end
