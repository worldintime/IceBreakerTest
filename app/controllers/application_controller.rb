class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery

  before_filter :set_access_control_headers

  def set_access_control_headers
     headers['Access-Control-Allow-Origin'] = '*'
     headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
     headers['Access-Control-Request-Method'] = '*'
     headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
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
