class RegistrationsController < Devise::RegistrationsController
  layout :set_layout

  protected

  def set_layout
    if action_name == "edit"
      'application'
    else
      'devise'
    end
  end
end
