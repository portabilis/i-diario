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

  def history
    @general_configuration = GeneralConfiguration.current

    respond_with @general_configuration
  end

  protected

  def permitted_attributes
    params.require(:general_configuration).permit(
      :security_level
      )
  end
end
