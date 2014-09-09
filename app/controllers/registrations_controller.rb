class RegistrationsController < Devise::RegistrationsController
  layout :set_layout

  def edit
  end

  def update
  end

  protected

  def set_layout
    if action_name == "edit" || action_name == "update"
      'application'
    else
      'devise'
    end
  end
end
