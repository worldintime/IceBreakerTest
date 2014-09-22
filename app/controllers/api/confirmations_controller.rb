class Api::ConfirmationsController < Devise::ConfirmationsController
  def confirmed
  end

  protected

  def after_confirmation_path_for(resource_name, resource)
    '/users/confirmed'
  end
end
