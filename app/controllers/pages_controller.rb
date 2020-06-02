class PagesController < ApplicationController
  layout false, only: :disabled_entity

  skip_before_action :check_entity_status
  skip_before_action :authenticate_user!

  def disabled_entity
    redirect_to root_path unless current_entity.disabled
  end
end
