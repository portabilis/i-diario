class Api::V1::BaseController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :configure_permitted_parameters
  skip_before_action :check_for_***REMOVED***

  def authenticate_api!
    unless ieducar_api.authenticate!(params[:token])
      render json: { errors: "Token inválido" }, status: 401
    end
  end

  def ieducar_api
    @ieducar_api ||= IeducarApiConfiguration.current
  end
end