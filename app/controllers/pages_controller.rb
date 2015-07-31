class PagesController < ApplicationController
  layout false, only: :disabled_entity

  def disabled_entity
    redirect_to root_path unless current_entity.disabled
  end
end