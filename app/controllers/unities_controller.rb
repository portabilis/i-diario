class UnitiesController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  def index
    @unities = apply_scopes(Unity.filter_from_params(filtering_params(params[:search]))).ordered

    authorize @unities
  end

  def new
    @unity = Unity.new unit_type: 'school_unit'
    @unity.build_address unless @unity.address

    authorize @unity
  end

  def show
    @unity = Unity.find(params[:id])
    render json:  @unity
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
    if @unity.active
      @unity.destroy
    else
      @unity.discard
    end

    respond_with @unity, location: unities_path
  end

  def destroy_batch
    @unities = Unity.where(id: params[:ids])

    if @unities.destroy_all
      render json: {}, status: :ok
    else
      render json: {}, status: 500
    end
  end

  def history
    @unity = Unity.find params[:id]

    authorize @unity

    respond_with @unity
  end

  def search
    @unities = apply_scopes(Unity).ordered

    render json: @unities
  end

  def all
    @unities = Unity.ordered
    render json:  @unities
  end

  def select2_remote
    unities = UnityDecorator.data_for_select2_remote(params[:description])
    render json: unities
  end

  private

  def unity_params
    params.require(:unity).permit(
      :name, :phone, :email, :responsible, :api_code, :unit_type, :active,
      :address_attributes => [
        :id, :zip_code, :street, :number, :complement, :neighborhood, :city,
        :state, :country, :latitude, :longitude, :_destroy
      ],
      :unity_equipments_attributes => [
        :id, :_destroy, :code, :biometric_type
      ]
    )
  end

  def filtering_params(params)
    if params
      params.slice(:search_name, :unit_type, :phone, :email, :responsible)
    else
      {}
    end
  end
end
