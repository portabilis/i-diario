class GeneralConfigurationsController < ApplicationController
  def edit
    @general_configuration = GeneralConfiguration.current

    authorize @general_configuration
  end

  def update
    @general_configuration = GeneralConfiguration.current
    @general_configuration.attributes = permitted_attributes

    authorize @general_configuration

    if @general_configuration.save
      respond_with @general_configuration, location: edit_general_configurations_path
    else
      render :edit
    end
  end

  def history
    @general_configuration = GeneralConfiguration.current

    authorize @general_configuration

    respond_with @general_configuration
  end

  protected

  def permitted_attributes
    params.require(:general_configuration).permit(
      :security_level, :students_default_role_id, :employees_default_role_id, :parents_default_role_id
      )
  end
end
