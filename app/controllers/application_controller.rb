class ApplicationController < ActionController::Base
  before_filter :allow_cors

  def home
    render json: {success: false, status: 402, info: 'Wrong request'}
  end

  private

  def allow_cors
    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Allow-Methods"] = %w{GET POST PUT DELETE}.join(",")
    headers["Access-Control-Allow-Headers"] = %w{Origin Accept Content-Type X-Requested-With X-CSRF-Token}.join(",")
    head(:ok) if request.request_method == "OPTIONS"
  end

  def api_authenticate_user
    @session = Session.where(auth_token: params[:authentication_token]).first
    unless @session
      render json: {success: false,
                       info: 'Session expired. Please login',
                     status: 400}
    else
      @session[:updated_at] = Time.now
      @current_user = @session.user
      unless @current_user
        render json: {success: true,
                         info: 'Session expired. Please login',
                       status: 400}
        session = Session.find_by_user_id(@session.user_id)
        session.destroy
      end
    end
  end


end
