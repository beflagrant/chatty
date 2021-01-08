class ApplicationController < ActionController::Base
  def set_user(user)
    session[:user_id] = user.id
  end

  def current_user
    ## session isn't available during turbo requests/responses
    User.find_by(id: session[:user_id])
  end
  helper_method :current_user

  def require_user
    current_user || redirect_to(new_user_path)
  end
end
