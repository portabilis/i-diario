class UnitiesController < ApplicationController
  def index
    @unities = Unity.ordered

    authorize @unities
  end

  def new
    @unity = Unity.new unit_type: 'school_unit'
    @unity.build_address unless @unity.address

    authorize @unity
  end

  def create
    @unity = Unity.new(unity_params)
    @unity.author = current_user

    authorize @unity

    if @unity.save
      respond_with @unity, location: unities_path
    else
      render :new
    end
  end

  def edit
    @unity = Unity.find(params[:id])
    @unity.build_address unless @unity.address

    authorize @unity
  end

  def update
    @unity = Unity.find(params[:id])

    authorize @unity

    if @unity.update(unity_params)
      respond_with @unity, location: unities_path
    else
      render :edit
    end
  end

  def destroy
    @unity = Unity.find(params[:id])

    authorize @unity

    @unity.destroy

    respond_with @unity, location: unities_path
  end

  def history
    @unity = Unity.find params[:id]

    authorize @unity

    respond_with @unity
  end

  private

  def unity_params
    params.require(:unity).permit(
      :name, :phone, :email, :responsible, :api_code, :unit_type,
      :address_attributes => [
        :id, :zip_code, :street, :number, :complement, :neighborhood, :city,
        :state, :country, :latitude, :longitude, :_destroy
      ]
    )
  end
end
