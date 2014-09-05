class UnitiesController < ApplicationController
  def index
    @unities = Unity.ordered
  end

  def new
    @unity = Unity.new
  end

  def create
    @unity = Unity.new(unity_params)
    @unity.author = current_user

    @unity.save

    respond_with @unity
  end

  def edit
    @unity = Unity.find(params[:id])
  end

  def update
    @unity = Unity.find(params[:id])

    @unity.update(unity_params)

    respond_with @unity
  end

  def destroy
    @unity = Unity.find(params[:id])

    @unity.destroy

    respond_with @unity
  end

  private

  def unity_params
    params.require(:unity).permit(
      :name, :phone, :email, :responsible, :api_code
    )
  end
end
