class EntityConfigurationsController < ApplicationController
  def edit
    @entity_configuration = EntityConfiguration.current
    @entity_configuration.build_address unless @entity_configuration.address

    authorize @entity_configuration
  end

  def update
    @entity_configuration = EntityConfiguration.current
    @entity_configuration.build_address unless @entity_configuration.address
    @entity_configuration.attributes = permitted_attributes
    @entity_configuration.update_request_remote_ip = request.remote_ip
    @entity_configuration.update_user_id = current_user.id

    authorize @entity_configuration

    if @entity_configuration.save
      cache_key = "EntityConfiguration##{current_entity.id}"
      Rails.cache.delete(cache_key)
      respond_with @entity_configuration, location: edit_entity_configurations_path
    else
      render :edit
    end
  end

  def history
    @entity_configuration = EntityConfiguration.current

    authorize @entity_configuration

    respond_with @entity_configuration
  end

  protected

  def permitted_attributes
    params.require(:entity_configuration).permit(
      :entity_name, :cnpj,:organ_name,:phone,:website,:email,:logo,
      :address_attributes => [
        :id, :zip_code, :street, :number, :complement, :neighborhood, :city,
        :state, :country, :latitude, :longitude, :_destroy
      ]
      )
  end
end
