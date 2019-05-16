class IeducarApiConfigurationsController < ApplicationController
  def edit
    @ieducar_api_configuration = IeducarApiConfiguration.current

    if @ieducar_api_configuration.api_security_token.blank?
      @ieducar_api_configuration.update(api_security_token: SecureRandom.hex(15))
    end

    authorize @ieducar_api_configuration
    render :edit
  end

  def update
    @ieducar_api_configuration = IeducarApiConfiguration.current
    @ieducar_api_configuration.attributes = permitted_attributes

    authorize @ieducar_api_configuration

    if @ieducar_api_configuration.save
      respond_with @ieducar_api_configuration, location: edit_ieducar_api_configurations_path
    else
      render :edit
    end
  end

  def history
    @ieducar_api_configuration = IeducarApiConfiguration.current

    authorize @ieducar_api_configuration

    respond_with @ieducar_api_configuration
  end

  protected

  def permitted_attributes
    params.require(:ieducar_api_configuration).permit(
      :url, :token, :secret_token, :unity_code
    )
  end

  def show_configuration_form?
    current_user.can_change?('ieducar_api_configurations')
  end
  helper_method :show_configuration_form?
end
