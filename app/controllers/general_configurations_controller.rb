class GeneralConfigurationsController < ApplicationController
  def edit
    @general_configuration = GeneralConfiguration.current
  end

  def update
    @general_configuration = GeneralConfiguration.current
    @general_configuration.attributes = permitted_attributes

    if @general_configuration.save
      respond_with @general_configuration, location: edit_general_configurations_path
    else
      render :edit
    end
  end

  protected

  def permitted_attributes
    params.require(:general_configuration).permit(
      :security_level
      )
  end
end